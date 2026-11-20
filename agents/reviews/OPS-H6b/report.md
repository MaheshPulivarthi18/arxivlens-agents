<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/72#issuecomment-7029276827 (the QA harness could not write report.md). -->

[qa-reviewer] **QA report — OPS-H6b · PR #72 · round 1**

**Verdict: PASS.** All 5 ACs have evidence, the 6/6 CI checks are green, the AC4 mutants (a), (b) and (c) are all killed, and there are no blocking findings.
**Reviewed commit:** `0fbf4e0d70466e9529a51b0ca7c6580cc4883b81` (CI ran on merge `2ba4fab` = 0fbf4e0 into main 4c7d327) · **Date:** 2026-11-20
**Ticket:** `agents/tasks/OPS-H6b.md` (KAN-75) · **PRD:** Product PRD OPS-1 · Evidence pinned at arxivlens-agents@67faa18

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136053158087 (run 44665348466) | pass ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/00-ci-checks.png?raw=true), `` [02](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/02-ci-go-kafka-step.png?raw=true)) ``` |
| Python M0 / Frontend / DB | CI jobs 136053157828 / 136053158091 / 136053157548 | pass |
| Agent ownership check | CI job 136053158054 | pass (`Ownership OK for role=backend (59 changed lines)`) |
| Full stack (compose + make test-full) | CI job 136053158182 | pass: 237 passed, 1 skipped (opt-in), 3 deselected (F1); all 3 `test_m4_chaos` rows PASSED ([09](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/09-ci-full-stack.png?raw=true)) ```` |
| Ticket verification | local: go1.24.7 scratch module against the **real** franz-go v1.16.1 (tag-pinned GitHub clones; module proxy blocked) | `gofmt -l` clean, ownership OK ([01](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/01-scope-numstat-ownership.png?raw=true)); ````` `go test -race -v -run Consumer` all PASS ([07](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/07-local-race-tests.png?raw=true)); `````` `go vet` not run locally (it passed in CI `make lint-go`) |
| `make eval` | not run: no retrieval or answering change | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | Row `clean_shutdown_logs_no_poll_error` uses the fake's `poll(end)` path (partition -1, `Err: ctx.Err()`). It asserts the shutdown line is present, `Poll error` is absent, and `Start` returns nil. PASS in CI ([02](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/02-ci-go-kafka-step.png?raw=true)) ``````` and locally. M1 (guard removed) fails this row ([04](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/04-ac4-mutants.png?raw=true)). ```````` With the real franz-go client, main logs `Poll error (topic= partition=-1): context canceled` and the PR head does not ([05](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/05-real-kgo-shutdown-before-after.png?raw=true)). ````````` |
| AC2 | ✅ | Row `other_error_after_cancel_is_still_logged`: ctx is cancelled inside `PollFetches`, with `errBoom` on partition 0. The row asserts `Poll error (topic=papers.discovered partition=0): boom`. PASS. M2 (`ctx.Err() != nil` alone) fails it. |
| AC3 | ✅ | numstat: consumer_test.go 54/0, consumer.go 5/0 ([01](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/01-scope-numstat-ownership.png?raw=true)). `````````` `TestConsumerPollErrorStillProcessesRecords` (both rows) and every other kafka test PASS in CI. |
| AC4 | ✅ | Run locally against real franz-go, never on the PR branch. Each mutant ran on the full package and on `-run ^TestConsumerPollErrorAfterCancel$` ([04](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/04-ac4-mutants.png?raw=true)). ``````````` (a) M1 KILLED by `clean_shutdown…`. (b) M2 KILLED by `other_error_after_cancel…` and `client_closed_after_cancel…`. (c) M3 `if ctx.Err() != nil { return }` before `closed`: KILLED by `other_error…` and by the new row `client_closed_after_cancel_still_returns_the_error`. Extra mutants M4 (&&→\|\|), M5 (negated errors.Is) and M10 (closed dropped) were KILLED. The 4 survivors M6–M9 are equivalent, shown from source ([06](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/06-survivors-equivalence.png?raw=true)): ```````````` ErrClientClosed is a distinct sentinel, EachError never passes a nil err, NewErrFetch doesn't wrap ctx.Err(), and production ctx is only `signal.NotifyContext`. No INVALID mutants. |
| AC5 | ✅ | Run 44665348466 / job 136053158087, step `Kafka consumer tests (verbose, race, coverage)`: success. The `-v` output names the new test and its 3 subtests. `Start` is 100.0% before (main run 44585775176, job 135778169056) and 100.0% after. Package coverage went from 62.9% to 63.7% ([03](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/03-ac5-coverage-before-after.png?raw=true)). ````````````` `make lint-go` and the ownership check pass. |
| Docs | ✅ | Comment above `PollFetches`/`EachError` (consumer.go:113-114) explains the skip. No command or API change. |

## Scope / design
Only `internal/kafka/consumer.go` and `internal/kafka/consumer_test.go` changed (+59/−0). Both are backend-owned and in scope. `closed` is still computed first, and only the `log.Printf` is skipped. Returns, commit order, `AllowRebalance` and the shutdown line are unchanged. No contract change.

## PRD fit
OPS-1 asks for full diagnostics that don't cry wolf. The real-client probe shows exactly the false shutdown `Poll error` line removed, while real partition errors after cancel are still logged and `ErrClientClosed` is still returned.

## Findings
No blocking findings.
1. [nit] The PR body's "PRD ref" says `Technical PRD §8.1`, but the ticket says Product PRD OPS-1. pm-lead should align it when writing the evidence into the PR.
2. [nit] The fake's shutdown fetch uses `Topic: "papers.discovered"`, while real `NewErrFetch` uses `Topic: ""`. The guard ignores the topic, and probe 05 covers the real shape.

## Missing tests
- Optional: no row uses a deadline ctx (`DeadlineExceeded`), which is why M9 survives. It's equivalent today because production only uses `signal.NotifyContext`.

## Method
Harness: a go1.24 module. `internal/kafka` and `shared/events` are copied from the PR head (`diff -r` clean). Deps are `replace`d with tag-pinned clones (franz-go v1.16.1, kmsg v1.7.0, compress v1.17.6, lz4 v4.1.19, x/crypto v0.21.0, x/sys v0.18.0, x/text v0.14.0, ulid v2.1.0). Full sources, mutate.py, probe.sh and the probe test: [08](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence/08-harness-sources.png?raw=true). `````````````` Every `.png` has a `.txt` with the full output next to it in the [evidence folder](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/67faa18894942eef6028c3885f1cce4fa2c231ef/agents/reviews/OPS-H6b/evidence).

**Hand-off:** PASS → pm-lead final review. (The harness refused to write `agents/reviews/OPS-H6b/report.md`. This comment is the report; the orchestrator should save it verbatim.)


---
_Generated by [Claude Code](https://claude.ai/code)_
