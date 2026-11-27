<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-27T03:59Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/127#issuecomment-7210307970 ; qa-reviewer's harness could not write report.md. -->

[qa-reviewer] QA report — OPS-H6f · PR #127 · round 1

**Verdict:** PASS
**Reviewed commit:** `b4b64b3d53b42fbf76c13ec013f09062a7f2edfd` · **Date:** 2026-11-27
**Ticket:** [`agents/tasks/OPS-H6f.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/tasks/OPS-H6f.md) · **PRD:** Product OPS-3; Technical §8.1 L3
**Evidence:** [`agents/reviews/OPS-H6f/evidence/`](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence) (commit `130f277`)

CI ran on `refs/pull/127/merge` = `f4f03fd`, which is b4b64b3 merged into current main `53171d6`. The PR is still a draft and not merged.

## Test results
| Check | Source | Result |
|---|---|---|
| Go / Python M0 / Frontend / Ownership / DB / Full stack | CI on b4b64b3 | all 6 pass |
| Full stack `-rA` | run 45940231278, job 140312624580 | `447 passed, 1 skipped, 3 deselected`. All 5 `tests/test_chunk_reprocess_db.py` tests `PASSED` (log lines 3130-3134) |
| Unit `test_processor_pages.py -k save_` | local, pymupdf/torch replaced by MagicMock modules | 18 passed |
| Real-DB module | local PG 16 + psycopg wire-protocol double + `halfvec` text-domain shim (no pgvector/psycopg in sandbox) | 5 passed; 20/20 under CPU load |
| ruff E,F,W/130 | local | 2 findings, identical on main; 0 added lines > 130 |
| `make eval` | not run: write-path locking only, no retrieval change | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | Lock at `db.py:98`, before the loop's DELETE. The unit test pins SQL, `(7,)`, position and `commits == 0`. M1/M2/M3/M7/M9 killed ([03](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/03-AC1-AC2-unit.png?raw=true), `` [05](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/05-AC8-mutants.png?raw=true)) ``` |
| AC2 | ✅ | Only 4 lines removed: 2 docstring lines and 2 re-indexed lines with the same tuple. No assertion dropped ([01](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/01-scope.png?raw=true ````)). 18 `save_` tests pass ([03](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/03-AC1-AC2-unit.png?raw=true), ````` [02](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/02-AC9-fullstack-rA.png?raw=true)) `````` |
| AC3 | ✅ | Neither test body is in the diff. Both `PASSED` in CI and locally ([04](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/04-AC3-AC6-real-pg-base-vs-head.png?raw=true)) ``````` |
| AC4 | ✅ | Passes on head. Base control (PR tests × `origin/main` db.py) fails exactly this test: `chunk 0: old-text vector kept under the new hash` ([04](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/04-AC3-AC6-real-pg-base-vs-head.png?raw=true)) ```````` |
| AC5 | ✅ | Stale item skipped, current one written (→ 1). M12 (drop `FOR SHARE OF pc`) fails it ([05](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/05-AC8-mutants.png?raw=true)) ````````` |
| AC6 | ✅ | Paper B shares `hash-a1`. M13 (hash-only lookup) fails it ([05](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/05-AC8-mutants.png?raw=true)) `````````` |
| AC7 | ✅ | 20/20 runs under load, counts `1/0/0` before and after. Test mutant T1 (cleanup dropped) trips `db_left_as_found`. NOWAIT/base runs end in about 10–21 s, no hang ([07](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/07-AC7-flake-and-fixture.png?raw=true)) ``````````` |
| AC8 | ✅ | 13/13 killed, fresh DB per mutant. M4 (no `ORDER BY`), M6 (`FOR NO KEY UPDATE`) and M8 (chunk 0 only) are killed only by the unit SQL pin ([05](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/05-AC8-mutants.png?raw=true)) ```````````` |
| AC9 | ✅ | [00](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/00-ci-checks.png?raw=true), ````````````` [02](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/02-AC9-fullstack-rA.png?raw=true), `````````````` [08](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/08-AC9-ruff.png?raw=true) ``````````````` |
| Docs | ✅ | Exactly the 3 expected files ([01](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/01-scope.png?raw=true ````````````````)) |

### Extra probes ([06](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/06-probes.png?raw=true `````````````````); harness [09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/130f27707e81350dd0e7d4726f074cacf1283bb7/agents/reviews/OPS-H6f/evidence/09-harness.txt))
| Probe | head | origin/main | M6 |
|---|---|---|---|
| P1: AC4 order, **3-tuple** save (the worker today) | no stale vector | stale on 0, 1 | stale on 0, 1 |
| P2: reverse order, 3-tuple | stale on 0 | stale on 0 | stale on 0 |
| P3: ascending interleave | no deadlock, no stale vector | stale on 0 | no stale vector |
| P4: E saving descending | `deadlock detected` | same | same |

## PRD fit
Yes. For the in-flight-embedder-then-processor ordering, OPS-3 no longer leaves an old-text vector, with both the 4-tuple and today's 3-tuple save. Everything stays inside the L2 transaction.

## Findings
1. [nit][test] M6 (`FOR NO KEY UPDATE`) and M8 (lock only chunk 0) survive every real-PG test; only the exact-SQL unit pin kills them. M6 reopens the AC4 race for the 3-tuple save the worker uses today (P1). A 3-tuple variant of the AC4 test would pin the lock strength by behaviour.
2. [spec] The reverse order with a 3-tuple save still leaves an old-text vector (P2). This is expected: AI-13 (worker → 4-tuple) closes it. Don't mark OPS-3 done until AI-13 merges.
3. [nit][code] The lock is deadlock-free only while the embedder saves in ascending `chunk_index` (P4 deadlocks; it does on main too, so no regression). AI-13 should keep the ASC order.

## Missing tests
- A real-PG AC4 variant with the 3-tuple save (finding 1).

## Hand-off
PASS → pm-lead final review. (The QA harness refused to write `report.md`; this comment is the full report, for the orchestrator to save verbatim.)


---
_Generated by [Claude Code](https://claude.ai/code)_
