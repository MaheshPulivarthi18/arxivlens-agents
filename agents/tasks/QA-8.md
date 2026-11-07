# QA-8: LLM answer synthesis in `/v1/ask` through the provider interface, with template fallback

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (top roadmap item; Phase 1 "make answers real") |
| **PRD ref** | Product PRD QA-8, §7 principles 1–2, risks "Template answers feel shallow" / "Hallucinated citations"; Technical PRD §7.2, §11; ADR-0001, ADR-0002, ADR-0003 (all Accepted 2026-11-07) |
| **Depends on** | **LLM-1 merged** (`internal/llm` + `llmtest` fake), **AI-6 merged** (context/prompt/parser, same file), AI-7 merged (refusal safety net; it comes before AI-6 in the `rag.go` order). EVAL-1, AI-1 (Done). |
| **Jira** | KAN-7 (existing; re-scoped 2026-11-07, `labels = "task-QA-8"`) |
| **Design required** | **yes**: an addendum to `docs/design/QA-8.md` (written in AI-6) covering the provider call, timeout and fallback. pm-lead approves before code. |
| **Status** | Ready (Wave 3: starts when LLM-1 and AI-6 are merged). The ADR blockers are gone (ADR-0001/0002 Accepted `51d8ff5`) |

## Goal
Replace the templated answer with an LLM-written synthesis over the selected passages whenever a provider is configured,
keeping every existing guarantee: numbered `[n]` citations checked by the validator, fabricated markers dropped, ADR-0003
refusal when nothing is supported, and today's template behaviour whenever no provider is configured or the provider fails.

## Decisions this follows (ADR-0001/0002/0003, Accepted)
- Provider: `internal/llm` (LLM-1). Local OpenAI-compatible server by default, hosted when `LLM_API_KEY` + base URL are set,
  fake in tests, **template when `LLM_MODEL` is unset**.
- Synthesis lives in `rag.go`. The Python embedder isn't involved.
- The LLM call has its own timeout. On timeout or error → template answer, logged with the trace ID.
- Cost per answer stays open (Mahesh sets a cap before a hosted key is enabled in any shared deployment). This task logs token
  usage so the cost can be computed, and enforces no cap.

## Scope
- `internal/query/rag.go`:
  - `NewRAGService` reads the provider with `llm.FromEnv(os.Getenv)`. A config error is logged and leaves the template path on
    (the signature stays the same, so `cmd/` needs no change). Log once at startup: `answer synthesis: template` or
    `answer synthesis: llm model=<m> base_host=<host>` (never the key).
  - A test seam to inject a provider (e.g. an unexported field or `newRAGServiceWith(...)` used only by tests).
  - In `Ask`, after the relevance filter: if a provider is set, `selectContext` → `buildSynthesisPrompt` →
    `provider.Complete` (JSON mode, the config timeout) → `parseSynthesis` → the answer text from claims, each followed by its `[n]`
    markers. Then the **existing** `validateCitations` runs over the selected passages, and AI-7's refusal rule applies.
    `insufficient_evidence` → the existing QA-5 refusal ("No indexed papers are relevant to this question.", `citations: []`).
  - Provider error, timeout or parse error → template answer over the same hits. Log `trace_id`, the error class and latency (no text).
  - One usage log line per LLM answer: `trace_id`, model, `prompt_version`, prompt/completion tokens, latency.
  - **No response-shape change.** `prompt_version` / `answer_source` go to logs only, until ADR-0014 decides the fields (AI-8).
- `internal/query/rag_test.go`: tests with `llmtest` for every branch.
- App `README.md`: Environment table rows for `LLM_MODEL`, `LLM_BASE_URL`, `LLM_API_KEY`, `LLM_TIMEOUT`, `LLM_MAX_TOKENS` (with a
  local Ollama example and a "never commit a key" note). Update the Known limitations line about templated answers.
- Out of scope: streaming (QA-9), regeneration on unsupported claims (ADR-0003 chose refusal), claims/quote/status fields (AI-8),
  a cost cap, real-LLM eval runs (EVAL-8), `cmd/`, `internal/llm`.

## Acceptance criteria
- [ ] AC1 — `LLM_MODEL` unset → behaviour identical to today: every pre-existing `rag_test.go` test passes unmodified, and no provider call happens (fake records 0 requests).
- [ ] AC2 — Fake provider, happy path: the answer is built from the fake's claims with `[n]` markers; citations are validated as before; the
      prompt sent contains only the selected passages (assert on `Requests()`).
- [ ] AC3 — Fabricated marker: a claim citing `[9]` with K = 3 → marker dropped. If no valid marker remains anywhere → AI-7's `all_citations_unsupported` refusal.
- [ ] AC4 — `insufficient_evidence: true` → the QA-5 refusal, `citations: []`.
- [ ] AC5 — Provider error, provider timeout (fake blocks; `Ask` returns within `LLM_TIMEOUT` + 200 ms) and malformed JSON → template answer, and one log line each with the trace ID and no text.
- [ ] AC6 — Usage log line has model, `prompt_version`, token counts and latency; no line anywhere contains the key, prompt or completion (captured-logger test with a sentinel key).
- [ ] AC7 — `rag.go` per-file coverage ≥ 90% (`go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go`).
- [ ] AC8 — `make eval` with the template path (no `LLM_MODEL`) doesn't regress against the latest EVAL-3 run (paste both). The run with a real
      LLM is **EVAL-8** (Blocked on Mahesh's model/host choice). Say "real-LLM eval: EVAL-8" in the PR, not "passes".
- [ ] AC9 — README Environment rows + Known limitations updated. pm-lead moves Product PRD QA-8 to ◐ (LLM path built, not yet measured) after merge.
- [ ] AC10 — Diff < 400 changed lines (split the README/log work into a follow-up if not).

## Verification
```bash
make lint
make test-unit
go test -run 'Ask' -v ./internal/query/
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go
make eval   # template path, on the EVAL-3 workflow
```

## Notes
- 2026-11-03 (pm-lead, from AI-1 QA finding 2): `splitIntoSentences` misses `U.S.`, `Sec.`, `approx.`, `resp.`, `Tab.`. With structured
  claims (AI-6) LLM text isn't split. Only relevant if this task ends up splitting LLM text.
- 2026-11-07 (pm-lead): re-scoped after ADR-0001/0002/0003 were Accepted and the 2026-11-07 plan. Context selection, prompt and parser
  moved to AI-6. Refusal moved to AI-7. Claims/provenance fields moved to AI-8 (ADR-0014). The old AC3 (eval with the LLM: supported ≥ 90%,
  refusal ≥ 95%, p95 < 3 s) moved to EVAL-8 as its AC2, because CI has no LLM and a hosted key needs Mahesh's cost cap first. The old AC4 (cost
  within budget) can't be checked until that cap exists; AC6's token log is the input for it. Wave 3.
