# EVAL-6c: Answer eval fails closed on every malformed `/v1/ask` shape (body, `citations`, citation items, `claims`)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P3 (harness/quality: one bad response must not crash the whole `make eval` run) |
| **PRD ref** | Product PRD §8 (answer metrics, method notes); ADR-0003 (Accepted: anything that isn't a valid refusal is an error). Follow-up from the EVAL-6b QA/PM review: QA finding 3 `[spec]` (probe 10) and nit 1 (`agents/reviews/EVAL-6b/report.md`, evidence `10-probe-other-shapes.txt`, `04-ruff.txt`) |
| **Depends on** | EVAL-6b (ArxivLens #96) **merged** as `cb5d833` (same files). No open PR on `scripts/evaluate_answers.py`, `tests/test_evals_data.py` or `evals/README.md` (checked 2026-11-21 05:00Z: no open ArxivLens PRs) |
| **Jira** | needs a story (orchestrator) under epic KAN-2 "Retrieval & answer quality gates"; labels `task-EVAL-6c`, `agent-ai`, `arxivlens` |
| **Design required** | no: no gate key, threshold, metric definition, contract, CLI or table change. A malformed response already counts as an error under ADR-0003; this makes the code do that instead of raising |
| **Status** | In QA (draft PR opened cycle 2026-11-21T05:00Z) |

## Goal
`make eval` must never crash on a malformed `/v1/ask` response. EVAL-6b fixed this for a non-string `refusal_reason`. QA's probe 10
(run on `c053564`, now `main`) shows three other shapes still raise inside `evaluate()` and kill the whole run, so one bad response blanks the gate:

```
RAISES citations=5 (non-list): TypeError: 'int' object is not iterable
RAISES citations=['str'] (non-dict item): AttributeError: 'str' object has no attribute 'get'
RAISES response is a list: AttributeError: 'list' object has no attribute 'get'
```

Each such response must count as **one error case**, as ADR-0003 and `evals/README.md`'s classification table require.

## Scope
- `scripts/evaluate_answers.py`: `classify()`, `case_record()`, `coverage_units()`, and the `call()` / `gated_call()` path inside `evaluate()`
  (`normalize_arxiv_id` only if the developer chooses that seam). No change to metric definitions, gate keys or the results JSON field names.
- `tests/test_evals_data.py`: new tests next to the EVAL-6b block (`# EVAL-6b: a non-string refusal_reason …`, l.1058 at `11c4696`), plus the
  blank-line nit (AC6).
- `evals/README.md`: the classification table (l.104-111 at `11c4696`) gains one row for malformed shapes (AC5).
- Allowed files (from Scope + Docs): exactly these three.
- Out of scope: `make_http_ask` (it already returns `None` for undecodable JSON), `eval_gate.py`, `evals/thresholds.json`, the EVAL-7
  `build_rows` and EVAL-5 `CHUNK_COUNTS_SQL` follow-ups (they come next on `tests/test_evals_data.py`, after this merges), any `rag.go` change.
- Size: ~30-50 production lines + ~80-120 test lines. Stop and report if > 300.

## Acceptance criteria
- [ ] AC1 — **Non-dict body.** A `/v1/ask` result that is valid JSON but not an object (list, string, number, `true`) is handled exactly like a
  failed request (`None`): outcome `error`, its case ID is in `error_case_ids` (answer and refusal sets) or `near_miss_error_ids` (near-miss set),
  it does **not** count in `requests_ok` (so an all-malformed run still trips `eval_gate.py`'s `requests_ok == 0` "could not run" path), its latency
  is handled as today for its set (answer/refusal calls stay in the gated latency list as measured; near-miss calls stay out of it), and its `cases` record has `outcome: "error"`, `refusal_reason: null`, `citations: []`.
- [ ] AC2 — **Malformed `citations` in a dict body.** `classify()` returns `error` when (a) `citations` is present, not `null` and not a list;
  (b) any item of a list `citations` is not a dict; (c) any citation item has an `arxiv_id` that is present, not `null` and not a string.
  Such a response counts in `requests_ok` (the HTTP call worked), counts once in `error_case_ids`, is never a correct refusal or an answer-set hit,
  and adds nothing to `citations_total` / `supported_citation_rate`. Its `cases` record has `citations: []` for (a), and keeps only the dict
  items for (b) (no exception in `case_record`).
- [ ] AC3 — **Report-only `claims`.** `coverage_units()` never raises: a `claims` item that isn't a dict, a `markers` value that isn't a list,
  and marker entries that aren't ints (incl. strings like `"1"` and unhashables like `[1]`) count that claim's unit as **uncited**; a citation
  `marker` that isn't an int is ignored when building the in-range set. None of these changes the outcome (`answered` stays `answered`).
  Test rows cover a string `markers` (`"12"`, today silently split into characters) and an int `markers` (`5`, today `TypeError`).
- [ ] AC4 — **No crash, property-style.** A parametrized test runs `evaluate()` (answer, refusal and near-miss sets, one case each) with each of
  the hostile values `None, 0, 5, True, "s", [], ["x"], {}, {"k": 1}` placed at each position: whole body, `citations`, `citations[0]`,
  `citations[0].arxiv_id`, `citations[0].marker`, `claims`, `claims[0]`, `claims[0].markers`, `claims[0].markers[0]`. Every run completes,
  returns the metrics dict, and every case's `outcome` is one of `error | refusal | answered` and matches AC1-AC3 (e.g. body/`citations`/item/
  `arxiv_id` shapes → `error`; `[]` or `None` `citations` → today's rules; `claims` shapes → unchanged outcome). Keep the existing EVAL-6b rows
  (`NON_STRING_REASONS`) green unchanged.
- [ ] AC5 — `evals/README.md` classification table: one row "malformed response (body not an object, `citations` not a list, a non-object
  citation, a non-string citation `arxiv_id`)" → **error**, `ask_error_count` +1, not refused; and one sentence under the report-only
  `citation_coverage` notes that malformed `claims`/`markers` count as uncited units.
- [ ] AC6 — Lint. `ruff check --isolated --select E,F,W --line-length 130 scripts/evaluate_answers.py tests/test_evals_data.py` has no findings.
  EVAL-6b QA nit 1: `ruff check --isolated --preview --select E3 --line-length 130 tests/test_evals_data.py` loses the four EVAL-6b findings
  (l.1058, 1130, 1202, 1212 at `11c4696`) and adds none on new lines (the two pre-existing ones at l.780 and 811 may stay or go). Paste before/after.
- [ ] AC7 — Mutants (developer or QA harness, run locally, never pushed; output in the PR or the evidence pack), each killed by
  `python -m pytest -q tests/test_evals_data.py`, **one per operand** of the new guards: (m1) drop the non-dict body check; (m2) drop the
  "`citations` not a list" check; (m3) drop the "item not a dict" check; (m4) drop the non-string `arxiv_id` check; (m5) count a non-dict body in
  `requests_ok`; (m6) `coverage_units` accepts a string `markers` again; (m7) `case_record` keeps non-dict citation items. Report any mutant that
  doesn't change behaviour as INVALID, not KILLED.
- [ ] AC8 — CI `Python M0 unit tests` job (step "Light tests without the ML stack (make test-py-light)") green on the PR and its pass count is higher than `main`'s by the number of
  new test cases (quote both counts); `Agent ownership check` and `Full stack` green (`tests/**` triggers `stack.yml`).

## Verification
```bash
cd app
python -m pytest -q tests/test_evals_data.py                       # light deps only (requirements-light.txt)
ruff check --isolated --select E,F,W --line-length 130 scripts/evaluate_answers.py tests/test_evals_data.py
ruff check --isolated --preview --select E3 --line-length 130 tests/test_evals_data.py   # AC6 before/after
git diff origin/main --name-only   # exactly scripts/evaluate_answers.py, tests/test_evals_data.py, evals/README.md
make test-unit                     # CI is the source of truth (test-py-ml needs torch)
# CI: python job "Light tests without the ML stack (make test-py-light)"; Full stack job
```

## Notes
- 2026-11-21 (ai-engineer, cycle 05:00Z): `1f3bd31` on `agent/ai/EVAL-6c` → draft PR [#107](https://github.com/MaheshPulivarthi18/ArxivLens/pull/107) (3 files, +170/−9; ownership OK). Non-object body → failed request; `_citations_ok()` makes malformed `citations` an error; `_citation_items()` for `case_record`/`coverage_units`; malformed `claims`/`markers` (not a list of non-bool ints, all-or-nothing per claim) are uncited; non-int citation `marker` ignored; non-string `answer` has no units (beyond the listed positions). Local `tests/test_evals_data.py`: 142 → 261 passed (+119 incl. 81-case property test; new tests fail 64× on main's file). ruff E,F,W clean; E3 6 → 2 (the two pre-existing). Mutants m1–m5, m7 killed; m6 INVALID (equivalent). `make eval`/`test-unit`/`lint` not run (no infra / Go 1.25).
- 2026-11-21 05:00Z (pm-lead): specced from the EVAL-6b final review Backlog line (QA finding 3 `[spec]`, probe 10, and nit 1). Code read at
  `11c4696`: `classify()` l.75-84 only guards `refusal_reason`; `call()` l.193-198 calls `_reason_str(resp or {})` and `case_record()`, both
  `.get` on the body; `gated_call()` l.206 calls `resp.get`; `case_record()` l.151-152 calls `c.get` on each citation item; `coverage_units()` l.135-140
  does `set(c.get("markers") or [])`; `normalize_arxiv_id()` l.53-54 calls `.strip()` on a non-string. Hint (not an AC): normalising a non-dict body
  to `None` at the top of `call()` gives AC1 in one place; a small `_citations_ok(resp)` helper used by `classify()` keeps AC2's three operands
  separate for AC7. The old "String `claims[].markers` → note for AI-8" item is covered by AC3 on the eval side; the server side stays as is.
