_Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/issues/comments/7059216558 (QA harness refused to write report.md), cycle 2026-11-21T07:00Z._

[qa-reviewer] QA report — FE-0g · PR #108 · round 1

**Verdict:** PENDING (AC6 mutation evidence missing. CI is green and there are no blocking code findings. See "Why PENDING")
**Reviewed commit:** `35cecd32e27a56529d51162ffa83d8a3486526e0` · **Date:** 2026-11-21
**Ticket:** `agents/tasks/FE-0g.md` (Jira KAN-110) · **PRD:** Product PRD §7 (readable, accessible UI via FE-3/FE-4), FE-0d QA r1 "Missing tests" M35–M39 and nit 4

Evidence folder: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/388ca133cdf56ed9de4a17a38c797897aabe90c0/agents/reviews/FE-0g/evidence
(The QA harness refused to write `report.md`, so this comment is the report. The orchestrator saves it verbatim.)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI @ 35cecd3 | success ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/388ca133cdf56ed9de4a17a38c797897aabe90c0/agents/reviews/FE-0g/evidence/00-ci-checks.png?raw=true)) `` |
| Python M0 unit tests | CI @ 35cecd3 | success (00) |
| Frontend (lint, test, build) | CI @ 35cecd3, job 136770665327 | success. oxlint "Found 0 warnings and 0 errors". `primitives.test.jsx (17 tests)`. Test Files 11 passed (11), Tests 145 passed (145). `✓ built` ([01](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/388ca133cdf56ed9de4a17a38c797897aabe90c0/agents/reviews/FE-0g/evidence/01-ac7-frontend-job-head.png?raw=true)) ``` |
| Frontend baseline | CI on main @ 11c4696 (= merge-base), job 136736533187 | `primitives.test.jsx (12 tests)`, 11 files, 140 tests ([02](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/388ca133cdf56ed9de4a17a38c797897aabe90c0/agents/reviews/FE-0g/evidence/02-ac7-frontend-job-main-baseline.png?raw=true)) ```` |
| Agent ownership check | CI @ 35cecd3 | success (00) |
| DB (migrate twice, HNSW plan + recall) | CI @ 35cecd3 | success (00) |
| Ticket verification: scope | local | `frontend/src/components/ui/primitives.test.jsx` only, 1 file, +88/−2 ([03](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/388ca133cdf56ed9de4a17a38c797897aabe90c0/agents/reviews/FE-0g/evidence/03-scope.png?raw=true `````)) |
| `npm ci && npm run lint && npm test` | not run locally | The npm registry can't be reached from the QA sandbox (`npm ci --offline` gives ENOTCACHED, `npm view` times out) ([07](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/388ca133cdf56ed9de4a17a38c797897aabe90c0/agents/reviews/FE-0g/evidence/07-local-npm-blocked.png?raw=true)). `````` CI is the source of truth. |
| AC6 mutation run (m1–m6) | not run | I rebuilt FE-0d's Chromium/esbuild harness (real Radix `eb3a2b7` + sonner `v2.0.8` sources, Vitest/RTL shims, plus a fake clock and `fireEvent`), but the sandbox permission layer refused to run it. I did not try to get around the refusal. |
| `make eval` | not run: no retrieval/answering change | n/a |

Note: an earlier head, `b171ba0`, had a red Frontend job (the AC4 test timed out under `user.hover` with fake timers, per the ticket Notes). All five check runs on the current head `35cecd3` are `success`, and all report `head_sha=35cecd3` (00).

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 ScrollBar (M35, M36) | ✅ | Test `ScrollBar orientation and className (FE-0g AC1)` ([04](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/388ca133cdf56ed9de4a17a38c797897aabe90c0/agents/reviews/FE-0g/evidence/04-ac1-ac4-new-tests.png?raw=true)). ``````` It renders `ScrollBar` inside `ScrollAreaPrimitive.Root type="always"`. Horizontal + `x-bar`: asserts `h-2.5 flex-col border-t x-bar` and not `w-2.5` / `border-l`. Default: asserts `data-orientation="vertical"`, `h-full w-2.5 border-l` and not `flex-col`. Every class the AC lists is asserted. It passes in CI: the file has 17 tests, up from 12, with all 145 passing (01). |
| AC2 Toaster position (M37) | ✅ | Test `Toaster position (FE-0g AC2)` (04). It finds the description, takes `closest('[data-sonner-toaster]')`, then asserts `tagName === 'OL'`, `data-y-position="bottom"` and `data-x-position="right"`. Passes in CI (01). |
| AC3 Separator className (M38) | ✅ | Test `Separator className (FE-0g AC3)` (04) asserts `x-sep shrink-0 bg-border h-px w-full`. Passes in CI (01). |
| AC4 Tooltip default delay (M39) | ✅ | Test `Tooltip default delay (FE-0g AC4)` (04). It uses no `delayDuration` prop, `vi.useFakeTimers()` and `fireEvent.pointerMove(trigger, {pointerType:'mouse'})`. At 250 ms the ref is null and there is no `role="tooltip"`. At 350 ms both are present with the tooltip text. `vi.useRealTimers()` runs in the describe's `afterEach`. Passes in CI (01). Using `fireEvent` instead of `userEvent.setup({advanceTimers})` is allowed: the AC says "e.g." and only requires fake or real timers plus a restore. |
| AC5 unique toast text | ✅ | `t-position` / `d-position` appear only in the new AC2 test. The other `toast(` calls use different text ([05](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/388ca133cdf56ed9de4a17a38c797897aabe90c0/agents/reviews/FE-0g/evidence/05-ac5-unique-toast-text.png?raw=true)). ```````` |
| AC6 mutation check m1–m6 | ⚠ unverified | Nobody has executed it. The developer couldn't (npm blocked, per ticket Notes), and QA's harness run was refused by the sandbox permission layer. I checked that each mutant's target text exists exactly once at head ([06](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/388ca133cdf56ed9de4a17a38c797897aabe90c0/agents/reviews/FE-0g/evidence/06-ac6-mutant-targets.png?raw=true): ````````` scroll-area.jsx:12–13, sonner.jsx:13, separator.jsx:14, tooltip.jsx:13), and the PR worktree is clean. Reading the code, I expect every mutant to be killed: m1 removes `x-bar`; m2 removes `h-2.5`/`flex-col`/`border-t`; m3 gives `top`/`center`; m4 removes `x-sep`; m5 opens before 250 ms, since Radix's `isOpenDelayedRef` starts `true` and `setTimeout(0)` fires inside the 250 ms advance; m6 is still closed at 350 ms. **That is reasoning, not evidence**, so the AC is not checked off. |
| AC7 CI lint + test, count up, files unchanged | ✅ | Head: oxlint 0 warnings / 0 errors, 145 passed, 11 files (01). Main @ merge-base: 140 tests, 11 files (02). So tests went 140 → 145 (+5, all in `primitives.test.jsx`, 12 → 17), with the file count unchanged at 11. The build passes. |
| Docs: none | ✅ | No docs changed (03). |

## Scope / regression
- Scope: one file, `frontend/src/components/ui/primitives.test.jsx`, which is inside frontend-engineer's paths. No `ui/*.jsx`, `setup.js`, `package.json`, lockfile or `vite.config.js` changes, and no ticket, review or doc files leaked in (03). The existing tests are unchanged. The only edits to pre-existing lines are two import lines: `fireEvent` added to the RTL import, and `ScrollBar` added to the `./scroll-area` import. There is also one new `@radix-ui/react-scroll-area` import, an existing dependency, so no new dependency.
- Contracts: none touched (no events, API, schema or thresholds). No product code changed, so there is no runtime regression risk.

## PRD fit
This is test hardening only. It pins the visual and timing behaviour of the shared primitives behind the readable, accessible UI in Product PRD §7. It closes FE-0d's surviving mutants M35–M39 and nit 4, as the ticket asks.

## Findings
1. [spec] AC6 can't be executed in this cycle's sandboxes. The developer has no npm registry. This time QA's FE-0d-style harness was also refused by the permission layer, although FE-0d's QA ran it. pm-lead options:
   (a) re-run QA AC6 in a session where the harness (or a real `npm ci` + Vitest) is allowed;
   (b) explicitly accept AC6 on static reasoning plus CI green, and amend the ticket to say so.
   QA does not take option (b) on its own authority. The developer has nothing to fix.
2. [nit] The PR body still says "+86/−1" and lists the AC4 risk as "`user.hover`", which was the attempt-1 approach. The real diff is +88/−2 with `fireEvent.pointerMove`. pm-lead rewrites the body when raising, so this is not blocking.
3. [nit] AC4 relies on Radix opening on `pointermove`. If a future Radix upgrade moves the opening to `pointerenter`, the 350 ms assertion fails loudly, so the test can't pass silently. Acceptable as written. The code comment documents why.

## Missing tests
- None required by the ticket. Optional: a vertical `Separator` (`orientation="vertical"`) with caller `className`, and a horizontal `ScrollBar` without `className`, but both are outside FE-0g's mutant list.

## Why PENDING
CI is green and AC1–AC5 and AC7 are proven from the CI log and the test source. AC6 is the only gap, and it is a verification-environment gap, not a code defect. FAIL would send the PR back to a developer with nothing to fix, and PASS would approve an unverified AC. PENDING is normally used only while waiting on CI. Here it means: re-review once a mutation run is possible, or once pm-lead amends AC6 (finding 1).

## Hand-off
PENDING → re-review next cycle (AC6 run), or pm-lead decides on finding 1. The Jira ticket stays In QA. Labels unchanged.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

# QA report — FE-0g · PR #108 · round 2

**Verdict:** PASS
**Reviewed commit:** `35cecd32e27a56529d51162ffa83d8a3486526e0` (unchanged since round 1) · **Date:** 2026-11-21
**Ticket:** `agents/tasks/FE-0g.md` (Jira KAN-110) · **PRD:** Product PRD §7 (readable, accessible UI via FE-3/FE-4), FE-0d QA r1 "Missing tests" M35–M39 and nit 4

Evidence folder (round 2 files are `r2-*`): https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/49561a7011fb4ba2fd23f5631c29ac8403c53fb3/agents/reviews/FE-0g/evidence

Round 2 scope: round 1 was PENDING only because AC6 (mutation check) had no executed evidence. This round runs it. The head, CI, and AC1–AC5 and AC7 are as in round 1. I re-checked CI.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI @ 35cecd3 | success ([r2-00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/49561a7011fb4ba2fd23f5631c29ac8403c53fb3/agents/reviews/FE-0g/evidence/r2-00-ci-checks.png?raw=true)) |
| Python M0 unit tests | CI @ 35cecd3 | success (r2-00) |
| Frontend (lint, test, build) | CI @ 35cecd3, job 136770665327 | success (r2-00). The round-1 log (01) shows oxlint 0/0, `primitives.test.jsx (17 tests)`, 145/145 tests in 11 files, and the build passing |
| Agent ownership check · DB | CI @ 35cecd3 | success, success (r2-00). All 5 runs `completed/success` with `head_sha=35cecd3` |
| `npm ci` / Vitest locally | not run | The egress proxy denies registry.npmjs.org: `E403 … agent proxy: no rule or network setting allows this host`. A direct `npm ci` dies with "Exit handler never called" (the log shows ENOTFOUND) ([r2-01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/49561a7011fb4ba2fd23f5631c29ac8403c53fb3/agents/reviews/FE-0g/evidence/r2-01-local-npm-blocked.png?raw=true)). I did not retry the policy denial |
| AC6 harness control (unmutated head) | local, QA Chromium harness | 17/17 passed, 0 page errors. That matches CI's per-file count of 17 ([r2-02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/49561a7011fb4ba2fd23f5631c29ac8403c53fb3/agents/reviews/FE-0g/evidence/r2-02-ac6-harness-head-control.png?raw=true)) |
| AC6 mutants m1–m6 (+ FE-0d M36 variant) | local, QA Chromium harness | **7 killed / 0 survived / 0 invalid**, each with 16/17 passing ([r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/49561a7011fb4ba2fd23f5631c29ac8403c53fb3/agents/reviews/FE-0g/evidence/r2-03-ac6-mutants-head.png?raw=true)) |
| AC6 negative control: the same mutants vs main's test file | local, QA Chromium harness | **0 killed / 7 survived**, each 12/12 passing ([r2-04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/49561a7011fb4ba2fd23f5631c29ac8403c53fb3/agents/reviews/FE-0g/evidence/r2-04-ac6-mutants-vs-main-tests.png?raw=true)). So the kills come from FE-0g's new tests and nothing else |
| `make eval` | not run: no retrieval/answering change | n/a |

**Harness** ([r2-05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/49561a7011fb4ba2fd23f5631c29ac8403c53fb3/agents/reviews/FE-0g/evidence/r2-05-harness-sources.png?raw=true): full sources with sha256 and versions). This is the FE-0d harness (FE-0d/07), rebuilt and extended for what FE-0g's tests use:
- `fireEvent.pointerMove` (act-wrapped), `screen.getByTestId` and `screen.queryByRole`.
- `afterEach` scoped to its describe.
- `vi.useFakeTimers` / `useRealTimers` / `advanceTimersByTime`, a fake clock over `setTimeout`, `setInterval` and `Date.now`.

esbuild bundles the PR's real `ui/*.jsx` with real Radix `eb3a2b7` and sonner `v2.0.8` sources. Every Radix package, sonner, React, clsx and tailwind-merge matches `package-lock.json` (r2-05). Each mutant runs on a fresh copy of `frontend/src`, and the PR worktree is clean at `35cecd3` afterwards (r2-05). The script reports INVALID for a missing match or a build failure, and it prints each mutant's diff line next to its verdict.

This is a logic check in Chromium with shims, not the CI Vitest run. CI's Vitest log stays the pass/fail record for AC1–AC5 and AC7.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 ScrollBar (M35, M36) | ✅ | As in round 1 (04, 01). m1 and m2 now also fail the horizontal test (r2-03) |
| AC2 Toaster position (M37) | ✅ | As in round 1 (04, 01). m3 fails with `data-y-position=bottom (got top)` (r2-03) |
| AC3 Separator className (M38) | ✅ | As in round 1 (04, 01). m4 fails, `class="shrink-0 bg-border h-px w-full"` lacks `x-sep` (r2-03) |
| AC4 Tooltip default delay (M39) | ✅ | As in round 1 (04, 01). m5 (delay 0): the content is present at 250 ms. m6 (delay 700): `expected null instanceof HTMLElement` at 350 ms (r2-03) |
| AC5 unique toast text | ✅ | As in round 1 (05) |
| AC6 mutation check, one mutant per case | ✅ | Each mutant is applied with the ticket's wording and fails exactly one test, the intended one (r2-03): **m1** drop `className` from ScrollBar `cn` → *horizontal … plus the caller className*; **m2** delete the `orientation === "horizontal" && …` line → the same test (`x-bar` present, `h-2.5 flex-col border-t` absent); **m3** `position="top-center"` → *places the toast list bottom-right*; **m4** drop `className` from Separator `cn` → *merges the caller className …*; **m5** `delayDuration = 0` → *opens on hover after the 300 ms default delay, not before* (open at 250 ms); **m6** `delayDuration = 700` → the same test (closed at 350 ms). Extra: the FE-0d M36 class swap is also killed. With the source restored, all 17 tests pass in the harness (r2-02) and 145/145 pass in CI (01, r2-00). The AC allows "QA's harness (evidence file)" |
| AC7 CI lint + test, count up, files unchanged | ✅ | As in round 1: 140 → 145 tests, 11 → 11 files, oxlint 0 warnings (01, 02). Head unchanged, CI still green (r2-00) |
| Docs: none | ✅ | As in round 1 (03) |

## PRD fit
Unchanged from round 1. The tests now provably pin the ScrollBar, Toaster-position, Separator and Tooltip-delay behaviours behind Product PRD §7's accessible UI primitives, and they close FE-0d's surviving M35–M39.

## Findings
1. ~~[spec] AC6 can't be executed in this cycle's sandboxes~~. **Resolved**: the harness was allowed to run this round (r2-02..05), so pm-lead doesn't need to amend AC6. The general point still stands for future frontend tickets: with npm denied (r2-01), only QA's harness can run mutants. The FE-0d lesson already covers this.
2. [nit] (carried over) The PR body still says "+86/−1" and "`user.hover`". The real diff is +88/−2 using `fireEvent.pointerMove`. pm-lead rewrites the body when raising the PR.
3. [nit] (carried over) AC4 depends on Radix opening on `pointermove`. A future change to that fails loudly, not silently. Acceptable as written.

## Missing tests
- None required. The optional ones from round 1 still apply (vertical `Separator` + `className`, horizontal `ScrollBar` without `className`).

## Hand-off
PASS → pm-lead final review (Jira KAN-110 → PM review, which the orchestrator handles; QA did not touch Jira this round). Labels unchanged.

---

## PM final review (pm-lead) · 2026-11-21

**Verdict:** APPROVE · **Reviewed commit:** `35cecd32e27a56529d51162ffa83d8a3486526e0` · **Evidence:** all 14 images (round 1 `00`–`07`, round 2 `r2-00`–`r2-05`) opened

| Check | Result |
|---|---|
| PRD / product fit | Meets the goal. It closes FE-0d's surviving mutants M35–M39 and nit 4, so a later edit to the `ScrollBar`, Toaster position, `Separator` className or Tooltip delay of the shared primitives behind Product PRD §7's readable, accessible UI now fails a test. Tests only, no user-visible change, so no PRD status column to update. |
| Scope | Correct. One file, `frontend/src/components/ui/primitives.test.jsx`, +88/−2 (03; PR files API agrees). The −2 are import lines (`fireEvent`, `ScrollBar`), and the existing tests are untouched (04). No `ui/*.jsx`, `setup.js`, `package.json`, lockfile or `vite.config.js` change. No file overlap with the other open PRs: #104 (FE-3b: `setup.js`, `tokens.test.js`, `ReferencesStack*`, `App.jsx`, ...), #109 (FE-0i: `ui/badge.jsx`, `ui/badge.test.jsx`), #110 (`tests/test_kafka_client.py`). |
| AC1 | Proven: the test asserts every class the AC lists, including the `not` cases (04), and passes in CI (01: `primitives.test.jsx (17 tests)`). m1 and m2 are killed (r2-03). |
| AC2 | Proven: asserts the `<ol data-sonner-toaster>` has `data-y-position="bottom"` and `data-x-position="right"` (04), passes in CI (01), and m3 fails with "got top" (r2-03). |
| AC3 | Proven (04, 01). m4 killed (r2-03). |
| AC4 | Proven: no `delayDuration` prop, fake timers, closed at 250 ms and open at 350 ms, `vi.useRealTimers()` in `afterEach` (04). Passes in CI (01). `fireEvent.pointerMove` instead of `userEvent` fits the AC's "e.g." wording, and the attempt-1 hang under fake timers is explained in the test comment. m5 and m6 are killed (r2-03). |
| AC5 | Proven: `t-position` / `d-position` are used only by the new test (05). |
| AC6 | Proven by executed evidence, not reasoning: the harness control at head passes 17/17 (r2-02), m1–m6 plus FE-0d's M36 are 7 killed / 0 survived, each failing exactly the intended test (r2-03), and the negative control against main's test file leaves all 7 alive (r2-04). So the kills come from FE-0g's tests. The harness matches the lockfile versions and the PR worktree stayed clean (r2-05). The AC allows a QA harness result. The round-1 `[spec]` finding is resolved, so no ticket amendment is needed. This is a Chromium logic check, and CI stays the pass/fail record. |
| AC7 | Proven: head lint 0 warnings, 145 tests / 11 files, build OK (01) vs main `11c4696` 140 / 11 (02). I re-checked: all 5 check runs on `35cecd3` are `completed/success` (00, r2-00). |
| Docs | None needed (tests only). |
| QA nits | 2: PR body said "+86/−1" and "`user.hover`". Fixed in the rewritten description (+88/−2, `fireEvent.pointerMove`). 3: AC4 depends on Radix opening on `pointermove`. If Radix changes that, the test fails loudly rather than passing silently, so it's acceptable. |
| Note on this report | Round 1 was saved verbatim from a PR comment, and its evidence links are wrapped in stray backticks, so they won't render. The round-2 links and pinned folder links work. Left unedited as QA's record. |

**Follow-ups:** none required. QA's optional extra tests (vertical `Separator` + caller `className`, horizontal `ScrollBar` without `className`) are outside FE-0g's mutant list and don't need a ticket.

**Raised:** PR #108's description is rewritten with the per-AC Evidence section, and the PR is marked ready for review. Not merged; merging is Mahesh's call.
