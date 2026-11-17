# ING-6c: `arxivlens crawl-loop` command, single-instance lock, real-stack evidence and README

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Product ING-6; Technical PRD §11 "Scheduled crawler", §9 (politeness). Umbrella: [ING-6](ING-6.md) |
| **Depends on** | ING-6b **merged**; #51 and #52 **merged** (README, `db.yml`); no open PR on `cmd/arxivlens/main.go` (OPS-H7b also edits it), `.github/workflows/stack.yml`, `.github/workflows/db.yml` or `README.md` when the build starts. Approved design `docs/design/ING-6.md`, PM conditions 3, 6, 7, 9 and answer 3 |
| **Jira** | to create under KAN-18's epic, `labels = "task-ING-6c"` |
| **Design required** | no (covered by the approved ING-6 design) |
| **Status** | Blocked (ING-6b, #51, #52 not merged) |

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
  `.github/workflows/stack.yml` (step "ING-6: crawl-loop", design test plan AC2/AC3/SIGTERM rows); app `README.md`.
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
- [ ] AC8 — README (PM condition 9): CLI reference row for `crawl-loop`; a "Scheduled crawl" paragraph covering the first-run horizon (newest
  `--limit-per-run` only; older via `arxivlens crawl`), one instance (enforced by the lock), `backlog=` / `out_of_order=`, how to raise
  `--limit-per-run`, resetting a category, and the late-announcement residual risk (ING-6e). PRD status is pm-lead's docs PR after merge.
- [ ] AC9 — `make test-unit` and `make lint` green in CI; `stack.yml` and `db.yml` green.

## Verification
```bash
cd app
make test-unit
make lint
go test -count=1 -v -run 'TestCrawlLoopFlags' ./cmd/arxivlens/
make stack-up && make migrate && ./bin/arxivlens crawl-loop --once --categories cs.LG --limit-per-run 3   # needs Docker; else CI
# CI: stack.yml step "ING-6: crawl-loop" + "arXiv replay stats"; db.yml integration step
```

## Notes
- 2026-11-17 (pm-lead): specced from the approved ING-6 design; the advisory lock moved here from design open question 3 (PM answer 3).
