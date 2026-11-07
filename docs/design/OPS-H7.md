# Tech design — OPS-H7: DLQ list/replay with partition/offset checkpoints, paging, a replay lock and idempotent replay

**Author:** backend-engineer · **Ticket:** `agents/tasks/OPS-H7.md` · **PRD:** Product OPS-2, OPS-3, §5.3; Technical §5 (DLQ manager), §8.2 · **Status:** Approved with conditions 2026-11-07 (pm-lead; split into OPS-H7f/a/b/c, see PM decision)

Code refs are to ArxivLens `origin/main` `2b71772`.

## Problem
`internal/dlq/manager.go` cannot drain a DLQ. `ListEvents` starts a group-less client at the topic start (`:30-34`) and stops at a 2 s
deadline or on the first empty or failed poll (`:41-56`). It also drops any record that is not a valid `DLQPayload` without saying so (`:62-64`), and it
never returns partition or offset. `Replay` republishes the first `limit` of those records (`:79`) with no checkpoint, so every run repeats
the same head and never reaches the tail. Nothing stops two concurrent runs.

I found two more bugs on the same path. Both make replay unsafe on top of the above:
- **B1, empty `event_id`.** `json.Unmarshal` of a map into `EventEnvelope` (`:114-115`) does not fail when the keys are missing. So a raw payload is
  republished with `event_id: ""`, `event_type: ""`, `paper_id: ""`, and the re-envelope fallback (`:117`) almost never runs. The processor's L2
  ledger is keyed on `(consumer_group, event_id)` (`migrations/000001_init_schema.up.sql:65-70`, `services/processor/worker.py:79`). The first `""` event
  is processed. **Every later `""` event, for any paper, is treated as a duplicate and its DB write is skipped.**
- **B2, null original value.** If the failed record's value was not a JSON object, the Go consumer stores `OriginalValue = nil` (`internal/kafka/consumer.go:163-164`).
  `Marshal(nil)` gives `null`, and `Unmarshal("null")` into the struct is a no-op without an error. So replay publishes an all-empty envelope.

This design covers AC1–AC8.

## Approach

### Shape
`Manager` gets three small dependencies so the logic can be unit-tested with fakes:

```go
type Watermark struct{ Low, High int64 }              // High = next offset to be written (exclusive)
type Record struct {                                  // one DLQ record, decoded or not
    Partition int32; Offset int64; Timestamp time.Time
    Payload *events.DLQPayload                        // nil when the value is not a valid DLQPayload
}
type Reader interface {                               // kgo adapter in internal/dlq/kafka.go
    Watermarks(ctx context.Context, topic string) (map[int32]Watermark, error)
    // Read calls fn for each record of one partition with from <= offset < until, in offset order; fn returns false to stop.
    Read(ctx context.Context, topic string, p int32, from, until int64, fn func(Record) bool) error
}
type Publisher interface { Publish(ctx context.Context, topic string, e events.EventEnvelope) error } // *kafka.Producer
type Store interface {                                // Postgres impl in internal/dlq/store.go
    TryLock(ctx context.Context, dlqTopic string) (unlock func(), ok bool, err error)
    Checkpoints(ctx context.Context, dlqTopic string) (map[int32]int64, error)
    Resolved(ctx context.Context, dlqTopic string, p int32, from int64) (map[int64]bool, error)
    MarkResolved(ctx context.Context, r Resolution) error // inserts the row + moves the checkpoint, in one tx
}
func (m *Manager) List(ctx, topic string, opt ListOptions) (Page, error)   // ListOptions{Partition *int32; From Cursor; PageSize int}
func (m *Manager) Replay(ctx, topic string, opt ReplayOptions) (ReplayResult, error) // ReplayOptions{ErrorType; Limit; DryRun}
```

`cmd/arxivlens/main.go` (`:266-368`) wires the kgo reader, `kafka.NewProducer` and (for `replay` only) `db.Connect(cfg.PostgresURL)` into the store.
`list` and `inspect` stay Kafka-only.

### Q1. Where checkpoints live: Postgres (recommended)
A new additive migration (the next free number at build time; `000003` is reserved by RET-2, `docs/design/RET-2.md:63`, so likely `000004_dlq_replay`):

```sql
CREATE TABLE IF NOT EXISTS dlq_replay_checkpoints (   -- every offset < next_offset is resolved
  dlq_topic TEXT NOT NULL, partition INT NOT NULL, next_offset BIGINT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY (dlq_topic, partition));
CREATE TABLE IF NOT EXISTS dlq_replay_log (           -- one row per resolved DLQ record
  dlq_topic TEXT NOT NULL, partition INT NOT NULL, dlq_offset BIGINT NOT NULL,
  outcome TEXT NOT NULL CHECK (outcome IN ('replayed', 'unreplayable')),
  target_topic TEXT, event_id TEXT, resolved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (dlq_topic, partition, dlq_offset));
```

Reasons:
- **Holes.** A Kafka group offset is a single "everything below is done" number. It cannot represent "offset 7 was skipped by the filter, 8 was
  replayed" (Q6). The log table can. The checkpoint is only a scan start, so we don't re-read the whole partition every run.
- **Atomic with the record of what was replayed.** The row and the checkpoint move in one Postgres transaction. With Kafka offsets plus a
  separate record, they could drift.
- **The lock is in Postgres anyway (Q4).** Everything replay touches is then in one place.
- **Visibility and reset.** `SELECT * FROM dlq_replay_checkpoints` / `dlq_replay_log` shows them, and every replay run prints the per-partition
  checkpoint and the start-time high watermark. Reset is `DELETE ... WHERE dlq_topic = $1`, documented in README. Multi-topic is the `dlq_topic` key.
  With a consumer group, you'd need `kafka-consumer-groups.sh --describe/--reset-offsets` and group membership (a stray member would trigger a rebalance).
- Cost: `replay` now needs Postgres (`DATABASE_URL`). That's acceptable, since every operator flow already runs `migrate` first.

Ordering: replay walks partitions in ascending order, and offsets in ascending order within a partition. "Records 1..N" in AC2 means that order.

### Q2. End of topic: start-time watermarks, no wall-clock deadline
- At the start of `list`/`replay`, `Reader.Watermarks` sends one `kmsg.ListOffsetsRequest` (timestamp `-2` = log start, `-1` = high watermark) through
  `client.Request`, which franz-go shards to the partition leaders. `kmsg` is already in `go.mod` as an indirect dependency of `franz-go v1.16.1`,
  so it moves to a direct require with no new module and no download. `kadm` is **not** used, because it would be a new module.
- Each partition is read with `kgo.ConsumePartitions({topic: {p: NewOffset().At(from)}})`. It uses no group and commits nothing. A partition is done
  when a record with `offset >= until-1` arrives (`until` = snapshot `High`). Records at or past `until` are ignored. A DLQ record that arrives during the run,
  including one caused by this run's own replays, waits for the next run, so a run always terminates.
- **Empty partition** (`Low == High`): skipped without a fetch.
- **Checkpoint below `Low`** (retention deleted records that were never replayed): the reader starts at `Low`, and the run prints
  `WARNING partition 3: offsets 10..41 expired before replay` to stderr. The checkpoint then moves to `Low`, because those records can't be read again.
- **Compacted topic / offset gaps.** The DLQ topics are created by compose with the default `delete` cleanup policy (`docker-compose.yml:101-103`),
  so offsets between `Low` and `High` are contiguous. As a guard, if a partition makes no progress for 10 s while `position < until`, `Read`
  returns `ErrPartitionStalled{p, lastOffset, until}`. That is an **error**, not a silent stop: `list` prints it and exits non-zero. `replay` keeps every checkpoint already
  written and exits non-zero. The fake reader test injects it.
- Poll and partition errors are returned instead of being treated as "end" (today `:51-53` stops silently).

### Q3. Paging flags and output
```
arxivlens dlq list [--topic T] [--partition P] [--from P/O] [--page-size 50] [--all]
```
- Each record line starts with `P/O`, the same form `--from` takes:
  `3/17  key=2401.00001  error=PdfParseError  failed_at=...  -> papers.downloaded` and then the message line, as today (`main.go:291-296`).
  An undecodable record prints `3/18  UNDECODABLE (n bytes)`, so it is never hidden.
- `--from P/O` is the page cursor. It starts at partition `P` offset `O`, then continues with the later partitions from their `Low`. `--partition P` restricts the listing to one
  partition. `--page-size` caps the records per page. `--limit` stays as a hidden alias of `--page-size` (AC7).
- The footer is either `next page: arxivlens dlq list --topic T --from 3/67` or
  `end of topic (high watermarks at start: 0=12 1=0 ... 11=4; 57 records)`. `--all` prints every page to the end in one run, which is what
  `stack.yml:173,184,244` diagnostics want.
- `inspect --key` scans the whole topic to the watermarks with the same reader (today it sees only the first 100 records, `main.go:309`), and prints `P/O`.
  The flags don't change.
- `--from-offset` (named in the ticket) is not added. `--from P/O` names a cursor across partitions in one flag, and it matches the printed form.

### Q4. Lock: Postgres session advisory lock
- `TryLock` acquires a **dedicated** connection from the pool (`pool.Acquire`) and runs
  `SELECT pg_try_advisory_lock(hashtextextended('arxivlens.dlq.replay/' || $1, 0))`. If that returns false, `replay` prints
  `another 'dlq replay' holds the lock for papers.downloaded.dlq (pid 1234 on <client_addr>, since <backend_start>)` and exits **1**.
  The pid and address come from `pg_locks JOIN pg_stat_activity`, best effort. It publishes nothing and does not read the topic.
- `unlock` runs `pg_advisory_unlock` and releases the connection. It is deferred, and it also runs on SIGINT/SIGTERM through `signal.NotifyContext`.
- **Crashed holder:** a session lock belongs to the backend session. When the process dies, its TCP connection closes and Postgres releases the lock
  at once. No TTL or heartbeat is needed. A **hung but alive** holder keeps the lock. The README shows the `pg_stat_activity` query and
  `pg_terminate_backend(pid)` to release it. Residual risk: a network partition leaves the session until TCP keepalive notices. The lock connection
  sets `tcp_keepalives_idle=30` on its connection string to bound that.
- The lock is per DLQ topic, so replays of different DLQs run in parallel.
- Rejected: a lock row with a TTL needs heartbeats, clock agreement and a steal race. A Kafka group as the lock would make the second member share
  partitions after a rebalance instead of failing fast.

### Q5. Idempotent replay
Per record, in order: build the envelope, `Publish`, and only after it returns nil, `MarkResolved` (row + checkpoint in one tx). `Publish` is
`ProduceSync` and returns only after the broker acks (`internal/kafka/producer.go:56-59`). So **the checkpoint never passes an un-acked publish**.
If the process crashes between the ack and the commit, the next run publishes the record again. The rule below makes that the **same `event_id`**:

| `OriginalValue` | Envelope published | `event_id` |
|---|---|---|
| decodes to `EventEnvelope` **and** `event_id`, `event_type`, `paper_id` are non-empty | that envelope, `Attempt = 0`, `Traceparent` = DLQ's (as today, `:119-120`) | original (unchanged) |
| a non-empty JSON object that is not a full envelope (fixes B1) | `EventEnvelope{EventType: target, PaperID: OriginalKey, Version: 1, Payload: value}` | **deterministic ULID** (below) |
| nil / empty, or the DLQ record itself is undecodable (fixes B2) | none. Resolved as `unreplayable`, printed with `P/O` | n/a |

**Deterministic ULID:** the timestamp is the DLQ record's Kafka timestamp in ms. The 80-bit entropy is the first 10 bytes of
`SHA-256("arxivlens/dlq-replay\x00" + dlqTopic + "\x00" + partition + "\x00" + offset)`. It is built with `ulid.New(ms, bytes.NewReader(entropy))`
(`oklog/ulid/v2`, already a direct dependency). The same DLQ record always gives the same ID. It is still a valid, time-sortable ULID, so the
envelope contract holds (`shared/events/events.go:22`, `docs/PRD-Technical.md:139` "`event_id` is a ULID"). **No envelope, `DLQPayload` or `events.py` change, so no ADR.**
`OccurredAt` is the same Kafka timestamp (RFC 3339), so the re-publish is byte-identical apart from `traceparent`.

Downstream treatment of a duplicate:
- `papers.downloaded` → processor. The L2 ledger hits on the same `event_id` (`worker.py:79-89`): it skips the chunk writes and re-emits `papers.chunked`.
  If the first copy failed again, there is no ledger row (the transaction rolled back, `worker.py:107-108`). The paper is processed or DLQ'd again, and the new
  DLQ record is a new offset that the next run replays once.
- `papers.discovered` → Go downloader. It has no ledger, but the L1 object-exists check and the natural-key `UPDATE` keep the row count (OPS-H6 design §5, gap G1).
- `papers.chunked` → embedder. L3 skips chunks that already have a vector for the model.

Alternative considered: derive the ID from the *original* coordinates (`OriginalTopic/Partition/Offset`). That would also dedupe two DLQ entries of
the same raw record (possible on shutdown mid-publish, OPS-H6 §3). Rejected: we don't know the original record's timestamp, so the ULID time part would be
made up. That case also only arises for raw payloads, and L1/L3 natural keys already absorb it.

### Q6. Filters keep skipped records eligible
With `--error-type X`, a decodable record whose `ErrorType` doesn't match is **not resolved**: there is no log row. From that offset on, the
partition's checkpoint stops moving for the rest of the run. Later matching records are still published and logged. Their log rows make the
next run skip them. Concretely, per partition: `contiguous = true` at the start. Each resolved record (new, or already in `Resolved(...)`) moves
`next_offset` to `offset+1` while `contiguous`. The first skipped record, or reaching `--limit`, sets `contiguous = false`. A later run without the filter starts at
the checkpoint, sees the logged records as already resolved, and publishes only the skipped ones (AC5). `unreplayable` records are resolved under any
filter, so they don't pin the checkpoint forever. `--limit N` counts **published** records across partitions.

### Q7. `--dry-run`
Dry-run reads `Checkpoints` and `Resolved`, which are plain `SELECT`s, so its output matches what a real run would publish, with the `event_id` it would use. It
**does not take the lock** and **never calls `Publish` or `MarkResolved`**. With no lock, a dry-run can preview while a real replay runs, and it cannot
block one. Its output is labelled `DRY RUN (no lock taken; may race a concurrent replay)`.

### Files and size estimate (changed lines, including tests)
| File | Part a | Part b | Part c |
|---|---|---|---|
| `internal/dlq/kafka.go` (new: kgo `Reader`, watermarks via `kmsg`) | 110 | | |
| `internal/dlq/manager.go` (`List`, cursor, page) | 70 | 120 (`Replay` loop, checkpoints, filters, dry-run) | 40 (envelope rule + deterministic ULID) |
| `internal/dlq/store.go` (new: pgx `Store`) | | 70 | 35 (`TryLock`) |
| `migrations/00000N_dlq_replay.{up,down}.sql` | | 15 | |
| `cmd/arxivlens/main.go` (`dlq` subcommands) | 40 | 30 | 15 |
| `internal/dlq/manager_test.go` (fakes, table-driven) | 130 | 170 | 90 |
| `internal/dlq/*_integration_test.go` (`-tags integration`) | 60 (reader) | 40 (store) | 40 (lock crash) |
| `.github/workflows/db.yml` (Kafka service + `go test -tags integration ./internal/dlq/`) | 25 | | |
| `README.md` / `CONTRIBUTING.md` | 6 | 6 | 6 |
| `go.mod` (`kmsg` → direct) | 2 | | |
| **Total** | **~445** | **~450** | **~225** |

The whole task is **~1,100 lines**, well over 400. **Split recommended: three parts, not two.** The ticket's two-way split puts (b) at ~675, still over the limit.
Even the three-part split has (a) and (b) at ~450. That is over the 400 target, because each part ships its fakes and integration test. I'd rather
trim prose than tests. If the cap is hard, the `kafka.go` integration test in (a) could move to (c), which brings (a) to ~385.

| Part | Scope | ACs |
|---|---|---|
| **OPS-H7a** list to end + paging | `Reader`, watermarks, `List`/`inspect` to end, `P/O` output, `--partition`/`--from`/`--page-size`/`--all`, the `--limit` alias, the CI Kafka service | AC1, AC7 (list/inspect) |
| **OPS-H7b** checkpoints + resume + filters + dry-run | migration, `Store` (without the lock), `Replay` loop, ack-then-commit | AC2, AC5, AC6, AC7 (replay) |
| **OPS-H7c** lock + idempotent IDs + integration | `TryLock`, envelope rule (B1/B2), deterministic ULID, AC8 stack run | AC3, AC4, AC8 |

The parts run in order: b depends on a, and c depends on b. They touch the same files, so they are never parallel. The README/CONTRIBUTING edits wait for PR #26 (OPS-H10) to merge.
**Risk if c ships later than b:** B1/B2 stay live on a replay that now drains the whole topic. Mitigation: b keeps today's envelope code, and c follows right after.
The alternative is to move the ~40-line envelope rule and its tests into b, which puts b at ~510.

## Alternatives considered
1. **Kafka consumer group `arxivlens-dlq-replay` with committed offsets.** It can't express filter holes, and a stray member causes a rebalance. Visibility and reset go through Kafka
   admin tools, and the lock would need a separate store anyway. Rejected (Q1).
2. **No checkpoint table: scan the whole partition every run and rely on the log table only.** It is simpler, and DLQs are small. Rejected because the
   ticket asks for resumable checkpoints, the scan cost grows with retention, and the checkpoint costs one upsert in the same transaction.
3. **A wall-clock deadline (today's design) or "stop at the first empty poll".** It can end early under load, which is the bug being fixed (Q2).
4. **A lock row with a TTL** (Q4): it needs heartbeats and has a steal race. Advisory locks release on session end for free.
5. **Batch commits (checkpoint every N records)** are faster, but a crash re-publishes up to N. Per-record transactions are fine at DLQ volumes.

## Contracts and invariants
- **Shared contracts:** the event envelope, `DLQPayload`, topics, HTTP API and `events.py` are **unchanged**. The deterministic `event_id` is still a ULID. Schema: two **additive**
  tables (no ADR, AGENTS.md §2). CLI flags change, not the HTTP API, and the README CLI table is updated (`README.md:183-185`).
- L2: replay keeps the original `event_id`, or a deterministic one, so the processor ledger dedupes a re-publish. L1/L3 are untouched. L4 does not apply (replay
  has no consumer group). The analogous rule is that the checkpoint is written only after the broker acks.
- Retry/DLQ: the consumer is not touched. `Attempt` is reset to 0 as today, so the replayed record gets the full 3× retry.
- `traceparent`: copied from `DLQPayload.Traceparent` into the envelope and header, as today (`manager.go:120`, `producer.go:49-54`).
- `tests/test_m4_chaos.py` is unaffected (it doesn't call the CLI). It produces the corrupt-PDF DLQ record used for AC8.

## Test plan
Unit tests (`internal/dlq/manager_test.go`, table-driven, no infra): `fakeReader` (scripted watermarks plus per-partition records, delivered in chunks of 3
so one page needs several underlying polls; injectable `ErrPartitionStalled` and poll errors), `fakePublisher` (records `(topic, envelope)`, fails on a scripted call),
`fakeStore` (in-memory checkpoints/log/lock, records every write, `MarkResolved` can fail on a scripted call).
Integration tests (`-tags integration`, real Kafka + Postgres in a new CI job in `db.yml`: `apache/kafka` KRaft service + the existing pgvector service, so they run on every PR,
following the `search_integration_test.go` pattern).

| AC | Test | Type / runs in CI? |
|---|---|---|
| AC1 | `TestListPagesToHighWatermark`, table: 1 partition of 25 records with page 10 (3 pages, last cursor = end); 3 partitions where one is empty; records beyond the snapshot High are not returned; `--partition` filter; checkpoint below Low warns. The union of pages equals all records, each with the right `P/O`. Plus `TestReadStopsAtSnapshot_Integration`: real topic, 3 partitions (one empty), 1,500 records, `FetchMaxBytes` small enough to force ≥ 5 polls | unit + integration, yes (a) |
| AC1 errors | `TestListPropagatesStallAndPollErrors` → error, non-zero exit path | unit, yes (a) |
| AC2 | `TestReplayResumes`: 2N records over 2 partitions, `--limit N` twice. The publisher sees records 1..N, then N+1..2N, with no repeat or gap. The checkpoint after run 2 = High. A third run publishes 0. The integration variant asserts on the real target topic's contents | unit (b) + integration (b) |
| AC3 | `TestReplayRefusedWhileLocked`: fakeStore lock held → `ErrLocked`, 0 `Publish`, 0 `Read` calls. CLI prints the message, exit 1. `TestAdvisoryLock_Integration`: conn A locks; B's `TryLock` returns false; A's backend is killed with `pg_terminate_backend` (simulated crash); B gets the lock. A different topic locks at once | unit + integration, yes (c) |
| AC4 | `TestReplayCrashAfterPublish`: `MarkResolved` fails on record k. Run 1 errors after publishing k. Run 2 publishes k again with an **identical `event_id`** and continues. `TestEnvelopeRule` table: full envelope keeps its ID; raw payload → deterministic ULID (same input → same ID, `ulid.Parse` ok, time = Kafka ts, different offset → different ID); missing `event_id` (B1) → fallback; nil value (B2) → unreplayable. Downstream: reference `worker.py:79-89` + `processed_events` PK. AC8 shows row counts unchanged | unit, yes (c) |
| AC5 | `TestReplayFilterKeepsSkippedEligible`: mixed error types, `--error-type A` publishes only A, checkpoint stops at the first B. A run without the filter publishes only the Bs, and each record is published exactly once overall | unit, yes (b) |
| AC6 | `TestReplayDryRun`: 0 `Publish`, 0 `MarkResolved`, 0 `TryLock`. The checkpoints are unchanged, and the result lists the would-be `P/O` and `event_id` | unit, yes (b) |
| AC7 | `TestDLQFlags` (cobra): `--topic`, `--error-type`, `--limit` (list alias and replay), `--dry-run`, `inspect --key` parse and reach the manager with the same values. README table diff | unit, yes (a, b) |
| AC8 | Compose stack: `make stack-up && ./bin/arxivlens migrate && make test-full` (M4 leaves corrupt-PDF records in `papers.downloaded.dlq`), then `dlq list --all`, `replay --limit 1` twice, `dlq list --all` again, and `kafka-get-offsets.sh --topic papers.downloaded` before and after each run. Run via `stack.yml` `workflow_dispatch` on the branch; the step is added there in (c). "not run: no stack" only with these exact commands | integration, manual dispatch (c) |

Failure paths covered: stalled partition, poll error, publish error (stop, no checkpoint), `MarkResolved` error (re-publish on the next run), lock held,
Postgres down for `replay` (it fails before reading), expired offsets, undecodable records, an empty partition, and records arriving mid-run.

## Risks and rollout
- **Behaviour change:** `replay` now requires a migrated Postgres. The README and the error text (`run 'arxivlens migrate'`) say so. `list` output changes to `P/O` lines, and
  the `stack.yml` greps only print it (no parsing), so nothing breaks.
- **First run after deploy** has no checkpoint, so it replays every unresolved record still in retention. That is the intended "drain" behaviour, but operators should
  `--dry-run` first (README note).
- **B1 is fixed only in part c.** See the split risk above.
- **Rollback:** revert the PR. The new tables are inert, and the down migration drops them.

## Open questions
1. **pm-lead:** is a three-way split at ~450/450/225 acceptable against the 400 target, or should the integration tests move so (a) and (b) are under 400?
2. **pm-lead:** should the B1/B2 envelope fix ship in (b), or as a tiny standalone fix ahead of the split? Today's replay already publishes `event_id: ""` for raw payloads.
3. **Mahesh (FYI, no ADR needed):** a replayed raw payload gets a deterministic ULID whose time part is the DLQ record's timestamp, not the original event time.

## PM decision
**2026-11-07 (pm-lead): Approved with conditions, split into four tickets.** Spot-checked against ArxivLens `origin/main` `2b71772`.

**Claims checked.**
- These are as the design says: `manager.go:30-34` (no group, `AtStart`), `:41-56` (2 s deadline, break on error/empty poll), `:62-64` (silent drop),
  `:79` (replays the head), `:114-117` (B1), `consumer.go:163-164` (B2: `_ = json.Unmarshal` into a map, so a non-object value gives nil),
  `worker.py:79` + `000001_init_schema.up.sql:65-70` (ledger key), `producer.go:56-59` (`ProduceSync`), `docker-compose.yml:101-103` (delete
  policy), `main.go:309` (`inspect` sees 100), `stack.yml:173,184,244`, `kmsg v1.7.0 // indirect` and `oklog/ulid/v2` direct in `go.mod`.
- **B1 is real, but its consequence is overstated.** A B1 envelope has `paper_id: ""` and an empty `payload` (raw keys don't map onto
  envelope fields). The processor fails on it before it reaches the ledger: it falls back to storage key `raw/_v{n}.pdf` (`worker.py:45-52`),
  and the ledger check is at `:79`. The record is DLQ'd again with the broken envelope as `original_value`, and the producer keys it `""`
  (`producer.go:44`). Ledger poisoning needs a `""` event to *succeed*, which is possible but unlikely. Today B1 can only be reached through the Go
  consumer's DLQ (`papers.discovered.dlq`). Python DLQs only ever hold full envelopes, because `kafka_client.py:178-179` parses the envelope before
  the handler runs. **This changes when OPS-H8b merges.** Its AC7 sends poison records to the DLQ as `{"raw_value": ...}` or as the partial
  decoded dict (e.g. `{"event_id": "x"}`), so raw payloads will reach every DLQ. That is why the fix goes first.
- **Migration number: the design's citation is wrong.** `RET-2.md:63` is RET-2's *processor follow-up*, which became ING-11. RET-2 adds no
  migration. `000003` belongs to ING-11 (`docs/design/ING-11.md:44`, `000003_paper_chunk_pages`).
- **Deterministic ULID vs the envelope contract: no ADR needed.** The contract is the field set and types in `shared/events/events.go:21-30` and
  `events.py:20-28`, plus "`event_id` is a ULID, so IDs sort by time and work as dedup keys" (`PRD-Technical.md:139`). A
  `ulid.New(ms, 10-byte reader)` value is a valid 26-char ULID that sorts by its time part, and its distinct `(dlq_topic, partition, offset)`
  inputs keep it unique. Neither file changes. Nothing in the PRD or the ADRs says the time part must be the original produce time. The
  time-part caveat (open question 3) goes in OPS-H7c's PR description as an FYI for Mahesh.

**Answers to the open questions.**
1. **Size: rebalanced, and (a)/(b) accepted above 400 for test lines only, with a gate.** The ~40-line envelope rule and its tests move out of (c)
   into a standalone fix that ships first (OPS-H7f). The deterministic ULID stays in (c). Lessons LLM-1 and OPS-H8 say estimates near 400 came in
   30-70 % low. So each of a/b/c must **commit a counted skeleton first** (stubbed files + doc comments, `git diff --stat`, posted in the ticket Notes).
   If it projects **> 480 changed lines, or > 250 non-test lines**, stop and split at the seam named in the ticket. That seam is a layer
   boundary in each case: (a) kgo `Reader` + its integration test + `db.yml` / `List`+CLI on the fake. (b) migration + `Store` + its integration
   test / `Replay` loop on the fakes.
2. **Yes: B1/B2 ship first as OPS-H7f** (~130 lines, `internal/dlq/` only). It touches no file in any open PR, needs no README change and
   depends only on merged work. OPS-H8b (raw payloads into DLQs) and OPS-H7b (replay drains the whole topic) both widen B1's reach, so it should be
   in place before either.

**Conditions (each is an AC in the part tickets).**
1. Envelope rule (OPS-H7f, and kept by OPS-H7c). The design's table, plus: (i) the re-envelope row also needs a non-empty `OriginalKey`, since the
   producer keys by `PaperID`. (ii) An `original_value` whose only key is `raw_value` (`kafka_client.py:80`, OPS-H8b AC7) is **unreplayable**,
   because re-enveloping a stringified byte blob can only fail again. (iii) No code path may publish an envelope with an empty `event_id`,
   `event_type` or `paper_id`. (iv) Dry-run applies the same rule, so its count equals a real run's.
2. Migrations: **ING-11 = `000003_paper_chunk_pages`, OPS-H7b = `000004_dlq_replay`.** These numbers hold whatever the merge order.
   `migrate` re-applies every `*.up.sql` in lexical order (`main.go:89`), and both files are independent `CREATE TABLE IF NOT EXISTS`, so a
   later-merged `000003` is safe. The part that merges second rebases and sets `TestRepoMigrationsOrder`'s `want` (`internal/db/db_test.go:87`)
   to the full ordered list. If the `schema_migrations` ledger follow-up (OPS-H5) lands first, re-check this rule before building.
3. OPS-H7b ships without the lock. Its README replay section says "don't run two replays of the same DLQ at once (lock: OPS-H7c)", and OPS-H7c
   is the next backend task on these files after OPS-H7b merges.
4. `--from P/O` replaces the ticket's `--from-offset`. Accepted: the ticket said "flags such as", and the cursor matches the printed form.
5. `replay` requires a migrated Postgres. Accepted. The error text names `arxivlens migrate`, and README documents reset
   (`DELETE ... WHERE dlq_topic = $1`) and "`--dry-run` first after deploy".
6. CI-measured evidence (AC8, integration tests) must be readable from the job log (`dlq list --all` output, `kafka-get-offsets.sh` counts
   printed in the step). Nothing may rely on artifacts or the step summary (lesson OPS-H10).
7. A PRD truthfulness follow-up is mine, not the developer's: Product PRD OPS-2 ✅ → ◐ in the next pm-lead docs PR (list doesn't reach the end, and
   replay repeats the head), back to ✅ when OPS-H7c merges. OPS-3 stays ✅ (L1/L3 hold).

**Tickets and order.** All are backend-engineer and P1.

| Ticket | ACs (from OPS-H7) | Depends on | Files in any open PR? | Can start |
|---|---|---|---|---|
| [OPS-H7f](../../agents/tasks/OPS-H7f.md) | AC4 (part: full envelopes keep their ID; B1/B2), condition 1 | — (OPS-H6 merged) | no | **now / next cycle** (independent of #24, #26-#31) |
| [OPS-H7a](../../agents/tasks/OPS-H7a.md) | AC1, AC7 (list/inspect) | OPS-H7f merged, #26 merged (README) | README (#26) | after #26 + OPS-H7f merge; README is sequenced with RET-2 (same-file rule) |
| [OPS-H7b](../../agents/tasks/OPS-H7b.md) | AC2, AC4 (crash: same ID for envelope records), AC5, AC6, AC7 (replay) | OPS-H7a merged | — | after OPS-H7a merges |
| [OPS-H7c](../../agents/tasks/OPS-H7c.md) | AC3, AC4 (deterministic ULID for raw payloads), AC8 | OPS-H7b merged, #26 merged (`stack.yml`) | `stack.yml` (#26) | after OPS-H7b merges |

The split covers all eight ACs: AC1 is in a, AC2 in b, AC3 in c, AC4 is spread across f/b/c, AC5 and AC6 are in b, AC7 is split between a and b, and AC8 is in c.
`OPS-H7` stays the umbrella and is Done when OPS-H7c merges.
