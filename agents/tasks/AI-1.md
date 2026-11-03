# AI-1: Unit tests for `rag.go` filtering and citation validation (no infra)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 (safety net before QA-8 rewrites synthesis) |
| **PRD ref** | QA-3, QA-4, QA-5, QA-6; Technical PRD §7.2 |
| **Depends on** | — |
| **Status** | Ready to merge (PR #10, QA PASS r1 · PM APPROVE r1) |

## Goal
`internal/query/rag.go` holds the product's core promise (grounded, validated citations; honest refusal) and has zero
Go tests. Lock its behaviour down before QA-8 replaces the template with an LLM.

## Scope
- `internal/query/rag.go`: introduce two small interfaces in this file, e.g. `searcher` (the `SearchEngine` methods `Ask` uses)
  and `embedder` (`EmbedTexts`). `NewRAGService` keeps its current signature (concrete types satisfy the interfaces), so callers don't change.
- New `internal/query/rag_test.go` with fakes. Table-driven tests for:
  - relevance cutoff (rerank < 0.45 dropped), auxiliary-section cutoff (appendix/supplementary/table < 0.70 dropped)
  - refusal when nothing passes
  - marker extraction: `[n]` with n outside `1..K` is discarded; multiple markers per sentence
  - support labelling at `SupportThreshold` boundary (0.49 → unsupported, 0.50 → supported)
  - `splitIntoSentences` edge cases (abbreviations like "e.g.", "et al.", decimals)
  - `cosineSimilarity` with zero vectors (no NaN)
- Out of scope: changing thresholds or behaviour. If a test exposes a bug, fix it only if the fix is ≤ 20 lines and note it; otherwise write the failing case as `t.Skip("bug: ...")` and request a follow-up task.

## Acceptance criteria
- [x] AC1 — `go test ./internal/query/...` passes with no network, no DB, no embedder.
- [x] AC2 — Every bullet above has at least one test case; coverage of `rag.go` ≥ 80% (`go test -cover`, paste number).
- [x] AC3 — No public API or HTTP response shape changed.
- [x] AC4 — Any bug found is listed in Notes with its test name.

## Verification
```bash
go vet ./... && gofmt -l internal/query
go test -cover ./internal/query/...
make test-unit
```

## Notes
- 2026-11-03 (ai-engineer) Built on `agent/ai/AI-1` (from origin/main a959d03); not committed, orchestrator opens the draft PR.
  - **rag.go**: added `searcher` (`HybridSearch`, same signature as `*SearchEngine`) and `embedder` (`EmbedTexts`, same as `*EmbedClient`) interfaces; `RAGService` fields now use them; `NewRAGService(*SearchEngine, *EmbedClient)` unchanged. Moved the filter loop verbatim into `filterRelevantHits(hits)` and marker extraction/support labelling into `(*RAGService).validateCitations(ctx, answer, hits)`. This was needed because the templated answer only ever emits `[1]`/`[2]`, so out-of-range and multi-marker cases can't be reached through `Ask`. `markerRegex` is now a package var (same pattern). No threshold, constant, route or JSON tag changed. `search.go` not touched.
  - **rag_test.go** (new, stdlib-only fakes): `TestFilterRelevantHits`, `TestAskRefusesWhenNothingPasses`, `TestAskAnswersWithValidatedCitations`, `TestValidateCitationsMarkers`, `TestValidateCitationsSupportThreshold` (0.49 / 0.4999 → unsupported, 0.50 → supported, plus a per-sentence case), `TestValidateCitationsFallbackWhenUnverifiable`, `TestSplitIntoSentences`, `TestCosineSimilarity` (zero/empty/mismatched → 0, never NaN), `TestAskResponseShapeAndConstructor` (AC3 JSON keys + constructor wiring).
  - **Local verification (not CI)**: local Go is 1.24.7 and go.mod needs 1.25, so `go test` on the real module can't run here. `gofmt -l internal/query` printed nothing. I ran a stdlib-only scratch copy (`/tmp/claude-0/ai1-scratch/query`, GOTOOLCHAIN=local, real rag.go/rag_test.go/client.go plus a `search.go` stub without the db import): `go vet` ok; `go test -race` ok with 9 tests and 46 subtests, no skips. **rag.go coverage 97.9% (94/96 statements)**; the 2 uncovered statements can't be reached (`len(m) < 2` with a capture-group regex; the whole-text fallback in `splitIntoSentences`). The package figure printed was 68.1% because it includes the untested client.go. I also compiled and ran with the real `search.go` from main and from RET-1 (#9) plus a stub `internal/db`; with RET-1's `search_test.go` added, all tests pass with no identifier clashes. **CI on the PR is the source of truth.** `make eval` not run (no infra). The splitter fix can change support scores only when a paper title or section name in the template contains one of these abbreviations.
  - **AC4 bugs found**:
    1. FIXED (17 added lines + 1 changed, within the ≤ 20-line policy): `splitIntoSentences` ended sentences at abbreviations, so `"Smith et al. [1] show gains."` was verified as `"show gains."` alone, and `"e.g."`, `"i.e."`, `"vs."`, `"Fig."` broke the same way (titles like "X vs. Y" in the template were affected too). Test: `TestSplitIntoSentences/{et_al._not_split,e.g._not_split,i.e._in_parens_not_split,vs._and_Fig._not_split}`. Before the fix, those 4 subtests failed on the original splitter. Known trade-off: a real sentence that ends in one of these abbreviations is now merged with the next sentence.
    2. Not fixed (behaviour pinned, follow-up already exists as AI-2): fail-open 0.75/supported when the embedder fails or a chunk has no vector. Test: `TestValidateCitationsFallbackWhenUnverifiable`. AI-2 must flip these expectations.
    3. Observation, no change (needs a pm-lead/ADR decision): a hit with `RerankScore == 0` (no rerank score, e.g. reranker down) bypasses the 0.45 relevance cutoff, so retrieval fails open, though an aux section with 0 is still dropped. Pinned in `TestFilterRelevantHits/zero_rerank_score_bypasses_relevance_cutoff`. Also, `EarlyRefusalThreshold` (RRF 0.015) is declared but never used. Suggest a follow-up ticket to decide both.
  - Diff: 405 insertions, 24 deletions (429 lines), slightly over the 400-line target. About 18 of those lines are code moved verbatim inside rag.go and counted twice; I chose not to compress the tests further.
- 2026-11-03 (pm-lead) PM APPROVE r1 ([report](../reviews/AI-1/report.md)); PR #10 raised (ready for review). Bug 3 (zero rerank score bypass + unused `EarlyRefusalThreshold`) → ADR-0011 (Proposed) + [AI-5](AI-5.md) (Blocked on ADR-0011).
