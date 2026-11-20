<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/96#issuecomment-7049974382 (QA harness could not write report.md); role tag and footer removed. -->

QA report — EVAL-6b · PR #96 · round 1

**Verdict:** PASS
**Reviewed commit:** `c0535643303c188264f269c68c5b94b107fc8583` · **Date:** 2026-11-20
**Ticket:** [agents/tasks/EVAL-6b.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/EVAL-6b.md) · **PRD:** Product PRD §8 (answer metrics: correct-refusal row, method notes); ADR-0003 (Accepted)
**Evidence:** [agents/reviews/EVAL-6b/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/) (the QA harness refused to write `report.md`; this comment is the report, and the orchestrator saves it verbatim)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136544805170 | pass |
| Python M0 unit tests | CI job 136544805122 (merge `5473411` of head into `230f617`) | pass: 213 passed, 3 skipped (main `230f617` job 136502157925: 195 passed) → +18 ([08](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/08-ci-m0-log.png?raw=true)) `` |
| Frontend (lint, test, build) | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Full stack (compose + make test-full) | CI job 136544805113 | pass (completed 20:31Z) |
| Agent guardrails (ownership check) | CI | pass ([00](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/00-ci-checks.png?raw=true)) ``` |
| Ticket verification commands | local (Python 3.13, pytest 9.1, ruff 0.16.9) | `pytest tests/test_evals_data.py`: 142 passed, 1 skipped (main: 124 passed); ruff ticket command: All checks passed; diff = exactly the 3 named files, +95/−6 |
| `make test-unit` / `make lint` | not run locally: no Go 1.25 / npm in sandbox | CI green (Go + Python + Frontend jobs) |
| `make eval` | not run: eval-harness robustness only, no retrieval/answer behaviour change (ticket says not required) | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 non-string reason fails closed | ✅ | `scripts/evaluate_answers.py:80-81` guard (`reason is not None and not isinstance(reason, str)` → `"error"`) runs before the truthiness test. `test_classify_non_string_refusal_reason_is_error` × 12 (6 values × with/without citations) + `test_classify_null_or_empty_reason_means_no_reason` × 2 pass ([02](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/02-new-tests.png?raw=true)). ```` The existing asserts at `:947-951` are unchanged and green. Base control: the same tests against main's script fail exactly the 8 rows `['x']`, `{'k':1}`, `[]`, `0` (×2) + the AC2 test, while `7` and `True` already returned error on main, as the ticket said ([05](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/05-base-control.png?raw=true)) ````` |
| AC2 `evaluate()` completes | ✅ | `test_evaluate_completes_on_non_string_refusal_reason`: `error_case_ids == ["a1","x1"]`, `ask_error_count == 2`, `correct_refusal_rate == 0.0`, `refusal_reason_counts == {"all_citations_unsupported": 1}` (string keys only), per-case `refusal_reason` is `None` for both bad cases, `json.dumps(m)` succeeds. The counter and `case_record` share `_reason_str()`. Mutants m3, m5, m6, m8 are each killed by this test ([06](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/06-mutants.png?raw=true)) `````` |
| AC3 `main` wiring | ✅ | `test_main_loads_real_sets_including_near_miss`: monkeypatched `make_http_ask`, `main([--json-out])` returns 0, `near_miss_cases` equals the real file's line count (≥ 10), `seen == answers + refusals + near_miss`, and no question text in the JSON. `test_main_near_miss_empty_skips_the_set`: `near_miss_cases == 0`, rate `None`, no near-miss question seen, no text. Mutants m4 (always load), m9 (swap answer/refusal files), m10 (no JSON written) and m11 (never load near-miss) are all killed |
| AC4 errored refusal-set case | ✅ | `test_failed_refusal_set_call_is_error_and_refusal_failure`: `ask → None` → `refusal_failure_ids == error_case_ids == ["x1"]`, `correct_refusal_rate == 0.0`, x1 in no answer-set ID list. Killed m12 (refusal-set failure also written to misses) and m13 (refusal-set errors not counted) |
| AC5 docs | ✅ | The `miss IDs` bullet now says "refusals, errored calls and wrong-paper answers" (this matches the code: an answer-set `outcome != "answered"` goes to `misses`). The `refusal_reason_counts` bullet now says "String values only … counts as an error" ([09](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/09-readme-diff.png?raw=true)) ``````` |
| AC6 mutation check | ✅ (QA re-run) | 14/14 mutants killed, on the full file and on the AC-specific tests (`-k`), each with its applied diff lines printed. These are the 4 AC mutants m1–m4 plus 10 extra ([06](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/06-mutants.png?raw=true), ```````` sources [07](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/07-harness-src.png?raw=true)). ````````` The extras cover each operand of the guard one at a time: m7 drops `is not None`; m14 lets ints through |
| AC7 CI + count + ruff | ✅ | CI M0 green, 195 → 213 (+18 = 12+2+1+2+1 new ids), 0 failed ([08](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/08-ci-m0-log.png?raw=true)); `````````` local file 124 → 142 ([03](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/03-count-head-vs-main.png?raw=true)); ``````````` the ticket's ruff command reports no findings ([04](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/04-ruff.png?raw=true ````````````)) |

Scope: exactly `evals/README.md`, `scripts/evaluate_answers.py`, `tests/test_evals_data.py`, +95/−6, all ai-engineer paths, no ticket/review files ([01](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/01-scope-diff.png?raw=true)). ````````````` The script changes stay inside `classify()`, `case_record()` and the `call()` counter, plus the new `_reason_str()` helper. `REFUSAL_REASONS`, gate keys, `thresholds.json` and `eval_gate.py` are untouched. No existing assert was edited. No other open PR (#91–#95, #97, #98) touches these files.

## PRD fit
PRD §8 / ADR-0003 say anything that isn't a valid refusal is an error. A malformed `refusal_reason` is now counted as one error case: it lowers `correct_refusal_rate` and shows up in the gated `ask_error_count`. It no longer crashes `make eval` or slips through as a refusal or an answer. So the gate fails closed and every other case is still reported. Report-only counts stay string-keyed, and the JSON holds no question text.

## Findings
1. [nit] `tests/test_evals_data.py` blank-line drift in the new blocks: 3 blank lines before `# EVAL-6b:` (l.1058) and before `test_failed_refusal_set_call…` (l.1202); 1 blank line after the new functions before `# --- EVAL-10` (l.1130) and `# --- EVAL-7` (l.1212). Only ruff's `--preview` E3 rules flag these (4 new vs 2 pre-existing on main, [04](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/04-ruff.png?raw=true ``````````````)). The ticket's ruff command is clean.
2. [nit] PR body: the AC6 line says "4 mutants killed locally (developer)" with no output, while AC6 says "reports output in Notes". QA's independent run covers it.
3. [spec] The goal says "`make eval` must never crash on a malformed `/v1/ask` response", but the scope (rightly) covers only `refusal_reason`. Probe [10](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8fc31c543921d293121c84ed18b1cc9cf4ddbf44/agents/reviews/EVAL-6b/evidence/10-probe-other-shapes.png?raw=true) ``````````````` shows three other shapes still raise inside `evaluate()`: `citations: 5` (TypeError), a non-dict citation item (AttributeError), and a non-dict body (AttributeError). This is out of scope and not a regression. It is a candidate Backlog follow-up for pm-lead.

## Missing tests
- None required by the ACs. An unknown string reason is already pinned as error (`test_unknown_refusal_reason_fails_closed_as_error`); probe 10 shows it is still counted as a string key, as the README says.

## Hand-off
PASS → pm-lead final review.



---

## PM final review (pm-lead) — 2026-11-21

**Verdict: APPROVE** · reviewed PR #96 head `c0535643303c188264f269c68c5b94b107fc8583` · evidence pinned at `8fc31c5`

**Product fit.** Product PRD §8 / ADR-0003 say anything that isn't a valid refusal is an error. Before this PR, one malformed `refusal_reason` (`["x"]`, `{}`) raised `TypeError` and killed the whole `make eval` run, so a single bad response blanked out the gate. Now it is one counted error: it lowers `correct_refusal_rate` and raises the gated `ask_error_count`. Falsy non-strings (`[]`, `0`) don't slip through as "no reason". Report-only `refusal_reason_counts` stays string-keyed, and the results JSON still holds no question text, which matters because CI artifacts are public. That is the fail-closed behaviour the gate needs.

**Scope.** The diff is exactly the 3 ticket files, +95/−6. The script changes stay in `classify()`, `case_record()`, the `call()` counter and the small `_reason_str()` helper. Nothing outside scope changed: no `REFUSAL_REASONS`, gate keys, `thresholds.json`, `eval_gate.py` or `answer_review.py`. No existing assert was edited. Nothing the ticket intended is missing.

**Evidence, every file opened.**
- 00: 6/6 CI checks succeed on `c053564`.
- 01: scope.
- 02: 18/18 new tests pass (AC1–AC4). The `.txt` confirms that the red-coloured lines in the image all read PASSED.
- 03: local count 124 → 142 (AC7).
- 04: the ticket's ruff command is clean (AC7). The preview E3 nits are cosmetic.
- 05: base control. The PR's tests against `main`'s script fail exactly the 8 fixed `classify` rows and the `evaluate` test, which proves the tests pin the fix (AC1/AC2).
- 06/07: 14/14 mutants killed, including AC6's m1–m4, with the harness sources shown (AC6). This covers QA nit 2: the developer's PR body gave no mutant output, but QA's independent run is the evidence.
- 08: CI M0 195 → 213, 0 failed (AC7).
- 09: README bullets (AC5).
- 10: out-of-scope probe.

No AC is left ⚠ unverified.

**Docs.** `evals/README.md` is updated as AC5 asks. No app `README.md` change is needed, since no command or API changed. No PRD status column changes: EVAL-6/EVAL-10 are already delivered, and this is a P3 hardening follow-up. `make eval` was not run, because there is no retrieval/answer behaviour change. The ticket says so, and so does the PR.

**QA findings.**
1. [nit] E3 blank-line drift: not blocking. Folded into the Backlog follow-up below.
2. [nit] PR-body AC6 line: resolved. The rewritten PR description cites QA's 14/14 mutant run.
3. [spec] Accepted. The ticket's Goal sentence ("never crash on a malformed `/v1/ask` response") was broader than its ACs, which cover `refusal_reason` only. That's a wording gap in my spec, not a code defect. The remaining shapes (`citations` not a list, a non-dict citation item, a non-dict body) are a new Backlog line (EVAL-6c candidate, ai, P3, after #96 merges).

**Raised.** The PR description was rewritten with an Evidence section (one row per AC, embedded images), CI results and both verdicts. The PR is marked ready for review with label `ready-to-merge`. Jira KAN-100 → Ready to merge still needs doing by the orchestrator, because this agent has no Jira tools.
