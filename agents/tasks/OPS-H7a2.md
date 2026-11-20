# OPS-H7a2: `dlq list` / `inspect` page to the start-time high watermark with `P/O` cursors (Manager.List + CLI)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Product PRD OPS-2, §5.3; Technical PRD §5 (DLQ manager) |
| **Depends on** | OPS-H7a1 = ArxivLens PR #62 **merged** (provides `Reader`, `Record`, `Watermark`, `KafkaReader`, `ErrPartitionStalled` in `internal/dlq/kafka.go`). Must not run alongside OPS-H7b (same files: `manager.go`, `main.go`) |
| **Jira** | KAN-71 |
| **Design required** | covered by `docs/design/OPS-H7.md` § Shape, Q2, Q3 + PM decision (approved 2026-11-07) and its "Build notes (a1)" |
| **Status** | In QA (a2a half, ArxivLens PR #83, draft); OPS-H7a2b (CLI) needs a spec |

## Goal
An operator can list every record in a DLQ up to the end of the topic, page by page, see each record's `partition/offset` so they can resume, and
find any key with `inspect`, however deep in the topic it sits. This is the operator half of OPS-H7a. The reader half (a1) is in PR #62.

## Scope
- Files: `internal/dlq/manager.go` (`List`, `ListOptions{Partition *int32; From Cursor; PageSize int}`, `Cursor`/`Page`, `ParseCursor("P/O")`,
  `Manager` takes a `Reader`), new `internal/dlq/manager_test.go` (`fakeReader`), `internal/dlq/kafka.go` (only `var _ Reader = (*KafkaReader)(nil)`
  and the `Polls` doc comment), `internal/dlq/kafka_integration_test.go` (log wording only: "non-empty polls"), `cmd/arxivlens/main.go` (`dlq list` / `inspect`),
  new `cmd/arxivlens/dlq_test.go` (`TestDLQFlags`), app `README.md` CLI rows (`README.md:183-185`).
- Out of scope: `Replay` and `ListEvents` (stay as they are; `Replay` still calls `ListEvents`, which OPS-H7b rewrites), the lock (OPS-H7c), `db.yml`, `stack.yml`,
  and any other change to `kafka.go`'s reader logic.
- **Size gate** (the same rule as OPS-H7a): commit a counted skeleton first and put its `git diff --stat` in Notes. a1 projected this half at ~430 changed lines
  (manager ~105, main ~80, README ~8, manager_test ~170, dlq_test ~70). If it projects > 480 changed or > 250 non-test lines, split at
  **OPS-H7a2a** = `Manager.List` + cursor + `manager_test.go` (AC1, AC3 `List` half, AC6 `List` half, AC7) / **OPS-H7a2b** = CLI + `TestDLQFlags` + README (the rest).

## Acceptance criteria
- [ ] AC1 (OPS-H7 AC1): `TestListPagesToHighWatermark`. The `fakeReader` delivers records in chunks of 3, so one page needs several reads.
  With 1 partition of 25 records and page size 10, there are 3 pages and the last one reports end of topic. With 3 partitions (one empty), the union of the pages is every record, with the right `P/O`.
  Records the fake appends after `Watermarks` was taken (offset ≥ start-time `High`) are not returned. `Partition` restricts the listing. A `From` cursor below `Low`
  prints `WARNING partition P: offsets a..b expired` to stderr and starts at `Low`. `ParseCursor` rejects `3`, `3/`, `/5`, `a/b` and `-1/0`.
- [ ] AC3 (CLI half): errors are not "end". `fakeReader` returning `ErrPartitionStalled` (wrapped), or a poll error, makes `List` return an error that satisfies `errors.Is`.
  `dlq list` run through cobra with that reader exits non-zero and prints the error (unit test, no Kafka).
- [ ] AC4 (print half): nothing is hidden. A record with `Payload == nil` prints `P/O  UNDECODABLE (n bytes)`, where `n = len(Value)`, in `dlq list` and in `inspect` without `--key`. Unit test.
- [ ] AC5 (OPS-H7 AC7, list/inspect half): `--topic` and `inspect --key` behave as before. `inspect` scans the whole topic to the start-time watermarks with the same `Reader`
  (no more first-100 cap, `main.go:322`), stops at the first match when `--key` is set, and prints `P/O`. `--partition`, `--from P/O`, `--page-size` (default 50) and `--all` exist on `list`.
  `--limit` is a hidden alias of `--page-size`. `TestDLQFlags` (cobra) checks that each flag reaches `ListOptions`. The footer is `next page: arxivlens dlq list --topic T --from P/O`
  or `end of topic (high watermarks at start: 0=H0 1=H1 ...; N records)`. `--all` prints every page in one run.
- [ ] AC6 (missing topic; **PM decision, settled here**): `dlq list` / `inspect` on a topic that doesn't exist exit **non-zero** with
  `dlq: topic <T> does not exist (check --topic; compose's kafka-init creates the three DLQs)`. The error wraps `kerr.UnknownTopicOrPartition`, which `Watermarks` already returns.
  No auto-create, and no "0 records". (Reason: "errors are not end". The stack creates all three DLQs in `kafka-init`, so `stack.yml:259-260`, which runs without `|| true`, is unaffected,
  and `:249` already sits on a failure path that exits 1.) Unit test via `fakeReader`.
- [ ] AC7: compile-time `var _ Reader = (*KafkaReader)(nil)` (cut from a1 for size). `Manager.List` takes the `Reader` interface, and the CLI wires a `*KafkaReader` and `Close`s it.
- [ ] AC8: the real-Kafka step in `db.yml` and the Full-stack job stay green on the PR (`stack.yml` calls `dlq list` for all three DLQs).
- [ ] Docs: the README CLI table (`README.md:183-185`) lists `--partition`, `--from P/O`, `--page-size`, `--all`, the `P/O` output and the end-of-topic footer.

## Verification
```bash
make test-unit
make lint
go test -race -count=1 -v ./internal/dlq/ ./cmd/arxivlens/
KAFKA_BROKERS=localhost:9092 go test -tags integration -count=1 -v ./internal/dlq/   # runs in db.yml on the PR
./bin/arxivlens dlq list --topic papers.downloaded.dlq --page-size 10
./bin/arxivlens dlq list --topic papers.downloaded.dlq --all
./bin/arxivlens dlq list --topic no.such.dlq; echo "exit=$?"                        # AC6: non-zero
./bin/arxivlens dlq inspect --topic papers.downloaded.dlq --key <arxiv_id>
```

## Notes
- 2026-11-19 (pm-lead): carved out of OPS-H7a after the size gate fired (QA report `agents/reviews/OPS-H7a/report.md`, findings 2-5).
  - a1 (#62) added `internal/dlq/kafka_test.go`, which wasn't in OPS-H7a's Scope list. It is correct: the role rules require infra-free unit tests for new Go code (QA finding 3). Keep it as is.
  - Types live in `kafka.go`, not `manager.go` (design "Build notes (a1)"). `Record.Value` holds the raw bytes for `UNDECODABLE (n bytes)`.
  - `KafkaReader.Polls()` counts only polls that returned records. Fix the integration log line to say "non-empty polls" (QA finding 2).
  - Optional, not required: a unit row that pins the −2/−1 `ListOffsets` order (mutant M26). Today only the real-Kafka test catches it. Skip it if it pushes the size gate.
  - OPS-H7b depends on this ticket and on #62 being merged.
- 2026-11-20 (backend-engineer): **size gate fired → split; PR #83 is OPS-H7a2a.**
  - Skeleton `94db799` (`internal/dlq/manager.go | 75 +++++++++++++++++++++++++++++++++++++++++++++++--`, 73+/2-), committed before the bodies.
  - The first full draft measured `cmd/arxivlens/main.go | 198` and `manager.go | 80`. With README (~8) that is ~294 non-test lines (> 250), and with the tests (~250) the total projects to ~550 (> 480).
    So I split at the ticket's seam.
  - **a2a (PR #83, head `1ae23bd`, 397 changed lines):** `Manager.List`, `ListOptions`, `Cursor`/`ParseCursor`, `Page`, the AC6 missing-topic error, `var _ Reader = (*KafkaReader)(nil)`,
    the `Polls` doc, the "non-empty polls" log wording, and `manager_test.go` (`fakeReader`, chunks of 3).
    It covers AC1, the `List` halves of AC3, AC6 and AC7, and AC8 via CI. `main.go` changes only `NewManager(cfg.KafkaBrokers, nil)` ×3.
  - **Deviation:** `ListOptions` has a 4th field, `Snapshot map[int32]Watermark` (nil: `List` takes one). `--all` and `inspect` pass `Page.Watermarks` so the whole run stops at its start-time watermarks (Q2).
    Without it each page would re-snapshot. This is internal API, not a contract.
  - **a2b (needs a spec, pm-lead):** the CLI. `newDLQCmdWith(readerFactory)` wires a `*KafkaReader` + `Close`. It adds the `--partition`, `--from`, `--page-size`, hidden `--limit` and `--all` flags,
    the footers, `UNDECODABLE (n bytes)` in list/inspect, `inspect` scanning pages of 500 on one snapshot and stopping at the first match, and warnings to stderr.
    Then `TestDLQFlags` + the README rows. Covers AC3/AC6 CLI exits, AC4, AC5, the AC7 wiring and Docs.
    A draft of the main.go part (~198 changed lines, untested) was written; it was not committed anywhere, so a2b rebuilds it from this description.
  - Verified locally: `gofmt -l .` is clean. In a scratch module (stubs for `events.DLQPayload` + `kerr` only), `go vet` is clean and `go test -race` passes (4 tests, 15 subtests).
    8 hand mutants all fail the tests. `ownership-check.sh`: OK, 397 lines. Real `make test-unit`/`make lint`: CI only (Go 1.24.7 locally, no module proxy).

  - **Rework round 1 (2026-11-20T08:00Z cycle, QA FAIL on `1ae23bd`, `agents/reviews/OPS-H7a2/report.md`)**. New head `9bcd07e` (PR #83, still draft):
    - [x] F1 (blocking, untested cross-partition `Next`, mutants M01/M02): 6 new `TestListPagesToHighWatermark` rows. A page fills at a partition's end, then a
      non-empty partition with Low 0 `{0:{0,3},1:{0,3}}` or Low 5 `{0:{0,3},1:{5,2}}`, or across an empty partition `{0:{0,2},1:{9,0},2:{4,3}}` page 2. Plus
      `From == Low > 0` (no warning), `From` at a partition's High (goes on to later partitions), and `--partition` on an empty partition (one empty page, no Next).
      No code change: the head code passes every row. QA's 33-mutant harness (go1.24 scratch module, real franz-go, `diff -r` identical to the PR) now gives
      31 killed / 2 survived (was 28/5). **M01, M02 and M06 are KILLED.** The survivors are M19 (`DefaultPageSize`: a2b `TestDLQFlags`) and M28 (equivalent).
      Coverage of `List`, `listPartitions`, `nextCursor` and `ParseCursor` is 100%.
    - [x] F2 (nit, M06 false expiry when From == Low): killed by the `From at Low` and `Low 5` rows.
    - [x] F3 (blocking, deviation not in design): `docs/design/OPS-H7.md` § "Build notes (a2a, PR #83)" (commit `6ad61c6`) records `ListOptions.Snapshot`, `Page{Next, Watermarks, Warnings}`,
      `Read` on empty partitions, and the `NewManager(…, nil)` rule for a2b. **Flagged for pm-lead acknowledgement.** No shared contract changes.
    - [x] F8 (nit, subtest count): the PR body was rebuilt from the template. It now says 4 tests / 20 subtests (13 + 7) and has a rework section.
    - [ ] F4 (M19) and F6/F7 (spec): these are for OPS-H7a2b / pm-lead and were not done here. F5 (`ParseCursor` accepts `+3/5`, `03/007`) is optional and harmless, so it is left as is.
    - CI on `9bcd07e`: all 6 check runs succeeded (Go 136202883013, DB with real Kafka 136202882278, where all 13 `TestListPagesToHighWatermark` subtests PASS, Full stack
      136202882840, Python M0, Frontend, ownership). The size is now 409 changed lines: `ownership-check` passes with only the >400 warning, and the 12 extra lines are the requested test rows.
