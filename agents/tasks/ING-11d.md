# ING-11d: Clear the two ruff findings in `tests/test_m2_pipeline.py`

| | |
|---|---|
| **Owner** | ai-engineer (ai owns `tests/`; same owner as ING-11c) |
| **Priority** | P3 (harness/quality) |
| **PRD ref** | Product PRD QA-3 (citations with page; the file's M2 tests); follow-up from the ING-11c QA/PM review (QA nit 1, board Backlog) |
| **Depends on** | ING-11c (#78, merged `cee2543`). No open PR touches `tests/test_m2_pipeline.py` (checked 2026-11-20 20:00Z against #91–#94) |
| **Jira** | KAN-102 (epic KAN-4 "Continuous ingestion", same as ING-11c/KAN-81; labels `task-ING-11d`, `agent-ai`, `arxivlens`) |
| **Design required** | no: two lint fixes in a test file, no behaviour change |
| **Status** | Ready to merge (PR #98, QA r1 PASS, PM APPROVE 2026-11-21) |

## Goal
`ruff check --isolated --select E,F,W --line-length 130 tests/test_m2_pipeline.py` reports 2 findings on `origin/main` `230f617`
(checked by pm-lead with ruff 0.16.9): `2:8 F401 'pytest' imported but unused` and `57:1 W293 blank line contains whitespace`.
Make the file lint-clean so later edits to it are judged against zero findings.

## Scope
- `tests/test_m2_pipeline.py` only: delete the unused `import pytest` (line 2) and strip the whitespace on line 57. Nothing else.
- Out of scope: any assertion, fixture or other test file; adding ruff to CI or the Makefile.
- Size: 2 changed lines.

## Acceptance criteria
- [ ] AC1 — `ruff check --isolated --select E,F,W --line-length 130 tests/test_m2_pipeline.py` prints `All checks passed!` (paste output; before: `Found 2 errors.`).
- [ ] AC2 — No other change: `git diff origin/main --stat` shows only `tests/test_m2_pipeline.py`, 2 deletions / 1 insertion or fewer; no assertion text changes. `grep -n "pytest\." tests/test_m2_pipeline.py` is empty (proves the import was unused: the three tests use no `pytest` fixtures, marks or `raises`).
- [ ] AC3 — `python -m py_compile tests/test_m2_pipeline.py` succeeds and `python -m pytest --collect-only -q tests/test_m2_pipeline.py` collects the same test count as `main` (collection may need the DB env; if it can't import `psycopg` in the sandbox, say "not run" and rely on AC4).
- [ ] AC4 — CI: `stack.yml` runs on the draft PR (its `pull_request` paths include `tests/**`) and is green; quote its `PASSED tests/test_m2_pipeline.py::…` lines (OPS-H12 prints one per test) with the run ID, same set as the latest green `stack.yml` run on another PR. Other required checks green.
- [ ] Docs: none.

## Verification
```bash
ruff check --isolated --select E,F,W --line-length 130 tests/test_m2_pipeline.py
python -m py_compile tests/test_m2_pipeline.py
git diff origin/main --stat
# CI (source of truth): stack.yml (Full stack) on the draft PR, plus the required checks
```

## Notes
- 2026-11-20 20:00Z (pm-lead): Backlog said "fold into the next `tests/test_m2_pipeline.py` change"; none is planned, ai-engineer has a free slot,
  and the stack run is the only cost. Re-checked both findings on `230f617` before speccing.
- 2026-11-21 (pm-lead): Final review APPROVE on head `03fa179`. PR #98 raised (description has the evidence, PRD ref corrected to QA-3), ready for review, label `ready-to-merge`. No new follow-ups (the F1 flake is already tracked on the board).
