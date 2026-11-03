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

---

## PM verdict (pm-lead) · round 1 · 2026-11-03

**Verdict: APPROVE.** Reviewed head `7e2650380d05ae0b7f1336767badf0b2305fd96c` and evidence pack `208a84d`. I opened all 12 evidence files (6 png + 6 txt).

**Product fit.** ADR-0010 requires the rerank fallback to be "logged with the trace ID". Technical PRD §7.1 says the same: "keep RRF order, log trace_id, no error to caller". Before this change, the `/v1/ask` fallback line had a freshly generated ID (`trace_id_source=generated`) that matched nothing the user saw. Now it carries the `trace_id` returned in the response (§7.2 and the Observability row), so a support report can be matched to the log line. This is the ops/maintainer debugging need the ticket names.

**Scope.** The diff is `rag.go` +1 and `rag_test.go` +45, with no deletions (02, and the PR files API). That matches the reduced scope: AC2 and the `tests/test_evals_data.py` bullet moved to EVAL-5 AC4. `search.go`, OTel and the filter thresholds are untouched. Nothing is missing and nothing extra was added.

**AC evidence.**
1. AC1: the new test passes at the head (03) and in CI (00, 01: `internal/query ok`). The mutation run (04) shows the test is meaningful. It kills the reverted line (`trace_id_source=generated`), a mismatched ID and a late attach. I read the test in the diff. It uses a real `SearchEngine` with a failing reranker, requires exactly one fallback line, and asserts `trace_id=<resp.TraceID> ` (trailing space prevents prefix matches) plus `trace_id_source=ctx`.
2. AC3: no existing test was modified (02). All 21 `internal/query` tests pass, and vet and gofmt are clean (05). CI Go job is green on the head (00, 01). The response shape is unchanged.
3. `make eval` not run: acceptable. The change only touches logging; retrieval order and answers are the same (DoD 3 "not run: <reason>").

**Docs.** No user-facing behaviour, commands or API changed, so README/CONTRIBUTING need no update. No PRD status row tracks this item (OPS-5 is already ✅ for propagation), so no PRD PR is needed.

**Evidence quality notes (non-blocking).** In 05, the renderer colours the PASS lines red for tests whose names contain "Fail" (e.g. `TestAskBatchFailClosed`). The text is `--- PASS` and the `.txt` confirms it. Tabs render as boxes in 01–05. The verbatim-saved QA comment above has stray backtick runs around its evidence links. These are cosmetic; logged as a tooling follow-up.

**Follow-ups (backlog, not blocking):** QA finding 1 and missing tests. Add an `Ask`-level test that the `citation support unverified` log line also carries `trace_id=<resp.TraceID>` with `trace_id_source=ctx`, plus a timeout fallback through `Ask`.

Next: PR #18 raised (ready for review) with the evidence in its description → Mahesh.
