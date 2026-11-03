# OPS-H6: Go consumer commits an offset only after success or a confirmed DLQ write; context-aware retry wait

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (silent message loss in the pipeline) |
| **PRD ref** | Product PRD OPS-1, OPS-3, §5.3; Technical PRD §8.1 (L4 commit-after-process), §8.2 (retry and DLQ) |
| **Depends on** | — |
| **Jira** | KAN-28 (`labels = "task-OPS-H6"`) |
| **Design required** | **yes**: P0, and it changes the pipeline's delivery semantics (what is committed when, and what happens on redelivery) |
| **Status** | In Progress (rework round 1: PM final review CHANGES 2026-11-03, see `agents/reviews/OPS-H6/report.md`); draft PR [#15](https://github.com/MaheshPulivarthi18/ArxivLens/pull/15), QA round 1 PASS at `7814563` |

## Goal
Technical PRD §8.1 promises L4 for the Go consumer: an offset is committed only after the handler succeeds or the
message has been routed to the DLQ. The code doesn't keep that promise. In `internal/kafka/consumer.go` (at `origin/main`
`9c1229a`), when `PublishDLQ` fails after `maxRetries`, the consumer only logs `CRITICAL: Failed to write to DLQ` (line 131),
then `CommitRecords` runs anyway (line 137). The record is gone from both the topic and the DLQ. Also, the retry wait is
`time.Sleep(retryBackoff(attempt))` (line 102), so shutdown waits out the backoff. Fix both, so the pipeline is really
at-least-once and an operator (Product PRD §5.3) finds every failed paper in the DLQ.

Found by an external review of ArxivLens at `bb9ee90` (see PROGRESS 2026-11-03); re-checked by pm-lead against `9c1229a`.

## Scope
- Files: `internal/kafka/consumer.go`, `internal/kafka/consumer_test.go`. If the tests need it, a small seam: an interface over
  the `kgo.Client` calls the loop uses (poll, commit, rewind/seek, `AllowRebalance`), a DLQ-publisher interface that
  `*Producer` satisfies, and an injectable wait function. `cmd/arxivlens/main.go` only if the constructor signature changes (the design keeps it unchanged, so don't touch it). `.github/workflows/ci.yml`: one added step in the `go` job (verbose/race/coverage run of `./internal/kafka/`, design PM decision Q3). **Not** `Makefile` (OPS-H1 edits it in parallel).
- Docs: app `README.md:39` and `CONTRIBUTING.md:57` if the retry/DLQ wording changes. Technical PRD §8.1/§8.2 is a
  pm-lead docs PR: put the new sequence (who commits when, what's redelivered) in this task's Notes.
- Out of scope: the Python consumer (`services/common/kafka_client.py:170-199`, same pattern; follow-up OPS-H8 in the
  board Backlog), DLQ replay (OPS-H7), changing `maxRetries` or the backoff schedule, the event envelope or topics (shared contract).

## Design must answer (in `docs/design/OPS-H6.md`)
1. **Kafka commits are per partition and cumulative.** Not committing record N is not enough: if record N+1 in the same
   partition succeeds and is committed, N is committed with it. Say how the loop stops that. Options: stop handling that
   partition for this poll and rewind its fetch position to N (`SetOffsets`/seek); return from `Start` with an error so
   the process restarts from the last commit; or keep retrying the DLQ write in place with backoff until it succeeds or ctx ends.
   Pick one and give the reasons. Say what happens to records from other partitions in the same poll.
2. **No hot loop while the DLQ is down.** How often the record is retried (handler + DLQ write) and how the loop waits between rounds.
3. **Redelivery against the idempotency layers.** Today the only Go consumer is the downloader (`papers.discovered`,
   `cmd/arxivlens/main.go:153`). A redelivered record re-runs `Downloader.HandleRecord`: L1 (MinIO `ObjectExists`,
   `UpdatePaperDownloaded` by natural key) keeps storage and rows the same, but it re-publishes `papers.downloaded`
   with a **new** `event_id` (`events.NewEventEnvelope`), so the processor's L2 ledger (`processed_events`, keyed on
   `event_id`) does not dedupe it. The natural-key upserts in `services/common/db.py` `save_sections_and_chunks` and
   the embedder's L3 model join keep rows the same. Confirm this chain, or name the gap and request a follow-up task. Don't change other services here.
4. **`BlockRebalanceOnPoll` without `AllowRebalance`.** `NewConsumer` sets `kgo.BlockRebalanceOnPoll()` (line 30), and
   nothing in the repo calls `AllowRebalance()`. Check franz-go v1.16.1 docs: if this blocks group rebalances
   indefinitely, fix it in this task (call it after each poll's records are done), or remove the option and say why.
5. **Cancellation.** If ctx is cancelled during a backoff or while the handler runs, the record is neither committed nor sent to the DLQ (shutdown is not a processing failure).
6. Test plan: one test per AC below, using fakes only (no broker).

## Acceptance criteria
- [ ] AC1: Success path unchanged. If the handler succeeds on attempt 1, or after 1–2 failures, the record is committed
  exactly once and `PublishDLQ` is not called. (Unit test, fake client and fake publisher.)
- [ ] AC2: DLQ path. If the handler fails `maxRetries` (3) times, `PublishDLQ` is called exactly once for
  `<topic>.dlq` with `OriginalTopic`, `Partition`, `Offset`, `Attempts = 3`, `ConsumerGroup` and `Traceparent` from the
  record. **Only after it returns nil** is the record committed. (Unit test asserts call order: publish, then commit.)
- [ ] AC3: **DLQ publish fails → no commit.** If `PublishDLQ` returns an error, the failed record's offset is not
  committed, and no later offset of the same partition is committed while it is unresolved. The test feeds
  `[p0@5 fails, p0@6 ok]`, makes the DLQ publish always fail, and cancels ctx after a few rounds. It asserts that no commit for partition 0
  reaches offset ≥ 5, the DLQ write for @5 is retried in place (`PublishDLQ` called ≥ 2× for @5), the handler for @5 is called exactly 3×,
  the handler is never called for @6, and `Start` returns nil when ctx ends. Records before @5 in the same poll are still committed.
  (Amended 2026-11-03 by pm-lead to match the approved mechanism: retry the DLQ write in place, design §1.)
- [ ] AC4: Recovery. The fake publisher fails twice and then succeeds. The record ends with exactly one DLQ message and
  one commit, and there is a context-aware wait between rounds (no busy loop: the test asserts the number of handler calls is bounded).
- [ ] AC5: `producer == nil` no longer means "commit without DLQ". Either the constructor rejects it, or the loop treats it as a failed DLQ publish (AC3). Tested.
- [ ] AC6: **ctx cancelled during backoff → returns promptly.** With a backoff of ≥ 5 s injected and ctx cancelled
  during the first wait, `Start` returns within 200 ms. The record is neither committed nor sent to the DLQ. There is no
  `time.Sleep` left in the retry path (`grep -n "time.Sleep" internal/kafka/consumer.go` is empty).
  **AC6b** (added 2026-11-03 at PM final review round 1; the approved design §3 case 2 and its test plan already promised it): if ctx is
  cancelled while the handler runs on its **last** attempt and the handler then returns an error, there is no `PublishDLQ` call and no commit,
  and `Start` returns nil. Named test, plus mutation (e) "drop the `ctx.Err()` check after a failed attempt" red in CI.
- [ ] AC7: The retry tests exercise the real loop. `TestRetrySleepSchedule` currently mirrors the loop. Replace it with a
  test that drives `Start` (or the extracted per-record function) through the injected wait function and asserts the waits
  `[200ms, 400ms]` for `maxRetries = 3`. `TestRetryBackoff` stays.
- [ ] AC8: Design item 4 is resolved: there's a test that `AllowRebalance` is called after each poll's records are
  done, or the option is removed with the franz-go doc reference given in the design.
- [ ] AC9: Logs on a failed DLQ publish include topic, partition, offset and the error, but never the record value.
- [ ] AC10: Mutation check (QA). (a) Re-adding the unconditional `CommitRecords` after a failed `PublishDLQ`, and (b) reverting to `time.Sleep`,
  each make at least one named test fail in CI. Method: design "PM decision" Q3. The developer pushes each mutation as its own commit and then a revert,
  waits for each CI run to finish, and lists the SHAs and run URLs in Notes. QA checks each diff and red run, and checks that the final head is green.
- [ ] AC11: `make test-full` M4 (`tests/test_m4_chaos.py`) passes against the full stack. If OPS-H1 hasn't merged: "not run: no stack" plus the exact command.
- [ ] AC12: A poll that returns partition-level errors still handles the records it returned for other partitions. Each error is
  logged with topic and partition. `kgo.ErrClientClosed` makes `Start` return that error (no spin). Test: `TestConsumerPollErrorStillProcessesRecords`.
  (Added 2026-11-03 by pm-lead from design §6. If the PR would go over 400 changed lines, this AC moves to a follow-up task.)
- [ ] Docs: app README/CONTRIBUTING lines in Scope updated if the wording changed. The Notes give pm-lead the §8.1/§8.2 text.

## Verification
```bash
make test-unit
make lint
go test -race -count=1 -run 'Consumer|Retry|DLQ|CtxWait' -v ./internal/kafka/   # in CI: step "Kafka consumer tests (verbose, race, coverage)"
go test -coverprofile=c.out ./internal/kafka/ && go tool cover -func=c.out | grep consumer.go   # paste the consumer.go rows
grep -n "time.Sleep" internal/kafka/consumer.go    # expect no output
make stack-up && make test-full                     # AC11, once OPS-H1 is merged
```
CI is the source of truth for Go: local sandboxes have Go 1.24.7, so a stdlib-only scratch run is OK only as extra evidence.

## Notes
- 2026-11-03 (pm-lead): specced from the external review of `bb9ee90` (approved by Mahesh). Verified in code: `consumer.go:129-139` commits after a failed DLQ write, `:102` uses `time.Sleep`, `:30` sets `BlockRebalanceOnPoll` and nothing calls `AllowRebalance`. The Python consumer has the same flaw: `publish_dlq` calls `flush(timeout=5)` and ignores undelivered messages, then `commit` runs regardless (`kafka_client.py:189-199`). That's OPS-H8 (Backlog); fix it after this design so both sides share the same semantics.
- This also closes the OPS-H3 backlog item "make the retry sleep injectable".
- Technical PRD §8.1 L4 ("all consumers") is not true today for Go or Python. pm-lead adds a caveat in the next docs PR and removes it when OPS-H6 + OPS-H8 merge.
- 2026-11-03 14:00 cycle (pm-lead): started in parallel with OPS-H1 (same owner, independent files). Line refs re-checked against `9c1229a`: `consumer.go:30/102/130-131/137` and `main.go:153` are current; Python `kafka_client.py` retry sleep is `:184`, commit `:199`. **While OPS-H1's PR is open, don't edit `README.md` or `CONTRIBUTING.md`** (OPS-H1 edits other lines of both). Put the proposed README:39 / CONTRIBUTING:57 wording in Notes; if OPS-H1 has merged by the time this PR is built, rebase and make the edit in this PR. AC11 stays "not run: no stack" unless OPS-H1 has merged; then run it via OPS-H1's `stack.yml` (`workflow_dispatch` on this branch).
- 2026-11-03 (pm-lead, design gate): design **APPROVED** with conditions C1–C7. AC3 was amended to the retry-in-place mechanism, AC10 now states the
  mutation-commit method, and AC12 was added (the poll-error drop fix). Follow-up for after OPS-H1 merges: change `Makefile` `test-go` to `go test -race -count=1 ./...`
  (backend, small). It isn't done here because OPS-H1 edits `Makefile` in parallel. G1/G2 were filed in the board Backlog.
- 2026-11-03 (backend-engineer, build): **draft PR [#15](https://github.com/MaheshPulivarthi18/ArxivLens/pull/15)**, branch `agent/backend/OPS-H6`, final head
  `7814563cb81cbbf5b21d0f40b43a095f39bf90e8`, CI green: [run 41655887813](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/41655887813) (Go, Python, Frontend, ownership).
  - Files: `internal/kafka/consumer.go`, `internal/kafka/consumer_test.go`, `.github/workflows/ci.yml` (one step `Kafka consumer tests (verbose, race, coverage)`).
    No `Makefile`, `README.md`, `CONTRIBUTING.md` or `cmd/` (C1). `ownership-check.sh origin/main agent/backend/OPS-H6` → `Ownership OK for role=backend (392 changed lines)`.
  - Shape differs from design §7: the per-record logic stays inline in `Start` with `break records`, so the diff fits under 400 without cutting AC tests. Recorded in design §7a. Semantics are unchanged.
    AC12 fit in the line budget, so it's included.
  - CI step output on the final head: 14 tests pass with `-race`. Coverage: `Start` 97.9%, `ctxWait` 100%, `dlqRetryBackoff` 100%, `retryBackoff` 100%,
    `NewConsumer` 28.6% (only the nil-producer branch is unit-testable without a broker), `Close` 0%.
  - AC → test: AC1 `TestConsumerSuccessPath` · AC2 `TestConsumerDLQThenCommit` · AC3 `TestConsumerDLQFailureBlocksPartition` · AC4 `TestConsumerDLQRecovers` ·
    AC5 `TestNewConsumerRejectsNilProducer`, `TestConsumerNilDLQIsFailedPublish` · AC6 `TestConsumerCancelDuringBackoffReturnsPromptly`, `TestCtxWait` (+ `grep -n "time.Sleep" internal/kafka/consumer.go` is empty) ·
    AC7 `TestRetrySleepSchedule` (rewritten), `TestRetryBackoff` (unchanged), `TestDLQRetryBackoff` · AC8 `TestConsumerAllowRebalanceAfterEachPoll` · AC9 `TestConsumerDLQFailureLogNoValue` ·
    AC12 `TestConsumerPollErrorStillProcessesRecords`.
  - **AC10 mutations**. Pre-mutation commit `b6b9383` is green ([run 41654530650](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/41654530650)).
    - (a) `bfa7e92` `mutation(AC10a): commit after failed PublishDLQ` → red, [run 41654856105](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/41654856105)
      (Go job 125982338034, `make test-go`). Fails: `TestConsumerDLQFailureBlocksPartition` (both rows, "commits = [commit 0@5 commit 0@6], want []"), `TestConsumerDLQRecovers`, `TestConsumerNilDLQIsFailedPublish`. Reverted in `36d6ef5`.
    - (b) `1021560` `mutation(AC10b): time.Sleep instead of c.wait` → red, [run 41655446862](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/41655446862)
      (Go job 125984389787). Fails: `TestRetrySleepSchedule` ("waits = [], want [200ms 400ms]"), `TestConsumerCancelDuringBackoffReturnsPromptly` ("Start returned after 5.004s"),
      `TestConsumerSuccessPath`, `TestConsumerDLQFailureBlocksPartition`, `TestConsumerDLQRecovers`, `TestConsumerNilDLQIsFailedPublish`. Reverted in `7814563`.
    - `git diff b6b9383 7814563` is empty (whole tree, so `-- internal/kafka/` too). Each run was allowed to complete before the next push. Neither failure is a compile or vet error.
    - Superseded: a first (a) on `560ab04` ([run 41654062505](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/41654062505)) was red, but `TestConsumerDLQRecovers` panicked
      on an unguarded `f.payloads[2]` there, which stopped the rest of the package. It was reverted in `b965a64`, and `b6b9383` guards the indexes (test-only change, same line count). Both mutations were then re-run as above.
  - **C2: franz-go doc quote unverified.** proxy.golang.org (DNS), raw.githubusercontent.com (proxy 403) and the twmb/franz-go GitHub API (session not enabled) are unreachable.
    QA: check design §4's `BlockRebalanceOnPoll`/`AllowRebalance` text against the v1.16.1 source (`pkg/kgo/config.go`, `pkg/kgo/consumer_group.go`). The real-module CI build confirms that `AllowRebalance()`, `EachError`,
    `kgo.ErrClientClosed` and the exported `Fetch`/`FetchTopic`/`FetchPartition` fields exist with the shapes used.
  - **Not run:** AC11 M4, no stack (OPS-H1 not merged). Command once it is: `make stack-up && make test-full` (or OPS-H1's `stack.yml` `workflow_dispatch` on this branch).
    `make test-unit`/`make lint` were not run locally (Go 1.24.7, go.mod needs 1.25, franz-go unavailable); CI is the evidence. Extra local evidence only: vet plus `go test -race` against a minimal local stub of the `kgo` types, all 14 tests passing, and both mutations pre-checked to fail tests rather than vet.
  - Behaviour notes for QA: shutdown now also logs `Poll error (topic= partition=-1): context canceled` once (it logged `Poll error: context canceled` before). A closed client returns before `AllowRebalance`.
  - Docs (C1): README:39 and CONTRIBUTING:57 are unchanged because OPS-H1 hasn't merged. Proposed wording is in design "Docs wording".
  - **C6: proposed Technical PRD §8.1/§8.2 text** (for pm-lead's docs PR):
    ```
    poll → for each record, in order:
      attempt 1..3: handle; on error wait 200ms, 400ms (ctx-aware; ctx done → stop, no DLQ, no commit)
      success → commit record
      3 failures → build DLQPayload once → publish to <topic>.dlq
         ok → commit record
         error → log CRITICAL, wait 1s,2s,4s…30s (ctx-aware) and publish again; never commit, never move on, until it lands or ctx ends
    partition-level poll errors are logged (topic, partition); the poll's other records are still handled; a closed client stops the consumer
    after the poll's records: AllowRebalance
    On restart/rebalance, everything after the last committed offset is redelivered; L1–L3 keep row counts unchanged.
    ```
    With this, §8.1 L4 holds for the Go consumer. The Python consumer doesn't hold it until OPS-H8.
- 2026-11-03 (pm-lead, final review round 1): **CHANGES** (QA PASS at `7814563`). Rework checklist (details in `agents/reviews/OPS-H6/report.md`):
  - [x] 1. AC6b test: handler cancels ctx on its 3rd call and returns an error → 0 `PublishDLQ` calls, 0 commits, `Start` returns nil. Fake publisher must **not** check ctx (so the test fails if the branch is removed).
  - [x] 2. Mutation (e) `mutation(AC6b): drop ctx check after failed attempt` + `revert mutation(AC6b)`, same method as AC10 (wait for each CI run; list SHA + run URL here).
  - [x] 3. Design doc (this repo): fix the test plan's "a mutex in the fakes" sentence (there is none; state why `-race` is clean) and record the AC6b test in §7a.
  - Diff cap: ≤ 420 changed lines, for the added test only (design C1 amended). No other code changes this round.
  - Not changes: C2 closes as "verified by Mahesh at PR review" (design PM decision addendum); shutdown "Poll error … context canceled" log → Backlog; revert `36d6ef5` without CI accepted (tree = green `b6b9383`).
- 2026-11-03 (backend-engineer, rework round 1 done; final head **`a8a2cf5431a5725cf675deaeeb91cc6a1811a890`**, green: [run 41658732637](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/41658732637)):
  - Item 1: `aa4ed67` adds `TestConsumerCancelInsideHandlerNoDLQ` (test-only, +15 lines in `consumer_test.go`). The handler closure fails on calls 1–2, and on call 3 it cancels ctx and returns `errBoom`.
    It asserts `Start` returns nil, 3 calls, `f.payloads == nil` (0 `PublishDLQ`) and no commits. `fake.PublishDLQ` ignores ctx. CI green: [run 41657980852](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/41657980852).
    `ownership-check.sh` → `Ownership OK for role=backend (407 changed lines)` (cap 420). `git diff 7814563 a8a2cf5 -- internal/kafka/consumer.go` is empty. `Start` coverage is now 100.0% (was 97.9%).
  - Item 2: `74e3585` `mutation(AC6b): drop ctx check after failed attempt` (removes only `consumer.go:145-147`, 3 deletions) → red, [run 41658339174](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/41658339174)
    (Go job 125994581866; `go vet` passed; the only failure is `--- FAIL: TestConsumerCancelInsideHandlerNoDLQ` with `log = [poll dlq 0@5 err=<nil> commit 0@5 allow]`). The run finished before the next push.
    `a8a2cf5` `revert mutation(AC6b)` → green, [run 41658732637](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/41658732637) (run completed, success). `git diff aa4ed67 a8a2cf5` is empty.
  - Item 3: `docs/design/OPS-H6.md` now says there is no mutex, and why `-race` is clean. AC6b is in the test plan and §7a.
