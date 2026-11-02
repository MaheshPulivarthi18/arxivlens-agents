# OPS-H4: Ignore `evals/results/` and run the eval-data tests in `make test-unit`

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Product PRD §8; EVAL-1 AC5 + Notes follow-up request |
| **Depends on** | EVAL-1 (PR #2 merged) |
| **Status** | Ready (start once PR #2 is merged) |

## Goal
Each `make eval` run writes `evals/results/<timestamp>.json`, so the directory must never be committed. The eval dataset
checks in `tests/test_evals_data.py` (schema, sizes, corpus membership, unique IDs) need no infra, but today nothing runs
them in the fast suite. Ignoring the results and running the checks keeps broken eval data out of `main`.

## Scope
- Files: `.gitignore` (add `evals/results/`), `Makefile` (`test-py` runs `tests/test_m0.py tests/test_evals_data.py`).
- Out of scope: any change to `evals/`, `scripts/`, or `tests/test_evals_data.py` itself (those belong to ai-engineer).

## Acceptance criteria
- [ ] AC1 — `git check-ignore evals/results/x.json` prints the path (exit 0).
- [ ] AC2 — `make test-py` runs `tests/test_evals_data.py` and it passes (paste the pytest summary line).
- [ ] AC3 — `make test-unit` still passes, and `make help` still lists `test-py` with an accurate description.
- [ ] AC4 — The diff touches only `.gitignore` and `Makefile`.
- [ ] AC5 — In CI, the "Python M0 unit tests" job (it runs `make test-py`, `.github/workflows/ci.yml:44`) runs `tests/test_evals_data.py`: the job log on the PR head shows its pass count (47 or more at the time EVAL-1 merged). If the CI job needs an extra package for it, say so in Notes instead of editing `requirements*.txt` silently.

## Verification
```bash
git check-ignore -v evals/results/x.json
make test-py
make test-unit
make lint
git diff --stat origin/main
```

## Notes
- Specced by pm-lead in PM-1 from the EVAL-1 follow-up requests.
- 2026-11-02 (pm-lead, EVAL-1 round-3 PM review): confirmed this ticket covers EVAL-1 AC5 and CI for the eval tests (QA r3 finding 8). CI calls `make test-py`, so the Makefile change is enough; AC5 added to prove it from the CI log. Today nothing in CI runs the 47 eval tests (EVAL-1 evidence `301-ci-job-logs.png`).
