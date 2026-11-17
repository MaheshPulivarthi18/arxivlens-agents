<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-17T13:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/55#issuecomment-6949754324 (the QA harness could not write report.md). -->

[qa-reviewer] **QA round 1: PASS** for OPS-H11 at `2039650`

_The QA harness refused to write `agents/reviews/OPS-H11/report.md`, so this comment is the full report. The orchestrator saves it verbatim._

# QA report: OPS-H11 · PR #55 · round 1

**Verdict:** PASS
**Reviewed commit:** `2039650814ad3724953d58496cfb52cafebfd38c` (CI ran on merge `851607b` = head into main `40dec5a`, which is still main's head) · **Date:** 2026-11-17
**Ticket:** `agents/tasks/OPS-H11.md` · **PRD:** Product OPS-3, OPS-4; Technical PRD §8 (L1–L3); `docs/design/OPS-H6.md` §5 G1
**Evidence:** [agents/reviews/OPS-H11/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence) (commit `52e57e8`)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 134069236011 | pass: `make lint-go`, `make test-go` (`ok arxivlens/internal/downloader 0.106s`, `ok arxivlens/internal/db`), `make build-go` ([07](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/07-ac5-ci-unit-lint.png?raw=true)) `` |
| Python M0 unit tests | CI job 134069236552 | pass: `182 passed, 3 skipped` + `37 passed` |
| Frontend (lint, test, build) | CI | pass (no frontend change) |
| Agent guardrails (ownership) | CI job 134069236545 | pass: `Ownership OK for role=backend (212 changed lines)` |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Full stack (compose + make test-full) | CI job 134069235738 | pass: `234 passed, 1 skipped, 3 deselected`; the new test is id 200 and is a `.` ([05](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/05-ac4-dot-map.png?raw=true)) ``` |
| Ticket verification `go test … -run TestHandleRecord -v` | local scratch module | pass. Go 1.24.7 `GOTOOLCHAIN=local`, `-race`, real `internal/downloader` (+ test), `internal/arxiv`, `shared/events` sources, real `PaperVersionStatus`/`UpdatePaperDownloaded` bodies extracted from `db.go`; stubs only for pgx/kgo/ulid/kafka/storage ([01](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/01-ac1-ac2-go-tests.png?raw=true), ```` sources in [09](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/09-harness-sources.png?raw=true)) ````` |
| `make test-unit`, `make lint` | not run locally: repo needs Go 1.25 (toolchain download blocked) | CI green (rows above) |
| `make eval` | not run: no retrieval/answering change | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: table test rows (a)–(g) | ✅ | `TestHandleRecordSkipsAlreadyEmbedded` has exactly the 7 rows the ticket lists. Each asserts DB-update, publish and PDF-request counts, plus lookup count/version, the published sha256, the skip log line and the lookup-error log. All 7 pass locally with `-race` ([01](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/01-ac1-ac2-go-tests.png?raw=true)) `````` and in CI ([07](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/07-ac5-ci-unit-lint.png?raw=true)). ``````` Control: main's pre-fix `downloader.go` with the PR's tests fails rows a–f ([03](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/03-ac3-mutation.png?raw=true)). ```````` |
| AC2: version test unchanged; lookup at the envelope's version | ✅ | The function body is byte-identical between main and the head (24 lines, `diff` empty). Only the shared fakes changed, and their zero values reproduce the old `ObjectExists=false`/`io.EOF` behaviour ([02](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/02-ac2-test-unchanged.png?raw=true)). ````````` It passes ([01](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/01-ac1-ac2-go-tests.png?raw=true)). `````````` Row (a) is a v0 envelope that asserts the lookup ran at v1, and the mutant that looks up with raw `envelope.Version` is killed by row a ([03](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/03-ac3-mutation.png?raw=true) ``````````` x5). |
| AC3: mutants (i)–(iii) each fail a row | ✅ | Independent QA run, each mutant against the full package and with `-run '^TestHandleRecordSkipsAlreadyEmbedded$'`, same result both ways. (i) drop sha comparison → rows b, c; (ii) drop `embedded` check → row d; (iii) `return lerr` → row f. Of 9 extra single-operand mutants, 8 are killed. Survivors: x2 (drop `storedSHA != ""`) is equivalent, because in that branch `sha256Hex` is always a 64-char hex. x9 (`strings.EqualFold`) only matters for uppercase stored sha, which no writer produces ([03](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/03-ac3-mutation.png?raw=true)). ```````````` Build failures would count as INVALID, never KILLED; none occurred. |
| AC4: real-stack `test_redelivered_discovered_keeps_embedded_status` green in `stack.yml` | ✅ (by dot map; see finding 1) | The job ran on merge `851607b`. The crawl reached 2 `embedded` papers with `raw/…_v1.pdf` keys and sha256, and all DLQs were empty ([04](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/04-ac4-stack-job-log.png?raw=true)). ````````````` An offline collection of the job's exact pytest args at the head gives 235 ids = 235 outcome characters. The lone `s` lands on id 85, the only `skipif`. Id 200 = the new test = `.` ([05](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/05-ac4-dot-map.png?raw=true)). `````````````` It did not take its skip path: that path `warnings.warn`s first, and the 3 UserWarnings are all `test_m0.py`. The pass is not vacuous. The control stack run on the same main (PR #54) has 233 passed against 234 here, and the arXiv replay shows `hits: 5, misses: 0` in both, so the redelivery caused no arXiv fetch ([06](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/06-ac4-replay-stats-vs-control.png?raw=true)). ``````````````` Without the guard, `UpdatePaperDownloaded` sets `status='downloaded', updated_at=now()` before the commit (`internal/kafka/consumer.go:197`, commit-after-process), so the assertions would fail. This last point is an argument from the code: QA did not run a pre-fix real stack. |
| AC5: `make test-unit` + `make lint` green in CI; diff < 250 lines | ✅ | `make lint-go`, `make test-go`, `make test-py` and Frontend are green ([07](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/07-ac5-ci-unit-lint.png?raw=true), ```````````````` [00](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/00-ci-checks.png?raw=true)). ````````````````` 212 changed lines (+209/-3), 4 files, `gofmt -l` clean ([08](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/08-ac5-diff-scope.png?raw=true)). `````````````````` |
| Docs: none required | ✅ | No command/API change. README, `db.yml` and CONTRIBUTING are untouched. |

**Scope:** 4 files, all in the backend paths and exactly the ticket's list. `cmd/` and `ingester.go` are untouched, and no tickets, reviews or docs are in the PR. No file overlap with open PRs #51–#54. No shared-contract change: no migration, envelope or route change, and `UpdatePaperDownloaded`'s SQL is unchanged. `PaperVersionStatus`'s query and args match the ticket verbatim; my scratch test of the real body covers row, `ErrNoRows` (including wrapped) → `("","",nil)`, and other error → wrapped ([01](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/52e57e8f7c36df6c1de5620c5b7ec8d2c9239c36/agents/reviews/OPS-H11/evidence/01-ac1-ac2-go-tests.png?raw=true)). ```````````````````

**Decision fidelity:** The guard is `len(pdfBytes) > 0`, which holds only when the object was read from MinIO (the L1 `exists` branch). Mutant x4 shows that moving it outside that branch is caught by row g. It skips only on `embedded` with a non-empty, equal sha. A lookup error is logged and falls through, never returned. The log line matches the ticket. A recrawl doesn't defeat the guard either, because `UpsertDiscoveredPaper`'s `ON CONFLICT` leaves `status` alone.

## PRD fit
This delivers OPS-4: a done paper's status stays `embedded` after a redelivery or DLQ replay of `papers.discovered`. For the common case it also removes the duplicate `papers.downloaded`/`papers.chunked` events (OPS-3, Technical PRD §8 L1–L3). It fails toward reprocessing in every uncertain case, and the `chunked` restart path is preserved.

## Findings
1. [spec] AC4 says "quote the test's line from the job log", but `make test-full` runs `pytest -q`, which prints no test names on a green run, and `stack.yml` was out of scope for this ticket. This is the third time (OPS-H8, ING-11b). QA substituted the dot map with a skip-marker cross-check plus a control-run comparison (05, 06). pm-lead: a backend follow-up to give `make test-full` in `stack.yml` `-rA` would let future ACs quote a named line.
2. [nit] `test_redelivered_discovered_keeps_embedded_status` doesn't check that `raw/<id>_v<N>.pdf` is in MinIO before it redelivers. On a dev stack where the object is gone, the downloader would make one rate-limited arXiv fetch and the test would then fail on `updated_at`. That fails loudly rather than giving a false pass. The hard-coded `occurred_at` is cosmetic.

No blocking findings.

## Missing tests
- None required by the ACs. Optional: an uppercase-stored-sha row (mutant x9 survives). Today the downloader alone writes `sha256`, always as lowercase hex.
- A real-Postgres test of `PaperVersionStatus` (NULL sha → `''`, no row). Today only QA's scratch test and the stack run cover it indirectly.

## Process note
The ticket's Notes include the developer's self-report. QA re-derived every claim independently (01–08) and did not rely on it.

## Hand-off
PASS → pm-lead final review. Draft state, labels and Jira were left untouched as instructed.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

# PM final review: OPS-H11 · PR #55 · head `2039650`

**Verdict:** APPROVE · **Reviewer:** pm-lead · **Date:** 2026-11-17

## What I checked
- **Ticket and PRD fit.** The diff implements the settled decision as written. The guard is in the downloader, only on the L1 MinIO branch (`len(pdfBytes) > 0`), and it skips only when the row is `embedded` and has a non-empty stored sha256 equal to the stored object's sha256. Every other case falls through to today's path, including a lookup error (logged, not returned). The `chunked` restart path is kept. `PaperVersionStatus` uses the ticket's query verbatim and returns `("","",nil)` for `ErrNoRows`. This delivers Product PRD OPS-4: a done paper stays `embedded` after a `papers.discovered` redelivery or DLQ replay. It also removes the duplicate downstream events in the common case (OPS-3, Technical PRD §8 L1–L3). For operators/ML researchers this means `arxivlens status` stays truthful and replays are cheap. It fails toward reprocessing, so nothing can be silently left half-done.
- **Scope.** 4 files, exactly the ticket's list, 212 changed lines (< 250). No `cmd/`, `ingester.go`, SQL change to `UpdatePaperDownloaded`, `stack.yml`, `db.yml`, README or CONTRIBUTING. No shared-contract change: no migration, event envelope or route. No file overlap with #51–#54. Nothing missing and nothing extra.
- **Evidence, all 10 files opened (PNG and `.txt`).**
  - 00: 6/6 check runs succeeded on `2039650`.
  - 01: AC1 rows a–g and the AC2 test pass with `-race`, plus QA's own test of the real `PaperVersionStatus` body.
  - 02: AC2's function body is identical to main, and the fake zero values keep the old behaviour.
  - 03: AC3 mutants (i) b,c, (ii) d and (iii) f are killed. The control run of main's pre-fix code against the PR tests fails rows a–f, which proves the tests detect the bug. 8 of 9 extra mutants are killed. The 2 survivors are equivalent (x2) or unreachable (x9: no writer stores uppercase hex).
  - 04: the stack job reached 3 embedded papers with `raw/…_v1.pdf` keys and sha256, all DLQs are empty, and the run ends with `234 passed, 1 skipped`.
  - 05: dot map with 235 ids = 235 outcome characters, the lone `s` on the lone `skipif`, and id 200 (the new test) = `.`.
  - 06: arXiv replay shows `hits: 5, misses: 0, upstream_fetches: 0`, the same as the control run, and +1 passed test against the control.
  - 07: `make lint-go`, `make test-go` (`ok arxivlens/internal/downloader`), `make test-py` and the ownership check are green in CI.
  - 08: diff stat, 212 lines, `gofmt -l` clean.
  - 09: the harness sources are disclosed, and the stubs are only for infra and third-party packages.
  Each PNG shows the result for its AC, not just the command.
- **AC4 is proven, not inferred.** The new test waits for `downloader-v1` to commit past the produced offset before it asserts anything. The consumer commits only after processing (`internal/kafka/consumer.go`), so a green run means the redelivered record was handled and the status and `updated_at` didn't move. The no-skip check (the `warnings.warn` skip path is absent from the warnings summary) rules out a vacuous pass.
- **Docs.** None required: no command or API change. Product PRD OPS-3 and OPS-4 stay ✅. I'll add a one-line note on OPS-4 ("redelivery of `papers.discovered` no longer regresses `embedded`, OPS-H11") in my next `docs/` PR.

## QA findings: decisions
1. **[spec] AC4's "quote the test's line from the job log".** I accept QA's dot map (05) plus the skip-path cross-check and the control comparison (06) as meeting AC4. This is now the third time this has happened (OPS-H8, ING-11b, OPS-H11). The cause is in the harness, not in this PR. Follow-up **OPS-H12** (backend, P2 harness, Ready): `stack.yml` passes `-rA` through `PYTEST_ARGS` so the job log has one `PASSED <node id>` line per test. It only touches `stack.yml`, so it avoids #53's `Makefile`/`ci.yml`. I amended the ticket's AC4 text with a dated note.
2. **[nit] No MinIO pre-check in the real-stack test.** No follow-up. If the object is missing, the test fails loudly (one arXiv fetch, then the `updated_at` assertion). It can't give a false pass, and in CI the crawl always leaves the object in place (04). I recorded this in the ticket Notes as a known dev-stack caveat.

Optional, not required: an uppercase-sha row and a real-Postgres `PaperVersionStatus` test (QA "Missing tests") are low value today and not ticketed.

## Raise
PR #55 description rewritten with the Evidence section (images pinned to `52e57e8`), CI, and the QA and PM verdicts. PR marked ready for review. Merge: Mahesh.
