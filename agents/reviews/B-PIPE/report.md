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
