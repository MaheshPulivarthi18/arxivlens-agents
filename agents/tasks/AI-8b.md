# AI-8b: `claims[]` and `prompt_version` in `/v1/ask`, README `/v1/ask` row, eval compatibility test

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (Phase 1 item 4: each claim maps to inspectable passages; part 2 of 2 of umbrella AI-8) |
| **PRD ref** | Product PRD QA-3, QA-4, §7 principles 1–3; Technical PRD §7.2; ADR-0014 (Accepted); ADR-0018 (Proposed, documented as such) |
| **Depends on** | **AI-8a merged** (same `rag.go`/test files, builds on its statuses). **ING-11b merged** (it edits `tests/test_evals_data.py` and the README API table). Design approved with conditions: `docs/design/AI-8.md`. Independence at start: no open PR touches `internal/query/rag.go`, `rag_test.go`, `synthesis_test.go`, `tests/test_evals_data.py` or `README.md` |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-AI-8b"`), linked to the AI-8 story |
| **Design required** | yes, done: `docs/design/AI-8.md` (approved, conditions 1–8). No further design. |
| **Status** | Blocked (needs AI-8a merged + ING-11b merged) |

## Goal
A non-refused answer lists its claims in order, each with a status and the markers of its evidence, and a written answer says
which prompt made it. The README documents the whole `/v1/ask` shape so FE-3/FE-4 and API users can rely on it.

## Scope (design §4, README, AC6 Python)
- `internal/query/rag.go`: `Claim{text, status, markers}` and `AskResponse.Claims` (omitempty), `PromptVersion` (omitempty).
  - LLM path (`finalizeClaims`): one claim per **kept** claim, in answer order, `markers = claim.Citations`.
  - Extractive path (`checkCitations` → `finalize`): one claim per `splitIntoSentences(answer)` sentence, including sentences with
    no in-range marker (`markers: []`, `unverified`). Markers are kept in occurrence order and not deduplicated.
  - `claimStatus`: supported if any citation is supported, else unverified if any is unverified, else unsupported, and
    unverified when there are no citations.
  - Ordering invariant: claim *i*'s citations are `citations[o_i : o_i + len(markers_i)]`.
  - `claims` is absent on every refusal (including the early one). `prompt_version = synthesisPromptVersion` only on
    `synthesized` answers.
- `internal/query/rag_test.go`, `synthesis_test.go`: `checkAskInvariants` (extends AI-8a's helper with claims and ordering),
  called from every existing test that gets an `AskResponse`, plus the tests below.
- `tests/test_evals_data.py`: one test (AC6).
- App `README.md`, **`/v1/ask` row only**, with everything in design condition 4.
- If AI-8a used the fallback seam (design condition 5): the model-quote check (design 3b) and AI-8a's AC3 b–e also land here.
  Read AI-8a's Notes before starting.
- Out of scope (design condition 8): `answer_source`, reserved statuses, explicit per-claim citation indices, quote offsets, prompt
  changes, splitter fixes, frontend, the README `/v1/search` row and Testing block, `scripts/` changes.

## Acceptance criteria
- [ ] AC1: Every non-refused response (`answer_kind != ""`) has non-empty `claims`. Each claim has `text`, `status` ∈ enum and
  non-nil `markers`. The ordering invariant holds, and each claim's status equals `claimStatus` of its citation slice. Refusals
  have no `claims` key. Checked by `checkAskInvariants` at every existing `AskResponse` test site.
- [ ] AC2: `TestAskClaims`: extractive → one claim per quoted sentence, markers `[i]`, `answer_kind == "quoted"`, no
  `prompt_version` key; LLM (two claims, one dropped) → the kept claims in order with their markers,
  `answer_kind == "synthesized"`, `prompt_version == "synthesis-v1"`, dropped claim absent; quick stage → no `prompt_version`;
  an extractive answer that sentence-splits into an uncited fragment (direct `checkCitations` call) → that claim has
  `markers: []` and status `unverified`.
- [ ] AC3: Every refusal path (`all_citations_unsupported`, `verification_unavailable`, no in-range marker, `insufficient_evidence`,
  early refusal) → no `claims` key and no `prompt_version` key. The early refusal also has `citations == []` and no
  `refusal_reason` (design condition 3).
- [ ] AC4: Design condition 7: one test where the quoted sentence contains `e.g.` and `0.5` asserts one claim per quoted
  sentence. If the current splitter fails it, pin the current behaviour, don't change `splitIntoSentences`, and request a
  follow-up in Notes.
- [ ] AC5: `TestAskResponseShapeAndConstructor` is extended with `claims` and `prompt_version` (present only when set); every
  pre-existing key keeps its name and JSON type.
- [ ] AC6: A new test in `tests/test_evals_data.py` feeds `classify`, `coverage_units` and `case_record` (from
  `scripts/evaluate_answers.py`) the same fixture response with and without `claims` and the new citation fields. Results must be
  equal for an extractive answer (claims = its sentences) and for a refusal.
- [ ] AC7: README `/v1/ask` row documents: request `quick`; `answer_kind`, `synthesis_available`, `insufficient_evidence` (marked
  "ADR-0018, Proposed"); `prompt_version`; `claims[]` with the status enum and claim-status rule; citation `paper_version`,
  `page`, `quote`, `status`; the versioned `pdf_url`; `unverified` = "not checked: the verifier was unavailable, or no statement
  cited this passage"; `quote` occurs in `content` after whitespace/inline-reference normalisation; the ordering invariant. No
  other README row or section changes (`git diff README.md` in the PR).
- [ ] AC8: `rag.go` per-file coverage ≥ 90% (paste the rows); `git diff --stat origin/main` < 400 changed lines.
- [ ] AC9: One `workflow_dispatch` of `eval.yml` on `agent/ai/AI-8b`. Paste `supported_citation_rate`, the correct-refusal rate,
  answer coverage and `GATE:` next to nightly 43902662193 and the AI-8a run. A coverage change is reported as a finding (design
  condition 6). Otherwise "not run: <reason>" with the command.
- [ ] Docs: the PR body notes that `answer_source` isn't added (ADR-0018 Option 1) and would be an additive follow-up under
  Option 2. pm-lead updates the Product PRD QA-3/QA-4 status column after merge (docs PR).

## Verification
```bash
make lint
make test-unit
go test -race -run 'Ask|Synth|Citation|Claim' -v ./internal/query/
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go
python3 -m pytest -q tests/test_evals_data.py
git diff --stat origin/main
git diff origin/main -- README.md      # AC7: only the /v1/ask row
gh workflow run eval.yml --ref agent/ai/AI-8b   # AC9, then read the job log's gate table
```

## Notes
- 2026-11-17 (pm-lead): created from the approved AI-8 design (PM decision 2026-11-17). Q3: the positional mapping is enough for
  AI-8. If FE-4's design needs explicit per-claim citation indices, that needs a new Proposed ADR (Mahesh), not this ticket.
