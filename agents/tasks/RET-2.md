# RET-2: Search hits carry the paper version and page (citation provenance)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (provenance input for claim-level citations, AI-8) |
| **PRD ref** | Product PRD QA-3, ING-7 (versions are distinct records), §7 principle 3; Technical PRD §5, §7.1; ADR-0014 (Accepted 2026-11-07) |
| **Depends on** | **ADR-0014 Accepted** (adds `version`/`page` to `/v1/search` hits: HTTP API contract). **AI-7 merged** (both edit the README API table). **EVAL-6 merged** (both may edit `tests/test_evals_data.py`, which holds the ADR-0010 SQL parity guard). |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-RET-2"`) |
| **Design required** | **yes** (short, `docs/design/RET-2.md`): it touches a shared contract (HTTP API) and the SQL the parity guard mirrors. |
| **Status** | **Ready to merge**: PR [#35](https://github.com/MaheshPulivarthi18/ArxivLens/pull/35) raised for Mahesh, head `3bf5dab`, all 6 CI checks green. QA PASS r1 · PM APPROVE 2026-11-08 ([report](../reviews/RET-2/report.md)). Design conditions 1–7 met. Followed by **ING-11b** (search returns `page`) and **AI-8** (maps `version`/`page` into citations) |

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
- [x] AC1 — `/v1/search` hits include `version` (int) for every hit; `page` only when reliable (per the design's finding).
- [x] AC2 — Integration test on real pgvector (`db.yml`): a paper with v1 and v2 returns the right version per chunk, and a chunk with a stored `page_number` returns no `page` (no hit carries `page`; real chunk pages → ING-11b, the query side of ING-11). *(amended 2026-11-07, see Notes; ING-11 → ING-11b 2026-11-08)*
- [x] AC3 — The ADR-0010 parity guard passes: the whole `tests/test_evals_data.py` file, plus `test_rrf_pool_sql_mirrors_search_go`, `test_adr0010_parity_pool_one_call_stable_ties_top5` and `test_rrf_pool_query_runs_with_production_hnsw_settings_then_resets` run by node ID. Any allowed-difference change is shown in the PR. *(amended 2026-11-07, see Notes)*
- [x] AC4 — No change to ranking: the RRF arms are byte-identical (`git diff` shows only the outer SELECT and scan); `search_test.go` ordering tests pass unmodified.
- [x] AC5 — README `/v1/search` row updated. Diff < 400 lines.

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
- 2026-11-08 08:00Z (backend-engineer, build): branch `agent/backend/RET-2` at `b1c5b9b` (from origin/main `d3f9408`), pushed; PR not opened yet (orchestrator).
  377+/7- = 384 lines, 6 files: `search.go` (+`Version`, +`Page` never set, with comment naming ING-11; outer SELECT `+ p.version`; scan `+ &h.Version`),
  new `search_provenance_test.go` (unit) and `search_provenance_integration_test.go` (`db.yml`), `db.yml` run pattern `'TestHNSW|TestSearchProvenance'`,
  the one `_GO_TO_EVAL_SQL` fragment in `tests/test_evals_data.py`, README `/v1/search` row. `search_test.go`, `search_integration_test.go`, `rag*.go`, `scripts/` unchanged (`git diff --quiet`).
  Local: `pytest -q tests/test_evals_data.py` 97 passed, 1 skipped; the three guards by node ID 3 passed; `gofmt -l` clean; ownership check OK (384 lines).
  Go 1.25 unavailable: ran `search.go` + both unit test files with Go 1.24.7 in a scratch module (stubs only for `db`/`pgx`): all 12 tests PASS with `-race`;
  8/8 mutants killed (drop `p.version`, drop `&h.Version`, swap scan order, select `c.page_number`, keyword LIMIT, RRF constant, `version` omitempty, `page` not omitempty).
  Integration test compiles + vets (`-tags integration`) against the stubs; not run locally (no Docker daemon, no pgvector) → AC2 evidence is the `db.yml` log (`PROVENANCE ...` lines).
  `make lint`/`make test-unit` not run (Go 1.25) → CI. Deviations from design recorded in `docs/design/RET-2.md` § Build notes.
- 2026-11-08 (backend-engineer, CI fix on PR #35): `db.yml` FAILED on `b1c5b9b` (job 128673836567). Every assertion passed and the 3 `PROVENANCE` lines were right
  (v1 → 1, both v2 chunks → 2, `page` absent). The failure was in my test's teardown: `defer d.Close()` ran before `t.Cleanup`, so the seed `DELETE` hit a closed pool (`cleanup: closed pool`).
  Fix `3bf5dab`: `t.Cleanup(d.Close)`, registered first so it runs last. Test-only, 1 line; no assertion, threshold or product code changed.
  All 6 checks green on `3bf5dab` (DB job 128681427063: `--- PASS: TestHNSWVectorHits`, `--- PASS: TestSearchProvenance`).
  `TestHNSW` RESULT rows: every generic, auto (production) and `hybridSearchSQL` row matches main `d3f9408` (job 128645946281) exactly. Custom-plan rows differ by <= 0.01 recall,
  and they also differ between `b1c5b9b` and `3bf5dab`, which have identical `search.go`, so this is run-to-run HNSW variation, not RET-2 (`vectorHitsSQL` unchanged, AC4 golden test).
- 2026-11-08 (pm-lead, final review): **APPROVE** ([report](../reviews/RET-2/report.md) § PM verdict). QA PASS r1 at `3bf5dab`; all 6 CI checks green on merge `1a9ee6c`.
  Fixed QA's `[spec]` finding 5: Status no longer says the build waits for #26 (merged `54cad79`), and AC2 now names ING-11b. QA nits, none blocking:
  - Nit 1 (`search.go` `Page` comment names ING-11, not ING-11b): accurate in substance (the query side of ING-11). ING-11b's Scope already rewrites
    this comment when it sets `Page`, so no RET-2 rework. Follow-up: ING-11b Scope (line added there).
  - Nit 2 (PR body PRD ref): fixed by pm-lead in the rewritten PR description (QA-3, ING-7, §7 principle 3; Technical §5, §7.1; ADR-0014).
  - Nit 3 (no NaN / `context.Canceled` rows in `TestSearchHitProvenanceTravelsWithHit`): all fallbacks share one return path and QA mutant M16
    (fallback drops `Page`) is killed by the existing rows. Follow-up: add the two rows in ING-11b, which edits `search_provenance_test.go` anyway (Notes line added there).
