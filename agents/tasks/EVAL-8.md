# EVAL-8: First answer eval with a real LLM (local OpenAI-compatible model in the eval workflow, or a hosted key)

| | |
|---|---|
| **Owner** | backend-engineer (workflow) + ai-engineer (reading results, `evals/BASELINE.md`): split into two tickets once the decision below is made |
| **Priority** | P1 |
| **PRD ref** | Product PRD QA-8, §8; ADR-0001 (Accepted: "pick the default by measuring both on `evals/`"; cost per answer open) |
| **Depends on** | QA-8 delivered (Mahesh #46 `cc57474`), EVAL-3 merged, EVAL-6 merged. **A decision from Mahesh** (below): whether his local run in #46 is the answer (option 3) |
| **Jira** | not yet: create it when it's unblocked |
| **Design required** | yes (new CI cost/runtime, possibly a secret) |
| **Status** | Blocked (needs Mahesh: is his local qwen2.5:3b run in #46 option 3, i.e. EVAL-8 done with no CI change? If yes, attach or commit the results JSON and this closes; if he wants CI or hosted runs, pick option 1 or 2) |

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
- [ ] AC1 — One completed `make eval` run with `LLM_MODEL` set; results JSON attached; model, host and machine profile recorded.
- [ ] AC2 — (moved from QA-8 old AC3) supported ≥ 90%, correct refusal ≥ 95%, `/v1/ask` p95 < 3 s reported against the template-path
      baseline. A miss is a finding for pm-lead/Mahesh: no threshold changes.
- [ ] AC3 — Token usage per answer reported (QA-8 log line), and the cost per answer for a hosted model.

## Notes
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
