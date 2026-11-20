# EVAL-10: Name refused, missed and near-miss-failed case IDs in the `/v1/ask` eval summary

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P2 |
| **PRD ref** | Product PRD §8 (answer metrics: method notes); follow-up from EVAL-4 PM review (AC5 finding, 2026-11-17) |
| **Depends on** | EVAL-6 merged (report-only metrics, done). Tests go in `tests/test_evals_data.py`, which open PR #52 (ING-11b) also changes, so **start only after #52 merges** (file-overlap rule), or put the new tests in a new file `tests/test_evaluate_answers_ids.py` and start now |
| **Jira** | KAN-69 |
| **Design required** | no: report-only output, no gate, threshold or contract change |
| **Status** | **Done**: merged by Mahesh, ArxivLens [#61](https://github.com/MaheshPulivarthi18/ArxivLens/pull/61) → `d64c56d` (2026-11-19) |

## Goal
Nightly `eval.yml` run 43902662193 refused 1 of 22 in-corpus answer-set questions (`In-corpus refused : 4.55%`) and answered 3 of 15
near-miss questions, and nobody can say which ones. The case IDs exist only in the results JSON, and agent sandboxes can't download
Actions artifacts (lessons 2026-11-08 AI-9). This task prints the IDs (IDs only, never question or answer text) in the summary that
already goes to the job log, so any reviewer can name the case from the log.

## Scope
- `scripts/evaluate_answers.py`:
  - `evaluate()`: add `answer_refused_ids` (answer-set cases whose outcome is `refusal`), kept separate from the existing
    `expected_paper_miss_ids`, which mixes refusals and answers that cite the wrong paper. Additive key; no existing key renamed or removed.
  - `print_report()`: after `In-corpus refused`, print `  refused IDs : <ids>` when non-empty; print `  miss IDs : <ids>` for
    `expected_paper_miss_ids` when non-empty; in the report-only block, print `  near-miss answered IDs : <ids>` for `near_miss_failure_ids`
    when non-empty. Same style as the existing `WARNING: errors` line (comma-separated IDs, no text).
- Tests (see Depends on for the file).
- Out of scope: `scripts/eval_gate.py` table, thresholds, datasets, `eval.yml`, any gate, `evals/BASELINE.md` numbers (the next baseline
  refresh picks up the new lines).

## Acceptance criteria
- [x] AC1: For a fake run with 1 early-refused answer case, 1 wrong-paper answer case and 1 answered near-miss case, the results contain
  `answer_refused_ids == [<refused id>]`, `expected_paper_miss_ids` holds both answer-set IDs (unchanged behaviour), and
  `print_report()` output contains each of the 3 IDs on the labelled line. Mutation: dropping each of the 3 new print lines in turn
  fails a test (one mutant per line), and so does putting the wrong-paper ID into `answer_refused_ids`.
- [x] AC2: With no refusals, misses or near-miss failures, `print_report()` prints none of the 3 new lines (existing output unchanged:
  the existing `test_print_table_shows_report_only_block` and every other test in the file pass unmodified).
- [x] AC3: No text leaks: in the AC1 fixture, the question and answer strings don't appear in the `print_report()` output or in
  `json.dumps(results)` beyond what the existing EVAL-6 no-text test already allows.
- [x] AC4: `git diff --stat origin/main` shows only `scripts/evaluate_answers.py` and the one test file; ownership check OK for role=ai.
- [x] Docs: `evals/README.md` gets one sentence where it describes the `/v1/ask` summary (IDs printed, no text). No PRD status change.

## Verification
```bash
python3 -m pytest -q tests/test_evals_data.py      # or tests/test_evaluate_answers_ids.py if the new-file route is taken
ruff check --select E,F,W scripts/evaluate_answers.py <test file>   # no findings on added lines (make lint doesn't cover Python)
.github/scripts/ownership-check.sh origin/main agent/ai/EVAL-10
git diff --stat origin/main
```
`make eval` is not required (no retrieval or answering behaviour changes; the gate table is untouched). A later nightly run shows the
new lines in the job log. QA can confirm with `gh api .../actions/jobs/<id>/logs | grep -E 'refused IDs|miss IDs|near-miss answered IDs'`
once the PR merges, but this isn't a PR AC.

## Notes
- 2026-11-17 (pm-lead): created from the EVAL-4 final review (D2 in `agents/reviews/EVAL-4/report.md`). Until this merges, the only source
  for run 43902662193's refused case is `answers.cases` in artifact 14247998742 (expires 2026-12-16), which only Mahesh can read.
- 2026-11-19 (pm-lead): final review **APPROVE** on `164305b` (QA PASS r1, evidence `9d8ab39`). Verdict and rulings are in
  `agents/reviews/EVAL-10/report.md`. [spec] AC4 named 2 files but the Docs criterion needs a third (`evals/README.md`); README accepted.
  [spec] The ruff command had no line length; repo convention is `--isolated --line-length 130`. Follow-up **EVAL-10a**
  (error-outcome tests, P3). The `make lint` Python target (AI-11 follow-up (a)) is still unspecced; there are 63 pre-existing findings
  at 130, so it needs grooming. PR #61 raised (description has evidence, ready for review); waiting on Mahesh.
- 2026-11-20 13:00Z (pm-lead, sync): merged (#61 `d64c56d`); Status → Done.
