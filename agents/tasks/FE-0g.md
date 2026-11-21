# FE-0g: Kill the surviving primitive mutants M35–M39 (ScrollBar, Toaster position, Separator className, Tooltip delay)

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P3 (harness/quality) |
| **PRD ref** | Product PRD §7 (readable, accessible UI via FE-3/FE-4); FE-0d QA r1 "Missing tests" M35–M39 and nit 4 (`agents/reviews/FE-0d/report.md`, "Missing tests" and finding 4) |
| **Depends on** | FE-0d (#95, merged `ae8de39`). FE-1 (Vitest, merged). No ADR |
| **Jira** | KAN-110 |
| **Design required** | no: tests only, no component, contract or dependency change |
| **Status** | Ready (picked 2026-11-21 07:00Z) |

## Goal
FE-0d's render tests leave five mutants of the `ui/` primitives alive (QA evidence `agents/reviews/FE-0d/evidence/06-mutants-all.png`).
Pin those behaviours so an edit to `scroll-area.jsx`, `sonner.jsx`, `separator.jsx` or `tooltip.jsx` can't silently change them.

## Scope
- Files expected to change: `frontend/src/components/ui/primitives.test.jsx` only (add tests/imports; keep the existing ones as they are).
- Not in scope: any `ui/*.jsx` source, `src/test/setup.js` (open PR #104 edits it; keep stubs in the test file as FE-0d does),
  `package.json`, the lockfile, `vite.config.js`, `ui/badge.jsx` (FE-0i), `ui/button*` (FE-0f).
- Size: ~80–120 test lines.

## Acceptance criteria
- [ ] AC1 — **ScrollBar (M35, M36):** a `ScrollBar` rendered inside a scroll-area Root (import `ScrollBar` from `./scroll-area`; use the Root
  from `@radix-ui/react-scroll-area` or `ScrollArea` with `type="always"`, or `forceMount` on the scrollbar, whichever renders it in jsdom) with
  `orientation="horizontal"` and a caller `className="x-bar"` has `h-2.5`, `flex-col`, `border-t` and `x-bar` in its class list and **not** `w-2.5`
  or `border-l`. A default (vertical) `ScrollBar` has `h-full`, `w-2.5`, `border-l` and not `flex-col`.
- [ ] AC2 — **Toaster position (M37):** once a toast is shown, the `<ol data-sonner-toaster>` list has `data-y-position="bottom"` and
  `data-x-position="right"`. Note: sonner's own default is also `bottom-right`, so the mutant to kill is a *changed* value (see AC6), not a removed prop.
- [ ] AC3 — **Separator className (M38):** `<Separator className="x-sep" />` has `x-sep` alongside `shrink-0`, `bg-border`, `h-px`, `w-full`.
- [ ] AC4 — **Tooltip default delay (M39):** with no `delayDuration` prop, hovering the trigger does **not** show the content before 300 ms
  (e.g. still absent at 250 ms) and does show it after 300 ms. Use fake timers (`vi.useFakeTimers()` + `userEvent.setup({ advanceTimers: vi.advanceTimersByTime })`)
  or real timers with `waitFor`; restore real timers in the test's cleanup so the other tests are unaffected.
- [ ] AC5 — Any new toast test uses toast text no other test uses (FE-0d QA nit 4).
- [ ] AC6 — **Mutation check, one mutant per case.** The developer (if the sandbox can run Vitest) or QA's harness (evidence file) shows each of these
  makes at least one new test fail, and that all tests pass with the source restored: (m1) drop `className` from `ScrollBar`'s `cn(...)`;
  (m2) delete the `orientation === "horizontal" && ...` line; (m3) `position="top-center"` in `sonner.jsx`; (m4) drop `className` from
  `Separator`'s `cn(...)`; (m5) `Tooltip` default `delayDuration = 0`; (m6) `Tooltip` default `delayDuration = 700`. Mutants are local only, never committed.
- [ ] AC7 — `npm run lint` (0 warnings) and `npm test` pass in the CI Frontend job on the draft PR; the test count in its Vitest summary is higher than on `main` and the file count is unchanged.
- [ ] Docs: none.

## Verification
```bash
# CI (source of truth): Frontend job on the draft PR
cd frontend && npm ci && npm run lint && npm test && npm run build

# Scope (sandbox)
git diff origin/main --name-only     # exactly frontend/src/components/ui/primitives.test.jsx
git diff origin/main --shortstat
```

## Notes
- 2026-11-21 07:00Z (pm-lead): specced from the FE-0d QA r1 "Missing tests". Independent of open PRs: #104 (FE-3b) touches
  `setup.js`, `tokens.test.js`, `ReferencesStack*`, `App.jsx`, `SynthesisView.jsx`, `HeroSearch.jsx`, `theme.js`, `index.html`, `README.md`;
  #105–#107 touch no frontend file. FE-0i (same cycle) changes `ui/badge.jsx` + new `ui/badge.test.jsx`, which this file doesn't import.
- jsdom: Radix's scrollbar may not mount without overflow; `type="always"` or `forceMount` is the usual way. `ResizeObserver`/`DOMRect` stubs
  are already in this file's `beforeAll`.
