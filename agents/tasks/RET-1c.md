# RET-1c: Query API never sends an empty 200 when a JSON response can't be encoded

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 |
| **PRD ref** | Product PRD §7 (honest failure: an error must look like an error, never like an empty result); Technical PRD §7 (query API); follow-up from RET-1b QA finding 4 (`agents/reviews/RET-1b/report.md`) |
| **Depends on** | RET-1b (#75, merged `b81a66f`). No open PR touches `internal/query/server.go` or a `server_test.go` (checked 2026-11-20 13:00Z via REST against #70, #79, #81, #82, #83; #81 edits only `internal/query/search_integration_test.go`) |
| **Jira** | needs Jira story (epic KAN-2 "Retrieval & answer quality gates"; labels `task-RET-1c`, `agent-backend`, `arxivlens`) |
| **Design required** | no: one unexported helper in one file, no route, field, CLI, table or service change |
| **Status** | In QA: draft PR #84 |

## Goal
Every handler in `internal/query/server.go` sets `Content-Type`, then calls `_ = json.NewEncoder(w).Encode(v)` (9 call sites on `c37d27c`:
lines 97, 119, 145, 165, 176, 204, 209, 238, 243). If `Encode` fails (e.g. a NaN/±Inf `float64` anywhere in the value), the client gets
`200 OK` with an empty or truncated body and nothing is logged. RET-1b closed the known NaN/Inf source in `/v1/search`, but the handler would
still hide the next one. Marshal first; on failure, log the route (and the trace ID when the response has one) and answer 500.

## Scope
- `internal/query/server.go`: one unexported helper, e.g. `writeJSON(w http.ResponseWriter, status int, v any, route, traceID string)`, that
  1. calls `json.Marshal(v)` **before** touching headers or status;
  2. on error: logs one line `[Query Service] encode response failed route=<route> trace_id=<traceID or ->: <err>` and calls
     `http.Error(w, "failed to encode response", http.StatusInternalServerError)`;
  3. on success: sets `Content-Type: application/json`, writes `status` (skip `WriteHeader` for 200 or call it, either is fine) and writes the bytes
     followed by `"\n"`, so a successful body is **byte-identical** to today's `json.NewEncoder(w).Encode(v)` output.
  All 9 call sites use it. `/v1/ask` passes `resp.TraceID`; the others pass `""`. The two 500 error-JSON paths in the ingest/discover handlers
  keep their status (500) and body via `status`.
- New `internal/query/server_test.go` (package `query`, no infra): table test of the helper with `httptest.NewRecorder()`.
- Out of scope: any route, request/response field, status code of a non-encoding path, README API table, `rag.go`, `search.go`.
- Size: ~35 production + ~80 test lines.

## Acceptance criteria
- [ ] AC1 — `TestWriteJSON` row "unencodable" (`map[string]float64{"x": math.NaN()}`, route `/v1/search`): recorder code **500**, body does not
  start with `{`, `Content-Type` is not `application/json`, and exactly one captured log line (`log.SetOutput` to a buffer, restored in `t.Cleanup`)
  contains `encode response failed route=/v1/search` and `unsupported value`.
- [ ] AC2 — row "unencodable with trace ID" (`/v1/ask`, trace `t-ret1c`): the log line contains `trace_id=t-ret1c`. Row without a trace ID: `trace_id=-`.
- [ ] AC3 — row "ok": for a value with HTML-sensitive text (`{"q":"a<b & c>d","n":1}` as a struct or map), code 200, `Content-Type: application/json`,
  and the body is byte-identical to what `json.NewEncoder(&buf).Encode(sameValue)` writes (compare against that, not a literal). No log line.
- [ ] AC4 — row "status passthrough": `writeJSON(rec, 500, map[string]string{"error":"boom"}, …)` → code 500, `application/json`, body `{"error":"boom"}\n`.
- [ ] AC5 — `grep -c 'json.NewEncoder(w)' internal/query/server.go` prints `0`, and `grep -c 'writeJSON(' internal/query/server.go` prints ≥ 10
  (9 call sites + the definition). Paste both outputs.
- [ ] AC6 — Mutants, run locally (never pushed), each killed by `go test -count=1 -run '^TestWriteJSON$' ./internal/query/`, output in the PR:
  (a) ignore the marshal error and write 200 anyway; (b) set `Content-Type`/`WriteHeader(status)` before marshalling; (c) drop the trailing `"\n"`;
  (d) always write 200 (ignore `status`); (e) log without the route.
- [ ] AC7 — `make test-unit` and `make lint` green in CI; the Full stack job (`stack.yml`) green on the PR (M3 query tests exercise every changed handler).
- [ ] Docs: none (error path only; the README API table lists routes and fields, which don't change). Say so in the PR.

## Verification
```bash
cd app
gofmt -l internal/query/
go vet ./internal/query/
go test -race -count=1 -v -run '^TestWriteJSON$' ./internal/query/
grep -c 'json.NewEncoder(w)' internal/query/server.go   # 0
make test-unit
make lint
# CI: Go job + Full stack job on the PR
```

## Notes
- 2026-11-20 13:00Z (pm-lead): specced from the Backlog line "backend (from RET-1b QA finding 4)" (sketched at the 08:00Z grooming). The ID
  follows RET-1b; it is not a Product PRD row (`grep -n 'RET-1c' docs/PRD-*.md` is empty).
- Why 500 and not 200 + partial: a client that sees 200 and `{}` or nothing renders "no results", which is the dishonest-empty-state the
  Product PRD §7 principles rule out. The status code of an encoding failure is not part of the documented API (README lists routes and fields only).
- 2026-11-20 (backend-engineer, Build): draft PR [#84](https://github.com/MaheshPulivarthi18/ArxivLens/pull/84), branch `agent/backend/RET-1c`,
  head `baa6fa06f2a1f0558ae869453225d98bee1e38b5` (base `c37d27c`). Files: `internal/query/server.go` (+29/-21, the `writeJSON` helper plus 9 call sites),
  `internal/query/server_test.go` (new, 143 lines, `TestWriteJSON` with 4 rows). Ownership check: `Ownership OK for role=backend (193 changed lines)`.
  - Local toolchain is go1.24.7 and `go.mod` needs 1.25 (proxy blocked), so the full package can't build locally. `gofmt -l internal/query/` printed nothing.
    `go vet` + `go test -race -count=1 -v -run '^TestWriteJSON$'` ran in a scratch module holding the real `writeJSON` (awk-extracted verbatim from `server.go`)
    and the real `server_test.go`: PASS with 4/4 subtests.
  - AC1/AC2/AC3/AC4: the `TestWriteJSON` rows `unencodable` (NaN, `/v1/search`, `trace_id=-`), `unencodable with trace ID` (+Inf, `/v1/ask`, `trace_id=t-ret1c`),
    `ok` (`a<b & c>d`, compared to `json.NewEncoder(&buf).Encode(sameValue)` at runtime, no log line) and `status passthrough` (500, `application/json`, `{"error":"boom"}\n`) all pass.
  - AC5: `grep -c 'json.NewEncoder(w)' internal/query/server.go` gives `0`, and `grep -c 'writeJSON(' internal/query/server.go` gives `10`.
  - AC6: local mutants in a scratch copy (never pushed), each run with `go test -count=1 -run '^TestWriteJSON$'`. All KILLED: (a) `if false` for the marshal error, which gave 200
    with 0 log lines; (b) Content-Type+WriteHeader moved before the marshal, which gave 200 on unencodable; (b2) only WriteHeader moved, 200; (c) no `\n`, so `ok` and passthrough
    bodies differ; (d) `WriteHeader(http.StatusOK)` makes passthrough return 200; (e) dropping route from the log fails the `route=` substring check; (f) no `-` default fails
    `trace_id=-`. The full output is in the PR body.
  - AC7: CI on `baa6fa0` is all green: Go (vet, gofmt, test, build; `GOFLAGS=-race`, `ok arxivlens/internal/query 1.583s`), Full stack (compose + make test-full:
    `246 passed, 1 skipped, 3 deselected`, including `test_query_service_health` and `test_paper_status_endpoint` PASSED; the separate F1 run of the 3 M3 search/ask tests
    gave `3 passed`), Python M0, DB, Frontend and Agent ownership check also passed.
  - Docs: none, since only the error path changed. Unverified locally: the full-package build and `make test-unit`/`make lint` (no Go 1.25 or Docker), so CI covers those.
  - Note: `/readyz` shares `handleHealth`, so it logs `route=/healthz`. Its payload is a constant map and can't fail to encode.
