# OPS-H6e: The embedder never saves a vector for chunk text that changed or was deleted while it was embedding

| | |
|---|---|
| **Owner** | backend-engineer (the `services/embedder/worker.py` half is a separate ai-engineer follow-up, see Scope) |
| **Priority** | P2 (narrow race; data correctness) |
| **PRD ref** | Product PRD OPS-3 ("Reprocessing never creates duplicate rows or embeddings"); Technical PRD §8.1 L3 ("content hashing"); QA OPS-H6d r1 finding 3 `[spec]`; OPS-H6d ticket Notes "Known residual race" |
| **Depends on** | OPS-H6d (ArxivLens #102) **merged**: same file, `services/common/db.py` |
| **Jira** | to be created by the orchestrator when this moves to Ready (epic KAN-4 "Continuous ingestion"; labels `task-OPS-H6e`, `agent-backend`, `arxivlens`) |
| **Design required** | no: one function in `services/common/db.py`, backward compatible, no schema/event/HTTP change |
| **Status** | Backlog (waits for #102 to merge; then pm-lead re-checks open-PR overlap and moves it to Ready) |

## Goal
After OPS-H6d, a re-parse deletes the vectors of a changed chunk and deletes the chunks a shorter parse no longer has.
Two races are left when an embedder run overlaps a processor re-save of the same paper:
1. **Stale vector re-appears.** The embedder reads chunk *k* with the old text, the processor commits the new text and
   deletes *k*'s vector, then the embedder inserts the vector of the old text. The next embedder run sees a vector and
   skips *k*, so it keeps the wrong vector for good.
2. **Deleted chunk → failed message.** The embedder reads chunk *k*, the processor's tail delete removes it, then the
   embedder's insert hits the `chunk_embeddings.chunk_id` FK, and the whole message rolls back and retries (or ends in the DLQ).

`save_chunk_embeddings` should only write a vector when the chunk still exists **and** still has the `content_hash` the
vector was computed from. Otherwise it skips the vector and reports how many it skipped.

## Scope
- Files expected to change:
  - `services/common/db.py`: `save_chunk_embeddings` only. It accepts the existing 3-tuples `(chunk_id, model, vec)`
    unchanged, and also 4-tuples `(chunk_id, model, vec, content_hash)`. For a 4-tuple, the insert/upsert only happens
    when `paper_chunks` has a row with that `id` and that `content_hash` (for example `INSERT … SELECT … WHERE EXISTS
    (…)` or a locking read of the chunk row first; the developer picks and tests it). The return value is the number of
    vectors actually written. Still no commit (the caller's transaction).
  - A new or existing test file under `tests/`: FakeConn unit tests for the statement and parameters, and a
    real-Postgres test in the style of `tests/test_chunk_reprocess_db.py` (one connection, always rolled back).
- Out of scope (separate ai-engineer follow-up, board Backlog): `services/embedder/worker.py` passing
  `c["content_hash"]` as the 4th element and logging the skipped count. Until that lands the new branch is unused, so
  this task must not change behaviour for 3-tuples.
- Optional, if the loop is touched anyway: QA OPS-H6d nit 1 (one set-based statement instead of a round trip per chunk).
- No schema change (a `content_hash` column on `chunk_embeddings` would change an existing table and need an ADR).

## Acceptance criteria
- [ ] AC1: a 3-tuple call behaves exactly as on `main` (same SQL effect; the existing tests keep passing unchanged).
- [ ] AC2: a 4-tuple whose `content_hash` matches the chunk row is written (insert, or update on conflict) and counted.
- [ ] AC3: a 4-tuple whose `content_hash` no longer matches is not written, no error is raised, and it isn't counted.
  An existing vector for that chunk/model is left as it is (the processor already deleted it in the race above).
- [ ] AC4: a 4-tuple whose `chunk_id` no longer exists is skipped without an FK error, and the transaction is still usable afterwards.
- [ ] AC5: real-Postgres test covering AC2-AC4 on one rolled-back connection (shared stack DB left unchanged); green in the
  draft PR's `Full stack` run, quoted from the `-rA` summary with the run ID.
- [ ] AC6: mutants, each failing at least one test: no hash condition; no existence condition (FK error); 3-tuples routed through
  the hash path (or rejected).
- [ ] AC7: CI `Python M0 unit tests`, `Go`, `Agent ownership check` and `Full stack` green; ruff (E,F,W, line length 130) has no findings on added lines.
- [ ] Docs: none in the app repo.

## Verification
```bash
python -m pytest -q tests/test_processor_pages.py <new unit test file>
ruff check --isolated --select E,F,W --line-length 130 services/common/db.py <changed test files>
# real DB: make infra-up && make migrate && python -m pytest -v <new DB test file>
git diff origin/main --name-only
# CI: Full stack run on the draft PR -> `AC4: make test-full` step, -rA summary lines for the new DB test
```

## Notes
- 2026-11-21 (pm-lead): specced from QA OPS-H6d r1 finding 3 `[spec]` during the #102 PM review. Split into two tickets so
  each has one owner: backend makes `save_chunk_embeddings` hash-aware (backward compatible); ai then makes the worker pass
  the hash. The FK case (AC4) is new: it became reachable once OPS-H6d added the tail delete.
