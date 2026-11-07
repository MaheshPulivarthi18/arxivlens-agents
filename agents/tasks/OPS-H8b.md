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
