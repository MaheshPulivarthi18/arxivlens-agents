# FE-3: Show refusals with their evidence, and stop labelling unchecked citations "Verified"

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (ADR-0003 consequence: unsupported citations must stay visibly flagged; Product PRD §7 principles 1–2) |
| **PRD ref** | Product PRD UI-1, QA-4, QA-5, §7; ADR-0003 (Accepted) |
| **Depends on** | **FE-1 merged** (Vitest harness) and **FE-0 merged** (theme tokens, fonts) and **FE-0b merged** (`ui/tooltip`; split from FE-0 2026-11-19). AI-7 merged (`8406b18`). #46 merged (`cc57474`: new props and `insufficient_evidence`) |
| **Jira** | new story under epic KAN-5 "Research UI & citations" (`labels = "task-FE-3"`) |
| **Design required** | **yes** (short, `docs/design/FE-3.md`: states, copy and component changes; P0) |
| **Status** | Closed — merged into B-UI (2026-11-28). Delivered by FE-3a (#86) and FE-3b (#104); design Q3/Q6 (show a full-stage `insufficient_evidence`?) moved to the decisions list |

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
- [ ] AC8 — **Flip the interim theme default** (from FE-0's design review, 2026-11-19): `DEFAULT_THEME` becomes `"system"` in both
  `src/lib/theme.js` and the `index.html` pre-paint script, once `SynthesisView`, `ReferencesStack` and App's refusal banner use tokens. Evidence:
  WCAG contrast ≥ 4.5:1 on the light theme for the answer prose, refusal text, passage text and `[n]` markers (no hard-coded `slate-`/`emerald-`/`amber-`
  text classes left in those three files), and the built CSS contains `.prose` (moved here from FE-0 AC3).

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
- 2026-11-17 (pm-lead, grooming, after Mahesh's #46): part of this ticket's problem is now handled and part isn't.
  **Done by #46:** `SynthesisView` gets `refusalReason` and shows the subtitle "No verified answer — the passages are shown as evidence".
  Quoted/written answers have their own subtitles. **Still open (checked at `40dec5a`):** "PostgreSQL pgvector Verified" (`SynthesisView.jsx:115`),
  the export heading "References & Verified Citations" (`:50`), and `{score}% Verified` on every citation (`ReferencesStack.jsx:72`).
  There is no reason-specific copy or `role="status"` panel, and nothing hides "copy" for refusals. Scope additions: copy for the third reason
  **`insufficient_evidence`** ("the passages found don't answer this question"), and the design must cover the two-stage states (quoted
  answer shown while `writing`, then swapped). A written answer that falls back to quotes stays quoted (`App.jsx:109-110`). Extend AC1/AC2
  with an `insufficient_evidence` fixture.
- 2026-11-19 (pm-lead, grooming): FE-1 is unblocked (#64/#67 merged the test deps) and now Ready. FE-3 also depends on **FE-0** (classic
  research theme). Use FE-0's tokens and fonts: answer prose in `font-serif`, the status badges styled with the `supported` / `unsupported` / `unchecked`
  tokens (add the badge variants here), and a `ui/tooltip` on each status chip explaining what it means (e.g. "Supported: the passage
  entails this sentence (score x%)"). The tooltip is extra help only: the chip text must carry the meaning without it (AC3 unchanged).
  Restyling `SynthesisView`/`ReferencesStack` to the tokens is in scope here. The design must not start before FE-0's design is approved.
- 2026-11-19 (pm-lead, from the FE-1 QA/PM review, PR #68): FE-1 adds `verification()` to `ReferencesStack.jsx`. Only `status: supported` (with
  `supported !== false`) renders "x% Verified". Otherwise the badge is an amber "Unsupported · x%" or "Unverified · x%". Citation cards are `role="article"`
  with an aria-label. Fixtures are in `src/test/fixtures.js`. Build AC3 on top of that: rename "Verified" to "Supported" there. Three additions from FE-1 QA:
  (a) **AC2 "no toast" must be an App-level test** (`App.jsx` with `fetch` mocked: a `refusal_reason` response shows no toast and keeps
  ReferencesStack visible). Toasts live in `App.jsx`, so a component test can't prove it. (b) Add test rows for `status: "supported"` + `supported: false`
  and for the reserved ADR-0014 statuses (`partially_supported`, `contradicted`): neither may read Supported/Verified. FE-1's tests leave both mutants alive.
  (c) QA re-confirmed the "PostgreSQL pgvector Verified" footer (`SynthesisView.jsx:115`) and the export heading (`:50`) are still on main (AC5).
- 2026-11-20 13:00Z (pm-lead, sync): FE-1 (#68 `2410d2e`) and FE-0 (#69 `54c4de8`) merged; FE-0b #70 is in QA r3. Picked for the design step only: the developer writes `docs/design/FE-3.md`, pm-lead reviews; no product code until #70 merges (its `ui/tooltip` API is FE-0 design §6). FE-0c's drift guard (AC1) will catch AC8 changing only one of the two default literals.
- 2026-11-20 (pm-lead, FE-0b final review): #70 is raised (Ready to merge). For the design: `Tooltip` wraps its Root in its own Provider (`delayDuration=300`),
  and the innermost Provider wins, so an app-level `<TooltipProvider>` does **not** change these tooltips' delay (FE-0b QA r1 N1; comment in `tooltip.jsx`).
  Don't add one expecting it to work. Tooltips stay supplementary: each chip keeps visible status text. Render tests for the primitives are FE-0d.
- 2026-11-20 (frontend-engineer): design written, `docs/design/FE-3.md` (Draft), awaiting pm-lead review. Proposes a split: FE-3a (labels + refusal state, ~470 lines, no `ui/tooltip`, so it can start before #70 merges) and FE-3b (tokens, tooltip, theme flip, ~140 lines, after #70 + FE-3a). 6 open questions in the design. No app code written.
- 2026-11-20 (pm-lead, design review): `docs/design/FE-3.md` **Approved with changes**; see its PM decision. Split into FE-3a (AC1–AC7 + hero sentence
  rewrite, starts now) and FE-3b (AC3 tooltip, AC8, after #70 + FE-3a + new FE-0e). Q1: hold the flip until FE-0e moves IngestModal/InfrastructureModal/
  PapersLibrary/Toast to tokens. Q2: hide Copy and Export on refusals. Q3/Q6: keep today's two-stage rule; whether a full-stage `insufficient_evidence` should be
  surfaced is **an open question for Mahesh** (ADR-0018 territory). Q5: copy approved. Change found in review: `HeroSearch.jsx:58` ("Every claim is mathematically
  verified…") is always rendered and would fail AC1's whole-tree assert; FE-3a replaces that sentence.
