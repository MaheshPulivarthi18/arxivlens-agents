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

## PM decision — pm-lead, 2026-11-20 — round 1

**Verdict: APPROVE**

Reviewed against: ticket `agents/tasks/EVAL-10a.md` (4 ACs), Product PRD §8 (answer metrics: method notes), `evals/README.md` "Summary IDs" (EVAL-10), PR #82 at head `69aaaf454794bc0b7abf0fe6b24c055bf631316f` (`pulls/82/files` = `tests/test_evals_data.py` +24/-0, patch read in full), the 6 check runs on that head (6/6 completed/success), and all 8 evidence files 00–07 at commit `40bf91712a84e3321e22a3c9881ea0fade1fe6fa` (PNG opened, `.txt` consulted for the cut-off part of 04/05).

1. **Product fit.** The test pins the two counting rules the §8 summary IDs rely on: an errored answer-set call is a miss and never a refusal, and near-miss failures include errors. That stops a refactor from quietly turning infrastructure errors into "refusals", which would make the refusal metric look better than it is. No user-facing or metric behaviour changes.
2. **Scope.** Exactly what the ticket asked for: one parametrized test next to the EVAL-10 tests, covering both `classify()` error paths (`None` and `verification_unavailable`). `scripts/evaluate_answers.py` is untouched and the `near-miss answered IDs` label wasn't renamed, as the out-of-scope rule says. Nothing extra.
3. **Evidence per AC.**
   - AC1: 03 shows the real `evaluate()`/`print_report()` output for both paths (`a9` in misses and errors, not refused; `refused IDs : a7`, `miss IDs : a7, a9`). 04 shows the AC-named mutant M1 at the answer loop (line 207) killed 2/2, and the EVAL-10 test survives it, so the gap was real.
   - AC2: 03 (`near_miss_failure_ids = ['n6']`, line `near-miss answered IDs : n6`); 04 M2 killed 2/2.
   - AC3: 03 "none (checked 6)" for both paths; the test asserts the 6 strings against both output and JSON; 04 M11 (text leak) killed.
   - AC4: 06 (stat/numstat `24 0`, 0 removed lines, ownership OK, ruff clean); 01 (CI ownership job, and `195 passed` vs `193` on base main = the +2 new cases); 07 (`pulls/82/files` is that one file).
   - CI: 00, 6/6 success on the head. No "⚠ unverified" on anything that matters. `make test-unit`/`make lint` are covered by CI; `make eval` not required (test-only).
4. **Docs.** No behaviour or command change, so no app README/CONTRIBUTING change is due and no PRD status column moves (EVAL-10a is a test-hardening follow-up with no PRD row of its own).
5. **PR body** describes EVAL-10a (heading, spec link, KAN-85, 4/4 ACs, the one changed path). I fill in Evidence, CI and Review status when raising it.

**QA nit 1 (`evals/README.md:135`)**: accepted as a Backlog item, not for this PR. The README says `miss IDs` = "refusals plus wrong-paper answers", but the code (now pinned by AC1) also includes errored calls, so the doc understates the line. It's a one-line doc fix in ai-engineer's `evals/` path and outside this tests-only ticket. Added to `agents/board.md` Backlog (ai, P3), together with QA's "Missing tests" note (an errored **refusal-set** case → `refusal_failure_ids` has no dedicated assertion yet).

Next: PR #82 description rewritten with the Evidence section, marked ready for review, label `ready-to-merge`. Mahesh reviews and merges.
