# AI-4: `/v1/ask` passes its trace ID to `HybridSearch`; harden the ADR-0010 parity drift guard

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P2 |
| **PRD ref** | ADR-0010 (fallback "logged with the trace ID"); Technical PRD §7.1–7.2 |
| **Depends on** | RET-1, EVAL-1 (both merged); AI-3 (PR #13, same files: wait until merged) |
| **Jira** | find with JQL `labels = "task-AI-4"` |
| **Design required** | no (P2, no contract change) |
| **Status** | Ready once AI-3 (#13) merges |

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
- [x] AC2: **moved to [EVAL-5](EVAL-5.md) AC4(a)(b)** (pm-lead 2026-11-03 16:00). ~~the parity test fails if `internal/query/search.go` is missing (shown by running it with the file renamed, output pasted) and fails if `RerankPool` in `search.go` differs from `RRF_POOL_SIZE` (shown with a temporary edit, output pasted; edit not committed).~~
- [ ] AC3: `/v1/ask` responses and behaviour otherwise unchanged (existing `rag_test.go` tests pass).

## Verification
```bash
cd app && go vet ./... && test -z "$(gofmt -l .)" && go test -cover ./internal/query/...
python -m pytest -q tests/test_evals_data.py
make test-unit && make lint
```

## Notes
- Created 2026-11-02 by pm-lead at the RET-1 design gate (`docs/design/RET-1.md` → PM decision, follow-ups).
- 2026-11-03 (pm-lead): dependencies met (RET-1 = ArxivLens #9, EVAL-1 = #2, both merged; origin/main `bb9ee90`) → Ready. Checked against `bb9ee90`: `traceID := generateTraceID()` is `rag.go:73` and `HybridSearch` is called at `rag.go:76`; `withTraceID`/`traceIDFrom` are at `search.go:213-224`; the fallback log is `search.go:198` (`rerank fallback trace_id=%s trace_id_source=%s ...`); `const RerankPool = 20` is `search.go:17`; `RRF_POOL_SIZE = 20` is `scripts/evaluate_retrieval.py:50`; the silent skip is `tests/test_evals_data.py:241` (`if os.path.exists(go):`). For AC1, `rag_test.go`'s `fakeSearcher` bypasses `search.go`, so build a real `&SearchEngine{rr: <failing fake reranker>, fetch: <fake fetch>}` (unexported seams, same package) and pass it as `RAGService.searchEngine`; capture `log` output with `log.SetOutput`. Ordering: AI-2 first (P1, same files), then AI-4. No Jira story found (`labels = "task-AI-4"` returns nothing); orchestrator to create one under the Retrieval/Eval epic.
- 2026-11-03 14:00 cycle (pm-lead): not started; waits for AI-3 (same files). Line refs at `9c1229a` (after AI-2): `traceID := generateTraceID()` is `rag.go:74`, `HybridSearch` `rag.go:77`; `search.go` refs unchanged (`:17`, `:198`, `:213-224`); silent skip `tests/test_evals_data.py:241`. Re-check after AI-3 merges.
- 2026-11-03 16:00 cycle (pm-lead, plan): the `tests/test_evals_data.py` parity-test part (old Scope bullet 3 and AC2) moved
  to EVAL-5 AC4, which rewrites the same test. AI-4 is now `rag.go` + `rag_test.go` only (AC1, AC3) and stays parked until
  AI-3 (#13) merges. Ignore Scope bullet 3 and the `pytest tests/test_evals_data.py` verification line.
