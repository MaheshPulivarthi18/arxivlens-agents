# RET-2: Search hits carry the paper version and page (citation provenance)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (provenance input for claim-level citations, AI-8) |
| **PRD ref** | Product PRD QA-3, ING-7 (versions are distinct records), §7 principle 3; Technical PRD §5, §7.1; ADR-0014 (Proposed) |
| **Depends on** | **ADR-0014 Accepted** (adds `version`/`page` to `/v1/search` hits: HTTP API contract). **AI-7 merged** (both edit the README API table). **EVAL-6 merged** (both may edit `tests/test_evals_data.py`, which holds the ADR-0010 SQL parity guard). |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-RET-2"`) |
| **Design required** | **yes** (short, `docs/design/RET-2.md`): it touches a shared contract (HTTP API) and the SQL the parity guard mirrors. |
| **Status** | Blocked (needs ADR-0014). Wave 2 once it's Accepted and a backend slot is free. |

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
- [ ] AC2 — Integration test on real pgvector (`db.yml`): a paper with v1 and v2 returns the right version per chunk, and a chunk with a known page returns it.
- [ ] AC3 — The ADR-0010 parity guard passes (`pytest tests/test_evals_data.py -k parity`), and any allowed-difference change is shown in the PR.
- [ ] AC4 — No change to ranking: the RRF arms are byte-identical (`git diff` shows only the outer SELECT and scan); `search_test.go` ordering tests pass unmodified.
- [ ] AC5 — README `/v1/search` row updated. Diff < 400 lines.

## Verification
```bash
make lint
make test-unit
python3 -m pytest -q tests/test_evals_data.py -k parity
# db.yml on the PR for AC2
```

## Notes
- 2026-11-07 (pm-lead): from the 2026-11-07 plan (Phase 1 item 4: provenance needs paper version, chunk, section, page).
- Wave 2, gated by ADR-0014. If ADR-0014 is rejected, pm-lead re-specs this ticket.
