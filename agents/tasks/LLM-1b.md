# LLM-1b: OpenAI-compatible LLM client and `FromEnv` (`internal/llm/openai.go`)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (QA-8 can't call a model without it) |
| **PRD ref** | Product PRD QA-8; Technical PRD §7.2, §11 P0 "LLM answer synthesis"; ADR-0001 (Accepted), ADR-0002 (Accepted) |
| **Depends on** | **LLM-1 merged** (types, typed errors, `Config`/`ConfigFromEnv`, `llmtest`). ADR-0001/0002 Accepted. |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-LLM-1b"`) |
| **Design required** | no new design: covered by the approved `docs/design/LLM-1.md` (PM decision 2026-11-07, conditions 1–5). Split from LLM-1 for size, not scope. |
| **Status** | **Done**: PR #27 merged by Mahesh 2026-11-08 06:00Z as `70b0afe` on ArxivLens `main` |

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
- 2026-11-07 11:00Z (pm-lead, grooming): LLM-1 merged (`43713ce`), so this is Ready. **The pre-split code is gone**: local branch `wip/LLM-1b` @ `8a776d6` in `/root/wt/LLM-1` and the scratchpad copy did not survive the sandbox reset (checked 11:00Z: `/root/wt` absent, object `8a776d6` unknown, no `openai.go` in any pushed ref). Re-implement from this spec and the approved `docs/design/LLM-1.md`; scope and ACs are unchanged. Cut `agent/backend/LLM-1b` from `origin/main` `2b71772`. Lesson: set-aside work must be pushed to a branch, not left in a local worktree.
- 2026-11-07 (backend-engineer): **Built**, re-implemented from this spec and `docs/design/LLM-1.md` on `agent/backend/LLM-1b` @ `efbe972`
  (local commit; orchestrator pushes and opens the draft PR). Files: `internal/llm/openai.go` (new), `internal/llm/config.go` (+`FromEnv`),
  `internal/llm/openai_test.go` (new), `internal/llm/config_test.go` (FromEnv assertions in every `TestConfigFromEnv` row, `*Client` in `TestConfigRedactsKey`).
  AC8 counts: **prod 289, test 676**; `go.mod`/`go.sum` unchanged; ownership check OK (warns on 965 total lines, expected per the non-test rule).
  Carry-overs: (1) `attemptsText` now has its callers in `openai.go` (HTTP, transport and timeout details). (2) `New` runs `normalize` first;
  `TestNew` rows "hand-built userinfo/query key rejected unprinted" prove a credential URL never reaches an error or `String()`.
  AC map: AC1 `TestConfigFromEnv`+`checkFromEnv`, `TestConfigRedactsKey`, `TestNew` · AC2 `TestCompleteSuccess`, `TestAuthHeader`, `TestRequestWire` ·
  AC3 `TestRetry` (+`TestParseRetryAfter`) · AC4 `TestTimeout`, `TestCancel` (cancel during 2 s backoff, during request, before call; every sentinel false) ·
  AC5 `TestBadResponse`, `TestBodyCapBoundary` · AC6 `TestNoSecretLeaks` (echoing hostile server, 10 cases) · AC7 CI step from LLM-1.
  Local evidence only (Go 1.24.7 with a scratch `-modfile` setting `go 1.24`, not committed): `go vet` clean, `gofmt -l .` empty,
  `go test -race -count=5 ./internal/llm/...` ok, timing tests `-race -count=10` ok, per-file coverage `openai.go` 96.6%, `config.go` 98.2%.
  **Not verified locally:** `make lint`/`make test-unit` under Go 1.25 and the CI coverage totals AC7 asks for; CI is the source of truth.
  Gotcha found: an `httptest` handler that blocks without reading the request body never sees the client hang up (net/http starts its
  background read only after the body is consumed), so `srv.Close` blocked forever; the test `hang` handler drains the body first.
- 2026-11-07 (backend-engineer, rework r1 for QA FAIL `agents/reviews/LLM-1b/report.md`): pushed `e031ac0` to PR #27 (still draft).
  - [x] ✅ Finding 1 [blocking] AC6: `openai.go` no longer copies `err.Error()`. New `transportDetail` keeps only `*net.OpError.Op` + the `syscall.Errno`
    (e.g. `transport: dial: connection refused after 1 attempt`); DNS → "DNS lookup failed", EOF → "connection closed early", anything else →
    "malformed response or protocol error". The `Error` cause is that errno (or nil), never the raw net/http error, so nothing server-sent is unwrappable.
    `TestNoSecretLeaks` has 3 raw-TCP rows (`rawServer`: malformed status line, malformed header, garbage response, each echoing prompt, completion,
    key and the request body; each asserts Status 0 + `transport:` so it hits this path) and now checks the full `Unwrap` chain too.
    `TestTransportError` asserts `errors.Is(err, syscall.ECONNREFUSED)` and that no `*net.OpError` is reachable. Mutants: restoring `err.Error()` fails
    all 3 raw rows ("SENTINEL-PROMPT leaked"); returning the raw err as cause fails `TestTransportError`.
  - [x] ✅ Finding 2 [nit]: `CheckRedirect` returns `http.ErrUseLastResponse`, so a 3xx is `ErrProvider{Status: 3xx}` after 1 request. `TestNoRedirect`
    (301/302/307/308, the follow-up target would answer 200). Removing `CheckRedirect` fails it.
  - [x] ✅ Finding 3 [nit]: comment on the unreachable `New` error branch in `FromEnv`.
  - Finding 4 [spec]: Status line updated here; the PR description's AC7 numbers are pm-lead's at stage 4.
  - AC8: **prod 310, test 756**, the same 4 files, `go.mod`/`go.sum` unchanged; ownership check OK (warns on 1066 total lines, expected).
  - Local (Go 1.24.7, scratch `-modfile` `go 1.24`, not committed): `go vet` ok, `gofmt -l .` empty, `go test -race -count=3 ./internal/llm/...` ok,
    timing/leak/redirect tests `-race -count=10` ok, coverage `openai.go` 95.2%, `config.go` 98.2%, `llm.go` 100%.
    **Not verified locally:** `make lint`/`make test-unit` under Go 1.25 and the CI coverage totals; CI is the source of truth.
- 2026-11-07 (pm-lead, final review): **APPROVE** at `e031ac0`. All 8 ACs are covered at the head by CI and QA r2 evidence (`openai.go` 95.2%, `config.go` 98.2%; prod 310 / test 756).
  I accept the redirect-off change as in scope because it hardens AC6. QA r2 nit 1 (TLS/x509 errors shown as "malformed response or protocol error")
  is now a Backlog item (backend P2) on the board. The QA-8 PRD row text ("ADR-0001/0002 Proposed") is stale and is fixed by the pending pm-lead docs PR.
- 2026-11-08 (pm-lead, grooming): PR #27 merged as `70b0afe` (06:00Z). Status → Done.
