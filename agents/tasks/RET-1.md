# RET-1: `/v1/ask` and `/v1/search` rerank a candidate pool and return results sorted by rerank score

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (retrieval quality users actually get; the eval gate assumes it) |
| **PRD ref** | QA-1, QA-2 (Product PRD §6.2); Technical PRD §7.1; ADR-0010 |
| **Depends on** | ADR-0010 (Accepted). Merge after EVAL-1 so before/after eval numbers exist. |
| **Jira** | find with JQL `labels = "task-RET-1"` |
| **Design required** | yes: ordering semantics of a public endpoint change |
| **Status** | Done (ArxivLens PR #9 merged as `bb9ee90`; Jira KAN-24 Done) |

## Goal
Today the cross-encoder scores are attached to the RRF top-K but never used for ordering, so reranking can't surface
a better passage. Make reranking actually decide the order users see, as ADR-0010 specifies.

## Scope
- `internal/query/search.go`: when `rerank=true`, query an RRF candidate pool of `RerankPool` (const, 20) or `limit`,
  whichever is larger; rerank the pool in one `EmbedClient.Rerank` call; stable-sort by `RerankScore` descending
  (ties keep RRF order); truncate to `limit`. On rerank error or score-count mismatch: keep RRF order, log with trace ID.
- Introduce a small interface for the rerank client (and the DB query, if needed) so the logic is unit-testable without infra.
- `internal/query/search_test.go`: table-driven tests.
- Out of scope: `rag.go` filter thresholds (ai-engineer), the eval scripts (EVAL-1), API response shape.

## Acceptance criteria
- [x] AC1: with `rerank=true`, results are ordered by rerank score descending; a passage at RRF rank 8 with the top rerank score is returned first (unit test).
- [x] AC2: the pool is `max(RerankPool, limit)` candidates and exactly one rerank call is made (unit test with a fake client counting calls and passages).
- [x] AC3: rerank failure or score-count mismatch → RRF order, top `limit`, no error to the caller, a log line with the trace ID (unit test).
- [x] AC4: ties keep RRF order (unit test).
- [x] AC5: `rerank=false` behaviour is byte-for-byte unchanged (unit test or golden).
- [x] AC6 (not run: infra unavailable; follow-up EVAL-2 AC10): `make eval` before/after numbers in the PR (or "not run: infra unavailable" plus the exact commands); `/v1/ask` p95 stays < 3 s when measured.
- [x] AC7 (pm-lead docs PR [arxivlens-agents#2](https://github.com/MaheshPulivarthi18/arxivlens-agents/pull/2), merge after #9): Technical PRD §7.1 sequence diagram updated via a `docs/` PR in arxivlens-agents (pm-lead can do it from your note).

## Verification
```bash
cd app && go vet ./... && test -z "$(gofmt -l .)" && go test -cover ./internal/query/...
make eval   # when infra is available
```

## Notes
- Created 2026-11-02 from Mahesh's decision (ADR-0010) on his PR #2 review, blocker 2.
- 2026-11-02 (pm-lead, EVAL-1 round-3 PM review; QA r3 finding 7): **how ADR-0010 is read.** The reranked, sorted, truncated list is what `search.go` returns. `rag.go`'s relevance filters (drop rerank < 0.45; appendix/table/supplementary < 0.70) stay in `rag.go` and apply **after** the sort. Do not move them into `search.go`. The EVAL-1 retrieval gate measures the ranking only (pool → rerank → sort → top 5), and the filters are covered end to end by the answer/refusal eval through `/v1/ask`. If you change the `search.go` SQL fragments, update `test_rrf_pool_sql_mirrors_search_go` in `app/tests/test_evals_data.py` via ai-engineer in the same cycle (or pair the PRs).
- 2026-11-02 (pm-lead, design gate): **design APPROVED** with 8 binding conditions, see `docs/design/RET-1.md` → PM decision. Key ones: SQL literal stays character-identical in `search.go` and no extra `LIMIT 50` / `WHERE ce.model = $2` text anywhere in that file (verified: one extra `LIMIT 50` comment fails `test_rrf_pool_sql_mirrors_search_go`); run that parity test from the EVAL-1 branch against this branch's `search.go` and paste the output (not on `main`, so CI won't); no OTel import; trace-ID helpers unexported; `trace_id_source` field instead of a suffixed ID; error messages unchanged. Follow-up AI-4 (ai-engineer, P2) wires `rag.go`'s trace ID into ctx and hardens the parity guard.
- 2026-11-02 (backend-engineer, build): code committed on `agent/backend/RET-1` (831905e, not pushed; orchestrator opens the draft PR). `search.go` +107/-13, new `search_test.go` 284 lines, 391 changed lines total, ownership check OK. The SQL literal is character-identical to `origin/main`, with `LIMIT 50` ×2 and `WHERE ce.model = $2` ×1. The EVAL-1 parity test (condition 2 command, EVAL-1 @ d83a4c0) passes: `1 passed`. Not verifiable in the sandbox: real `go vet`/`go test` (local Go is 1.24.7; Go 1.25 and golang.org/x/* modules can't be downloaded). The unit tests did pass on go1.24 against stubs of `db.DB`/`EmbedClient`, and 8 mutants were all caught; CI is the source of truth. One addition to the design: the fallback log writes a fixed reason class (`rerank error|rerank timeout|rerank canceled|score count mismatch|NaN score`) and never `err.Error()`, because `EmbedClient.Rerank` errors include the embedder's response body, which can echo the query or passages (condition 5). AC6 eval/p95 not run (no infra). AC7 for pm-lead: `PG-->>Q: top max(20, limit) by rrf_score`; `Q->>EA: rerank pool (one call)`; `Q: stable sort by rerank_score desc, truncate to limit; on failure keep RRF order + log trace_id`.
- 2026-11-03 (pm-lead, final review r1): **APPROVE** on `831905e` ([report](../reviews/RET-1/report.md) → PM decision (round 1)). Finding 3: merge without p95/eval measurement; the follow-up is **EVAL-2 AC10** (first `make eval` on a stack with EVAL-1 and RET-1 merged records `/v1/ask` and `/v1/search` p95 and answer eval vs baseline; a breach goes to an ADR-0010 pool decision). Finding 4: merge order PR #2 (EVAL-1) → PR #9; after #2 merges, re-run #9's CI so the parity guard runs against this `search.go`. Non-blocking nits for the next `search.go` change (backend-engineer): `context.Canceled` fallback case, a `±Inf` score test. AC7 is a docs PR in arxivlens-agents; merge it after #9. After #9 merges, pm-lead drops the AGENTS.md §6 "does not yet sort by rerank score" gotcha via a rules PR.
- 2026-11-03 (pm-lead): PR #9 merged by Mahesh (`bb9ee90`) → Done. AGENTS.md §6 gotcha and the Product PRD RET-1 caveat removed in docs PR (see PROGRESS). Open follow-ups: EVAL-2 AC10 (p95 + eval on a real stack), AI-4 (trace ID in `/v1/ask`, parity guard), backend nits (`context.Canceled`, `±Inf` score tests) for the next `search.go` change.
