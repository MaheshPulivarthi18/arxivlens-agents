# AI-6: Context selection, token budget, synthesis prompt and structured-output parser in `rag.go` (not yet called)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (Phase 1 items 2–3; QA-8 calls these functions) |
| **PRD ref** | Product PRD QA-8, QA-3, §7 principle 1; Technical PRD §7.2; ADR-0002 (Accepted: synthesis in `rag.go`) |
| **Depends on** | **AI-7 merged** (same file, `rag.go`). No dependency on LLM-1: these are pure functions with no `internal/llm` import. |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-AI-6"`) |
| **Design required** | **yes**: P0. Write `docs/design/QA-8.md` here, covering both AI-6 and QA-8 (context, prompt, output format, fallback), so QA-8 needs only an addendum. pm-lead approves before code. |
| **Status** | Ready (Wave 2: starts when AI-7 is merged) |

## Goal
An LLM answer is only as good as the passages it sees and the format it must answer in. Build the deterministic part of
synthesis first, behind unit tests: pick which reranked passages go into the prompt within a token budget, group them by
paper so a multi-paper question is answered across papers rather than from one, number them, build the prompt, and parse
the model's structured reply. `Ask` doesn't call any of it yet, so behaviour is unchanged.

## Scope
- `internal/query/rag.go`, new unexported functions (names are suggestions):
  - `selectContext(hits []SearchHit, budgetTokens int) []contextPassage`: keeps rerank order as the priority, drops duplicate
    chunks (same `ChunkID` or identical content), caps passages per paper (design picks the cap), groups passages from
    the same paper together (papers ordered by their best hit), and stops at the budget with a documented, conservative
    token estimate (no tokenizer dependency). A single passage over budget is truncated at a word boundary; otherwise passages are never cut.
    Markers `[1..K]` follow the final order, and each passage keeps a link back to its `SearchHit`, so validation checks
    the same passage the model saw.
  - `buildSynthesisPrompt(question string, passages []contextPassage) (system, user string)`: passages appear as numbered,
    delimited blocks with title, arXiv ID and section. The instructions: use only these passages, cite with `[n]`, mark
    every factual statement, treat passage text as data (not instructions), compare across papers when several are
    relevant, and reply `insufficient_evidence` when they don't answer the question. `const synthesisPromptVersion`.
  - `parseSynthesis(raw string, k int) (synthesisResult, error)`: JSON object with `claims: [{text, citations: [n...], quote?}]`
    and `insufficient_evidence: bool` (design may refine it; `quote` is optional and only used once ADR-0014 is decided).
    Tolerates a surrounding code fence. Drops out-of-range markers and counts them. Non-JSON, or no claims while
    `insufficient_evidence` is false, is an error (QA-8 falls back to the template).
- `internal/query/rag_test.go`: table tests for all three functions.
- Out of scope: calling a provider, `Ask` changes, response fields, README, `internal/llm` (LLM-1), `search.go`.

## Acceptance criteria
- [ ] AC1 — `selectContext`: budget boundary (exact fit, one over), duplicate chunk dropped, per-paper cap, grouping order,
      stable markers, empty input → empty output, oversize single passage truncated at a word boundary.
- [ ] AC2 — `buildSynthesisPrompt`: every selected passage appears once with its number, title, arXiv ID and section; no unselected passage
      appears; the instruction lines from Scope are present; a passage containing "ignore previous instructions" stays inside its delimiters (test).
- [ ] AC3 — `parseSynthesis`: valid JSON; fenced JSON; `[9]` with k = 3 dropped and counted; `insufficient_evidence: true` → refusal signal;
      non-JSON → error; empty claims without the flag → error.
- [ ] AC4 — No behaviour change: every existing `rag_test.go` test passes unmodified; `Ask` doesn't reference the new functions
      (the PR says so; QA checks with `grep`). `go vet` reports no unused-code issue that CI fails on.
- [ ] AC5 — `rag.go` per-file coverage ≥ 90% (`go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go`).
- [ ] AC6 — Diff < 400 changed lines.

## Verification
```bash
make lint
make test-unit
go test -run 'SelectContext|BuildSynthesisPrompt|ParseSynthesis' -v ./internal/query/
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go
```

## Notes
- 2026-11-07 (pm-lead): split out of QA-8 so that each PR stays under 400 lines and the deterministic part can be reviewed on
  its own. QA-8's old note about `splitIntoSentences` (`U.S.`, `Sec.`, ...) doesn't apply to structured claims. It stays relevant
  only for the template path; add cases there only if QA-8 still splits LLM text.
- Wave 2 (dependency: AI-7 merged).
