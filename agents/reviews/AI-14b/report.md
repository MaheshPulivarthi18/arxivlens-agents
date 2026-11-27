<!-- Provenance: saved verbatim by the orchestrator from ArxivLens PR #129 comment 7214578329 (https://github.com/MaheshPulivarthi18/ArxivLens/pull/129#issuecomment-7214578329); the QA harness could not write this file. -->

[qa-reviewer] **QA report: AI-14b · PR #129 · round 1**

**Verdict:** PASS
**Reviewed commit:** `92f37ad147e5e3e8f6ef5d26b6ea987a48706926` · **Date:** 2026-11-27
**Ticket:** [agents/tasks/AI-14b.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/tasks/AI-14b.md) · **PRD:** Product QA-6, Technical §7.2 (aux cutoff 0.70)
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/59ebe98/agents/reviews/AI-14b/evidence
(`report.md` is saved to `agents/reviews/AI-14b/` by the orchestrator, because the QA harness refused to write the file.)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 140412961980 (merge ref `fe51ba6` = 92f37ad into main 53171d6) | pass: `make lint-go`, `make test-go` with `GOFLAGS=-race`, `ok arxivlens/internal/query` ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/00-ci-checks.png?raw=true), [04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/04-ac4-ci-go-ownership.png?raw=true)) |
| Python M0 unit tests | CI | pass |
| Frontend (lint, test, build) | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Full stack (compose + make test-full) | CI | pass (completed 09:19:15Z) |
| Agent ownership check | CI | pass: `Ownership OK for role=ai (3 changed lines)` ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/04-ac4-ci-go-ownership.png?raw=true)) |
| Ticket verification: `go test -run TestFilterRelevantHits -v` | local, QA scratch harness | 21/21 PASS incl. both new rows ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/02-ac1-ac2-filter-tests.png?raw=true)). The real package was not run locally because the sandbox has Go 1.24.7, `go.mod` needs 1.25, and toolchain downloads are blocked. The harness extracts `filterRelevantHits`, `tableWordRegex`, `isAuxiliarySection`, `SearchHit`, `hitContent`, `ragHit` and `TestFilterRelevantHits` verbatim from the PR head with `go/parser` ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/05-qa-harness.png?raw=true)) |
| `make lint-go` / `make test-go` | not run locally (Go 1.25 unavailable); CI pass | local `gofmt -l internal/query/` clean ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/01-ac1-ac2-diff.png?raw=true)) |
| `make eval` | not run: test-only change, `rag.go` is unchanged, so retrieval and answering behaviour can't move | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `rag_test.go:178-179` at 92f37ad: `"word starting with table kept: Tablet"` (`ragHit(1, "Tablet experiments", 0.5)` → `[]int64{1}`) and the matching `Tableau dashboards` row, named in the existing style, next to the AI-14 rows ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/01-ac1-ac2-diff.png?raw=true)). Both run and PASS ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/02-ac1-ac2-filter-tests.png?raw=true)) |
| AC2 | ✅ | `git diff --numstat origin/main...HEAD` = `3 0 internal/query/rag_test.go`, `removed lines: 0`, merge-base is main `53171d6` ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/01-ac1-ac2-diff.png?raw=true)). Whole package: CI `ok arxivlens/internal/query` under `-race` ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/04-ac4-ci-go-ownership.png?raw=true)) |
| AC3 | ✅ | QA ran the mutants on a copy of PR-head `rag.go:832` ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/03-ac3-mutants.png?raw=true)). Unmutated: 21 PASS. **m7** (right boundary dropped) fails exactly `word_starting_with_table_kept:_Tablet` and `..._Tableau` (`got [], want [1]`). **m6** (left boundary dropped) fails Notable/Stable/Suitable/Timetable, so the old rows still guard. Negative control: **m7 SURVIVES main's 53171d6 test file** and is killed only by the new rows. m6 is caught by both files |
| AC4 | ✅ | Head 92f37ad: `Go (vet, gofmt, test, build)` success (steps `make lint-go` and `make test-go`, `GOFLAGS: -race`) and `Agent ownership check` success. All 6 check runs are green ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/00-ci-checks.png?raw=true), [04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/04-ac4-ci-go-ownership.png?raw=true)) |
| Docs | ✅ | No behaviour change. The diff touches only `rag_test.go`, and `README.md`/`CONTRIBUTING.md` are untouched ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/59ebe98/agents/reviews/AI-14b/evidence/01-ac1-ac2-diff.png?raw=true)) |

**Scope:** one file, `internal/query/rag_test.go`, which ai-engineer owns (AGENTS.md §2). Nothing out of scope appears in the diff: no `rag.go` change, no cutoff change, no "Appendices" row. No ticket, review or doc files leaked into the PR. The design check doesn't apply (not design-required).

## PRD fit
QA-6 says only *auxiliary* sections (appendix, supplementary, table) should face the stricter 0.70 cutoff. These rows make sure an ordinary title that merely starts with "table" ("Tablet experiments", "Tableau dashboards") at rerank 0.5 still reaches `/v1/ask` evidence. That closes the AI-14 gap where QA mutant m7 survived. Contracts, thresholds and eval gates are unchanged.

## Findings
None blocking. No nits.

## Missing tests
Optional, not needed for this ticket:
- The right boundary is `[^\pL]`, so a digit counts as a boundary: `tableWordRegex` matches "Table2 results" (QA probe: `true`), so that title is treated as a table section. That's probably intended for "Table 2"-style captions, but no row pins it. A row would document the choice.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_
