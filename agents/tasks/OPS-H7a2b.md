# OPS-H7a2b: `dlq list` / `inspect` CLI on `Manager.List` (flags, `P/O` footers, stderr warnings, README)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (Product PRD OPS-2 is a P0 row, ◐ until OPS-H7c) |
| **PRD ref** | Product PRD OPS-2, §5.3; Technical PRD §5 (DLQ manager). Parent: [OPS-H7a2](OPS-H7a2.md) (split at its size gate) |
| **Depends on** | **OPS-H7a2a = ArxivLens PR #83 merged** (`Manager.List`, `ListOptions{…, Snapshot}`, `Page{Next, Watermarks, Warnings}`, `ParseCursor`, missing-topic error). #65/#69 (root `README.md`) are merged. Must not run alongside ING-6c or OPS-H7b (both edit `cmd/arxivlens/main.go`; ING-6c also edits `README.md`) |
| **Jira** | KAN-71 (the OPS-H7a2 story; a2b is its second PR) |
| **Design required** | covered by `docs/design/OPS-H7.md` § Shape, Q2, Q3 + PM decision (approved 2026-11-07), "Build notes (a1)" and "Build notes (a2a, PR #83)" |
| **Status** | Ready (OPS-H7a2a #83 merged `a0b80fe`, 2026-11-20; picked for cycle 2026-11-20T19:00Z) |

## Goal
The operator half of OPS-H7a2: `arxivlens dlq list` pages to the start-time end of the topic and prints a resumable `P/O` cursor, and `dlq inspect`
finds a key anywhere in the topic. a2a (#83) built `Manager.List`; this PR wires it into the CLI.

## Scope
- `cmd/arxivlens/main.go`: `newDLQCmdWith(readerFactory)` wiring a `*dlq.KafkaReader` (closed with `defer Close()` on every path) into `dlq list` and
  `dlq inspect`; flags on `list`: `--partition`, `--from P/O`, `--page-size` (default 50), hidden `--limit` (alias of `--page-size`), `--all`; `--topic`
  and `inspect --key` unchanged. New `cmd/arxivlens/dlq_test.go` (`TestDLQFlags`, cobra with a fake reader factory, no Kafka). App `README.md` CLI rows
  (`README.md:186-188` on `230f617`, re-checked by pm-lead 2026-11-20 19:00Z after #83 merged).
- Out of scope: `Manager.List` itself (a2a), `Replay`/`ListEvents` (OPS-H7b), the lock (OPS-H7c), `db.yml`, `stack.yml`, `kafka.go`.
- **Size gate**: commit a counted skeleton that stubs **`main.go` and `dlq_test.go`** first (QA OPS-H7a2 finding 7) and paste its `git diff --stat` in Notes.
  The uncommitted a2 draft measured `main.go | 198`; with README ~8 and `dlq_test.go` ~70 this projects ≈ 280. Stop and report if > 400 changed lines.

## Acceptance criteria
(Carried from OPS-H7a2; numbering kept so QA can map them.)
- [ ] AC1 (CLI half) — `Page.Warnings` (e.g. `WARNING partition P: offsets a..b expired`) go to **stderr**, never stdout. Test captures both streams.
- [ ] AC3 (CLI half) — errors are not "end": a fake reader returning a wrapped `ErrPartitionStalled`, or a poll error, makes `dlq list` (cobra `Execute`)
  return non-zero and print the error; stdout has no "end of topic" footer.
- [ ] AC4 — `Payload == nil` prints `P/O  UNDECODABLE (n bytes)` with `n = len(Value)`, in `dlq list` and in `inspect` without `--key`. Unit test.
- [ ] AC5 — `inspect` scans the whole topic up to the start-time watermarks with the same reader (no first-100 cap, `main.go:322` on `c37d27c`, still `:322` on `230f617`): pages of
  500 on **one** snapshot (pass `Page.Watermarks` back as `ListOptions.Snapshot`), stops at the first match when `--key` is set, prints `P/O`.
  `--all` also reuses the first page's `Watermarks` as `Snapshot` for every later page (records appended mid-run are not listed: test with a fake that
  appends after the first page). `TestDLQFlags` checks each flag reaches `ListOptions` (`--partition`, `--from` parsed by `ParseCursor`, `--page-size`,
  `--limit` alias, and **the default page size 50 when no flag is given**, which kills a2a's surviving mutant M19). Footers exactly:
  `next page: arxivlens dlq list --topic T --from P/O` or `end of topic (high watermarks at start: 0=H0 1=H1 ...; N records)`.
- [ ] AC6 (CLI half) — `dlq list` / `inspect` on a missing topic exit non-zero with
  `dlq: topic <T> does not exist (check --topic; compose's kafka-init creates the three DLQs)` (fake reader returning a wrapped `kerr.UnknownTopicOrPartition`).
- [ ] AC7 (wiring half) — the CLI builds a `*dlq.KafkaReader` and closes it on success and error paths (test: fake factory records `Close`); the CLI never
  calls `List` on a `Manager` built with a `nil` reader (QA OPS-H7a2 finding 6: that nil-panics). `Replay` keeps `NewManager(…, nil)` until OPS-H7b.
- [ ] AC8 — CI green on the PR: Go job, the DB job's real-Kafka step, and the Full stack job (`stack.yml` runs `dlq list` for all three DLQs without `|| true`).
  Paste the three `dlq list` output lines from the Full stack job log (each ends with an `end of topic (…)` footer).
- [ ] AC9 — `make test-unit`, `make lint` green; `go test -race ./cmd/arxivlens/ ./internal/dlq/` green.
- [ ] Docs — README CLI rows list `--partition`, `--from P/O`, `--page-size` (default 50), `--all`, the `P/O` column, both footers and the stderr warning.
  pm-lead's docs PR flips OPS-2 back to ✅ only after OPS-H7c.

## Verification
```bash
cd app
make test-unit
make lint
go test -race -count=1 -v ./cmd/arxivlens/ ./internal/dlq/
KAFKA_BROKERS=localhost:9092 go test -tags integration -count=1 -v ./internal/dlq/   # db.yml on the PR
./bin/arxivlens dlq list --topic papers.downloaded.dlq --page-size 10
./bin/arxivlens dlq list --topic papers.downloaded.dlq --all
./bin/arxivlens dlq list --topic no.such.dlq; echo "exit=$?"     # AC6: non-zero
./bin/arxivlens dlq inspect --topic papers.downloaded.dlq --key <arxiv_id>
```

## Notes
- 2026-11-20 13:00Z (pm-lead): specced from OPS-H7a2's Notes ("a2b (needs a spec, pm-lead)") and QA OPS-H7a2 r1 findings 4 (M19), 6 and 7 ([spec]).
  Not startable this cycle: #83 is in QA round 2 and owns the `Manager.List` API this builds on.
- Sequencing after #83 merges: OPS-H7a2b → OPS-H7b → OPS-H7c (all `main.go`/`manager.go`), with ING-6c (`main.go`, `README.md`) slotted between
  a2b and OPS-H7b if backend has a free slot. Never two of them at once.
