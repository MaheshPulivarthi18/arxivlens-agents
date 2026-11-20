> Provenance: saved verbatim by the orchestrator (cycle 2026-11-20T08:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/82#issuecomment-7035515583 (QA's harness could not write report.md).

[qa-reviewer] QA report: EVAL-10a, PR #82, round 1: **PASS**

**Reviewed commit:** `69aaaf454794bc0b7abf0fe6b24c055bf631316f` (base `main` `3835dee`) · **Date:** 2026-11-20
**Ticket:** [agents/tasks/EVAL-10a.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/EVAL-10a.md) (Jira KAN-85) · **PRD:** Product PRD §8 (answer metrics: method notes) · **Design:** none (not design-required)
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/main/agents/reviews/EVAL-10a/evidence (images pinned at commit `40bf917`)

## Test results
| Check | Source | Result |
|---|---|---|
| All 6 check runs on the head | CI | 6/6 completed/success: Go, Python M0, Frontend, Agent ownership, DB, Full stack ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/40bf917/agents/reviews/EVAL-10a/evidence/00-ci-checks.png?raw=true)) |
| Python M0 unit tests | CI job 136186133171 | on merge commit `3f8c695` (69aaaf4 into 3835dee): `195 passed, 3 skipped` vs `193 passed, 3 skipped` on base main (job 136184190114). The +2 are the two new parametrized cases ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/40bf917/agents/reviews/EVAL-10a/evidence/01-ci-python-job.png?raw=true)) |
| Agent ownership check | CI job 136186133149 | `Ownership OK for role=ai (24 changed lines)` (01) |
| `python3 -m pytest -q tests/test_evals_data.py` | local, PR head | `124 passed, 1 skipped`; both new cases PASSED in `-v` ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/40bf917/agents/reviews/EVAL-10a/evidence/02-pytest-local.png?raw=true)) |
| `ruff check --isolated --select E,F,W --line-length 130 tests/test_evals_data.py` | local, ruff 0.16.9 | `All checks passed!` ([06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/40bf917/agents/reviews/EVAL-10a/evidence/06-ac4-diff-ownership-ruff.png?raw=true)) |
| `ownership-check.sh origin/main agent/ai/EVAL-10a` | local | `Ownership OK for role=ai (24 changed lines)` (06) |
| `make test-unit` / `make lint` | not run locally: no Go 1.25 in the sandbox; covered by the green CI jobs | n/a |
| `make eval` | not run: test-only change, no retrieval or answering code changed (the ticket says it is not required) | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | The new test asserts `error_case_ids == ["a9"]`, `expected_paper_miss_ids == ["a7","a9"]`, `answer_refused_ids == ["a7"]` and the exact `refused IDs` = `a7` / `miss IDs` = `a7, a9` lines. A probe through the real `evaluate()`/`print_report()` shows the same for both error paths ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/40bf917/agents/reviews/EVAL-10a/evidence/03-ac1-ac3-probe.png?raw=true)). Mutant M1 (`if outcome == "refusal":` → `!= "answered"`, anchored on the answer loop at line 207, not the refusal loop at 228) fails **2/2** new cases, and the existing EVAL-10 test still **passes** under it ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/40bf917/agents/reviews/EVAL-10a/evidence/04-mutants.png?raw=true)). |
| AC2 | ✅ | Asserts `near_miss_failure_ids == ["n6"]`, `near_miss_error_ids == ["n6"]` and the `near-miss answered IDs` line = `n6` (03). Mutant M2 (wrap `near_miss_failures.append` in `if outcome != "error":`) fails 2/2; the EVAL-10 test passes under it (04). |
| AC3 | ✅ | The test checks 6 strings (3 questions, the `verification_unavailable` and early-refusal answers, `passage text`) against the output and the JSON. The probe finds none in either path (03). Mutant M11 (the per-case record keeps `case["question"]`) is killed 2/2 (04). |
| AC4 | ✅ | `git diff --stat origin/main` → only `tests/test_evals_data.py` +24; numstat `24 0`; 0 removed lines in `-U0`; ownership OK locally (06) and in CI (01). `pulls/82/files` = that one file ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/40bf917/agents/reviews/EVAL-10a/evidence/07-pr-body-check.png?raw=true)). No other open PR (#70, #79, #80, #81, #83) touches it. |

### Mutation run: 12 single-edit mutants, scratch copies, never pushed
The new test alone **killed all 12** ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/40bf917/agents/reviews/EVAL-10a/evidence/04-mutants.png?raw=true); harness source in [05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/40bf917/agents/reviews/EVAL-10a/evidence/05-harness-source.png?raw=true)). The table lists each mutant's diff and its result against the new test, the EVAL-10 test and the whole file:
- the two AC-named mutants (M1, M2);
- the other call sites of the same rules: an errored answer case not added to misses (M3); `gated_call` not recording errors (M6); near-miss errors counted as refusals (M7); near-miss errors dropped from `near_miss_error_ids` (M12);
- both `classify()` error paths separately: `None` → refusal (M4) and `verification_unavailable` → refusal (M5). Each kills exactly one parametrized case, so both parameters are needed;
- print-line swaps (M8–M10) and a text leak (M11).

8 of the 12 (M1–M7, M12) **survive the existing EVAL-10 test**, so this test adds coverage that wasn't there before.

## PRD fit
The test pins the two documented counting rules behind the §8 answer-metric summary: an errored call is a miss and is never reported as a refusal, and near-miss failures include errors (`evals/README.md` "errors included"). A later refactor can't silently relabel errors as refusals. Product behaviour doesn't change, so there's no NFR impact.

## Scope / PR hygiene
- One file, +24/-0, inside ai-engineer's paths. `scripts/evaluate_answers.py` is untouched (the out-of-scope rule held). No ticket, review or doc files in the PR.
- The PR body matches this task: heading, Spec link, Jira `KAN-85`, the "What changed" path and 4/4 ACs. It is the only open `agent/ai/*` PR (07).
- The PR is still a draft and not merged.

## Findings
1. [nit] (doc follow-up, not for this PR) `evals/README.md:135` describes `miss IDs` as "refusals plus wrong-paper answers" and doesn't mention errored calls, which the code includes and this test now pins (AC1). A one-line README fix would bring the doc in line. That's outside this ticket's tests-only scope, so it's a possible small follow-up for ai-engineer.

No blocking findings.

## Missing tests
- Not required by this ticket: an errored **refusal-set** case (→ `refusal_failure_ids`) has no dedicated assertion here. Noted for completeness only.

## Hand-off
PASS → pm-lead final review.

_Report provenance: the QA harness refused to write `agents/reviews/EVAL-10a/report.md`; this comment is the report verbatim for the orchestrator to save._


---
_Generated by [Claude Code](https://claude.ai/code)_
