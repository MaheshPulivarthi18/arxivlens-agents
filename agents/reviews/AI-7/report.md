<!-- Provenance: written by qa-reviewer (fresh context, 2026-11-07 cycle 05:21Z); its harness could not write files, so the orchestrator saved the report text verbatim from qa-reviewer's hand-back. Evidence files were rendered by qa-reviewer with agents/tools/render_evidence.py. -->

# QA report — AI-7 · PR #21 · round 1

**Verdict:** PASS
**Reviewed commit:** `9265b5fcc5005049cab60a1ed1984ac147d2670b` (base `origin/main` `71cb609`) · **Date:** 2026-11-07
**Ticket:** `agents/tasks/AI-7.md` · **PRD:** Product QA-4, QA-5, §7 principles 1–2; Technical §7.2; ADR-0003 (Accepted) · **Design:** `docs/design/AI-7.md` (APPROVED with conditions)

Evidence folder: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/main/agents/reviews/AI-7/evidence
(each `.png` has a `.txt` with the full output next to it. Images 02–08 were run in the worktree at `9265b5f`.)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 128319260225, go1.25.0 | **pass**. `make lint-go` (vet + gofmt), `make test-go` → `ok arxivlens/internal/query`, `make build-go` ([00](evidence/00-ci-checks.png), [01](evidence/01-ci-go-job.png)) |
| Python M0 unit tests | CI | pass |
| Frontend (lint, test, build) | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Agent guardrails (ownership check) | CI | pass |
| Full stack (`stack.yml`, M3) | CI | **not triggered**. The PR touches no path in its `pull_request` filter ([08](evidence/08-ac9-stack-not-run.png)) |
| Ticket verification: `make lint`, `make test-unit` | not run locally: the sandbox has Go 1.24 and `go.mod` needs 1.25 (proxy blocked). CI ran the Go part (above). | — |
| `rag.go` tests, vet, gofmt, coverage, mutations | local, in a Go 1.24 scratch module. `rag.go`, `rag_test.go`, `client.go`, `search.go` and `search_test.go` are copied verbatim from `9265b5f`. Only `internal/db` and `pgx` are compile-only stubs. | vet clean, gofmt clean, all PASS ([03](evidence/03-unit-tests.png)), 98.0% ([04](evidence/04-coverage-rag.png)), 16/16 mutations killed ([05](evidence/05-mutations.png)) |
| `git diff origin/main -- internal/query/server.go evals/thresholds.json` | local | empty (0 lines) ([02](evidence/02-scope-ac8.png)) |
| `make eval` | not run: EVAL-3 (#22) is not merged, so there is no stack eval workflow, and the sandbox has no stack. | n/a (see AC9) |

## Scope and design check
- **Files:** `README.md` (1 row), `internal/query/rag.go`, `internal/query/rag_test.go`. All three are ai-engineer paths or README, and ownership CI is green. No changes under `scripts/`, `evals/`, `frontend/`, `tests/`, `shared/` or `migrations/`, and no ticket, review or doc files ([02](evidence/02-scope-ac8.png)). Diff is 318+/26−, under 400.
- **Design followed:** one optional `refusal_reason` field. `Ask` is split into `buildTemplateAnswer` + `finalize`. Reason precedence is `unverified>0` → B, else A, which covers zero in-range markers. Evidence is every relevant hit with markers 1..K, the best computed score or 0, and `supported=false`. There is one counts-only log line. Both deviations (the wrapper that keeps `validateCitations`'s signature, and `hitScored []bool` instead of a `-1` sentinel) are recorded in the design under "Build deviations". Both are justified and don't change behaviour.
- **PM condition 1 (existing-test edits):** I diffed `rag_test.go` against `origin/main` ([07](evidence/07-existing-test-diff.png)). There are exactly 4 hunks: the `TestAskResponseShapeAndConstructor` extension (additions only), two hunks in `TestAskBatchFailClosed`, and the appended new tests. The only removed lines are the `!= 2` citation check and the 1-line log check. Both were replaced exactly as approved (`!= 3`; 2 lines, with line 1 still containing `tc.wantLog` and line 2 containing `reason=verification_unavailable` and `trace_id=<resp.TraceID>`). The required additions are present (reason, B sentence, markers `[1 2 3]`). All 5 cases and every `wantLog` are unchanged, as are the score-0/supported loop and the 2-call check. No existing test function was removed. Running `origin/main`'s unmodified `rag_test.go` against the PR's `rag.go` shows that **only** `TestAskBatchFailClosed` fails ("got 3 citations, want 2"), and every other existing test passes ([06](evidence/06-main-tests-vs-pr.png)). The PR has the "Changed existing test (ADR-0003)" section with a before/after table.
- **PM condition 2:** the PR lists both readings (mixed → `verification_unavailable`; no in-range marker → `all_citations_unsupported`) and both proposed sentences under "Decisions for Mahesh".
- **PM condition 3 (AC9 source):** partly met. See AC9, finding 1 and [spec] finding 3.
- **PM condition 4:** the PR says "Merge order: EVAL-6 (#20) merges first". #20 is still open ([08](evidence/08-ac9-stack-not-run.png)), so pm-lead must not raise the PR yet.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 case A | ✅ | `TestAskRefusesAllUnsupported` (`constSim(0.3)` through the real `Ask`) asserts the reason, the A sentence, 32-hex `trace_id`, evidence = all 3 hits in rank order with full metadata, scores `[0.3, 0.3, 0]`, all `supported=false`, and `refusal_reason` in the JSON. `TestFinalizeEvidenceKeepsBestComputedScore` checks that the max (not the last) score is kept, including negatives. Passes in CI ([01](evidence/01-ci-go-job.png)) and locally ([03](evidence/03-unit-tests.png)). Mutations M2, M5, M6, M7, M8, M15 are killed ([05](evidence/05-mutations.png)). |
| AC2 case B + mixed | ✅ | `TestAskRefusesVerificationUnavailable` covers chunk-batch error, sentence-batch error, count mismatch, and mixed (hit 1 checked at 0.3, hit 2 missing a vector). All give `verification_unavailable`, the B sentence, and score 0 for unverified/uncited hits (mixed: `[0.3,0,0]`). The updated `TestAskBatchFailClosed` adds 5 more B cases. M1 (precedence) and M9 (unverified not recorded) are killed. |
| AC3 ≥1 supported → unchanged | ✅ | `TestAskKeepsAnswerWithOneSupportedCitation`: the template answer, per-citation flags 0.9/true and 0.2/false, JSON keys exactly `answer, citations, trace_id`, and no log output. Existing answer tests pass unmodified against the new `rag.go` ([06](evidence/06-main-tests-vs-pr.png)). The only exception is the PM-approved `TestAskBatchFailClosed`. M3 and M4 (refuse unless all supported) are killed. |
| AC4 no in-range marker | ✅ | `TestAskRefusesNoInRangeMarker` (`"Claim [9]."`, no markers, empty answer, K=3) asserts `all_citations_unsupported`, 0 `EmbedTexts` calls, and 3 evidence hits with score 0, through `finalize`, the seam the design approved. |
| AC5 early refusal unchanged | ✅ | `TestAskRefusesWhenNothingPasses` has no diff hunk ([07](evidence/07-existing-test-diff.png)) and passes. `TestAskEarlyRefusalHasNoRefusalReason` asserts the early refusal sentence and no `refusal_reason` key in the JSON. M11 (omitempty removed) is killed. |
| AC6 log line | ✅ | `checkRefusalLog` captures the logger and asserts exactly one `ask refused` line with `trace_id=<resp.TraceID>`, `trace_id_source=ctx` and exact counts. It also asserts the line has no question, answer, sentence, chunk content, title or refusal-sentence text. M12 (answer appended to log), M13 (trace_id not from ctx) and M14 (line removed) are killed. In code, the line logs only the id, source, reason and 4 integers (`rag.go` `finalize`). |
| AC7 coverage ≥ 90% | ✅ (local) | `rag.go` 144/147 statements = **98.0%**, lowest function `embedBatch` 90.0% ([04](evidence/04-coverage-rag.png)). CI's Go job prints per-file rows only for `consumer.go`, not `rag.go`, so this number comes from the scratch module with verbatim sources. |
| AC8 README + no contract drift | ✅ | The README diff is the single `/v1/ask` row, which names `refusal_reason?` and both values. The `server.go` / `thresholds.json` diff is empty ([02](evidence/02-scope-ac8.png)). `TestAskResponseShapeAndConstructor` is extended to cover the new key. |
| AC9 effect on template answers | ⚠ not run (accepted under the ticket's "not run: <reason>" clause) | `stack.yml` did not run: its `pull_request` path filter doesn't include `internal/**` or `README.md`, and EVAL-3 (#22) is not merged ([08](evidence/08-ac9-stack-not-run.png)). The reason below is mine, because the PR text doesn't give the exact command (finding 1). **Not run**, reason: `stack.yml` is not triggered by `internal/query/rag.go` changes, and `make eval` doesn't exist on `main` until EVAL-3. Command to produce it: `gh workflow run stack.yml --ref agent/ai/AI-7`, then from that run's `query.log`: `grep -c 'ask refused .*reason=all_citations_unsupported' query.log`, `grep -c 'ask refused .*reason=verification_unavailable' query.log`, `grep -c 'ask refused\|POST /v1/ask' query.log`. Note [spec] 3: on a green run `query.log` is **not** in the artifact. |

## PRD fit
This delivers ADR-0003 and Product §7 principle 2 ("say I don't know") on today's template path. When nothing is supported, no synthesized text reaches the user, the reason is machine-readable, and every relevant passage is returned with its score and PDF link (principle 1, evidence first). Answers with any supported citation and the early QA-5 refusal are unchanged. Unverified citations still never count as supported (Technical §7.2 fail-closed). The real-world refusal rate on template answers is unmeasured (AC9). The design expects it to rise, and this must not be tuned away.

## Findings
1. [nit] The PR "Verification" row for AC9 says "from `stack.yml` `query.log` if it runs on this PR; else not run: no stack in sandbox". It didn't run, and the row gives no exact command, which design condition 3 asks for. When pm-lead writes the evidence into the PR description, replace it with the not-run reason and command from the AC9 row above.
2. [nit] The README row says `citations` lists every relevant passage "as evidence" but doesn't say that in a refusal `score` is the support score (0 for an uncited or unverified passage), not a retrieval score. API readers may misread `score: 0`. This can wait for ADR-0014 / AI-8's per-citation status.
3. [spec] AC9 / design condition 3 assume the M3 ask tests run "on the PR's `stack.yml`" and that `query.log` is uploaded with `if: always()`. Neither holds for this PR. (a) `stack.yml`'s `pull_request` paths don't include `internal/**`, so a `rag.go` PR never triggers it. (b) `query.log` is copied into `stack-logs/` only in the `Diagnostics` step (`if: "failure()"`, `stack.yml:232-241`), and the F1 ask tests are `continue-on-error`. So a green run uploads no `query.log`, and the planned `grep -c` has nothing to read. Also, the F1 asks time out client-side at 10 s, though the server still logs them. pm-lead should decide whether to dispatch `stack.yml` on `agent/ai/AI-7` and fetch `query.log` another way, add a backend follow-up (add `query.log` to the always-uploaded artifact and `internal/query/**` to the path filter), or wait for EVAL-3. This should be settled before LLM answers (QA-8) depend on the refusal rate.
4. [spec] `docs/design/AI-7.md` still shows `**Status:** Draft` in its header, though the PM decision section says APPROVED. This is a bookkeeping fix for pm-lead.
5. [spec] Merge gate: EVAL-6 (#20) is still open. Per the ticket, pm-lead must not raise PR #21 for merge until #20 is merged.

## Missing tests
None of these block the PASS. All are nice-to-have:
- One hit cited by two sentences, one checked (< 0.50) and one unverified (e.g. one sentence's vector missing). The evidence score for that hit should be the checked score, and the reason should be B. Today's mixed case uses two different hits.
- An HTTP-level test (`server.go` handler with a fake `RAGService`) showing that `refusal_reason` reaches the wire. Today only `json.Marshal(AskResponse)` is asserted, which is enough since the handler marshals the struct unchanged.
- A refusal where `finalize` is called with a context that has no trace ID. Today the log falls back to a generated id that differs from `resp.TraceID`. This can't be reached from `Ask`, which always sets the ctx trace ID, so it's informational only.

## Hand-off
PASS → pm-lead final review. Before raising the PR: EVAL-6 (#20) must be merged (finding 5), AC9 needs the not-run reason and command in the PR description (finding 1), and [spec] 3 needs a decision.
