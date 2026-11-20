# OPS-H17: CI frontend job runs `npm test` (drop `--if-present`, no silent pass)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 (harness) |
| **PRD ref** | Technical PRD §10 Testing and evaluation (CI harness; no PRD row). Follow-up from the OPS-H16 QA `[spec]` finding 2 (`agents/reviews/OPS-H16/report.md`, evidence `07-spec-ci-if-present`); original intent in the FE-1 QA/PM Backlog line ("replace the conditional with a plain `npm test` step") |
| **Depends on** | FE-1 (#68, merged `2410d2e`: `frontend/package.json` `"test": "vitest run"`). Independent of OPS-H16 #89 (`Makefile` only) and OPS-H9b #88 (`db.yml`, `image-pins.yml`, `CONTRIBUTING.md`). No open PR touches `.github/workflows/ci.yml` (REST check 2026-11-21 of #70, #79, #81–#89) |
| **Jira** | needs story (epic for Technical PRD §10 harness; label `task-OPS-H17`) |
| **Design required** | no: one CI step; no production code, contract, CLI, table or service |
| **Status** | Ready to merge (PR #90 raised 2026-11-20 UTC; QA PASS r1, PM APPROVE) |

## Goal
The CI `frontend` job's Test step (`.github/workflows/ci.yml:72-73` on `c37d27c`) runs `npm run test --if-present`. With real npm,
that exits 0 **with no output** when `frontend/package.json` has no `test` script (QA OPS-H16 evidence 07). If someone deletes or
renames the script, the frontend job stays green with no tests run. That is the same false green OPS-H16 removed from `make test-fe`.
`--if-present` was only a bridge until FE-1 merged, and FE-1 has merged. The step should run `npm test`.

## Scope
- File expected to change (only this one): `.github/workflows/ci.yml`, the `frontend` job's `Test` step:
  `run: npm run test --if-present` → `run: npm test`. Keep the step name `Test`, its position (after lint, before build) and the
  job's `working-directory: frontend`.
- Decision (settled, no ADR): plain `npm test`, as the FE-1 Backlog line asked. Don't call `make test-fe` from CI: the job runs in
  `frontend/`, and every other step in it is an `npm` call.
- Out of scope: `Makefile` (OPS-H16), `frontend/**`, the `dist/ report` step, any other job.

## Acceptance criteria
- [ ] AC1: the diff is one line in `ci.yml` (`git diff --stat origin/main` shows `.github/workflows/ci.yml | 2 +-`). `grep -n 'if-present' .github/workflows/ci.yml`
  prints nothing. The ownership check passes for role=backend.
- [ ] AC2 (real CI): on the PR's head, the `Frontend (lint, test, build)` job is green. Its Test step log shows `Run npm test`,
  `> vitest run` and `Test Files  N passed (N)` with N ≥ 3, and has 0 `npm error` lines. Quote the job ID and log lines.
- [ ] AC3 (the silent pass is gone; local, real npm, no registry needed): in a scratch dir outside the repo, with a `package.json`
  that has no `test` script, show `npm run test --if-present` → rc 0 (old step) and `npm test` → `npm error Missing script: "test"`,
  rc ≠ 0 (new step). Paste both.
- [ ] AC4: all other CI jobs on the PR are green (Go, Python M0, DB, ownership). `make test-unit` / `make lint`: not needed (no
  source change). `make eval`: not run, nothing in retrieval or answering changes.

## Verification
```bash
git diff --stat origin/main && git diff origin/main -- .github/workflows/ci.yml
grep -n 'if-present' .github/workflows/ci.yml || echo "none"
.github/scripts/ownership-check.sh origin/main agent/backend/OPS-H17
# AC3: d=$(mktemp -d); printf '{"name":"x","private":true,"scripts":{"build":"true"}}' > "$d/package.json"
#      (cd "$d" && npm run test --if-present; echo "rc=$?"; npm test; echo "rc=$?")
# CI (source of truth): Frontend job log of the PR
gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/<job>/logs | grep -nE 'Run npm test|vitest run|Test Files|npm error'
```

## Notes
- 2026-11-21 (pm-lead): specced from QA OPS-H16 `[spec]` finding 2 during the OPS-H16 final review (PM APPROVE). Checked on app
  `origin/main` `c37d27c`: `ci.yml:72-73` `- name: Test` / `run: npm run test --if-present`; the job has
  `defaults.run.working-directory: frontend`. Before this, `make test-fe` (local) and CI used two different guards. After OPS-H16
  and this task, both run `npm test` with no silent pass.
- 2026-11-20 (backend-engineer): build. Branch `agent/backend/OPS-H17` pushed, head `9dae472`, from `origin/main` `c37d27c`. PR not opened yet
  (orchestrator raises it). Diff: `.github/workflows/ci.yml | 2 +-`, `run: npm run test --if-present` → `run: npm test`. Step name `Test`,
  position (after lint, before build) and `defaults.run.working-directory: frontend` are unchanged (yaml.safe_load step list:
  checkout, setup-node, `npm ci`, `npm run lint`, `Test`, `npm run build`, dist/ report). `grep -n if-present ci.yml` → none.
  Ownership: `Ownership OK for role=backend (2 changed lines)`. AC3 (npm 10.9.9 / node v22.23.5, scratch dir outside the repo,
  `{"scripts":{"build":"true"}}`): `npm run test --if-present` → no output, rc=0; `npm test` → `npm error Missing script: "test"`,
  rc=1. Positive control with `"test":"echo ran-tests"`: `npm test` → `ran-tests`, rc=0. `frontend/package.json:11` has
  `"test": "vitest run"`. Not run: actionlint (not installed). AC2/AC4 (CI) are pending: `ci.yml` triggers only on `pull_request` and on
  push to `main`, so the branch push started no run (`actions/runs?head_sha=9dae472` total_count 0). Make/eval not run: no source change.
- 2026-11-20 (pm-lead): final review **APPROVE** on head `9dae472` after QA r1 PASS with no findings. I opened all 5 evidence files (00–04 at `4adb852`) and each one proves its AC. The diff is only `ci.yml` +1/-1. I rewrote the PR #90 description with the Evidence section and marked it ready for review, so it is now Ready to merge for Mahesh. Jira: needs story (orchestrator).
