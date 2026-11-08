# OPS-H8b: Python consumer loop: in-place DLQ retry, commit gating, interruptible waits, graceful stop, poison records

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (finishes Technical PRD §8.1 L4 for the Python consumer; replaces OPS-H8's interim crash-restart) |
| **PRD ref** | Product PRD OPS-1, OPS-3, §5.3; Technical PRD §8.1 (L4 commit-after-process: "All consumers"), §8.2 (retry and DLQ) |
| **Depends on** | **OPS-H8 merged** (same file `services/common/kafka_client.py` and same test file; AGENTS.md §3 independence). OPS-H1 merged (heartbeat hook kept) |
| **Jira** | not yet created (orchestrator: story under the OPS epic, label `task-OPS-H8b`, link KAN-34) |
| **Design required** | yes, **covered by the approved `docs/design/OPS-H8.md`** (§2–§5, §7; PM decision + split addendum 2026-11-07). No new design round. Binding conditions 1, 5, 6 and 7 apply |
| **Status** | Ready (once OPS-H8 merges) |

## Goal
OPS-H8 (part a) makes the producer confirm every delivery and keeps the existing loop from committing past an unconfirmed DLQ write. It does that by
leaving `start`, so the worker restarts and re-runs the handler 3× per restart while the DLQ is down. This ticket finishes the consumer side the way the approved
design says, mirroring OPS-H6. A failed DLQ write is retried in place with the handler not re-run, a commit error is logged instead of killing the worker, shutdown
interrupts every wait promptly, and an undecodable record goes to the DLQ instead of crash-looping the worker (Goal bullets 3 and 4 of `agents/tasks/OPS-H8.md`).

## Scope
- Files: `services/common/kafka_client.py` (**consumer layer**: `ServiceKafkaConsumer.start`, `_dead_letter`, `_commit`, `stop`, the stop flag
  `threading.Event` plus the `_wait` / `_handler_backoff` / `_dlq_backoff` instance seams, SIGTERM/SIGINT install and restore inside `start`, the
  poison decode `try`, the per-attempt handler warning logging `type(e).__name__`, and the DLQ `traceparent` fallback to `envelope.traceparent`), and `tests/test_kafka_client.py` (extend).
- Source: the full implementation already exists at ArxivLens `ebe80a7` (branch `agent/backend/OPS-H8` history). Cut `agent/backend/OPS-H8b` from a fresh `origin/main`
  **after OPS-H8 merges** and bring the consumer parts over (`git checkout ebe80a7 -- …`, then reconcile with what OPS-H8 merged).
- Keep the retry body at its original indentation (lesson OPS-H6; the build note's shape change from design §7 is accepted).
- **Not in scope:** the producer layer (done in OPS-H8), worker files, `tests/test_worker_heartbeat.py` (unchanged, green), `ci.yml` (OPS-H8's step already runs the file),
  `Makefile`, `docker-compose.yml` (`stop_grace_period` is a Backlog item), `shared/events/*`, `services/common/db.py`, the Go consumer, the 3-attempt count and the 200/400 ms schedule.

## Acceptance criteria
These are OPS-H8's original AC1–AC4, AC5 through `start`, AC6/6b, AC7, AC8, AC10a/c and AC11/AC12, unchanged in substance. Test names follow design §"Test plan".
- [ ] AC1 — Success path unchanged: `test_success_path` (ok on attempt 1 / after 1 / after 2 failures → exactly one commit, no DLQ produce, waits `[]`, `[0.2]`, `[0.2, 0.4]`).
  `test_commit_error_is_logged_and_loop_continues`: `commit` raising `KafkaException` → ERROR `Commit failed (… offset=5 …)`, @6 still handled and committed. Only `KafkaException` is caught.
- [ ] AC2 — DLQ path: handler fails 3× → one DLQ message with `original_topic`, `partition`, `offset`, `attempts = 3`, `consumer_group`, `traceparent` (header, else envelope),
  and `stack_trace` naming the handler. Commit only after the confirmed delivery (call order asserted).
- [ ] AC3 — **DLQ delivery fails → no commit, retried in place**: `[p0@4 ok, p0@5 fails, p0@6 ok]`, every DLQ write fails (`err` and `queued` cases), stop after a few rounds. Commit for @4 only;
  ≥ 2 produces for @5; handler@5 exactly 3×; handler@6 never; `start` **returns normally** and closes the consumer. This replaces OPS-H8 AC5's interim
  "`start` raises": update that test's expectation to this one. The no-commit assertions stay the same (that's not a weakened test; the design mandates it).
- [ ] AC4 — Recovery: DLQ `err, err, ok` → one confirmed DLQ message, one commit after it, handler calls 3, DLQ waits `[1, 2]`. `test_dlq_backoff_schedule`: rounds 1–7 → 1, 2, 4, 8, 16, 30, 30.
- [ ] AC5 — A processor-style handler whose `publish` keeps failing, with the consumer's DLQ also failing → no commit for that record (extends OPS-H8 AC5).
- [ ] AC6 — Interruptible waits: real `threading.Event`, 5 s backoff injected, stop set during the first handler-retry wait → `start` returns within 200 ms, no commit, no DLQ write;
  same for a DLQ-round wait (1 failed produce, no commit). **AC6b:** stop requested while the handler runs its last attempt and it then raises → no DLQ write, no commit (and the
  stop-on-call-1 variant). `test_signal_handler_sets_stop_and_is_restored` (first signal graceful, handler restored after `start`). `grep -n "time.sleep" services/common/kafka_client.py` prints nothing.
- [ ] AC7 — Poison records: `b"not json"` → `original_value == {"raw_value": …}`; valid JSON missing envelope fields → the decoded dict; `b"[1, 2]"` → `raw_value`. Each: one DLQ message,
  `attempts == 1`, commit after it, the handler never called for it, the next record handled and committed.
- [ ] AC8 — Log hygiene: on a failed DLQ write the CRITICAL line has topic, partition, offset, DLQ topic, round and the error. No log record contains the record value or the handler
  error text (`caplog`, sentinel in both). Handler and poison rows.
- [ ] AC9 — No regressions: `make test-py` and the `tests/test_kafka_client.py` CI step are green, including every OPS-H8 test (apart from the one expectation AC3 replaces).
  `tests/test_worker_heartbeat.py` and the worker files are unchanged.
- [ ] AC10 — Mutations (OPS-H6 procedure, design condition 6): (a) unconditional `commit` after a failed DLQ write, (b) bare `flush` (regression check of OPS-H8's guard),
  (c) `time.sleep` in the handler wait → each turns at least one named test red in CI. Each mutation is its own commit plus a revert, with a finished run each. SHAs and run URLs go in Notes. The final head is green.
- [ ] AC11 — M4 (`tests/test_m4_chaos.py`) green on the PR's `stack.yml` run (URL + M4 log lines; red only on the known F1 step is acceptable).
- [ ] AC12 — ≤ 400 changed lines in total. Record a counted skeleton in Notes before the full test bodies (expected about 325). No size exception. If the projection is > 400,
  stop and report before writing more. The **named seam** is AC7 (poison decode + its tests) into OPS-H8c. The PR body lists the behaviour changes (design condition 5, items 2–4 and
  "while the DLQ is unreachable the worker stalls with one CRITICAL line per round", replacing OPS-H8's interim exit; the handler warning now logs the exception type only).
  The final sequence (design §7) goes in Notes for pm-lead's Technical PRD §8.1/§8.2 docs PR.

## Verification
```bash
make test-unit
make lint
python -m pytest -v tests/test_kafka_client.py
pytest -q tests/test_worker_heartbeat.py
grep -n "time.sleep" services/common/kafka_client.py   # must print nothing
git diff --stat origin/main...HEAD                     # <= 400
# AC11: stack.yml on the PR (make test-full includes tests/test_m4_chaos.py)
```

## Notes
- 2026-11-07 (pm-lead): created by the OPS-H8 split decision (option A, split by layer; see `docs/design/OPS-H8.md` PM decision addendum and `agents/tasks/OPS-H8.md` Notes).
  Measured starting point from the developer's build: consumer layer about 100 prod + about 225 test lines. Until this merges, Technical PRD §8.1 L4 holds for the Python
  consumer only via OPS-H8's crash-restart interim, so the PRD caveat removal (pm-lead docs PR) waits for this ticket.
- 2026-11-07 (pm-lead, OPS-H8 part-a final review): carried over from QA OPS-H8 r1 (finding 4 and "missing tests"). Add these to `tests/test_kafka_client.py` alongside this ticket's ACs:
  (1) `test_publish_requires_confirmation[ok]` asserts that the return value **equals** the produced envelope's `event_id`, not just that it's truthy; (2) `produce` raising `KafkaException` → `DeliveryError`
  (only `BufferError` is covered today); (3) the DLQ `produce` raising, driven through `start`, gives no commit. Also, the `ci.yml` step from part a is named "(commit-after-process, DLQ, shutdown; fakes only)".
  Part a has no shutdown tests, so this ticket's stop/signal tests make the name true; if they're cut, rename the step.
- 2026-11-08 (backend-engineer, build): branch `agent/backend/OPS-H8b` from `origin/main` `d3f9408` (OPS-H8 part a merged as `db6f670`), head **`f357f15`**, pushed; PR not opened yet (orchestrator).
  - **Source:** `services/common/kafka_client.py` = `git checkout ebe80a7 -- …`. Reconcile result: part a's producer layer on `main` is byte-identical to `ebe80a7`'s, so the file diff vs `main` is exactly the
    consumer layer plus `build_dlq_payload` totality (non-dict JSON → `raw_value`, key `decode(errors="replace")`). That totality lives in the producer class but is in scope here: AC7's `b"[1, 2]"` row needs it
    and design §2 relies on it. `tests/test_kafka_client.py` keeps every part-a test and fake; consumer tests ported from `ebe80a7` onto part a's names.
  - **AC12 counted skeleton** (recorded before the test bodies): `kafka_client.py` done = 96 (+73/−23); test file = imports +6, fakes/`make`/`handler_failing` ≈ +40/−20, 15 named test functions ≈ +150 → projected ≈ 310.
    **Actual `git diff --stat origin/main`: 2 files, +255/−65 = 320** (`kafka_client.py` 96, `tests/test_kafka_client.py` 224). No seam needed; AC7 stays in.
  - **AC3 replaced expectation:** part a's `test_unconfirmed_dlq_write_stops_before_commit` keeps its name and its no-commit assertion (`commits == [("commit", 4)]`, `calls == {4: 1, 5: 3}`, `close` last);
    `pytest.raises(DeliveryError)` became "returns normally after 3 in-place DLQ rounds" (`waits == [0.2, 0.4, 1, 2, 4]`, 3 produces for @5). Rows `err`, `queued`, plus `raise` and `raise-kafka` (carry-over 3).
  - **Carry-overs from the part-a review:** (1) `test_publish_requires_confirmation[ok]` asserts the return value equals the produced envelope's `event_id`; (2) new row `raise-kafka` (`produce` raises `KafkaException` → `DeliveryError`);
    (3) `test_unconfirmed_dlq_write_stops_before_commit[raise|raise-kafka]` drives a raising DLQ `produce` through `start` → no commit. The `ci.yml` step name ("…shutdown; fakes only") is now true (stop/signal tests present), so no rename.
  - **AC → tests:** AC1 `test_success_path[0|1|2]`, `test_commit_error_is_logged_and_loop_continues` · AC2 `test_confirmed_dlq_write_then_commit[header|envelope]` (call order asserted; `envelope` row = traceparent fallback) ·
    AC3 `test_unconfirmed_dlq_write_stops_before_commit[err|queued|raise|raise-kafka]` · AC4 `test_dlq_recovers_after_two_failures`, `test_dlq_backoff_schedule` · AC5 `test_failing_publish_in_handler_is_retried[ok|err]` ·
    AC6 `test_stop_during_wait_returns_promptly[handler-wait|dlq-wait]` (real `threading.Event`, 5 s backoff, < 200 ms), AC6b `test_stop_during_last_attempt_is_not_a_failure[3|1]`, `test_signal_handler_sets_stop_and_is_restored`;
    `grep -n "time.sleep" services/common/kafka_client.py` → no output (rc 1) · AC7 `test_poison_record_goes_to_dlq_and_loop_continues[not json|missing fields|[1, 2]]` · AC8 `test_dlq_failure_log_has_coordinates_not_value[False|True]` (sentinel in value and handler error).
  - **Local runs (sandbox):** PyPI unreachable (DNS for pypi.org fails; `pip install confluent-kafka` → "No matching distribution"), so `confluent_kafka` and `ulid` were stubbed in a scratch `PYTHONPATH` dir (pydantic 2.13.5 real), pytest run from a different cwd:
    `pytest -v tests/test_kafka_client.py tests/test_worker_heartbeat.py` → **43 passed** (37 + 6). `ruff check --isolated --select E,F,W --line-length 130` on both files → clean. `make lint` is Go + frontend only (no Python linter in the Makefile); Go untouched. `make test-unit`/`make test-py` not run locally (BGE download, no deps): CI.
  - **AC10 pre-check (local, stubbed, scratch copies, not the CI evidence):** (a) commit after a failed DLQ write → 6 red (`test_unconfirmed_dlq_write_stops_before_commit[*]`, `test_failing_publish_in_handler_is_retried[err]`, `test_stop_during_wait_returns_promptly[dlq-wait]`);
    (b) bare `flush` (drop both confirmation checks) → 12 red (incl. `test_publish_requires_confirmation[err|queued]`, `test_dlq_recovers_after_two_failures`); (c) `time.sleep` in the handler wait → 11 red (incl. `test_success_path[1|2]`, `test_stop_during_wait_returns_promptly[handler-wait]`).
    Extra probe: handler-path DLQ traceparent reverted to header-only → `test_confirmed_dlq_write_then_commit[envelope]` red.
    **Still to do (needs the PR, `ci.yml` runs on `pull_request` only):** the three `mutation(AC10a|b|c)` commits + reverts with a finished CI run each, SHAs/URLs here; AC11 `stack.yml` M4 run on the PR.
  - **PR body, "Behaviour changes" (condition 5):** (2) a commit `KafkaException` is logged at ERROR and the loop continues (was: worker dies); (3) poison records → DLQ with `attempts=1`, committed (was: crash loop);
    (4) first SIGTERM/SIGINT finishes the running handler call and stops cleanly, second forces the stop; while the DLQ is unreachable the worker stalls on that record with one CRITICAL line per round
    (replaces OPS-H8's interim exit/restart); the handler warning now logs the exception type only; DLQ `traceparent` falls back to the envelope's own.
  - **Final sequence (design §7, for pm-lead's Technical PRD §8.1/§8.2 docs PR):**
    ```
    poll (1 record) → decode
      undecodable → DLQ path with attempts=1
      attempt 1..3: handle; on error, if stop requested → stop (no DLQ, no commit); else wait 0.2 s, 0.4 s (interruptible)
      success → commit (commit error → log ERROR; record redelivered later)
      3 failures → build DLQPayload once → produce to <topic>.dlq, confirmed by delivery callback within 12 s
         confirmed → commit
         not confirmed → CRITICAL log, wait 1,2,4…30 s (interruptible) and send again; no commit, no next record, until it lands or stop
    SIGTERM/SIGINT → finish the running handler call, commit only if it resolved, close. Second signal → force stop, no commit.
    On restart/rebalance everything after the last committed offset is redelivered; L2 (processor) and L3 (embedder) keep row counts unchanged.
    ```
