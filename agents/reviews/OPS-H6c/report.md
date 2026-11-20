<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/issues/comments/7031250347 (qa-reviewer's harness could not write report.md), 2026-11-20. -->

[qa-reviewer] QA report — OPS-H6c · PR #76 · round 1

**Verdict:** PASS
**Reviewed commit:** `6b1e814` (CI merge `1cbae83` = 6b1e814 into current main `e6cffba`) · **Date:** 2026-11-20
**Ticket:** `agents/tasks/OPS-H6c.md` · **PRD:** Product PRD OPS-1 (diagnostics must not cry wolf). Follow-up from OPS-H6b QA mutant M9.

Evidence folder: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/4e337745c2f5c28aa263452881b5a3054c81c7a6/agents/reviews/OPS-H6c/evidence
(The QA harness wouldn't let me write `report.md`, so this comment is the report. The orchestrator saves it verbatim.)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136098750087 (run 44679348972) | success. `make lint-go` success. Step `Kafka consumer tests (verbose, race, coverage)` success, log line 358: `--- PASS: TestConsumerPollErrorAfterDeadline (0.02s)`. 0 `--- FAIL` lines ([02](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4e337745c2f5c28aa263452881b5a3054c81c7a6/agents/reviews/OPS-H6c/evidence/02-ci-go-kafka-step.png?raw=true)) `` |
| Python M0 / Frontend / DB / Ownership | CI | all success. Ownership log: `Ownership OK for role=backend (37 changed lines)` ([00](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4e337745c2f5c28aa263452881b5a3054c81c7a6/agents/reviews/OPS-H6c/evidence/00-ci-checks.png?raw=true)) ``` |
| Full stack (compose + make test-full) | CI job 136098751090 (run 44679349166) | success: `243 passed, 1 skipped, 3 deselected`. F1 step `3 passed`. Only Diagnostics skipped (it is `if: failure()`). All 3 `test_m4_chaos` rows PASSED ([08](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4e337745c2f5c28aa263452881b5a3054c81c7a6/agents/reviews/OPS-H6c/evidence/08-ci-full-stack.png?raw=true)) ```` |
| Ticket verification commands | local, partly | `gofmt -l internal/kafka/` empty, ownership-check OK, diff stat/numstat ([01](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4e337745c2f5c28aa263452881b5a3054c81c7a6/agents/reviews/OPS-H6c/evidence/01-scope-numstat-ownership.png?raw=true)). ````` `go vet` and `go test -race -v -run Consumer` ran in a go1.24 scratch module with the PR's real `internal/kafka` and `shared/events` sources, plus the **real** franz-go v1.16.1 and deps from tag-pinned clones ([03](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4e337745c2f5c28aa263452881b5a3054c81c7a6/agents/reviews/OPS-H6c/evidence/03-local-race-tests.png?raw=true), `````` sources [07](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4e337745c2f5c28aa263452881b5a3054c81c7a6/agents/reviews/OPS-H6c/evidence/07-harness-sources.png?raw=true)). ``````` Not run locally: `make lint-go` and repo-wide `go vet ./...` (no Go 1.25 in the sandbox), so those rest on CI. |
| `make eval` | not run | test-only change, nothing in retrieval or answering |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: log capture plus 4 checks (nil return, shutdown line, no `Poll error`, poll reached) | ✅ | The new `TestConsumerPollErrorAfterDeadline` checks all four. It passes locally under `-race`, and 50/50 under `-race -count=50` (03). The poll-reached check really fires: test-side mutant T1 (an already-expired ctx) fails with `poll(deadline) reached 0 times, want 1` ([05](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4e337745c2f5c28aa263452881b5a3054c81c7a6/agents/reviews/OPS-H6c/evidence/05-row-assertion-mutants.png?raw=true)) ```````` |
| AC2: ctx ends with `DeadlineExceeded` | ✅ | Asserted. Mutant T2 (`WithCancel` + `AfterFunc(20ms, cancel)`) fails with `ctx.Err() = context canceled, want context.DeadlineExceeded` (05) |
| AC3a: M9 killed | ✅ | `errors.Is(err, ctx.Err())` → `errors.Is(err, context.Canceled)`: the full package FAILs on `TestConsumerPollErrorAfterDeadline` only, and `-run '^…Deadline$'` FAILs too ([04](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4e337745c2f5c28aa263452881b5a3054c81c7a6/agents/reviews/OPS-H6c/evidence/04-ac3-mutants.png?raw=true)). ````````` The no-edit control passes, and build failures are counted INVALID, not KILLED |
| AC3b: guard removed | ✅ | Full package FAILs on `TestConsumerPollErrorAfterDeadline` and on `TestConsumerPollErrorAfterCancel/clean_shutdown_logs_no_poll_error` (04) |
| AC4: additions only, one file, CI lists the test, lint-go, ownership | ✅ | `37 0 internal/kafka/consumer_test.go`, 0 deleted lines, empty `consumer.go` diff (01). CI run 44679348972 `--- PASS: TestConsumerPollErrorAfterDeadline (0.02s)`, lint-go success (02). Ownership OK (00) |
| AC5: < 1 s under `-race` | ✅ | CI `(0.02s)` (02). Locally 50× `(0.02s)` (03). The deadline is `20*ms` |
| Docs: one-line comment pinning M9 | ✅ | `// OPS-H6c: pins the deadline case (M9): ...` |

Extra checks beyond the ACs:
- **Fake fidelity against the real library** ([06](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/4e337745c2f5c28aa263452881b5a3054c81c7a6/agents/reviews/OPS-H6c/evidence/06-real-kgo-deadline-probe.png?raw=true)): `````````` a real franz-go v1.16.1 client (unreachable seed broker) on a 20 ms `WithTimeout` ctx returns `partition=-1 err=context deadline exceeded`, the same shape the fake returns. Driving `Start` with that real client logs 0 `Poll error` lines on the head. With M9 it logs `Poll error (topic= partition=-1): context deadline exceeded`.
- **Other guard mutants** (04): X2 (`ctx.Err() == context.Canceled && …`) and X3 (`err == context.Canceled`) are killed by the new row. X1 (`errors.Is(err, context.DeadlineExceeded)`) passes the new row alone but is killed by the existing cancel row. Between them, the two rows pin `ctx.Err()` from both sides.

## PRD fit
OPS-1 says diagnostics must not cry wolf. This row stops a future `WithTimeout` caller, or a refactor of the guard, from bringing back a false `Poll error` on a deadline shutdown. The real-kgo probe shows that false line appears under M9 (06). No production, contract or schema change.

## Findings
None blocking.
1. [nit] T3 in 05 is informational: if `deadlinePoll` ever returned an empty fetch, the row would pass without testing anything. Today it returns `Err: ctx.Err()`, and probe 06 confirms that matches real kgo. Keep it that way if the fake is ever refactored. No action needed.

## Missing tests
- None for this scope.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

## PM decision — pm-lead, 2026-11-20 — round 1

**Verdict: APPROVE**

_Provenance: the interrupted 05:00Z cycle first posted this verdict in the PR #76 body (PR marked ready for review, label `ready-to-merge`) but never committed it here. This section records the PM final review, redone in full in cycle 08:00Z._

Reviewed: ticket `agents/tasks/OPS-H6c.md`; Product PRD OPS-1 (✅, unchanged); the PR #76 diff at `6b1e814` via REST (`internal/kafka/consumer_test.go` +37/-0, the only file); this QA report; every file in `evidence/` (00–08, `.png` and `.txt`).

- **PRD fit.** OPS-1 needs diagnostics that don't cry wolf. The new `TestConsumerPollErrorAfterDeadline` pins that a consumer whose ctx ends by **deadline** shuts down without a false `Poll error` line. Probe 06 shows the false line really appears with a real franz-go client under M9, so the test guards a real regression and not just a fake. Test-only. No PRD status column changes.
- **Scope.** Exactly as specced: one test file, additions only, `consumer.go` untouched (01). Nothing missing, nothing extra.
- **Evidence per AC.**
  - AC1: all four checks are in the row. T1 (already-expired ctx) trips the poll-reached check (05), so the row really goes through `PollFetches`.
  - AC2: `DeadlineExceeded` is asserted. T2 (cancel at 20 ms) trips it (05).
  - AC3: M9 is killed by the new test alone, and the no-guard mutant is killed by the new test plus `clean_shutdown_logs_no_poll_error`, with a passing no-edit control (04). QA's X1–X3 show the deadline row and the cancel rows together pin `ctx.Err()` from both sides.
  - AC4: `37 0`, one file (01). CI run 44679348972, log line 358 `--- PASS: TestConsumerPollErrorAfterDeadline (0.02s)`, `make lint-go` success, 0 `--- FAIL` (02). Ownership OK (00, 01).
  - AC5: `(0.02s)` under `-race` in CI (02), and 50/50 locally (03).
  - Docs: the `// OPS-H6c: pins the deadline case (M9)` comment is present.
  - CI: 6/6 checks success on `6b1e814` (00). `stack.yml` green, F1 step `3 passed` (08).
- **Every PNG shows its result** (checked against the LLM-1b lesson): 02 shows line 358 and the FAIL count, 04 shows every mutant verdict, 03 shows the 50× line.
- **PR body check.** Head is still `6b1e814`; `draft: false`; labels `ready-to-merge`, `qa-pass`. All 9 evidence URLs are pinned to `4e33774` (the QA pack commit). Files 01–07 were first added in `1867853`, but `4e33774` is a pushed descendant on `main` and holds byte-identical blobs for all 9 files (`git rev-parse 4e33774:<path>` = `HEAD:<path>`), so the links are immutable and correct. Not re-pinned. The embeds show as backtick-wrapped links without `!`; this is the known outbound filter (OPS-H8 lesson), not an authoring error.
- **QA nit 1** (the fake must keep returning `Err: ctx.Err()`): already written under "Not verified / risks" in the PR. No follow-up needed.

Next: PR #76 stays raised (ready for review, `ready-to-merge`), waiting for Mahesh.
