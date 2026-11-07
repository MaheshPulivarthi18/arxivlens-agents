# LLM-1b: OpenAI-compatible LLM client and `FromEnv` (`internal/llm/openai.go`)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (QA-8 can't call a model without it) |
| **PRD ref** | Product PRD QA-8; Technical PRD §7.2, §11 P0 "LLM answer synthesis"; ADR-0001 (Accepted), ADR-0002 (Accepted) |
| **Depends on** | **LLM-1 merged** (types, typed errors, `Config`/`ConfigFromEnv`, `llmtest`). ADR-0001/0002 Accepted. |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-LLM-1b"`) |
| **Design required** | no new design: covered by the approved `docs/design/LLM-1.md` (PM decision 2026-11-07, conditions 1–5). Split from LLM-1 for size, not scope. |
| **Status** | Ready (Wave 1b: starts when LLM-1 is merged) |

## Goal
Ship the real provider behind the `llm.Provider` interface: an OpenAI-compatible HTTP client (local server by default, hosted
API when a key is set) and `FromEnv`, which returns it, or nil (template answers) when `LLM_MODEL` is unset. Nothing imports it
yet (QA-8 wires it), so `/v1/ask` doesn't change.

## Scope
- Code already written in LLM-1's worktree and set aside at the split (pm-lead decision, `agents/tasks/LLM-1.md` Notes 2026-11-07).
  Rebase it onto `main` after LLM-1 merges, on branch `agent/backend/LLM-1b`:
  - `internal/llm/openai.go`: `Client`, `New(cfg Config)`, `Complete`, wire types, retry (at most one, on 429/502/503/504 only,
    `Retry-After` capped by the remaining deadline, never sleeping past it), 1 MiB body cap, JSON mode, `Authorization` only with a key.
  - `internal/llm/config.go`: add `FromEnv(getenv) (Provider, error)` back (an untyped nil `Provider` when `LLM_MODEL` is unset).
  - Tests: `internal/llm/openai_test.go`, `TestNew`, the `FromEnv` assertions in `TestConfigFromEnv`, and the `Client` `String()` check in
    `TestConfigRedactsKey` (all removed from LLM-1 at the split).
- Out of scope: everything in LLM-1 (types, errors, config parsing, `llmtest`, the CI step, which already runs `./internal/llm/...`),
  `internal/query/`, `cmd/`, README, `go.mod`/`go.sum`, streaming, cost caps.

## Acceptance criteria
- [ ] AC1 — `FromEnv` table: `LLM_MODEL` unset → `p == nil` (untyped nil) and no error; set → a `*Client` with the default local base URL;
      invalid env → the `ConfigFromEnv` error is passed through; a `Client`'s `String()`/`%v`/`%+v` never contains the key.
- [ ] AC2 — `httptest` client tests: success parses text, model and usage (missing `usage` → 0, never guessed); `Authorization` present only
      when a key is set; JSON mode puts `response_format: {"type":"json_object"}` on the wire; the body carries model, messages and max tokens.
- [ ] AC3 — Retry: 429 then 200 → one retry, success; 503 twice → error after exactly 2 attempts; 400 → no retry; a `Retry-After` longer than
      the remaining deadline → no sleep past the deadline (elapsed time asserted with slack ≤ 100 ms).
- [ ] AC4 — Timeout and cancellation: a hanging server → the timeout error within `timeout + 100 ms`; a cancelled `ctx` stops a pending backoff
      wait and returns the well-formed cancel error (`errors.Is(err, context.Canceled)`, false for every sentinel; LLM-1 design condition 2).
- [ ] AC5 — Bad responses: non-JSON, empty `choices`, an oversized body → the bad-response error, not a panic.
- [ ] AC6 — No leaks: with a sentinel key, the key is absent from every returned error string across the AC3–AC5 cases. Prompt and completion
      text don't appear in errors either.
- [ ] AC7 — `go test -race ./internal/llm/...` passes in CI (LLM-1's step), and per-file coverage of `openai.go` and `config.go` is ≥ 85% (paste the CI totals).
- [ ] AC8 — `git diff origin/main --stat` lists only `internal/llm/openai.go`, `internal/llm/openai_test.go`, `internal/llm/config.go`,
      `internal/llm/config_test.go`. `go.mod`/`go.sum` unchanged. **Non-test lines < 400** (expected ≈ 279; LLM-1's non-test-only rule applies
      here too), test lines uncapped. Paste both counts:
      `git diff origin/main --numstat -- internal/llm | awk '$3 !~ /_test\.go$/ {p+=$1+$2} $3 ~ /_test\.go$/ {t+=$1+$2} END {print "prod", p, "test", t}'`.

## Verification
```bash
make lint
make test-unit
go test -race -count=1 -v ./internal/llm/...
go test -coverprofile=c.out ./internal/llm/... && go tool cover -func=c.out
git diff origin/main --stat
```

## Notes
- 2026-11-07 (pm-lead): split from LLM-1 at its AC8 check (655 non-test lines vs < 400). See `agents/tasks/LLM-1.md` Notes. The code is already
  written and passed a local Go 1.24 scratch-module run (`-race -count=5` green, `openai.go` 99.1%), so this task is mostly rebase, CI and QA.
  QA-8 depends on LLM-1 **and** this task being merged. Backend WIP: this counts as an active PR once opened (EVAL-3 #22 and LLM-1 come first).
- 2026-11-07 (pm-lead, from LLM-1 QA/PM review): carry-overs QA checks here. (1) `attemptsText` (`llm.go`, shipped in LLM-1 with no caller) gets its
  caller in `openai.go`; if the client doesn't use it, delete it in this PR. (2) `New` runs `Config.normalize` (rejecting userinfo/query) before the
  config is printed or logged anywhere, so a hand-built, unnormalised `Config` can never print credentials; add a test row for it.
