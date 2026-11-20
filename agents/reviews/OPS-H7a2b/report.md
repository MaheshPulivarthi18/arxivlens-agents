<!-- Provenance: saved verbatim by the orchestrator from PR #93 comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/93#issuecomment-7048816136 (QA harness could not write report.md), cycle 2026-11-20T19:00Z -->

[qa-reviewer] **QA round 1: PASS.** OPS-H7a2b · PR #93 · head `0f99a63`

The harness refused to let me write `report.md`, so this comment is the full report. The orchestrator saves it verbatim to `agents/reviews/OPS-H7a2b/report.md`. Evidence pack: [agents/reviews/OPS-H7a2b/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence) (commit `f55525c`).

**Ticket:** `agents/tasks/OPS-H7a2b.md` (KAN-71) · **PRD:** Product PRD OPS-2, §5.3; Technical PRD §5 · **Design:** `docs/design/OPS-H7.md` § Shape, Q2, Q3, Build notes (a1, a2a)

## Test results
| Check | Source | Result |
|---|---|---|
| All check runs | [00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/00-ci-checks.png?raw=true) `` | 6/6 completed / success. Every job checked out the merge `26cda97` = `0f99a63` into current main `230f617` |
| Go (vet, gofmt, test, build) | CI job 136509388044 [02](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/02-ci-go-job.png?raw=true) ``` | pass. `go test ./...` with `GOFLAGS: -race`; `ok arxivlens/cmd/arxivlens` (on main this package has no test files) |
| DB real-Kafka step | CI job 136509386630 [03](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/03-ci-db-job-dlq.png?raw=true) ```` | pass, 12/12 top-level PASS incl. `TestReadStopsAtSnapshot_Integration` |
| Full stack | CI job 136509386842 [04](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/04-ci-stack-dlq-list.png?raw=true) ````` | pass. 248 passed / 1 skipped / 3 deselected; the separate "Known failure F1" step (continue-on-error, tracked) failed as expected |
| Python M0 / Frontend / ownership | CI | pass |
| `go test -race -v ./cmd/arxivlens/ ./internal/dlq/` | local go1.24.7 harness [14](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/14-harness-full-run.png?raw=true) `````` [15](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/15-harness-sources.png?raw=true) ``````` | `TestDLQFlags` 18/18 PASS, dlq unit PASS, `go vet` clean, `gofmt -l` empty |
| `make test-unit`, `make lint`, binary vs Kafka | not run locally | No Go 1.25, no module proxy, no Docker. CI is the source |
| `make eval` | not run | No retrieval/answering change |

Harness: a go1.24 module whose dependencies are all **tag-pinned clones of the real libraries** (cobra v1.8.0, pflag v1.0.5, franz-go v1.16.1, kmsg v1.7.0, compress, lz4, x/crypto, x/sys, x/text, ulid). Only the unused x/net, x/term, md2man and yaml are empty-`go.mod` stubs. It holds the PR's real `internal/dlq`, `internal/kafka` and `shared/events`, the real DLQ section of `main.go` (byte-identical, checked in 15) and the real `dlq_test.go` (`cmp` identical). QA wrote only a 20-line header. The rest of `main.go` is not compiled locally; CI covers it.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 stderr warnings | ✅ | `main.go:376-377`. Row `expired offsets warn on stderr only` checks both streams. M01/M02 KILLED [05](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/05-ac1-stderr-warnings.png?raw=true) ```````` |
| AC3 errors are not "end" | ✅ | `main.go:383-384`. Rows stall / poll error / inspect stall assert err + stderr and no footer. M03, M20, M27 KILLED [06](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/06-ac3-errors-not-end.png?raw=true) ````````` |
| AC4 UNDECODABLE | ✅ | `printDLQRecord`. List row `(7 bytes)`, inspect-without-key row `(4 bytes)`. M08, M09 KILLED [07](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/07-ac4-undecodable.png?raw=true) `````````` |
| AC5 paging/flags/footers | ✅ | Default 50, `--page-size`, `--limit` alias, `--partition`, `--from`, bad `--from`, `--all` on one snapshot (late-append fake, `wmCalls 1`), inspect pages of 500 / first match / one snapshot, exact footers. 15 of the 16 aimed mutants KILLED. M25 is equivalent [08](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/08-ac5-paging-flags-footers.png?raw=true) ``````````` |
| AC6 missing topic | ✅ | Exact message for list and inspect via a wrapped `kerr.UnknownTopicOrPartition` [09](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/09-ac6-missing-topic.png?raw=true) ```````````` |
| AC7 reader wiring/Close | ✅ | `NewKafkaReader` factory, `defer r.Close()`, `NewManager(nil, r)`; replay alone keeps `nil`. `closed==1` on success and error rows, 0 on factory error. M19, M26 KILLED [10](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/10-ac7-reader-close.png?raw=true) ````````````` |
| AC8 CI + 3 `dlq list` lines | ✅ | Each of `papers.{discovered,downloaded,chunked}.dlq` prints `end of topic (high watermarks at start: 0=0 1=0 … 11=0; 0 records)`. The step has 0 × `\|\| true` [04](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/04-ci-stack-dlq-list.png?raw=true) `````````````` |
| AC9 unit/lint/race | ✅ (CI) | Go job `make lint-go` + `make test-go` (race); Python M0 + Frontend green [02](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/02-ci-go-job.png?raw=true) ``````````````` [14](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/14-harness-full-run.png?raw=true) ```````````````` |
| Docs README | ✅ | Flags, `P/O`, both footers, stderr warning [11](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/11-docs-readme.png?raw=true) ````````````````` |

**Scope** [01](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/01-scope-diffstat.png?raw=true): `````````````````` 3 backend-owned files, 395 changed lines (< 400), skeleton commit first, nothing from Out of scope touched, PR body matches the ticket. **Design:** the code follows OPS-H7 § Shape and Build notes (a2a) on snapshot reuse, the stderr rule and `NewManager(nil, r)`. I found no unexplained deviation.

## PRD fit
This delivers OPS-2's operator half. `list` pages to the start-time end with a resumable `P/O` cursor. `inspect` is no longer capped at 100 records. Stalls, poll errors and missing topics fail loudly instead of passing as "end". Undecodable records stay visible. OPS-2 stays ◐ until OPS-H7c.

## Findings
1. [spec] **The `next page:` footer drops `--partition` and `--page-size`** [13](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/13-probe-footer-partition.png?raw=true). ``````````````````` After `dlq list --partition 0 --page-size 2`, the printed `… --from 0/2` reads `0:2-3 1:0-3`: it leaves partition 0 and switches to page size 50. AC5 mandates this exact footer, and the developer flagged it. pm-lead should decide on a follow-up (spec + design Q3). It does not block.
2. [nit] Missing test: `inspect --key` with an undecodable record present. M21 SURVIVED; it would print every UNDECODABLE line during a key search. Current behaviour is correct (probe 13).
3. [nit] `inspect` without `--key` on an empty topic prints nothing (exit 0); before this PR it printed `No DLQ events found for key: `. M22 SURVIVED. Pin the chosen output.
4. [nit] Errors print twice in the real binary: cobra's `Error: …` (no `SilenceErrors`; cobra v1.8.0 `command.go:1126-1127`) and then `main.go:47-49`. This is from reading the code; I did not run the binary. It predates the PR and affects every subcommand.
5. [nit] (info) CI's real-Kafka CLI run only covers the empty-topic case. Non-empty paging, `--all` and `inspect --key` against a broker are evidenced by the fake and `internal/dlq` integration tests only. A later OPS-H7 slice should paste a non-empty `dlq list --all`.
6. Equivalent / cosmetic survivors: M25 (default `0`; `List` maps it to 50, so only `--help` changes) and M30 (usage text on stderr).

## Missing tests
- `inspect --key` over a topic containing an undecodable record.
- `inspect` (no key) on an empty topic.
- CLI-level `--from 1/0 --partition 0` mismatch and `--partition 9` non-zero exits (covered in `internal/dlq` only; low priority).

## Mutation summary
29 single-edit mutants on the full `TestDLQFlags` (fresh copy each; a build failure counts as INVALID): 25 KILLED, 4 SURVIVED (M21, M22, M25, M30), 0 INVALID [12](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f55525c0acf4a08cf5b14afa0a319860e56471fe/agents/reviews/OPS-H7a2b/evidence/12-mutation-summary.png?raw=true). ```````````````````` Coverage of the new code: `withDLQManager`, `printDLQRecord` and `watermarkList` 100%. The only count-0 blocks are the production factory and the unchanged `replay`.

## Not executed
`make` targets, the whole `cmd/arxivlens` package, and the binary against Kafka (sandbox limits; CI logs used). Jira KAN-71: this session has no Atlassian connector, so the orchestrator handles it.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM final review (pm-lead), 2026-11-21: **APPROVE**

Reviewed PR #93 @ `0f99a63` (draft, label `qa-pass`). Files from `gh api …/pulls/93/files`: `README.md` +8/-1, `cmd/arxivlens/dlq_test.go` +198, `cmd/arxivlens/main.go` +142/-46.
Read the ticket, Product PRD OPS-2 (row ◐), design OPS-H7 § Q3 + PM decision, and the PR's `main.go` DLQ section at the head. CI check runs for the head
were re-read through REST: all 6 `success` (Frontend, Go, Python M0, Agent ownership, Full stack, DB).

**Evidence (opened all 16 PNG + 16 TXT in `evidence/`, pinned at `f55525c`).**
| AC | Files | Proves it? |
|---|---|---|
| AC1 stderr warnings | 05 | yes. The test row checks both streams, and the M01/M02 mutants are killed |
| AC3 errors ≠ end | 06 | yes. Stall, poll error and inspect stall all return an error with no footer (M03/M20/M27 killed) |
| AC4 UNDECODABLE | 07 | yes for both required cases (list, inspect without `--key`). M21 survives on `inspect --key`, which this AC doesn't cover → follow-up |
| AC5 paging/flags/footers | 08, 13 | yes. Default 50 (kills a2a's M19), alias, partition, from, `--all` and inspect on one snapshot (`wmCalls 1`), pages of 500, exact footers |
| AC6 missing topic | 09 | yes, exact message for list and inspect |
| AC7 reader wiring/Close | 10 | yes. `closed==1` on success and error paths, `NewManager(nil, r)`; only `replay` keeps a nil reader |
| AC8 CI + 3 lines | 00, 03, 04 | yes. Three `end of topic (…; 0 records)` lines from the Full stack job log, and 0 `|| true` |
| AC9 unit/lint/race | 02, 14, 15 | yes (CI Go job runs `-race`). The local harness is byte-identical to the PR (15) and backs it up |
| Docs | 11 | yes. Flags, `P/O`, both footers, stderr, non-zero exits |
| Scope / size | 01 | 3 files, 395 changed lines, skeleton commit first, nothing out of scope |

No AC is left "unverified". The binary was not run locally, which is a sandbox limit. CI's Full stack job ran the built binary for AC8.

**Product fit.** This delivers OPS-2's operator half (persona: the operator draining a DLQ). `list` reaches the start-time end with a cursor the operator can paste.
`inspect` is no longer capped at 100 records. Failures exit loudly instead of looking like an empty topic. Undecodable records stay visible. OPS-2 stays ◐
until OPS-H7c (design condition 7), so this PR needs no PRD status change.

**QA findings, decided.**
1. `[spec]` footer drops `--partition`/`--page-size`: **accepted as specced, follow-up.** This was my spec. AC5 and design Q3 fixed the text, the developer
   flagged it, and adding the flags here would push the PR past the 400-line gate. Following the footer never hides records: it lists more, not fewer.
   Fixed in **OPS-H7a2c** (new task, Ready after #93 merges). Design Q3 is amended.
2. Nit, `inspect --key` with an undecodable record is untested (M21): → OPS-H7a2c AC2.
3. Nit, `inspect` without `--key` on an empty topic prints nothing (M22): → OPS-H7a2c AC3 pins `No DLQ events in topic: <T>`.
4. Nit, errors are printed twice (cobra + `main()`; this predates the PR): → OPS-H7a2c AC4 (`SilenceErrors` on the root command).
5. Info, CI's broker run only covers empty DLQs: already covered by OPS-H7c AC3's stack step. Noted on OPS-H7c.
6. M25/M30 are equivalent or cosmetic. Accepted.

**Action.** PR #93 description rewritten with the Evidence section, marked ready for review, label `ready-to-merge`. Board → Ready to merge.
