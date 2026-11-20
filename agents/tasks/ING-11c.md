# ING-11c: M2 start-page test names a NULL `page_number` on its own (test message only)

| | |
|---|---|
| **Owner** | ai-engineer (ai owns `tests/`; the Backlog line said backend, which already has OPS-H6c and LLM-1d this cycle) |
| **Priority** | P3 |
| **PRD ref** | Product PRD QA-3 (citations with page); Technical PRD §5; follow-up from ING-11b QA finding 4 (`agents/reviews/ING-11b/report.md`) |
| **Depends on** | ING-11b (#52, merged `343a1c3`). No open PR touches `tests/test_m2_pipeline.py` (checked 2026-11-20 05:00Z against #65, #66, #68, #69, #70 via REST) |
| **Jira** | to create (same epic as ING-11b / KAN-59; labels `task-ING-11c`, `agent-ai`, `arxivlens`) |
| **Design required** | no: one assertion message in a stack-only test |
| **Status** | Ready |

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
