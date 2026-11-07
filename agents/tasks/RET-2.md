# RET-2: Search hits carry the paper version and page (citation provenance)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (provenance input for claim-level citations, AI-8) |
| **PRD ref** | Product PRD QA-3, ING-7 (versions are distinct records), §7 principle 3; Technical PRD §5, §7.1; ADR-0014 (Accepted 2026-11-07) |
| **Depends on** | **ADR-0014 Accepted** (adds `version`/`page` to `/v1/search` hits: HTTP API contract). **AI-7 merged** (both edit the README API table). **EVAL-6 merged** (both may edit `tests/test_evals_data.py`, which holds the ADR-0010 SQL parity guard). |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-RET-2"`) |
| **Design required** | **yes** (short, `docs/design/RET-2.md`): it touches a shared contract (HTTP API) and the SQL the parity guard mirrors. |
| **Status** | Design approved 2026-11-07; build waits for ArxivLens #26 (OPS-H10) to merge (README same-file rule). Conditions 1–7 in `docs/design/RET-2.md` § PM decision |

## Goal
A citation should say which version of a paper it came from, and the page when the system knows it, so one click reaches
the right place in the PDF (Product PRD §7 principle 3). `papers.version` and `paper_chunks.page_number` exist, but
`SearchHit` (`internal/query/search.go:21`) returns neither.

## Scope
- `internal/query/search.go`: `SearchHit` gains `Version int \`json:"version"\`` and `Page *int \`json:"page,omitempty"\``.
  Select them in `hybridSearchSQL`'s outer query (and the fallback path, if any). Keep the RRF arms unchanged.
- **Page reliability first:** `services/common/db.py:119` writes `page_number` with a default of 1 when a chunk has none. The design traces
  whether `TokenChunker` sets `page_number` for every chunk (the processor tracks `page` per block,
  `services/processor/worker.py:164`). If it isn't reliable, return `page` as omitted for all hits and file a follow-up
  for the processor. Never return a default 1 as if it were real.
- `internal/query/search_test.go` / `search_integration_test.go`: cover the new fields. The `db.yml` job runs the integration test on real pgvector.
- `tests/test_evals_data.py`: the ADR-0010 parity guard must stay green. If the outer SELECT is part of what it compares,
  update its allowed-differences list in the same PR (backend may edit `tests/`). Don't touch `scripts/evaluate_retrieval.py`
  (ai-owned). If the eval's mirrored SQL must change, stop and ask ai for a paired change.
- App `README.md` API table: the `/v1/search` row lists the new fields.
- Out of scope: which version search returns when a paper has several (today: all of them). That's a product rule, so
  write it up as a Backlog item or ADR if the design finds a problem. Also out: `rag.go` (AI-8 maps the fields into citations) and the frontend.

## Acceptance criteria
- [ ] AC1 — `/v1/search` hits include `version` (int) for every hit; `page` only when reliable (per the design's finding).
- [ ] AC2 — Integration test on real pgvector (`db.yml`): a paper with v1 and v2 returns the right version per chunk, and a chunk with a stored `page_number` returns no `page` (no hit carries `page`; real chunk pages → ING-11). *(amended 2026-11-07, see Notes)*
- [ ] AC3 — The ADR-0010 parity guard passes: the whole `tests/test_evals_data.py` file, plus `test_rrf_pool_sql_mirrors_search_go`, `test_adr0010_parity_pool_one_call_stable_ties_top5` and `test_rrf_pool_query_runs_with_production_hnsw_settings_then_resets` run by node ID. Any allowed-difference change is shown in the PR. *(amended 2026-11-07, see Notes)*
- [ ] AC4 — No change to ranking: the RRF arms are byte-identical (`git diff` shows only the outer SELECT and scan); `search_test.go` ordering tests pass unmodified.
- [ ] AC5 — README `/v1/search` row updated. Diff < 400 lines.

## Verification
```bash
make lint
make test-unit
python3 -m pytest -q tests/test_evals_data.py
python3 -m pytest -q tests/test_evals_data.py::test_rrf_pool_sql_mirrors_search_go \
  tests/test_evals_data.py::test_adr0010_parity_pool_one_call_stable_ties_top5 \
  tests/test_evals_data.py::test_rrf_pool_query_runs_with_production_hnsw_settings_then_resets
# db.yml on the PR for AC2
```

## Notes
- 2026-11-07 (pm-lead): from the 2026-11-07 plan (Phase 1 item 4: provenance needs paper version, chunk, section, page).
- Wave 2, gated by ADR-0014. If ADR-0014 is rejected, pm-lead re-specs this ticket.
- 2026-11-07 11:00Z (pm-lead, grooming): ADR-0014 is Accepted and #20/#21 merged, so this is Ready. Not picked in cycle 11:00Z: no backend slot, and it edits the README API table while OPS-H10 edits the README Full stack paragraph (same-file rule). Start after OPS-H10 merges (or in a slot where no open PR changes `README.md`).
- 2026-11-07 (backend-engineer): design written → docs/design/RET-2.md; build waits for #26 merge (README). Finding: `page_number` is the section start page, not the chunk page, so `page` is omitted for all hits; processor follow-up (PROC-n) and version-label follow-up (ING-n) proposed; open questions Q1–Q3 in the design.
- 2026-11-07 (pm-lead, design review): **APPROVE with conditions 1–7** (`docs/design/RET-2.md` § PM decision). AC changes:
  - **AC2 (page half)** was "a chunk with a known page returns it". It is now "a chunk with a stored `page_number` returns no `page`".
    The design traced the pipeline and found `page_number` is the section-heading page (`worker.py:164`, `m0_skeleton.py:225`),
    not the chunk's page. No stored page is "known", so the old wording could only pass by returning a wrong page, which this
    ticket's Scope forbids ("never return a default 1 as if it were real") and ADR-0014 rules out ("page is only returned when the
    chunker recorded it"). This is not a weakening. AC1 and the Scope always made `page` conditional. The new assertion tests the
    forbidden case directly. Real per-chunk pages move to ING-11 with their own ACs. The version half of AC2 is unchanged.
  - **AC3 + Verification:** `-k parity` collected 1 of 76 tests and missed the SQL mirror test. It is now the whole file plus the three
    guards by node ID. This is stricter than before.
  - Q2: ship `version` as the owning `papers` row's version. Label correctness on on-demand ingests → ING-10 (Ready). Follow-ups ING-10 and ING-11 are filed.
