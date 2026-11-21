# ING-9d: Deterministic test that `Limiter.Wait` on a cancelled ctx never takes a permit

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 (harness) |
| **PRD ref** | Technical PRD §9 "External politeness" (≤ 1 arXiv request / 3 s); Product PRD ING-1; ING-9c QA r1 optional mutant x5 (`agents/reviews/ING-9c/report.md:43`, evidence `07-x5-kill-rate`) and PM decision item 1 (`:77`) |
| **Depends on** | ING-9c (ArxivLens #99, merged `b56739e`). No ADR. No open PR touches `internal/arxiv/` (checked 2026-11-21 11:00Z against #104–#110; the only Go PR, #105, edits `internal/query/server_test.go`) |
| **Jira** | KAN-114 (epic KAN-4 "Continuous ingestion"; labels `task-ING-9d`, `agent-backend`, `arxivlens`; link KAN-103 (ING-9c)) |
| **Design required** | no: one new test in an existing test file |
| **Status** | Done (PR #112 merged 2026-11-21 → `69a0240`) |

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
- [x] AC1: The new test loops ≥ 50 times; each iteration builds a fresh `NewLimiter(time.Hour)`, calls `Wait` with an
  already-cancelled ctx and requires `errors.Is(err, context.Canceled)`, then requires that a `Wait(context.Background())` on the
  same limiter returns at once (the cancelled call took no permit; reuse `waitImmediate`). It passes with `-count=20` and `-race`.
- [x] AC2: Mutation check (developer or QA; output in an evidence file; revert afterwards): x5 (delete the up-front `ctx.Err()`
  check in `Limiter.Wait`) makes the new test fail in **30/30** runs (`go test -count=30 -run <NewTest> ./internal/arxiv/`, count
  the `FAIL`s). Unmutated: 30/30 pass.
- [x] AC3: Runtime of the new test < 100 ms (quote the `-v` `--- PASS` line).
- [x] AC4: CI on the draft PR: the `Go (vet, gofmt, test, build)` job green, including its steps `Run make lint-go` and
  `Go unit tests (make test-go, race detector)`, and the `Run npm run lint` step of the `Frontend (lint, test, build)` job green.
  _(Amended at PM review 2026-11-21, QA r1 [spec] finding 2: the original wording named a `Lint` job that doesn't exist;
  `make lint` = `lint-go` + `lint-fe`, which run as steps inside those two jobs. Same intent, no change to what was checked.)_
- [x] Docs: none (test-only).

## Verification
```bash
go test -count=20 -race -v -run 'TestCancelledCtxNeverTakesPermit' ./internal/arxiv/
go test -count=1 ./internal/arxiv/...
make test-unit && make lint    # CI is the source of truth; Go 1.25.1 is at /usr/local/go1.25.1 in some sandboxes
git diff origin/main --name-only   # exactly internal/arxiv/limiter_test.go
```

## Notes
- 2026-11-21 11:00Z (pm-lead): specced from the Backlog ING-9c follow-up (unblocked since #99 merged; waited for a free backend slot).
- 2026-11-21 (backend-engineer): built on `agent/backend/ING-9d` (commit `ac9ba42`, +19 lines in `internal/arxiv/limiter_test.go` only): `TestCancelledCtxNeverTakesPermit`, 50 tries, checks `context.Canceled` + `l.last.IsZero()` then `waitImmediate`. Local Go 1.25.1 (`/usr/local/go1.25.1`, `GOTOOLCHAIN=local`): `-count=20 -race` 20/20 PASS; runtime `(0.00s)`; x5 mutant 30/30 FAIL (also 30/30 under `-race`), reverted, unmutated 30/30 PASS. Ownership check OK. Full `make test-unit`/`make lint` not runnable locally (otel modules missing) → CI. Not pushed; orchestrator opens the draft PR.
- 2026-11-21 (pm-lead): final review **APPROVE** (`agents/reviews/ING-9d/report.md`). AC4 reworded to name the real CI job/steps (QA [spec] 2). PR #112 description rewritten with pinned evidence, marked ready for review, label `ready-to-merge`. No PRD status change: test-only harness work, ING-1 row unchanged. Follow-up: OPS-H19 AC7 also names a `Lint` job; fix at its PM review.
