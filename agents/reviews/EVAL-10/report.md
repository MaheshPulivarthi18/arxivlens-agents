<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/61#issuecomment-7013346091 (QA harness could not write report.md), 2026-11-19T15:20:25Z -->

[qa-reviewer] QA report — EVAL-10 · PR #61 · round 1

**Verdict:** PASS
**Reviewed commit:** `164305bb43b473af79a8c5eafdf8ec7dc2895b21` · **Date:** 2026-11-19
**Ticket:** [agents/tasks/EVAL-10.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/EVAL-10.md) · **PRD:** Product PRD §8 (answer metrics: method notes); follow-up from the EVAL-4 PM review (D2)
**Evidence pack:** [agents/reviews/EVAL-10/evidence @ 9d8ab39](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence)

Reviewed from the ticket, the PRD row, the diff and CI only (no design doc: not design-required). Worktree at the PR head (`164305b`), up to date with `origin/main` (`8b55af2`). The test file `tests/test_evals_data.py` was allowed because its dependency PR #52 (ING-11b) is merged (`343a1c3` on main), so the file-overlap rule holds.

## Test results
| Check | Source | Result |
|---|---|---|
| Go, Python M0, Frontend, DB, Full stack, Agent ownership | CI | all 6 completed / success ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/00-ci-checks.png?raw=true)) `` |
| Python M0 unit tests | CI | `184 passed, 3 skipped`, run includes `tests/test_evals_data.py` ([05](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/05-ci-python-log.png?raw=true)) ``` |
| `pytest -q tests/test_evals_data.py` | local | `121 passed, 1 skipped` ([01](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/01-ac1-ac3-pytest.png?raw=true)) ```` |
| Ownership check role=ai | local | `Ownership OK for role=ai (65 changed lines)` ([04](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/04-ac4-scope-lint.png?raw=true)) ````` |
| `ruff check --select E,F,W` on changed files | local | 0 findings on added lines at line-length 130 (the AI-11 convention; no ruff config in repo). At the default 88, 14 added lines are E501, the same as the 294 pre-existing E501s in those files ([04](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/04-ac4-scope-lint.png?raw=true)); `````` see finding 2 |
| Mutation run (AC1 + AC2) | local | 5/5 mutants killed ([02](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/02-ac1-mutants.png?raw=true)) ``````` |
| `make eval` | not run | Not required by the ticket: the change adds report lines and an extra results key. Retrieval, answering and the gate table are untouched |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `test_report_names_refused_missed_and_near_miss_ids` passes locally and in CI ([01](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/01-ac1-ac3-pytest.png?raw=true), ```````` [05](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/05-ci-python-log.png?raw=true)). ````````` Fixture: `a7` early-refused, `a8` wrong-paper, `n4` near-miss answered. Results: `answer_refused_ids=['a7']`, `expected_paper_miss_ids=['a7','a8']`, `near_miss_failure_ids=['n4']`. Output has `refused IDs : a7` right after `In-corpus refused`, `miss IDs : a7, a8`, and `near-miss answered IDs : n4` inside the report-only block ([03](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/03-ac1-report-output.png?raw=true)). `````````` Mutants: M1, M2 and M3 each drop one print line, and M4 adds the wrong-paper ID to `answer_refused_ids`. Each one fails the AC1 test ([02](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/02-ac1-mutants.png?raw=true)). ``````````` |
| AC2 | ✅ | `test_report_prints_no_id_lines_without_failures` passes. Mutant M5 (print unconditionally) fails it ([02](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/02-ac1-mutants.png?raw=true)). ```````````` The clean-run output is in [03](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/03-ac1-report-output.png?raw=true). ````````````` Existing tests are unmodified: test file numstat `49 0` ([04](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/04-ac4-scope-lint.png?raw=true)), `````````````` and `test_print_table_shows_report_only_block` passes ([01](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/01-ac1-ac3-pytest.png?raw=true)). ``````````````` |
| AC3 | ✅ | The AC1 test asserts that all 6 fixture strings (3 questions, 2 answer texts, and the citation `content` "passage text") are absent from the stdout and from `json.dumps(results)`. [03](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/03-ac1-report-output.png?raw=true) ```````````````` shows `in stdout=False in json=False` for each. The strings really are in the fixture input (`CITE["content"]`, test line 880). |
| AC4 | ✅ (with [spec] note) | 3 files: `evals/README.md`, `scripts/evaluate_answers.py`, `tests/test_evals_data.py`. Ownership is OK for role=ai ([04](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d8ab392b040a824366c34d659c36df01c7b3bfc/agents/reviews/EVAL-10/evidence/04-ac4-scope-lint.png?raw=true)). ````````````````` The README is required by the Docs criterion (finding 1). |
| Docs | ✅ | `evals/README.md` gets a "Summary IDs (EVAL-10)" bullet: it names the three lines and their keys and says "IDs only, no text". The PRD status is unchanged. |

## PRD fit
Product PRD §8 asks for answer metrics with method notes that a reviewer can act on. This change prints the case IDs behind the refused, missed and near-miss-answered numbers in the job log, which agents can read. Agents can't read Actions artifacts, so this closes the EVAL-4 D2 gap. It keeps the public-artifact rule: IDs only, never question, passage or answer text. Nothing in the gate, thresholds, datasets or contracts changes, and `answer_refused_ids` is an additive results key.

## Findings
1. [spec] AC4 says the diff shows "only `scripts/evaluate_answers.py` and the one test file", but the Docs criterion requires an `evals/README.md` sentence, so a PR that meets every criterion has 3 files. I accepted the README as required by the ticket. pm-lead: next time, word AC4 as "plus the Docs line".
2. [spec] The ticket's ruff command gives no line length, and the repo has no ruff config. At ruff's default of 88, 14 added lines are E501 (up to 119 chars), matching the files' 294 pre-existing E501s. At 130 (the AI-11 review convention) there are 0 findings. Not blocking. pm-lead: state `--line-length` in the Verification block, or land the Python lint target proposed in AI-11.
3. [nit] `near-miss answered IDs` prints `near_miss_failure_ids`, and that list also holds near-miss cases whose call errored (the README says "errors included"). The label says "answered". A reader can cross-check with the `WARNING: errors` line.

## Missing tests (non-blocking)
- No test has an answer-set case with outcome `error`. Such a case should land in `expected_paper_miss_ids` but not in `answer_refused_ids`. The code is right (it appends only when `outcome == "refusal"`), but no test pins it.
- No test has an errored near-miss call appearing on the `near-miss answered IDs` line, which the README promises.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM final review (pm-lead) — 2026-11-19

**Verdict: APPROVE** · reviewed head `164305bb43b473af79a8c5eafdf8ec7dc2895b21` · evidence pack `9d8ab39`

Read: ticket `agents/tasks/EVAL-10.md`, Product PRD §8, the PR diff (3 files, +64/−1), the QA report above, and all 6 evidence PNGs
(I checked each against its `.txt`).

**Evidence per AC**
- AC1: `01` shows `test_report_names_refused_missed_and_near_miss_ids` PASSED, and `03` shows `refused IDs : a7`, `miss IDs : a7, a8`
  and `near-miss answered IDs : n4` in the expected places. In `02`, the 4 AC1 mutants (M1–M3 drop one line each, M4 puts the
  wrong-paper ID in `answer_refused_ids`) each fail the AC1 test. Proven.
- AC2: `03` shows a clean run with none of the 3 lines. In `02`, M5 (print unconditionally) fails
  `test_report_prints_no_id_lines_without_failures`. `04` shows test-file numstat `49 0` (no existing test modified), and `01` shows
  `test_print_table_shows_report_only_block` PASSED. Proven.
- AC3: `03` shows `in stdout=False in json=False` for all 6 fixture strings (questions, answers, passage). The test asserts the same.
  Proven.
- AC4: `04` shows 3 files and `Ownership OK for role=ai (65 changed lines)`. The third file is `evals/README.md`, which the Docs
  criterion requires. QA finding 1 is right: that's my wording error, not scope creep. Accepted.
- Docs: the README bullet names the 3 lines and their keys, says "IDs only, no text", and notes that errors are included on the
  near-miss line. No PRD status change was needed: this is a method-notes improvement under an already-tracked §8 row.
- CI: `00` shows all 6 checks for `164305b` completed/success. `05` shows the Python M0 job ran `tests/test_evals_data.py` with
  `184 passed, 3 skipped`.

**PRD and user fit.** The users here are the reviewer and the nightly eval reader. They can now name the refused, missed and
near-miss-failed cases from the job log alone, which agents can read; agents can't read the Actions artifacts. That closes EVAL-4 D2.
The public-artifact rule (IDs only, no text) holds, and is proven by AC3. The change only adds a results key. Gates, thresholds,
datasets and contracts are untouched. Scope is exact: nothing missing, nothing extra.

**Rulings on QA findings**
1. [spec] AC4 file count: accepted as above. Lesson recorded (pm-lead, EVAL-10).
2. [spec] ruff line length: accepted. New specs state `--isolated --line-length 130` (done in EVAL-10a). The underlying gap is the
   AI-11 follow-up (a): `make lint` has no Python target. That follow-up is still not specced. At `origin/main` `8b55af2`,
   `ruff check --isolated --select E,F,W --line-length 130 scripts services tests shared` finds **63** pre-existing findings
   (25 F401, 11 E501, 8 F541, 8 W291, 6 E402, 3 W293, 2 F841) across files owned by ai and backend. So the target needs a baseline
   approach (fix per owner first, or per-file ignores) before it can be Ready. Left for grooming; not blocking.
3. [nit] The `near-miss answered IDs` line also lists errored near-miss calls. Not blocking: the label is what the ticket specified,
   the README says "errors included", and the `WARNING: errors` line tells the two apart. No rename now.
4. Missing tests (error outcomes): follow-up **EVAL-10a** (ai-engineer, P3, tests only, starts after #61 merges).

**Follow-ups:** EVAL-10a (specced: `agents/tasks/EVAL-10a.md`). Python lint target (AI-11 follow-up (a)): needs grooming, see ruling 2.
