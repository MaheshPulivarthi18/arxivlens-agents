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
