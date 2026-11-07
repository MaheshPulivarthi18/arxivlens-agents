# OPS-H8 (part a): Python producer confirms delivery; no offset is committed past an unconfirmed DLQ write

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (silent message loss in the processor and embedder stages) |
| **PRD ref** | Product PRD OPS-1, OPS-3, §5.3; Technical PRD §8.1 (L4 commit-after-process: "All consumers"), §8.2 (retry and DLQ) |
| **Depends on** | OPS-H6 (Done, ArxivLens #15 → `e9be32e`; its approved design `docs/design/OPS-H6.md` defines the semantics to mirror); **OPS-H1 (ArxivLens #14) merged**: #14 adds a worker heartbeat hook (`_heartbeat`, about 16 lines) to `services/common/kafka_client.py`, the file this task rewrites (AGENTS.md §3 independence). The design must keep that hook (touch after every `poll()` while assigned; no-op when `WORKER_HEARTBEAT_FILE` is unset) |
| **Jira** | KAN-34 (`labels = "task-OPS-H8"`) |
| **Design required** | **yes**: P0, and it changes the pipeline's delivery semantics for both Python workers |
| **Status** | In Progress (rework to the part-a subset; pm-lead split decision 2026-11-07, option A). Branch `agent/backend/OPS-H8` (full build at `ebe80a7`, kept in history for OPS-H8b); PR not yet opened |

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

**Split (pm-lead, 2026-11-07, option A from the build note; design `docs/design/OPS-H8.md` "PM decision" addendum).** The full build was
487 changed lines, and the pre-named §5 seam only got it to 462. The work is now split at the layer boundary:
- **OPS-H8 (this ticket, part a): the producer layer.** `publish` and `publish_dlq` raise `DeliveryError` unless the broker confirms delivery.
  The consumer loop is **not** restructured. Because the existing `start` calls `publish_dlq` before `commit` and doesn't catch its exception, an
  unconfirmed DLQ write now leaves `start` (consumer closed in `finally`) **before** the commit. The record is redelivered after the restart
  (compose `restart: unless-stopped`). An unconfirmed `papers.chunked` publish fails the processor handler, which is retried and then DLQ'd.
  Both silent-loss paths in the Goal (bullets 1 and 2) are closed. **Accepted interim behaviour** until OPS-H8b merges: while the DLQ is
  unreachable, the worker exits and restarts, and the handler runs 3 more times per restart (design alt. 2). That costs time, never a record.
- **[OPS-H8b](OPS-H8b.md): the consumer layer.** In-place DLQ retry (which replaces the interim exit), commit-error logging, stop flag and signals,
  interruptible waits (no `time.sleep`), poison records, log hygiene, DLQ `traceparent` envelope fallback.
  Bullets 3 and 4 of the Goal are OPS-H8b's.

## Scope
- Files: `services/common/kafka_client.py` (**producer layer only**: `DeliveryError`, `MESSAGE_TIMEOUT_MS` / `DELIVERY_TIMEOUT_S` named constants,
  `message.timeout.ms` in the producer config, `_produce_confirmed` (`on_delivery` callback, then `flush` until it ran or the bound expires),
  `publish` / `publish_dlq` raising `DeliveryError`, `build_dlq_payload` / `send_dlq` with `publish_dlq` = build + send, an injectable
  `producer=` parameter on `ServiceKafkaProducer`, and the stack-trace fix `traceback.format_exception(error)` in place of `format_exc()`).
  The `ServiceKafkaConsumer` class may only gain the injectable `consumer=` / `producer=` constructor parameters (defaults = today's calls)
  that the AC5 test needs. **Its `start` loop is unchanged** (same lines as `origin/main`, including `time.sleep`, the decode, and the
  unconditional `commit` after `publish_dlq`).
- New `tests/test_kafka_client.py` (fakes only, no broker), holding only the part-a tests below. OPS-H8b extends the same file.
- `.github/workflows/ci.yml`: one added step in the `python` job, `python -m pytest -v tests/test_kafka_client.py` (kept even though #22 may merge first; design condition 1).
- **Not in scope (OPS-H8b):** anything in `ServiceKafkaConsumer.start` / `_heartbeat`, the in-place DLQ retry, `_dead_letter`, `_commit`, `stop`,
  signal handlers, removing `time.sleep`, poison-record decoding, the per-attempt handler warning text, the DLQ `traceparent` fallback.
- **Not in scope (unchanged):** worker files (`services/processor/worker.py`, `services/embedder/worker.py`), `tests/test_worker_heartbeat.py`,
  `Makefile`, `docker-compose.yml`, `shared/events/*` (`DLQPayload` fields stay the same), `services/common/db.py`, the Go consumer, `README.md`, `CONTRIBUTING.md`.

## Design must answer (in `docs/design/OPS-H8.md`)
Answered. Design approved 2026-11-07 10:19Z with conditions. The split addendum maps §1 (and the §2 build-once trace fix) to part a and §2–§5 to OPS-H8b. No new design round.

## Acceptance criteria
Renumbered for part a. The old ACs moved as follows: old AC5 (producer level), AC9 and condition 4 stay here; old AC1–AC4, AC5-through-the-final-loop,
AC6/6b, AC7, AC8 and AC10a/c are in OPS-H8b. No AC was dropped or weakened. Where part a tests a narrower interim behaviour, OPS-H8b's ACs replace it.
- [ ] AC1 — `publish` requires confirmation: `test_publish_requires_confirmation` (parametrised): delivery callback `ok` → returns the event id;
  callback reports a delivery error (`flush` returns 0), message still queued (`flush` returns 1, no callback) and `produce` raising `BufferError`
  → `DeliveryError` each. The `DeliveryError` message names the topic and the error and does **not** contain the record value (sentinel string in the payload).
- [ ] AC2 — `publish_dlq` contract: `test_publish_dlq_direct_call_contract`: the M4-style call (`original_msg=None`, `attempts=3`, `traceparent`) returns `None`
  on `ok` and raises `DeliveryError` on `err` and on `queued`. The signature is unchanged, and the `original_value or {}` / `dlq_topic.replace(".dlq", "")` fallbacks are
  kept. `test_build_dlq_payload_is_total`: `build_dlq_payload` returns a `DLQPayload` for `original_msg=None`, a non-UTF-8 value, and a missing header.
- [ ] AC3 — Real stack trace: a `DLQPayload` built for an exception raised in a named helper and passed in **after** its `except` block has ended (the consumer-path
  situation) has a `stack_trace` that contains the helper's name and not `NoneType: None`.
- [ ] AC4 — Delivery bound (design condition 4): `MESSAGE_TIMEOUT_MS` and `DELIVERY_TIMEOUT_S` are named module constants with a one-line comment.
  `test_delivery_bound_outlasts_message_timeout` asserts `DELIVERY_TIMEOUT_S > MESSAGE_TIMEOUT_MS / 1000` and that the default producer config passes
  `message.timeout.ms = MESSAGE_TIMEOUT_MS` (monkeypatched `Producer`, as `tests/test_worker_heartbeat.py` does).
- [ ] AC5 — **No commit past an unconfirmed DLQ write (interim, through the unchanged `start`)**: `test_unconfirmed_dlq_write_stops_before_commit`
  (parametrised `err`, `queued`). Script `[p0@4 ok, p0@5 handler always fails, p0@6 ok]`. Assert: `("commit", 4)` present; no commit for 5 or 6; handler@5
  called exactly 3×; handler@6 never called; `start` raises `DeliveryError` (not swallowed); `("close",)` is the last fake-consumer call.
  Plus `test_confirmed_dlq_write_then_commit`: DLQ `ok` → exactly one produce to `papers.downloaded.dlq` with `attempts == 3`, `original_topic`, `partition`, `offset`,
  `consumer_group`, and the logged order is produce @5 → commit 5. Plus `test_failing_publish_in_handler_is_retried`: a processor-style handler calling
  `ServiceKafkaProducer(producer=FakeProducer(all err)).publish` is called 3×, its record is DLQ'd (consumer producer `ok`) and committed only after that.
  Handler retry waits go through the existing `time.sleep`, so patch `kafka_client.time.sleep` in these tests. Don't edit `start` to make it testable.
- [ ] AC6 — No regressions: `make test-py` (M0 + eval-data) and the new `ci.yml` step are green in CI. `tests/test_worker_heartbeat.py` and both worker files are unchanged
  (`git diff --stat origin/main...` lists only the three Scope files). The `git diff origin/main... -- services/common/kafka_client.py` hunks inside `ServiceKafkaConsumer.start` are empty.
- [ ] AC7 — Mutation check (OPS-H6 procedure, design condition 6): (b) `_produce_confirmed` ignores the callback outcome (back to bare `flush`) → AC1/AC2/AC5 `err` rows red;
  (a') `start` wraps `publish_dlq` in `try/except DeliveryError: pass` so it falls through to `commit` → AC5 red. Each mutation is its own commit (`mutation(AC7a|b): …`,
  `kafka_client.py` only, no test edits), followed by `revert mutation(AC7x)`. Wait for each CI run to finish before the next push. SHAs and run URLs go in Notes. The final head is green.
- [ ] AC8 — M4 on the full stack (old AC11): the PR's `stack.yml` run (it triggers on `services/common/**`) shows the `tests/test_m4_chaos.py` tests passing, with a real broker,
  against the new `publish`/`publish_dlq`. Evidence: the run URL plus its M4 log lines. A run red only on the known F1 step is acceptable if the M4 lines are green.
- [ ] AC9 — Size and PR text: the diff is ≤ 400 changed lines in total (`git diff --stat origin/main...` in the PR body; expected about 200). No size exception.
  The PR body has a "Behaviour changes" section: (1) `publish`/`publish_dlq` raise `DeliveryError` when delivery isn't confirmed within `DELIVERY_TIMEOUT_S`
  (`message.timeout.ms = 10000`); before, they returned silently; (2) the DLQ `stack_trace` is the handler's real traceback; (3) **interim:** while the DLQ is unreachable, the worker
  exits without committing and compose restarts it (the handler re-runs 3× per restart) until OPS-H8b replaces this with an in-place retry. Ticket Notes record the
  interim sequence (when the consumer commits and what is redelivered).

## Verification
```bash
make test-unit                                   # CI (Go + M0 + eval data); Go 1.25 not available locally
make lint
python -m pytest -v tests/test_kafka_client.py   # new; also its own step in ci.yml (python job)
pytest -q tests/test_worker_heartbeat.py         # unchanged, green
git diff --stat origin/main...HEAD               # 3 files, <= 400 changed lines
git diff origin/main...HEAD -- services/processor/worker.py services/embedder/worker.py tests/test_worker_heartbeat.py   # empty
# AC8: stack.yml on the PR (make stack-up && make migrate && make test-full, includes tests/test_m4_chaos.py)
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
- 2026-11-07 (pm-lead, split decision): **Option A, split by layer.** No size exception (B). This ticket is now part a (producer confirmation + the interim
  "unconfirmed DLQ write leaves `start` before commit"). The rest is [OPS-H8b](OPS-H8b.md) (P0, depends on this ticket merged, same design). The ACs were rewritten above and the old→new map
  is at the top of Acceptance criteria. Added beyond the developer's option-A list: AC5 (through-`start` proof that nothing is committed past an unconfirmed DLQ write, which is the
  whole reason part a closes the loss) and AC7a' (mutation that swallows the `DeliveryError`). AC8 (M4) stays here because M4 exercises exactly the producer contract.
  **What to change on the branch (no force-push):** add commit(s) on top of `ebe80a7` that restore `ServiceKafkaConsumer.start` (and the rest of the consumer
  section, apart from the optional `consumer=`/`producer=` constructor params) to `origin/main` and drop the OPS-H8b tests from `tests/test_kafka_client.py`. `ebe80a7` stays
  in the branch history as OPS-H8b's source (`git checkout ebe80a7 -- …` onto a fresh `main` later). Merge `origin/main` in if it moved (don't rebase a pushed branch). Re-run the
  open-PR overlap check, then open the draft PR and run AC7 + AC8 on it. Record the counted `git diff --stat` in Notes before opening the PR.
