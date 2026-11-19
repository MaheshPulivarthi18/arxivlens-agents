# OPS-H7a: `dlq list` / `inspect` read to the start-time high watermark, with partition/offset paging

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Product PRD OPS-2, §5.3; Technical PRD §5 (DLQ manager) |
| **Depends on** | OPS-H7f **merged** (`5e557bc`). OPS-H10 #26 **merged** (`54cad79`). RET-2 merged (`6cfd836`), so the README sequencing is moot. Must not run alongside another task that edits `.github/workflows/db.yml` (ING-11b, OPS-H9) |
| **Jira** | to create under the "Dev harness & infrastructure" epic (labels `task-OPS-H7a`, `agent-backend`, `arxivlens`); parent work KAN-31 |
| **Design required** | covered by `docs/design/OPS-H7.md` § Shape, Q2, Q3 + PM decision (approved 2026-11-07) |
| **Status** | In QA: size gate fired (projected ~890 lines); this branch ships the **OPS-H7a1** slice only (`kafka.go`, tests, `db.yml`, `go.mod`) @ `d420463`. OPS-H7a2 (List/CLI/fakes/README) to be specced by pm-lead after a1 merges |

## Goal
An operator can list every record in a DLQ up to the end of the topic, page by page, and see each record's `partition/offset` so they can resume.

## Scope
- Files: new `internal/dlq/kafka.go` (kgo `Reader`: `Watermarks` via `kmsg.ListOffsetsRequest`, `Read` via `ConsumePartitions`, no group, no commits),
  `internal/dlq/manager.go` (`Reader` interface, `Record`, `List`, cursor/page), `internal/dlq/manager_test.go` (new, `fakeReader`),
  new `internal/dlq/kafka_integration_test.go` (`//go:build integration`), `cmd/arxivlens/main.go` (`dlq list` / `inspect`),
  `.github/workflows/db.yml` (add an `apache/kafka` KRaft service + `go test -tags integration ./internal/dlq/`), `go.mod` (`kmsg` → direct, no new module),
  app `README.md` CLI table (`README.md:183-185`).
- Out of scope: `Replay` changes (OPS-H7b), lock (OPS-H7c). `stack.yml` stays as it is (its greps only print the output).
- **Size gate:** commit a counted skeleton first (`git diff --stat` in Notes). If it projects > 480 changed lines or > 250 non-test lines, stop and split at
  the named seam: **OPS-H7a1** = `kafka.go` + `kafka_integration_test.go` + `db.yml` + `go.mod`; **OPS-H7a2** = `List`/`inspect` + CLI + fakes + README.

## Acceptance criteria
- [ ] AC1 (OPS-H7 AC1): `TestListPagesToHighWatermark` (fakeReader delivers records in chunks of 3, so one page needs several polls). With 1 partition of 25 records and
  `--page-size 10`, there are 3 pages and the last footer says end of topic. With 3 partitions, one empty, the union of pages = every record with the right `P/O`.
  Records past the start-time `High` are not returned. `--partition` restricts the listing. A checkpoint/cursor below `Low` warns and starts at `Low`.
- [ ] AC2: `TestReadStopsAtSnapshot_Integration` on real Kafka in `db.yml`: 3 partitions (one empty), 1,500 records, `FetchMaxBytes` small enough to force ≥ 5 polls.
  Every record is returned once, and the job log prints the count and number of polls.
- [ ] AC3: Errors are not "end". A stalled partition (`ErrPartitionStalled`) and a poll error make `List` return an error, and `dlq list` exits non-zero (unit test).
- [ ] AC4: Nothing is hidden. A record that isn't a valid `DLQPayload` prints `P/O  UNDECODABLE (n bytes)`.
- [ ] AC5 (OPS-H7 AC7, list/inspect half): `--topic` and `inspect --key` work as before. `inspect` scans to the watermarks, not the first 100 (`main.go:309`), and prints `P/O`.
  `--limit` is a hidden alias of `--page-size`. `TestDLQFlags` (cobra) parses each flag to the manager. The footer prints `next page: ... --from P/O` or
  `end of topic (high watermarks at start: ...)`. `--all` prints every page.
- [ ] Docs: README CLI table lists `--partition`, `--from P/O`, `--page-size`, `--all` and the `P/O` output.

## Verification
```bash
make test-unit
make lint
go test -race -count=1 -v ./internal/dlq/
KAFKA_BROKERS=localhost:9092 go test -tags integration -count=1 -v ./internal/dlq/   # runs in db.yml on the PR
./bin/arxivlens dlq list --topic papers.downloaded.dlq --page-size 10
./bin/arxivlens dlq list --topic papers.downloaded.dlq --all
```

## Notes
- 2026-11-07 (pm-lead): part a of the OPS-H7 split (design PM decision). OPS-H7b builds on the `Reader`/`Record` types defined here.
- 2026-11-17 (pm-lead, grooming): dependencies merged. Line refs moved: `inspect` reads the first 100 at `cmd/arxivlens/main.go:322`
  (was 309; #46 added the LLM wiring to the `query` command), and the README CLI rows are still `README.md:183-185`. `kmsg` is still `// indirect`
  in `go.mod`. #45 (`393bcf3`) didn't touch `internal/dlq` or `db.yml`.
- 2026-11-19 (backend-engineer): **size gate fired; split. This branch is OPS-H7a1 only.**
  - Skeleton commit `39274c6` (stubs + doc comments for the whole ticket): `7 files changed, 84 insertions(+)`. Projection: non-test kafka.go ~200,
    manager.go ~105, main.go ~80, db.yml ~28, README ~8, go.mod 2 = **~420 (> 250)**. Tests: kafka_test ~110, kafka_integration_test ~120,
    manager_test ~170, cmd dlq_test ~70 = ~470. **Total ~890 (> 480).** Split at the named seam.
  - **OPS-H7a1 (built, `agent/backend/OPS-H7a` head `d420463`):** `git diff --stat origin/main`: db.yml +16, go.mod +1/-1, internal/dlq/kafka.go +212,
    kafka_integration_test.go +110, kafka_test.go +140 → **5 files, 479 insertions, 1 deletion (480 changed; 230 non-test)**. a1 alone first measured 598
    and was trimmed to fit with no test row dropped except the integration "from mid-partition" subtest (covered by unit rows `below from` / `fn false stops`).
  - Added `internal/dlq/kafka_test.go` (not in the Scope file list): unit tests for new Go code, no infra (role rule 5).
  - Types live in `kafka.go` (not manager.go) so a1 doesn't touch manager.go: `Watermark{Low, High}`, `Record{Partition, Offset, Timestamp, Value, Payload}`
    (`Value` added so a2 can print `UNDECODABLE (n bytes)`), `Reader`, `ErrPartitionStalled` (a wrapped sentinel; the message names topic/partition, offset,
    snapshot high and the timeout). `KafkaReader` exports `FetchMaxBytes`, `PollTimeout` (1 s), `StallTimeout` (10 s), `Polls()`, `Close()`.
  - For a2: `Watermarks` on a missing topic returns an error wrapping `kerr.UnknownTopicOrPartition` (no auto-create). `stack.yml:249,260` call `dlq list`
    for all three DLQs without `|| true`. compose's kafka-init creates them, so it's fine on the stack, but a2 must decide the CLI behaviour (error vs "0 records").
    a2 also has to assert `var _ Reader = (*KafkaReader)(nil)` when it wires `Manager`; it was cut here for size.
  - Not run locally: Go 1.25 and the module proxy are unavailable in the sandbox. Ran a scratch Go 1.24 module with the real `internal/dlq/kafka*.go` and
    `shared/events` plus hand-written `kgo`/`kmsg`/`kerr` stubs (signatures from franz-go v1.16.1 as I know them; **not** the real API): `go vet` (+ `-tags integration`)
    ok, `go test -race -count=10 ./internal/dlq/` ok, 21 single-edit mutants: 20 killed, M22 (swap low/high inside `Watermarks`) survives unit tests. It's killed only
    by the integration test (`Low > High` → `mergeWatermarks` error). The real-Kafka test runs only in `db.yml` on the PR (it has no branch-push trigger).
  - **Next: OPS-H7a2** (pm-lead to spec): `Manager.List` + cursor/page on `Reader`, `manager_test.go` with `fakeReader` (AC1, AC3), `dlq list`/`inspect` CLI +
    `TestDLQFlags` (AC4, AC5), README CLI table. AC2 is covered by this slice.
