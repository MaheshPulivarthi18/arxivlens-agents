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


---

## Round 2

[qa-reviewer] QA report — LLM-1b · PR #27 · round 2

**Verdict:** PASS
**Reviewed commit:** `e031ac08c43dea286e0cafae36359d73fe783766` (base `origin/main` `2b71772`; rework commit on top of round-1 `efbe972`) · **Date:** 2026-11-07
**Ticket:** [agents/tasks/LLM-1b.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/LLM-1b.md) · **PRD:** Product QA-8; Technical §7.2, §11 P0; ADR-0001, ADR-0002 · **Design:** [docs/design/LLM-1.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/docs/design/LLM-1.md) (approved)

Evidence (pinned to `24dfd20`): https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/24dfd20a52dc1f887e8e518c780a2f0e4c336a8d/agents/reviews/LLM-1b/evidence (round-2 files are `r2-*`; round-1 files are unchanged)

## Round-1 findings, checked one by one
| # | Round-1 finding | Status | Evidence |
|---|---|---|---|
| 1 | [blocking] AC6: transport errors copied server-sent bytes (prompt) into `err.Error()` | **Fixed** | I reran raw-TCP probe 06 against `e031ac0` with all 4 round-1 rows plus 5 new ones: a malformed header echoing the key, a bad `Content-Length`, a bad `Transfer-Encoding`, a bad chunk size on a 200 (the body-read path), and a bad chunked 503 (the discard path). Each row ran with a plain key and with a key containing `"` and `\` (the case round 1 said would get past `ReplaceAll` under `%q`). The probe checks `Error()`, `%+v`, `%#v` and every error in the `Unwrap` chain. **18/18 rows: no prompt, key or quoted-key bytes.** The errors are now `transport: malformed response or protocol error after 1 attempt`, `bad response: reading the body failed` and `HTTP 503 after 2 attempts` ([r2-06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/24dfd20a52dc1f887e8e518c780a2f0e4c336a8d/agents/reviews/LLM-1b/evidence/r2-06-ac6-malformed-response-probe.png?raw=true)). In CI, `TestNoSecretLeaks` has 3 new raw rows that pass ([r2-01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/24dfd20a52dc1f887e8e518c780a2f0e4c336a8d/agents/reviews/LLM-1b/evidence/r2-01-ci-llm-race-coverage.png?raw=true)). It also walks the full Unwrap chain now. Its `rawServer` sends a well-formed 418 if the key is missing, so these rows can't pass by accident. Mutants N1 (restore `err.Error()`), N2 (raw error as cause), N3 (default branch quotes the text) and N4 (`op.Error()`) are all killed ([r2-05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/24dfd20a52dc1f887e8e518c780a2f0e4c336a8d/agents/reviews/LLM-1b/evidence/r2-05-mutations.png?raw=true)). |
| 2 | [nit] redirects followed | **Fixed** | `CheckRedirect` returns `http.ErrUseLastResponse`. `TestNoRedirect` checks 301/302/307/308: each gives `ErrProvider{Status: code}` after 1 request. It passes in CI (r2-01), and mutant N5 (no `CheckRedirect`) is killed (r2-05). |
| 3 | [nit] `FromEnv` 85.7%: comment the unreachable branch | **Fixed** | `config.go:121` now has a comment on the branch. Function coverage is still 85.7%, which is expected; the file is at 98.2% (r2-01). |
| 4 | [spec] ticket status / PR AC7 numbers stale | **Partly** | The ticket's Status line is current (`e031ac0`, QA r2). The PR description's AC7 box still says "CI numbers pending". This is pm-lead's to fill at stage 4: the CI numbers are `openai.go` 95.2%, `config.go` 98.2%. Not blocking. |

Carry-overs from LLM-1 are still met: `attemptsText` has 3 callers in `openai.go` ([r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/24dfd20a52dc1f887e8e518c780a2f0e4c336a8d/agents/reviews/LLM-1b/evidence/r2-03-scope-ac8.png?raw=true)). `New` still runs `normalize` first, and `TestNew` passes in CI (r2-02).

## Test results
| Check | Source | Result |
|---|---|---|
| All 5 check runs on `e031ac0` | CI | success: Go, Python M0, Frontend, DB, Agent ownership ([r2-00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/24dfd20a52dc1f887e8e518c780a2f0e4c336a8d/agents/reviews/LLM-1b/evidence/r2-00-ci-checks.png?raw=true)) |
| `internal/llm` step `go test -race -count=1 -v -coverprofile` | CI job 128439300294 | 0 `DATA RACE`, 0 `--- FAIL`, 127 `--- PASS` lines. `ok … coverage: 96.6%` ([r2-01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/24dfd20a52dc1f887e8e518c780a2f0e4c336a8d/agents/reviews/LLM-1b/evidence/r2-01-ci-llm-race-coverage.png?raw=true), [r2-02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/24dfd20a52dc1f887e8e518c780a2f0e4c336a8d/agents/reviews/LLM-1b/evidence/r2-02-ci-llm-step-full.png?raw=true)) |
| `make lint-go` / `make test-go` | CI (Go job) | pass. Not run locally: needs Go 1.25, and the toolchain download is blocked |
| Ticket verification, local | Go 1.24.7, scratch `go.mod` (`go 1.24`, not committed), `git archive` copy | `go vet` ok, `gofmt -l` empty, `-race -count=3` ok, timing/leak/redirect/transport tests `-race -count=10` ok ([r2-04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/24dfd20a52dc1f887e8e518c780a2f0e4c336a8d/agents/reviews/LLM-1b/evidence/r2-04-local-verify-mutations.png?raw=true)) |
| QA mutants on rework code | local | **9/9 killed** (r2-05). r2-04 also has a first mutant run in which N1, N7 and N9 were invalid: two didn't compile, and N7 read the body after it was discarded. r2-05 corrects them and supersedes those rows. |
| `make eval` | not run | Nothing imports `internal/llm` yet, so retrieval and answering are unchanged. QA-8 owns the eval. |

## Acceptance criteria (re-checked at `e031ac0`)
| AC | Met? | Evidence |
|---|---|---|
| AC1 `FromEnv` + redaction | ✅ | `TestConfigFromEnv`, `TestConfigRedactsKey` and `TestNew` pass in CI (r2-02). `config.go` changed only by a comment since round 1. |
| AC2 wire + parse | ✅ | `TestCompleteSuccess`, `TestAuthHeader` and `TestRequestWire` pass in CI (r2-02). The code is unchanged since round 1, when its mutants were killed. |
| AC3 retry | ✅ | `TestRetry` passes in CI and in 10 local `-race` runs. N8 (3 attempts) and N9 (sleeping past the deadline) are killed (r2-04, r2-05). |
| AC4 timeout + cancel | ✅ | `TestTimeout` and `TestCancel` pass in CI and in 10 local `-race` runs (r2-02, r2-04). |
| AC5 bad responses | ✅ | `TestBadResponse` and `TestBodyCapBoundary` pass in CI (r2-02). The probe's bad chunked body gives `ErrBadResponse` "reading the body failed" with no panic (r2-06). |
| AC6 no leaks | ✅ | Key, prompt and completion are absent across all 13 `TestNoSecretLeaks` rows (10 original + 3 raw) and all 18 QA probe rows (r2-01, r2-06). N1–N4 and N7 are killed (r2-05). |
| AC7 `-race` in CI + per-file ≥ 85% | ✅ | CI per-file totals: **`openai.go` 95.2%**, **`config.go` 98.2%**, `llm.go` 100%, `llmtest/fake.go` 100%. Function-level, `transportDetail` is 75.0% (r2-01). |
| AC8 scope + lines | ✅ | Only the 4 allowed files, nothing outside `internal/llm/`, `go.mod`/`go.sum` diff is 0 lines. **prod 310, test 756** (prod < 400). CI ownership check: "Ownership OK for role=backend (1066 changed lines)" (r2-03). |

## Design / PRD check
The rework keeps design §5.2's intent that error detail never holds server bytes. It now drops net/http's free-form text, which resolves the §4/§5.2 tension round 1 flagged. It keeps only Go-generated parts: the `net.OpError.Op` plus a `syscall.Errno`. The no-redirect policy fits the fail-fast design and stops the body and key from being re-POSTed elsewhere. Contracts are untouched: no change to `shared/events`, HTTP routes, migrations or `go.mod`. PRD fit is as in round 1: this is the ADR-0001/0002 provider seam for QA-8, with nil meaning template answers, so `/v1/ask` is unchanged.

## Findings (round 2)
1. **[nit][code] TLS failures are reported as "malformed response or protocol error".** `transportDetail` has no branch for TLS or x509 errors (e.g. an unknown authority or a handshake failure against a hosted API). An operator would see a misleading class, and `transportDetail` is 75% covered at function level. A fixed-string branch such as `errors.As(err, new(*tls.CertificateVerificationError))` → "TLS certificate rejected" (or any `tls.*` → "TLS handshake failed") would keep the no-server-bytes rule. This could be a follow-up; no AC requires it.
2. **[spec] PR description AC7** still says "CI numbers pending". pm-lead fills it at stage 4 with the CI numbers above.

## Missing tests
None blocking. Optional: a TLS-error row, once nit 1 is decided.

## Hand-off
**PASS → pm-lead** for final review (Jira: PM review). No blocking findings remain.


---
_Generated by [Claude Code](https://claude.ai/code)_
