# ING-6a: Crawl-loop "decide" half: `crawl_watermarks` table, watermark store, newest-first walk and batch selection

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Product ING-6 (goal 3); Technical PRD §11 "Scheduled crawler", §9 (arXiv politeness). Umbrella: [ING-6](ING-6.md) |
| **Depends on** | ING-9 (Done `2b71772`), #45 (merged `393bcf3`: `arxiv.GetAPI`, `DefaultRetry`, `ARXIV_API_URL`). Approved design `docs/design/ING-6.md` (PM decision 2026-11-17, conditions 1–10). No open PR touches its files |
| **Jira** | to create under KAN-18's epic, `labels = "task-ING-6a"` |
| **Design required** | no (covered by the approved ING-6 design) |
| **Status** | In QA, delivered by **two PRs** (split per PM condition 8; Done rule below): **ING-6a2** = draft [#56](https://github.com/MaheshPulivarthi18/ArxivLens/pull/56) (QA r1 FAIL, rework r1 @ `3f8e903`, QA r2 pending); **ING-6a1** = [#57](https://github.com/MaheshPulivarthi18/ArxivLens/pull/57) @ `c86bd5a`: QA r1 PASS, PM APPROVE 2026-11-17, raised (Ready to merge) |

## Goal
Land the pure, unit-testable half of the scheduled crawler: where the watermark lives, how it only moves forward, and how a run decides which
papers are new and which batch to emit. Nothing calls it yet (6b wires emit, 6c the CLI), so no runtime behaviour changes.

## Scope
- Files (all **new**; nothing existing is edited):
  - `migrations/000005_crawl_watermarks.up.sql`, `migrations/000005_crawl_watermarks.down.sql` (number fixed by the PM decision; OPS-H7b keeps `000004`)
  - `internal/db/watermarks.go`: `(*DB).Watermark(ctx, category) (time.Time, bool, error)` (`pgx.ErrNoRows` → `false, nil`) and
    `(*DB).AdvanceWatermark(ctx, category, t) error` (`INSERT … ON CONFLICT (category) DO UPDATE SET last_published_at = GREATEST(…), updated_at = now()`)
  - `internal/db/watermarks_integration_test.go` (`//go:build integration`): `TestAdvanceWatermarkMonotonic`. CI wiring (`db.yml`) is ING-6c's, because #52 edits `db.yml`
  - `internal/crawler/loop.go`: the interfaces of design §5 (`pageFetcher`, `paperUpserter`, `eventPublisher`, `watermarkStore`), `LoopConfig`,
    `walk` (design §2 incl. `out_of_order` stat, PM condition 3), `selectBatch` (oldest-first, tie extension, design §3 first bullet),
    `NewArxivFeed(client, lim)` (`arxiv.GetAPI` + existing Atom parsing, UA `arxiv.UserAgent("Crawl Loop")`, `arxiv.DefaultRetry`), `ParseCategories`
  - `internal/crawler/loop_test.go` (fakes + tables)
- Out of scope: emit/advance/`RunOnce`/`Run` and the payload helper (ING-6b); CLI, advisory lock, `stack.yml`, `db.yml`, README (ING-6c);
  any edit to `internal/db/db.go` (#55), `internal/db/db_test.go` (OPS-H7b), `internal/crawler/crawler.go`, `shared/events/*`.
- Size: design estimate ~360 changed lines. Commit a counted skeleton first; if it projects > 480, split per PM condition 8 (ING-6a1 = migration +
  `watermarks.go` + integration test; ING-6a2 = walk/feed/select).

## Done rule (added 2026-11-17, pm-lead, QA r1 finding 8 [spec])
- ING-6a is delivered by two PRs, each with its own QA report, PM review and raise, and each merged by Mahesh on its own:
  - **ING-6a1** (#57, `agent/backend/ING-6a1`): migration `000005` + `internal/db/watermarks.go` + `watermarks_integration_test.go`. Owns **AC6, AC7**,
    and AC9 for its 4 files.
  - **ING-6a2** (#56, `agent/backend/ING-6a2`): `internal/crawler/loop.go` + `loop_test.go`. Owns **AC1–AC5, AC8, AC10**, and AC9 for its 2 files.
- QA reviews each PR only against the ACs it owns (the other part's ACs are "out of this PR's scope", not "not met"). Both parts' reports go in
  `agents/reviews/ING-6a/report.md`, each section headed with its part name and PR number. New evidence file names should make the part clear (for example an `a1-`/`a2-` prefix). Existing files keep their names.
- **ING-6a is Done only when both #56 and #57 are merged.** Either may merge first (no shared files; 6a2 doesn't import 6a1).
- **ING-6b needs both merged**: it edits `loop.go`/`loop_test.go` (6a2) and adds the `*db.DB` → `watermarkStore` compile-time check, which needs
  `watermarks.go` (6a1). ING-6b also needs ING-6f's Risk 1 verdict (see AC10).

## Acceptance criteria
- [ ] AC1 — `TestWalkStopsAtWatermark` (fake `pageFetcher` recording `(start, n)`) has every row of the design test plan: 5 new + 5 old with page size 3
  → requests `start=0,3` only and 5 candidates; nothing new → 1 request, 0 candidates; entry `== W` is not a candidate; an old entry at the top of a
  page whose last entry is `> W` doesn't stop the walk; an entry repeated across pages is deduped; zero `published` is ignored and is not a boundary;
  a short page stops; first run with `limit 4` requests exactly 4 (`n` = remainder); backlog > `maxScan` with a watermark → error and 0 candidates.
- [ ] AC2 — `out_of_order` is counted (a row with one out-of-order entry asserts `1`, the sorted rows assert `0`).
- [ ] AC3 — `TestSelectBatch`: candidates come back ascending by `(published, arxiv_id)`; more than `limit` → the oldest `limit`, extended to the end
  of a tie group that straddles the cut; ≤ `limit` → all.
- [ ] AC4 — `TestArxivFeedRequest` (httptest + `ARXIV_API_URL`): a first run with `limit 2` sends a query string byte-identical to the URL
  `stack.yml` records (`search_query=cat:cs.LG&start=0&max_results=2&sortBy=submittedDate&sortOrder=descending`); two categories' requests share one
  limiter (test interval, spacing asserted) and send the `Crawl Loop` UA; a 429 is retried through `arxiv.Retry`; a non-200 after retries returns
  `*arxiv.StatusError` and is not parsed.
  *Amended 2026-11-17 (pm-lead, QA r1 finding 6 [spec]):* the string above is the **parameter set**, not the byte order. "Byte-identical to
  the URL `stack.yml` records" means the bytes `Crawl` sends, which are `url.Values.Encode` output (keys sorted, `:` encoded):
  `max_results=2&search_query=cat%3Acs.LG&sortBy=submittedDate&sortOrder=descending&start=0`. Proof: `stack.yml` run 44092000441
  (job 134069235738) logs `URL=http://127.0.0.1:8099/api/query?max_results=2&search_query=cat%3Acs.LG&sortBy…`, and
  `scripts/arxiv_replay.py` `search_query_string`/`api_key` sort the keys (QA evidence 07). The test asserting these bytes meets AC4.
- [ ] AC5 — `TestParseCategories`: accepts `cs.AI`, `hep-th`, `math.CO`, `cs.AI, cs.LG,cs.AI` (trimmed, deduped, order kept); rejects empty,
  spaces-only, `cs.AI OR x`, `cat:cs.AI`.
- [ ] AC6 — `TestAdvanceWatermarkMonotonic` exists and compiles under `-tags integration` (`go vet -tags integration ./internal/db/` output in the
  PR; may be a scratch-module run if the sandbox lacks Go 1.25): no row → `ok=false`; advance to t2 then t1 < t2 → stays t2; advance to t3 > t2 → t3.
  It runs against real Postgres in CI from ING-6c.
- [ ] AC7 — The migration applies on real Postgres: the PR's `stack.yml` run (triggered by `migrations/**`) passes its `make migrate` step, and
  `\d crawl_watermarks` or an equivalent query output is in the evidence if the run exposes it (else the green `make migrate` step log).
- [ ] AC8 — Mutants (local only, never pushed; PM condition 4): `>` → `>=` in the candidate filter; stop on the *first* `≤ W` entry instead of the
  page's last; drop the tie extension; drop dedupe. Each is killed by a named test, in the full package run **and** with `-run '^Test…$'`.
- [ ] AC9 — No existing file changed (`git diff --stat origin/main` lists only the six new files); `make test-unit` and `make lint` green in CI.
  *Amended 2026-11-17 (pm-lead):* per PR: #57 lists only its 4 new files, #56 only its 2 (Done rule above).
- [ ] AC10 — PR description quotes the two `published` values of the recorded CI feed (`internal/crawler/testdata/arxiv_feed.xml` or the replay
  cache entry) and states whether they are descending (design Risk 1). If they are not, stop and tell pm-lead before ING-6b.
  *Decision 2026-11-17 (pm-lead, QA r1 finding 7 [spec]):* AC10 is **met as worded by ING-6a2** (#56 quotes the fixture values and says they're
  ascending), and Risk 1 is triggered because that fixture is synthetic. Answering it is not ING-6a's job: new harness task
  **[ING-6f](ING-6f.md)** (backend, P1, `stack.yml` only) prints the recorded `cat:cs.LG` feed's `published` order in the job log. ING-6b's
  Depends on now includes ING-6f's verdict `descending`. It doesn't block either 6a PR.

## Verification
```bash
cd app
make test-unit
make lint
go test -count=1 -v -run 'TestWalkStopsAtWatermark|TestSelectBatch|TestArxivFeedRequest|TestParseCategories' ./internal/crawler/
go vet -tags integration ./internal/db/
git diff --stat origin/main   # only the six new files
# CI: ci.yml Go job + stack.yml (migrations/** and internal/** trigger it)
```

## Notes
- 2026-11-17 (pm-lead): specced from the approved ING-6 design. Buildable now: all files are new, no overlap with #51–#55 (#55 edits
  `internal/db/db.go` in the same package, different file; no textual conflict). Backend WIP: only #55 is active.
- 2026-11-17 (backend-engineer): built. **Split per PM condition 8**: the full part was 505 changed lines (> 480 gate), so it is split at the named seam.
  - **ING-6a1** (107 lines): migration `000005` + `internal/db/watermarks.go` + `watermarks_integration_test.go`, branch
    `agent/backend/ING-6a1` @ `c86bd5a` (pushed, **no PR**: backend WIP would be 3 with #55 and #56). Covers AC6, AC7, AC9 for its files.
    Open its PR when a backend slot frees; it must merge before ING-6b.
  - **ING-6a2** (398 lines): `internal/crawler/loop.go` + `loop_test.go`, draft [#56](https://github.com/MaheshPulivarthi18/ArxivLens/pull/56) @ `3756173`.
    Covers AC1–AC5, AC8, AC9 for its files, AC10. It doesn't depend on 6a1 (the `*db.DB`→`watermarkStore` compile-time check moves to 6b).
  - Local checks: scratch module, Go 1.24.7 with pgx/ulid/kgo stubs. `go vet ./internal/...` and `go vet -tags integration ./internal/db/` exit 0,
    and `go test -race` on crawler/arxiv/db is ok. Each part was also vetted and tested alone. Go 1.25 `make test-unit`/`make lint` run in CI only.
  - AC8: the 4 listed mutants plus 4 extra are all killed in the full package run and with `-run '^T$'` (table in the #56 description). The undated-boundary
    mutant survived the first table, so the undated row gained an all-undated page.
  - **AC10, needs pm-lead before ING-6b**: `testdata/arxiv_feed.xml` is ascending (`2023-07-17T17:50:36Z`, then `2024-01-22T09:00:00Z`). It is a
    hand-written OPS-H3 fixture, though, not an arXiv recording. The real recording is only in the Actions cache (not downloadable here), CI logs don't print
    `published`, and live arXiv is blocked (403). The only CI datum is crawl order `2611.21608` → `2611.21602` (run 44092000441), descending IDs.
    Proposal: one `psql` line in `stack.yml` printing `arxiv_id, published_at` (outside 6a; place it in 6c or a small harness task before 6b).
  - Deviations written back into `docs/design/ING-6.md` §"Build notes (ING-6a)".
  - Jira: no `task-ING-6a` story exists yet, so nothing to move.
- 2026-11-17 (backend-engineer): **rework r1 (QA round 1 FAIL on #56)**, test-only, `internal/crawler/loop_test.go`. ING-6a2 head `3756173` → `3f8e903`;
  the PR is now 426 changed lines (177 + 249, all additions; ownership-check OK, warns > 400, under the 480 gate). `loop.go` unchanged.
  - Finding 1 [blocking]: added 3 walk rows. `first run: undated not a candidate` (`feed(15,-1,14)`, no W → `p15 p14`), `page ending [<=W, undated] stops`
    (`[15,9,undated]`, W=10 → exactly one request `0,3`), and `out_of_order across an undated entry` (`15,13,undated | 14,12,9` → out_of_order=1).
    M5 (`if false && p.PublishedAt.IsZero()`) is killed by all 3 rows, both in the full package and with `-run '^TestWalkStopsAtWatermark$'`.
  - Nits 2+3: new `TestNewArxivFeedDefaults` checks the given client and limiter, that retry Attempts/Base/Max equal `arxiv.DefaultRetry`, and that
    `NewArxivFeed(client, nil)` gives a non-nil limiter with `Interval() == arxiv.DefaultInterval`. It kills M23 (NoRetry / zero retry) and M24 (nil stays nil /
    `NewLimiter(0)`) in both runs.
  - Nit 4: added the subtest `ctx cancelled between requests` (the fake cancels on its first request → `context.Canceled`, no candidates, one request).
    It kills M27 (ctx check removed) in both runs.
  - Nit 5 and [spec] 6–8 are left to pm-lead. No existing row was changed.
  - Local checks: scratch module, Go 1.24.7 (stubs for db/kafka/ulid, real arxiv/crawler/events). `go vet` is clean, `gofmt -l` is empty, and
    `go test -race ./internal/...` is ok. Mutants ran in the scratch copy only and were never committed. Go 1.25 `make test-unit`/`make lint` run in CI only.
- 2026-11-17 (pm-lead): **decisions on ING-6a2 QA r1 [spec] findings 6–8.** (6) AC4 amended to the real sorted-encode bytes, with the CI log
  line as proof. The test was right and the AC text was wrong. (7) Risk 1 goes to new task **ING-6f** (backend, P1, Ready, `stack.yml` only).
  It doesn't go in 6c, which comes after 6b, or in 6b's ACs, because 6b needs the answer before its build starts. ING-6f is independent of #56/#57 (no
  shared files). It must not run in parallel with OPS-H12 (same file). ING-6b Depends on updated. (8) Done rule written above: ING-6a is Done when
  #56 **and** #57 merge; 6b needs both. QA scopes each PR to its own ACs. Nit 5 (no counted-skeleton commit) needs no action: condition 8's
  outcome (split at 505 > 480) is recorded in these Notes.
- 2026-11-17 (pm-lead): **ING-6a1 (#57) final review: APPROVE** at `c86bd5a` (verdict in `agents/reviews/ING-6a/report-6a1.md`). AC6, AC7 and AC9
  are met for its 4 files. QA findings: nits 1 (teardown order), 2 (M6, read error vs no row) and 3 (M7/M8) go into **ING-6c AC10**, which already edits
  `watermarks_integration_test.go` and wires it into `db.yml`, so the rows are CI-run when they land. The caller half of nit 2 (category skipped on a read
  error, never a first run) is **ING-6b AC9**. [spec] 4: ING-6c AC7 now names the exact `go vet` and `-v` test commands and PASS lines.
