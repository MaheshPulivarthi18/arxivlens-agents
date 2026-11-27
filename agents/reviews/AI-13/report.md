<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-27T03:59Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/126#issuecomment-7210140551 ; qa-reviewer's harness could not write report.md. -->

[qa-reviewer] QA report — AI-13 · PR #126 · round 1

**Verdict:** PASS
**Reviewed commit:** `00e7b173b2da32606ebd7b8c2fc4d0d356029167` · **Date:** 2026-11-27 (cycle 2026-11-27T03:59Z)
**Ticket:** [agents/tasks/AI-13.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/AI-13.md) · **PRD:** Product PRD OPS-3; Technical PRD §8.1 L3 (content hashing)
**Evidence:** [agents/reviews/AI-13/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence) (commit `b1efe05`). The QA harness refused to write `report.md`, so this comment is the report of record; the orchestrator saves it.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 140310849079 | pass ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/00-ci-checks.png?raw=true)) `` |
| Python M0 unit tests (incl. `make test-py-ml`) | CI job 140310849323 | pass: 75 passed / 2 skipped vs 73 / 2 on base `53171d6`; both new tests map to `.` (passed) ([05](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/05-AC5-ci-python-m0.png?raw=true), ``` [06](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/06-AC5-ci-dotmap.png?raw=true)) ```` |
| Frontend / DB / Agent ownership check | CI jobs 140310849327 / 140310849258 / 140310849424 | pass |
| Full stack (compose + make test-full) | CI job 140310849043 | pass: `443 passed, 1 skipped, 3 deselected`; both new tests `PASSED` by name ([07](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/07-AC5-ci-full-stack.png?raw=true)) ````` |
| `pytest tests/test_verify.py` (new tests) | local, stubbed | 2/2 pass, with torch/psycopg/kafka/fastapi as MagicMock modules (not installed, PyPI blocked). Logic check only; CI is the source of truth ([02](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/02-AC1-AC3-new-tests-local.png?raw=true)) `````` |
| ruff E,F,W, 130 | local | 0 findings on the 109 added lines; 7 pre-existing on untouched lines ([08](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/08-AC5-ruff-added-lines.png?raw=true)) ``````` |
| `git diff origin/main --name-only` | local | exactly `services/embedder/worker.py`, `tests/test_verify.py` ([01](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/01-scope-diff.png?raw=true)) ```````` |
| `make test-unit` / `make lint` | not run locally | No Go 1.25 modules or torch in the sandbox; CI green |
| `make eval` | not run | Write path only (AC6): vectors for unchanged chunks are identical, and retrieval/answering are untouched |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: 4-tuple, 4th = that chunk's `content_hash` | ✅ | `worker.py:75` appends `(c["chunk_id"], self.model_name, vec_list, c["content_hash"])`. `test_embedder_worker_passes_each_chunks_content_hash` checks exact id/model/hash and per-chunk vectors across 2 batches, with a pre-embedded chunk in the middle. Mutants M01–M05 (3-tuple, first chunk's hash, next chunk's hash, `chunks[i+j]` index skew, missing key) are all KILLED ([03](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/03-AC4-mutants.png?raw=true)) ````````` |
| AC2: log uses the return value, plus skipped when > 0 | ✅ | `worker.py:78-84`. The CI captured log shows `Saved 1 embeddings for 2608.00001 (2 skipped: chunk text changed or removed since read)` ([07](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/07-AC5-ci-full-stack.png?raw=true)). `````````` M06–M10 and M12 are KILLED. M11 (`len()` in the no-skip branch) SURVIVES but is equivalent: that branch runs only when `written >= len(items)`, and the function never returns more than `len(items)` |
| AC3: a skip doesn't fail the message | ✅ | The status/commit lines are unchanged and outside the `else`. The test records the commit count at the moment the status is set (0), then checks 1 commit, 0 rollbacks, closed. M13 (raise on skip), M14 (no status on skip), M15 (commit before status) and M16 (rollback on skip) are KILLED |
| AC4: tests cover AC1–3; named mutants killed | ✅ | The AC's named mutants are all KILLED: hash dropped (M01), wrong hash (M02/M03), skipped ignored (M07, M06, M08). Controls: the head passes 2/2, and the PR tests against main's `worker.py` fail 2/2. 15/16 killed; the 1 survivor is equivalent. Harness sources + sha256: [04](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/04-AC4-harness-sources.png?raw=true) ``````````` |
| AC5: CI green; ruff clean on added lines | ✅ | All 6 checks show `success` on `00e7b17` ([00](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/00-ci-checks.png?raw=true)). ```````````` In Full stack, the compose `embedder-worker` (built from the PR, `CMD python services/embedder/worker.py`) took both real papers `chunked` → `embedded`, and `test_m2_pipeline.py::test_chunk_embeddings_and_pgvector_cosine_ops` (`emb_count >= 100`) PASSED. So the 4-tuple path writes real vectors ([07](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/07-AC5-ci-full-stack.png?raw=true)). ````````````` Ruff: [08](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/08-AC5-ruff-added-lines.png?raw=true) `````````````` |
| AC6: `make eval` "not run: <reason>" | ✅ | Stated in the PR body; QA agrees |
| Docs: none | ✅ | No app doc change needed |

## PRD fit
This delivers OPS-3 / §8.1 L3. A vector is written only for the chunk text it was computed from. A chunk the processor rewrote or deleted mid-run is skipped instead of being saved stale or raising an FK error, and the message still completes. The OPS-H6e contract (`a4c0140`) is unchanged by this PR, and `paper_chunks.content_hash` is `NOT NULL`, so a NULL hash can't make every save skip ([09](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1efe053aa9866bbd97da7acf03cd348745ffedd/agents/reviews/AI-13/evidence/09-contract-4tuple-path.png?raw=true)). ``````````````` Scope: 2 ai-engineer-owned files, +109/−6. No leaked ticket/review/doc files, and no contract, threshold or gate change.

## Findings
1. [nit][test] The worker-level skip is tested only through a fake `save_chunk_embeddings`. No DB-backed `process_message` run injects a hash change between read and save. The DB half is covered by `test_chunk_reprocess_db.py::test_save_embeddings_only_for_current_chunk_text` (PASSED in Full stack), and the ticket asked for fakes, so this is not blocking.
2. [nit] In the PR body's Verification table, `-k embedder_worker` "3 passed": at this head that `-k` selects 5 tests (it also matches `test_ingest_embedder_worker_*`). AC5 is also still unchecked ("pending") although CI is green. pm-lead rewrites the body when raising.

No blocking findings.

## Missing tests
- Optional: a DB-backed `process_message` run with a hash change injected between `get_chunks_for_embedding` and `save_chunk_embeddings`, asserting no stale vector and status `embedded`.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_
