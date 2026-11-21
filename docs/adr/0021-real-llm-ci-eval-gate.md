# ADR-0021: Real-LLM answer eval in CI (Ollama `qwen2.5:3b-instruct` on Modal)

- **Status:** Proposed
- **Date:** 2026-11-22
- **Deciders:** Mahesh Pulivarthi (only the human owner sets Accepted/Rejected)
- **Blocks:** EVAL-8a (backend, `eval.yml`), EVAL-8b (ai, replayed LLM answers). EVAL-8c (results record which LLM ran) does not wait on it
- **Relates to:** ADR-0001 (LLM provider and budget; cost per answer still open), ADR-0003 (refusal policy), ADR-0019 (quick-stage
  latency gate, written answer report-only), Technical PRD §9 "Reference hardware", Product PRD §8, QA-8, EVAL-3 (`eval.yml`), EVAL-8

## Context
`make eval` in CI (`eval.yml`: nightly `17 6 * * *`, `workflow_dispatch`, and PRs that touch `eval.yml` or
`scripts/arxiv_replay.py`) runs with no LLM. The header says "No secrets". `/v1/ask` therefore returns quoted answers
only, so CI never measures written (`answer_kind: synthesized`) answers. The supported-citation and refusal gates are
QA-8's real product risk, and CI checks them only on the extractive path.

On 2026-11-21 Mahesh ran `make eval` locally with the LLM on: Ollama `0.40.16`, `qwen2.5:3b-instruct` @ `357c53fb659c`,
Apple M4 (`mps`). The gate passed: supported 1.00 (44 citations), correct refusals 1.00 (22), quick-stage `ask_p95_ms`
2423, `ask_full_p95_ms` 16786 (report-only), near-miss 0.933 (`n003` answered). The results JSON is in
`agents/reviews/EVAL-8/`. He chose to run **the same model in CI on Modal**: an Ollama server behind a bearer-token proxy that
he deploys, with the GitHub secrets set by him. He ruled out OpenRouter, which has no 3B Qwen2.5 and serves different weights.

The query service already reads `LLM_MODEL`, `LLM_BASE_URL`, `LLM_API_KEY` (a `Secret`, never logged), `LLM_TIMEOUT`
(default 30 s) and `LLM_MAX_TOKENS` (`internal/llm/config.go`). On any LLM failure it falls back to the quoted answer
(QA-8). That fallback is right for users, but a CI run can then **pass on quoted answers while claiming to test the LLM**.
The results JSON also doesn't say which LLM ran (`agents/reviews/EVAL-8/README.md`).

What makes this a gate decision (AGENTS.md §2, "Quality gates"): the thresholds in `evals/thresholds.json` stay the same,
but the answers they are measured on change from quoted to LLM-written. This ADR also adds rules for when a run counts.

## Questions for Mahesh
1. **Which runs use the real LLM?** (options A–C below)
2. **What makes a run "could not run" (exit 2) rather than a pass?** (proposed rules R1–R4)
3. **What do PRs that don't call Modal get?** (replay options P1–P3, EVAL-8b)
4. **Budget:** the most you will pay for Modal GPU time per month (ADR-0001's open cost question). EVAL-8a reports measured
   GPU-seconds per run, and you read the cost from Modal billing.

## Options: which runs call the real LLM
- **A. Nightly + `workflow_dispatch` + opt-in PR label `eval-llm`** *(recommended)*. Roughly one Modal session per day, plus
  any PR you label. The existing PR path trigger (`eval.yml`, `arxiv_replay.py`) runs without the LLM, or with replay (Q3).
  Pros: cost is bounded and predictable, and every day's `main` is measured with the real model. Cons: a PR that changes
  prompting or verification is measured only if someone adds the label (qa-reviewer asks for it, as with `workflow_dispatch`
  today, lesson 2026-11-07 EVAL-6).
- **B. Every `eval.yml` run, including PRs.** Pros: no label to forget. Cons: cost grows with PR count, and PRs from forks
  get no secrets, so they need a rule anyway.
- **C. Keep CI LLM-less.** Mahesh's local runs stay the record (EVAL-8 option 3). Pros: no cost, no secret. Cons: nothing
  catches a regression in written answers between his manual runs. He has already rejected this.

## Proposed rules (all options except C)
- **R1. Secrets.** Two repository secrets, `LLM_BASE_URL` (the Modal proxy's OpenAI-compatible `/v1` base) and `LLM_API_KEY`
  (its bearer token), are passed only to the query-service step, the warm-up step and the `make eval` step. `LLM_MODEL` is
  plain workflow env (`qwen2.5:3b-instruct`). The expected digest `357c53fb659c` is workflow env too (not a secret). If the
  secrets are missing on a run that should use the LLM (fork PR, a secret removed), the job fails with exit 2 "LLM
  configured but no endpoint". It never passes LLM-less in silence.
- **R2. Warm-up.** Before `make eval`, one tiny `/v1/chat/completions` request is retried until it returns 200, within a
  fixed budget (proposed 10 min, covering a GPU cold start plus the model load). If the budget runs out, exit 2. The step
  prints the time it took as a % of its budget (lesson 2026-11-07 EVAL-3).
- **R3. Provenance.** The results JSON records the LLM: model, endpoint host (never the key or full URL), and, if the proxy
  exposes Ollama's `/api/version` and `/api/tags`, the Ollama version and model digest (EVAL-8c). In CI, a digest that
  doesn't match the expected value means exit 2, because the numbers would not be comparable with the local baseline. An
  unknown digest (proxy doesn't expose `/api/tags`) only warns. **Ask:** can the Modal proxy pass `GET /api/version` and
  `GET /api/tags` through behind the same bearer token?
- **R4. The run measured the LLM.** Every case record gets `answer_kind`, and results get a report-only
  `synthesized_answer_rate` (EVAL-8c). With an LLM configured, **zero** synthesized answers means exit 2: the LLM never
  answered, so every answer was a quoted fallback. A rate between 0 and 1 is reported, not gated. Making it a gate
  later is a `thresholds.json` change and needs its own ADR.
- **Unchanged:** every threshold in `evals/thresholds.json`. Quality metrics come from the written (full) answer, as
  `evaluate_answers.py` already does. The gated latency stays the quick stage (ADR-0019); it never calls the LLM, and it is
  informational on CI's CPU profile (Technical PRD §9). `ask_full_p95_ms` stays report-only. Its CI value includes the
  network round trip to Modal, so it is **not** comparable with the local 16.8 s, and the summary says so.
- **Timeouts.** `LLM_TIMEOUT` in CI is proposed at 60 s (Modal round trip plus a busy GPU). The eval's per-request
  `--timeout` (30 s today) must be at least `LLM_TIMEOUT`, or a slow written answer counts as an error (exit 1), not a
  fallback. EVAL-8a's design sets both values and re-derives the `make eval` step budget (45 min today).

## Options: what PRs without the real LLM get (EVAL-8b)
- **P1. LLM record/replay proxy in `eval.yml`** *(recommended)*. `scripts/llm_replay.py` copies the `arxiv_replay.py`
  pattern: real-LLM runs record each `/v1/chat/completions` response, keyed by a hash of the canonical request (model,
  messages, sampling params), into an Actions cache created on `main`. PR runs serve them replay-only. A cache miss
  returns 404, so the query service falls back to the quoted answer. That is visible through R4's per-case `answer_kind`,
  and the summary prints `llm replay: hits H / misses M`. Pros: PR runs exercise the real Go parse, claim and verify path on
  real model output, at no cost and deterministically. Cons: any change to retrieval or the prompt changes the keys, so
  exactly the PRs that most need the LLM get misses. They need the `eval-llm` label (option A).
- **P2. Recorded `/v1/ask` responses as unit-test fixtures.** A few real-LLM `/v1/ask` bodies are committed under `tests/`,
  and `make test-py-light` scores them with `evaluate_answers.py`. Pros: cheap; runs on every PR in `ci.yml`. Cons: it
  tests the scorer, not the service.
- **P3. Recorded completions as Go fixtures through `llmtest`.** `rag_test.go` runs `parseSynthesis` and claim handling on
  real `qwen2.5:3b` output. Pros: catches format drift in `make test-unit`. Cons: needs a `testdata/` path under
  `internal/query/` that the ownership check doesn't yet allow for ai-engineer (rules PR), and it doesn't check the gate
  numbers.

## Recommendation (from pm-lead)
Option **A** with rules **R1–R4**, and **P1** for PRs. The thresholds stay as they are. Each night the real model is
measured on `main` at a bounded cost. A run where the LLM silently fell back, or where a different model answered, is
red (exit 2), not a misleading green. PRs get real-model output for free when the prompts haven't changed, and the
`eval-llm` label when they have. EVAL-8c, which records which LLM ran, is useful locally today and doesn't depend on this
decision, so it goes first.

## Decision
_(Filled by the human.)_

## Consequences
- If accepted: EVAL-8a (backend: `eval.yml` secrets, R1–R4 wiring, warm-up, digest check, token usage from `query.log` for
  EVAL-8 AC3, step budgets, README/CONTRIBUTING eval lines) and EVAL-8b (ai: the chosen P option) become Ready once EVAL-8c
  merges. Mahesh deploys Modal and sets the secrets before EVAL-8a's first real-LLM run.
- `eval.yml`'s "No secrets" header and the CONTRIBUTING eval section change. Secrets are never echoed. The LLM client's
  `Secret` type already redacts the key.
- QA evidence for prompt, verification or claim changes can include an `eval-llm` run (qa-reviewer rule: rules PR after
  acceptance).
- The local baseline (`agents/reviews/EVAL-8/baseline-local-20261121T212749Z.json`) becomes the reference that Modal runs are
  compared with. A gap between them is a finding for Mahesh, not a threshold change.
