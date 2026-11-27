<!-- Provenance: saved verbatim by the orchestrator from ArxivLens PR #130 comment 7214590791 (https://github.com/MaheshPulivarthi18/ArxivLens/pull/130#issuecomment-7214590791); the QA harness could not write this file. -->

[qa-reviewer]

# QA report: FE-0k · PR #130 · round 1

**Verdict:** PASS
**Reviewed commit:** `3056e80e5996d1bef4de02357e67431cac9de4e4` (branch `agent/frontend/FE-0k`, base `origin/main` `53171d6`) · **Date:** 2026-11-27
**Ticket:** [`agents/tasks/FE-0k.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/FE-0k.md) · **PRD:** FE-0 design token rule, `docs/design/FE-0.md:105-108, 120-123, 210` (WCAG 1.4.11). Not design-required.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI | pass ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/00-ci-checks.png?raw=true)) `` |
| Python M0 unit tests | CI | pass ([00](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/00-ci-checks.png?raw=true)) ``` |
| DB (migrate twice, HNSW plan + recall) | CI | pass ([00](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/00-ci-checks.png?raw=true)) ```` |
| Frontend (lint, test, build) | CI job 140412970507 | pass: oxlint 0 warnings / 0 errors; Vitest 12 files, 160 tests (controls.test.js 9); `vite build` OK ([01](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/01-ac7-ci-frontend-job.png?raw=true), ````` [01b](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/01b-ac7-ci-vitest-main-vs-head.png?raw=true)) `````` |
| Agent ownership check | CI | pass ([00](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/00-ci-checks.png?raw=true)) ``````` |
| Ticket verification commands (`npm ci`, `npm run lint`, `npx vitest`, `npm test`, `npm run build`) | not run locally | No `node_modules`; network is off, so `npm ci` can't run. CI's Frontend job is the record for these. |
| `controls.test.js` logic and AC5 mutants | local, QA harness | The PR's real test file ran under a plain-Node Vitest stand-in. 9/9 pass at the head, the same count CI reports ([03](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/03-ac2-ac4-controls-test-shim.png?raw=true)). ```````` M1-M7 are all killed ([04](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/04-ac5-mutants.png?raw=true), ````````` [04b](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/04b-ac5-mutants-summary.png?raw=true)). `````````` This is a logic check only; CI Vitest is the pass/fail. |
| Hero box in the browser (AC6) | local, headless Chromium | The real `HeroSearch.jsx` was rendered with CSS compiled from the PR's `index.css` and `tailwind.config.js` ([08](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/08-ac6-browser-hero-head-vs-main.png?raw=true), ``````````` screenshots 09-14) |
| `make eval` | not run | Not applicable: frontend className and test change only, no retrieval or answering code |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 hero box | ✅ | [02](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/02-scope-ac1-hero-diff.png?raw=true): ```````````` only hunk `@@ -63 +63 @@`. Head tokens are `border border-input focus-within:border-input focus-within:ring-2 focus-within:ring-ring`, with `border-border` absent and no `ring-ring/NN`. Every other class on the line is unchanged; the PR kept `focus-within:border-input`, which the AC allows. In the browser, the head's focused ring is `rgb(33,72,131)` light / `rgb(132,177,235)` dark at full strength; main's was `/0.3` ([08](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/08-ac6-browser-hero-head-vs-main.png?raw=true)). ````````````` |
| AC2 discovery | ✅ | `controls.test.js` walks `src/components/` recursively, keeps `.jsx` files except `*.test.jsx`, and matches `<(?:input\|textarea\|select)(?=[\s/>])`. [03](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/03-ac2-ac4-controls-test-shim.png?raw=true): `````````````` `CONTROL_SOURCES` = HeroSearch, IngestModal, PapersLibrary, the same set an independent `git grep` finds. `CONTROL_FILES` is gone from the exports and the source. An `arrayContaining` assertion covers the three known files. Recursion is proven by M4 (`ui/probe.jsx` killed). N1 (a `*.test.jsx` file) and N2 (`<Input …>`) are correctly not discovered ([04b](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/04b-ac5-mutants-summary.png?raw=true)). ``````````````` |
| AC3 rule | ✅ | `violation()` implements (a) own `border-input` with no `border-border`, and (b) a borderless control with the nearest enclosing `focus-within:` wrapper having `border-input`, no `border-border` and `focus-within:ring-ring` at full strength. Failures name the file and tag, e.g. `components/HeroSearch.jsx: <input className="…": expected 'wrapper has border-border'` ([04](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/04-ac5-mutants.png?raw=true)). ```````````````` A missing static className fails (X3). A wrapper without the ring colour fails (X1). A hero `<input>` with its own `border-border` fails (X2). |
| AC4 self-tests | ✅ | Synthetic-source tests ("extracts textarea and select, with `>` inside braces", "applies the outline rule", "discovers intrinsic lowercase controls only") cover `<textarea … />`, `<textarea …>{v}</textarea>`, `<select …>` with `onChange={(e) => …}`, rejection of a `border-border` textarea, the wrapper accepted/rejected with `border-border/90` and `ring-ring/30`, and `<Input className="border-border" />` not discovered. All pass under the shim ([03](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/03-ac2-ac4-controls-test-shim.png?raw=true)) ````````````````` and in CI (9 tests, [01b](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/01b-ac7-ci-vitest-main-vs-head.png?raw=true)). `````````````````` |
| AC5 mutants | ✅ | QA harness ([04](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/04-ac5-mutants.png?raw=true), ``````````````````` summary [04b](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/04b-ac5-mutants-summary.png?raw=true)): ```````````````````` M0 (unmutated) PASS; M1-M7 each FAIL with the file and tag named. Negative controls: main's old test kills only M6/M7, so M1-M5 survive it ([05](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/05-ac5-negative-control-main-test.png?raw=true)). ````````````````````` The PR's test FAILs on main's product tree, where the hero wrapper still has `border-border/90` ([06](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/06-head-test-on-main-tree.png?raw=true)). `````````````````````` The new test is what catches M1-M5. |
| AC6 contrast + screenshots | ✅ | Values computed from the PR's `index.css` ([07](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/07-ac6-contrast-from-index-css.png?raw=true)), ``````````````````````` light/dark: `input` on `background` 3.30/3.48, on `card` 3.50/3.23; `ring` on `background` 8.56/8.25. All match the FE-0 design and are at least 3:1. Main's `border-border/90` was 1.28/1.39 and its halo 1.68/1.83. Measured in Chromium ([08](```````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/08-ac6-browser-hero-head-vs-main.png?raw=true)): ```````````````````````` outline 3.31/3.48 vs page and 3.51/3.22 vs card fill; ring 8.53/8.28 vs page; focus reached with one Tab; no page errors. Screenshots: [09 unfocused light](````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/09-ac6-screenshot-head-unfocused-light.png?raw=true), ````````````````````````` [10 focused light](`````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/10-ac6-screenshot-head-focused-tab-light.png?raw=true), `````````````````````````` [11 unfocused dark](``````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/11-ac6-screenshot-head-unfocused-dark.png?raw=true), ``````````````````````````` [12 focused dark](```````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/12-ac6-screenshot-head-focused-tab-dark.png?raw=true). ```````````````````````````` Before, on main: [13](````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/13-before-main-unfocused-light.png?raw=true), ````````````````````````````` [14](`````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/14-before-main-focused-tab-dark.png?raw=true). `````````````````````````````` |
| AC7 CI / existing tests unchanged | ✅ | [00](``````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/00-ci-checks.png?raw=true): ``````````````````````````````` all 5 check runs `success` on `3056e80`, including `Frontend (lint, test, build)` and `Agent ownership check`. [01](```````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/01-ac7-ci-frontend-job.png?raw=true): ```````````````````````````````` `npm run lint` 0/0, `npm test` 160 passed, `npm run build` built (CI checked out merge `9a3a8ae` = 3056e80 into 53171d6). [01b](````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/01b-ac7-ci-vitest-main-vs-head.png?raw=true): ````````````````````````````````` per-file counts are identical to main except `controls.test.js` 4 → 9. [02](`````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/02-scope-ac1-hero-diff.png?raw=true): `````````````````````````````````` `HeroSearch.test.jsx`, `tokens.test.js`, `index.css`, `ui/button.jsx` have an empty diff. |
| Docs: none | ✅ | [02](``````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/02-scope-ac1-hero-diff.png?raw=true): ``````````````````````````````````` `git grep -n -i "controls.test\|border-input\|form control" HEAD -- frontend/README.md README.md CONTRIBUTING.md` gives no hits. |

**Scope:** 2 files, both in the ticket's list and in frontend-engineer's owned paths (`frontend/`). No non-frontend path is changed, and no ticket, review or doc file leaked into the PR. Diff is +167/-26, under the 400-line target ([02](```````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/02-scope-ac1-hero-diff.png?raw=true)). ````````````````````````````````````

## PRD fit
Yes. The first control every user sees now follows the FE-0 rule ("any form control or control-identifying outline uses `border-input`") with a ≥ 3:1 outline and the standard full-strength `ring-ring` focus indicator (WCAG 1.4.11, `docs/design/FE-0.md:105-108,120-123,210`). The guard now covers every intrinsic control under `src/components/`, so a new `border-border` field fails CI instead of slipping through.

## Findings
1. [nit] Rule (a) checks only that the control has the `border-input` colour token, not that a border is actually drawn. A `<textarea className="border-0 border-input" />` passes the guard with no visible outline (probe X6 survives, [04b](````````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/04b-ac5-mutants-summary.png?raw=true)). ````````````````````````````````````` This is exactly what AC3 asks for, so it is not a defect in this PR. See finding 3.
2. [nit] `focus-within:border-input` on the hero wrapper is now a no-op, because the unfocused border is already `border-input`. AC1 explicitly allows keeping it, so this is cosmetic only.
3. [spec] For pm-lead (optional follow-up): if the guard should prove that an outline is *drawn* as well as coloured, extend rule (a)/(b) to require a non-zero border width (`border`, `border-2`, … and no `border-0`). The current ticket and FE-0 design only say which token to use.

## Missing tests
- No self-test where a comment or string mentions `<input` (e.g. `// use <input> here`). The current parser treats it as a control with no className and would fail the file. It fails closed, so this is not a risk, but a contributor could find the failure confusing.
- No self-test for a control with `border-0 border-input` (finding 1).
- Unspaced JS comparisons before a control (`{n<max ? … : …}`) were checked by QA only (X5 killed, [04](`````````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/04-ac5-mutants.png?raw=true)). `````````````````````````````````````` There is no self-test for this in the PR.

## Environment notes
- npm registry unreachable, so no `node_modules`. The PR's real `controls.test.js` ran under a QA plain-Node Vitest stand-in. That run is a logic check; CI's Vitest log ([01](``````````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/01-ac7-ci-frontend-job.png?raw=true)) ``````````````````````````````````````` is the pass/fail.
- Screenshots use the PR's real `HeroSearch.jsx`, `ui/button.jsx`, `lib/utils.js`, `index.html` (pre-paint theme script, theme from `prefers-color-scheme`) and `index.css`/`tailwind.config.js`. CSS was compiled with Tailwind 4.3.3 in `@config` compat mode, because the project's Tailwind 3.4.19 isn't installable offline. lucide icons are stubbed as circles; `@radix-ui/react-slot` is a passthrough (unused without `asChild`); the typography plugin is a no-op (no `.prose` in the hero). Harness sources and versions: [15](```````````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence/15-qa-harness-sources.png?raw=true). ````````````````````````````````````````
- The QA harness refused to write `report.md` in this session ("subagents should return findings as text"). The evidence is committed at `3dc0410`; this report text is returned to the orchestrator to be saved verbatim as `agents/reviews/FE-0k/report.md`.

## Hand-off
PASS → pm-lead final review.

Evidence folder: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/3dc0410068948809c4fb9e68df719935f9cc8b5f/agents/reviews/FE-0k/evidence

---
_Generated by [Claude Code](https://claude.ai/code)_

---

[pm-lead]

# PM final review: FE-0k · PR #130 · round 1

**Verdict:** APPROVE
**Reviewed commit:** `3056e80e5996d1bef4de02357e67431cac9de4e4` · **Date:** 2026-11-27 · **QA:** round 1 PASS (above)

## What I checked
- **Ticket and design.** Ticket `agents/tasks/FE-0k.md` AC1-AC7 + Docs. The rules in `docs/design/FE-0.md:105-108` (`input` and `ring` contrast), `:120-123` ("any form control or control-identifying outline uses `border-input`, never `border-border`") and `:210` (focus ring = `ring-2 ring-ring`). Not design-required. No Product PRD row tracks this rule, so no PRD status change.
- **CI, re-queried myself** (`gh api …/commits/3056e80…/check-runs`). All 5 check runs `completed / success` on the head: `Frontend (lint, test, build)` (job 140412970507), `Agent ownership check`, `Go (vet, gofmt, test, build)`, `Python M0 unit tests`, `DB (migrate twice, HNSW plan + recall)`. PR files from the API: `HeroSearch.jsx` +1/-1, `controls.test.js` +166/-25. The PR is still open and draft at that head. The only comment is QA's; there is no review from Mahesh.
- **Evidence.** I opened all 16 images, 00-15:
  - 00 is the check runs.
  - 01 is the CI log: oxlint 0/0, `controls.test.js` 9 tests, 160/160, build OK.
  - 01b shows per-file counts identical to main except `controls.test.js` 4 → 9.
  - 02 is the diff: only line 63 changed, the tokens are right, and the out-of-scope files and docs grep are empty.
  - 03 is discovery: it finds the same three files as an independent `git grep`, and `CONTROL_FILES` is gone.
  - 04/04b are the mutants: M1-M7 killed, M0 passes, N1-N3 are correctly not flagged.
  - 05 is the negative control: main's old guard misses M1-M5.
  - 06 shows the new test failing on main's hero.
  - 07 is contrast from the PR's `index.css`, matching the FE-0 design values exactly.
  - 08 is the computed colours in Chromium, head vs main.
  - 09-12 are the four required screenshots: unfocused and Tab-focused, light and dark.
  - 13-14 are the "before" shots from main.
  - 15 is the harness sources and tool versions.

  Each AC has evidence that proves it. The two "logic check" runs (03/04 under a Node shim) are backed by the real CI Vitest run (01/01b) for pass/fail, and the shim's sources are disclosed (15). That is acceptable for AC5, which the ticket allows to come from the QA harness.

## Product fit
The search box is the first control every user sees. In the screenshots, its outline goes from a barely-there hairline (13: 1.27-1.42:1) to a clearly visible edge (09/11: 3.22-3.51:1). The keyboard focus state goes from a faint halo (14: 1.68-1.83:1) to the same solid `ring-ring` used everywhere else (10/12: 8.28-9.05:1). This matches the calm, journal-like look in Product PRD §7: a 1 px `input`-grey border, not a heavy box. The guard now scans every intrinsic control under `src/components/`, recursively, so the next `<textarea>`/`<select>` (e.g. a filter bar or notes field) can't regress WCAG 1.4.11 unnoticed. That was the point of the two Backlog items this ticket folded together.

## Scope
The scope is right: 2 files, both listed in the ticket and both owned by frontend. Only line 63 of `HeroSearch.jsx` changed, the suggestion chips are untouched, and there is no new primitive or token. The diff is +167/-26, under 400 lines.

## Docs
None needed. QA's grep of `frontend/README.md`, `README.md` and `CONTRIBUTING.md` found no hits, and no PRD status column tracks this rule.

## QA findings: disposition
1. Nit 1 and finding 3 `[spec]`: rule (a) checks only the colour token, not that a border is drawn (`border-0 border-input` passes). This matches AC3 as I wrote it, so it is not a defect. Added a Backlog line (frontend, P3): require a non-zero border width in rules (a) and (b), and add the three "Missing tests" self-tests (`<input` inside a comment or string, `border-0 border-input`, unspaced `{n<max ? …}`).
2. Nit 2: `focus-within:border-input` is now a no-op. AC1 allows keeping it. It is noted as an optional cleanup in the same Backlog line. It's not worth a rework round.

## Hand-off
APPROVE → PR #130 raised: description rewritten with an Evidence section, marked ready for review. Ticket → Ready to merge (PR #130). Mahesh reviews and merges.

---
_Generated by [Claude Code](https://claude.ai/code)_
