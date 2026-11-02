# ADR-0010: `/v1/ask` reranks a candidate pool and orders by rerank score; the eval gates that ordering

- **Status:** Accepted (2026-11-02, Mahesh — decided in chat during the PR #2 review; recorded by the orchestrator)
- **Date:** 2026-11-02
- **Deciders:** Mahesh Pulivarthi
- **Blocks:** RET-1 (production change), EVAL-1 round 3 (gate mode)

## Context
Mahesh's review of PR #2 (blocker 2) asked that the gated "Hybrid RRF + Rerank" mode measure the production retrieval
path. After round 2 the eval calls the real cross-encoder (`/internal/rerank`), but QA round 2 found that production
doesn't use rerank for ordering: `/v1/ask` (`internal/query/rag.go`) asks `HybridSearch` for only `maxCitations` (5)
RRF hits, `search.go` attaches rerank scores **without sorting**, and `rag.go` uses the score only as a filter
(< 0.45 dropped; appendix/table < 0.70 dropped). So a cross-encoder that would surface a better passage at RRF rank 8
can never help users, and any rerank-based eval number is about a pipeline users don't get.

## Options
1. **Production reranks a pool and sorts** (chosen). `HybridSearch(rerank=true)` fetches an RRF candidate pool larger
   than the requested limit, reranks the pool with the cross-encoder, sorts by rerank score (ties keep RRF order), then
   truncates to the limit. `/v1/ask` keeps its relevance filters on the sorted top results. The eval gates exactly that.
2. Gate what `/v1/ask` does today (RRF top-5, rerank only as a filter). Honest, but it locks in the weaker behaviour.
3. Keep the endpoint fix only and track the mismatch. Leaves the gate measuring something users don't get.

## Decision
**Option 1.**
- Candidate pool: **20** RRF candidates (configurable constant; same 50-per-arm vector/BM25 limits and `ce.model`
  filter as today), reranked in one `/internal/rerank` call, sorted descending by rerank score, truncated to the
  requested limit. If the rerank call fails or returns the wrong number of scores, fall back to RRF order and log it
  with the trace ID (no silent failure in tests).
- `/v1/search` with `rerank=true` returns the same sorted order (API shape unchanged; ordering semantics change, which
  this ADR approves).
- Latency budget unchanged: `/v1/ask` p95 < 3 s, `/v1/search` p95 < 1.5 s. If reranking 20 passages breaks it, reduce
  the pool and record the number here.
- The eval's gated mode mirrors this exactly (same pool size, same SQL limits and model filter, same endpoint, same
  sort and tie rule). Until RET-1 merges, the gate measures the *target* behaviour and the PR must say so.

## Consequences
- RET-1 (backend-engineer, `internal/query/search.go`, design-required) implements the production change with unit
  tests; ai-engineer's `rag.go` needs no change beyond asking for the limit it wants.
- EVAL-1 round 3 aligns the eval pool/limits/filter with this ADR and adds a parity test.
- Answers may change for existing questions; re-run `make eval` and record before/after in RET-1's PR.
