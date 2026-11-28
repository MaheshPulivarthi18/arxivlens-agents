# QA report — B-PIPE (part 1: B-PIPE-1) · ArxivLens PR #133 · round 1 · tier Large

> Provenance: written by qa-reviewer. The QA harness refused to write this file, so the orchestrator saved qa-reviewer's text verbatim (2026-11-28). The same content is the PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/133#issuecomment-7227409757. Evidence: `agents/reviews/B-PIPE/evidence/` at `9fd6770`.

**Verdict:** FAIL (2 blocking test gaps in the replay/checkpoint semantics; the code behaved correctly under every QA probe)
**Reviewed commit:** `9ac897883ce5355818a2748a2165c8fa4eee5afd` (draft) · **Date:** 2026-11-28
**Ticket:** `agents/tasks/B-PIPE.md`. This PR covers AC1–AC7, AC11, AC12 and part of AC13; AC8–AC10 and the lock are B-PIPE-2.
**Design:** `docs/design/OPS-H7.md` · **PRD:** Product OPS-2, OPS-3, §5.3; Technical §5, §8.2, §9
**Inputs:** ticket, design, the diff vs `origin/main`, CI check runs and job logs. I did not use the developer's self-report as evidence.

## Test results
| Check | Source | Result |
|---|---|---|
| Go, DB, Full stack, Python M0, Frontend, Pinned digests, Agent ownership check | CI on `9ac8978` | all success ([00](evidence/00-ci-checks.png)). The stack job's `make test-full` fails only `test_rag_early_refusal_on_unrelated_query` (ReadTimeout), which is the tracked F1 step 24 |
| Ownership | CI job 140711320871 | `Ownership OK for role=backend (1221 changed lines)` plus the >800 warning ([13](evidence/13-ownership-ci.png)) |
| `go vet ./...`, `gofmt -l .`, `go test -race ./...` | local, Go 1.25.1 via scratch modfile | clean ([10](evidence/10-unit-lint.png)) |
| Migration 000004 up×2 / down / down again, plus `TestPGStore_Integration` | local PG16 | pass ([03](evidence/03-AC7-migration-store-local.png)) |
| `TestReplayResumes_Integration` | not run locally (no Kafka); CI pass | ([04](evidence/04-AC3-AC7-db-ci.png)) |
| Mutation: 45 mutants on local copies, never pushed | local | 31 killed, 14 survived the PR's tests ([08b](evidence/08b-mutant-verdicts.png), [08](evidence/08-mutants.png), harness [09](evidence/09-harness.png)) |
| `make eval` | n/a | no retrieval/answering change |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `TestDLQFlags` rows (a)(b)(c) and `TestDLQFooterRoundTrip` (d) ([01](evidence/01-AC1-AC2-cli.png)). Mutants C1, C2 killed. |
| AC2 | ✅ | Rows for an undecodable first record, an empty topic (exact output), and `missing topic (list)` (`dlq_test.go:158`), all through `newRootCmd` with no `Error: ` line on stderr. C3, C4 killed. |
| AC3 | ✅ | `TestReplayResumes` ([02](evidence/02-AC3-AC7-replay-unit.png)). CI integration on real Kafka and Postgres: the target topic holds the 10 event_ids once each, in order ([04](evidence/04-AC3-AC7-db-ci.png), log line 1886). R7, R16–R18, R20 killed. |
| AC4 | ✅ for full envelopes (the raw-payload row is AC9) | `TestReplayCrashAfterPublish`. R1 (checkpoint written before the ack) killed; R12–R14 killed. |
| AC5 | ✅ | `TestReplayFilterKeepsSkippedEligible`. R2, R3 and R4 (the filter advancing past or marking skipped records) killed; R5, R6, R8, R9, R27 killed. |
| AC6 | ⚠ | `TestReplayDryRun` and `TestDLQReplayCLI` pass, but two dry-run write paths are not tested (finding 2). |
| AC7 | ✅ | db.yml snapshots and down step ([04](evidence/04-AC3-AC7-db-ci.png)); local up/down ([03](evidence/03-AC7-migration-store-local.png)); `TestReplayNeedsMigratedStore` and `TestDLQReplayNeedsPostgres`. R19, C5 killed. |
| AC11 | ✅ | `make -n test-py-light` checked with and without the extra file; warning threshold is 800, and rules PR #21 is merged ([05](evidence/05-AC11-harness.png)). |
| AC12 | ✅ | `TestCrawlRateLimitFlag` and `TestCrawlWaitsOnLimiter` ([06](evidence/06-AC12-crawl-unit.png)). Stack crawl ran at `rate-limit=3s` with replay `"misses": 0`; the replay store was re-recorded on this branch ([07](evidence/07-AC12-stack-crawl-ci.png)). E1, E2, C7 killed. |
| AC13 (part) | ✅, plus nit 4 | README replay section ([11](evidence/11-AC13-readme.png)). The lock, the hung-holder query and the ULID FYI are B-PIPE-2. |

## Judgments
- **Migration 000004:** it only adds two `CREATE TABLE IF NOT EXISTS` tables, with primary keys and a CHECK. Running up a second time changes nothing; down drops both tables cleanly, twice. No ADR is needed. ✅
- **Checkpoint correctness:** the code is correct.
  - A record is published first; only after the broker acks does one transaction write its row and the `GREATEST` checkpoint.
  - A filtered record gets no row and holds the checkpoint at its offset.
  - Unreplayable records are resolved under any filter.
  - A crash between ack and commit re-publishes exactly one record, with the same event_id.
  - All 10 QA probes (real `Manager` plus real `PGStore` on PG16) pass on the head. The gap is in the tests (findings 1–2).
- **README without a lock:** adequate as a stopgap (design condition 3).
  - Two runs that overlap both publish the same unresolved records. Nothing is skipped (`ON CONFLICT DO NOTHING`, `GREATEST`).
  - Full envelopes keep their event_id, so consumers dedupe them.
  - Raw payloads get a new random ULID on every run until B-PIPE-2, so only natural keys absorb those duplicates (nit 4).
- **Size: 1,221 lines (639 tests, 582 non-test; [12](evidence/12-scope-size.png)).** A reviewer can follow it, so **no cut is needed**.
  - The risky surface is small and concentrated: `manager.go` Replay (~180 lines), `store.go` (70) and the migration (25). Parts A, D and E don't share functions with it.
  - If pm-lead still wants a cut, cut **E** (~122 lines: `crawler.go` 41, `crawler_test.go` 59, `main_test.go` 16, two `newCrawlCmd` hunks, one README line).
  - Don't cut **A**: B's CLI tests are built on A's `newRootCmd` and the `runDLQ` harness.
  - The fixes for findings 1–2 add about 40 test lines.

## PRD fit
This delivers OPS-2's "operator recovers failed papers":
- Repeated `--limit N` runs drain the DLQ in order and resolve each record once.
- Records a filter skips stay eligible for a later run.
- A dry run matches what a real run would do.
- Replay refuses to run without a migrated Postgres.
- The §9 arXiv rate limit now holds for the one-off `crawl` too.

OPS-2 stays ◐ until B-PIPE-2 merges.

## Findings
1. **[blocking] The store's SQL rules that prevent skips and double publishes have no test.** These `store.go` mutants pass `TestPGStore_Integration` and the whole PR suite; my QA probes catch them:
   - **S5/S7:** no `dlq_topic` filter in `Checkpoints` or `Resolved`. Draining DLQ A, then DLQ B, publishes nothing from B.
   - **S6:** no `partition` filter in `Resolved`. Partition 0's log rows mark partition 1's matching offsets as resolved, so they're skipped. Reading the code, CI's Kafka test would catch this; I couldn't run it here.
   - **S1:** `GREATEST` removed. The step meant to show the checkpoint never moves backwards writes `Next: 1` over an existing 1, so it can't fail.
   - **S4:** `>= $3` changed to `>`.

   Fix, about 15–20 lines in `TestPGStore_Integration`:
   - Add rows for a second topic and assert the first topic's queries exclude them.
   - Add a partition 1 log row and assert `Resolved` for partition 0 excludes it.
   - Assert `Resolved` with `from` equal to a logged offset includes that offset.
   - Write `Next: 5`, then `Next: 3`, and expect 5.
2. **[blocking] Unit gaps on double-publish and dry-run write paths.**
   - **R21:** a `Resolved` error is ignored, so already-resolved records are re-published. `fakeStore.Resolved` can't fail, and `manager.go:266-268` has 0 coverage.
   - **R23:** a dry run whose partition ends on already-logged records calls `MarkResolved`.
   - **R26:** a dry run over a partition where every record has expired moves the checkpoint. AC6 requires 0 `MarkResolved`.

   Fix, about 20 lines: add a `resolvedErr` to `fakeStore` with a row asserting an error and 0 publishes, plus two dry-run rows asserting `marks == 0` and unchanged checkpoints. My probes `TestQAProbeResolvedErrorStops`, `TestQAProbeDryRunTailNoWrite` and `TestQAProbeAllExpired` show the shape ([09](evidence/09-harness.png)).
3. **[nit]** Also add tests for these surviving mutants:
   - R24/R25: on a real run where every record has expired, the checkpoint and the reader both move to `Low`.
   - R15: `--limit` counts only published records.
   - R28: an empty `original_topic` falls back to the DLQ name minus `.dlq`.
   - S3: marking the same record twice doesn't error.

   C8 is already covered by the stack crawl.
4. **[nit] README.** The dry run's "would-be `event_id`" is wrong for raw payloads, which get a fresh random ULID on every run until B-PIPE-2. Say so, and say what overlapping runs do: full envelopes are deduped by event_id, and nothing is skipped.
5. **[nit]** The `withDLQManager` comment says "its deferred unlock runs", but there is no unlock until B-PIPE-2.
6. **[nit]** Write these internal API changes back to `docs/design/OPS-H7.md` as "Build notes (B-PIPE-1)":
   - `Resolution.Next`, and checkpoint-only marks with an empty `Outcome`
   - `NewManager(reader, pub, store)`
   - the `ReplayResult` shape
   - `ListEvents` removed
7. **[nit, optional]** Commit `MarkResolved` with `context.WithoutCancel(ctx)`, so a Ctrl-C right after an ack doesn't force a re-publish on the next run.

## Missing tests
The rows listed in findings 1–3.

## Mutation
45 mutants on local copies, never pushed, 0 invalid: 31 killed and 14 survived the PR's tests. My QA probes catch every survivor except R15, and C8 is covered by stack CI. Evidence: [08b](evidence/08b-mutant-verdicts.png), [08](evidence/08-mutants.png), [09](evidence/09-harness.png).

## PM-equivalent check
Not applicable (FAIL).

## Hand-off
FAIL goes back to backend-engineer for rework round 1 of 2. Fix findings 1–2 in this PR, and preferably 3–6 too. QA round 2 will re-run the same mutants and probes from `09-harness.txt`. Any nits left unfixed go to the ticket's `## Checklist`.

---

# Round 2 — B-PIPE-1 · PR #133 · head `bbb2657f34a8a5092503424a8254af00af41e7cf` · 2026-11-28

**Verdict: PASS.** All 7 round-1 findings are addressed. All 45 round-1 mutants are now killed. One nit remains: the new `WithoutCancel` commit has no test (W1/W2).

## Test results
| Check | Source | Result |
|---|---|---|
| Go, DB, Full stack, Python M0, Frontend, Pinned digests, Agent ownership check | CI on `bbb2657` | all success ([r2-00](evidence/r2-00-ci-checks.png)) |
| Rework rows, `go test -race ./...`, `TestPGStore_Integration` (PG16), gofmt | local, Go 1.25.1 | all ok, 0 gofmt files ([r2-01](evidence/r2-01-rework-tests.png)) |
| Mutation: the same 45 mutants, plus W1/W2 for the new `WithoutCancel` (R10/R13 re-anchored) | local scratch copies, never pushed | **45 killed**, 2 survived, 0 invalid ([r2-02b](evidence/r2-02b-mutant-verdicts.png), [r2-02](evidence/r2-02-mutants.png); harness diff in [p2-05](evidence/p2-05-harness.png)) |

## Round-1 findings re-checked
| # | Status | Evidence |
|---|---|---|
| 1 [blocking] store SQL | ✅ fixed | `TestPGStore_Integration` now adds another topic's rows, a partition-1 log row, a `from`-equal-to-a-logged-offset case, `Next 5 → 3` (expects 5) and a duplicate mark. S1 and S3–S7 killed by the PR's own test. |
| 2 [blocking] manager double-publish / dry-run writes | ✅ fixed | `TestReplayResolvedErrorStops`, `TestReplayDryRunTailNoWrite`, and the all-expired dry/real rows in `TestReplayExpiredAndStall`. R21, R23, R26 killed. |
| 3 [nit] lesser survivors | ✅ fixed | R24/R25 (`reads == 0:3-5`, all-expired real run), R15 (`TestReplayLimitCountsPublishedOnly`), R28 (`TestReplayTargetFallback`), S3 (duplicate-mark step), C8 (`--rate-limit 3s` accepted row) all killed. |
| 4 [nit] README | ✅ fixed | The dry-run raw-payload caveat and the overlapping-runs consequence are both stated (README lines 225–229 at `bbb2657`). |
| 5 [nit] stale comment | ✅ fixed | The comment now reads "Replay stops after the record in flight is marked resolved". |
| 6 [nit] design write-back | ✅ fixed | `docs/design/OPS-H7.md` § "Build notes (B-PIPE-1, PR #133, 2026-11-28)". |
| 7 [nit] `WithoutCancel` | ✅ implemented, ⚠ untested | All three `MarkResolved` calls use `context.WithoutCancel(ctx)`. **W1/W2** (revert to `ctx`) survive the suite. A regression only brings back the round-1 behaviour that was accepted by design: one re-publish with the same event_id. → nit 8. |

## New findings
8. **[nit]** Pin `WithoutCancel`. Add a `fakePublisher` hook that cancels the run's ctx inside `Publish` (after the "ack"), plus a `fakeStore.MarkResolved` that returns `ctx.Err()`. Then assert the record is logged and the next run publishes 0. Append to the ticket's `## Checklist` if it isn't fixed here.

## Size
1,316 changed lines vs `main` (730 in test files). The rework added 95 lines, almost all test rows. My round-1 judgement still holds: a reviewer can follow it, because the non-test surface barely grew (manager.go +3/−3, a comment, the README). There is still no cut to make. If one is wanted anyway, it would be E, as in round 1.

## PM-equivalent check
Deferred: the coordinator asked for one combined check once both #133 and #134 pass, and #134 fails below. #133 is ready for pm-lead's final review. Mahesh should merge #133 first, whatever happens to #134.

---

# Part 2 (B-PIPE-2, PR #134) round 1 · head `96025da58d49df62ae1dc554b2a3be884171792f` (base `agent/backend/B-PIPE` @ `bbb2657`) · 2026-11-28

**Verdict: FAIL.** One blocking test gap: the raw-payload ID is never checked at the `Manager` level. The lock, the ID derivation and the stack proof are otherwise correct and well tested.
**Scope:** AC8, AC9, AC10 and the rest of AC13 from `agents/tasks/B-PIPE.md`, against design Q4/Q5. 387 changed lines vs base (187 in tests), 11 files, all backend-owned, ownership check green.

## Test results
| Check | Source | Result |
|---|---|---|
| Go, DB, Full stack, Python M0, Frontend, Pinned digests, Agent ownership check | CI on `96025da` | all success ([r2-00](evidence/r2-00-ci-checks.png)) |
| AC8/AC9 unit, CLI, `TestAdvisoryLock_Integration` + `TestPGStore_Integration` (PG16), vet, gofmt | local | all pass ([p2-01](evidence/p2-01-lock-id-tests.png)) |
| db.yml requires `TestAdvisoryLock_Integration` to PASS | CI | PASS; "B got the lock after A's backend (pid 355) was terminated" ([p2-02](evidence/p2-02-AC8-db-ci.png)) |
| stack.yml B-PIPE step | CI | green ([p2-03](evidence/p2-03-AC10-stack-ci.png)) |
| Mutation: 69 mutants (47 carried over + 22 lock/ID) | local scratch copies, never pushed | **61 killed, 8 survived**; the 6 lock/ID survivors are caught by #134 QA probes ([p2-04b](evidence/p2-04b-mutant-verdicts.png), [p2-04](evidence/p2-04-mutants.png), [p2-05](evidence/p2-05-harness.png)) |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC8 lock | ✅ | `TestReplayRefusedWhileLocked`: `ErrLocked`, the holder in the message, 0 Watermarks/Read/Publish/marks. CLI row `lock held: nothing read or published` (`errors.Is(err, dlq.ErrLocked)`, exit 1 through `main`). `TestAdvisoryLock_Integration`: B refused with the holder's pid; another topic locks at once; after `pg_terminate_backend(A)`, B gets the lock. `runReplay` asserts the lock is released after every real run, error paths included. Mutants L1–L7, L9 and L10 killed: dry run takes the lock, refusal ignored, no unlock, lock after Kafka, not `ErrLocked`, **key ignores the topic**, xact-level lock, leaked connection, holder query. |
| AC9 deterministic IDs | ⚠ ID function ✅, use by the Manager unpinned (finding 1) | `TestReplayID`: stable; `ulid.Parse` ok; time part = Kafka ms; offset, partition, topic and a digit shift (3/17 vs 31/7) give different entropy; a later timestamp changes only the time part; a zero timestamp doesn't panic; the wrong-field-type row gets a new, stable ID. `TestReplayCrashAfterPublish/AARAA` re-publishes the raw record with an identical ID. All the `TestReplayEnvelope` (OPS-H7f) rows still pass. I1–I6 and I10 killed. **I7, I8 and I9 survive.** |
| AC10 stack run | ✅ | Job log ([p2-03](evidence/p2-03-AC10-stack-ci.png)):<br>• `dlq list --all` (2 records), a dry run, then `replay --limit 1` ×2, replaying **6/0 then 6/1**. `papers.downloaded` end offsets go 3→4 and 4→5, equal to `published=1` each time, and the log rows are printed. Then `dlq list --all` again.<br>• **Concurrent pair:** Kafka is paused, so A takes the lock and blocks on Kafka. B starts only after `pg_locks` shows the advisory key held (`held: 1`). B exits **1** with `another 'dlq replay' holds the lock for papers.downloaded.dlq (pid 1089 on 172.18.0.1, since …)` and prints no summary. After the unpause, A exits **0** (`6/2 replayed`).<br>• The step fails if the lock never shows in `pg_locks`, if A≠0 or B≠1, if B lacks the lock message, or if B printed a summary. So it truly proves exactly one of two concurrent runs is refused, and it can't pass vacuously. |
| AC13 rest | ✅ | README: one replay per DLQ, the exit-1 message, the dry run takes no lock, crash releases / a hung holder keeps it, the `pg_locks JOIN pg_stat_activity` query, `pg_terminate_backend(<pid>)`, SIGINT/SIGTERM, and event IDs with the time-part caveat. The PR body carries the FYI for Mahesh (body line 25). |

## Design check (Q4/Q5)
- Matches Q4:
  - a dedicated `pool.Acquire` connection with `pg_try_advisory_lock(hashtextextended('arxivlens.dlq.replay/' || $1, 0))`
  - the holder found best-effort through `pg_locks JOIN pg_stat_activity` (bigint key split into classid/objid, objsubid 1)
  - unlock with a 5 s timeout that closes the session on failure
  - the dry run takes no lock
  - the lock is taken before any Kafka read (L4 killed)
- `tcp_keepalives_idle = 30` is applied with `SET` on the lock connection instead of the connection string. That's an equivalent, recorded best-effort choice.
- Matches Q5: entropy is `SHA-256("arxivlens/dlq-replay\x00"+topic+"\x00"+partition+"\x00"+offset)[:10]`, time is the Kafka ms, and `occurred_at` is the same timestamp.
- No envelope or `events.py` change, so no ADR.

## Findings
1. **[blocking] The Manager → `replayID` wiring is not tested, and a regression would silently drop raw-payload records downstream.** Mutants I7 (`source{topic, p, 0, r.Timestamp}`) and I9 (partition 0) pass every PR test, as does I8 (zero timestamp). Under I7, every raw record of a partition is published with **one** event_id. The processor's L2 ledger keys on `(consumer_group, event_id)`, so after the first one succeeds, every later raw record is skipped as a duplicate. That is the ledger-poisoning failure the design's B1 analysis was written to prevent.
   - Why nothing catches it: `TestReplayID` tests the function directly. The crash test has only one `R`, so it only checks that the ID is *stable*, not that it is *this record's*.
   - **Fix (~15 lines in `manager_test.go`):** a row with raw records at ≥2 offsets and ≥2 partitions (e.g. `{0: "RR", 1: "R"}`). Assert each published event_id `== replayID(source{dlqTopic, p, o, rec.Timestamp})` and that they are pairwise distinct. My probe `TestQAProbe134RawIDsPerRecord` ([p2-05](evidence/p2-05-harness.png)) has this shape and kills I7, I8 and I9.
2. **[nit] The lock release and lock-error paths aren't tested** (L8, L11, L12 survive; all caught by #134 probes):
   - L8: `unlock` doesn't unlock.
   - L11: the lock is taken on a pooled connection rather than the dedicated one.
   - L12: a `TryLock` error is ignored and the run continues unlocked.

   Impact is bounded today because the CLI's pool (and its session) closes when the process exits. Fix (~10 lines):
   - in `TestAdvisoryLock_Integration`: after `unlockA()`, B gets the lock at once (`TestQAProbe134UnlockReleases`)
   - a `fakeStore.lockErr` row: error, 0 reads, 0 publishes (`TestQAProbe134LockErrorStops`)
3. **[nit] W1/W2 carried from #133** (nit 8 above). #134 merges `bbb2657`, so both mutants survive here too.
4. **[observation, no action]** The stack data shows the expected poison loop. The corrupt-PDF event `9999.00001` (`event_id 01M8G95995…`) fails again on every replay and returns as a new DLQ offset (6/0 → 6/1 → 6/2), and each one is replayed exactly once. This is the design's documented behaviour (Q5, "the new DLQ record is a new offset that the next run replays once"). The operator stops it with `--error-type` or by fixing the input. Product might want "known-poison" handling later; Mahesh's call, not a ticket.

## Size
387 lines vs its base, inside the 800 bundle guideline. Easy to follow: the lock is in `store.go`/`manager.go`, the ID in `envelope.go`, and the proof is one stack step.

## Hand-off
- #134: FAIL → backend-engineer, rework round 1 of 2. Fix finding 1 in this PR; preferably 2 and 3 too.
- #133: PASS → pm-lead final review.
- Merge order when both pass: #133 first, then retarget #134 to `main` and merge it. The combined PM-equivalent check (OPS-2/OPS-3 product fit) will be added when #134 passes. QA's next round re-runs `mutants134*.py` and the #134 probes from [p2-05](evidence/p2-05-harness.png).
