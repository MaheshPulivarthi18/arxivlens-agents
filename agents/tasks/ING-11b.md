# ING-11b: `/v1/search` returns each chunk's recorded start page as `page` (consumer, part b)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (Product PRD §7 principle 3 "one click to the source": AI-8 maps it into `citations[].page`, FE-4 links `#page=N`) |
| **PRD ref** | Product PRD QA-3, §7 principle 3; Technical PRD §5, §7.1; ADR-0014 (Accepted: `page` "(int, omitted when unknown)") |
| **Depends on** | **AI-11 merged** (`68a57a9`, and ING-11 `d3f9408`), **RET-2 merged** (`6cfd836`). Independence check at start: no open PR touches `internal/query/search*.go`, `.github/workflows/db.yml`, `tests/test_evals_data.py`, `tests/test_m2_pipeline.py`, the README API table's `/v1/search` row or `CONTRIBUTING.md:23` (cycle 2026-11-17: no open PRs; OPS-H7a and OPS-H9 also edit `db.yml`, so neither runs alongside this) |
| **Jira** | not yet created (orchestrator: story under epic KAN-1, labels `task-ING-11b`, `agent-backend`, `arxivlens`; link KAN-55) |
| **Design required** | yes, **covered by the approved `docs/design/ING-11.md`** (decision 6, part b; PM conditions 4, 5, 6, 9). No new design round |
| **Status** | **In Progress** (built 2026-11-17, head `706e43e` pushed; draft PR to be opened by the orchestrator). Branch `agent/backend/ING-11b` |

## Goal
After ING-11 and AI-11, the processor stores each chunk's real start page in `paper_chunk_pages`. This part returns it from
`/v1/search` as `page`, and keeps returning no `page` for every chunk without a row (everything written before ING-11, and any
chunk the chunker couldn't place). Ranking doesn't change.

## Scope
- `internal/query/search.go`: the outer SELECT gains `(SELECT cp.page_start FROM paper_chunk_pages cp WHERE cp.chunk_id = c.id) AS page`
  after `p.version` (scalar PK subquery, not a `LEFT JOIN`; design Q3); the scan gains `&h.Page` in the same position (NULL → nil →
  omitted). The `Page` comment becomes "start page when recorded (`paper_chunk_pages`), omitted otherwise". RRF arms, `rrf_score`,
  `ORDER BY`, `LIMIT` byte-identical.
- `internal/query/search_provenance_test.go` (RET-2's unit tests; `search_test.go` has a zero diff in RET-2): the golden/source checks (`TestSearchSQLOuterSelectOnly`, `TestSearchSQLColumnsMatchScan`) also strip the page column and expect `&h.Page`; `TestSearchHitProvenanceTravelsWithHit` gains the NaN-score and `context.Canceled` rerank-fallback rows (RET-2 QA nit 3) with a non-nil `Page`. `search_test.go` ordering tests not edited.
- `internal/query/search_provenance_integration_test.go`: seed one `paper_chunk_pages` row; assertions per AC3.
- `.github/workflows/db.yml` "Migrate run 1": `grep -E '^column\|paper_chunk_pages\.page_start\|integer$' /tmp/run1.txt`.
- `tests/test_evals_data.py`: the one outer-SELECT `_GO_TO_EVAL_SQL` fragment. `scripts/evaluate_retrieval.py` unchanged.
- `tests/test_m2_pipeline.py`: the real-pipeline write check (AC5, design condition 4).
- App `README.md` `/v1/search` row: "`page` is the page the chunk's text starts on, when recorded; omitted otherwise (ADR-0014)".
- `CONTRIBUTING.md:23` (backstop, only if still missing when this starts): the `make test-unit` row lists the pytest files
  run by `test-py`; add `tests/test_processor_pages.py` (added to `test-py` by ING-11 #33). Board Backlog has it as an earlier
  one-liner for the first backend PR after #26 merges.
- Out of scope: reprocessing the corpus, page ranges, `citations[].page` (AI-8), the frontend (FE-4). Technical PRD §5/§6.2 is a pm-lead docs PR after merge.

## Acceptance criteria
- [ ] AC3: On real pgvector in `db.yml`, extending RET-2's `TestSearchProvenance` through the production `HybridSearch`: the v2 chunk
  with `page_number` 7 and a `paper_chunk_pages` row of 6 returns `Page == 6` and `"page":6` in its JSON (the differing values prove
  the new table is the source); the chunk with `page_number` 4 and no row, and the v1 chunk with NULL `page_number` and no row,
  return `Page == nil` and no `"page"` key. `t.Logf` lines are linked from the `db.yml` log (condition 6).
- [ ] AC4: ADR-0010 parity guard passes: whole `tests/test_evals_data.py`, plus by node ID `test_rrf_pool_sql_mirrors_search_go`,
  `test_adr0010_parity_pool_one_call_stable_ties_top5`, `test_rrf_pool_query_runs_with_production_hnsw_settings_then_resets`.
  Exactly one `_GO_TO_EVAL_SQL` fragment changes; `git diff --stat` shows no `scripts/` path; `TestSearchSQLOuterSelectOnly`
  (both added columns stripped → golden) and the `search_test.go` ordering tests pass unmodified; `TestHNSW` recall lines unchanged (condition 5).
- [ ] AC5: `stack.yml` passes on the PR (triggered by `internal/**`/`tests/**` once OPS-H10 #26 is merged; otherwise dispatched on the
  branch and the run ID named). Its `make test-full` includes the new `tests/test_m2_pipeline.py` test: for every `embedded` paper,
  every `paper_chunks` row has a `paper_chunk_pages` row, `page_start >= page_number`, and `page_start` doesn't decrease with
  `chunk_index` within a paper. The PR names the test and how its result shows in the log (the run uses `pytest -q`, so give the dot position or a failure-free summary line).
- [ ] AC6: README `/v1/search` row updated (wording in Scope). The PR is < 400 changed lines (estimate ~85).

## Verification
```bash
make lint
make test-unit
python3 -m pytest -q tests/test_evals_data.py
python3 -m pytest -q tests/test_evals_data.py::test_rrf_pool_sql_mirrors_search_go \
  tests/test_evals_data.py::test_adr0010_parity_pool_one_call_stable_ties_top5 \
  tests/test_evals_data.py::test_rrf_pool_query_runs_with_production_hnsw_settings_then_resets
# db.yml on the PR (AC3, migrate grep); stack.yml on the PR (AC5)
# make eval: not required (ranking SQL byte-identical, AC4) — say "not run: ranking SQL unchanged (AC4)"
```

## Notes
- 2026-11-07 (pm-lead): split from ING-11 at its design approval (Q2, producer/consumer seam). Carries the original ING-11 AC3, AC4
  and the README half of AC6, plus the new real-pipeline write check (design condition 4).
- 2026-11-08 (pm-lead, RET-2 final review): RET-2 (#35) put its unit tests in a new `search_provenance_test.go`, not `search_test.go`, so Scope now names that file. Two RET-2 QA nits land here: the `Page` comment in `search.go` still says "ING-11 fills Page" (Scope already rewrites it), and the NaN / `context.Canceled` fallback rows (added to Scope).
- 2026-11-17 (pm-lead, grooming): unblocked (AI-11 #38 and RET-2 #35 merged 2026-11-14). Re-checked against Mahesh's later PRs:
  - #49 (`538b2ea`, ADR-0016 `diversify`) and #50 (`40dec5a`, ADR-0017 rank fusion) changed `rerankAndSort` and the ordering tests in
    `search_test.go`/`search_provenance_test.go`, **not** `hybridSearchSQL` or the scan. The outer-SELECT edit in Scope still applies as written.
    AC4's "the `search_test.go` ordering tests pass unmodified" now means the fused-order expectations from #50. The `TestSearchHitProvenanceTravelsWithHit`
    rows you add (NaN, `context.Canceled`) go through the ADR-0017 fallback (RRF order, `RerankScore` 0), so assert `Page` survives that path.
  - #48/#49/#50 added parity fragments and shared cases to `tests/test_evals_data.py`. Still exactly **one** `_GO_TO_EVAL_SQL` fragment changes here.
  - `CONTRIBUTING.md:23` backstop: the `make test-unit` row now misses **three** files that `make test-py` runs (`Makefile:49`):
    `tests/test_processor_pages.py`, `tests/test_verify.py` (#44) and `tests/test_arxiv_replay.py` (#45). List all of them, in `Makefile` order.
  - AC5's `stack.yml` run now serves arXiv from the replay cache (#45), so the crawl step is deterministic. Re-ingest: #40/#42 change
    chunk text, but `stack.yml` starts from a fresh DB, so every chunk in the run gets a `paper_chunk_pages` row from AI-11's chunker.
  - README: edit only the API table's `/v1/search` row (`README.md:162`). EVAL-4 edits the Testing block (`:215-222`) in this cycle; AI-8 later edits the `/v1/ask` row.
- 2026-11-17 (backend-engineer, build): head `706e43e` on `agent/backend/ING-11b` (base `40dec5a`), 8 files, +114/-25
  (ownership check: "Ownership OK for role=backend (139 changed lines)"). No open PRs at start (REST `pulls?state=open` empty).
  - `search.go`: outer SELECT gains `(SELECT cp.page_start FROM paper_chunk_pages cp WHERE cp.chunk_id = c.id) AS page` on its own
    line after `p.version,`; scan `&h.Version, &h.Page, &h.RRFScore`; `Page` comment rewritten (RET-2 nit). Nothing else in the SQL changes.
  - `search_provenance_test.go`: `outerSelectColumns` now anchors on `"\n\t\tSELECT "` (the old `LastIndex("SELECT ")` would find the
    page subquery); `TestSearchSQLColumnsMatchScan` expects `Page`; `TestSearchSQLOuterSelectOnly` strips `p.version` and `pageColumn` and
    compares to the unchanged golden; `TestSearchHitProvenanceTravelsWithHit` gains `fallback NaN score` and `fallback canceled` rows,
    asserts `RerankScore == 0` on fallback rows and that at least one hit has a non-nil `Page`. `search_test.go`: zero diff.
  - Integration: chunk `page_number` 7 gets a `paper_chunk_pages` row 6; `page_number` 4 and the NULL v1 chunk get none. `PROVENANCE` log
    line prints `page=6`/`page=nil`. `db.yml` migrate run 1 greps `^column|paper_chunk_pages.page_start|integer$`.
  - `test_evals_data.py`: only the outer-SELECT fragment changes; no `scripts/` path in the diff.
  - `test_m2_pipeline.py::test_embedded_chunks_have_recorded_start_pages` (3rd test in the file, after the two existing ones).
  - README `/v1/search` row (Scope wording); `CONTRIBUTING.md:23` lists all six `test-py` files in `Makefile:49` order.
  - Local runs: Go 1.25 unavailable (`go.mod requires go >= 1.25.0 (running go 1.24.7; GOTOOLCHAIN=local)`), so `make test-unit`/`make lint`
    not run locally. Scratch go1.24 module with the real `search.go`, `client.go`, `search_test.go`, `search_provenance_test.go` (+ stubs for
    `db`, `pgx`, `generateTraceID` only): `go vet` OK, `go test -race` all 15 tests PASS; `go vet -tags integration` OK on the integration
    file. 6 local mutants all killed (drop `&h.Page`; drop page column; `c.page_number AS page`; swap Page/Version scan; fallback clears
    Page; LEFT JOIN instead of subquery). `pytest -q tests/test_evals_data.py`: 119 passed, 1 skipped (opt-in DATABASE_URL); the three
    node IDs: 3 passed; old fragment + new search.go: `test_rrf_pool_sql_mirrors_search_go` fails (guard live). New M2 test checked with a
    stub psycopg on 6 inputs (good, missing row, below page_number, decreasing, per-paper reset, empty) — all as expected.
  - Not verified locally: `db.yml` (AC3), `stack.yml` (AC5; triggered by `internal/**` on the PR), CI `make test-unit`/`make lint`.
    `make eval` not run: ranking SQL unchanged (AC4). No workflow runs on a branch push, so CI starts when the PR opens.

