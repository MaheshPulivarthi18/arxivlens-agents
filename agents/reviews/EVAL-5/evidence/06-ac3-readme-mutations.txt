$ bash -c grep -n -E '^## |Model name: two sources|Partly embedded papers|SQL parity test' evals/README.md; echo; python3 /tmp/claude-0/-home-claude/89335d91-2f06-5a4a-8e86-f0fff55515ee/scratchpad/mutate.py /tmp/claude-0/-home-claude/89335d91-2f06-5a4a-8e86-f0fff55515ee/scratchpad/mutants.json ac3
15:## Running
43:- **Model name: two sources that must match.** The eval reads `EMBEDDING_MODEL` (`services/common/config.py`,
51:- **Partly embedded papers are reported, not gated.** For every relevant paper the results JSON records
55:- The SQL parity test in `tests/test_evals_data.py` compares the RRF pool query with `internal/query/search.go`
67:## Seeding the corpus
77:## Adding cases

[mismatch warning never emitted] scripts/evaluate_retrieval.py: '    if model == query_model:\n        return None\n' -> '    return None\n'
    exit=1  2 failed, 56 passed, 1 skipped in 0.17s
    FAILED tests/test_evals_data.py::test_model_mismatch_warning - TypeError: arg...
    FAILED tests/test_evals_data.py::test_model_mismatch_uses_explicit_query_model_override
[embedding_model not recorded] scripts/evaluate_retrieval.py: '"embedding_model": model, ' -> ''
    exit=1  2 failed, 56 passed, 1 skipped in 0.18s
    FAILED tests/test_evals_data.py::test_run_checks_healthz_before_any_rerank_and_reports_metrics
    FAILED tests/test_evals_data.py::test_model_mismatch_warning - KeyError: 'emb...
worktree clean after restore: True

[exit code 0]
