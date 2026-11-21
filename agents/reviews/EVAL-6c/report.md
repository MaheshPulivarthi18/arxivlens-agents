> Provenance: saved verbatim by the orchestrator (cycle 2026-11-21T05:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/107#issuecomment-7058096249 (QA harness refuses to write report.md).

[qa-reviewer] QA report: EVAL-6c, PR #107, round 1

**Verdict:** PENDING (waiting on the Full stack re-run, AC8. Everything else is verified: no blocking findings, AC1-AC7 met)
**Reviewed commit:** `1f3bd3177bc7a83625f23a82042492a3e0436247` · **Date:** 2026-11-21
**Ticket:** [agents/tasks/EVAL-6c.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/tasks/EVAL-6c.md) · **PRD:** Product PRD §8 (answer metrics, method notes). ADR-0003 (anything that isn't a valid refusal is an error). Follow-up from EVAL-6b QA finding 3 and nit 1.
**Evidence pack:** [agents/reviews/EVAL-6c/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence) (pinned at agents commit `2548932`)
**Note:** my harness doesn't let me write `report.md`. This comment is the full report. The orchestrator will save it verbatim to `agents/reviews/EVAL-6c/report.md` with a provenance note.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136743720711 | pass |
| Python M0 unit tests | CI job 136743720411 (merge onto current main `11c4696`) | pass: light step **276 passed** vs main's 157 (+119) |
| Frontend (lint, test, build) | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Agent ownership check | CI | pass |
| Full stack (compose + make test-full) | CI job 136743720337 | **fail (infra)**: `arxiv_replay.py prefetch` got 8× upstream 429/503 and exited 1 before any test step. No test ran. A re-run is pending |
| `pytest -q tests/test_evals_data.py` | local, head | 261 passed, 1 skipped |
| ruff E,F,W / E3 preview | local | clean / main 6 → head 2 (the two pre-existing ones) |
| `make test-unit` / `make lint` | not run locally: Go 1.25 is unavailable in the sandbox. CI covers both (Go + Python jobs green) | |
| `make eval` | not run: no stack in the sandbox. In its place: a well-formed head-vs-main differential, 3000 random responses with 0 metric differences ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/07-probes.png)) | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 non-dict body | ✅ | `call()` sets a non-dict body to `None` (l.227-228). `test_non_object_body_is_a_failed_request` (6 bodies: `["x"]`, `[]`, `"s"`, `5`, `0`, `True`) asserts error IDs in both sets, `requests_ok == 0`, p95 1234 with the 99999 near-miss latency left out, and records `("error", None, [])`. It fails 6/6 against main's script ([05](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/05-base-control.png ``)). m1 and m5 are KILLED ([06](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/06-AC7-mutants.png ```)). With an all-`[]` run, `eval_gate` now exits 2 via `ConnectionError: every /v1/ask request … failed` (main: `AttributeError`) ([08](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/08-AC1-gate-reason.png ````)) |
| AC2 malformed citations | ✅ | `_citations_ok()` is checked before the reason in `classify()`. `test_malformed_citations_are_one_error_case` (10 rows) covers (a), (b), (c), `requests_ok == 2`, the error IDs, no refusal/hit, `citations_total == 0`, and the kept-dict-items records. m2/m3/m4/m7 are KILLED, and so are x1 (check moved after the reason), x2 (null citations) and x3 (null arxiv_id) ([06](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/06-AC7-mutants.png `````)). 10/10 rows fail on main ([05](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/05-base-control.png ``````)) |
| AC3 report-only claims | ✅ | `_markers_ok()` plus the int-filtered `in_range`. `test_malformed_claims_count_as_uncited_units` includes `"12"` and `5` plus a well-formed control, and `test_non_int_citation_marker_is_ignored` covers `"1"`, `[1]`, `{}`, `None`, `True`, `1.0`. x4/x5/x6/x9 are KILLED. Outcome stays `answered` in every row |
| AC4 property test | ✅ | `test_evaluate_never_crashes_on_hostile_shapes`: 9 values × 9 positions = 81 ids, all three sets, all passing ([02](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/02-head-tests.png ```````)). 37 of them fail on main ([05](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/05-base-control.png ````````)). The EVAL-6b `NON_STRING_REASONS` rows are unchanged and green (13 passed; the only diff line touching the name is the E3 blank-line fix above it). Independent fuzz: 4000 random nested hostile values, 0 crashes, 0 rule mismatches ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/07-probes.png)) |
| AC5 README | ✅ | Classification row and the `citation_coverage` sentence, verbatim scope ([04](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/04-AC5-readme-diff.png `````````)) |
| AC6 lint | ✅ | E,F,W: "All checks passed!". E3 preview: main has 780, 811, 1058, 1130, 1202, 1212; head has only 781 and 812, the pre-existing two shifted by the new `import copy` ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/03-AC6-ruff.png)) |
| AC7 mutants | ✅ | m1-m5 and m7 KILLED. m6 SURVIVED, and P3a ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/07-probes.png)) proves it equivalent, so it counts as **INVALID**: `set("12")` holds only strings, `in_range` now holds only non-bool ints, so 0/5000 random inputs differ. That matches the developer's report |
| AC8 CI | ⚠ pending | Light step 276 vs main 157 = **+119**, exactly the 119 new ids ([09](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/09-AC8-ci-m0-counts.png), `````````` [02](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/02-head-tests.png ```````````)). Ownership check green. **Full stack has not passed yet**: it failed in the replay prefetch (8 upstream 429/503, `prefetch FAILED … arXiv unreachable or rate-limiting`, and no `make test-full` step in the log) ([10](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/10-AC8-ci-stack.png ````````````), [00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/00-ci-checks.png)) |

## Scope
Exactly the 3 allowed files, +170/−9 ([01](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/01-scope-diff.png `````````````)). Nothing out of scope (`make_http_ask`, `eval_gate.py`, and `thresholds.json` are untouched). The PR body's heading, Spec, and Jira lines match EVAL-6c/KAN-109.

## PRD fit
This serves Product PRD §8 and ADR-0003 directly: a malformed `/v1/ask` response now counts as one error case and no longer blanks the whole answer gate. An all-malformed run still reaches the honest "could not run" path. Well-formed responses give byte-identical metrics to main (3000-run differential), so no gate value or metric definition moves.

## Findings
1. [nit] `test_all_non_object_bodies_trip_could_not_run` only asserts exit code 2, and main also returns 2 (via the catch-all `except` on the `AttributeError` crash, [08](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/08-AC1-gate-reason.png)). `````````````` The test passes on main, so it doesn't pin the AC1 "`requests_ok == 0` could-not-run path". Asserting `"every /v1/ask request"` in `capsys` stderr would fix that. Not blocking: the `requests_ok == 0` assertion in `test_non_object_body_is_a_failed_request` already kills m5.
2. [nit] Mutant x8 survives: `coverage_units` builds `in_range` from raw `resp.get("citations")` and skips `_citation_items`. Through `evaluate()` the two are equivalent (0/5000 differences, since `classify` rejects malformed citations first). A direct `coverage_units({"citations": 5})` call raises `TypeError` under x8, though, and no test calls `coverage_units` with malformed citations (P3c, [07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/07-probes.png)). Only reachable by a direct caller. One test row would cover it.

## Missing tests
- A direct `coverage_units` row with malformed `citations` (finding 2).
- A stderr-reason assertion for the could-not-run path (finding 1).

## Hand-off
PENDING → re-review when the Full stack job re-run finishes on `1f3bd31`. If it's green and the head is unchanged, this becomes PASS → pm-lead final review. No developer rework needed. The two nits are optional.

Evidence: [00 CI checks](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/00-ci-checks.png) · [01 scope](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/01-scope-diff.png ```````````````) · [02 head tests](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/02-head-tests.png ````````````````) · [03 ruff](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/03-AC6-ruff.png) · [04 README](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/04-AC5-readme-diff.png `````````````````) · [05 base control](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/05-base-control.png ``````````````````) · [06 mutants](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/06-AC7-mutants.png ```````````````````) · [07 probes](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/07-probes.png) · [08 gate reason](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/08-AC1-gate-reason.png ````````````````````) · [09 CI M0 counts](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/09-AC8-ci-m0-counts.png `````````````````````) · [10 CI stack](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/10-AC8-ci-stack.png ``````````````````````) · [11 harness src](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/11-harness-src.png ```````````````````````)


---
_Generated by [Claude Code](https://claude.ai/code)_


---

## Round 2

[qa-reviewer] QA report: EVAL-6c, PR #107, round 2

**Verdict:** PASS
**Reviewed commit:** `1f3bd3177bc7a83625f23a82042492a3e0436247` (same as round 1) · **Base/main:** `11c4696` (unchanged) · **Date:** 2026-11-21
**Evidence pack:** [agents/reviews/EVAL-6c/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/074ac0c7a1d962c7e79a013583b847f09092b5af/agents/reviews/EVAL-6c/evidence) (round 2 files 12-14, pinned at agents commit `074ac0c`)

## What changed since round 1
- Nothing in the PR. The head is still `1f3bd31`, main is still `11c4696`, and the diff is the same 3 files, +170/−9. No new commits, no human review, and no new comments except the round 1 QA comment.
- The Full stack workflow run 44870501649 was re-run as attempt 3 (job 136768996544, event `pull_request`, head `1f3bd31`). It concluded **success** at 07:15:40Z.

## AC8 re-check (only open item from round 1)
| Check | Source | Result |
|---|---|---|
| All 6 check runs on `1f3bd31` | [12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/074ac0c7a1d962c7e79a013583b847f09092b5af/agents/reviews/EVAL-6c/evidence/12-r2-ci-checks.png) | all `completed / success`: Full stack, Agent ownership, Go, Frontend, Python M0, DB |
| Full stack job steps | run 44870501649 attempt 3 ([13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/074ac0c7a1d962c7e79a013583b847f09092b5af/agents/reviews/EVAL-6c/evidence/13-r2-AC8-stack-steps.png)) | every step success (only `Diagnostics` skipped, as it runs on failure only), including "Prefetch arXiv responses", "AC4: make test-full" and "Known failure F1" |
| What ran | job log ([14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/074ac0c7a1d962c7e79a013583b847f09092b5af/agents/reviews/EVAL-6c/evidence/14-r2-AC8-stack-log.png)) | checkout `264409b Merge 1f3bd31… into 11c4696…`. Prefetch `upstream_failures: 0, saved: 5` (the round 1 429 blocker is gone). `make test-full`: **390 passed, 1 skipped, 3 deselected** (the 3 tracked F1 tests). The F1 step: 3 passed. 261 `PASSED tests/test_evals_data.py` lines, the same as the local head count (261 passed, 1 skipped). 0 FAILED/ERROR test lines |
| Python M0 light count | round 1 [09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/09-AC8-ci-m0-counts.png) | 276 vs main 157 = +119 = the new ids (unchanged run, same head) |

In [14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/074ac0c7a1d962c7e79a013583b847f09092b5af/agents/reviews/EVAL-6c/evidence/14-r2-AC8-stack-log.png), the `[exit code 1]` footer comes from the last `grep -c` finding 0 FAILED lines, which is the expected result. The 429 lines inside the log come from the replay unit tests' own mocked upstream (`127.0.0.1:<port>`), not from arXiv.

## Acceptance criteria (final)
| AC | Met? | Evidence |
|---|---|---|
| AC1-AC7 | ✅ | Unchanged from round 1 (same head; evidence 01-11 still applies) |
| AC8 | ✅ | Python M0 +119 ([09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/25489328343c7d48e63896decb2afbd8ce0bd8e2/agents/reviews/EVAL-6c/evidence/09-AC8-ci-m0-counts.png)). Ownership green, Full stack green ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/074ac0c7a1d962c7e79a013583b847f09092b5af/agents/reviews/EVAL-6c/evidence/12-r2-ci-checks.png), [13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/074ac0c7a1d962c7e79a013583b847f09092b5af/agents/reviews/EVAL-6c/evidence/13-r2-AC8-stack-steps.png), [14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/074ac0c7a1d962c7e79a013583b847f09092b5af/agents/reviews/EVAL-6c/evidence/14-r2-AC8-stack-log.png)) |

## Findings
No blocking findings. The round 1 nits 1 (could-not-run test only asserts exit 2) and 2 (mutant x8 / direct `coverage_units` row) remain optional and need no rework.

## Not run locally
`make test-unit` / `make lint` (no Go 1.25 in the sandbox) and `make eval` (no stack). CI covers the first two. For `make eval`, the round 1 3000-run well-formed differential showed 0 metric differences.

## Hand-off
PASS → pm-lead final review. Jira: move to PM review.


---

## PM final review (pm-lead)

**Verdict:** APPROVE
**Reviewed:** PR #107 head `1f3bd3177bc7a83625f23a82042492a3e0436247` (base/main `11c4696`, unchanged) · QA r1 PENDING → r2 PASS at the same head · 2026-11-21

- **PRD fit (Product PRD §8, ADR-0003):** a malformed `/v1/ask` response now counts as one `error` case instead of crashing `evaluate()` and blanking the whole answer gate. An all-malformed run reaches the honest "could not run" path, and `eval_gate` now names the right cause (`ConnectionError: every /v1/ask request … failed` instead of `AttributeError`, evidence 08). This is what the gate's users (Mahesh reading CI, the ai-engineer tuning RAG) need: one bad response means one error, not "no data".
- **Scope:** exactly the 3 allowed files, +170/−9, below the 300-line stop (01). Production change +41/−6. One small addition beyond the listed positions: a non-string `answer` gives no sentence units. It sits inside AC3's "`coverage_units()` never raises" intent, is tested (3 rows, mutant x7 killed), and changes no metric for well-formed input. Accepted, not scope creep. No gate key, threshold, metric definition or results field changed, so no design or ADR was needed.
- **Evidence:** I opened all 15 images (00-14) and their `.txt` files. Every AC has proof. AC1: 05, 06 m1/m5, 08. AC2: 05, 06 m2/m3/m4/m7/x1-x3. AC3: 06 x4-x6/x9, 07 P3a. AC4: 02 (81 ids), 05 (37 fail on main), 07 P1 fuzz. AC5: 04. AC6: 03 (E3 6 → 2, only the two pre-existing ones left). AC7: 06 (m6 INVALID, shown equivalent by 07 P3a). AC8: 09 (276 vs 157 = +119 = new ids), 12-14 (Full stack attempt 3 green on the merge ref, `make test-full` 390 passed, 261 `test_evals_data.py` PASSED lines). No "⚠ unverified" remains on anything that matters. The round 1 Full stack failure (00, 10) was upstream arXiv 429/503 in prefetch, with no test run, and it is superseded by 12-14.
- **m6 INVALID:** I accept it. It is my spec's fault: m6 assumed `_markers_ok` would be the only guard, but the int-only `in_range` makes a string `markers` uncited either way. The AC3 behaviour (`"12"` → uncited) is still pinned by `test_malformed_claims_count_as_uncited_units`.
- **DoD 3, `make eval`:** not run, because there is no stack in the sandbox. That is acceptable here: the change only affects malformed responses, and QA's 3000-run well-formed head-vs-main differential shows 0 metric differences (07 P2), so no gate value can move.
- **DoD 2:** `make test-unit` / `make lint` come from CI (Go + Python M0 + Frontend + DB green at the head). I checked the check-runs API myself at review time: all 6 runs `completed/success`.
- **Docs:** `evals/README.md` classification row and coverage note done (AC5). The app `README.md` needs no change (no CLI/API change). No PRD status column covers this item (it is a §8 harness follow-up with no ⏳ row), so no PRD edit.
- **Follow-ups (already in board Backlog, ai, P3, after #107 merges):** QA nit 1 (`test_all_non_object_bodies_trip_could_not_run` should assert the "every /v1/ask request" stderr reason, because it also passes on main) and nit 2 (a direct `coverage_units` row with malformed `citations`, to cover mutant x8). Fold both into the EVAL-7 `build_rows` follow-up on `tests/test_evals_data.py`.
- **Process note:** the round 1 links in this report wrap some URLs in backticks (a copy artifact from saving the comment verbatim), so those links don't click. The pinned URLs are still readable, and round 2 plus the PR description use clean links.

→ Raise PR #107 (ready for review); Jira KAN-109 → Ready to merge (orchestrator).
