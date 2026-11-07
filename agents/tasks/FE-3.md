# FE-3: Show refusals with their evidence, and stop labelling unchecked citations "Verified"

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (ADR-0003 consequence: unsupported citations must stay visibly flagged; Product PRD §7 principles 1–2) |
| **PRD ref** | Product PRD UI-1, QA-4, QA-5, §7; ADR-0003 (Accepted) |
| **Depends on** | **FE-1 merged** (Vitest harness). **AI-7 merged** (so QA can check the UI against the real `refusal_reason` JSON). |
| **Jira** | new story under epic KAN-5 "Research UI & citations" (`labels = "task-FE-3"`) |
| **Design required** | **yes** (short, `docs/design/FE-3.md`: states, copy and component changes; P0) |
| **Status** | Ready (Wave 2: starts when FE-1 and AI-7 are merged) |

## Goal
After AI-7, `/v1/ask` can return no answer plus evidence passages and a `refusal_reason`. The UI must show that as a
normal, honest state ("no answer, and here is what was found"), not as an error and not as a verified answer. It also
still shows trust labels that claim more than the system checked.

## Scope
- `frontend/src/components/SynthesisView.jsx`: when `refusal_reason` is present, show a refusal panel (`role="status"`,
  neutral styling, no error toast) with reason-specific copy. `all_citations_unsupported`: the draft answer couldn't be
  verified against the passages. `verification_unavailable`: citation checking is unavailable right now, try again shortly.
  Exact copy goes in the design for pm-lead. Hide "copy answer" for refusals. The early refusal (no `refusal_reason`,
  `citations: []`) keeps today's state.
- Remove the static "PostgreSQL pgvector Verified" label (`SynthesisView.jsx:105`). The Markdown export heading
  "References & Verified Citations" becomes "References", with each entry marked supported or unsupported.
- `frontend/src/components/ReferencesStack.jsx`: in refusal mode, the heading reads like "Retrieved passages (no answer was
  shown)" and each card shows its score without the word "Verified". In answer mode: supported → "Supported · x%",
  unsupported → "Unsupported · x%" (builds on FE-1 AC3 if that already fixed the badge).
- Vitest tests next to the components with fixture responses for: answer, early refusal, A-refusal, B-refusal.
- `App.jsx`: only if needed to pass `refusal_reason` through.
- Out of scope: claims and per-citation `status` (FE-4, ADR-0014), FE-2 export, any API change.

## Acceptance criteria
- [ ] AC1 — A-refusal fixture: refusal panel with A copy, evidence cards with scores, no "Verified" text anywhere in the rendered tree (test).
- [ ] AC2 — B-refusal fixture: B copy; nothing styled as an error (no toast); evidence cards shown (test).
- [ ] AC3 — Answer fixture with one supported and one unsupported citation: badges "Supported · …" and "Unsupported · …" (test).
- [ ] AC4 — Early refusal fixture renders as today (snapshot or explicit asserts).
- [ ] AC5 — "PostgreSQL pgvector Verified" is gone; the Markdown export has no "Verified" heading and marks unsupported entries (test on the export string).
- [ ] AC6 — Refusal panel has `role="status"` and is reachable by keyboard focus order (test).
- [ ] AC7 — `npm run lint`, `npm test`, `npm run build` pass in CI.

## Verification
```bash
cd frontend && npm ci && npm run lint && npm test && npm run build
```

## Notes
- 2026-11-07 (pm-lead): from the 2026-11-07 plan (Phase 1 item 8, refusal half). Sandbox: registry.npmjs.org doesn't resolve,
  so `npm ci` can't run locally. With FE-1's lockfile merged, no new dependency is needed here and CI verifies.
- Wave 2.
- 2026-11-07 (pm-lead, from the AI-7 review): in a refusal (`refusal_reason` set), each evidence citation's `score` is the **support** score of
  the best checked citation for that passage, and **0 when the passage was not cited or couldn't be checked**, not a retrieval score (AI-7, PR #21;
  Mahesh may change this, it's Decision 4 in #21). So don't render a refusal card's score as relevance, and don't show `0` as "0%": show
  "not checked" for 0 in refusal mode. Put the exact copy in the design.
