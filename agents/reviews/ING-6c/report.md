<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-22T02:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/124#issuecomment-7072854957 (posted 2026-11-22T02:21:10Z); the QA harness could not write this file. -->

[qa-reviewer] # QA report — ING-6c · PR #124 · round 1

**Verdict:** FAIL
**Reviewed commit:** `dec6386a8a96f87b8d8faba0c2065ac601036cb6` (CI merge ref `50d4471` = dec6386 into main `53171d6`, which is still current main) · **Date:** 2026-11-22
**Ticket:** [`agents/tasks/ING-6c.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/ING-6c.md) · **PRD:** Product ING-6; Technical PRD §11 "Scheduled crawler", §9 (politeness); design `docs/design/ING-6.md` (approved)
**Evidence:** [`agents/reviews/ING-6c/evidence/` @ 6110552](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence) (each image has a `.txt` with the full output)

## Test results
| Check | Source | Result |
|---|---|---|
| Full stack (compose + make test-full) | CI job 137004575227 | **failure**: in the PR's new step "ING-6: crawl-loop", precondition `##[error]want the 2 crawled papers, got: 2611.26619 2611.26627 9999.00001` ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/00-ci-checks.png?raw=true), `` [01](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/01-stack-failure.png?raw=true)) ``` |
| Go (vet, gofmt, test, build) | CI | success |
| DB (migrate twice, HNSW plan + recall) | CI job 137004574551 | success, incl. the new ING-6c step ([08](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/08-AC7-db-ci.png?raw=true)) ```` |
| Python M0 unit tests / Frontend / Agent ownership / Pinned digests | CI | success (all 4) |
| `go test ./...`, `go vet ./...`, `gofmt -l` | local, go1.25.1, tag-pinned GitHub clones replace the non-GitHub modules (`-modfile`, app tree untouched) | all `ok`, vet OK, gofmt clean ([04](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/04-AC9-unit-lint.png?raw=true)) ````` |
| `TestCrawlLoopFlags`, `TestRunOnce*` with `-race` | local | PASS ([02](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/02-AC1-flags.png?raw=true), `````` [03](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/03-AC11-runonce.png?raw=true)) ``````` |
| `go vet -tags integration ./internal/db/` + both integration tests | local, real PostgreSQL 16.15 | PASS; 0 `it-test.%` rows and 0 advisory locks left ([06](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/06-AC7-integration-local.png?raw=true)) ```````` |
| Mutation run (17 mutants, incl. the ticket's M6, M8, M9) | local, PG16 + unit suites | 16 KILLED, 1 SURVIVED (C1, finding 3) ([05](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/05-mutants.png?raw=true `````````), harness [07](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/07-harness.png?raw=true ``````````)) |
| `make stack-up … crawl-loop --once` | not run locally: no Docker in the sandbox | CI only, and the CI step failed before running it |
| `make eval` | not run: no retrieval/answering change | n/a |

### Is the Full stack failure caused by this PR? Yes.
- The failing step `ING-6: crawl-loop` is new in this PR (`.github/workflows/stack.yml` line 313). It runs **after** `AC4: make test-full`
  and first collects "the two crawled papers" with `select arxiv_id from papers where arxiv_id <> '2608.20331'`, then requires exactly 2 rows.
- `make test-full` runs `tests/test_m4_chaos.py`, which inserts `9999.00001` ('Corrupt Test Paper', line 106) and never deletes it. So on
  every stack run the `papers` table holds 3 non-fixture rows when this step starts, and the precondition fails deterministically. All
  earlier steps in this job were green, including `make test-full` (`441 passed, 1 skipped, 3 deselected`) and F1 (`3 passed`).
- Comparison: `stack.yml` has never run on `main` (`runs?branch=main` total_count = 0; it is a `pull_request` workflow). The same-day runs
  on other PR branches over the same main are all success: `agent/ai/OPS-H21` 0970737, `agent/ai/EVAL-8c` b91f78e, `agent/ai/AI-14`,
  `agent/ai/EVAL-6c`, `embedder/rerank-fp16` ([00](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/00-ci-checks.png?raw=true)). ``````````` Only this PR adds the failing step.
- Consequence: `crawl-loop` never ran in CI. The job log has no `[CrawlLoop]`, `AC2:`, `AC4` or `AC5` output line ([01](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/01-stack-failure.png?raw=true), ```````````` last section).

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 flags | ✅ | `TestCrawlLoopFlags`: 7 rows PASS locally ([02](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/02-AC1-flags.png?raw=true)); ````````````` Go CI job `ok arxivlens/cmd/arxivlens`. Rejections are tested through `newCrawlLoopCmdWith(run)` with `run` never called (the only path that connects). Mutants F1–F7 (each check dropped or loosened, run-before-validate, wrong default) all KILLED ([05](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/05-mutants.png?raw=true)). `````````````` |
| AC2 single instance | ⚠ partial | `TestCrawlLoopLock` PASS in CI db.yml ([08](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/08-AC7-db-ci.png?raw=true)) ``````````````` and locally on PG16 ([06](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/06-AC7-integration-local.png?raw=true)). ```````````````` Lock mutants L1 (no unlock), L2 (ok ignored), L3 (xact-level lock) and L4 (conn not released) all KILLED; L2–L4 show up as test timeouts (finding 4). **The `stack.yml` half has no evidence, because the step failed before it**: a second `--once` exiting non-zero with `another crawl-loop is running` and making 0 arXiv requests. |
| AC3 zero events on second run | ❌ no evidence | The step failed at the precondition. No `AC2: second run produced 0 papers.discovered events (N -> N)` line in the job log ([01](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/01-stack-failure.png?raw=true)). ````````````````` |
| AC4 kill + restart | ❌ no evidence | Same: no `AC4 …` lines in the job log. |
| AC5 SIGTERM | ❌ no evidence | Same: no `AC5 SIGTERM: exit …` or `[CrawlLoop] stopped` line. I reviewed the code path (`Loop.Run` returns nil and logs `[CrawlLoop] stopped` once ctx is done; the command uses `signal.NotifyContext(os.Interrupt, SIGTERM)`), but that isn't the evidence the AC asks for. |
| AC6 politeness | ⚠ vacuous | `arXiv replay: {"hits": 5, "misses": 0, …}` ([01](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/01-stack-failure.png?raw=true)). `````````````````` But `crawl-loop` made no requests in this run, so 0 misses says nothing about it. `out_of_order=` is in the summary format (`runCategory` in `loop.go`) and appears in unit-test log lines (05, C1 probe), but in no stack job line yet. |
| AC7 db.yml | ✅ | The db.yml step runs `go vet -tags integration ./internal/db/` and the exact `-v -run '^(TestAdvanceWatermarkMonotonic\|TestCrawlLoopLock)$'` line. The log shows `--- PASS: TestAdvanceWatermarkMonotonic (0.22s)`, `--- PASS: TestCrawlLoopLock (0.01s)`, `ok arxivlens/internal/db`, no SKIP. The step fails on `--- SKIP` or a missing PASS line ([08](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/08-AC7-db-ci.png?raw=true)). ``````````````````` |
| AC10 watermark test gaps | ✅ | (a) `connectIT` registers `t.Cleanup(d.Close)` first, then the DELETE cleanup; CI log: `crawl_watermarks rows left by the tests (category LIKE 'it-test.%'): 0` ([08](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/08-AC7-db-ci.png?raw=true)). ```````````````````` `TestCrawlLoopLock` uses the same order. (b), (c), (d): rows present; mutants **M6, M8 and M7 KILLED** by `TestAdvanceWatermarkMonotonic` on real PG16 ([05](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/05-mutants.png?raw=true)). ````````````````````` The AC asks for the mutant output "in the PR". The developer couldn't run the mutants (ticket Notes), so this QA run is that output. |
| AC8 README | ✅ | CLI row for `crawl-loop` with all 5 flags. The "Scheduled crawl" paragraph covers the first-run horizon with backfill via `arxivlens crawl`, one instance enforced by the lock, `backlog=` / `out_of_order=`, raising `--limit-per-run` (and `--max-scan`), resetting a category, and the late-announcement gap (ING-6e). Prerequisites says PostgreSQL 16 + pgvector ≥ 0.8.0, consistent with the compose pin comment (0.8.7) ([09](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/09-AC8-readme.png?raw=true)). `````````````````````` |
| AC9 CI green | ❌ | The `make test-unit`/`make lint` equivalents are green (Go job; local run 04) and db.yml is green, but **`stack.yml` is red** ([00](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/00-ci-checks.png?raw=true)). ``````````````````````` |
| AC11 loop tests | ✅ | (a) Row `TestRunOnceCrossListed/cs.AI's_publish_of_p14_fails:_cs.LG_publishes_it`; **M9 (acked before Publish) KILLED** both in the full crawler run and with `-run '^TestRunOnceCrossListed$'`. (b) `TestRunOnceCancelledAfterFirstCategory` PASS (see finding 3). (c) The single prefix is asserted as the exact string `cat:cs.LG: page start=0: arxiv 503`; mutant P1 (walk re-adds `cat:`) is KILLED by `TestRunStopsOnCancel/Once_returns_the_pass_error` ([03](```````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/03-AC11-runonce.png?raw=true), ```````````````````````` [05](````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/05-mutants.png?raw=true)). ````````````````````````` |

## PRD fit
The code faithfully implements the approved design: flags are validated before any connection, one global advisory lock is taken before
the first arXiv request, there is one limiter per process, and SIGTERM stops it cleanly. Unit tests, integration tests and mutants cover it
well. But the real-stack step was supposed to prove exactly the PRD row ING-6 ("a second run with no new papers emits zero events; kill +
restart, no duplicates or skips"), and that step never got past its precondition. The headline claim has no evidence yet.

## Findings
1. **[blocking] `stack.yml` "ING-6: crawl-loop" fails deterministically, so AC2 (stack half), AC3, AC4, AC5, AC6 and AC9 have no evidence.**
   The precondition `mapfile -t crawled < <(q "select arxiv_id from papers where arxiv_id <> '2608.20331' order by 1")` also picks up
   `9999.00001`, which `tests/test_m4_chaos.py:106` inserts during the earlier `make test-full` step and never removes. This happens on
   every run, so it is not flaky and not main's fault.
   - **Fix:** make the step identify the two crawled papers independently of whatever `make test-full` leaves behind. For example, record
     the IDs right after "AC3: crawl 2 papers" (before test-full), or select the two newest IDs of the recorded `cat:cs.LG` feed. Avoid a
     fixture deny-list, which breaks again the next time a test seeds a row. The `check()` baseline `papers0` is also taken after test-full,
     so the chosen approach must keep "count unchanged" meaningful.
   - **Then:** re-run and confirm the job log carries every line AC3–AC5 name, and that the replay stats still show `misses: 0`:
     `AC2: second run produced 0 … (N -> N)`, both `[CrawlLoop] cat=cs.LG …` lines, the `crawl_watermarks` row, `AC4 …` ×2, the `AC2 lock:`
     line with equal request counts, `AC5 SIGTERM: exit 0 after … ms`, and `[CrawlLoop] stopped`.
   - The developer checked the script only with `bash -n` and stubs (ticket Notes). Stubs can't reproduce a DB row left by another step.
2. **[nit] Design condition 10 not written back.** The PR body mentions the error-text change: `walk` no longer adds a `cat:` prefix, so the
   backlog error now reads `cat:cs.LG: backlog exceeds --max-scan N; …`. But `docs/design/ING-6.md` line 51 still quotes
   `backlog in cat:c exceeds --max-scan N; …`, and there is no "Build notes (ING-6c)" section. Condition 10 requires the write-back "in the
   same cycle". Add it before PM review. The change is cosmetic and AC11(c) mandates it.
3. **[nit] `TestRunOnceCancelledAfterFirstCategory` doesn't pin `RunOnce`'s own cancel check.** Mutant C1 deletes the guard between
   categories (`if ctx.Err() != nil { errs = append(errs, ctx.Err()); break }`). It survives the full crawler suite and the named test,
   because `walk`'s own `ctx.Err()` check still gives 0 feed requests and an error wrapping `context.Canceled`. The behaviour does change:
   the mutant reads cs.LG's watermark with a dead ctx and logs a spurious `[CrawlLoop] cat=cs.LG pages=0 … error=context canceled` line
   (probe at the end of [05](`````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/05-mutants.png?raw=true ``````````````````````````) / `.txt`). AC11(b) as worded is met, so this is not blocking. Asserting 0
   `Watermark` reads for cs.LG, or the exact error string, would pin the guard.
4. **[nit] `TestCrawlLoopLock` failure modes hang instead of failing.** With lock mutants L2, L3 and L4, the test hits `t.Fatalf` while a
   pooled connection is still acquired, and `t.Cleanup(d.Close)` then blocks forever (pgxpool `Close` waits for acquired conns). The job
   would end only at `go test`'s 10-minute default timeout. These regressions would still turn db.yml red, but as a panic dump with no
   test message. Releasing any non-nil `release`/`r` in a cleanup, or adding `-timeout` to the db.yml line, would make the failure readable.

## Missing tests
- The stack evidence for AC2–AC5 (finding 1) is the main gap. Everything else in the ticket's test plan exists and is mutation-checked.
- No test checks that a crashed holder's lock is freed when its session ends (the `kill -KILL` → `lock_free` path). Only the stack step
  covers it, and that step hasn't run yet.

## Scope
9 files, +388/−18. Every file is in the ticket's Scope list and in backend-engineer's owned paths, and the Agent ownership check passed. No
tickets, reviews or docs leaked into the PR ([10](``````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6110552a229f28d0b84fc19388a284484f98887a/agents/reviews/ING-6c/evidence/10-scope.png?raw=true ```````````````````````````)). Nothing from "Out of scope" is touched (compose service,
lookback, `crawl --rate-limit`, `Crawl` changes).

## Hand-off
FAIL → back to backend-engineer (finding 1 is blocking; 2–4 are nits). The re-review will check finding 1 against a fresh stack job log, line by line.

Note: the QA harness refused to write `agents/reviews/ING-6c/report.md`; this comment is the full report, and the orchestrator saves it verbatim.


---
_Generated by [Claude Code](https://claude.ai/code)_
