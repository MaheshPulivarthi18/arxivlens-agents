# AI-5: `/v1/ask` relevance bar when rerank scores are missing (implements ADR-0011)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 (QA-5 honest refusal; principle 2) |
| **PRD ref** | QA-5, QA-6; Product PRD §7 principle 2; Technical PRD §7.2 |
| **Depends on** | AI-1 (PR #10, test harness in `rag_test.go`), **ADR-0011 (Proposed, human decision)**; soft: RET-1 (#9) for the ADR-0010 fallback |
| **Jira** | `KAN-n` (find with JQL `labels = "task-AI-5"`) |
| **Design required** | no (small change in one file; the decision itself lives in ADR-0011) |
| **Status** | Blocked (needs ADR-0011) |

## Goal
During a reranker outage, every hit has `RerankScore == 0`, so it skips the 0.45 relevance cutoff and `/v1/ask` answers
from unchecked passages instead of refusing (found and pinned by AI-1). Make `/v1/ask` follow ADR-0011's decision so a
missing relevance score never counts as "relevant".

## Scope
Written for the **recommended Option 1**. If Mahesh picks another option, pm-lead re-specs this ticket before work starts.
- `internal/query/rag.go`:
  - In `Ask`, after `HybridSearch`: if there is ≥ 1 hit and **no** hit has `RerankScore > 0`, return the
    "relevance check unavailable" response: same `AskResponse` shape, `answer` = the exact text recorded in ADR-0011's
    Decision, `citations` = empty non-nil slice, `trace_id` set. Log one line with the trace ID (no question or passage text).
    Do not call the embedder.
  - In `filterRelevantHits`: a hit with `RerankScore <= 0` is dropped (it never passes the 0.45 bar).
  - Delete the unused `EarlyRefusalThreshold` constant (unexported use only; check with `grep -rn EarlyRefusalThreshold`
    across the app repo first; if anything outside `rag.go` references it, stop and note it).
- `internal/query/rag_test.go`: flip `TestFilterRelevantHits/zero_rerank_score_bypasses_relevance_cutoff` to expect a
  drop; add the cases in the ACs. Non-blocking extras from AI-1 QA (add them; they're cheap): `maxCitations < 0` → 5;
  `Ask` end to end with a failing embedder; pin current behaviour for a section title that merely *contains* "table"
  (e.g. `"Notable results"`), with a comment pointing to a follow-up, not a fix.
- `services/embedder/api.py`: **only if ADR-0011's Decision accepts removing the bi-encoder fallback.** `/internal/rerank`
  returns 503 when the cross-encoder isn't loaded, instead of dot products. Add a test under `tests/` that needs no model
  download (mock the model globals).
- Out of scope: changing 0.45 / 0.70 / `SupportThreshold`; RRF-based fallback (ADR-0011 Option 2); the substring
  `"table"` match fix; frontend changes; `search.go` (backend-owned).

## Acceptance criteria
- [ ] AC1 — `Ask` with hits whose `RerankScore` are all 0 returns `citations == []` (non-nil), the ADR-0011 text
      exactly, a trace ID, and makes no embedder call (test name in Notes).
- [ ] AC2 — `Ask` with a mix of scored (≥ 0.45) and 0-score hits cites only the scored ones; 0 and negative scores are
      dropped by `filterRelevantHits` (table-driven cases: 0, -0.1, 0.44, 0.45).
- [ ] AC3 — The normal refusal (all hits scored < 0.45) still returns the existing text "No indexed papers are relevant
      to this question." unchanged (existing `TestAskRefusesWhenNothingPasses` passes unmodified).
- [ ] AC4 — `/v1/ask` JSON shape unchanged: `TestAskResponseShapeAndConstructor` passes unmodified; no route, JSON tag or
      threshold value changes (`git diff origin/main -- internal/query/server.go evals/thresholds.json` empty).
- [ ] AC5 — `rag.go` per-file statement coverage stays ≥ 90%, measured as `go test -coverprofile=c.out ./internal/query/`
      then `go tool cover -func=c.out | grep rag.go` (paste the per-function rows and the file total). The package-wide
      `-cover` figure doesn't count.
- [ ] AC6 — `EarlyRefusalThreshold` no longer exists (`grep -rn EarlyRefusalThreshold` in the app repo returns nothing).
- [ ] AC7 — If the api.py part is in scope: `/internal/rerank` without a cross-encoder returns HTTP 503, covered by a
      no-download test; otherwise write "api.py: out of scope per ADR-0011" in Notes.
- [ ] AC8 — `make eval` before/after for the refusal and supported-citation rates, or "not run: <reason>" plus the exact
      command. No change is expected while the reranker is healthy.
- [ ] Docs: README unchanged unless the ADR adds user-facing text worth documenting; pm-lead updates Product PRD QA-5 to ✅ after merge.

## Verification
```bash
go vet ./... && gofmt -l internal/query
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go
grep -rn EarlyRefusalThreshold . || echo "none"
make test-unit
make lint
make eval   # when infra is available
```

## Notes
- 2026-11-03 (pm-lead) Specced from AI-1 QA finding 4 [spec] and the ticket's AC4 item 3. Blocked because the behaviour
  (refuse vs RRF fallback vs fail open) is a product trade-off and changes user-visible text, so it's ADR-0011, not a bug fix.
  `rag.go` is also touched by AI-2 and AI-3. Whichever starts second rebases; keep one open PR per agent.
