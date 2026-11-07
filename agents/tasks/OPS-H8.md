# OPS-H8: Python consumer commits an offset only after success or a confirmed DLQ write; interruptible retry waits

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (silent message loss in the processor and embedder stages) |
| **PRD ref** | Product PRD OPS-1, OPS-3, §5.3; Technical PRD §8.1 (L4 commit-after-process: "All consumers"), §8.2 (retry and DLQ) |
| **Depends on** | OPS-H6 (Done, ArxivLens #15 → `e9be32e`; its approved design `docs/design/OPS-H6.md` defines the semantics to mirror); **OPS-H1 (ArxivLens #14) merged**: #14 adds a worker heartbeat hook (`_heartbeat`, about 16 lines) to `services/common/kafka_client.py`, the file this task rewrites (AGENTS.md §3 independence). The design must keep that hook (touch after every `poll()` while assigned; no-op when `WORKER_HEARTBEAT_FILE` is unset) |
| **Jira** | KAN-34 (`labels = "task-OPS-H8"`) |
| **Design required** | **yes**: P0, and it changes the pipeline's delivery semantics for both Python workers |
| **Status** | In Progress: built at `ebe80a7` (branch `agent/backend/OPS-H8` pushed), PR pending. **On hold (design condition 2): 487 changed lines > 400, and still 462 without §5, so the OPS-H8b seam doesn't fix it. Needs pm-lead's split decision before the PR is opened** (see Notes 2026-11-07 build) |

## Goal
Technical PRD §8.1 promises L4 for **all** consumers: the offset is committed only after the handler succeeds or the
message is in the DLQ. OPS-H6 fixed the Go consumer. The Python consumer used by the processor (`papers.downloaded`)
and the embedder (`papers.chunked`) still breaks it. At `origin/main` `8b0a2d2`, `services/common/kafka_client.py`:

- `ServiceKafkaProducer.publish_dlq` (`:64-116`) calls `produce` then `flush(timeout=5)` and ignores both the return
  value of `flush` (number of messages still queued) and any per-message delivery error (no `on_delivery` callback).
  `ServiceKafkaConsumer.start` (`:186-199`) then calls `commit` unconditionally. If the DLQ write didn't land, the paper
  is in neither the topic nor the DLQ: an operator (Product PRD §5.3) never finds it.
- `ServiceKafkaProducer.publish` (`:26-62`) has the same unchecked `flush`. The processor publishes `papers.chunked` from
  inside its handler (`services/processor/worker.py:98`), so an undelivered event is reported as success and the offset is
  committed: the paper stays `chunked` forever and is never embedded.
- Handler retry waits are `time.sleep(0.1 * 2**attempt)` (`:183`), so shutdown sits out the backoff.
- An undecodable record (`json.loads` / `EventEnvelope(**…)` at `:163-164`, outside the retry `try`) raises out of the
  loop, closes the consumer and kills the worker; on restart the same record kills it again (poison-pill crash loop),
  and it never reaches the DLQ.

Make the Python consumer keep the same promise as the Go one, so the pipeline is at-least-once end to end.

## Scope
- Files: `services/common/kafka_client.py`; new `tests/test_kafka_client.py` (fakes only, no broker);
  `.github/workflows/ci.yml`: one added step in the `python` job that runs `python -m pytest -v tests/test_kafka_client.py`
  (so CI runs the new tests without touching `Makefile`).
- Small seams are fine if the tests need them: injectable `Producer`/`Consumer` objects (constructor parameters with the
  current defaults), an injectable wait function, and a stop flag (e.g. `threading.Event`) that a SIGTERM/SIGINT handler
  or the test can set. Worker call sites (`services/processor/worker.py`, `services/embedder/worker.py`) must keep working
  unchanged; if a worker needs one line to install the signal handler, list it in the design and ask (the embedder worker
  is ai-owned, so prefer doing it inside `ServiceKafkaConsumer.start`).
- **Not in scope / do not touch** (open PRs edit them): `Makefile`, `docker-compose.yml`, `.github/workflows/stack.yml`,
  `services/*/Dockerfile` (#14); `.github/workflows/db.yml`, `cmd/`, `internal/`, `migrations/` (#16);
  `README.md`, `CONTRIBUTING.md` (#14 and #16). README:39 already describes the intended behaviour ("retries 3×, then routes to
  `<topic>.dlq`"), so no doc edit is needed; if the design finds one, put the wording in Notes as a follow-up.
- Out of scope: the Go consumer (OPS-H6, done; its shutdown poll-error log nit stays in Backlog), DLQ list/replay (OPS-H7),
  changing the 3-attempt count or the 200/400 ms handler schedule, `shared/events/*` (shared contract; `DLQPayload` fields
  stay as they are), the idempotency layers in `services/common/db.py` (OPS-H6 G1/G2 follow-ups).

## Design must answer (in `docs/design/OPS-H8.md`)
1. **How a delivery is confirmed** with confluent-kafka: `flush()`'s return value alone isn't enough (a message can fail
   with a delivery error and still leave the queue). Say how `publish_dlq` and `publish` learn the per-message outcome
   (delivery callback / `on_delivery`, then `flush` or `poll` until the callback ran or a timeout), and what they raise.
2. **Mechanism after the DLQ write fails.** Mirror OPS-H6 §1 (retry the DLQ write in place with a capped backoff,
   `min(1 s << (round-1), 30 s)`, handler not re-run, one `CRITICAL` log per round, no commit until it lands) or justify a
   different choice. Build the `DLQPayload` once (the stack trace must be the handler's, not a later one).
3. **`max.poll.interval.ms = 300000`.** While retrying in place the loop doesn't call `poll()`. Say what happens after
   5 minutes (the member leaves the group, the partition is reassigned, `commit` fails), confirm that this cannot lose the
   record, and say whether `commit` errors are raised or logged. No swallowed commit error may be followed by moving on as if committed.
4. **Shutdown.** How SIGTERM (Docker stop) and SIGINT interrupt a handler-retry wait or a DLQ-round wait promptly, with no
   commit and no DLQ write for the interrupted record, and the consumer closed. A handler that fails *because* shutdown was
   requested on its last attempt is not a processing failure (OPS-H6 AC6b).
5. **Poison records.** A record whose value isn't valid JSON or doesn't build an `EventEnvelope` goes to `<topic>.dlq`
   (with `original_value = {"raw_value": …}` as `publish_dlq` already does) after the same rules, then is committed. Say
   whether it gets 3 attempts or 1 (decoding is deterministic) and why.
6. **Redelivery against the idempotency layers.** Confirm the chain for a record redelivered after a failed `publish`
   (processor: L2 ledger already recorded → "Duplicate event … proceeding to re-emit downstream", `worker.py:84-90`, so
   `papers.chunked` is re-sent; embedder: L3 model join skips compute and re-marks `embedded`). Name any gap as a follow-up.
7. Test plan: one named test per AC, fakes only.

## Acceptance criteria
- [ ] AC1 — Success path unchanged: handler succeeds on attempt 1, or after 1–2 failures → exactly one commit for the
  record, no DLQ produce. (Fake consumer + fake producer.)
- [ ] AC2 — DLQ path: handler fails 3× → exactly one DLQ message to `<topic>.dlq` with `original_topic`, `partition`,
  `offset`, `attempts = 3`, `consumer_group`, `traceparent` from the record; the commit happens **only after** the fake
  reports the DLQ delivery as successful (test asserts call order).
- [ ] AC3 — **DLQ delivery fails → no commit.** Feed `[p0@5 fails, p0@6 ok]`; the fake producer reports a delivery error
  (and, in a second case, leaves the message undelivered: `flush` returns 1) for every DLQ write; stop after a few rounds.
  Assert: no commit for @5 or @6, the DLQ write for @5 retried in place (≥ 2 produce calls for @5), handler for @5 called
  exactly 3×, handler for @6 never called, `start` returns normally and closes the consumer. Records before @5 in the same
  run are still committed.
- [ ] AC4 — Recovery: the DLQ write fails twice then succeeds → exactly one successful DLQ message and one commit, with an
  (injected) wait between rounds; the test asserts the wait durations `[1 s, 2 s]` and that handler calls stay at 3.
- [ ] AC5 — `publish` raises when the message isn't confirmed delivered (delivery error or still queued after the timeout);
  a processor-style handler that calls `publish` therefore fails and is retried, and its record is never committed while
  `publish` keeps failing. Tested at the `ServiceKafkaProducer` level and through `start`.
- [ ] AC6 — Interruptible waits: with a ≥ 5 s backoff injected and the stop flag set during the first handler-retry wait,
  `start` returns within 200 ms with no commit and no DLQ write; same for a DLQ-round wait. **AC6b:** stop requested while
  the handler runs its last attempt and it then raises → no DLQ write, no commit. `grep -n "time.sleep" services/common/kafka_client.py` is empty.
- [ ] AC7 — Poison record: a record with value `b"not json"` (and one with valid JSON missing envelope fields) ends with one DLQ
  message containing `raw_value` (or the decoded dict) and one commit; the loop keeps consuming the next record (no crash).
- [ ] AC8 — Logs on a failed DLQ write include topic, partition, offset, DLQ topic, round and the error, but never the record value
  (test with `caplog` and a value containing a marker string).
- [ ] AC9 — No regressions: `make test-py` (M0 + eval-data) and the new `tests/test_kafka_client.py` CI step are green;
  `tests/test_m4_chaos.py`'s direct `worker.producer.publish_dlq(..., original_msg=None, ...)` call keeps its signature and
  return contract (returns on success, raises only on a failed delivery).
- [ ] AC10 — Mutation check (QA, same method as OPS-H6 AC10): (a) re-adding the unconditional `commit` after a failed DLQ
  write, (b) ignoring the delivery result in `publish_dlq` (back to bare `flush`), (c) reverting to `time.sleep`, each make at
  least one named test fail in CI. The developer pushes each mutation as its own commit and a revert, waits for each CI run,
  and lists the SHAs and run URLs in Notes; the final head is green.
- [ ] AC11 — M4 (`tests/test_m4_chaos.py`) on the full stack, **delivered in this PR** (amended 2026-11-07 by pm-lead design review; OPS-H1 is merged
  and `stack.yml` triggers on `services/common/**`). Evidence: the PR's `stack.yml` run URL plus its log lines showing the M4 tests passing. A run red only on
  the known F1 step is acceptable if the M4 lines are green; an M4 failure fails QA.
- [ ] AC12 — Diff ≤ 400 changed lines in total (code + tests + CI step). Before writing the full test file, record a counted skeleton in Notes. **Split seam
  (pm-lead, design review):** if the projection is > 400, move design §5 (poison-record decode) + AC7 into follow-up **OPS-H8b** (backend, P0, same design); don't trim
  AC1–AC6/AC8–AC10 tests. No size exception in advance. Docs: Technical PRD §8.1/§8.2 caveat removal is a pm-lead docs PR;
  put the final sequence (when the Python consumer commits, what is redelivered) in this ticket's Notes.

## Verification
```bash
make test-unit                                   # CI (Go + M0 + eval data); Go 1.25 not available locally
make lint
python -m pytest -v tests/test_kafka_client.py   # new; also runs as its own step in ci.yml (python job)
grep -n "time.sleep" services/common/kafka_client.py   # must print nothing
# AC11: make stack-up && make migrate && pytest -q tests/test_m4_chaos.py   (after OPS-H1 merges; via stack.yml)
```

## Notes
- Independence (2026-11-03 21:02Z): no file overlap with open PRs #14 (compose/Makefile/stack.yml/Dockerfiles/README/CONTRIBUTING),
  #16 (db.yml/cmd/internal/migrations/README/CONTRIBUTING), #17 (`scripts/evaluate_retrieval.py`, `tests/test_evals_data.py`,
  `evals/README.md`), #18 (`internal/query/rag.go`, `rag_test.go`). `ci.yml` is in none of them.
- Follow-up after OPS-H1 merges (backend, P2): add `tests/test_kafka_client.py` to `make test-py` (Makefile) and drop the separate CI step if redundant.
- 2026-11-07 (pm-lead, plan): OPS-H1 merged (`71cb609`). The heartbeat hook is on `main`, so the design must keep it (Depends on). AC11 (M4 on the
  full stack) is now runnable through `stack.yml` on the PR. Deliver it in this PR instead of deferring it. Wave 2 for WIP reasons only
  (backend runs LLM-1 + EVAL-3 first: both unblock other tasks). If Mahesh wants the P0 data-loss fix first, swap it with EVAL-3.
- 2026-11-07 (backend-engineer, design): design written at `docs/design/OPS-H8.md`, grounded in `origin/main` `71cb609`. **Design stage only, no product code.**
  Sequencing: this ticket's scope adds one step to `.github/workflows/ci.yml`, and open PR #23 (LLM-1) also changes `ci.yml`, so the build branch
  `agent/backend/OPS-H8` is cut from a fresh `origin/main` only **after #23 merges** (AGENTS.md §3). Putting the test in `make test-py` instead doesn't help,
  because `Makefile` is in open PR #22 (EVAL-3). No other open PR touches `services/common/`, the workers or `tests/test_kafka_client.py`.
  - Mechanism: confirmation by `on_delivery` callback served in `flush`; no callback = not delivered; raises `DeliveryError`. Failed DLQ write → retry in place
    `min(1 s << (round-1), 30 s)`, payload built once, no commit. Stop flag + SIGTERM/SIGINT installed inside `start` (no worker edits). Poison → DLQ with attempts=1.
    Commit errors logged, not raised (safe: sequential per-record commits). Heartbeat hook unchanged; `tests/test_worker_heartbeat.py` monkeypatch seams kept.
  - Found while reading: `publish_dlq` calls `traceback.format_exc()` (`kafka_client.py:100`) after the `except` block ended, so consumer-path DLQ entries carry
    `"NoneType: None"` as the stack trace today. Fixed in the design (`format_exception(error)`).
  - AC11: `stack.yml` triggers on `services/common/**`, so M4 runs on the PR itself (matches the 2026-11-07 pm-lead note).
  - Open questions for pm-lead/Mahesh: design §"Open questions" 1–6 (commit-error policy, `message.timeout.ms=10000`, poison `attempts=1`, SIGINT semantics,
    DLQ traceparent fallback, file G5/G4).
  - Jira KAN-34 → Design and the design link: not done from this session (no Jira tool available to the backend agent here); orchestrator to mirror.
- 2026-11-07 10:19Z (pm-lead, design review): **APPROVED with conditions** (design `docs/design/OPS-H8.md` "PM decision"). Open questions 1–6 all decided by pm-lead,
  none needs Mahesh/ADR (no shared contract change): commit errors logged (KafkaException only); `message.timeout.ms=10000` + 12 s bound as named constants with a bound
  test; poison `attempts=1`; first signal graceful, second forces; DLQ traceparent falls back to the envelope; G5, G4 and a compose `stop_grace_period` item go to the
  board Backlog. Conditions: (1) build starts only after #23 merges; recheck open-PR overlap at start; keep the `ci.yml` step even if #22 has merged; (2) counted
  skeleton + OPS-H8b split seam (AC12 amended); (3) AC11 delivered in this PR via `stack.yml` (AC11 amended); (4) delivery-bound test; (5) PR body lists the
  behaviour changes for Mahesh; (6) AC10 mutation procedure as OPS-H6; (7) `tests/test_worker_heartbeat.py` and worker call sites unchanged.
- 2026-11-07 11:00Z (pm-lead, grooming): #23 (LLM-1, `ci.yml`) merged as `43713ce`, so the build wait is over. Not picked this cycle: the two backend slots went to LLM-1b (P0, unblocks QA-8) and OPS-H10 (unblocks AI-9's open PR), per unblocks-others > P0. First in line for the next free backend slot. Cut the branch from a fresh `origin/main`.
- 2026-11-07 (backend-engineer, build): built on `agent/backend/OPS-H8` from `origin/main` `2b71772`, head **`ebe80a7`** (pushed; **no PR opened**).
  **Stopped by binding condition 2 (size):** the counted total is over 400 with and without the OPS-H8b seam, so I'm reporting here instead of opening the PR.
  - Open-PR recheck at build start (condition 1): #24 `services/embedder/api.py`, `tests/test_m0.py`; #26 `stack.yml`, README, CONTRIBUTING; #27 `internal/llm/*`; #28 `internal/query/rag*.go`.
    None of them touches `services/common/`, `ci.yml`, `tests/test_kafka_client.py` or the worker files.
  - **Counted skeleton (condition 2, recorded before the test bodies):** `kafka_client.py` done = 174 (125+/49-); test file with fakes + 17 stubbed functions = 140;
    `ci.yml` = 2. That's 316 before any test body. Full test file = 311, so the total is **487** (`git diff --stat origin/main...ebe80a7`: 3 files, 438+, 49-; ownership-check warns at > 400).
    **Seam projection** (scratch copy, §5 decode `try` reverted to the original 2 lines, AC7 test removed): `kafka_client.py` 164 (117+/47-), tests 296, ci 2, so **462 > 400**.
    Per condition 2 ("still > 400 without §5 → stop and report"), I stopped. I didn't trim any AC test.
    The design estimate (~120 prod + ~250 tests) ran low on both: prod 174 (the build/send split, the signal install/restore, and the 15-line old DLQ call deleted), tests 311 (fakes ~120).
  - **Options for pm-lead** (your call, I haven't done either):
    (A) **Split by layer.** OPS-H8 = producer confirmation only (`DeliveryError`, `_produce_confirmed`, constants, `publish`/`publish_dlq` raise, `build_dlq_payload`/`send_dlq`, trace fix)
    plus AC5 (producer level), AC9 and the bound test, about 75 prod + about 90 tests, under 200. This alone closes the silent loss: an unconfirmed DLQ write raises out of `start` before
    `commit`, so the record is redelivered (the worker crash-restarts while the DLQ is down, which is design alt. 2, interim only).
    OPS-H8b = the consumer loop (in-place DLQ retry, commit gating/logging, stop flag + signals, poison) plus AC1–AC4, AC5-through-`start`, AC6/6b, AC7, AC8, AC10, AC11, about 100 prod + about 225 tests, about 325.
    (B) A one-off size exception for 487 (condition 2 says none is granted in advance, so this is your decision, not mine).
  - **Built (all in `ebe80a7`):** design §1 (`on_delivery` confirmation, `MESSAGE_TIMEOUT_MS = 10000` / `DELIVERY_TIMEOUT_S = 12.0` as named constants, `publish`/`publish_dlq`
    raise `DeliveryError`), §2 (payload built once, DLQ write retried in place `min(1 << (round-1), 30)` s, one CRITICAL line per round), §3 (only `KafkaException` from `commit` is logged),
    §4 (`threading.Event` stop flag; SIGTERM/SIGINT installed in `start` on the main thread and restored in `finally`; second signal → `KeyboardInterrupt`; AC6b), §5 (poison → DLQ `attempts=1`), §7 (DLQ traceparent falls back to the envelope).
    Shape change from design §7: per lesson OPS-H6 (re-indent doubles the diff), the retry body stays inline in `start` at its original indentation (`stopped` flag) rather than in a `_process` method.
    `_dead_letter`, `_commit`, `_coords` and `stop` are as designed.
    One addition the design implied (AC8: "the handler error contains the sentinel; no log contains it"): the per-attempt handler warning now logs `type(e).__name__` instead of `str(e)`.
    The full message stays in the DLQ payload. This is an operator-visible change and goes in the PR body (item 5 below).
  - **Commands + output (sandbox; CI not run, because no PR exists and `ci.yml` runs only on `pull_request`/push to main):**
    - PyPI is blocked by the egress proxy (`pypi.org:443 connect_rejected`), so `confluent-kafka` and `ulid-py` couldn't be installed. Tests ran against a **local stub** `confluent_kafka`/`ulid`
      (scratchpad, not committed: `KafkaException`, `KafkaError._PARTITION_EOF`, `Message`, `Producer`, `Consumer`). Real-library import compatibility is **unverified until CI**.
    - `PYTHONPATH=<stub> python3 -m pytest -v tests/test_kafka_client.py` (Python 3.13): **29 passed in 0.20s**.
    - `pytest -q tests/test_worker_heartbeat.py` (unmodified): **6 passed**.
    - `grep -n "time.sleep" services/common/kafka_client.py`: no output (rc 1).
    - `.github/scripts/ownership-check.sh origin/main agent/backend/OPS-H8`: `Ownership OK for role=backend (487 changed lines)` + `::warning::487 changed lines (> 400)`.
    - Local mutation smoke (scratch, not pushed): (a) unconditional DLQ-then-commit gives 4 failed; (b) `_produce_confirmed` ignores the callback outcome gives 11 failed; (c) `time.sleep` in the handler wait gives 8 failed.
      The AC10 CI procedure (commit, revert, a finished run each) needs the PR, so it's **not done**.
    - Not run: `make test-unit` / `make test-py` (no BGE/torch here), `make lint` (Go 1.25 unavailable; there's no Python linter in the harness), M4/`stack.yml` (AC11, needs the PR).
  - **ACs (local evidence only):** AC1 `test_success_path`[0/1/2] + `test_commit_error_is_logged_and_loop_continues` pass. AC2 `test_dlq_then_commit` pass. AC3 `test_dlq_failure_blocks_and_never_commits`[err/queued] pass.
    AC4 `test_dlq_recovers_after_two_failures` + `test_dlq_backoff_schedule` pass. AC5 `test_publish_requires_confirmation`[ok/err/queued/raise] + `test_failing_publish_in_handler_is_retried_not_committed`[ok/err] pass.
    AC6 `test_stop_during_wait_returns_promptly`[handler-wait/dlq-wait] (real `Event.wait`, 5 s backoff, < 0.2 s) pass, grep empty. AC6b `test_stop_during_last_attempt_is_not_a_failure`[3/1] pass.
    AC7 `test_poison_record_goes_to_dlq_and_loop_continues`[not json / missing fields / list] pass. AC8 `test_dlq_failure_log_has_coordinates_not_value`[handler/poison] pass.
    AC9 `test_publish_dlq_direct_call_contract`[ok/err] + `test_build_dlq_payload_is_total` pass, heartbeat suite unmodified and green; `make test-py` not run. **AC10, AC11: not done (need the PR). AC12: FAIL (487).**
  - **Binding conditions:** 1 met (built after #23; overlap rechecked; ci.yml step kept). 2 **triggered: stop** (counts above). 3 pending the PR. 4 met (`test_delivery_bound_outlasts_message_timeout`).
    5 text ready (below). 6 pending the PR (local smoke only). 7 met (`tests/test_worker_heartbeat.py` and both worker files unchanged; embedder untouched).
  - **PR body, "Behaviour changes (decided by pm-lead in design review)":**
    1. `ServiceKafkaProducer.publish` and `publish_dlq` raise `DeliveryError` when the broker hasn't confirmed delivery within 12 s (`message.timeout.ms = 10000`). Before, they returned silently.
       The processor's handler therefore fails and is retried when `papers.chunked` isn't delivered.
    2. A `KafkaException` from `commit` is logged (`Commit failed (topic=… partition=… offset=…): …; the record will be redelivered`) and the loop continues. Before, it killed the worker.
    3. An undecodable record (not JSON, or not a valid `EventEnvelope`) goes to `<topic>.dlq` with `attempts = 1` and is committed. Before, it crash-looped the worker. Tell poison records apart by `error_type`.
    4. The first SIGTERM/SIGINT finishes the running handler call, commits only if that record resolved, and exits. A second signal forces the stop with no commit.
       While the DLQ is unreachable the worker stalls on that record with one CRITICAL line per round (1, 2, 4 … 30 s) and commits nothing after it.
    5. Also: DLQ `stack_trace` is now the handler's real traceback (it was `NoneType: None` on the consumer path). The per-attempt handler warning logs the exception type only (the message stays in the DLQ payload), so record values don't leak into logs.
  - **Final sequence** (for pm-lead's Technical PRD §8.1/§8.2 docs PR): as in design §7 "Final sequence", unchanged by the build.
  - Unverified: the real `confluent_kafka` import/behaviour (CI), `make test-py`, AC10 CI runs, AC11 M4 on `stack.yml`. Jira KAN-34 isn't touched from this session (orchestrator mirrors).
