# ADR-0003: What to do with unsupported citations

- **Status:** Proposed
- **Date:** 2026-11-01
- **Deciders:** Mahesh Pulivarthi
- **Blocks:** follow-up after QA-8 (not QA-8 itself)

## Context
Product PRD open question 2. Each sentence's citation is scored (cosine ≥ 0.50 → supported). With an LLM, some sentences
will be unsupported. Principle: "evidence first; say I don't know".

## Options
1. **Flag** (current) — show with an "unsupported" badge. Transparent; may look noisy.
2. **Hide** — drop unsupported sentences. Clean; can silently change meaning.
3. **Regenerate** — if > X% sentences unsupported, retry once with a stricter prompt; still flag what remains. Better answers; doubles latency/cost on bad cases.

## Recommendation (from pm-lead)
Option 1 now (already implemented, keeps trust visible), and decide on Option 3 after QA-8 eval data shows how often it happens.

## Decision
_(Human to fill)_

## Consequences
Frontend must keep unsupported citations visibly flagged (FE-1 tests it).

## Question for Mahesh: abstention policy (added by pm-lead 2026-11-03; still Proposed, not decided)
Raised by the external reviews of ArxivLens `bb9ee90`. The options above cover a **single** unsupported sentence. They
don't say what `/v1/ask` does when verification fails for the **whole answer**. Two cases:
- **A. All citations unsupported**: every sentence was checked and none reaches `SupportThreshold = 0.50`.
- **B. Verification unavailable**: the embedder call fails or cited chunks have no vectors. Since AI-2 (ArxivLens #11,
  `9c1229a`), these citations are unsupported with score 0 (fail closed), so an embedder outage looks like case A to the
  user, while the server logs one `citation support unverified` line.

**Today** (`internal/query/rag.go` at `9c1229a`, lines 95–115): the answer is always returned, with each citation flagged
`supported=false`. The only refusal is the early one, when no passage passes the relevance bar (QA-5). With the template
answer that's tolerable. With LLM synthesis (QA-8, ADR-0001/0002), case A is the hallucination case Product PRD §7
principle 2 ("say I don't know") is about.

| Option | What `/v1/ask` returns in case A / B | For | Against |
|---|---|---|---|
| **1. Refuse** | The refusal message (as in QA-5) plus the reason (`all_citations_unsupported` / `verification_unavailable`), no answer text | Strictest reading of §7.2; nothing unverified reaches the user | An embedder outage turns every answer into a refusal; the correct-refusal metric needs splitting so outages aren't counted as correct refusals |
| **2. Answer with a warning** | The answer plus a top-level `warning` field and UI banner ("none of these claims could be verified" / "verification unavailable") | Keeps the answer useful, honest about trust; matches §7.1 "evidence first" | Adds a response field (HTTP API contract: needs this ADR Accepted + README API table), FE work |
| **3. Answer (today)** | Answer with per-citation `supported=false` only | No change | Users may miss that *nothing* is supported; weakest under QA-8 |

Sub-questions: (i) Should A and B be treated the same? A plausible split is to refuse on A and warn on B. (ii) Should it
trigger on "all unsupported" or "supported share < X%"? The Product PRD §8 target is ≥ 90% supported overall. (iii) Does
the eval count case B as an error (like `ask_errors`) rather than a refusal?

**pm-lead recommendation (for discussion only):** Option 2 now. Option 1 for case A once QA-8 is on, if the QA-8 eval shows
LLM answers with zero supported citations. Keep B as a warning, never a silent pass, and count it as an error in the eval.
The decision affects QA-8 (prompt/fallback), FE-1/FE-2 (badge and banner) and EVAL-1's refusal metric. No task is
specced on it until you decide.
