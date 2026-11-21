# EVAL-8: First answer eval with a real LLM (local OpenAI-compatible model in the eval workflow, or a hosted key)

| | |
|---|---|
| **Owner** | pm-lead (umbrella). Work split 2026-11-22: [EVAL-8c](EVAL-8c.md) (ai, results record the LLM + BASELINE section, Ready), [EVAL-8a](EVAL-8a.md) (backend, `eval.yml` on Modal, Blocked on ADR-0021), [EVAL-8b](EVAL-8b.md) (ai, replayed LLM answers for PRs, Blocked on ADR-0021) |
| **Priority** | P1 |
| **PRD ref** | Product PRD QA-8, §8; ADR-0001 (Accepted: "pick the default by measuring both on `evals/`"; cost per answer open) |
| **Depends on** | QA-8 delivered (Mahesh #46 `cc57474`), EVAL-3 merged, EVAL-6 merged. Mahesh's option-3 decision: **answered 2026-11-21** (local run committed; CI on Modal chosen → ADR-0021) |
| **Jira** | KAN-46 |
| **Design required** | yes (new CI cost/runtime, possibly a secret) |
| **Status** | Blocked (umbrella; option 3 answered 2026-11-21: local run done, CI chosen). AC1 met, AC2 numbers met (BASELINE section → EVAL-8c), AC3 open → EVAL-8a. CI half waits on **ADR-0021** (Proposed). Closes when EVAL-8c and EVAL-8a merge |

## Goal
Fake-provider tests prove the plumbing, not the answers. Before QA-8's LLM path can be called "done" in the PRD, `make eval`
must run once with a real model and report supported-citation rate, correct refusal (incl. near-miss), citation coverage and
`/v1/ask` p95 against the Product PRD §8 targets, followed by a human review (EVAL-7) of a sample.

## Decision needed (Mahesh)
1. **Local in CI**: an Ollama (or llama.cpp) service in `eval.yml` with a small open model. No key and no per-token cost,
   but a CPU runner will likely miss the 3 s p95, and small models follow the citation format less reliably.
2. **Hosted**: a repository secret, run only on `workflow_dispatch` with a capped eval size. Needs the max cost per answer from ADR-0001 first.
3. **Mahesh runs it locally** and attaches the results JSON. No CI change.

## Acceptance criteria (draft, finalised once unblocked)
- [x] AC1 — One completed `make eval` run with `LLM_MODEL` set; results JSON attached; model, host and machine profile recorded.
- [ ] AC2 — (numbers met 2026-11-21; template-path comparison in `evals/BASELINE.md` → EVAL-8c AC7) (moved from QA-8 old AC3) supported ≥ 90%, correct refusal ≥ 95%, `/v1/ask` p95 < 3 s reported against the template-path
      baseline. A miss is a finding for pm-lead/Mahesh: no threshold changes.
- [ ] AC3 — (open → EVAL-8a: the local run's `query.log` wasn't kept; cost 0 locally, Modal cost per ADR-0021 Q4) Token usage per answer reported (QA-8 log line), and the cost per answer for a hosted model.

## Notes
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
