<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/60#issuecomment-7013259387 (QA harness could not write report.md), 2026-11-19T15:20:25Z -->

[qa-reviewer] QA report — ING-6b · PR #60 · round 1

**Verdict: PASS**
**Reviewed commit:** `ea3bf324b3a8abe6622aae509c009f911d5e4660` · **Date:** 2026-11-19
**Ticket:** `agents/tasks/ING-6b.md` (umbrella ING-6) · **PRD:** Product ING-6; Technical PRD §11 "Scheduled crawler", §8.1 (L1) · **Design:** `docs/design/ING-6.md` §3–§5 + PM conditions 4, 5, 7, 8
**Evidence pack:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence (the QA harness couldn't write `report.md`, so this comment is the report of record)

### Preconditions
- #57 (ING-6a1) and #56 (ING-6a2) are merged (`6586cc6`, `437466f`). The PR's merge base is the current `origin/main` `8b55af2` ([01-diff-scope](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/01-diff-scope.png?raw=true)). ``
- Scope: 3 backend-owned files named in the ticket. +421/−22 = 443 lines: over the 400 target, under the 480 gate (condition 8). `crawler_test.go` and `shared/` have 0 diff lines. Nothing from 6c (CLI, lock, `stack.yml`, README) is in this PR.

### Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 135653680672 | **pass**: `make lint-go`, `make test-go` (`ok arxivlens/internal/crawler`), `make build-go` ([06](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/06-ac8-ci-go-job.png?raw=true)) ``` |
| Python M0 / Frontend / Ownership / DB | CI | **pass** ([00](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/00-ci-checks.png?raw=true)) ```` |
| Full stack (`stack.yml`) | CI job 135653680484 | **pass**: `crawl --limit 2` publishes 2, `235 passed` + `3 passed`, replay `misses: 0` ([07](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/07-ac8-ci-stack-crawl.png?raw=true)) ````` |
| Ticket verification commands | local harness, Go 1.25.1 | **pass** ([03](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/03-ac1-6-9-verification.png?raw=true), `````` [04](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/04-ac6-crawler-package.png?raw=true)) ``````` |
| `make test-unit` / `make lint` | local | not run as make targets: Go module downloads are blocked in this sandbox. The harness compiles the **real** `internal/crawler`, `internal/arxiv` and `shared/events` from the head, with stubs only for `internal/db` (PaperRecord copied from the head), `internal/kafka` and `ulid` ([02](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/02-harness-source.png?raw=true)). ```````` CI is green. |
| `make eval` | — | not run: no retrieval or answering change |

CI's `go test ./...` isn't verbose, so the CI log names the package, not the individual tests. The per-test names come from the local harness run at the same commit.

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `TestRunCategoryAdvancesWatermark` has 4 rows: untruncated → W = max seen; truncated → oldest 3, then the rest, then nothing, union = candidates; first run ascending; tie group straddling the limit is emitted whole. `TestWatermarkAfter` covers k = 0..4 and an incomplete first group. Mutants M1 and M5 are killed ([03](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/03-ac1-6-9-verification.png?raw=true), ````````` [05](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/05-ac7-mutants.png?raw=true)) `````````` |
| AC2 | ✅ | `TestRunOnceTwiceEmitsNothingSecondTime`: pass 2 adds 0 upserts, 0 publishes and 0 watermark writes, and W is unchanged |
| AC3 | ✅ | `TestRunCategoryCrashAtK` has 9 rows (upsert and publish failures at k = 0..3, plus a failed write). W is never at or above an un-acked paper, nothing is skipped, there is 1 row per `(id, version)`, and duplicates come only from the failed group or the unwritten batch. M2 and M13 are killed |
| AC4 | ✅ | `TestRunStopsOnCancel`: `Run` returns nil and W = 11 (the group-complete prefix) is written once. The fake store rejects a cancelled ctx and requires a deadline, which proves `WithoutCancel` and the timeout. Subtests cover the Interval wait and `Once` returning the pass error. M3, M8, M10 and M11 are killed |
| AC5 | ✅ | `TestRunOnceCrossListed`: the cross-listed paper is acked once (3 upserts) and both W reach 14. M4 is killed |
| AC6 | ✅ | `crawler_test.go` is unmodified and the package is green ([04](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/04-ac6-crawler-package.png?raw=true)). ``````````` The `TestDiscoveredPayload` golden map equals `Crawl`'s inline map at `origin/main` ([08](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/08-ac6-payload-golden.png?raw=true)). ```````````` M12 is killed. `shared/events` has no diff |
| AC7 | ✅ | I re-ran all 5 AC7 mutants independently. Each is killed in the full run and with `-run '^T$'`. Nothing was pushed. Of 7 extra QA mutants, 6 are killed and 1 survives (finding 1) ([05](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/05-ac7-mutants.png?raw=true)) ````````````` |
| AC8 | ✅ | All 6 check runs for `ea3bf32` are `success`, and the existing `crawl` path in `stack.yml` is unchanged with 0 replay misses ([00](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/00-ci-checks.png?raw=true), `````````````` [06](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/06-ac8-ci-go-job.png?raw=true), ``````````````` [07](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/dfd1af9b639842f553873bf4a92b7711d41d4a66/agents/reviews/ING-6b/evidence/07-ac8-ci-stack-crawl.png?raw=true)) ```````````````` |
| AC9 | ✅ | `TestRunOnceWatermarkReadError`: cs.AI gets 0 feed calls, 0 upserts, 0 publishes and no write, and the error names `cat:cs.AI`. cs.LG runs normally. The AC9 mutant M6 is killed in the full run and with `-run '^TestRunOnceWatermarkReadError$'` |

### Design check
§3 (oldest-first, upsert then publish with a stop on error, group-complete W on `WithoutCancel` + 10 s, pass-local acked set filled after the ack), §4 (a read error skips the category, a write failure returns an error with W unchanged) and §5 (`NewLoop`, `Run`, `RunOnce` with joined errors, compile-time interface checks, a summary line with all fields) all match the design. Conditions 4, 5, 7 and 8 are met. One deviation: the `W' > W` guard was dropped. It is equivalent (candidates are strictly `> W`, and SQL uses `GREATEST`), but it isn't recorded in the design file yet (finding 2).

### PRD fit
This delivers the core of Product ING-6 / Technical §11: emit only new papers, advance W only past acked papers, re-emit (never skip) after a crash, failed write or SIGTERM, and emit nothing on a repeat pass. L1 and the event payload are unchanged. Real-stack AC2/AC3 evidence is deferred to ING-6c by design.

### Findings
1. [nit] Test gap: extra mutant **M9** ("mark acked before publish") survives. If the first category's publish of a cross-listed paper fails, the second category would skip that paper and advance its W past an un-acked paper. The first category's own W still forces a re-emit, so nothing is skipped permanently, but the per-category invariant breaks. Suggested fix: add a `TestRunOnceCrossListed` row with that failure.
2. [nit] Condition 10: record the dropped `W' > W` guard in `docs/design/ING-6.md` ("Build notes (ING-6b)") before pm-lead's final review. No code change is needed.
3. [nit] Errors carry `cat:<c>` twice (`RunOnce` wraps an error that `walk` already prefixes). This is cosmetic and can be tidied in 6c.
4. [nit] The summary log line has no unit test. The ticket doesn't require one, and 6c's `stack.yml` step will grep it.
5. [spec] The ticket's Status still says "Blocked (needs #57/#56 merged)", but both are merged. pm-lead should update it.

### Missing tests
- A cross-listed paper whose publish fails in the first category (finding 1).
- `RunOnce` with ctx cancelled before the second category (the `break` path) isn't asserted directly.

### Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_
