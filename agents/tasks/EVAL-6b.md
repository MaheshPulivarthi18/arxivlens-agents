# EVAL-6b: Answer eval fails closed on a non-string `refusal_reason`; `main` tests; errored refusal-set and README `miss IDs` nits

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P3 (harness/quality) |
| **PRD ref** | Product PRD §8 (answer metrics: correct-refusal row, method notes); ADR-0003 (Accepted: anything that isn't a valid refusal is an error). Follow-ups from the EVAL-6 review (board Backlog: "`classify()` treats a non-string `refusal_reason` as an error case instead of raising `TypeError`; tests for `main` loading the real near-miss file and `--near-miss ''`") and the EVAL-10a QA/PM review (QA nit 1 + "Missing tests", `agents/reviews/EVAL-10a/report.md`) |
| **Depends on** | EVAL-6 (#20), EVAL-10a (#82, merged `21eb4e9`). No open PR touches `scripts/evaluate_answers.py`, `tests/test_evals_data.py` or `evals/README.md` (checked 2026-11-20 20:00Z: open PRs #91–#94 change only `frontend/…`, `README.md`, `cmd/arxivlens/…`, `internal/query/server*.go`) |
| **Jira** | KAN-100 (epic KAN-2 "Retrieval & answer quality gates"; labels `task-EVAL-6b`, `agent-ai`, `arxivlens`) |
| **Design required** | no: no gate key, threshold, contract, CLI or table change; report-only metric wording only |
| **Status** | Ready to merge (PR #96 @ `c053564`, QA r1 PASS, PM APPROVE 2026-11-21) |

## Goal
`make eval` must never crash on a malformed `/v1/ask` response: a `refusal_reason` that isn't a string (e.g. `["x"]`, `{}`) today raises
`TypeError: unhashable type` in `classify()` (`REFUSAL_REASONS.get(reason, …)`, `scripts/evaluate_answers.py:79-81`) and in the
`reason_counts` update (`:186-188`), so one bad response kills the whole run instead of counting as one error. Also pin `main`'s
argument wiring (nothing calls `evaluate_answers.main` in tests today) and close two EVAL-10a nits.

Checked on `origin/main` `230f617`: `classify({"refusal_reason": ["x"]})` raises `TypeError`; `classify({"refusal_reason": 7})` returns `"error"`;
`grep -n "evaluate_answers.main" tests/test_evals_data.py` has no match; `evals/README.md:135` still says `miss IDs` = "refusals plus wrong-paper answers".

## Scope
- `scripts/evaluate_answers.py`: `classify()` and the `call()` reason counter (`:184-190`), and `case_record()`'s `refusal_reason` field (`:142`). Nothing else.
- `tests/test_evals_data.py`: new tests in the EVAL-6 / EVAL-10 sections. Don't edit existing asserts.
- `evals/README.md`: the `refusal_reason_counts` bullet (~l.126) and the Summary IDs bullet (~l.134-136).
- Out of scope: new `refusal_reason` values, gate keys, `evals/thresholds.json`, `eval_gate.py`, `answer_review.py` (EVAL-7 follow-up stays Backlog), `CHUNK_COUNTS_SQL` (EVAL-5 follow-up).
- Size: ~15 script lines + ~60 test lines + 2 README lines.

## Acceptance criteria
- [ ] AC1 — **Non-string reason fails closed.** For `refusal_reason` in `["x"]`, `{"k": 1}`, `7`, `True`, `[]`, `0`, `classify()` returns `"error"` and never raises. `None` (absent / JSON null) and `""` keep today's behaviour (no reason: `"answered"` with citations, else `"refusal"`; the existing asserts at `test_evals_data.py:947-951` stay green). Note `[]`, `0` are falsy: they must still be `"error"`, not "no reason".
- [ ] AC2 — **`evaluate()` completes on them.** A run where the answer-set and refusal-set responses carry `refusal_reason=["x"]` returns metrics with both cases in `error_case_ids`, `ask_error_count == 2`, `correct_refusal_rate == 0.0`, and `refusal_reason_counts` holds string keys only (the non-string value is **not** counted there; it is visible as an error). The case record's `refusal_reason` is `None` for a non-string value, and `json.dumps(metrics)` succeeds.
- [ ] AC3 — **`main` wiring.** With `evaluate_answers.make_http_ask` monkeypatched to a fake (no network) that records the questions it gets: (a) `main(["--json-out", <tmp>])` returns 0, loads the real `evals/answer.jsonl`, `evals/refusal.jsonl` and `evals/refusal_near_miss.jsonl` (the JSON's `near_miss_cases` equals the line count of the real near-miss file, which is ≥ 10, and the fake saw every near-miss question); (b) `main(["--near-miss", "", "--json-out", <tmp>])` gives `near_miss_cases == 0` and `near_miss_correct_refusal_rate is None`, and the fake saw no near-miss question. The JSON file must hold no question text (reuse the existing "no text" check style).
- [ ] AC4 — **Errored refusal-set case (EVAL-10a missing test).** A refusal-set case whose call fails (`ask` returns `None`) is in `refusal_failure_ids` and `error_case_ids`, `correct_refusal_rate == 0.0`, and it is in no answer-set ID list. (`B_RESPONSE` in the refusal set is already pinned at `test_evals_data.py:926-929`; this AC is the failed-call path.)
- [ ] AC5 — **Docs.** `evals/README.md`: the Summary IDs bullet says `miss IDs` are "refusals, errored calls and wrong-paper answers" (matches EVAL-10a AC1); the `refusal_reason_counts` bullet says string values only, a non-string `refusal_reason` counts as an error.
- [ ] AC6 — **Mutation check** (developer runs, reports output in Notes, reverts): (m1) remove the non-string guard in `classify()` → an AC1 test fails (or raises); (m2) let a falsy non-string (`[]`) fall through as "no reason" → an AC1 row fails; (m3) count non-string values in `reason_counts` (e.g. `str(reason)`) → AC2 fails; (m4) in `main`, drop the `if args.near_miss else None` (always load) → AC3(b) fails with a file error or count ≠ 0.
- [ ] AC7 — CI: `Python M0 unit tests` job green on the draft PR; `pytest tests/test_evals_data.py` count goes up versus `main` with 0 failures. Ruff: no findings on added lines.

## Verification
```bash
# CI (source of truth): Python M0 unit tests job on the draft PR (runs tests/test_evals_data.py via make test-py)
python -m pytest -q tests/test_evals_data.py            # sandbox; needs no DB, model or network (real-PG test skips)
ruff check --isolated --select E,F,W --line-length 130 scripts/evaluate_answers.py tests/test_evals_data.py
git diff origin/main --name-only   # exactly scripts/evaluate_answers.py, tests/test_evals_data.py, evals/README.md
git diff origin/main --shortstat
```
`make eval` (DoD 3): not required. The change only alters behaviour for malformed responses the query service never emits; say "not run: no retrieval/answer behaviour change" in the PR.

## Notes
- 2026-11-20 20:00Z (pm-lead): specced from two Backlog lines (EVAL-6 review; EVAL-10a QA nit 1 + missing test), combined because they share
  `tests/test_evals_data.py` and only one open PR may change that file at a time. The EVAL-7 `answer_review` follow-up and the EVAL-5
  `CHUNK_COUNTS_SQL` follow-up also live in `tests/test_evals_data.py` and stay in Backlog until this merges.
- Hint (not an AC): `isinstance(reason, str)` check before the truthiness test; keep `REFUSAL_REASONS` unchanged.
- 2026-11-21 (pm-lead): final review **APPROVE** ([report](../reviews/EVAL-6b/report.md)). PR [#96](https://github.com/MaheshPulivarthi18/ArxivLens/pull/96) raised: Evidence section in the description, ready for review, label `ready-to-merge`. QA `[spec]` finding 3 (the goal says "never crash on a malformed `/v1/ask` response", but the ACs cover `refusal_reason` only) is accepted as a wording gap in this spec. The other shapes (`citations` not a list, a non-dict citation item, a non-dict body) are now a Backlog follow-up (EVAL-6c candidate) together with QA nit 1 (E3 blank lines). QA nit 2 (PR body AC6 line) is resolved by the rewritten PR description. Merging frees `tests/test_evals_data.py` for the next EVAL-6c / EVAL-7 / EVAL-5 follow-up.
