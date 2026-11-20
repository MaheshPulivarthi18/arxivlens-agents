<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/95#issuecomment-7050131742 (QA harness could not write report.md); role tag and footer removed. -->

QA report: FE-0d · PR #95 · round 1

**Verdict:** PASS
**Reviewed commit:** `76b851ce5f6d48ae77590d8ef52e8c6968b61304` · **Date:** 2026-11-20
**Ticket:** [agents/tasks/FE-0d.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/FE-0d.md) · **PRD:** Product PRD §7 (accessible, readable UI; principles 1 and 3 via FE-3/FE-4); FE-0b QA "Missing tests"
**Evidence:** [agents/reviews/FE-0d/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence) (pinned `e012695`)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136544779342 | pass |
| Python M0 unit tests | CI job 136544778877 | pass |
| Frontend (lint, test, build) | CI job [136544778476](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/44810285381/job/136544778476) (merge `1e7f1d1` of `76b851c` into main `230f617`) | pass: oxlint 0 warnings / 0 errors; `primitives.test.jsx (12 tests)` ✓; 8 files / 126 tests (main: 7 / 114); build ✓ |
| DB (migrate twice, HNSW plan + recall) | CI job 136544778465 | pass |
| Agent ownership check | CI job 136544778167 | pass |
| Ticket verification: `npm ci && npm run lint && npm test && npm run build` | not run locally: the egress proxy refuses `registry.npmjs.org` (403; direct access gives `ENOTFOUND`) | CI is the source of truth |
| Ticket verification: scope `git diff --name-only/--shortstat` | local | exactly `frontend/src/components/ui/primitives.test.jsx`, 199 insertions |
| QA harness logic check (headless Chromium, real Radix `eb3a2b7` + sonner `v2.0.8` sources at the lockfile versions, Vitest/RTL shims) | local | head 12/12; 39 single-edit mutants: 34 killed, 5 survived (outside the ACs) |
| `make eval` | n/a | tests only, no retrieval/answering change |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 Tooltip / Popover | ✅ | Tests at `primitives.test.jsx:53-79`: content is in `document.body` but not in the container; it has `font-sans bg-popover text-popover-foreground` plus the caller class; `ref.current` is that element. CI ✓ ([01](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/01-ac7-frontend-job-head.png?raw=true)). `` Mutants M13–M21 (no Portal, drop className/ref/font-sans, wrong token) are all killed ([06](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/06-mutants-all.png?raw=true)) ``` |
| AC2 Collapsible | ✅ | `:83-104`: with `defaultOpen` the text is present with `data-state="open"`; closed, `queryByText` returns null; `user.click` on the trigger opens it. M32 (forceMount), M33 (ignore defaultOpen) and M34 (trigger without toggle) are killed |
| AC3 ScrollArea | ✅ | `:108-123`: the viewport has `focus-visible:ring-inset` and `focus-visible:ring-ring` and no class matching `/ring-offset/`; the Root ref forwards and contains the viewport; the child is inside the viewport. M2 and M22–M26 are killed. ScrollBar is not asserted (see Missing tests) |
| AC4 Separator | ✅ | `:127-150`: default gives `role="none"` + `h-px w-full`; `decorative={false}` gives `role="separator"`; vertical gives `h-full w-px`, plus `aria-orientation="vertical"` when not decorative. M27–M31 are killed |
| AC5 Toaster | ✅ (see [spec] 1) | `:164-198`: the four variables are set; a `--normal-bg: red` override keeps the other three; `[data-description]` has `!text-muted-foreground`; the caller's `x-title` / `x-desc` are merged in alongside it; no theme prop. The variables are read on `<ol data-sonner-toaster>` inside the ref'd `<section>`, because sonner 2.0.8 puts `style` there and not on the ref target ([08](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/08-ac5-sonner-ref-vs-style.png?raw=true)). ```` M1 and M3–M12 are killed |
| AC6 Mutation check | ⚠ met by QA, not the developer | The developer did not run it (PR body: "not run locally … QA to run"), and the ticket has no Notes entry for it. QA ran both named mutants on copies of the PR head: **M1** (drop `sonner.jsx` `classNames.description` line) makes 2 tests fail; **M2** (`ring-inset` → `ring-offset-2`) makes the AC3 test fail ([05](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/05-ac6-named-mutants.png?raw=true)). ````` The PR worktree was clean afterwards ([07](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/07-harness-sources.png?raw=true)). `````` This is a logic check in Chromium with shims, not the CI Vitest run. Control: the harness at head passes 12/12, the same set as CI ([04](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/04-ac1-ac5-harness-head-control.png?raw=true)) ``````` |
| AC7 lint + test in CI, +1 test file | ✅ | Head: `Found 0 warnings and 0 errors`, `Test Files 8 passed (8)`, `Tests 126 passed (126)` ([01](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/01-ac7-frontend-job-head.png?raw=true)); ```````` main `230f617`: 7 files / 114 tests ([02](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/02-ac7-frontend-job-main-baseline.png?raw=true)); ````````` 5/5 checks green ([00](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/00-ci-checks.png?raw=true)) `````````` |
| Docs: none | ✅ | No README/CONTRIBUTING change needed (tests only) |
| Scope | ✅ | One file, 199 lines. The six `ui/*.jsx` files, `setup.js`, `package.json`, the lockfile and `vite.config.js` are untouched; there is no `button.jsx` import; the stubs live in the test file via `vi.stubGlobal`; there is no template-literal `new URL(` ([03](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/03-scope.png?raw=true ```````````)) |

## PRD fit
The tests pin the FE-0b primitives (portal + popover tokens, the inset focus ring, separator semantics, the toast description's contrast class) before FE-3/FE-4 build citations and refusal states on them. That serves the PRD §7 requirement for an accessible, readable UI without touching product code.

## Findings
1. [spec] AC5 says "the rendered sonner section (`ref` target) carries the inline variables". In sonner 2.0.8 the ref goes to `<section>`, but `style` lands on the inner `<ol data-sonner-toaster>`, which only renders once a toast exists ([08](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/08-ac5-sonner-ref-vs-style.png?raw=true)). ```````````` The test reads the variables on that list inside the ref'd section. This is the only correct reading, and the PR body discloses it. pm-lead: please amend the AC wording.
2. [spec] AC6 asks the developer to report mutant output in Notes, but the frontend sandbox has no npm registry, so the developer could not run Vitest at all. QA ran the mutants instead (05/06). Future frontend mutation ACs should either name QA's harness or accept a result QA ran.
3. [nit] There is no developer Notes entry in `agents/tasks/FE-0d.md` (Status is still "Ready"). Per AGENTS.md §1.4, record the AC6 hand-off and the AC5 deviation there.
4. [nit] `afterEach` wraps `toast.dismiss()` in `act` but does not wait for sonner's removal timers. The tests stay independent today because each uses unique toast text and `cleanup()` unmounts the Toaster. Keep the unique-text convention if more toast tests are added.

## Missing tests
None of these are required by the ACs. Each mutant survives at head ([06](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e01269580f278a113302d957c839f4bce145b172/agents/reviews/FE-0d/evidence/06-mutants-all.png?raw=true)): `````````````
- M35/M36: `ScrollBar` (named in AC3's title). Its caller `className` merge and its horizontal-orientation classes are never rendered or asserted.
- M37: `Toaster position="bottom-right"`. The FE-0b smoke facts verified `y=bottom x=right`, but nothing asserts `data-y-position` / `data-x-position` on the list.
- M38: `Separator` caller `className` merge.
- M39: `Tooltip` default `delayDuration = 300`.

## Hand-off
PASS → pm-lead final review.



---

## PM final review (pm-lead) · 2026-11-21

**Verdict:** APPROVE · **Reviewed commit:** `76b851ce5f6d48ae77590d8ef52e8c6968b61304` · **Evidence:** all nine images at `e012695` opened

| Check | Result |
|---|---|
| PRD / product fit | Meets the goal: one test file pins the FE-0b primitives (portal + popover tokens, inset focus ring, separator semantics, the muted toast description from the F3 fix) before FE-3/FE-4 build citations and refusal states on them. This protects PRD §7's readable, accessible UI. No user-visible change, so no PRD status column to update. |
| Scope | Correct. One new file, +199 lines (03); none of the six `ui/*.jsx`, `setup.js`, `package.json`, the lockfile or `vite.config.js` touched; no `button.jsx` import (03's "button imported?" hit is a `getByRole('button')` query, not an import); stubs scoped to the file. |
| AC1–AC4 | Proven: CI Frontend job lists `primitives.test.jsx (12 tests)` passing (01). The QA harness with real Radix sources shows one passing test per AC (04), and mutants M13–M34 that break each AC are all killed (06). I read the test file at head: assertions match the AC text. |
| AC5 | Proven, with spec wording fixed: 08 shows sonner 2.0.8 sends `ref` to `<section>` and `style` to `<ol data-sonner-toaster>`. The test asserts on that list inside the ref'd section. M1, M3–M12 killed (06). Ticket AC5 amended (QA `[spec]` 1). |
| AC6 | Accepted as met by QA (05: M1 → 2 failing, M2 → 1 failing; 07: harness at lockfile versions, worktree clean). The AC was there to show the tests catch regressions, and QA's run shows that. Who ran it doesn't change the result. Ticket AC6 amended to allow a QA-run result when npm is blocked (QA `[spec]` 2). This is a Chromium logic check, not a Vitest run. CI is still the pass/fail for AC1–AC5, and the mutants only measure test strength. |
| AC7 | Proven: head 8 files / 126 tests, lint 0 warnings, build OK (01) vs main `230f617` 7 / 114 (02). 5/5 checks green (00). |
| Docs | None needed (tests only). |
| QA nits | 3: recorded in the ticket Notes by pm-lead. 4: guidance for future toast tests, recorded in Notes. |
| Note on this report | The QA section above was saved verbatim from a PR comment, and its evidence links are wrapped in stray backticks, so they won't render as links. The pinned evidence folder link at the top works. Left unedited as QA's record. |

**Follow-ups:** FE-0g (Backlog, frontend, P3): add asserts that kill the surviving mutants M35–M39 (`ScrollBar` className merge + horizontal classes, Toaster `bottom-right` `data-y/x-position`, Separator caller className, Tooltip `delayDuration` 300).

**Raised:** PR #95 description rewritten with the per-AC Evidence section, marked ready for review, label `ready-to-merge`. Not merged; that's Mahesh's call.
