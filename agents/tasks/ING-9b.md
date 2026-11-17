# ING-9b: `arxivlens crawl` uses the shared 3 s arXiv limiter; `--rate-limit` can't go below it

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 |
| **PRD ref** | Technical PRD §9 (arXiv politeness, ≤ 1 request / 3 s); follow-up of ING-9 and ING-6 design open question 6 |
| **Depends on** | ING-6c **merged** (ING-6b/6c edit `internal/crawler/crawler.go` and `cmd/arxivlens/main.go`) |
| **Jira** | to create when it leaves Backlog, `labels = "task-ING-9b"` |
| **Design required** | no |
| **Status** | Backlog (Ready once ING-6c merges) |

## Goal
Today `arxivlens crawl --rate-limit 1s` sends one request per second (`cmd/arxivlens/main.go` `--rate-limit` flag; `crawler.go` `NewCrawler`
uses its own `time.After` sleep, not ING-9's `arxiv.Limiter`). Every bulk arXiv caller should go through the one shared limiter.

## Scope
- Files: `internal/crawler/crawler.go` (`Crawl` waits on an `*arxiv.Limiter` built from `arxiv.NewLimiter(max(rateLimit, arxiv.DefaultInterval))`
  passed to `arxiv.GetAPI`, replacing the `time.After` sleep), `internal/crawler/crawler_test.go`, `cmd/arxivlens/main.go` (`--rate-limit` below
  `arxiv.DefaultInterval` is rejected with a clear error before connecting), app `README.md` CLI row if the flag text changes.
- Out of scope: `crawl-loop` (already on the shared limiter), the PDF downloader.

## Acceptance criteria
- [ ] AC1 — `crawl --rate-limit 1s` fails before any connection with an error naming the 3 s minimum (test).
- [ ] AC2 — A `Crawl` over 3 pages against httptest (test interval) sends requests spaced by the limiter, and a 429 retry also waits on it (test).
- [ ] AC3 — `crawl --query "cat:cs.LG" --limit 2` in `stack.yml` is unchanged and green; replay stats 0 misses.
- [ ] AC4 — `make test-unit`, `make lint` green.

## Verification
```bash
cd app
make test-unit
make lint
go test -count=1 -v ./internal/crawler/ ./cmd/arxivlens/
```

## Notes
- 2026-11-17 (pm-lead): from ING-6 design open question 6; folds in nothing else. The board's "ING-9 follow-ups" (ingester/downloader tests) stay separate.
