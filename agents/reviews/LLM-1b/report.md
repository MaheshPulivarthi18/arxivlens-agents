<!-- Saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/27#issuecomment-6706214872 (the QA harness could not write report.md). -->

[qa-reviewer] QA report — LLM-1b · PR #27 · round 1

**Verdict:** FAIL
**Reviewed commit:** `efbe972f0fc74b18c7e8226b0cb0a4ad2b3ea423` (base `origin/main` `2b71772`) · **Date:** 2026-11-07
**Ticket:** [agents/tasks/LLM-1b.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/LLM-1b.md) · **PRD:** Product QA-8; Technical §7.2, §11 P0 "LLM answer synthesis"; ADR-0001, ADR-0002 · **Design:** [docs/design/LLM-1.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/docs/design/LLM-1.md) (approved, conditions 1–5, split addendum)

Evidence (pinned to `09abdab`): https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/09abdabbd01122d8101894e6552a831ada37a8e6/agents/reviews/LLM-1b/evidence

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 128388800285 | pass. The `internal/llm` step ran `go test -race -count=1 -v -coverprofile` with 0 `DATA RACE`/`FAIL` lines ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/09abdabbd01122d8101894e6552a831ada37a8e6/agents/reviews/LLM-1b/evidence/00-ci-checks.png?raw=true),`` [01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/09abdabbd01122d8101894e6552a831ada37a8e6/agents/reviews/LLM-1b/evidence/01-ci-llm-race-coverage.png?raw=true),``` [02](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/09abdabbd01122d8101894e6552a831ada37a8e6/agents/reviews/LLM-1b/evidence/02-ci-llm-step-full.png?raw=true))```` |
| Python M0 unit tests | CI | pass |
| Frontend (lint, test, build) | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Agent ownership check | CI | pass ("Ownership OK for role=backend"; it warns on 965 total lines, which is expected under AC8's non-test rule) |
| Ticket verification commands | local, Go 1.24.7 + scratch `-modfile` (`go 1.24`, not committed) | `go vet` ok, `gofmt -l` empty, `-race -count=3` ok for the full package, `-race -count=10` ok for the timing tests ([04](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/09abdabbd01122d8101894e6552a831ada37a8e6/agents/reviews/LLM-1b/evidence/04-local-race-timing.png?raw=true)).````` `make lint`/`make test-unit` not run locally (they need Go 1.25, and the toolchain download is blocked). CI covers them. |
| Mutation testing (QA) | local, on a `git archive HEAD` copy | 20/20 mutants killed ([05](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/09abdabbd01122d8101894e6552a831ada37a8e6/agents/reviews/LLM-1b/evidence/05-mutations.png?raw=true))`````` |
| `make eval` | not run | Nothing imports `internal/llm` yet, so the retrieval and answering paths are unchanged. QA-8 owns the eval. |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 `FromEnv` table + `Client` redaction | ✅ | `config_test.go` `checkFromEnv` runs in every `TestConfigFromEnv` row. Unset → `p != nil` is false, so it is an untyped nil. The default row gives a `*Client` with `http://localhost:11434/v1`. Error rows compare against the `ConfigFromEnv` error text. `TestConfigRedactsKey` covers `client`, `*client` and unexported holders in `%v/%+v/%#v/%s`. `TestNew` checks that hand-built userinfo and query URLs are rejected without echoing them (carry-over 2). All pass in CI (02). Mutants M12 (typed nil), M13 (skip normalize) and M17 (key in `String`) are killed (05). |
| AC2 wire + parse | ✅ | `TestCompleteSuccess` covers text, model and usage; missing or null usage gives 0/0, and the model falls back to the configured one. `TestAuthHeader` checks there is no header without a key and exactly `Bearer k` with one. `TestRequestWire` checks model, roles in order, system first, the max_tokens default/override, temperature, `stream:false`, and that `response_format` is present only in JSON mode. M05, M06, M08 and M20 are killed. |
| AC3 retry | ✅ | `TestRetry`: 429→200, 502→200 and 504→200 each take 2 requests. 503×2 → `ErrProvider` after 2 attempts. 429×2 → `ErrRateLimited`. 400/401/500 take 1 request. `Retry-After: 5` with a 300 ms timeout returns within 100 ms (`maxElapsed: slack`) with Attempts 1 and `RetryAfter` 5 s, and the HTTP-date form behaves the same. M01–M04 and M19 are killed. |
| AC4 timeout + cancel | ✅ | `TestTimeout`: our 200 ms timeout and a shorter 150 ms caller deadline both return within `limit+100ms` with `ErrTimeout` and `DeadlineExceeded`, and match no other sentinel. `TestCancel` cancels during a 2 s backoff, during the request, and before the call. Each returns within 100 ms with `errors.Is(err, context.Canceled)`, `Kind == nil` and `Error() == "llm: canceled"`, matches no sentinel (including `ErrTimeout`), and doesn't match `DeadlineExceeded`. This meets design condition 2. M07, M11 and M18 are killed. |
| AC5 bad responses | ✅ | `TestBadResponse` covers non-JSON, wrong JSON type, `[]`/missing choices, null/whitespace content, an oversized body and an empty body. Each gives `ErrBadResponse`, 1 attempt, no panic. `TestBodyCapBoundary` checks that exactly 1 MiB parses. M09 and M15 are killed. |
| AC6 no leaks | ❌ | The key is never leaked: `TestNoSecretLeaks` runs 10 cases against a hostile echoing server that also verifies it received the key, and M10/M14/M16/M17 are killed. **The prompt is not protected:** a malformed HTTP response puts server-sent bytes, including an echoed prompt, into `err.Error()` (finding 1, [06](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/09abdabbd01122d8101894e6552a831ada37a8e6/agents/reviews/LLM-1b/evidence/06-ac6-malformed-response-leak.png?raw=true)).``````` |
| AC7 `-race` in CI + per-file coverage ≥ 85% | ✅ | CI step `go test -race -count=1 -v -coverprofile=llm.out ./internal/llm/...` totals: **`openai.go` 96.6%**, **`config.go` 98.2%**, `llm.go` 100%, `fake.go` 100%, total 97.8% ([01](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/09abdabbd01122d8101894e6552a831ada37a8e6/agents/reviews/LLM-1b/evidence/01-ci-llm-race-coverage.png?raw=true),```````` [02](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/09abdabbd01122d8101894e6552a831ada37a8e6/agents/reviews/LLM-1b/evidence/02-ci-llm-step-full.png?raw=true)).````````` |
| AC8 scope + line counts | ✅ | Exactly the 4 allowed files. **prod 289, test 676** (prod < 400). `go.mod`/`go.sum` unchanged. No files outside `internal/llm/` ([03](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/09abdabbd01122d8101894e6552a831ada37a8e6/agents/reviews/LLM-1b/evidence/03-scope-ac8.png?raw=true)).`````````` |

Carry-overs from LLM-1: (1) `attemptsText` now has 3 callers in `openai.go` (03). (2) `New` runs `normalize` first, and `TestNew` has the "hand-built userinfo/query … rejected unprinted" rows. Both done.

## Design check (`docs/design/LLM-1.md`)
The code follows §1–§5:
- one whole-call deadline (`WithTimeout` on the caller ctx)
- retry only on 429/502/503/504, at most 2 attempts, 250 ms default backoff, no retry on transport or bad-response errors
- "don't sleep past the deadline, fail now" with `RetryAfter` kept
- the backoff `select` honours ctx
- 1 MiB `LimitReader` cap, 64 KiB discard of non-2xx bodies, `choices[0]` only, usage never estimated
- `*url.Error` unwrapped to its inner error
- redaction with `ReplaceAll` in `newError`
- a cloned transport with no client `Timeout`

There are no unexplained deviations. Finding 1 is a gap in §5.2 itself: the design allows "inner transport errors" in `detail` and also promises the detail "never holds response bodies". net/http's protocol errors quote the server bytes, so both can't hold.

## PRD fit
This delivers the ADR-0001/0002 provider seam that QA-8 needs: local server by default, hosted with a key, nil → template answers. The bounded single retry and the deadline cap support the PRD §8 `/v1/ask` p95 < 3 s budget. Nothing is wired in yet, so `/v1/ask` is unchanged. ADR-0001 says the caller (QA-8) logs these errors with the trace ID, which is why finding 1 matters: error text goes to logs.

## Findings
1. **[blocking][code] AC6: prompt (and any server-sent) text reaches `err.Error()` through transport errors.**
   - **Where:** `openai.go:188` builds `detail` as `"transport: "+err.Error()`. For a malformed response, net/http's error quotes the bytes it couldn't parse.
   - **Reproduction ([06](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/09abdabbd01122d8101894e6552a831ada37a8e6/agents/reviews/LLM-1b/evidence/06-ac6-malformed-response-leak.png?raw=true)):**``````````` a QA-only raw-TCP probe uses the same hostile-echo threat model as `TestNoSecretLeaks`. Results:
     - `malformed HTTP status code "SENTINEL-PROMPT"`: prompt leaked
     - `malformed MIME header: missing colon: "SENTINEL-PROMPT"`: prompt leaked
     - `malformed HTTP response "{\"model\":\"m\",\"messages\":[{\"role\":\"user\",\"content\":\"SENTINEL-"`: request-body fragment leaked
     - the same path with the key: `"[REDACTED]"`. The key is caught only because `ReplaceAll` matches the raw key. A key containing characters that `%q` escapes would slip through.
   - **What this contradicts:** AC6 ("Prompt and completion text don't appear in errors either"), the package doc in `llm.go` ("No error … contains … the prompt or the completion text"), and design §4/§5.2 ("the body is never put in an error").
   - **Fix (small):** don't copy free-form transport error text. Keep only server-independent parts, e.g. `*net.OpError` op/net plus the syscall error such as `connect: connection refused`, and use a fixed string such as `"transport: malformed response"` for anything else. Add raw-TCP rows to `TestNoSecretLeaks` (malformed status line, malformed header and garbage response, each echoing the prompt, completion and key). If pm-lead decides to accept the residual risk, record it as a design deviation and amend AC6. Until then this is blocking.
2. **[nit][code] Redirects are followed by default.** `http.Client` follows 3xx, and on 307/308 to the same host it re-POSTs the body with `Authorization`. The design doesn't cover redirects. Setting `CheckRedirect` to return `http.ErrUseLastResponse` would make a 3xx a plain `ErrProvider{3xx}`, which matches the fail-fast intent. Not required by any AC.
3. **[nit][code] `FromEnv` is 85.7% covered at function level.** The `New` error branch can't be reached after a successful `ConfigFromEnv` (which already normalizes). This is fine, and the file is at 98.2%. A short comment would explain it.
4. **[spec] The ticket is out of date.** Its Status line still says "draft PR pending (orchestrator)", but PR #27 is open. The PR description's AC7 box is still unchecked with "CI numbers pending". The CI numbers are now available (above), and pm-lead's PR text should carry them.

## Missing tests
- A transport error built from a malformed/non-HTTP response that echoes the prompt, completion and key (finding 1).
- (Optional) A 3xx response, once the redirect policy is decided (finding 2).

Everything else in the AC table and the design test plan is covered. Every mutant QA tried was killed (05).

## Hand-off
**FAIL → back to backend-engineer** (rework round 1). Only finding 1 blocks. Round 2 will rerun probe 06 against the new head and check the new `TestNoSecretLeaks` rows in CI.


---
_Generated by [Claude Code](https://claude.ai/code)_
