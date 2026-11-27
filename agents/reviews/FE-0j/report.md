# QA report: FE-0j · PR #125 · round 1

**Verdict:** PASS
**Reviewed commit:** `79da23ed9e119f2a3eca1c21db20527c0f7faa88` · **Date:** 2026-11-27
**Ticket:** `agents/tasks/FE-0j.md` · **PRD:** Product PRD §7 (readable, accessible UI); follow-up from FE-0i QA r1 nit 1

Evidence base URL: `https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/`.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 137066033614 | pass (no Go change) |
| Python M0 unit tests | CI job 137066033741 | pass (no Python change) |
| DB (migrate twice, HNSW plan + recall) | CI job 137066033202 | pass (no schema change) |
| Frontend (lint, test, build) | CI job 137066033508 | pass: oxlint 0 warnings / 0 errors, 12 files / 156 tests, build ok ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/02-ac3-ci-frontend-head-vs-main.png?raw=true)) |
| Agent guardrails (ownership) | CI job 137066033663 + local re-run | pass, `Ownership OK for role=frontend (10 changed lines)` ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/00-ci-checks.png?raw=true), [01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/01-scope-diff.png?raw=true)) |
| Ticket verification `npm ci && npm run lint && npm test && npm run build` | local | not run locally: `npm ci` fails in the sandbox because the registry is blocked (`npm error Exit handler never called!`, [05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/05-local-npm-ci.png?raw=true)). I used the CI Frontend log instead |
| `git diff origin/main --name-only` | local | exactly `frontend/src/components/ui/badge.test.jsx` ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/01-scope-diff.png?raw=true)) |
| Mutation check (AC2) | local QA harness (shim Vitest/RTL, real react-dom 19.2.8 + cva 0.7.1 + tailwind-merge 3.6.0 in headless Chromium) | M0–M5 all killed by the head tests, and both controls pass ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/03-ac2-mutation-run.png?raw=true)) |
| `make eval` | n/a | not run: test-only frontend change, no retrieval/answering code touched |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 `<Badge className="px-2 py-0">` has `px-2`/`py-0` and not `px-2.5`/`py-0.5` | ✅ | `badge.test.jsx:31-37` (`lets a caller className override conflicting default padding`) asserts `toHaveClass('px-2','py-0')`, `not.toHaveClass('px-2.5')` and `not.toHaveClass('py-0.5')` ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/01-scope-diff.png?raw=true)). It passes in the CI Frontend job: `badge.test.jsx (4 tests)` ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/02-ac3-ci-frontend-head-vs-main.png?raw=true)) |
| AC2 M5 fails the new test, unmutated passes, M0–M4 stay killed | ✅ (QA harness, logic check) | [03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/03-ac2-mutation-run.png?raw=true), head tests: CONTROL 4/4, **M5 KILLED (3 passed / 1 failed)**. The one failure is the new test: `expected class(es) px-2 py-0 on <span class="… px-2.5 py-0.5 …">`. M0 (pre-FE-0i `div`), M1, M2, M3 and M4 are all KILLED, and RESTORED passes 4/4. **Negative control:** with main's 3-test file, M5 **SURVIVES** (3/3) while M0–M4 are still killed, so the new test is the only one that kills M5. Harness sources and sha256 provenance of every tree file, matched against `git show`, are in [04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/04-qa-harness-sources.png?raw=true). This is a shim run, so the CI Vitest log (AC3) is the pass/fail of record |
| AC3 lint 0 warnings + `npm test` pass in CI Frontend. Count main + 1, files unchanged | ✅ | [02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/02-ac3-ci-frontend-head-vs-main.png?raw=true): main `53171d6` (the merge-base and current `origin/main`) job 136988844933 has 12 files / 155 tests / badge 3 tests. Head `79da23e` job 137066033508 has 12 files / **156** tests / badge **4** tests, `Found 0 warnings and 0 errors.`, build ok. +1 is a new test, not an extended one, which matches the PR description |
| Docs: none | ✅ | No behaviour change. README/CONTRIBUTING untouched |

## Scope
One file changed, `frontend/src/components/ui/badge.test.jsx` (+10/-0), inside the frontend's owned paths. No product code, no `badge.jsx`, no callers, no ticket/review/doc files ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5fb190a3432d795a1ad658d396230cca9db82a9e/agents/reviews/FE-0j/evidence/01-scope-diff.png?raw=true)). Nothing from "Out of scope" is touched. No design was required.

## PRD fit
This hardens a test with no user-visible change. It pins the precedence that `ReferencesStack.jsx` relies on for its compact count badge (`className="text-xs px-2 py-0"`), so a future refactor of `Badge` can't quietly restore the default padding. That serves PRD §7 (a consistent, readable UI). No contracts, thresholds or reliability invariants are touched.

## Findings
1. [spec] (cosmetic) The ticket cites `ReferencesStack.jsx:42`, but at this head the `<Badge variant="secondary" className="text-xs px-2 py-0">` call is on line 43. The test comment names only the file, so nothing in the PR needs to change.

No blocking findings, and no nits on the code.

## Missing tests
- None needed for this ticket. Optional later: a variant-colour override (e.g. `variant="supported" className="bg-red-500"` → no `bg-supported`) would pin precedence for the colour group too. The padding test already kills the only order mutant (M5).

## Hand-off
PASS → pm-lead final review.

---

# PM final review: FE-0j · PR #125 · round 1

**Verdict:** APPROVE
**Reviewed commit:** `79da23ed9e119f2a3eca1c21db20527c0f7faa88` · **Date:** 2026-11-27 · **Reviewer:** pm-lead

- **PRD fit:** a test-only change. It pins the `cn(badgeVariants(...), className)` order that `ReferencesStack.jsx` (line 43) depends on for its compact count badge. This keeps the UI consistent (Product PRD §7) with no user-visible change. No contracts are touched.
- **Scope:** one file, `frontend/src/components/ui/badge.test.jsx` (+10/-0). This matches the ticket's "Files expected" exactly, with nothing extra. `badge.jsx` and the callers are untouched, as the ticket required.
- **Evidence (opened all six, 00–05 at `5fb190a`):**
  - 00 shows 5/5 checks passing at the head commit.
  - 01 is the diff and the ownership check. It proves AC1's assertions.
  - 02 compares the CI Frontend job at head and at main: 0 warnings, 12 files both times, 155 → 156 tests, badge tests 3 → 4. It proves AC3 (+1, a new test).
  - 03 is the mutation run. M5 is KILLED by the new test only, M0–M4 are KILLED, and both controls pass. The negative control is the key part: on main's tests M5 SURVIVES, which proves AC2.
  - 04 holds the harness sources and their provenance.
  - 05 records why the tests weren't run locally. That is acceptable because CI is the source of truth.
- **AC2 caveat:** the mutation run uses a shim (Vitest/RTL shims, with real react-dom, cva and tailwind-merge in Chromium). This is acceptable because the ticket explicitly allows QA's harness, and the CI Vitest log is the pass/fail of record.
- **Docs:** none needed. The PRD status column doesn't change for a test-hardening task.
- **QA finding 1 [spec]:** fixed in the ticket (`ReferencesStack.jsx:42` → `:43`). No code change needed.
- **Optional follow-up (not filed):** a colour-group precedence test, suggested by QA. M5 is already killed, so the value is low. Left as a note.

Action: PR #125 description rewritten with evidence, marked ready for review. Merge is Mahesh's.
