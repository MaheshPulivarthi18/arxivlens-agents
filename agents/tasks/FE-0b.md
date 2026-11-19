# FE-0b: Remaining ui primitives: tooltip, popover, collapsible, scroll-area, separator, sonner Toaster

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P1 (unblocks FE-3 `tooltip`, FE-4 `popover` + `collapsible`) |
| **PRD ref** | Product PRD UI-1, UI-2; §7 principles 1 "Evidence first" and 3 "One click to the source" (via FE-3/FE-4) |
| **Depends on** | FE-0's design approved (2026-11-19, `docs/design/FE-0.md` §6 is this ticket's API). No merge dependency: the files use existing shadcn token names (`bg-popover`, `border-border`, `ring-ring`, `bg-accent`), which `tailwind.config.js` already maps on `origin/main`. They pick up FE-0's new values when it merges |
| **Jira** | new story under epic KAN-5 "Research UI & citations" (`labels = "task-FE-0b"`) |
| **Design required** | no: covered by `docs/design/FE-0.md` §6 (approved). Any deviation from that table is written in this ticket's Notes before code |
| **Status** | Ready, but **waits for a frontend WIP slot** (FE-1 #68 + FE-0 = 2 active PRs). Shares no file with FE-0 or FE-1 (new files only) |

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
