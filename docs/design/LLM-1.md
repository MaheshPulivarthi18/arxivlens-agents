# Tech design — LLM-1: Go LLM provider interface, OpenAI-compatible client and a fake provider (`internal/llm`)

**Author:** backend-engineer · **Ticket:** `agents/tasks/LLM-1.md` · **PRD:** Product QA-8, §8 (`/v1/ask` p95 < 3 s); Technical §7.2, §11 P0 "LLM answer synthesis"; ADR-0001, ADR-0002 (Accepted) · **Status:** Draft

Code refs are to ArxivLens `origin/main`. Stdlib only: `go.mod`/`go.sum` stay the same.

## Problem
ADR-0001 picks one provider abstraction: an OpenAI-compatible HTTP client. It talks to a local server by default and to a hosted
API when a key is set. Tests get a fake, and with no provider configured the answer stays the template. ADR-0002 puts that client
in a small Go package that `rag.go` calls. This task builds `internal/llm` and `internal/llm/llmtest`, tested without any infra,
and does **not** wire them into `/v1/ask` (QA-8 does that). Covers AC1–AC9.

## Approach

### Files (all new)
| File | Contents |
|---|---|
| `internal/llm/llm.go` | `Provider`, `Request`, `Message`, `Response`, `Error` and the sentinel errors |
| `internal/llm/config.go` | `Config`, `Secret`, `ConfigFromEnv`, `FromEnv`, redacting `String`/`GoString` |
| `internal/llm/openai.go` | `Client` (OpenAI-compatible): request build, single retry, body cap, response parse |
| `internal/llm/llmtest/fake.go` | `Fake` provider for other packages' tests |
| `*_test.go` beside each | table tests (`httptest` only) |

### 1. Interface and types (Q1; the seam QA-8 builds on)
```go
type Provider interface {
    Complete(ctx context.Context, req Request) (*Response, error)
    Name() string // "openai-compatible" or "fake"; for logs and metrics, no secrets
}
type Role string // RoleUser = "user", RoleAssistant = "assistant"
type Message struct { Role Role; Content string }
type Request struct {
    System      string    // sent as the first {"role":"system"} message when non-empty
    Messages    []Message // at least one, or ErrInvalidRequest
    MaxTokens   int       // 0 → Config.MaxTokens; < 0 → ErrInvalidRequest
    Temperature float64   // always sent; the zero value 0 (deterministic) suits grounded answers
    JSON        bool      // → response_format: {"type":"json_object"}
}
type Response struct {
    Text             string
    Model            string        // the server's "model"; the configured model if the server omits it
    PromptTokens     int           // 0 when the server omits usage (never estimated)
    CompletionTokens int
    FinishReason     string        // "stop", "length", ...: lets QA-8 spot truncated answers
    Latency          time.Duration // Complete entry → return, retries and backoff included
}
var (
    ErrTimeout        = errors.New("llm: timeout")
    ErrRateLimited    = errors.New("llm: rate limited")   // final status 429
    ErrProvider       = errors.New("llm: provider error") // any other non-2xx, or a transport error
    ErrBadResponse    = errors.New("llm: bad response")
    ErrInvalidRequest = errors.New("llm: invalid request") // caller bug; never sent
)
type Error struct {
    Kind     error         // one of the sentinels above
    Status   int           // HTTP status of the last attempt, 0 if none
    Attempts int           // 1 or 2
    RetryAfter time.Duration // parsed from the last response, 0 if absent
    detail   string        // built by this package only, see §5
    cause    error         // e.g. context.DeadlineExceeded, *url.Error
}
func (e *Error) Error() string   // "llm: provider error: HTTP 503 after 2 attempts"
func (e *Error) Unwrap() []error // [Kind, cause]: errors.Is(err, llm.ErrTimeout) and errors.Is(err, context.DeadlineExceeded) both hold
```
Caller cancel is its own case: when the caller's `ctx` is **cancelled** (not past its deadline), `Complete` returns an `*Error`
whose cause is `context.Canceled` and whose `Kind` is nil. QA-8 can tell "the client went away, skip the fallback" apart from "the LLM was slow,
use the template". When a deadline passes, ours or the caller's, the result is `ErrTimeout`.

Constructors: `ConfigFromEnv(getenv func(string) string) (*Config, error)` returns `nil, nil` when `LLM_MODEL` is unset.
`New(Config) (*Client, error)`. `FromEnv(getenv) (Provider, error)` combines the two and returns an **untyped** `nil` Provider when
disabled, so QA-8's `if p == nil` works. The client keeps one `http.Client` with a cloned default transport and no client-level
`Timeout`: all timing comes from `ctx`.

### 2. Config and defaults (Q2)
| Env | Default | Validation (error, never a silent default) |
|---|---|---|
| `LLM_MODEL` | unset → provider disabled | none |
| `LLM_BASE_URL` | `http://localhost:11434/v1` (Ollama) | absolute `http`/`https`; **no userinfo, query or fragment** (see §5); trailing `/` trimmed |
| `LLM_API_KEY` | empty → no `Authorization` header | none |
| `LLM_TIMEOUT` | **`2s`** | `time.ParseDuration`, must be > 0 |
| `LLM_MAX_TOKENS` | **`256`** | `strconv.Atoi`, 1..8192 |

Error messages name the variable but don't echo its value. Then a key pasted into the wrong variable can't leak.

**Why 2 s / 256 tokens.** The 3 s p95 covers the whole `/v1/ask`: hybrid search, rerank of a pool of 20, the LLM call, then
citation validation (≤ 2 embedder round trips after AI-3). Nobody has measured the non-LLM part on the reference machine yet (AI-3 report, finding 3). It is
embed + SQL + rerank + validation, and we budget it at ≤ 1 s, which leaves **2 s** for the LLM. The timeout covers the **whole** `Complete`
call, both attempts and the backoff, so the worst case on the timeout path is about 2 s + 1 s + the template fallback, still ≤ 3 s.
At 256 output tokens, a hosted small-tier model at roughly 150–200 tok/s plus 0.3–0.5 s to the first token on a ~3k-token prompt
(5 passages × 512 tokens) finishes in about 1.6–2.0 s. A grounded answer of 4–6 cited sentences is about 120–200 tokens,
so 256 leaves headroom and `FinishReason == "length"` flags anything cut off. Known gap, not hidden: a 7–8B local model on an
M1 Pro decodes at about 20–30 tok/s, so it will usually time out at 2 s and fall back to the template. A local user who accepts the
slower answer raises `LLM_TIMEOUT`. The eval's p95 gate then reports the cost, as ADR-0001 intended ("pick the default by measuring").

### 3. Retry policy vs the caller's deadline (Q3)
- `ctx, cancel := context.WithTimeout(callerCtx, cfg.Timeout)`. The effective deadline is the earlier of the caller's and ours, and
  every attempt and wait runs under it. A retry can't outlive the deadline, because it doesn't get a new one.
- At most **2 attempts**. A retry happens only for HTTP **429, 502, 503, 504**. There is no retry for other 4xx or 5xx, transport errors
  (for example connection refused: a local server that is down should fail fast to the template), timeouts or bad responses.
- Backoff is `Retry-After` when present (delta-seconds or HTTP-date), else **250 ms**. There is no jitter: one retry from one process
  can't cause a thundering herd.
- **Deadline cap:** if `wait >= time.Until(deadline)`, we **don't sleep**. We return the retryable error at once (`Attempts: 1`,
  `RetryAfter` set), which gives the caller the most time left for its fallback. Otherwise we wait in
  `select { case <-timer.C: case <-ctx.Done(): }`, so a cancel or deadline stops the wait right away (AC4).
- Result after the final attempt: 429 → `ErrRateLimited`, the other statuses → `ErrProvider{Status}`.

### 4. Response parsing (Q4)
- 2xx: read through `io.LimitReader(body, 1<<20+1)`. More than 1 MiB → `ErrBadResponse` ("body exceeds 1 MiB").
  Non-2xx: read and discard at most 64 KiB (for connection reuse). The body is **never** put in an error.
- Decode into `{model, choices[{message{content *string}, finish_reason}], usage *{prompt_tokens, completion_tokens}}`.
  Bad JSON → `ErrBadResponse`. **Empty `choices`** → `ErrBadResponse` ("no choices"). A missing/null or whitespace-only
  `content` in `choices[0]` → `ErrBadResponse` ("empty completion"): QA-8 would have nothing to validate. Bad responses are not retried
  (the same request probably gets the same answer). Only `choices[0]` is used.
- **`usage` missing or null → both counts 0.** We never estimate from text length. Callers treat 0 as "unknown".
- JSON mode only sets `response_format`. Checking that `Text` is valid JSON is the caller's job (QA-8).

### 5. Redaction (Q5)
**Where the key could leak, and why it doesn't:**
1. *`net/http` errors.* Confirmed in Go's `net/http/client.go`: `Client.Do` returns a `*url.Error{Op, URL, Err}`, and
   `URL` comes from `stripPassword(req.URL)`. **Request headers are never in it**, so a key in `Authorization` can't show up. A key in the URL query
   (`?key=`, the Gemini style) *would* show up, so `LLM_BASE_URL` rejects queries and userinfo (§2). As well, `Error()` uses only the inner `url.Error.Err`
   (for example `dial tcp 127.0.0.1:1: connect: connection refused`), never the URL.
2. *Our own messages.* `detail` is built only from fixed strings, status codes, attempt counts and inner transport errors. It never holds response
   bodies (a server can echo the request or the prompt in a 4xx body), the prompt or the completion. As a last step, if the key is non-empty,
   `strings.ReplaceAll(detail, key, "[REDACTED]")` runs when each `Error` is built.
3. *Printing the config or client.* The key is stored as `type Secret struct{ v *string }` with `String`, `GoString` and `MarshalJSON`
   all returning `[REDACTED]`. `Config` and `*Client` also implement `String`/`GoString`. The pointer matters: when a caller nests the config in an **unexported**
   field, `fmt` can't call methods on it and prints the raw value. A raw `*string` prints as an address, not as the key.
4. *Prompts and completions.* `Request` and `Response` get `String()` methods that print sizes only (`llm.Request{system: 812B, messages: 1, max_tokens: 256, json: false}`).
   The package **does no logging** and never panics on input. The caller (QA-8) logs with the trace ID, per ADR-0001.

**The test that proves it (AC6)**, `TestNoSecretLeaks`: the key is `sk-SENTINEL-KEY-…`, the prompt holds `SENTINEL-PROMPT` and the server's body holds
`SENTINEL-COMPLETION`. A hostile `httptest` server **echoes the `Authorization` header and the request body** into every response body. The table runs
429×2, 503×2, 400, a `Retry-After` past the deadline, a hang/timeout, non-JSON, empty choices, an oversized body, a closed server (connection refused)
and a cancelled ctx. For each case, none of the three sentinels may appear in `err.Error()`, `fmt.Sprintf("%v / %+v / %#v", err)`,
or in `%v/%+v/%#v/%s` of `Config`, `*Config`, `*Client`, a struct with the config in an unexported field, and `json.Marshal(cfg)`.
The server also checks that it **received** the key, so the test can't pass by never sending it.

### 6. `llmtest.Fake` (AC7)
```go
type Step struct { Resp *llm.Response; Err error; Block bool }
func New(steps ...Step) *Fake
func Reply(text string) Step   // Resp{Text: text, Model: "fake"}
func Fail(err error) Step
func Hang() Step               // blocks until ctx is done, then returns nil, ctx.Err()
func (f *Fake) Complete(ctx context.Context, req llm.Request) (*llm.Response, error)
func (f *Fake) Name() string            // "fake"
func (f *Fake) Requests() []llm.Request // deep copies, in call order
var ErrScriptExhausted = errors.New("llmtest: no scripted step left")
```
Each call records the request first and then pops the next step under a `sync.Mutex`. A call after the script runs out returns
`ErrScriptExhausted`, so a test that makes more calls than it expects fails loudly. A `*Response` is copied before it is returned.
The package has `var _ llm.Provider = (*Fake)(nil)`.

## Alternatives considered
1. **A per-attempt timeout (each attempt gets `LLM_TIMEOUT`).** Rejected: the worst case becomes 2 × timeout + backoff, which breaks the 3 s budget and AC3's deadline rule.
2. **Sleeping until the deadline when `Retry-After` is longer, then failing.** Rejected: it costs the full deadline for a known
   failure. Failing at once hands the time to the template fallback.
3. **Retrying transport errors.** Rejected for now: the usual cause is a local server that isn't running, and a retry only delays the
   fallback. Revisit only if hosted runs show transient resets.
4. **A plain `string` key with `String()` redaction.** Rejected: `fmt` ignores methods on unexported nested fields and would print the raw
   string (§5.3).
5. **An official provider SDK.** Out of scope (stdlib only, ADR-0001 says provider-agnostic).

## Contracts and invariants
- Shared contracts: **none touched.** No event, HTTP API, schema or embedding change. `/v1/ask` stays byte-for-byte the same, because nothing imports
  `internal/llm` yet (AC8). The env vars aren't documented in the README until QA-8 makes them do something.
- Pipeline reliability invariants (idempotency, DLQ, traceparent, arXiv politeness) aren't involved: the code is query-side and isn't wired in.
  The `traceparent` for LLM calls is QA-8's logging concern. This package takes `ctx`, so a future header injection fits there.

## Test plan
| AC | Test (all unit, `httptest`/fake, no infra) | CI? |
|---|---|---|
| AC1 | `TestConfigFromEnv` table: unset model → nil/nil and `FromEnv` returns an untyped nil; model only → base `http://localhost:11434/v1`, 2 s, 256; bad/zero/negative `LLM_TIMEOUT`; non-int/0/8193 `LLM_MAX_TOKENS`; base URL with query/userinfo/relative → error; key present → absent from `String`/`%v`/`%+v`/`%#v` | yes |
| AC2 | `TestCompleteSuccess` (text, model, usage, finish reason); `TestAuthHeader` (with key → `Bearer k`, without → no header); `TestRequestWire` (model, system+messages in order, max_tokens default and override, temperature, `response_format` only in JSON mode, `stream:false`) | yes |
| AC3 | `TestRetry` table: 429→200 (2 attempts, success); 503,503 (`ErrProvider`, Status 503, Attempts 2); 400 (1 attempt); 500 (1 attempt); `Retry-After: 5` with a 300 ms timeout → returns in < 100 ms with Attempts 1, and elapsed ≤ timeout + 100 ms; HTTP-date `Retry-After` parsed | yes |
| AC4 | `TestTimeout`: a hanging handler with a 200 ms timeout → `ErrTimeout` and `context.DeadlineExceeded` within 300 ms; caller deadline shorter than `LLM_TIMEOUT` → that one applies; `TestCancelDuringBackoff`: cancel during a 2 s `Retry-After` wait → returns in < 100 ms, `errors.Is(err, context.Canceled)`; `errors.Is`/`errors.As` table for every kind | yes |
| AC5 | `TestBadResponse` table: non-JSON, `{"choices":[]}`, null content, whitespace content, a 1 MiB + 1 body → `ErrBadResponse`, 1 attempt, no panic; missing `usage` → 0/0 and success | yes |
| AC6 | `TestNoSecretLeaks` (§5) | yes |
| AC7 | `llmtest`: `TestFakeScript` (order, errors, exhaustion), `TestFakeRequests` (deep copy), `TestFakeHang` (returns `ctx.Err()`), `TestFakeConcurrent` (50 goroutines, run under `-race`) | yes (`go test -race ./internal/llm/...` in the PR; CI's unit job too if it uses `-race`) |
| AC8 | `git diff origin/main --stat` pasted in the PR; `go.mod`/`go.sum` unchanged | PR |
| AC9 | `go test -coverprofile` per-file totals ≥ 85% pasted from CI (no Go 1.25 in the sandbox) | yes |

Failure paths covered: every typed error, the deadline cap, cancel during backoff, oversized body, connection refused, hostile echoing server.
Tests guard slice indexes (lesson OPS-H6) and use short real timers. To keep them deterministic, the default 250 ms backoff is an unexported field that in-package tests set to 10 ms.

## Risks and rollout
- **Diff size (needs a PM call).** About 380 production lines + about 450 test lines. AC8's "< 400 changed lines" can't hold if tests count.
  Proposal: apply the 400-line target to non-test code. Otherwise split `llmtest` into LLM-1b, which would make QA-8 depend on both.
- **Default timeout is too short for local models** (§2). This is on purpose and documented. QA-8's eval run shows the real p95, and `LLM_TIMEOUT` tunes it.
- **Servers that differ from OpenAI** (some reject `response_format` or `temperature`). Detected as `ErrProvider{400}` → template fallback in QA-8.
  The fix would be a follow-up flag, not a change here.
- Rollout and rollback: nothing imports the package, so there's no runtime change. Rollback is reverting the PR.

**Review requested from ai-engineer (the QA-8 seam):** (a) Is `System` + `Messages` enough, or do you want few-shot turns
(already possible with `RoleAssistant`)? (b) Is a nil `Kind` with a `context.Canceled` cause the right signal for "don't fall back"?
(c) Does `FinishReason` cover truncation, or do you want a typed error for `"length"`?

## PM decision
**APPROVED with conditions** (pm-lead, 2026-11-07, reviewed at design commit `d33b8ef` against `agents/tasks/LLM-1.md`,
ADR-0001/0002 (Accepted), Product PRD QA-8 and §8 `/v1/ask` p95 < 3 s; app `origin/main` `71cb609`).

Why: all five "Design must answer" items are answered and every AC (AC1–AC9) maps to a named test. The whole-call deadline
(Alt 1 rejected), the "don't sleep past the deadline, fail now" rule, no retry on transport errors, and the `Secret` pointer
type are the right calls for a fallback-first client. The `net/http` claim in §5.1 is correct (`*url.Error` carries the
password-stripped URL, never headers), and refusing a query string in `LLM_BASE_URL` closes the one real leak path.
Stdlib only, new directory only, nothing imports it, so `/v1/ask` can't change. No shared contract is touched.

### Decision on the open question (diff size)
**Apply the < 400 changed-lines target to non-test code for this task. Don't split `llmtest` into LLM-1b.**
- Splitting doesn't fix the problem. `llmtest/fake.go` is about 60 production lines, so LLM-1a would still be about 320 prod
  + 350 test lines. It would also add a PR cycle and a second dependency in front of QA-8 (P0, Wave 3).
- The test lines are additive table tests in a new package that nothing imports. Review risk sits in the ~380 production lines,
  and that's what the target is for.
- Ticket-level exception only. The ticket's AC8 is amended to: **non-test lines (`*.go` excluding `*_test.go`) < 400**,
  test lines uncapped. The PR pastes both numbers, e.g.
  `git diff origin/main --numstat -- internal/llm | awk '$3 !~ /_test\.go$/ {p+=$1+$2} $3 ~ /_test\.go$/ {t+=$1+$2} END {print "prod", p, "test", t}'`.
  If production code goes over 400, stop and report; don't squeeze it. Whether AGENTS.md §3 should say this for every task is a
  rules question for Mahesh (board Backlog, *Proposed*). Until he decides, other tasks keep the target as written.

### Conditions (binding; QA checks each)
1. **CI must run `-race` and per-file coverage for this package.** `ci.yml`'s unit job runs neither for `internal/llm` (only the
   Kafka step at `ci.yml:23-24` does), and the sandbox has no Go 1.25, so AC7 (`-race`) and AC9 (per-file ≥ 85%) would have no
   evidence. Add one step that mirrors the Kafka one:
   `go test -race -count=1 -v -coverprofile=c.out ./internal/llm/... && go tool cover -func=c.out`.
   AC8's file allow-list is amended to `internal/llm/**` + that step in `.github/workflows/ci.yml` (≤ 5 lines; no other CI change).
   A scratch-module run on local Go 1.24 (lesson AI-1) is welcome extra evidence but doesn't replace the CI output.
2. **The cancel case must be a well-formed error.** When `Kind` is nil (caller cancelled), `Error()` reads e.g. `llm: canceled`
   (never `<nil>` or a nil-pointer panic), and `Unwrap()` leaves out the nil entry. Add to the AC4 `errors.Is` table: a cancelled
   ctx → `errors.Is(err, context.Canceled)` true and `errors.Is` false for **every** sentinel, including `ErrTimeout`.
3. **Answers to the ai-engineer questions** (pm-lead answers them for the QA-8 seam, so they don't hold up code; ai-engineer may
   ask for additions in the QA-8 design addendum, as a separate change): (a) `System` + `Messages` is enough; few-shot turns use
   `RoleAssistant`. (b) Yes: nil `Kind` + `context.Canceled` means "the client went away". QA-8 decides what to do with it. (c)
   `FinishReason` is enough; no typed error for `"length"`. A truncated answer still goes through citation validation and the
   ADR-0003 refusal (AI-7).
4. **Keep the §2 budget honest in the package doc.** The 2 s / 256-token defaults are a budget, not a measurement. Say so in
   the `config.go` doc comment: they're a starting point, EVAL-8 measures the real p95, and local 7–8B models will usually fall
   back to the template at 2 s. No code change; it's so QA-8's README rows don't present the default as tested.
5. Nothing outside `internal/llm/**` and the condition-1 CI step; `go.mod`/`go.sum` unchanged (AC8). No README change (QA-8 documents the env vars).

### PM addendum 2026-11-07: split at the AC8 check
The build came in at 655 non-test lines (510 code), not ~380. Per "if production code goes over 400, stop and report", pm-lead **splits** the
ticket instead of granting a second exception. **LLM-1** = `llm.go`, `config.go` without `FromEnv`, `llmtest/`, the CI step (≈ 376).
**[LLM-1b](../../agents/tasks/LLM-1b.md)** = `openai.go` + `FromEnv` (≈ 279), starting when LLM-1 is merged. The design itself is unchanged and still
approved for both parts. The earlier "don't split" reasoning assumed the split would only move `llmtest` (~60 lines). The client is the
natural seam, and it holds the code that most needs its own review. Details: `agents/tasks/LLM-1.md` Notes.
