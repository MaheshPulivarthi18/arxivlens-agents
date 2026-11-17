# ING-6: Scheduled crawler with per-category `since` watermark

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | ING-6; Technical PRD §11 "Scheduled crawler" |
| **Depends on** | OPS-H3 (Done). ING-9 (Done `2b71772`: one shared 3 s limiter). Mahesh's #45 (`393bcf3`: `arxiv.GetAPI` typed `*StatusError`, `arxiv.Retry` 5/15/45 s, `ARXIV_API_URL` override) is merged and must be reused. Default categories may change via ADR-0005 (Proposed), so keep them configurable |
| **Design required** | **yes**: it adds a CLI command and a table (pm-lead rule). `docs/design/ING-6.md` doesn't exist yet |
| **Status** | **Umbrella.** Design approved with conditions (pm-lead 2026-11-17, [`docs/design/ING-6.md`](../../docs/design/ING-6.md) "PM decision"). Built as [ING-6a](ING-6a.md) (Ready) → [ING-6b](ING-6b.md) → [ING-6c](ING-6c.md). Done when ING-6c merges. Deferred: [ING-6d](ING-6d.md) (compose), [ING-6e](ING-6e.md) (lookback); follow-up [ING-9b](ING-9b.md) |

## Goal
Keep the corpus fresh without someone running `arxivlens crawl` by hand (Product PRD goal 3).

## Scope
- New CLI command `arxivlens crawl-loop --categories "cs.AI,cs.LG" --interval 6h [--limit-per-run 100]`.
- New additive migration creating `crawl_watermarks(category TEXT PRIMARY KEY, last_published_at TIMESTAMPTZ, updated_at TIMESTAMPTZ)`.
- Each run, per category: crawl newest-first until reaching papers published ≤ watermark, then advance the watermark
  **only after** the events were produced successfully (crash-safe; re-runs are idempotent thanks to natural-key upserts).
- Respect the existing 3 s rate limit across categories (one shared limiter), handle SIGTERM gracefully between requests.
- Optional compose service `crawler` under profile `workers` running `crawl-loop`. *(Amended 2026-11-17: profile `crawler`, deferred to ING-6d.)*
- Out of scope: changing the existing `crawl` command behaviour.

## Acceptance criteria
- [ ] AC1 — Unit test (no infra) for the stop-at-watermark logic with a fake feed: stops at the boundary, advances watermark to max seen.
  *(Amended 2026-11-17, PM answer 1: "max seen" means the max `published` of the fully emitted prefix, which equals max seen unless the run is
  truncated at `--limit-per-run` or stopped; proven by ING-6a AC1 + ING-6b AC1.)*
- [ ] AC2 — (ING-6b AC2 unit, ING-6c AC3 real stack) Running `crawl-loop` twice in a row with no new papers produces zero new `papers.discovered` events on the second run (paste evidence).
- [ ] AC3 — (ING-6b AC3 unit, ING-6c AC4 real stack) Killing the process mid-run and restarting produces no duplicate `papers` rows (natural keys) and no skipped papers.
- [ ] AC4 — (ING-6c AC8; PRD via pm-lead docs PR after 6c merges) README CLI reference + Product PRD ING-6 status updated.

## Verification
```bash
go test ./internal/crawler/...
make stack-up && ./bin/arxivlens migrate && ./bin/arxivlens crawl-loop --categories cs.LG --interval 1m --limit-per-run 3
```

## Notes
- 2026-11-17 (pm-lead, grooming): marked **design-required** (new CLI command + new table, per my definition). The spec predates #45, which
  rewrote `internal/crawler/crawler.go` onto `arxiv.GetAPI` + `arxiv.Retry`. The design must reuse those, the ING-9 limiter, and the
  `ARXIV_API_URL` override (so CI can replay the loop's requests). **Migration number:** OPS-H7b's spec also claims `000004`. The
  design takes the next free number at build time and says so; whichever merges second renumbers. Also fold in the ING-9 follow-ups that
  touch `internal/arxiv`/`crawler` (board Backlog) only if they're on the same lines.
- 2026-11-17 13:00Z (pm-lead, planning): design stage can start now (it writes only `docs/design/ING-6.md` here). Re-check before the
  build starts: the build touches `README.md` (CLI table) and probably `docker-compose.yml` and `cmd/arxivlens/main.go`; README is
  held by #51/#52 today, so the build waits until those merge or the README row moves to a follow-up. The design must also say how
  AC2/AC3 are evidenced in CI (`stack.yml` runs on Go PRs; arXiv is replayed from the Actions cache since #45), and which migration
  number it takes (next free at build time; OPS-H7b also wants one).
- 2026-11-17 (backend-engineer, design): wrote `docs/design/ING-6.md` against app `40dec5a`. Key points: walk newest-first to find the gap, emit **oldest-first**, advance `W` to the last fully-emitted `published` group (fixes the silent skip on `--limit-per-run` truncation and on a crash between publishes); one shared `arxiv.Limiter` + `DefaultRetry`; first-run URL identical to the recorded CI replay URL, so AC2/AC3 are evidenced in `stack.yml` with no new recording. Proposed split: ING-6a decide (~360), 6b act (~310), 6c CLI + stack evidence + README (~160, after #51/#52), 6d compose (optional, ~55, profile `crawler` not `workers`). Watermark SQL lives in new `internal/db/watermarks.go`, so no `db.go` overlap with OPS-H11. Migration number: next free at 6a build time (`000004` unless OPS-H7b merged first). Six open questions for pm-lead at the end of the design.
- 2026-11-17 (pm-lead, design gate): **Approved with conditions 1–10** (see the design's "PM decision"). Answers: (1) max emitted = AC1's
  "max seen" (AC1 amended above); (2) late announcements = documented residual risk, ING-6e Backlog, FYI to Mahesh; (3) global
  `pg_try_advisory_lock` single-instance guard, in ING-6c; (4) profile `crawler`, compose deferred to ING-6d; (5) defaults 6h / 100 / 2000 /
  `cs.AI,cs.LG` (categories stay ADR-0005's); (6) `crawl --rate-limit` → ING-9b (P3). **Migration number fixed: `000005_crawl_watermarks`**
  (OPS-H7b keeps `000004`; `migrate` applies all sorted files idempotently, so the gap is harmless and nobody renumbers).
  ING-6a is buildable now: six new files, no overlap with #51–#55.
