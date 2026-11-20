<!-- Provenance: qa-reviewer's harness refused to write report.md; saved verbatim by the orchestrator from the PR comment https://github.com/MaheshPulivarthi18/ArxivLens/issues/comments/7030405781 on 2026-11-20T04:28Z. -->

[qa-reviewer] **QA report — RET-1b · PR #75 · round 1 — Verdict: PASS**

**Reviewed commit:** `846984439890259093dcfcbe783bf4f5a535a523` · 2026-11-20 · Ticket `agents/tasks/RET-1b.md` · PRD: Product QA-1/QA-2, Technical §7.1, ADR-0010
Evidence (commit-pinned): https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/

[00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/00-ci-checks.png?raw=true) ``

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | ci.yml run 44672623091, job 136076889192 (go1.25.0, merge `064f1b1` = `8469844` into main `4c7d327`) | pass: `make lint-go` OK, `ok arxivlens/internal/query 0.327s` ([06](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/06-ci-go-job.png?raw=true)) ``` |
| Python M0 / Frontend / DB | jobs 136076888897 / 136076889219 / 136076890387 | pass |
| Ownership | CI job 136076889112 + local | `Ownership OK for role=backend (21 changed lines)` ([01](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/01-scope-ownership.png?raw=true)) ```` |
| Full stack | stack.yml run 44672623037, job 136076888827 | **success**: AC4 `237 passed, 1 skipped, 3 deselected`; continue-on-error F1 step 1 failed/2 passed (Finding 3) ([07](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/07-ci-stack-f1-compare.png?raw=true)) ````` |
| Ticket verification | local scratch module, go1.24.7 | gofmt/vet clean; `-race -v` 8/8 sub-tests PASS. I couldn't build the real module locally (go.mod needs 1.25 and there's no module proxy). The scratch module uses the PR's **real** `search.go`/`search_test.go`/`client.go` (sha256 = head), stub `internal/db` and a `replace`d stub pgx, plus `generateTraceID` copied from rag.go ([08](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/08-harness-source.png?raw=true), `````` [09](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/09-harness-scripts.png?raw=true)) ``````` |
| `make eval` | not run | ±Inf can't occur on the eval stack (finite scores), so ranking on real data doesn't change |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 canceled | ✅ | Row with `fmt.Errorf("wrapped: %w", context.Canceled)` → `reason="rerank canceled"`, RRF `[1 2 3 4 5]`, scores 0, log checks: PASS ([03](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/03-ac1-ac2-fallback-v.png?raw=true)) ```````` |
| AC2 ±Inf | ✅ | `infAt3(±1)` rows → `reason="Inf score"`: PASS ([03](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/03-ac1-ac2-fallback-v.png?raw=true)). ````````` Base control: the PR tests against main's `search.go` fail exactly the two Inf rows ([05](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/05-base-control-json-probe.png?raw=true)) `````````` |
| AC3 json.Marshal in every row | ✅ (Finding 1) | Added once in the shared body ([02](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/02-ac3-ac4-test-diff.png?raw=true)). ``````````` Probe: a ±Inf `RerankScore` gives `json: unsupported value: +Inf` ([05](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/05-base-control-json-probe.png?raw=true)) ```````````` |
| AC4 existing tests unmodified | ✅ | search_test.go: 0 removed lines, 14 added ([02](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/02-ac3-ac4-test-diff.png?raw=true)) ````````````` |
| AC5 mutants | ✅ | QA-run, local only, one fresh copy per mutant, `-run HybridSearchRerank` + full scratch pkg. (a) → +Inf/-Inf FAIL; (b) → -Inf FAIL; (c) → canceled FAIL (`reason="rerank error"`); (d) → both Inf FAIL. Extra (e) `IsInf(x,-1)`, (f) canceled→"rerank error", (g) NaN check removed: all killed. 7/7 killed, 0 invalid ([04](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/04-ac5-mutants.png?raw=true)) `````````````` |
| AC6 CI | ✅ | Go job green + `ok internal/query`, lint-go passed, ownership OK, stack.yml success ([00](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/00-ci-checks.png?raw=true), ``````````````` [06](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/06-ci-go-job.png?raw=true), ```````````````` [07](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/07-ci-stack-f1-compare.png?raw=true)). ````````````````` The `-v` listing comes from the scratch module ([03](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/03-ac1-ac2-fallback-v.png?raw=true)) `````````````````` |
| Docs | ✅ | Doc comment now says "a NaN or ±Inf score"; README unchanged |

**Scope:** only `internal/query/search.go` (6+/1-) and `search_test.go` (14+/0-), both backend-owned and both in the ticket. No rag.go/server.go changes and no planning files.

## ±Inf behaviour vs ADR-0010 and the HTTP API
I agree with falling back. ADR-0010 falls back when the rerank output is unusable. RET-1 already counts a NaN as unusable, and ±Inf from a cross-encoder is equally invalid. Accepting +Inf would let an invalid output take the top position. Before this PR, ±Inf reached `RerankScore`, `encoding/json` rejected it, and `server.go` dropped the `Encode` error after the 200, so `/v1/search` sent a truncated body. That breaks the README contract `{query, count, hits:[…]}`. On fallback, `RerankScore` is 0 and `omitempty` omits it. The documented `rerank_score?` is optional, so the shape stays in contract, the same as the NaN path. No contract changed, so no ADR is needed. `/v1/ask` (`rag.go:759`) treats a 0 score the same as it already does for other fallbacks.

## PRD fit
This serves QA-2 and Technical §7.1's "no error to caller" fallback. A malformed reranker output now degrades to RRF order with a trace-ID log line instead of a corrupt response. The latency cost is negligible: one `math.IsInf` per pool score.

## Findings
1. [nit] The AC3 `json.Marshal` assertion can't fail on its own. Every row is a fallback row, and the preceding `RerankScore != 0` `Fatalf` already stops any non-finite score. The ticket asked for it, so it is not a dev defect. A meaningful encode guard belongs on the success path or in a `/v1/search` handler test (optional follow-up).
2. [spec] ADR-0010 line 27 and PRD-Technical §7.1 line 243 still don't mention NaN/±Inf. The ticket gives the PRD note to pm-lead. The ADR wording needs Mahesh.
3. [info] stack.yml succeeded. The continue-on-error "Known failure F1" step had `test_rag_early_refusal_on_unrelated_query` hit a ReadTimeout (tracked CPU-rerank latency). OPS-H9 run 44617013932 on the same base `4c7d327` fails identically (1 failed, 2 passed, same test). Other same-base runs pass or fail all 3, so this is a flake ([07](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12a2e573b45aff73423494a219e764f61437b5f0/agents/reviews/RET-1b/evidence/07-ci-stack-f1-compare.png?raw=true)). ```````````````````
4. [info] Out of scope: `server.go` still ignores `Encode` errors, which is the root cause of "200 + truncated body". It needs its own backend ticket.

## Missing tests (optional)
- A row with both a NaN and an Inf (pins which reason wins); a large finite score (`math.MaxFloat32`) that must be accepted.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_
