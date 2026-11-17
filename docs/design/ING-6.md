# Tech design — ING-6: Scheduled crawler with per-category `since` watermark

**Author:** backend-engineer · **Ticket:** `agents/tasks/ING-6.md` · **PRD:** Product ING-6 (goal 3); Technical §11 "Scheduled crawler", §8.1 (L1), §9 (arXiv politeness) · **Status:** Draft

Code refs are to ArxivLens `origin/main` `40dec5a`. Relevant today: `internal/crawler/crawler.go` (`Crawl` `:72-170`: pages of
`min(20, limit)`, `arxiv.GetAPI(..., lim=nil, ...)` + `arxiv.DefaultRetry`, its own `time.After(rateLimit)` sleep `:160-166`, upsert error
only logged `:133-136`, publish error `continue` `:152-154`), `internal/arxiv/http.go` (`GetAPI`, `Retry`, `APIURL()` / `ARXIV_API_URL`),
`internal/arxiv/limiter.go` (`NewLimiter(DefaultInterval)`), `internal/db/db.go` (`UpsertDiscoveredPaper` `:107-132`, natural key
`UNIQUE (arxiv_id, version)`), `internal/kafka/producer.go` (`Publish` = `ProduceSync`, so a nil error means the broker acked),
`cmd/arxivlens/main.go` (`newCrawlCmd` `:95-136`), `migrations/000001..000003`, `.github/workflows/stack.yml` (replay-only arXiv proxy;
prefetch records exactly `search_query=cat:cs.LG&start=0&max_results=2&sortBy=submittedDate&sortOrder=descending`).

## Problem
Today the corpus grows only when someone runs `arxivlens crawl`. ING-6 adds a long-running `arxivlens crawl-loop` that, every `--interval`,
asks arXiv for each configured category's newest papers, publishes `papers.discovered` only for papers it hasn't covered yet, and remembers
how far it got in a new `crawl_watermarks` table. The watermark moves only after the events are acked, so a crash re-emits (idempotent) and
never skips. Two runs with nothing new emit nothing. This design covers AC1–AC4.

Two things the ticket's one-line rule ("crawl newest-first until ≤ watermark, then advance to max seen") doesn't handle, and that decide the shape:
1. **`--limit-per-run` truncation.** cs.LG alone gets roughly 300–400 new listings a day, so with `--interval 6h --limit-per-run 100` a run often
   finds more than 100 new papers. Newest-first + "emit the newest 100, advance to max seen" silently skips everything between the old watermark
   and the 100th paper, forever. That contradicts the PRD row ("no duplicate or skipped papers").
2. **Crash in the middle of a run.** If the watermark advances per paper in newest-first order, a crash after the newest paper but before older
   ones leaves the watermark *above* papers that were never emitted.

Both are solved by the same rule: **walk newest-first to find the gap, emit oldest-first, advance to the last fully-emitted timestamp.**

## Approach

### 1. Watermark semantics (the invariant)
For category `c` with watermark `W(c)`: *every paper listed in `cat:c` with `published > H(c)` and `published ≤ W(c)` has been upserted into
`papers` and its `papers.discovered` event acked by Kafka*, where `H(c)` is the horizon set by the first run (below). `published` is the Atom
`<published>` field (v1 submission time, what `sortBy=submittedDate` orders by), already parsed into `PaperRecord.PublishedAt`.

- No row for `c` = no watermark = first run. The first run takes the newest `--limit-per-run` papers (so the first backfill is bounded, as ADR-0005
  asks) and sets the horizon: older papers are not crawl-loop's job (`arxivlens crawl` can backfill by query). This is the only place a paper can be
  "not covered", and it is by construction, not by accident.
- `W` only increases (`GREATEST` in SQL), so two writers, a retry, or a stale process can never move it back.
- A paper is a **candidate** iff `published > W` (strict). Equal-to-`W` papers were all emitted when `W` was written (tie rule, §3).

### 2. Walk (decide what is new) — newest-first, same request shape as `crawl`
`walk(ctx, feed, category, W, hasW, limit, maxScan) (candidates []db.PaperRecord, stats, error)`:
- Query `search_query=cat:<category>`, `sortBy=submittedDate`, `sortOrder=descending`, `start` += page size. Page size `min(limit, 100)`; on a
  first run the last page asks only for the remainder, exactly like `Crawl` (so `--limit-per-run 2` sends the byte-identical URL CI already has
  recorded; asserted by a unit test, §Test plan T6).
- Keep entries with `published > W` (dedupe by `arxiv_id`, since new listings arriving mid-walk shift pages down and repeat an entry). Entries with a
  zero `published` (unparsable) are logged and ignored: they are neither candidates nor a boundary.
- Stop after: (a) a page whose **last** (oldest) entry has `published ≤ W` (boundary crossed; the rest of that page was still filtered, so an
  occasional out-of-order entry at the top of a page can't end the walk early); (b) a short or empty page (end of feed); (c) first run only:
  `limit` entries collected; (d) `scanned ≥ maxScan` with a watermark and no boundary yet → **error**, nothing emitted, `W` unchanged
  (`backlog in cat:c exceeds --max-scan N; raise --max-scan once or backfill with arxivlens crawl`). Never a silent gap.
- Every request goes through `arxiv.GetAPI(ctx, client, lim, url, arxiv.UserAgent("Crawl Loop"), arxiv.DefaultRetry)` with **one**
  `*arxiv.Limiter` (`arxiv.NewLimiter(arxiv.DefaultInterval)`) shared by all categories and all retries of the process. No `--rate-limit` flag:
  the interval can't be lowered. Non-200 is a typed `*arxiv.StatusError` (#45), never parsed.

### 3. Select and emit (act) — oldest-first
- Sort candidates ascending by `(published, arxiv_id)`. If there are more than `limit`, take the oldest `limit`, then extend to the end of the last
  timestamp group (tie rule: a batch never ends in the middle of a group of equal `published`). The rest wait for the next run (log
  `backlog: N remain`). Each run makes progress of ≥ `limit` papers, so a backlog drains as long as arrivals < `limit` per interval.
- For each paper in order: `ctx` cancelled → stop; `UpsertDiscoveredPaper` (L1; error → stop, because the downloader needs the row, unlike
  `Crawl`, which logs and goes on); `Publish(papers.discovered)` (acked; error → stop). Same payload as `Crawl` (shared helper, §5).
- After the loop, normal or stopped: `W' = published` of the last paper such that it and every earlier one were emitted **and** the next candidate
  has a strictly greater `published` (or there is none). If `W' > W`, `AdvanceWatermark(c, W')` on `context.WithoutCancel(ctx)` with a 10 s
  timeout, so a SIGTERM still records the finished prefix. "Advance to max seen" (AC1) holds exactly when the run isn't truncated or stopped;
  otherwise it's max *emitted*, which is what makes truncation and crashes safe.
- Cross-listed papers (in both cs.AI and cs.LG) are published once per pass: a pass-local set of `arxiv_id@version` already acked counts as
  emitted for the second category (and moves its watermark) without a second event.

### 4. Failure modes

| What happens | State after | Next run |
|---|---|---|
| SIGKILL/OOM anywhere before `AdvanceWatermark` returns | `W` unchanged; 0..k events acked, their rows upserted | Re-emits those k (duplicate events, same `papers` rows via the natural key; downstream L1–L3 absorb them), then the rest. No skip |
| SIGKILL after `AdvanceWatermark` | `W` = last emitted group | Nothing re-emitted |
| SIGTERM during the walk | Nothing emitted (walk emits nothing), `W` unchanged | Same as a fresh run. Process exits 0 |
| SIGTERM during emit | Finishes the in-flight call, stops, writes `W'` for the acked prefix, exits 0 | Continues after `W'` |
| arXiv 429/5xx/timeout after `DefaultRetry` | Category fails, nothing emitted; next category still runs | Retried next interval |
| Kafka/Postgres error at paper k | Stops; `W'` = prefix before k (group rule) | Re-emits from k's group |
| `AdvanceWatermark` fails | Logged; `W` unchanged | Re-emits the batch (duplicates only) |
| Watermark read fails | Category skipped (never treated as "no watermark") | Retried |
| Backlog > `--max-scan` | Category error each run, loud log | Operator raises `--max-scan` once |
| Two `crawl-loop` processes | `W` stays monotonic, duplicates only; but each has its own limiter, so arXiv sees 2 req / 3 s | README: run one instance (open question 3) |

Known residual risk (not fixed here, open question 2): arXiv can announce a paper days after its `published` time (moderation holds). If its
`published` is already below `W`, it is never a candidate. A `--lookback` window that re-checks `(W - lookback, W]` against `papers` would close
it, but costs extra pages every run and needs a DB existence check; proposed as follow-up **ING-6e**.

### 5. Code shape (new code in new files; existing behaviour unchanged)
`internal/crawler/loop.go` (new):
```go
type pageFetcher interface { Page(ctx context.Context, query string, start, n int) ([]db.PaperRecord, error) }
type paperUpserter interface { UpsertDiscoveredPaper(ctx context.Context, p *db.PaperRecord) (int64, error) }
type eventPublisher interface { Publish(ctx context.Context, topic string, e events.EventEnvelope) error }
type watermarkStore interface {
	Watermark(ctx context.Context, category string) (t time.Time, ok bool, err error)
	AdvanceWatermark(ctx context.Context, category string, t time.Time) error
}
type LoopConfig struct { Categories []string; Interval time.Duration; LimitPerRun, MaxScan int; Once bool }
func NewLoop(cfg LoopConfig, f pageFetcher, u paperUpserter, p eventPublisher, w watermarkStore) *Loop
func NewArxivFeed(client *http.Client, lim *arxiv.Limiter) pageFetcher // GetAPI + parseAtomFeed
func (l *Loop) Run(ctx context.Context) error     // pass, then wait Interval (from the end of the pass) or ctx.Done; returns nil on signal
func (l *Loop) RunOnce(ctx context.Context) error // one pass over all categories; joined error if any category failed
func ParseCategories(s string) ([]string, error)  // comma list, trimmed, deduped; each must match ^[a-z-]+(\.[A-Za-z-]+)?$ (no query injection)
```
`*db.DB` satisfies `paperUpserter` + `watermarkStore`, `*kafka.Producer` satisfies `eventPublisher`, so unit tests need no infra.
`crawler.go`: extract the payload map (`:139-148`) into `discoveredPayload(p *db.PaperRecord) map[string]interface{}` used by both `Crawl` and
the loop (no behaviour change; keeps the event shape in one place). `Crawl` is otherwise untouched.

`internal/db/watermarks.go` (new file, so it doesn't touch `db.go`, which OPS-H11 is changing):
`Watermark`: `SELECT last_published_at FROM crawl_watermarks WHERE category=$1` (`pgx.ErrNoRows` → `ok=false, nil`).
`AdvanceWatermark`: `INSERT … ON CONFLICT (category) DO UPDATE SET last_published_at = GREATEST(crawl_watermarks.last_published_at, EXCLUDED.last_published_at), updated_at = now()`.

`migrations/00000N_crawl_watermarks.{up,down}.sql` (additive, `IF NOT EXISTS`, no ADR needed per AGENTS §2):
```sql
CREATE TABLE IF NOT EXISTS crawl_watermarks (
    category          TEXT PRIMARY KEY,
    last_published_at TIMESTAMPTZ NOT NULL,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
```
`down`: `DROP TABLE IF EXISTS crawl_watermarks;`. **Number:** the next free one when the migration's part is built: `000004` if OPS-H7b
(whose spec also names `000004_dlq_replay`) hasn't merged, else `000005`. Whichever of the two merges second renumbers before merge (no
migration is "applied" until merged). `TestRepoMigrationsOrder` is a prefix check, so it stays green; I leave `db_test.go` alone (OPS-H7b edits it).

`cmd/arxivlens/main.go`: `newCrawlLoopCmd()`, `signal.NotifyContext(SIGINT, SIGTERM)`, flags
`--categories` (default `cs.AI,cs.LG`, today's `crawl` default; ADR-0005 may change it, so it stays a flag), `--interval` (default `6h`, must be
≥ `1m`), `--limit-per-run` (default `100`, > 0), `--max-scan` (default `2000`, ≥ `--limit-per-run`), `--once` (one pass, exit non-zero if any
category failed; used by CI). Invalid flags fail before connecting to anything. One summary line per category per pass, which CI greps:
`[CrawlLoop] cat=cs.LG pages=1 scanned=2 candidates=0 emitted=0 backlog=0 watermark=2026-…Z (unchanged)`.

Compose (optional part): service `crawler` built from a new `cmd/arxivlens/Dockerfile` (Go 1.25 build stage, static runtime), command
`crawl-loop --categories ${CRAWL_CATEGORIES:-cs.AI,cs.LG} --interval ${CRAWL_INTERVAL:-6h} --limit-per-run ${CRAWL_LIMIT_PER_RUN:-100}`,
`stop_grace_period: 30s`, depends on `postgres` healthy + `kafka-init` done. **Profile `crawler`, not `workers`** (deviation from the ticket,
open question 4): under `workers`, `make stack-up` would start it in CI, where it would call live arXiv (the replay proxy listens on the
runner's `127.0.0.1`), add events behind `stack.yml`'s `count(*) = 2` check, and add a Go image build to every stack run.

## Alternatives considered
1. **Ticket rule as written** (newest-first, advance to max seen after the run). Skips the tail on every truncated run and above-`W` gaps on a crash
   between publishes (§Problem). Rejected.
2. **Oldest-first query with a date range** (`cat:c AND submittedDate:[W TO now]`, `sortOrder=ascending`). Natural cursor, no walk. But the URL
   changes every run (`now`), so CI's replay-only proxy can't serve it, and `prefetch` (ai-owned `scripts/arxiv_replay.py`) only records the
   descending first page; arXiv's range filter is also minute-granular. Rejected for v1; it's the better tool for a big manual backfill.
3. **One combined query** (`cat:cs.AI OR cat:cs.LG`) with one watermark. Fewer requests, but the ticket asks per category, and a per-category
   watermark lets categories be added later without re-crawling the others.
4. **Dedupe by "row exists in `papers`" instead of a watermark.** A row is written *before* the publish (the downloader needs it), so after a
   failed publish the paper would look done and never be emitted. Rejected as the primary mechanism (it's only safe for the lookback idea in ING-6e).
5. **Advance per paper.** More DB writes, and still needs the tie rule; one write per category per run (plus on stop) gives the same crash safety.

## Contracts and invariants
- Shared contracts: **schema, additive only** (new table, new numbered migration; no ADR per AGENTS §2). No event, HTTP or embedding change: the
  loop emits the existing `papers.discovered` envelope with the same payload as `crawl` (shared helper). New CLI command = new README row.
- L1 idempotency: natural-key upsert before publish, as today. The loop only adds *fewer* duplicates than repeated `crawl`s.
- Commit-after-process analogue: the watermark is written only after `ProduceSync` acks (and the upsert succeeded) for every paper at or below it.
- arXiv politeness: one `DefaultInterval` limiter per process across categories and retries; `DefaultRetry` (5/15/45 s, Retry-After honoured)
  reused, not re-implemented; identifying UA via `arxiv.UserAgent`; no flag can lower the interval. `ARXIV_API_URL` honoured (via `APIURL()`).
- traceparent: same as `crawl` today (the crawler is the origin; envelopes carry none). Unchanged; out of scope.
- Not touched: `Crawl` behaviour, `internal/db/db.go`, `kafka/`, `dlq/`, so `tests/test_m4_chaos.py` is unaffected.

## Test plan
| Acceptance criterion | Test (name / type) | Runs in CI? |
|---|---|---|
| AC1 stop at boundary | `TestWalkStopsAtWatermark` (table, fake `pageFetcher` recording `(start, n)`). Rows: 5 new + 5 old, page 3 → pages `0,3` only, 5 candidates; nothing new → 1 page, 0 candidates; entry `== W` not a candidate; old entry at the top of page 1 but last entry `> W` → walk continues; repeat across pages → deduped; zero `published` → ignored, not a boundary; short page → stop; first run `limit 4` → exactly 4 requested (`n` = remainder); backlog > `maxScan` → error, 0 candidates | Go job (`make test-unit`) |
| AC1 advance to max seen | `TestRunCategoryAdvancesWatermark` (fakes): untruncated → `W` = max candidate `published`; truncated at `limit` → oldest `limit` emitted ascending, `W` = max emitted, the next run emits the rest, union = all candidates; tie group straddling `limit` → whole group emitted | Go job |
| AC1 rule pieces | `TestSelectBatch` (pure: ordering, tie extension), `TestWatermarkAfter` (group-complete prefix) | Go job |
| AC2 (unit analogue) | `TestRunOnceTwiceEmitsNothingSecondTime` (fakes): 2nd pass, same feed → 0 publishes, 0 upserts, `W` unchanged | Go job |
| AC2 (real) | New `stack.yml` step "ING-6: crawl-loop" after the F1 step, downloader stopped first: sum `papers.discovered` end offsets (`kafka-get-offsets.sh`), `crawl-loop --once --categories cs.LG --limit-per-run 2` → +2 (first run), again → **+0**, printed to the **job log** (`AC2: second run produced 0 papers.discovered events (N -> N)`) plus the `crawl_watermarks` row and both `[CrawlLoop]` summary lines. Same recorded URL, so the replay proxy needs no new recording; the existing "arXiv replay stats" step must show 0 misses | `stack.yml` (triggers on `cmd/**`, `internal/**`, `migrations/**`) |
| AC3 (unit) | `TestRunCategoryCrashAtK` (table over every k = 0..n, failure injected at upsert k and at publish k; plus "killed before `AdvanceWatermark`" = store write fails): run 1 errors, `W` never above an un-acked paper; run 2 healthy → every candidate published at least once (no skip), fake `papers` map keyed by `(arxiv_id, version)` has one entry per paper, duplicates only from the failed group or the unwritten batch | Go job |
| AC3 (real) | Same `stack.yml` step: (i) worst case "crashed after publishing, before the watermark write" = `DELETE FROM crawl_watermarks`, rerun `--once`; (ii) a real `kill -KILL` of a looping `crawl-loop` (`--interval 1m`) ~1 s after start, then `--once`. After each: `select count(*), count(distinct (arxiv_id, version)) from papers` equal and unchanged, both crawled IDs present, `W = max(published_at)` of the crawled papers. The kill point in (ii) isn't controlled; (i) and the unit table cover the exact points, and the evidence says so | `stack.yml` |
| SIGTERM | `TestRunStopsOnCancel` (cancel after publish 2 → returns nil, `W` = group-complete prefix written via `WithoutCancel`); stack step: `kill -TERM` a looping process → exits 0 within 5 s, log `[CrawlLoop] stopped` | Go job + `stack.yml` |
| Shared limiter / request shape | `TestArxivFeedRequest` (httptest + `ARXIV_API_URL`): first-run `limit 2` URL query equals `crawl`'s exactly (the recorded one); two categories' requests go through one limiter (test interval) and send the `Crawl Loop` UA; 429 retried via `Retry` | Go job |
| Flags | `TestParseCategories` (valid `cs.AI`, `hep-th`, `math.CO`; rejects empty, `cs.AI OR x`, `cat:cs.AI`, spaces-only); `TestCrawlLoopFlags` (interval < 1m, limit ≤ 0, max-scan < limit rejected before any connection) | Go job |
| Watermark SQL | `TestAdvanceWatermarkMonotonic` (`-tags integration`, real Postgres: lower value doesn't move it back). Wired into `db.yml` only once #52 (which edits `db.yml`) has merged; until then the stack step's `W` check is the real-DB evidence | `db.yml` (if wired) |
| AC4 | README CLI reference row + "scheduled crawl" paragraph; Product PRD ING-6 status via pm-lead's `docs/` PR | review |

Failure paths covered: arXiv non-200 after retries, upsert error, publish error, watermark read error, watermark write error, ctx cancel in walk and
in emit, backlog over max-scan, out-of-order and duplicated feed entries, unparsable `published`, ties at the `limit` cut. Mutants to run locally
(not pushed, per the OPS-H8b lesson): `>` → `>=` in the candidate filter; stop on *first* `≤ W` entry; drop the tie extension; advance to
max seen instead of max emitted; advance on a failed publish; drop `WithoutCancel`; skip the cross-category set. Each must fail a named row,
checked both in the full package run and with `-run '^T$'` (AI-8a lesson).

## Diff size and split (> 400 lines, so 4 parts)
Estimated with fakes and test tables counted separately (OPS-H8 lesson: +30 % over estimate is normal).

| Part | Files | Est. changed lines | Depends on / coordination |
|---|---|---|---|
| **ING-6a** decide | `migrations/00000N_crawl_watermarks.{up,down}.sql`, `internal/db/watermarks.go` (+ `watermarks_integration_test.go`), `internal/crawler/loop.go` (walk, select, `NewArxivFeed`, `ParseCategories`), `internal/crawler/loop_test.go` | ~120 code + ~200 test/fakes + ~40 integ = **~360** | None open: new files only, no `db.go` (OPS-H11) or README (#51/#52). Migration number fixed at build time |
| **ING-6b** act | `internal/crawler/loop.go` (emit, advance, `RunOnce`, `Run`, cross-category set), `internal/crawler/crawler.go` (payload helper), `loop_test.go` | ~130 code + ~180 test/fakes = **~310** | ING-6a merged |
| **ING-6c** CLI + evidence + docs | `cmd/arxivlens/main.go` (`crawl-loop`), `cmd/arxivlens/main_test.go` (flags), `.github/workflows/stack.yml` (ING-6 step), app `README.md` (CLI row, scheduled-crawl note, "run one instance") | ~60 + ~40 + ~50 + ~10 = **~160** | ING-6b merged; #51/#52 merged (README); no open PR on `main.go` (OPS-H7b also edits it) or `stack.yml` |
| **ING-6d** compose (optional) | `cmd/arxivlens/Dockerfile`, `docker-compose.yml` (`crawler`, profile `crawler`), `stack.yml` lint line (`docker compose --profile crawler config --quiet`) | **~55** | ING-6c merged |

AC1 is proven across 6a (stop) + 6b (advance); AC2/AC3 real-stack evidence lands in 6c (unit halves in 6b); AC4 in 6c. ING-6 is Done when 6c merges
(6d is the ticket's "optional" item and can be deferred). If pm-lead prefers fewer QA rounds, 6a+6b could be one PR at ~670 lines; I don't recommend it.

## Risks and rollout
- **arXiv sort semantics.** The design assumes `sortBy=submittedDate` orders by the `<published>` field. Rule (a) (stop on a page's *last* entry)
  tolerates a few out-of-order entries. Check during 6a: the recorded CI feed's two entries and one live sample (if the sandbox can reach arXiv;
  it can't today, so via a CI log line) must be in descending `published` order. If not, stop and revisit before 6b.
- **Late announcements** (above): residual, documented, follow-up ING-6e.
- **Duplicate events after a crash or a failed watermark write**: by design; L1–L3 absorb them (M4 proves duplicate invariance).
- **Rollout:** additive table, new command; nothing runs it unless started. Rollback = stop the process (and `DROP TABLE crawl_watermarks` via the down
  migration). Reset a category: `DELETE FROM crawl_watermarks WHERE category = 'cs.LG'` (next run is a first run again; documented in README).
- Detection: per-category summary line each pass; a failing category logs an error every interval; `backlog=` > 0 for several passes means
  `--limit-per-run` is too low for the arrival rate.

## Open questions for pm-lead
1. Accept "advance to max **emitted**" (equal to max seen unless truncated/stopped) as meeting AC1's "advances watermark to max seen"?
2. Late-announced papers below `W`: accept as a documented residual risk with follow-up ING-6e (`--lookback`), or require it in this ticket?
3. Second instance: README warning only (proposed), or a `pg_try_advisory_lock` single-instance guard (~15 lines, could join 6b)?
4. Compose profile `crawler` instead of the ticket's `workers` (reasons in §5)? And is 6d wanted now or deferred?
5. Defaults: `--limit-per-run 100`, `--max-scan 2000`, `--interval 6h`, categories `cs.AI,cs.LG` until ADR-0005 is decided.
6. Seen while reading, out of scope: `crawl --rate-limit` accepts values below 3 s (`main.go:134`, `crawler.go:59-61`), and `Crawl` doesn't use the
   ING-9 limiter. A one-line clamp or switching `Crawl` to the shared limiter would be a separate P3 politeness follow-up (board Backlog), not part of ING-6.

## PM decision
_(pm-lead fills)_
