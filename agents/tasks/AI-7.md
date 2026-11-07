# AI-7: Refuse with evidence when no citation is supported or verification is unavailable (ADR-0003)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (Product PRD §7 principle 2; must be in place before LLM answers go live in QA-8) |
| **PRD ref** | Product PRD QA-4, QA-5, §7 principles 1–2; Technical PRD §7.2; ADR-0003 (Accepted) |
| **Depends on** | ADR-0003 (Accepted, `51d8ff5`). **Merge gate:** EVAL-6 must be merged first, so the eval classifies the new refusals correctly (see Notes). |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-AI-7"`) |
| **Design required** | **yes** (short, ≤ 1 page, `docs/design/AI-7.md`): P0. ADR-0003 settles the policy, but the design fixes how evidence passages are returned, the reason precedence, and the test plan. |
| **Status** | Ready (Wave 1) |

## Goal
ADR-0003: when every citation in an answer is unsupported (case A) or support can't be checked (case B), `/v1/ask`
returns no synthesized answer. It says why in `refusal_reason` and still returns the retrieved passages with their scores
so the user can read the evidence. This works on today's template path and becomes the safety net for QA-8's LLM answers.

## Scope
- `internal/query/rag.go`:
  - `validateCitations` keeps, per citation, whether it was **checked** (both vectors present) or **unverified**
    (embed error, missing vector, wrong count). This is internal only: no new per-citation JSON field (that's ADR-0014 / AI-8).
  - `AskResponse` gains `RefusalReason string \`json:"refusal_reason,omitempty"\`` (the one field ADR-0003 accepts).
  - In `Ask`, after validation, if **no** citation is supported:
    - `refusal_reason = "verification_unavailable"` if any citation was unverified, else `"all_citations_unsupported"`.
      An answer with **no in-range marker at all** counts as `all_citations_unsupported`. Both of these are pm-lead's
      reading of ADR-0003 and are listed in the PR for Mahesh to confirm.
    - `answer` = the fixed refusal sentence for that reason. Proposed wording (Mahesh may edit it in PR review):
      A: "I couldn't verify any statement of a draft answer against the retrieved passages, so no answer is shown. The passages found are listed below."
      B: "Citation checking is unavailable right now, so no answer is shown. The passages found are listed below."
    - `citations` = every relevant hit as evidence, in rank order: marker `1..K`, `score` = the support score when one was
      computed, else 0, `supported = false`.
    - Log one line with `trace_id`, the reason and counts only (no question, answer or passage text).
  - Answers with at least one supported citation are unchanged: per-sentence flags stay (ADR-0003 Option 1).
  - The early relevance refusal (QA-5, "No indexed papers are relevant to this question.", `citations: []`, no `refusal_reason`) is unchanged.
- `internal/query/rag_test.go`: the cases in the ACs. Extend `TestAskResponseShapeAndConstructor` for the new field; don't delete assertions.
- `tests/test_m3_query.py`, only if an M3 test asserts old behaviour for a case ADR-0003 now refuses. Then assert the
  ADR-0003 response (reason + evidence), never a weaker check. Say so in the PR.
- App `README.md` API table: the `/v1/ask` row mentions `refusal_reason` and its two values (ADR-0003 requires it). Touch only that row.
- Out of scope: `scripts/` and `evals/` (EVAL-6), any per-citation `status` field (ADR-0014), thresholds, frontend (FE-3), the LLM path (QA-8).

## Acceptance criteria
- [ ] AC1 — Case A: a fake embedder making every citation score < 0.50 → `refusal_reason == "all_citations_unsupported"`, the A sentence,
      `citations` = all relevant hits with their computed scores and `supported=false`, non-empty `trace_id`.
- [ ] AC2 — Case B: embedder error on either batch → `verification_unavailable`, the B sentence, evidence passages with score 0.
      Mixed (some citations checked-and-unsupported, some unverified, none supported) → `verification_unavailable`.
- [ ] AC3 — ≥ 1 supported citation → response identical to today (no `refusal_reason` key in the JSON; existing answer tests pass unmodified).
- [ ] AC4 — No in-range marker (e.g. only `[9]` with K = 3) → `all_citations_unsupported`.
- [ ] AC5 — The early refusal is unchanged: `TestAskRefusesWhenNothingPasses` passes unmodified; its JSON has no `refusal_reason` key.
- [ ] AC6 — The log line for A/B has the trace ID and counts, and no passage/question text (assert on a captured logger).
- [ ] AC7 — `rag.go` per-file coverage ≥ 90%: `go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go` (paste rows).
- [ ] AC8 — README `/v1/ask` row updated. `git diff origin/main -- internal/query/server.go evals/thresholds.json` is empty.
- [ ] AC9 — Effect on today's template answers, measured: the M3 suite on `stack.yml` (or `make eval` if EVAL-3 has merged) reports
      how many answer-set questions now refuse, with which reason. Paste counts, or "not run: <reason>" with the exact command.
      A rise is expected and is a finding for pm-lead, not something to tune away (no threshold change).

## Verification
```bash
make lint
make test-unit
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go
git diff origin/main -- internal/query/server.go evals/thresholds.json
# stack.yml run on the PR (M3) for AC9; make eval after EVAL-3
```

## Notes
- 2026-11-07 (pm-lead): specced from the 2026-11-07 plan (Phase 1 items 5–6) and ADR-0003 as accepted.
- **Merge order with EVAL-6:** `scripts/evaluate_answers.py` treats a response with citations as an answer. If AI-7
  merged first, case-A refusals (which carry evidence passages) would be counted as answers with unsupported citations,
  and case B wouldn't count as an error. EVAL-6 teaches the eval about `refusal_reason` from fixtures, so it can merge
  first. AI-7 doesn't touch `scripts/`.
- `rag.go` order for this plan: AI-7 → AI-6 → QA-8 → AI-8 (one file, one owner, sequential).
- Wave 1. Go results come from CI (no Go 1.25 in the sandbox). No LLM is involved.
