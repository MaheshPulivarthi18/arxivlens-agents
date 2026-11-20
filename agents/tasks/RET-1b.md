# RET-1b: rerank fallback covers `context.Canceled` (test) and ±Inf scores (fallback, like NaN)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 |
| **PRD ref** | Product PRD QA-1/QA-2; Technical PRD §7.1 (rerank fallback); ADR-0010 (Accepted); follow-up from RET-1 QA "Missing tests" + PM nits 1–2 (`agents/reviews/RET-1/report.md`) |
| **Depends on** | RET-1 (#9, merged `bb9ee90`). No open PR touches `internal/query/search.go` or `search_test.go` (re-checked 2026-11-20 04:00Z; #65 changes `rag.go`/`rag_test.go` in the same package, different files) |
| **Jira** | KAN-78 (epic KAN-2 "Retrieval & answer quality gates"; labels `task-RET-1b`, `agent-backend`, `arxivlens`) |
| **Design required** | no: one more fallback condition on an existing branch plus test rows; HTTP response shape unchanged |
| **Status** | Ready |

## Goal
`rerankAndSort` falls back to RRF order when the reranker errors, times out, is cancelled, returns the wrong count or a NaN. Two
gaps remain: the `rerank canceled` reason has no test, and a `±Inf` score is accepted, stored in `RerankScore` and sent to
`/v1/search`, where `encoding/json` can't encode it (`json: unsupported value: +Inf`). `server.go` ignores the `Encode` error after
the 200 header, so the client gets a truncated body. Treat ±Inf like NaN.

## Scope
- Files expected to change (and only these): `internal/query/search.go` (`rerankAndSort` default branch, `search.go:239-245` on
  `4c7d327`, and the doc comment at `search.go:215-217`), `internal/query/search_test.go` (new rows in `TestHybridSearchRerankFallback`;
  existing rows unmodified).
- Rule to implement: in the score loop, NaN keeps reason `"NaN score"`; `math.IsInf(float64(sc), 0)` (either sign) → reason
  `"Inf score"`. Same fallback as today: RRF order, `RerankScore` 0, one `rerank fallback` log line with the trace ID, no error.
- Out of scope: `rag.go` (owned by ai-engineer, open in #65), `server.go` (the ignored `Encode` error is a separate, wider issue; not
  reachable from rerank once this lands), the reranker service, ADR text.

## Acceptance criteria
- [ ] AC1: New `TestHybridSearchRerankFallback` row `canceled`: `err = fmt.Errorf("wrapped: %w", context.Canceled)` →
  `reason="rerank canceled"`, RRF top 5 (`[1 2 3 4 5]`), every `RerankScore` 0, no error, log passes the existing leak/trace checks.
- [ ] AC2: New rows `+Inf score` and `-Inf score` (the score at rank 3 is `float32(math.Inf(±1))`, others finite) →
  `reason="Inf score"`, same RRF/zero/log assertions as the NaN row.
- [ ] AC3: In every row of the table (old and new), `json.Marshal(hits)` returns no error (one added assertion in the shared row body;
  existing row data unchanged).
- [ ] AC4: Existing tests in `internal/query/` pass unmodified apart from AC3's one added assertion:
  `git diff origin/main -- internal/query/search_test.go` shows only added lines.
- [ ] AC5: Mutation, one per operand (QA applies each to `search.go`, runs `go test -count=1 -run HybridSearchRerank ./internal/query/`,
  shows a named row failing): (a) remove the Inf check → `+Inf score` row fails; (b) `math.IsInf(x, 1)` only → `-Inf score` row fails;
  (c) remove the `context.Canceled` case → `canceled` row fails (reason becomes `rerank error`); (d) give Inf the reason `"NaN score"`
  → both Inf rows fail.
- [ ] AC6: CI `ci.yml` job `Go (vet, gofmt, test, build)` green (`make test-go` prints `ok` for `internal/query`; quote run ID).
  `make lint-go` clean. Ownership check passes for role=backend. `stack.yml` (triggered by `internal/**`) concludes success, or any
  failure is shown to fail identically on a main-based run. A local or scratch `go test -v -run TestHybridSearchRerankFallback
  ./internal/query/` listing the 8 sub-tests as PASS is the AC1/AC2 evidence (CI's `make test-go` has no `-v`); say if not run.
- [ ] Docs: the `rerankAndSort` doc comment says "a NaN or ±Inf score". Technical PRD §7.1 diagram note (`PRD-Technical.md:243`,
  "wrong score count or NaN") is pm-lead's to update in the next docs PR (Backlog line added); no README change.

## Verification
```bash
gofmt -l internal/query/ && go vet ./internal/query/
go test -race -count=1 -v -run 'TestHybridSearchRerank' ./internal/query/
go test -count=1 ./internal/query/
.github/scripts/ownership-check.sh origin/main agent/backend/RET-1b
git diff --stat origin/main && git diff --numstat origin/main
```
Agent sandboxes may lack Go 1.25 (AGENTS.md §6): "not run locally" is fine; CI's Go job is the source of truth. QA runs the AC5
mutants in a scratch checkout if Go 1.25 is available, else on a throwaway branch's CI (say which). `make eval`: not run: a
reranker returning ±Inf doesn't occur on the eval stack (scores are finite), so ranking on real data is unchanged.

## Notes
- 2026-11-20 04:00Z (pm-lead): specced from the Backlog line "backend nits from the RET-1 review (fold into the next `search.go`
  change): `context.Canceled` fallback test case, `±Inf` score test". Verified on `4c7d327`: `search.go:232` has the
  `rerank canceled` case with no test row (`search_test.go:198-202` has error/timeout/count/NaN only); the loop at `search.go:240`
  checks `math.IsNaN` only. **Decision (pm-lead):** the RET-1 review asked to *pin* the ±Inf behaviour; pinning "accepted, sorts
  first/last" would pin a broken `/v1/search` body (`RerankScore` is `json:"rerank_score,omitempty"`, `search.go:44`, and
  `server.go:119` discards the `Encode` error), so ±Inf falls back like NaN, which is what ADR-0010's fallback is for (an invalid
  score). Mahesh can override on the PR.
- Independent of every open PR: #65 (`internal/query/rag.go`, `rag_test.go`, `tests/test_evals_data.py`, `README.md`; same Go
  package, no shared file or helper: `search_test.go` helpers `newEngine`, `fakeReranker`, `byRank`, `ids` are defined in search
  tests), #66 (workflows, CONTRIBUTING, compose), #68–#70 (`frontend/**`), #71 (`ci.yml`, `.github/scripts/`), #72 (`internal/kafka/`),
  #73 (`services/embedder/`, `tests/test_verify.py`), and of LLM-1c (`internal/llm/`) groomed in the same cycle.
