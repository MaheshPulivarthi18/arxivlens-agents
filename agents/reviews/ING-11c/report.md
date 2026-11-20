<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/issues/comments/7031311622 (qa-reviewer's harness could not write report.md), 2026-11-20. -->

[qa-reviewer] QA report — ING-11c · PR #78 · round 1

**Verdict:** PASS
**Reviewed commit:** `1f24fc9` (merge ref `1ca5d73` = 1f24fc9 into main `e6cffba`) · **Date:** 2026-11-20
**Ticket:** `agents/tasks/ING-11c.md` · **PRD:** Product PRD QA-3 (citations with page); Technical PRD §5; ING-11b QA finding 4
**Evidence folder (pinned):** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence
_Provenance: the QA harness refused to write `report.md`; this comment is the full report, for the orchestrator to save verbatim._

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI 136098760680 | pass ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/00-ci-checks.png)) |
| Python M0 unit tests | CI 136098760693 | pass |
| Frontend (lint, test, build) | CI 136098760656 | pass |
| Agent ownership check | CI 136098760465 | pass; also local: `Ownership OK for role=ai (4 changed lines)` ([05](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/05-ac4-ownership.png ``)) |
| DB (migrate twice, HNSW plan + recall) | CI 136098760453 | pass |
| Full stack (compose + make test-full) | CI job 136098759408, run 44679351931 | pass; AC4 step `243 passed, 1 skipped, 3 deselected`; F1 step `1 failed, 2 passed` (documented F1, continue-on-error) ([06](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/06-ac3-stack-passed.png)) ``` |
| Ticket verification: ruff, ownership, numstat | local (ruff 0.16.9) | see AC4 |
| AC1/AC2 harness | local scratch (stubbed psycopg, real test function from `e6cffba` and `1f24fc9`) | [01](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/01-ac1-ac2-harness.png ````), sources [07](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/07-harness-source.png `````) |
| `make test-unit` / `make lint` | not run locally: sandbox lacks Go 1.25 / torch; the CI Go + Python jobs above are green | — |
| `make eval` | not run: test-message-only change, no retrieval/answering code touched | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | [01](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/01-ac1-ac2-harness.png ``````): after, row `page_number None (ps=3)` → `2401.1v1 chunk 0: page row but NULL page_number` (no `<` message); row `page_start<page_number (1<2)` → `2401.1v1 chunk 0: page_start 1 < page_number 2`. Before shows the old `page_start 3 < page_number None`. |
| AC2 | ✅ | [01](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/01-ac1-ac2-harness.png ```````): the five named rows, plus three extra (NULL page_number with a decreasing successor, NULL page_number on the earlier chunk, empty result), get the same verdict before and after: FAIL on the first four named rows, PASS on "all good" (`verdict column identical … True`). The monotonic check still fires next to the new message in both combined rows, and `prev` is still updated after a NULL page_number row. The harness can tell the versions apart: 4 single-edit mutants of the new branch (`continue` after the new append, `elif`→`if`, drop the NULL message, reword it) each change the output ([02](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/02-harness-mutants.png)). ```````` |
| AC3 | ✅ | `stack.yml` ran on the PR (`tests/**` is in its paths). Job 136098759408 (run 44679351931), `head_sha 1f24fc9…`, checkout `HEAD is now at 1ca5d73 Merge 1f24fc9… into e6cffba…`. Log line 3252: `PASSED tests/test_m2_pipeline.py::test_embedded_chunks_have_recorded_start_pages`; line 3300: `243 passed, 1 skipped, 3 deselected`. The log's only FAILED line is the F1 step's `tests/test_m3_query.py::test_rag_early_refusal_on_unrelated_query - ReadTimeout` (documented F1); job conclusion success ([06](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/06-ac3-stack-passed.png)). ````````` |
| AC4 | ✅ | [03](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/03-ac4-diff-scope.png ``````````): `3 1 tests/test_m2_pipeline.py` is the only file (4 changed lines). [04](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/04-ac4-ruff.png ```````````): ruff reports `2:8 F401` and `57:1 W293` on head, the same on base `e6cffba`; nothing on lines 94–97. [05](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/05-ac4-ownership.png ````````````): `Ownership OK for role=ai (4 changed lines)`, rc=0. |
| Docs | ✅ | none required; none changed. |

Scope: the change stays inside `test_embedded_chunks_have_recorded_start_pages`. The SQL, the `no paper_chunk_pages row` branch, the monotonic check and the final assert are untouched. `tests/` is ai-owned, and no ticket, review or doc files are in the PR. No other open PR touches `tests/test_m2_pipeline.py` ([08](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7e1d4407e10896c1b847008439243eb9f5dbbb79/agents/reviews/ING-11c/evidence/08-open-pr-overlap.png)). `````````````

## PRD fit
This serves QA-3 / Technical PRD §5 indirectly. The stack guard on recorded chunk start pages (which page citations need) now reports a NULL `page_number` as a missing value, not as a misleading ordering failure, and it catches exactly what it caught before.

## Findings
No blocking findings.
1. [nit] Two older ruff findings remain in this file (`2:8 F401 pytest unused`, `57:1 W293`). They are on lines this ticket doesn't touch, so they're out of scope; they could go into the next change to this file.

## Missing tests
- None required by the ticket. No committed test covers the new message (in CI the stack test only runs the passing path). The ticket asks for a scratch-only harness instead, and QA rebuilt it independently (01, 02, 07).

## Hand-off
PASS → pm-lead final review


---
_Generated by [Claude Code](https://claude.ai/code)_
