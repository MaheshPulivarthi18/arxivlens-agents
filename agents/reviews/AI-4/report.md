<!-- Saved verbatim by the orchestrator (cycle 2026-11-03 19:02Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/18#issuecomment-6613883747, because the QA harness could not write report.md. -->

[qa-reviewer] QA report: AI-4 · PR #18 · round 1

**Verdict: PASS**. Reviewed commit `7e2650380d05ae0b7f1336767badf0b2305fd96c` · 2026-11-03
Ticket: `agents/tasks/AI-4.md` (AC1, AC3 in scope; AC2 moved to EVAL-5 AC4) · PRD: ADR-0010 (fallback "logged with the trace ID"), Technical PRD §7.1–7.2
Evidence pack: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/208a84d292c464179b6c605d5bd40c83ff6d58c4/agents/reviews/AI-4/evidence (the QA harness couldn't write `report.md`, so this comment is the report)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI run 41701810033, job 126146729066 | pass ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/208a84d292c464179b6c605d5bd40c83ff6d58c4/agents/reviews/AI-4/evidence/00-ci-checks.png?raw=true),`` [01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/208a84d292c464179b6c605d5bd40c83ff6d58c4/agents/reviews/AI-4/evidence/01-ci-go-job-log.png?raw=true))``` |
| Python M0 unit tests | CI job 126146729030 | pass |
| Frontend (lint, test, build) | CI job 126146729164 | pass |
| Agent ownership check | CI job 126146728646 | pass: `Ownership OK for role=ai (46 changed lines)` |
| Ticket verification | local scratch module | `go vet` OK, `gofmt -l` empty, `go test -cover ./internal/query/` ok, 69.0% ([05](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/208a84d292c464179b6c605d5bd40c83ff6d58c4/agents/reviews/AI-4/evidence/05-ac3-existing-tests.png?raw=true)).```` Local Go is 1.24.7, go.mod needs 1.25 and the proxy is unreachable, so I ran a scratch module with the PR-head `rag.go`/`search.go`/`client.go`/`rag_test.go`/`search_test.go` (`cmp`-verified identical) and `internal/db` stubbed. `make test-unit`/`make lint` not run locally; CI green. |
| `make eval` | not run | No stack in the sandbox. The change only touches a log line; retrieval order and answers are unchanged. |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `rag_test.go:614-656` `TestAskRerankFallbackLogsResponseTraceID`: a real `SearchEngine{rr: failing fakeReranker, fetch: fake}` inside `Ask`. It asserts exactly one `rerank fallback` line containing `trace_id=<resp.TraceID> ` and `trace_id_source=ctx`, plus RRF order `[1 2]` and one Rerank call. Passes at the head ([03](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/208a84d292c464179b6c605d5bd40c83ff6d58c4/agents/reviews/AI-4/evidence/03-ac1-new-test.png?raw=true))````` and in CI. The mutation check kills all 3 mutants ([04](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/208a84d292c464179b6c605d5bd40c83ff6d58c4/agents/reviews/AI-4/evidence/04-ac1-mutants.png?raw=true)):`````` M1 line reverted (origin/main) → `trace_id_source=generated`; M2 ctx gets a different ID → trace_id mismatch; M3 ID attached after `HybridSearch` → `generated`. |
| AC2 | n/a | Moved to EVAL-5 AC4 by pm-lead. `tests/test_evals_data.py` is not in the diff. |
| AC3 | ✅ | Diff is `rag.go` +1/-0 and `rag_test.go` +45/-0, so no existing test was touched ([02](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/208a84d292c464179b6c605d5bd40c83ff6d58c4/agents/reviews/AI-4/evidence/02-scope-diff.png?raw=true)).``````` All 20 existing `internal/query` tests pass at the head ([05](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/208a84d292c464179b6c605d5bd40c83ff6d58c4/agents/reviews/AI-4/evidence/05-ac3-existing-tests.png?raw=true)).```````` The only production change, `rag.go:75` `ctx = withTraceID(ctx, traceID)`, adds a context value. The response shape, ordering and HTTP API are unchanged. |

## Scope
Only `internal/query/rag.go` and `rag_test.go` changed (ai-engineer paths, confirmed by CI). No tickets/docs/evidence in the PR. `search.go`, OTel and the filter thresholds are untouched. No shared contract changes.

## PRD fit
ADR-0010 requires the `/v1/ask` rerank fallback to be logged with the trace ID. Before, the log line carried a fresh generated ID that matched nothing the user saw. Now it is the `trace_id` returned in the response, so a support report can be traced to the log.

## Findings
1. [nit] Side effect worth one line in the PR description: `ctx` now carries the trace ID for all of `Ask`, so the `citation support unverified` log (`rag.go:227-229`, via `validateCitations(ctx, …)`) also logs the response trace ID with `trace_id_source=ctx` on the `/v1/ask` path. This is the desired behaviour, but no `Ask`-level test pins it.

No blocking findings.

## Missing tests (nice-to-have)
- An `Ask`-level assertion that the `citation support unverified` line carries `trace_id=<resp.TraceID>`.
- A timeout fallback through `Ask`. The reason mapping is already table-tested in `TestHybridSearchRerankFallback`.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_
