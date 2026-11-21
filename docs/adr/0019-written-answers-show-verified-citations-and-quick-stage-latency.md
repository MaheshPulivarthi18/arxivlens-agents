# ADR-0019: Written answers show only verified citations; the 3 s `/v1/ask` latency gate times the quick stage

- **Status:** Accepted (Mahesh, 2026-11-22, in chat: "yes do both in one PR")
- **Date:** 2026-11-22
- **Deciders:** Mahesh Pulivarthi
- **Amends:** ADR-0003 (Option 1, "flag", for written answers only). **Puts into effect:** the latency row of ADR-0018.
- **Implemented in:** ArxivLens PR "ask: written answers show only verified citations; eval gates the quick stage"

## Context
A local `make eval` on the reference Mac (MPS, `qwen2.5:3b-instruct`, main `391eceb`) passes every retrieval and refusal
gate and fails two answer gates:

| Gate | Value | Target | Why |
|---|---|---|---|
| `supported_citation_rate` | 0.86 | ≥ 0.90 | 7 of 22 written answers keep a claim that has one verified citation and one that failed (NLI score 0.00–0.02). ADR-0003 Option 1 shows the failed one, flagged, so the reader sees a marker like "[2]" that does not back the sentence. |
| `ask_p95_ms` | 19.8 s | < 3 s | The eval times the written (LLM) answer. Since #46 the reader sees the quick, quoted answer first (about 1.2 s on MPS) and the written one replaces it later; ADR-0018 already says the 3 s target is for that first stage, but the eval never implemented it. |

A claim with **no** verified citation is already dropped (QA-8). The open case is a kept claim that also carries a failed
citation. The model attached it, the verifier rejected it, and showing it adds a marker that points at the wrong passage.

## Decision
1. **Written answers (`answer_kind: synthesized`) show only verified citations.** For each kept claim, a citation whose
   status is not `supported` is removed from the answer text's markers, from the claim's `markers` and from `citations`.
   A kept claim therefore always has status `supported`. The query service logs `synthesis hid unverified citations`
   with counts only. Quoted answers and refusals are unchanged: ADR-0003's flags and refusal evidence still apply, and
   FE-1's "unsupported citations stay visibly flagged" holds wherever unsupported citations are returned.
2. **The eval gates latency on the quick stage.** `ask_p95_ms` (gated `< 3000` on the GPU profile, PRD §9) times
   `POST /v1/ask {"quick": true}` for every answer- and refusal-set question; a failed quick call is an ask error. All
   quality metrics still come from the full answer. Its latency is reported as `ask_full_p50_ms` / `ask_full_p95_ms`,
   report-only (EVAL-6); promoting it to a gate needs another ADR.

## Options considered
- **Citations:** (a) keep flagging (ADR-0003 Option 1): honest, but the gate fails and the reader sees wrong markers;
  (b) **hide failed citations on kept claims** (chosen); (c) regenerate (ADR-0003 Option 3): doubles LLM latency on
  exactly the slow path; (d) drop the whole claim when any citation fails: loses correct, verified statements.
- **Latency:** (a) keep timing the written answer: it measures the 3B model on the user's laptop, not what the reader
  waits for; (b) **time the quick stage, report the written one** (chosen); (c) raise the target: hides regressions in
  the stage that is actually interactive.

## Consequences
- `supported_citation_rate` on written answers measures what the reader sees. It can only fall below 1.0 through quoted
  answers, which keep their flags.
- Markers in a written answer can skip numbers (e.g. "[1] … [3]"): markers are passage numbers, not a sequence.
- The eval makes one extra (quick) call per gated question, roughly +1.2 s each on MPS.
- A slow written answer no longer fails the gate. `ask_full_p95_ms` is printed on every run so it stays visible.
