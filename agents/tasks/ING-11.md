# ING-11: Record where each section's pages break and store chunk start pages (producer, part a)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (Product PRD §7 principle 3 "one click to the source": FE-4's `#page=N` link needs a real page) |
| **PRD ref** | Product PRD ING-3, QA-3, §7 principle 3; Technical PRD §5 (data model), §6.1–6.2 (extraction, chunking); ADR-0014 (Accepted: `page` is "omitted when unknown", "only returned when the chunker recorded it") |
| **Depends on** | **Build:** none (design approved 2026-11-07). Independence check at start: no open PR touches `services/processor/worker.py`, `services/common/db.py`, `migrations/`, `internal/db/db_test.go`, `Makefile` or `tests/test_processor_pages.py` (on 2026-11-07 none does; #30 edits `services/common/kafka_client.py` and `ci.yml`, a different file). ING-8's branch `agent/ai/ING-8` calls `_parse_doc_sections(None, doc)`: keep that contract (design decision 4) |
| **Jira** | KAN-55 (`labels = "task-ING-11"`), under epic KAN-1 "Grounded LLM answers" |
| **Design required** | yes, **approved**: `docs/design/ING-11.md` (PM decision 2026-11-07, conditions 1–9; this ticket is bound by 2, 3, 7, 8) |
| **Status** | Ready (build can start next cycle). Followed by **AI-11** (chunker emits `page_start`), then **ING-11b** (search returns `page`) |

## Goal
`paper_chunks.page_number` is the page of a chunk's *section heading*, which is wrong for every later chunk of a section that
crosses a page break, so RET-2 returns no `page`. This part lays the producer side: the processor records where page breaks
fall in each section's text, and the database gets a place to store each chunk's real start page, written in the processor's
transaction. Nothing reads it yet, and no chunk has a `page_start` until AI-11, so search output doesn't change.

## Scope
- `services/processor/worker.py` `_parse_doc_sections`: every new section dict (`:118`, `:160-165`) gets `"page_breaks": []`, and
  just before the only text write (`:167`) append `(len(current_section["text"]), page_idx + 1)` when the list is empty or the
  last page differs (design decision 3). `text`, `title`, `level`, `page` and section order stay byte-identical. Keep the
  method name, `(self, doc)` signature and no instance state (ING-8).
- `migrations/000003_paper_chunk_pages.up.sql` / `.down.sql`: `CREATE TABLE IF NOT EXISTS paper_chunk_pages (chunk_id BIGINT PRIMARY KEY
  REFERENCES paper_chunks(id) ON DELETE CASCADE, page_start INT NOT NULL CHECK (page_start >= 1))`; down = `DROP TABLE IF EXISTS`.
  No backfill, no default. Only adds a table, so no ADR (AGENTS.md §2).
- `services/common/db.py` `save_sections_and_chunks`: the chunk upsert gains `RETURNING id`; then, in the same cursor and
  transaction, `chunk.get("page_start")` set → `INSERT INTO paper_chunk_pages ... ON CONFLICT (chunk_id) DO UPDATE SET page_start =
  EXCLUDED.page_start`; missing → `DELETE FROM paper_chunk_pages WHERE chunk_id = %s`. `page_number` (`:119`) unchanged. No commit inside.
- `internal/db/db_test.go` `TestRepoMigrationsOrder`: `want` gains `000003_paper_chunk_pages.up.sql`.
- `tests/test_processor_pages.py` (new) and `Makefile` `test-py` runs it. The fixture builder and oracle helpers are importable
  module-level functions (AI-11 appends its tests to this file and reuses them; design condition 3).
- PR description: how to backfill the existing corpus (re-publish `papers.downloaded` with a fresh `event_id` per paper; chunk ids
  are kept by the `(paper_id, chunk_index)` upsert, so no re-embedding), marked as Mahesh's decision (condition 8).
- Out of scope: the chunker (`scripts/m0_skeleton.py`, ai-owned → AI-11), search/README/parity fragment (→ ING-11b), reprocessing,
  page ranges, the frontend (FE-4). `CONTRIBUTING.md`: no change needed unless the `test-py` description line lists files (then update it).

## Acceptance criteria
- [ ] AC2: Chunk output is unchanged. For a small multi-page fixture PDF generated in the test with PyMuPDF (base-14 `helv`, no
  download, nothing binary committed), where the Introduction runs over pages 1–3 and a second section starts mid-page 3:
  each section's `(title, level, page, sha256(text))` and each chunk's `(chunk_index, token_count, content_hash, sha256(content))`
  through the production `_parse_doc_sections(None, doc)` + `TokenChunker` equal a literal captured from unchanged production code.
  **Before** evidence: the first pushed commit adds only the test file + Makefile line and its `ci.yml` python job is green;
  **after**: the same test is green on the code commits (condition 2; both run IDs in the PR). `make eval`: "not run: chunk text identical (AC2)".
- [ ] AC2b: `page_breaks` invariants on the fixture: every section has one; first offset 0; offsets and pages strictly ascending;
  every offset < `len(text)`; at least one section has ≥ 2 breaks; the fixture's vocabulary is asserted single-wordpiece up front (test).
- [ ] AC2c: `db.py` write path (fake cursor, table-driven, no DB): `page_start` set → the page upsert uses the id from `RETURNING id`
  and the given value; missing → `DELETE` for that id; `page_number` argument still `chunk.get("page_number", 1)`; no `commit` (test).
- [ ] AC5: Migration applies twice cleanly on a fresh DB (`db.yml` "Migrate run 2" diff, which now includes `paper_chunk_pages`);
  `TestRepoMigrationsOrder` passes with `000003`; `stack.yml` (triggered by `services/processor/**`/`migrations/**`) passes on the
  PR, which exercises `RETURNING id` and the `DELETE` path on real Postgres.
- [ ] AC6: The PR is < 400 changed lines (`git diff --stat origin/main`). Over 400 → split at condition 7's seam.

## Verification
```bash
make lint
make test-unit
python3 -m pytest -q tests/test_processor_pages.py          # AC2, AC2b, AC2c (downloads BGE on first run)
go test ./internal/db/ -run TestRepoMigrationsOrder          # AC5
# db.yml on the PR ("Migrate run 1", "Migrate run 2"), stack.yml on the PR (AC5)
```

## Notes
- 2026-11-07 (pm-lead): filed from the RET-2 design review (finding 2, Q3). Numbered in the ING series (no collision with Product PRD rows ING-1..7).
- 2026-11-07 (backend-engineer): design written, [docs/design/ING-11.md](../../docs/design/ING-11.md).
- 2026-11-07 (pm-lead): design **approved with conditions 1–9**. Ticket re-scoped to part a (producer). The original AC1 (recorded
  page = page of first characters) moves to AI-11; AC3, AC4 and the README part of AC6 move to ING-11b. Order reversed from the
  design's proposal: ING-11 → AI-11 → ING-11b, because AI-11's tests need a file already in `make test-py` and `tests/test_m0.py` is
  held by open draft #24 (design PM decision, Q1).
