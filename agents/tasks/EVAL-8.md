# EVAL-8: First answer eval with a real LLM (local OpenAI-compatible model in the eval workflow, or a hosted key)

| | |
|---|---|
| **Owner** | backend-engineer (workflow) + ai-engineer (reading results, `evals/BASELINE.md`): split into two tickets once the decision below is made |
| **Priority** | P1 |
| **PRD ref** | Product PRD QA-8, §8; ADR-0001 (Accepted: "pick the default by measuring both on `evals/`"; cost per answer open) |
| **Depends on** | QA-8 merged, EVAL-3 merged, EVAL-6 merged; **a decision from Mahesh** (below) |
| **Jira** | not yet: create it when it's unblocked |
| **Design required** | yes (new CI cost/runtime, possibly a secret) |
| **Status** | Blocked (needs Mahesh: which model and where it runs; for a hosted model, the cost cap from ADR-0001) |

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
