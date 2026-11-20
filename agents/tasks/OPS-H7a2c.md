# OPS-H7a2c: `dlq list` next-page footer keeps `--partition`/`--page-size`; pin `inspect` edge cases; print CLI errors once

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (Product PRD OPS-2 is a P0 row, ◐ until OPS-H7c; this fixes the operator paging flow before OPS-2 flips back to ✅) |
| **PRD ref** | Product PRD OPS-2, §5.3; Technical PRD §5 (DLQ manager). Parent: [OPS-H7a2b](OPS-H7a2b.md) (QA r1 finding 1 `[spec]` + nits 2-4) |
| **Depends on** | **OPS-H7a2b = ArxivLens PR #93 merged** (same files). Never alongside ING-6c, OPS-H7b or OPS-H7c (all edit `cmd/arxivlens/main.go`; ING-6c also edits `README.md`). `main.go` queue: OPS-H7a2b → ING-6c → **OPS-H7a2c** → OPS-H7b → OPS-H7c |
| **Jira** | to create (orchestrator) under the OPS-2 / "Dev harness & infrastructure" epic, labels `task-OPS-H7a2c`, `agent-backend`, `arxivlens` |
| **Design required** | no. It amends `docs/design/OPS-H7.md` § Q3's footer text (amendment recorded there by pm-lead 2026-11-21). No new command, table or contract |
| **Status** | Ready after #93 merges |

## Goal
An operator who runs `arxivlens dlq list --partition 1 --page-size 10` can paste the printed `next page:` command and stay on partition 1 with 10-record pages.
Today (PR #93, exactly as OPS-H7a2b AC5 specced it) the footer drops both flags, so the pasted command moves on to the later partitions at page size 50
(QA OPS-H7a2b r1 evidence `13-probe-footer-partition`). The same PR pins two `inspect` edge cases QA found untested and stops the CLI printing every error twice.

## Scope
- `cmd/arxivlens/main.go`:
  - `dlq list` footer: append `--partition P` when the `--partition` flag was set, and `--page-size N` when `--page-size` or `--limit` was set
    (`cmd.Flags().Changed`). Don't add `--all`: the footer is only printed without `--all`.
  - `dlq inspect` without `--key` on a topic with no records prints one line, `No DLQ events in topic: <T>` (today it prints nothing; before #93 it printed
    `No DLQ events found for key: `).
  - Root command: set `SilenceErrors: true` so cobra doesn't print `Error: …` before `main()` prints it again (`main.go:47-49` on `0f99a63`). To test it,
    move the root command's construction into `newRootCmd()`; `main()` stays `cfg` load + `Execute` + the one error print.
- `cmd/arxivlens/dlq_test.go`: new `TestDLQFlags` rows (below), plus one root-level test.
- App `README.md`: the `dlq list` paragraph's footer text (added in #93) gains the optional flags.
- Out of scope: `internal/dlq/` (no `Manager.List` change), `replay` (OPS-H7b), `stack.yml` (its `dlq list` calls use no `--partition`/`--page-size`, so their output
  is unchanged), every other subcommand's behaviour beyond printing errors once.
- Size target: ~60-90 changed lines. Stop and report if > 200.

## Acceptance criteria
- [ ] AC1 — Footer. Exactly `next page: arxivlens dlq list --topic T [--partition P] [--page-size N] --from P/O`, with each optional part present **only** when
  that flag was given (`--limit N` prints as `--page-size N`). Without either flag, the text is unchanged from #93. `TestDLQFlags` rows:
  (a) `--partition 0 --page-size 2` prints `… --topic T --partition 0 --page-size 2 --from 0/2`; (b) `--limit 3` prints `… --page-size 3 --from …`;
  (c) default flags print the #93 text; (d) **round trip**: run (a), parse the footer's args, run them on the same fake, and assert the second run reads only
  partition 0 with page size 2 (fake `reads` = `0:2-3`, no partition-1 read) and ends with `end of topic (…)`.
- [ ] AC2 — `inspect --key K` on a topic where an undecodable record comes before the match prints only the match (no `UNDECODABLE` line). Test row; it must kill
  QA's mutant M21 (`ev == nil ||` → `ev != nil &&` in the key filter).
- [ ] AC3 — `inspect` (no `--key`) on an empty topic prints exactly `No DLQ events in topic: <T>` and exits 0; `inspect --key K` with no match still prints
  `No DLQ events found for key: K`. Test rows; they must kill QA's mutant M22.
- [ ] AC4 — An error is printed once. A test builds `newRootCmd()` with the fake reader factory (wire `newDLQCmdWith` through it, or inject it), runs
  `dlq list --topic no.such.dlq` with a missing-topic fake, and asserts stderr has no `Error: ` line from cobra (the one remaining print is `main()`'s).
  State in the PR body which other subcommands' error output changes (they lose cobra's duplicate line only).
- [ ] AC5 — README's `dlq list` paragraph shows the footer as in AC1 and says the optional flags are repeated only when given.
- [ ] AC6 — CI green on the PR (Go job, DB job, Full stack job; Full stack's three `dlq list` lines are unchanged). `make test-unit`, `make lint` green;
  `go test -race ./cmd/arxivlens/` green.

## Verification
```bash
cd app
make test-unit
make lint
go test -race -count=1 -v -run 'TestDLQFlags|TestRootCmd' ./cmd/arxivlens/
./bin/arxivlens dlq list --topic papers.downloaded.dlq --partition 0 --page-size 2   # footer repeats both flags (needs a non-empty DLQ)
./bin/arxivlens dlq inspect --topic papers.chunked.dlq                              # empty topic: "No DLQ events in topic: papers.chunked.dlq"
./bin/arxivlens dlq list --topic no.such.dlq; echo "exit=$?"                         # one error line, exit=1
```

## Notes
- 2026-11-21 (pm-lead): specced from the OPS-H7a2b final review (PR #93, QA r1 finding 1 `[spec]` and nits 2-4). Finding 1 was my spec: AC5 fixed the footer
  text and design Q3 showed it without the flags, so the developer correctly dropped the suffix they had first added (it also kept #93 under 400 lines).
  #93 was approved as specced because following its footer never hides records (it lists more, not fewer).
  QA nit 5 (CI only runs `dlq list` on empty DLQs) is already covered by OPS-H7c's stack step (`dlq list --all` before and after a replay on a seeded DLQ).
