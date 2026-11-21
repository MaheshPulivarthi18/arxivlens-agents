# ING-6c: `arxivlens crawl-loop` command, single-instance lock, real-stack evidence and README

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Product ING-6; Technical PRD §11 "Scheduled crawler", §9 (politeness). Umbrella: [ING-6](ING-6.md) |
| **Depends on** | ING-6b **merged**; #51 and #52 **merged** (README, `db.yml`); **OPS-H9 merged** (`db.yml`; AC8 documents its pgvector pin); no open PR on `cmd/arxivlens/main.go` (OPS-H7b also edits it), `.github/workflows/stack.yml`, `.github/workflows/db.yml` or `README.md` when the build starts. Approved design `docs/design/ING-6.md`, PM conditions 3, 6, 7, 9 and answer 3 |
| **Jira** | KAN-66 (under KAN-18's epic KAN-4, `labels = "task-ING-6c"`) |
| **Design required** | no (covered by the approved ING-6 design) |
| **Status** | In QA (PR pending). Built cycle 2026-11-21T21:59Z on `agent/backend/ING-6c` (commit `dec6386`, see Notes) |

## Goal
Ship the user-facing command and prove on the real stack the PRD row: a second run with no new papers emits zero `papers.discovered` events, and a
kill + restart creates no duplicate or skipped papers. Merging this completes ING-6.

## Scope
- Files: `cmd/arxivlens/main.go` (`newCrawlLoopCmd`: `signal.NotifyContext(SIGINT, SIGTERM)`; flags `--categories` (default `cs.AI,cs.LG`),
  `--interval` (default `6h`, ≥ `1m`), `--limit-per-run` (default `100`, > 0), `--max-scan` (default `2000`, ≥ `--limit-per-run`), `--once`
  (one pass, non-zero exit if any category failed); invalid flags fail before any connection; takes the lock before the first arXiv request);
  `cmd/arxivlens/main_test.go` (flags); `internal/db/watermarks.go` (+ `TryCrawlLoopLock(ctx) (release func(), ok bool, err error)`: one global
  session-level `pg_try_advisory_lock` on a dedicated pool connection held for the process lifetime); `internal/db/watermarks_integration_test.go`
  (lock test); `.github/workflows/db.yml` (run `-tags integration ./internal/db/` for `TestAdvanceWatermarkMonotonic|TestCrawlLoopLock`);
  `.github/workflows/stack.yml` (step "ING-6: crawl-loop", design test plan AC2/AC3/SIGTERM rows); app `README.md` (incl. the
  OPS-H9 prerequisite line, AC8);
  `internal/crawler/loop.go` + `internal/crawler/loop_test.go` (AC11 only: one test row, one assertion, error-prefix tidy).
- Out of scope: compose service (ING-6d), lookback (ING-6e), `crawl --rate-limit` (ING-9b), any `Crawl` change.
- Size: design estimate ~160 + ~60 for the lock ≈ 220 changed lines.

## Acceptance criteria
- [ ] AC1 — `TestCrawlLoopFlags`: `--interval 30s`, `--limit-per-run 0`, `--max-scan` < `--limit-per-run`, and a bad `--categories` are rejected
  with a clear error before any DB/Kafka/arXiv connection; defaults are `6h`, `100`, `2000`, `cs.AI,cs.LG`.
- [ ] AC2 — Single instance (PM answer 3): `TestCrawlLoopLock` (integration, real Postgres in `db.yml`): a second acquirer gets `ok=false`;
  after `release` it gets `ok=true`. In `stack.yml`, a `--once` started while a looping instance runs exits non-zero with `another crawl-loop is
  running` and makes 0 arXiv requests (job log).
- [ ] AC3 — PRD "zero events on the second run", in the `stack.yml` job log: `papers.discovered` end offsets summed before/after;
  `crawl-loop --once --categories cs.LG --limit-per-run 2` → +2, again → **+0**, with the line
  `AC2: second run produced 0 papers.discovered events (N -> N)`, the `crawl_watermarks` row, and both `[CrawlLoop]` summary lines.
- [ ] AC4 — PRD "kill + restart, no duplicate or skipped papers", in the job log: (i) `DELETE FROM crawl_watermarks` then `--once`; (ii) `kill -KILL`
  of a looping `crawl-loop --interval 1m` ~1 s after start, then `--once`. After each: `count(*)` = `count(distinct (arxiv_id, version))` in
  `papers` and unchanged, both crawled IDs present, `W` = max `published_at` of the crawled papers. The evidence states that (ii)'s kill point is
  not controlled and that the exact points are covered by ING-6b's `TestRunCategoryCrashAtK`.
- [ ] AC5 — SIGTERM: `kill -TERM` of a looping instance → exit 0 within 5 s, log `[CrawlLoop] stopped`.
- [ ] AC6 — Politeness (PM condition 6): the "arXiv replay stats" step of the same run shows **0 misses**; the summary line includes `out_of_order=`.
- [ ] AC7 — `db.yml` runs `TestAdvanceWatermarkMonotonic` and `TestCrawlLoopLock` green against Postgres.
  *Amended 2026-11-17 (pm-lead, ING-6a1 QA r1 finding 4 [spec]):* the `db.yml` integration step runs, next to the existing `./internal/query/` lines
  (`db.yml` lines 70–71 on main), exactly `go vet -tags integration ./internal/db/` and
  `go test -tags integration -count=1 -v -run '^(TestAdvanceWatermarkMonotonic|TestCrawlLoopLock)$' ./internal/db/`. Evidence is the job log lines
  `--- PASS: TestAdvanceWatermarkMonotonic` and `--- PASS: TestCrawlLoopLock` (`-v` prints them; no `SKIP`, so `DATABASE_URL` is set). Until this
  lands, no CI job compiles `watermarks_integration_test.go`.
- [ ] AC10 — Watermark store test gaps from ING-6a1 QA r1 (findings 1–3), in `internal/db/watermarks_integration_test.go` (already in Scope), run by AC7:
  (a) teardown: `defer d.Close()` replaced by `t.Cleanup(d.Close)` registered **before** the `DELETE` cleanup (cleanups run LIFO), so the test row is
  removed; the same order in `TestCrawlLoopLock`. Evidence: a `SELECT count(*) FROM crawl_watermarks WHERE category LIKE 'it-test.%'` after the
  test in the `db.yml` log prints `0`. (b) `Watermark` with a cancelled context returns `err != nil` and `ok == false` (the design rule "a read error is
  never treated as no watermark"; kills QA mutant M6 "any read error → (zero, false, nil)"). (c) `AdvanceWatermark` with a cancelled context returns
  `err != nil` (kills M8 "Exec error swallowed"). (d) optional: `updated_at` moves forward on a conflicting advance (M7). Mutants M6 and M8 run
  locally (never pushed), each killed with `-run '^TestAdvanceWatermarkMonotonic$'` (or the named new test), output in the PR.
- [ ] AC8 — README (PM condition 9): CLI reference row for `crawl-loop`; a "Scheduled crawl" paragraph covering the first-run horizon (newest
  `--limit-per-run` only; older via `arxivlens crawl`), one instance (enforced by the lock), `backlog=` / `out_of_order=`, how to raise
  `--limit-per-run`, resetting a category, and the late-announcement residual risk (ING-6e). PRD status is pm-lead's docs PR after merge.
  *Added 2026-11-19 (pm-lead, moved from OPS-H9):* README "Prerequisites" says PostgreSQL 16 + **pgvector ≥ 0.8.0** (needed by
  `hnsw.iterative_scan`), matching the tag OPS-H9 pinned in `docker-compose.yml`. If OPS-H9 isn't merged when this starts, this task waits (shared `db.yml`).
- [ ] AC9 — `make test-unit` and `make lint` green in CI; `stack.yml` and `db.yml` green.
- [ ] AC11 — *Added 2026-11-19 (pm-lead, ING-6b final review; QA r1 findings 1 and 3 + missing test).* In `internal/crawler/loop_test.go`:
  (a) a `TestRunOnceCrossListed` row where the **first** category's publish of the cross-listed paper fails. Assert that the second category
  doesn't treat it as acked: it publishes it (or stops before it), and its W stays below that paper's `published`. QA mutant M9 ("mark acked before
  publish", i.e. move `acked[key] = true` above `Publish`) is run locally, never pushed, and is killed in the full run and with
  `-run '^TestRunOnceCrossListed$'`. (b) `RunOnce` with `ctx` cancelled after the first category: the second category makes 0 feed requests and
  the returned error wraps `context.Canceled`. (c) In `loop.go`, the `cat:<c>` prefix appears once in `RunOnce` errors (no `cat:cs.AI: cat:cs.AI`),
  with an assertion on the error string in an existing test. Size: about +40 lines.

## Verification
```bash
cd app
make test-unit
make lint
go test -count=1 -v -run 'TestCrawlLoopFlags' ./cmd/arxivlens/
go test -count=1 -race -v -run 'TestRunOnce' ./internal/crawler/   # AC11
make stack-up && make migrate && ./bin/arxivlens crawl-loop --once --categories cs.LG --limit-per-run 3   # needs Docker; else CI
go vet -tags integration ./internal/db/
DATABASE_URL=postgres://... go test -tags integration -count=1 -v -run '^(TestAdvanceWatermarkMonotonic|TestCrawlLoopLock)$' ./internal/db/   # needs Postgres; else CI
# CI: stack.yml step "ING-6: crawl-loop" + "arXiv replay stats"; db.yml integration step
```

## Notes
- 2026-11-17 (pm-lead): specced from the approved ING-6 design; the advisory lock moved here from design open question 3 (PM answer 3).
- 2026-11-17 (pm-lead, ING-6a1 final review of #57): AC7 made exact (vet + `-v` run of both tests in `db.yml`, PASS lines as evidence; QA finding 4
  [spec]) and AC10 added for QA findings 1–3 (teardown order, read-error and write-error rows). They land here because this task already edits
  `watermarks_integration_test.go` and `db.yml`, so the new rows are CI-verified the first time they exist. The caller side of the read-error rule
  (category skipped, never a first run) is ING-6b AC9. Size: about +25 lines on the ~220 estimate.
- 2026-11-19 (pm-lead, ING-6b final review of #60): AC11 added from ING-6b QA r1 (M9 test row, cancel-before-second-category assertion, single
  `cat:` prefix). It goes here because this task starts only after 6b merges and is owned by the same engineer. QA finding 4 (summary line
  untested) is already covered by AC3's `stack.yml` log lines. Scope gains `internal/crawler/loop.go` + `loop_test.go`. Size about 220 + 25 + 40 ≈ 285.
- 2026-11-19 18:00Z (pm-lead, plan): AC8 gains OPS-H9's one-line README prerequisite (pgvector ≥ 0.8.0), so OPS-H9 can run beside AI-8b
  without touching README. This task already waits for OPS-H9 to merge (both edit `db.yml`). New dependency: OPS-H9 merged. ~+1 line.
- 2026-11-20 13:00Z (pm-lead, sync): ING-6b (#60), #51, #52, OPS-H9 (#66) and the README PRs #65/#69 are merged; the only remaining blocker is the shared `cmd/arxivlens/main.go` with open #83, then OPS-H7a2b (README + main.go). Not startable this cycle.
- 2026-11-22 (backend-engineer, build): branch `agent/backend/ING-6c` from `53171d6`, one commit, 406 changed lines (+388/−18; ownership
  check OK with the >400 warning; under the design's 480 gate). `crawl-loop` in `main.go` (`newCrawlLoopCmdWith(run)` validates flags, then
  `runCrawlLoop`: connect → `TryCrawlLoopLock` → Kafka → `NewArxivFeed` with one `DefaultInterval` limiter → `Loop.Run`); lock =
  `pg_try_advisory_lock(hashtext('arxivlens:crawl-loop'))` on a held `pgxpool.Conn`; `TestCrawlLoopFlags`; `TestCrawlLoopLock` + AC10 (a)(b)(c)(d)
  rows; `db.yml` step (vet + `-v` run, fails on `--- SKIP`/missing PASS, prints the `it-test.%` leftover count); `stack.yml` step
  "ING-6: crawl-loop" after F1 (AC2 lock, AC3, AC4 (i)/(ii), AC5); README (CLI row, Scheduled crawl, pgvector ≥ 0.8.0). AC11: rows
  `TestRunOnceCrossListed/cs.AI's publish of p14 fails` and `TestRunOnceCancelledAfterFirstCategory`; exact error string asserted in
  `TestRunStopsOnCancel/Once returns the pass error`.
  **Deviation (design condition 10, needs a build note in `docs/design/ING-6.md`):** walk errors lost their own `cat:` (`page start=N: …`,
  `backlog exceeds --max-scan N; …`); `RunOnce` adds the single `cat:<c>: ` prefix, so the backlog error now reads `cat:cs.LG: backlog exceeds …`.
  **Not run locally:** no Go module cache and proxy.golang.org is blocked here, so nothing compiled, no `go vet`/`go test`, and mutants M6/M8/M9
  were not run (QA must run them; the M9 row's comment names the expected failure). Docker unavailable: the `stack.yml` script was only
  run under `bash -n` and against stubbed docker/curl/arxivlens up to the kill -KILL part (stubs can't release a lock on SIGKILL). CI is the source of truth.
