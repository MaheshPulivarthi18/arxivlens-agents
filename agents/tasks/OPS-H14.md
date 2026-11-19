# OPS-H14: Frontend CI job prints `dist/` font/CSS evidence; Test step without the spurious `npm error`

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 (harness: gives frontend QA `dist/` evidence for FE-0/FE-3 without a local npm build) |
| **PRD ref** | Technical PRD §11 (dev harness); FE-0 design Q3 (`docs/design/FE-0.md` §405); FE-1 QA/PM review (spurious `npm error`) |
| **Depends on** | none. Merged prerequisites only (`ci.yml` frontend job exists on `main` 4c7d327). Works before and after FE-0 #69 / FE-1 #68 merge |
| **Jira** | to create (orchestrator: story under epic "Dev harness & infrastructure" KAN-3, labels `arxivlens`, `agent-backend`, `task-OPS-H14`, status To Do) |
| **Design required** | no: CI-only, report-only step, no contract, gate, CLI, table or service |
| **Status** | Ready |

## Goal
Frontend QA can't run `npm run build` in agent sandboxes, so FE-0's `dist/` checks (self-hosted fonts, no Google font hosts,
`.font-serif` / `.prose` in the built CSS) were unverifiable (FE-0 QA report finding 3). The CI `frontend` job should print those facts
into the job log, where QA can read them. Separately, the job's Test step pipes `npm run` into `grep -q`, which logs a spurious
`npm error` (EPIPE) once a `test` script exists (seen on FE-1 #68). Replace it with a pipe-free form.

## Scope
- Files expected to change (and only these):
  - `.github/workflows/ci.yml`, `frontend` job only: (a) replace the step `Test (if FE-1 has added a test script)` with a step named
    `Test` that runs `npm run test --if-present` (no pipe, no `grep`); (b) add a step `dist/ report (fonts, CSS)` **after**
    `npm run build` that runs the new script on `dist/`.
  - `.github/scripts/frontend-dist-report.sh` (new, executable): takes one argument, the dist directory, and prints the report below.
- Out of scope: the `go`, `python` and `agent-ownership` jobs (the `-race` nit is a separate Backlog item); `Makefile` `test-fe` (same
  `grep -q` pattern, local only, stays in Backlog); any `frontend/` file; turning the report into a failing check (that would be a new
  gate: Backlog, *Proposed*, after FE-0 #69 merges); `CONTRIBUTING.md` / `README.md` (CI-only change with no command or behaviour change for
  users; `CONTRIBUTING.md` is also in open PR #66).

### Report format (fixed, one line each, in this order; `<n>` is an integer)
```
DIST woff2 files: <n>
DIST woff2: <file name>            # one line per .woff2 under <dist>/assets, sorted; none if n = 0
DIST css @font-face rules: <n>     # occurrences across <dist>/assets/*.css
DIST css .font-serif: yes|no
DIST css .prose: yes|no
DIST google font hosts: <n>        # occurrences of fonts.googleapis.com or fonts.gstatic.com across every file under <dist> (html, css, js)
DIST google font host files: <comma-separated relative paths, or "none">
```
The script is **report-only**: it exits 0 whatever the counts are. It exits non-zero only if `<dist>` is missing or has no `index.html`
(the build step already failed then). Under `bash -e`, `grep` finding nothing must not fail the step (`|| true` or `grep -c`).

## Acceptance criteria
- [ ] AC1: Fixture run in the sandbox (no npm needed). QA builds two fixture dirs and pastes both outputs:
  (a) **positive** `pos/index.html` containing `https://fonts.googleapis.com/css2?family=Inter`, `pos/assets/a.css` containing two
  `@font-face{` rules plus `.font-serif{` and `.prose{`, and `pos/assets/x.woff2`, `pos/assets/y.woff2` → exactly
  `woff2 files: 2`, both names, `@font-face rules: 2`, `.font-serif: yes`, `.prose: yes`, `google font hosts: 1`,
  `host files: index.html`; (b) **negative** `neg/index.html` (no hosts) + `neg/assets/b.css` (none of the strings) → `0`, `0`, `no`, `no`,
  `0`, `none`. Both runs exit 0. (c) A missing dir and a dir without `index.html` exit non-zero.
- [ ] AC2: Mutation, one per report line (QA runs each against the AC1 fixtures and shows it changes the output): counting only
  `fonts.googleapis.com` (drop `gstatic`) → a fixture with only a `fonts.gstatic.com` host reports 0; searching only `*.css` for hosts →
  the `index.html` host is missed; dropping `|| true`/`-c` handling → the negative fixture exits non-zero.
- [ ] AC3: On the PR's own CI run (`ci.yml`, job `Frontend (lint, test, build)`), the `dist/ report (fonts, CSS)` step log shows all 7
  line types in the order above, and the values match the base the branch was built on. Write in the PR which case applies and quote the
  lines: **before #69 merges** `frontend/index.html` links Google Fonts (lines 8–10 on 4c7d327), so expect `google font hosts` ≥ 1 with
  `index.html` among the files; **after #69 merges** expect `woff2 files` ≥ 1 and `google font hosts: 0`. Quote the job's run ID.
- [ ] AC4: The `Test` step's log contains no line starting `npm error`. If #68 has merged when the PR is built, the step log also shows the
  Vitest summary line (`Tests  <n> passed`); if not, the step runs and exits 0 with no output from a test runner. State which one applies.
  `ci.yml` has no `npm run | grep` left (`grep -n 'npm run |' .github/workflows/ci.yml` → no output).
- [ ] AC5: `git diff --stat origin/main` lists only `.github/workflows/ci.yml` and `.github/scripts/frontend-dist-report.sh`; the `go`,
  `python` and `agent-ownership` jobs are byte-identical (`git diff origin/main -- .github/workflows/ci.yml` touches only the `frontend`
  job). The script passes `shellcheck` if available (else `bash -n`). Ownership check passes for role=backend.
- [ ] Docs: the script starts with a comment saying what it prints, that it is report-only, and why (agent QA can't build `dist/`; FE-0
  design Q3). No README/CONTRIBUTING change (see Scope).

## Verification
```bash
bash -n .github/scripts/frontend-dist-report.sh && (shellcheck .github/scripts/frontend-dist-report.sh || true)
# AC1/AC2 fixtures: see AC1 (scratch dirs under the QA scratchpad, not in the repo)
.github/scripts/frontend-dist-report.sh /path/to/pos; echo "exit=$?"
.github/scripts/frontend-dist-report.sh /path/to/neg; echo "exit=$?"
.github/scripts/frontend-dist-report.sh /nonexistent; echo "exit=$?"
grep -n 'npm run |' .github/workflows/ci.yml          # expect no output
gh api repos/MaheshPulivarthi18/ArxivLens/actions/runs/<run_id>/jobs --jq '.jobs[] | select(.name|startswith("Frontend")) | .id'
gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/<job_id>/logs | grep -E 'DIST |npm error|Tests '
.github/scripts/ownership-check.sh origin/main agent/backend/OPS-H14
git diff --stat origin/main
```
`make test-unit` / `make lint`: CI runs them; no Go/Python change. `make eval`: not run, CI-only change.

## Notes
- 2026-11-19 23:00Z (pm-lead): specced from two Backlog items (FE-0 design review "OPS-H14"; FE-1 QA/PM review EPIPE nit). Independent
  of every open PR: #65 (`rag.go`, `rag_test.go`, `tests/test_evals_data.py`, `README.md`), #66 (`db.yml`, `image-pins.yml`,
  `CONTRIBUTING.md`, `docker-compose.yml`), #68/#69/#70 (`frontend/**`, root `README.md`) don't touch `ci.yml` or `.github/scripts/`.
  Started in parallel with OPS-H6b (`internal/kafka/`) and AI-12 (`services/embedder/`, `tests/test_verify.py`): no shared files.
- Why `npm run test --if-present` and not plain `npm test`: on `main` (4c7d327) `frontend/package.json` has no `test` script yet (FE-1 #68
  adds it), so plain `npm test` would fail this PR's own CI. `--if-present` runs Vitest once #68 merges and is a no-op before.
- The report is not a gate. Making "no Google font hosts" / "woff2 ≥ 1" fail CI after #69 merges is a Backlog item (*Proposed*).
