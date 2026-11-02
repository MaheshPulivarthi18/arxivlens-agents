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
