# OPS-H6c: Pin "no Poll error" for a deadline-ended consumer ctx (test-only)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 |
| **PRD ref** | Product PRD OPS-1 (retry + DLQ with full diagnostics: diagnostics must not cry wolf); follow-up from the OPS-H6b QA/PM review (`agents/reviews/OPS-H6b/report.md` lines 41, 79; QA mutant M9) |
| **Depends on** | OPS-H6b (#72, merged `8cf7251`). No open PR touches `internal/kafka/` (checked 2026-11-20 05:00Z against #65, #66, #68, #69, #70 via REST) |
| **Jira** | to create (epic KAN-3 "Dev harness & infrastructure"; labels `task-OPS-H6c`, `agent-backend`, `arxivlens`) |
| **Design required** | no: one test row, no production code, contract, CLI, table or service change |
| **Status** | Ready to merge — PR [#76](https://github.com/MaheshPulivarthi18/ArxivLens/pull/76) `6b1e814` (QA PASS r1, PM APPROVE r1), waiting for Mahesh |

## Goal
OPS-H6b's guard in `Consumer.Start` skips the `Poll error` log line when the fetch error is ctx's **own** error
(`ctx.Err() != nil && errors.Is(err, ctx.Err())`, `internal/kafka/consumer.go:119` on `e6cffba`). Every test row ends its ctx with
`cancel()`, so `ctx.Err()` is always `context.Canceled`, and QA mutant M9 (`ctx.Err()` → `context.Canceled` in the guard) survives. A
ctx that ends by **deadline** (`context.DeadlineExceeded`) must also shut down quietly. Add a row that ends through a deadline, so the
`ctx.Err()` choice is pinned and M9 is killed.

## Scope
- Files expected to change (and only this one): `internal/kafka/consumer_test.go`, additions only.
- What to add: a test (a new row in `TestConsumerPollErrorAfterCancel` or a sibling test next to it) where `Start` runs on a
  `context.WithTimeout` ctx (e.g. 20 ms) whose deadline expires **while `PollFetches` is running**: a small fake wrapper (like the
  existing `cancelPoll`, `consumer_test.go:331`) whose `PollFetches(ctx)` blocks on `<-ctx.Done()` and returns
  `fetchOf(kgo.FetchPartition{Partition: -1, Err: ctx.Err()})`, which is the shape franz-go returns on shutdown. Don't use an
  already-expired ctx: `Start` would return in its `select` before polling, and the row would prove nothing.
- Out of scope: `consumer.go` (no production change). If the new row fails on `e6cffba`, **stop and report** in Notes. Don't
  change the guard. Also out of scope: the DLQ Reader, the Python consumer.

## Acceptance criteria
- [ ] AC1: The new row captures `log` output (same `log.SetOutput` pattern as the existing rows) and asserts: `Start` returns nil;
  the output contains `Context cancelled, shutting down`; the output contains **no** `Poll error`; and the fake's poll was reached
  (e.g. its `add("poll(deadline)")` entry is in `f.log`, or a counter is 1). The last check makes sure the row really went through
  `PollFetches`.
- [ ] AC2: The ctx's error at the end of the row is `context.DeadlineExceeded` (assert `errors.Is(ctx.Err(), context.DeadlineExceeded)`),
  so the row can't silently become a cancel row.
- [ ] AC3: Mutation, one per mutant (QA applies each to `consumer.go`, runs `go test -count=1 ./internal/kafka/`, names the failing test):
  (a) M9: `errors.Is(err, ctx.Err())` → `errors.Is(err, context.Canceled)` → the new row fails (it survived in OPS-H6b);
  (b) remove the guard entirely → the new row fails, and so does the existing "clean shutdown logs no poll error" row.
- [ ] AC4: Existing tests unmodified: `git diff --numstat origin/main -- internal/kafka/consumer_test.go` shows 0 deletions, and
  that's the only file in the diff. CI `ci.yml` job `Go (vet, gofmt, test, build)`, step `Kafka consumer tests (verbose, race, coverage)`
  passes and its `-v` output lists the new test or subtest name as `--- PASS` (quote the run ID and the line). `make lint-go` is clean.
  The ownership check passes for role=backend.
- [ ] AC5: Runtime: the new row finishes in < 1 s under `-race` (quote its `--- PASS (0.0Xs)` line). Use a deadline in milliseconds,
  not seconds.
- [ ] Docs: none (test-only). A one-line comment above the row says it pins the deadline case (M9).

## Verification
```bash
gofmt -l internal/kafka/ && go vet ./internal/kafka/
go test -race -count=1 -v -run 'Consumer' ./internal/kafka/
.github/scripts/ownership-check.sh origin/main agent/backend/OPS-H6c
git diff --stat origin/main && git diff --numstat origin/main
```
Agent sandboxes may lack Go 1.25 (AGENTS.md §6): "not run locally" is fine, and CI's Go job is the source of truth. QA can run the AC3
mutants locally against real franz-go with go1.24, as in OPS-H6b (`agents/reviews/OPS-H6b/evidence/08-harness-sources.txt`), or on
a throwaway branch's CI (say which). `make eval`: not run, because nothing in retrieval or answering changes. `stack.yml` runs on
the PR (`internal/**` path) and has to be green apart from the documented F1 step.

## Notes
- 2026-11-20 05:00Z (pm-lead): specced from the Backlog line "From the OPS-H6b PM review (backend, P2, next `internal/kafka/consumer*`
  change): add a deadline-ctx row …". Checked on app `origin/main` `e6cffba`: the guard is at `consumer.go:119`, and
  `TestConsumerPollErrorAfterCancel` (`consumer_test.go:343`) has three rows, all ended through `cancel()`. The QA M9 mutant text is
  in `agents/reviews/OPS-H6b/evidence/04-ac4-mutants.txt:11`. Today M9 is equivalent in production, since every `Start` ctx is
  `signal.NotifyContext`. The row stops a future `WithTimeout` caller (or a refactor of the guard) from bringing the false
  `Poll error` back.
- Independent of every open PR (#65 `internal/query/rag*.go`, `tests/test_evals_data.py`, `README.md`; #66 `db.yml`, `image-pins.yml`,
  `CONTRIBUTING.md`, `docker-compose.yml`; #68/#69/#70 `frontend/**` + root `README.md`), and of AI-12b, ING-11c and LLM-1d (groomed in
  the same pass).
- 2026-11-20 05:10Z (backend): built on `agent/backend/OPS-H6c` commit `6b1e814` (from `e6cffba`), not pushed. I added a sibling test
  `TestConsumerPollErrorAfterDeadline` and a `deadlinePoll` fake to `internal/kafka/consumer_test.go`: +37/-0, the only file changed,
  `consumer.go` untouched. The fake logs `poll(deadline)`, blocks on `<-ctx.Done()` and returns `fetchOf(Partition -1, Err: ctx.Err())`.
  `Start` runs on `context.WithTimeout(…, 20*ms)`. The row passes on `e6cffba`.
  Local evidence used a go1.24 scratch module with the real `internal/kafka` + `shared/events` sources and the real franz-go v1.16.1,
  kmsg v1.7.0, compress, lz4, ulid and x/crypto from tag-pinned GitHub clones. Go 1.25 isn't in the sandbox, so `make lint-go` and
  the repo-wide `go vet ./...` weren't run; that part is for CI.
  - `go test -race -count=1 -v -run 'Consumer'`: everything passes, including `--- PASS: TestConsumerPollErrorAfterDeadline (0.02s)`
    (AC5). Under `-race -count=50` it passed every time.
  - Mutants on `consumer.go`, each run on the full package and with `-run '^TestConsumerPollErrorAfterDeadline$'`:
    M9 (`errors.Is(err, context.Canceled)`): only the new test fails (`Poll error (topic=papers.discovered partition=-1): context deadline exceeded`).
    With the guard removed: the new test and `TestConsumerPollErrorAfterCancel/clean_shutdown_logs_no_poll_error` both fail (AC3).
  - `gofmt -l internal/kafka/` prints nothing. `go vet ./internal/kafka/` is clean in the scratch module. Ownership check:
    `Ownership OK for role=backend (37 changed lines)`.
  - Still open for CI: the AC4 run ID and the `--- PASS` line from the `Kafka consumer tests` step, plus `make lint-go` and `stack.yml`.
- 2026-11-20 (qa-reviewer): round 1 **PASS** at `6b1e814`. M9 and the no-guard mutant killed, real-kgo probe matches the fake, CI 6/6 green, 1 nit. See `agents/reviews/OPS-H6c/report.md`.
- 2026-11-20 08:00Z (pm-lead): round 1 **APPROVE** (first posted in the PR #76 body by the interrupted 05:00Z cycle; recorded in `agents/reviews/OPS-H6c/report.md` now). Opened every evidence file 00–08; each AC is proven by CI (02, 08) and QA's mutants (04, 05). PR #76 was already ready for review with `ready-to-merge`; its evidence URLs are pinned to `4e33774`, which holds byte-identical blobs, so I left the PR as is. No follow-ups.
