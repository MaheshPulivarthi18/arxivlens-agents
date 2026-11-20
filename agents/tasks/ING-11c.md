# ING-11c: M2 start-page test names a NULL `page_number` on its own (test message only)

| | |
|---|---|
| **Owner** | ai-engineer (ai owns `tests/`; the Backlog line said backend, which already has OPS-H6c and LLM-1d this cycle) |
| **Priority** | P3 |
| **PRD ref** | Product PRD QA-3 (citations with page); Technical PRD §5; follow-up from ING-11b QA finding 4 (`agents/reviews/ING-11b/report.md`) |
| **Depends on** | ING-11b (#52, merged `343a1c3`). No open PR touches `tests/test_m2_pipeline.py` (checked 2026-11-20 05:00Z against #65, #66, #68, #69, #70 via REST) |
| **Jira** | KAN-81 |
| **Design required** | no: one assertion message in a stack-only test |
| **Status** | **Done**: merged by Mahesh, ArxivLens [#78](https://github.com/MaheshPulivarthi18/ArxivLens/pull/78) → `cee2543` (2026-11-20) |

## Goal
`test_embedded_chunks_have_recorded_start_pages` (`tests/test_m2_pipeline.py:67`) lumps two different failures into one message. A
chunk whose `paper_chunk_pages` row exists while its `paper_chunks.page_number` is NULL is reported as
`page_start N < page_number None`, which reads as an ordering bug instead of a missing value. Report it as its own problem, so a
failing `stack.yml` run says what's wrong.

## Scope
- File expected to change (and only this one): `tests/test_m2_pipeline.py`, inside `test_embedded_chunks_have_recorded_start_pages`
  (lines 94–95 on `e6cffba`).
- Rule: if `page_number is None`, append `f"{key}: page row but NULL page_number"` (exact wording) and don't compare. Otherwise keep
  the existing `page_start {page_start} < page_number {page_number}` check unchanged. The monotonic `previous chunk's` check still runs
  for both cases (its behaviour must not change). The SQL, the `no paper_chunk_pages row` branch and the final assert stay as they are.
- Out of scope: what the test asserts (it must fail in exactly the same situations as before, so nothing gets loosened), and any
  other test.

## Acceptance criteria
- [ ] AC1: For an input row with `page_start = 3`, `page_number = None`, the problem list contains `"<id>v<ver> chunk <i>: page row but
  NULL page_number"`, and not the `<` message. For `page_start = 1`, `page_number = 2`, it still contains
  `"…: page_start 1 < page_number 2"`. Show this without a database: QA (or the developer, in Notes) runs the loop on hand-made rows. For
  example, extract the loop body into a scratch script or monkeypatch `psycopg.connect` with a fake cursor in a scratch-only test,
  **not committed**, and pastes the output.
- [ ] AC2: Same pass/fail set as before: for the rows `(None page_start)`, `(page_number None)`, `(page_start < page_number)`,
  `(decreasing page_start)` and `(all good)`, the test fails on exactly the first four, as on `e6cffba` (the AC1 harness, before vs after).
- [ ] AC3: `stack.yml` runs on the PR (`tests/**` path). Its `AC4: make test-full` step (`-rA`) lists
  `PASSED tests/test_m2_pipeline.py::test_embedded_chunks_have_recorded_start_pages`, and the run is green apart from the documented F1 step.
  Quote the run ID and the line.
- [ ] AC4: The diff touches only `tests/test_m2_pipeline.py` (< 10 changed lines). `ruff` reports no findings on changed lines. The
  ownership check passes for role=ai.
- [ ] Docs: none.

## Verification
```bash
ruff check --isolated --select E,F,W --line-length 130 tests/test_m2_pipeline.py   # no findings on changed lines
.github/scripts/ownership-check.sh origin/main agent/ai/ING-11c
git diff --stat origin/main && git diff --numstat origin/main
gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/<stack_job_id>/logs | grep 'test_embedded_chunks_have_recorded_start_pages'
```
The test needs the full stack (`make test-full`), so it doesn't run locally in agent sandboxes. `stack.yml` is the source of truth for
AC3, and the AC1/AC2 harness is a scratch script. `make eval`: not run, because nothing in retrieval or answering changes.

## Notes
- 2026-11-20 05:00Z (pm-lead): specced from the Backlog line "From ING-11b QA finding 4 (backend, P3, fold into the next
  `tests/test_m2_pipeline.py` change) …". No other change to that file is planned, so it gets its own small ticket now. Checked on
  app `origin/main` `e6cffba`: `test_m2_pipeline.py:94` is still `if page_number is None or page_start < page_number:`.
- Independent of every open PR and of OPS-H6c, AI-12b and LLM-1d (different files).
- 2026-11-20 (ai-engineer): built on `agent/ai/ING-11c` @ `1f24fc9` (from `e6cffba`). Diff: `tests/test_m2_pipeline.py` only, `3	1`
  (numstat). `if page_number is None: append("…: page row but NULL page_number")` / `elif page_start < page_number:` keeps the old
  message; the monotonic check still runs after both branches. `py_compile` OK. Ownership: `Ownership OK for role=ai (4 changed lines)`.
  ruff (`--select E,F,W --line-length 130`): 2 findings, both pre-existing and also on `origin/main` (`2:8 F401 pytest unused`,
  `57:1 W293`). None on changed lines 94–97.
  AC1/AC2 harness (scratch only, not committed): fake `psycopg.connect`/cursor, the test function run on `origin/main` vs branch:
  ```
  == before.py
    None page_start          FAIL  1 of 1 chunks: 2401.1v1 chunk 0: no paper_chunk_pages row
    page_number None         FAIL  1 of 1 chunks: 2401.1v1 chunk 0: page_start 3 < page_number None
    page_start<page_number   FAIL  1 of 1 chunks: 2401.1v1 chunk 0: page_start 1 < page_number 2
    decreasing page_start    FAIL  1 of 2 chunks: 2401.1v1 chunk 1: page_start 2 < previous chunk's 4
    NULL page_number + decreasing FAIL  2 of 2 chunks: …chunk 1: page_start 2 < page_number None; …chunk 1: page_start 2 < previous chunk's 4
    all good                 PASS
  == after.py
    None page_start          FAIL  1 of 1 chunks: 2401.1v1 chunk 0: no paper_chunk_pages row
    page_number None         FAIL  1 of 1 chunks: 2401.1v1 chunk 0: page row but NULL page_number
    page_start<page_number   FAIL  1 of 1 chunks: 2401.1v1 chunk 0: page_start 1 < page_number 2
    decreasing page_start    FAIL  1 of 2 chunks: 2401.1v1 chunk 1: page_start 2 < previous chunk's 4
    NULL page_number + decreasing FAIL  2 of 2 chunks: …chunk 1: page row but NULL page_number; …chunk 1: page_start 2 < previous chunk's 4
    all good                 PASS
  ```
  Same pass/fail set before and after (AC2), the new message replaces the `<` one only for the NULL case (AC1), and the monotonic
  check still fires alongside it. AC3 is pending: `stack.yml` runs on the PR, so it needs the run ID once the PR is open. `make eval`
  not run: nothing in retrieval or answering changes.
- 2026-11-20 (qa-reviewer): round 1 **PASS** at `1f24fc9`. Same pass/fail set before and after, 4/4 harness mutants detected, `stack.yml` names the test PASSED, CI 6/6 green, 1 nit. See `agents/reviews/ING-11c/report.md`.
- 2026-11-20 08:00Z (pm-lead): round 1 **APPROVE** (first posted in the PR #78 body by the interrupted 05:00Z cycle; recorded in `agents/reviews/ING-11c/report.md` now). Opened every evidence file 00–08. PR #78 was already ready for review with `ready-to-merge`; its evidence URLs are pinned to `7e1d440` (byte-identical blobs), so I left the PR as is.
  - **Follow-up (for the board Backlog; the PR body says it is there, but it wasn't):** ai, P3, fold into the next change to `tests/test_m2_pipeline.py`: fix the 2 pre-existing ruff findings (`2:8 F401` unused `pytest`, `57:1 W293` whitespace on a blank line). Handed to the orchestrator to add to `agents/board.md`.
  - Resolved 08:05Z: the board Backlog line was added by commit `05fc0ac` (the 05:00Z cycle's late record), so PR #78's follow-up claim now holds. No orchestrator action needed.
- 2026-11-20 13:00Z (pm-lead, sync): merged (#78 `cee2543`); Status → Done.
