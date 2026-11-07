# LLM-1: Go LLM provider interface, OpenAI-compatible client and a fake provider (`internal/llm`)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (first step of Phase 1 "make answers real"; QA-8 can't call a model without it) |
| **PRD ref** | Product PRD QA-8; Technical PRD §7.2, §11 P0 "LLM answer synthesis"; ADR-0001 (Accepted), ADR-0002 (Accepted) |
| **Depends on** | ADR-0001, ADR-0002 (both Accepted, `51d8ff5`). No code dependency. |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-LLM-1"`) |
| **Design required** | **yes**: P0, and a new client package that every answer will go through. `docs/design/LLM-1.md` before code. |
| **Status** | Ready (Wave 1) · design approved 2026-11-07 |

## Goal
ADR-0001 chose one provider abstraction: an OpenAI-compatible HTTP client that serves a local server (Ollama /
llama.cpp / vLLM) by default and a hosted API when a key is set, a fake for tests, and the template answer when nothing
is configured. ADR-0002 put the client in a small Go package that `rag.go` calls. This task builds that package, fully
tested, without wiring it into `/v1/ask` (QA-8 does that), so `/v1/ask` behaviour doesn't change.

## Scope
- New package `internal/llm/` (backend-owned per AGENTS.md §2, `internal/` except `rag.go`):
  - `Provider` interface, e.g. `Complete(ctx, Request) (*Response, error)` and `Name() string`.
    `Request`: system prompt, messages, max tokens, temperature, JSON-mode flag. `Response`: text, model, prompt/completion
    token counts, latency.
  - Typed errors the caller can branch on: timeout, rate limited, provider error (HTTP status), bad response. Wrap them
    so `errors.Is` works.
  - OpenAI-compatible client: `POST {base}/chat/completions`. `Authorization: Bearer` only when a key is set. Honour
    `ctx` and a per-call timeout. At most **one** retry, only on 429/502/503/504, with a ctx-aware backoff (`Retry-After`
    honoured but capped by the remaining deadline). No retry on other 4xx. Cap the response body read (e.g. 1 MiB). JSON
    mode sends `response_format: {"type": "json_object"}`.
  - Config from the environment, with an injectable `getenv` for tests: the provider is **enabled only when `LLM_MODEL`
    is set** (unset → `nil` provider, meaning template answers, per ADR-0001). `LLM_BASE_URL` defaults to a local
    OpenAI-compatible server (`http://localhost:11434/v1`). Also `LLM_API_KEY` (optional; set it for a hosted API),
    `LLM_TIMEOUT` (Go duration) and `LLM_MAX_TOKENS`. The design picks the defaults and justifies the timeout against the
    `/v1/ask` p95 < 3 s target (Product PRD §8). Invalid values return an error, never a silent default.
  - The config's `String()` / log form redacts the key. No error message, log line or panic contains the key, the prompt or the completion text.
  - `internal/llm/llmtest`: a fake `Provider` for other packages' tests (ai uses it in `rag_test.go`). It returns
    scripted responses or errors in order, can block until `ctx` is done (to test timeouts), records every `Request`, and is safe for concurrent use.
- Out of scope: any change to `internal/query/` (rag.go is ai-owned; wiring is QA-8), `cmd/`, README (env vars are documented by
  QA-8 when they start doing something), streaming (QA-9), cost caps (ADR-0001 leaves the max cost per answer open for Mahesh),
  provider-specific SDKs, and new modules (`go.mod`/`go.sum` unchanged: stdlib only).

## Design must answer (`docs/design/LLM-1.md`)
1. The exact interface and types (ai-engineer should comment on the design: it's the seam QA-8 builds on).
2. Defaults for `LLM_TIMEOUT` and `LLM_MAX_TOKENS`, and why they fit the 3 s `/v1/ask` budget.
3. Retry policy and how it interacts with the caller's deadline (a retry must never push the call past `ctx`'s deadline).
4. How token usage is read when a server omits `usage` (report 0, never guess), and what the client does with an empty `choices` array.
5. Redaction: where the key could leak (errors from `net/http` include the URL, not headers; confirm) and the test that proves it doesn't.

## Acceptance criteria
- [ ] AC1 — `FromEnv` table test: `LLM_MODEL` unset → nil provider, no error; set → provider with the default local base URL;
      invalid `LLM_TIMEOUT` / `LLM_MAX_TOKENS` → error; key present → it appears in no `String()`/`%v`/`%+v` output.
- [ ] AC2 — `httptest` server tests for the client: success parses text, model and usage; `Authorization` header present only when a key is set;
      JSON mode puts `response_format` on the wire; request body carries model, messages and max tokens.
- [ ] AC3 — Retry: 429 then 200 → one retry, success; 503 twice → error after exactly 2 attempts; 400 → no retry; a `Retry-After`
      longer than the remaining deadline → no sleep past the deadline (assert elapsed time with a slack ≤ 100 ms).
- [ ] AC4 — Timeout and cancellation: a server that hangs → the timeout error within `timeout + 100 ms`; a cancelled `ctx`
      stops a pending backoff wait. `errors.Is` works for each typed error.
- [ ] AC5 — Bad responses: non-JSON, empty `choices`, an oversized body → the bad-response error, not a panic.
- [ ] AC6 — The key never leaks: a test sets a sentinel key and asserts it's absent from every returned error string across AC3–AC5 cases.
- [ ] AC7 — `llmtest` fake: scripted responses/errors in order, `Requests()` returns what was sent, blocking mode returns `ctx.Err()`;
      `go test -race ./internal/llm/...` passes.
- [ ] AC8 — No behaviour change: `git diff origin/main --stat` lists only `internal/llm/**` plus the one `-race`/coverage step in
      `.github/workflows/ci.yml` (≤ 5 lines; design PM decision condition 1); `go.mod`/`go.sum` unchanged. **Non-test lines
      (`*.go` excluding `*_test.go`) < 400 changed lines; test lines uncapped** (pm-lead exception 2026-11-07, design PM decision).
      Paste both counts.
- [ ] AC9 — Per-file coverage ≥ 85% for the package: `go test -coverprofile=c.out ./internal/llm/... && go tool cover -func=c.out` (paste the file totals; CI or a local Go 1.25 run).

## Verification
```bash
make lint
make test-unit
go test -race -count=1 -v ./internal/llm/...
go test -coverprofile=c.out ./internal/llm/... && go tool cover -func=c.out
git diff origin/main --stat
```

## Notes
- 2026-11-07 (pm-lead): specced from the 2026-11-07 plan (external review, Phase 1 item 1) and ADR-0001/0002 as accepted.
  Sandbox: Go 1.25 isn't available locally (proxy.golang.org unreachable), so Go results come from CI. No LLM key or
  server is needed: every test uses `httptest` or the fake.
- Wave 1: independent of every open PR (new directory). QA-8 (Wave 3) depends on this being merged.
- 2026-11-07 (pm-lead, design review): `docs/design/LLM-1.md` **APPROVED with conditions** (see its PM decision). AC8 amended:
  the 400-line target applies to non-test code for this task (no LLM-1b split), and a CI step for `-race` + per-file coverage
  is in scope, because CI's unit job runs neither for this package and the sandbox has no Go 1.25.
