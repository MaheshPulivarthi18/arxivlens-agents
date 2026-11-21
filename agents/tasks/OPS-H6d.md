# OPS-H6d: A reprocessed paper never keeps a stale vector or a stale tail chunk

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (data correctness) |
| **PRD ref** | Product PRD OPS-3 ("Reprocessing never creates duplicate rows or embeddings", P0 ✅); Technical PRD §8.1 L3 row ("content hashing"); follow-up G2 from the approved OPS-H6 design (`docs/design/OPS-H6.md:100-101`, PM decision item 4) |
| **Depends on** | none open. OPS-H6 and ING-11 (`paper_chunk_pages`, migration 000003) are merged. No open PR touches `services/common/db.py`, `tests/test_processor_pages.py` or the new test file (checked 2026-11-21 01:00Z against the file lists of #91–#101) |
| **Jira** | KAN-106 (epic KAN-4 "Continuous ingestion") |
| **Design required** | no: one function in `services/common/db.py`, no schema, event or HTTP change, no new CLI/table/service |
| **Status** | Done: ArxivLens [#102](https://github.com/MaheshPulivarthi18/ArxivLens/pull/102) merged by Mahesh 2026-11-21 as `c629bd9` (QA r1 PASS, PM APPROVE) |

## Goal
When the processor re-parses a paper that is already chunked (a DLQ replay, a redelivered `papers.downloaded` with a new
event id, or a re-ingest after a chunker/detector change), the stored chunks and vectors must match the new parse. Today two
things go stale, so search can match on text that is no longer in the chunk, or return chunks that no longer exist in the parse:

1. **Stale vector (OPS-H6 G2).** `save_sections_and_chunks` (`services/common/db.py:94-122`) upserts each chunk by
   `(paper_id, chunk_index)` and overwrites `content` and `content_hash`, but leaves its `chunk_embeddings` rows. The embedder's
   L3 check (`get_chunks_for_embedding`, `db.py:145-167`, and `services/embedder/worker.py:58`) only asks "is there a vector for
   this model?", so it skips the changed chunk. The chunk then keeps the vector of its *old* text.
2. **Stale tail.** When the new parse has fewer chunks than the stored one, the rows whose `chunk_index` isn't in the new list
   stay in `paper_chunks` with their vectors, page rows and `content_tsv`. They keep showing up in vector and BM25 search.

Checked on `origin/main` `230f617`: nothing in `services/` deletes from `paper_chunks` or `chunk_embeddings`. `chunk_embeddings`
and `paper_chunk_pages` both reference `paper_chunks(id) ON DELETE CASCADE` (`migrations/000001…:57`, `000003…:5`).

## Scope
- Files expected to change:
  - `services/common/db.py`: `save_sections_and_chunks` only. Still inside the caller's transaction (L2: no commit, no
    autocommit; `services/processor/worker.py:79-82`).
  - `tests/test_processor_pages.py`: unit tests with the existing `FakeConn`/`FakeCursor` for the new statements.
  - New `tests/test_chunk_reprocess_db.py`: real-Postgres test. It isn't added to `make test-py` (needs a DB); it runs in CI
    through `stack.yml`'s `make test-full` (no `TESTS=`, so pytest collects all of `tests/`; `stack.yml:286`, `-rA`).
- Out of scope:
  - The embedder (`services/embedder/worker.py`, `get_chunks_for_embedding`, `save_chunk_embeddings`): unchanged. Once the
    stale vector is deleted, the existing L3 `LEFT JOIN` re-embeds the chunk on the next `papers.chunked`.
  - Orphaned `paper_sections` rows past the new section count (they're not searched; leave them).
  - Schema changes: no new column or migration (a `content_hash` column on `chunk_embeddings` would change an existing table
    and need an ADR).
  - The narrow race where an embedder run that read the *old* text saves its vector after the processor's delete commits
    (see Notes). Don't fix it here.
- Size: ~20 lines in `db.py`, ~60 unit-test lines, ~100 DB-test lines.

## Acceptance criteria
- [x] AC1 (changed text → vector dropped): when a chunk at an existing `(paper_id, chunk_index)` is saved with a different
  `content_hash`, every `chunk_embeddings` row for that chunk (all models) is deleted in the same transaction. Afterwards
  `get_chunks_for_embedding(conn, paper_id, model)` returns `existing_model = None` for that chunk.
- [x] AC2 (same text → vector kept): a chunk saved again with the **same** `content_hash` keeps its `chunk_embeddings` row
  unchanged (same `embedding` and `created_at`) and keeps its `paper_chunks.id`.
- [x] AC3 (stale tail removed): after the save, the paper has exactly the `chunk_index` values in the new `chunks` list.
  Rows with any other index are deleted, and the cascade removes their `chunk_embeddings` and `paper_chunk_pages` rows.
  Chunks of **other papers** are untouched. An empty `chunks` list leaves the paper with no chunks.
- [x] AC4 (transaction): `save_sections_and_chunks` still never commits (existing `conn.commits == 0` assertions keep
  passing). The new statements run on the caller's cursor, before the `UPDATE papers SET status = 'chunked'`.
- [x] AC5 (unit tests, `tests/test_processor_pages.py`): the existing ING-11 tests keep their meaning (you may re-index
  `calls[...]` if a new statement shifts positions, but don't drop or weaken an assertion). New tests pin the statements
  from AC1 and AC3, with their parameters (`paper_id`, the chunk's index and new hash, the kept index set).
- [x] AC6 (real Postgres, new `tests/test_chunk_reprocess_db.py`): on one connection with `autocommit=False`, insert two
  synthetic papers (unique `arxiv_id`s such as `ops-h6d-a`/`ops-h6d-b`). Save 3 chunks for paper A and 1 for paper B, add a
  `chunk_embeddings` row (768-d `halfvec`) for each chunk, then save paper A again with chunk 0 unchanged, chunk 1 with new
  text and hash, and no chunk 2. Assert AC1-AC3 with SQL: chunk 0's row and vector are identical, chunk 1 has no vector and
  `get_chunks_for_embedding` reports it as missing, chunk 2 and its page and vector rows are gone, and paper B is unchanged.
  **Always roll back at the end** (`finally`), so the shared stack DB that `test_m2_pipeline.py`/`test_m3_query.py` count is
  left exactly as it was. Green in the draft PR's `Full stack` run: quote the `PASSED tests/test_chunk_reprocess_db.py::…`
  lines from the `-rA` summary of the `AC4: make test-full` step, with the run ID.
- [x] AC7 (mutants, one per case; developer or QA, with an evidence file): each of these must fail at least one test:
  m1 drop the AC1 delete; m2 delete vectors even when the hash is unchanged; m3 drop the AC3 tail delete; m4 tail delete not
  scoped to `paper_id` (paper B loses its chunk); m5 tail delete keeps one stale index (for example a `chunk_index > max`
  bound instead of "not in the new set", with the AC6 data shaped so that it matters, or an off-by-one).
- [x] AC8: CI `Python M0 unit tests` (`make test-py`), `Go (vet, gofmt, test, build)`, `Agent ownership check` and `Full stack` are green on the draft PR. Lint for the
  changed Python files: `ruff check --isolated --select E,F,W --line-length 130 services/common/db.py tests/test_processor_pages.py tests/test_chunk_reprocess_db.py`
  reports no findings on added lines.
- [x] Docs: none in the app repo (no command or API change). pm-lead updates the Technical PRD §8.1 L3 row after merge
  (docs PR here).

## Verification
```bash
python -m pytest -q tests/test_processor_pages.py            # unit (needs pymupdf + transformers tokenizer; else CI)
ruff check --isolated --select E,F,W --line-length 130 services/common/db.py tests/test_processor_pages.py tests/test_chunk_reprocess_db.py
# real DB (any host with Docker): make infra-up && make migrate && python -m pytest -v tests/test_chunk_reprocess_db.py
git diff origin/main --name-only   # exactly the three files in Scope
# CI: Full stack run on the draft PR -> `AC4: make test-full` step, -rA summary lines for tests/test_chunk_reprocess_db.py
```

## Notes
- 2026-11-21 01:00Z (pm-lead): specced from the OPS-H6 design follow-up G2 (Backlog since 2026-11-03), widened to the stale-tail
  case of the same function, which breaks the same OPS-3 promise. Both are reproducible from the code on `230f617` (no
  deletes anywhere in `services/`). This is not a schema change: deletes only, existing cascades.
- Hint, not a requirement (write the SQL you can test): before the chunk upsert, something like
  `DELETE FROM chunk_embeddings ce USING paper_chunks pc WHERE ce.chunk_id = pc.id AND pc.paper_id = %s AND pc.chunk_index = %s AND pc.content_hash <> %s`;
  after the loop, `DELETE FROM paper_chunks WHERE paper_id = %s AND NOT (chunk_index = ANY(%s))` with the list of new indexes
  (psycopg 3 adapts a Python list to an array; an empty list must delete all of the paper's chunks, so check that
  `= ANY('{}')` behaves as you expect).
- The `papers` insert in AC6 needs only `arxiv_id` (the other columns have defaults or are nullable; `migrations/000001…:5-22`).
  A `halfvec(768)` literal can be built as `'[' + ','.join(['0'] * 767 + ['1']) + ']'`.
- Known residual race (out of scope, possible follow-up for ai + backend): an embedder run that read the old text before the
  processor's transaction committed can save the old vector after the delete. The next run then sees a vector and skips. Fixing
  that means making `save_chunk_embeddings` conditional on the chunk's `content_hash` still matching, which touches the
  ai-owned embedder worker too.
- 2026-11-21 (backend-engineer): Built in worktree `/root/wt/OPS-H6d`, commit `5ba967b` (3 files, +193/-2; ownership check OK, 195 lines).
  `db.py`: per chunk, before the upsert, `DELETE FROM chunk_embeddings ce USING paper_chunks pc WHERE ce.chunk_id = pc.id AND
  pc.paper_id = %s AND pc.chunk_index = %s AND pc.content_hash <> %s` (all models); after the loop and before the status update,
  `DELETE FROM paper_chunks WHERE paper_id = %s AND NOT (chunk_index = ANY(%s::int[]))` with the new index list (explicit `int[]` cast,
  so an empty list is typed; checked on PG16: it deletes every chunk of the paper). No commit.
  Unit: existing ING-11 test re-indexed `calls[1]`→`calls[2]` and now also pins `calls[1]` = the vector delete; new
  `test_save_chunks_reprocess_deletes[contiguous|gaps|single-not-zero|empty]` pins both statements' exact SQL and params, order, and
  `commits == 0`. DB test: AC6 scenario plus two extra saves on the same rolled-back transaction: `[1]` only (kills a `chunk_index > max`
  bound) and `[]` (empty list → no chunks); paper B compared after each step; vectors inserted with an explicit 2020 `created_at`.
  Local runs (no psycopg/pymupdf/transformers, PyPI unreachable, no Docker daemon, no pgvector headers, Go 1.25 download blocked):
  FakeConn tests under self-written import stubs → `9 passed`; the DB test on a throwaway local PG16 with migrations 000001/3/5
  (`halfvec(768)` replaced by a text domain, 000002 HNSW skipped) through a self-written psql-backed psycopg test double → `1 passed`.
  Mutants m1, m2, m3, m4, m5 (`> max`), m5 (extra kept index), m5 (last index dropped) each fail the DB test, and m1–m5 each fail the
  unit tests (7/7/4/4/4 failures); `origin/main` `db.py` as a control fails the DB test. A pure-Python psycopg build from a tag clone
  was refused by the sandbox's permission classifier, so the real-driver + pgvector run is CI-only (`stack.yml` `make test-full`).
  ruff on the three files: two findings, both pre-existing on `origin/main` (`db.py:1` unused `json`, `test_processor_pages.py:212` E501); none on added lines.

- 2026-11-21 (pm-lead): PM review of #102: **APPROVE** (`agents/reviews/OPS-H6d/report.md`). PR description rewritten with the Evidence section, marked ready for review, label `ready-to-merge`. QA `[spec]` finding 3 (the race above) → specced as [OPS-H6e](OPS-H6e.md) (backend, Backlog until #102 merges) + ai worker half in the board Backlog. After merge: Technical PRD §8.1 L3 note in the next pm-lead docs PR.
