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

---

# PM final review: AI-7 · PR #21 · round 1

**Verdict:** APPROVE
**Reviewer:** pm-lead · **Date:** 2026-11-07 · **Reviewed commit:** `9265b5fcc5005049cab60a1ed1984ac147d2670b` · **QA pack:** arxivlens-agents `62b13e2`
**Inputs:** `agents/tasks/AI-7.md`, `docs/design/AI-7.md` (PM decision + build deviations), ADR-0003 (Accepted), Product PRD QA-4, QA-5, §7.1–7.2,
Technical PRD §7.2, the PR diff (`gh api .../pulls/21/files`), the QA report above and all 9 evidence images + `.txt` files.
No review or comment from Mahesh on #21 yet (checked `pulls/21/reviews`: none; the one issue comment is the QA report).

## Evidence check (each file against the AC it claims)
| File | Claims | Proves it? |
|---|---|---|
| 00-ci-checks | CI for head `9265b5f` | Yes. All 5 check runs `completed / success` on the exact head SHA. |
| 01-ci-go-job | Go vet + test + build on 1.25 | Yes. `GOVERSION='go1.25.0'`, `make lint-go`, `make test-go` → `ok arxivlens/internal/query`, `make build-go`. Proves the PR's tests (incl. the changed `TestAskBatchFailClosed`) pass on the real toolchain. |
| 02-scope-ac8 | Scope + AC8 | Yes. 3 files, 318+/26−; `server.go` + `thresholds.json` diff = 0 lines; 0 files under out-of-scope paths; README diff is the one `/v1/ask` row (full row in the `.txt`). |
| 03-unit-tests | AC1–AC6 test names pass | Yes, as a by-name list. The assertions themselves I checked in the diff (see below). Red "PASS" lines are the known `render_evidence.py` colouring nit (names containing "Fail"), not failures. |
| 04-coverage-rag | AC7 ≥ 90% | Yes, with the caveat QA states: scratch module with verbatim sources, because CI doesn't print `rag.go` rows. 144/147 = 98.0%, lowest function 90.0%. The ticket's AC7 command is used verbatim. Accepted (AI-1 lesson: scratch runs are acceptable when CI doesn't print the file). |
| 05-mutations | Test strength | Yes. 16/16 killed, including the ones that matter for the product: never refuse (M2), always refuse (M3), refuse unless all supported (M4), reason precedence (M1), log leaks answer text (M12). |
| 06-main-tests-vs-pr | AC3/AC5 + design cond. 1 | Yes. `origin/main`'s unmodified tests against the new `rag.go`: only `TestAskBatchFailClosed` fails (the approved ADR-0003 change); `TestAskRefusesWhenNothingPasses` and every answer test pass unmodified. |
| 07-existing-test-diff | Design cond. 1 | Yes. 4 hunks; the only removed lines are the two approved assertions; no test function removed; all 5 cases and `wantLog`s unchanged; added reason/B-sentence/markers assertion present. |
| 08-ac9-stack-not-run | AC9 not run | Yes, proves the reason: `stack.yml`'s `pull_request` paths don't include `internal/**` (only DB + CI ran on this head), `query.log` is copied to `stack-logs/` only under `if: "failure()"`, and #20/#22 are unmerged. |

Diff read (rag.go patch): one optional field; `finalize` returns the answer unchanged as soon as any citation is `Supported`; else reason B iff
`check.unverified > 0`, else A; evidence = every relevant hit (markers 1..K, best checked score or 0, `supported=false`); the log line carries
only the trace id, source, reason and 4 integers. `validateCitations`' signature and the existing unverified log line are unchanged. Matches the
design and both recorded build deviations. Nothing extra: no `scripts/`, `evals/`, `server.go`, frontend or threshold change.

## Product fit
- **Principle 2 ("say I don't know").** Delivered on today's path: when nothing is supported, no synthesized sentence reaches the user, and the
  reason is machine-readable, so FE-3 can show reason-specific copy. This is the safety net QA-8 needs before LLM text goes live.
- **Principle 1 (evidence first).** The refusal still returns every relevant passage with title, section, content and PDF link, so the
  researcher persona can read the evidence themselves rather than getting an empty screen. ADR-0003 asks for exactly this.
- **Fail-closed (Technical §7.2).** Unverified never counts as supported, and a partial outage with nothing supported refuses as B rather than A,
  which is the honest message ("checking is unavailable") instead of blaming the passages.
- **QA-5 early refusal** is untouched (06, 07, `TestAskEarlyRefusalHasNoRefusalReason`).
- **Known product risk, stated, not hidden:** the template answer's cosine against chunks may be < 0.50 often, so many of today's real asks may
  now refuse (A). That is what ADR-0003 decided; it is unmeasured (AC9) and goes in the PR as a decision note for Mahesh, with where it will be
  measured (EVAL-4 AC5, below).

## Scope
Right size and right content: 344 changed lines, 3 files, one owner. Every Scope bullet of the ticket is delivered; the M3 test file wasn't
touched, correctly (the only M3 ask tests are in the F1 `continue-on-error` set, so no required stack step changes; I checked
`tests/test_m3_query.py` on `origin/main`: only `test_rag_ask_with_groundedness_support` asserts on `/v1/ask` citations, and it is F1-deselected).
README: the `/v1/ask` row only, as ADR-0003 requires. PRD status rows: QA-4's row is already stale from AI-2 and is in the pending pm-lead
docs PR (Backlog); I add the ADR-0003 refusal to that same PR after #21 merges (DoD 4 for PRDs is pm-lead's, via PR, not this code PR).

## QA [spec] findings: decisions
3. **AC9: accept "not run".** The ticket allows it, and QA's evidence (08) proves the reason. Two of my spec assumptions were wrong (path
   filter; `query.log` upload is failure-only), so a dispatch of `stack.yml` on the branch wouldn't produce the counts either. Per the RET-1
   lesson the measurement doesn't float: it is attached as **EVAL-4 AC5** (ai-engineer): the first `eval.yml` run that EVAL-4 records must be on
   an `origin/main` that contains #20 and #21 if both are merged by then, and EVAL-4 reports EVAL-6's `refusal_reason_counts` and
   `answer_refusal_rate` for the answer set as AI-7's AC9 numbers, with a stop-and-report rule (report to pm-lead, no tuning, no threshold change).
   That is a better measure than grepping `query.log`, because EVAL-6 classifies every response.
   **No new backend ticket.** Widening `stack.yml`'s path filter to `internal/**` is rejected: it adds a 45-minute full-stack run, HF downloads
   and arXiv requests to every Go PR to get a number `eval.yml` gives us anyway (EVAL-6 lesson: check a trigger's cost first). Always
   uploading `query.log` is a cheap diagnostics improvement: Backlog nit (backend, P3), folded into the next `stack.yml` change (the AI-9
   follow-up that drops the F1 step).
4. **Design header fixed.** `docs/design/AI-7.md` now reads `Status: Approved with conditions (pm-lead, 2026-11-07)`.
5. **Merge gate: raise now, merge after #20.** #20 is already raised for review (ready, PM APPROVE, Jira Ready to merge). The ordering is a
   merge-time constraint, and only Mahesh merges, so I raise #21 now with "Merge after #20" as the first line of the description and in
   "Decisions for Mahesh", and the board row says the same. Reasons: Mahesh can review the pair in one sitting and merge in order; holding #21
   at PM review buys no safety (the PR can't merge itself) and only delays AI-6, which waits on AI-7 *merged*. The cost of a wrong order is small
   and reversible: no eval runs on `main` until EVAL-3 (#22) merges, so nothing would be misclassified in the meantime. This replaces design
   condition 4's "pm-lead won't raise it before EVAL-6 is merged" (amended in the design's PM decision); the merge order itself is unchanged.

## QA nits
1. AC9 row in the PR: replaced with QA's not-run reason and exact command, plus where the number will come from (EVAL-4 AC5).
2. `score` semantics in a refusal (support score, 0 when uncited or unverified, not the retrieval score): ADR-0003 says "with their scores"
   without saying which. The ticket chose the support score, so this is my spec, not the code. Added as Decision 4 for Mahesh in the PR, and as a
   note on FE-3 (show 0 as "not checked", never as "0% relevant"). If Mahesh wants the retrieval score instead, that is a small follow-up on
   `rag.go` after merge (or part of AI-8's per-citation status, ADR-0014).

QA's "Missing tests" list is nice-to-have and stays out of this PR (the same-hit checked + unverified case is folded into the existing Backlog
item for AI-2's split log counters).

## Hand-off
APPROVE → orchestrator: replace the PR #21 description with `/tmp/claude-0/s/pr21-body.md`, mark #21 ready for review, Jira AI-7 story
(`labels = "task-AI-7"`, KAN-36) → Ready to merge with a link to this verdict. **Merge after EVAL-6 #20.**
