# AI-2: Fail closed when citation support cannot be verified

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 (it inflates the gated supported-citation metric) |
| **PRD ref** | QA-4; Product PRD §7 "Say I don't know"; Product PRD §8 supported ≥ 90% |
| **Depends on** | AI-1 (test harness and fakes for `rag.go`; same file, so do it after AI-1 to avoid conflicts) |
| **Status** | Done (PR #11 merged by Mahesh as `9c1229a`, 2026-11-03) |

## Goal
In `internal/query/rag.go`, when the sentence embedding call fails or the cited chunk has no embedding, the citation is
labelled `supported = true` with `score = 0.75`
("Fallback if embedding service unavailable"). QA-4 requires every citation to be *verified*. An unverified citation
labelled supported breaks the core trust promise, and it inflates `supported_citation_rate` in `make eval`. Fail closed:
an unverified citation is never labelled supported.

## Scope
- `internal/query/rag.go`: in the support-check `else` branch, set `supported = false` and `score = 0`, and log the failure once per request (no secrets or passage text in the log). `SupportThreshold` stays as it is.
- `internal/query/rag_test.go`: add cases using AI-1's fake embedder for (a) a sentence-embed error, (b) a chunk-embed error, and (c) an empty vector result. All give `Supported == false` and `Score == 0`.
- Out of scope: a third "unknown/unverified" state. That would add a field to the `/v1/ask` response (a shared HTTP contract), so it needs an ADR. If you think it is needed, add a request in Notes; pm-lead will fold it into ADR-0003. Frontend changes are also out of scope.

## Acceptance criteria
- [ ] AC1 — No code path in `rag.go` sets `supported = true` without a computed cosine similarity ≥ `SupportThreshold` (`grep -n "supported = true" internal/query/rag.go` returns nothing, or only that comparison).
- [ ] AC2 — The three new test cases pass with no network, DB, or embedder.
- [ ] AC3 — The `/v1/ask` JSON shape is unchanged (same fields and types).
- [ ] AC4 — `make eval` before/after numbers pasted, or "not run: infra unavailable" plus the exact command. A drop in the supported rate is expected only if embed failures occurred. Explain any change.

## Verification
```bash
go vet ./... && gofmt -l internal/query
go test -cover ./internal/query/...
make test-unit
make lint
make eval   # when infra is available
```

## Notes
- Specced by pm-lead in PM-1 from EVAL-1 finding (c). AI-1 locks existing behaviour with tests and allows only small bug fixes (≤ 20 lines). The AI-2 code change is about 3 lines, but it is a separate task because failing closed is a product-behaviour decision (QA-4 trust promise, affects the gated supported-citation metric), not a bug fix found while testing.
- ~~Verified on main: `rag.go` lines ~146–154~~ (stale after AI-1/RET-1).
- 2026-11-03 (pm-lead): AI-1 merged (ArxivLens #10) → Ready. Re-checked on origin/main `bb9ee90`: the fail-open branch is `rag.go:182-184` (`score = 0.75 // Fallback if embedding service unavailable`, `supported = true`); the verified path is `rag.go:178-181` (`supported = score >= SupportThreshold`). So AC1's grep must return nothing after the change. **Existing test to flip:** AI-1 locked today's behaviour in `TestValidateCitationsFallbackWhenUnverifiable` (`rag_test.go:245`, asserts `Score == 0.75 && Supported`). Changing that test's expectation to `Score == 0 && !Supported` is the point of this ticket and is **not** weakening a test; extend it (rename if you like) with the empty-vector case so all three AC2 cases live there. Use AI-1's `fakeEmbedder` (`rag_test.go:28`: `err` field for the error case, `vec` returning nil for the missing-vector case). Run the Verification commands from inside `app/`. Local Go is 1.24.7 and Go 1.25 can't be downloaded, so CI on the draft PR is the source of truth for `go vet`/`go test`.
- 2026-11-03 (ai-engineer): Built on `agent/ai/AI-2` (from `bb9ee90`). `rag.go`: the fail-open `else` (score 0.75, supported) is gone. An unverifiable citation keeps its marker with `Score 0` and `Supported false`. An empty sentence vector now also counts as unverified. When any citation is unverified, `validateCitations` logs one line per request: trace id plus counts (unverified, citations, chunks without a vector, sentence embed errors), with no text. `rag_test.go`: `TestValidateCitationsFallbackWhenUnverifiable` is renamed to `TestValidateCitationsFailClosedWhenUnverifiable` and now expects `Score 0 && !Supported`. It has 7 cases: embedder down; sentence-embed error; chunk-embed error; sentence nil or empty vector; chunk nil or empty vector. Each case also asserts exactly one log line with no leaked text. A further check asserts that the verified path logs nothing. `fakeEmbedder` gained an optional `failOn` field. AC1 grep for `supported = true` returns nothing. `gofmt -l` is clean. A stdlib scratch module (Go 1.24.7, `search.go` types stubbed) passed `go vet` and all rag tests, with per-file coverage `validateCitations` 97.4%. The new test fails on the old `rag.go`. `make eval`: not run, because infra is unavailable (no Docker daemon, no query service on :8080). Command: `make eval`. Possible follow-up, no ADR needed: `Ask` doesn't put its `trace_id` into ctx, so this log line (like RET-1's rerank-fallback line) shows a generated id with `trace_id_source=generated` rather than the response's trace_id. A one-line `ctx = withTraceID(ctx, traceID)` in `Ask` would fix it; I left it out to keep scope.
- 2026-11-03 (pm-lead, PM review round 1 of PR #11): **APPROVE** on `c9ae07c` (`agents/reviews/AI-2/report.md`). PR raised for Mahesh. After merge, pm-lead opens a docs PR: QA-4 ◐→✅, drop the AI-2 caveat in §8, drop the Technical PRD §9 known-gap paragraph. Follow-ups: rag_test counters, a mixed case, dimension mismatch logged as unverified (backlog, ai-engineer P2, after AI-4); FE-1 note on the "Verified" badge text; all-unsupported-answer policy is input for ADR-0003.
