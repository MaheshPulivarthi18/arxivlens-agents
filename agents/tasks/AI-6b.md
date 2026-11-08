# AI-6b: Structured-output parser `parseSynthesis` in `rag.go` (not yet called)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (Phase 1 items 2–3; QA-8 calls it to turn the model's reply into cited claims or a refusal) |
| **PRD ref** | Product PRD QA-8, §7 principles 1–2 (evidence first, honest refusal), risk "Hallucinated citations"; Technical PRD §7.2; ADR-0002, ADR-0003 (Accepted) |
| **Depends on** | **AI-6 merged** (ArxivLens PR #28; same files `rag.go` + `rag_test.go`). No dependency on LLM-1/LLM-1b: pure function, no `internal/llm` import. |
| **Jira** | KAN-52, story under epic KAN-1 "Grounded LLM answers" (`labels = "task-AI-6b"`) |
| **Design required** | covered: `docs/design/QA-8.md` §1 (types, errors), §5 (`parseSynthesis`), the test-plan AC3 rows and PM decision (open question 3, conditions 1, 5, 6), plus the pm-lead post-build record at the end of that file. **No new design.** |
| **Status** | Ready (Wave 3: starts when AI-6 #28 is merged). Branch `agent/ai/AI-6b` |

## Goal
Split out of AI-6 under design condition 1 seam (c): AI-6 ships context selection and the prompt; this task adds the parser for
the model's JSON reply. It returns cited claims (out-of-range citation numbers dropped and counted), passes the model's own
"insufficient evidence" through as a refusal signal, and returns errors that never carry completion text. QA-8 then has every
deterministic piece it needs. `Ask` doesn't call any of it yet, so behaviour is unchanged.

## Scope
- `internal/query/rag.go` (new unexported code, after AI-6's block):
  - `synthesisClaim`, `synthesisResult`, `errSynthesisMalformed`, `errSynthesisNoClaims`, exactly as in design §1.
  - `parseSynthesis(raw string, k int) (synthesisResult, error)`, exactly as in design §5 steps 1–6 (fence handling, strict
    `json.Decoder` decode, nothing but whitespace after the object, refusal flag wins over claims, inline `[n]` stripped with the
    existing `markerRegex` and merged, dedup, `1 ≤ n ≤ k`, drop empty/uncited claims with counts, all-dropped → zero claims + nil error).
    Errors are the two sentinels, **never wrapping** the `encoding/json` error.
  - New imports: standard library only (`encoding/json`, `errors`, and `io` if used to detect trailing data).
  - Small hardening from AI-6 QA r1 (pm-lead decision, recorded in the design's post-build record):
    - nit 5: widen `blockTagRegex` to `(?i)<\s*(/?)\s*(passage|question)`, so `< /passage>`, `</ passage>` and `<\tpassage n="9">` are escaped too.
      The replacement stays `&lt;$1$2`. It's still idempotent, because `&lt;` contains no `<`.
    - missing test 2: `selectContext` skips a hit whose content is empty after whitespace collapse (no evidence to cite). It uses no cap slot and no budget.
- `internal/query/rag_test.go`: new tests appended, and new cases added to AI-6's tables (no existing case changed or removed).
- Out of scope: calling a provider, `Ask`/`finalize`/`checkCitations` changes, response fields, README, `internal/llm`, `search.go`,
  `quote` checking (AI-8 / ADR-0014), the prompt text and `synthesisPromptVersion` (unchanged), fullwidth look-alikes such as `＜/passage＞`
  (left to system rule 3; revisit if EVAL-8 shows a problem), and the whitespace-only question (`Ask` refuses an empty question first).

## Acceptance criteria
- [ ] AC3 — `parseSynthesis`: valid JSON; fenced JSON; `[9]` with k = 3 dropped and counted; `insufficient_evidence: true` → refusal signal;
      non-JSON → error; empty claims without the flag → error. *(Carried over unchanged from AI-6 AC3.)* Tests, exactly as in the design test plan:
  - `TestParseSynthesis` (table): **valid** JSON → claims, citations, no drops; **fenced** (```` ```json ```` and bare ```` ``` ````) → same result;
    **`[9]` with k = 3** in citations → dropped, `DroppedMarkers = 1`, claim kept with `[1]`; inline `[2]` in text → stripped and merged, inline `[7]` → counted;
    duplicate citations deduplicated; **all citations out of range** → claim dropped, `DroppedClaims = 1`, zero claims, **nil error**;
    **`insufficient_evidence: true`** (with and without claims) → flag set, no claims, nil error; **non-JSON**, prose around JSON, trailing data,
    `"citations": ["1"]`, a JSON array → `errSynthesisMalformed`; **empty claims / missing claims / `null`** without the flag → `errSynthesisNoClaims`;
    unknown key ignored; `quote` kept.
  - `TestParseSynthesisErrorHasNoCompletionText`: malformed reply containing a sentinel string → `err.Error()` doesn't contain the sentinel.
- [ ] AC4 — Delimiter look-alikes: `TestBuildSynthesisPromptInjection` gets new cases for `< /passage>`, `</ passage>`, `<\tpassage n="9">` and `< question>`
      in passage text and in the question. The delimiter counts still match `len(passages)` and 1, and the injected text stays inside passage 1's tags.
      All existing injection cases still pass, and `TestPassageTokensBoundsRenderedBlock` still holds.
- [ ] AC5 — `selectContext` edge cases (new `TestSelectContext` rows): (a) an empty or whitespace-only content hit is skipped and takes no cap slot,
      so 3 more hits of the same paper are still taken; (b) the truncation branch is reached after earlier hits were **skipped** (a duplicate,
      then an oversize hit, with nothing taken yet) → truncated at a word boundary, `Marker == 1`, `HitIndex` points at the oversize hit.
- [ ] AC6 — No behaviour change: `Ask` doesn't reference `parseSynthesis` (the design §7 `awk … | grep -c` prints `0`, and the pattern includes
      `parseSynthesis`). Every pre-existing `rag_test.go` test and AI-6 table case passes unmodified, and `git diff` on `rag_test.go` is additions only.
      `go vet` is clean. In `rag.go` the only removed or changed lines are the import block and `blockTagRegex`, plus at most 2 lines in `selectContext`'s skip condition.
- [ ] AC7 — `rag.go` per-file coverage ≥ 90%, and `parseSynthesis` at 100% (pasted `go tool cover` output or CI output, never an estimate).
- [ ] AC8 — Mutation evidence **in the PR description** (design condition 5), each with the test that fails: out-of-range marker kept;
      claim with no citations kept; `insufficient_evidence` with claims returns the claims; error wraps the JSON error; trailing data accepted;
      old `blockTagRegex` restored; empty-content skip removed. If they ran in a scratch module, say so.
- [ ] AC9 — Diff < 400 changed lines (design estimate ≈ 50 `rag.go` + ≈ 60–90 `rag_test.go`).

## Verification
```bash
make lint
make test-unit
go test -run 'ParseSynthesis|SelectContext|BuildSynthesisPrompt|PassageTokens' -v ./internal/query/
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go
awk '/^func \(r \*RAGService\) Ask\(/,/^}/' internal/query/rag.go | grep -cE 'selectContext|buildSynthesisPrompt|parseSynthesis|passageHits'   # prints 0
git diff --shortstat origin/main
.github/scripts/ownership-check.sh origin/main agent/ai/AI-6b
```

## Notes
- 2026-11-07 (pm-lead): created from AI-6 QA r1 finding 3 `[spec]`. AI-6's AC3 and its two design test-plan rows are copied
  **unchanged**. The third design mutation (out-of-range marker kept) moved here with the parser, and AI-6 marks AC3 "moved to AI-6b". I folded in
  QA nit 5 (whitespace delimiter look-alikes) and missing tests 1–2, because they're small (≈ 20 lines) and touch the same two files.
  Empty-content passages: pm-lead decision is **skip** (an empty passage can't support a citation, and the template path already handles
  "nothing to cite"). Missing test 3 (whitespace-only question) is left out: `Ask` returns earlier.
- Cut the branch from `origin/main` after #28 merges (not from `agent/ai/AI-6`). Branch name `agent/ai/AI-6b` (`ownership-check.sh` accepts role `ai` only).
- 2026-11-07 (pm-lead): Jira story is **KAN-52**. Its dependency AI-6 (#28) got PM APPROVE and is Ready to merge. This task still waits for the **merge**.
- 2026-11-08 (ai-engineer, build): branch `agent/ai/AI-6b` @ `b39fa04` (from `origin/main` `d3f9408`), pushed. PR not opened (orchestrator opens it).
  Diff: `rag.go` +88/−2, `rag_test.go` +90/−0 (178 insertions, 2 deletions; `ownership-check.sh`: OK, 180 changed lines).
  Built: §1 types and errors, plus §5 `parseSynthesis` after `buildSynthesisPrompt`. Imports `encoding/json`, `errors`, `io` (`io.EOF` for the trailing-data check).
  The regexp is widened (nit 5). The `selectContext` skip condition gains `norm == "" ||` (1 changed line), and one doc-comment line was added.
  The only changed `rag.go` lines are `blockTagRegex` and the skip condition. The import block is additions only.
  Local runs: Go 1.24.7 scratch module with stub `internal/db` and pgx (never committed) and the real `rag.go`, `rag_test.go`, `search.go`, `search_test.go`, `client.go`.
  `go vet` clean, `gofmt -l` empty, `go test` ok. Per-file coverage: `rag.go` 98.7% (229/232 statements), `parseSynthesis` 100%. All 7 AC8 mutations killed.
  CI is the source of truth.
  Interpretation choices (flag to QA):
  1. **AC5(b)** says "a duplicate, then an oversize hit, with nothing taken yet". That can't happen: dedup keys (`ids`, `contents`) are only recorded for *taken* passages.
     So the skipped hits ahead of the oversize one are an empty hit and a whitespace-only hit. The second also has the same collapsed content.
     The check sits in `TestSelectContextOversizeTopPassage` (appended block), not as a `TestSelectContext` row, because that table's assertion loop requires `!Truncated`.
  2. Dedup runs before the range check (design §5 order), so `[9, 9]` counts as 1 dropped marker.
  3. A top-level JSON `null` or a non-object is `errSynthesisMalformed`, because the input must start with `{`.
     A missing `claims`, `"claims": null` or `"claims": []` gives `errSynthesisNoClaims`.
  4. Claim text is trimmed only, not whitespace-collapsed (per the design). So `"X [2] y"` becomes `"X  y"`; QA-8's rendering can collapse it if needed.
  5. AC4: the delimiter look-alike cases are a loop appended inside `TestBuildSynthesisPromptInjection`, which was not a table. The token bound gets a look-alike check appended to `TestPassageTokensBoundsRenderedBlock`.
  Jira KAN-52 not moved by me: no Jira tool in this session, so the orchestrator should move it.
