# ING-9d: Deterministic test that `Limiter.Wait` on a cancelled ctx never takes a permit

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 (harness) |
| **PRD ref** | Technical PRD §9 "External politeness" (≤ 1 arXiv request / 3 s); Product PRD ING-1; ING-9c QA r1 optional mutant x5 (`agents/reviews/ING-9c/report.md:43`, evidence `07-x5-kill-rate`) and PM decision item 1 (`:77`) |
| **Depends on** | ING-9c (ArxivLens #99, merged `b56739e`). No ADR. No open PR touches `internal/arxiv/` (checked 2026-11-21 11:00Z against #104–#110; the only Go PR, #105, edits `internal/query/server_test.go`) |
| **Jira** | needs creating: epic KAN-4 "Continuous ingestion"; labels `task-ING-9d`, `agent-backend`, `arxivlens`; link KAN-103 (ING-9c) |
| **Design required** | no: one new test in an existing test file |
| **Status** | Ready |

## Goal
`Limiter.Wait` (`internal/arxiv/limiter.go`, on `origin/main` `11c4696`) starts with `if err := ctx.Err(); err != nil { return err }`.
Without that check, a cancelled ctx and a free `turn` slot are both ready in the following `select`, Go picks one at random, and
about half the time a cancelled caller takes a permit and sets `l.last`. ING-9c QA showed today's tests kill that mutant (x5) only
24/30 (`TestIngestCancelledCtxSendsNoRequest`) and 14/30 (`TestFirstWaitIsImmediate`) times, so a regression would show up as a
flaky test. This ticket adds a test that fails every time.

## Scope
- `internal/arxiv/limiter_test.go`: one new test (e.g. `TestCancelledCtxNeverTakesPermit`).
- Out of scope: any non-test file, other test files, the existing tests' assertions.
- Size: ~15–25 lines.

## Acceptance criteria
- [ ] AC1: The new test loops ≥ 50 times; each iteration builds a fresh `NewLimiter(time.Hour)`, calls `Wait` with an
  already-cancelled ctx and requires `errors.Is(err, context.Canceled)`, then requires that a `Wait(context.Background())` on the
  same limiter returns at once (the cancelled call took no permit; reuse `waitImmediate`). It passes with `-count=20` and `-race`.
- [ ] AC2: Mutation check (developer or QA; output in an evidence file; revert afterwards): x5 (delete the up-front `ctx.Err()`
  check in `Limiter.Wait`) makes the new test fail in **30/30** runs (`go test -count=30 -run <NewTest> ./internal/arxiv/`, count
  the `FAIL`s). Unmutated: 30/30 pass.
- [ ] AC3: Runtime of the new test < 100 ms (quote the `-v` `--- PASS` line).
- [ ] AC4: CI on the draft PR: `Go` (`make test-unit`) and `Lint` green.
- [ ] Docs: none (test-only).

## Verification
```bash
go test -count=20 -race -v -run 'TestCancelledCtxNeverTakesPermit' ./internal/arxiv/
go test -count=1 ./internal/arxiv/...
make test-unit && make lint    # CI is the source of truth; Go 1.25.1 is at /usr/local/go1.25.1 in some sandboxes
git diff origin/main --name-only   # exactly internal/arxiv/limiter_test.go
```

## Notes
- 2026-11-21 11:00Z (pm-lead): specced from the Backlog ING-9c follow-up (unblocked since #99 merged; waited for a free backend slot).
