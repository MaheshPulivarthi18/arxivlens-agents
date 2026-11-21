# ADR-0020: The cross-encoder reranker runs in fp16 on MPS/CUDA

- **Status:** Accepted (Mahesh, 2026-11-22, in chat: "do fp16 reranker")
- **Date:** 2026-11-22
- **Deciders:** Mahesh Pulivarthi
- **Relates to:** ADR-0010 (rerank pool), ADR-0015 (rerank latency options; fp16 was not among them), ADR-0019 (quick-stage
  latency gate), PRD-Technical §9 (reference hardware: GPU)

## Context
With ADR-0019 the 3 s `/v1/ask` gate times the quick stage. On the reference Mac (M-series, 16 GB, MPS) that stage was
2.2 s median and 3.97 s at p95, nearly all of it `bge-reranker-base` scoring the 20-passage pool in fp32 (2.1 s; search
without rerank is 24 ms). Lowering precision can change scores, and the AI-9 rule is that a change that can move
the ranking needs an ADR.

## Decision
On `mps` and `cuda` the embedder loads the reranker with `.half()`. On `cpu` it stays fp32, because fp16 matmuls are
slower on CPU. `EMBEDDER_RERANK_FP16=0` (or `false`/`no`/`off`) forces fp32 anywhere. Logits are cast to fp32 before the
sigmoid, so `/internal/rerank` returns fp32 scores as before. `/healthz` reports `reranker_dtype`. `max_length` (512),
the pool (20) and the model are unchanged.

## Evidence (full `make eval`, reference Mac, LLM `qwen2.5:3b-instruct` on)

| | fp32 (main `c2b3bd6`) | fp16 |
|---|---|---|
| Recall@5 / MRR / NDCG@5 (Hybrid RRF + Rerank, 78 cases) | 0.9850 / 0.9765 / 0.9707 | 0.9850 / 0.9765 / 0.9707 |
| Supported citations, expected-paper hits, refusals | 1.00, 100%, 100% | 1.00, 100%, 100% |
| `/internal/rerank`, 20 passages, idle machine (median) | 2.1 s | 0.72 s |
| Quick `/v1/ask`, idle machine (median) | 2.2 s | 1.0 s |
| Gated `ask_p95_ms` (quick stage, in the eval run) | 3.97 s FAIL | 2.95 s PASS |
| Gate | FAIL | **PASS** |

In the eval, each quick call follows a written answer while Ollama still holds the GPU, so its p50 (2.0 s) is about
twice the idle median. The p95 margin is small (45 ms); `ask_full_p95_ms` (written answer) stays report-only at ~20 s.

## Consequences
- The gated quick stage passes on the reference hardware with little headroom. Further cuts (sharing hits between
  the two stages, ADR-0015 options) remain open and need their own decisions.
- CI (CPU) keeps fp32, so CI scores are unchanged. Rankings on GPU and CPU can differ in the last decimals; the
  eval showed no case where it changed the top 5.
