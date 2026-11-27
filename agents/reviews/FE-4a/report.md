<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-27T03:59Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/128#issuecomment-7210282511 ; qa-reviewer's harness could not write report.md. -->

[qa-reviewer] **QA round 1: FAIL** (1 blocking: AC2b swap test is vacuous). Evidence: [agents/reviews/FE-4a/evidence @ d44b7cf](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence). The report is below; the harness refused to write `report.md`, so the orchestrator saves it verbatim.

[mutants](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/07-mutants.png?raw=true ``)
[swap test](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/08-ac2b-swap-test-vacuous.png?raw=true) ```

# QA report — FE-4a · PR #128 · round 1

**Verdict:** FAIL (1 blocking finding, a test-quality gap; the behaviour itself is correct in every check I ran)
**Reviewed commit:** `34cbd2ecb719b108788c73f4e05108dd44a9eaea` · **Date:** 2026-11-27
**Ticket:** `agents/tasks/FE-4a.md` · **Design:** `docs/design/FE-4.md` (approved with conditions) · **PRD:** Product UI-1, QA-3, QA-4, §7 principles 1–3; ADR-0003, ADR-0014, ADR-0019

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI | pass ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/00-ci-checks.png)) |
| Python M0 unit tests | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Agent ownership check | CI | pass (also: all 9 files under `frontend/src/`, [01](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/01-scope-diffstat.png ````)) |
| Frontend (lint, test, build) | CI job 140313386494 (ran on merge `be57e8b` = head into `53171d6`) | pass: `npm ci` OK; oxlint `Found 0 warnings and 0 errors` (main 53171d6: 0); Vitest 12 files **207 passed** (main 155); `vite build` OK ([02](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/02-ac6-ci-frontend-head-vs-main.png)) ````` |
| Per-file test deltas | CI logs head vs main | SynthesisView 17→30 (+13), citations 35→59 (+24), ReferencesStack 16→21 (+5), App 7→17 (+10). Each delta equals the number of new `it`/`it.each` rows in the diff, so every new test ran |
| Ticket verification (`npm ci && …`) | local | not run: `npm ci` can't reach the npm registry from the sandbox. CI is the source of truth |
| QA: PR's real `citations.test.js` in node with a vitest shim | local | 59 passed, 0 failed, which equals the CI count ([04](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/04-ac1-citations-test-node-shim.png)). `````` This is a logic check only |
| QA: browser run of the PR's real `App.jsx` and components in Chromium, with the real Radix tooltip (radix-ui/primitives `eb3a2b7`, tooltip 1.4.1 = lockfile) | local | **48 PASS, 0 FAIL** ([05](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/05-browser-run-head.png ```````)) |
| QA: negative control, the same harness on main `53171d6` code with the PR's fixtures | local | 12 PASS, 15 FAIL: duplicate React keys, a ring on card [1] in refusal A/B/C, no focus move ([06](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/06-negative-control-main.png)) ```````` |
| QA: mutants (design §Test plan + QA) | local | see the table below ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/07-mutants.png)) |
| `make eval` | — | not run: frontend only, no retrieval or answering change |

Stubbed in the browser run: lucide icons (drawn as circles), the `ui/dialog`, `ui/tabs` and `ui/dropdown-menu` wrappers (closed in every run), and fonts (system fallback). CSS was compiled from the PR's real `tailwind.config.js` with Tailwind 4.3.3 in v3-compat mode. The full harness sources and dependency commits are in [09](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/09-qa-harness-sources.txt). `````````

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: claim list, chips Supported / Not checked / Unsupported, different variants, no "Supported"/"verified" on unverified claims, `markers: []` → chip only, `synthesizedSkips` → `[1] [1] [3]`, no `[2]`, no "hidden" | ✅ | CI: `citations.test.js › claimState` (7 rows + missing claim) and `SynthesisView.test.jsx › quoted claims…` / `› written answer with skipped markers…` ([02](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/02-ac6-ci-frontend-head-vs-main.png)). `````````` Browser: chips `["Supported","Unsupported","Not checked","Not checked"]`, variants `supported/unsupported/unchecked`, uncited claim shows no buttons, markers `["[1]","[1]","[3]"]`, no `[2]`, no "hidden" ([05](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/05-browser-run-head.png ```````````)). Screenshots [10](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/10-screenshot-quotedClaims-light.png) ```````````` and [11](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/11-screenshot-synthesizedSkips-light.png). ````````````` Mutant M1 (unverified → Supported) is killed by the unit test and the browser run |
| AC2: click, Enter and Space call `onCitationClick(marker, pos)`; in App focus goes to "Citation [n]" with `data-active`; `aria-controls="ref-<n>"`; the tooltip opens on focus with title + status; after Enter focus is on the card (condition 4); broken invariant still maps by number | ✅ (the FE-4b clauses moved per the PM size decision) | CI: `SynthesisView.test.jsx › marker has aria-controls… (3, 2)`, `› focusing a marker previews…`, and App `› clicking [3]…`, `› Tab to [1]… Enter moves focus to card [1]` (asserts `document.activeElement`, so condition 4 is met), `› Space…`, `› broken positional invariant…`. Browser: Tab → `role=tooltip` "[1] Grounded Retrieval for Scientific QA · § Methods · Supported · 87.3%" with `aria-describedby`; Enter → activeElement "Citation [1]…", `data-active` on ref-1, tooltip closed, card `:focus-visible` with a 2px ring; Space and click work too; brokenPositional maps `[3]`→card 3 and `[1]`→card 1; reduced motion gives `behavior:"auto"`, otherwise `"smooth"` ([05](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/05-browser-run-head.png ``````````````)). Screenshots [12](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/12-screenshot-tooltip-focus-light.png) ``````````````` and [13](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/13-screenshot-enter-focus-card-light.png) ```````````````` |
| AC2b: nothing active on load in any mode; refusal A/B/C never show `[data-active]`; nothing active after the written answer replaces the quoted one | ⚠ behaviour met, **swap test vacuous** | Browser: no `[data-active]` and no ring classes on load for quotedClaims, synthesizedSkips, the prose fallback and refusal A/B/C; the swap clears `active` ([05](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/05-browser-run-head.png `````````````````), [14](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/14-screenshot-refusalA-light.png), `````````````````` [16](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/16-screenshot-twoStage-after-swap-light.png)). ``````````````````` But the PR's App swap test can't fail: see Finding 1 ([08](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/08-ac2b-swap-test-vacuous.png)) ```````````````````` |
| AC2c: one card per distinct marker, no duplicate `id="ref-n"`; heading (cards) and footer (entries) both pinned for `synthesizedSkips` (condition 3) | ✅ | CI: `ReferencesStack.test.jsx › one card per distinct marker…` and App `› AC2/AC2c…` pin "2 cited" and "3 of 3 citations supported". Browser: ids `["ref-1","ref-3"]`, heading "References 2 cited", footer "3 of 3 citations supported" ([05](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/05-browser-run-head.png `````````````````````)), screenshot [11](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/11-screenshot-synthesizedSkips-light.png). `````````````````````` Mutant M9 (no grouping) is killed. Main shows the duplicate-key warning this fixes ([06](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/06-negative-control-main.png)) ``````````````````````` |
| AC5: absent / `[]` / malformed `claims` → FE-3 prose with `[n]` buttons; existing FE-1/FE-3 tests unmodified | ✅ | CI: `› claims absent / empty / malformed 1–4 → prose…` and `› claims: [] renders the same DOM as no claims`. The only lines removed from test files are 3 import lines, and every other hunk is an import extension or an appended block; `fixtures.js` has 0 removed lines ([03](```````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/03-ac5-existing-tests-unmodified.png)). ```````````````````````` The PR body lists the import changes. Browser: the prose fallback has no claims list and `[2]` focuses card 2 ([05](````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/05-browser-run-head.png `````````````````````````), [15](`````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/15-screenshot-fallback-prose-light.png)). `````````````````````````` Mutant M8 (`hasClaims` without the text check) is killed |
| AC6: CI frontend green, lint warnings not above main | ✅ | [02](``````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/02-ac6-ci-frontend-head-vs-main.png): ``````````````````````````` 0 warnings (main 0), 207/207, build OK |
| Docs: `docs/design/FE-4.md` §2 item 3 wording per condition 1 | ✅ | The design §2 item 3 on `main` has the "gain only `aria-controls`, the focus behaviour and the tooltip … passes unmodified" wording |

PM size conditions: (1) no "Cited by claim n" / "Check n" rows or `aria-current` in the diff; a repeated marker shows one chip per check (card [1] shows "Supported · 87.3%" and "Supported · 80.1%", [13](```````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/13-screenshot-enter-focus-card-light.png)). ```````````````````````````` (2) Production code is **221** changed lines, under the ~250 cap; tests + fixtures are 436 ([01](````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/01-scope-diffstat.png `````````````````````````````)). (3) No existing test body changed ([03](`````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/03-ac5-existing-tests-unmodified.png)). `````````````````````````````` Design condition 2 holds: the meta line, passage box and PDF link are untouched in the diff.

### Mutants ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/07-mutants.png); the browser column is QA's harness, not the PR's tests)
| Mutant | PR unit test (run) | QA browser | PR component tests (static reading; RTL can't run offline) |
|---|---|---|---|
| M1 claimState unverified → Supported | killed | killed | also `SynthesisView › quoted claims…` |
| M2 / M2b claimCitations without the marker check / count check | killed / killed | survive (expected, same rendering via fallback) | — |
| M3 `active` initial `{marker:1}` (design's "back to 1") | — | survives | **equivalent**: `handleSearch` calls `setActive(null)` before any result renders. M3 combined with M10 (the real old behaviour) is killed by the browser run, and by the App AC2b "on load" rows |
| M4 drop `tabIndex={-1}` | — | killed | `ReferencesStack › cards are programmatic focus targets` and App `document.activeElement` asserts |
| M5 drop `.focus()` | — | killed | App `document.activeElement` asserts |
| **M6 keep `active` across the swap** | — | killed only by QA's `[1]` swap scenario | **survives**: the App swap test clicks `[2]`, which the written fixture has no card for (Finding 1) |
| M7 honour `active` in refusal mode | — | survives (refusals have no markers) | `ReferencesStack › refusal mode ignores active` |
| M8 `hasClaims` without the text check | killed | — | also the SynthesisView malformed rows |
| M9 no grouping | — | killed | `ReferencesStack › one card per distinct marker`, App AC2c |
| M10 keep `active` on a new search | — | killed | **no test** (Finding 2) |
| M11 marker ignores `pos` | — | survives (pos isn't visible until FE-4b) | `SynthesisView › … (marker, pos)` `toHaveBeenLastCalledWith(3, 2)` |
| M12 drop `aria-controls` | — | killed | SynthesisView aria-controls asserts |
| M13 reduced motion ignored | — | killed | **no test** (Finding 3) |

## PRD fit
This delivers UI-1 / QA-3 / QA-4 as the design describes. Each statement shows its own verdict, and "Not checked" is distinct from "Unsupported" without ever saying "verified" (principles 1–2). Each `[n]` takes mouse and keyboard users to its passage card, which stays one click from the PDF (principle 3). Refusals no longer show a stray active ring. The duplicate `ref-n` cards are gone.

## Findings
1. **[blocking] [test]** AC2b's swap test is vacuous. `App.test.jsx:292-307` ("after the written answer replaces the quoted one, no card is active") clicks `[2]` on `quotedClaims`, then swaps to `synthesizedSkips`, whose citation markers are `[1,1,3]`. A stale `active = {marker: 2}` matches no card, so the final `activeCards()` length 0 holds even with the reset deleted. Mutant M6 (remove `setActive(null)` after `setSearchResult(full)`, `App.jsx:113`) passes this test; the same browser flow with `[1]` shows `["ref-1"] -> ["ref-1"]` ([08](``````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/08-ac2b-swap-test-vacuous.png)). ``````````````````````````````` Fix: click a marker that has a card in both answers (`[1]`), assert `citationCard(1)` has `data-active` before the swap, and assert no `[data-active]` after it.
2. [nit] [test] No test covers the reset on a new search (`App.jsx:84`, design §4 / ticket scope "cleared on new search"). M10 survives the PR suite. Without it, a second search would ring the previous answer's card on load (browser: `["ref-3"] -> ["ref-3"]`, [07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/07-mutants.txt)). Suggest an App test: search, click `[3]`, search again, assert no `[data-active]`.
3. [nit] [test] The `prefers-reduced-motion` branch (`behavior: 'auto'`) has no test; M13 survives the PR suite. It isn't an AC, but it is design §4 behaviour. A `matchMedia` stub plus a `scrollIntoView` spy would cover it.
4. [nit] [code] In the claims list, the first marker sits right against the sentence ("answer.[1]", "claim.[1]"; screenshots [10](```````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/10-screenshot-quotedClaims-light.png), ```````````````````````````````` [11](````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/11-screenshot-synthesizedSkips-light.png)), ````````````````````````````````` while the prose fallback has a space. This is cosmetic. Adding `{' '}` before the markers would match the prose.
5. [spec] The design's mutant "active initial value back to 1" is an equivalent mutant now that `handleSearch` resets `active` before rendering any result (M3). For FE-4b/QA, pair it with the reset (M3+M10), or test the reset directly.

## Missing tests
- App: the quoted → written swap with a marker present in both answers (Finding 1, blocking).
- App: a second search clears `active` (Finding 2).
- App: reduced-motion scroll behaviour (Finding 3).

## Hand-off
FAIL → back to frontend-engineer. Fixing Finding 1 is a test-only change in `App.test.jsx` (it doesn't touch any existing test body); Findings 2–3 can go in the same commit. Round 2 will rerun mutants M6, M10 and M13 against the new tests (statically, plus CI counts) and the browser harness ([09](`````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d44b7cf5914541b642bb3898d1d3095d5cfbf187/agents/reviews/FE-4a/evidence/09-qa-harness-sources.txt)). ``````````````````````````````````

---
_Generated by [Claude Code](https://claude.ai/code)_

---

# QA report — FE-4a · PR #128 · round 2

**Verdict:** PASS
**Reviewed commit:** `529ad12bb2e3f20bb3ebeb29162dddf81107fcaf` (rework on top of round-1 `34cbd2e`) · **Date:** 2026-11-27
**Evidence:** [17–25 @ b0225a1](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence) · Inputs: ticket `agents/tasks/FE-4a.md`, design `docs/design/FE-4.md`, the diff `34cbd2e..529ad12` and CI. I did not use the developer's Notes as evidence.

## Test results
| Check | Source | Result |
|---|---|---|
| All 5 check runs on `529ad12` | CI | Go, Python M0, DB, Agent ownership and Frontend all `completed success` ([17](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/17-ci-checks-r2.png)) |
| Frontend (lint, test, build) | CI job 140323578256, merge `d2b4bcd` = `529ad12` into `53171d6` | `npm ci` OK; oxlint `Found 0 warnings and 0 errors` (main: 0); Vitest 12 files, **210 passed** (round 1: 207); `vite build` OK. App.test.jsx 17→**20**, and SynthesisView 30, citations 59, ReferencesStack 21 are unchanged, so the +3 are exactly the 3 new App rows. The log lists "a new search clears the active card" by name ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/18-ac6-ci-frontend-r2.png)) |
| Rework scope | local git | `34cbd2e..529ad12`: `App.test.jsx` +50/−2, `SynthesisView.jsx` +1. The only 2 removed lines are in the PR-added AC2b swap test (git blame at `34cbd2e`: commit `34cbd2ec`; main `53171d6` has no FE-4a block). For the whole PR vs main, the removed test lines are still only the 3 import lines from round 1. Prod is 222 changed lines (cap ~250), and every path is under `frontend/src/` ([19](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/19-rework-scope-r2.png)) |
| QA: the PR's **real** `App.test.jsx` + `src/test/setup.js` in Chromium | local | **20 passed, 0 failed**, the same count as CI ([20](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/20-app-tests-browser-head-r2.png)). New in round 2: in-browser stand-ins for `vitest`, `@testing-library/react` and `user-event`. Clicks use userEvent's pointer sequence; Tab, Enter, Space and typing are real Chromium key presses. No CSS is loaded, and Chromium's `scrollIntoView` is removed for jsdom parity. Sources are in [25](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/25-qa-harness-sources-r2.txt). This is a logic check; the CI Vitest log is the record |
| QA: mutants against those real tests | local | M6, M10, M13 and M13b are all **KILLED** at `529ad12`, each by the intended test. All four **SURVIVE** on round-1 `34cbd2e` with the same harness, which reproduces the round-1 finding and shows the new tests do the killing ([21](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/21-mutants-r2.png)) |
| QA: round-1 browser harness (real App, real Radix tooltip, compiled CSS) re-run at `529ad12` | local | **48 PASS, 0 FAIL** (round 1: 48/0) ([22](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/22-browser-run-head-r2.png)). Screenshots: [23](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/23-screenshot-quotedClaims-spacing-r2.png) (quoted claims, three chip kinds) and [24](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/24-screenshot-synthesizedSkips-r2.png) (skip + grouping + both counts) |
| Ticket verification `npm ci && …` | local | not run: the npm registry is unreachable from the sandbox. CI is the source of truth |
| `make eval` | — | not run: frontend only, no retrieval or answering change |

## Round-1 findings, checked one by one
| # | Round-1 finding | Fix in `529ad12` | Verified by |
|---|---|---|---|
| 1 | **[blocking] [test]** The AC2b swap test was vacuous (it clicked `[2]`, which the written answer has no card for). M6 survived | It now clicks `[1]`, which has a card in both answers, and asserts `citationCard(1)` `data-active` plus 1 active card before the swap. After the swap it asserts `citationCard(1)` has no `data-active` and there are 0 active cards | M6 now fails exactly that test: `expect(<div#ref-1 Citation [1]…>).not.toHaveAttribute(data-active) got "true"`. M6 survives at `34cbd2e` ([21](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/21-mutants-r2.png)). CI runs it green ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/18-ac6-ci-frontend-r2.png)). **Resolved** |
| 2 | [nit] [test] No test for "new search clears active". M10 survived | New App test: search, click `[3]`, assert card 3 active, search again, wait for the 2nd fetch and the list, assert card 3 not active and 0 active | M10 fails "a new search clears the active card" (`#ref-3 … got "true"`) ([21](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/21-mutants-r2.png)). It is listed as passing in CI ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/18-ac6-ci-frontend-r2.png)). **Resolved** |
| 3 | [nit] [test] Reduced motion was untested. M13 survived | New `it.each` (true→`auto`, false→`smooth`): `vi.stubGlobal('matchMedia')` (restored by the existing `afterEach` `vi.unstubAllGlobals()`), a `scrollIntoView` spy restored in `finally`, and a check that the last call is `{ behavior, block: 'nearest' }` on card 3 via `mock.contexts` | M13 (always smooth) fails the `true` row and M13b (always auto) fails the `false` row ([21](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/21-mutants-r2.png)). **Resolved** |
| 4 | [nit] [code] No space between a claim and its first marker | `{entries.length > 0 && ' '}` in `SynthesisView.jsx` (+1 line). Uncited claims are unchanged | Browser text: "…check each claim. [1] Supported" ([22](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/22-browser-run-head-r2.txt)). Screenshot [23](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/23-screenshot-quotedClaims-spacing-r2.png). The existing SynthesisView tests are still 30/30 in CI. **Resolved** |
| 5 | [spec] The design's "active initial back to 1" mutant is equivalent (M3) | No code needed. The reset is now tested directly (finding 2) | Still open for pm-lead in the ticket (F5 unchecked). Not blocking |

## Acceptance criteria (re-checked at `529ad12`)
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | Browser: chips Supported/Unsupported/Not checked/Not checked in three variants; `synthesizedSkips` markers `[1] [1] [3]`, no `[2]`, no "hidden" ([22](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/22-browser-run-head-r2.png), [23](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/23-screenshot-quotedClaims-spacing-r2.png), [24](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/24-screenshot-synthesizedSkips-r2.png)). CI: citations 59 and SynthesisView 30 pass ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/18-ac6-ci-frontend-r2.png)) |
| AC2 (FE-4a part; the "Cited by claim n"/"Check n" rows are FE-4b per the PM size decision) | ✅ | The real App tests for click, Tab+tooltip+Enter, Space and the broken positional invariant pass in Chromium ([20](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/20-app-tests-browser-head-r2.png)) and in CI. Browser harness: tooltip text, `aria-describedby`, focus on the card, `:focus-visible` ring ([22](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/22-browser-run-head-r2.png)) |
| AC2b | ✅ (round-1 gap closed) | The on-load rows for prose, quoted claims and refusal A/B/C pass, and the swap test is now non-vacuous (M6 killed) ([20](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/20-app-tests-browser-head-r2.png), [21](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/21-mutants-r2.png)) |
| AC2c | ✅ | Card ids `["ref-1","ref-3"]`, heading "References 2 cited", footer "3 of 3 citations supported" ([22](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/22-browser-run-head-r2.png), [24](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/24-screenshot-synthesizedSkips-r2.png)) |
| AC5 | ✅ | No main-origin test body changed in the rework or in the whole PR ([19](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/19-rework-scope-r2.png)). The prose fallback still has no claims list and `[2]` focuses card 2 ([22](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/22-browser-run-head-r2.png)) |
| AC6 | ✅ | 0 lint warnings (main 0), 210/210, build OK ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b0225a1c10e4a535193c0d4a8f74db1f5d491832/agents/reviews/FE-4a/evidence/18-ac6-ci-frontend-r2.png)) |
| Docs (design §2 item 3) | ✅ | Unchanged since round 1 (already on main) |

PM size conditions still hold: no "Cited by claim n" rows and no `aria-current`, prod 222 lines (≤ ~250), no existing test body changed. Design condition 2 holds: the rework doesn't touch the card body.

## PRD fit
Unchanged from round 1. The rework only adds tests and one space character. The space makes the claim list read the same as the prose fallback, which helps principle 1 (each statement with its own verdict, legible).

## Findings (round 2)
None blocking.
1. [spec] Round-1 finding 5 (M3 equivalent mutant) is still unchecked in the ticket. pm-lead should note it in the design test plan or FE-4b's spec.

## Hand-off
PASS → pm-lead for final review. CI is green on `529ad12` (5/5). Every round-1 item is verified against the real tests, with mutants killed at head and surviving at the round-1 commit. The PR stays draft; I made no change to the ArxivLens repo.

---

# PM review — FE-4a · PR #128 · pm-lead

**Verdict: APPROVE** · **Reviewed commit:** `529ad12bb2e3f20bb3ebeb29162dddf81107fcaf` · **Date:** 2026-11-27 (cycle 2026-11-27T03:59Z)
**Inputs:** ticket `agents/tasks/FE-4a.md` (incl. the 2026-11-22 size decision), design `docs/design/FE-4.md` (PM decision + conditions 1–4 for FE-4a),
Product PRD UI-1 / QA-3 / QA-4 / §7 principles 1–3, ADR-0003 / 0014 / 0019, the production diff (`gh api …/pulls/128/files`), QA rounds 1 and 2,
and every file in `evidence/` (00–25: all 25 PNGs opened, including the Chromium screenshots 10–16, 23, 24).

## Product fit (Product PRD §7)
- **Principle 1 (every statement shows its own verdict):** each claim renders as a list item with its own text + icon chip (10, 23). The chip comes from the
  claim's `status`, not from the citations, so a claim whose check failed can't borrow a neighbour's "Supported".
- **Principle 2 (never overclaim):** `claimState` is the conservative order: only `supported` reads Supported, `unverified` → "Not checked", anything else
  → "Unsupported". "Not checked" is a distinct amber chip, and no unverified item says "verified" (04, 05/22, M1 killed by unit + browser).
- **Principle 3 (one click to the source):** every `[n]` button that has a card moves focus to that card and marks it (12, 13). Keyboard users get the
  preview tooltip on focus, and Enter lands on the card, which is design condition 4 asserted on `document.activeElement` (20, CI 18).
  Reduced motion is respected. The FE-3b review item (a stray ring in refusal mode) is closed (14 against negative control 06).
- **ADR-0019:** a written answer with skipped markers shows `[1] [1] [3]`, no `[2]` and no "hidden" count. One card per passage, with both counts
  pinned and shown: "2 cited" and "3 of 3 citations supported" (11, 24). Design condition 3 is met, including the screenshot.

## Scope
- Matches the ticket and the size decision. The 9 files are all under `frontend/src/` (01, 19). The "Cited by claim n" / "Check n" rows and `aria-current`
  are absent, as agreed; they're FE-4b AC2d. The interim one-chip-per-check header on a repeated-marker card (11, 13: "Supported · 87.3%" and
  "Supported · 80.1%") hides no check's status, which is why I accepted that interim.
- Design condition 2 holds: the meta line, passage box and PDF link are untouched. "Chunk #", "§ Section:" and the `max-h-36` box are still visible in the screenshots, as intended until FE-4b.
- Nothing extra. `hasClaims` was moved into `lib/citations.js` so it can be unit-tested (§2 item 2). This adds no behaviour. The dropped `title` on fallback markers with a card is the accepted deviation (design Q1).
- **Size:** 706 changed lines in total. Prod is **222** (cap ~250; App 23, ReferencesStack 64, SynthesisView 78, citations 57) and tests + fixtures are 484. Accepted under the 2026-11-22 decision.
  The overage is the AC test plan plus the three round-1 tests that killed M6/M10/M13.
- **No existing test body changed** (condition 1 / AC5): the only removed test lines PR-wide are 3 import lines (03, 19). The 2 lines removed in the rework belong to the PR's own swap test (git blame in 19).

## Evidence covers every AC
| AC | Convincing? | Key evidence |
|---|---|---|
| AC1 | yes | 04 (claimState table), 05/22 (chips, variants, `[1] [1] [3]`, no hidden), 10/23, 11/24, CI 18 |
| AC2 (FE-4a part) | yes | 12 (tooltip on keyboard focus with title + status), 13 (focus ring on card [1] after Enter), 20 (real App tests incl. broken invariant), 05/22 |
| AC2b | yes, after rework | 14 (refusal A: no ring), 16 (after swap: no ring), 21 (M6 and M10 killed at 529ad12 and survive at 34cbd2e), 06 (main shows the ring) |
| AC2c | yes | 11/24 (two cards, "2 cited", "3 of 3"), 05/22 (ids `ref-1`, `ref-3`), 06 (main: duplicate-key warning) |
| AC5 | yes | 15 (prose fallback; `[2]` → card 2), 03/19 (no test body changed), CI SynthesisView 30/30 |
| AC6 | yes | 17 (5/5 checks on 529ad12), 18 (oxlint 0 warnings = main, Vitest 210/210, build OK) |
| Docs | yes | design §2 item 3 carries the condition-1 wording; no app README change needed |

No AC rests on a "⚠ unverified" item. Mutants M7 and M11 survive QA's browser harness, but the PR's component tests kill them statically and those tests run green in CI (`refusal mode ignores active`, `toHaveBeenLastCalledWith(3, 2)`). M11 becomes visible in FE-4b (`aria-current` per `(marker, pos)`), and I've added it to FE-4b's mutant list.

Observation (not a finding): in 16, claim 2's chip is captured mid colour transition (amber tint). The same fixture settled in 24 is green, and the variant assertions pass (05/22).

## [spec] items (mine)
- QA r1 F5 / r2 F1, **M3 is an equivalent mutant**: `handleSearch` resets `active` before any result renders, so "initial value back to 1" can't be observed.
  I fixed the design test plan (`docs/design/FE-4.md` §Test plan: M3 is replaced by "drop the reset on a new search", alone or combined with M3) and added the
  note to FE-4b's spec. Nothing changes in FE-4a. The reset is now tested directly ("a new search clears the active card", M10 killed).

## Follow-ups
- FE-4b (already specced, Blocked on this merge): AC2d rows replace the interim chips. Mutant list updated (M11, M3+M10). After FE-4b merges, the Product PRD UI-1 note gets updated via a `docs/` PR (already in FE-4b's Docs AC).
- None new.

**Raised:** PR description rewritten with the Evidence section, marked ready for review, label `ready-to-merge`. Merge is Mahesh's.
