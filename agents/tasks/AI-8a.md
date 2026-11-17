# AI-8a: Citation `status`, provenance (`paper_version`, `page`), verified `quote`, versioned `pdf_url` and raw `content` in `/v1/ask`

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (Phase 1 item 5: unverified is never shown as verified; part 1 of 2 of umbrella AI-8) |
| **PRD ref** | Product PRD QA-3, QA-4, §7 principles 1–3; Technical PRD §7.2; ADR-0003 (Accepted), ADR-0014 (Accepted) |
| **Depends on** | ADR-0014 Accepted ✅, QA-8 delivered (#46 `cc57474`) ✅, RET-2 merged (`6cfd836`) ✅. **Design approved with conditions**: `docs/design/AI-8.md`, PM decision 2026-11-17. Not a dependency: ADR-0018 (Proposed), ING-11b (`page` is tested with hand-built hits). Independence at start: no open PR touches `internal/query/rag.go`, `rag_test.go` or `synthesis_test.go` (cycle 2026-11-17: ING-11b, EVAL-4 and OPS-H2 don't) |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-AI-8a"`), linked to the AI-8 story |
| **Design required** | yes, done: `docs/design/AI-8.md` (approved, conditions 1–8). No further design. |
| **Status** | Ready. Branch `agent/ai/AI-8a` |

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
- `internal/query/rag_test.go`, `internal/query/synthesis_test.go`: tests below, plus a `checkCitationInvariants` helper called
  from existing tests that get an `AskResponse`.
- Out of scope (AI-8b): `claims[]`, `prompt_version`, the README `/v1/ask` row, the AC6 Python test. Also out (design condition 8):
  `answer_source`, `partially_supported`/`contradicted`, quote offsets, prompt changes, `search.go`, frontend, `README.md`,
  `tests/test_evals_data.py`.

## Acceptance criteria
- [ ] AC1: Every citation (answers and refusal evidence, both paths) has `paper_version` and `status` ∈ {supported, unsupported,
  unverified}, and `supported == (status == "supported")`. `quote` present ⇒ `status == "supported"` and
  `inPassage(quote, content)`. Checked by `checkCitationInvariants(t, resp)`, which is called from every existing test in
  `rag_test.go` and `synthesis_test.go` that gets an `AskResponse`. A response without `answer_kind` counts as a refusal
  (design condition 3).
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
