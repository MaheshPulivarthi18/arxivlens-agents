_Provenance: saved verbatim by the orchestrator from the qa-reviewer's PR #90 comment (https://github.com/MaheshPulivarthi18/ArxivLens/pull/90#issuecomment-7047745509); the QA harness could not write this file._

[qa-reviewer] QA report — OPS-H17 · PR #90 · round 1

**Verdict:** PASS
**Reviewed commit:** `9dae472aed2d925e8167c1ea7509bbe1412369e0` · **Date:** 2026-11-21
**Ticket:** [agents/tasks/OPS-H17.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/OPS-H17.md) · **PRD:** Technical PRD §10 (CI harness, no PRD row); follow-up from QA OPS-H16 `[spec]` finding 2

Evidence is pinned at arxivlens-agents `4adb852`: [evidence folder](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4adb852ce5dcc5f76f206d59402ae558d1e0e5b4/agents/reviews/OPS-H17/evidence/). (The harness refused to write report.md; this comment is the report verbatim.)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136491104274 | pass |
| Python M0 unit tests | CI job 136491103744 | pass |
| Frontend (lint, test, build) | CI job 136491103955 | pass: Test step `npm test` → `vitest run`, 3 files / 19 tests, 0 `npm error` |
| DB (migrate twice, HNSW plan + recall) | CI job 136491104907 | pass |
| Agent ownership check | CI job 136491104061 + local | pass: `Ownership OK for role=backend (2 changed lines)` |
| Ticket verification commands | local, PR-head worktree, real npm 10.9.9 / node v22.23.5 | all as expected (01, 03) |
| `make test-unit` / `make lint` | not run locally: no source change (AC4 waives them); CI Go/Python/Frontend jobs cover them | n/a |
| `make eval` | not run: nothing in retrieval or answering changes | n/a |

All five check runs have `head_sha` = `9dae472` and ran on the merge commit `1450d11` (`Merge 9dae472 into c37d27c`); `c37d27c` is current `origin/main` ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4adb852ce5dcc5f76f206d59402ae558d1e0e5b4/agents/reviews/OPS-H17/evidence/00-ci-checks.png?raw=true)). `` The PR was open, draft and not merged when the review started.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `git diff --stat origin/main...HEAD` → `.github/workflows/ci.yml \| 2 +-`, a single `-run: npm run test --if-present` / `+run: npm test` hunk. `grep -n if-present ci.yml` → none (also none anywhere under `.github/` or in `Makefile`). The parsed frontend job keeps `defaults.run.working-directory: frontend`, and step 4 `Test` still sits between `npm run lint` and `npm run build`. Ownership OK locally and in CI. [01](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4adb852ce5dcc5f76f206d59402ae558d1e0e5b4/agents/reviews/OPS-H17/evidence/01-ac1-diff-ownership.png?raw=true) ``` |
| AC2 | ✅ | Frontend job **136491103955**: conclusion success, step 6 `Test` success. Log lines: `180: ##[group]Run npm test`, `186: > vitest run`, `196: Test Files  3 passed (3)` (N=3 ≥ 3), `197: Tests  19 passed (19)`. `grep -c 'npm error'` = 0, `##[error]` = 0. [02](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4adb852ce5dcc5f76f206d59402ae558d1e0e5b4/agents/reviews/OPS-H17/evidence/02-ac2-ci-frontend-npm-test.png?raw=true) ```` |
| AC3 | ✅ | Real npm, scratch dirs from `mktemp -d` outside the repo. Case A, ticket package `{"scripts":{"build":"true"}}`: old `npm run test --if-present` → no output, rc=0; new `npm test` → `npm error Missing script: "test"`, rc=1. Case B, the PR head's real `frontend/package.json` with only `test` deleted (the regression this task guards against): old rc=0 silent, new rc=1. Case C, positive control (`"test":"echo ran-tests"`): both print `ran-tests`, rc=0. [03](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4adb852ce5dcc5f76f206d59402ae558d1e0e5b4/agents/reviews/OPS-H17/evidence/03-ac3-real-npm-old-vs-new.png?raw=true), ````` harness source [04](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4adb852ce5dcc5f76f206d59402ae558d1e0e5b4/agents/reviews/OPS-H17/evidence/04-harness-sources.png?raw=true) `````` |
| AC4 | ✅ | Go, Python M0, DB, Agent ownership and Frontend are all `completed success` on head `9dae472` [00](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4adb852ce5dcc5f76f206d59402ae558d1e0e5b4/agents/reviews/OPS-H17/evidence/00-ci-checks.png?raw=true). ``````` make test-unit/lint/eval: waived by the AC, see above. |

## Scope / contracts
- Changed files (`pulls/90/files`): only `.github/workflows/ci.yml`, which is within backend ownership. No tickets, reviews or docs leaked into the PR. Nothing listed as out of scope (`Makefile`, `frontend/**`, the dist report step, other jobs) is touched.
- No shared contract, schema, threshold or eval gate changes. The gate gets stricter, not weaker.
- Open PRs: none of #70, #79 or #81–#89 touches `ci.yml`. Frontend PRs #85, #86 and #87 add or modify `*.test.*` files. `"test": "vitest run"` already exists, so the old and new steps both run the same `vitest run` and their CI behaviour doesn't change.
- PR body: the heading, Spec link and "What changed" path match OPS-H17 and `pulls/90/files`.

## PRD fit
Technical PRD §10 relies on CI as the source of truth for test results. Before this change, deleting or renaming the frontend `test` script left the job green with zero tests run. Now the job fails with `Missing script: "test"`, the same guard that local `make test-fe` got in OPS-H16.

## Findings
No blocking findings, no nits, no spec issues.

## Missing tests
None needed for a one-line CI step change. AC3 proves the failure path with real npm against the actual frontend manifest; AC2 proves the success path in CI.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM final review — pm-lead · 2026-11-20 UTC · head `9dae472`

**Verdict: APPROVE**

- **PRD fit:** Technical PRD §10 treats CI as the source of truth for test results. The frontend job had a silent pass: if the `test` script went missing, it exited 0 and ran no tests. This change closes it, and CI now matches the local `make test-fe` guard from OPS-H16 (#89). It is the plain `npm test` step that the FE-1 Backlog line asked for.
- **Scope:** `pulls/90/files` lists only `.github/workflows/ci.yml` (+1/-1), which is the single line the ticket named. Nothing is missing and nothing extra was changed. No contract, threshold or gate was touched, and the gate is now stricter.
- **Evidence (all 5 files opened):** 00 shows all 5 check runs `success` with `head_sha` 9dae472 (AC4). 01 shows the diff stat `2 +-`, no `if-present` left, step order unchanged and ownership OK both locally and in CI (AC1). 02 shows the CI Test step log with `Run npm test`, `> vitest run`, `Test Files 3 passed (3)` and 0 `npm error` (AC2). 03 runs real npm: the old step returns rc 0 silently, the new step prints `Missing script: "test"` and returns rc 1. It does this for both the ticket package and the real manifest with `test` removed, and includes a positive control (AC3). 04 is the harness source for 03. No AC is left unverified.
- **Docs:** the app README and CONTRIBUTING need no change because the CI step is internal and no command changed. This task has no PRD status row.
- **Note (non-blocking):** the markdown links in the verbatim-saved QA comment above contain stray backticks. The pinned evidence URLs inside them are still correct, and the PR body links them cleanly.

Raised: I rewrote the PR #90 description with the Evidence section (images pinned at `4adb852`), CI results and both verdicts, and marked it ready for review. Head was checked before the PATCH and is still `9dae472`. Jira: needs story (orchestrator is creating it). I made no Jira edits.
