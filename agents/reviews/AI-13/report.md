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

---

# PM review — AI-13 · PR #126 · pm-lead

**Verdict: APPROVE** · 2026-11-27 (cycle 2026-11-27T03:59Z) · head `00e7b173b2da32606ebd7b8c2fc4d0d356029167` (QA r1 PASS at the same head; all 6 CI checks `success`)

**PRD fit.** Delivers Product PRD OPS-3 / Technical PRD §8.1 L3 on the worker side: the embedder now uses the OPS-H6e hash-guarded
write path, so a vector is saved only for the chunk text it was computed from. A chunk rewritten or tail-deleted mid-run is skipped
(no stale vector, no FK failure) and the paper still reaches `embedded` in one transaction. The log tells an operator what actually
landed ("Saved N … (M skipped: …)"), which matches the Ops-persona need for honest pipeline status.

**Scope.** Exactly the two ticketed files (`services/embedder/worker.py` +13/−6, `tests/test_verify.py` +96; 109/6 lines). No
`db.py`, schema, event or HTTP change; the OPS-H6e 4-tuple contract (`a4c0140`) is consumed as merged. Nothing missing, nothing extra.

**OPS-H6f interaction (QA OPS-H6f finding 3).** OPS-H6f's lock is deadlock-free only while the embedder saves in ascending
`chunk_index`. AI-13 keeps that: `get_chunks_for_embedding` is `ORDER BY pc.chunk_index ASC` (app `main` `services/common/db.py:183`),
the worker filters `chunks_to_embed` and appends in that same order across batches, and `save_chunk_embeddings` iterates the list
in order. AI-13 also closes OPS-H6f finding 2 (3-tuple reverse-order stale vector, P2) once merged. The files are disjoint from OPS-H6f.

**Evidence (opened every file, 00–09).**
| AC | Evidence | Proves it? |
|---|---|---|
| AC1 | 02 (local stubbed run), 03 (M01–M05 killed), 06 (both new tests `.` in CI), 07 (both `PASSED` by name in Full stack) | yes: exact id/model/hash per chunk, across 2 batches with a pre-embedded chunk skipped |
| AC2 | 02 + 07 (CI captured log `Saved 1 embeddings … (2 skipped: …)`), 03 (M06–M10, M12 killed; M11 equivalent) | yes; I agree M11 is equivalent (no-skip branch only runs when `written == len(items)`) |
| AC3 | 03 (M13–M16 killed), 02 (`marked as 'embedded'` after the skip) | yes: status set before the single commit, 0 rollbacks |
| AC4 | 03 + 04 (harness sources with sha256; controls C1 pass / C2 main fails) | yes: all named mutants killed |
| AC5 | 00 (6/6 success at `00e7b17`), 05 (test-py-ml 75 vs 73 base), 07 (443 passed; real papers `chunked`→`embedded` through the PR's embedder image; `emb_count >= 100` passed), 08 (ruff 0 on added lines) | yes |
| AC6 | "not run: write path only, vectors for unchanged chunks identical" | accepted |
| Contract | 09 (`content_hash TEXT NOT NULL`, 4-tuple path unchanged) | yes: a NULL hash can't silently skip every save |

**QA nits.** (1) No DB-backed worker race test: accepted as optional; the DB half is covered by
`test_chunk_reprocess_db.py::test_save_embeddings_only_for_current_chunk_text` (PASSED in Full stack). Not raised as a task now; revisit
if OPS-H6f's two-connection harness makes it cheap. (2) Stale PR body: fixed by this review (PR description rewritten with evidence).

**Docs.** No app README/CONTRIBUTING change needed (internal behaviour + one log line). PRD OPS-3 is already ✅; after #126 merges the
stale-vector gap QA OPS-H6f flagged is closed on the worker side, so no PRD edit is needed.

**Action:** PR #126 description rewritten with the Evidence section, marked ready for review, label `ready-to-merge`. Mahesh merges.
