[qa-reviewer] **QA report: AI-2 · PR #11 · round 1. Verdict: PASS**

**Reviewed commit:** `c9ae07c3894749fcd7bb6ead5b83efd70ce791a6` (base `bb9ee90`) · 2026-11-03 · **Ticket:** [AI-2](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/tasks/AI-2.md) · **PRD:** QA-4, §7, §8 supported ≥ 90% · no design doc (not design-required)
**Evidence pack:** [agents/reviews/AI-2/](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2) (scripts in [scripts/](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/scripts)). The harness blocked me from writing `report.md`, so this comment is the report and the orchestrator will save it verbatim.

I checked the work myself and did not use the developer's self-report. Every result below comes from a command I ran or a CI log I fetched.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 125824913066 | **pass**: `go vet ./...`, `ok arxivlens/internal/query`, build ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/00-ci-checks.png?raw=true),`` [01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/01-ci-go-job-log.png?raw=true))``` |
| Python M0 / Frontend / Agent ownership check | CI | pass / pass / pass |
| Ticket verification (`go vet`, `gofmt -l internal/query`, `go test -cover`) | local, labelled scratch signal | pass. I copied the PR head's real `rag.go` and `rag_test.go` (byte-identical, checked with `cmp`) into a stdlib-only scratch module and ran it under Go 1.24.7 inside `unshare -rn`, which leaves only `lo` and no network. Results: 9 top-level and 51 subtests pass, 0 fail, `validateCitations` coverage 97.4%. `gofmt` is clean ([03](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/03-ac2-offline-tests.png?raw=true))```` |
| `make test-unit` / `make lint` | CI | not run locally, because go.mod needs Go 1.25 and the sandbox can't download it. CI runs `make lint-go` and `make test-go`, and both are green |
| `make eval` | not run: infra unavailable | I tried it. There is no Docker daemon, nothing listens on :8080, and the run exits 2 with `ModuleNotFoundError: psycopg` ([07](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/07-ac4-eval-not-runnable.png?raw=true))````` |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: no `supported = true` without a computed cosine ≥ threshold | ✅ | [02](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/02-ac1-grep.png?raw=true):`````` the ticket's grep finds nothing (exit 1). The only assignments are `supported := false` (rag.go:182) and `supported = score >= SupportThreshold` (rag.go:189), which runs only when both vectors are non-empty and there was no embed error. There is no `0.75` literal left, and `SupportThreshold = 0.50` is unchanged |
| AC2: three new cases pass with no network, DB or embedder | ✅ | `TestValidateCitationsFailClosedWhenUnverifiable` has 7 subtests: sentence-embed error, chunk-embed error, nil or empty vector on each side, and embedder down. All pass offline ([03](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/03-ac2-offline-tests.png?raw=true))``````` and in CI ([01](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/01-ci-go-job-log.png?raw=true)).```````` The same test **fails all 7** against main's fail-open `rag.go` ([04](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/04-ac2-new-test-fails-on-main.png?raw=true))````````` |
| AC3: `/v1/ask` JSON shape unchanged | ✅ | [05](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/05-ac3-json-shape-and-scope.png?raw=true):`````````` the exported declarations, JSON tags, field types and constants of `rag.go` are identical between main and the head. `server.go`, `search.go`, `client.go`, `README.md`, `shared/events` and `frontend/` are unchanged. `TestAskResponseShapeAndConstructor` passes. An unverified citation marshals with all 9 keys, `score` as a number (0) and `supported` as a bool (false) |
| AC4: `make eval` numbers, or "not run" plus the command | ✅ (not run) | The PR body says "not run: infra unavailable … Command: `make eval`", and my own attempt confirms the infra is missing ([07](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/07-ac4-eval-not-runnable.png?raw=true)).``````````` `evaluate_answers.py` counts only `supported is True`, so the rate can drop only on runs where the embedder fails. The verified path is unchanged, and mutations N15/N16 are killed |

**Scope:** only `internal/query/rag.go` and `rag_test.go` changed (both owned by ai-engineer, +94/−20). No ticket, review or doc files are in the PR, no third "unverified" state was added, and the frontend is untouched. The PR is still a draft.

## PRD fit
This delivers QA-4: a citation is labelled supported only when its similarity has actually been computed and is at or above the threshold. Otherwise it is shown as unsupported, which matches the honest-refusal principle in §7. It also removes the inflation of the §8 gated `supported_citation_rate`. The marker and its one-click source link stay in the response.

## Findings
1. [nit] The log counters are not asserted. Mutations N13 (`sentence_embed_errors` never counted) and N14 (`chunks_without_vector` never counted) survive. The other 14 of 16 are killed, including restoring fail-open, dropping either guard, logging per citation or on verified requests, leaking text, and dropping the trace id ([06](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/06-mutation-tests.png?raw=true)).````````````
2. [nit] No test mixes a verified and an unverified citation in one answer, for example two hits where only hit 2's chunk embed fails. It would show marker 1 stays supported, marker 2 does not, and the log reports `unverified=1 citations=2`.
3. [nit] A dimension mismatch between the sentence and chunk vectors makes `cosineSimilarity` return 0. The citation still fails closed, but it is not counted or logged as unverified, so it can't be told apart from a real similarity of 0. This could be a follow-up.
4. [nit] The log's `trace_id` is a generated id because `Ask` doesn't put its trace id into ctx. This is already tracked by AI-4 (KAN-27) and is not a regression.
5. [spec] (pm-lead) After merge, move the QA-4 PRD row from ◐ to done and remove the AI-2 caveat in the §8 row (via a docs PR). ADR-0003 still has to decide how to treat an answer whose citations are *all* unsupported, for example during an embedder outage. Today the template answer is still returned with no refusal.

## Missing tests
- A mixed verified and unverified request (finding 2), and asserts on `sentence_embed_errors` and `chunks_without_vector` (finding 1). Optional: a dimension-mismatch case.

## Hand-off
**PASS → pm-lead final review.** All four ACs have evidence, the 4 CI checks on `c9ae07c` are green, and there are no blocking findings.


---
_Generated by [Claude Code](https://claude.ai/code)_


_Provenance: saved verbatim by the orchestrator from PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/11#issuecomment-6599796071 (qa-reviewer harness could not write report.md); evidence commit 209432e._
