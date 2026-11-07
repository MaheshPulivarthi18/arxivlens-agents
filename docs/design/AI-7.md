# Tech design — AI-7: Refuse with evidence when no citation is supported or verification is unavailable

**Author:** ai-engineer · **Ticket:** `agents/tasks/AI-7.md` · **PRD:** Product QA-4, QA-5, §7.1–7.2; Technical §7.2; ADR-0003 (Accepted) · **Status:** Draft

## Problem
If no citation in an answer is supported, `/v1/ask` still returns the answer today. That covers case A (every checked citation scored < 0.50, or no in-range marker at all) and case B (support couldn't be checked). ADR-0003 says to refuse in both cases: return a fixed sentence and a `refusal_reason`, plus every relevant hit as evidence. Answers with at least one supported citation, and the early QA-5 refusal, stay as they are. Covers AC1–AC9.

## Approach (all in `internal/query/rag.go`)
1. **Per-citation state.** `validateCitations` returns `([]Citation, citationCheck)`. `citationCheck` is internal and never serialized. It holds `checked` and `unverified` counts, plus `hitScore []float64` (len K, `-1` = not computed). A citation counts as **checked** when both its sentence and chunk vectors are present (the existing `len(sentVec)>0 && len(chunkVec)>0` branch). It counts as **unverified** otherwise: an embed error, a missing vector, or a vector count mismatch, all of which `embedBatch` already reduces to empty slots. `hitScore[i]` is the highest computed score of any checked citation for hit i. If there is no in-range marker, it returns `nil` and a zero `citationCheck` (no embed calls, as today). The existing `citation support unverified` log line is unchanged.
2. **Field.** `AskResponse.RefusalReason string \`json:"refusal_reason,omitempty"\``. It is empty, and so missing from the JSON, on every non-refusal path.
3. **Decision in `Ask`**, after validation. If any citation is `Supported`, return exactly what is returned today. Otherwise:
   - `reason = "verification_unavailable"` if `check.unverified > 0`. Otherwise `"all_citations_unsupported"`, which also covers zero in-range markers.
   - `answer` = the fixed A or B sentence from the ticket (package consts `refusalUnsupported`, `refusalUnavailable`).
   - `citations` = `evidenceCitations(hits, check.hitScore)`: one entry per relevant hit in rank order. Each entry has `Marker = i+1` (1..K), the same metadata fields as today, `Score = hitScore[i]` when computed (else 0) and `Supported = false`. Uncited hits get score 0.
   - One log line, counts only: `[Query Service] ask refused trace_id=%s trace_id_source=%s reason=%s citations=%d checked=%d unverified=%d evidence=%d`. No question, answer, sentence or passage text.
4. `server.go` is untouched; the handler already marshals `AskResponse`. In the README, only the `/v1/ask` row changes, to add `refusal_reason?` (`all_citations_unsupported` | `verification_unavailable`).

## Alternatives considered
1. **Per-citation `status` JSON field.** This is ADR-0014 / AI-8, so it is out of scope.
2. **Return only the cited hits as evidence.** In case AC4 (no in-range marker) that would leave nothing to read, and ADR-0003 asks for "the retrieved passages". So all relevant hits are returned.
3. **Fold the refusal into the existing "unverified" log line.** That line only fires for unverified citations, so case A would get no log. A separate line is used.

## Contracts and invariants
- HTTP API: adds one optional field, allowed by ADR-0003 (Accepted). Routes, `server.go` and `evals/thresholds.json` are unchanged. No change to events, schema, embedding model or thresholds.
- Grounding: the refusal is fail-closed. Unverified citations never count as supported. Markers outside 1..K are still discarded.
- **Existing test whose behaviour ADR-0003 changes:** `TestAskBatchFailClosed` asserts 2 citations and 1 log line. That is now a case-B refusal (3 evidence hits, 2 log lines). Its per-citation assertions (`score 0`, `supported=false`, 2 embed calls, unverified-line content) are kept. Only the citation count changes from 2 to K=3, and the line-count check now expects the unverified line followed by the refusal line. No assertion is dropped. This goes in the PR for pm-lead and Mahesh.
- `tests/test_m3_query.py::test_rag_ask_with_groundedness_support` asserts a supported answer. It is unchanged. If the template answer now refuses on `stack.yml`, that is the AC9 finding, not something to edit.

## Test plan
| AC | Test (Go unit, fakes only, no network) | CI? |
|---|---|---|
| AC1 | `TestAskRefusesAllUnsupported`: `constSim(0.3)` → reason, A sentence, K evidence hits with markers 1..K, cited hits score 0.3 and uncited hits 0, all `supported=false`, 32-hex trace_id | yes |
| AC2 | `TestAskRefusesVerificationUnavailable` table: chunk-batch error, sentence-batch error, count mismatch, and mixed (one checked < 0.50, one missing vector) → `verification_unavailable`, B sentence, unverified scores 0. Plus the updated `TestAskBatchFailClosed` | yes |
| AC3 | Existing `TestAskAnswersWithValidatedCitations`, `TestAskRerankFallbackLogsResponseTraceID` and batch tests left unmodified. New case: one supported + one unsupported → today's answer, per-citation flags, marshalled JSON has no `refusal_reason` key | yes |
| AC4 | `TestAskRefusesNoInRangeMarker`: call the decision helper with an answer containing only `[9]` and K=3 → `all_citations_unsupported`, 0 embed calls, K evidence hits | yes |
| AC5 | `TestAskRefusesWhenNothingPasses` unmodified, plus a JSON assertion that `refusal_reason` is absent | yes |
| AC6 | Captured `log` output in AC1/AC2 tests: contains `trace_id=<resp.TraceID>`, `reason=`, counts. Does not contain the question, answer or any hit `Content`/`Title` | yes |
| AC7 | `go test -coverprofile` per-file rows for `rag.go` ≥ 90% (CI; scratch-module run locally) | yes |
| AC8 | `TestAskResponseShapeAndConstructor` extended: `refusal_reason` appears only when set. README row diff; `git diff origin/main -- internal/query/server.go evals/thresholds.json` empty | yes |
| AC9 | M3 on `stack.yml` (PR CI), with refusal counts per reason pasted; or "not run: <reason>" with the command | stack CI |

To make AC4 reachable, the template synthesis step and the "decide/refuse" step are split into `buildTemplateAnswer(hits)` and `finalize(ctx, traceID, answer, hits)`. `Ask` calls both, and the test calls `finalize` directly.

## Risks and rollout
- The template answer's cosine against chunks may often be < 0.50, so many real asks could now refuse (AC9 measures this). That is expected under ADR-0003 and is reported to pm-lead, not tuned. Merge after EVAL-6 so the eval classifies the refusals. Roll back by reverting the PR. No data or schema change.

## PM decision
**APPROVED with conditions** (pm-lead, 2026-11-07, reviewed at design commit `d33b8ef` against `agents/tasks/AI-7.md`,
ADR-0003 (Accepted) and Product PRD §7 principles 1–2; app `origin/main` `71cb609`, `rag_test.go:561-612`).

Why: it does exactly what ADR-0003 decides and nothing more: one optional field, the two reasons, all relevant hits returned as
evidence with their scores, answers with ≥ 1 supported citation unchanged, the early QA-5 refusal unchanged. Unverified never counts
as supported. The per-citation state stays internal (ADR-0014 is still Proposed). Splitting into `buildTemplateAnswer` +
`finalize` is a fair way to reach AC4, and it's the seam QA-8 will need anyway. The test plan covers AC1–AC9.

### Decision on the developer's question (`TestAskBatchFailClosed`)
**Approved.** Every case in that table is now case B (`verification_unavailable`) under ADR-0003, so the old "2 citations, 1 log
line" can't hold without breaking the Accepted ADR. This is the ADR-mandated change of an expected value, not a weaker test. Allowed
edits, and nothing else:
- `len(resp.Citations) != 2` → `!= 3` (K = 3 evidence hits, markers 1..3).
- The log check → exactly 2 lines: line 1 still contains `tc.wantLog` unchanged (the `citation support unverified` line), and line 2
  is the refusal line containing `reason=verification_unavailable` and `trace_id=<resp.TraceID>`.
- Kept as is: score 0 and `supported=false` for every citation, 2 `EmbedTexts` calls, all five cases and their `wantLog` strings.
- **Add** (it's a refusal test now, so assert it): `resp.RefusalReason == "verification_unavailable"`, `resp.Answer` == the B sentence,
  and markers are exactly 1, 2, 3 in order.

### Conditions (binding; QA checks each)
1. **Call it out in the PR.** Add a "Changed existing test (ADR-0003)" section with the before/after of each changed assertion in
   `TestAskBatchFailClosed` and the reason. QA diffs the test against `origin/main` and confirms only the changes above happened (no case
   removed, no `wantLog` changed). No other existing test in `rag_test.go` may change, except the extension of
   `TestAskResponseShapeAndConstructor` that the ticket asks for.
2. **List pm-lead's two readings of ADR-0003 in the PR for Mahesh to confirm** (ticket Scope): mixed checked-unsupported + unverified with
   none supported → `verification_unavailable`, and no in-range marker → `all_citations_unsupported`. Also list the two refusal sentences
   as Proposed wording.
3. **AC9: say where the numbers come from.** In `stack.yml` the M3 ask tests are the F1 set (deselected from AC4 and run in a
   `continue-on-error` step), and M3 prints no per-reason counts. Count the new refusal log line instead, in the `query.log` that
   `stack.yml` uploads with `if: always()` (`stack.yml:240-249`), e.g. `grep -c 'ask refused .*reason=all_citations_unsupported'` and
   the same for `verification_unavailable`, next to the number of asks in that run. If EVAL-3 has merged, the latest `eval.yml` run on
   `main` is the before number. Otherwise write "not run: <reason>" with the exact command. Don't infer counts from unit tests.
4. Merge order is unchanged: **EVAL-6 merges first**. The PR says so, and pm-lead won't raise it before EVAL-6 is merged.
