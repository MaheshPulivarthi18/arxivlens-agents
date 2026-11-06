# EVAL-5: Harden the retrieval eval tests (EVAL-1 QA round-3 nits) and the ADR-0010 parity drift guard

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P2 (harness/quality) |
| **PRD ref** | Product PRD §8 (Recall@5 gate robustness); QA-2; ADR-0006, ADR-0010 |
| **Depends on** | EVAL-1 (PR #2 merged `a959d03`), RET-1 (PR #9 merged `bb9ee90`) |
| **Jira** | find with JQL `labels = "task-EVAL-5"` (orchestrator to create under the Retrieval/Eval epic) |
| **Design required** | no (P2, no gate, threshold or contract change) |
| **Status** | Done (merged; see PROGRESS 2026-11-07) |

## Goal
Make the existing Recall@5 eval fail loudly instead of silently when the rerank endpoint errors, when the mirrored RRF
SQL drifts from production, or when the indexed corpus is only partly embedded. No gate value or definition changes.

Split out of [EVAL-2](EVAL-2.md) by pm-lead on 2026-11-03 (cycle 16:00): these were EVAL-2 AC6–AC9, which need no
decision. EVAL-2 keeps the new `/v1/search` p95 gate key, which is a gate change and now waits on ADR-0012. The
parity-test half of [AI-4](AI-4.md) (its old AC2) also moved here, because AC4 below rewrites the same test.

## Scope
- `scripts/evaluate_retrieval.py`: AC1–AC4 behaviour (error propagation, partial-embedding count + warning, model-name warning).
- `tests/test_evals_data.py`: all new tests go **in this file**. Do not add a new test file: `make test-py` lists its
  files in the `Makefile` (`tests/test_m0.py tests/test_evals_data.py`), and the `Makefile` is changed by open PR #14
  (OPS-H1), so a new file would either not run in CI or overlap #14.
- `evals/README.md`: the model-name paragraph (AC3). Put it in the existing retrieval-eval section, not at the end of the
  file (the blocked `agent/ai/ING-8` branch appends a section at the end).
- Out of scope: `evals/thresholds.json`, `scripts/eval_gate.py`, `evals/BASELINE.md`, `internal/` (incl. `search.go`,
  `rag.go`), `Makefile`, the Recall@5 definition (ADR-0006), the ADR-0010 pool/ordering, the `/v1/search` p95 gate (EVAL-2).

## Acceptance criteria
- [x] AC1 (EVAL-1 QA r3 finding 2, mutant M13) — A rerank error stops the run. A test injects a rerank function that raises
  (`RerankError`, and separately a score-count mismatch) into `run_modes_for_case` / `run_retrieval_evaluation` (stubbed
  as in `test_run_checks_healthz_before_any_rerank_and_reports_metrics`) and asserts the run raises and produces no
  summary. The mutant "catch the error in `rerank_pool` and fall back to RRF order" must fail this test (paste the
  mutation output; mutation not committed).
- [x] AC2 (finding 4) — A paper with only some chunks embedded is visible in the output. For each relevant paper the
  summary records `embedded_chunks` / `total_chunks` for the current model, and the run prints a warning for any paper
  with embedded < total. The gate does not fail on it (warning only; changing that needs an ADR). Unit test with a stubbed cursor.
- [x] AC3 (finding 5) — Model-name sources documented and recorded. `evals/README.md` says the eval reads
  `EMBEDDING_MODEL` (`services/common/config.py`) while the Go query service uses its `--model` flag (default
  `BAAI/bge-base-en-v1.5`), and that both must match. The results JSON keeps `embedding_model`. The eval prints a
  warning when `EMBEDDING_MODEL` differs from `BAAI/bge-base-en-v1.5`. Warning only, no gate change. Unit test for the warning.
  *(pm-lead 2026-11-03: superseded by H2. The warning compares `EMBEDDING_MODEL` with the resolved query-service model
  (`--query-model` / `ARXIVLENS_QUERY_MODEL`, else the `--model` default parsed from `cmd/arxivlens/main.go`), not a hard-coded string.)*
- [x] AC4 (finding 3, mutants M16/M17; plus old AI-4 AC2) — `test_rrf_pool_sql_mirrors_search_go` is robust to drift:
  - (a) it **fails** if `internal/query/search.go` is missing (drop the silent `if os.path.exists(go):` skip at
    `tests/test_evals_data.py:241`);
  - (b) it asserts `const RerankPool = 20` in `search.go` equals `evaluate_retrieval.RRF_POOL_SIZE`;
  - (c) it compares the normalised CTE/arm text of `RRF_POOL_SQL` with the SQL in `search.go` (placeholders normalised:
    `%(name)s` ↔ `$n`; every other allowed difference listed explicitly in the test, as in EVAL-1 QA evidence 307).
  These temporary edits must each make it fail (paste output for each; none committed): rename `search.go`; change
  `RerankPool`; drop the vector arm's `ORDER BY ... LIMIT 50`; `ORDER BY rrf_score ASC`; change one arm's `LIMIT 50`.
  Compare against `search.go` as on `origin/main` (RET-1 merged).
- [x] AC5 — No existing test in `tests/test_evals_data.py` is removed or weakened (diff shows only additions or stricter asserts);
  `make test-unit` and `make lint` green in CI.
- [x] AC6 — Diff < 400 changed lines. If it goes over, stop after AC1+AC4 and ask pm-lead to split AC2/AC3 off.

## Verification
```bash
cd app
python3 -m pytest -q tests/test_evals_data.py
python3 scripts/evaluate_retrieval.py --help
make test-unit && make lint      # CI is the source of truth (sandbox lacks Go 1.25 / PyPI)
# mutation checks for AC1 and AC4: apply each edit locally, run the pytest line above, paste output, revert
```
`make eval` is not needed (no retrieval behaviour change when the stack is healthy); write "not run: no stack, no behaviour change".

## Notes
- Source: `agents/reviews/EVAL-1/report.md` round 3 Findings 2–5; mutation evidence `evidence/310-qa-mutations.png`.
- Line refs at `9c1229a`: `RerankError` `scripts/evaluate_retrieval.py:58`, `rerank_pool` `:101`, `RRF_POOL_SQL` `:213`,
  `run_modes_for_case` `:249`, `config.embedding_model` `:290`; parity test `tests/test_evals_data.py:232-246`;
  `const RerankPool = 20` `internal/query/search.go:17`.
- Independent of open PRs #13 (`rag.go`), #14 (compose/Dockerfiles/Makefile/stack.yml/README/CONTRIBUTING), #15 (`internal/kafka/`).

### ai-engineer, 2026-11-03 (build)
- PR [#17](https://github.com/MaheshPulivarthi18/ArxivLens/pull/17) (draft), branch `agent/ai/EVAL-5`, head `910f2f8f498b2bb0682ce57c4d07f6c066f7c2fa`.
  Files: `scripts/evaluate_retrieval.py` +50/-2, `tests/test_evals_data.py` +134/-6, `evals/README.md` +12 (196 insertions, 8 deletions).
- CI on `910f2f8` (workflow run 41671780187): Python M0 unit tests `126041766536` success (`make test-py`: 58 passed);
  Go (vet, gofmt, test, build) `126041767214` success; Frontend `126041767315` success; Agent ownership check `126041767031` success.
- AC1: `test_rerank_failure_in_run_modes_for_case_raises[raises|short|long]` and `test_rerank_failure_stops_run_with_no_summary[raises|short]`
  (the second goes through `main --json-out` and asserts no JSON is written). `rerank_pool` now raises `RerankError` on a score-count mismatch.
  Mutant M13 (catch in `rerank_pool`, fall back to RRF order): 5 failed, `DID NOT RAISE RerankError`.
- AC2: `chunk_coverage[arxiv_id] = {embedded_chunks, total_chunks}` in the summary, with a warning for embedded < total; the gate is unaffected.
  Tests: `test_partial_embedding_recorded_and_warned_without_failing` and `test_chunk_counts_fully_embedded_and_unknown_papers`.
- AC3: README paragraph in the retrieval section. `model_mismatch_warning` covered by `test_model_mismatch_warning`. `embedding_model` is still recorded.
- AC4: parity test without the silent skip, with a `RerankPool` == `RRF_POOL_SIZE` assert and a whole-query normalised comparison using the
  explicit `_GO_TO_EVAL_SQL` allowed-difference list. Every required temporary edit failed the test (renamed search.go; RerankPool 25;
  dropped the vector arm ORDER BY+LIMIT in eval and in Go; `rrf_score ASC` in eval and in Go; one arm LIMIT 40 in eval and in Go). So did two
  ORDER-BY-only mutants that keep `LIMIT 50` count = 2 (QA's M16 shape), which only the new comparison catches. Output is in the PR body.
- AC5: the test diff only re-indents the existing parity asserts and extends `_FakeCursor.__init__`; no assert removed. CI is green.
- AC6: 204 changed lines.
- Local: `python3 -m pytest -q tests/test_evals_data.py` 55 passed (47 before); `py_compile` ok; `--help` ok; ownership-check OK.
- Not run: `make eval` (no stack, no behaviour change on a healthy stack). `CHUNK_COUNTS_SQL` is not executed against real Postgres
  (stubbed cursor only). `make lint` locally (no Go 1.25), but the CI Go job ran vet/gofmt.
- 2026-11-03 19:02Z cycle (orchestrator): **Human review** from Mahesh on PR #17 (2026-11-03T17:59Z, head `910f2f8`) —
  top priority. PR stays draft; Jira → In Progress. Rework checklist (QA checks each item explicitly next round):
  - [x] H1 (P2, required): one source of truth for the Go default model — the test must **extract the default from
    `cmd/arxivlens/main.go`** and assert parity with the Python side (or Python reads it from Go), so a Go-side change
    fails the test. Shown by a temporary edit of the Go default (output pasted, edit not committed).
  - [x] H2 (P2, required): explicit `--model` override — the evaluator must compare against the model actually used
    when an override is supplied, not the duplicated default; tests for default parity **and** an explicit override.
    ("Preferably" the query service reports its runtime model — that is `internal/query/server.go`, backend-owned and
    an HTTP API change → backlog follow-up / ADR, not this PR.)
  - [ ] H3 (P2, **open, merge gate G1**): run `CHUNK_COUNTS_SQL` against the **real schema** in PostgreSQL+pgvector with a paper with zero
    embedded chunks and one partially embedded; attach output. Sandbox has no pgvector; needs a DB-backed CI job
    (backend, being added in OPS-H5 rework) → may stay open with "not run: <reason>" and is then a merge gate.

### ai-engineer, 2026-11-03 (rework r1, Mahesh's review)
- Head `557f4e12bbbb02b2dd3d6e28a7122af9ac460dbd` on `agent/ai/EVAL-5`. PR #17 is still draft, and its body now has the H1–H3 status.
  Files: `scripts/evaluate_retrieval.py`, `tests/test_evals_data.py`, `evals/README.md`. Diff vs main is 319 changed lines (ownership-check OK).
- CI on `557f4e1` (run 41702078502): Python M0 unit tests `126147657540` success (61 passed, 1 skipped); Go `126147657013`,
  Frontend `126147657411`, Agent ownership check `126147657276` success. Local: `pytest tests/test_evals_data.py` 58 passed, 1 skipped.
- [x] H1: `GO_DEFAULT_MODEL` removed. `go_default_model()` parses the `--model` StringVar default from `cmd/arxivlens/main.go`
  (it needs exactly one match). `test_go_model_default_parsed_from_main_go_matches_python_default` asserts it equals the
  `EMBEDDING_MODEL` default in `services/common/config.py`. With a temporary Go default of `BAAI/bge-large-en-v1.5`
  (not committed) the result is `1 failed` with `AssertionError: cmd/arxivlens/main.go --model default 'BAAI/bge-large-en-v1.5' != ...`.
  Deleting the flag gives `ValueError ... found []`.
- [x] H2: `--query-model` / `ARXIVLENS_QUERY_MODEL` (default: the Go default). The warning compares against it, and the summary records
  `query_model`. Tests: `test_model_mismatch_warning` (default parity) and `test_model_mismatch_uses_explicit_query_model_override`
  (match: no warning; differ: warning; env; CLI). Mutant "ignore the override" fails that test.
  **Follow-up (backend, backlog/ADR):** have the query service report its runtime `--model` (e.g. in `/healthz` or a
  `/v1/info`), so the eval can read it instead of being told. That changes `internal/query/server.go` and the HTTP API contract.
- [ ] H3: **not run.** The sandbox has PG16 binaries but no pgvector extension files and no `psycopg`, and PyPI/Docker are unreachable, so
  the real `halfvec(768)` migration can't be applied. Nothing was faked. Added the opt-in `test_chunk_counts_sql_against_real_postgres`
  (skipped without `DATABASE_URL`; cases 0/2 with another model's vector, 1/2, unknown 0/0; rolls back). It has never been executed.
  It needs the DB-backed CI job (OPS-H5) or a manual run, and remains a merge gate.
- Observation (not changed): `CHUNK_COUNTS_SQL` groups by `arxiv_id`, so if `papers` ever holds two versions of a paper,
  both versions' chunks are summed.

### pm-lead, 2026-11-03 (final review, head `557f4e1`)
- **APPROVE.** PR #17 raised for Mahesh's review. Verdict and reasoning are in [`agents/reviews/EVAL-5/report.md`](../reviews/EVAL-5/report.md) (PM section).
- H1 and H2 (Mahesh's Required items) are met, with mutation evidence 07/08. H3 is **not run** and is merge gate **G1**: Mahesh waits, runs it, or waives it.
  The PR does not claim coverage is verified against pgvector.
- Merge gate **G2**: #16 (OPS-H5, head `f69f340`) still renames `querySQL`. Whichever PR merges second rebases and re-runs CI. If #16 goes first, ai-engineer updates the parity extraction.
- Follow-ups F1–F5 are listed in the report (F1 runtime model reporting needs an ADR; F2 a `db.yml` pytest step closes H3).

### ai-engineer, 2026-11-04 (G2: #16 OPS-H5 merged first as `e67354c`)
- Head `f24e1da75d89bc519077bee4a263ebe89ab4d5ec` on `agent/ai/EVAL-5`: merge commit `95556da` (origin/main, no conflicts, no rebase/force-push)
  plus `f24e1da`. Delta on top of the merge: `tests/test_evals_data.py` +50/-4, `scripts/evaluate_retrieval.py` +9/-2, `evals/README.md` +4/-1.
  Diff vs main: 3 files, 379 changed lines (ownership-check OK for role=ai). No `internal/` or `.github/` change.
- Before: `pytest tests/test_evals_data.py` 1 failed (`HybridSearch querySQL not found exactly once`), 57 passed, 1 skipped. After: 59 passed, 1 skipped.
- Parity guard: `_go_string_const()` rebuilds `hybridSearchSQL` from the Go consts (raw/plain strings, `+`, identifiers resolved recursively;
  each const must be declared exactly once; comments are not part of the value). Added: `LIMIT 50` count and `ce.model = $2` on the resolved
  SQL, `vectorHitsSQL` spliced in, `fetchCandidates` runs `Exec(ctx, hnswSearchSettings)` once before `Query(ctx, hybridSearchSQL,` once.
  The raw-`src` asserts are kept as-is (nothing weakened).
- SET LOCAL decision: **mirror.** ADR-0010 says the gated mode mirrors production, and production now runs ef_search=100 + strict_order
  before the hybrid query. With the default ef_search=40 the eval's vector arm can return < 50 rows after the `ce.model` filter, so its RRF
  pool would differ from production's. The eval runs `RRF_HNSW_SETTINGS` (same text as `hnswSearchSettings`, asserted) right before
  `RRF_POOL_SQL` and `RESET`s after it, so the ungated BM25/dense baselines keep server defaults. Like production, it now needs pgvector >= 0.8.0.
  New test `test_rrf_pool_query_runs_with_production_hnsw_settings_then_resets`.
- Mutants (temporary, not committed), 23/23 caught: G1 rename search.go, G2 RerankPool 25, G3 vectorHitsSQL LIMIT 40, G4 G3 + `// LIMIT 50`
  comment (raw count stays 2; caught by the resolved-const count), G5 drop vector ORDER BY+LIMIT, G6 rrf_score ASC, G7 keyword LIMIT 40,
  G8 drop ce.model filter, G9 Go ef_search 200, G10 drop iterative_scan, G11 Query not on hybridSearchSQL, G12 settings Exec removed,
  G13 inline vector arm instead of the const, G14 main.go model default (H1); E1 eval ef_search 40, E2 settings not run, E3 no reset,
  E4 settings before BM25, E5 eval arm LIMIT 40, E6 eval ASC, E7 RRF_POOL_SIZE 25, E8 eval drops ce.model, E9 eval drops vector ORDER BY.
- Not run: `make eval` (no stack), `make test-unit`/`make lint` locally (no Go 1.25); CI on `f24e1da` is the source of truth. H3/G1 still open.
