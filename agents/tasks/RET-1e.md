# RET-1e: Handler tests for the query API's `http.Error` paths and `SetIngester(non-nil)`

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 |
| **PRD ref** | Product PRD §7 (principle 2: a failure must not look like a success); Technical PRD §7 (query API); follow-up from RET-1d QA "Missing tests" (`agents/reviews/RET-1d/report.md`, mutants q2, e2, e3) |
| **Depends on** | RET-1d (PR #94) **merged** (same files, and it adds the fakes and `TestHandlersEncodeContract` this extends) |
| **Jira** | KAN-99 (board, 2026-11-21; epic KAN-2 "Retrieval & answer quality gates"; labels `task-RET-1e`, `agent-backend`, `arxivlens`) |
| **Design required** | no: test-only, one package, no route, field, status code, CLI, table, service or exported signature change |
| **Status** | Ready, **picked cycle 2026-11-21T05:00Z** (RET-1d #94 merged `29f6213`; app `main` = `11c4696`) |

## Goal
RET-1d locked the `writeJSON` call sites, but QA showed that the `http.Error` paths in `internal/query/server.go` are still unguarded.
`/v1/stats` answering **200** on a DB error (mutant e3) survives every test, and so does search's 500→502 (e2). That is the "an error
that looks like a success" failure Product PRD §7 rules out. Also, `SetIngester` silently dropping a non-nil ingester (q2) is caught only
by the Full stack job. Add no-infra rows that pin each error path's status, Content-Type and body prefix, and the non-nil `SetIngester` case.

## Scope
- `internal/query/server_test.go` only: extend the RET-1d fakes/table (or add `TestHandlersErrorContract` beside it).
- Out of scope: any change to `server.go` behaviour (if a row exposes a real bug, stop and file it in Notes as a follow-up), `writeJSON`,
  argument-passing checks (mutant e4, recording fakes: separate idea, not specced), `rag.go`, `search.go`, `cmd/`, README.
- Size: ~80 test lines.

## Acceptance criteria
- [ ] AC1 — For each `http.Error` call in `server.go` at the PR base, one row asserts code, `Content-Type: text/plain; charset=utf-8` and a body
  prefix, with no JSON body. At minimum:
  search bad JSON → 400 `invalid request payload:`; search empty query → 400 `query is required`; search fake error → 500 `search failed:`;
  ask bad JSON → 400; ask empty question → 400 `question is required`; ask fake error → 500 `rag ask failed:`;
  status empty `arxiv_id` → 400 `arxiv_id is required`; status fake error → **404** `paper not found:`;
  stats fake error → **500** `failed to get stats:`; ingest bad JSON → 400 `invalid JSON body`; ingest no `arxiv_id`/`url` → 400;
  discover bad JSON → 400; discover empty query → 400 `query is required`;
  *(added 2026-11-21 05:00Z)* ingest and discover with a valid body and **no ingester set** → **503** `paper ingester not configured on server`
  (`server.go:237`, `:268`). `server.go:133` (`writeJSON`'s own 500) is already pinned by `TestWriteJSON`; no new row.
- [ ] AC2 — `SetIngester` with a real non-nil `*PaperIngester` (built as `ingester_test.go` does: `NewPaperIngester(nil, nil, "bucket", "", 0)`)
  leaves `s.ingester` non-nil and holding that pointer (type-assert in-package). Ingest is not called.
- [ ] AC3 — Mutants run locally (never pushed), each killed by `go test -count=1 -run '^(TestWriteJSON|TestHandlersEncodeContract|TestHandlersErrorContract)$' ./internal/query/`
  (drop the last name if the rows go into the existing table), with output in the PR: (e2) search error 500→502; (e3) `/v1/stats` error
  500→200; (e5) status not-found 404→500; (e6) ask empty-question 400→500; (q2) `SetIngester` never stores a non-nil ingester.
- [ ] AC4 — `make test-unit` and `make lint` are green in CI; the Full stack job is green on the PR.
- [ ] Docs: none (tests only). Say so in the PR.

## Verification
```bash
cd app
gofmt -l internal/query/
go vet ./internal/query/
go test -race -count=1 -v -run '^(TestWriteJSON|TestHandlersEncodeContract|TestHandlersErrorContract)$' ./internal/query/
git diff --stat origin/main            # only internal/query/server_test.go
make test-unit
make lint
# CI: Go job + Full stack job on the PR
```

## Notes
- 2026-11-21 (pm-lead, RET-1d PM review): created from RET-1d QA "Missing tests" (q2, e2, e3 SURVIVED in
  `agents/reviews/RET-1d/evidence/06-ac6-mutants.png`). The `http.Error` line list comes from `server.go` at `a5bf0f4` (lines 148–268).
  Re-check it against `main` after #94 merges.
- 2026-11-21 05:00Z (pm-lead, cycle pick): re-checked against `main` `11c4696` after #94 merged. `http.Error` calls are at `server.go:133, 148, 153,
  159, 173, 178, 184, 196, 203, 213, 223, 232, 237, 257, 263, 268`. Same messages and codes as at `a5bf0f4`, plus the two 503 "ingester not
  configured" paths, which AC1 now names. `NewPaperIngester(nil, nil, "bucket", "", 0)` is still the call shape at `ingester_test.go:132`.
  Jira key KAN-99 is from the board row; the orchestrator confirms it exists.
