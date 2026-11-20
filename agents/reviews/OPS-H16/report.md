_Provenance: saved verbatim by the orchestrator from the qa-reviewer's PR #89 comment (https://github.com/MaheshPulivarthi18/ArxivLens/pull/89#issuecomment-7047446397); the QA harness could not write this file._

[qa-reviewer] QA report: OPS-H16 · PR #89 · round 1

**Verdict:** PASS
**Reviewed commit:** `bf76769b4fd0b1ceb12024f8a01a8fbdfda2b526` · **Date:** 2026-11-20
**Ticket:** [agents/tasks/OPS-H16.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/OPS-H16.md) · **PRD:** Technical PRD §10 (local test commands; no PRD row)
**Evidence:** [agents/reviews/OPS-H16/evidence](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/f0758cd88dc038151760d1c0c72905b82b0617fc/agents/reviews/OPS-H16/evidence). Every file is rendered from real output at `bf76769`.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI 136478156562 | success |
| Python M0 unit tests | CI 136478156497 | success |
| Frontend (lint, test, build) | CI 136478156455 | success: `Test Files 3 passed (3)`, `Tests 19 passed (19)`, 0 `npm error` lines |
| DB / Full stack | CI 136478156974 / 136478156531 | success / success |
| Agent ownership check | CI 136478155999 | `Ownership OK for role=backend (4 changed lines)` |
| Ticket verification commands | local, worktree at `bf76769` | all as expected (01-03, 06) |
| `make test-unit` / `make lint` | not run locally: no source change, and no Go 1.25 in the sandbox | CI green |
| `make eval` | not run: no retrieval or answering change | n/a |

All 6 check runs: [00-ci-checks](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f0758cd88dc038151760d1c0c72905b82b0617fc/agents/reviews/OPS-H16/evidence/00-ci-checks.png?raw=true) ``

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | [01](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f0758cd88dc038151760d1c0c72905b82b0617fc/agents/reviews/OPS-H16/evidence/01-ac1-make-n.png?raw=true): ``` `make -n test-fe` prints exactly `cd frontend && npm test`, and `grep -cE "\\||grep|npm run"` on it gives 0. |
| AC2 | ✅ | [02](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f0758cd88dc038151760d1c0c72905b82b0617fc/agents/reviews/OPS-H16/evidence/02-ac2-stub-npm.png?raw=true), ```` stub outside the repo. (a) rc 0: make exits 0, 1 call, `cwd=…/frontend argv=test`. (b) rc 1: `make: *** [Makefile:52: test-fe] Error 1`, exit 2. (c) The origin/main recipe with no ` test` line in the listing prints `no frontend tests yet (FE-1)` and exits 0, even when npm test would fail (c2). Extra check with **real npm 10.9.9** ([03](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f0758cd88dc038151760d1c0c72905b82b0617fc/agents/reviews/OPS-H16/evidence/03-ac2-real-npm-old-vs-new.png?raw=true)): ````` with the script missing, head fails with `npm error Missing script: "test"` (exit 2) where the old recipe exits 0. With a passing or failing script, head propagates the code. The old recipe prints a spurious `npm error A complete log…` (EPIPE). |
| AC3 | ⚠ covered by composition | Local `npm ci` fails (registry blocked, `Exit handler never called!`) ([05](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f0758cd88dc038151760d1c0c72905b82b0617fc/agents/reviews/OPS-H16/evidence/05-ac3-local-real-npm.png?raw=true)). `````` **CI never runs `make test-fe`** (0 matches in the job log). It runs `npm run test --if-present` in `frontend/`. Coverage: (1) the CI job at `bf76769` runs the same `test` script, `> vitest run`, `Test Files 3 passed (3)`, 0 `npm error` lines ([04](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f0758cd88dc038151760d1c0c72905b82b0617fc/agents/reviews/OPS-H16/evidence/04-ac3-ci-frontend-vitest.png?raw=true)). ``````` (2) Local real `make test-fe` reaches `> vitest run` and fails only with `vitest: not found` (Error 127), make exit 2 (05). (3) The stub shows exactly one call, `npm test` in `frontend/` (02). The AC allows "not run: <reason>", so this is not blocking (see finding 1). |
| AC4 | ✅ | [06](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f0758cd88dc038151760d1c0c72905b82b0617fc/agents/reviews/OPS-H16/evidence/06-ac4-help-diff-ownership.png?raw=true): ```````` `test-fe      Frontend tests (Vitest; run npm ci in frontend/ first)`, `grep -c FE-1` gives 0. `Makefile \| 4 ++--` is the only file changed. Ownership OK both locally and in CI. CI is green. |

Scope: `Makefile` only, which backend owns. `test-unit` and `ci.yml` are untouched, and no `npm ci` is added. The PR body matches OPS-H16. The PR is open, draft and not merged.

## PRD fit
`make test-fe` now runs Vitest directly, passes through its exit code and fails loudly when the `test` script is missing. That removes the false green and the spurious `npm error`. It is deterministic, as Technical PRD §10 requires.

## Findings
1. [spec] AC3 can't be met literally in agent sandboxes (registry blocked), and CI doesn't run `make test-fe`. Coverage is by composition only.
2. [spec] Follow-up for backend, out of scope here: `ci.yml:72-73` still has `npm run test --if-present`, which with real npm exits **0 with no output** when the `test` script is missing ([07](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f0758cd88dc038151760d1c0c72905b82b0617fc/agents/reviews/OPS-H16/evidence/07-spec-ci-if-present.png?raw=true)). ````````` That is the same silent pass. OPS-H14 used it only because FE-1 hadn't merged yet. Switch it to `npm test` (or `make test-fe`).

No blocking findings, no nits.

## Missing tests
None needed for a 2-line recipe change. QA harness sources: [08](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f0758cd88dc038151760d1c0c72905b82b0617fc/agents/reviews/OPS-H16/evidence/08-harness-sources.png?raw=true). ``````````

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

# PM final review: OPS-H16 · PR #89 · pm-lead

**Verdict:** APPROVE
**Reviewed:** head `bf76769b4fd0b1ceb12024f8a01a8fbdfda2b526` · **Date:** 2026-11-21
**Read:** ticket `agents/tasks/OPS-H16.md`, Technical PRD §10 (local test commands, no PRD row), the FE-1/OPS-H14 Backlog line it came from, the PR diff (`gh api …/pulls/89/files`: `Makefile` +2/−2), QA r1 above, and all 18 evidence files (00–08, `.png` + `.txt`, added at `f0758cd`).

## Checks
1. **PRD / goal fit.** `make test-fe` now runs Vitest directly and passes its exit code through. A missing `test` script now fails loudly (`npm error Missing script: "test"`, make exit 2, from real npm 10.9.9 in [03]) where the old recipe exited 0 with "no frontend tests yet". The spurious EPIPE `npm error` is also gone ([03]: the old recipe prints it, head doesn't). A developer running the local command gets the same verdict CI would.
2. **Evidence per AC.**
   - AC1: [01] shows `cd frontend && npm test`, and the pipe/grep/`npm run` count is 0.
   - AC2: [02] covers (a) rc 0 with one call, argv `test`, cwd `frontend/`; (b) `make: *** [Makefile:52: test-fe] Error 1`; (c)/(c2) the old recipe's false green, even when the tests would fail.
   - AC4: [06] shows the help row with no "FE-1", the diff is `Makefile` only (4 lines), ownership is OK locally and in CI, and all 6 CI checks are green ([00]).
3. **AC3 (QA `[spec]` finding 1).** **Accepted as met through the AC's own "else not run: <reason>" branch, with composed evidence.** The reason is concrete: `npm ci` fails because the registry is blocked ([05]). The composed evidence closes the gap that matters:
   - CI job 136478156455 at this exact head runs the same `test` script (`> vitest run`), with `Test Files 3 passed (3)`, `Tests 19 passed (19)` and 0 `npm error` lines ([04]).
   - Local real `make test-fe` reaches `> vitest run` and fails only because deps are not installed ([05]).
   - The stub shows the recipe makes exactly that one call ([02]).

   The only untested link is "make invokes npm test", and [02], [03] and [05] all show it. No spec change for this ticket. The lesson is recorded (an AC that needs a registry should name CI as the evidence source), and OPS-H17 below makes CI exercise the same `npm test` with no silent-pass path.
4. **Scope.** `Makefile` `test-fe` only. `test-unit`, `ci.yml` and `frontend/**` are untouched, and no `npm ci` was added. This matches the ticket exactly.
5. **Docs.** No doc mentions `make test-fe` besides `make help`, which is updated. There is no PRD status column for this item.

## QA `[spec]` finding 2, PM disposition
`ci.yml:72-73` still runs `npm run test --if-present`, which exits 0 with no output when the `test` script is missing ([07]). That is the same silent pass this PR removes locally, and it was originally meant to be a plain `npm test` (the FE-1 Backlog line said so; OPS-H14 used `--if-present` only because FE-1 had not merged). **Specced as [OPS-H17](../../tasks/OPS-H17.md)** (backend, P3, Ready): `.github/workflows/ci.yml` frontend Test step → `npm test`. No open PR touches `ci.yml` (REST 2026-11-21).

## Raise
The PR description has been rewritten with an Evidence section (one row per AC, images pinned at `f0758cd`), CI results and both verdicts. The PR is marked ready for review. Jira: needs story (the orchestrator is creating it), status → Ready to merge once it exists. Merge: Mahesh.
