# ADR-0012: Add a `/v1/search` p95 latency gate to `make eval`

- **Status:** Proposed
- **Date:** 2026-11-03
- **Deciders:** Mahesh Pulivarthi (only the human owner sets Accepted/Rejected)
- **Blocks:** EVAL-2

## Context
Product PRD §8 sets `/v1/search` p95 < 1.5 s, but nothing measures or gates it (Product PRD §8 row "Latency": "Not gated
yet — EVAL-2"). `evals/thresholds.json` gates `/v1/ask` p95 (`ask_p95_latency_ms_max: 3000`) unconditionally on any
machine. AGENTS.md §2 says gate definitions and `evals/thresholds.json` values change only through an Accepted ADR;
adding a gate key is such a change, so EVAL-2 can't add it on a PR comment alone.

Two facts make the choice non-obvious:
- The first full-stack `make eval` will run on GitHub's CPU-only runners (EVAL-3). `/v1/search` with `rerank: true`
  scores a 20-candidate pool with a cross-encoder (ADR-0010), which may be slower there than on the Proposed reference
  machine (Technical PRD §9 "Reference hardware", not yet approved). No `/v1/search` latency number exists yet.
- An unconditional gate that fails on CI hardware would make EVAL-3's workflow red for a hardware reason, not a regression.

## Options
1. **Gate now, unconditional** — add `search_p95_latency_ms_max: 1500`, `make eval` exits 1 above it on any machine
   (same as `ask_p95`). Pros: matches the PRD target and the existing `ask_p95` pattern. Cons: may turn EVAL-3's runs red
   on CPU runners before anyone has seen a number.
2. **Measure and report now, gate later** — EVAL-2 prints p50/p95 and records them (plus machine profile) in the results
   JSON, failed `/v1/search` calls fail the run, but no threshold key yet. After EVAL-3/EVAL-4 record the first numbers,
   a follow-up adds the key (option 1 or 3). Pros: no gate change without data. Cons: the PRD target stays unenforced a while longer.
3. **Profile-aware gate** — add the key but enforce it only when the machine profile matches the approved reference
   hardware (else report-only). Pros: precise. Cons: needs Technical PRD §9 reference hardware approved first, and the
   same rule should then apply to `ask_p95` too (a broader decision).

## Recommendation (from pm-lead)
Option 2. It delivers the measurement (the part users and PRD §8 actually need now) without changing a gate before any
number exists, and keeps EVAL-3's first runs about real regressions. Revisit with option 1 or 3 once EVAL-4 records the
first CI numbers and the reference-hardware question is decided.

## Decision
_(Filled by the human.)_

## Consequences
- Option 1 or 3: EVAL-2 proceeds as specced (AC2–AC5), with the key value fixed here.
- Option 2: pm-lead re-scopes EVAL-2 to report-only (no `thresholds.json` change) and specs the gate key as a later task after EVAL-4.
