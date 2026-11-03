# ADR-0011: What `/v1/ask` does when no rerank score is available

- **Status:** Proposed
- **Date:** 2026-11-03
- **Deciders:** Mahesh Pulivarthi (only the human owner sets Accepted/Rejected)
- **Blocks:** AI-5

## Context
Product PRD QA-5: "Refuse cleanly when no passage passes the relevance bar". Principle 2 (Product PRD §7): "A refusal
beats a confident hallucination." The relevance bar in `internal/query/rag.go` `filterRelevantHits` is the
cross-encoder rerank score (Technical PRD §7.2: drop < 0.45; drop appendix/supplementary/table < 0.70).

AI-1 (PR #10) pinned behaviour that QA flagged as a [spec] finding:
- The cutoff is `if h.RerankScore > 0 && h.RerankScore < 0.45 { drop }`. A hit with `RerankScore == 0`, meaning "no
  score", **passes** the relevance bar (an aux-section hit with 0 is still dropped by the 0.70 rule). Test:
  `TestFilterRelevantHits/zero_rerank_score_bypasses_relevance_cutoff`.
- ADR-0010 (Accepted) / RET-1: when the `/internal/rerank` call fails, returns the wrong count or a NaN, `HybridSearch`
  keeps RRF order, leaves **every** `RerankScore` at 0 and logs the trace ID. So during a reranker outage `/v1/ask`
  never refuses for relevance. It answers from the top-K RRF hits, and nobody checked whether they are relevant.
  Citation support checking (QA-4) still runs, but it checks sentence/chunk agreement, not question relevance.
- `EarlyRefusalThreshold = 0.015` ("Minimum RRF score required to attempt answer") is declared in `rag.go` but never
  used. For scale: RRF uses k = 60, so a hit ranked 1st in one arm only scores 1/61 ≈ 0.0164. As written, 0.015 lets
  through almost any hit in the top ~6 of either arm.
- Related: when the cross-encoder model isn't loaded, `services/embedder/api.py` `/internal/rerank` falls back to
  bi-encoder dot products. Those are on a different scale from the sigmoid cross-encoder scores the 0.45/0.70 cutoffs
  were tuned for, and they can be ≤ 0 (which also skips the cutoff).

The question is a trade-off between honesty (principle 2) and availability (the answer is still useful most of the
time), and some options change user-visible text or what a quality threshold means. So it needs your decision.

## Options
1. **Fail closed with a distinct message.** If no hit carries a rerank score (all `RerankScore == 0`, the ADR-0010
   fallback signature), `/v1/ask` returns a refusal-shaped response (same JSON: `answer`, empty non-nil
   `citations`, `trace_id`) with a different text, e.g. *"The relevance check is unavailable right now, so I can't
   answer reliably. Please try again shortly."*, and logs the trace ID. If only some hits have a score of 0, those hits
   are dropped (0 < 0.45). Delete `EarlyRefusalThreshold`.
   *Pros:* honest; matches principle 2; no response-shape change; tiny diff in `rag.go` only. *Cons:* `/v1/ask` is
   effectively down while the reranker is down (search still works); a new user-visible string.
2. **Fall back to an RRF bar.** If no rerank scores, keep hits with `RRFScore ≥ EarlyRefusalThreshold`, after first
   re-calibrating that value on the EVAL-1 refusal set (0.015 is too loose, see above). *Pros:* keeps answering during
   outages. *Cons:* RRF scores are rank-based, not relevance-based, so a refusal question with any lexical match
   still gets answered. It needs a calibration study and a new value in `evals/thresholds.json`-style governance (a
   quality-gate meaning change).
3. **Keep failing open, but say so.** Answer as today; log a warning; optionally prefix the answer with "Relevance
   not verified". Delete or document `EarlyRefusalThreshold`. *Pros:* maximum availability. *Cons:* goes against
   principle 2 and QA-5 at exactly the moment the system is degraded; the refusal-rate metric becomes
   outage-dependent.

Independent of the option: the bi-encoder fallback in `/internal/rerank` (last Context bullet) should either be
removed (fail the call, which triggers the ADR-0010 fallback) or flagged so `rag.go` doesn't apply cross-encoder
cutoffs to it. Recommended: remove it, so "no cross-encoder" always means "no rerank score".

## Recommendation (from pm-lead)
**Option 1**, plus removing the bi-encoder fallback in `/internal/rerank`. It is the only option consistent with
principle 2 and QA-5 without a new calibration effort. It keeps the HTTP shape. The outage it exposes is visible and
logged with a trace ID, not hidden. If outages turn out to be frequent, Option 2 can come later with eval data
behind its threshold.

## Decision
_(Filled by the human.)_

## Consequences
- AI-5 (ai-engineer, `rag.go` + `rag_test.go`, plus `services/embedder/api.py` if the fallback removal is accepted)
  implements the chosen option and flips `TestFilterRelevantHits/zero_rerank_score_bypasses_relevance_cutoff`.
- Product PRD QA-5 status: ◐ (fails open during reranker outages) until AI-5 merges. pm-lead will correct it in the next PRD docs PR.
- Option 1: the frontend shows the new text like any refusal (no change needed); README API table unchanged.
- Option 2: adds a threshold value that EVAL must gate; needs an EVAL task.
