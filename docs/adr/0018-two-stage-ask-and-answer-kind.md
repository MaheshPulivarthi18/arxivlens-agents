# ADR-0018: Record the `/v1/ask` contract changes made in ArxivLens #46 (two-stage answers, `answer_kind`, `insufficient_evidence`)

- **Status:** Proposed
- **Date:** 2026-11-17
- **Deciders:** Mahesh Pulivarthi (only the human owner sets Accepted/Rejected)
- **Blocks:** nothing is blocked. AI-8's design and FE-3/FE-4 build on the shape described here and need to know whether it is final.

## Context
The HTTP API is a shared contract (AGENTS.md §2): routes and fields change only through an Accepted ADR. Mahesh's own PRs
#44 (`6251d1a`) and #46 (`cc57474`), merged 2026-11-14/15 outside the agent workflow, changed `/v1/ask`. No ADR covers these changes:

| Change | Where | ADR coverage today |
|---|---|---|
| Request field `quick` (bool): skip the LLM and return the quoted answer | `internal/query/server.go`, `rag.go` `AskOptions` | none |
| Response field `answer_kind` (`quoted` \| `synthesized`, empty on refusals) | `rag.go` `AskResponse` | ADR-0014 accepted `answer_source` (`llm` \| `template`) for the same job; AI-8 hasn't built it yet |
| Response field `synthesis_available` (bool, omitted when false) | `rag.go` | none |
| `refusal_reason: insufficient_evidence` (the LLM says the passages don't answer), passages returned as evidence | `rag.go` | ADR-0003 lists two reasons; QA-8's spec mapped this case to the QA-5 refusal with `citations: []` |
| No verified LLM claim → fall back to the quoted answer, which is verified on its own terms (and refuses if nothing is supported) | `rag.go` `synthesize` | ADR-0003 says refuse. The fallback answer is still verified, so the ADR-0003 rule that unverified text is never shown holds |
| Citation support = verbatim quote match (score 1) or NLI P(entailment) ≥ 0.50 (`cross-encoder/nli-deberta-v3-small`), not BGE cosine ≥ 0.50 | `rag.go`, `services/embedder/verify.py` | ADR-0003/0014 say "cosine ≥ 0.50" or "the check". The threshold value is the same, but it means something different |
| `/v1/ask` p95 < 3 s applies to the first (quick) stage. The written answer is measured separately (qwen2.5:3b, M4: p50 1.8 s, p95 10.2 s) | #46 body, "Product decisions" 1 | Product PRD §8 has a single `/v1/ask` p95 row |

The README API table's `/v1/ask` row doesn't list `quick`, `answer_kind` or `synthesis_available` yet (AI-8 AC8 fixes the README).

## Options
1. **Accept the shape as implemented, and fold ADR-0014's `answer_source` into `answer_kind`** (recommended). AI-8 adds the rest of
   ADR-0014 (`claims[]`, `prompt_version`, citation `paper_version`/`page`/`quote`/`status`) on top and doesn't add `answer_source`.
   Pros: no duplicate field, and nothing breaks for the UI that already reads `answer_kind`. Cons: ADR-0014's written field name changes.
2. **Accept, and keep `answer_source` as well** (`llm` \| `template`, next to `answer_kind`). Pros: ADR-0014 stays literally true. Cons:
   two fields that say the same thing, and "template" no longer exists (the fallback is the quoted answer).
3. **Revert to the ADR-0003/QA-8 behaviour** (refuse when no LLM claim verifies; `insufficient_evidence` → QA-5 refusal). Cons: Mahesh's
   measured result (answerable questions refused 9% → 0%) would be lost. Not recommended.

## Recommendation (from pm-lead)
Option 1. Also, for Mahesh to confirm or change:
- Product PRD §8 gets two `/v1/ask` latency rows: the **quick (quoted) answer** p95 < 3 s, gated on the GPU profile as today, and the
  **written answer** p95 reported, not gated, until you set a target. `scripts/eval_gate.py` already measures the request
  without `quick`, which today is the quoted path because CI has no LLM. With an LLM configured, it would measure the written stage. The
  eval should request `quick: true` for the gated number. That's an ai-engineer follow-up after this is decided, because it changes
  what the gate measures.
- ADR-0003's reasons list adds `insufficient_evidence`, and its "refuse when nothing is supported" reads "…after the quoted fallback".
- `SupportThreshold = 0.50` now applies to NLI P(entailment) or an exact quote. ADR-0014 keeps `partially_supported`/`contradicted`
  reserved: the NLI model exists, but it hasn't been calibrated on the EVAL-7 human judgments, which is ADR-0014's condition.

## Decision
_(Filled by the human.)_

## Consequences
If accepted: pm-lead updates ADR-0003/0014 cross-references and Product PRD §8/QA-8 in a docs PR. AI-8 builds on Option 1 (no
`answer_source`). FE-3 adds copy for `insufficient_evidence`. A small ai follow-up makes the eval's gated p95 use `quick: true`.
If Option 2: AI-8 adds `answer_source` too. If Option 3: an ai task reverts the fallback, and FE-3/FE-4 are re-specced.
