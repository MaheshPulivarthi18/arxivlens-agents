# ING-6e: `crawl-loop --lookback` to catch papers announced after the watermark passed them

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 (P1 if Mahesh asks; see Notes) |
| **PRD ref** | Product ING-6 ("no skipped papers"); Technical PRD §11. Umbrella: [ING-6](ING-6.md) |
| **Depends on** | ING-6c **merged** and data from its `out_of_order=` summary field (or Mahesh asking for it) |
| **Jira** | to create when it leaves Backlog, `labels = "task-ING-6e"` |
| **Design required** | yes, short addendum to `docs/design/ING-6.md` (changes the walk's stop rule and adds a DB existence check) |
| **Status** | Closed — deferred, not ticketed (2026-11-28, process reset) |

## Goal
arXiv can announce a paper days after its `<published>` time (moderation holds). If that time is already below a category's watermark, the
crawl loop never sees it as new. A lookback window re-checks `(W - lookback, W]` and emits papers not yet in `papers`.

## Scope
- Files (expected): `internal/crawler/loop.go` + `loop_test.go` (walk continues to `W - lookback`; entries in the window are candidates only if no
  `papers` row exists for `(arxiv_id, version)`), `internal/db/watermarks.go` (batched existence check), `cmd/arxivlens/main.go` (`--lookback`,
  default to be decided in the addendum), app `README.md` (remove the residual-risk note).
- Out of scope: changing the watermark invariant for papers above `W`.

## Acceptance criteria
- [ ] AC1 — Unit table: a paper with `published < W` first appearing in the feed inside the window and absent from `papers` is emitted once and
  `W` doesn't move backwards; one already in `papers` is not re-emitted; one older than the window is ignored.
- [ ] AC2 — Extra arXiv requests per pass are bounded and stated in the README (pages needed for the window at the default).
- [ ] AC3 — `make test-unit`, `make lint`, `stack.yml` green; replay stats 0 misses (CI's recorded URL unchanged, or a new recording justified).

## Verification
```bash
cd app
make test-unit
make lint
go test -count=1 -v -run 'TestWalk.*Lookback|TestLookback' ./internal/crawler/
```

## Notes
- 2026-11-17 (pm-lead): split out of ING-6 as a documented residual risk (design open question 2). Becomes Ready after ING-6c merges **if**
  `out_of_order` counts or a manual check show late-announced papers being missed. FYI to Mahesh on KAN-18: if moderation-delayed papers must
  be covered by "no skipped papers" from day one, this becomes P1 and Ready right after ING-6c.
