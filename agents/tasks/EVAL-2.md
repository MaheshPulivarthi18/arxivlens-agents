# EVAL-2: Gate `/v1/search` p95 and harden the eval tests

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P2 |
| **PRD ref** | Product PRD §8 (`/v1/search` p95 < 1.5 s, Recall@5 gate robustness); QA-2; ADR-0006, ADR-0010 |
| **Depends on** | EVAL-1 (PR #2 merged) |
| **Status** | Ready (start once PR #2 is merged) |

## Goal
EVAL-1 left two kinds of gap. (b) The PRD target `/v1/search` p95 < 1.5 s is not measured or gated at all. (c) QA round 3 on
EVAL-1 found four test-strength and robustness nits in the retrieval eval. (Gap (a), "the rerank mode uses a bi-encoder", was
**fixed in EVAL-1 round 2/3**: the gated mode now calls `/internal/rerank` per ADR-0010. It is removed from this ticket; re-scoped by pm-lead 2026-11-02.)

## Scope
- New `tests/test_eval_gate.py` (no infra): `/v1/search` latency gate-decision tests. You may also move the gate tests out of `tests/test_evals_data.py` into it; none may be dropped or weakened.
- `scripts/evaluate_retrieval.py` + tests: the EVAL-1 QA round-3 nits (AC6–AC9).
- `scripts/evaluate_answers.py` or a small new `scripts/evaluate_search.py` called by `scripts/eval_gate.py`: time `POST /v1/search` (`rerank: true`) for every `evals/retrieval.jsonl` query, after one warm-up call, and report p50/p95.
- `evals/thresholds.json`: add a **new gate key** `search_p95_latency_ms_max: 1500`. The value is the existing Product PRD §8 target, but adding a gate key changes the gate. Thresholds change only through an Accepted ADR, so **the PR needs Mahesh's explicit confirmation** of this key before merge (ask in the PR description).
- Results JSON records the machine profile (CPU model, core count, RAM, torch device: `mps`/`cuda`/`cpu`), so numbers can be read against Technical PRD §9.
- Update `evals/README.md` and `evals/BASELINE.md`.
- Out of scope: changing any existing threshold, the Recall@5 definition (ADR-0006), the ADR-0010 pool/ordering, or `rag.go`.

## Acceptance criteria
- [x] AC1 — ~~The gated rerank mode's scores come from `/internal/rerank`~~ Done in EVAL-1 (`test_gated_mode_calls_production_rerank_endpoint`, `test_adr0010_parity_pool_one_call_stable_ties_top5`). Nothing to do; keep those tests passing.
- [ ] AC2 — `make eval` prints `/v1/search` p50/p95 and exits 1 when p95 > 1500 ms, **unconditionally** (on any machine, same as today's `ask_p95` gate). The machine profile is written to the results JSON. A unit test in `tests/test_eval_gate.py` covers the gate decision with fixed numbers. If Mahesh approves the Proposed reference-hardware rule in Technical PRD §9, a later task makes latency gates profile-aware; do not implement that here.
- [ ] AC3 — Failed `/v1/search` calls fail the gate, the same way `ask_errors` does.
- [ ] AC4 — The PR description asks Mahesh to confirm the new `search_p95_latency_ms_max` key.
- [ ] AC5 — Before/after `make eval` numbers pasted, or "not run: infra unavailable" plus the exact command.
- [ ] AC6 (EVAL-1 QA r3 finding 2, mutant M13) — A rerank error stops the run. A test injects a rerank function that raises (`RerankError` and a score-count mismatch) into `run_modes_for_case` / `run_retrieval_evaluation` (stubbed as in `test_run_checks_healthz_before_any_rerank_and_reports_metrics`) and asserts the run raises and produces no summary. The mutant "catch the error in `rerank_pool` and fall back to RRF order" must fail this test (paste the mutation result).
- [ ] AC7 (finding 3, mutants M16/M17) — The SQL parity test is robust to ORDER BY and sort-direction drift. It compares the normalised CTE/arm text of `RRF_POOL_SQL` with `internal/query/search.go` (placeholders normalised; the allowed differences are listed explicitly in the test, as in QA evidence 307), or it runs both against Postgres in an integration test. These mutants must fail it: drop the vector arm's `ORDER BY ... LIMIT 50` before LIMIT; `ORDER BY rrf_score ASC`; change one arm's `LIMIT 50`. If RET-1 has merged and changed `search.go`, compare against the new text.
- [ ] AC8 (finding 4) — A paper with only some chunks embedded is visible in the output. For each relevant paper the summary records `embedded_chunks` / `total_chunks` for the current model, and the run prints a warning for any paper with embedded < total. The gate does not fail on it (warning only; changing that needs an ADR). Unit test with a stubbed cursor.
- [ ] AC9 (finding 5) — The model-name sources are documented and recorded. `evals/README.md` says that the eval reads `EMBEDDING_MODEL` (Python config) while the Go query service uses its `--model` flag (default `BAAI/bge-base-en-v1.5`), and that both must match. The results JSON keeps `embedding_model`. The eval also prints a warning when `EMBEDDING_MODEL` differs from the Go default `BAAI/bge-base-en-v1.5`, because the Go side has only a flag and no env var. This is a warning only, with no gate change. Unit test for the warning.

## Verification
```bash
make test-unit
python3 -m pytest -q tests/test_evals_data.py
python3 -m pytest -q tests/test_eval_gate.py
python3 scripts/eval_gate.py --help
make eval   # when infra is available
```

## Notes
- Specced by pm-lead in PM-1 from EVAL-1 findings (a) and (d).
- 2026-11-02 (pm-lead, EVAL-1 round-3 PM review): re-scoped. (a) the production rerank endpoint was done in EVAL-1, so AC1 is closed. Added AC6–AC9 from EVAL-1 QA round 3 nits 2–5 (`agents/reviews/EVAL-1/report.md`, round 3 Findings; mutation evidence `evidence/310-qa-mutations.png`). Expected diff is about 250 lines; split AC6–AC9 into EVAL-3 if the build goes over 400.
