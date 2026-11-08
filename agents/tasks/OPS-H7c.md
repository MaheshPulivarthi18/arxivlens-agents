# OPS-H7c: DLQ replay lock (Postgres advisory), deterministic IDs for raw payloads, compose-stack replay run

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Product PRD OPS-2, OPS-3, §5.3; Technical PRD §4 (`event_id` is a ULID), §8.2 |
| **Depends on** | OPS-H7b **merged** (same files, `Store`). ArxivLens #26 (OPS-H10) **merged** (`stack.yml`, README) |
| **Jira** | to create under the "Dev harness & infrastructure" epic (labels `task-OPS-H7c`, `agent-backend`, `arxivlens`); parent work KAN-31 |
| **Design required** | covered by `docs/design/OPS-H7.md` § Q4, Q5 + PM decision (approved 2026-11-07) |
| **Status** | Ready after OPS-H7b merges |

## Goal
A second concurrent replay of the same DLQ fails fast and publishes nothing. A crashed holder never blocks later runs. A re-published raw payload keeps the same `event_id`.

## Scope
- Files: `internal/dlq/store.go` (`TryLock`: dedicated pooled conn, `pg_try_advisory_lock(hashtextextended('arxivlens.dlq.replay/' || $1, 0))`, holder info
  from `pg_locks JOIN pg_stat_activity`, best effort; keepalive on the lock conn), `internal/dlq/manager.go` (`Replay` takes the lock; dry-run never does),
  `internal/dlq/envelope.go` (OPS-H7f's re-envelope row uses the deterministic ULID), tests, new or extended `internal/dlq/*_integration_test.go`,
  `cmd/arxivlens/main.go` (`signal.NotifyContext`, exit 1 on `ErrLocked`), `.github/workflows/stack.yml` (AC3 step), app `README.md` (lock + release query).
- Out of scope: `shared/events/*` (unchanged; the deterministic ULID is still a ULID, so there's no ADR, see the PM decision).
- Size target: ~225 changed lines.

## Acceptance criteria
- [ ] AC1 (OPS-H7 AC3): `TestReplayRefusedWhileLocked`: when the store lock is held, `Replay` returns `ErrLocked` with 0 `Publish` and 0 `Read` calls, and the CLI
  prints `another 'dlq replay' holds the lock for <topic> ...` and exits 1. `TestAdvisoryLock_Integration` (Postgres in `db.yml`): conn A locks and B's
  `TryLock` returns false. `pg_terminate_backend(A)` (simulated crash) lets B get the lock. A different DLQ topic locks at once. Dry-run takes no lock (`TestReplayDryRun` asserts 0 `TryLock`).
- [ ] AC2 (OPS-H7 AC4, raw payloads): `TestEnvelopeRule` adds these deterministic-ULID rows. The same `(dlq_topic, partition, offset)` gives the same ID.
  `ulid.Parse` succeeds, and the ULID's time part = the DLQ record's Kafka timestamp. A different offset or topic gives a different ID. `OccurredAt` = that
  timestamp. `TestReplayCrashAfterPublish` adds a raw-payload record: the re-publish carries the identical `event_id`. Every OPS-H7f AC1/AC2 row stays green.
- [ ] AC3 (OPS-H7 AC8): compose-stack run in `stack.yml` (it triggers on Go PRs after OPS-H10). After `make test-full` (M4 leaves corrupt-PDF records in
  `papers.downloaded.dlq`), a step runs `dlq list --all`, `dlq replay --limit 1` twice, `dlq list --all` again, and
  `kafka-get-offsets.sh --topic papers.downloaded` before and after each replay. It also runs two concurrent `replay` runs and shows exactly one exit 1
  with the lock message. All output is printed **in the job log** (not only an artifact). "not run: no stack" only with these exact commands.
- [ ] Docs: README covers the lock, the "hung holder" `pg_stat_activity` / `pg_terminate_backend` query, and removes OPS-H7b's "don't run two replays" warning.
  The PR description carries the FYI for Mahesh: a raw payload's replayed ULID time part = the DLQ record time, not the original event time.

## Verification
```bash
make test-unit
make lint
go test -race -count=1 -v ./internal/dlq/
DATABASE_URL=postgres://... KAFKA_BROKERS=localhost:9092 go test -tags integration -count=1 -v ./internal/dlq/
make stack-up && ./bin/arxivlens migrate && make test-full
./bin/arxivlens dlq replay --topic papers.downloaded.dlq --limit 5 & ./bin/arxivlens dlq replay --topic papers.downloaded.dlq --limit 5; wait
```

## Notes
- 2026-11-07 (pm-lead): part c of the OPS-H7 split. When it merges, OPS-H7 is Done and Product PRD OPS-2 goes back to ✅ (pm-lead docs PR).
- 2026-11-08 (pm-lead, from OPS-H7f QA r2 nit 4): an `original_value` with all three IDs but a wrongly typed non-ID field (e.g. `"version":"2"`) fails `Unmarshal`
  and goes down the wrap path, so it gets a **new** `event_id` (OPS-H7f row `b_envelope_with_wrong_field_type`). Here AC2 must cover that row with the
  deterministic ULID (stable across replays), and the PR description must name the case: its original `event_id` is not kept, so L2 won't dedupe it against the first attempt.
  Don't add lenient parsing to keep the ID without a design note.
