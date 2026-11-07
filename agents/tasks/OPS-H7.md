# OPS-H7: DLQ list/replay with partition/offset checkpoints, paging, a replay lock and idempotent replay

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Product PRD OPS-2, OPS-3, §5.3 "Operator recovers failed papers"; Technical PRD §5 (DLQ manager), §8.2 |
| **Depends on** | OPS-H6 (same delivery semantics; replayed records flow back through the fixed consumer) |
| **Jira** | KAN-31 (epic "Dev harness & infrastructure", labels `task-OPS-H7`, `agent-backend`, `design-required`, `arxivlens`) |
| **Design required** | **yes**: changes CLI behaviour/flags of `arxivlens dlq`, may add a table (checkpoints/lock), and defines replay delivery semantics |
| **Status** | Ready after OPS-H6 merges (design can start once OPS-H6's design is approved) |

## Goal
An operator must be able to drain a DLQ of any size, exactly once per DLQ record, without two operators replaying the same records.
Today `internal/dlq/manager.go` can't do that (checked at `9c1229a`):
- `ListEvents` starts a fresh client at the start of the topic and stops after a ~2 s deadline or the first empty poll (lines 33, 41–56). It sees only whatever arrives in that window, never "everything up to the end".
- `Replay` calls `ListEvents(limit)` and republishes that first batch (line 79). It keeps no checkpoint, so every run replays the same first `limit` records, and records after them are never reached.
- Nothing stops two `dlq replay` runs from going at once.
- Records the error-type filter skips aren't distinguished from records not yet seen.

## Scope
- Files: `internal/dlq/manager.go` (+ new `manager_test.go`), `cmd/arxivlens/main.go` (`dlq` subcommands, lines ~251–351),
  optionally a new additive migration (checkpoint and/or lock table; additive tables don't need an ADR, AGENTS.md §2),
  app `README.md:171-173` (CLI table) and `CONTRIBUTING.md` if commands change.
- Out of scope: the Python consumer, the `DLQPayload` / envelope shape (shared contract: needs an ADR), automatic replay, a UI.

## Design must answer (in `docs/design/OPS-H7.md`)
1. **Where checkpoints live:** a dedicated consumer group (e.g. `arxivlens-dlq-replay`) with Kafka-committed offsets, or a
   Postgres table `dlq_replay_checkpoints(topic, partition, next_offset, ...)`. Trade-offs: visibility (`status`),
   reset, and multi-topic.
2. **End of the topic:** read up to the high watermarks snapshotted at start (per partition), not a wall-clock deadline. Say how an empty or compacted partition is handled.
3. **Paging:** flags such as `--partition`, `--from-offset`, `--page-size`, and a list output that shows `partition/offset` for each record, so an operator can page through and resume.
4. **Lock:** what makes a second concurrent `replay` on the same DLQ topic fail fast with a clear message (Postgres advisory lock, lock row with TTL, ...), and how a crashed holder's lock is released.
5. **Idempotent replay:** a crash after publish but before the checkpoint will cause a re-publish. Say how downstream treats it.
   The republished envelope keeps the original `event_id` when `OriginalValue` is an envelope (manager.go:114-118), so the
   processor's L2 ledger dedupes it. The re-envelope fallback (line 117) mints a new ID. Propose a deterministic ID (e.g. from
   DLQ topic/partition/offset) or justify the alternative. The checkpoint advances only after the publish is acknowledged.
6. **Filters:** with `--error-type X`, are skipped records left eligible for a later replay with another filter? Recommended: yes, so checkpoints don't jump past them silently. Say how.
7. `--dry-run` never moves a checkpoint or takes the lock longer than the run.

## Acceptance criteria
- [ ] AC1: `dlq list` reaches the end of the topic. Against a topic with more records than one poll returns (test: fake/mock
  client or the compose Kafka), it returns every record up to the start-time high watermark, paged by `--page-size`, and
  shows partition and offset for each one.
- [ ] AC2: Replay resumes. Two consecutive `dlq replay --limit N` runs over 2N records publish records 1..N, then N+1..2N
  (no repeats, no gaps). Asserted on the target topic's contents.
- [ ] AC3: Concurrent replay is refused. A second `replay` on the same DLQ topic while the first holds the lock exits non-zero
  with a clear message and publishes nothing. After the holder exits or crashes (simulated), a new run gets the lock.
- [ ] AC4: Crash safety. A failure injected after publish and before the checkpoint leads, on the next run, to a re-publish
  with the **same `event_id`**, and downstream rows stay unchanged (M4-style invariant, or a unit test of the ID rule plus a
  reference to `processed_events`).
- [ ] AC5: Filters. With `--error-type`, non-matching records are not published and are still replayable by a later run without the filter (test).
- [ ] AC6: `--dry-run` publishes nothing and leaves checkpoints unchanged (test).
- [ ] AC7: Existing flags (`--topic`, `--error-type`, `--limit`, `--dry-run`, `inspect --key`) keep working. README CLI table updated for any new flag.
- [ ] AC8: Integration run against the compose stack. Force some DLQ records (corrupt-PDF path from M4), replay twice, and paste `dlq list` before/after and the target-topic counts. "not run: no stack" only with the exact commands.

## Verification
```bash
make test-unit
make lint
go test -race -count=1 -v ./internal/dlq/
make stack-up && ./bin/arxivlens migrate
./bin/arxivlens dlq list --topic papers.downloaded.dlq --page-size 10
./bin/arxivlens dlq replay --topic papers.downloaded.dlq --limit 5 --dry-run
./bin/arxivlens dlq replay --topic papers.downloaded.dlq --limit 5 & ./bin/arxivlens dlq replay --topic papers.downloaded.dlq --limit 5   # AC3
make test-full
```

## Notes
- 2026-11-03 (pm-lead): specced from the external review of `bb9ee90` (approved by Mahesh). Expected diff is about 350 lines. If the design goes over 400, split into (a) list to end + paging and (b) checkpoints + lock + idempotent replay.
- 2026-11-07 (backend-engineer): design written at [`docs/design/OPS-H7.md`](../../docs/design/OPS-H7.md) (Draft; awaiting pm-lead). The design puts checkpoints, a per-record log and the advisory lock in Postgres, and uses a deterministic ULID for the re-envelope fallback (no envelope change, no ADR). It also found bugs B1 (raw payloads are replayed with `event_id: ""`) and B2 (a null original value is replayed as an empty envelope). Estimate ~1,100 lines → proposes a 3-way split: OPS-H7a (AC1, AC7), OPS-H7b (AC2, AC5, AC6, AC7), OPS-H7c (AC3, AC4, AC8). Jira row fixed to KAN-31. Build stays held behind PR #26 (README/CONTRIBUTING).
