# QA report: OPS-H4 · PR #12 · round 1

**Verdict:** PASS
**Reviewed commit:** `31682fb0dce718286a504e73e3809a3305389181` · **Date:** 2026-11-03
**Ticket:** `agents/tasks/OPS-H4.md` · **PRD:** Product PRD §8; EVAL-1 AC5 (+ Notes follow-up)
**Design:** none (not design-required)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 125824920370 | pass ([00](evidence/00-ci-checks.png), [07](evidence/07-ac3-ci-test-unit.png)) |
| Python M0 unit tests (`make test-py`) | CI job 125824920242 | pass, `50 passed in 6.47s` (main `bb9ee90`: `3 passed`) ([05](evidence/05-ac5-ci-python-job.png)) |
| Frontend (lint, test, build) | CI | pass ([00](evidence/00-ci-checks.png)) |
| Agent ownership check | CI | pass ([00](evidence/00-ci-checks.png)) |
| `git check-ignore -v evals/results/x.json` | local | `.gitignore:29:evals/results/`, exit 0 ([01](evidence/01-ac1-check-ignore.png)) |
| `pytest -q tests/test_evals_data.py` | local | `47 passed` ([02](evidence/02-ac2-test-py.png)) |
| `make test-py` | local | fails in this sandbox: `tests/test_m0.py` collection error (no torch / HF blocked). CI is the source of truth ([02](evidence/02-ac2-test-py.png)) |
| `make test-unit`, `make lint` | not run locally | Go 1.24.7 here, go.mod needs 1.25 (download blocked). CI ran `make lint-go`, `make test-go`, `make test-py`: all green ([07](evidence/07-ac3-ci-test-unit.png)) |
| `git diff --stat origin/main...HEAD` | local | 2 files, +4/-3 ([04](evidence/04-ac4-diff.png)) |
| Mutation check on eval data | local, scratch copy of HEAD | duplicate ID → 2 failed; off-corpus relevant ID → 1 failed ([06](evidence/06-mutation-eval-data.png)) |
| `make eval` | not run: no retrieval/answering change (only `.gitignore` + `Makefile` test target) | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: `git check-ignore evals/results/x.json` prints path, exit 0 | ✅ | `.gitignore:29:evals/results/	evals/results/x.json`, `exit=0`. `git ls-files -ci --exclude-standard` is empty, so the new rule hides no tracked file; the tracked `evals/*` files are unaffected. [01-ac1-check-ignore.png](evidence/01-ac1-check-ignore.png) |
| AC2: `make test-py` runs `tests/test_evals_data.py`, passes | ✅ | `make -n test-py` → `python3 -m pytest -q tests/test_m0.py tests/test_evals_data.py` (Makefile:47-48). Local eval-data run: `47 passed in 0.11s` [02](evidence/02-ac2-test-py.png). The full `make test-py` passes in CI: `50 passed in 6.47s` [05](evidence/05-ac5-ci-python-job.png) |
| AC3: `make test-unit` passes; `make help` lists `test-py` accurately | ✅ | `make help`: `test-py  Python unit tests: M0 + eval data (M0 downloads BGE model on first run)`; `test-unit  Fast tests, no infra (Go + M0 + eval data)...`. Both match the recipes (`make -n test-unit`) [03](evidence/03-ac3-make-help.png). `test-unit = test-go test-py`, both green in CI on 31682fb [07](evidence/07-ac3-ci-test-unit.png) |
| AC4: diff touches only `.gitignore` and `Makefile` | ✅ | `.gitignore | 1 +`, `Makefile | 6 +++---`, single commit [04](evidence/04-ac4-diff.png). Both paths are in backend's allow-list (`.github/scripts/ownership-check.sh:15`); the CI ownership check passed |
| AC5: CI "Python M0 unit tests" job runs `tests/test_evals_data.py`, pass count ≥ 47 | ✅ | Head job log: `python3 -m pytest -q tests/test_m0.py tests/test_evals_data.py` → `50 passed`. Baseline main job log: `pytest -q tests/test_m0.py` → `3 passed`; `test_m0.py` has 3 tests and `test_evals_data.py` collects 47, so 50 = 3 + 47 [05](evidence/05-ac5-ci-python-job.png). No extra CI package was needed and `requirements*.txt` is unchanged |

## PRD fit
Yes. Product PRD §8 gates quality on the `evals/*.jsonl` datasets. With this change the CI job that runs on every PR checks those datasets' schema, sizes, corpus membership and unique IDs, and per-run `make eval` outputs can't be committed by accident. That closes the EVAL-1 AC5 / QA r3 finding 8 follow-up. Contracts, thresholds and eval gates are untouched.

## Findings
1. [spec] Stale docs that AC4 doesn't allow fixing in this PR: `CONTRIBUTING.md:23` still says ``make test-unit`` = "Go tests + `pytest tests/test_m0.py`", and `README.md:199` lists only `pytest tests/test_m0.py` as the unit run. AGENTS.md DoD 4 asks for CONTRIBUTING to be updated when commands change, but AC4 limits the diff to `.gitignore` + `Makefile`. pm-lead: either relax AC4 to allow a one-line CONTRIBUTING/README update in this PR, or open a backend follow-up. This doesn't block, because the developer followed the ticket.
2. [spec] AC5 asks for "its pass count", but `pytest -q` prints one combined summary for both files (`50 passed`). I derived the 47 by comparing against main's `3 passed` and the collected counts ([05](evidence/05-ac5-ci-python-job.png)). That proof is fine. If a separate per-file count is ever wanted, the AC (or the recipe) has to ask for it explicitly.
3. [nit] Both files run in one pytest invocation, so a collection error in `tests/test_m0.py` (e.g. no torch in an agent sandbox) aborts the whole run and the eval-data tests don't execute either ([02](evidence/02-ac2-test-py.png)). In CI this doesn't matter because torch is installed. Locally, `python3 -m pytest -q tests/test_evals_data.py` (as in `evals/README.md:67`) remains the workaround. No change requested.

## Missing tests
- None required. The change adds no new test logic and wires existing tests into the suite. The mutation check ([06](evidence/06-mutation-eval-data.png)) shows the newly wired tests catch broken eval data (duplicate case ID; relevant paper missing from `evals/corpus.txt`), so CI now fails on those cases.

## Hand-off
PASS → pm-lead final review (see [spec] items 1-2).
