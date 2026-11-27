# EVAL-8: Real-LLM answer eval in CI on Modal (built by Mahesh)

| | |
|---|---|
| **Owner** | **Mahesh** (human). He builds it himself (planned 2026-11-29). Agents don't build it; pm-lead keeps this spec and the board truthful |
| **Priority** | P1 |
| **PRD ref** | Product PRD QA-8, §8; ADR-0001 (Accepted), ADR-0019 (Accepted), ADR-0021 (Proposed, **Mahesh's decision**: triggers A–C, could-not-run rules R1–R4, PR replay P1–P3, budget), ADR-0024 (reference model) |
| **Depends on** | EVAL-8c merged (#122 `6d43de4`: results record model, host, Ollama version + digest, `answer_kind`). Mahesh's Modal endpoint + GitHub secrets |
| **Jira** | KAN-46. KAN-125 (EVAL-8a), KAN-126 (EVAL-8b) and KAN-129 (EVAL-8d) are closed and point here. KAN-127 = the ADR-0021 decision |
| **Tier** | Large (CI cost, secrets). Design: ADR-0021 is the design; Mahesh decides it |
| **Size estimate** | Mahesh's call. The agent drafts below come to about 400 lines (`eval.yml` ~150, `scripts/llm_replay.py` + tests ~200, two digest tests ~60) |
| **Absorbs** | EVAL-8a (KAN-125), EVAL-8b (KAN-126), EVAL-8d (KAN-129) |
| **Status** | Mahesh building (2026-11-28). AC1 met, AC2 numbers met (local run 2026-11-21, EVAL-8c BASELINE section), AC3 open |

## Goal
CI measures written (`answer_kind: synthesized`) answers with the same model as Mahesh's local baseline
(`qwen2.5:3b-instruct` @ `357c53fb659c`, Ollama `0.40.16`). A run where the LLM silently fell back, or where a
different model answered, ends red (exit 2), never as a misleading green. Gate thresholds stay as they are.

## Acceptance criteria
- [x] AC1: one completed `make eval` with `LLM_MODEL` set; results JSON attached; model, host and machine recorded (2026-11-21, `agents/reviews/EVAL-8/`).
- [x] AC2: supported ≥ 90%, correct refusal ≥ 95%, quick-stage p95 < 3 s on the reference profile (local runs 2026-11-21/22; EVAL-8c BASELINE section).
- [ ] AC3: token usage per answer and Modal GPU-seconds (or wall time) per CI run reported (ADR-0021 Q4 cost).
- [ ] AC4 (was EVAL-8a AC1): a `workflow_dispatch` run of `eval.yml` with the secrets: warm-up passes, `make eval` exits 0 or 1 (not 2), and the summary shows model,
  digest `357c53fb659c`, `synthesized_answer_rate` > 0, and token usage.
- [ ] AC5 (was EVAL-8a AC2, rules R1–R4): each could-not-run case ends exit 2 with its own `::error::`: a missing secret, the warm-up budget exhausted, a digest mismatch, 0 synthesized answers.
- [ ] AC6 (was EVAL-8a AC3/AC4): no secret value in any job log, and secrets only on the R1 steps. Unlabelled PR runs keep the LLM-less behaviour (or replay, AC7).
- [ ] AC7 (was EVAL-8b, if ADR-0021 picks P1): PR runs replay recorded real-LLM answers (`scripts/llm_replay.py` record/serve, sha256 of the canonical request body as the
  key, 404 on a miss, `hits/misses` in the summary, the key never stored or logged).
- [ ] AC8 (was EVAL-8d): two `tests/test_evals_data.py` pins. `main` passes `rate` to `llm_warnings` (an all-refused run gives no "0 answers were synthesized"
  warning), and a `sha256:`-prefixed `/api/tags` digest gives `digest` = 64 hex and `digest_short` = 12 hex (ADR-0021 R3 relies on this).
- [ ] Docs: `CONTRIBUTING.md` eval section, the `eval.yml` header ("No secrets"), and the app README eval lines.

## Checklist
- [ ] Mahesh: record the ADR-0021 decision (Q1 triggers, Q2 R1–R4, Q3 replay option, Q4 budget) by setting its Status, or ask pm-lead to write it up from chat.
- [ ] Detailed drafts, kept for reference: `agents/tasks/EVAL-8a.md` (eval.yml steps, budget table), `EVAL-8b.md` (replay proxy), `EVAL-8d.md` (the two tests).

## Notes
- 2026-11-28 (pm-lead, process reset): owner → Mahesh, who implements the Modal eval himself. EVAL-8a/8b/8d are absorbed (ACs above). Agents don't build or ticket any part of it this cycle.
- 2026-11-22 cycle 2026-11-21T21:59Z (pm-lead): **option 3 answered.** Mahesh ran it locally (results JSON committed in `3d8cab1`) and wants CI on Modal
  as well. Checked against the ACs with the committed JSON (`agents/reviews/EVAL-8/baseline-local-20261121T212749Z.json`):
  - **AC1 met.** One completed `make eval` with the LLM on; the JSON is attached; model, host (Ollama `0.40.16` on localhost) and machine (M4, `mps`) are
    recorded in the evidence README, *reported by Mahesh*. The JSON itself doesn't name the model, which is EVAL-8c's job. The full-answer latencies
    (6–19 s) show synthesis ran.
  - **AC2: numbers met, write-up open.** `supported_citation_rate` 1.0000 (≥ 0.9), `correct_refusal_rate` 1.0000 (≥ 0.95), gated quick-stage
    `ask_p95_ms` 2423 (< 3000, ADR-0019), `ask_errors` 0, GATE PASS. Not yet done: the comparison with the template-path (extractive) baseline in
    `evals/BASELINE.md` → EVAL-8c AC7.
  - **AC3 open.** Token usage per answer isn't in the JSON, and the run's `query.log` wasn't kept. Cost per answer is 0 locally. CI will report tokens
    from `query.log` (EVAL-8a), and Modal GPU cost waits on ADR-0021 Q4.
  - New ADR [ADR-0021](../../docs/adr/0021-real-llm-ci-eval-gate.md) (Proposed) covers the CI gate. Three observations from the evidence README go to Backlog
    (n003 unsupported citation in an answered response, duplicate citations, full p95 16.8 s) and are triaged after EVAL-8c records `answer_kind`.
- 2026-11-21 ~21:30Z (orchestrator, from Mahesh live in session_01ATEBeRawKzi1RDhbRiuzYB): Mahesh ran `make eval` locally with a real LLM: Ollama `0.40.16`, `qwen2.5:3b-instruct` @ `357c53fb659c`, M4. **GATE: PASS**: supported 100% (44), correct refusals 100% (22), quick p95 2423 ms, full p95 16786 ms (report-only), near-miss 93.33% (`n003` answered). Results JSON and observations: [reviews/EVAL-8/](../reviews/EVAL-8/README.md). He chose **CI on Modal running the same Ollama model** (not OpenRouter, which has no 3B Qwen2.5 and serves different weights). Next: an ADR (Proposed) for the real-LLM CI eval gate plus EVAL-8a (backend: `eval.yml` secrets, warm-up, model and digest in results) and EVAL-8b (ai: replayed `/v1/ask` fixtures). Mahesh does the Modal deploy and GitHub secrets himself.
- 2026-11-07 (pm-lead): created so that QA-8's deferred LLM measurement has an owner (lesson 2026-11-03 RET-1). Not among the 15 started tasks.
- 2026-11-17 (pm-lead, grooming): **Mahesh effectively ran option 3** in #46 (`cc57474`): local `qwen2.5:3b-instruct` on Ollama, Apple M4,
  31-paper corpus, `LLM_TIMEOUT=30s`. Reported, not re-measured (PR body numbers; no results JSON in either repo):
  - AC1: model, host and machine are recorded in the PR body. **Missing: the results JSON.**
  - AC2 (after his two-stage product decision): answerable questions refused 0%, answers citing the expected paper 95%, near-miss refusals
    93%, out-of-corpus refusals 100%. Quoted answer 1.1–2.4 s warm; written answer p50 1.8 s / p95 10.2 s. Supported citations were 79% before the
    quote-fallback decision; the after-table doesn't report it. Against §8: correct refusal ≥ 95% is met, supported ≥ 90% is **not shown**, and
    p95 < 3 s is met only by the quick stage, which needs the §8 wording change in Proposed ADR-0018.
  - AC3: token counts are in the `synthesis` log line; cost per answer is 0 (local model).
  If Mahesh confirms option 3: he attaches the JSON (to #46 or to this repo's `agents/reviews/EVAL-8/`; `evals/results/` is git-ignored), ai-engineer adds a
  "real LLM (reported)" section to `evals/BASELINE.md`, and this closes. The supported-citation number for the written stage stays an open finding.
- 2026-11-21 21:00Z cycle (pm-lead, grooming): ADR-0019 and ADR-0020 (both Accepted 2026-11-22) record two more full local `make eval` runs with the
  LLM on (reference Mac, MPS, `qwen2.5:3b-instruct`, main `391eceb` / `c2b3bd6`): supported citations 0.86 → 1.00 after ADR-0019 (written answers show
  only verified citations), expected-paper hits 100%, refusals 100%, gated quick-stage `ask_p95_ms` 2.95 s PASS with fp16 (#121), written-answer
  `ask_full_p95_ms` ~20 s report-only. The "supported ≥ 90% not shown" gap above is answered by these numbers (reported in ADR text, not re-measured).
  Still no results JSON in either repo, and Mahesh's question (option 3 vs CI/hosted) is unanswered, so still Blocked.
