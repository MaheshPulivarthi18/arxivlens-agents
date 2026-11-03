# OPS-H8: Python consumer commits an offset only after success or a confirmed DLQ write; interruptible retry waits

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (silent message loss in the processor and embedder stages) |
| **PRD ref** | Product PRD OPS-1, OPS-3, §5.3; Technical PRD §8.1 (L4 commit-after-process: "All consumers"), §8.2 (retry and DLQ) |
| **Depends on** | OPS-H6 (Done, ArxivLens #15 → `e9be32e`; its approved design `docs/design/OPS-H6.md` defines the semantics to mirror) |
| **Jira** | to be created by orchestrator (`labels = "task-OPS-H8"`) |
| **Design required** | **yes**: P0, and it changes the pipeline's delivery semantics for both Python workers |
| **Status** | Ready (specced 2026-11-03 21:02Z cycle by pm-lead) — next stage: Design (`docs/design/OPS-H8.md`) |

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
- [ ] AC11 — Deferred, with an owner: M4 (`tests/test_m4_chaos.py`) on the full stack. Not runnable until OPS-H1 (#14)
  merges and `stack.yml` exists on `main`. Stop-and-report rule: the PR states "M4 not run: no stack" and this AC stays open
  on the ticket; it is closed by the first green `stack.yml` run on `main` after both merge (pm-lead files the run URL in
  `agents/reviews/OPS-H8/`). If that run fails in M4, a follow-up task is opened for backend before anything else in the area.
- [ ] AC12 — Diff ≤ 400 changed lines in total (code + tests + CI step); if the design shows it can't fit, split the poison-record AC7 into its own task. Docs: Technical PRD §8.1/§8.2 caveat removal is a pm-lead docs PR;
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
