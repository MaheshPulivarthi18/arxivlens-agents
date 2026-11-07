# OPS-H7a: `dlq list` / `inspect` read to the start-time high watermark, with partition/offset paging

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Product PRD OPS-2, §5.3; Technical PRD §5 (DLQ manager) |
| **Depends on** | OPS-H7f **merged** (same package). ArxivLens #26 (OPS-H10) **merged** (README). Sequence the README edit with RET-2 (whichever builds second rebases) |
| **Jira** | to create under the "Dev harness & infrastructure" epic (labels `task-OPS-H7a`, `agent-backend`, `arxivlens`); parent work KAN-31 |
| **Design required** | covered by `docs/design/OPS-H7.md` § Shape, Q2, Q3 + PM decision (approved 2026-11-07) |
| **Status** | Ready after OPS-H7f and #26 merge |

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
