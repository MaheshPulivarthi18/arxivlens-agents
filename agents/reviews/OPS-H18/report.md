<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/issues/comments/7055144386 (QA harness could not write report.md), per sprint.md Step 5. -->

[qa-reviewer] QA round 1 for OPS-H18: **PASS**

The harness refused to write `report.md`. The orchestrator will save this comment verbatim to `agents/reviews/OPS-H18/report.md`. Evidence pack: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence

# QA report — OPS-H18 · PR #103 · round 1

**Verdict:** PASS
**Reviewed commit:** `2242efe71617b5396e204b6029d11ca700bab377` · **Date:** 2026-11-21
**Ticket:** `agents/tasks/OPS-H18.md` · **PRD:** Technical PRD §10 (Testing and evaluation) / `CONTRIBUTING.md` Commands table; Mahesh's #12 review (as recorded in PROGRESS 2026-11-03 and the board Backlog)
**Design:** none (not design-required)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136675420265 | success ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/00-ci-checks.png?raw=true)) `` |
| Python M0 unit tests | CI job 136675419985 (run 44848938142) | success: light `139 passed, 1 skipped`, ml `56 passed, 2 skipped, 3 warnings`, kafka `37 passed` ([02](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/02-ac2-ci-light-step.png?raw=true), ``` [03](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/03-ac3-coverage.png?raw=true)) ```` |
| Frontend (lint, test, build) | CI job 136675418716 | success ([00](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/00-ci-checks.png?raw=true)) ````` |
| Agent ownership check | CI job 136675419060 + local run | success; local: `Ownership OK for role=backend (41 changed lines)` ([07](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/07-scope-docs.png?raw=true)) `````` |
| Full stack (compose + make test-full) | CI job 136675419194 | success ([00](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/00-ci-checks.png?raw=true)) ``````` |
| DB (migrate twice, HNSW plan + recall) | CI job 136675418721 | success ([00](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/00-ci-checks.png?raw=true)) ```````` |
| `make -n test-py-light / test-py-ml / test-py`, `make help` | local (GNU Make 4.3) | as specified ([01](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/01-ac1-make-n.png?raw=true), ````````` [04](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/04-ac4-make-help.png?raw=true)) `````````` |
| venv + `pip install -r requirements-light.txt` + `make test-py-light` | not run locally: PyPI unreachable (`No matching distribution found for ulid-py`) | CI is the evidence (AC2). Partial local run in a torch-free sandbox: `make test-py-light` on 2 of 3 files → `133 passed, 1 skipped`; `test_worker_heartbeat.py` needs `confluent_kafka`, which isn't installed here ([06](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/06-local-light-run.png?raw=true)) ``````````` |
| CI guard probe (real `ci.yml` step script, stub pip/make, `bash -e`) | local | clean env → reaches `make test-py-light`, exit 0. torch / sentence-transformers / transformers / PyMuPDF present → `::error::`, exit 1. Light tests fail → exit 1 ([05](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/05-ac2-guard-probe.png?raw=true)) ```````````` |
| `make test-unit`, `make lint` | not run locally: Go 1.25 not in the sandbox, no torch/HF | CI green (Go + Python jobs) |
| `make eval` | not run: harness-only change (Makefile, CI, deps file, docs), no retrieval or answering code touched | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: exact file sets for `test-py-light`, `test-py-ml`; `test-py` runs all six | ✅ | `make -n test-py-light` → `python3 -m pytest -q tests/test_evals_data.py tests/test_worker_heartbeat.py tests/test_arxiv_replay.py`; `make -n test-py-ml` → `... tests/test_m0.py tests/test_verify.py tests/test_processor_pages.py`; `make -n test-py` → both lines. The union is identical to `origin/main`'s `test-py` file list (`diff` exit 0), and the two sets don't overlap (0 shared files). [01](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/01-ac1-make-n.png?raw=true) ````````````` |
| AC2: light step before any torch install; filter prints nothing; `make test-py-light` passes | ✅ | Job 136675419985, run 44848938142, `head_sha` 2242efe. Step 5 "Light tests without the ML stack" (01:14:30Z) comes before step 6 "Install deps (CPU-only torch)" (01:14:41Z). `Successfully installed` in step 5 lists only annotated-types, confluent-kafka, iniconfig, numpy, packaging, pluggy, pydantic(-core), pygments, pytest, typing-*, ulid-py. Log line 241 `ML packages installed (must be none):` is followed directly by line 242, the pytest command, so the filter printed nothing. The first log line that mentions torch/transformers/sentence/PyMuPDF outside the guard text is line 246, the step-6 header. Summary: **`139 passed, 1 skipped in 4.26s`**. [02](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/02-ac2-ci-light-step.png?raw=true). `````````````` The guard fails the step when it should, shown by running the real step script under `bash -e`: [05](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/05-ac2-guard-probe.png?raw=true) ``````````````` |
| AC3: light + ml counts = main `make test-py` counts | ✅ | PR job 136675419985: `139 passed, 1 skipped` + `56 passed, 2 skipped, 3 warnings` = 195 passed, 3 skipped. Baseline: latest green `main` CI run 44797226987 (`230f617`, which is current `main` HEAD), job 136502157925 `Python M0 unit tests`: `195 passed, 3 skipped, 3 warnings in 13.36s`. **MATCH**, no missing tests. The separate `test_kafka_client.py` step is 37 passed in both runs. [03](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/03-ac3-coverage.png?raw=true) ```````````````` |
| AC4: `make help` lists both targets with descriptions | ✅ | `test-py-light  Python tests without torch: eval data, worker heartbeat, arXiv replay (pip install -r requirements-light.txt)` and `test-py-ml     Python tests needing torch/PyMuPDF: M0, verifier, processor pages (downloads BGE model on first run)`. The help column was widened to 14, so the columns still line up. [04](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/04-ac4-make-help.png?raw=true) ````````````````` |
| AC5: other CI jobs green (Go, Frontend, Agent ownership, Full stack) | ✅ | All 6 check runs on 2242efe are `completed/success`, including `Full stack (compose + make test-full)` (job 136675419194) and `DB (...)`. [00](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/00-ci-checks.png?raw=true) `````````````````` |
| Docs: CONTRIBUTING Commands table matches | ✅ | `CONTRIBUTING.md:23-25`: the `test-unit` row now reads `make test-py` (= light + ml), and the two new rows list exactly the AC1 files, with *Needs infra?* = `No`. [07](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/07-scope-docs.png?raw=true) ``````````````````` |

**Scope check:** 4 files (`.github/workflows/ci.yml`, `CONTRIBUTING.md`, `Makefile`, new `requirements-light.txt`), +33/-8, all on backend's allow-list. There are no ticket, review or doc files. `README.md` is untouched: its `test-py` count is 0, so it was correctly left out of scope. In `ci.yml`, only the `python` job changed. Its id and name (`Python M0 unit tests`) are kept, and the `test_kafka_client.py` step is unchanged. `test-unit` is unchanged (`test-go test-py`). Every package in `requirements-light.txt` uses the same lower bound as `requirements.txt`/`requirements-dev.txt` (pytest>=8.0.0, numpy>=1.24.0, pydantic>=2.5.0, confluent-kafka>=2.3.0, ulid-py), and none of them is an ML package. The file has the subset/keep-in-sync header the ticket asks for ([07](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/07-scope-docs.png?raw=true); ```````````````````` the image ends `[exit code 1]` only because the final `grep -c test-py README.md` counts 0, which is the expected result). `numpy` goes beyond the example list in the ticket. The ticket's Notes allow "exactly what it imports", and the inline comment gives the reason (`scripts/evaluate_retrieval.py` imports it lazily).

## PRD fit
Yes. Technical PRD §10 runs the no-infra unit tests on every PR. Mahesh's #12 request, as recorded, was to split `test-py` so the eval-data tests still run when the ML stack fails to install or import, and to keep `test-py` running both. This PR does that. The light group installs and runs in CI before torch is installed, and the log shows it ran without the ML stack. A torch install or import failure can no longer hide the eval-data, worker-heartbeat and arXiv-replay results. CI coverage is exactly the same (195 passed / 3 skipped). No contracts, thresholds or eval gates are touched.

## Findings
1. [nit] `if pip list 2>/dev/null | grep -iE ...` fails open: if `pip list` itself errors, grep sees no input and the guard passes silently. The risk is low, because `pip install` just ran in the same `bash -e` step. Dropping `2>/dev/null`, or running `set -o pipefail` before the `if`, would make a `pip list` failure visible. No change requested.
2. [nit] `test-py: test-py-light test-py-ml` uses prerequisites, so a failing light group stops a local `make test-py` before the ML group runs (unless `make -k`). The ticket allows this, and CI runs the two groups as separate steps, so it doesn't affect the isolation goal. Noted only for contributors.
3. [nit] (pre-existing, out of scope) The `make help` text for `test-unit` still says "(Go + M0 + eval data)", which undersells the six files. Fold it into the next Makefile change.
4. [spec] The ticket names "Mahesh's review of ArxivLens #12" as a PRD ref, but that review isn't on GitHub. REST shows 0 reviews, 0 review comments and no untagged issue comments on #12: its only comments are two `[qa-reviewer]` posts, and it was merged on 2026-11-03. The request appears to have arrived with the 2026-11-03 external-review plan (PROGRESS line 164; board Backlog). I checked the change against that recorded wording ("split `make test-py` ... so the eval-data tests still run when the ML stack fails to install/import; `test-py` keeps running both"), and it matches. Target names differ (`test-py-light`/`test-py-ml` vs `test-m0`/`test-evals-data`); the ticket explains why, and Mahesh can object on the PR. pm-lead: next time, cite the PROGRESS entry as the source, not PR #12. The Backlog line also said "update README Testing block". README has no `test-py` mention, so it rightly isn't in scope.

## Missing tests
- None required. The PR adds no test logic: it regroups existing files, and AC3 proves nothing was lost (195/3 on both sides). The one new piece of logic is the CI absence guard, which I probed locally ([05](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/05-ac2-guard-probe.png?raw=true)): ````````````````````` it trips on each of the four package names and propagates a light-test failure.

## Hand-off
PASS → pm-lead final review.

### Evidence images
**00-ci-checks** (AC5)

[00-ci-checks](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/00-ci-checks.png?raw=true) ``````````````````````

**01-ac1-make-n** (AC1)

[01-ac1-make-n](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/01-ac1-make-n.png?raw=true) ```````````````````````

**02-ac2-ci-light-step** (AC2)

[02-ac2-ci-light-step](```````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/02-ac2-ci-light-step.png?raw=true) ````````````````````````

**03-ac3-coverage** (AC3)

[03-ac3-coverage](````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/03-ac3-coverage.png?raw=true) `````````````````````````

**04-ac4-make-help** (AC4)

[04-ac4-make-help](`````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/04-ac4-make-help.png?raw=true) ``````````````````````````

**05-ac2-guard-probe** (AC2)

[05-ac2-guard-probe](``````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/05-ac2-guard-probe.png?raw=true) ```````````````````````````

**06-local-light-run** (local, partial)

[06-local-light-run](```````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/06-local-light-run.png?raw=true) ````````````````````````````

**07-scope-docs** (Scope, Docs)

[07-scope-docs](````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b5c9e81e2571582f4de0ba3263ae6048b75b86bb/agents/reviews/OPS-H18/evidence/07-scope-docs.png?raw=true) `````````````````````````````


---
_Generated by [Claude Code](https://claude.ai/code)_
