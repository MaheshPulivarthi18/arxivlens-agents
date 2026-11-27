# EVAL-8c: Eval results record which LLM answered (model, host, Ollama version + digest, `answer_kind`)

| | |
|---|---|
| **Owner** | ai-engineer (`scripts/`, `tests/`, `evals/`) |
| **Priority** | P1 (Mahesh's direction 2026-11-21; first step of EVAL-8's CI half) |
| **PRD ref** | Product PRD QA-8, §8; EVAL-8 AC1–AC2; ADR-0021 (Proposed) rules R3/R4 *data only* |
| **Depends on** | EVAL-6c (#107, `bf37354`) and AI-14 (#115, `53171d6`) merged. **No ADR wait**: report-only metadata, no threshold, check or exit-code change (see Notes) |
| **Jira** | needs a story (orchestrator) under epic KAN-2 "Retrieval & answer quality gates"; labels `task-EVAL-8c`, `agent-ai`, `arxivlens`; link KAN-46 (EVAL-8) |
| **Design required** | no: report-only fields in an existing script's output; no CLI command, table, service or shared contract |
| **Status** | Ready to merge (#122 raised 2026-11-27; QA PASS r2, PM APPROVE) |

## Goal
Mahesh's GATE-PASS real-LLM run (`agents/reviews/EVAL-8/`) can't prove from its JSON which model answered, or whether a
given answer was LLM-written or a quoted fallback (observation 1, `n003`). Every `make eval` results file should say so,
locally today and in CI once ADR-0021 is decided. Also record the local baseline in `evals/BASELINE.md` (EVAL-8 AC2).

## Scope
- `scripts/eval_gate.py`: a top-level `"llm"` block in the results JSON and one `llm:` line printed next to the existing
  `hardware:` line (`eval_gate.py:194`):
  - `model`: `LLM_MODEL` from the eval process env, or `null`; `source: "env"`.
  - `host`: hostname[:port] of `LLM_BASE_URL` (default `http://localhost:11434/v1` only when `LLM_MODEL` is set, mirroring
    `internal/llm/config.go`). **Never** the scheme+path+query, never `LLM_API_KEY`.
  - `ollama_version` / `digest` / `digest_short` (first 12 hex): best effort from `GET <base without /v1>/api/version` and
    `GET …/api/tags` (the entry whose `name` or `model` equals `LLM_MODEL`), sent with `Authorization: Bearer $LLM_API_KEY`
    when that is set, short timeout (≤ 5 s each). Any failure → `null` plus a `probe_error` string (no key in it); never raises,
    never changes the exit code.
  - `synthesized_answer_rate` (report-only): answered full responses with `answer_kind == "synthesized"` / all answered full
    responses, across the answer, refusal and near-miss sets; `null` when none answered.
  - Warnings (stderr, exit code unchanged): `LLM_MODEL` unset but synthesized answers > 0 ("written answers came from an
    LLM the eval can't name; export LLM_MODEL for make eval too"); `LLM_MODEL` set but 0 synthesized answers.
- `scripts/evaluate_answers.py`: `case_record` adds `answer_kind` (string or `null`) and, per citation, `status`
  (ADR-0014 string or `null`). Nothing else in the metrics changes.
- `tests/test_evals_data.py`: tests below. Fakes only (monkeypatched `urllib`/env); no network.
- `evals/README.md`: the results-file description gains the `llm` block and the two new per-case keys (grep
  `git -C app grep -n "results/" origin/main -- evals/README.md` → `:14`, `:162`; add the text near `:14` or the
  "Latency is gated" section at `:95`, your call).
- `evals/BASELINE.md`: a new section "Real LLM (reported, local)" after the existing CPU sections: Mahesh's numbers from
  `agents/reviews/EVAL-8/baseline-local-20261121T212749Z.json` (profile GPU `mps`, M4; Ollama `0.40.16`,
  `qwen2.5:3b-instruct` @ `357c53fb659c`; reported, not re-measured), next to the extractive-path numbers already in the file,
  plus a link to the arxivlens-agents evidence README and the three open observations (`n003`, duplicate citations, full p95).
- Out of scope: `check_thresholds`, `evals/thresholds.json`, exit codes, `.github/` (EVAL-8a), any digest *comparison* or
  could-not-run rule (ADR-0021 R3/R4 enforcement → EVAL-8a/8b after the ADR), `internal/` (no `/healthz` change: the
  query service reporting its own model is an HTTP API change, Backlog item from EVAL-5), app `README.md`.
- Size target: ~150 changed lines incl. tests. Stop and report if > 300.

## Acceptance criteria
- [ ] AC1 — With `LLM_MODEL=qwen2.5:3b-instruct`, `LLM_BASE_URL=https://u:p@llm.example:8443/v1?x=1` and
      `LLM_API_KEY=sk-test-SECRET`, and faked `/api/version` → `{"version":"0.40.16"}` and `/api/tags` listing that model
      with digest `357c53fb659c…` (64 hex), the results JSON `llm` block is exactly `model`, `source`, `host`
      (`llm.example:8443`), `ollama_version`, `digest`, `digest_short` (`357c53fb659c`), `synthesized_answer_rate`, and
      the probe sent `Authorization: Bearer sk-test-SECRET` (test). Neither `sk-test-SECRET` nor `u:p` nor `x=1` appears
      anywhere in the written JSON or in captured stdout/stderr (test greps both).
- [ ] AC2 — Probe failures never fail the run: (a) connection refused, (b) HTTP 401, (c) `/api/tags` without the model,
      (d) non-JSON body each give `digest: null` and a `probe_error`, and `main` returns the same exit code as with the probe
      patched to succeed (parametrized test). With `LLM_MODEL` unset **and `LLM_BASE_URL` and `LLM_API_KEY` set**, no probe
      request is made (test asserts zero calls; a row with neither set is not enough).
- [ ] AC3 — `case_record` carries `answer_kind` and each citation's `status`; a response without them gives `null`
      (tests on one synthesized, one quoted and one refusal fixture). `answer_review.py`'s existing tests still pass unchanged
      (its drift fingerprint is not widened here).
- [ ] AC4 — `synthesized_answer_rate`: 2 synthesized + 1 quoted answered + 1 refusal → `0.6667` (4 dp) or the exact
      fraction your code stores, stated in the test; 0 answered → `null`. Both warnings fire on their conditions and not
      otherwise (4 rows: set/unset × 0/>0 synthesized).
- [ ] AC5 — Gate unchanged: `check_thresholds` output for the existing `_results()` fixtures is identical before/after
      (the existing `test_gate_*` tests pass unmodified), and no new `checks[]` entry exists.
- [ ] AC6 — Mutants, each failing ≥ 1 test (run locally, never pushed): (m1) write the full `LLM_BASE_URL` instead of the
      host; (m2) drop the `Authorization` header; (m3) let a probe exception propagate; (m4) count quoted answers as
      synthesized; (m5) drop `answer_kind` from `case_record`; (m6) drop the `LLM_MODEL` condition of the probe guard (probe whenever
      `LLM_BASE_URL` is set), so it must be killed by the AC2 row with `LLM_BASE_URL` set and `LLM_MODEL` unset.
- [ ] AC7 — Docs: `evals/README.md` documents the `llm` block and the per-case keys; `evals/BASELINE.md` has the
      "Real LLM (reported, local)" section with every number traceable to the committed JSON (QA diffs them).
- [ ] AC8 — CI on the draft PR: check-run `Python M0 unit tests` green (job runs `make test-py-light`, which includes
      `tests/test_evals_data.py`), `Agent ownership check` green. `ruff check --isolated --select E,F,W --line-length 130`
      clean on added lines of the changed `.py` files. `git diff origin/main --name-only` = exactly
      `scripts/eval_gate.py`, `scripts/evaluate_answers.py`, `tests/test_evals_data.py`, `evals/README.md`, `evals/BASELINE.md`.

## Verification
```bash
cd app
python -m pytest -q tests/test_evals_data.py
ruff check --isolated --select E,F,W --line-length 130 scripts/eval_gate.py scripts/evaluate_answers.py tests/test_evals_data.py
git diff origin/main --name-only
# optional, real stack + local Ollama: LLM_MODEL=qwen2.5:3b-instruct make eval  -> results JSON has a non-null llm.digest_short
```
`make eval` itself is not required (no retrieval or answering change; DoD 3 "not run: report-only metadata").
Confirm the CI job name with `gh api repos/MaheshPulivarthi18/ArxivLens/commits/<sha>/check-runs --jq '.check_runs[].name'`
before quoting it (lesson ING-9d).

## Notes
- 2026-11-22 (pm-lead): split out of Mahesh's "EVAL-8a (backend: … model + digest in results)". The results JSON is written by
  `scripts/eval_gate.py`, which is ai-owned (AGENTS.md §2), so the recording half is this ticket and the workflow half
  stays EVAL-8a. Why it doesn't wait on ADR-0021: it adds report-only fields and warnings only. No threshold, check,
  exit code or workflow changes, so the gate means the same thing before and after. Enforcing R3/R4 (digest mismatch or
  0 synthesized → exit 2) is a gate rule and waits on the ADR.
- Hint (not prescriptive): Ollama's native API lives at the server root, so strip a trailing `/v1` from `LLM_BASE_URL`.
  `ollama list`'s ID is the first 12 hex of the `/api/tags` `digest`.
- `answer_kind` per case answers EVAL-8 observation 1: if `n003`'s answer was `quoted`, its unsupported citation is the
  ADR-0003 flag (expected). If it was `synthesized`, that is an ADR-0019 bug ("written answers show only verified
  citations"). Triage that in the follow-up after this merges (Backlog), not here.
- 2026-11-22 (ai-engineer, build): branch `agent/ai/EVAL-8c` commit `b91f78e` (local, not pushed; orchestrator opens the
  draft PR). 5 files, 290 changed lines (over the ~150 target, under the 300 stop): `scripts/eval_gate.py`
  (`llm_info`/`probe_ollama`/`synthesized_answer_rate`/`llm_warnings`, `llm:` line, `llm` block),
  `scripts/evaluate_answers.py` (`answer_kind` + citation `status` in `case_record`), `tests/test_evals_data.py`
  (+15 tests), `evals/README.md`, `evals/BASELINE.md`. Local: `pytest tests/test_evals_data.py` 285 passed / 1 skipped;
  ruff clean; ownership check OK; mutants m1–m6 each killed. Three existing tests compared exact `case_record` dicts
  (`test_case_records_hold_ids_and_numbers_only`, `test_malformed_citations_are_one_error_case`,
  `test_claims_and_citation_fields_leave_eval_results_unchanged`); their expectations gained the two new keys (the AI-8b
  one now compares records minus the EVAL-8c keys), no assertion removed. `test_gate_*` and `answer_review` tests
  untouched. `llm.probe_error` is present only on a probe failure (absent when unprobed or successful), so AC1's
  success block has exactly the 7 keys. Not run: `make test-py-light` locally (`confluent_kafka` not installable in the
  sandbox, pre-existing; the other 3 light files pass), `make eval` (report-only metadata), Go tests (no Go change). AC8 is CI.
- 2026-11-22 (pm-lead, cycle 2026-11-22T02:00Z): QA r1 Finding 5 `[spec]` fixed. AC2's no-probe row now requires
  `LLM_BASE_URL` and `LLM_API_KEY` set with `LLM_MODEL` unset (the old wording let a row with no base URL pass, which is
  how Finding 1 slipped through), and AC6 m6 is now "drop the `LLM_MODEL` condition of the probe guard". No other AC
  changed; QA r2 checks both against the reworded text. Findings 1–4 stay with ai-engineer (rework running).
- 2026-11-22 (ai-engineer, rework after QA r1 FAIL): pushed `afed799` on `agent/ai/EVAL-8c` (was `b91f78e`). Now 300 changed
  lines over the same 5 files (at the 300 stop, not over it; `ownership-check.sh`: "Ownership OK for role=ai (300 changed lines)").
  - [x] Finding 1 (blocking): `test_no_probe_without_llm_model` is parametrized: `no-url` (the old row, unchanged) and `url`
        (`LLM_BASE_URL` + `LLM_API_KEY` set, `LLM_MODEL` unset), each asserting `calls == []` (so no Authorization sent) and
        `model`/`digest`/`digest_short` null (`host` = `llm.example:8443` in the url row). Mutant m6a (`if root:`) now fails
        `[url]` (2 probe calls with `Bearer sk-test-SECRET`); unmutated 287 passed / 1 skipped.
  - [x] Finding 2: the rate test adds an answered synthesized near-miss plus a quoted answer → `(1/2, 1)`. The 2/3 row is unchanged. Kills x1.
  - [x] Finding 3: `evals/BASELINE.md` extractive p95 cell says "(INFO; full answer, pre-ADR-0019)"; lines 18 and 72 now say "CI baseline".
  - [x] Finding 4: `llm_warnings(model, synthesized, rate=0.0)` skips the "0 synthesized" warning when `rate is None`.
        `main` passes the rate. Test: `llm_warnings(model, 0, None) == []`. A mutant that drops the check is killed.
  - Missing tests added: a probe `timeout` row and an IPv6 `_llm_root` assertion (an IPv6 mutant is killed). Not added: the `sha256:` digest
    prefix test, because it would have pushed the diff over 300. That needs a follow-up or a budget waiver.
  - Finding 5 (AC wording) is for pm-lead.
