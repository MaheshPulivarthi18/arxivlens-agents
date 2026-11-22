<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-22T02:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/122#issuecomment-7070242341 (posted 2026-11-21T22:31:33Z); the QA harness could not write this file. -->

[qa-reviewer] QA report: EVAL-8c · PR #122 · round 1

**Verdict:** FAIL
**Reviewed commit:** `b91f78e6389eb64915bd25403a521f9408f6268d` · **Date:** 2026-11-22
**Ticket:** [`agents/tasks/EVAL-8c.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/EVAL-8c.md) · **PRD:** Product PRD QA-8, §8; EVAL-8 AC1–AC2; ADR-0021 (Proposed) R3/R4 data only

Evidence pack: arxivlens-agents commit [`1a227a6`](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence). Every `.png` has a `.txt` beside it with the full output, and the harness sources are printed after the results.

**In one line:** the code does what the spec asks and CI is green. But the only "no probe without `LLM_MODEL`" test also leaves `LLM_BASE_URL` unset, so the guard is never exercised. Deleting the `model` half of `if model and root:` survives all 285 tests. With `LLM_BASE_URL` set and `LLM_MODEL` unset, that mutant sends the bearer key and records another model's digest under `model: null` (AC2, AC6 m6).

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 137004563980 | success |
| Python M0 unit tests | CI job 137004564072 (`test-py-light`: `tests/test_evals_data.py` + 3 → `317 passed, 1 skipped`) | success |
| Frontend (lint, test, build) | CI job 137004563676 | success |
| Agent ownership check | CI job 137004563941 | success |
| DB / Full stack (compose + make test-full) | CI 137004563781 / 137004563546 | success / success |
| `pytest -q tests/test_evals_data.py` | local, PR head | 285 passed, 1 skipped |
| `ruff check --isolated --select E,F,W --line-length 130` (3 files) | local | All checks passed |
| `git diff origin/main --name-only` | local (merge-base = origin/main = `53171d6`) | exactly the 5 named files |
| `make test-py-light` | not run locally: `confluent_kafka` can't be installed in the sandbox; CI ran it (above) | — |
| `make eval` | not run: report-only metadata, no retrieval or answer change. The `check_thresholds` differential has 0 diffs (06) | — |

CI ran on `c2f111a` = "Merge b91f78e… into 53171d6…" (current main) ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence/00-ci-checks.png?raw=true)). ``

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `test_llm_block_names_model_host_version_digest_and_never_leaks` checks the exact 7-key block, both requests with `Bearer sk-test-SECRET`, timeout ≤ 5, and a JSON/stdout/stderr grep for `sk-test-SECRET`/`u:p`/`x=1` ([01](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence/01-AC1-llm-block-tests.png?raw=true)). ``` Independently, I ran the real `eval_gate.main` against a **real local HTTP server** (no urllib fake) with `LLM_BASE_URL=http://u:p@127.0.0.1:<port>/v1?x=1`. The server received `/api/version` and `/api/tags` with `Bearer sk-test-SECRET`, the block was exact, and nothing leaked. With no key set, no `Authorization` header was sent ([02](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence/02-AC1-AC2-real-socket-probe.png?raw=true)). ```` |
| AC2 | ⚠ partly | Cases (a)–(d) pass in `test_probe_failure_never_changes_the_run[refused/401/model-missing/non-json]` ([03](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence/03-AC2-probe-failure-tests.png?raw=true)). ````` The real-socket probe agrees and adds two cases: a 7 s server (`TimeoutError` after 2 × 5 s) and an `ftp://` URL. All exit codes equal the success run's (02). **But** "With `LLM_MODEL` unset, no probe request is made" is only checked with `LLM_BASE_URL` also unset, so the test can't fail at the model guard (Finding 1, [08](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence/08-AC6-survivors-behaviour.png?raw=true)). `````` |
| AC3 | ✅ | `test_case_record_carries_answer_kind_and_citation_status` covers the synthesized, quoted and refusal fixtures, plus a non-string `answer_kind` → null. The `answer_review` tests pass. An ast diff shows no `answer_review`-calling test changed, `scripts/answer_review.py` is unchanged, and its fingerprint is still `(marker, chunk_id, score, supported)` ([04](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence/04-AC3-case-record-and-answer-review.png?raw=true), ``````` [06](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence/06-AC5-gate-unchanged.png?raw=true)). ```````` |
| AC4 | ✅ (as written) | The rate is stored as the exact `2/3`; 0 answered → `(None, 0)`; the 4-row warning matrix passes; warnings go to stderr and the exit code is unchanged ([05](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence/05-AC4-rate-and-warnings.png?raw=true)). ````````` The scope's "across … near-miss sets" is untested (Finding 2). |
| AC5 | ✅ | ast diff: 0 of 10 `test_gate_*` functions changed. The 3 changed tests are the exact-dict `case_record` tests, and none lost an assertion. A differential plugin also ran each of the 47 `check_thresholds` calls in the head's test file (13 with an `llm` block) through origin/main's `check_thresholds`: **0 differing outputs**. `test_llm_block_adds_no_check` passes (06). |
| AC6 | ❌ | I ran 20 anchored single-edit mutants on local copies (none pushed), with a green control run. m1, m2, m3a, m3b, m4 and m5 were KILLED. Of the two m6 variants, **m6a `if model and root:` → `if root:` SURVIVED** and m6b (default URL even without a model) was KILLED. Of the 14 extras, 12 were KILLED and **x1 (near-miss not counted) SURVIVED** ([07](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence/07-AC6-mutants.png?raw=true)). `````````` Both survivors change behaviour (08). |
| AC7 | ✅ | All 11 rows of the "Real LLM (reported, local)" table match the committed `baseline-local-20261121T212749Z.json` (0 diffs). The 3 observations match the per-case records: `n003` chunk 239 `supported=False` 0.0551; `a001` (98, 2)×3; `a020` (1680, 1)×2; no other duplicates. The extractive column equals the existing gate table. Ollama/model/ID match the EVAL-8 README, and `evals/README.md` documents the `llm` block and both per-case keys ([09](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence/09-AC7-baseline-vs-json.png?raw=true)). ``````````` One labelling nit (Finding 3). |
| AC8 | ✅ | `Python M0 unit tests` and `Agent ownership check` succeeded on `b91f78e` (00). Locally the diff is exactly the 5 named files, ruff is clean, and `ownership-check.sh` reports "Ownership OK for role=ai (290 changed lines)" ([10](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1a227a6631c14bdff8a49e7be6ba5ae752930a8a/agents/reviews/EVAL-8c/evidence/10-AC8-files-ruff-ownership.png?raw=true)). ```````````` |

## Scope / PRD fit
**Scope:** all 5 files are ai-owned and named in the ticket. Nothing touches `check_thresholds`, `thresholds.json`, `.github/`, `internal/` or the app `README.md`. No tickets or reviews leaked in. 290 changed lines, under the 300 stop.

**PRD fit:** this delivers EVAL-8 AC1's "which model answered" as report-only data. It reports probe failures honestly (`null` plus `probe_error`), never changes the gate, and keeps secrets out of the results. AC2's baseline is marked as reported, not re-measured. Once Finding 1 is fixed, it serves QA-8/§8 as intended.

## Findings
1. **[blocking] AC2/AC6: the "no probe without `LLM_MODEL`" test never reaches the model guard.** `test_no_probe_without_llm_model` sets only `LLM_API_KEY`, so `base` is `""` and `root` is `None`. The test passes because there is no URL, not because `LLM_MODEL` is unset. Mutant m6a (`llm_info`: `if model and root:` → `if root:`) survives all 285 tests (07). On a real socket with `LLM_BASE_URL` set and `LLM_MODEL` unset, m6a sends `Authorization: Bearer sk-test-SECRET` to both endpoints. It also records `digest: ffff…` from a **different** listed model under `model: null`, because `None in (m.get("name"), m.get("model"))` matches an entry that has no `model` key. The head makes 0 requests in the same setup (08). This is the realistic misconfiguration (`LLM_BASE_URL` exported, `LLM_MODEL` forgotten). **Fix:** add a row with `{"LLM_BASE_URL": LLM_ENV["LLM_BASE_URL"], "LLM_API_KEY": "sk-test-SECRET"}` and no model, asserting `calls == []` and `digest is None`. Keep the no-URL row and rerun m6a.
2. **[nit] The scope says the rate counts "across the answer, refusal and near-miss sets", but no test covers the near-miss set.** Mutant x1 (count only `set == "answer"`) survives (07), and it changes behaviour. When the only synthesized answer is a near-miss (the `n003` case behind this ticket), the head gives `(0.5, 1)` and warns; x1 gives `(0.0, 0)` and stays silent (08). **Fix:** add an answered, synthesized near-miss case to `test_synthesized_answer_rate_counts_answered_full_responses_only` (pass `near_miss_cases` to `evaluate`).
3. **[nit] `evals/BASELINE.md` labelling.** The "ask_p95_ms (quick stage, gated on GPU)" row shows the extractive `13330.2916` from the 2026-11-16 run. That run predates quick-stage timing (`quick_ask` arrived in #120, `c2b3bd6`, 2026-11-21), so the value is a full-answer p95. Mark that cell "(full answer, pre-ADR-0019)". Also, line 18 ("this file has no GPU baseline") and line 72 ("not a baseline value here") now sit next to a GPU section; "no GPU *CI* baseline" would be accurate.
4. **[nit] Warning text when nothing was answered.** If `LLM_MODEL` is set and 0 cases were answered (rate `null`, e.g. all refused), the warning still says "(every answer was quoted)". Skip it when the rate is `None`, or say "0 of N answered were synthesized".
5. **[spec] AC2/AC6 wording (pm-lead).** "With `LLM_MODEL` unset, no probe request is made" doesn't require `LLM_BASE_URL` to be set in that row, which is how Finding 1 got through. Suggest adding "(with `LLM_BASE_URL` and `LLM_API_KEY` set)" to AC2, and "m6 = drop the `LLM_MODEL` condition of the probe guard" to AC6.

## Missing tests
- No-model probe guard with a base URL set (Finding 1).
- An answered near-miss case in `synthesized_answer_rate` and in the unset-model warning (Finding 2).
- A `sha256:`-prefixed `/api/tags` digest: the code strips the prefix, but no test exercises it.
- An IPv6 `LLM_BASE_URL` (`http://[::1]:11434/v1` → `[::1]:11434`), which has its own branch in `_llm_root`.
- A probe timeout row. The real-socket probe shows timeouts are handled, but no unit row covers them.

## Hand-off
FAIL → back to ai-engineer. Finding 1 must be fixed; Findings 2–4 are cheap to include in the same round. Finding 5 → pm-lead.
Note: the QA harness refused to write `agents/reviews/EVAL-8c/report.md` ("subagents return findings as text"). This comment is the report, verbatim, for the orchestrator to save there with a provenance line.


---
_Generated by [Claude Code](https://claude.ai/code)_
