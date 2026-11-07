# LLM-1: Go LLM provider interface, typed errors, config and a fake provider (`internal/llm`); the OpenAI-compatible client is LLM-1b

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (first step of Phase 1 "make answers real"; QA-8 can't call a model without it) |
| **PRD ref** | Product PRD QA-8; Technical PRD §7.2, §11 P0 "LLM answer synthesis"; ADR-0001 (Accepted), ADR-0002 (Accepted) |
| **Depends on** | ADR-0001, ADR-0002 (both Accepted, `51d8ff5`). No code dependency. |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-LLM-1"`) |
| **Design required** | **yes**: P0, and a new client package that every answer will go through. `docs/design/LLM-1.md` before code. |
| **Status** | **Ready to merge** (PR #23 @ `8e333c4`: QA PASS r2, PM APPROVE 2026-11-07) · design approved 2026-11-07 · **split 2026-11-07**: this task = part a; the client + `FromEnv` = [LLM-1b](LLM-1b.md) |

## Goal
ADR-0001 chose one provider abstraction: an OpenAI-compatible HTTP client that serves a local server (Ollama /
llama.cpp / vLLM) by default and a hosted API when a key is set, a fake for tests, and the template answer when nothing
is configured. ADR-0002 put the client in a small Go package that `rag.go` calls. This task builds that package, fully
tested, without wiring it into `/v1/ask` (QA-8 does that), so `/v1/ask` behaviour doesn't change.

## Scope
> **Split 2026-11-07 (pm-lead, see Notes).** This task ships `llm.go`, `config.go` **without `FromEnv`**, `llmtest/` and the CI step.
> `openai.go` (`Client`, `New`, retry, wire format) and `FromEnv` (which constructs the client) move to [LLM-1b](LLM-1b.md),
> with their tests (`openai_test.go`, `TestNew`, the `FromEnv` rows of the config table). The scope text below is the whole package design;
> the AC list says what is checked here.
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
- [ ] AC1 — *(split)* `ConfigFromEnv` table test: `LLM_MODEL` unset → nil config, no error; set → config with the default local base URL;
      invalid `LLM_TIMEOUT` / `LLM_MAX_TOKENS` / userinfo, a query or a fragment in `LLM_BASE_URL` → error; key present → it appears in no `String()`/`%v`/`%+v`/JSON
      output of `Secret`, `Config`, `Request`, `Response`, `Message`. (The `FromEnv` → nil `Provider` / `*Client` rows are LLM-1b AC1.)
- [ ] ~~AC2~~ → **LLM-1b** — `httptest` server tests for the client: success parses text, model and usage; `Authorization` header present only when a key is set;
      JSON mode puts `response_format` on the wire; request body carries model, messages and max tokens.
- [ ] ~~AC3~~ → **LLM-1b** — Retry: 429 then 200 → one retry, success; 503 twice → error after exactly 2 attempts; 400 → no retry; a `Retry-After`
      longer than the remaining deadline → no sleep past the deadline (assert elapsed time with a slack ≤ 100 ms).
- [ ] AC4 — *(split)* here: the `errors.Is` table on `*Error` built with `newError` (each sentinel; nil `Kind` + `context.Canceled` reads `llm: canceled`, `Unwrap` drops the nil entry, `errors.Is` false for every sentinel; design condition 2). Client behaviour → **LLM-1b**: Timeout and cancellation: a server that hangs → the timeout error within `timeout + 100 ms`; a cancelled `ctx`
      stops a pending backoff wait. `errors.Is` works for each typed error.
- [ ] ~~AC5~~ → **LLM-1b** — Bad responses: non-JSON, empty `choices`, an oversized body → the bad-response error, not a panic.
- [ ] AC6 — *(split)* here: `newError` strips a sentinel key from `detail`/cause text (`TestErrorShape`). Client error paths → **LLM-1b**: a test sets a sentinel key and asserts it's absent from every returned error string across AC3–AC5 cases.
- [ ] AC7 — `llmtest` fake: scripted responses/errors in order, `Requests()` returns what was sent, blocking mode returns `ctx.Err()`;
      `go test -race ./internal/llm/...` passes.
- [ ] AC8 — No behaviour change: `git diff origin/main --stat` lists only `internal/llm/{llm.go,config.go,llmtest/**}` + their tests, plus the one `-race`/coverage step in
      `.github/workflows/ci.yml` (≤ 5 lines; design PM decision condition 1); `go.mod`/`go.sum` unchanged. **Non-test lines
      (`*.go` excluding `*_test.go`) < 400 changed lines; test lines uncapped** (pm-lead exception 2026-11-07, design PM decision).
      Paste both counts. **After the split, expected ≈ 376 non-test lines (llm.go 145 + config.go ≈ 144 + fake.go 87); the < 400 cap is unchanged — if it's ≥ 400, stop and report again.**
      No `openai.go`, no `FromEnv` in this PR.
- [ ] AC9 — Per-file coverage ≥ 85% for each file in this PR (from the CI step; `llm.go` must reach it through `newError`/`Error` tests, not the client): `go test -coverprofile=c.out ./internal/llm/... && go tool cover -func=c.out` (paste the file totals; CI or a local Go 1.25 run).

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
- 2026-11-07 (backend-engineer, build): implemented in worktree `~/wt/LLM-1` (branch `agent/backend/LLM-1`, **staged, not committed/pushed**).
  Scratch-module run on local Go 1.24: `go vet` clean, `go test -race -count=5 ./internal/llm/...` green, per-file coverage
  config.go 98.2%, llm.go 100%, openai.go 99.1%, llmtest/fake.go 100%; ownership check OK; go.mod/go.sum unchanged.
  **AC8 breach, stopped per the PM decision ("if production code goes over 400, stop and report"):** non-test lines = **655**
  (510 code, 77 comment, 68 blank; llm.go 145, config.go 157, openai.go 266, llmtest/fake.go 87); test lines 954; ci.yml +4.
  The design's ~380 estimate was low. Needs a pm-lead call: accept the exception, or split (e.g. LLM-1a = llm.go + config.go
  minus FromEnv + llmtest ≈ 380 prod; LLM-1b = openai.go + FromEnv ≈ 275 prod).
- 2026-11-07 (pm-lead, **AC8 decision: split**, not a second exception). The design estimate (~380 prod) was 72% low. 655 non-test lines
  (510 code) is a different review than the one I approved. A second exception on the same ticket would turn the target into a suggestion.
  The code is already written, so the split costs QA/review cycles, not build time. QA-8 also can't start before AI-7 → AI-6 merge
  anyway, so LLM-1b's extra cycle runs in parallel with that chain and doesn't move QA-8. The seam is clean: `openai.go` is the only file
  with the retry/deadline/body-cap/redaction logic, and it deserves a review of its own. `FromEnv` (config.go:112–124) just calls `New`, so it moves with the client.
  - **LLM-1 (this ticket, part a):** `llm.go`, `config.go` minus `FromEnv`, `llmtest/`, `llm_test.go`, `config_test.go` minus `TestNew` and any
    `FromEnv` rows, `llmtest/fake_test.go`, and the `ci.yml` step (its `./internal/llm/...` pattern already covers 1b). ≈ 376 non-test lines.
  - **[LLM-1b](LLM-1b.md):** `openai.go`, `FromEnv`, `openai_test.go`, `TestNew`, the `FromEnv` table rows. ≈ 279 non-test lines.
    It starts when LLM-1 is **merged** (it imports part a's types; AGENTS.md §3 independence rule). Keep the staged 1b files outside the
    LLM-1 commit (e.g. `git stash push -- internal/llm/openai.go internal/llm/openai_test.go` plus a saved patch for the `FromEnv` hunks), never on `main`.
  - `config_test.go` at the staged state calls `FromEnv` inside `TestConfigFromEnv` (line 51) and `New` inside `TestConfigRedactsKey` (line 98,
    the `Client` `String()` check). Part a drops those assertions and LLM-1b restores them (its AC1/AC6). `TestNew` (line 126) moves to 1b whole.
  - QA-8 now depends on LLM-1 **and** LLM-1b merged. The design's PM-decision conditions 1–5 still apply: 2 and 4 here, 1 here (CI step), 3 and 5 to both.
  - Lesson filed: size estimates in designs should be measured from a skeleton, not guessed (pm-lead lessons).

- 2026-11-07 (backend-engineer, split applied): commit `8e32771` on `agent/backend/LLM-1` (local, **not pushed**), on top of `origin/main` `71cb609`.
  Diff: ci.yml +4, config.go 143, llm.go 145, llmtest/fake.go 87 → **prod 375**; config_test.go 150, llm_test.go 72, llmtest/fake_test.go 151 → **test 373**.
  No `openai.go`, no `FromEnv`; go.mod/go.sum unchanged. Doc comments in llm.go/config.go no longer name `Client`/`New`.
  `TestNew` removed; its default/validation rows now run against `Config.normalize` directly (`TestConfigNormalize`), so config.go keeps its coverage without the client.
  Local Go 1.24 scratch module (`GOTOOLCHAIN=local`): vet clean, gofmt clean, `go test -race -count=3` green, per-file coverage config.go 100%, llm.go 100%, llmtest/fake.go 100%.
  Ownership check OK (prints the generic `> 400 changed lines` warning: it counts test lines too; AC8's cap is non-test only).
  **LLM-1b's full pre-split implementation saved** on local branch `wip/LLM-1b` @ `8a776d6` in `/root/wt/LLM-1` (not pushed) and as a copy + patch in the session scratchpad. Not run: Go 1.25, `make lint`/`make test-unit` (need Go 1.25) — CI is the source of truth.
- 2026-11-07 backend-engineer, rework r1 (QA finding 1 + nit 4): commit `8e333c4` (not pushed) adds `TestErrorsIsAs` to `internal/llm/llm_test.go` (one `newError` per sentinel + cancel row, passed as `error`; `errors.Is` own=true/other four false, cancel = `context.Canceled` only, `errors.As` Kind) and renames the CI step to "LLM package tests". Tests only (+39), prod still 375. Go 1.24 scratch module: vet/gofmt clean, `go test -race -count=3` green, 100% coverage; QA's `mutate.sh` re-run on the new head: 8/8 killed (M1, M2 by `TestErrorsIsAs`).
- 2026-11-07 (pm-lead, final review): **APPROVE** at `8e333c4` (QA round 2 PASS; evidence `8d68676`). All in-scope ACs (AC1, AC4, AC6–AC9) are backed by CI
  output plus a mutation kill; prod 375 < 400; design conditions 1, 2, 4, 5 met. Verdict + reasoning in `agents/reviews/LLM-1/report.md` (PM review).
  QA [spec] item 5 decided: no `MarshalJSON`; "never JSON-log `Request`/`Response`" is a caller rule, recorded in QA-8 Notes (enforced by QA-8 AC6).
  Carry-overs (`attemptsText` caller, `normalize` before printing in `New`) recorded in LLM-1b Notes. PR body for the orchestrator: `/tmp/claude-0/s/pr23-body.md`.
