# ADR-0016: At most two chunks per paper in the reranked top 5 (amends ADR-0010)

- **Status:** Accepted (2026-11-15, Mahesh: "yes go ahead" in chat to fixing multi-paper recall; the cap value of 2 was chosen by measurement, below; recorded by Claude)
- **Date:** 2026-11-15
- **Deciders:** Mahesh Pulivarthi
- **Amends:** ADR-0010 (ordering of the reranked list)

## Context
ADR-0010 orders `/v1/ask` and `/v1/search?rerank=true` by rerank score and keeps the top 5. The harder eval set
(ArxivLens PR #48: 78 cases in five query kinds) showed that the top 5 is often five chunks of a single paper. On
questions that two or three corpus papers answer ("multi" kind), the reranked Recall@5 was 0.64: a scholar asking a
survey-style question never saw the second relevant paper.

## Decision
After the ADR-0010 stable sort, the first `DiversityWindow = 5` results are picked greedily in rerank order with at
most `PaperCap = 2` chunks per paper (arXiv ID). Skipped chunks keep their order, fill any of the 5 slots the cap
leaves empty (so a pool with one or two papers still returns 5), and follow the window. Everything below the window
stays in rerank order. The RRF fallback (a rerank error) and the no-rerank path are unchanged. The eval mirrors the
rule (`scripts/evaluate_retrieval.py: diversify`), and tests pin it to `internal/query/search.go`.

## Measurements (78-case set, reference Mac on MPS, gated "Hybrid RRF + Rerank" mode)
| | Recall@5 | MRR | NDCG@5 | multi R@5 | own-words R@5 |
|---|---|---|---|---|---|
| ADR-0010 (no cap) | 0.951 | 0.959 | 0.938 | 0.64 | 0.83 |
| cap 1 (prototype) | 0.99 | 0.96 | — | 0.86 | 1.00 |
| **cap 2 (adopted)** | **0.985** | **0.964** | **0.961** | **0.86** | **1.00** |
| cap 3 (prototype) | 0.98 | 0.96 | — | 0.81 | 1.00 |

Cap 2 measures the same as cap 1 on the eval, and it still lets the dominant paper supply two passages to an answer,
which matters for `/v1/ask` context. `chunk_precision@5`, which is diagnostic and not gated, falls from 0.88 to 0.63
as expected.

## Considered and not adopted
**OR semantics for the keyword arm** (`to_tsquery('simple', replace(plainto_tsquery(...)::text, ' & ', ' | '))`,
instead of `websearch_to_tsquery`, which requires every term). It lifts BM25 on its own from 0.46 to 0.93 Recall@5, but
leaves the gated pipeline flat (0.96 / 0.96), lowers no-rerank hybrid MRR from 0.96 to 0.93, and lowers MRR on
abstract-style keyword queries from 1.00 to 0.96. Revisit once the eval has exact-term queries (acronyms, model and
dataset names), where the keyword arm should matter.

## Consequences
- `/v1/search?rerank=true` with `limit > 5` returns the same set of hits; only the first 5 positions are reordered.
- `/v1/ask` sees more distinct papers among its 5 candidates. The relevance cutoff (rerank ≥ 0.45) still removes off-topic ones.
- Two known limitations remain. On own-words queries the reranker's MRR is still 0.69, against 0.92 for dense alone:
  the right paper is now in the top 5 but not first. Diversity doesn't change which chunk ranks first.
