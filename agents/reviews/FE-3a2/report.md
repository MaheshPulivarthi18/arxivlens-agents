<!-- Provenance: saved verbatim by the orchestrator from PR #91 comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/91#issuecomment-7048721731 (QA harness could not write report.md), cycle 2026-11-20T19:00Z -->

[qa-reviewer] QA report — FE-3a2 · PR #91 · round 1

**Verdict:** PASS
**Reviewed commit:** `e7dc3c003802acf65d43f0b99acce634df6aabca` · **Date:** 2026-11-21
**Ticket:** [`agents/tasks/FE-3a2.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/FE-3a2.md) (KAN-93) · **PRD:** Product PRD UI-1, QA-4, QA-5, §7 principles 1–2; ADR-0003, ADR-0014; design `docs/design/FE-3.md` §Test plan (App.test.jsx rows)
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136509370761 | pass ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/00-ci-checks.png?raw=true)) `` |
| Python M0 unit tests | CI job 136509370446 | pass |
| Frontend (lint, test, build) | CI job 136509370552, merge ref `f1ad59b` = head + current main `230f617` | pass: `Found 0 warnings and 0 errors.`, `src/App.test.jsx (7 tests)`, `Test Files 8 passed (8)`, `Tests 121 passed (121)`, `built in 806ms` ([02](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/02-ac7-frontend-job-head.png?raw=true)) ``` |
| Agent ownership check | CI job 136509370498 | pass |
| DB (migrate twice, HNSW plan + recall) | CI job 136509369579 | pass |
| Main baseline (AC7) | CI job 136502158010 at `230f617` | `0 warnings`, `Test Files 7 passed (7)`, `Tests 114 passed (114)` ([03](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/03-ac7-frontend-job-main-baseline.png?raw=true)) ```` |
| Ticket verification (`npm ci && npm run lint && npm test && npm run build`) | not run locally: the sandbox can't reach the npm registry, and the developer worktree's `node_modules` is an empty skeleton (0 files), so there's no vitest/jsdom/testing-library | CI is the source |
| Mutation run (AC6) | **not executed**: no vitest/jsdom/testing-library in the sandbox. The verdicts below are reasoned from the real source at the head and checked against the CI pass | see AC6 table |
| `make eval` | not run: test-only change, no retrieval/answering code touched | n/a |

## Scope
One file changed: `frontend/src/App.test.jsx` (+202 / −0, new). There is no production code and no fixture change, and the file is inside the frontend-engineer's paths (ownership CI green). Open PRs #92 (`ui/button.jsx`, `ui/button.test.jsx`), #93 and #94 don't touch this file ([01](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/01-scope-files.png?raw=true)). ````` Out-of-scope items (tooltip, token/class asserts, `App.jsx`) are untouched. No tickets, reviews or docs leaked into the PR.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 refusal A / C, unscoped `document.body.textContent` has no `/verified/i` | ✅ | `App.test.jsx:79-95`: two separate tests. `stubFetch({ quick: refusalA })` and `stubFetch({ quick: refusalC })`, each waits for `findByRole('status', { name: /no answer shown/i })`, then the unscoped body assert. The CI log names both as passing ([02](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/02-ac7-frontend-job-head.png?raw=true)). `````` Every `verif` string left in non-test source is a comment, an object key, "Verification" or "Verify", and none match `/verified/i` in rendered text ([04](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/04-ac1-refusal-no-verified.png?raw=true)). ``````` Caveat: finding 2. |
| AC2 refusal B calm: Toast only ever `message === ''` (all calls), no `role="alert"`, "Retrieved passages" heading visible, `fetch` called once | ✅ | `App.test.jsx:65-68` (`expectNoToastMessage` asserts at least one call, then checks **every** call) and `:97-111`. A `setTimeout(0)` inside `act` lets any follow-up request settle before the asserts. The fixture's missing `synthesis_available` matches the server: `rag.go:222-225` sets it only when `RefusalReason == ""` ([05](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/05-ac2-refusal-b-calm.png?raw=true)). ```````` In CI, 7 of 7 tests pass (`App.test.jsx (7 tests)`, 0 failures). |
| AC3 early refusal: explicit asserts, discover POST body `{ query }`, no `article`, no "Clinical Literature Synthesis" | ✅ | `App.test.jsx:113-140`: exact text "Relevance Protection Activated:", a `CODE` element whose textContent is `"<question>"`, and the button found by its exact name `⚡ Search arXiv for "<q>" & Index`. Exactly one discover call, `init.method === 'POST'`, `JSON.parse(body)` toEqual `{ query: QUESTION }`. `queryAllByRole('article')` has length 0 (meaningful: `ReferencesStack.jsx` cards have `role="article"`), and the synthesis title is absent. Also checks that the re-run after indexing shows the banner again ([06](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/06-ac3-early-refusal.png?raw=true)). ````````` CI pass. |
| AC4 refusal A: Tab to "Read the 2 retrieved passages", Enter → `document.activeElement` is `#references-heading` | ✅ | `App.test.jsx:142-158`: a bounded Tab loop (60), an assert that the link is focused, `{Enter}`, then `activeElement === getElementById('references-heading')`. Production: `SynthesisView.jsx:29-36` `focusEvidence` plus `ReferencesStack.jsx:37-38` `tabIndex={-1}` ([07](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/07-ac4-focus-evidence.png?raw=true)). `````````` The CI log names it passing (396 ms), which also settles the PR's stated risk (user-event v14 Enter → click on `a[href]`). |
| AC5a quick quoted + deferred full: quoted + "Writing a summary…", then synthesized shown, quoted and status gone | ✅ | `App.test.jsx:162-180`: the full stage is a `deferred()` promise. Asserts quoted text + status, no synthesized text, `fetch` ×2, then resolves inside `act`: synthesized shown, quoted and status null ([08](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/08-ac5-two-stage.png?raw=true)). ``````````` CI pass. |
| AC5b full → `refusalC`: quoted stays, no panel, no toast | ✅ | `App.test.jsx:182-201`: waits for the status to clear (same update as the swap decision, `App.jsx:110-117`), then quoted present, no "No answer shown" text or status, `expectNoToastMessage()`. CI pass. |
| AC6 negative check per AC, recorded in the PR body (reasoned if npm unavailable) | ⚠ met in substance, not in place | The developer's per-AC mutant reasoning is in the ticket Notes (2026-11-20 Build). The PR body only says "AC6 mutant reasoning in ticket Notes (QA to run real mutants)" ([09](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/09-ac6-pr-body.png?raw=true)). ```````````` QA's independent reasoned table is below. Every AC-named mutant is killed. See finding 1. |
| AC7 CI frontend green; lint warnings ≤ main; one more test file than main | ✅ | Head: 0 warnings, 8 files / 121 tests, build OK. Main `230f617`: 0 warnings, 7 files / 114 tests ([02](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/02-ac7-frontend-job-head.png?raw=true), ````````````` [03](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/03-ac7-frontend-job-main-baseline.png?raw=true)). `````````````` Δ = +1 file (`src/App.test.jsx`), +7 tests. |
| Docs: none expected | ✅ | No behaviour or command change. |

Harness requirements from Scope: `fetch` is set per test via `vi.stubGlobal` and restored with `vi.unstubAllGlobals()` in `afterEach`. Routing is by URL plus the `/v1/ask` body (`quick === true` vs full) and `/v1/papers/discover`. Any other URL, or a stage the test didn't supply, goes into `unexpected`, and `afterEach` asserts it is empty (`:27-47`, `:70-76`). `Toast` is mocked with `vi.hoisted` + `vi.mock` (`:9-15`). There's no `new URL(…, import.meta.url)` in the file.

### AC6: QA mutant table (reasoned against the head source; not executed)
| # | Mutant (production edit) | Test that must fail | Why (source lines) | Verdict |
|---|---|---|---|---|
| M1 | HeroSearch subtitle back to a "…verified…" sentence | AC1 A and C | HeroSearch renders in every search state; unscoped body text matches `/verified/i` | killed |
| M2 | `unverified` chip text → "Unverified" (citations.js) | AC1 A and C | refusalA/C both contain `status: 'unverified'` citations and ReferencesStack renders chips in refusal mode | killed |
| M3 | Refusal subtitle/heading copy says "verified" (SynthesisView/ReferencesStack) | AC1 A and C | rendered in refusal mode | killed |
| M4 | `showToast(...)` on a refusal in `handleSearch` | AC2 | `toastSpy` then gets a non-empty `message` (cleared only after 2800 ms) | killed |
| M5 | Drop `if (!quick.synthesis_available) return` (`App.jsx:104`) | AC2 (and, through the `full` handler, also AC1) | a second `/v1/ask` (full) fires synchronously after `finally`; `toHaveBeenCalledTimes(1)` fails and `unexpected` gets `ask full` | killed |
| M6 | Refusal panel `role="status"` → `role="alert"` | AC1, AC2, AC4 | `findByRole('status', {name: /no answer shown/i})` times out; AC2 also asserts there's no `alert` | killed |
| M7 | Discover body `{ q: … }` / no POST / method GET | AC3 | `toEqual({ query })`, `method === 'POST'`, exactly 1 call | killed |
| M8 | Remove the early-refusal check (`App.jsx:88-91`) | AC3 | no banner; `findByText('Relevance Protection Activated:')` times out | killed |
| M9 | Keep the banner but drop the `return` (`App.jsx:90`) | AC3 | `setSearchResult(earlyRefusal)` renders SynthesisView's "Clinical Literature Synthesis" | killed |
| M10 | `focusEvidence` body emptied (keep `preventDefault`) | AC4 | focus stays on the link | killed |
| M11 | `onClick={focusEvidence}` removed (plain fragment nav) | AC4 | jsdom fragment navigation updates the URL and doesn't focus the target, so focus stays on the link. The jsdom behaviour is reasoned, not executed | killed (reasoned) |
| M12 | Heading loses `tabIndex={-1}` | AC4 | `focus()` on a non-focusable `h3` is a no-op in jsdom | killed |
| M13 | Never `setSynthesis('writing')` | AC5a, AC5b | `findByText(WRITING)` times out | killed |
| M14 | Drop the swap (`App.jsx:110-113`) | AC5a | the synthesized text never appears | killed |
| M15 | Drop the `answer_kind === 'synthesized'` guard | AC5b | refusalC replaces the quoted answer: `getByText(QUOTED)` throws and the panel appears | killed |
| M16 | Drop the `finally` → `setSynthesis('idle')` | AC5a, AC5b | the status stays; `queryByText(WRITING)` is non-null / `waitFor` times out | killed |
| M17 | `showToast` on a full-stage refusal | AC5b | `expectNoToastMessage` | killed |
| M18 | Drop the stale-search guards `seq !== searchSeq.current` (`App.jsx:87, 108`) | none | no test runs two overlapping searches | **survives** (not an AC; see Missing tests) |
| M19 | Toast with text containing "verified" shown on refusal A or C only | none | the Toast mock renders `null`, so the text is not in `document.body` | **survives** (finding 2) |

## PRD fit
This serves principle 1 ("evidence first": on a refusal the passages stay visible and one link moves focus to them) and principle 2 ("honest refusals": no "verified" claim, no error toast, no second writing request). It does so as CI regression tests on the real `<App>`, replacing FE-3a's one-off browser check. The two-stage tests pin the ADR-0003/QA-8 behaviour that the quoted, verified evidence is never replaced by a refused written answer.

## Findings
1. [nit] AC6 asks for the negative check "recorded in the PR body". The PR body only points to the ticket Notes ([09](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4df0fb063154a9d080afeb4442cb6067c688bde6/agents/reviews/FE-3a2/evidence/09-ac6-pr-body.png?raw=true)). ``````````````` The content exists and QA's table above confirms it, so this is a location problem, not a missing check. **pm-lead:** when you raise the PR, paste the per-AC negative-check list (developer Notes + the table above, marked "reasoned, not executed") into the PR description.
2. [nit] AC1 says "whole tree, unscoped", but `vi.mock('./components/Toast')` renders `null`. Any toast text is therefore missing from `document.body.textContent`, and the AC1 tests don't call `expectNoToastMessage()`. Mutant M19 (a "…verified…" toast on refusal A/C) survives. Fix in a follow-up: have the mock render `<output>{props.message}</output>`, or call `expectNoToastMessage()` in both AC1 tests.
3. [nit] PR #92 (FE-0f) changes `ui/button.jsx`, which `<App>` renders in the AC4 Tab path (Navbar, HeroSearch). There's no file overlap, but whichever PR merges second should get its Frontend job re-run on the new main (tests that exercise another PR's files).

## Missing tests (none required by this ticket; candidates for a follow-up)
- A newer search discards both stages of an older one (`App.jsx:87`, `:108`; M18). Hold search 1's full stage on a deferred, start search 2, resolve 1, and assert search 2's result stays.
- Full-stage network failure (`App.jsx:114-117`): the status clears, the quoted answer stays, no toast.
- A refusal with zero citations at App level (no link; panel still `role="status"`). This is covered at component level in FE-3a, not in `<App>`.
- Discover failure (`data.error` / non-ok): a `❌` toast and no re-run search.

## Hand-off
PASS → pm-lead final review. The CI evidence is complete, and the mutant verdicts are reasoned against the real source, not executed (no vitest/jsdom in the QA sandbox). Findings 1–3 are non-blocking.

Note: the QA harness refused to write `agents/reviews/FE-3a2/report.md`; this comment is the full report, for the orchestrator to save verbatim with a provenance note. Evidence commit: `4df0fb063154a9d080afeb4442cb6067c688bde6` in arxivlens-agents.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM review (pm-lead) — round 1 · 2026-11-21

**Verdict:** APPROVE · **Reviewed head:** `e7dc3c003802acf65d43f0b99acce634df6aabca` · **Evidence commit:** `4df0fb0`

- **PRD fit:** Every App-level row of `docs/design/FE-3.md` §Test plan (AC1, AC2, AC4, AC6, AC6 two-stage, which were moved out of FE-3a by PM decision change 5) is now a CI regression test on the real `<App>`. That pins Product PRD §7 principle 1 (on a refusal the passages stay and one link moves focus to them) and principle 2 (no "verified" claim, no error toast, no writing stage after a refusal). It also pins the ADR-0003/0014 two-stage rule that a refused written answer never replaces the quoted one. UI-1 and QA-5 are already ✅ and QA-4 stays ◐ (AI-2 / FE-3b), so no PRD status change is needed.
- **Scope:** One new test file, `frontend/src/App.test.jsx` (+202), as the ticket asked. No production or fixture change, nothing out of scope (no tooltip or token asserts, no `App.jsx` edits), and no overlap with open PRs #92–#94.
- **Evidence:** I opened all 10 PNGs and their 10 `.txt` twins. Each one shows real command output pinned to `e7dc3c0` (or to main `230f617` for the baseline) and proves its row. AC1–AC5 are backed by the test source plus the production lines they pin and the green CI Frontend job (`App.test.jsx (7 tests)`, 121/121). AC7 compares head and main: 0 warnings each, 8 vs 7 files. The only ⚠ is AC6 "in place". AC6 allows "a reasoned note per AC if npm is unavailable", so reasoned mutants satisfy it. They're labelled **reasoned, not executed** everywhere.
- **Docs:** none expected, none needed.

**QA nits handled:**
1. Nit 1 (AC6 list not in the PR body): fixed by pm-lead. The PR description now carries the merged developer + QA mutant table (M1–M19), marked "reasoned, not executed", with M18/M19 shown as surviving.
2. Nit 2 (Toast mock renders `null`, so M19 survives in AC1): Backlog line for frontend (P2), together with QA's "Missing tests" (stale-search discard M18, full-stage network failure, zero-citation refusal, discover failure). Not blocking: AC1 as specced ("`document.body.textContent`") is met. The toast-text gap is my spec's blind spot (`[spec]`-like), and the follow-up closes it.
3. Nit 3 (#92 `ui/button.jsx` sits on the AC4 Tab path): recorded in the PR risks. Whichever of #91/#92 merges second gets its Frontend job re-run on the new main.

**Raised:** PR #91 description rewritten (Evidence table with 10 embedded images pinned to `4df0fb0`, CI per check run, the AC6 table, QA + PM verdicts). Marked ready for review and labelled `ready-to-merge`. Jira → Ready to merge is left to the orchestrator.
