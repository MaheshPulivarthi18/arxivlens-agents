# OPS-H7b: Resumable DLQ replay: Postgres checkpoints + replay log, ack-then-commit, filters that keep skipped records, dry-run

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Product PRD OPS-2, OPS-3, §5.3; Technical PRD §5 (DLQ manager), §8.2 |
| **Depends on** | OPS-H7a **merged** (same files, `Reader`) |
| **Jira** | to create under the "Dev harness & infrastructure" epic (labels `task-OPS-H7b`, `agent-backend`, `arxivlens`); parent work KAN-31 |
| **Design required** | covered by `docs/design/OPS-H7.md` § Q1, Q5, Q6, Q7 + PM decision (approved 2026-11-07) |
| **Status** | Ready after OPS-H7a merges |

## Goal
Repeated `dlq replay --limit N` runs work through a DLQ of any size, each DLQ record resolved once, and records skipped by a filter stay eligible.

## Scope
- Files: new `migrations/000004_dlq_replay.{up,down}.sql` (the design's two tables, `CREATE TABLE IF NOT EXISTS`; **number fixed by the PM decision:
  000003 is ING-11's**), new `internal/dlq/store.go` (pgx `Store`: `Checkpoints`, `Resolved`, `MarkResolved` in one tx; **no lock**), new
  `internal/dlq/store_integration_test.go`, `internal/dlq/manager.go` (`Replay` loop), `internal/dlq/manager_test.go` (`fakePublisher`, `fakeStore`),
  `cmd/arxivlens/main.go` (`replay` wires `db.Connect`), `internal/db/db_test.go:87` (`want` list = the full ordered migration list), app `README.md` replay row + notes.
  If OPS-H7a's `db.yml` step doesn't already run `./internal/dlq/` integration tests against Postgres, add that to `db.yml`.
- Out of scope: lock (OPS-H7c), deterministic IDs for raw payloads (OPS-H7c). The envelope rule from OPS-H7f is reused unchanged.
- **Size gate:** commit a counted skeleton first. If it projects > 480 changed lines or > 250 non-test lines, stop and split at the named seam:
  **OPS-H7b1** = migration + `store.go` + `store_integration_test.go` + `db_test.go`; **OPS-H7b2** = `Replay` loop + fakes + CLI + README.

## Acceptance criteria
- [ ] AC1 (OPS-H7 AC2): `TestReplayResumes`: 2N records over 2 partitions and `--limit N` twice. The publisher sees records 1..N, then N+1..2N, in
  (partition, offset) order, with no repeat and no gap. After run 2 the checkpoint = `High`, and a third run publishes 0. The integration variant asserts on the real target topic's contents.
- [ ] AC2 (OPS-H7 AC4, envelope records): `TestReplayCrashAfterPublish`: `MarkResolved` fails on record k. Run 1 errors after publishing k and writes no checkpoint
  past k-1. Run 2 publishes k again with an **identical `event_id`** and continues. The checkpoint never passes an un-acked publish: a `Publish` error stops the run with no row written.
- [ ] AC3 (OPS-H7 AC5): `TestReplayFilterKeepsSkippedEligible`: with mixed error types, `--error-type A` publishes only As, and the checkpoint stops at the first B.
  A run without the filter publishes only the Bs. Each record is published exactly once overall. `unreplayable` records (OPS-H7f rule) are resolved under any filter.
- [ ] AC4 (OPS-H7 AC6): `TestReplayDryRun`: 0 `Publish`, 0 `MarkResolved`. Checkpoints are unchanged, and the output lists the would-be `P/O` and `event_id`, labelled `DRY RUN`.
  The input includes OPS-H7f's unreplayable records (nil, `raw_value`-only, no key), and the test asserts the dry-run count equals a real run's `Publish` count on the
  same input (OPS-H7f QA nit 5: mutant M14, "apply the rule only in real runs", must go red).
- [ ] AC5 (OPS-H7 AC7, replay half): `--topic`, `--error-type`, `--limit` (counts published records) and `--dry-run` parse and reach `Replay` (`TestDLQFlags`).
- [ ] AC6: Migration. `db.yml`'s migrate-twice step stays green with the two new tables in both snapshots. The down file drops them.
- [ ] AC7: Postgres down / not migrated → `replay` fails before reading Kafka, with a message naming `arxivlens migrate` (unit test on the store error path).
- [ ] Docs: README says `replay` needs a migrated Postgres, documents reset (`DELETE FROM dlq_replay_checkpoints/dlq_replay_log WHERE dlq_topic = $1`) and
  "run `--dry-run` first after deploy", and warns "don't run two replays of the same DLQ at once (lock: OPS-H7c)".

## Verification
```bash
make test-unit
make lint
go test -race -count=1 -v ./internal/dlq/ ./internal/db/
DATABASE_URL=postgres://... KAFKA_BROKERS=localhost:9092 go test -tags integration -count=1 -v ./internal/dlq/   # db.yml on the PR
./bin/arxivlens migrate
./bin/arxivlens dlq replay --topic papers.downloaded.dlq --limit 5 --dry-run
```

## Notes
- 2026-11-07 (pm-lead): part b of the OPS-H7 split. Interim risk: until OPS-H7c, two concurrent replays can double-publish (that's true today too).
  Full envelopes still dedupe in L2. OPS-H7c is the next task on these files.
- 2026-11-08 (pm-lead): AC4 extended from OPS-H7f QA r2 nit 5. OPS-H7f's own tests can't catch a dry-run-only envelope rule (no publisher seam); `fakePublisher` here can.
