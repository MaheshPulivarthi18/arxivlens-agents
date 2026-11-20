# FE-0f: Retarget the `ui/button` `clinical` variant to theme tokens (WCAG 1.4.3 on the main CTAs)

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P1 (WCAG 1.4.3 AA failure on the primary call-to-action buttons, in both themes; pre-existing) |
| **PRD ref** | UI-1 (hero search), UI-3 (ingest modal), UI-4 (infrastructure modal); FE-0 design §4 + §6 (`clinical` deprecated, callers move to tokens; Navbar "Index Paper" already `clinical` → `default`); FE-0e QA r1 finding 3 / r2 finding 2 (`agents/reviews/FE-0e/report.md`) |
| **Depends on** | FE-0 #69 merged (`54c4de8`, tokens). No open PR changes `frontend/src/components/ui/button.jsx` (#70 = six other `ui/` files, #86 = `ui/badge.jsx`; REST check 2026-11-21). Independent of FE-0e #87, FE-3a #86, FE-3b and FE-0d |
| **Jira** | KAN-97 (epic KAN-5 "Research UI & citations"; labels `task-FE-0f`, `agent-frontend`, `arxivlens`) |
| **Design required** | no: one variant string in an existing `ui/` file plus one new test file; no new component, contract or dependency |
| **Status** | Ready (specced 2026-11-20 UTC by pm-lead at the FE-0e final review) |

## Goal
`<Button variant="clinical">` draws white `text-sm`/`text-xs` text on an emerald-600 → teal-600 gradient: **3.77:1 / 3.74:1 in both themes**, below
the 4.5:1 AA minimum (FE-0e QA r1 evidence 06). It is the submit button of the hero search and the main action in the ingest and infrastructure
modals. Retarget the variant itself to FE-0's ink primary so all four call sites pass in light and dark without touching the callers.

## Scope
- Files: `frontend/src/components/ui/button.jsx` (the `clinical` entry of `buttonVariants` only); new `frontend/src/components/ui/button.test.jsx`.
- Target classes (guide): the `default` variant's colours, `bg-primary text-primary-foreground shadow-sm hover:bg-primary/90`, keeping `font-semibold`.
  `primary-foreground` on `primary` is 8.73:1 light / 8.11:1 dark (pm-lead, FE-0 appendix functions on `src/index.css` at `c37d27c`). Keep the
  variant name and the FE-0 "deprecated" comment, so callers can move to `variant="default"` later without a flag day.
- Call sites that change appearance (no code change there): `HeroSearch.jsx:75` (submit), `IngestModal.jsx:90` ("Index Paper") and `:159`
  ("Ask a question about this paper"), `InfrastructureModal.jsx:139` ("Replay DLQ").
- Out of scope: the callers (no prop or class change, so no overlap with FE-3b's `HeroSearch.jsx` swaps or FE-0e's files), `ui/badge.jsx`
  (its `clinical` variant is overridden at its only caller by FE-0e, and FE-3a owns `badge.jsx`), `tailwind.config.js`'s `clinical` colour, copy, layout.

## Acceptance criteria
- [ ] AC1 — The `clinical` variant contains no palette colour class and no `text-white`: a test in `ui/button.test.jsx` renders `<Button variant="clinical">`
  and asserts its `className` contains `bg-primary` and `text-primary-foreground` and matches none of `emerald`, `teal`, `from-`, `to-`, `text-white`.
- [ ] AC2 — QA evidence: contrast of the variant's text on its fill, idle and hover (`primary/90` composited over `background` and `card`, the surfaces the
  four callers sit on), light and dark, ≥ 4.5:1, computed from the PR's `src/index.css` with FE-0's appendix functions. Focus ring unchanged (base class).
- [ ] AC3 — No change outside the two files; existing tests pass unchanged.
- [ ] AC4 — CI `frontend` job green (`npm ci && npm run lint && npm test && npm run build`), lint warnings not above main.

## Verification
```bash
cd app/frontend && npm ci && npm run lint && npm test && npm run build
```
The npm registry is blocked in agent sandboxes: the evidence for AC1, AC3 and AC4 is the CI `Frontend (lint, test, build)` job log on the PR head
(`Tests N passed`, `✓ built in`, `Found 0 warnings`).

## Notes
- 2026-11-20 UTC (pm-lead): specced from FE-0e QA `[spec]` finding (r1 #3, r2 #2). Retargeting the variant (not the call sites) because FE-0e AC3 forbids
  prop changes in its files and FE-3b owns `HeroSearch.jsx`; the visual direction (ink primary instead of emerald gradients) is the one FE-0's approved
  design already applied to the Navbar's "Index Paper". Hint, not a requirement: if the test needs to read a source file, resolve it with
  `fileURLToPath(import.meta.url)` + `path`, never `new URL(\`…${x}\`, import.meta.url)` (Vite rewrites it under Vitest: FE-0c, FE-0e r1).
