# EVAL-10a: Pin errored cases in the `/v1/ask` summary ID lines (test-only)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P3 |
| **PRD ref** | Product PRD §8 (answer metrics: method notes); follow-up from the EVAL-10 PM review (QA "Missing tests", 2026-11-19) |
| **Depends on** | EVAL-10 (PR #61) **merged**. Same test file `tests/test_evals_data.py`, so don't start while another open PR changes it |
| **Jira** | KAN-85 |
| **Design required** | no: tests only, no behaviour change |
| **Status** | In QA (PR #82, draft) |

## Goal
EVAL-10 prints `refused IDs`, `miss IDs` and `near-miss answered IDs`. Its code handles errored calls correctly, but no test covers
errored calls. An answer-set error belongs in `expected_paper_miss_ids` but not in `answer_refused_ids`. A near-miss error belongs in
`near_miss_failure_ids`, as `evals/README.md` says ("errors included"). This task adds tests for those two rules so a later refactor
can't quietly break them.

## Scope
- `tests/test_evals_data.py` only: one new test (or one parametrized test) next to the EVAL-10 tests. Reuse `_eval10_run`-style fakes
  where the fake `ask` raises an error or returns a non-answer, non-refusal outcome. Use whichever path `gated_call` already maps to
  `outcome == "error"`.
- Out of scope: any change to `scripts/evaluate_answers.py`, including renaming the `near-miss answered IDs` label. The label is what
  EVAL-10 specified. A rename would be a separate ticket.

## Acceptance criteria
- [x] AC1: For a fake run with 1 answer-set case whose call errors, the results have that ID in `expected_paper_miss_ids` and in
  `error_case_ids`, but **not** in `answer_refused_ids`. The `print_report()` output shows the ID on the `miss IDs` line and not on the
  `refused IDs` line. Mutation: changing `if outcome == "refusal":` to `if outcome != "answered":` in `evaluate()` makes the test fail.
- [x] AC2: For a fake run with 1 near-miss case whose call errors, the ID is in `near_miss_failure_ids` and on the
  `near-miss answered IDs` line. Mutation: excluding errored near-miss cases from `near_miss_failure_ids` makes the test fail.
- [x] AC3: No question or answer text from the new fixture appears in the `print_report()` output or in `json.dumps(results)`.
- [x] AC4: `git diff --stat origin/main` shows only `tests/test_evals_data.py`, and existing tests are unmodified (numstat deletions 0).
  The ownership check passes for role=ai.

## Verification
```bash
python3 -m pytest -q tests/test_evals_data.py
ruff check --isolated --select E,F,W --line-length 130 tests/test_evals_data.py   # no findings on added lines (repo convention since AI-11; make lint has no Python target)
.github/scripts/ownership-check.sh origin/main agent/ai/EVAL-10a
git diff --stat origin/main && git diff --numstat origin/main
```
`make eval` is not required: this task changes tests only.

## Notes
- 2026-11-19 (pm-lead): created from the EVAL-10 final review (QA report "Missing tests", both bullets).
- 2026-11-20 (ai-engineer): built on `agent/ai/EVAL-10a`, PR [#82](https://github.com/MaheshPulivarthi18/ArxivLens/pull/82) (draft), head `69aaaf4`.
  One parametrized test `test_errored_cases_are_misses_and_near_miss_failures_not_refusals` covers both `outcome == "error"` paths:
  a failed call (`None`) and a `verification_unavailable` response. Run: refused `a7` + errored `a9` (answer set) + errored `n6` (near miss).
  Local: `124 passed, 1 skipped`; ruff `All checks passed!`; diff `tests/test_evals_data.py` +24/-0; ownership OK (role=ai).
  Mutations, both run locally on reverted scratch edits: AC1 `== "refusal"` → `!= "answered"` and AC2 skipping errored near-miss failures.
  Each one fails both parametrized cases. The existing EVAL-10 test survives the AC1 mutant, which confirms the gap.
