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
