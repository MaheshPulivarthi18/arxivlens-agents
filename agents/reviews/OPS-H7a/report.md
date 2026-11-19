<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/62#issuecomment-7015390935 (QA harness refused the file write). -->

[qa-reviewer] # QA report: OPS-H7a (OPS-H7a1 slice) · PR #62 · round 1

**Verdict:** PASS (for the OPS-H7a1 slice: AC2 in full, plus the reader halves of AC3 and AC4. AC1, AC5 and Docs are deferred to OPS-H7a2.)
**Reviewed commit:** `d42046392c7d3aacba5bc2abedb256f10c7e5552` · **Date:** 2026-11-19
**Ticket:** `agents/tasks/OPS-H7a.md` (KAN-70) · **PRD:** Product OPS-2 (§5.3), Technical §5 (DLQ manager) · **Design:** `docs/design/OPS-H7.md` § Shape, Q2, Q3 + PM decision
**Evidence pack:** [agents/reviews/OPS-H7a/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence) (commit `ba75819`). Each PNG has a `.txt` beside it with the full output.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 135705487891 | pass (`make lint-go` = vet + gofmt gate, `ok arxivlens/internal/dlq`) ([03](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/03-ac3-ac4-reader-unit-ci.png?raw=true)) `` |
| DB (migrate twice, HNSW + **new Kafka DLQ step**) | CI job 135705487518 | pass, 34 PASS / 0 FAIL, ran on the merge of the head into current main `8b55af2` ([02](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/02-ac2-db-job-real-kafka.png?raw=true)) ``` |
| Python M0 unit tests | CI | pass ([00](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/00-ci-checks.png?raw=true)) ```` |
| Frontend (lint, test, build) | CI | pass |
| Full stack (compose + make test-full) | CI | pass |
| Agent ownership check | CI | pass, with an advisory warning: `480 changed lines (> 400)` |
| `go vet` (+ `-tags integration`), `gofmt -l`, `go test -race -count=3 ./internal/dlq/` | local, **real franz-go v1.16.1 + kmsg v1.7.0** cloned from GitHub, go1.24 scratch module with the PR files byte-identical | pass ([04](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/04-local-real-franz-go.png?raw=true), ````` harness [06](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/06-harness-sources.png?raw=true)) `````` |
| `make test-unit` / `make lint` | not run locally: no Go 1.25 toolchain or module proxy. CI covers both | n/a |
| Integration test on real Kafka | not run locally: no Docker daemon, and archive.apache.org / Maven Central are blocked by the egress proxy. CI only | CI pass |
| `make eval` | not run: no retrieval or answering change | n/a |

## Scope and split check
- **The split is legitimate.** The ticket's gate says "> 480 changed lines or > 250 non-test lines → split at the named seam". The skeleton projection in the ticket Notes was ~890 total and ~420 non-test, so the gate fired. The PR is exactly the named **OPS-H7a1** seam: `kafka.go` + `kafka_integration_test.go` + `db.yml` + `go.mod`, plus `kafka_test.go` (see finding 3). The a2 files (`manager.go`, `cmd/arxivlens/main.go`, `README.md`) are unchanged at the head. The slice measures **480 changed / 230 non-test**, so it is at the gate, not over it ([01](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/01-scope-size-gate.png?raw=true)). ```````
- Every file is in backend-owned paths, and ownership CI is green. No ticket, review or doc files leaked into the PR. `go.mod` only moves `kmsg v1.7.0` from indirect to direct, with no new module.
- Ticket sequencing rule: no other open PR touches `.github/workflows/db.yml` (#59, #60, #61, #63 checked, [00](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/00-ci-checks.png?raw=true)). ```````` #62 is not merged and is still a draft.

## Design check (OPS-H7 § Shape, Q2)
- `Watermarks` sends one Metadata request (`AllowAutoTopicCreation=false`), then `kmsg.ListOffsetsRequest` at −2/−1 through the client, with no `kadm`. `Read` uses `ConsumePartitions` + `NewOffset().At(from)` with no group and no commits. A partition ends when its position reaches `until`, and records at or past `until` are ignored. `from >= until` (an empty partition) returns without a fetch. A stall or a poll error is returned as an error, never as "end". All of this matches the design.
- **Deviations:** the types live in `kafka.go`, not `manager.go`, and `Record` gains a `Value []byte` field that the design's Shape struct doesn't have. Both are justified (a2 needs `Value` to print `UNDECODABLE (n bytes)`) and are recorded in the ticket Notes, but not in the design file (finding 1).
- Fake fidelity: `fakePoller`'s idle path returns `Fetches{{Topic "", Partition -1, Err: ctx.Err()}}`, which is exactly what franz-go v1.16.1 `PollFetches` returns when the context is done (`NewErrFetch(ctx.Err())`, `consumer.go:526-528`) ([07](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/07-fake-vs-real-kgo.png?raw=true)). `````````

## Acceptance criteria (a1 slice)
| AC | Met? | Evidence |
|---|---|---|
| AC1 (`TestListPagesToHighWatermark`, `List`) | deferred to OPS-H7a2 | not in this PR |
| AC2: real Kafka in `db.yml`, 3 partitions (one empty), 1,500 records, ≥ 5 polls, every record once, count + polls in the job log | ✅ | DB job 135705487518 (head `d420463` merged with main `8b55af2`), `kafka_integration_test.go:99`: `read 1500 records (1 undecodable) from 3 partitions, watermarks map[0:{0 1000} 1:{0 500} 2:{0 0}], in 123 polls (FetchMaxBytes=4096); 15 records written after the snapshot were not returned` → `--- PASS (3.72s)` ([02](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/02-ac2-db-job-real-kafka.png?raw=true)). `````````` "Once" is asserted, not just counted: per-partition offsets strictly increase within `[Low, High)`, there are 1,499 distinct keys plus 1 planted undecodable record, and 15 post-snapshot records (5 of them into the empty partition) must not appear. The same test asserts `ErrPartitionStalled` on real Kafka for `until = High+1`. |
| AC3, reader half: stall and poll errors are errors, not "end" | ✅ (reader) · `List` / `dlq list` exit code → a2 | `TestReadLoop` rows `poll_error_is_an_error,_not_end` and `idle_polls_then_stall` (which also checks the message text), passing in CI ([03](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/03-ac3-ac4-reader-unit-ci.png?raw=true)) ``````````` and locally ×3 with `-race` ([04](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/04-local-real-franz-go.png?raw=true)). ```````````` Mutants M05/M06/M07/M12/M13 are killed ([05](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/05-mutants-kafka-go.png?raw=true)). ````````````` |
| AC4, reader half: nothing hidden, undecodable kept with raw bytes | ✅ (reader) · `UNDECODABLE (n bytes)` print → a2 | `TestDecodeRecord`: 9 rows (`{}`, `null`, `[1,2]`, `"text"`, garbage, empty, key-only → `Payload=nil`; error_type-only and original_topic-only → decoded), each keeping P/O, timestamp and raw `Value`. On real Kafka, the planted `not a DLQPayload` at 1/250 came back with `Payload=nil` and its raw value. Each operand of the `OriginalTopic != "" \|\| ErrorType != ""` guard was mutated separately (M14–M17), and dropping `Value` was mutated (M18). All were killed. |
| AC5 (`--topic`, `inspect`, flags, footer) | deferred to OPS-H7a2 | n/a |
| Docs (README CLI table) | deferred to OPS-H7a2 | n/a |

## Test quality
- 28 single-edit mutants of `kafka.go` against the unit tests, with real franz-go: **25 killed, 0 invalid** ([05](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ba758198ac160a43b31be1b0fd353e92f8e82c51/agents/reviews/OPS-H7a/evidence/05-mutants-kafka-go.png?raw=true)). `````````````` Every guard in `readLoop`, `decodeRecord`, `mergeWatermarks` (each conjunct), `partitionsFromMetadata` and `offsetsFromResponse` was mutated one at a time, and each mutant was killed by the row meant to pin it.
- The 3 survivors are on paths that only the integration test exercises:
  - M26 (`Watermarks` swaps −2/−1): on the integration fixture this gives Low=1000 > High=0, so `mergeWatermarks` errors and the test fails. That comes from reading the code; I couldn't run it locally.
  - M27 (`FetchMaxBytes` not applied): the ≥ 5-polls assertion is the guard. This is reasoned, not run.
  - M28 (drop the `from >= until` early return): an equivalent mutant, because `readLoop` returns nil at once.

## PRD fit
This is the honest-end-of-topic building block for OPS-2 / Technical §5. A reader stops at the start-time high watermark instead of a 2 s deadline, never hides undecodable records, and reports stalls and poll errors as errors. Operators get nothing visible until OPS-H7a2 wires `List` and the CLI, so Product PRD OPS-2 correctly stays ◐ (PM decision, condition 7).

## Findings
1. [nit] The design deviations (types in `kafka.go`; the `Record.Value` field) are recorded in the ticket Notes but not in `docs/design/OPS-H7.md`. Add a short "Build notes (a1)" line there; it's a direct-to-main notebook edit and doesn't change the code.
2. [nit] The integration log says `in 123 polls`, but `Polls()` counts only polls that returned at least one record (`kafka.go:61`). That still satisfies AC2's "≥ 5 polls", since it's the conservative count. Wording it "non-empty polls" would avoid confusion.
3. [spec] `internal/dlq/kafka_test.go` isn't in the ticket's Scope file list. It's justified by the area rule (new Go code ships with infra-free unit tests). pm-lead: list it in the ticket / OPS-H7a2 spec.
4. [spec] For the OPS-H7a2 spec, carry over: AC1; the `List` + `dlq list` non-zero-exit half of AC3; the `UNDECODABLE (n bytes)` print half of AC4; AC5; Docs; `var _ Reader = (*KafkaReader)(nil)` (cut here for size); and a decision on the missing-topic CLI behaviour (`Watermarks` wraps `kerr.UnknownTopicOrPartition`, and `stack.yml:249,260` call `dlq list` without `|| true`).
5. [spec] The slice sits exactly on the gate (480 changed lines; the gate is "> 480") and over the 400 target. The CI ownership check warns but doesn't fail. That's acceptable under the PM decision (over 400 for test lines only), but any rework that adds lines would cross the gate.

## Missing tests
- None blocking for this slice. Optional, for a2: a unit row that pins the −2/−1 `ListOffsets` timestamp order (M26) through an injectable requester, so it doesn't rely on the real-Kafka test alone.

## Hand-off
PASS → pm-lead final review for the OPS-H7a1 slice. pm-lead then specs OPS-H7a2 (finding 4).

Note: the QA harness refused to write `agents/reviews/OPS-H7a/report.md`. The evidence images are committed; this report text goes to the orchestrator to save verbatim.

---
_Generated by [Claude Code](https://claude.ai/code)_
