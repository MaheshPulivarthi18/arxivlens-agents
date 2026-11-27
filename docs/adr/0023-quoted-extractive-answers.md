# ADR-0023: Without an LLM, answers quote the passages verbatim (replaces the fixed template)

- **Status:** Accepted (Mahesh, implemented in ArxivLens #44 `6251d1a`, 2026-11-15; kept as the quick stage and the LLM fallback in #46 `cc57474`). Recorded by pm-lead 2026-11-28
- **Date:** 2026-11-28 (decision made 2026-11-15)
- **Deciders:** Mahesh Pulivarthi
- **Relates to:** ADR-0001 (no provider configured → no LLM), ADR-0003, ADR-0018 (`answer_kind: quoted`), ADR-0019 (quick-stage latency gate), Product PRD QA-8, Technical PRD §7.2

## Context
Before #44, `/v1/ask` without an LLM returned a fixed template such as "... demonstrates relevant improvements [2]".
The template asserted things no passage said, and the LLM fallback ADR-0001 described was "the template answer".
Mahesh replaced it in #44. No ADR records that change.

## Decision (as implemented)
- The extractive answer quotes, for each of the top `maxAnswerHits = 3` relevant hits, the candidate sentence the cross-encoder
  scores most relevant to the question, followed by its `[n]`. Candidates are 40–400 bytes, ≥ 6 words, ≥ 60% letters,
  which filters out tables, equations and reference lists. If sentence scoring fails, the hit's first candidate is used.
- Each quoted sentence is verified like any claim (ADR-0022). Being verbatim, it normally passes by exact match. If no citation
  is supported, the ADR-0003 refusal applies.
- This is the answer when `LLM_MODEL` is unset, the first (`quick`) stage when it is set, and the fallback when the LLM
  fails or nothing it wrote verifies. `answer_kind = quoted` (ADR-0018).

## Options that were on the table
1. **Fixed template**: fast, but it states things no passage supports, which breaks Product PRD §7 principle 1.
2. **Verbatim quotes** (chosen): every sentence can be checked against its source and the answer is ready in about the time of a search. It is terse, not a synthesis.
3. **Always require an LLM**: better prose, but there would be no answer without a model and no fast first stage.

## Consequences
- Answers are always checkable, and the quick stage meets the 3 s p95 gate on the GPU profile (ADR-0019).
- CI, which has no LLM, measures this path only. Measuring the real-LLM path is EVAL-8 (ADR-0021).
