# AI-8b: `claims[]` and `prompt_version` in `/v1/ask`, README `/v1/ask` row, eval compatibility test

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (Phase 1 item 4: each claim maps to inspectable passages; part 2 of 2 of umbrella AI-8) |
| **PRD ref** | Product PRD QA-3, QA-4, §7 principles 1–3; Technical PRD §7.2; ADR-0014 (Accepted); ADR-0018 (Proposed, documented as such) |
| **Depends on** | **AI-8a merged** (same `rag.go`/test files, builds on its statuses). **AI-8c merged** (puts `checkCitationInvariants` at the `synthesis_test.go` sites, so the extended helper covers them). **ING-11b merged** (it edits `tests/test_evals_data.py` and the README API table). Design approved with conditions: `docs/design/AI-8.md`. Independence at start: no open PR touches `internal/query/rag.go`, `rag_test.go`, `synthesis_test.go`, `tests/test_evals_data.py` or `README.md` |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-AI-8b"`), linked to the AI-8 story |
| **Design required** | yes, done: `docs/design/AI-8.md` (approved, conditions 1–8). No further design. |
| **Status** | Ready (AI-8a #54, AI-8c #59, ING-11b #52 merged). Picked for cycle 2026-11-19 18:00Z |

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
- `internal/query/rag_test.go` only: extend AI-8a's `checkCitationInvariants(t, resp)` **in place** (same name and signature; or
  have it delegate to a new `checkAskInvariants`) with the claims and ordering checks, so every existing call site in `rag_test.go`
  *and* the backend-owned `synthesis_test.go` (via AI-8c) gets them without editing that file. Plus the tests below.
  `synthesis_test.go` is **not** in scope (backend-owned; amended 2026-11-17).
- `tests/test_evals_data.py`: one test (AC6).
- App `README.md`, **`/v1/ask` row only**, with everything in design condition 4.
- If AI-8a used the fallback seam (design condition 5): the model-quote check (design 3b) and AI-8a's AC3 b–e also land here.
  Read AI-8a's Notes before starting.
- Out of scope (design condition 8): `answer_source`, reserved statuses, explicit per-claim citation indices, quote offsets, prompt
  changes, splitter fixes, frontend, the README `/v1/search` row and Testing block, `scripts/` changes.

## Acceptance criteria
- [ ] AC1: Every non-refused response (`answer_kind != ""`) has non-empty `claims`. Each claim has `text`, `status` ∈ enum and
  non-nil `markers`. The ordering invariant holds, and each claim's status equals `claimStatus` of its citation slice. Refusals
  have no `claims` key. Checked by the extended `checkCitationInvariants` helper at every `AskResponse` test site. The `rag_test.go`
  sites are edited here. The `synthesis_test.go` sites already call the helper (AI-8c), so they are covered without editing that
  file. The PR shows `go test -run 'Synth|QuickAnswer|WithLLMNil' -v ./internal/query/` passing with the extended helper.
  *Amended 2026-11-17 (pm-lead, AI-8a QA r1 finding 4 [spec]).* Sites that call `finalize` directly with a hand-set
  `answer_kind` (see the AI-8a Notes) must build a response that really satisfies the claims invariant. Don't skip the check there.
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
  *Amended 2026-11-17 (pm-lead, AI-8a final review):* AI-8a was raised without its own `eval.yml` run (AC7 "not run": dispatch
  denied to the ai sandbox). "The AI-8a run" therefore means **the first scheduled nightly `eval.yml` on `main` after AI-8a merges**
  (or Mahesh's dispatch on `agent/ai/AI-8a`, if he ran one; its ID is then in PR #54). Before building, paste its
  `supported_citation_rate`, correct-refusal rate, answer coverage and `GATE:` next to 43902662193. **Stop and report** (Notes +
  pm-lead) if any of them differs: AI-8a was expected to leave all four identical on the quoted path.
- [ ] Docs: the PR body notes that `answer_source` isn't added (ADR-0018 Option 1) and would be an additive follow-up under
  Option 2. pm-lead updates the Product PRD QA-3/QA-4 status column after merge (docs PR).

## Verification
```bash
make lint
make test-unit
go test -race -run 'Ask|Synth|Citation|Claim|QuickAnswer|WithLLMNil' -v ./internal/query/
grep -c 'checkCitationInvariants' internal/query/synthesis_test.go   # 11 from AI-8c, unchanged by this PR
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go
python3 -m pytest -q tests/test_evals_data.py
git diff --stat origin/main
git diff origin/main -- README.md      # AC7: only the /v1/ask row
gh workflow run eval.yml --ref agent/ai/AI-8b   # AC9, then read the job log's gate table
```

## Notes
- 2026-11-17 (pm-lead): created from the approved AI-8 design (PM decision 2026-11-17). Q3: the positional mapping is enough for
  AI-8. If FE-4's design needs explicit per-claim citation indices, that needs a new Proposed ADR (Mahesh), not this ticket.
- 2026-11-17 (ai-engineer, from AI-8a build): design condition 5 was **not** taken (AI-8a is 387 lines), so 3b stays in AI-8a. **[spec]**
  AC1's "every existing `AskResponse` test site" includes `internal/query/synthesis_test.go`, which `ownership-check.sh` doesn't allow for
  `ai`. See AI-8a Notes (2026-11-17 ai-engineer) for the follow-up options. Resolve before AI-8b starts.
- 2026-11-17 (pm-lead): ownership issue resolved with option (a); see AI-8a Notes. AC1 and Scope amended: this ticket edits only
  `rag_test.go` and extends the shared helper in place, so no second backend follow-up is needed for claims. New dependency: AI-8c merged.
- 2026-11-19 18:10Z (ai-engineer, build): PR [#65](https://github.com/MaheshPulivarthi18/ArxivLens/pull/65) (draft), head `9b2778f`, 198 changed lines.
  AC9 pre-build check: first nightly after AI-8a, 44559854028 (`8b55af2`, contains `12e9c82`), matches 43902662193 on all four values
  (supported 1.0000/60, correct refusals 1.0000/22, citation_coverage 1.0000, GATE: PASS). Branch eval dispatched: run 44584838337.
  Choices: an extractive claim's `text` is `normQuote(sentence)` (same normalisation as the AI-8a extractive `quote`); an LLM claim's `text` is
  `claim.Text`. `TestAskKeepsAnswerWithOneSupportedCitation`'s key assertion now includes the additive `claims` key. AC4: splitter handles `e.g.` and `0.5`.
  Mutation M7 (LLM claim status hardcoded `supported`) is unkillable by design (a kept LLM claim always has a supported citation).
- 2026-11-19 (ai-engineer): **Rework r1** (QA FAIL r1, finding 1 [blocking]). Test-only change in `internal/query/rag_test.go` (+19 lines,
  commit `956db78`, new PR #65 head `956db7824ec2f706565e02426762a7a5220f2683`): `TestAskClaims` now asserts by literal value that a quote +
  paraphrase answer with the verifier down gives claims `[supported [1], unverified [2]]`, plus a literal `claimStatus` table
  (`[]`→V, `[U]`→U, `[V]`→V, `[U,V]`→V, `[V,U]`→V, `[U,S]`→S, `[V,S]`→S, `[U,U]`→U). No `rag.go` change.
  M3 result: applied temporarily in a go1.24 scratch module (QA harness stubs; `internal/` identical to head) → `FAIL arxivlens/internal/query`,
  `TestAskClaims` reports `verifier down claims [... Status:unsupported Markers:[2]]` and `claimStatus([unverified]) = "unsupported"`; reverted.
  QA's 23-mutant script re-run: 21 killed, survivors M0 (control), M14, M23 (equivalent, as in the QA report).
  CI on `956db78`: 6/6 success (Go, ownership, Python M0, Frontend, DB, Full stack). Local `rag.go` coverage 416/420 = 99.0%.
  Nit 2 done: PR body now has the AC1 `-v` run, AC8 coverage rows, CI and mutation rows. Branch is behind `origin/main` (no conflict
  reported by GitHub checks; not rebased, no force-push).
