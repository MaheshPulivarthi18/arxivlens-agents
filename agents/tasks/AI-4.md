# AI-4: `/v1/ask` passes its trace ID to `HybridSearch`; harden the ADR-0010 parity drift guard

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P2 |
| **PRD ref** | ADR-0010 (fallback "logged with the trace ID"); Technical PRD §7.1–7.2 |
| **Depends on** | RET-1 (adds `withTraceID` in `search.go`), EVAL-1 (adds `test_rrf_pool_sql_mirrors_search_go`); both merged |
| **Jira** | find with JQL `labels = "task-AI-4"` |
| **Design required** | no (P2, no contract change) |
| **Status** | Blocked (needs RET-1 and EVAL-1 merged) |

## Goal
When reranking falls back to RRF order during `/v1/ask`, the log line should carry the same `trace_id` the user gets in
the response, so a support report can be traced. And the eval's parity test should fail loudly, not pass silently, if
production drifts from the mirrored pool settings.

## Scope
- `internal/query/rag.go`: in `Ask`, `ctx = withTraceID(ctx, traceID)` right after `traceID := generateTraceID()`,
  before `HybridSearch`. No other change.
- `internal/query/rag_test.go`: test that a rerank fallback during `Ask` logs `trace_id=<the response's TraceID>`
  with `trace_id_source=ctx` (fake reranker/fetch seams from RET-1).
- `tests/test_evals_data.py::test_rrf_pool_sql_mirrors_search_go`: assert `search.go` exists (drop the silent
  `os.path.exists` skip) and assert `RerankPool = 20` in `search.go` equals `evaluate_retrieval.RRF_POOL_SIZE`.
- Out of scope: `search.go` (backend), OpenTelemetry wiring, `rag.go` filter thresholds.

## Acceptance criteria
- [ ] AC1: a `rag_test.go` unit test forces a rerank failure in `Ask` and asserts the captured log line contains `trace_id=` + the `TraceID` returned in the `AskResponse`, and `trace_id_source=ctx`.
- [ ] AC2: the parity test fails if `internal/query/search.go` is missing (shown by running it with the file renamed, output pasted) and fails if `RerankPool` in `search.go` differs from `RRF_POOL_SIZE` (shown with a temporary edit, output pasted; edit not committed).
- [ ] AC3: `/v1/ask` responses and behaviour otherwise unchanged (existing `rag_test.go` tests pass).

## Verification
```bash
cd app && go vet ./... && test -z "$(gofmt -l .)" && go test -cover ./internal/query/...
python -m pytest -q tests/test_evals_data.py
make test-unit && make lint
```

## Notes
- Created 2026-11-02 by pm-lead at the RET-1 design gate (`docs/design/RET-1.md` → PM decision, follow-ups).
