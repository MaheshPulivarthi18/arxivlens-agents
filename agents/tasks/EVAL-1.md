# EVAL-1: Versioned golden eval sets + `make eval` quality gate

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (QA-8 cannot be judged without it) |
| **PRD ref** | Product PRD §8 Success metrics |
| **Depends on** | — (runs against whatever corpus is indexed; works best after OPS-H1) |
| **Status** | Done (PR #2 squash-merged as `a959d03` on 2026-11-03) |

## Goal
The PRD's quality targets (Recall@5 ≥ 0.80, supported ≥ 90%, refusal ≥ 95%) have no versioned dataset behind them.
Make quality measurable and gateable so every retrieval/answering change is judged on numbers, not vibes.

## Scope
- Create `evals/`:
  - `evals/corpus.txt` — list of arXiv IDs the eval assumes are indexed (start with the papers already used in `scripts/evaluate_retrieval.py`).
  - `evals/retrieval.jsonl` — `{"id","query","relevant_arxiv_ids":[...]}`; move the existing hardcoded queries here and grow to ≥ 30.
  - `evals/answer.jsonl` — `{"id","question","expected_arxiv_ids":[...]}` for in-corpus questions (≥ 20).
  - `evals/refusal.jsonl` — `{"id","question"}` clearly out of corpus (≥ 20, e.g. cooking, sports, unrelated science).
  - `evals/thresholds.json` — the Product PRD §8 targets.
  - `evals/README.md` — how to add cases, how to seed the corpus (`scripts/ingest_batch.py` or `/v1/papers/ingest`).
- Refactor `scripts/evaluate_retrieval.py` to read `evals/retrieval.jsonl` (no hardcoded queries).
- Add `scripts/evaluate_answers.py`: calls `/v1/ask` for answer + refusal sets; reports % supported citations,
  % answers citing an expected paper, correct-refusal rate, p50/p95 latency.
- Add `scripts/eval_gate.py`: runs both, writes `evals/results/<timestamp>.json` (git-ignored), prints a table, exits non-zero if any metric is below `thresholds.json`.
- Out of scope: changing retrieval logic or thresholds in `rag.go`. The Makefile `eval` target is backend-owned; request the change in Notes (or it already calls `scripts/eval_gate.py` — check).

## Acceptance criteria
- [x] AC1 — No eval queries remain hardcoded in `scripts/evaluate_retrieval.py`. *Evidence: the 4 old queries are now `evals/retrieval.jsonl` r001–r004; the script loads cases via `load_cases()`; `test_retrieval_script_has_no_hardcoded_queries` passes.*
- [x] AC2 — Datasets meet the minimum sizes above and every `relevant_arxiv_ids`/`expected_arxiv_ids` entry is in `corpus.txt`. *Evidence: retrieval 34, answer 22, refusal 22 cases, corpus 31 IDs; `tests/test_evals_data.py` checks sizes, schema, corpus membership, unique IDs (18 passed).*
- [~] AC3 — `python scripts/eval_gate.py --help` works without infra; with the stack up it prints all metrics and exits 0/1 by threshold. *Evidence: `--help` exits 0 with no infra or heavy deps. Threshold logic is unit-tested on fake results (pass, each metric below target, partial run, hybrid not beating baselines). With no stack it exits 2 ("could not run"). **Not verified against a live stack.***
- [x] AC4 — Baseline numbers for the current templated `/v1/ask` recorded in `evals/BASELINE.md` (or "not run: infra unavailable" plus the exact command for the human). *Evidence: `evals/BASELINE.md` says "not run: infra unavailable in agent sandbox" and gives the exact commands.*
- [ ] AC5 — `evals/results/` added to `.gitignore` (request in Notes if outside your scope — pm-lead/backend can apply). *Requested below (`.gitignore` is backend-owned per `scripts/agent_guardrails.sh`).*

## Verification
```bash
make test-unit
python scripts/eval_gate.py --help
make stack-up && python scripts/eval_gate.py   # when infra is available
```

## Notes
- 2026-11-01 (ai-engineer, attempt 1): implemented on `agent/ai/EVAL-1`. Files: `evals/{corpus.txt,retrieval.jsonl,answer.jsonl,refusal.jsonl,thresholds.json,README.md,BASELINE.md}`, `scripts/{eval_gate.py,evaluate_answers.py}`, refactored `scripts/evaluate_retrieval.py` (dataset-driven, lazy heavy imports, returns a summary dict, `--dataset/--json-out`), `tests/test_evals_data.py`, README eval commands. Diff is about 710 changed lines, which is over the 400 target; about 140 of those are data.
- **Unverified (sandbox has no Docker, HF, arXiv, or Go 1.25):** no eval has been run against a live stack, so there are no baseline numbers. `make test-unit` and `make lint` fail at the Go 1.25 toolchain download. `tests/test_m0.py` needs torch, which is not installed. `oxlint` is not installed. The dataset queries have not been checked against real retrieval. The content of 2608.20331 and 2608.20320 was carried over from the old script without checking.
- **Gate semantics:** recall@5 is gated on the "Hybrid RRF + Rerank" mode. Retrieval coverage must be 1.0, so any query whose paper is not indexed fails the gate instead of being silently skipped. Any failed /v1/ask call (error or timeout, in either the answer or refusal set) fails the gate through the `ask_errors == 0` check. Failed calls are also included in p50/p95 at their elapsed time (a timeout counts as at least the `--timeout` value), and they never count as a refusal, hit, or supported citation. If every request fails, the gate exits 2. (Fix round 1, after pm-lead review: previously, failed in-corpus calls changed no gated metric.) Partial runs (`--skip-*`) never pass. Exit codes: 0 pass, 1 fail, 2 could not run.
- **Follow-up request, backend-engineer:** (1) add `evals/results/` to `.gitignore` (AC5). (2) Add `tests/test_evals_data.py` to `make test-py` / `test-unit`. It needs no infra and runs in under 1 s; today `test-py` only runs `tests/test_m0.py`.
- **Follow-up request, pm-lead:** the AGENTS.md §5 gotcha "Retrieval eval queries are hardcoded in `scripts/evaluate_retrieval.py`" is stale once this merges. Product PRD §8 "Measured with ..." could also mention `make eval` / `scripts/eval_gate.py`.
- **Findings for future ai-engineer tasks (not changed here, since they are out of scope):** (a) the eval's "Hybrid RRF + Rerank" mode reranks with a BGE bi-encoder dot product, not the cross-encoder `/internal/rerank` that `/v1/ask` uses. (b) Recall@5 is chunk-level with denominator `min(|relevant chunks|, 5)`, so it behaves like precision@5. It is strict, but pm-lead should confirm the intended definition, and an ADR is needed if it changes. (c) `rag.go` marks a citation `supported=true` (score 0.75) when the embedder call fails, which inflates the supported-citation rate. Cover this in AI-1/QA-8. (d) The PRD target `/v1/search` p95 < 1.5 s is not gated, because EVAL-1 scope did not include it.
- 2026-11-02 (ai-engineer, rework round 2, after the human "Needs work" review on PR #2):
  - **Blocker 1 (Recall@5 definition): still open and BLOCKED on ADR-0006** (Status: Proposed, PR #3). The gated value is chunk-level hits / min(|relevant chunks|, 5), which acts like precision@5 and is not paper-level recall. I did not change the definition, because that would pre-empt an ADR that only the human can accept. Once ADR-0006 is Accepted, implement its definition in `compute_recall_at_k` / `run_retrieval_evaluation` and re-baseline. Until then, the gate's Recall@5 number must not be read as the PRD §8 Recall@5.
  - **Blocker 2 (rerank path): fixed.** Mode "Hybrid RRF + Rerank" now reorders the Hybrid RRF top-10 by `POST <embedder>/internal/rerank`, the production cross-encoder endpoint that `/v1/ask` reaches via `EmbedClient.Rerank`. It no longer uses a local BGE bi-encoder dot product. The embedder URL comes from `--embedder-url` or `ARXIVLENS_EMBEDDER_URL` (default `http://localhost:8081`, the same default as `arxivlens query --embedder-url`). The eval checks `/healthz` first and refuses to run if `"reranker"` is not true, because `api.py` silently falls back to bi-encoder scoring in that state. Any rerank HTTP error or score-count mismatch raises, so the gate exits 2. The summary records `rerank_path`, and the gate has a `rerank via production /internal/rerank` check that also withholds the gated Recall@5 when that value is missing. Tests (HTTP mocked, no infra) assert the exact URL, method, body, and timeout, and assert that the gated ordering follows the endpoint's scores. The misleading `eval_gate.py` comment is fixed.
  - **Major 3 (coverage): fixed.** Coverage is now checked per arXiv ID (`relevant_chunks_for_case` / `missing_arxiv_ids`). A case is skipped unless every relevant ID has chunks, and skipped cases fail the gate through coverage. Missing IDs are printed per case and saved as `missing_arxiv_ids` in the results JSON. Added tests for the two-paper / one-indexed case.
  - **Remaining production/eval mismatch, for the owners to decide (not changed here):** production `HybridSearch` (`internal/query/search.go`, backend-owned) attaches rerank scores but does **not** reorder by them, and `/v1/ask` fetches only `maxCitations` (5) RRF hits before reranking. Production also uses LIMIT 50 per arm plus a `ce.model` filter, while the eval uses 20 and no filter. So the gated mode measures the production *reranker model and endpoint*, not the exact `/v1/ask` ordering. Suggested follow-up for backend-engineer and ai-engineer: either sort by `RerankScore` in production (rerank a larger RRF pool, then truncate) or redefine the gated mode to match. The second option should go through an ADR alongside ADR-0006.
  - Unverified: no live run (no Docker, HF, Go 1.25, or npm in the sandbox). `make test-unit`, `make lint`, and `make eval` were not run.
- 2026-11-02 (orchestrator) **Unblocked: Mahesh decided ADR-0006 (Option 3) and ADR-0010 (production sorts by rerank).**
  Rework round 3 checklist for ai-engineer. QA must check every line, and each line maps to Mahesh's PR #2 review or QA round 2.
  - [x] R3-1 (review blocker 1, ADR-0006): gated `recall@5` is **paper-level**: dedupe ranked chunks to arXiv IDs in
        rank order, `|top-5 papers ∩ relevant_arxiv_ids| / |relevant_arxiv_ids|`. MRR and NDCG@5 use the same paper ranking.
  - [x] R3-2 (ADR-0006): today's formula is kept as `chunk_precision@5`, reported but **not gated**.
  - [x] R3-3 (review blocker 1 fix + QA r2 missing tests): tests that tell recall and precision apart: one relevant
        paper with ≥5 chunks filling the top 5 (recall 1.0, precision high); a two-paper case where only one paper
        appears (recall 0.5); duplicate chunks of one paper don't raise recall. A denominator mutation must fail a test.
  - [x] R3-4 (review blocker 2, ADR-0010): the gated mode mirrors ADR-0010 exactly: RRF pool of 20 candidates
        (50 per arm, `ce.model` filter, as in `search.go`), one `/internal/rerank` call, stable sort by score (ties keep
        RRF order), top 5. The README/report state that production matches only after RET-1 merges.
  - [x] R3-5 (QA r2 finding 3): test that `run_retrieval_evaluation` calls the `/healthz` cross-encoder check before
        any rerank, and that a failed check produces no summary (stub psycopg/embedder/urlopen).
  - [x] R3-6 (QA r2 finding 4): coverage counts a paper only if its chunks have embeddings for the current model
        (`chunk_embeddings` with `model` filter), not just `paper_chunks`.
  - [x] R3-7 (review should-fix "no Fixes #N"): no GitHub issue exists. The PR body links Jira **KAN-8** and the
        spec instead; say so explicitly in the PR description.
  - [x] R3-8 (QA r2 finding 6): the PR description reflects round 3 (pm-lead does this when raising).
  - [x] R3-9 (repo split): PR #2 contains **no** `agents/` files; tickets and reviews now live in arxivlens-agents.
  - Already done in round 2 (keep): production `/internal/rerank` endpoint + `/healthz` guard; per-paper coverage (review major 3).
- 2026-11-02 (ai-engineer, round 3) app commit `d83a4c0` on `agent/ai/EVAL-1` (PR #2, left in draft). Files changed:
  `scripts/evaluate_retrieval.py`, `scripts/eval_gate.py`, `tests/test_evals_data.py`, `evals/README.md`, `evals/BASELINE.md`,
  `evals/thresholds.json` (only the `_source` text; every threshold value is unchanged), `README.md` (one line). No eval case was added or removed.
  - **R3-1 done.** `score_case()` dedupes the ranked chunks to arXiv IDs with `dedupe_to_papers()`, which keeps the first rank
    and strips `vN`. It then computes `compute_recall_at_k(papers, relevant)` = `|top-5 ∩ relevant| / |relevant|`. MRR and NDCG@5
    use the same paper list. The `compute_recall_at_k` name is kept (and now means standard recall) because
    `tests/test_m5_m6_telemetry_eval.py` imports it. Its assertions still hold; I checked them inline because that file needs
    opentelemetry/psycopg to import.
  - **R3-2 done.** `chunk_precision@5` = `|top-5 chunks from a relevant paper| / 5`. It is the ADR-0006 text formula: divide by 5.
    The old `min(|relevant chunks|, 5)` only differs when relevant papers have fewer than 5 chunks in total. It is in every mode's
    summary and results JSON, and the gate prints it as an "(info, not gated)" row. The gate never reads it:
    `test_gate_ignores_chunk_precision` sets it to 0 (still PASS) or 1.0 with recall 0.79 (still FAIL).
  - **R3-3 done.** New tests: `test_one_relevant_paper_filling_top5_is_full_recall`,
    `test_best_chunk_first_then_other_papers_is_full_recall_low_precision` (the ADR-0006 example: recall 1.0, precision 0.2),
    `test_two_relevant_papers_one_retrieved_is_half_recall`, `test_duplicate_chunks_do_not_raise_recall`,
    `test_paper_level_mrr_and_ndcg_use_deduped_ranking`, `test_recall_denominator_is_all_relevant_papers_not_capped_at_k`,
    `test_chunk_precision_divides_by_k_even_with_fewer_hits`.
  - **R3-4 done (eval side).** `RRF_POOL_SQL` copies the `search.go` HybridSearch SQL, including ORDER BY + LIMIT 50 in both arms,
    `WHERE ce.model = ...` and k=60, and requests a pool of `RRF_POOL_SIZE = 20`. `rerank_pool()` makes ONE `/internal/rerank`
    call over the whole pool, stable-sorts by score descending, and keeps the top `RESULT_LIMIT = 5`. A rerank error raises
    (fail closed) instead of falling back to RRF order like production does. The round-2 `/healthz` guard is kept.
    All 4 modes are scored on their top 5 chunks (the `/v1/ask` default `maxCitations`). Dense now also filters on
    `ce.model`. This also fixes a round-2 bug: the old eval's vector CTE had `LIMIT 20` with no ORDER BY, so it returned
    arbitrary rows. The eval keeps a `c.id` tiebreak after `rrf_score` for determinism; production has none.
    `evals/README.md` and `evals/BASELINE.md` say production matches only after RET-1 merges. Parity tests:
    `test_adr0010_parity_pool_one_call_stable_ties_top5` (pool params = 20, exactly 1 call with 20 passages, tie order kept,
    5 results), `test_rrf_pool_sql_mirrors_search_go` (also reads `internal/query/search.go` and asserts 2× `LIMIT 50`,
    `ce.model = $2`, and the `60 +` constants, so drift fails the test), and `test_rerank_pool_empty_makes_no_call`.
    **RET-1 heads-up:** if RET-1 changes those `search.go` fragments, update that test in the same PR.
  - **R3-5 done.** `test_run_checks_healthz_before_any_rerank_and_reports_metrics` stubs `psycopg`, `scripts.m0_skeleton`,
    `services.common.config` and `urlopen` via `sys.modules`/monkeypatch. It runs `run_retrieval_evaluation` end to end on
    2 cases and asserts: `/healthz` is the first event and comes before the single rerank call; `missing_arxiv_ids` is reported
    for the half-indexed case; the summary values are right. `test_run_with_failed_healthz_yields_no_summary` (2 params)
    asserts RerankError is raised and the event log is only `["healthz"]` (no DB connect, no embedder, no rerank).
  - **R3-6 done.** `COVERAGE_SQL` joins `chunk_embeddings` with `ce.model = %(model)s`. The model comes from
    `config.embedding_model` (`EMBEDDING_MODEL`, the same env var the embedder worker writes with) and is recorded as
    `embedding_model` in the summary. Test: `test_coverage_requires_embeddings_for_current_model` (chunked-not-embedded and
    other-model papers count as missing).
  - **R3-9 done.** `git diff --name-only origin/main...HEAD` has no `agents/`, `docs/`, `.claude/`, `AGENTS.md` or `CLAUDE.md`
    files. Text that pointed at moved docs is reworded: the `thresholds.json` `_source`, the `eval_gate.py` comment (used to cite
    `agents/tasks/EVAL-1.md`), and the `evals/README.md` intro now say "Product PRD §8 (arxivlens-agents)" / ADRs and link
    `https://github.com/MaheshPulivarthi18/arxivlens-agents/...`.
  - **Results (local):** `python3 -m pytest -q tests/test_evals_data.py` → `47 passed in 0.11s` (was 33).
    `PYTHONPATH=. python3 scripts/eval_gate.py --help` → exit 0. A no-stack gate run → exit 2 ("could not run": no psycopg).
    `.github/scripts/ownership-check.sh origin/main agent/ai/EVAL-1` → `Ownership OK for role=ai (1610 changed lines)`,
    with the >400 size warning.
  - **Mutation testing** (scratch copy, 17 mutants): first pass 15/17 killed. The survivors were
    "denominator → min(|relevant|, 5)" (only differs with more than 5 relevant papers) and "chunk precision ÷ len(hits)".
    I added the two tests above, and the second pass killed **17/17**: denominator → k / → min(|rel|,k); skip dedupe in
    score_case; dedupe no-op; NDCG ideal not deduped; tie order reversed; no top-5 truncation; pool 10; rerank only RRF
    top 5; arm limit 20; drop `ce.model` in pool; coverage on `paper_chunks` only; coverage ignores model; delete the
    `require_cross_encoder` call; healthz after DB connect; gate reads `chunk_precision@5`; precision ÷ len(hits).
  - **Unverified:** `make test-unit`, `make lint` and `make eval` were not run locally (no Go 1.25, npm, Docker, HF or psycopg in
    the sandbox); CI is the source of truth. The SQL has never run against a real Postgres. No baseline numbers exist, so
    there are no before/after numbers; `evals/BASELINE.md` still says "not run". The round-3 diff alone is about 616 lines
    (465+/151−), over the 400 target; most of it is the tests the review asked for.
  - **Still open, not mine:** R3-7/R3-8 (pm-lead, PR description). AC5 / tests in CI → OPS-H4. Production ordering → RET-1.
- 2026-11-02 (pm-lead, round-3 final review): **APPROVE.** R3-7/R3-8 done: the PR #2 description was rewritten with a review → resolution table, the "No GitHub issue; Jira KAN-8 + spec" line, the ADR-0010/RET-1 statement, and evidence pinned to `b9059b2`. The PR is marked ready for review and labelled `ready-to-merge`. QA r3 nits 2–5 → EVAL-2 AC6–AC9. AC5 and CI for the eval tests → OPS-H4 (AC5 added). ADR-0010 filter reading → RET-1 Notes. Decision: `agents/reviews/EVAL-1/report.md` § "PM decision — round 3".
