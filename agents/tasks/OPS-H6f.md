# OPS-H6f: A processor re-save never leaves an old-text vector under the chunk's new hash

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 (narrow race; data correctness) |
| **PRD ref** | Product PRD OPS-3 ("Reprocessing never creates duplicate rows or embeddings"); Technical PRD §8.1 L3 ("content hashing"); QA OPS-H6e r1 finding 2 / r2 finding 1 `[spec]` and nit 3 / r2 nit 2; OPS-H6e ticket Notes "Residual race" |
| **Depends on** | OPS-H6e (ArxivLens #106) **merged**: same files `services/common/db.py`, `tests/test_chunk_reprocess_db.py` |
| **Jira** | KAN-116 (epic KAN-4 "Continuous ingestion"; labels `task-OPS-H6f`, `agent-backend`, `arxivlens`) |
| **Design required** | no: one function in `services/common/db.py` plus tests, no schema/event/HTTP change, no new CLI/table/service |
| **Status** | Done (#127 merged `45792f8`) |

## Goal
OPS-H6e made the embedder's save hash-aware: with a 4-tuple it locks the chunk row `FOR SHARE` and writes only if
`content_hash` still matches. One ordering is still wrong, and it is on the processor side. `save_sections_and_chunks`
(`services/common/db.py`, OPS-H6d) first deletes a changed chunk's vectors (`DELETE FROM chunk_embeddings … AND
pc.content_hash <> %s`) and only then upserts the chunk with the new hash. The chunk row isn't locked between the two
statements, so an embedder insert that lands between them still sees the old hash, passes its guard, and writes the
old text's vector. The processor's upsert then sets the new hash, and the chunk keeps a vector of text it no longer has.
The next embedder run sees a vector and skips it, so it stays wrong for good. QA reproduced this on PostgreSQL 16
(`agents/reviews/OPS-H6e/evidence/05-AC2-AC4-real-pg-probe.png`, last block: `final: hb-new|m|[0.500000]`).

The processor must lock the paper's chunk rows before it deletes their vectors, so a concurrent embedder write either
finishes first (and its vector is then deleted) or waits and re-checks the new hash (and writes nothing).

## Scope
- Files expected to change:
  - `services/common/db.py`: `save_sections_and_chunks` only. Before step 2's per-chunk vector DELETE, lock the paper's
    existing chunk rows, e.g. one `SELECT id FROM paper_chunks WHERE paper_id = %s ORDER BY chunk_index FOR UPDATE;`
    (ascending `chunk_index`, the same order the embedder processes chunks, so the two can't deadlock). The developer may
    pick another approach (e.g. per-chunk `FOR UPDATE`) if it is tested the same way and the Notes say why. Still inside
    the caller's transaction, no commit.
  - `tests/test_processor_pages.py`: FakeConn unit test pinning the lock statement, its parameters and its position
    (before the first vector DELETE). Existing OPS-H6d/ING-11 tests may be re-indexed if a statement shifts positions;
    no assertion dropped or weakened.
  - `tests/test_chunk_reprocess_db.py`: two-connection real-Postgres tests (see AC4-AC6). Rows these tests commit must be
    deleted in a `finally` so the shared stack DB the M2/M3 suites count is left as it was; update the module docstring.
- Out of scope: `services/embedder/worker.py` (AI-13), `save_chunk_embeddings` (OPS-H6e, unchanged), schema changes.

## Acceptance criteria
- [ ] AC1: `save_sections_and_chunks` locks the paper's existing `paper_chunks` rows (`FOR UPDATE`, ascending
  `chunk_index`) before any `chunk_embeddings` DELETE, in the caller's transaction (no commit; `conn.commits == 0` kept).
- [ ] AC2: unit test pins the lock statement, its `paper_id` parameter and that it runs before the first vector DELETE.
  OPS-H6d and ING-11 unit tests keep passing without weakened assertions.
- [ ] AC3: single-session behaviour is unchanged: `test_reprocess_drops_stale_vectors_and_tail` and
  `test_save_embeddings_only_for_current_chunk_text` pass unchanged.
- [ ] AC4 (the race, real PG, two connections): session E (embedder) runs a 4-tuple `save_chunk_embeddings` for chunk *k*
  with the **old** hash and holds its transaction open; session P (processor) runs `save_sections_and_chunks` with new text
  for *k* and blocks; E commits; P completes and commits. Final state: chunk *k* has the new hash and **no** vector for
  that model. The test fails on `origin/main` after #106 (i.e. without the lock) — show that run in the PR or QA evidence.
- [ ] AC5 (reverse order, real PG, two connections): P has locked/updated *k* (transaction open); E's 4-tuple save with the
  old hash blocks, P commits, E returns 0 written and no error. This guards OPS-H6e's `FOR SHARE` (QA OPS-H6e nit): the
  test fails if `FOR SHARE OF pc` is removed from `_UPSERT_EMBEDDING_IF_CURRENT_SQL`.
- [ ] AC6: the real-PG fixture includes a chunk on **another paper** with the same `content_hash`, and a 4-tuple keyed on
  the wrong `chunk_id` with that hash writes nothing (kills the "look up by hash only" mutant without the SQL-string test).
- [ ] AC7: tests use timeouts (e.g. `SET lock_timeout` or a thread join timeout) so a broken lock can't hang CI; committed
  test rows are removed in `finally`, and a count of `papers`/`paper_chunks`/`chunk_embeddings` before and after the module
  is equal.
- [ ] AC8: mutants, each failing at least one test: no lock; lock after the vector DELETE; lock without `ORDER BY`
  is optional to kill (note it). Run locally, never pushed.
- [ ] AC9: CI `Python M0 unit tests`, `Go`, `Agent ownership check` and `Full stack` green; the new real-PG tests appear as
  `PASSED` in the `AC4: make test-full` `-rA` summary (quote with run ID). Ruff (E,F,W, line length 130) clean on added lines.
- [ ] Docs: none in the app repo.

## Verification
```bash
cd app
python -m pytest -q tests/test_processor_pages.py          # needs torch/PyMuPDF; else CI `make test-py-ml`
ruff check --isolated --select E,F,W --line-length 130 services/common/db.py tests/test_processor_pages.py tests/test_chunk_reprocess_db.py
# real DB: make infra-up && make migrate && python -m pytest -v tests/test_chunk_reprocess_db.py
git diff origin/main --name-only   # exactly services/common/db.py, tests/test_processor_pages.py, tests/test_chunk_reprocess_db.py
# CI: Full stack run on the draft PR -> `AC4: make test-full` step, -rA summary lines for the new DB tests
```

## Notes
- 2026-11-21 (pm-lead): specced from QA OPS-H6e r1 finding 2 / r2 finding 1 `[spec]` (processor-side residual race,
  reproduced on PG16) and nit 3 / r2 nit 2 + "Missing tests" (two-session `FOR SHARE` guard, duplicate-hash fixture),
  during the #106 PM review. Code refs are at app `main` `11c4696` + #106 head `f1b156e`. Backlog until #106 merges
  (same three files). Independent of AI-13 (different files), so both can be picked in the same cycle after #106 merges.
- 2026-11-22 (pm-lead, cycle 2026-11-22T02:00Z): picked. Independent of ING-6c (#124, Go + workflows): no shared files.
  #124's `Full stack` job is currently red; if OPS-H6f's own `Full stack` run fails, check whether the same failure is on
  #124/main (pre-existing) before treating it as this change's regression, and say which in the PR. AC9 still needs the
  new real-PG tests `PASSED` in the `-rA` summary.
- 2026-11-27 (pm-lead, cycle 2026-11-27T03:59Z): **re-picked** (the 2026-11-22T02:00Z cycle died before building; no
  `agent/backend/OPS-H6f` on origin). Still independent: #124 ING-6c touches Go + workflows + app `README.md` only; #122/#123 are
  `scripts/`, `evals/`, `tests/test_evals_data.py`, `tests/test_arxiv_replay.py`; AI-13 (picked alongside) is `services/embedder/worker.py` +
  `tests/test_verify.py`. `tests/test_processor_pages.py` and `tests/test_verify.py` share the `make test-py-ml` target but no file.
  The 2026-11-22 Note on #124's red `Full stack` still applies. Backend WIP after this pick: 2 (#124 + OPS-H6f).
- 2026-11-27 (backend-engineer, cycle 2026-11-27T03:59Z): built `b4b64b3` on `agent/backend/OPS-H6f` → draft PR
  [#127](https://github.com/MaheshPulivarthi18/ArxivLens/pull/127) (3 files, +198/−4; ownership check OK, 202 lines).
  `save_sections_and_chunks` runs one `SELECT id FROM paper_chunks WHERE paper_id = %s ORDER BY chunk_index FOR UPDATE;`
  after the section upserts and before any vector DELETE/chunk write (also for an empty parse). Chose the single paper-wide
  statement over per-chunk `FOR UPDATE`: one round trip, and every row is locked before the *first* DELETE.
  Tests: unit `test_save_chunks_locks_chunk_rows_before_vector_deletes` (3 cases); `test_save_chunks_page_rows` re-indexed
  by one, plus an assert for the lock. Real PG: `test_processor_resave_waits_for_inflight_embedder_write` (AC4),
  `test_embedder_write_waits_for_processor_resave_then_skips` (AC5), `test_save_embeddings_keyed_on_chunk_id_not_hash` (AC6),
  committed papers `ops-h6f-a/b` deleted in `finally`, module fixture `db_left_as_found` compares counts, `lock_timeout` 10 s,
  joins 20 s, blocking observed via `pg_stat_activity.wait_event_type = 'Lock'`.
  Test design notes: (1) AC4 races on chunk 0 (the first vector DELETE). With the race on chunk 1, "lock after the first
  DELETE" survived the real-PG test. (2) AC5's batch puts the stale chunk first. With it second, the no-`FOR SHARE` mutant
  survived: the first item's FK check waited out P's lock, so the second statement's snapshot already saw the new hash.
  Local, not CI: PG 16 (`/usr/lib/postgresql/16`), with `halfvec` as a text domain plus a normalising trigger, run through
  a psql-backed psycopg double (one `psql` per connection, so the locks are real). Head `5 passed` (×5). origin/main
  `db.py`: AC4 test FAILED (`chunk 0: old-text vector kept under the new hash`). Mutants M1-M9 all KILLED. M4 (no
  `ORDER BY`) is killed by the unit test only. M8 (no `FOR SHARE OF pc`) is killed by the AC5 test, M9 (hash-only lookup)
  by the AC6 test. Ruff on the 3 files shows only the 2 findings already on main.
  CI on `b4b64b3`: all 6 checks green. `Full stack` run 45940231278 / job 140312624580 lists all 5
  `tests/test_chunk_reprocess_db.py` tests as `PASSED` in the `-rA` summary (`447 passed, 1 skipped, 3 deselected`).
  Status → In QA.
- 2026-11-27 (pm-lead, cycle 2026-11-27T03:59Z): **PM APPROVE** ([report](../reviews/OPS-H6f/report.md)); PR #127 description
  rewritten with the evidence, marked ready for review, label `ready-to-merge`. Follow-up [OPS-H6g](OPS-H6g.md) (P3,
  test-only) pins M4/M6/M8 and the ascending-order invariant by behaviour. The reverse-order 3-tuple residue (QA finding 2)
  closes with AI-13 (#126). Status → Ready to merge.
