# QA report — RET-1c · PR #84 · round 1

**Verdict:** PASS
**Reviewed commit:** `baa6fa06f2a1f0558ae869453225d98bee1e38b5` · **Date:** 2026-11-20
**Ticket:** `agents/tasks/RET-1c.md` · **PRD:** Product PRD §7 (honest failure), Technical PRD §7 (query API); follow-up from RET-1b QA finding 4. Not design-required.
**Evidence (commit-pinned):** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence

PR state at review: open, draft, not merged; CI ran on `refs/pull/84/merge` = `a5b03a0` (baa6fa0 merged into current main `c37d27c`).

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136310387183 (go1.25.0, `GOFLAGS=-race`) | **pass**: `make lint-go` clean, `ok arxivlens/internal/query 1.583s` ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/00-ci-checks.png?raw=true)) |
| Full stack (`stack.yml`) | CI job 136310387284 | **pass**: query service is `./bin/arxivlens query` built from the merge commit; `246 passed, 1 skipped, 3 deselected`, including `test_query_service_health` and `test_paper_status_endpoint`; the F1 step ran the 3 M3 search/ask tests: `3 passed` ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/08-ac7-full-stack.png?raw=true)) |
| Python M0 / DB / Frontend | CI | pass (none touched by this diff) ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/00-ci-checks.png?raw=true)) |
| Agent ownership | CI job 136310387146 | pass: `Ownership OK for role=backend (193 changed lines)` ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/00-ci-checks.png?raw=true)) |
| Ticket verification commands | local, go1.24.7 scratch module | `gofmt -l internal/query/` empty; `go vet` OK; `go test -race -count=1 -v -run '^TestWriteJSON$'` 4/4 PASS ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/03-verify-gofmt-vet-fidelity.png?raw=true), [04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/04-ac1-ac4-testwritejson.png?raw=true)). I couldn't build the real module locally: go.mod needs 1.25 and there's no module proxy. The harness holds the PR's **real** `server.go` and `server_test.go` (sha256 identical to the head, shown in 03) plus small stubs for `db`, `SearchEngine`, `RAGService` and `PaperIngester`. All harness sources are in [09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/09-harness-source.png?raw=true). |
| `make test-unit` / `make lint` | CI only | not run locally (no Go 1.25, no npm deps); CI `make lint-go` + `make test-go` green, Python M0 + Frontend jobs green |
| `make eval` | — | not run: this change touches only the response-encoding path. No retrieval or answer logic changed: `rag.go`/`search.go` are untouched (01), and the success bodies are byte-identical to main (05 vs 06 `ok` rows) |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 unencodable → 500, non-JSON, one log line | ✅ | `TestWriteJSON/unencodable` PASS ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/04-ac1-ac4-testwritejson.png?raw=true)). The test asserts code 500, no leading `{`, Content-Type ≠ `application/json`, exactly 1 log line containing `encode response failed route=/v1/search`, `trace_id=-` and `unsupported value` (`server_test.go:46-52, 89-131`). The log is captured with `log.SetOutput` and restored in `t.Cleanup`. Mutants a, b, b2, g, h, i, j are killed (07). |
| AC2 trace ID in log / `-` default | ✅ | `TestWriteJSON/unencodable_with_trace_ID` (+Inf, `/v1/ask`, `t-ret1c`) PASS. The `-` default is asserted in the AC1 row. Mutant f (no `-` default) is KILLED ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/07-ac6-mutants.png?raw=true)). |
| AC3 ok row byte-identical to `json.Encoder`, no log | ✅ | `TestWriteJSON/ok` uses `okBody{Q:"a<b & c>d",N:1}` and compares at runtime against `json.NewEncoder(&buf).Encode(v)` (`encoderBytes`, not a literal). PASS (04). The HTML-escaping mutant l and the no-newline mutant c are both KILLED (07). Independent check: my handler probe compares every real handler's 200 body with `json.Encoder` output, and every `ok` row passes on both the head (05) and main's `server.go` (06). So the success bytes are unchanged vs main. |
| AC4 status passthrough | ✅ | `TestWriteJSON/status_passthrough` → 500, `application/json`, `{"error":"boom"}\n` PASS (04). Mutant d (always 200) is KILLED (07). At handler level, ingest/discover `ingester-error` rows give 500 + JSON `{"error":…}` with no log line ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/05-handler-probe-head.png?raw=true)). |
| AC5 grep counts | ✅ | `grep -c 'json.NewEncoder(w)'` → `0`, `grep -c 'writeJSON('` → `10`; all 9 call sites listed with their route/status ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/02-ac5-grep.png?raw=true)). `/v1/ask` passes `resp.TraceID` (line 161) and the others pass `""`. |
| AC6 mutants a–e killed by `-run '^TestWriteJSON$'` | ✅ | I ran 18 local mutants myself, never pushed. AC mutants a, b, c, d, e: all KILLED by the PR test. Extras b2, f, g, h, i, j, k, l: KILLED. b3 (only `Content-Type` moved before the marshal) survives both suites because it is **equivalent**: `http.Error` overwrites Content-Type with `text/plain`, so the response doesn't change, and the PR row's `Content-Type ≠ application/json` assertion passes on it. m–p are call-site mutants, see Finding 1 ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/07-ac6-mutants.png?raw=true)). The PR body also contains the developer's own mutant output. |
| AC7 CI test-unit/lint + Full stack green | ✅ | All 6 check runs `success` on baa6fa0 (00). The Full stack job ran this PR's query binary and passed the M3 health/status tests and the F1 search/ask tests (08). Search/ask/stats/ingest/discover aren't all exercised on their *failure* paths by the stack suite; the unit test and QA probe cover those. |
| Docs: none, stated in PR | ✅ | PR body: "Docs: none. Only the error path changed, and the README API table lists routes and fields, which are unchanged." No route or field changed (01, 02). |

## Bug really fixed (base control)
The same QA handler probe run against main's `server.go` (`c37d27c`) shows the bug for all six fallible routes. A NaN anywhere in the value gives `code=200 ct="application/json" body="" logs=[]` ([06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/06-base-control.png?raw=true)). On the head, each of those routes returns 500 `text/plain` with one log line naming the correct route, and `/v1/ask` logs its trace ID ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/05-handler-probe-head.png?raw=true)).

## Scope
Two files are changed, both in backend-owned `internal/query/`: `server.go` +29/−21 and `server_test.go` (new, 143 lines). No ticket, review or doc files are in the PR. `rag.go`, `search.go` and the README are untouched, and no route, field or non-encoding status code changed ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0421dca35be911b42b112be0b87681b86c3758ca/agents/reviews/RET-1c/evidence/01-scope-diffstat.png?raw=true)). The PR body's heading, Spec link and "What changed" paths match RET-1c and `pulls/84/files`.

## PRD fit
Yes. An encoding failure used to reach clients as an empty 200, which they render as "no results", the dishonest empty state that Product PRD §7 ("Say 'I don't know'" / honest failure) rules out. It is now an explicit, logged 500. The documented API (routes, fields, success bodies) is unchanged (Technical PRD §7), and no shared contract was touched.

## Findings
1. [nit] **The call-site contract has no unit test.** Four call-site mutants survive `TestWriteJSON`, and the stack suite doesn't hit those paths either: m (`/v1/ask` passes `""` instead of `resp.TraceID`), n/o (ingest/discover error path `500` → `200`, an error that would look like a success) and p (`/v1/stats` logs the wrong route). My handler probe kills all four (07), and the code is correct today (05). The ticket scoped the test to the helper, with AC5's grep as the call-site evidence, so this isn't blocking. Suggest a backend follow-up: a handler-level test for the ingest/discover error paths and the ask trace ID. It needs the handlers' dependencies behind interfaces.
2. [nit] `server_test.go:85` restores logging with `log.SetOutput(os.Stderr)` instead of the previous `log.Writer()`. `rag_test.go:631` and `search_test.go:221` save and restore `prevOut`. It's harmless today, but it would clobber a package-level log redirect if one is ever added.
3. [nit/info] `/readyz` shares `handleHealth`, so it would log `route=/healthz`. The payload is a constant map and can't fail to encode, so there's no impact.
4. [spec] The ticket header still says Jira "needs Jira story", while the PR body says **KAN-86**. pm-lead should update the ticket's Jira row.

## Missing tests
- A handler-level test for the `/v1/papers/ingest` and `/v1/papers/discover` error paths (500 + `{"error":…}` JSON), and for `/v1/ask` passing its trace ID to the encode-failure log (Finding 1).

## Hand-off
PASS → pm-lead final review.

---

## PM review (pm-lead) — round 1

**Verdict:** APPROVE
**Reviewed:** PR #84 head `baa6fa06f2a1f0558ae869453225d98bee1e38b5`; QA report (6fd066c); evidence 00–09 at `0421dca`, every PNG opened.

**Product fit.** This fixes a real honest-failure gap: on main, a NaN anywhere in the response gives `200`, `application/json`, an empty body and no log on all six fallible routes (06). Clients render that as "no results". On the head each route returns a logged `500 text/plain` naming the route, and `/v1/ask` includes its trace ID (05). That matches Product PRD §7 ("an error must look like an error"). The documented API is unchanged: success bodies are byte-identical to `json.Encoder` on every handler, both before and after (05 vs 06 `ok` rows).

**Scope.** Exactly the ticket: `server.go` +29/−21 and the new `server_test.go` (01). No route, field, README, `rag.go` or `search.go` change, and nothing extra. 193 lines, ownership OK (00).

**Evidence per AC.**
1. AC1–AC4: `TestWriteJSON` 4/4 PASS (04), run on the PR's real `server.go`/`server_test.go` (sha256 identical, 03), and CI's go1.25 `-race` run of `internal/query` is ok (00). Convincing.
2. AC5: 0 / 10, with all 9 call sites listed and their routes/statuses (02).
3. AC6: mutants a–e plus b2, f–l are killed by the PR test (07). b3 is equivalent (`http.Error` resets Content-Type), which I accept.
4. AC7: all 6 check runs succeed on baa6fa0. The Full stack job built the query binary from the merge commit: 246 passed, and the F1 M3 search/ask run gave 3 passed (00, 08).
5. Docs: none needed, and the PR says so. No PRD status row exists for RET-1c (follow-up ID), so there is no PRD edit.

No "⚠ unverified" on anything that matters. The only local gap (full-module build on go1.24) is covered by CI.

**QA findings, decided.**
1. Call-site mutants m–p survive the PR's test → follow-up **[RET-1d](../../tasks/RET-1d.md)** (backend-engineer, `internal/query/server.go` + `server_test.go`, P2, Ready after #84 merges): unexported dependency interfaces plus a handler-level contract test. Not blocking: the ticket deliberately scoped the test to the helper, and the code is correct today (05).
2. `log.SetOutput(os.Stderr)` restore → folded into RET-1d AC5 (same file).
3. `/readyz` logs `route=/healthz` → accepted, no action (constant payload can't fail to encode).
4. `[spec]` Jira row → fixed in `agents/tasks/RET-1c.md` (KAN-86).

**Raise.** PR description rewritten with the Evidence section (pinned to `0421dca`), marked ready for review → Ready to merge.
