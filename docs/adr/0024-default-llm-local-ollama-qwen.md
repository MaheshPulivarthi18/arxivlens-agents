# ADR-0024: LLM synthesis is opt-in; the default endpoint is local Ollama and the reference model is `qwen2.5:3b-instruct`

- **Status:** Accepted (Mahesh, implemented in ArxivLens #46 `cc57474`, 2026-11-15: `DefaultBaseURL` Ollama, budget sized for `qwen2.5:3b-instruct`; same model chosen for his 2026-11-21 local eval). Recorded by pm-lead 2026-11-28
- **Date:** 2026-11-28 (decision made 2026-11-15)
- **Deciders:** Mahesh Pulivarthi
- **Relates to:** ADR-0001 (Accepted: option 3, both providers behind one interface; "pick the default by measuring"), ADR-0021 (Proposed: the same model in CI on Modal), Technical PRD §9

## Context
ADR-0001 accepted one OpenAI-compatible client for both local and hosted models and left the default to be measured.
In #46 Mahesh set the defaults in `internal/llm/config.go` and sized the answer budget for a local model on the reader's
own GPU machine. No ADR records that default.

## Decision (as implemented)
- **Opt-in:** synthesis is on only when `LLM_MODEL` is set. Without it, answers are quoted (ADR-0023). No key is needed for dev or CI.
- **Default endpoint:** `LLM_BASE_URL` defaults to `http://localhost:11434/v1`, Ollama's OpenAI-compatible API on the
  same machine. A hosted API works by setting `LLM_BASE_URL` and `LLM_API_KEY` (a `Secret`, never logged).
- **Reference model:** `qwen2.5:3b-instruct` through Ollama. The defaults (`LLM_TIMEOUT` 30 s, `LLM_MAX_TOKENS` 256) are
  sized for it on an M-series Mac (about 6 s to read 1–2k tokens of passages). Mahesh's local real-LLM eval (2026-11-21) used it,
  and ADR-0021 proposes it for CI.

## Options that were on the table
1. **Hosted model by default**: better prose, but it needs a key, costs money per answer (ADR-0001's cost cap is still open) and sends questions off the machine.
2. **Local Ollama + small open model** (chosen): free, private, fits the self-hosting persona on GPU hardware (Technical PRD §9).
3. **No default endpoint**: forces every user to configure one. No benefit over 2.

## Consequences
- A user with Ollama and `qwen2.5:3b-instruct` pulled only needs to set `LLM_MODEL=qwen2.5:3b-instruct`.
- The written-answer latency (`ask_full_p95_ms`, about 10–17 s on the reference Mac) is report-only (ADR-0019).
- Changing the reference model changes what the answer eval measures. That needs a new ADR or an ADR-0021 amendment.
