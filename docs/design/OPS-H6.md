# Tech design — OPS-H6: Go consumer commits only after success or a confirmed DLQ write; context-aware retry wait

**Author:** backend-engineer · **Ticket:** `agents/tasks/OPS-H6.md` · **PRD:** Product OPS-1, OPS-3, §5.3; Technical §8.1 (L4), §8.2 · **Status:** Approved with conditions C1–C7 (pm-lead, 2026-11-03); C1 amended and C2 closure set at PM final review round 1 (see the end of PM decision)

Code refs are to ArxivLens `origin/main` `9c1229a`.

## Problem
`Consumer.Start` (`internal/kafka/consumer.go`) breaks L4 in two ways. First, if `PublishDLQ` fails, or if `producer == nil`,
it logs and still runs `CommitRecords` (`:129-139`), so the record ends up in neither the topic nor the DLQ. Second, the retry wait
is `time.Sleep` (`:102`), so shutdown has to sit out the backoff. Two more things are wrong in the same loop. `BlockRebalanceOnPoll` is set (`:30`), but nothing
calls `AllowRebalance`. And a poll that returns any error drops every record in that poll (`:71-76`, see Approach §6). This design
covers AC1–AC11 and the Docs AC.

## Approach

### 1. Mechanism for a failed DLQ write: retry the DLQ write in place (ticket option 3)
After the handler has failed `maxRetries` (3) times, the consumer builds the `DLQPayload` **once** and keeps calling
`PublishDLQ` until it returns nil (then it commits) or ctx ends (then it returns without committing). Between failed rounds it
waits with a capped, ctx-aware backoff. The handler is **not** run again.

The loop is one goroutine and handles records in order, so nothing after the stuck record is handled. That holds for its
partition and for every other partition in the same poll. So no later offset of that partition can be committed, and cumulative
commits can't sweep the record up (design question 1). Records earlier in the poll were committed one by one as they finished, as they are today.
Records later in the poll, from any partition, wait. If ctx ends while we wait, `Start` returns. Those records were never committed,
so the next owner gets them again from the last commit.

Why this option:
- **No loss, smallest diff.** The invariant is structural: the loop can't reach a later record until this one is resolved.
  We don't need per-partition bookkeeping or fetch-position surgery.
- **The handler isn't re-run.** It already failed 3 times. Re-running it each round (option "rewind with `SetOffsets`")
  would mean more arXiv PDF requests. The downloader has no rate limiter of its own in `HandleRecord`, so politeness is at risk.
  It would also mean more side effects, such as republished `papers.downloaded` events. Only the DLQ write is missing, so only that is retried.
- **It survives a short Kafka outage.** A DLQ write usually fails because the brokers are unavailable, and then everything else is
  stalled anyway. Retrying in place picks up again on its own when Kafka returns. "Return an error from `Start`" would crash the downloader
  (`main.go:160` returns it), and the worker isn't supervised in compose yet (OPS-H1). On restart it would re-handle the record
  3 times and probably crash again, a crash loop with arXiv hits.
- **It fits the existing sequential semantics.** One stuck record already blocks the loop today, for up to 600 ms of handler backoff.

Cost, accepted and documented: while the DLQ stays down, the consumer stalls on that record. Lag grows, and one `CRITICAL` log
line is written per round (§4). That is the right failure mode for "never lose a paper". An operator sees it at once, and no data is lost.

### 2. No hot loop (design question 2)
- Handler retries are unchanged: 3 attempts, waits `retryBackoff(1)=200ms` and `retryBackoff(2)=400ms`, now through `c.wait`.
- DLQ write rounds: `dlqRetryBackoff(round) = min(1s << (round-1), 30s)`. That gives 1 s, 2 s, 4 s, 8 s, 16 s, 30 s, 30 s, and so on. There is no jitter,
  so tests stay deterministic, and there is one consumer per group today. This is a new schedule, so `maxRetries` and `retryBackoff` are untouched.
- Per round: 1 `PublishDLQ` call (it is `ProduceSync`, which itself respects ctx and the client's produce timeouts), then 1 wait.
  So at most ~2 publish attempts per minute in steady state, with zero handler calls.
- Every wait goes through one injectable function:
  ```go
  type waitFunc func(ctx context.Context, d time.Duration) error
  func ctxWait(ctx context.Context, d time.Duration) error // timer + select on ctx.Done(); returns ctx.Err() if cancelled
  ```
  No `time.Sleep` remains in `consumer.go` (AC6 grep).

### 3. Cancellation (design question 5)
- **During a handler-retry wait:** `c.wait` returns `ctx.Err()`, and `processRecord` returns "not resolved". The record gets no DLQ write and
  no commit, and `Start` returns nil (shutdown is not a failure, so the exit is unchanged).
- **The handler returns an error while ctx is done:** we don't count this as a processing failure. If `ctx.Err() != nil` after a
  failed attempt, we stop. No more attempts, no DLQ, no commit.
- **During a DLQ-round wait:** same as the first case.
- **ctx is cancelled during an in-flight `PublishDLQ`:** it returns an error, the next `c.wait` sees ctx done, and there is no commit. The write
  may still have landed. Then the record is redelivered, fails again, and gets a second DLQ entry. That's a duplicate, not a loss (at-least-once).
- **The handler succeeds but ctx is already cancelled:** `CommitRecords(ctx, …)` may fail. It is logged, and the record is redelivered to an idempotent
  handler (§5). This is unchanged from today. I chose not to add a `context.WithoutCancel` commit, to keep the diff small.

### 4. `BlockRebalanceOnPoll` / `AllowRebalance` (design question 4): keep the option, call `AllowRebalance` after every poll
franz-go v1.16.1 `kgo.BlockRebalanceOnPoll` godoc (config.go). I quote it from memory of the upstream doc, because the sandbox can't reach
proxy.golang.org or GitHub. The implementer must re-check it in `go doc github.com/twmb/franz-go/pkg/kgo.BlockRebalanceOnPoll` on a
machine with the module: *"switches the client to block rebalances whenever you poll until you explicitly call AllowRebalance … the big
tradeoff is that by blocking rebalances, you put your group member at risk of waiting so long that the group member is kicked
from the group because it exceeded the rebalance timeout … You must always AllowRebalances when you are done processing the
records you received. Only rebalances that lose partitions are blocked."* `AllowRebalance` godoc: *"You can poll many times
before calling this function; this function internally resets the poll count and allows any blocked rebalances to continue."*

So today, after the first poll, any rebalance that revokes a partition from the downloader blocks until the member is kicked.
The fix is to keep the option, because it is what makes per-record commits safe: we only commit partitions we still own. We then call
`c.client.AllowRebalance()` once per poll, after that poll's records are all resolved and committed (or abandoned on ctx end),
via `defer` in the per-poll function. That covers every exit path, including poll errors.

Interaction with §1: while a DLQ write is stuck, the member can't let a revoking rebalance proceed. After the rebalance timeout
(kgo default 60 s) the broker may evict it. Heartbeats run in the background, so this happens only when a rebalance is actually pending.
In that case the later `CommitRecords` fails and is logged, and the new owner redelivers from the last committed offset. That is a duplicate, never a loss.
With one downloader instance today, this is rare.

### 5. Redelivery against the idempotency layers (design question 3)
Chain for a redelivered `papers.discovered` record (checked in code):

| Step | Code | Result on redelivery |
|---|---|---|
| Downloader L1 storage | `downloader.go:55-72`: `ObjectExists` → read back, recompute sha256 | No arXiv request, no new object |
| Downloader L1 row | `db.UpdatePaperDownloaded` (`internal/db`): `UPDATE … WHERE arxiv_id, version` | Same row, same key and sha; **but `status` is forced back to `'downloaded'`** (see gap G1) |
| Re-publish | `events.NewEventEnvelope` → new ULID `event_id` | Processor L2 (`processed_events`) does **not** dedupe |
| Processor writes | `services/common/db.py` `save_sections_and_chunks`: upsert on `(paper_id, position)` and `(paper_id, chunk_index)` | Same rows (PyMuPDF parse of identical bytes is deterministic); status → `'chunked'` |
| Embedder L3 | `get_chunks_for_embedding` LEFT JOIN `chunk_embeddings` on `model` | No re-embedding, no new rows; status → `'embedded'` |

The chain is confirmed for **row and embedding counts**. That is what OPS-3 and M4 invariant (a) assert. Gaps to name, all out of scope here:
- **G1, status regression window.** A redelivered record for an already-`embedded` paper briefly moves it to `downloaded` and then
  `chunked`. It converges back to `embedded` once the embedder runs. If a later stage DLQs on the replay, the paper stays at an earlier status.
  Proposed follow-up (backend): make `UpdatePaperDownloaded` not downgrade a later status, or skip re-publish when the status is past `downloaded`.
- **G2, L3 keys on model, not content.** If a re-parse ever produced different text for an existing `chunk_index`, the old vector would be
  kept. It doesn't happen for identical PDF bytes, but the PRD calls L3 "content hashing". Proposed follow-up (ai/backend): join on `content_hash`.
- **G3, duplicate downstream events.** Each redelivery adds one `papers.downloaded` and one `papers.chunked` event with fresh ids. That is harmless given the
  above, but it is extra processing. A deterministic `event_id` (for example derived from source event id + topic) would let L2 dedupe it, but that is an envelope
  contract change and needs an ADR. I'm not proposing it now.

pm-lead: please file G1 (and G2 if you agree) as Backlog tasks. No other service changes in this task.

### 6. Poll errors must not drop records (same L4 bug, same loop)
`:71-76` does `continue` when `fetches.Errors()` is non-empty. In franz-go, partition-level errors come back next to records from other
partitions, and the client has already moved its fetch position past those records. Skipping them means the next poll's later
offsets get committed past records that were never handled, which is silent loss. The fix is to log each error with
`fetches.EachError` (topic, partition, error) and then **still process the records** in the poll. If ctx is done, return nil.
If the error is `kgo.ErrClientClosed`, return it, so the loop can't spin on a closed client. This is a few lines and isn't in the
ACs, so it is listed under Open questions for pm-lead. The extra test is `TestConsumerPollErrorStillProcessesRecords`.

### 7. Code shape (`internal/kafka/consumer.go`, about 150 changed lines plus tests)
```go
type consumerClient interface {           // *kgo.Client satisfies it
    PollFetches(ctx context.Context) kgo.Fetches
    CommitRecords(ctx context.Context, rs ...*kgo.Record) error
    AllowRebalance()
    Close()
}
type dlqPublisher interface {             // *Producer satisfies it
    PublishDLQ(ctx context.Context, dlqTopic string, p events.DLQPayload) error
}

type Consumer struct {
    client     consumerClient
    group      string
    topics     []string
    dlq        dlqPublisher
    maxRetries int
    backoff    func(attempt int) time.Duration // retryBackoff
    dlqBackoff func(round int) time.Duration   // dlqRetryBackoff
    wait       waitFunc                        // ctxWait
}

func NewConsumer(brokers []string, group string, topics []string, producer *Producer) (*Consumer, error)
    // unchanged signature; returns an error if producer == nil (checked BEFORE wrapping in the interface, so a
    // typed-nil *Producer can't slip through) → no change to cmd/arxivlens/main.go

func (c *Consumer) Start(ctx, handler) error            // poll loop: ctx check → PollFetches → c.handlePoll
func (c *Consumer) handlePoll(ctx, handler, fetches) (stop bool, err error)
    // defer c.client.AllowRebalance(); log EachError; for each record: if !c.processRecord(...) { return true }; CommitRecords
func (c *Consumer) processRecord(ctx, handler, rec) (resolved bool)
    // handler attempts with c.wait(ctx, c.backoff(attempt)); on exhaustion: build payload once, then
    // for round := 1; ; round++ { if c.publishDLQ(...) == nil { return true }; log CRITICAL; if c.wait(ctx, c.dlqBackoff(round)) != nil { return false } }
func (c *Consumer) publishDLQ(...) error                // c.dlq == nil → errNoDLQPublisher (defence in depth for struct literals)
func buildDLQPayload(rec, traceparent, handleErr, attempts, group) events.DLQPayload   // unchanged fields
func ctxWait(ctx, d) error
func retryBackoff(attempt int) time.Duration            // unchanged
func dlqRetryBackoff(round int) time.Duration           // new
```
`DLQPayload` fields and values are exactly as today. `Attempts = c.maxRetries` and `FailedAt` is set at the first failure, so it stays the same across
rounds. Logs on a failed DLQ write: `CRITICAL: DLQ write failed (topic=%s partition=%d offset=%d dlq_topic=%s round=%d): %v`, with no value
and no payload. The existing `Routing failed record to DLQ` line keeps logging only the key (the arXiv id). The existing handler-error log
already omits the value. `Producer` doesn't change.

New sequence (proposed text for pm-lead's Technical PRD §8.1/§8.2 docs PR; the same text goes in the ticket Notes at build):
```
poll → for each record, in order:
  attempt 1..3: handle; on error wait 200ms, 400ms (ctx-aware; ctx done → stop, no DLQ, no commit)
  success → commit record
  3 failures → build DLQPayload once → publish to <topic>.dlq
     ok → commit record
     error → log CRITICAL, wait 1s,2s,4s…30s (ctx-aware) and publish again; never commit, never move on, until it lands or ctx ends
after the poll's records: AllowRebalance
On restart/rebalance, everything after the last committed offset is redelivered; L1–L3 keep row counts unchanged.
```
§8.1 L4 then holds for the Go consumer. The Python consumer still doesn't hold it until OPS-H8.

### 7a. As built (2026-11-03, backend-engineer; changes from the shape above)
To stay under the C1 limit of 400 changed lines without trimming AC tests, the per-record logic stays **inline in `Start`**, at the
original indentation, so the unchanged lines (traceparent, retry log, `DLQPayload` literal, commit) don't show up as re-indented diff. It is not split into
`handlePoll`/`processRecord`/`publishDLQ`/`buildDLQPayload`. Semantics are the same as §1–§6:
- An unresolved record does `break records` (a labelled break out of the record loop), so its commit and every later commit in the poll are skipped.
- `c.client.AllowRebalance()` is called explicitly after the record loop on every poll, including error-only polls, instead of via `defer`.
  The `kgo.ErrClientClosed` return skips it (the client is closed).
- Poll errors: `fetches.EachError` logs `Poll error (topic=%s partition=%d): %v` and the poll's records are still handled (AC12).
- `waitFunc` is the struct field type `func(ctx, d) error`, with no named type. The `nil` DLQ check is inline (`errNoDLQPublisher`).
- C2: the franz-go v1.16.1 doc quote in §4 is **unverified** (proxy.golang.org, raw.githubusercontent.com and the twmb/franz-go API are
  unreachable from the sandbox). QA checks it against the v1.16.1 source.

## Alternatives considered
1. **Rewind the partition (`SetOffsets` to N), skip the rest of that partition for this poll, redeliver next poll.** Other
   partitions keep flowing, which is the only real advantage. Rejected: it re-runs the handler every round (arXiv load, duplicate
   downstream events) and needs per-partition backoff state, or it hot-loops through 3 handler calls per poll. It is also coupled to franz-go's
   buffered-fetch semantics, and fake-based tests can't faithfully reproduce those. With a single consumer goroutine and Kafka usually being the thing that's down,
   "other partitions keep flowing" helps little.
2. **Return an error from `Start` and let the process restart from the last commit.** Simplest code, but it turns a transient
   Kafka blip into a crash. Without a supervisor (OPS-H1), the downloader just stops. With one, it crash-loops, re-handling the record 3× per restart.
3. **Keep committing, but write the failed record to a local file or DB table as a fallback DLQ.** It adds new storage and a schema, and operators
   would have to look in two places (§5.3). Rejected.
4. **Remove `BlockRebalanceOnPoll` instead of calling `AllowRebalance`.** Then a rebalance can happen mid-record, and we may commit a partition
   we no longer own, which can rewind another member's commit (franz-go doc). Calling `AllowRebalance` per poll is one line and keeps the safety.

## Contracts and invariants
- Shared contracts touched: **none**. No change to the event envelope, topics, `DLQPayload`, HTTP API, schema or embedding model. `NewConsumer`'s
  signature doesn't change. The internal Go API now also rejects a nil producer, and its only caller passes a non-nil one.
- L4 commit-after-process: now true for the Go consumer, and the cumulative-commit case is covered by sequential, blocking resolution.
- Retry 3× with backoff 200/400 ms: unchanged (`maxRetries`, `retryBackoff` untouched).
- DLQ with full diagnostics: same payload. Delivery is now guaranteed before the commit. A duplicate DLQ entry is possible on shutdown mid-publish.
- `traceparent`: still read from the record header into `DLQPayload.Traceparent` (asserted in AC2).
- arXiv politeness: improved, since the handler isn't re-run while the DLQ is down.
- `tests/test_m4_chaos.py`: its invariants (row counts under redelivery, DLQ payload) are exercised on the Python processor. Go-side behaviour is
  more conservative now, so it can't break them. AC11 runs it when a stack exists.

## Test plan
All tests are in `internal/kafka/consumer_test.go`, package `kafka`, stdlib plus franz-go types only. There is no broker, network or Docker. Fakes:
- `fakeClient`: a scripted list of `kgo.Fetches`, built from exported structs: `kgo.Fetches{{Topics: []kgo.FetchTopic{{Topic, Partitions: []kgo.FetchPartition{{Partition, Records, Err}}}}}}`.
  When the script runs out, it cancels the test ctx and blocks until `<-ctx.Done()`. It records an ordered event log (`poll`, `commit t/p@o`, `allow`).
  `CommitRecords` can be told to fail.
- `fakeDLQ`: records each `(topic, payload)` into the same ordered log (`dlq t/p@o`) and returns scripted errors.
- `fakeWait`: records requested durations and returns nil, or `ctx.Err()` when ctx is done. The handler is a closure with per-offset scripted errors and a call counter.

| Acceptance criterion | Test (name / type) | Runs in CI? |
|---|---|---|
| AC1 success path | `TestConsumerSuccessPath`, table: `ok on 1st`, `ok after 1 failure`, `ok after 2 failures`. Asserts exactly one `commit` for the record, 0 DLQ calls, waits `[]`, `[200ms]`, `[200ms 400ms]` | yes, `make test-go` |
| AC2 DLQ path + order | `TestConsumerDLQThenCommit`: always-failing handler, DLQ ok. Asserts 1 call to `<topic>.dlq` with `OriginalTopic`, `Partition`, `Offset`, `Attempts==3`, `ConsumerGroup`, `Traceparent` (from header), and the log order `dlq p0@5` **before** `commit p0@5` | yes |
| AC3 DLQ fails → no commit | `TestConsumerDLQFailureBlocksPartition`: poll `[p0@5 fails, p0@6 ok]`, DLQ always errors, fakeWait cancels ctx after round 3. Asserts no commit for p0 with record offset ≥ 5, handler never called for @6, `PublishDLQ` called ≥ 2× for @5 (retried in place), handler for @5 called exactly 3×, `Start` returns nil. Records committed before @5 in the same poll (p0@4 in a second table row) **are** committed | yes |
| AC4 recovery | `TestConsumerDLQRecovers`: DLQ fails, fails, then ok. Asserts exactly 1 successful DLQ message, 1 commit (after it), handler calls == 3 (bounded: not re-run per round), DLQ waits `[1s, 2s]` recorded by fakeWait (context-aware wait between rounds, no busy loop) | yes |
| AC5 nil producer | `TestNewConsumerRejectsNilProducer` (constructor returns an error, no client created). `TestConsumerNilDLQIsFailedPublish` (struct literal with `dlq: nil`, behaves as AC3: no commit) | yes |
| AC6 ctx cancel in backoff | `TestConsumerCancelDuringBackoffReturnsPromptly`: real `ctxWait`, `backoff` returns 5s, handler fails and a goroutine cancels ctx 20 ms later. Asserts `Start` returns in < 200 ms, 0 commits, 0 DLQ calls. Plus `TestCtxWait` table (expires → nil; cancelled → `context.Canceled` within 50 ms). The grep in Verification proves no `time.Sleep` | yes (grep: QA/PR evidence) |
| AC7 real loop schedule | `TestRetrySleepSchedule` **rewritten**: drives `Start` with fakeWait and an always-failing handler, DLQ ok, and asserts waits == `[200ms, 400ms]`. `TestRetryBackoff` kept unchanged; `TestDLQRetryBackoff` table added (1,2,4,8,16,30,30 s) | yes |
| AC8 AllowRebalance | `TestConsumerAllowRebalanceAfterEachPoll`: 2 polls with 2 records each (2 partitions) plus 1 poll that has only an error. Asserts log order `poll, commit, commit, allow, poll, commit, commit, allow, poll, allow`: exactly one `allow` per poll, after that poll's commits | yes |
| AC9 log hygiene | `TestConsumerDLQFailureLogNoValue`: `log.SetOutput(&buf)` (restored in `t.Cleanup`), record value contains the sentinel `SENTINEL-VALUE-7f3a`, DLQ fails once then ok. Asserts that the log contains the topic, `partition=0`, `offset=5` and the error text, and does **not** contain the sentinel | yes |
| AC10 mutation check | QA mutations: (a) add `c.client.CommitRecords(ctx, rec)` after a failed publish (or commit regardless of `resolved`) → killed by AC3 and AC9 tests. (b) replace `c.wait(...)` with `time.Sleep(...)` → killed by AC6 (timing) and AC7 (fakeWait sees no calls). Also (c) drop the `defer AllowRebalance` → AC8; (d) re-run the handler per DLQ round → AC4 | needs a Go runner with franz-go (see Open questions) |
| AC11 M4 | `make stack-up && make test-full` (via OPS-H1's `stack.yml` `workflow_dispatch` on this branch, if OPS-H1 has merged); otherwise "not run: no stack" plus that command | only after OPS-H1 |
| Extra (§6) | `TestConsumerPollErrorStillProcessesRecords`: a fetch with p0 error + p1 records. p1 records are handled and committed, the error is logged | yes |
| Docs | Proposed wording in ticket Notes (below). The edit is made in this PR only if OPS-H1 has merged | n/a |

Failure paths covered: handler error ×1/×2/×3, DLQ error transient and permanent, nil publisher, ctx cancel in a handler wait, in a DLQ
wait and inside the handler, commit error (logged, loop continues: a table row in AC1), partition-level poll error, closed client.

All tests are table-driven where there's more than one case. They use `-race`-safe fakes (a mutex in the fakes, since the AC6 cancel goroutine shares state).
Total test runtime target: < 1 s, with no real waits except AC6's ≤ 200 ms.

**Docs wording (for Notes; edit only after OPS-H1 merges):**
- `README.md:39`: no change in this PR. "Every Kafka stage" would overclaim the stronger guarantee until OPS-H8 fixes Python. After
  OPS-H8: "…then routes to a `<topic>.dlq` topic carrying full diagnostics; the offset is committed only once that write is confirmed."
- `CONTRIBUTING.md:57`: "Natural-key upserts, commit-after-process (commit only after success or a confirmed DLQ write; if the DLQ is
  unreachable the consumer waits and retries rather than skipping), 3× retry with backoff then DLQ with full diagnostics, idempotent replays".

## Risks and rollout
- **Risk: the consumer stalls while the DLQ is down.** This is intended. It is detected by the per-round `CRITICAL` log line and by consumer lag.
  It recovers on its own when Kafka is back. If a single poison payload made `PublishDLQ` itself fail forever (for example a marshal error, which can't happen for
  `DLQPayload` of strings, numbers and maps decoded from JSON), the stall would be permanent. The log names the exact offset, so an operator can skip it by hand.
  I'm noting this rather than designing around it.
- **Risk: group eviction during a long stall** (§4). The result is a duplicate, not a loss.
- **Risk: franz-go doc quoted from memory.** The implementer verifies the text against v1.16.1 `go doc` and corrects this file if it differs.
- **Rollback:** revert the single PR. No schema, contract or config migration.

## Open questions (for pm-lead)
1. **AC3 wording vs. the chosen mechanism.** AC3 ends "the record at offset 5 is redelivered (handled again) or `Start` returns an
   error". The mechanism chosen here is the ticket's third option (retry the DLQ write in place), so the observable outcome is "the DLQ write for @5
   is retried (≥ 2 publish calls), @6 is never handled, nothing ≥ 5 is committed, `Start` returns nil on ctx end". Please amend AC3 to match, or
   pick another mechanism.
2. **Scope add §6** (poll errors drop records): OK to fix here with one extra test? It's the same L4 bug in the same function.
3. **Evidence path for a Go package that imports franz-go.** The sandbox has Go 1.24.7, no franz-go in the module cache, and proxy.golang.org is
   unreachable. Unlike AI-2's `rag.go`, a stdlib-only scratch run isn't possible. CI `make test-go` runs `go test ./...` (no `-race`, no `-v`).
   Proposal: in this PR, change `test-go` to `go test -race -count=1 ./...` (harness is backend-owned; ubuntu runners support it; it costs a few seconds).
   For the per-test names, coverage and AC10 mutation results QA needs, pick one: (a) add a CI step that runs
   `go test -race -count=1 -v -coverprofile=c.out ./internal/kafka/ && go tool cover -func=c.out | grep consumer.go`; or (b) QA reads the
   CI result of short-lived mutation commits. (b) needs someone to push them, which the role rules don't clearly allow. I recommend (a) for the verbose
   and coverage rows, and accepting AC10 as "mutations run in CI via a QA-requested commit on the PR branch, reverted in the next commit" if you agree.
4. **Follow-ups G1/G2** (§5): file as Backlog?

## PM decision
**Decision: APPROVED with binding conditions** (pm-lead, 2026-11-03, design at `e7dadd1`, code at `9c1229a`).

Why: the design answers all six "Design must answer" items. Retrying the DLQ write in place is the right mechanism. The single
sequential loop makes "nothing at or after N is committed" structural, so cumulative commits can't sweep the record up. The handler
isn't re-run (arXiv politeness, Product PRD §7). A Kafka blip doesn't turn into a crash loop while workers are unsupervised (OPS-H1).
The stall is loud: a CRITICAL log every round plus consumer lag, and no data is lost. That fits OPS-1/§5.3. I re-checked the code refs
(`consumer.go:30`, `:71-76`, `:102`, `:129-139`) against `9c1229a`. There's one test per AC, and the failure paths are listed.

Answers to the open questions:
1. **AC3: mechanism accepted. AC3 is amended in the ticket** to: DLQ write retried in place (≥ 2 `PublishDLQ` calls for @5), handler
   for @5 called exactly 3×, @6 never handled, no commit for p0 at offset ≥ 5, and `Start` returns nil when ctx ends.
2. **§6 (a poll error drops the whole poll): accepted in this task** as new **AC12**. It's the same L4 bug in the same function. Limits: only
   `consumer.go` + `consumer_test.go`, and one test (`TestConsumerPollErrorStillProcessesRecords`; a table row for `kgo.ErrClientClosed` → `Start`
   returns it is allowed and expected). If the PR would go over 400 changed lines, cut §6 into a follow-up. Don't trim AC1–AC10 tests to make room.
3. **Evidence.**
   - **No `Makefile` change in this PR.** OPS-H1 runs in parallel and changes `Makefile` (AGENTS.md §3: parallel tasks must not touch the
     same files). Changing `test-go` to `-race -count=1` is a follow-up for after OPS-H1 merges (ticket Notes).
   - **Option (a) accepted, in `.github/workflows/ci.yml` only** (OPS-H1 is barred from `ci.yml`). Add one step to the `go` job, after
     `make test-go`, named `Kafka consumer tests (verbose, race, coverage)`, that runs:
     `go test -race -count=1 -v -coverprofile=c.out ./internal/kafka/ && go tool cover -func=c.out | grep consumer.go`.
     That's ≤ 3 lines; no other workflow changes.
   - **AC10, how mutations are evidenced** (QA never pushes to ArxivLens; only the owning developer pushes to `agent/backend/OPS-H6`):
     before moving the ticket to In QA, the developer pushes each mutation as its own commit, then a revert commit. Commit
     messages are `mutation(AC10a): commit after failed PublishDLQ` and `mutation(AC10b): time.Sleep instead of c.wait`, each followed by
     `revert mutation(AC10x)`. Each mutation commit holds **only** that mutation in `consumer.go`, with no test edits.
     **Wait for that commit's CI run to finish before pushing the next commit**: `ci.yml` has `concurrency: cancel-in-progress: true`,
     so a quick push would cancel the run and leave no evidence. The developer lists the mutation SHAs and run URLs in the ticket Notes.
     QA checks the evidence on its own: it opens each mutation commit's diff on GitHub, confirms the diff is exactly the stated mutation,
     confirms that run's `go` job is red with a named failing test, and confirms the final head is green and its tree has `consumer.go`
     identical to the pre-mutation commit (`git diff <pre> <head> -- internal/kafka/` is empty). Mutations (c) and (d) from the test plan
     are optional; QA may request them in a FAIL report, and the developer runs them the same way. If CI is red on a mutation only because of
     a compile error, the mutation doesn't count. Mahesh merges with squash or rebase, either way the reverts net to zero.
   - Local evidence: "not run locally: Go 1.24.7, no franz-go" is acceptable. CI is the source of truth.
4. **G1 and G2 are filed in the board Backlog.** G3 isn't filed: it needs an envelope ADR, and we don't propose one now.

Binding conditions (QA checks each one):
- C1. The diff touches only `internal/kafka/consumer.go`, `internal/kafka/consumer_test.go` and the one `ci.yml` step above. It touches
  `CONTRIBUTING.md:57` only if OPS-H1 has merged before this PR is built. No `Makefile`, no `README.md` (README:39 stays until OPS-H8), and no `cmd/`.
  Total diff stays under 400 changed lines.
- C2. Before writing code, verify the franz-go v1.16.1 `BlockRebalanceOnPoll` / `AllowRebalance` doc text against the source
  (pkg.go.dev or the module source, if reachable). Correct §4 of this design if it differs. If neither is reachable, write "doc quote unverified"
  in Notes, and QA checks it against the v1.16.1 source on GitHub.
- C3. `maxRetries`, `retryBackoff`, the `DLQPayload` fields and `NewConsumer`'s signature are unchanged. `FailedAt` is set once per record.
- C4. The CRITICAL DLQ-failure log uses the exact format in §7. Logs never include the record value or the payload (AC9).
- C5. Every wait goes through `c.wait`. There is no busy loop: the fakes in the AC3/AC4 tests assert the recorded wait durations.
- C6. The §8.1/§8.2 sequence text from §7 goes in the ticket Notes for pm-lead's docs PR.
- C7. AC11: "not run: no stack" plus the command is acceptable unless OPS-H1 has merged. In that case, run it via `stack.yml` on this branch.

**PM final review, round 1 (pm-lead, 2026-11-03, PR #15 at `7814563`): CHANGES. Conditions amended:**
- C1 (amended): the round-1 rework may push the diff past 400 changed lines **only** for the one added test (change 1 in
  `agents/reviews/OPS-H6/report.md`), with a hard cap of 420. No other code change.
- C2 (closed this way): agents can't reach the franz-go v1.16.1 source (QA evidence 09). The code doesn't depend on the exact wording,
  because one `AllowRebalance()` after every poll is correct under either reading, and the CI build proves the API exists. C2 closes as
  **"verified by Mahesh at PR review"**: the raised PR carries a reviewer check item for the godoc of `kgo.BlockRebalanceOnPoll` and
  `(*kgo.Client).AllowRebalance` at tag v1.16.1. If the doc text contradicts §4, that's a review comment, and it goes back to the developer.
- Test plan correction: the "Failure paths covered" line and the "a mutex in the fakes" sentence must match the code (change 2 in the report).
