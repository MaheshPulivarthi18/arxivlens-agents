# OPS-H6: Go consumer commits an offset only after success or a confirmed DLQ write; context-aware retry wait

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (silent message loss in the pipeline) |
| **PRD ref** | Product PRD OPS-1, OPS-3, §5.3; Technical PRD §8.1 (L4 commit-after-process), §8.2 (retry and DLQ) |
| **Depends on** | — |
| **Jira** | KAN-28 (`labels = "task-OPS-H6"`) |
| **Design required** | **yes**: P0, and it changes the pipeline's delivery semantics (what is committed when, and what happens on redelivery) |
| **Status** | Ready (design approved 2026-11-03 with binding conditions C1–C7, see `docs/design/OPS-H6.md` PM decision) |

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
