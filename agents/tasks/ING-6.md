# ING-6: Scheduled crawler with per-category `since` watermark

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | ING-6; Technical PRD §11 "Scheduled crawler" |
| **Depends on** | OPS-H3 (Done). ING-9 (Done `2b71772`: one shared 3 s limiter). Mahesh's #45 (`393bcf3`: `arxiv.GetAPI` typed `*StatusError`, `arxiv.Retry` 5/15/45 s, `ARXIV_API_URL` override) is merged and must be reused. Default categories may change via ADR-0005 (Proposed), so keep them configurable |
| **Design required** | **yes**: it adds a CLI command and a table (pm-lead rule). `docs/design/ING-6.md` doesn't exist yet |
| **Status** | Ready for design (no design yet). Not picked in cycle 2026-11-17: backend is at 2 picks |

## Goal
Keep the corpus fresh without someone running `arxivlens crawl` by hand (Product PRD goal 3).

## Scope
- New CLI command `arxivlens crawl-loop --categories "cs.AI,cs.LG" --interval 6h [--limit-per-run 100]`.
- New additive migration creating `crawl_watermarks(category TEXT PRIMARY KEY, last_published_at TIMESTAMPTZ, updated_at TIMESTAMPTZ)`.
- Each run, per category: crawl newest-first until reaching papers published ≤ watermark, then advance the watermark
  **only after** the events were produced successfully (crash-safe; re-runs are idempotent thanks to natural-key upserts).
- Respect the existing 3 s rate limit across categories (one shared limiter), handle SIGTERM gracefully between requests.
- Optional compose service `crawler` under profile `workers` running `crawl-loop`.
- Out of scope: changing the existing `crawl` command behaviour.

## Acceptance criteria
- [ ] AC1 — Unit test (no infra) for the stop-at-watermark logic with a fake feed: stops at the boundary, advances watermark to max seen.
- [ ] AC2 — Running `crawl-loop` twice in a row with no new papers produces zero new `papers.discovered` events on the second run (paste evidence).
- [ ] AC3 — Killing the process mid-run and restarting produces no duplicate `papers` rows (natural keys) and no skipped papers.
- [ ] AC4 — README CLI reference + Product PRD ING-6 status updated.

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
