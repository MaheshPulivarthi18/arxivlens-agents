# ING-9c: Ingester sends no arXiv request on a cancelled ctx; tighter limiter spacing test

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 (harness) |
| **PRD ref** | Technical PRD §9 "External politeness"; Product PRD ING-1 (~1 req / 3 s); follow-up from the ING-9 QA/PM review (QA r1 nits 3 and 5, `agents/reviews/ING-9/report.md:43,45`, PM decision `:144,146`) |
| **Depends on** | ING-9 (#25, merged `2b71772`). No open PR touches the files below (checked 2026-11-21 00:00Z: #94 `internal/query/server.go` + `server_test.go`, #97 `internal/query/search_integration_test.go`, #93 `cmd/arxivlens/`; nothing under `internal/arxiv/`) |
| **Jira** | to be created by the orchestrator (epic KAN-4 "Continuous ingestion"; labels `task-ING-9c`, `agent-backend`, `arxivlens`; link KAN-48) |
| **Design required** | no: test-only, two existing test files |
| **Status** | Ready (picked 2026-11-21 00:00Z) |

## Goal
The ingester checks the limiter's error before each arXiv request, so a cancelled ingest (client gone, `INGEST_TIMEOUT`) never sends
one. No test pins this, and ING-9 QA's surviving mutant "ignore the `Wait` error" proves it. Also `TestConcurrentCallersAreSpaced`
uses d = 30 ms with 20 ms slack, so it only proves gaps of at least 10 ms. Both gaps close here, with tests only.

Checked on `origin/main` `230f617`:
- Atom/search requests: `internal/query/ingester.go:66-67` `getAPI` → `arxiv.GetAPI` (`internal/arxiv/http.go:126-133`, `if err := lim.Wait(ctx); err != nil { return err }`).
- PDF request: `internal/query/ingester.go:198-205` (`ing.retry.Do` → `ing.limiter.Wait(ctx)` → `arxiv.FetchPDF`).
- Test fakes: `arxivStub` (records each request, PDF → 503) and `newStubIngester` (`retry = arxiv.NoRetry`), `ingester_test.go:102-135`.
- `internal/arxiv/limiter_test.go:61-77`: `const n, d = 10, 30 * time.Millisecond`, `slack = 20 * time.Millisecond` (`:13`).

## Scope
- `internal/query/ingester_test.go`: new test(s) using the existing `arxivStub` / `newStubIngester` (a small stub variant that cancels a ctx from inside `RoundTrip` is fine).
- `internal/arxiv/limiter_test.go`: `TestConcurrentCallersAreSpaced` with d >= 100 ms (slack stays 20 ms).
- Out of scope: any non-test file; the `HandleRecord` → `fetchPDF` wiring test (needs db/storage interfaces, still Backlog); the `arxiv.org/pdf` redirect check (needs network, still Backlog); `-race` in CI (OPS-H15).
- Size: ~50-70 lines.

## Acceptance criteria
- [ ] AC1: With an already-cancelled ctx, `IngestPaper(ctx, "2307.08691")` and `DiscoverAndIngest(ctx, "flash attention")` each return an error where `errors.Is(err, context.Canceled)`, and the stub records **0** requests.
- [ ] AC2: If the ctx is cancelled after the Atom response (the stub cancels it while serving the `id_list=` request), `IngestPaper` returns an error with `errors.Is(err, context.Canceled)`. The stub records exactly 1 request (the `id_list=` one) and no `.pdf` request. If Go's `http.Client` turns out to refuse a cancelled ctx before `RoundTrip` (so the mutant in AC4 (m2) survives anyway), record the exact observation in Notes and keep the assertions.
- [ ] AC3: `TestConcurrentCallersAreSpaced` uses d >= 100 ms with `slack` unchanged (20 ms), so it proves gaps >= 80 ms. It still passes `-count=10`. Runtime grows by < 1.5 s.
- [ ] AC4: Mutation check, run by the developer or the QA harness, with output in an evidence file; revert each mutant afterwards. (m1) `arxiv.GetAPI` ignores the `Wait` error (`_ = lim.Wait(ctx)`): AC1 fails. (m2) `ingester.go:199` ignores the `Wait` error: AC2 fails. (m3) `Limiter.Wait` without the `turn` channel serialization (the ING-9 "no serialization" mutant): AC3 fails. (m4) `Limiter.Wait` sleeps `interval/2`: AC3 fails. Mutant (m4) survives today's d = 30 ms test (15 ms gap >= 10 ms) and must die with the new d.
- [ ] AC5: `go test -race -count=5 ./internal/arxiv/... ./internal/query/...` passes (CI or developer output). The CI `Go` job (`make test-unit`) and `make lint` are green on the draft PR. Quote the new tests' `--- PASS` lines from a `-v` run, or name the CI job ID.
- [ ] Docs: none (test-only).

## Verification
```bash
go test -count=1 -v -run 'TestConcurrentCallersAreSpaced' ./internal/arxiv/
go test -count=1 -v -run 'Cancel' ./internal/query/
go test -race -count=5 ./internal/arxiv/... ./internal/query/...
make test-unit && make lint      # CI is the source of truth (sandbox may lack Go 1.25: "not run locally" OK)
git diff origin/main --name-only # exactly internal/query/ingester_test.go and internal/arxiv/limiter_test.go
```

## Notes
- 2026-11-21 00:00Z (pm-lead): the ING-9 follow-ups were meant to "fold into the next `ingester.go`/`internal/arxiv` change", and none has come in 14 days. The two test-only items get their own ticket now. The wiring test and the redirect check stay in the Backlog line.
- 2026-11-21 (backend-engineer): built on `agent/backend/ING-9c` commit `6afd06d` (2 test files, +55/-1). Sandbox has Go 1.24.7 and
  the module proxy is blocked, so `internal/query` was **not run locally**. `internal/arxiv` (stdlib only) was run with a temporary
  `go 1.24` modfile: new spacing test PASS (0.90 s, was 0.27 s), `-count=10` ok, `-race -count=5` ok. m3 (no `turn`) fails (gap 1.07 µs),
  m4 (`interval/2`) fails at d=100 ms (gap 50.3 ms) and survives the old d=30 ms test. AC2 probe (Go 1.24.7): `http.Client` with a
  custom Transport calls `RoundTrip` on an already-cancelled ctx (Timeout 0 and 5 s), so m1/m2 should die. QA/CI still has to run AC1/AC2 and m1/m2.
