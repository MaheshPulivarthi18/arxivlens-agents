# QA report — RET-1 · PR #9 · round 1

> Written by qa-reviewer. The orchestrator saved this file because qa-reviewer's harness blocked it from writing report files. The text is qa-reviewer's own, unedited. The evidence is in commit b596aee.

**Verdict:** PASS
**Reviewed commit:** `831905e911ac04884ed2b301da500874a3fc5820` · **Date:** 2026-11-02
**Ticket:** `agents/tasks/RET-1.md` · **PRD:** Product PRD QA-1, QA-2 (§6.2); Technical PRD §7.1; ADR-0010 (Accepted)
**Design:** `docs/design/RET-1.md` (Approved, 8 binding conditions) · **Evidence pack:** `agents/reviews/RET-1/evidence/` (commit b596aee)

I reviewed this from the ticket, the design, ADR-0010, the diff, CI and my own runs. I did not use the developer's self-report. I wrote the QA scripts behind evidence 03–11 and copied them unchanged to `agents/reviews/RET-1/scripts/`.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI, go1.25.0 | **pass**: `make lint-go` (vet + gofmt), `go test ./...` → `ok arxivlens/internal/query`, `make build-go` ([00](evidence/00-ci-checks.png), [01](evidence/01-ci-go-job-log.png)) |
| Python M0 unit tests | CI | pass ([00](evidence/00-ci-checks.png)) |
| Frontend (lint, test, build) | CI | pass; the PR doesn't touch frontend ([00](evidence/00-ci-checks.png)) |
| Agent ownership check | CI + local | pass, `Ownership OK for role=backend (391 changed lines)` ([00](evidence/00-ci-checks.png), [02](evidence/02-scope-ownership.png)) |
| Ticket verification `go vet && gofmt && go test -cover ./internal/query/...` | local, partial | The real module was **not run locally**: the sandbox has go1.24.7, and the go1.25 toolchain and pgx can't be downloaded ([12](evidence/12-local-gofmt-toolchain.png)). `gofmt -l` on the changed files prints nothing ([12](evidence/12-local-gofmt-toolchain.png)). I ran the PR's `search.go` and `search_test.go` (sha256-checked as unchanged) with the real `client.go`/`rag.go` in a go1.24 harness with a stub `internal/db`: `go vet` clean, **all 8 tests / 25 subtests pass** ([05](evidence/05-ac1-order-by-score.png)–[09](evidence/09-ac5-no-rerank-unchanged.png), [11](evidence/11-test-map-and-full-run.png)). CI on go1.25 is the source of truth, and it is green. |
| Design condition 2: EVAL-1 parity test vs this branch's `search.go` | local (EVAL-1 @ d83a4c0) | **1 passed**. A negative control (one extra `// LIMIT 50` comment) gives **1 failed**, as expected; the script's exit code 1 comes from the control ([04](evidence/04-c2-parity-test.png)) |
| Mutation testing (17 QA-written mutants) | local harness | **17/17 caught** ([10](evidence/10-mutation-testing.png)) |
| `make eval` / `/v1/ask` p95 | not run: infra unavailable (no Docker, indexed corpus or HF model in the sandbox) | before → after: n/a (see AC6) |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: ordered by rerank score desc; RRF rank 8 with top score returned first | ✅ | `TestHybridSearchRerankOrdersByScore`, case `rrf_rank_8_has_top_score` → `[8 1 2 3 4]`, plus reversed and already-sorted cases ([05](evidence/05-ac1-order-by-score.png)). Code: `rerankAndSort` → `sort.SliceStable(... > ...)`. Mutants M3 (ascending sort), M4 (no pool), M5 (pool of 10) and M7 (no truncation) are caught ([10](evidence/10-mutation-testing.png)). CI `ok internal/query` ([01](evidence/01-ci-go-job-log.png)). |
| AC2: pool = `max(RerankPool, limit)`, exactly one rerank call | ✅ | `TestHybridSearchRerankPoolSize` checks `[fetch n, calls, passages, len]` for limit 5/20/50/0, for 7 available candidates, and for 0 available (0 calls) ([06](evidence/06-ac2-pool-one-call.png)). `search.go:74` calls `s.fetch(..., max(RerankPool, limit))`. Mutants M4, M5 and M17 are caught. |
| AC3: rerank failure or count mismatch → RRF order, top `limit`, no error, log line with trace ID | ✅ | `TestHybridSearchRerankFallback` covers error, timeout, too few scores, too many scores and NaN. It checks RRF order, length 5, `err == nil` and `RerankScore == 0`. It also checks the log has `trace_id=<32hex> `, `trace_id_source=ctx`, the reason and `pool=20`, and **does not** contain the query or passage text. `TestTraceIDFrom` covers the ctx and generated paths ([07](evidence/07-ac3-fallback-log.png)). Mutants M6, M8, M9, M10, M13, M14, M15 and M16 are caught. |
| AC4: ties keep RRF order | ✅ | `TestHybridSearchRerankTiesKeepRRFOrder`: all-equal scores keep the original order; interleaved tied pairs give `[2 5 3 7 1 4]` ([08](evidence/08-ac4-ties-rrf-order.png)). Mutant M1 (`SliceStable` → `Slice`) is **caught**, so the test really depends on a stable sort. |
| AC5: `rerank=false` byte-for-byte unchanged | ✅ | `TestHybridSearchNoRerankUnchanged` checks that `json.Marshal` output equals the fetched hits with no `rerank_score` key, that fetch n == limit (5/20/0→20), and that there are 0 rerank calls. `TestHybridSearchFetchError` checks the error passes through unchanged ([09](evidence/09-ac5-no-rerank-unchanged.png)). For the code below the test seam: the SQL literal is identical (same sha256), the four `fmt.Errorf` messages are identical, `$5` is bound to `n` (which equals `limit` when `rerank=false`), and the `HybridSearch`/`NewSearchEngine` signatures are unchanged ([03](evidence/03-design-conditions.png)). Mutants M11 and M12 are caught. |
| AC6: `make eval` before/after (or "not run: infra unavailable" + exact commands); `/v1/ask` p95 < 3 s when measured | ⚠ not run, in the allowed form | The ticket and DoD §4.3 accept "not run: <reason>". The PR body says "Not run: no Docker, corpus or model in the agent sandbox. Commands: `make infra-up && make eval`, run on main and on this branch." QA couldn't run it either. **No eval or latency number exists.** p95 has not been measured, so it is neither broken nor verified. See finding 3. |
| AC7: Technical PRD §7.1 diagram via a `docs/` PR in arxivlens-agents | n/a for this PR, pending pm-lead | By the ticket's wording this is a pm-lead docs PR. The diagram steps are in the ticket Notes. pm-lead raises it at final review. It doesn't count against the developer. |

## Design binding conditions
| # | Condition | Result | Evidence |
|---|---|---|---|
| 1 | SQL literal identical in `search.go`, `$1..$5`, pool as `$5`, no extra `LIMIT 50` / `WHERE ce.model = $2` | ✅ | Same 34 lines and same sha256 on main and HEAD, empty diff. Counts main/head: `LIMIT 50` 2/2, `WHERE ce.model = $2` 1/1, `LIMIT $5` 1/1. The SQL is in no other file ([03](evidence/03-design-conditions.png)) |
| 2 | EVAL-1 parity test run against the branch | ✅ | 1 passed; the negative control fails ([04](evidence/04-c2-parity-test.png)) |
| 3 | No OTel import | ✅ | 0 `otel` references. Only `errors`, `log`, `math`, `sort` added. `go.mod`/`go.sum` unchanged ([03](evidence/03-design-conditions.png)) |
| 4 | Trace-ID helpers unexported; `RerankPool` the only new exported name | ✅ | [03](evidence/03-design-conditions.png) |
| 5 | `trace_id=<32 hex>` plus a separate `trace_id_source`; log only reason, pool and score count | ✅ | The log format is fixed and `reason` is a fixed set of strings. `err.Error()` appears only in a comment. The leak test and mutant M10 back this up ([03](evidence/03-design-conditions.png), [07](evidence/07-ac3-fallback-log.png)) |
| 6 | Error messages unchanged; `NewSearchEngine` signature unchanged | ✅ | [03](evidence/03-design-conditions.png) |
| 7 | `RerankPool = 20` | ✅ | No p95 data, so no reason to change it |
| 8 | NaN fallback; no `limit` cap | ✅ | NaN case tested; no cap added |

Scope: two backend-owned files, 391 changed lines. No `rag.go`, schema, event, API-shape or CI change. No ticket, review or doc files leaked into the PR ([02](evidence/02-scope-ownership.png)).

## PRD fit
This delivers ADR-0010 option 1. The cross-encoder now decides the order users get from `/v1/search?rerank=true` and `/v1/ask`, so it can promote a passage from RRF rank 6–20. That serves QA-1/QA-2's "evidence first". Rerank failures still fall back to RRF order quietly, as before, but now write a log line with the trace ID, which meets the ADR's "no silent failure". `rag.go`'s 0.45/0.70 filters are untouched and still run after the sort. The open question is latency (finding 3).

## Findings
No blocking findings.
1. [test][nit] The `rerank canceled` fallback reason (`errors.Is(err, context.Canceled)`) has no test case. Add a `context.Canceled` case to `TestHybridSearchRerankFallback`.
2. [code][nit] `/v1/ask` fallback logs carry a *generated* trace ID (`trace_id_source=generated`) until AI-4 calls `withTraceID` in `rag.go`. The design accepted this. ADR-0010's "log it with the trace ID" is only fully met for `/v1/ask` once AI-4 lands.
3. [spec] AC6 uses the allowed "not run" form. But the change roughly quadruples cross-encoder pairs per `/v1/ask` (5 → 20), and ADR-0010 makes a pool of 20 depend on p95 < 3 s. That hasn't been measured, and `make test-full` / M3 haven't run against this branch (blocked by OPS-H1). pm-lead should decide whether to merge before measuring. If yes, make the p95 and before/after `make eval` run an explicit follow-up.
4. [spec] Keep the merge order EVAL-1 → RET-1. Re-run evidence 04 if EVAL-1's `test_rrf_pool_sql_mirrors_search_go` changes before EVAL-1 merges (checked at d83a4c0).
5. [test][nit] `fetchCandidates` (embed → SQL → scan) has no unit test because it needs Postgres. That it is unchanged rests on the SQL and error-message diffs in evidence 03. M3 should cover it once infra is available.

## Missing tests
- The `context.Canceled` fallback reason.
- `±Inf` rerank scores: they are accepted today and sort first or last, but no test pins that.
- An end-to-end check of the new ordering through `/v1/ask` (needs infra; AC6/M3).

## Hand-off
**PASS → pm-lead final review.** pm-lead: decide finding 3 (measure latency and eval before or after merge), raise the AC7 docs PR, and keep the merge order EVAL-1 → RET-1.

## PM decision (round 1)

**Verdict: APPROVE**: pm-lead, 2026-11-03. Reviewed head `831905e911ac04884ed2b301da500874a3fc5820` (PR #9). Inputs I checked myself: the ticket, ADR-0010 (Accepted), the approved design and its 8 conditions, Product PRD QA-1/QA-2, Technical PRD §7.1, the full `search.go` diff and the `search_test.go` AC1–AC3 tests, `rag.go` on the branch, and the CI check runs (re-queried: all 4 `completed/success` on `831905e`). I opened all 26 evidence files (13 `.png` + 13 `.txt`).

### Product fit
ADR-0010 option 1 is delivered as written. `/v1/ask` (`rag.go:66`, `HybridSearch(..., maxCitations, true)`) and `/v1/search?rerank=true` now return the cross-encoder's order over a 20-candidate pool. A passage at RRF rank 6–20 can now reach a user's citations, which is the point of QA-2 ("cross-encoder reranking of top candidates") for the Product PRD §7 evidence-first principle. On fallback, `RerankScore` stays 0, so `rag.go`'s filters (`> 0 && < 0.45`; appendix/table `< 0.70`) behave exactly as on `main` today. That's not a new regression. Rerank failures now leave a trace-ID log line instead of failing silently, and the log never carries query or passage text (the leak check is in the test, and mutant M10 is caught). The API shape is unchanged. The only API change is the ordering ADR-0010 approved. QA-1/QA-2 stay ✅ in the Product PRD; no status-column change is needed.

### Scope
Two backend-owned files, 391 changed lines (under 400), ownership CI green. Nothing is missing that the ticket intended (AC6 and AC7 are handled below). Nothing extra: no `rag.go`, schema, event, API-shape, `go.mod` or CI change. The fixed reason class in the log (never `err.Error()`) is a justified tightening of design condition 5, not scope creep. The app README makes no claim about result ordering, so nothing there is stale. Its "Known limitations" line ("top reranked chunks") becomes accurate with this PR.

### Per AC
| AC | PM view |
|---|---|
| AC1 | Met. I read the test: `rrf_rank_8_has_top_score` expects `[8 1 2 3 4]`, plus reversed and sorted cases. Mutants M3/M4/M5/M7 are caught, and CI `ok internal/query` on go1.25. |
| AC2 | Met. The `[fetch n, calls, passages, len]` table covers limit 5/20/50/0, a short pool and an empty pool. `max(RerankPool, limit)` is in code. |
| AC3 | Met. Error, timeout, both mismatch directions and NaN all give RRF top 5, `err == nil`, `RerankScore == 0`, and a log line with `trace_id=<32hex> `, `trace_id_source=ctx`, the reason and `pool=20`, with no leak. The `context.Canceled` reason is untested (QA nit 1), which is non-blocking because it shares the same fallback branch. `/v1/ask` logs a *generated* ID until AI-4 (nit 2, accepted at design time). |
| AC4 | Met. The interleaved tied pairs give `[2 5 3 7 1 4]`, and the unstable-sort mutant M1 is caught, so the test really pins stability. |
| AC5 | Met. JSON bytes are equal, fetch n == limit, 0 calls, and fetch errors pass through. Below the seam: the SQL sha256 is identical, the error strings are identical, and the signatures are unchanged (evidence 03). |
| AC6 | Met in the allowed "not run: infra unavailable + exact commands" form (ticket wording, DoD §4.3). The measurement becomes an explicit follow-up: see decision on finding 3. |
| AC7 | pm-lead's item, not the developer's. Done as a docs PR in arxivlens-agents (see below). It merges after PR #9. |

### Per evidence file
| File | Proves | Accepted? |
|---|---|---|
| 00-ci-checks | 4/4 check runs `success`, `head_sha` = `831905e` | yes |
| 01-ci-go-job-log | go1.25.0 in CI; `make lint-go` (vet), `go test ./...` → `ok arxivlens/internal/query`; `make build-go` | yes. This is the authoritative run of the real module. |
| 02-scope-ownership | 2 files, 391 lines, `Ownership OK for role=backend` | yes |
| 03-design-conditions | C1 (SQL sha256 identical; `LIMIT 50` 2/2, `WHERE ce.model = $2` 1/1), C3 (no otel, go.mod untouched), C4 (only `RerankPool` exported; the rest are lowercase or `Test*`), C5 (log format; `err.Error()` only in a comment), C6 (error strings and signatures identical) | yes. The C4 heading says "exported" but lists every new identifier. Reading the names, only `RerankPool` is exported, as QA states. |
| 04-c2-parity-test | EVAL-1 @ d83a4c0 parity test: `1 passed` on PR `search.go`; the negative control fails as designed | yes. Exit code 1 comes from the intended control. |
| 05-ac1-order-by-score | AC1 subtests pass; sha256 shows the harness used the PR's files verbatim | yes, backed by the CI run in 01 |
| 06-ac2-pool-one-call | AC2 6 subtests pass | yes |
| 07-ac3-fallback-log | AC3 5 subtests + `TestTraceIDFrom` 3 subtests pass | yes. The red highlighting is the renderer colouring the word "error", not a failure. |
| 08-ac4-ties-rrf-order | AC4 2 subtests pass | yes |
| 09-ac5-no-rerank-unchanged | AC5 3 subtests + fetch-error passthrough + seam wiring pass | yes (red lines are again renderer highlighting of "Error") |
| 10-mutation-testing | 17/17 QA mutants caught, each mapped to the AC test that kills it | yes. This is the strongest evidence that the tests have teeth. |
| 11-test-map-and-full-run | Test-to-AC map; full package run in the harness `ok` | yes. 22.6% coverage is for the whole `query` package (server/rag untested before this PR); the changed logic is covered by the mutants. |
| 12-local-gofmt-toolchain | gofmt clean; why the real module can't build locally (go1.24.7, no toolchain download) | yes. It explains the harness, and CI covers the gap. |

### Decision on QA finding 3: merge before measuring p95 and eval? **Yes, merge without the measurement**, with an explicit follow-up.
Reasons:
1. ADR-0010 itself sets the order: implement pool 20, keep the latency budget, and "if reranking 20 passages breaks it, reduce the pool and record the number". The pool constant is one line and is pinned by EVAL-1's parity guard (AI-4 asserts `RerankPool == RRF_POOL_SIZE`), so a later reduction is cheap and visible.
2. The gated retrieval metric doesn't depend on this PR. EVAL-1's gated mode already computes pool → `/internal/rerank` → stable sort → top 5 in the eval itself (ADR-0010: "until RET-1 merges, the gate measures the *target* behaviour"). After RET-1, production matches the gate. Only the end-to-end answer/refusal eval and `/v1/ask` latency can move.
3. No agent can produce the number: there's no Docker, corpus or HF model in the sandboxes, and `make test-full`/M3 is blocked on OPS-H1. Holding a P0 correctness fix for an environment we don't have would block indefinitely.
4. Mahesh can still measure before merging if he wants. The PR's reviewer-focus section gives the exact commands.

**Follow-up recorded** as a new AC on an existing task, not a new task: `agents/tasks/EVAL-2.md` **AC10** (ai-engineer). The first `make eval` run on a stack with EVAL-1 and RET-1 merged records `/v1/ask` p50/p95 (gated `< 3 s` by EVAL-1's `ask_p95`), `/v1/search?rerank=true` p95, and the answer-eval numbers against the pre-RET-1 `evals/BASELINE.md`. If either latency budget is breached, the PR stops and reports to pm-lead. Pool changes go through ADR-0010 (design condition 7), never by editing the constant alone. A one-line pointer was also added to OPS-H1 Notes: its AC4 full-stack run should include `make eval` once EVAL-1 and RET-1 are on `main`.

### Decision on QA finding 4: merge order EVAL-1 (#2) → RET-1 (#9). **Kept.**
- PR #2 is ready-to-merge (PM APPROVE r3), and PR #9 depends on it only for evidence and the parity guard, not for compilation. Merging #9 first wouldn't break `main`, but it would leave the parity guard un-run in CI against the new `search.go`, and the RET-1 caveat in EVAL-1's docs would be stale for a while.
- After #2 merges: re-run CI on #9 (or update the branch from `main`) so `test_rrf_pool_sql_mirrors_search_go` runs in CI against this `search.go`. If #2's parity test changes before it merges (it's at d83a4c0 now), QA re-runs evidence 04.
- This is in the PR description's merge-order note.

### Non-blocking nits (no new task; fold into the next `search.go` change by backend-engineer)
1. Add a `context.Canceled` case to `TestHybridSearchRerankFallback` (QA finding 1).
2. Pin the `±Inf` score behaviour in a test (QA missing tests).
3. `fetchCandidates` has no unit test because it needs Postgres. M3 covers it once OPS-H1 lands (QA finding 5).

### Docs
- AC7: the Technical PRD §7.1 sequence diagram is updated in a `docs/RET-1-sequence` PR in arxivlens-agents. It merges after ArxivLens PR #9.
- After #9 merges (pm-lead, rules PR): drop the AGENTS.md §6 gotcha "does not yet sort by rerank score (ADR-0010, RET-1)". The pending Product PRD §8 "RET-1 caveat" (board note) is then no longer needed.

### Raise
PR #9: description rewritten with the Evidence section, marked ready for review, label `ready-to-merge`. Jira KAN-24 → Ready to merge (orchestrator).
