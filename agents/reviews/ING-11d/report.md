<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/98#issuecomment-7049983961 (QA harness could not write report.md); role tag and footer removed. -->

# QA report: ING-11d · PR #98 · round 1

**Verdict:** PASS
**Reviewed commit:** `03fa179149ea3d42acc830268df19c52e64ed85a` · **Date:** 2026-11-20
**Ticket:** `agents/tasks/ING-11d.md` · **PRD:** Product PRD QA-3 (M2 pipeline tests), follow-up to ING-11c QA nit 1
**Evidence pack:** [agents/reviews/ING-11d/evidence](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/451b86a8d1ec95f66e9dac09dc5642dded474dd7/agents/reviews/ING-11d/evidence) (commit 451b86a)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136544848221 | pass |
| Python M0 unit tests | CI job 136544848934 | pass |
| Frontend (lint, test, build) | CI job 136544848715 | pass |
| Agent ownership check | CI job 136544848597 | pass |
| DB (migrate twice, HNSW plan + recall) | CI job 136544848379 | pass |
| Full stack (compose + make test-full) | CI run 44810305214 / job 136544848630 | pass (merge `b7bfe8c` = 03fa179 into main 230f617) |
| Ticket verification commands | local worktree at 03fa179, ruff 0.16.9, Python 3.13 | ruff clean, py_compile OK, diff 1+/2-, 3 tests collected (psycopg stubbed) |
| `make eval` | not run: lint-only test-file change, no retrieval/answering code | n/a |

[00-ci-checks](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/451b86a8d1ec95f66e9dac09dc5642dded474dd7/agents/reviews/ING-11d/evidence/00-ci-checks.png?raw=true) ``

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 ruff clean | ✅ | [01-ruff-before-after.png](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/451b86a8d1ec95f66e9dac09dc5642dded474dd7/agents/reviews/ING-11d/evidence/01-ruff-before-after.png?raw=true): ``` base 230f617 has `F401` 2:8 and `W293` 57:1, `Found 2 errors.` (exit 1). The head prints `All checks passed!` (exit 0). |
| AC2 no other change | ✅ | [02-diff-scope.png](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/451b86a8d1ec95f66e9dac09dc5642dded474dd7/agents/reviews/ING-11d/evidence/02-diff-scope.png?raw=true): ```` 1 file, 1 insertion and 2 deletions (`-import pytest`, whitespace-only line → empty). 0 changed lines mention `assert`. `grep -n "pytest\."` and `grep -nw pytest` return no match. |
| AC3 compile + same collection | ✅ | [03-compile-collect.png](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/451b86a8d1ec95f66e9dac09dc5642dded474dd7/agents/reviews/ING-11d/evidence/03-compile-collect.png?raw=true): ````` `py_compile OK`. HEAD and main have the same 3 test functions (AST), and `--collect-only` collects the same 3 ids on both. The sandbox has no real `psycopg`, so a collection-only stub (source shown in the image) was used. AC4 is authoritative. |
| AC4 stack.yml green, PASSED lines | ✅ | [04-stack-m2-passed.png](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/451b86a8d1ec95f66e9dac09dc5642dded474dd7/agents/reviews/ING-11d/evidence/04-stack-m2-passed.png?raw=true): `````` run 44810305214, step `AC4: make test-full` = success, 3× `PASSED tests/test_m2_pipeline.py::…` (sections_and_chunks_stored, chunk_embeddings_and_pgvector_cosine_ops, embedded_chunks_have_recorded_start_pages), `248 passed, 1 skipped, 3 deselected`. Baseline is the latest green stack.yml on another PR (OPS-H5c run 44810300544, same main 230f617). The test_m2 set and the full 248-id PASSED set are identical. |
| Docs: none | ✅ | No behaviour or command change. |

## PRD fit
Hygiene only, with no behaviour change. The M2 pipeline tests that guard QA-3's page/section provenance pass as the same set in CI, and the file is now lint-clean as the ING-11c follow-up intended.

## Findings
1. [nit] (observation, not caused by this PR) The `continue-on-error` step "Known failure F1 (CPU rerank latency, tracked)" failed 3 of 3 with `ReadTimeout` in job 136544848630. The baseline passed 3 of 3. The F1 step runs only test_m3 ids (0 test_m2 lines), and stack.yml documents it as expected to fail on CPU runners, so this is runner latency: [05-known-failure-f1.png](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/451b86a8d1ec95f66e9dac09dc5642dded474dd7/agents/reviews/ING-11d/evidence/05-known-failure-f1.png?raw=true). ```````
2. [nit] The PR body's "PRD ref" says `ING-11 (Technical PRD pipeline tests)`, but the ticket says Product PRD QA-3. pm-lead can align them when filling in the evidence section.

## Missing tests
- None. The change is lint-only, and the existing 3 M2 tests (green in CI) are the guard.

## Hand-off
PASS → pm-lead final review



---

# PM final review: ING-11d · PR #98 · head `03fa179`

**Verdict:** APPROVE · **Date:** 2026-11-21 · **Reviewer:** pm-lead

- **Product fit:** hygiene follow-up to the ING-11c review, with no change to user-facing behaviour. The 3 M2 tests that guard QA-3 page/section provenance still pass as the same set in CI.
- **Scope:** exactly what the ticket asked for. 1 file, 1+/2-, nothing extra.
- **Evidence:** I opened all 6 files (png + txt). 00 shows all 6 checks succeeded on 03fa179. 01 proves AC1 (base `Found 2 errors.` exit 1 → head `All checks passed!` exit 0). 02 proves AC2 (stat, cat -A of the changed lines, 0 assert lines, no `pytest` token). 03 proves AC3: py_compile and identical collection on head and main. The psycopg stub is disclosed and used only for collection, and AC4 covers the rest. 04 proves AC4 (run 44810305214, 3x test_m2 PASSED, the 248-id PASSED set matches baseline run 44810300544 on the same main). Nothing important is left unverified.
- **QA nits:** (1) the F1 `continue-on-error` timeouts came from test_m3 runner latency, were there before this PR, and are already tracked on the board (drop the F1 step after AI-10). No new follow-up. (2) I corrected the PR body's PRD ref to Product PRD QA-3 when I raised the PR.
- **Docs:** none needed. The PRD QA-3 row stays ✅.

**Raised:** PR #98 description rewritten with an Evidence section (images pinned at arxivlens-agents `451b86a`), marked ready for review, label `ready-to-merge`. Waiting for Mahesh to merge.
