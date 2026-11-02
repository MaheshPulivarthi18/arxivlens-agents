#!/usr/bin/env bash
# Design condition 2 command (verbatim logic), run from the PR head checkout, plus a negative control.
set -uo pipefail
git fetch -q origin agent/ai/EVAL-1 && echo "EVAL-1 @ $(git rev-parse --short FETCH_HEAD); search.go from PR head $(git rev-parse --short HEAD)"
D=$(mktemp -d) && git archive FETCH_HEAD | tar -x -C "$D" && cp internal/query/search.go "$D/internal/query/search.go"
echo "== 1. parity test against PR head search.go (expect pass)"
(cd "$D" && python3 -m pytest -q -p no:cacheprovider tests/test_evals_data.py::test_rrf_pool_sql_mirrors_search_go 2>&1 | tail -3)
echo "== 2. negative control: same file + one comment line containing 'LIMIT 50' (expect FAIL)"
printf '\n// LIMIT 50\n' >> "$D/internal/query/search.go"
(cd "$D" && python3 -m pytest -q -p no:cacheprovider tests/test_evals_data.py::test_rrf_pool_sql_mirrors_search_go 2>&1 | tail -3)
