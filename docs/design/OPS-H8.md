# Tech design — OPS-H8: Python consumer commits an offset only after success or a confirmed DLQ write; interruptible retry waits

**Author:** backend-engineer · **Ticket:** `agents/tasks/OPS-H8.md` · **PRD:** Product OPS-1, OPS-3, §5.3; Technical §8.1 (L4), §8.2 · **Status:** Draft

Code refs are to ArxivLens `origin/main` `71cb609` (OPS-H1 merged). The ticket's refs were taken at `8b0a2d2`; at `71cb609` the heartbeat
hook moved the consumer lines down: `publish` `:27-63` (bare `flush` `:61`), `publish_dlq` `:65-118` (`format_exc` `:100`, bare `flush` `:117`),
`ServiceKafkaConsumer.__init__` `:122-147`, `_heartbeat` `:149-155`, `start` `:157-219` (decode `:178-179`, `time.sleep` `:199`,
DLQ `:201-211`, unconditional `commit` `:214`).

## Problem
`ServiceKafkaConsumer.start`, used by the processor (`papers.downloaded`) and the embedder (`papers.chunked`), commits every record it
touches, whether or not the work landed. `publish_dlq` and `publish` call `produce` and a bare `flush(timeout=5)` and never learn whether the
message was delivered, so a failed DLQ write or a failed `papers.chunked` publish is followed by a commit. The paper is then in no topic and no
DLQ. Retry waits are `time.sleep`, so a shutdown has to wait out the backoff. An undecodable record raises out of the loop and kills the worker
on every restart (a poison-pill crash loop), and it never reaches the DLQ. Also found while reading the code: `publish_dlq` builds `stack_trace` with
`traceback.format_exc()` (`:100`), which `start` calls *after* the `except` block has ended. So every DLQ entry from the consumer path today carries
`"NoneType: None\n"` instead of the handler's trace. Only M4's direct call, made inside an `except`, gets a real one.
This design covers AC1–AC12.

## Approach

### 1. Confirmed delivery (design question 1)
One private helper on `ServiceKafkaProducer` does every produce:

```python
class DeliveryError(Exception):  # "not confirmed delivered": delivery error, still queued, or produce() raised
    pass

def _produce_confirmed(self, topic, key, value, headers) -> None:
    outcome = {}
    def on_delivery(err, msg):
        outcome["err"] = err
    try:
        self.producer.produce(topic=topic, key=key, value=value, headers=headers, on_delivery=on_delivery)
    except (BufferError, KafkaException) as e:      # local queue full, invalid args, etc.
        raise DeliveryError(f"produce to {topic} failed: {e}") from e
    self.producer.flush(timeout=self.delivery_timeout_s)
    if "err" not in outcome:
        raise DeliveryError(f"delivery to {topic} not confirmed within {self.delivery_timeout_s}s")
    if outcome["err"] is not None:
        raise DeliveryError(f"delivery to {topic} failed: {outcome['err']}")
```

- The per-message `on_delivery` callback is the confirmation. `flush()` serves delivery callbacks before it returns. If our callback has run,
  its `err` is the outcome, whatever `flush` returned (other messages may still be queued). If it hasn't run when `flush` returns, the message is
  still queued and is treated as **not delivered**. So `flush`'s return value is never trusted on its own.
- **Bounding "still queued".** If the producer is left as it is (`message.timeout.ms` default 300 s), a message we gave up on can still be
  delivered minutes later. That is a duplicate, not a loss, but during a broker outage every DLQ round would leave one more copy queued.
  So the producer gets `"message.timeout.ms": 10000`, and `delivery_timeout_s = 12.0` is the `flush` bound. librdkafka then fails the
  message itself (callback with `_MSG_TIMED_OUT`) before we stop waiting. In practice "not confirmed" means "failed and will not be delivered later".
  The leftover race (delivered in the last 2 s) can only add a duplicate. This is producer-internal config, not a contract or a retry count
  (librdkafka still retries inside the window). It is open question 2.
- `publish` raises `DeliveryError` and logs `Published …` only after confirmation. It still returns `event_id`.
- `publish_dlq` keeps its signature and return contract (AC9, `tests/test_m4_chaos.py:156`). It returns `None` on confirmed delivery and raises
  `DeliveryError` otherwise. It is split into two steps that the consumer calls separately:
  - `build_dlq_payload(dlq_topic, original_msg, error, consumer_group, attempts, traceparent, original_key, original_value) -> DLQPayload`
    has the same field logic as today, plus three fixes. `stack_trace = "".join(traceback.format_exception(type(error), error, error.__traceback__))`
    gives the handler's trace wherever it is called. A key that isn't UTF-8 is decoded with `errors="replace"` instead of raising. A JSON value that
    is valid but isn't an object (`[1]`, `"x"`) becomes `{"raw_value": …}`, because `DLQPayload.original_value` is a `Dict` and a list would
    make the build itself raise.
  - `send_dlq(dlq_topic, payload: DLQPayload) -> None` serialises the payload and calls `_produce_confirmed`. On success it writes the existing
    `Routed failed message {key} to DLQ topic {dlq_topic}` warning (key only).
  - `publish_dlq(...)` = `self.send_dlq(dlq_topic, self.build_dlq_payload(...))`.

### 2. A failed DLQ write: retry in place (design question 2, mirrors OPS-H6 §1)
After the handler has failed 3 times, `start` builds the `DLQPayload` **once**, so `failed_at` and the stack trace are the handler's. It then loops:

```
for round in 1, 2, ...:
    try: self.producer.send_dlq(dlq_topic, payload); return RESOLVED
    except Exception as e:
        logger.critical("DLQ write failed (topic=%s partition=%d offset=%d dlq_topic=%s round=%d): %s", ...)
        if self._wait(self._dlq_backoff(round)): return STOPPED     # stop requested
```

- `_dlq_backoff(round) = min(1 << (round - 1), 30)` seconds, so 1, 2, 4, 8, 16, 30, 30, … with no jitter, the same as OPS-H6. The handler isn't re-run,
  the handler schedule (3 attempts, 0.2 s and 0.4 s) is unchanged, and nothing is committed until a write lands.
- The loop is single-threaded and sequential (`max.poll.records` is in effect 1: `poll()` returns one message). So no later record is
  handled or committed while this one is stuck, and a cumulative commit can't sweep it up.
- In steady state each round is ≤ 12 s of `flush` plus ≤ 30 s of wait, with one CRITICAL line per round and no handler calls.
- The `except Exception` is deliberately broad, so any send failure counts as a failed round. `build_dlq_payload` is total by construction (§1).
  A test feeds it the shapes that broke it before: a non-dict JSON value and a non-UTF-8 key.

Why retry in place: the same reasons as OPS-H6 §1. The invariant is structural. A broker blip doesn't become a crash. Compose does restart the worker
now (`restart: unless-stopped`), but a crash would re-run the handler 3× on every restart. The processor handler re-reads MinIO and re-parses the PDF each time.

### 3. `max.poll.interval.ms = 300000` and commit errors (design question 3)
While a record is retried in place, `poll()` isn't called, and neither is `_heartbeat()`, which is unchanged and still runs only after a `poll()`.
- **Over 5 minutes:** librdkafka notices that `max.poll.interval.ms` has passed, leaves the group, and its partitions are revoked. With one
  replica per group (today), no one else takes them. The heartbeat file goes stale, and after 300 s the compose healthcheck reports the worker
  `unhealthy`, a second loud signal on top of the CRITICAL lines. Docker doesn't restart a container for being unhealthy, so the worker keeps retrying.
- **When the DLQ write then lands:** `commit` fails, because the member is no longer in the group (`UNKNOWN_MEMBER_ID`, `ILLEGAL_GENERATION`
  or `_MAX_POLL_EXCEEDED`, raised as `KafkaException`). The next `poll()` rejoins. The newly assigned partition starts again from the
  **committed** offset, which is still the stuck record's own offset, so the record is redelivered, fails 3× again, and is DLQ'd again.
  Result: a duplicate DLQ entry, never a loss. A second replica that picked up the partition during the stall would also redeliver from the
  committed offset (a duplicate).
- **Commit errors are logged, not raised:** `logger.error("Commit failed (topic=%s partition=%d offset=%d): %s; the record will be redelivered", …)`,
  then the loop polls again. The code never treats the record as committed: nothing reads a "committed" state, and per-record commits are cumulative
  only over records that were *processed*, in order. Two cases remain. (a) The member lost the partition: it's redelivered from the committed offset (above).
  (b) A transient coordinator error while the member still owns the partition: the next record's successful commit covers this one, which was already
  processed. Raising instead would turn a rebalance blip into a container restart that redelivers the same record anyway. Today a commit error
  raises out of `start` and kills the worker, so this is a behaviour change, covered by a test (row AC1-e).

### 4. Shutdown (design question 4)
- **A stop flag:** `self._stop = threading.Event()`, set by `stop()`. Every wait is `self._wait(seconds) -> bool` (default `self._stop.wait`,
  which returns `True` when the flag is set). No `time.sleep` remains in the file (AC6 grep).
- **Signals, installed inside `start`**, so neither worker changes (the embedder worker is ai-owned). Only when
  `threading.current_thread() is threading.main_thread()`: save the current SIGTERM and SIGINT handlers, install one that calls `self.stop()`,
  and restore the old ones in `finally`. A **second** signal raises `KeyboardInterrupt` (force stop). The existing `except KeyboardInterrupt` keeps
  catching it, and the loop still never commits a record it was in the middle of. So Ctrl-C behaves as it did, except that the first press now finishes
  the current handler call cleanly instead of aborting it.
- **Where stop is checked:**
  - At the top of the poll loop. The `poll(timeout=1.0)` bound means an idle worker exits within about 1 s of SIGTERM, well inside Docker's 10 s grace.
  - In a handler-retry wait: `_wait` returns `True` at once. The record is **STOPPED**: no more attempts, no DLQ write, no commit, and the loop breaks.
  - **AC6b, after any failed attempt:** if `self._stop.is_set()`, the record is STOPPED. A handler that fails *because* shutdown was requested isn't a processing failure.
  - In a DLQ-round wait: STOPPED, same as above.
  - The handler succeeds while stop is set: the record is committed (the work is done), then the loop exits.
- **What can't be interrupted:** a handler call that is running, such as an embedding batch, and one `flush` (≤ 12 s). If Docker's grace (10 s) runs out first,
  SIGKILL arrives before any commit, so the record is redelivered and handled idempotently (§6). Duplicates only.
- `finally: self.consumer.close()` is unchanged. `start` returns normally after a stop.

### 5. Poison records (design question 5): one attempt, then the same DLQ rules
Decoding (`json.loads` then `EventEnvelope(**…)`) moves inside its own `try`. On any exception, the record goes straight to the §2 DLQ path, with
`attempts=1` and `error=` the decode exception (`JSONDecodeError`, `UnicodeDecodeError`, pydantic `ValidationError`, or `TypeError` for a non-dict
JSON value). It then waits for a confirmed write, retries in place, and commits only after the write lands, as in §2. `original_value` comes from `build_dlq_payload`:
`{"raw_value": "b'not json'"}` for a non-JSON value, the decoded dict for valid JSON with missing fields. Why 1 attempt and not 3: decoding is a
pure function of the bytes, so attempts 2 and 3 can't change the result and would only add 600 ms. `attempts=1` is the honest count, and the field
is documented as "attempts made". The log line for a poison record is
`Undecodable record (topic=%s partition=%d offset=%d): %s` with `type(e).__name__` only, because a pydantic `ValidationError` string contains
`input_value=…`, that is, the record value.

### 6. Redelivery against the idempotency layers (design question 6)
| Case | Code (`71cb609`) | Result |
|---|---|---|
| Processor `publish` fails inside the handler (new: raises `DeliveryError`) | `worker.py:79-83`: ledger row + chunks are **committed** before `publish` (`:98`); the `except` (`:107-109`) does a no-op rollback and re-raises | The consumer retries the handler with the same `event_id`. `check_and_record_ledger` returns False → `:84-90` "Duplicate event … proceeding to re-emit downstream" → `chunk_count = len(chunks)` → `publish` again. Rows unchanged; `papers.chunked` re-sent. |
| Processor publish keeps failing 3× | same | Record → `papers.downloaded.dlq` (the error is the `DeliveryError`), committed. Paper stays `chunked` in Postgres with no `papers.chunked` event. A replay (OPS-H7) redelivers it: same `event_id` → L2 duplicate → re-emit; new id → upserts are idempotent → re-emit. Either way it recovers. |
| Redelivery after a stall, eviction or SIGKILL (processor) | same | Same as row 1: L2 dedupes the DB write, re-emits `papers.chunked` (a duplicate downstream event, OPS-H6 G3). |
| Redelivery (embedder) | `embedder/worker.py:48-81`: `get_chunks_for_embedding` LEFT JOIN on `model` | Every chunk has `existing_model` → "Skipping compute" → `update_paper_status(…, "embedded")` → commit. No new vectors. |

The ordering "DB commit, then publish" in the processor is what makes the chain safe: an embedder can never get a `papers.chunked` for chunks
that aren't committed yet. Gaps, all out of scope here:
- **G4 (new, small):** the embedder doesn't use the L2 ledger, though it imports `check_and_record_ledger`. Redelivery is safe through L3, but each
  redelivery runs one `SELECT` plus a status `UPDATE`. That's harmless, so not filed unless pm-lead wants it.
- OPS-H6 G1 (status downgrade on replay), G2 (L3 keys on model, not content hash) and G3 (duplicate downstream events) apply unchanged.
- **G5 (new):** a DLQ message that can never be delivered, for example one over `message.max.bytes` (1 MiB: original value + stack trace), stalls the
  consumer for good. `papers.downloaded` and `papers.chunked` values are small claim-check envelopes, so this isn't reachable today. Proposed follow-up (backend, P3):
  treat non-retriable produce errors (`MSG_SIZE_TOO_LARGE`) by truncating `original_value` and `stack_trace` and retrying once.

### 7. Code shape (`services/common/kafka_client.py`)
```python
class DeliveryError(Exception): ...

class ServiceKafkaProducer:
    def __init__(self, brokers: str = None, producer=None):     # producer: injectable confluent Producer (tests); default unchanged + message.timeout.ms
    def publish(...) -> str                                      # unchanged signature; raises DeliveryError
    def build_dlq_payload(...) -> DLQPayload                     # new, total
    def send_dlq(self, dlq_topic: str, payload: DLQPayload) -> None   # new; raises DeliveryError
    def publish_dlq(...) -> None                                 # unchanged signature + contract (build + send)
    def _produce_confirmed(self, topic, key, value, headers) -> None

class ServiceKafkaConsumer:
    def __init__(self, group_id, topics, brokers=None, max_poll_records=1, consumer=None, producer=None):
        # consumer/producer: injectable; None → exactly today's `Consumer({...})` and `ServiceKafkaProducer(self.brokers)` calls
        # (tests/test_worker_heartbeat.py monkeypatches both module names and must keep passing). Heartbeat setup unchanged.
        # self._stop = threading.Event(); self._wait = self._stop.wait
        # self._handler_backoff = lambda attempt: 0.1 * 2**attempt ; self._dlq_backoff = lambda rnd: min(1 << (rnd - 1), 30)
    def stop(self) -> None
    def _heartbeat(self) -> None                                 # unchanged (OPS-H1)
    def start(self, handler) -> None                             # poll loop: stop check → poll → _heartbeat → error/None skip →
                                                                 # _process(msg, handler) → RESOLVED: _commit(msg) / STOPPED: break
    def _process(self, msg, handler) -> bool                     # decode (poison → _dead_letter attempts=1) → 3 attempts → _dead_letter
    def _dead_letter(self, msg, error, attempts, traceparent) -> bool   # build once, §2 round loop
    def _commit(self, msg) -> None                               # sync commit; KafkaException → logger.error (§3)
```
The tests override `_wait`, `_handler_backoff` and `_dlq_backoff` on the instance. There are no constructor parameters for them, which keeps the public API small.
`traceparent`: read from the header as today. The handler-path DLQ payload uses `envelope.traceparent` (the header value when present, otherwise the
envelope's own), so a header-less record no longer gets a `None` trace. The poison path uses the header only.
The `max_poll_records` parameter stays accepted and unused, as today.

Size estimate: `kafka_client.py` about 120 changed lines, `tests/test_kafka_client.py` about 250, `ci.yml` 2. That's about 370, under 400 (AC12).
If the build goes over, §5 plus the AC7 tests move to a follow-up task, as the ticket says. AC1–AC6 tests are not trimmed.

**Final sequence** (goes in the ticket Notes for pm-lead's Technical PRD §8.1/§8.2 docs PR):
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

## Alternatives considered
1. **Trust `flush()`'s return value only (0 = delivered).** Wrong: a message that failed with a delivery error has also left the queue, so `flush` returns 0. Rejected by the ticket and by AC10b.
2. **Raise from `start` after a failed DLQ write (crash and restart).** Compose now restarts the worker, but every restart re-runs the handler 3× (MinIO read, PDF parse, BGE tokenizer). With Kafka down this becomes a crash loop. Rejected, same as OPS-H6 alt. 2.
3. **Seek back and re-poll (`consumer.seek` to the record) instead of blocking in place.** This keeps `poll()` running, so there's no `max.poll.interval` eviction, but it re-runs the handler every round or needs per-partition state to skip it. Rejected, same as OPS-H6 alt. 1. Eviction during a stall is harmless (§3).
4. **Call `consumer.poll(0)` during the in-place retry to stay in the group.** `poll()` on a confluent consumer returns *messages*. Any message it returned would have to be held or re-sought, and a rebalance could arrive in between. That's more state for a case that is already safe. Rejected.
5. **Use `asyncio` or a worker thread with a cancellable handler.** Python can't safely cancel a running handler (psycopg transaction, torch). Rejected. Shutdown waits for the running call, and SIGKILL is the backstop.
6. **3 attempts for poison records.** It's deterministic, so it adds latency and buys nothing (§5).

## Contracts and invariants
- Shared contracts touched: **none**. `EventEnvelope` and `DLQPayload` fields and topics are unchanged (`shared/events/*` not touched). There is no HTTP, schema or model change.
  `ServiceKafkaConsumer(...)`, `ServiceKafkaProducer(...)`, `publish(...)` and `publish_dlq(...)` keep their signatures. The new parameters are optional and keyword-only in use.
  Worker call sites (`services/processor/worker.py`, `services/embedder/worker.py`) are unchanged.
- **Behaviour changes** callers can see: `publish` and `publish_dlq` raise `DeliveryError` when delivery isn't confirmed (before, they returned silently).
  A commit error is logged instead of killing the worker. A poison record is DLQ'd instead of crashing the worker. The first SIGINT stops the worker cleanly instead of raising mid-handler.
- L4 commit-after-process: holds for the Python consumer, so L4 now holds for all consumers (Technical PRD §8.1).
- Retry 3× with 200/400 ms backoff: unchanged. DLQ with full diagnostics: the same payload, now with the *real* handler stack trace (it was `NoneType: None`).
- `traceparent`: header → DLQ header and payload, as today, with the envelope as fallback (§7). The processor still forwards `envelope.traceparent` to `papers.chunked`.
- Idempotency L2/L3: untouched (§6). The OPS-H1 heartbeat hook is unchanged: touched after every `poll()` while assigned, no-op when `WORKER_HEARTBEAT_FILE` is unset. `tests/test_worker_heartbeat.py` stays green unmodified.

## Test plan
All tests are in the new `tests/test_kafka_client.py`. They use pytest and fakes only: no broker, network or Docker, and no `time.sleep`. Imports are what the CI `python` job
already installs (`confluent-kafka`, `pydantic`, `ulid-py`). Fakes:
- `FakeMsg(topic, partition, offset, value, key=b"2401.00001", headers=[("traceparent", b"00-…")])` with the `Message` accessors and `error()`.
- `FakeConsumer(script, log)`: `poll()` pops the next scripted message. When the script is empty it calls `owner.stop()` and returns `None`.
  `commit(message=…)` appends `("commit", offset)` to the shared `log` and can be scripted to raise `KafkaException`. `close()` appends `("close",)`, and `assignment()` returns `[("t", 0)]`.
- `FakeProducer(outcomes, log)`: `produce(..., on_delivery=cb)` appends `("produce", topic, offset-from-payload)` and queues `cb`. `flush(timeout)` applies the next
  scripted outcome: `ok` → `cb(None, msg)`, return 0; `err` → `cb(FakeErr("Broker: timed out"), None)`, return 0; `queued` → return 1 without calling `cb`; `raise` → `produce` raises `BufferError`.
- Fake wait: `c._wait = rec` appends the duration to a list and returns `c._stop.is_set()`. Optionally it calls `c.stop()` after N calls. Handlers are closures with per-offset scripted errors and call counters.

| Acceptance criterion | Test (name / type) | Runs in CI? |
|---|---|---|
| AC1 success path | `test_success_path` (parametrised): (a) ok on 1st → waits `[]`; (b) ok after 1 failure → `[0.2]`; (c) after 2 → `[0.2, 0.4]`. Each: exactly one `("commit", 5)`, 0 produces. (e) commit raises `KafkaException` for @5 → ERROR log `Commit failed (… offset=5 …)`, @6 is still handled and committed, and `start` returns | yes, new `ci.yml` step |
| AC2 DLQ path + order | `test_dlq_then_commit`: always-failing handler, DLQ `ok`. One produce to `papers.downloaded.dlq`. The payload has `original_topic`, `partition`, `offset`, `attempts == 3`, `consumer_group`, `traceparent` == header value, and `stack_trace` contains the handler function's name (proves the build-once trace fix). Log order `produce @5` → `commit 5` | yes |
| AC3 DLQ fails → no commit | `test_dlq_failure_blocks_and_never_commits` (parametrised `err`, `queued`): script `[@4 ok, @5 fails, @6 ok]`, every DLQ outcome failing, the fake wait stops after 3 rounds. Asserts `("commit", 4)` present and no commit for 5 or 6; ≥ 2 produces for @5; handler@5 calls == 3, handler@6 calls == 0; `start` returns; `("close",)` is last | yes |
| AC4 recovery | `test_dlq_recovers_after_two_failures`: DLQ `err, err, ok`. Exactly 1 confirmed DLQ message, 1 commit (after it), handler calls == 3, DLQ waits == `[1, 2]` (after the handler waits `[0.2, 0.4]`). Also `test_dlq_backoff_schedule` (rounds 1–7 → 1, 2, 4, 8, 16, 30, 30) | yes |
| AC5 `publish` raises | `test_publish_requires_confirmation` (parametrised `ok` → returns event id; `err`, `queued`, `raise` → `DeliveryError`), at the `ServiceKafkaProducer` level. `test_failing_publish_in_handler_is_retried_not_committed`: the handler calls a second `ServiceKafkaProducer(producer=FakeProducer(all err))`. Asserts 3 handler calls, a DLQ write for the record (consumer's producer `ok`) and commit only after it. A second row where the consumer's DLQ also fails → no commit | yes |
| AC6 interruptible waits | `test_stop_during_handler_wait_returns_promptly`: real `threading.Event` wait, `_handler_backoff = lambda a: 5.0`, `threading.Timer(0.02, c.stop)`. `start` returns in < 0.2 s, 0 commits, 0 produces. `test_stop_during_dlq_wait_returns_promptly`: same with `_dlq_backoff = lambda r: 5.0`, DLQ `err`: < 0.2 s, 0 commits, 1 produce (the failed one). The grep is QA/PR evidence | yes |
| AC6b stop inside the last attempt | `test_stop_during_last_attempt_is_not_a_failure`: the handler fails calls 1–2; on call 3 it calls `c.stop()` and raises. 3 handler calls, 0 produces, 0 commits, `start` returns. Variant: stop on call 1 → 1 handler call, no wait recorded | yes |
| AC7 poison records | `test_poison_record_goes_to_dlq_and_loop_continues` (parametrised): `b"not json"` → `original_value == {"raw_value": "b'not json'"}`; `b'{"event_id": "x"}'` → the decoded dict; `b"[1, 2]"` → `raw_value` (non-dict guard). Each: 1 DLQ message with `attempts == 1`, commit after it, and the next record @6 handled and committed; the handler is never called for the poison record | yes |
| AC8 log hygiene | `test_dlq_failure_log_has_coordinates_not_value` (`caplog`): the record value and the handler error both contain `SENTINEL-7f3a`, DLQ `err` then `ok`. The CRITICAL record contains `topic=papers.downloaded`, `partition=0`, `offset=5`, `dlq_topic=papers.downloaded.dlq`, `round=1` and the delivery error text. **No** log record contains the sentinel. The poison row checks the same with a `ValidationError` | yes |
| AC9 no regressions | `test_publish_dlq_direct_call_contract`: the M4-style call (`original_msg=None`, `attempts=3`, `traceparent`) returns `None` on `ok` and raises `DeliveryError` on `err`; the payload keeps the `original_value or {}` / `dlq_topic.replace(".dlq", "")` fallbacks. `tests/test_worker_heartbeat.py` unchanged and green. `make test-py` green in CI | yes |
| AC10 mutations | Developer-pushed mutation commits, each followed by a revert and its own finished CI run (OPS-H6 procedure): (a) unconditional `self.consumer.commit` after `_dead_letter` → `test_dlq_failure_blocks_and_never_commits` and AC5 row 2 red; (b) bare `flush` in `_produce_confirmed` (ignore `outcome`) → AC3 `err` row, AC5 `err`/`queued` rows and AC9 red; (c) `time.sleep(self._handler_backoff(attempt))` in place of `self._wait` → AC6 (timing) and AC1 (no recorded waits) red | yes (a run per mutation) |
| AC11 M4 | `stack.yml` runs on this PR automatically (its `paths` include `services/common/**`); it runs `make test-full`, which includes `tests/test_m4_chaos.py`. Its URL goes in Notes. Note: M4 calls `process_message` and `publish_dlq` directly, so it checks the producer contract (`publish` against a real broker, M4's DLQ assertions); `start` against a real broker is exercised by the compose workers that take M2 papers to `embedded` | yes (`stack.yml`) |
| AC12 size + docs | `git diff --stat origin/main...` in the PR body (≤ 400). Final sequence (§7) in ticket Notes. No README change: README:39 holds now; proposed sharper wording in Notes as a follow-up | n/a |

Failure paths covered: handler error ×1, ×2, ×3; delivery error, still queued, and `produce` raising, each for the DLQ and for `publish`; DLQ failing
transiently and permanently; commit error; stop in a handler wait, in a DLQ wait, and inside the last attempt; non-JSON, schema-invalid and non-dict JSON values.
Not covered by unit tests (by design): real signal delivery. `test_signal_handler_sets_stop_and_is_restored`: the fake handler reads
`signal.getsignal(signal.SIGTERM)` while `start` runs, calls it with `(SIGTERM, None)`, and the test asserts the record is committed (the handler returned),
the loop then exits, and after `start` returns `getsignal(SIGTERM)` is the pre-test handler again. Real SIGTERM-on-`docker stop` is seen in `stack.yml` teardown logs only.
Runtime target: < 1 s, with no real waits except AC6's ≤ 0.2 s pair.

## Risks and rollout
- **The stall while the DLQ is down is intended.** It is detected by one CRITICAL line per round, consumer lag, and after 300 s the compose healthcheck (`unhealthy`).
  It recovers on its own. A permanently undeliverable DLQ message (G5) stalls for good; the log names the offset.
- **Duplicates:** a DLQ entry after eviction or a late delivery, and a `papers.chunked` event after a failed `publish`. At-least-once by design; L2 and L3 absorb them (§6).
- **`message.timeout.ms = 10000`:** a slow broker that needs more than 10 s to ack now fails the publish (the handler retries) instead of waiting up to 5 min.
  Normal acks take milliseconds. It's tunable in one place if this shows up in `stack.yml`.
- **Signal handlers inside a library:** installed only on the main thread, restored on exit. Pytest runs `start` on the main thread, so the tests cover the restore path.
- **Rollback:** revert the single PR. No schema, contract or data migration.
- **Sequencing (why this cycle is design-only):** the scope adds one step to `.github/workflows/ci.yml` (`python` job), and open PR #23 (LLM-1,
  Ready to merge) also changes `ci.yml` (AGENTS.md §3 independence). The build starts on a fresh `origin/main` **after #23 merges**. The fallback,
  adding the file to `make test-py` instead of a CI step, doesn't help: `Makefile` is in open PR #22 (EVAL-3). Once both have merged, the
  follow-up already in the ticket Notes (move `tests/test_kafka_client.py` into `make test-py`, drop the CI step) applies. No other open PR
  (#20, #21, #22, #23) touches `services/common/`, `tests/test_kafka_client.py` or the worker files.

## Open questions (for pm-lead / Mahesh)
1. **Commit errors logged, not raised (§3)** is a behaviour change: today a commit error kills the worker. OK? It is safe under sequential per-record commits, and raising buys only a restart that redelivers the same record.
2. **`message.timeout.ms = 10000` and a 12 s confirmation bound (§1)** instead of keeping `flush(timeout=5)` with the 300 s default. The alternative, which keeps the config, is a 5 s wait and accepting a growing queue of late duplicates during an outage. I recommend the change; it's one config line.
3. **Poison records: `attempts = 1` in `DLQPayload` (§5).** The field's meaning is "attempts made". Confirm, or ask for `3` to keep one value across DLQ entries (operators filtering on it).
4. **The first SIGINT finishes the running handler instead of raising `KeyboardInterrupt` mid-call (§4)**, and a second press forces the stop. OK for local `python services/*/worker.py` use?
5. **DLQ `traceparent` falls back to `envelope.traceparent` when the header is missing (§7).** It's one word in the handler path, inside L4 scope. OK, or keep it header-only?
6. File **G5** (undeliverable DLQ message, P3) and optionally **G4** (embedder L2 unused) as Backlog?

## PM decision
**Decision: APPROVED with conditions** (pm-lead, 2026-11-07 10:19Z, design at `f1b5c0e`, code at ArxivLens `origin/main` `71cb609`).

Why: the design answers all seven "Design must answer" items in the ticket and mirrors the approved OPS-H6 semantics: retry the DLQ write in place,
build the payload once, no commit until the write lands, interruptible waits, AC6b. With per-record sync commits in a single sequential loop,
"nothing at or after N is committed" is structural. I checked the refs against `71cb609`. `start` is at `:157-219`: decode `:178-179` is outside the retry `try`,
`time.sleep` is at `:199`, and `commit(message=msg, asynchronous=False)` runs unconditionally after `publish_dlq`. `DLQPayload` (`shared/events/events.py:31-43`)
keeps its fields. Neither worker installs a signal handler today, so installing one inside `start` collides with nothing. The redelivery table (§6) matches
Technical PRD §8.1 L2/L3. The `format_exc()` trace finding is real, and fixing it here is in scope (AC2 diagnostics, Product PRD §5.3). There is one named test
per AC, and failure paths are listed. No shared contract changes: event envelope, `DLQPayload` fields, topics, HTTP, schema and model all stay the same. So none of the
six questions needs an ADR.

Answers to the open questions (all within pm-lead authority; **none needs Mahesh**. Items 1–3 change what operators see, so they go in the PR body for visibility, condition 5):
1. **Commit errors logged, not raised: accepted.** Same policy as the approved OPS-H6 Go consumer (its test plan, "commit error (logged, loop continues)").
   The ticket's rule ("no swallowed commit error may be followed by moving on as if committed") holds: nothing reads a committed state, and an uncommitted
   processed record is either covered by the next cumulative commit or redelivered. Only `KafkaException` from `commit` is caught. Any other exception still propagates.
2. **`message.timeout.ms = 10000` with a 12 s confirmation bound: accepted.** It is producer-internal config, not a retry count or a gate. It turns "not confirmed" into
   "failed, won't arrive later", so outages don't build a queue of late duplicates. Define both values once, as named module constants with a one-line comment, and add a test that
   asserts `delivery_timeout_s > message.timeout.ms / 1000` (condition 4). Known consequence, accepted: a `flush` (≤ 12 s) can outlast Docker's 10 s stop grace. SIGKILL comes
   before any commit, so the cost is a duplicate, never a loss. The compose `stop_grace_period` is a Backlog item, not this PR (`docker-compose.yml` is out of scope).
3. **Poison records `attempts = 1`: accepted.** Technical PRD §8.2 lists `attempts` as a diagnostic field. "Attempts made" is the honest value, and decoding is deterministic.
   The field's meaning will be written down in the pm-lead Technical PRD §8.2 docs PR (Backlog, already listed). Operators tell poison records apart by
   `error_type` (`JSONDecodeError` / `ValidationError` / `TypeError`), not by `attempts`.
4. **First SIGINT/SIGTERM finishes the running handler call, second forces the stop: accepted.** This is the behaviour Docker stop needs (OPS-1), and local Ctrl-C keeps an
   escape hatch. Handlers are installed only on the main thread and restored in `finally`. Keep `test_signal_handler_sets_stop_and_is_restored`.
5. **DLQ `traceparent` falls back to `envelope.traceparent`: accepted.** Technical PRD §9 says "W3C `traceparent` on every event and DLQ record". At `:180-181` the
   envelope's value is already the header value when a header is present, so this only fills today's `None` case. The poison path stays header-only (no envelope).
6. **Backlog: G5 is filed** (backend, P3). **G4 is filed** (ai, P3, low value: L3 already makes redelivery safe; fold into the next `services/embedder/worker.py` change).
   Also filed: compose `stop_grace_period` for the workers (backend, P3, from answer 2). All three are in `agents/board.md` Backlog.

Binding conditions:
1. **Sequencing.** No build this cycle. Cut `agent/backend/OPS-H8` from a fresh `origin/main` **only after ArxivLens #23 (LLM-1, changes `.github/workflows/ci.yml`) merges**.
   `Makefile` is in open #22 (EVAL-3), so the CI-step route in Scope stands. At build start, recheck that no open PR touches `services/common/`, `.github/workflows/ci.yml`,
   `tests/test_kafka_client.py` or either worker file (AGENTS.md §3). On 2026-11-07 10:19Z, open #20–#25 touch none of them except #23's `ci.yml`. If #22 has also merged by then,
   keep the CI step anyway. Moving the file into `make test-py` stays the follow-up in Notes, not scope creep here.
2. **Size (lesson LLM-1: estimates near 400 run low).** Before writing the full test file, record a counted skeleton in ticket Notes (`git diff --stat` of `kafka_client.py`
   done plus the stubbed test functions with their fakes). **Split seam, named now:** if the projected total is > 400, move §5 (poison-record decode `try`) and the AC7 tests
   into follow-up **OPS-H8b** (backend, P0, covered by this design, no new design round). OPS-H8 then ships AC1–AC6 and AC8–AC12 unchanged, and AC7 moves to OPS-H8b. Don't trim
   AC1–AC6 or AC8–AC10 tests to fit. No size exception is granted in advance. If it's still > 400 without §5, stop and report in Notes.
3. **AC11 is delivered in this PR** (amended in the ticket). `stack.yml` runs on the PR (`paths` include `services/common/**`). Evidence: the run URL, plus the M4 test lines
   (`tests/test_m4_chaos.py`) passing in that run's log. If the run is red only on the known F1 deselection/step, QA shows the M4 lines are green. If M4 itself fails, the PR doesn't pass QA.
4. **Delivery bound test:** `message.timeout.ms` and `delivery_timeout_s` are named constants, and one test asserts the bound in answer 2. It's a few lines inside the AC5 test module.
5. **PR body:** a "Behaviour changes (decided by pm-lead in design review)" section listing the four visible changes (publish/publish_dlq raise `DeliveryError`; commit error
   logged; poison → DLQ with `attempts=1`; first signal = graceful stop) plus the stack-trace fix, so Mahesh sees them at merge.
6. **AC10 mutations** follow the OPS-H6 procedure exactly. Each mutation is its own commit (`mutation(AC10a|b|c): …`) containing only the `kafka_client.py` mutation and no test edits,
   followed by `revert mutation(AC10x)`. Wait for each CI run to finish before the next push (`ci.yml` cancels in-progress runs). SHAs and run URLs go in Notes. The final head is green.
7. Keep `tests/test_worker_heartbeat.py` unmodified and green, and keep worker call sites unchanged (§7). Don't touch the embedder worker (ai-owned).

### Addendum, 2026-11-07 (pm-lead): split decision after condition 2 triggered
**Decision: split by layer (the developer's option A). No size exception.** The build at ArxivLens `ebe80a7` is 487 changed lines (174 prod + 311 tests + 2 ci). With the
§5 seam named above it's still 462, so that seam was the wrong one. Fakes and deleted call sites dominate, not §5. The design itself is unchanged and stays approved. Only the delivery is split:
- **OPS-H8 (part a), producer layer:** §1 in full (`on_delivery` confirmation, named constants, `DeliveryError` from `publish`/`publish_dlq`), the build-once
  `build_dlq_payload`/`send_dlq` split and the `format_exception(error)` trace fix (§2's "build once" sentence), the injectable `producer=`/`consumer=` seams, and the `ci.yml` step.
  `ServiceKafkaConsumer.start` stays byte-for-byte as on `main`. An unconfirmed DLQ write therefore raises out of `start` (consumer closed in `finally`) **before** its
  `commit`. This is alt. 2, accepted **as an interim only**: it costs re-running the handler 3× per restart while the DLQ is down, never a record. Conditions 1 (overlap recheck), 4, 5 (part-a list),
  6 and 7 apply, plus AC8 = condition 3 (M4 runs against exactly this layer).
- **OPS-H8b, consumer layer:** §2 in-place DLQ retry (replaces the interim exit), §3 commit-error logging, §4 stop flag + signals + interruptible waits, §5 poison, §7 shape,
  the `traceparent` fallback (answer 5) and log hygiene. Depends on OPS-H8 merged. No new design round. Conditions 2 (counted skeleton, named seam = poison/AC7 → OPS-H8c), 3, 5, 6 and 7 apply.

Why A and not B: two size exceptions granted on estimates have both been wrong by more than 25% (LLM-1, here). Part a is independently valuable: it closes both silent-loss paths
(the unchecked DLQ `flush` and the unchecked `papers.chunked` `flush`) in one ~200-line PR that's easy to review. The interim behaviour is strictly safer than `main` today,
which commits after a lost DLQ write. Splitting at the producer/consumer boundary leaves part a's tests valid in part b. The single exception is AC5's "`start` raises",
whose no-commit assertions are kept while the exit expectation becomes "returns normally after the in-place retry". That's mandated by §2, not a weakened test.
