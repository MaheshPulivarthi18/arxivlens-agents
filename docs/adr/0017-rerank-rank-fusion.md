# ADR-0017: Order the reranked pool by fusing reranker and first-stage ranks (amends ADR-0010)

- **Status:** Accepted (2026-11-15, Mahesh: "fix own-words reranking" and "pick the best reranker option and implement it" in chat; the option and its constant were chosen by measurement, below; recorded by Claude)
- **Date:** 2026-11-15
- **Deciders:** Mahesh Pulivarthi
- **Amends:** ADR-0010 (the reranked list is no longer ordered by rerank score alone). ADR-0016's top-5 paper cap still applies after this ordering.

## Context
On the harder eval set (78 cases), the reranked MRR on questions phrased in the reader's own words was 0.69, while
dense retrieval alone scored 0.92. `bge-reranker-base` threw away correct first-stage evidence when a question shares
few terms with the passage:
- "how to find the closest vectors quickly in a very large collection": HNSW was RRF #1 but scored 0.12, below DPR
  and ColBERT chunks that mention fast vector search.
- "an agent that thinks out loud and then calls a search tool": ReAct fell to rerank #19 of 20, behind a travel-behaviour
  paper whose text says "agentic".

## Decision
Each candidate in the RRF pool (in RRF order) is keyed by
`1/(FusionK + rerank rank) + 1/(FusionK + RRF rank)`, with 1-based ranks and **`FusionK = 10`**. Rerank ranks come from a
stable sort by score; ties in either step keep RRF order. `RerankScore` stays the cross-encoder probability, so the
`/v1/ask` relevance cutoff (≥ 0.45) is unchanged. The same `bge-reranker-base` model is kept. The eval mirrors the rule
(`fuse_ranks`), and tests pin the constant and shared cases to `search.go`.

## Measurements
78-case set, reference Mac on MPS, gated mode with the ADR-0016 cap. All variants were scored on the same cached pools
with production's `score_pairs`; latency is one rerank of 20 passages.

| Option | Recall@5 | MRR | NDCG@5 | own-words MRR | body-detail MRR | Rerank time |
|---|---|---|---|---|---|---|
| base, rerank score only (ADR-0010) | 0.985 | 0.964 | 0.961 | 0.69 | **0.98** | 1.0 s |
| **base + fusion, k = 10 (adopted)** | **0.985** | **0.976** | **0.971** | **0.89** | 0.95 | **1.0 s** |
| base + fusion, k = 60, RRF weight 0.5 | 0.985 | 0.970 | 0.966 | 0.81 | 0.95 | 1.0 s |
| base + fusion, k = 60, RRF weight 1 | 0.972 | 0.970 | 0.963 | 0.89 | 0.93 | 1.0 s |
| bge-reranker-large | 0.985 | 0.968 | 0.964 | 0.69 | 0.97 | 5.5 s |
| bge-reranker-v2-m3 | 0.985 | 0.974 | 0.969 | 0.78 | 0.97 | 5.4 s |
| v2-m3 + fusion, k = 10 | 0.972 | 0.972 | 0.964 | 0.89 | 0.94 | 5.4 s |
| first stage only (no rerank) | 0.959 | 0.966 | 0.956 | 0.89 | 0.92 | — |

Fusion changes five cases: three improve (r033 ReAct 0.50 → 1.00, h026 HNSW 0.33 → 1.00, h027 LoRA 0.50 → 1.00) and two
drop one rank (h003 the Transformer's warmup 0.50 → 0.33, h022 RoFormer's decay 1.00 → 0.50).

## Why not a larger reranker
Both larger models are about 5× slower on the reference GPU, which breaks the `/v1/ask` p95 < 3 s target. Neither fixes
own-words on its own: large stays at 0.69, v2-m3 reaches 0.78. Fused with the first stage, they score no better than
base.

## Consequences
- A passage that only the reranker likes no longer jumps straight to #1 from deep in the pool. Body-detail MRR falls by
  0.03 (two cases, one rank each).
- The constant was picked from three settings on a 78-case set, which is a small sample. Revisit `FusionK` whenever the eval
  set grows. A fusion weight below 1 for RRF is the first knob to try if body-detail keeps losing.
- There is no latency cost: the fusion sorts 20 numbers in memory.
