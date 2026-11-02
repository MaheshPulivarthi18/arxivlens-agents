# RET-1: `/v1/ask` and `/v1/search` rerank a candidate pool and return results sorted by rerank score

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (retrieval quality users actually get; the eval gate assumes it) |
| **PRD ref** | QA-1, QA-2 (Product PRD §6.2); Technical PRD §7.1; ADR-0010 |
| **Depends on** | ADR-0010 (Accepted). Merge after EVAL-1 so before/after eval numbers exist. |
| **Jira** | find with JQL `labels = "task-RET-1"` |
| **Design required** | yes: ordering semantics of a public endpoint change |
| **Status** | Ready (design first) |

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
- [ ] AC1: with `rerank=true`, results are ordered by rerank score descending; a passage at RRF rank 8 with the top rerank score is returned first (unit test).
- [ ] AC2: the pool is `max(RerankPool, limit)` candidates and exactly one rerank call is made (unit test with a fake client counting calls and passages).
- [ ] AC3: rerank failure or score-count mismatch → RRF order, top `limit`, no error to the caller, a log line with the trace ID (unit test).
- [ ] AC4: ties keep RRF order (unit test).
- [ ] AC5: `rerank=false` behaviour is byte-for-byte unchanged (unit test or golden).
- [ ] AC6: `make eval` before/after numbers in the PR (or "not run: infra unavailable" plus the exact commands); `/v1/ask` p95 stays < 3 s when measured.
- [ ] AC7: Technical PRD §7.1 sequence diagram updated via a `docs/` PR in arxivlens-agents (pm-lead can do it from your note).

## Verification
```bash
cd app && go vet ./... && test -z "$(gofmt -l .)" && go test -cover ./internal/query/...
make eval   # when infra is available
```

## Notes
- Created 2026-11-02 from Mahesh's decision (ADR-0010) on his PR #2 review, blocker 2.
