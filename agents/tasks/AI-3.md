# AI-3: Batch embedding calls in RAG citation validation

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 |
| **PRD ref** | Technical PRD §11 "Batch embedding in RAG validation"; Product PRD §8 `/v1/ask` p95 < 3 s |
| **Depends on** | AI-1 (tests lock behaviour), AI-2 (same code block; avoids merge conflicts) |
| **Jira** | find with JQL `labels = "task-AI-3"` |
| **Design required** | no (P1, internal to `rag.go`, response shape unchanged) |
| **Status** | Ready (AI-1 merged `4702daa`, AI-2 merged `9c1229a`) |

## Goal
`Ask` in `internal/query/rag.go` calls `EmbedTexts` once per hit (chunk) and once per cited sentence, which makes K + S
sequential HTTP round-trips to the embedder API. `EmbedTexts` already accepts a slice. Making one call for all chunks
and one call for all distinct cited sentences cuts `/v1/ask` latency, and QA-8 will produce more sentences.

## Scope
- `internal/query/rag.go` `validateCitations` (at `9c1229a`: per-hit chunk loop `rag.go:152-161`, per-citation sentence call `rag.go:185`): at most 2 `EmbedTexts` calls per `Ask` (chunks, then deduplicated cleaned sentences). Keep the results in input order. Keep AI-2's fail-closed behaviour: if a batch call fails, or returns a different number of vectors than inputs, every citation that depends on it is unsupported with score 0.
- The `citation support unverified` log line (`rag.go:211-213`) keeps its fields and meaning: `chunks_without_vector` counts hits, `sentence_embed_errors` counts citations whose sentence vector failed (so one failed sentence batch with 2 citations logs `sentence_embed_errors=2`). Splitting these counters is a separate Backlog item; don't do it here.
- `internal/query/rag_test.go`: a fake embedder that counts calls. Assert ≤ 2 calls for an answer with 3 hits and 2 cited sentences. Assert that labels and scores equal the per-item results from the existing tests.
- Out of scope: changing thresholds, the response shape, or the embedder API's batch size (32 on the Python side).

## Acceptance criteria
- [ ] AC1 — The call-count test passes (≤ 2 `EmbedTexts` calls per `Ask`).
- [ ] AC2 — All existing AI-1/AI-2 tests pass unchanged (no test edited to fit the new code).
- [ ] AC3 — `make eval`: supported-citation rate unchanged (±0.01) and `/v1/ask` p50/p95 before/after pasted, or "not run: infra unavailable" plus the exact command.
- [ ] AC4 — Fail-closed batch tests: (a) the chunk batch call errors → every citation unsupported, score 0; (b) the sentence batch call errors → same; (c) a batch returns fewer vectors than inputs → affected citations unsupported, no panic. Each asserts the call count too.
- [ ] AC5 — Mutation check (QA): reverting to one `EmbedTexts` call per hit makes the call-count test fail.
- PRD: the Technical PRD lives in arxivlens-agents now, so the developer does **not** edit it. Put the PR number in this task's Notes; pm-lead marks the §11 row "Batch embedding in RAG validation" (`docs/PRD-Technical.md:385`) done in the next docs PR.

## Verification
```bash
go vet ./... && test -z "$(gofmt -l .)"
go test -race -count=1 -run 'Validate|Citation|Ask|Embed' -v ./internal/query/
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go   # paste the rag.go rows
make test-unit
make lint
make eval   # when infra is available
```

## Notes
- Specced by pm-lead in PM-1 from the board Backlog item "Batch embedding in RAG validation".
- 2026-11-03 14:00 cycle (pm-lead): picked over AI-4 (P1 > P2; both change `rag.go`/`rag_test.go`, so only one at a time). AI-4 rebases on this after merge. Old AC4 (edit the Technical PRD in the app PR) was stale since the repo split; replaced. CI is the source of truth for Go (sandbox Go 1.24.7); a stdlib-only scratch run is extra evidence only.
