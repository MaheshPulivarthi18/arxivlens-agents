# ING-11: Record each chunk's real start page and return it as `page` in search hits

| | |
|---|---|
| **Owner** | backend-engineer (processor, schema, `db.py`, search). **Paired ai-engineer part** if the design maps pages inside `TokenChunker` (`scripts/m0_skeleton.py`, ai-owned): pm-lead then specs it as its own ticket at design approval, and this one depends on it |
| **Priority** | P1 (Product PRD §7 principle 3 "one click to the source": FE-4's `#page=N` link needs a real page) |
| **PRD ref** | Product PRD ING-3, QA-3, §7 principle 3; Technical PRD §5 (data model), §6.1–6.2 (extraction, chunking), §7.1; ADR-0014 (Accepted: `page` is "omitted when unknown", "only returned when the chunker recorded it") |
| **Depends on** | **Design:** none, it can start now. **Build:** RET-2 merged (adds `SearchHit.Page`, the outer-SELECT parity fragment and the README `/v1/search` row, which this ticket edits again). ING-8's branch `agent/ai/ING-8` (no PR) calls `_parse_doc_sections`; the design checks it isn't broken. |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-ING-11"`) |
| **Design required** | **yes**: it changes the schema, crosses an ownership boundary (processor vs ai-owned chunker) and changes what the HTTP API returns |
| **Status** | Ready (design first; build after RET-2 merges). Filed 2026-11-07 from the RET-2 design review (finding 2, Q3) |

## Goal
`paper_chunks.page_number` today is the page of the chunk's *section heading* (`services/processor/worker.py:164`, copied to
every chunk by `scripts/m0_skeleton.py:225`). It is wrong for every later chunk of a section that crosses a page break, so
RET-2 returns no `page` at all. This ticket records the page on which each chunk's text starts and returns it as `page`.
Rows without a recorded page keep returning no `page`.

## Scope
- `services/processor/worker.py` (`_parse_doc_sections`): per section, record where page breaks fall in its text, for example
  `page_breaks: [(char_offset, page), ...]`. The section `text` must stay byte-identical.
- Chunk → page mapping. **The design picks one, with reasons:**
  (a) inside `TokenChunker.chunk_sections` (map the chunk's first token to a character offset with `return_offsets_mapping=True`):
  this is the paired ai ticket; or (b) in the processor after `chunk_sections`, using the same tokenizer, with a test that
  fails if it drifts from the chunker's windowing. Either way, `content`, `content_hash`, `chunk_index` and `token_count`
  stay identical for the same PDF. The chunk text contract in `agents/area-notes/services.md` must not change.
- Storage. **The design picks one:** (a) a new table (for example `paper_chunk_pages(chunk_id PK → paper_chunks.id ON DELETE CASCADE, page_start INT NOT NULL)`).
  It only adds a table, so it needs no ADR (AGENTS.md §2). Or (b) a nullable `paper_chunks.page_start` column. That changes an
  existing table, so pm-lead writes a Proposed ADR, and this ticket is `Blocked (needs ADR)` until Mahesh decides.
  pm-lead leans to (a) unless the design shows a real cost. In both cases: a new numbered migration, never an edit to an
  applied one, and existing rows stay unknown (no backfill, no default).
- `services/common/db.py:119`: write the new value with no default (`chunk.get("page_start")`). Leave `page_number` as it is.
- `internal/query/search.go`: select the page in the outer query and scan it into `SearchHit.Page` (NULL → nil → omitted). One
  `_GO_TO_EVAL_SQL` fragment update in `tests/test_evals_data.py`. RRF arms unchanged.
- App `README.md` `/v1/search` row: `page` is the chunk's start page when recorded. Technical PRD §5/§6.2: pm-lead docs PR.
- **Split seam if the design estimates > 300 lines:** part a = producer (processor + mapping + migration + `db.py`, page written
  but not read), part b = consumer (search + parity fragment + README, as RET-3). Part a is safe alone.
- Out of scope: reprocessing the existing corpus (an ops decision, and the PR says how to do it), page *ranges* (end page), and the frontend (FE-4).

## Acceptance criteria
- [ ] AC1: For a committed small multi-page fixture PDF (generated in the test with PyMuPDF, no arXiv download), where one section
  crosses a page break: every chunk's recorded page equals the page its first characters are on. At least one chunk has a page
  greater than its section's heading page (test).
- [ ] AC2: Chunk output is otherwise unchanged. For the same fixture, `content`, `content_hash`, `chunk_index` and `token_count`
  are identical before and after the change (test compares against the pre-change output saved in the test). `make eval` is not
  required, because no text changes. Say "not run: chunk text identical (AC2)".
- [ ] AC3: Rows written before the migration, and chunks with no recorded page, return no `page` from `/v1/search`. A chunk with
  a recorded page returns it (integration test on real pgvector in `db.yml`, extending RET-2's `TestSearchProvenance`).
- [ ] AC4: The ADR-0010 parity guard passes: the whole `tests/test_evals_data.py`, plus `test_rrf_pool_sql_mirrors_search_go` by node ID.
  RRF arms are byte-identical, and `search_test.go` ordering tests pass unmodified.
- [ ] AC5: Migration applies twice cleanly on a fresh DB (`db.yml` "migrate twice"). The milestone suite (`stack.yml`) passes on the PR.
- [ ] AC6: README `/v1/search` row updated. Each PR is < 400 changed lines.

## Verification
```bash
make lint
make test-unit
python3 -m pytest -q tests/test_evals_data.py
python3 -m pytest -q tests/test_evals_data.py::test_rrf_pool_sql_mirrors_search_go
# processor/chunker tests named in the design (AC1, AC2)
# db.yml on the PR (AC3, AC5); stack.yml on the PR (AC5)
```

## Notes
- 2026-11-07 (pm-lead): filed from the RET-2 design review. The trace is in `docs/design/RET-2.md` finding 2. The processor
  follow-up there ("PROC-n") is this ticket. It is numbered in the ING series (ING-10/11 don't collide with Product PRD rows ING-1..7).
- 2026-11-07 (backend-engineer): design written, [docs/design/ING-11.md](../../docs/design/ING-11.md): mapping (a) in `TokenChunker` (paired AI-11 proposed), storage (a) `paper_chunk_pages`, split into producer (a, ~205 lines, waits for AI-11 only) / consumer (b, ~65 lines, after RET-2). Awaiting pm-lead approval (Q1–Q3).
