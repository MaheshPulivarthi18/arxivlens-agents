# OPS-H6g: Pin the processor lock's strength and coverage, and the embedder's ascending order, by behaviour

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 (harness/quality; test-only) |
| **PRD ref** | Product PRD OPS-3; Technical PRD §8.1 L3; QA OPS-H6f r1 finding 1 `[test]`, finding 3 `[code]`, "Missing tests" |
| **Depends on** | OPS-H6f (ArxivLens #127) **merged**: same file `tests/test_chunk_reprocess_db.py` |
| **Jira** | create (epic KAN-4 "Continuous ingestion"; labels `task-OPS-H6g`, `agent-backend`, `arxivlens`) |
| **Design required** | no: tests only, no schema/event/HTTP change |
| **Status** | Backlog (Ready once #127 merges) |

## Goal
OPS-H6f's lock (`SELECT id FROM paper_chunks WHERE paper_id = %s ORDER BY chunk_index FOR UPDATE;`) is pinned by an
exact-SQL unit test, but three weakenings survive every real-Postgres test (QA OPS-H6f r1, `agents/reviews/OPS-H6f/evidence/05-AC8-mutants.png`):
M6 `FOR NO KEY UPDATE` (reopens the AC4 race for the 3-tuple save, probe P1 in `06-probes.png`), M8 lock only
`chunk_index 0`, and M4 no `ORDER BY`. Deadlock-freedom also relies on the embedder reading chunks in ascending
`chunk_index` (`get_chunks_for_embedding`, `ORDER BY pc.chunk_index ASC`), which nothing pins (probe P4 deadlocks with a
descending save). Pin all of this by behaviour, so a reworded-but-equivalent lock still passes and a weaker one fails.

## Scope
- Files expected to change: `tests/test_chunk_reprocess_db.py` only (reuse its two-session helpers, `lock_timeout`,
  thread-join timeouts, `finally` cleanup and the `db_left_as_found` fixture).
- Out of scope: `services/common/db.py` (no code change; if a test exposes a real bug, stop and report it in Notes),
  `services/embedder/worker.py` (AI-13).

## Acceptance criteria
- [ ] AC1 (3-tuple AC4 variant, real PG, two sessions): E runs a **3-tuple** `save_chunk_embeddings` for chunks 0..2 and
  holds its transaction open; P runs `save_sections_and_chunks` with new text for those chunks and blocks; E commits;
  P commits. No changed chunk keeps a vector. Fails with M6 (`FOR NO KEY UPDATE`) and with no lock.
- [ ] AC2 (later chunk, real PG): same race with E's in-flight write on chunk 1 only (chunk 0 unchanged). Fails with M8
  (lock only `chunk_index 0`).
- [ ] AC3 (order invariant): a real-PG test that `get_chunks_for_embedding` returns a paper's chunks in ascending
  `chunk_index` when they were inserted out of order; and a two-session test where E saves ascending while P re-saves
  (QA probe P3) finishes with no `deadlock detected` and no stale vector.
- [ ] AC4: M4 (no `ORDER BY`) is optional to kill by behaviour (say in Notes whether it is). Report a mutant table for
  M4, M6, M8 and "no lock" (run locally, never pushed).
- [ ] AC5: the AC7 rules of OPS-H6f still hold (timeouts, `finally` cleanup, equal `papers`/`paper_chunks`/`chunk_embeddings`
  counts before and after); CI `Python M0 unit tests`, `Go`, `Agent ownership check` and `Full stack` green; the new tests
  `PASSED` in the `AC4: make test-full` `-rA` summary (quote run ID). Ruff (E,F,W, line length 130) clean on added lines.
- [ ] Docs: none in the app repo.

## Verification
```bash
cd app
# real DB: make infra-up && make migrate && python -m pytest -v tests/test_chunk_reprocess_db.py
ruff check --isolated --select E,F,W --line-length 130 tests/test_chunk_reprocess_db.py
git diff origin/main --name-only   # exactly tests/test_chunk_reprocess_db.py
# CI: Full stack run on the draft PR -> `AC4: make test-full` step, -rA summary lines for the new DB tests
```

## Notes
- 2026-11-27 (pm-lead, OPS-H6f PM review): specced from QA OPS-H6f r1 finding 1 `[test]` (M6/M8 killed only by the SQL
  pin), finding 3 `[code]` (ascending-order invariant) and "Missing tests". QA's probe file
  `agents/reviews/OPS-H6f/evidence/09-harness.txt` (`probe/test_qa_h6f_probe.py`, P1-P4) is a starting point. Once AI-13
  (#126) merges the worker uses the 4-tuple path, so AC1 guards the 3-tuple API rather than today's worker; keep it, it is
  cheap. Independent of AI-13 (different files).
