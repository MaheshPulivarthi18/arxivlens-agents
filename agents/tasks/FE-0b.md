# FE-0b: Remaining ui primitives: tooltip, popover, collapsible, scroll-area, separator, sonner Toaster

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P1 (unblocks FE-3 `tooltip`, FE-4 `popover` + `collapsible`) |
| **PRD ref** | Product PRD UI-1, UI-2; §7 principles 1 "Evidence first" and 3 "One click to the source" (via FE-3/FE-4) |
| **Depends on** | FE-0's design approved (2026-11-19, `docs/design/FE-0.md` §6 is this ticket's API) **and FE-0 #69 merged** (pm-lead, QA r1 F1, option a). Correction: `origin/main`'s `tailwind.config.js` does **not** map `popover`, so `bg-popover`/`text-popover-foreground` generate no CSS until #69 adds the `popover` colour entry. The other token names (`border-border`, `ring-ring`, `bg-accent`) are mapped |
| **Jira** | new story under epic KAN-5 "Research UI & citations" (`labels = "task-FE-0b"`) |
| **Design required** | no: covered by `docs/design/FE-0.md` §6 (approved). Any deviation from that table is written in this ticket's Notes before code |
| **Status** | Ready to merge (PR #70 raised; QA PASS r3, PM APPROVE) |

## Goal
Ship the six remaining shadcn-style Radix/sonner wrappers that the FE-0 design specifies, so FE-3 (status-chip tooltips) and FE-4
(`[n]` popovers, collapsible passages) can build on shared, token-styled, accessible primitives. This was split out of FE-0 to keep each PR under 400 lines.

## Scope
- Files expected to change (ArxivLens `frontend/`, **new files only**):
  - `src/components/ui/tooltip.jsx`: `TooltipProvider`, `Tooltip`, `TooltipTrigger`, `TooltipContent`
  - `src/components/ui/popover.jsx`: `Popover`, `PopoverTrigger`, `PopoverAnchor`, `PopoverContent`
  - `src/components/ui/collapsible.jsx`: `Collapsible`, `CollapsibleTrigger`, `CollapsibleContent`
  - `src/components/ui/scroll-area.jsx`: `ScrollArea`, `ScrollBar`
  - `src/components/ui/separator.jsx`: `Separator`
  - `src/components/ui/sonner.jsx`: `Toaster` (sonner CSS variables mapped to tokens; not mounted)
  - Classes, defaults and behaviour exactly as in the `docs/design/FE-0.md` §6 table (portal, `sideOffset=4`, `z-50`, `font-sans`
    on floating content, the FV ring on focusable parts, no motion classes).
- Out of scope:
  - Any existing file: `Navbar.jsx` (FE-0's file; its divider stays a `div`), the other `ui/*.jsx`, `index.css`, `tailwind.config.js`, `main.jsx`, `App.jsx`.
  - Mounting `<Toaster/>` or retiring `Toast.jsx` (token-migration follow-up). Using the primitives in any feature component (FE-3/FE-4/FE-2).
  - `package.json`, `package-lock.json`, `vite.config.js`, vitest config and tests (no dependency change: every package is already in the lockfile).

## Acceptance criteria
- [ ] AC1 — `npm run lint` and `npm run build` pass in CI on the draft PR (lint: no new warnings versus `origin/main`).
- [ ] AC2 — **Primitives:** each of the six files imports its package (`@radix-ui/react-tooltip`, `-popover`, `-collapsible`,
  `-scroll-area`, `-separator`, `sonner`), has exactly the exports listed in Scope, uses `React.forwardRef` + `displayName` for every
  element that renders DOM and is styled, merges classes with `cn()`, uses token colours only (`grep -E '(slate|emerald|teal|zinc|gray|amber|clinical)-'`
  finds nothing), has no `animate-`/`fade-`/`zoom-` classes, and gives focusable styled parts (ScrollArea viewport) the FV ring.
  Floating content (`TooltipContent`, `PopoverContent`) renders in a Portal with `font-sans`.
- [ ] AC3 — **Theme-following toasts:** `sonner.jsx` sets `--normal-bg`, `--normal-text`, `--normal-border` and `--border-radius` from
  `hsl(var(--popover))`, `hsl(var(--popover-foreground))`, `hsl(var(--border))` and `var(--radius)`, with no `theme` prop.
- [ ] AC4 — **Only components exported:** every file satisfies `react/only-export-components` (lint clean). `Tooltip` wraps Root in its
  own Provider (`delayDuration=300`).
- [ ] AC5 — **Scope guard:** `git diff origin/main --name-only` lists exactly the six new files (plus this repo's notes). No existing file
  changes. Diff < 400 lines (expected ~170).
- [ ] AC6 — **Smoke render (if `node_modules` is available to QA):** a scratch page (uncommitted) renders an open Tooltip, Popover,
  Collapsible (open and closed), ScrollArea with overflow, Separator and a `toast()` in light and dark (`.dark` on `<html>`). Screenshots
  are the evidence. Otherwise QA states "not run: <reason>", and AC2's static review plus the CI build stand in.
- [ ] Docs: none (no user-visible behaviour change; README untouched).

## Verification
```bash
# CI (source of truth): frontend job on the draft PR
cd frontend && npm ci && npm run lint && npm run build

# Static checks (sandbox)
git diff origin/main --name-only -- frontend/            # exactly the six ui/*.jsx files
git diff origin/main --shortstat
grep -nE "from \"(@radix-ui/react-(tooltip|popover|collapsible|scroll-area|separator)|sonner)\"" src/components/ui/{tooltip,popover,collapsible,scroll-area,separator,sonner}.jsx
grep -nE '(slate|emerald|teal|zinc|gray|amber|clinical)-|animate-|fade-in|zoom-' src/components/ui/{tooltip,popover,collapsible,scroll-area,separator,sonner}.jsx ; test $? -eq 1
grep -nE '^export ' src/components/ui/{tooltip,popover,collapsible,scroll-area,separator,sonner}.jsx
```

## Notes
- 2026-11-19 (pm-lead): split out of FE-0 at the design review (design Q5: ~570 lines in one PR is over the 400-line target). It is new files
  only, so it can run alongside FE-0 and FE-1 file-wise. The limit is frontend WIP (max 2 active PRs: FE-1 #68 + FE-0), so start it when one of
  those leaves active (Ready to merge counts as free). FE-3 depends on this (tooltip), and so does FE-4 (popover, collapsible). FE-2 doesn't.
- 2026-11-19 (pm-lead, from FE-0 QA nit 2, PR #69): FE-0's `Navbar.jsx` defines a local `focusRing` class string, and `ThemeToggle.jsx:55`
  re-declares part of it. If a primitive here (tooltip/popover trigger) needs a focus ring, don't add a third copy: reuse the Button
  base `focus-visible:ring-*` classes, or propose one shared constant (e.g. in `src/lib/utils.js`) in a follow-up. FE-0b may not edit
  `Navbar.jsx` or `ThemeToggle.jsx` (FE-0's files), so moving those two to a shared constant goes with the token-migration follow-up.
- 2026-11-19 (pm-lead): FE-0 #69 is now Ready to merge, so it no longer counts against frontend WIP. FE-1 #68 is also Ready to merge, so
  FE-0b can start next cycle (new files only, no overlap with #69).
- 2026-11-19 (frontend-engineer, build): draft PR [#70](https://github.com/MaheshPulivarthi18/ArxivLens/pull/70), branch `agent/frontend/FE-0b`,
  head `705b707063e8249b3f57e1c80b6bb2a2c60caee8`. Diff: 6 new files, 159 insertions (tooltip 37, popover 28, collapsible 10, scroll-area 38,
  separator 22, sonner 24). No existing file or dependency changed. `ownership-check.sh`: `Ownership OK for role=frontend (159 changed lines)`.
  No deviation from design §6. Two choices the design leaves open: `TooltipProvider` defaults `delayDuration=300` (same as `Tooltip`), and `Toaster` is
  forwardRef + `cn("toaster", className)`, with caller `style` spread after the token variables. Triggers are unstyled (no third `focusRing` copy).
  - AC1: CI on the head is all green (Frontend job 135909339973, `pull_request`). oxlint printed `Found 0 warnings and 0 errors.` on 26 files (main: 0),
    `vite build` printed `✓ built in 743ms`. Caveat: nothing imports the new files yet, so the build doesn't bundle them. Lint and the JSX parse cover them, and the build doesn't.
  - AC2/AC3/AC4: the static greps are clean (6 package imports; the colour/motion grep exits 1; only PascalCase exports per the TS AST; forwardRef + displayName
    on TooltipContent, PopoverContent, ScrollArea, ScrollBar, Separator and Toaster). All six files parse (TypeScript `transpileModule`, JSX).
  - AC5: met (see diff above). AC6: not run by the developer (no `node_modules`, npm registry unreachable). Left to QA.
- 2026-11-19 (frontend-engineer, Rework r1, QA round 1 FAIL): head `25ee64022edd7616113c5527e02c24ef86ffaf0e` (commit "FE-0b: inset scroll-area focus ring; tooltip provider note (QA r1)"), 2 files, +3/-2.
  - [x] F2 (blocking): `scroll-area.jsx` viewport ring is now inset: `focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-ring` (dropped `ring-offset-2` and `ring-offset-background`).
    **Deviation from design §6** (justified): §6's outset FV ring (offset 2) is fully clipped by the Root's `overflow-hidden`, so it fails WCAG 2.4.7. The inset ring
    uses the same `--ring` token, which both themes define, so it stays visible in light and dark.
  - [x] N1 (nit): `tooltip.jsx` comment says the innermost Provider wins, so a top-level `TooltipProvider` does not change these tooltips' delay.
  - CI on `25ee640`: all 5 checks green; Frontend job 135919189463: `Found 0 warnings and 0 errors.` (26 files), `✓ built in 530ms`.
  - [x] F1: not FE-0b's file. Fixed in FE-0 #69's `tailwind.config.js`; "Depends on" now says FE-0b needs #69 merged, and its wrong claim about main is corrected.
- 2026-11-20 (frontend-engineer, Rework r2, QA round 2 FAIL): merged `origin/main` (`3835dee`, FE-0 #69 + FE-1 #68) into the branch (merge commit `feece23`, no conflicts, no rebase),
  then fix commit; head `d10dc7f6d8a567330826b89b14118e23bcc2da1c`. Only `sonner.jsx` changed (+10/-1). Diff vs main: 6 new files, 169 insertions; `ownership-check.sh`: `Ownership OK for role=frontend (169 changed lines)`.
  - [x] F3 (blocking): `sonner.jsx` now passes `toastOptions.classNames.description = cn("!text-muted-foreground", <caller's description class>)`, spreading any caller
    `toastOptions` and `toastOptions.classNames` first, so the `{...props}` spread can't drop it (`toastOptions` is destructured out of props). Class checked against
    `frontend/tailwind.config.js` (Tailwind 4.3.3 `compile()` + `@config`, typography plugin stubbed; CI uses 3.4.19): `.\!text-muted-foreground { color: hsl(var(--muted-foreground)) !important; }`.
    **Deviation from design §6** (justified): §6 says toasts follow the theme through the four CSS variables alone, with no `theme` prop. That's incomplete: sonner hard-codes
    `[data-description] { color: #3f3f3f }` and only overrides it under `[data-sonner-theme='dark']`, which never applies without a `theme` prop, so the description was 1.56:1
    on the dark background. The token class keeps "no `theme` prop" and follows `.dark` like the rest (QA's r2 fix control: 6.73:1 light, 6.68:1 dark). The `!` is needed against sonner's (0,3,0) selector.
  - [x] N2 (nit): PR body refreshed from `agents/templates/pr.md` (169 lines, inset ring and F3 deviations, merge with main); grepped for other task IDs (only FE-0/FE-1 as context).
  - [ ] N3 (nit, for FE-4): not in scope. Radix ScrollArea viewport has no `tabindex`; FE-4 passes `tabIndex={0}` + `aria-label` on plain-text passage lists.
  - [ ] Missing render tests: not in scope (tests are out of this ticket's scope); left to pm-lead as a follow-up or FE-3/FE-4.
  - CI on `d10dc7f`: Frontend job 136203251672 checked out `Merge d10dc7f… into 3835dee…`; `Found 0 warnings and 0 errors.` (34 files), `Test Files 3 passed (3)`, `✓ 1923 modules transformed`, `✓ built in 997ms`.
  - Not run locally: `npm ci`/lint/test/build (npm registry unreachable from the sandbox, `npm ci` hangs). Rendering the toast was not done by me; QA r3 re-runs the r2 harness.
- 2026-11-20 (pm-lead, final review): **APPROVE** at `d10dc7f` (QA PASS r3, `agents/reviews/FE-0b/report.md`). PR #70 raised (ready for review). The two §6 deviations
  (inset viewport ring, toast description class) are accepted as justified. Open items are tracked like this:
  - [x] N4 (design §6 out of date): amendment note added under the §6 table in `docs/design/FE-0.md`.
  - [x] Missing render tests: follow-up **[FE-0d](FE-0d.md)** (P2, frontend, after #70 merges).
  - [x] N3 (`tabIndex={0}` + `aria-label` on plain-text ScrollAreas) and the `!` needed for a caller's toast description colour: added to FE-4's Notes (and the §6 amendment).
  - [x] N1 (an app-level `TooltipProvider` can't configure `Tooltip`): added to FE-3's Notes.
