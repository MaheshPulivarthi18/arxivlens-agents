# OPS-H6b: Go consumer doesn't log a "Poll error" for its own clean shutdown

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 |
| **PRD ref** | Product PRD OPS-1 (retry + DLQ with full diagnostics: diagnostics must not cry wolf); follow-up from the OPS-H6 PM review |
| **Depends on** | OPS-H6 (#15) merged. No open PR touches `internal/kafka/` |
| **Jira** | [KAN-75](https://maheshsworkspace-42184075.atlassian.net/browse/KAN-75) |
| **Design required** | no: one guard in a log statement, no contract/CLI/table/service change |
| **Status** | Ready to merge (PR #72 @ `0fbf4e0`; QA PASS r1, PM APPROVE r1) |

## Goal
On a clean shutdown (`ctx` cancelled), franz-go's `PollFetches(ctx)` returns a fetch whose only error is `ctx.Err()` on partition -1, and
`Consumer.Start` logs it as `[Kafka Consumer] Poll error (topic= partition=-1): context canceled` before the `Context cancelled,
shutting down` line. Operators reading the downloader log see an error that isn't one. Skip logging exactly that case; every other poll
error stays logged.

## Scope
- Files expected to change (and only these): `internal/kafka/consumer.go` (the `fetches.EachError` callback in `Start`, lines ~114–118 on
  4c7d327), `internal/kafka/consumer_test.go` (new test(s); existing tests unmodified).
- Rule to implement: inside `EachError`, keep computing `closed` (the `kgo.ErrClientClosed` check) **first, for every error**; then skip
  the `log.Printf` only when `ctx.Err() != nil && errors.Is(err, ctx.Err())`. Errors that are not the context's own error are still
  logged, even after cancel. Nothing else changes: return values, commit order, `AllowRebalance`, the shutdown log line.
- Out of scope: the Python consumer (`services/common/kafka_client.py`), the DLQ Reader (`internal/kafka` reader files from OPS-H7a1),
  `stack.yml` (it doesn't stop the downloader gracefully, so it can't show the line either way).

## Acceptance criteria
- [ ] AC1: New test: a run that ends through the fake's `poll(end)` path (partition -1, `Err: ctx.Err()` after cancel) captures `log`
  output and asserts it contains `Context cancelled, shutting down` and **no** `Poll error`. `Start` returns nil.
- [ ] AC2: New test row: after `ctx` is cancelled, a fetch carrying a **different** error (e.g. `errBoom` on partition 0) still logs
  `Poll error (topic=<topic> partition=0): boom`.
- [ ] AC3: Existing `TestConsumerPollErrorStillProcessesRecords` (partition error logged while ctx is live; `ErrClientClosed` returned)
  and every other test in `internal/kafka/` pass unmodified (`git diff --numstat origin/main -- internal/kafka/consumer_test.go`
  shows 0 deletions).
- [ ] AC4: Mutation, one per operand (QA applies each to `consumer.go`, runs `go test -count=1 ./internal/kafka/`, shows a named test
  failing): (a) remove the guard → AC1 test fails; (b) guard on `ctx.Err() != nil` alone (drop `errors.Is`) → AC2 test fails;
  (c) move the skip **before** the `closed` computation and make it skip `ErrClientClosed` too (e.g. `if ctx.Err() != nil { return }` at
  the top of the callback) → a test fails (AC2's, or a new row: ctx cancelled + `kgo.ErrClientClosed` → `Start` returns
  `kgo.ErrClientClosed`; add that row if (c) survives).
- [ ] AC5: CI `ci.yml` job `Go (vet, gofmt, test, build)`: step `Kafka consumer tests (verbose, race, coverage)` passes with the new test
  names in its `-v` output and prints the `consumer.go` coverage rows (quote the run ID and the `Start` row, before vs after).
  `make lint-go` clean. Ownership check passes for role=backend.
- [ ] Docs: none needed (no command, flag or API change). The comment above the `EachError` call says why ctx's own error is skipped.

## Verification
```bash
gofmt -l internal/kafka/ && go vet ./internal/kafka/
go test -race -count=1 -v -run 'Consumer' ./internal/kafka/
go test -count=1 -coverprofile=c.out ./internal/kafka/ && go tool cover -func=c.out | grep consumer.go
.github/scripts/ownership-check.sh origin/main agent/backend/OPS-H6b
git diff --stat origin/main && git diff --numstat origin/main
```
Agent sandboxes may lack Go 1.25 (AGENTS.md §6): "not run locally" is fine; CI's Go job is the source of truth. QA runs the AC4
mutants in a scratch checkout if a Go 1.25 toolchain is available, else on a throwaway branch's CI (say which). `make eval`: not run,
no retrieval/answering change.

## Notes
- 2026-11-19 23:00Z (pm-lead): specced from the Backlog line "From the OPS-H6 PM review … `Poll error (topic= partition=-1): context
  canceled`". Verified on 4c7d327: `consumer.go:113-118` logs every `EachError` error unconditionally; the test fake's `PollFetches`
  already returns the shutdown shape (`Partition: -1, Err: ctx.Err()`) at `consumer_test.go:58-62`.
- Independent of every open PR (#65 `internal/query/rag*.go`, `tests/test_evals_data.py`, `README.md`; #66 workflows/CONTRIBUTING/compose;
  #68–#70 `frontend/**`) and of OPS-H14 (`ci.yml`, `.github/scripts/`) and AI-12 (`services/embedder/`, `tests/test_verify.py`).
- 2026-11-20 (backend-engineer): built on `agent/backend/OPS-H6b` commit `0fbf4e0` (from 4c7d327), +59/-0 lines.
  `consumer.go`: in `EachError`, `closed` is still computed first for every error, then
  `if ctx.Err() != nil && errors.Is(err, ctx.Err()) { return }` skips only the log line; comment above `EachError` says why.
  `consumer_test.go` (additions only): `cancelPoll` wrapper (cancels ctx inside `PollFetches`, returns a scripted fetch) and
  table test `TestConsumerPollErrorAfterCancel` with rows: "clean shutdown logs no poll error" (AC1, fake's `poll(end)` path),
  "other error after cancel is still logged" (AC2, `errBoom` on partition 0), "client closed after cancel still returns the error"
  (AC4c guard row). Expected mutant kills: (a) row 1, (b) row 2, (c) rows 2 and 3.
  Local: `gofmt -l internal/kafka/` clean; ownership check `Ownership OK for role=backend (59 changed lines)`.
  **Not run locally:** `go vet`/`go test` (Go 1.24.7 local, go.mod needs 1.25; module downloads from proxy.golang.org blocked by the
  sandbox proxy even with a 1.24 scratch copy). CI's Go job is the source of truth for AC3/AC5 and coverage rows.
- 2026-11-20 03:25Z (orchestrator): draft PR [#72](https://github.com/MaheshPulivarthi18/ArxivLens/pull/72) @ `0fbf4e0` → CI green → QA PASS r1 (`agents/reviews/OPS-H6b/report.md`) → PM APPROVE r1 (`5192b06`) → raised for review, label `ready-to-merge`. Jira → Ready to merge.
