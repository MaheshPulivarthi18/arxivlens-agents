# EVAL-5: Harden the retrieval eval tests (EVAL-1 QA round-3 nits) and the ADR-0010 parity drift guard

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P2 (harness/quality) |
| **PRD ref** | Product PRD §8 (Recall@5 gate robustness); QA-2; ADR-0006, ADR-0010 |
| **Depends on** | EVAL-1 (PR #2 merged `a959d03`), RET-1 (PR #9 merged `bb9ee90`) |
| **Jira** | find with JQL `labels = "task-EVAL-5"` (orchestrator to create under the Retrieval/Eval epic) |
| **Design required** | no (P2, no gate, threshold or contract change) |
| **Status** | In QA (draft PR [#17](https://github.com/MaheshPulivarthi18/ArxivLens/pull/17), head `910f2f8`) |

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
