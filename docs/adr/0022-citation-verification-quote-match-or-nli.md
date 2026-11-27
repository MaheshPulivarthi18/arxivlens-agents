# ADR-0022: Citations are verified by verbatim quote match or NLI entailment (replaces BGE cosine)

- **Status:** Accepted (Mahesh, implemented in ArxivLens #44 `6251d1a`, 2026-11-15; extended to LLM claims in #46 `cc57474`). Recorded by pm-lead 2026-11-28
- **Date:** 2026-11-28 (decision made 2026-11-15)
- **Deciders:** Mahesh Pulivarthi
- **Relates to:** ADR-0003 (unsupported-citation policy), ADR-0014 (citation `status`), ADR-0018 (lists this change among #44/#46's contract changes; that ADR is about the `/v1/ask` shape), Product PRD QA-4, Technical PRD §7.2

## Context
ADR-0003 and the first QA-4 build checked a citation by BGE cosine similarity between the sentence and the cited chunk,
with a 0.50 threshold. Cosine measures topical closeness, not whether the passage says what the sentence claims, so a
sentence on the right topic but with a wrong number or claim could still read as "supported". Mahesh replaced this
check in his own PR #44, outside the agent workflow, and nothing has recorded the decision since then.

## Decision (as implemented)
- A sentence or claim that is a **verbatim quote** of the cited chunk is supported with score 1. "Verbatim" here means a
  match after whitespace and inline-reference normalisation (`normQuote`) of at least 40 bytes.
- Every other (claim, passage) pair goes in one batch to the embedder's `POST /internal/verify`, which returns NLI
  P(entailment), taking the max over sentence windows. The model is `cross-encoder/nli-deberta-v3-small` (`ARXIVLENS_NLI_MODEL` overrides it).
  Supported = score ≥ `SupportThreshold = 0.50`, the same number as before, now with a different meaning.
- Fail closed: if the verifier is unavailable or errors, returns the wrong count, or returns a score outside [0, 1],
  the citation is `unverified` (ADR-0014), never `supported`.
- An LLM claim whose model-given `quote` is not in the cited chunk is `unsupported`.

## Options that were on the table
1. **BGE cosine ≥ 0.50** (the earlier behaviour): cheap, and it reuses the embedder. But it measures topic, not entailment.
2. **Quote match + small NLI cross-encoder** (chosen): checks that the passage actually says the claim, adds about one small model on the embedder, and runs on GPU and CPU.
3. **LLM judge**: the strongest check, but it costs money and time on every answer and doesn't work without an LLM.

## Consequences
- In a probe, NLI entailed 92% of verbatim sentences (README "Known limitations"), so some true paraphrases are dropped.
  That is an honest refusal or a dropped claim, never a false "supported".
- `SupportThreshold` 0.50 hasn't been calibrated on human judgments yet. The EVAL-7 review sheet is the way to do it,
  and a change needs a new ADR.
- ADR-0014's reserved statuses (`partially_supported`, `contradicted`) stay reserved until that calibration exists.
