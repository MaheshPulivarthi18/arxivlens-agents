# AI-8a: Citation `status`, provenance (`paper_version`, `page`), verified `quote`, versioned `pdf_url` and raw `content` in `/v1/ask`

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (Phase 1 item 5: unverified is never shown as verified; part 1 of 2 of umbrella AI-8) |
| **PRD ref** | Product PRD QA-3, QA-4, §7 principles 1–3; Technical PRD §7.2; ADR-0003 (Accepted), ADR-0014 (Accepted) |
| **Depends on** | ADR-0014 Accepted ✅, QA-8 delivered (#46 `cc57474`) ✅, RET-2 merged (`6cfd836`) ✅. **Design approved with conditions**: `docs/design/AI-8.md`, PM decision 2026-11-17. Not a dependency: ADR-0018 (Proposed), ING-11b (`page` is tested with hand-built hits). Independence at start: no open PR touches `internal/query/rag.go`, `rag_test.go` or `synthesis_test.go` (cycle 2026-11-17: ING-11b, EVAL-4 and OPS-H2 don't) |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-AI-8a"`), linked to the AI-8 story |
| **Design required** | yes, done: `docs/design/AI-8.md` (approved, conditions 1–8). No further design. |
| **Status** | In Progress (rework r1 done, awaiting QA round 2): `agent/ai/AI-8a` @ `a0a2ced`, PR #54 (draft). AC1 partly blocked on file ownership (QA finding 4, pm-lead) |

## Goal
Every `/v1/ask` citation, in both answers and refusal evidence, says whether it was checked and passed, checked and failed,
or not checked. It also says which paper version (and page, when known) it came from, opens that version's PDF, and carries a
verbatim quote only when the quote is really in the passage.

## Scope (design §1–3, §5–7)
- `internal/query/rag.go`:
  - `Citation` gains `paper_version` (int, always present), `page` (`*int`, omitempty, copied by value), `quote` (omitempty)
    and `status` (always present). Add the constants `StatusSupported`/`StatusUnsupported`/`StatusUnverified`.
  - `newCitation(marker, hit, score, status string)` sets `Supported = status == StatusSupported`, plus `PaperVersion`, `Page`,
    and `pdf_url` = `arxiv.PDFURL(id, version)` when `Version > 0` (else today's unversioned URL).
  - Status rules from design §1: `labelScore` ok and ≥ 0.50 → `supported`, ok and < 0.50 → `unsupported`, not ok → `unverified`.
    For refusal evidence on **every** path: `unsupported` if `hitScored[i]`, else `unverified`. `insufficient_evidence` evidence
    is all `unverified`.
  - `scorePairs` returns `exact []bool`. Add the `inPassage` helper (`normQuote`-normalised, case-sensitive, no minimum length).
  - `quote`: (a) an exact-match `supported` citation gets the marker-free sentence (on the LLM path only if `inPassage` against
    the raw chunk also holds); (b) a model `synthesisClaim.Quote` is checked per citation against the **raw** chunk. Not
    verbatim → that citation is `unsupported`, no quote, score kept. Invariant: `quote` present ⇒ `supported`.
  - LLM path: `finalizeClaims` takes `[]contextPassage`. It scores on `p.Text` and builds citations and checks quotes from
    `p.Hit` (raw `Content`). The `insufficient_evidence` evidence uses `p.Hit`. Delete `passageHits` and `TestPassageHits`.
- `internal/query/rag_test.go`: tests below, plus a `checkCitationInvariants` helper called from existing tests that get an
  `AskResponse`. (Amended 2026-11-17: `internal/query/synthesis_test.go` is **not** in scope; it is backend-owned per
  `ownership-check.sh`. Its 11 call sites are backend follow-up **AI-8c**.)
- Out of scope (AI-8b): `claims[]`, `prompt_version`, the README `/v1/ask` row, the AC6 Python test. Also out (design condition 8):
  `answer_source`, `partially_supported`/`contradicted`, quote offsets, prompt changes, `search.go`, frontend, `README.md`,
  `tests/test_evals_data.py`.

## Acceptance criteria
- [ ] AC1: Every citation (answers and refusal evidence, both paths) has `paper_version` and `status` ∈ {supported, unsupported,
  unverified}, and `supported == (status == "supported")`. `quote` present ⇒ `status == "supported"` and
  `inPassage(quote, content)`. Checked by `checkCitationInvariants(t, resp)`, which is called from every existing test in
  `rag_test.go` that gets an `AskResponse`, and from every new test (both paths). A response without `answer_kind` counts as a
  refusal (design condition 3). *Amended 2026-11-17 (pm-lead, QA r1 finding 4 [spec]):* the `synthesis_test.go` call sites are
  out of this ticket (ai can't edit that file) and land in backend follow-up **AI-8c** (Depends on AI-8a merged). The helper
  must stay callable from another `_test.go` file in package `query` (same signature `checkCitationInvariants(t, resp)`).
- [ ] AC2: `TestCitationStatusRule`, a table over both `checkCitations` and `finalizeClaims`: 0.9 / 0.50 → supported; 0.49 and a
  checked 0 → unsupported; verifier error, wrong score count, nil verifier, NaN, -0.1 and 1.1 → `unverified`, `supported == false`,
  score 0. Mutations (local, not pushed): removing any one `labelScore`/`scorePairs` failure branch, or setting `Supported`
  independently of `Status`, fails a row. List each mutation and the test that failed in the PR.
- [ ] AC2r: `TestRefusalEvidenceStatus`: `verification_unavailable` with mixed hits (checked → unsupported, failed → unverified);
  `all_citations_unsupported` with 5 hits (cited 1–3 unsupported, uncited 4–5 unverified); no in-range marker (all unverified);
  `insufficient_evidence` (all unverified, raw `content`); early refusal (`citations == []`). No refusal-evidence citation is ever
  `supported`.
- [ ] AC3: `TestCitationQuote`: (a) an extractive exact match has `quote` == the marker-free sentence; (b) an LLM quote with extra
  whitespace/newlines that is verbatim in the raw chunk is kept; (c) an LLM quote not in the chunk with fake NLI 0.9 → citation
  `unsupported`, no quote. A single-citation claim is then dropped, and when it was the only claim the response is the quoted
  fallback (`answer_kind == "quoted"`) (design condition 2 i–ii); (d) a two-citation claim whose quote is verbatim only in
  passage 1 → citation 1 supported with the quote, citation 2 `unsupported` (condition 2 iii); (e) a model quote that is `""`,
  whitespace only or `"[3]"` is treated as absent and the status follows NLI (condition 1); (f) a chunk containing `<passage`:
  `content` is raw (no `&lt;`), the verifier pair carries the sanitized text, and a model quote of the raw text is kept;
  (g) an NLI-supported paraphrase with no model quote has no `quote`.
- [ ] AC4: `TestCitationProvenance` (both paths): a hand-built hit with `Version: 3` and `Page: &4` → `paper_version` 3, `page` 4,
  `pdf_url` ends in `v3.pdf`, and the citation's page pointer is not the hit's; `Page: nil` → no `"page"` key in the JSON;
  `Version: 0` → unversioned `pdf_url`.
- [ ] AC5: Backward compatibility: `TestAskResponseShapeAndConstructor` is extended. Every pre-existing key keeps its name and
  JSON type and nothing is removed. `paper_version` and `status` are always present; `page` and `quote` only when set. The PR
  body has a `git grep -n` of `frontend/src` and `scripts/` for `pdf_url`, `content` and `supported`, matching the design's
  consumer table.
- [ ] AC6: `rag.go` per-file coverage ≥ 90% (the command below; paste the file rows; a scratch-module run is fine if CI doesn't
  print it). `git diff --stat origin/main` < 400 changed lines. If it's ≥ 400, apply design condition 5 (move 3b, i.e. AC3
  b–e, to AI-8b) and record it in Notes here and in AI-8b.
- [ ] AC7: One `workflow_dispatch` of `eval.yml` on `agent/ai/AI-8a`. Paste `supported_citation_rate`, the correct-refusal rate,
  answer coverage and `GATE:` next to nightly 43902662193 on `40dec5a` (supported 100%, correct refusals 100%, `GATE: PASS`).
  Expected identical. Otherwise "not run: <reason>" with the command.
- [ ] AC8: The PR body lists every new citation field with its meaning, says "README `/v1/ask` row lands in AI-8b" (design
  condition 4), and has one line each for Mahesh on the Q1 reading of `unverified` and on ADR-0018 (`answer_source` not added).

## Verification
```bash
make lint
make test-unit
go test -race -run 'Ask|Synth|Citation|Claim|Refusal|Quote|Provenance' -v ./internal/query/
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go
git diff --stat origin/main
git grep -n -E 'pdf_url|\.content|supported' origin/main -- frontend/src scripts/   # AC5 consumer check
gh workflow run eval.yml --ref agent/ai/AI-8a   # AC7, then read the job log's gate table
```

## Notes
- 2026-11-17 (pm-lead): created from the approved AI-8 design (PM decision 2026-11-17, conditions 1–8). Q1: never-checked
  refusal evidence is `unverified` (a fix to the AI-8 ticket's rule). Q2: model quote checked per citation. Q4: `normQuote`
  match accepted. AI-8b depends on this being **merged**.
- 2026-11-17 (ai-engineer): **build notes**, branch `agent/ai/AI-8a` @ `12e70b4` (from `40dec5a`). Files: `internal/query/rag.go` (150 lines
  changed) and `internal/query/rag_test.go` (237). **387 changed lines** (`git diff --stat origin/main`),
  so design condition 5 (moving 3b to AI-8b) was **not** taken. `ownership-check.sh origin/main agent/ai/AI-8a`: `Ownership OK for role=ai (387 changed lines)`.
  - **[spec] ownership conflict, `synthesis_test.go`.** Scope says ai edits `synthesis_test.go`, but `ownership-check.sh` allows only
    `internal/query/rag(_test)?\.go` for `ai` (AGENTS.md §2 agrees; the file is backend's under `internal/`). My first push candidate
    failed the check (`::error file=internal/query/synthesis_test.go::outside ai's code area`). So the four new tests live in
    `rag_test.go` and `synthesis_test.go` is untouched. **AC1 consequence:** `checkCitationInvariants` is called from every existing
    `AskResponse` test in `rag_test.go` (13 sites) and from all new tests (LLM path included), but **not** from the 10 existing tests in
    `synthesis_test.go`. **Follow-up request (pm-lead to pick one):** (a) a backend task adding one `checkCitationInvariants(t, resp)` line
    to each of `TestSynthesisAnswersWithVerifiedClaims`, `TestSynthesisDropsUnsupportedClaims`, `TestSynthesisRefusals`,
    `TestSynthesisFallsBackToExtractive`, `TestSynthesisClaimsUnsupportedFallBackToQuotes` (2 sites), `TestQuickAnswerSkipsSynthesis`
    (resp, full, plain), `TestSynthesisMarkersFollowPromptOrder`, `TestWithLLMNilKeepsExtractive` (~13 lines; I ran them locally,
    all pass); or (b) a `rules/` PR (Mahesh) adding `internal/query/synthesis_test.go` to the ai allow-list. AI-8b's AC1 has the same issue.
  - Local runs: Go 1.24.7 only (go.mod needs 1.25, toolchain download blocked), so `make lint-go`/`make test-go` fail at the toolchain
    download. Ran the real `rag.go`/`rag_test.go`/`synthesis_test.go`/`search.go`/`client.go`/`search_test.go` plus real `internal/arxiv` and
    `internal/llm` in a scratch module (stubbed `internal/db` and `pgx` only, `GOTOOLCHAIN=local GOPROXY=off`): `gofmt -l` empty, `go vet` OK,
    `go test -race ./internal/query/` ok, the ticket's `-run 'Ask|Synth|Citation|Claim|Refusal|Quote|Provenance'` 114 PASS, 0 FAIL.
    `rag.go` per-file coverage **99.0% (399/403)** (baseline `40dec5a`: 99.0%, 382/386). CI is the source of truth.
  - Mutations (local, never pushed): 20/20 killed. AC2 rows: drop `failed ||` / `raw >= 0` / `raw <= 1` in `labelScore`, drop
    `failed[i] = true`, `!ok → unsupported`, `Supported = status != unsupported` → `TestCitationStatusRule` rows; drop nil-verifier branch →
    row `nil_verifier` (panic); drop wrong-count check → row `wrong_score_count`. `Supported = score >= threshold`, quote vs `p.Text`, quote on
    an unsupported citation, empty quote counted, keep before downgrade, LLM exact quote without the raw-chunk check, extractive quote dropped →
    `TestCitationQuote`. Refusal evidence always unsupported, insufficient-evidence sanitized/unsupported → `TestRefusalEvidenceStatus`.
    Unversioned `pdf_url`, aliased page → `TestCitationProvenance`. One mutant (LLM exact quote without `inPassage` on the raw chunk)
    survived the first run; I added the row "(f) claim verbatim only in the escaped text: supported, no quote".
  - Choices: an extractive `quote` is `normQuote(marker-free sentence)`, so it reads "…benchmark." and not "…benchmark ." (design §3a allows
    `normQuote` differences). A model quote is kept as `TrimSpace(claim.Quote)` (design §3b). A fabricated model quote makes the citation
    `unsupported` even when the verifier failed (the quote check itself ran and failed). `TestAskKeepsAnswerWithOneSupportedCitation` and the
    verbatim-quote block of `TestAskRefusesVerificationUnavailable` call `finalize` directly, which leaves `answer_kind` to `AskWith`, so the
    helper gets `{Citations, AnswerKind: quoted}` there (condition 3 would otherwise count them as refusals).
  - **AC7 not run:** `gh workflow run eval.yml --ref agent/ai/AI-8a` was denied by this session's permission policy. Needs the orchestrator
    or pm-lead to dispatch it and compare with nightly 43902662193. No push-triggered runs exist on the branch (CI runs on the PR).
  - Jira KAN-60: this session has no Jira tool, so the In Progress/In QA moves and links are left to the orchestrator.
- 2026-11-17 (pm-lead): **decision on QA r1 finding 4 [spec] (AC1 vs file ownership): option (a).** AC1 amended to `rag_test.go` only
  (see AC1 text). The 11 `synthesis_test.go` call sites (QA evidence 05; QA's local probe, evidence 06, shows all 8 tests pass with them)
  become backend task **AI-8c** (`agents/tasks/AI-8c.md`, Depends on AI-8a merged). Why not (b): widening ai's allow-list needs a
  `rules/` PR here (AGENTS.md) *and* a backend change to `app/.github/scripts/ownership-check.sh`. Neither lands this cycle, and the
  rework would sit blocked on Mahesh. Option (a) weakens no test: the same checks run at the same sites, one PR later. Finding 4 is
  closed for AC1. QA round 2 checks AC1 against the amended text. Findings 1–3 and nits 5–7 stay with ai-engineer.
- 2026-11-17 (ai-engineer): **Rework r1** (QA round 1 FAIL, `agents/reviews/AI-8a/report.md`). New head `a0a2ced` (one commit on `12e70b4`, `rag_test.go` only, +16/-4; `rag.go` unchanged). Branch total **399 changed lines** (334+65), `ownership-check.sh`: `Ownership OK for role=ai (399 changed lines)`, so design condition 5 is not taken.
  - [x] 1 [blocking] AC5 grep: `git grep -n -E 'pdf_url|\.content|supported' origin/main -- frontend/src scripts/` (33 lines) pasted in the PR #54 body, with a line per consumer (including `answer_review.py:56,151`).
  - [x] 2 [blocking] AC2 list: the PR body now has a table of 10 mutations (A1–A10), each with the full-suite failing tests and the table-only failing rows. Corrected the claim: in the full suite, A5 (nil verifier) and A6 (wrong count) are killed first by `TestValidateCitationsFailClosedWhenUnverifiable` (panic). All 10 are killed in both kinds of run (local, scratch module).
  - [x] 3 [blocking] case-sensitive match: `TestCitationQuote` rows `(c) case-changed quote drops the only claim (ADR-0014)` (expects `quoted`) and `(d) quote differing only in case is unsupported` (expects `[S+quote, U no quote]`). M33 (case-insensitive `inPassage`) is killed by both.
  - [ ] 4 [spec] `synthesis_test.go` ownership: pm-lead's call; file not touched.
  - [x] 5 [nit] `TestCitationStatusRule` row `fabricated quote at 0.9` (LLM path expects unsupported, score 0.9). M09/A9 (`Supported = score >= 0.50`) now fails it in the table-only run.
  - [x] 6 [nit] AC7 line in the PR body has `gh workflow run eval.yml --ref agent/ai/AI-8a` and the reason (dispatch denied by the ai sandbox; `pull_request` filter excludes `internal/**`). **Still needs a dispatch by pm-lead or the orchestrator.**
  - [x] 7 [nit] `TestCitationQuote` row `(b) quote across newline, double space and inline refs in the chunk kept` plus an extractive check on the same chunk (`[12]`, `[3, 4]`), which expects the marker-free quote and runs `checkCitationInvariants`. M34 is killed by both.
  - Local runs (Go 1.24.7 scratch module, only `internal/db`/`pgx` stubbed): `gofmt -l` empty, `go vet` ok, `go test -race` on query/llm/arxiv ok, ticket targeted run 118 PASS / 0 FAIL, `rag.go` 99.0% (399/403). `make test-unit`/`make lint` are left to CI.
