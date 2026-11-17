# ING-6b: Crawl-loop "act" half: oldest-first emit, crash-safe watermark advance, `RunOnce` / `Run`

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Product ING-6; Technical PRD §11 "Scheduled crawler", §8.1 (L1). Umbrella: [ING-6](ING-6.md) |
| **Depends on** | **ING-6a Done = both ING-6a1 (#57) and ING-6a2 (#56) merged** (6b edits `loop.go` / `loop_test.go` from 6a2 and adds the `*db.DB` → `watermarkStore` compile-time check that needs 6a1's `watermarks.go`). **ING-6f verdict `RISK1 ORDER descending`** recorded in `agents/tasks/ING-6f.md` Notes (design Risk 1; ING-6f needn't be merged, no shared files). If ING-6f prints `NOT descending` or `none`, 6b stays Blocked until pm-lead revisits design §2. Approved design `docs/design/ING-6.md` §3–§5, PM conditions 4, 5, 7, 8 |
| **Jira** | to create under KAN-18's epic, `labels = "task-ING-6b"` |
| **Design required** | no (covered by the approved ING-6 design) |
| **Status** | Blocked (needs #57 ING-6a1 and #56 ING-6a2 merged, and ING-6f verdict `descending`) |

## Goal
Make a crawl pass actually publish: emit the selected batch oldest-first, and move each category's watermark only past papers that were
upserted and acked, so a crash or SIGTERM never skips a paper and a second pass with nothing new emits nothing.

## Scope
- Files: `internal/crawler/loop.go` (emit loop, `watermarkAfter` group-complete prefix, `AdvanceWatermark` on `context.WithoutCancel` + 10 s timeout,
  pass-local cross-category `arxiv_id@version` set, `NewLoop`, `RunOnce` (joined error per failed category; a failed watermark read skips the
  category), `Run` (pass, then wait `Interval` from the end of the pass or `ctx.Done()`; nil on signal), one summary log line per category per pass
  with `pages scanned candidates emitted backlog out_of_order watermark`); `internal/crawler/crawler.go` (extract `discoveredPayload(p)` from the
  `Crawl` payload map, used by both; no other change); `internal/crawler/loop_test.go`.
- Out of scope: CLI, advisory lock, `stack.yml`, `db.yml`, README (ING-6c); `shared/events/*`; any `Crawl` behaviour change.
- Size: design estimate ~310 changed lines; skeleton first, > 480 → stop and split (PM condition 8).

## Acceptance criteria
- [ ] AC1 — `TestRunCategoryAdvancesWatermark` (fakes): untruncated → `W` = max candidate `published` (= max seen); truncated at `limit` → the oldest
  `limit` emitted in ascending order, `W` = max emitted, a second pass emits the rest, and the union over both passes equals the candidate set;
  a tie group straddling `limit` is emitted whole. `TestWatermarkAfter` covers the group-complete prefix rule (pure).
- [ ] AC2 — `TestRunOnceTwiceEmitsNothingSecondTime`: a second pass over the same feed makes 0 publishes and 0 upserts, and `W` is unchanged.
- [ ] AC3 — `TestRunCategoryCrashAtK` (table over every k = 0..n, failure injected at upsert k and at publish k, plus "watermark write fails"):
  pass 1 returns an error and `W` is never at or above an un-acked paper's `published`; a healthy pass 2 publishes every candidate at least once
  (no skip); the fake `papers` map keyed by `(arxiv_id, version)` has exactly one entry per paper; duplicate publishes come only from the failed
  group or the unwritten batch.
- [ ] AC4 — `TestRunStopsOnCancel`: cancel after publish 2 → `Run` returns nil, `W` = the group-complete prefix, written although `ctx` is cancelled.
- [ ] AC5 — Cross-listed paper (in both categories' feeds) is published once per pass and moves both categories' watermarks.
- [ ] AC6 — Payload unchanged (PM condition 5): `crawler_test.go` passes **unmodified**; a test asserts `discoveredPayload` keys/values for a fixed
  `PaperRecord` equal what `Crawl` published before the extraction (golden map). No `shared/events/*` diff.
- [ ] AC7 — Mutants (local only): advance to max seen instead of max emitted; advance after a failed publish; drop `WithoutCancel`; skip the
  cross-category set; emit newest-first. Each killed by a named test in the full run and with `-run '^Test…$'`.
- [ ] AC8 — `make test-unit` and `make lint` green in CI; `stack.yml` green (existing `crawl` path unchanged).

## Verification
```bash
cd app
make test-unit
make lint
go test -count=1 -race -v -run 'TestRunCategory|TestWatermarkAfter|TestRunOnce|TestRunStops|TestDiscoveredPayload' ./internal/crawler/
go test -count=1 ./internal/crawler/   # crawler_test.go unchanged and green
```

## Notes
- 2026-11-17 (pm-lead): specced from the approved ING-6 design. Ready once ING-6a merges and no open PR edits `internal/crawler/`.
- 2026-11-17 (pm-lead): Depends on updated after ING-6a QA r1 [spec] findings 7–8. ING-6a ships as two PRs (#56, #57) and both must merge. Design
  Risk 1 is answered by ING-6f's `stack.yml` probe before 6b's build starts.
