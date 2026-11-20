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

## PM decision — pm-lead, 2026-11-20 — round 1

**Verdict: APPROVE**

_Provenance: the interrupted 05:00Z cycle first posted this verdict in the PR #78 body (PR marked ready for review, label `ready-to-merge`) but never committed it here. This section records the PM final review, redone in full in cycle 08:00Z._

Reviewed: ticket `agents/tasks/ING-11c.md`; Product PRD QA-3 (✅, unchanged) and Technical PRD §5; the PR #78 diff at `1f24fc9` via REST (`tests/test_m2_pipeline.py` +3/-1, the only file); this QA report; every file in `evidence/` (00–08, `.png` and `.txt`).

- **PRD fit.** QA-3 page citations depend on recorded chunk start pages. When this stack guard fails, it now names a NULL `page_number` as a missing value (`page row but NULL page_number`) instead of a misleading ordering failure, so a red `stack.yml` run points at the right bug. It fails in exactly the same cases as before (nothing loosened). No PRD status column changes.
- **Scope.** As specced: the change is inside `test_embedded_chunks_have_recorded_start_pages`, with the exact wording, and the SQL, the `no paper_chunk_pages row` branch, the monotonic check and the final assert are untouched (03). 4 changed lines (< 10).
- **Evidence per AC.**
  - AC1: after, `page_number None (ps=3)` gives `…chunk 0: page row but NULL page_number` and no `<` message; `(1<2)` still gives `page_start 1 < page_number 2` (01).
  - AC2: the five named rows plus three extra get the same verdict before and after (`verdict column identical … True`, 01). The harness can tell versions apart: 4/4 single-edit mutants change the output (02), and the harness runs the real test function from both commits (07).
  - AC3: `stack.yml` job 136098759408 (run 44679351931) on head `1f24fc9`, log line 3252 `PASSED tests/test_m2_pipeline.py::test_embedded_chunks_have_recorded_start_pages`, `243 passed` (06). Its only FAILED line is the documented F1 step (`test_rag_early_refusal_on_unrelated_query` ReadTimeout, `1 failed, 2 passed`), which AC3 allows; job conclusion success.
  - AC4: `3 1`, one file (03); ruff findings only at the pre-existing 2:8 and 57:1, same on base (04); ownership OK for role=ai (05).
  - CI: 6/6 checks success on `1f24fc9` (00). No other open PR touches the file (08).
- **Every PNG shows its result** (LLM-1b lesson): 01 shows both verdict tables and the `True` line, 06 shows line 3252 and the totals.
- **PR body check.** Head is still `1f24fc9`; `draft: false`; labels `ready-to-merge`, `qa-pass`. All 9 evidence URLs are pinned to `7e1d440`. Files 01–05 were first added in `5027a51`, but `7e1d440` is a pushed descendant on `main` with byte-identical blobs for all 9 files, so the links are immutable and correct. Not re-pinned. The embeds show as backtick-wrapped links (known outbound filter, OPS-H8 lesson).
- **Records gap (fixed here, not a CHANGES item).** The PR body's "Follow-ups created" says the 2 pre-existing ruff findings in `tests/test_m2_pipeline.py` (`2:8 F401` unused `pytest`, `57:1 W293`) went to the Board Backlog, but `agents/board.md` has no such line (grep at 08:00Z). The follow-up is now recorded in the ticket Notes and handed to the orchestrator to add as a Backlog line (ai, P3, fold into the next change to that file), so the PR's claim becomes true. The code is unaffected.

Next: PR #78 stays raised (ready for review, `ready-to-merge`), waiting for Mahesh.

_Update 08:05Z (pm-lead): the "records gap" above is closed. Commit `05fc0ac` added the ruff follow-up to the board Backlog (ai, P3)._
