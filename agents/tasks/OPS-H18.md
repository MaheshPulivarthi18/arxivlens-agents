# OPS-H18: Split `make test-py` so the non-ML Python tests run without torch, first in CI

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 (harness) |
| **PRD ref** | Technical PRD §10 (Testing and evaluation) / `CONTRIBUTING.md` Commands table; the `make test-py` split item in the 2026-11-03 external-review plan that Mahesh approved (PROGRESS 2026-11-03 "pm-lead — external-review plan specced", Backlog bullet; board Backlog). *Not* a GitHub review of ArxivLens #12: #12 has no review or comment from Mahesh. The earlier "Mahesh's #12 review" label was pm-lead's shorthand (QA OPS-H18 r1 `[spec]` finding 4) |
| **Depends on** | none open. No open PR touches `Makefile`, `.github/workflows/ci.yml`, `CONTRIBUTING.md` or `requirements*.txt` (checked 2026-11-21 01:00Z against the file lists of #91–#101). The app `README.md` doesn't mention `test-py`, so it is not in scope (it is held by #93 anyway) |
| **Jira** | KAN-107 (epic KAN-3 "Dev harness & infrastructure"; labels `task-OPS-H18`, `agent-backend`, `arxivlens`) |
| **Design required** | no: Makefile targets, one CI job's steps and a deps file; no product code, no contract |
| **Status** | Ready to merge: PR [#103](https://github.com/MaheshPulivarthi18/ArxivLens/pull/103) @ `2242efe`, QA r1 PASS, PM APPROVE 2026-11-21, raised for review (label `ready-to-merge`) |

## Goal
Mahesh's approved 2026-11-03 external-review plan (PROGRESS 2026-11-03) asks for `make test-py` to be split so the eval-data tests still run when the ML stack
(torch / sentence-transformers) fails to install or import. Today one `pip install -r requirements-dev.txt` (torch, transformers,
sentence-transformers, PyMuPDF) runs before any Python test, and `test-py` runs all six files in one pytest call. A torch install or
import failure therefore hides the results of three test files that need none of it. The same split lets agent sandboxes and
contributors without the ML stack, the BGE download or Hugging Face access run those three files locally.

Checked on `origin/main` `230f617`, top-level imports per file:
- **ML** (torch / transformers / PyMuPDF / BGE download): `tests/test_m0.py` (torch, `scripts.m0_skeleton`), `tests/test_verify.py`
  (torch, `services.embedder.verify`), `tests/test_processor_pages.py` (pymupdf, `TokenChunker`, `ProcessorWorker`).
- **Light**: `tests/test_evals_data.py` (stdlib scripts; `psycopg` only through `importorskip`), `tests/test_worker_heartbeat.py`
  (`services.common.kafka_client`: confluent-kafka, ulid-py, pydantic), `tests/test_arxiv_replay.py` (stdlib).

The names differ from Mahesh's `test-m0` / `test-evals-data` because the list has grown from two files to six. Each new target
covers a group, not one file. If he prefers other names he can say so on the PR.

## Scope
- `Makefile`: new `test-py-light` (the three light files) and `test-py-ml` (the three ML files), each with a `##` help line.
  `test-py` runs both (prerequisites or two pytest calls) and still covers exactly the same six files. `test-unit` is unchanged.
  Add the targets to `.PHONY`.
- New `requirements-light.txt`: the minimal deps for `test-py-light` (pytest plus the runtime subset it imports, e.g. pydantic,
  confluent-kafka, ulid-py). Use the same lower bounds as `requirements.txt` / `requirements-dev.txt`, with a header comment saying
  it is a subset and must stay in sync. No torch, transformers, sentence-transformers or PyMuPDF.
- `.github/workflows/ci.yml`, `python` job only (keep the job id and its name `Python M0 unit tests`): before the full install,
  add a step that installs `requirements-light.txt`, prints `pip list` filtered for `torch|transformers|sentence|PyMuPDF`
  (it must print nothing, so the log proves they're absent), and runs `make test-py-light`. Then the existing full install and
  `make test-py-ml`, replacing `make test-py`. The `test_kafka_client.py` step stays as it is.
- `CONTRIBUTING.md`: the `make test-unit` row (`:23`) and two new rows for `make test-py-light` (needs only
  `pip install -r requirements-light.txt`) and `make test-py-ml`.
- Out of scope: `README.md`, `stack.yml`, moving tests between files, adding new test files to `test-py` (e.g. ING-8's scorer
  tests, which aren't on `main`), `test_kafka_client.py` (it stays in its own step).
- Size: ~30-40 lines.

## Acceptance criteria
- [ ] AC1: `make test-py-light` runs exactly `tests/test_evals_data.py tests/test_worker_heartbeat.py tests/test_arxiv_replay.py`,
  `make test-py-ml` runs exactly `tests/test_m0.py tests/test_verify.py tests/test_processor_pages.py`, and `make test-py`
  runs all six. Show `make -n` for each of the three targets in an evidence file.
- [ ] AC2 (isolation, CI): in the draft PR's CI `Python M0 unit tests` job, the light step runs **before** any torch install. The
  `pip list` filter step prints no `torch`/`transformers`/`sentence-transformers`/`PyMuPDF` line, and `make test-py-light`
  passes. Quote its pytest summary line (`N passed …`) and the run/job ID.
- [ ] AC3 (no lost coverage): the sum of the passed and skipped counts of `make test-py-light` + `make test-py-ml` in that job
  equals the `make test-py` counts on the latest green `main` run of the same job (quote both runs' summary lines and IDs).
  If they differ, explain each test that is missing.
- [ ] AC4: `make help` lists `test-py-light` and `test-py-ml` with their descriptions (evidence: `make help` output).
- [ ] AC5: all other CI jobs are green on the draft PR (`Go (vet, gofmt, test, build)`, `Frontend (lint, test, build)`, `Agent ownership check`, and `Full stack`, which
  the `Makefile` and `requirements*.txt` path filters trigger).
- [ ] Docs: the `CONTRIBUTING.md` Commands table matches the new targets (AC1 file lists, and "No" in *Needs infra?*).

## Verification
```bash
make -n test-py-light; make -n test-py-ml; make -n test-py; make help | grep test-py
python3 -m venv /tmp/light && /tmp/light/bin/pip install -r requirements-light.txt && PY=/tmp/light/bin/python make test-py-light   # if the sandbox reaches PyPI; else CI (AC2)
git diff origin/main --name-only   # Makefile, requirements-light.txt, .github/workflows/ci.yml, CONTRIBUTING.md
# CI: Python M0 unit tests job on the draft PR (AC2/AC3), compared with the latest green main run of that job
```

## Notes
- 2026-11-21 01:00Z (pm-lead): Backlog since Mahesh's #12 review. Earlier groomings left it because they assumed the app `README.md`
  Testing block mentions `test-py`. It doesn't (`grep test-py README.md` is empty on `230f617`), so the task is independent of #93.
  The job name stays `Python M0 unit tests` so the history and any check names stay comparable (`main` has no branch protection
  today, so renaming wouldn't break a required check, but there is no reason to rename it).
- If `test_worker_heartbeat.py` turns out to need more than the listed light deps at import time, add exactly what it imports to
  `requirements-light.txt` (never torch or transformers). If one of the "light" files really needs the ML stack, move it to
  `test-py-ml` and say why in the PR.
- 2026-11-21 (backend-engineer): Built in worktree `/root/wt/OPS-H18`, commit `2242efe` (4 files, +33/-8; ownership check OK, 41 lines).
  `Makefile`: `PY_LIGHT_TESTS`/`PY_ML_TESTS` vars, `test-py-light`, `test-py-ml`, `test-py: test-py-light test-py-ml`, `.PHONY`; help
  column widened 12→14 so `test-py-light` aligns. `requirements-light.txt`: pytest, **numpy**, pydantic, confluent-kafka, ulid-py.
  numpy is needed because `scripts/evaluate_retrieval.py:386` imports it lazily in `run_retrieval_evaluation()`, and 8
  `test_evals_data.py` tests call it (torch and psycopg are stubbed there, numpy isn't). Found by running the two light files with an import
  blocker for torch/transformers/sentence_transformers/fitz/pymupdf/numpy/psycopg (8 failed, all `blocked: numpy`); with numpy
  allowed: `133 passed, 1 skipped`. `test_worker_heartbeat.py` wasn't run locally (no confluent-kafka; PyPI DNS fails in the sandbox).
  CI step: `pip install -r requirements-light.txt`, then `if pip list | grep -iE 'torch|transformers|sentence|PyMuPDF'; then exit 1`
  (an explicit `if`, because a `!`-negated pipeline doesn't trip `bash -e`), then `make test-py-light`, then the full install and `make test-py-ml`.
  AC3 baseline: the latest green `main` CI run 44797226987, job 136502157925 (`230f617`), `make test-py` → `195 passed, 3 skipped, 3 warnings`.
  AC2/AC3/AC5 are CI-only.
- 2026-11-21 (pm-lead, final review): **APPROVE**. All 5 ACs + Docs checked off with CI evidence (pack @ `b5c9e81`). QA `[spec]` finding 4 fixed
  above: the source is the Mahesh-approved 2026-11-03 external-review plan recorded in PROGRESS, not a GitHub review on #12. The PR description
  says the same. QA nits 1 (guard fails open on a `pip list` error: add `set -o pipefail`) and 3 (stale `test-unit` help text) → board Backlog
  (backend, P3, fold into the next Makefile/`ci.yml` change). Nit 2 (prerequisites stop at a light failure locally) is accepted as is. PR #103 raised.
  Lesson: cite the PROGRESS entry for requests that came in through plans or attachments, not a PR number.
