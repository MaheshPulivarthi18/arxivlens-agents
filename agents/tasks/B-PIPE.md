# B-PIPE: An operator drains a DLQ of any size exactly once, and two replays can't run at once

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (Product PRD OPS-2 is P0 and ◐ until this merges) |
| **PRD ref** | Product PRD OPS-2, OPS-3, §5.3 "Operator recovers failed papers"; Technical PRD §5 (DLQ manager), §8.2 |
| **Depends on** | Nothing open. OPS-H7f (#32), OPS-H7a (#62), OPS-H7a2 (#83), OPS-H7a2b (#93) and ING-6c (#124, the last `main.go`/README change) are merged |
| **Jira** | one story for the bundle under epic KAN-3 "Dev harness & infrastructure" (`labels = "task-B-PIPE"`); KAN-31, KAN-98, KAN-18 and KAN-130 are closed and point here |
| **Tier** | Large. Design: `docs/design/OPS-H7.md` (approved with conditions 2026-11-07, § Q1–Q7, PM decision, a2c footer amendment 2026-11-21). No new design step; any deviation is written back into that file in the same cycle |
| **Size estimate** | ~880 changed lines incl. tests (part A ~90, part B ~480, part C ~225, harness ~10, part E ~80). If the counted skeleton projects > 950, stop and split at the seam **B-PIPE-1 = A + B + D + E**, **B-PIPE-2 = C**, merged in that order |
| **Absorbs** | OPS-H7 (KAN-31), OPS-H7a2c (KAN-98), OPS-H7b, OPS-H7c, ING-9b (no key: `crawl` must obey arXiv politeness). ING-6 (KAN-18) is already complete (ING-6c #124) and closed. OPS-H6g (KAN-130) is deferred, not ticketed (see Notes) |
| **Branch** | `agent/backend/B-PIPE` |
| **Status** | In Review: B-PIPE-1 #133 Ready to merge (QA PASS r2, PM APPROVE 2026-11-28); B-PIPE-2 #134 in rework r1 |

## Goal
Repeated `dlq replay --limit N` runs work through the whole DLQ, resolving each record once. A crash never skips or
double-resolves a record. Records a filter skips stay eligible. A second concurrent replay of the same DLQ fails fast
and publishes nothing. The `dlq list` "next page" command can be pasted as-is. No CLI path can break arXiv's
1 request / 3 s politeness rule.

## Scope
- **A. List/inspect polish** (was OPS-H7a2c): `cmd/arxivlens/main.go`, `cmd/arxivlens/dlq_test.go`.
- **B. Resumable replay** (was OPS-H7b): new `migrations/000004_dlq_replay.{up,down}.sql` (the design's checkpoint and replay-log
  tables, `CREATE TABLE IF NOT EXISTS`; 000004 is still free, 000005 is `crawl_watermarks`). New `internal/dlq/store.go` (pgx `Store`:
  `Checkpoints`, `Resolved`, `MarkResolved` in one tx) and `store_integration_test.go`. `internal/dlq/manager.go` (`Replay` loop on
  the `Reader`), `manager_test.go` (`fakePublisher`, `fakeStore`), `cmd/arxivlens/main.go` (`replay` builds and closes a
  `*dlq.KafkaReader` and wires `db.Connect`; no CLI path keeps a `nil` reader), and `internal/db/db_test.go` (migration list).
- **C. Lock + deterministic IDs + stack run** (was OPS-H7c): `store.go` `TryLock` (dedicated conn, `pg_try_advisory_lock(hashtextextended('arxivlens.dlq.replay/' || $1, 0))`,
  holder info from `pg_locks JOIN pg_stat_activity`, best effort). `manager.go` (`Replay` takes the lock; dry-run never does), `envelope.go`
  (the re-envelope fallback uses a deterministic ULID), `main.go` (`signal.NotifyContext`, exit 1 on `ErrLocked`), and `.github/workflows/stack.yml` (replay step).
- **D. Harness**: `Makefile` adds `$(wildcard tests/test_evaluate_extraction.py)` to `PY_LIGHT_TESTS`, so B-QUAL's scorer tests run in CI
  whichever bundle merges first. `.github/scripts/ownership-check.sh` raises its size warning from 400 to 800 lines, **only if rules PR
  arxivlens-agents #21 has merged** when you build; otherwise leave it and say so in the PR.
- **E. Crawl politeness** (was ING-9b): `internal/crawler/crawler.go` (`Crawl` waits on an `*arxiv.Limiter` built with
  `arxiv.NewLimiter(max(rateLimit, arxiv.DefaultInterval))` and passed to `arxiv.GetAPI`, replacing its own `time.After` sleep), `crawler_test.go`,
  and `main.go` (`crawl --rate-limit` below `arxiv.DefaultInterval` is rejected before connecting). `crawl-loop` is already on the shared limiter.
- App `README.md` (the `dlq` CLI rows and notes, and the `crawl --rate-limit` text) and `CONTRIBUTING.md` if a command changes.
- Out of scope: `shared/events/*` (the deterministic ULID is still a ULID, so no ADR, per the design's PM decision), the Python consumer, automatic replay, a UI.

## Acceptance criteria
- [ ] AC1 (A): The footer reads exactly `next page: arxivlens dlq list --topic T [--partition P] [--page-size N] --from P/O`. Each optional part appears
  only when that flag was given, and `--limit N` prints as `--page-size N`. Without either flag the text is unchanged. `TestDLQFlags` rows (a) `--partition 0 --page-size 2`,
  (b) `--limit 3`, (c) defaults, and (d) a **round trip**: parse the footer from (a), run it on the same fake, and it reads only partition 0 with page size 2 and ends `end of topic (…)`.
- [ ] AC2 (A): `inspect --key K` prints only the match when an undecodable record comes first. `inspect` (no key) on an empty topic prints exactly
  `No DLQ events in topic: <T>` and exits 0. `inspect --key K` with no match still prints `No DLQ events found for key: K`. An error is printed once:
  `newRootCmd()` with `SilenceErrors: true`, and a test asserts stderr has no cobra `Error: ` line for `dlq list --topic no.such.dlq`.
- [ ] AC3 (B): `TestReplayResumes`: 2N records over 2 partitions with `--limit N` run twice. Run 1 publishes records 1..N and run 2 publishes N+1..2N, in (partition, offset)
  order, with no repeat and no gap. After that the checkpoint = `High`, and a third run publishes 0. The integration variant (`db.yml`, real Postgres + Kafka) asserts on the target topic's contents.
- [ ] AC4 (B): `TestReplayCrashAfterPublish`: `MarkResolved` fails on record k. Run 1 errors and writes no checkpoint past k-1. Run 2 re-publishes k with an
  **identical `event_id`** and carries on. A `Publish` error stops the run with no row written, so the checkpoint never passes an un-acked publish.
- [ ] AC5 (B): `TestReplayFilterKeepsSkippedEligible`: with mixed error types, `--error-type A` publishes only As, and the checkpoint stops at the first B. A later run
  without the filter publishes only the Bs. Each record is published exactly once overall. Unreplayable records (OPS-H7f rule) are resolved under any filter.
- [ ] AC6 (B): `TestReplayDryRun`: 0 `Publish`, 0 `MarkResolved`, 0 `TryLock`, and the checkpoints are unchanged. The output lists the would-be `P/O` and `event_id` under `DRY RUN`.
  On an input that includes unreplayable records, the dry-run count equals a real run's `Publish` count.
- [ ] AC7 (B): Migration `000004` passes `db.yml`'s migrate-twice step with both tables in both snapshots, and the down file drops them. If Postgres is down or not
  migrated, `replay` fails **before reading Kafka**, with a message naming `arxivlens migrate` (unit test).
- [ ] AC8 (C): `TestReplayRefusedWhileLocked`: while the lock is held, `Replay` returns `ErrLocked` with 0 `Read` and 0 `Publish`. The CLI prints
  `another 'dlq replay' holds the lock for <topic> ...` and exits 1. `TestAdvisoryLock_Integration` (`db.yml`): when A holds the lock, B's `TryLock` is false.
  After `pg_terminate_backend(A)` (a simulated crash), B gets the lock. A different DLQ topic locks at once.
- [ ] AC9 (C): Deterministic IDs for raw payloads. The same `(dlq_topic, partition, offset)` always gives the same ULID. `ulid.Parse` succeeds, and the time part =
  the DLQ record's Kafka timestamp. A different offset or topic gives a different ID. This covers the `b_envelope_with_wrong_field_type` row (new ID, but stable across
  replays). `TestReplayCrashAfterPublish` includes a raw-payload record. Every OPS-H7f row stays green.
- [ ] AC10 (C): Stack run, printed **in the job log** of `stack.yml`. After `make test-full` (M4 leaves corrupt-PDF records in `papers.downloaded.dlq`):
  `dlq list --all`, then `dlq replay --limit 1` twice, then `dlq list --all` again, with `kafka-get-offsets.sh --topic papers.downloaded` before and after
  each replay. Then two concurrent `replay` runs, showing exactly one exit 1 with the lock message.
- [ ] AC11 (D): `make test-py-light` passes with and without `tests/test_evaluate_extraction.py` present. The ownership-check warning threshold is as in Scope D.
- [ ] AC12 (E): `crawl --rate-limit 1s` fails before any connection with an error naming the 3 s minimum (test). A `Crawl` over 3 pages against
  httptest (test interval) sends requests spaced by the limiter, and a 429 retry waits on it too (test). `stack.yml`'s `crawl --query "cat:cs.LG" --limit 2` stays green with 0 replay misses.
- [ ] AC13: README covers the new behaviour: `replay` needs a migrated Postgres, the reset query (`DELETE FROM … WHERE dlq_topic = $1`),
  "run `--dry-run` first after deploy", the lock, and the hung-holder `pg_stat_activity` / `pg_terminate_backend` query.
  The PR body carries the FYI for Mahesh that a raw payload's replayed ULID time = the DLQ record's time, not the original event's.
- [ ] AC14: CI green on the draft PR: `Go` (`-race`), `DB`, `Full stack`, `Python` light/ML, `Agent ownership check`. `make test-unit` and `make lint` green.
- [ ] Docs: after merge, pm-lead flips Product PRD OPS-2 to ✅ (docs PR, no ticket).

## Verification
```bash
cd app
make test-unit && make lint
go test -race -count=1 -v ./internal/dlq/ ./internal/db/ ./cmd/arxivlens/
DATABASE_URL=postgres://... KAFKA_BROKERS=localhost:9092 go test -tags integration -count=1 -v ./internal/dlq/   # db.yml on the PR
make stack-up && ./bin/arxivlens migrate && make test-full
./bin/arxivlens dlq list --topic papers.downloaded.dlq --partition 0 --page-size 2
./bin/arxivlens dlq replay --topic papers.downloaded.dlq --limit 5 --dry-run
./bin/arxivlens dlq replay --topic papers.downloaded.dlq --limit 5 & ./bin/arxivlens dlq replay --topic papers.downloaded.dlq --limit 5; wait
# QA mutation (delivery/commit semantics: allowed, local only, never pushed): checkpoint written before the publish ack;
# filter advances the checkpoint past a skipped record; dry-run takes the lock; ID derived without the offset; lock key ignores the topic.
```

## Checklist
- [ ] QA #133 r2 nit 8: pin `context.WithoutCancel` on the `MarkResolved` commit (mutants W1/W2 survive): a `fakePublisher` that cancels the run ctx inside `Publish`, a `fakeStore.MarkResolved` returning `ctx.Err()`; assert the record is logged and the next run publishes 0. Being covered in #134.

## Notes
- 2026-11-28 (pm-lead): bundle created in the process reset from the four OPS-H7 sub-specs. Their detailed AC history and design
  conditions are in `agents/tasks/OPS-H7{,a2c,b,c}.md` (closed) and `docs/design/OPS-H7.md`. Checked on app `main` `5fcbd5f`: no
  `000004` migration, no `store.go`, `Replay` still uses `ListEvents`, and the footer still drops `--partition`/`--page-size` (`main.go:465`).
- ING-9b (politeness of the one-off `crawl`, `main.go:141` still accepts any `--rate-limit`) is folded in as part E: it's a PRD NFR (§9 "≤ 1 arXiv
  API request / 3 s") and shares `main.go`.
- **ING-6 is complete** (ING-6a/6b/6c merged, #124 `ed043ec`). The PRD flip is in docs PR arxivlens-agents #22.
  ING-6d (compose `crawler` profile) and ING-6e (late-announcement lookback) are deferred, not ticketed.
- **Deferred, not ticketed** (over the ~800-line budget, lowest value): OPS-H6g. Those are behaviour pins for the processor's chunk-row lock
  strength (`FOR NO KEY UPDATE` mutant), lock coverage past `chunk_index 0`, and the embedder's ascending order. The lock is correct and already pinned by an
  exact-SQL test. Revisit only if that code changes.
- 2026-11-28 (backend-engineer): built as **B-PIPE-1 = A + B + D + E**, draft PR ArxivLens #133 (`9ac8978`). The size gate fired: the whole bundle came to ~1,495 changed lines, so part C (lock, deterministic ULIDs, `stack.yml` replay step; AC8-AC10, AC13 lock text) is **B-PIPE-2**, and its code is kept on the local `wip/B-PIPE-full` branch of the `app` clone. B-PIPE-1 alone is 1,221 changed lines (~600 tests), over the ~800 bundle size: pm-lead to decide whether E or A splits out further. Ownership check: rules PR #21 merged, so the warning threshold is now 800.
- 2026-11-28 (backend-engineer): **B-PIPE-2** (part C: lock, deterministic ULIDs, `stack.yml` replay run; AC8-AC10, the rest of AC13) is draft PR ArxivLens #134 (`6f5e36f`), **stacked on #133** (base `agent/backend/B-PIPE`; merge #133 first, then retarget #134 to main). 380 changed lines against its base. If QA rework on #133 touches shared files, B-PIPE-2 takes them through a merge commit, never a force-push.
- 2026-11-28 (backend-engineer): QA r1 rework (round 1 of 2) on #133. All 7 findings are fixed. Findings 1-5 and 7 are in `bbb2657` (+112/-17); finding 6 is the build notes in `docs/design/OPS-H7.md` (`e377d7b`). I re-ran QA's 45 mutants (`09-harness.txt` shapes, R10/R13 anchors updated for `WithoutCancel`) in scratch copies, never pushed: 45/45 killed by the PR's own tests, including S1, S3-S7, R15, R21, R23-R26, R28 and C8. Merged into B-PIPE-2 with merge commit `96025da` (#134; no force-push).
- 2026-11-28 (pm-lead): #133 (B-PIPE-1, `bbb2657`) APPROVED and raised: PR body rewritten with evidence, marked ready, label `ready-to-merge`. The 1,316-line size is accepted without a cut (730 lines are tests; the risky surface is concentrated). Merge #133 first, then retarget #134 to `main`. OPS-2 stays ◐ until #134 merges.
- 2026-11-28 (backend-engineer): #134 QA r1 rework (round 1 of 2) is `29dbb38` (+70/-1, test-only). Finding 1: `TestReplayRawIDsPerRecord`. Finding 2: unlock-release rounds in `TestAdvisoryLock_Integration`, plus `TestReplayLockErrorStops`. Finding 3: `TestReplayCommitSurvivesCancel`. I re-ran QA's `mutants134.py` (69 mutants) in scratch copies, never pushed: 69/69 killed by the PR's own tests. That count needed L2 and I8 re-anchored, because QA's versions don't compile (unused `holder`, missing `time` import). #133 was not touched.
