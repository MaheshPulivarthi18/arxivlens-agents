<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/issues/comments/7055168728 (QA harness could not write report.md), per sprint.md Step 5. -->

[qa-reviewer] **QA report: OPS-H6d · PR #102 · round 1 · Verdict: PASS**

**Reviewed commit:** `5ba967b2d0de5b2afe3f70d52f9a7bb8000d812b` · **Date:** 2026-11-21 · **Ticket:** [agents/tasks/OPS-H6d.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/OPS-H6d.md) · **PRD:** Product PRD OPS-3; Technical PRD §8.1 L3; OPS-H6 design follow-up G2 · **Jira:** KAN-106
**Evidence pack:** [agents/reviews/OPS-H6d/evidence @ c466911](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence) (each `.png` has a `.txt` with the full output)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136675405855 | pass |
| Python M0 unit tests (`make test-py`) | CI job 136675405871 | pass (`199 passed, 3 skipped`, includes `tests/test_processor_pages.py`) |
| Full stack (compose + make test-full) | CI run 44848933981, job 136675405937 | pass (`253 passed, 1 skipped, 3 deselected`; the 3 deselected are the tracked F1 tests) |
| Agent ownership check | CI job 136675405930 | pass; local `ownership-check.sh` → `Ownership OK for role=backend (195 changed lines)` |
| Frontend / DB (migrate twice, HNSW) | CI | pass / pass |
| Unit tests (ticket verification) | local, heavy imports stubbed | `9 passed` (`-k save_chunks`) |
| Real-DB test (ticket verification) | local PG 16.15 + QA psql-backed psycopg stand-in | head `1 passed`, 0 rows left behind; `origin/main` `db.py` fails it |
| ruff (ticket verification) | local, ruff 0.16.9 | 2 findings, both also on `origin/main` (none on added lines) |
| `make eval` | not run | Reason: no ranking, prompt or answer change. The change only affects what a re-save of an already-chunked paper leaves in the tables, and the ticket doesn't ask for eval. The sandbox also has no stack or HF. |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 changed text → all vectors dropped, `existing_model=None` | ✅ | `db.py` +99-111: delete with `USING paper_chunks … content_hash <> %s` before the upsert, no model filter. DB test asserts both models' vectors are gone and `get_chunks_for_embedding` → `{0: MODEL, 1: None}`. CI PASSED ([02](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/02-AC6-ci-fullstack-db-test.png)). `` Mutants m1, x1 (delete moved after the upsert), x2 (not scoped to paper), x3 (one model only) KILLED ([06](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/06-AC7-mutants.png ```)) |
| AC2 same hash → row id and vector (embedding + `created_at`) kept | ✅ | DB test `after_a[0] == before_a[0]` compares id, hash, page, `{model: (embedding::text, created_at)}`. Vectors are inserted with an explicit 2020 `created_at`, so a delete-and-reinsert would show. m2 (ignore hash) KILLED ([06](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/06-AC7-mutants.png ````)) |
| AC3 stale tail removed with cascade, other papers untouched, empty list → no chunks | ✅ | `db.py` +150-155 `DELETE … WHERE paper_id = %s AND NOT (chunk_index = ANY(%s::int[]))`. DB test checks the orphan count `(0,0,0)` for chunk/vector/page rows, paper B equal after every step, a non-contiguous `[1]` save, and `[]` → no chunks. The real-driver empty-list step is green in CI. m3, m4, m5a/b/c, x4 (skip on empty) KILLED ([06](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/06-AC7-mutants.png `````)) |
| AC4 no commit; new statements on the caller's cursor, before the status `UPDATE` | ✅ | [08](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/08-AC4-statement-order.png): `````` order is vector delete → upsert → page row → tail delete → status `UPDATE`, with 0 `commit()`. Unit tests assert `commits == 0`, `calls[-2]` = tail delete, `calls[-1]` = status update. x5 (tail after update) and x6 (commit inside) KILLED by the unit tests |
| AC5 unit tests pin both statements and params; ING-11 assertions kept | ✅ | `test_save_chunks_page_rows` only re-indexes `calls[1]`→`calls[2]` and **adds** a `calls[1]` assertion; nothing dropped. New `test_save_chunks_reprocess_deletes[contiguous\|gaps\|single-not-zero\|empty]` pins the exact SQL, `(paper_id, index, new hash)`, the kept index list and the order. CI ([03](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/03-AC5-ci-unit-tests.png)), ``````` local ([04](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/04-AC1-AC5-local-unit.png)) ```````` |
| AC6 real-Postgres test, rolled back, green in Full stack | ✅ | CI Full stack run **44848933981**, step `AC4: make test-full` (`-rA`), log line 3975: `PASSED tests/test_chunk_reprocess_db.py::test_reprocess_drops_stale_vectors_and_tail`; job total `253 passed, 1 skipped, 3 deselected` ([02](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/02-AC6-ci-fullstack-db-test.png)). ````````` The step exits with pytest's rc (`stack.yml:279-293`). Fixture: `finally: c.rollback()`. Local: 0 rows left after the test ([05](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/05-AC6-local-db-test-head-vs-base.png)) `````````` |
| AC7 mutants m1–m5 each fail ≥1 test | ✅ | QA ran 13 mutants (m1, m2, m3, m4, m5a `> max`, m5b keeps the next stale index, m5c drops the last kept index, x1–x6) against the unit and DB tests. All KILLED, head control green, `origin/main` `db.py` control fails both suites ([06](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/06-AC7-mutants.png ```````````)). Every DB failure is a test `AssertionError`; none comes from the harness |
| AC8 CI green; ruff clean on added lines | ✅ | [00](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/00-ci-checks.png ````````````): 6/6 completed success. [07](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/07-AC8-ruff-head-vs-base.png): ````````````` `db.py:1` F401 and `test_processor_pages.py:212` E501 both exist on `origin/main` |
| Docs | ✅ n/a | No command, API or schema change. pm-lead updates the Technical PRD §8.1 L3 row after merge |

**Scope** ([01](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c4669112de930e4fae25158bafea50d755d93a32/agents/reviews/OPS-H6d/evidence/01-scope-ownership.png)): `````````````` exactly the 3 files in the ticket (+193/−2). No embedder, schema, event or HTTP change, and nothing leaked. The PR body matches the ticket, KAN-106 and the file list. Open-PR overlap: only #98 touches a related file (`tests/test_m2_pipeline.py`). It uses only `>=` counts and no id/sequence assumptions, so this test's rolled-back inserts can't break it.

## PRD fit
This delivers OPS-3 ("Reprocessing never creates duplicate rows or embeddings") for the two cases it didn't cover:
- A changed chunk no longer keeps the vector of its old text. L3 re-embeds it, and identical chunks are still never re-embedded.
- A shorter re-parse no longer leaves searchable stale chunks.

It's all in the L2 transaction (no commit), it only uses deletes and existing cascades, and the contracts are unchanged.

## Findings
1. [nit] The stale-vector check costs one `DELETE … USING` round trip per chunk. This is fine at today's ~10²-chunk papers. One set-based statement (`unnest(%s::int[], %s::text[])`) would do the same work if processor save time ever matters.
2. [nit] Two parts of AC4 are pinned only by the FakeConn unit tests: "tail delete before the status update" and "no commit". Mutants x5 and x6 pass the DB test. That's fine per AC4/AC5. Recorded so nobody later drops those unit assertions as "covered by the DB test".
3. [spec] The residual embedder/processor race lives only in the ticket Notes. Suggest pm-lead create the follow-up backlog task (ai + backend: make `save_chunk_embeddings` conditional on `content_hash`).

No blocking findings.

## Missing tests
- None blocking. Optional extra: an end-to-end DB case where a re-parse **grows** the paper (indexes past the old max). The unit `gaps` case covers it in logic.

## Local environment notes
- The sandbox has no psycopg, pgvector, pymupdf or transformers, and PyPI is unreachable. Running a psycopg clone was refused by the sandbox permission classifier, so I didn't use it.
- Local DB runs used PG 16.15 with migrations 000001/000003/000005 (`halfvec(768)` replaced by a `text` domain, the HNSW migration skipped) and a QA-written psql-backed stand-in. They are logic checks only. The real-driver + pgvector result is CI run 44848933981.
- My harness refused to write `agents/reviews/OPS-H6d/report.md`. This comment is the report; the orchestrator saves it verbatim.

## Hand-off
PASS → pm-lead final review


---
_Generated by [Claude Code](https://claude.ai/code)_
