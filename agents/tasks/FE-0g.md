# FE-0g: Kill the surviving primitive mutants M35–M39 (ScrollBar, Toaster position, Separator className, Tooltip delay)

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P3 (harness/quality) |
| **PRD ref** | Product PRD §7 (readable, accessible UI via FE-3/FE-4); FE-0d QA r1 "Missing tests" M35–M39 and nit 4 (`agents/reviews/FE-0d/report.md`, "Missing tests" and finding 4) |
| **Depends on** | FE-0d (#95, merged `ae8de39`). FE-1 (Vitest, merged). No ADR |
| **Jira** | KAN-110 |
| **Design required** | no: tests only, no component, contract or dependency change |
| **Status** | In Progress (built 2026-11-21, branch `agent/frontend/FE-0g` @ `b171ba0`; awaiting draft PR + CI + QA) |

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
- 2026-11-21 (frontend-engineer): built on `agent/frontend/FE-0g` @ `b171ba0`; diff is `primitives.test.jsx` only (+86/−1, the −1 is the
  `./scroll-area` import line gaining `ScrollBar`, plus a new `@radix-ui/react-scroll-area` import). 5 new tests: ScrollBar horizontal + default
  vertical (inside `ScrollAreaPrimitive.Root type="always"`, found by `data-testid`), Toaster `data-y-position`/`data-x-position` on the
  `<ol data-sonner-toaster>` (toast text `t-position`/`d-position`, used nowhere else), Separator `x-sep`, Tooltip default delay (fake timers +
  `userEvent.setup({ advanceTimers })`; ref null and no `role="tooltip"` at 250 ms, present at 350 ms; `vi.useRealTimers()` in that describe's `afterEach`).
  Read against sources at the lockfile versions (sonner v2.0.8 tag; radix-ui/primitives main): sonner 2.0.8 takes `data-y/x-position` from
  `position.split('-')` and renders the `<ol>` only once a toast exists; radix `type="always"` → `ScrollAreaScrollbarVisible` (no Presence);
  tooltip `isOpenDelayedRef` starts `true`, so the first hover waits `delayDuration`. Expected kills: m1 (`x-bar`), m2 (`h-2.5`/`flex-col`),
  m3 (`top`/`center`), m4 (`x-sep`), m5 (open at 250 ms), m6 (closed at 350 ms).
  **Not run locally:** npm registry is unresolvable here (`npm ci`: ENOTFOUND registry.npmjs.org; `--offline`: ENOTCACHED), so no Vitest, oxlint
  or mutation run in this sandbox. AC6 needs QA's harness (evidence file), and AC7 needs the CI Frontend job on the draft PR.
