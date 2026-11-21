# OPS-H18b: CI ML-absence guard fails closed when `pip list` errors; `make help` text for `test-unit`

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 (harness) |
| **PRD ref** | Technical PRD §10 (Testing and evaluation) / `CONTRIBUTING.md` Commands table. Source: [QA OPS-H18 report](../reviews/OPS-H18/report.md) findings 1 and 3, carried as the board Backlog line "OPS-H18 QA nits" |
| **Depends on** | OPS-H18 (ArxivLens #103) **merged** `11c4696`. No open PR (#104–#112) touches `Makefile` or `.github/workflows/ci.yml` (checked 2026-11-21 12:00Z with `gh api .../pulls/<n>/files`) |
| **Jira** | KAN-120 (epic KAN-3 "Dev harness & infrastructure"; labels `task-OPS-H18b`, `agent-backend`, `arxivlens`) |
| **Design required** | no: one CI step's shell and one Makefile help string; no product code, no contract, no new command |
| **Status** | Done (PR #113 merged 2026-11-21 → `54f6802`) |

## Goal
The `python` CI job checks that no ML package is installed before `make test-py-light` runs, so the light tests really
prove they need no torch. Today the check fails **open**: if `pip list` itself errors, `grep` sees no input, the `if`
is false and the job carries on as if the ML stack were absent. Also `make help` still describes `test-unit` as
"Go + M0 + eval data", which is no longer what it runs since OPS-H18.

Checked on `origin/main` `11c4696`:
- `.github/workflows/ci.yml:54` (job `python`, name `Python M0 unit tests`, step `Light tests without the ML stack (make test-py-light)`):
  `if pip list 2>/dev/null | grep -iE 'torch|transformers|sentence|PyMuPDF'; then … exit 1; fi`. The job has no
  `defaults.run.shell`, so the step runs under `bash -e {0}` (no `pipefail`).
- **`set -o pipefail` alone does not fix it** (the QA nit's first suggestion): a pipeline's status is the rightmost
  non-zero status, and `grep` exits 1 on no match, so `(exit 2) | grep -q torch` is still "no match" under `pipefail`
  (pm-lead checked in bash 2026-11-21). The `pip list` failure must be checked on its own.
- `Makefile:43`: `test-unit: test-go test-py ## Fast tests, no infra (Go + M0 + eval data). Frontend tests: make test-fe`.
  `CONTRIBUTING.md:23` already says "Go tests + `make test-py` (= `make test-py-light` + `make test-py-ml`)"; the app
  `README.md` does not mention `test-unit`'s contents (`grep -n "test-unit\|make help" README.md` → no match), so neither changes.

## Scope
- Files expected to change (only these two):
  - `.github/workflows/ci.yml`: the guard in step `Light tests without the ML stack (make test-py-light)` (lines 50-57).
  - `Makefile`: the `## ` help text on line 43 only.
- Out of scope: the package list in the regex, every other CI step and job, `requirements*.txt`, `CONTRIBUTING.md`,
  `README.md`, other Makefile targets.

## Acceptance criteria
- [x] AC1 — The guard fails the step when `pip list` exits non-zero, with an `::error::` line that says `pip list`
  failed (wording free, but distinct from the "ML stack present" error). It still fails with the existing
  `::error::ML stack present before the light tests` when a listed package is installed, and passes when neither
  happens. Hint (not required wording): capture first, e.g. `pkgs="$(pip list)" || { echo "::error::pip list failed"; exit 1; }`
  then `grep -iE '…' <<<"$pkgs"`.
- [x] AC2 — Evidence for the three AC1 branches, from a local bash run of the step's exact `run:` block with `pip`
  replaced by a stub function (exit 2 / prints `torch 2.x` / prints only light packages) → three outputs and exit codes
  pasted in the PR. The real CI run must show the step passing on the PR head.
- [x] AC3 — `make help` prints `test-unit` with text that names what it runs now, e.g.
  `Fast tests, no infra (Go + test-py). Frontend tests: make test-fe`; paste the `make help | grep test-unit` line.
- [x] AC4 — CI on the PR head: check-runs `Python M0 unit tests`, `Go (vet, gofmt, test, build)`,
  `Frontend (lint, test, build)` and `Agent ownership check` all `success` (names as `gh api .../commits/<sha>/check-runs`
  prints them). In `Python M0 unit tests`, the step `Light tests without the ML stack (make test-py-light)` logs
  `ML packages installed (must be none):` followed by no package line and then the `test-py-light` pytest summary.
- [x] AC5 — Diff touches only `.github/workflows/ci.yml` and `Makefile`; < 30 changed lines.
- [x] Docs: none needed (CONTRIBUTING:23 already correct; README has no `test-unit` description). Say so in the PR.

## Verification
```bash
cd app
make help | grep test-unit
# AC2: copy the step's run: block into a scratch script, define pip() { return 2; } / pip() { echo "torch 2.4.0"; } /
# pip() { echo "pytest 8.3.0"; }, run each with bash -e, print $? after each
gh api repos/MaheshPulivarthi18/ArxivLens/commits/<head-sha>/check-runs --jq '.check_runs[] | [.name, .conclusion] | @tsv'
```

## Notes
- 2026-11-21 12:00Z pm-lead: specced from the Backlog line "OPS-H18 QA nits" (findings 1 and 3). Picked alone for
  backend this cycle: every other backend Ready task waits on an open PR (#104 README, #106 db.py, #111 eval budget).
- 2026-11-21 backend-engineer: built on `agent/backend/OPS-H18b` (commit `246d6d1`, from `11c4696`; not pushed, no PR yet).
  ci.yml guard now captures `pkgs="$(pip list)" || { echo "::error::pip list failed; cannot check for the ML stack"; exit 1; }`
  and then runs `grep -iE '…' <<<"$pkgs"` (expansions quoted; regex unchanged). Makefile:43 help is now
  `Fast tests, no infra (Go + test-py). Frontend tests: make test-fe`. Diff: 2 files, +4/−2.
  Local evidence (step's `run:` block pulled from the YAML with PyYAML, run under `bash -e` with stub `pip`/`python`/`make`):
  pip list exits 2 → `::error::pip list failed…`, exit 1 · prints `torch 2.4.0` → `::error::ML stack present before the light tests`, exit 1 ·
  prints only `pytest 8.3.0` → reaches `make test-py-light`, exit 0. Contrast: the old block with the same exit-2 stub → exit 0 (the bug).
  `make help | grep test-unit` prints the new text. `ownership-check.sh origin/main agent/backend/OPS-H18b` → OK (6 changed lines).
  Not run locally: shellcheck (not installed), the real CI (AC2 last sentence, AC4: needs the PR head). Docs: none needed (as the spec says).
- 2026-11-21 pm-lead: final review **APPROVE** on `246d6d1` (QA r1 PASS; [report](../reviews/OPS-H18b/report.md), evidence at `6cd7729`).
  QA nits: (1) AC2 raw outputs are now pasted in the PR body and evidence 01 is embedded; (2) stderr from `pip list` now visible: accepted;
  (3) `torchfail` reports the pip error first: accepted (fails closed either way). No follow-ups. PR #113 description rewritten with
  Evidence, marked ready for review, label `ready-to-merge`. Next: Mahesh reviews/merges.
