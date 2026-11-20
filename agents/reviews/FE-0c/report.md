<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/85#issuecomment-7040949587 (2026-11-20T13:38:20Z); QA's harness could not write report.md (sprint.md Step 5). -->

[qa-reviewer] # QA report — FE-0c · PR #85 · round 1

**Verdict:** PASS
**Reviewed commit:** `969c4fb4e335be8e113eb20ed97063751f4c2846` · **Date:** 2026-11-20
**Ticket:** [agents/tasks/FE-0c.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/FE-0c.md) · **PRD:** Product PRD §7 (accessible, readable UI); FE-0 QA "Missing tests"; FE-0 design §AC5
**Reviewer:** qa-reviewer (independent; the developer's build note was not used as evidence)

Evidence pack (commit `e527bef`): [evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence) · reproducible QA harness: [checks/](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/checks) (`run.mjs`, `mutate.sh`, `ac6.sh`, `extra.sh` + shims)
_Provenance: QA's harness refused to write `report.md`; this comment is the full report, to be saved verbatim as `agents/reviews/FE-0c/report.md`._

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136313918106 | pass |
| Python M0 unit tests | CI job 136313917601 | pass |
| DB (migrate twice, HNSW plan + recall) | CI job 136313917869 | pass |
| Frontend (lint, test, build) | CI job 136313918021 (merge `ea24147` = `969c4fb` into current main `c37d27c`) | pass: `Found 0 warnings and 0 errors.`, `✓ src/lib/theme.test.js (35 tests)`, `✓ src/components/ThemeToggle.test.jsx (4 tests)`, `Tests 58 passed (58)`, `✓ built in 760ms` ([01](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence/01-ac7-ci-frontend-job.png?raw=true)) `` |
| Agent ownership check | CI job 136313918049 + local `ownership-check.sh` | pass: `Ownership OK for role=frontend (285 changed lines)` ([02](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence/02-scope-diff.png?raw=true)) ``` |
| Ticket verification (`npm ci && npm run lint && npm test && npm run build`) | not run locally: registry.npmjs.org unreachable, `npm ci --offline` → `ENOTCACHED`. CI is the source of truth. | — |
| QA stand-in run of both new test files | local: Node 22 `--experimental-webstorage` (real `Storage.prototype`) + minimal `documentElement` for `theme.test.js`; headless Chrome with real react/react-dom 19.2.8 (Radix dropdown, `Button`, lucide stubbed; Testing Library replaced by a small shim) for `ThemeToggle.test.jsx` | 35/35 + 4/4 ([03](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence/03-ac1-ac5-qa-standin-run.png?raw=true)) ```` |
| `make eval` | not applicable: tests only, no retrieval/answering change | — |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 drift guard | ✅ | `theme.test.js:12-17,58-68`: reads `index.html` relative to the test file, extracts the inline classic script, compares its `DEFAULT_THEME` literal and every `localStorage.getItem('…')` key to the `theme.js` imports; no `"dark"`/`"system"` hard-coded as the expected value. Mutant (a) and QA mutant (g, key changed in index.html only) killed; the FE-3 AC8 control (both files flipped to `system`) **survives**, as required ([04](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence/04-ac6-mutants-a-e.png?raw=true), ````` [05](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence/05-qa-extra-mutants.png?raw=true)). `````` Green in CI ([01](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence/01-ac7-ci-frontend-job.png?raw=true)). ``````` |
| AC2 pre-paint agreement, 14 combos | ✅ | `theme.test.js:71-108`: 7 stored values × 2 OS via `it.each`, script run in `vm.runInNewContext` vs `applyTheme(getStoredTheme())`, from both `.dark` start states; `covers all 14 combinations` pins the count. QA mutants (f) add-only `.dark`, (k) no try/catch around `getItem`, (l) ignore OS in system mode: all killed ([05](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence/05-qa-extra-mutants.png?raw=true)). ```````` |
| AC3 `theme.js` units | ✅ | `theme.test.js:110-186`: getStoredTheme valid/missing/invalid/empty/wrong-case/throwing; setStoredTheme persist / invalid ignored (`setItem` not called) / throwing swallowed; resolveTheme 3×2; watchSystemTheme delivery + unsubscribe + later change not delivered; addListener/removeListener fallback. Mutants (e), (i) Safari-fallback cleanup no-op, (j) invalid value written: all killed. |
| AC4 ThemeToggle OS change | ✅ | `ThemeToggle.test.jsx:44-59`: stored `system`, controllable `change` event, no user action; name `Theme: System (dark)` → `Theme: System (light)`, `.dark` off, `colorScheme` light, and back. Mutant (d) killed (`expected true toBe false`). Passes under real vitest/jsdom/Radix in CI. |
| AC5 cross-tab | ✅ | `ThemeToggle.test.jsx:61-88`: `StorageEvent` for `arxivlens-theme` → `Theme: Light`, `.dark` removed; other key → still `Theme: Dark` with `.dark` (the stored value is changed underneath, so the negative test is meaningful). Mutant (c) and QA mutant (h, handler ignores the key) killed. |
| AC6 mutants (a)–(e) | ✅ (QA re-ran independently) | All five killed, each in a fresh copy of `969c4fb`, never pushed. Failing tests ([04](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence/04-ac6-mutants-a-e.png?raw=true)): ````````` (a) `uses the same DEFAULT_THEME as theme.js` + 4 agreement rows (OS light); (b) `reads the same storage key as theme.js` + 3 agreement rows + `in System mode follows an OS change…` + `follows a theme change made in another tab`; (c) `follows a theme change made in another tab`; (d) `in System mode follows an OS change dark -> light without user action`; (e) `watchSystemTheme calls back on change and its cleanup unsubscribes` + `removes its OS listener on unmount`. Caveat: mutants ran in QA's stand-in harness, not real vitest/jsdom/Radix (not installable offline). |
| AC7 CI Frontend green, both files listed | ✅ | [01](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence/01-ac7-ci-frontend-job.png?raw=true); `````````` all 5 check runs `completed/success` on `969c4fb` ([00](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence/00-ci-checks.png?raw=true)). ``````````` |
| Docs | ⚠ nit 1 | `frontend/README.md` says test files are `src/**/*.test.jsx`; the new `theme.test.js` is `.js`. |

**Scope:** the diff is exactly two added files, `frontend/src/lib/theme.test.js` (187) and `frontend/src/components/ThemeToggle.test.jsx` (98). No change to `theme.js`, `index.html`, `ThemeToggle.jsx`, `package.json` or the lockfile; no new dependency; no ticket/review/doc files in the PR ([02](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/evidence/02-scope-diff.png?raw=true)). ```````````` 285 lines vs the ~150 estimate is under the 400-line limit; the extra is the tables.

## PRD fit
Closes the FE-0 QA "Missing tests" item. The duplicated theme logic (pre-paint script vs `theme.js`) is now guarded in CI, so FE-3 AC8's default flip has to change both files together: a lockstep flip stays green (control mutant) and a one-sided flip fails. Supports PRD §7 (readable UI, no theme flash) without changing product behaviour.

## Findings
1. [nit] `frontend/README.md:14` says test files are `src/**/*.test.jsx`. With `src/lib/theme.test.js` added that is no longer accurate (vite `include` is `src/**/*.test.{js,jsx}`). The ticket's Docs line allows a README touch "only if it lists test files". A one-word fix can go in the next frontend PR.
2. [nit] The PR description's AC1 bullet says the file is read "via `new URL('../../index.html', import.meta.url)`". The code actually does `new URL('../../index.html', testFile)` + `fileURLToPath`, with `testFile = import.meta.url`. The "Not verified / risks" section explains why. The verification table also quotes `282 changed lines`, but the current ownership check reports 285.
3. [spec] AC1 prescribes the literal `new URL('../../index.html', import.meta.url)`. According to the PR description, Vite's asset transform rewrites that to an http URL under jsdom. QA did not inspect the failed attempt-1 job. The implementation keeps the intent of the AC (a path relative to the test file, not the cwd). pm-lead may want ACs like this to state the intent rather than the syntax.

## Missing tests (optional, not required by the ACs)
- Pre-paint with no `window.matchMedia` (the `!!window.matchMedia` branch for old browsers). QA's FE-0 `prepaint.mjs` checked this, but no committed test covers it.
- `systemPrefersDark()` when `matchMedia` is absent.

## Not verified
- The ticket's local `npm ci` / `npx vitest run` (registry blocked). Results for the unmutated code under real vitest come only from CI.
- The mutants were not run under real vitest + jsdom + Radix. QA's runs used the stand-in harness in [checks/](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e527bef2853c29642b82e53158279ad409573694/agents/reviews/FE-0c/checks). The ThemeToggle assertions depend only on the trigger's `aria-label` and `documentElement`, which the stubs render faithfully, so QA rates the risk as low.
- No UI screenshots: this PR only adds tests and changes no rendered UI.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM final review (pm-lead) — round 1

**Verdict: APPROVE** · reviewed head `969c4fb4e335be8e113eb20ed97063751f4c2846` · 2026-11-20

**What I checked**
- Ticket `agents/tasks/FE-0c.md` AC1–AC7 + Docs line, FE-0 QA "Missing tests" and FE-0 design §AC5, Product PRD §7.
- Diff (`gh api …/pulls/85/files`): exactly two added files, `frontend/src/lib/theme.test.js` (+187) and `frontend/src/components/ThemeToggle.test.jsx` (+98). No source, `index.html`, `package.json` or lockfile change. Scope matches the ticket; 285 lines is over the ~150 estimate but under 400, and the extra is the 14-row agreement table and the unit tables the ACs ask for.
- Every evidence file at `e527bef`:
  - `00-ci-checks.png`: all 5 check runs on `969c4fb` completed/success. Proves AC7 (CI part).
  - `01-ac7-ci-frontend-job.png`: Frontend job 136313918021 log: oxlint `Found 0 warnings and 0 errors.`, `✓ src/lib/theme.test.js (35 tests)`, `✓ src/components/ThemeToggle.test.jsx (4 tests)`, `Tests 58 passed (58)`, build step reached (`✓ built in 760ms` in the `.txt`). Proves AC7 and that AC1–AC5 pass under real vitest + jsdom + Radix.
  - `02-scope-diff.png`: 2 added files, `Ownership OK for role=frontend (285 changed lines)`. Proves scope.
  - `03-ac1-ac5-qa-standin-run.png`: every test name for AC1 (drift guard ×3), AC2 (14 rows + count guard), AC3 (getStoredTheme/setStoredTheme/resolveTheme 3×2/watchSystemTheme + fallback), AC4/AC5 (ThemeToggle ×4). Names map 1:1 to the ACs.
  - `04-ac6-mutants-a-e.png`: mutants (a)–(e), each with its diff and failing test names: all KILLED. Proves AC6.
  - `05-qa-extra-mutants.png`: the FE-3 AC8 control (both files flipped to `system`) SURVIVES, so the guard compares the two files rather than hard-coding a default (AC1's key requirement); extra mutants f–l killed.
- AC1's syntax deviation: the code reads `fileURLToPath(new URL('../../index.html', testFile).href)` with `testFile = import.meta.url`, not the literal `new URL('../../index.html', import.meta.url)` the AC prescribed. The intent (path relative to the test file, not cwd) is kept, and the literal form is rewritten to an http URL by Vite under jsdom (attempt-1 CI failure). Accepted; the AC wording was my error (QA finding 3 [spec]).

**Product fit:** Closes the FE-0 QA "Missing tests" gap. The pre-paint script and `theme.js` are now guarded in CI, so FE-3b AC8's default flip must change both files together; the ThemeToggle OS-follow and cross-tab behaviours (PRD §7 readable UI, no wrong-theme flash) are pinned. No user-visible change, so no PRD status column moves.

**Residual risk accepted:** the AC6 mutants ran only in QA's stand-in harness (real vitest/jsdom/Radix not installable offline). The unmutated tests pass under real vitest in CI, and the ThemeToggle assertions use only the trigger's `aria-label` and `documentElement`, which the stand-in renders faithfully. Low risk.

**QA findings, decided**
1. [nit] `frontend/README.md:14` says tests are `src/**/*.test.jsx` (now also `.test.js`). Not blocking: the glob in `vite.config` already includes `.js` (CI ran both files), the README line is contributor-facing and one word. → Backlog follow-up (frontend, P3): fold into the next frontend PR that edits `frontend/README.md`.
2. [nit] Stale PR description (AC1 bullet quoting `import.meta.url` directly; `282` lines). Fixed by pm-lead in the PR description rewrite (now 285, and the AC1 bullet describes the `testFile` + `fileURLToPath` form).
3. [spec] AC1 prescribed syntax instead of intent. → pm-lead lesson added (`agents/memory/lessons.md`).
- Optional missing tests (pre-paint and `systemPrefersDark()` with no `window.matchMedia`) → same Backlog follow-up as 1 (P3, not required by any AC).

**Next:** PR #85 raised (ready for review) with the evidence in its description → Mahesh reviews and merges.
