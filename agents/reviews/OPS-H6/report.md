> Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/15#issuecomment-6606914204 (QA harness could not write report.md).

[qa-reviewer] QA report — OPS-H6 · PR #15 · round 1

**Verdict: PASS**
**Reviewed commit:** `7814563cb81cbbf5b21d0f40b43a095f39bf90e8` · **Date:** 2026-11-03
**Ticket:** `agents/tasks/OPS-H6.md` · **PRD:** Product OPS-1, OPS-3, §5.3; Technical §8.1 (L4), §8.2 · **Design:** `docs/design/OPS-H6.md` (approved, C1–C7, §7a as-built)
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence
_Note: the QA harness refused to write `agents/reviews/OPS-H6/report.md`. This comment is the full report; the orchestrator saves it verbatim._

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI run [41655887813](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/41655887813), job 125985942673 | pass ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/00-ci-checks.png?raw=true))`` |
| Kafka consumer tests (verbose, race, coverage) | same job | all 14 tests and subtests PASS with `-race`; `Start` 97.9%, `ctxWait`/`dlqRetryBackoff`/`retryBackoff` 100% ([02](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/02-head-kafka-tests-verbose.png?raw=true))``` |
| Python M0 / Frontend / Agent ownership | CI | pass / pass / pass |
| Ticket verification commands | not run locally: sandbox Go 1.24.7, go.mod needs 1.25, toolchain and franz-go download blocked ([13](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/13-local-toolchain.png?raw=true)).```` The `time.Sleep` grep was run locally at head. | grep empty ([03](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/03-ac6-c5-no-sleep.png?raw=true))````` |
| `make test-full` M4 (AC11) | not run: no stack (OPS-H1 PR #14 not merged). Command: `make stack-up && make test-full` (or OPS-H1 `stack.yml` via workflow_dispatch on this branch) | n/a (C7 allows this) |
| `make eval` | n/a: no retrieval or answering change | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `TestConsumerSuccessPath` (4 rows): commits exactly `[0@5, 0@6]`, no DLQ, waits `[]`/`[200ms]`/`[200ms 400ms]`; commit error is logged and the loop continues. [02] |
| AC2 | ✅ | `TestConsumerDLQThenCommit`: 1 call to `papers.discovered.dlq`. Checks OriginalTopic, Partition, Offset, Attempts==3, ConsumerGroup and Traceparent from the header, and log order `poll, dlq 0@5, commit 0@5, allow`. [02] |
| AC3 | ✅ | `TestConsumerDLQFailureBlocksPartition` (`[5,6]` and `[4,5,6]`): no commit ≥ 5, `0@4` committed, ≥ 2 DLQ writes for @5, handler @5 ×3, @6 ×0, Start returns nil. [02]. Killed by mutation (a) [05]. |
| AC4 | ✅ | `TestConsumerDLQRecovers`: 1 commit after `dlq err=<nil>`, handler calls == 3, waits `[200ms 400ms 1s 2s]`, one FailedAt across 3 writes. [02] |
| AC5 | ✅ | `NewConsumer` rejects a nil `*Producer` before building a client (`consumer.go:43-45`, `TestNewConsumerRejectsNilProducer`). `dlq: nil` counts as a failed publish (`TestConsumerNilDLQIsFailedPublish`). The only caller, `main.go:153`, passes non-nil. |
| AC6 | ✅ | `TestConsumerCancelDuringBackoffReturnsPromptly` (real ctxWait, 5 s backoff): 0.02 s in CI, no commit or DLQ [02]. grep empty [03]. Mutation (b) → 5.004 s, FAIL [07]. |
| AC7 | ✅ | `TestRetrySleepSchedule` drives `Start` via the injected wait → `[200ms 400ms]`. The mirror loop was removed, `TestRetryBackoff` is unchanged, and `TestDLQRetryBackoff` was added. [02] |
| AC8 | ✅ | `consumer.go:201` `AllowRebalance()` after each poll. `TestConsumerAllowRebalanceAfterEachPoll` asserts the exact log order. The real-module CI build proves `*kgo.Client` satisfies the interface. Doc quote: Finding 1. |
| AC9 | ✅ | `TestConsumerDLQFailureLogNoValue`: the exact C4 CRITICAL line is present and the value sentinel is absent. [02], [11](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/11-c3-c4-invariants.png?raw=true)`````` |
| AC10 | ✅ | (a) `bfa7e92`: GitHub diff touches only consumer.go (+4 −7) ([04](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/04-ac10a-mutation-diff.png?raw=true)).``````` Go job 125982338034 red, vet OK, `--- FAIL: TestConsumerDLQFailureBlocksPartition` (`commits = [commit 0@5 commit 0@6], want []`), `TestConsumerDLQRecovers`, `TestConsumerNilDLQIsFailedPublish` ([05](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/05-ac10a-ci-red.png?raw=true)).```````` (b) `1021560`: only consumer.go (+2 −2) ([06](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/06-ac10b-mutation-diff.png?raw=true)).````````` Go job 125984389787 red, vet OK, `--- FAIL: TestRetrySleepSchedule` (`waits = [], want [200ms 400ms]`), `TestConsumerCancelDuringBackoffReturnsPromptly` (`Start returned after 5.004337868s`) + 4 more ([07](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/07-ac10b-ci-red.png?raw=true)).`````````` `git diff b6b9383 7814563` (tree and `-- internal/kafka/`) is empty, b6b9383 is green, head is green ([08](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/08-ac10-reverts-net-zero.png?raw=true)).``````````` |
| AC11 | ⚠ not run (allowed) | OPS-H1 #14 is open and unmerged, main = 9c1229a ([10](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/10-ac11-c7-ops-h1-state.png?raw=true)).```````````` |
| AC12 | ✅ | `EachError` logs topic and partition and the records are still handled. `ErrClientClosed` → returns. `TestConsumerPollErrorStillProcessesRecords` (2 rows). [02] |
| Docs | ✅ | README/CONTRIBUTING untouched while OPS-H1 is open [10]. Wording and the C6 §8.1/§8.2 text are in the ticket Notes. |

### Design conditions
| Cond | Result |
|---|---|
| C1 | ✅ 3 files (`ci.yml` +2: the one step, exact command; `consumer.go`; `consumer_test.go`), **392** changed lines. No Makefile, README, CONTRIBUTING, cmd/ or tests/ ([01](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/01-c1-scope-diffstat.png?raw=true),````````````` [10]). |
| C2 | ⚠ **unverified**: twmb/franz-go GitHub API isn't enabled for this session, proxy.golang.org doesn't resolve, pkg.go.dev and raw.githubusercontent.com return 403 ([09](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/09-c2-franz-go-unreachable.png?raw=true)).`````````````` Finding 1. |
| C3 | ✅ `maxRetries: 3`, `retryBackoff`, `NewConsumer` signature and every DLQPayload field are unchanged (none appear in the removed lines). The payload is built once, and FailedAt equality is asserted [11]. |
| C4 | ✅ Format matches §7 exactly (`consumer.go:189`). |
| C5 | ✅ The only waits are `c.wait` at :152 and :191. Tests assert the exact durations [03]. |
| C6 | ✅ In ticket Notes. |
| C7 | ✅ "not run: no stack" + command [10]. |
| §7a | ✅ Deviation is recorded and justified. Every exit from the record loop reaches `AllowRebalance` except the `ErrClientClosed` return, which is correct. |

## PRD fit
Technical PRD §8.1 L4 now holds for the Go consumer: a record is committed only after the handler succeeds or PublishDLQ returns nil, and the sequential loop stops later offsets from being committed cumulatively past an unresolved record. OPS-1 diagnostics are unchanged, and §5.3 no longer loses failed papers silently. arXiv politeness improves, because the handler isn't re-run while the DLQ is down. No shared contract touched.

## Findings
1. [spec] **C2 can't be verified from agent sandboxes** (developer or QA) [09]. The code doesn't depend on the exact wording: one `AllowRebalance()` per poll is the conservative fix, and the CI build proves the API exists. pm-lead should choose how to close C2 (for example, Mahesh checks the v1.16.1 godoc at review). Not blocking AC8.
2. [nit] **No test for "the handler returns an error after ctx is cancelled"** (`consumer.go:145-147`, design §3 case 2), although the design test plan says it's covered. Removing that branch would survive every current test: with ctx cancelled during the 3rd attempt, a fake publisher that ignores ctx would get a DLQ write and a commit on shutdown. Suggested test: the handler cancels ctx on its 3rd call → assert no DLQ call and no commit. (`Start` at 97.9% fits one uncovered branch. That's inferred: per-line coverage isn't in the log.) Low real-world impact.
3. [nit] Every shutdown now logs `Poll error (topic= partition=-1): context canceled`. Consider skipping the log when `ctx.Err() != nil`.
4. [nit] The design says the fakes have a mutex, and the shared `fake` has none. The only cross-goroutine call is the `CancelFunc`, and the CI `-race` run is green, so this has no effect.
5. [nit, process] Revert `36d6ef5` has no CI run (pushed together with `1021560`). Its tree equals green `b6b9383` [08], and each mutation run finished before the next push.
6. [spec] The design header still says `Status: Draft`. AC11 (M4) and the `Makefile test-go -race` follow-up stay open until OPS-H1 merges.

## Missing tests
- ctx cancelled inside the handler on its last attempt → no DLQ call, no commit (Finding 2).

## Hand-off
PASS → pm-lead final review (open items: Findings 1 and 6).

Evidence files: [00](```````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/00-ci-checks.png?raw=true)``````````````` · [01](````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/01-c1-scope-diffstat.png?raw=true)```````````````` · [02](`````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/02-head-kafka-tests-verbose.png?raw=true)````````````````` · [03](``````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/03-ac6-c5-no-sleep.png?raw=true)`````````````````` · [04](```````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/04-ac10a-mutation-diff.png?raw=true)``````````````````` · [05](````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/05-ac10a-ci-red.png?raw=true)```````````````````` · [06](`````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/06-ac10b-mutation-diff.png?raw=true)````````````````````` · [07](``````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/07-ac10b-ci-red.png?raw=true)`````````````````````` · [08](```````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/08-ac10-reverts-net-zero.png?raw=true)``````````````````````` · [09](````````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/09-c2-franz-go-unreachable.png?raw=true)```````````````````````` · [10](`````````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/10-ac11-c7-ops-h1-state.png?raw=true)````````````````````````` · [11](``````````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/11-c3-c4-invariants.png?raw=true)`````````````````````````` · [12](```````````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/12-test-functions.png?raw=true)``````````````````````````` · [13](````````````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c14499639d1cfbb103cbfbdf8bdfab2cbc29c37/agents/reviews/OPS-H6/evidence/13-local-toolchain.png?raw=true)````````````````````````````


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM final review (pm-lead) — round 1

**Verdict: CHANGES** · **Reviewed:** PR #15 at `7814563cb81cbbf5b21d0f40b43a095f39bf90e8` · QA round 1 PASS · evidence at `0c14499` · 2026-11-03

**What I checked.** I read the ticket (AC1–AC12, Docs), the approved design (PM decision C1–C7, §3, §7a, test plan) and the full `consumer.go` diff on GitHub.
I opened all 14 evidence images and their `.txt` twins. Each one proves what it claims: 00 head CI all green · 01 3 files / 392 lines · 02 14 tests
`-race` PASS + per-func coverage · 03 no `time.Sleep`, only two `c.wait` sites · 04/06 mutation diffs are single-file, mutation-only · 05/07 Go job
red on named assertion failures (not compile/vet) · 08 reverts net to zero, pre-mutation `b6b9383` green · 09 franz-go source unreachable ·
10 OPS-H1 #14 unmerged, README/CONTRIBUTING/Makefile/cmd/tests untouched · 11 C3/C4 invariants · 12 test map · 13 local toolchain gap.

**Product fit.** This delivers what the ticket is for. Technical PRD §8.1 L4 now holds for the Go consumer: a record is committed only after the handler
succeeds or `PublishDLQ` returns nil, and the in-order `break records` keeps cumulative commits from sweeping up an unresolved record. An operator
(Product PRD §5.3) no longer loses a failed paper silently. The stall is loud: CRITICAL every round, plus lag. The handler isn't re-run while the DLQ
is down (arXiv politeness, §7). Scope is right. No shared contract was touched, AC12 fit the budget, and nothing extra was added. Docs (DoD 4): README/CONTRIBUTING are correctly
untouched while OPS-H1 is open (C1). The proposed wording and the C6 §8.1/§8.2 text are in the ticket Notes for my docs PR.

**Why CHANGES and not a follow-up (Finding 2).** Ticket design question 5 says cancellation *while the handler runs* must produce no DLQ write
and no commit. The approved design answers it (§3 case 2, `consumer.go:145-147`) and lists "ctx cancel … inside the handler" under "Failure paths
covered". I approved the design on that test plan, and the claim isn't true: QA showed that deleting the branch survives every test. The real-world
impact is low (a spurious DLQ entry on shutdown, no loss), but this branch is the shutdown semantics the task exists to settle, the fix is about 15
test lines, and this is rework round 1 of 2. Shipping a P0 delivery-semantics change with a false coverage claim in its approved design would be the
wrong precedent.

### Changes requested (developer: backend-engineer)
1. **Add the AC6b test** (ticket AC6b, added at this review). The handler fails on calls 1–2. On call 3 it cancels ctx and returns an error. Assert
   0 `PublishDLQ` calls, 0 commits and `Start` returns nil. The fake publisher must **not** check ctx itself, otherwise the test passes without the branch.
   A table row in an existing test is fine. Cap: total diff ≤ 420 changed lines, for this test only (design C1 amended). No other code change in this round.
2. **Mutation (e)**, same method as AC10: push `mutation(AC6b): drop ctx check after failed attempt` (removes only the `if ctx.Err() != nil { break records }`
   at `consumer.go:145-147`), let its CI run finish red on the new test (not compile/vet), push `revert mutation(AC6b)` and let that run finish green.
   Put both SHAs and run URLs in the ticket Notes.
3. **Make the design match the code** (this repo, `docs/design/OPS-H6.md`). Replace "a mutex in the fakes" with what is true: no mutex, because the only
   cross-goroutine call is the `CancelFunc`, which is goroutine-safe, and CI `-race` is green. Add the AC6b test to the test plan / §7a.

QA round 2 checks: items 1–3, the new mutation's diff and red run, head green, diff ≤ 420, and that `consumer.go` at head equals `7814563`'s.

### Decisions on the other findings (not changes)
- **Finding 1 [spec] C2:** closes as **"verified by Mahesh at PR review"** (design PM decision addendum). The code is correct under either reading of the
  doc, and the CI build proves the API shapes. When I raise the PR, its description will carry a reviewer check item: confirm the v1.16.1 godoc of
  `kgo.BlockRebalanceOnPoll` / `(*kgo.Client).AllowRebalance` against design §4. Not blocking.
- **Finding 3 [nit] spurious shutdown "Poll error … context canceled" log:** follow-up in the board Backlog (fold into OPS-H8 or the next `consumer.go` change).
  Not in this round: it's a behaviour change that would need its own assertion and would grow the diff.
- **Finding 4 [nit] fakes have no mutex:** no code change. The design text is corrected (change 3).
- **Finding 5 [process] revert `36d6ef5` had no CI run:** accepted. Its tree is byte-identical to green `b6b9383` (evidence 08). The round-2 mutation must
  wait for each run (change 2).
- **Finding 6 [spec] design header said Draft:** fixed by pm-lead. Header now says "Approved with conditions C1–C7"; AC6b added to the ticket.
- **AC11 (M4):** "not run: no stack" stays acceptable (C7). The `Makefile test-go -race` follow-up stays open until OPS-H1 merges.

PR #15 stays **draft**. Jira: back to In Progress (orchestrator).
