_Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/issues/comments/7059263782 (QA harness refused to write report.md), cycle 2026-11-21T07:00Z._

[qa-reviewer] QA round 1 for FE-0i (KAN-111): **PASS**

# QA report — FE-0i · PR #109 · round 1

**Verdict:** PASS
**Reviewed commit:** `12484f89053e01944f515c8cf31de078ad10f1ea` · **Date:** 2026-11-21
**Ticket:** `agents/tasks/FE-0i.md` · **PRD:** Product PRD §7 (readable, accessible UI); FE-3b QA r1 nit 1
**Evidence:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence

## Test results
| Check | Source | Result |
|---|---|---|
| Go / Python M0 / DB | CI jobs 136770333710 / 136770333597 / 136770333670 | pass (no change in these areas) |
| Frontend (lint, test, build) | CI job 136770333612 (`refs/pull/109/merge`, 12484f8 into current main 11c4696) | pass: `Found 0 warnings and 0 errors`, `✓ src/components/ui/badge.test.jsx (3 tests)`, `Test Files 12 passed (12)` / `Tests 143 passed (143)` vs main 11c4696's `11 (11)` / `140 (140)`, build ok ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/00-ci-checks.png?raw=true), `` [02](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/02-ac6-ci-frontend-head-vs-main.png?raw=true)) ``` |
| Agent ownership check | CI job 136770333436 | pass |
| Scope (ticket verification) | local, app checkout at 12484f8 | changes are `ui/badge.jsx` (1 line) and the new `ui/badge.test.jsx`, nothing else. Main's file with `<div `→`<span ` substituted is byte-identical to head ([01](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/01-scope-and-class-string.png?raw=true)) ```` |
| `npm ci` / lint / `npm test` | not run locally: npm registry unreachable | CI is the source of truth |
| AC5 mutation | local QA harness: the real `badge.test.jsx`, real react-dom 19.2.8, cva, clsx and tailwind-merge at the lockfile versions, Vitest/RTL/jest-dom **shims**, run in headless Chromium | control 3/3 (matches CI's 3 tests) → `div` mutant 0/3 → restored 3/3 ([03](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/03-ac5-mutation-run.png?raw=true)) ````` |
| AC4 layout | local: the real caller components from the main and head trees, the real `index.css` + `tailwind.config.js` via Tailwind 4 `@config`, headless Chromium, both themes | 14/14 badges identical, screenshots pixel-identical, the probe trips on a planted change ([04](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/04-ac4-layout-main-vs-head.png?raw=true), `````` ``````` [06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/06-ac4-probe-negative-control.png?raw=true)–[09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/09-ac4-screenshot-pixel-diff.png?raw=true)) ``````` |
| `make eval` | not run: no retrieval/answering change | — |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 SPAN + `inline-flex`/`rounded-full`/`bg-primary` | ✅ | `badge.test.jsx:9-14`, green in CI ([02](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/02-ac6-ci-frontend-head-vs-main.png?raw=true)). ```````` Fails on the `div` tag: `expected DIV toBe SPAN` ([03](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/03-ac5-mutation-run.png?raw=true)) ````````` |
| AC2 className merge, `supported` variant, `title` + `data-testid` | ✅ | `badge.test.jsx:16-28`, green in CI. Mutants M2 (drop className), M3 (ignore variant) and M4 (drop `{...props}`) are all killed ([03](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/03-ac5-mutation-run.png?raw=true)). `````````` Precedence gap: nit 1 |
| AC3 no `div` inside `<button>` | ✅ | `badge.test.jsx:30-38`, green in CI. Fails on the `div` tag: `expected DIV toBeNull` (03). Page level ([05](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/05-ac3-nesting-page-level.png?raw=true)): ``````````` #104's head d9b2386 with the old badge has 3 chip `BUTTON>DIV.badge`; with this PR's badge it has 0. Main's References `<h3>` count badge (`H3>DIV`) is fixed too. React's dev-mode `<p> cannot contain a nested <div>` errors go from 2 to 0 |
| AC4 class string identical; same display + bounding box per caller | ✅ (spec 2) | The diff is the tag token only (01). All 4 callers (SynthesisView, ReferencesStack, PapersLibrary, IngestModal result), plus #104's chip-in-button and 2 isolated badges, in light and dark: `RESULT: PASS (0 differing badges; w/h/x/y/display/class string compared per badge)` ([04](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/04-ac4-layout-main-vs-head.png?raw=true)). ```````````` Full-page screenshots are pixel-identical ([07 head](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/07-screenshot-callers-head-light.png?raw=true), ````````````` [08 main](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/08-screenshot-callers-main-light.png?raw=true), `````````````` [09](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/09-ac4-screenshot-pixel-diff.png?raw=true)). ``````````````` Negative control: a planted `px-2.5`→`px-3` gives `RESULT: FAIL (26 differing badges)` ([06](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/06-ac4-probe-negative-control.png?raw=true)) ```````````````` |
| AC5 `div` revert fails AC1 and AC3; restored passes | ✅ (QA harness, logic check) | 03: CONTROL 3/3 → `M0 main badge.jsx (div)` KILLED 0/3 → RESTORED 3/3. This is a shim harness, not real Vitest (registry blocked). The control's per-file count equals CI's. Harness sources: [10](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2eed9fce2bd585b5318ec0bc3d0c8c375132f2df/agents/reviews/FE-0i/evidence/10-qa-harness-sources.png?raw=true) ````````````````` |
| AC6 lint 0 warnings, tests green, file count main+1 | ✅ | 02: head `12 passed (12)` vs main `11 passed (11)`, `Found 0 warnings and 0 errors` |
| Docs: none | ✅ | no visible change (09) |

## PRD fit
This serves Product PRD §7 (accessible UI). Badges are now phrasing content inside #104's status-chip `<button>` and inside the existing References `<h3>`, which was also invalid on main. Nothing changes visually or in layout. Contracts, the API, the schema and eval gates are untouched.

## Findings
1. [nit] The tests don't pin className **precedence**. Mutant M5 `cn(className, badgeVariants({ variant }))` survives all 3 tests (03), and it changes real behaviour: ReferencesStack's count badge passes `px-2 py-0` to override the default `px-2.5 py-0.5`, and under M5 tailwind-merge keeps the default. Suggested assert: `className="px-2"` → `toHaveClass('px-2')` + `not.toHaveClass('px-2.5')`. Not blocking: AC2 as written is met.
2. [spec] AC4 expects computed `display: inline-flex`. A badge inside a flex container is blockified, so its computed value is `flex` on **both** main and head (11 of 14 badges, 04). Only the badges in `TD`/`DIV`/`P` parents compute to `inline-flex`. I judged AC4 as "computed display identical per badge on main and head", which holds.

QA-harness note, not a PR finding: my first layout run showed 4 IngestModal x/y DIFFs. That was jitter from the dialog's `duration-200` enter transition, so the fixed harness waits 1 s before measuring and the result is now stable across repeated runs (10).

## Missing tests
- A caller className overriding a conflicting default (nit 1).
- After #104 merges: a chip-level "no `div` in the status button" assert in `ReferencesStack.test.jsx`. The ticket assigns this to FE-2/FE-4.

## Not verifiable here
- A real-Vitest mutation run (npm registry blocked). AC5 rests on the shim harness plus CI's green run on the `span` side.
- lucide-react and the Radix dialog/tooltip are stubbed in the layout harness, the same way on both sides. Tailwind 4 `@config` stands in for Tailwind 3, and typography is dropped (no badge sits in `prose`). Absolute pixel values are approximate; the main-vs-head equality holds.
- Report file: my harness refused to write `agents/reviews/FE-0i/report.md`, so this comment is the report. The orchestrator saves it verbatim.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

# PM final review — FE-0i · PR #109 · head `12484f8`

**Verdict: APPROVE** (pm-lead, 2026-11-21)

- **PRD fit (Product PRD §7, accessible UI):** `Badge` is now phrasing content. QA's page-level check (05) shows 0 badge `<div>`s inside `button`/`p`/`h3` on head, compared with 3 chip `BUTTON>DIV` on #104's head with the old badge and the `H3>DIV` count badge already on main. React's dev-mode nesting errors drop from 2 to 0. Users see nothing different: 14 of 14 badges have identical geometry in both themes (04), the screenshots are pixel-identical (07/08/09), and the probe trips on a planted `px-3` (06).
- **Scope:** exactly `ui/badge.jsx` (1 line, tag token only, class string byte-identical, 01) and the new `ui/badge.test.jsx` (39 lines). No caller is edited and no `asChild` was added, as the ticket intended. **No file overlap with #104** (Ready to merge): #104 changes `README.md`, `index.html`, `App.jsx`, `HeroSearch.jsx`, `ReferencesStack.jsx` (+ test), `SynthesisView.jsx`, `lib/theme.js`, `test/setup.js` and `test/tokens.test.js`, none of them `ui/badge*`. The PRs merge in either order, and once both are in, #104's chip is valid HTML.
- **Evidence:** I opened all 19 evidence files (00–10, .png + .txt). Each AC is covered:
  - AC1–AC3 and AC6: green in CI job 136770333612 (`badge.test.jsx (3 tests)`, 12/12 files vs main's 11/11, lint 0 warnings).
  - AC5: shim harness, control 3/3 → div 0/3 → restored 3/3. It is not real Vitest, but CI's real run on the span side plus the matching per-file count are enough for a one-token change.
  - AC4: 04/06/09.
  - All 5 check runs on `12484f8` succeed (rechecked via the check-runs API).
  - No "⚠ unverified" remains on anything that matters.
- **Docs:** none needed (no visible change). There is no PRD status row to flip, because this is a hygiene item from the FE-3b review.
- **QA [spec] finding 2 (AC4 "computed `display: inline-flex`"):** accepted. A badge in a flex container is blockified to `flex` on both sides, so the right check is "computed display identical per badge", and QA applied it. I reworded AC4 in the ticket.
- **QA nit 1 (className precedence, mutant M5 survives):** this doesn't block the merge, because AC2 as written is met. It is a real behaviour pin, though: `ReferencesStack.jsx:42` overrides the default `px-2.5 py-0.5` with `px-2 py-0`, and under M5 tailwind-merge keeps the default. Follow-up **[FE-0j](../../tasks/FE-0j.md)** (frontend, P3, test-only, `ui/badge.test.jsx`) is in Backlog until #109 merges, since it edits the same file.
- QA "Missing tests" item 2 (chip-level "no `div` in the status button" in `ReferencesStack.test.jsx`) stays with FE-2/FE-4, as the ticket says.

Raised: PR description rewritten with evidence, marked ready for review → Ready to merge.
