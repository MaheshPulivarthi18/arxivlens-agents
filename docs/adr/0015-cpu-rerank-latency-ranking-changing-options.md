# ADR-0015: Which ranking-changing options may be used to cut CPU cross-encoder rerank latency (Known failure F1)

- **Status:** Proposed
- **Date:** 2026-11-07
- **Deciders:** Mahesh Pulivarthi (only the human owner sets Accepted/Rejected)
- **Blocks:** AI-10 (and through it: removing the "Known failure F1" step from `stack.yml`)

## Context
`/v1/ask` and `/v1/search?rerank=true` score the ADR-0010 pool of 20 passages with `BAAI/bge-reranker-base`
(fp32, `max_length=512`) through the embedder's `/internal/rerank`. On GitHub's CPU runners this takes about 10 s per
query, so three M3 tests (`test_rag_ask_with_groundedness_support`, `test_rag_early_refusal_on_unrelated_query`,
`test_hybrid_search_with_rrf_and_rerank`) exceed M3's 10 s client read timeout. Mahesh accepted this on 2026-11-04 as a
known red ("Known failure F1", OPS-H1). Product PRD §8 asks for `/v1/ask` p95 < 3 s and `/v1/search` p95 < 1.5 s, and
`evals/thresholds.json` gates `ask_p95_latency_ms_max: 3000`. An LLM call (QA-8) will have to fit in the same budget.

AI-9 (ArxivLens PR #24) tried every **score-preserving** change: `torch.inference_mode()`, a CPU thread setting, sorting
pairs by length and scoring in batches of 8, and a start-up warm-up. QA round 1 (`agents/reviews/AI-9/report.md`) confirmed
the scores don't change (real-model max diff 5.36e-07), but F1 still fails exactly as before. AI-9's ticket says that
outcome escalates to this ADR.

### Measured numbers (all on GitHub `ubuntu-latest`, 4 vCPU AMD EPYC, 15 GiB, PyTorch CPU)
| What | Source | Number |
|---|---|---|
| F1 before AI-9 | `stack.yml` run [42344527109](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42344527109) | 3/3 tests `ReadTimeout` at 10 s ("3 failed in 30.55s") |
| F1 with AI-9 | `stack.yml` run [42362802353](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42362802353) | 3/3 tests `ReadTimeout` at 10 s ("3 failed in 30.59s") |
| `/v1/ask` p95, full eval before AI-9 | Eval run 42344527129 (EVAL-3, `main` `71cb609`) | 12.8 s (attempt 2: 14.9 s); rerank about 10–12 s per query |
| Rerank split with AI-9, 20 **synthetic** pairs, 2 torch threads | CI Python job (AI-9 parity test) | tokenize 5.4–6.0 ms; forward 4,621–4,890 ms; padded tokens 5,328–5,488 (single batch would be 10,240) |
| Rerank split with AI-9 on the **fixture** pool, in the stack | *pending*: needs OPS-H10 (stack.yml keeps the embedder log on green runs) and then AI-9's AC1 | to be added here by pm-lead |

Two conclusions from these numbers (QA's arithmetic, labelled as an estimate):
- Almost all the time is in the model forward pass. Tokenisation (≈ 6 ms) and padding aren't worth optimising further.
- Fixture chunks are about 512 tokens each, so 20 pairs come to about 10k tokens with almost no padding to remove. That
  projects to roughly 9 s of forward time per query on this runner. Getting `/v1/ask` under 3 s needs about a **3× cut**
  in rerank time, and that is only plausible if something about *what* is scored changes.

**Not in scope of this ADR, and not proposed:** raising M3's 10 s client timeout, changing `ask_p95_latency_ms_max` or any
other threshold, or treating CPU runners as "informational only". (That last point is the separate, still-Proposed
reference-hardware rule in Technical PRD §9. It wouldn't fix F1 anyway, because M3's timeout applies on every machine.)

## Options
Speed-ups marked *est.* come from published CPU benchmarks for BERT-base-size models. None has been measured here yet.

1. **Status quo (fp32, `max_length=512`, pool 20).** Keep F1 as a known red and rely on faster hardware.
   Pros: rankings don't change, no work. Cons: `/v1/ask` misses its target on any CPU machine, M3 stays red in CI, and
   QA-8's LLM call has no latency headroom left.
2. **Dynamic int8 quantisation of the reranker's Linear layers** (`torch.ao.quantization.quantize_dynamic`, built into
   torch, no new dependency). Same model, pool and `max_length`; the whole passage is still read.
   Pros: smallest change to *what* is ranked; *est.* 1.5–2.5× on x86. Cons: scores drift (more than 1e-4), so a few
   rankings may flip; the speed-up depends on the CPU's int8 support, and on its own may fall short of 3×.
3. **Lower `max_length` (512 → 384 or 256).** Pros: cost grows with tokens, so 256 roughly halves forward time or better
   (*est.*); trivial to configure. Cons: the reranker no longer sees each chunk's tail (at 256, about half of a 512-token
   chunk), which can hurt relevance on long chunks. Same model.
4. **Smaller pool (amend Accepted ADR-0010: 20 → 10).** Pros: about 2× fewer pairs, predictable. Cons: reopens an
   Accepted decision. Rerank can then only promote from RRF's top 10, and the eval's ADR-0010 parity guard (EVAL-5)
   changes with it.
5. **A smaller reranker model** (e.g. a 6-layer MiniLM cross-encoder, about 22M parameters against about 278M).
   Pros: largest speed-up (*est.* 5–10×). Cons: a different model with a different quality profile, plus a new licence
   check, a new cache key and new eval baselines. Highest quality risk.
6. **A score-preserving runtime (ONNX Runtime fp32 export of the same model).** Pros: could keep scores within 1e-4, so
   it wouldn't need this ADR on ranking grounds. Cons: a new runtime dependency and an export step (backend-owned
   `requirements*.txt` and Dockerfile); the speed-up (*est.* 1.2–2×) is unlikely to reach 3× alone.

## Recommendation (from pm-lead)
Accept options **2 and 3 as configurable, measured candidates**, under a fixed adoption rule. Don't accept 4 or 5 for now.
Concretely: AI-10 adds `RERANK_QUANTIZE` (`none` | `int8`) and `RERANK_MAX_LENGTH` (default 512) to the embedder, with
defaults **unchanged**. It measures, on the seeded `evals/` corpus and the same commit: fp32-512 (baseline), int8-512,
fp32-384, int8-384 and int8-256. For each it records rerank p50/max, `/v1/ask` p95, the F1 result, Recall@5, MRR and NDCG@5,
and the top-5 overlap with the baseline. *Proposed adoption rule (Mahesh sets the tolerance):* the new default is the first
config in that order that (a) makes the three F1 tests pass on `stack.yml` and (b) keeps every `evals/thresholds.json` gate
passing, with Recall@5, MRR and NDCG@5 each within **0.01 absolute** of the fp32-512 run. If no config qualifies, the
default stays fp32-512, and pm-lead brings the numbers back to Mahesh with options 4/5. This order tries the change to
*what* is ranked that is smallest and easiest to undo first, and the gates can't move. Option 6 goes to the Backlog as a
possible extra, since it needs a dependency decision and can't close a 3× gap by itself.

## Decision
_(Filled by the human.)_ Chosen option(s), the adoption order and the quality tolerance (pm-lead proposes 0.01 absolute
on Recall@5 / MRR / NDCG@5 against the fp32-512 baseline, with every existing gate still passing).

## Consequences
- If accepted: AI-10 becomes Ready (design-required) once AI-9 (#24) merges, because it edits the same `services/embedder/api.py`.
  After AI-10 merges with F1 passing, backend drops the "Known failure F1" step and `F1_TESTS` from `stack.yml`.
- `/v1/ask` p95 < 3 s is still not guaranteed by F1 passing (that only proves < 10 s). The `ask_p95` gate keeps measuring it,
  unchanged.
- Rankings may change slightly. `evals/BASELINE.md` (EVAL-4) records the before/after numbers, so the change is visible.
- If rejected: F1 stays a known red, and QA-8's LLM synthesis has to fit inside whatever is left of the budget.
