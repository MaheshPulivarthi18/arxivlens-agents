# EVAL-8a: `eval.yml` runs the answer eval against the real LLM on Modal (secrets, warm-up, provenance checks, token usage)

| | |
|---|---|
| **Owner** | backend-engineer (`.github/`, `CONTRIBUTING.md`; app `README.md` eval lines) |
| **Priority** | P1 |
| **PRD ref** | Product PRD QA-8, §8; EVAL-8 AC1–AC3; ADR-0001 (cost per answer); ADR-0019; ADR-0021 (Proposed) |
| **Depends on** | **ADR-0021 Accepted** (which runs use the LLM, rules R1–R4, timeouts); **EVAL-8c merged** (the `llm` block and per-case `answer_kind` this workflow reads); **Mahesh**: Modal endpoint deployed and repository secrets `LLM_BASE_URL`, `LLM_API_KEY` set (he does both himself) |
| **Jira** | needs a story (orchestrator) under epic KAN-2 "Retrieval & answer quality gates"; labels `task-EVAL-8a`, `agent-backend`, `arxivlens`, `design-required`; link KAN-46 (EVAL-8) |
| **Design required** | **yes**: `docs/design/EVAL-8a.md`. It adds a secret, CI cost and runtime (EVAL-8's original flag), and needs a per-step budget table (lesson 2026-11-07 EVAL-3) |
| **Status** | Closed — merged into EVAL-8 (2026-11-28), owner Mahesh (AC3–AC6) |

## Goal
CI measures written (`answer_kind: synthesized`) answers with the same model as Mahesh's local baseline
(`qwen2.5:3b-instruct` @ `357c53fb659c`, Ollama `0.40.16`). A run where the LLM silently fell back, or where a different
model answered, ends red (exit 2), never as a misleading green. Gate thresholds stay as they are.

## Scope (draft; the accepted ADR text wins on any conflict, then pm-lead amends this ticket)
- `.github/workflows/eval.yml`:
  - Triggers per ADR-0021 Q1 (recommended A: the existing nightly + `workflow_dispatch` use the LLM; PRs only with the
    label `eval-llm`, so add `labeled` to `pull_request` types and make the LLM env conditional on it).
  - R1: `LLM_MODEL: qwen2.5:3b-instruct` and `LLM_MODEL_DIGEST_EXPECTED: 357c53fb659c` as plain env; `LLM_BASE_URL` /
    `LLM_API_KEY` from secrets, **only** on the query-service, warm-up and `make eval` steps. Missing secrets on an LLM
    run → exit 2 with `::error::LLM configured but no endpoint`.
  - R2: a warm-up step before `make eval` (tiny `/v1/chat/completions`, retried within the ADR's budget, prints elapsed as
    % of budget).
  - R3: after `make eval`, compare `llm.digest_short` from the results JSON with `LLM_MODEL_DIGEST_EXPECTED`: mismatch →
    exit 2; `null` → `::warning::`.
  - R4: `synthesized_answer_rate == 0` with an LLM configured → exit 2.
  - `LLM_TIMEOUT` and `make eval`'s per-request `--timeout` per the ADR (proposed 60 s, eval timeout ≥ `LLM_TIMEOUT`;
    `eval_gate.py` already has `--timeout`, so pass it through `make eval` args or env, no `scripts/` edit). Re-derive the
    `make eval` step timeout (45 min today) and the job timeout (180) in the design's budget table.
  - Step summary: `llm:` line (model, host, digest, `synthesized_answer_rate`) and **token usage per answer** (mean and
    max of prompt/completion tokens from the `synthesis` lines in `query.log`, already uploaded via `*.log`) for EVAL-8
    AC3. Header comment "No secrets" updated.
- `CONTRIBUTING.md` eval section and app `README.md` eval/testing lines that describe `eval.yml` (grep at spec
  finalisation: `git -C app grep -n "eval.yml\|No secrets\|make eval" origin/main -- README.md CONTRIBUTING.md`).
- Out of scope: Modal deployment and the secrets (Mahesh); `scripts/` and `evals/` (ai: EVAL-8b/8c); `evals/thresholds.json`.

## Acceptance criteria (draft, finalised when ADR-0021 is Accepted)
- [ ] AC1 — A `workflow_dispatch` run on the PR branch with the secrets set: warm-up passes, `make eval` exits 0 or 1
      (not 2), the summary shows model `qwen2.5:3b-instruct`, digest `357c53fb659c`, `synthesized_answer_rate` > 0, and
      token usage per answer. The run ID is quoted (EVAL-8 AC1, AC3).
- [ ] AC2 — Negative runs, each ending exit 2 with its own `::error::` line (dispatch with a test input, or a scratch
      branch; the design says how): missing secret; warm-up budget exhausted (unreachable URL); digest mismatch (wrong
      expected value); 0 synthesized answers (`LLM_MODEL` pointing to a model the endpoint lacks).
- [ ] AC3 — No secret value appears in any job log: QA greps the downloaded logs for the first 8 characters of the key
      (Mahesh provides them out of band, or QA checks the masking `***` lines). Secrets are absent from steps outside R1.
- [ ] AC4 — PR runs without the label keep today's LLM-less behaviour (or replay, per EVAL-8b), shown by one unlabeled
      run on the PR.
- [ ] AC5 — GPU-seconds or wall time of the Modal session per run reported for Mahesh's cost estimate (ADR-0021 Q4).
- [ ] AC6 — actionlint step green; `Agent ownership check` green; README/CONTRIBUTING lines updated (DoD 4).

## Verification
```bash
# CI only (needs secrets + Modal): gh workflow run eval.yml --ref agent/backend/EVAL-8a
gh api repos/MaheshPulivarthi18/ArxivLens/actions/runs/<id>/jobs --jq '.jobs[].steps[] | "\(.name) \(.conclusion)"'
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.7 -color .github/workflows/eval.yml
```

## Notes
- 2026-11-22 (pm-lead): specced from Mahesh's direction (EVAL-8 Notes 2026-11-21 ~21:30Z). "Model + digest in results"
  moved to EVAL-8c because `scripts/eval_gate.py` writes the results JSON and is ai-owned. This ticket enforces the
  check in the workflow. Blocked because it changes what the CI answer gate measures (quoted → LLM-written) and adds
  could-not-run rules: a quality-gate definition, so it needs an Accepted ADR (AGENTS.md §2).
