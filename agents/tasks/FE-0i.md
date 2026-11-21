# FE-0i: `Badge` renders a `<span>`, so a badge inside a button or paragraph is valid HTML

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P3 (quality / a11y hygiene) |
| **PRD ref** | Product PRD §7 (readable, accessible UI); FE-3b QA r1 nit 1 (`agents/reviews/FE-3b/report.md`): FE-3b's status chip `<button>` wraps `Badge`, which renders a `<div>` (non-phrasing content in a button) |
| **Depends on** | FE-0b (#70, merged). No ADR. Does **not** wait on FE-3b (#104): no shared file, see Notes |
| **Jira** | KAN-111 |
| **Design required** | no: one element tag in a ui primitive plus a test; no contract or dependency change |
| **Status** | Done (PR #109 merged 2026-11-21 → `8337086`) |

## Goal
`Badge` is inline content (`inline-flex`) but renders a block element. Inside FE-3b's status-chip `<button>` that is invalid HTML (the
accessible name is fine, the markup is not). Render a `<span>` with the same classes and props so every caller stays the same visually and is valid.

## Scope
- Files expected to change: `frontend/src/components/ui/badge.jsx` (`<div>` → `<span>`, nothing else), new `frontend/src/components/ui/badge.test.jsx`.
- All `Badge` callers on `main` `11c4696` (none is edited): `SynthesisView.jsx:100`, `IngestModal.jsx:134`, `PapersLibrary.jsx:110,117`,
  `ReferencesStack.jsx:42,73,78` (on #104's head the chip is `ReferencesStack.jsx:86`, inside a `<button>`). No test on `main` or on #104 selects a badge by `div` tag (grepped 2026-11-21).
- Not in scope: `asChild` support, new variants, class changes, any caller file, `ReferencesStack.test.jsx` (#104 edits it). A chip-level
  "button contains no `div`" assert in `ReferencesStack.test.jsx` rides with the next PR that edits that file after #104 merges (FE-2/FE-4).
- Size: ~40 lines.

## Acceptance criteria
- [x] AC1 — `render(<Badge>x</Badge>)` gives a `SPAN` element holding `x` with the `badgeVariants` default classes (`inline-flex`, `rounded-full`, `bg-primary`).
- [x] AC2 — A caller `className` is merged with the defaults, a named variant gets its classes (e.g. `variant="supported"` → `bg-supported`,
  `text-supported-foreground`), and extra props are forwarded (`title`, `data-testid`).
- [x] AC3 — `render(<button><Badge>x</Badge></button>)`: `button.querySelector('div')` is `null`.
- [x] AC4 — Layout unchanged: the class string `badge.jsx` produces is byte-identical to `main` (diff shows only the tag). QA's browser harness
  (evidence file) shows the same computed `display` (`inline-flex`, or `flex` where a flex parent blockifies it; amended per QA r1 [spec] finding 2) and the same bounding-box width/height on `main` and on the branch for one badge from each
  calling component (SynthesisView, IngestModal result, PapersLibrary, ReferencesStack), both themes not required.
- [x] AC5 — **Mutation check:** the developer (if the sandbox can run Vitest) or QA's harness (evidence file) shows that reverting the tag to `div`
  makes the AC1 and AC3 tests fail, and that they pass with the change restored.
- [x] AC6 — `npm run lint` (0 warnings) and `npm test` pass in the CI Frontend job on the draft PR; the file count in its Vitest summary is one higher than `main`.
- [x] Docs: none (no user-visible change).

## Verification
```bash
# CI (source of truth): Frontend job on the draft PR
cd frontend && npm ci && npm run lint && npm test && npm run build

# Scope (sandbox)
git diff origin/main --name-only     # exactly ui/badge.jsx and ui/badge.test.jsx
git diff origin/main -- frontend/src/components/ui/badge.jsx   # only the two tag tokens change
```

## Notes
- 2026-11-21 07:00Z (pm-lead): specced from FE-3b QA r1 nit 1 (Backlog). The bug only bites inside a `<button>` (#104's chip) or `<p>`, but the
  fix lives in `ui/badge.jsx`, which #104 doesn't touch, so it can land in either order: with #104 merged first the chip becomes valid as soon as
  this merges. Independent of #105–#107 (no frontend files) and of FE-0g (`ui/primitives.test.jsx`, which doesn't import `Badge`).
- 2026-11-21 07:15Z (frontend-engineer): built on `agent/frontend/FE-0i` off `11c4696`, head `12484f8`. Diff vs main is exactly
  `ui/badge.jsx` (1 line: `<div` → `<span`, self-closing so only one tag token; class string untouched) and new `ui/badge.test.jsx`
  (3 tests: AC1 tag+default classes, AC2 className merge / `variant="supported"` / `title` + `data-testid`, AC3 no `div` inside a `<button>`).
  npm registry unreachable in the sandbox (`ENOTFOUND registry.npmjs.org`), so `npm ci`, lint, Vitest and build were **not run**.
  Logic check only (per area-notes, not a pass/fail): esbuild bundle of the real `badge.test.jsx` + `badge.jsx` with lockfile-version
  react/react-dom 19.2.8, cva 0.7.1, clsx 2.1.1, tailwind-merge 3.6.0 from `/opt/npm-tools`, small vitest/RTL/jest-dom shims, run in
  Chrome: old `<div>` → 0 passed / 3 failed (`expected DIV toBe SPAN`; AC3 found the `<div>`), `<span>` → 3 passed / 0 failed (AC5 mutation, sandbox half).
  Grep: no test on main selects a badge by `div` tag. Pending for QA/CI: AC4 browser bounding boxes, AC6 CI Frontend job (lint 0 warnings,
  Vitest file count +1 vs main).
- 2026-11-21 (pm-lead): final review **APPROVE** ([report](../reviews/FE-0i/report.md)), PR #109 raised (ready for review) → Ready to merge.
  No file overlap with #104. QA [spec] finding 2 fixed in AC4 above (computed display compared per badge, because flex parents blockify the badge).
  QA nit 1 (className precedence mutant M5) → follow-up [FE-0j](FE-0j.md), Backlog until #109 merges.
