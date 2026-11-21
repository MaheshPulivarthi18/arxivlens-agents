[qa-reviewer] **PASS**: OPS-H18b round 1 on `246d6d1`

_Note: the QA harness refused to write `agents/reviews/OPS-H18b/report.md`. This comment is the full report; the orchestrator saves it verbatim. Evidence is committed at [`6cd7729`](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/6cd77291c6064eab9643cccd6289bd3ac3e23bc4/agents/reviews/OPS-H18b/evidence)._

# QA report — OPS-H18b · PR #113 · round 1

**Verdict:** PASS
**Reviewed commit:** `246d6d1dbea33501faccea3f8685ac4397d407e5` · **Date:** 2026-11-21
**Ticket:** `agents/tasks/OPS-H18b.md` · **PRD:** Technical PRD §10 (Testing and evaluation); source QA OPS-H18 findings 1 and 3

PR state at review: open, draft, not merged, 0 reviews, 0 comments. Base `origin/main` = `11c4696`, and CI ran on merge commit `8349c0f` (246d6d1 into 11c4696).

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI 136840015159 | pass |
| Python M0 unit tests | CI 136840015212 | pass (light step 157 passed / 1 skipped; ML step 60 passed / 2 skipped; Kafka 37 passed) |
| Frontend (lint, test, build) | CI 136840015210 | pass |
| Agent ownership check | CI 136840015089 + local `ownership-check.sh` | pass ("Ownership OK for role=backend (6 changed lines)") |
| DB / Full stack (not AC4 checks) | CI 136840015327 / 136840015421 | pass / pass (Full stack finished during the review) |
| Ticket verification commands | local, at the PR head | `make help \| grep test-unit` OK; real `run:` block under `bash -e` with stubs: 3/3 AC branches plus 3 extra cases OK |
| `make test-unit` / `make lint` | not run locally: the diff has no Go/Python/frontend code (CI yml + help string only), so CI is the source of truth | — |
| `make eval` | not run: no retrieval/answering change | n/a |
| shellcheck | not run locally: not installed in the sandbox | — |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: fail closed on `pip list` error with a distinct `::error::`; ML-present error unchanged; pass otherwise | ✅ | [01](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6cd77291c6064eab9643cccd6289bd3ac3e23bc4/agents/reviews/OPS-H18b/evidence/01-AC1-AC2-guard-branches-head.png?raw=true): `` head block `fail` → exit 1 `::error::pip list failed; cannot check for the ML stack`; `torch` → exit 1 `::error::ML stack present before the light tests`; `light` → exit 0, reaches `make test-py-light`. Extra cases: lowercase `pymupdf` → ML error; partial output then exit 2 → pip error; `torch` printed then exit 2 → still fails. Base control [02](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6cd77291c6064eab9643cccd6289bd3ac3e23bc4/agents/reviews/OPS-H18b/evidence/02-AC1-base-control-main.png?raw=true): ``` on `origin/main` the same harness gives `fail` → exit 0 and reaches the light tests, so the bug reproduces. Mutants [03](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6cd77291c6064eab9643cccd6289bd3ac3e23bc4/agents/reviews/OPS-H18b/evidence/03-AC1-mutants.png?raw=true): ```` 6/6 behaviour mutants KILLED (drop either `exit 1`, `\|\| true`, `export pkgs=…` masking the status, wrong here-string variable, revert to the old pipe guard). The equivalent control (unquoted assignment) SURVIVED, as expected. |
| AC2: three branch outputs from a local `bash -e` run of the exact `run:` block; real CI step passes | ✅ | [01](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6cd77291c6064eab9643cccd6289bd3ac3e23bc4/agents/reviews/OPS-H18b/evidence/01-AC1-AC2-guard-branches-head.png?raw=true) ````` shows the full outputs and exit codes. The block comes from `HEAD:.github/workflows/ci.yml` via PyYAML, and the extractor asserts there is no `defaults`/`shell` override (harness sources: [07](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6cd77291c6064eab9643cccd6289bd3ac3e23bc4/agents/reviews/OPS-H18b/evidence/07-harness-sources.png?raw=true)). `````` CI: [05](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6cd77291c6064eab9643cccd6289bd3ac3e23bc4/agents/reviews/OPS-H18b/evidence/05-AC4-python-step-log.png?raw=true) ``````` shows step 5 `success` under `shell: /usr/bin/bash -e {0}`. The PR body has exit codes and error lines, not the raw outputs (nit 1). |
| AC3: `make help` names what `test-unit` runs | ✅ | [04](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6cd77291c6064eab9643cccd6289bd3ac3e23bc4/agents/reviews/OPS-H18b/evidence/04-AC3-make-help.png?raw=true): ```````` `test-unit      Fast tests, no infra (Go + test-py). Frontend tests: make test-fe`, which matches the recipe `test-unit: test-go test-py`. |
| AC4: the four named checks are `success`; the step log shows the header, no package line, then the pytest summary | ✅ | [00](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6cd77291c6064eab9643cccd6289bd3ac3e23bc4/agents/reviews/OPS-H18b/evidence/00-ci-checks.png?raw=true): ````````` all 6 check runs are `completed success` on `246d6d1…`. [05](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6cd77291c6064eab9643cccd6289bd3ac3e23bc4/agents/reviews/OPS-H18b/evidence/05-AC4-python-step-log.png?raw=true): `````````` job `head_sha=246d6d1…`. Log line 240 is `ML packages installed (must be none):`, line 241 goes straight to `python3 -m pytest -q tests/test_evals_data.py tests/test_worker_heartbeat.py tests/test_arxiv_replay.py`, and line 245 is `157 passed, 1 skipped in 4.11s`. No `::error::` output lines. |
| AC5: only `ci.yml` + `Makefile`, < 30 lines | ✅ | [06](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6cd77291c6064eab9643cccd6289bd3ac3e23bc4/agents/reviews/OPS-H18b/evidence/06-AC5-diff-scope.png?raw=true): ``````````` 2 files, +4/−2 (6 lines). The ownership script reports OK. The regex and all other steps are unchanged. |
| Docs: none needed, and the PR says so | ✅ | PR body: "Docs: none needed (CONTRIBUTING.md:23 already correct; README does not describe `test-unit`)". |

## PRD fit
Technical PRD §10 relies on the light Python tests proving they run without the ML stack. The absence guard could pass silently when `pip list` failed. It now fails closed, so a green light step really means "no torch/transformers/sentence-transformers/PyMuPDF installed". The `make help` text now matches what `make test-unit` runs. No product behaviour, contract, threshold or eval gate changed.

## Findings
1. [nit] AC2 asks for "three outputs and exit codes pasted in the PR". The PR body has a one-line summary per branch (exit code + error line), not the raw outputs. QA evidence 01 has the full outputs; pm-lead can embed it when raising the PR. No rework needed.
2. [nit] `pip list` no longer has `2>/dev/null`, so pip warnings on stderr (e.g. the new-version notice) will now show between the header and the pytest line. That is arguably better for diagnosis and is not a stdout package line, so AC4 holds. Noted so a reader doesn't take a warning for a package line.
3. [nit] If `pip list` prints an ML package and *then* exits non-zero, the step reports `pip list failed` rather than `ML stack present` (evidence 01, `torchfail`). It still fails closed, and AC1 doesn't specify which error wins. Informational only.

No blocking findings.

## Missing tests
- None required: this is a CI-shell change with no unit-test surface. The local harness (07) covers the 3 AC branches, 3 edge cases and 7 mutants, and can be reused if the guard changes.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_


_Provenance: saved verbatim by the orchestrator from the [qa-reviewer] PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/113#issuecomment-7062461530 (the QA harness refused to write report.md)._
