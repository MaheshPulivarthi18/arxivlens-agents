# RET-1d: Handler-level tests for the query API's writeJSON call sites

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 |
| **PRD ref** | Product PRD §7 (honest failure: an error must look like an error); Technical PRD §7 (query API); follow-up from RET-1c QA findings 1 and 2 (`agents/reviews/RET-1c/report.md`) |
| **Depends on** | RET-1c (#84) **merged** (same files: `internal/query/server.go`, `server_test.go`) |
| **Jira** | KAN-92 (epic KAN-2 "Retrieval & answer quality gates"; labels `task-RET-1d`, `agent-backend`, `arxivlens`) |
| **Design required** | no: unexported interfaces inside one package, no route, field, CLI, table, service or exported signature change |
| **Status** | Done: ArxivLens [#94](https://github.com/MaheshPulivarthi18/ArxivLens/pull/94) merged by Mahesh 2026-11-21 as `29f6213` (QA r1 PASS, PM APPROVE) |

## Goal
RET-1c's `TestWriteJSON` covers the helper but not how the handlers call it. QA showed four call-site mutants survive both the unit test
and the stack suite: `/v1/ask` dropping `resp.TraceID` (m), the ingest (n) and discover (o) error paths answering 200 instead of 500 (an
error that looks like a success, which Product PRD §7 rules out), and `/v1/stats` logging the wrong route (p). Lock the call-site contract
with a handler test that needs no DB, embedder or Kafka.

## Scope
- `internal/query/server.go`: type the four `Server` dependency fields as small **unexported** interfaces holding only the methods the
  handlers call (`HybridSearch`; `AskWith`; `GetPaperStatus` + `GetSystemStats`; `IngestPaper` + `DiscoverAndIngest`), with signatures
  copied from the concrete types. `NewServer(*db.DB, *SearchEngine, *RAGService, int)` and `SetIngester(*PaperIngester)` keep their
  exported signatures, so `cmd/arxivlens/main.go` does not change.
  - **Nil trap:** a nil `*PaperIngester` stored in an interface is not `== nil`. `SetIngester(nil)` must leave the field a nil interface
    so the `503 paper ingester not configured` path still works (AC4).
- `internal/query/server_test.go`: new `TestHandlersEncodeContract` (package `query`, fakes for the four interfaces, `httptest`), and fix
  RET-1c QA finding 2: `TestWriteJSON` restores the **previous** `log.Writer()` in `t.Cleanup`, not `os.Stderr` (same pattern as
  `rag_test.go` / `search_test.go`).
- Out of scope: routes, request/response fields, status codes, `writeJSON` itself, `/readyz` route label (RET-1c finding 3: constant
  payload, accepted as is), `rag.go`, `search.go`, `cmd/`, README.
- Size: ~25 production + ~150 test lines.

## Acceptance criteria
- [x] AC1 — `/v1/ask`: a fake `AskWith` returning a response with `TraceID: "t-ret1d"` and a NaN somewhere in the payload → 500, and the
  one captured log line contains `route=/v1/ask` and `trace_id=t-ret1d`. (Kills mutant m: call site passes `""`.)
- [x] AC2 — `/v1/papers/ingest` and `/v1/papers/discover`: a fake returning `errors.New("boom")` → code **500**, `Content-Type: application/json`,
  body `{"error":"boom"}\n`, no log line. (Kills n/o: error path status 500 → 200.)
- [x] AC3 *(amended 2026-11-21 by pm-lead after QA `[spec]` finding 3: Go can't observe the original wording for every route)*: each route
  `/v1/search`, `/v1/ask`, `/v1/papers/{arxiv_id}/status`, `/v1/stats` has an "unencodable" row: a value `json.Marshal` rejects in the
  fake's result (NaN where the type has a float; a year-10000 `time.Time` for `db.PaperRecord`/`db.SystemStats`, which have no floats)
  → 500, non-JSON Content-Type, exactly one log line containing `route=<that route's label as passed in server.go>`. (Kills p:
  `/v1/stats` wrong route.) `/v1/papers/ingest` and `/v1/papers/discover` need no unencodable row: `IngestResult` has only string/int
  fields, so its encode can't fail; their error path is covered by AC2. Every one of the six routes also has an "ok" row: 200 and body
  byte-identical to `json.NewEncoder(&buf).Encode(<same value the handler wraps>)`.
- [x] AC4 — `SetIngester(nil)` (and a server where it was never called) → ingest and discover answer **503** `paper ingester not configured on server`.
- [x] AC5 — `TestWriteJSON`'s cleanup restores the previous `log.Writer()`: `grep -n 'os.Stderr' internal/query/server_test.go` prints nothing.
- [x] AC6 — Mutants run locally (never pushed), each killed by `go test -count=1 -run '^(TestWriteJSON|TestHandlersEncodeContract)$' ./internal/query/`,
  output in the PR: (m) `/v1/ask` passes `""` for the trace ID; (n) ingest error path status 200; (o) discover error path status 200;
  (p) `/v1/stats` passes `"/v1/search"` as the route; (q) `SetIngester` stores a nil pointer unconditionally.
- [x] AC7 — `make test-unit` and `make lint` green in CI; Full stack job (`stack.yml`) green on the PR (M3 query tests still pass with the
  interface-typed fields).
- [x] Docs: none (tests + internal types only). Say so in the PR.

## Verification
```bash
cd app
gofmt -l internal/query/
go vet ./internal/query/
go test -race -count=1 -v -run '^(TestWriteJSON|TestHandlersEncodeContract)$' ./internal/query/
grep -n 'os.Stderr' internal/query/server_test.go   # empty
git diff --stat origin/main -- cmd/                # empty
make test-unit
make lint
# CI: Go job + Full stack job on the PR
```

## Notes
- 2026-11-20 (pm-lead, RET-1c PM review): created from RET-1c QA finding 1 (call-site mutants m–p survive) and finding 2 (log restore).
  QA's handler probe (`agents/reviews/RET-1c/evidence/09-harness-source.txt`, `qa_probe_test.go`) shows the shape of the test; it stubbed
  `db` at package level, which the real module can't do, hence the interfaces.
- 2026-11-21 (backend-engineer, build): branch `agent/backend/RET-1d` @ `a5bf0f4` (base `230f617`), 2 files, +253/-8
  (`internal/query/server.go`, `server_test.go`); `cmd/` untouched. Interfaces: `hybridSearcher`, `asker`, `statusStore`,
  `paperIngester`; `SetIngester(nil)` stores a nil interface.
  - **AC3 deviation (needs pm-lead/QA ack):** `*IngestResult` has only string/int fields, so `json.Marshal` cannot fail for it.
    `/v1/papers/ingest` and `/v1/papers/discover` therefore have ok + error + 503 rows but no "unencodable" row, and their
    route labels in the encode-failure log are unobservable. The db types (`PaperRecord`, `SystemStats`) have no floats; their
    unencodable rows use a `time.Time` with year 10000 (`Time.MarshalJSON` error) instead of NaN.
  - Local run: sandbox Go is 1.24.7 and the toolchain/module proxy is unreachable (`dial tcp: lookup proxy.golang.org ... no such host`),
    so `go test` was run in a scratch copy with `go 1.24` in go.mod and throwaway local stubs for pgx/pgxpool/minio (not committed).
    There: `go vet ./internal/query/` clean, `go test -race` on both tests PASS, full `./internal/query/` PASS, mutants m/n/o/p/q all
    killed. `make test-unit`/`make lint`/stack.yml not run locally: CI is the source of truth.
- 2026-11-21 (pm-lead, final review): **APPROVE**, PR #94 raised (ready for review, label `ready-to-merge`), Jira → Ready to merge
  (orchestrator). QA round 1 PASS on `a5bf0f4`; evidence pinned to `c01cc9d`. QA findings: 1 (AC6 mutant output in the PR) and
  2 ("Docs: none") are folded into the PR description; 3 `[spec]` was fixed by amending AC3 above. QA's non-blocking "missing tests"
  (q2 `SetIngester(non-nil)`, e2/e3 `http.Error` paths, where e3 `/v1/stats` 500→200 is a §7 honest-failure gap) → follow-up
  [RET-1e](RET-1e.md).
