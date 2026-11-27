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

---

# QA report: ING-6c · PR #124 · round 2

**Verdict:** PASS
**Reviewed commit:** `d55508f3e372ce08ca8dea4ad05603c08a04e3a8` (rework of r1 FAIL at `dec6386`; main is still `53171d6`) · **Date:** 2026-11-27 · cycle 2026-11-27T03:59Z
**Ticket:** [`agents/tasks/ING-6c.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/ING-6c.md) · **PRD:** Product ING-6; Technical PRD §11 "Scheduled crawler", §9 · **Design:** `docs/design/ING-6.md` (approved; conditions 3, 6, 7, 9, answer 3)
**Evidence (round 2):** files 11–19 in [`agents/reviews/ING-6c/evidence/` @ 17556f9](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence). Every PNG has a `.txt` next to it with the full output. CI excerpts were rendered with `--from-file` from job logs I fetched myself.

## Test results
| Check | Source | Result |
|---|---|---|
| All 7 check runs on `d55508f` | CI | **success** ×7: Full stack 140306711751, DB 140306712586, Go, Python M0, Frontend, Agent ownership, Pinned digests ([11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/11-r2-ci-checks.png?raw=true)) |
| Full stack step "ING-6: crawl-loop" | CI job 140306711751 log | Ran to the end. Every AC2–AC5 line is present ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/12-r2-AC2-AC5-stack-crawl-loop.png?raw=true)) |
| arXiv replay stats | same job | `{"hits": 11, "misses": 0, …}` ([13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/13-r2-AC6-replay-stats.png?raw=true)) |
| db.yml integration step | CI job 140306712586 log | `--- PASS: TestAdvanceWatermarkMonotonic`, `--- PASS: TestCrawlLoopLock`, `ok arxivlens/internal/db`, no SKIP, leftover rows `0` ([14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/14-r2-AC7-db-ci.png?raw=true)) |
| `go vet ./...`, `gofmt -l`, `go test ./...` (= `make lint-go` + `make test-go`) | local, go1.25.1, `-modfile` with tag-pinned GitHub clones for the non-GitHub deps (app tree untouched) | vet OK, gofmt clean, every package `ok` (telemetry included this time) ([15](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/15-r2-AC9-unit-lint-local.png?raw=true)) |
| `TestCrawlLoopFlags`; `TestRunOnce*` with `-race` | local | 7/7 flag rows PASS; 4 RunOnce tests incl. both new rows PASS ([16](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/16-r2-AC1-AC11-local.png?raw=true)) |
| `go vet -tags integration ./internal/db/` + both integration tests | local, PostgreSQL 16.15 | PASS; 0 `it-test.%` rows and 0 advisory locks left ([17](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/17-r2-AC7-integration-local.png?raw=true)) |
| Mutation run (r1's 17 mutants, re-applied to `d55508f`) | local, PG16 + unit suites | **17/17 KILLED**, controls PASS ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/18-r2-mutants.png?raw=true)) |
| `make test-py` / `make lint-fe` | not run locally: no torch/HF and no npm in the sandbox | CI: Python M0 and Frontend jobs success |
| `make eval` | not run: no retrieval or answering change | n/a |

## Round-1 findings
| # | r1 finding | Status | Evidence |
|---|---|---|---|
| 1 | [blocking] stack step precondition picked up `9999.00001` | **Fixed** | The "AC3: wait" step writes `crawled-ids.txt` while the 2 crawled papers are the only rows. That runs before the 2608.20331 fixture seed and before `make test-full` (stack.yml lines 241–270). The step reads that file with no deny-list. Log: `crawled papers (AC3): 2611.26619 2611.26627; all papers now: 2608.20331 2611.26619 2611.26627 9999.00001`. `papers0` is still taken at step start (`4 4`), so "count unchanged" still detects a duplicate or a new version from any `crawl-loop` run ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/12-r2-AC2-AC5-stack-crawl-loop.png?raw=true), diff in [19](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/19-r2-scope-rework-diff.png?raw=true)). |
| 2 | [nit] design condition 10 write-back | **Fixed** | In this repo, `docs/design/ING-6.md` line 51 now quotes `cat:c: backlog exceeds --max-scan N; …`, and a new "Build notes (ING-6c)" section (commit `d725911`) records the prefix move, the cancel-guard text, the lock shape and the `crawled-ids.txt` hand-off. Matches `loop.go` lines 109 and 197. |
| 3 | [nit] mutant C1 survived | **Fixed** | `TestRunOnceCancelledAfterFirstCategory` now asserts `err.Error() == "context canceled"`. C1 is KILLED in the full crawler run and by the named test: `RunOnce = cat:cs.LG: context canceled … want exactly "context canceled"` ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/18-r2-mutants.png?raw=true)). |
| 4 | [nit] lock-test failure modes hang | **Fixed** | Measured with `-timeout=120s`: L2 and L3 now fail in 0.6 s with `second acquirer while held: …`. L4 fails in 10.6 s with `DB.Close still blocked after 10s: a pooled connection was never released`. L1 fails in 0.6 s. All four used to run to the go-test timeout ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/18-r2-mutants.png?raw=true)). |
| r1 missing test | crashed holder's lock freed on session end | **Covered in CI** | After `kill -KILL`, `lock_free` polls `pg_locks` for 0 advisory locks and the following `--once` succeeds. The step would have failed otherwise ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/12-r2-AC2-AC5-stack-crawl-loop.png?raw=true)). |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 flags | ✅ | 7 rows PASS ([16](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/16-r2-AC1-AC11-local.png?raw=true)). Mutants F1–F7 all KILLED ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/18-r2-mutants.png?raw=true)). Go CI job green. |
| AC2 single instance | ✅ | `TestCrawlLoopLock` PASS in db.yml ([14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/14-r2-AC7-db-ci.png?raw=true)) and on local PG16 ([17](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/17-r2-AC7-integration-local.png?raw=true)). L1–L4 KILLED. Stack: `Error: another crawl-loop is running (PostgreSQL advisory lock held); …`, then `AC2 lock: --once beside a running crawl-loop exited non-zero; arXiv requests (replay hits+misses) 9 -> 9`. The step asserts the non-zero exit, the message and equal counts ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/12-r2-AC2-AC5-stack-crawl-loop.png?raw=true)). |
| AC3 zero events on 2nd run | ✅ | `AC2: first run produced 2 papers.discovered events (3 -> 5)`, `AC2: second run produced 0 papers.discovered events (5 -> 5)`, both summary lines (`candidates=2 emitted=2 … (advanced)` / `candidates=0 emitted=0 … (unchanged)`), and the `crawl_watermarks` row `cs.LG\|2026-11-19 18:59:53+00\|…` ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/12-r2-AC2-AC5-stack-crawl-loop.png?raw=true)). |
| AC4 kill + restart | ✅ | `AC4 (i) DELETE FROM crawl_watermarks …` and `AC4 (ii) kill -KILL of a looping crawl-loop ~1 s after start …` each show `= 4 4 (before the step: 4 4)`, `both crawled IDs present (2611.26619 2611.26627)` and `W(cs.LG) = max(published_at) of them: t`. The log carries `kill point not controlled; exact points: ING-6b TestRunCategoryCrashAtK` ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/12-r2-AC2-AC5-stack-crawl-loop.png?raw=true)). See finding 1 below. |
| AC5 SIGTERM | ✅ | `[CrawlLoop] stopped`, `AC5 SIGTERM: exit 0 after 7 ms`. The step asserts rc 0, the < 5 s bound (50 × 0.1 s) and the stopped line ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/12-r2-AC2-AC5-stack-crawl-loop.png?raw=true)). |
| AC6 politeness | ✅ | Replay `misses: 0` after crawl-loop's 6 passes. Every `[CrawlLoop] cat=cs.LG …` line carries `out_of_order=0` ([13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/13-r2-AC6-replay-stats.png?raw=true)). No longer vacuous: crawl-loop now makes real feed requests (hits 9 at the lock check, 11 at the end). |
| AC7 db.yml | ✅ | Exact vet line and `-v -run '^(TestAdvanceWatermarkMonotonic\|TestCrawlLoopLock)$'` line. Both PASS lines present, no SKIP ([14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/14-r2-AC7-db-ci.png?raw=true)). |
| AC10 watermark test gaps | ✅ | (a) `rows left … : 0` in CI ([14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/14-r2-AC7-db-ci.png?raw=true)) and locally ([17](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/17-r2-AC7-integration-local.png?raw=true)). The bounded close cleanup is still registered before the DELETE cleanup. (b)(c)(d) M6, M8 and M7 KILLED ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/18-r2-mutants.png?raw=true)). |
| AC8 README | ✅ | Unchanged since r1 (the rework diff touches no README, see [19](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/19-r2-scope-rework-diff.png?raw=true)). The r1 evidence [09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/09-AC8-readme.png?raw=true) still holds. |
| AC9 CI green | ✅ | 7/7 success incl. Full stack and DB ([11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/11-r2-ci-checks.png?raw=true)). Local vet, gofmt and go test are clean ([15](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/15-r2-AC9-unit-lint-local.png?raw=true)). |
| AC11 loop tests | ✅ | (a) M9 KILLED in the full crawler run and with `-run '^TestRunOnceCrossListed$'`. (b) C1 is now KILLED too. (c) P1 KILLED by the exact-string assertion ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/18-r2-mutants.png?raw=true)). |

## PRD fit
The PRD row is now proven on the real stack. A second `--once` with no new papers emits 0 `papers.discovered` events. After a lost watermark,
and after a SIGKILL plus restart, `papers` has no duplicate and no missing crawled ID, and W equals the max `published_at` of the crawled papers.
Politeness holds: one instance is enforced before any arXiv request, and the replay shows 0 misses. No shared contract (events, HTTP API,
schema) changes. No threshold or eval gate is touched.

## Findings (round 2, none blocking)
1. **[spec] AC4 (ii) exercises lock recovery after SIGKILL, not a mid-publish kill.** The killed instance had already finished its pass
   (`candidates=0 emitted=0 … (unchanged)`) before the 1 s kill, because W was already at the max. So (ii) proves that the advisory lock
   is freed and that a restart is clean, but no publish was in flight at the kill. The AC accepts this: it requires the "not controlled"
   statement and points to ING-6b `TestRunCategoryCrashAtK` for the exact points, and the log has that statement. If pm-lead wants a kill
   with work in flight, a `DELETE FROM crawl_watermarks` before (ii) would give the killed pass 2 candidates. That would be a follow-up
   spec change, not a defect here.
2. **[code][nit] The lock error prints twice** (`Error: another crawl-loop is running …` ×2, from cobra and from `main`). It predates this PR
   (CLI-wide), it's out of scope, and it's already queued as OPS-H7a2c.

## Scope
Same 9 files as round 1, +407/−18 vs `53171d6`. The rework touches 3 files (+39/−20): `stack.yml`, `loop_test.go`, `watermarks_integration_test.go`
([19](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/17556f994074fc220694e8ee1ae5f45bd18e6ec5/agents/reviews/ING-6c/evidence/19-r2-scope-rework-diff.png?raw=true)). All of them are in the ticket's Scope and backend-engineer's owned paths, and the Agent ownership
check passed. The diff is over the 400-line target but under the design's 480 gate, which the ticket allows. No ticket, review or doc files
leaked into the PR, and nothing listed as out of scope is touched.

## Hand-off
PASS → pm-lead for final review (KAN-66 → PM review; Jira skipped this cycle per orchestrator). Findings 1–2 are informational.
