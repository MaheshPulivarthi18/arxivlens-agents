# ING-9: arXiv politeness on every Go arXiv request: one 3 s limiter per process + an identifying User-Agent

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1. Technical PRD §9 "External politeness" (≤ 1 arXiv request / 3 s; identifying User-Agent) is a stated requirement that isn't true today. Not P0: the on-demand path is low volume. It moves up if arXiv starts throttling or blocking (EVAL-3's nightly `seed.log` is the early warning). |
| **PRD ref** | Technical PRD §9 "External politeness"; Product PRD ING-1 ("respecting arXiv's ~1 req / 3 s policy"), ING-4, ING-5 |
| **Depends on** | none (no ADR: no shared contract changes). Start only when no open PR touches `internal/query/ingester.go`, `internal/query/ingester_test.go` or `internal/downloader/` (AGENTS.md §3). |
| **Jira** | KAN-48 |
| **Design required** | no. It's P1, adds no CLI command, table, service or contract, and is a small change to existing code. |
| **Status** | Done: ArxivLens #25 merged by Mahesh → `2b71772` (KAN-48) |

## Goal
Every arXiv request the Go code makes waits its turn: at least 3 s between request starts **within a process**, and an
identifying User-Agent on each one. Today (app `origin/main` `71cb609`) three places break this:
- `internal/query/ingester.go` `IngestPaper` sends the Atom request (`:116`, **no** User-Agent) and then the PDF request
  (`:172`, `User-Agent: ArxivLens-Bot/1.0`, which doesn't identify anyone) back to back. `DiscoverAndIngest` (`:276`, no User-Agent)
  then calls `IngestPaper`, which makes 3 requests in under a second. Concurrent `POST /v1/papers/ingest` calls aren't serialized at all.
- `internal/downloader/downloader.go:76-83` fetches PDFs one after another with no wait (it does send an identifying UA).
- The crawler (`internal/crawler/crawler.go:174-180`) already sleeps `--rate-limit` (default 3 s) and sends a UA. It is **not changed** here.

Found in the OPS-H1 design review and raised again by the EVAL-3 design: the eval seeder spaces ingests ≥ 3 s apart, but each
ingest still makes 2 arXiv requests back to back.

## Scope
- New package `internal/arxiv/` (stdlib only):
  - `Limiter` with `Wait(ctx) error`: it returns when at least `interval` has passed since the previous permit (the first call is
    immediate). It's safe for concurrent callers (they're served one at a time). It returns `ctx.Err()` at once if `ctx` ends
    while waiting, and a cancelled waiter doesn't use up a slot. `NewLimiter(interval)`, with `DefaultInterval = 3 * time.Second`
    (a constant, not an env var or flag: nobody should lower it by config).
  - `UserAgent(component string) string` → `ArxivLens/1.0 (<component>; mailto:contact@arxivlens.local)`, the same form the
    crawler and downloader already send. The contact address is the existing placeholder. Setting a real one is Mahesh's call
    and not part of this task.
- `internal/query/ingester.go`: `PaperIngester` gets a `limiter *arxiv.Limiter` field, created in `NewPaperIngester` (signature
  unchanged, so `cmd/` isn't touched; there is one ingester per query-service process, `cmd/arxivlens/main.go:249`). `Wait`
  runs before each of the three arXiv requests (Atom by ID, PDF, Atom search). All three send `arxiv.UserAgent("Query Ingester")`.
  A `Wait` error is returned like any other request error (the handler already maps errors to HTTP 500).
- `internal/downloader/downloader.go`: same `limiter` field, created in `NewDownloader` (signature unchanged), and `Wait` before
  the PDF GET. Pull the GET into a small method (e.g. `fetchPDF(ctx, url)`) so it can be unit-tested without a DB or MinIO.
  Keep the existing UA string, or switch to `arxiv.UserAgent("Downloader Pipeline")`, which gives the same value.
- Tests: `internal/arxiv/limiter_test.go` (new), `internal/query/ingester_test.go` (add cases), `internal/downloader/downloader_test.go`
  (new). Use a recording `http.RoundTripper` on the existing `httpClient`/`client` fields, and a limiter with a short interval (e.g. 50 ms)
  injected by in-package tests. No network.
- Out of scope: the crawler (already compliant); coordinating across processes (crawler, downloader and query service are separate
  processes, so the guarantee is per process: say so in the package doc); retries or 429 handling; checking the Atom response's
  HTTP status; `INGEST_TIMEOUT`/cancellation (separate Backlog item); README (no user-visible behaviour change beyond ingest
  latency of ~3 s, which goes in the PR description).

## Acceptance criteria
- [x] AC1: `Limiter` unit tests: the first `Wait` returns at once; N sequential `Wait`s with interval `d` take ≥ (N−1)·d; 10 concurrent
      callers get permits ≥ `d` apart (timestamps recorded, sorted, gaps checked, slack ≤ 20 ms); a waiter whose `ctx` is cancelled returns
      `context.Canceled` within 20 ms and the next caller isn't delayed by it; `go test -race ./internal/arxiv/...` passes.
- [x] AC2: `IngestPaper` test: the recording transport sees the Atom request and then the PDF request **≥ interval apart**, and both carry
      `User-Agent: ArxivLens/1.0 (Query Ingester; mailto:contact@arxivlens.local)`. (The test may stop the flow after the PDF request, e.g. a
      503 for the PDF, so no DB or MinIO is needed.)
- [x] AC3: `DiscoverAndIngest` test: search → Atom → PDF requests are each ≥ interval apart and all carry the UA. Two concurrent `IngestPaper`
      calls on one ingester: all 4 requests are ≥ interval apart.
- [x] AC4: Downloader test: two `fetchPDF` calls on one `Downloader` are ≥ interval apart, with the identifying UA.
- [x] AC5: The production interval is 3 s: a test asserts `arxiv.DefaultInterval == 3*time.Second` and that `NewPaperIngester` and
      `NewDownloader` use it. No env var or flag can lower it.
- [x] AC6: No `User-Agent: ArxivLens-Bot/1.0` and no arXiv request without a UA left: `grep -rn "ArxivLens-Bot" internal/` prints nothing.
- [x] AC7: Per-file coverage ≥ 90% for `internal/arxiv/limiter.go`:
      `go test -coverprofile=c.out ./internal/arxiv/ && go tool cover -func=c.out` (CI output, or a scratch-module run on local Go, since the
      package is stdlib only; lesson AI-1).
- [x] AC8: A `stack.yml` run of the PR head (dispatched: `gh workflow run stack.yml --ref agent/backend/ING-9`, because the workflow's path filter skips Go-only PRs until OPS-H10 merges) is green apart from the known F1 step (the crawl → download → embed path and the on-demand ingest step still
      work, now with the waits). Diff < 400 changed lines; `cmd/`, `go.mod`/`go.sum` unchanged.

## Verification
```bash
make lint
make test-unit
go test -race -count=1 -v ./internal/arxiv/... ./internal/downloader/...
go test -race -count=1 -v -run 'Ingest|Discover' ./internal/query/
go test -coverprofile=c.out ./internal/arxiv/ && go tool cover -func=c.out
grep -rn "ArxivLens-Bot" internal/      # expect no output
git diff origin/main --stat
```

## Notes
- 2026-11-07 (pm-lead): specced from the EVAL-3 design's request (`docs/design/EVAL-3.md`, PM decision) and the Backlog item from the OPS-H1
  design. Not in the 2026-11-07 plan: put it in the "Ready — not in this plan" table, after OPS-H7 and OPS-H2. It moves ahead of them if an
  EVAL-3 nightly `seed.log` shows arXiv 429/403 responses.
- Docs truthfulness: Product PRD ING-1 ✅ says "respecting arXiv's ~1 req / 3 s policy", which holds for the crawler only. The next
  pm-lead PRD docs PR adds the caveat ("crawler only; ingester/downloader: ING-9"), and it's removed when this merges.
- 2026-11-07 (backend-engineer): built on `agent/backend/ING-9` (commit `c5dc873`, base `71cb609`), not pushed (orchestrator opens the draft PR).
  - New `internal/arxiv/limiter.go`: `Limiter` (capacity-1 channel as the "turn" + `last` permit time; a waiter cancelled while queued
    or while sleeping returns `ctx.Err()` without setting `last`, so it uses no slot), `DefaultInterval = 3s` const, `UserAgent(component)`,
    `Interval()` accessor for the AC5 tests. Package doc states the guarantee is per process.
  - `ingester.go`: `limiter` field set in `NewPaperIngester` (signature unchanged); new `doArxiv(req)` waits, sets
    `arxiv.UserAgent("Query Ingester")` and sends, used for Atom-by-ID, PDF and Atom search. `ArxivLens-Bot/1.0` is gone.
  - `downloader.go`: `limiter` field set in `NewDownloader` (signature unchanged); PDF GET moved into `fetchPDF(ctx, url)`, which waits
    first; UA via `arxiv.UserAgent("Downloader Pipeline")` (same string as before).
  - Diff: 6 files, +376/-22 = 398 changed lines (ownership-check OK); `cmd/`, `go.mod`, `go.sum` unchanged.
  - Local verification (sandbox Go 1.24, no module proxy): scratch module with the three packages copied in and minimal stubs for
    db/storage/kafka/events/minio/kgo. `go vet` clean; `go test -race -count=1 -v` passes for arxiv, downloader and the
    `Ingest|Discover` query tests; `-count=20 -race` stable; `limiter.go` coverage 100%. Mutants (Wait removed from doArxiv/fetchPDF,
    sleep removed, ctx ignored while sleeping) are each caught. Full-repo `make lint`/`make test-unit` and `stack.yml` (AC8) need CI.
  - Test timing: HTTP tests use a 50 ms interval with 10 ms slack between permit and transport timestamp; limiter tests use 20 ms slack.
- 2026-11-07 (pm-lead, ING-9 QA r1 [spec] finding 2): AC8 reworded to "a dispatched `stack.yml` run of the PR head". The path filter
  doesn't match `internal/**`, so the run never starts by itself. The orchestrator or backend dispatches it on the rework head, and the run link goes
  in these Notes and the PR. Widening the filter is new ticket **OPS-H10** (backend), not this PR (`stack.yml` is out of this ticket's files).
- 2026-11-07 (pm-lead, final review): **APPROVE** on `c5dc873`. Every AC has evidence (`agents/reviews/ING-9/report.md`, files 00–15).
  AC8: dispatched `stack.yml` run [42364519257](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42364519257) succeeded, apart from the known F1 failure.
  The PR body for raising it is at `/tmp/claude-0/s/pr25-body.md`. The planned "crawler only" PRD caveat was never written, so ING-1 ✅ needs no edit on merge.
  QA nits 3–7 went to the Backlog: "ING-9 follow-ups" (backend P3: ingester cancelled-ctx test, tighter limiter `d`, `HandleRecord` wiring test
  once db/storage have interfaces, redirect hops) and "`-race` in CI's Go job" (backend P2, harness).
- 2026-11-07 11:00Z (pm-lead, grooming): merged by Mahesh as `2b71772` (#25); Jira Done. Follow-ups stay in the board Backlog.
