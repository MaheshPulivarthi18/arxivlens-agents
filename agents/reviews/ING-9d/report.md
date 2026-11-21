_Provenance: saved verbatim by the orchestrator from ArxivLens PR #112 comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/112#issuecomment-7062031349 (the qa-reviewer harness refused to write report.md)._

[qa-reviewer] QA report: ING-9d, PR #112, round 1

**Verdict:** PASS
**Reviewed commit:** `ac9ba424b1aaee49fae7ab5a10d34df9fb2e4efe` · **Date:** 2026-11-21
**Ticket:** `agents/tasks/ING-9d.md` · **PRD:** Technical PRD §9 "External politeness"; Product PRD ING-1; ING-9c QA r1 mutant x5
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence
(The harness refused to write `report.md`, so this comment is the report. The orchestrator saves it verbatim.)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136830906501 (merge `a46eb9d` = ac9ba42 into main `11c4696`) | pass: `make lint-go` and `make test-go` (`GOFLAGS=-race`) gave `ok arxivlens/internal/arxiv`, with 0 `--- FAIL` lines ([07](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/07-AC4-ci-go-lint.png?raw=true)) `` |
| Python M0 unit tests | CI | pass ([00](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/00-ci-checks.png?raw=true)) ``` |
| Frontend (lint, test, build) | CI | pass, `npm run lint` step success ([07](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/07-AC4-ci-go-lint.png?raw=true)) ```` |
| DB / Full stack | CI | pass / pass ([00](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/00-ci-checks.png?raw=true)) ````` |
| Agent ownership check | CI | pass ([00](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/00-ci-checks.png?raw=true)) `````` |
| Ticket verification commands | local, Go 1.25.1 (`GOTOOLCHAIN=local`) | `-count=20 -race -v`: 20/20 PASS. `./internal/arxiv/...`: ok ([02](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/02-AC1-race-count20.png?raw=true)). ``````` `gofmt -l` clean, `go vet` ok ([08](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/08-AC4-local-lint.png?raw=true)). ```````` Full `make test-unit`/`make lint` left to CI |
| `make eval` | not run: test-only change, no retrieval/answering code touched | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: at least 50 tries, a fresh `NewLimiter(time.Hour)` each time, cancelled ctx gives `errors.Is(err, context.Canceled)`, then `waitImmediate`; passes `-count=20 -race` | ✅ | `TestCancelledCtxNeverTakesPermit` in `internal/arxiv/limiter_test.go` (+19 lines, [01](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/01-diff-scope.png?raw=true)): ````````` loop `i < 50`, fresh limiter per try, `errors.Is` check, an extra `l.last.IsZero()` check, then `waitImmediate(t, l)`. `-count=20 -race -v`: PASS 20/20, FAIL 0 ([02](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/02-AC1-race-count20.png?raw=true)) `````````` |
| AC2: x5 makes the new test fail 30/30; unmutated passes 30/30 | ✅ | QA ran this in a temp copy, never on the PR branch. x5: FAIL 30/30. Unmutated control: PASS 30/30, both before and after ([03](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/03-AC2-mutants.png?raw=true)). ``````````` x5 under `-race`: FAIL 30/30 ([04](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/04-AC2-x5-control.png?raw=true)). ```````````` Negative control: with **main's** test file, x5 fails only `TestFirstWaitIsImmediate`, 14 times out of 30. That reproduces the flakiness the ticket cites ([04](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/04-AC2-x5-control.png?raw=true)). ````````````` Harness sources: [06](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/06-harness-sources.png?raw=true) `````````````` |
| AC3: runtime under 100 ms | ✅ | `--- PASS: TestCancelledCtxNeverTakesPermit (0.00s)` three times, and `(0.00s)` under `-race`. 1000 runs took 0.056 s ([05](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/05-AC3-runtime.png?raw=true)) ``````````````` |
| AC4: CI `Go` and `Lint` green | ✅ | Go job success, every step success including `make lint-go` and `make test-go` ([07](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/07-AC4-ci-go-lint.png?raw=true)). ```````````````` lint-fe (`npm run lint`) success in the Frontend job. All 6 check runs on ac9ba42 success ([00](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/00-ci-checks.png?raw=true)) ````````````````` |
| Docs: none | ✅ | Test-only. The diff is exactly `internal/arxiv/limiter_test.go` ([01](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/01-diff-scope.png?raw=true)) `````````````````` |

## Scope
One file changed: `internal/arxiv/limiter_test.go`, +19/−0. It is inside the backend-engineer's `internal/` paths and inside the ticket's scope. No non-test file changed, no other test file changed, and no existing test's assertions changed. No ticket, review or doc files leaked into the PR (the CI ownership check is green). The PR is open and draft, not merged.

## QA's own mutants (beyond x5), 30 runs each ([03](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb6609de55388174b48cabdab2fff36c3486465/agents/reviews/ING-9d/evidence/03-AC2-mutants.png?raw=true)) ```````````````````
| Mutant | Result |
|---|---|
| M2: the up-front check sets `l.last` and still returns err (cancelled call uses up a permit while reporting the cancel) | killed 30/30. The `l.last.IsZero()` check catches it at once; without that check the test would block for the 1 h interval |
| M3: the up-front check returns `nil` | killed 30/30 |
| M4: the up-front check returns an error that doesn't wrap `context.Canceled` | killed 30/30 |
| M5: x5, plus the first select's `ctx.Done` case returns `nil` | killed 30/30 |
| T1 (test mutant): loop once instead of 50 times, with x5 | FAIL 11/30 (19/30 in an earlier run). A single try is a coin flip, so the 50-try loop is what makes the test deterministic |
| T2 (test mutant): drop the `l.last` check, with x5 | still FAIL 1/1. Under x5, a call that takes the permit returns `nil`, so the `errors.Is` check fails first |

No production mutant survived.

## PRD fit
Technical PRD §9 allows at most 1 arXiv request per 3 s. If a cancelled caller quietly took a permit, the next real request would wait a full extra interval. Today's tests catch that regression only some of the time (14/30). This PR makes it fail every time (30/30), without touching the limiter itself.

## Findings
1. [nit] For x5 itself, the `l.last.IsZero()` check adds nothing: `errors.Is` already fails (T2). It still earns its place, because it catches M2 (a cancelled call that sets `l.last` and still returns `Canceled`) in milliseconds instead of hanging for `time.Hour`. The code comment says the check is there to fail fast, which is accurate. No change needed.
2. [spec] AC4 names a `Lint` CI job, but there is none. `make lint` is `lint-go` (a step in the `Go (vet, gofmt, test, build)` job) plus `lint-fe` (the `npm run lint` step in the `Frontend` job). I verified both as steps. pm-lead: future tickets should name those steps, not a job.

## Missing tests
- None in this ticket's scope.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM review (pm-lead), 2026-11-21

**Verdict: APPROVE**
**Reviewed head:** `ac9ba424b1aaee49fae7ab5a10d34df9fb2e4efe` (PR #112, draft, open, not merged). The diff (`gh api .../pulls/112/files`) is exactly `internal/arxiv/limiter_test.go` +19/−0.

**CI (re-checked via check-runs API on ac9ba42):** 6/6 `completed success`: Go (vet, gofmt, test, build) · Frontend (lint, test, build) · Python M0 unit tests · DB (migrate twice, HNSW plan + recall) · Full stack (compose + make test-full) · Agent ownership check.

**Evidence opened (all 9 PNGs + .txt siblings):**
| File | Proves | OK? |
|---|---|---|
| 00-ci-checks | 6 check runs success on ac9ba42; PR draft, unmerged | yes |
| 01-diff-scope | one file, +19; loop `i < 50`, fresh `NewLimiter(time.Hour)`, `errors.Is(err, context.Canceled)`, `l.last.IsZero()`, `waitImmediate` (AC1 shape, scope) | yes |
| 02-AC1-race-count20 | `-count=20 -race -v`: 20/20 PASS, 0 FAIL; `./internal/arxiv/...` ok (AC1) | yes |
| 03-AC2-mutants | x5 FAIL 30/30; unmutated control PASS 30/30 before and after; M2–M5 killed 30/30; T1 shows the 50-try loop is what makes it deterministic (AC2) | yes |
| 04-AC2-x5-control | main's tests vs x5: only 14/30 FAIL (the flakiness this ticket fixes); new test vs x5 under `-race` 30/30 FAIL (AC2) | yes |
| 05-AC3-runtime | `--- PASS: TestCancelledCtxNeverTakesPermit (0.00s)` ×3 and under `-race`; 1000 runs 0.056 s (AC3) | yes |
| 06-harness-sources | mutation harness copies to a temp dir, never edits the PR checkout; build failures reported INVALID | yes |
| 07-AC4-ci-go-lint | Go job steps all success incl. `Run make lint-go` and `make test-go` (race), `ok arxivlens/internal/arxiv`, 0 FAIL lines; Frontend `Run npm run lint` success (AC4) | yes |
| 08-AC4-local-lint | `gofmt -l` clean, `go vet ./internal/arxiv/` ok (supporting) | yes |

**Product / scope fit:** Technical PRD §9 "External politeness" (≤ 1 arXiv request / 3 s) depends on a cancelled caller never consuming a permit; today a regression of the up-front `ctx.Err()` check would surface only as a ~50% flaky test. This PR turns that into a 30/30 failure with a 0.00 s test, touching no production code. Scope matches the ticket exactly (one test, one file, existing assertions untouched). The extra `l.last.IsZero()` assert is within the AC's intent (QA nit 1 agrees: it makes M2 fail fast instead of hanging for an hour). No README/CONTRIBUTING change needed; no PRD status column changes (ING-1 status unchanged by a test-only harness task).

**QA findings:**
1. [nit] `l.last` check redundant for x5: accepted as is, no change.
2. [spec] AC4 named a non-existent `Lint` job: fixed in the ticket (AC4 now names the `Go (vet, gofmt, test, build)` job with steps `Run make lint-go` / `Go unit tests (make test-go, race detector)` and the Frontend job's `Run npm run lint` step). Evidence 07 already covers the reworded AC. Lesson added to `agents/memory/lessons.md` (pm-lead).

**Follow-ups:** OPS-H19 AC7 also names a `Lint` job; correct it at that ticket's PM review (not edited here to avoid colliding with the parallel review).

**Action:** PR #112 description rewritten with pinned evidence, marked ready for review, label `ready-to-merge`. Merge is Mahesh's.
