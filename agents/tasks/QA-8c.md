# QA-8c: Turn on LLM answer synthesis from the environment (provider wiring, startup line, README, template-path eval)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (second half of QA-8; only exists if QA-8 takes the pre-approved split) |
| **PRD ref** | Product PRD QA-8, §7 principles 1–2; Technical PRD §7.2, §11; ADR-0001, ADR-0002, ADR-0003, ADR-0014 (Accepted) |
| **Depends on** | **QA-8 merged** (the `askLLM` path, `provider`/`llmTimeout` fields, tests), **RET-2 (#35) merged** (same `README.md`) |
| **Jira** | none yet: created under epic KAN-1 "Grounded LLM answers" only when activated (`labels = "task-QA-8c"`) |
| **Design required** | no new design: covered by `docs/design/QA-8.md` § "QA-8 addendum" Q2, Q7, Q9 and its PM decision (2026-11-08) |
| **Status** | **Not active.** Becomes Ready only if QA-8's early size check trips and its PR says the split seam was taken (design Q9, PM decision condition 5). If QA-8 ships unsplit, this ticket is closed as "not needed" |

## Goal
QA-8 (split) builds and tests the LLM answer path but leaves `provider` nil in production. This task turns it on: `NewRAGService`
reads `LLM_*` and builds the provider, logs one startup line, documents the variables, and shows the template path didn't regress.

## Scope
- `internal/query/rag.go`: `newRAGServiceFromEnv(se searcher, ec embedder, getenv func(string) string)` calling `llm.ConfigFromEnv(getenv)`
  then `llm.New(*cfg)`; `NewRAGService` keeps its signature and delegates with `os.Getenv`. Config error (either call) → `provider` nil.
  Exactly one startup line (design Q2): `answer synthesis: template`, `answer synthesis: template (llm config error: <err>)`, or
  `answer synthesis: llm provider=openai-compatible model=%q base_host=%s timeout=%s max_tokens=%d`. Never the key.
- `internal/query/rag_test.go`: `TestNewRAGServiceFromEnv` (table, design Q8 AC1 row) and the key-sentinel part of the AC6 test.
- App `README.md`: Environment rows `LLM_MODEL`, `LLM_BASE_URL`, `LLM_API_KEY`, `LLM_TIMEOUT`, `LLM_MAX_TOKENS`; the local Ollama example
  with `OLLAMA_CONTEXT_LENGTH=8192` (design Q7); the "never commit a key" note; the question-cap clause (PM condition 3); the Known
  limitations line replaced (design Q7 wording).
- Out of scope: anything in `askLLM`/`renderClaims`/`llmErrorClass` (QA-8), `cmd/`, `internal/llm`, `server.go`, response shape (AI-8),
  real-LLM eval (EVAL-8), a cost cap.

## Acceptance criteria
- [ ] AC1 — `LLM_MODEL` unset → `provider == nil`, startup line `answer synthesis: template`; every pre-existing `rag_test.go` test passes unmodified.
- [ ] AC2 — Valid env → provider `Name() == "openai-compatible"`, `llmTimeout == LLM_TIMEOUT`, the startup line has `model=` and `base_host=localhost:11434`.
- [ ] AC3 — Invalid env (`LLM_TIMEOUT=-1s`; base URL with `?key=`) → `provider == nil`, `llm config error` in the line.
- [ ] AC4 — Every case sets `LLM_API_KEY=sk-SENTINEL`; no captured log line contains it (also on the Ask paths, provider swapped for the fake after construction).
- [ ] AC5 — `rag.go` per-file coverage ≥ 90% (`go tool cover -func`).
- [ ] AC6 — `make eval` on the template path (no `LLM_*` set; `eval.yml` `workflow_dispatch` on the branch) doesn't regress against the latest EVAL-3 run on `main` (paste both). The PR says "real-LLM eval: EVAL-8".
- [ ] AC7 — README rows, Ollama example with the context-length line, "never commit a key", question-cap clause and Known limitations updated. pm-lead moves Product PRD QA-8 to ◐ after merge.
- [ ] AC8 — Diff < 400 changed lines.

## Verification
```bash
make lint
make test-unit
go test -run 'NewRAGService|Ask' -v ./internal/query/
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go
make eval   # template path, on the EVAL-3 workflow
```

## Notes
- 2026-11-08 (pm-lead): written ahead of need at the QA-8 design gate (Q13 answer 4), so a split doesn't cost a cycle. Branch `agent/ai/QA-8c`.
  The exact `query` sub-command in the README example is checked against `cmd/arxivlens` at build time.
