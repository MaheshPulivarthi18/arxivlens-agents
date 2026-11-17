# OPS-H11: A redelivered `papers.discovered` record doesn't move an `embedded` paper back to `downloaded`

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (correctness gap G1 from the OPS-H6 design; OPS-4's status lookup shows a done paper as `downloaded`/`chunked` after a redelivery or DLQ replay, and it stays there if a later stage then fails) |
| **PRD ref** | Product PRD OPS-3 (reprocessing never creates duplicates), OPS-4 (per-paper status `discovered → downloaded → chunked → embedded`); Technical PRD §8 (idempotency layers L1–L3); `docs/design/OPS-H6.md` §5 G1 |
| **Depends on** | OPS-H6 (Done, #15), ING-10 (Done, #31: the downloader uses the envelope's version), OPS-H10 (Done, #26: `stack.yml` runs on Go/`tests/` PRs). No ADR: no schema, event or HTTP contract change |
| **Jira** | new story under epic KAN-3 "Dev harness & infrastructure" (`labels = "task-OPS-H11"`), like OPS-H6 (KAN-28) |
| **Design required** | no: P1, two Go packages + one test file, no new CLI/table/service, no shared-contract change |
| **Status** | Ready to merge (PR [#55](https://github.com/MaheshPulivarthi18/ArxivLens/pull/55) @ `2039650`: QA r1 PASS, PM APPROVE 2026-11-17, raised for Mahesh; specced 2026-11-17 13:00Z by pm-lead) |

## Goal
Today `Downloader.HandleRecord` always runs `UpdatePaperDownloaded`, which sets `status = 'downloaded'`, and then re-publishes
`papers.downloaded`, so the processor sets `chunked` and the embedder sets `embedded` again. A redelivered or replayed
`papers.discovered` record for a paper that is already `embedded` (same PDF bytes) should be a no-op: no status change, no new
downstream events, no re-chunking. The paper's status must stay truthful (OPS-4).

## Decision (pm-lead, settled; no open choice)
- The guard lives in the **downloader** (skip), not in the SQL (no-downgrade `CASE`): skipping removes the regression window
  *and* the duplicate `papers.downloaded`/`papers.chunked` events (OPS-H6 G3) for the common case, and it is unit-testable with the
  existing fakes.
- Skip **only** when the stored row for `(arxiv_id, version)` is `embedded` **and** its stored `sha256` equals the sha256 of the bytes
  in MinIO. `embedded` is the only terminal status. A `chunked` paper keeps today's behaviour (re-publish), so replaying
  `papers.discovered` can still restart a paper whose embed step failed. A sha mismatch, an empty stored sha, a missing row or a
  status lookup error keeps today's path (fail toward reprocessing, never toward silently skipping).
- The skip happens only when the PDF came from MinIO (the L1 `exists` branch). The downloader never fetches from arXiv to decide.

## Scope
- Files: `internal/db/db.go` (new method `PaperVersionStatus(ctx, arxivID string, version int) (status, sha256 string, err error)`:
  `SELECT status, COALESCE(sha256,'') FROM papers WHERE arxiv_id=$1 AND version=$2`; `pgx.ErrNoRows` → `("", "", nil)`),
  `internal/downloader/downloader.go` (add the method to the `paperDB` interface; the guard after the sha256 of the stored object is
  computed; one log line `[Downloader] <id> v<N> already embedded with the same sha256; skipping re-publish (event_id=…)`),
  `internal/downloader/downloader_test.go` (fakes + table test), `tests/test_m4_chaos.py` (one new real-stack test).
- `cmd/arxivlens/main.go` only if the compiler needs it (it shouldn't: `*db.DB` satisfies the interface).
- Out of scope: `internal/query/ingester.go` (on-demand ingest calls `UpdatePaperDownloaded` too; separate follow-up if wanted),
  changing `UpdatePaperDownloaded`'s SQL, the processor/embedder status writes (`services/common/db.py`), deterministic event IDs (G3, needs an ADR),
  `stack.yml`, `db.yml`, README (no user-visible command or API change).

## Acceptance criteria
- [x] AC1 — `TestHandleRecordSkipsAlreadyEmbedded` (table test, fakes, no infra). Rows: (a) object in MinIO, row `embedded`, same sha →
  `UpdatePaperDownloaded` not called, nothing published, no PDF request, `HandleRecord` returns nil; (b) `embedded` but different
  stored sha → today's path (one DB update, one `papers.downloaded`); (c) `embedded` with empty stored sha → today's path; (d) `chunked`,
  same sha → today's path; (e) no row (`""`) → today's path; (f) status lookup returns an error → today's path, error logged, not returned;
  (g) object **not** in MinIO, row `embedded` → today's path (fetch, upload, update, publish). Each row asserts DB-update count, publish count and PDF-request count.
- [x] AC2 — `TestHandleRecordFetchesTheEnvelopesVersion` still passes unchanged, and the status lookup is called with the envelope's
  version (v0 envelope → v1), asserted in AC1's fake.
- [x] AC3 — Mutation check (local, not pushed): (i) drop the sha comparison, (ii) drop the `embedded` check, (iii) return the lookup
  error instead of falling through. Each makes at least one AC1 row fail. Record the three runs in Notes.
- [x] AC4 — Real stack: new `test_redelivered_discovered_keeps_embedded_status` in `tests/test_m4_chaos.py`. Pick one `embedded` paper
  from `papers` (skip with a clear reason if none); record its `status`, `updated_at` and the end offsets of `papers.downloaded`;
  produce one `papers.discovered` envelope (new ULID, the paper's `arxiv_id` + `version`); wait (≤ 60 s, poll) until consumer group
  `downloader-v1`'s committed offset on that partition is past the produced offset; then assert status is still `embedded`, `updated_at`
  is unchanged, and no `papers.downloaded` record for that paper ID was appended after the recorded end offsets. Green in the PR's
  `stack.yml` run (it triggers on Go/`tests/` PRs); quote the test's line from the job log.
  *Amended 2026-11-17 (pm-lead, QA r1 finding 1 [spec]):* `make test-full` runs `pytest -q`, which prints no test names on a green
  run, so "quote the test's line" couldn't be met. A verified dot map (collected ids = outcome characters, the lone `s` on the lone
  `skipif`) plus proof that the skip path wasn't taken is accepted instead. OPS-H12 makes `stack.yml` print `PASSED <node id>` lines.
- [x] AC5 — `make test-unit` and `make lint` green in CI. Diff < 250 changed lines.
- [x] Docs: none required (no command/API change). Product PRD OPS-4 stays ✅; pm-lead adds a one-line note in the next `docs/` PR.

## Verification
```bash
cd app
go test ./internal/downloader/ ./internal/db/ -run 'TestHandleRecord' -count=1 -v
make test-unit
make lint
# real stack (CI): stack.yml on the PR → make test-full includes tests/test_m4_chaos.py
```

## Notes
- 2026-11-17 (pm-lead): independence at spec time: no open PR touches these four files (#51 docs/evals, #52 `internal/query/search*`,
  `tests/test_m2_pipeline.py`, `tests/test_evals_data.py`, `db.yml`, README, CONTRIBUTING; #53 CI/Makefile/requirements/Dockerfiles; #54 `rag.go`).
  Don't touch `db.yml`, README or CONTRIBUTING (held by #52/#53).
- 2026-11-17 (backend-engineer): built on `agent/backend/OPS-H11` from `40dec5a`, draft PR #55, head `2039650814ad`. 4 files,
  212 changed lines (+209/-3); `ownership-check.sh origin/main agent/backend/OPS-H11` → `Ownership OK for role=backend (212 changed lines)`.
  Guard: only in the L1 `exists` branch after the stored object's sha256 is computed; skip iff status `embedded` && stored sha non-empty && equal.
  Local runs (scratch module, Go 1.24.7 `GOTOOLCHAIN=local`, real `internal/downloader`, `internal/arxiv`, `shared/events` sources; stubs only for
  pgx/kgo/ulid/kafka/storage; `db` stub holds the real `UpdatePaperDownloaded` + `PaperVersionStatus` bodies): `go vet` clean,
  `go test -race -run 'TestHandleRecord|TestPaperVersionStatus'` PASS (AC1 rows a–g, AC2 unchanged test, a scratch-only `PaperVersionStatus` test for row/no-row/error).
  AC3 mutants (local only, never pushed), each run on the full package and with `-run '^TestHandleRecordSkipsAlreadyEmbedded$'`, same result both ways:
  (i) sha comparison dropped (`(… || true)`) → KILLED by rows b, c; (ii) `embedded` check dropped → KILLED by row d; (iii) `return lerr` → KILLED by row f
  (`HandleRecord = db down, want nil`). Extras: drop only `storedSHA == sha256Hex` → KILLED (b); guard moved outside the exists branch → KILLED (g);
  lookup with raw `envelope.Version` → KILLED (a, `lookups [0]`); drop only `storedSHA != ""` → SURVIVED (equivalent: the computed sha is never empty
  in that branch). Plain deletions of (i)/(ii) don't compile (unused var), so they were written as `|| true` to be valid mutants.
  AC4: `test_redelivered_discovered_keeps_embedded_status` checked locally only against stubbed confluent_kafka/psycopg: passes on the no-op path, fails on a
  re-published `papers.downloaded` and on a changed `updated_at`, skips with a `warnings.warn` reason when no embedded paper exists. Real result: PR's `stack.yml`.
  Not run locally: `make test-unit`, `make lint` (repo needs Go 1.25), real stack. Jira not updated from this session (no Jira tool available to me).
- 2026-11-17 (backend-engineer): CI on `2039650` all green: Go (vet, gofmt, test, build) job 134069236011 (`ok arxivlens/internal/downloader 0.106s`),
  Python M0, DB, Frontend, ownership, Full stack job 134069235738 (`make test-full`: `234 passed, 1 skipped, 3 deselected, 5 warnings in 54.21s`).
  AC4 has no named log line because `make test-full` runs `pytest -q` (stack.yml out of scope here); the new test did not skip (its skip path
  `warnings.warn`s and the warnings summary holds only 5 `tests/test_m0.py` entries) and no `F` appears. QA: map the dot positions if a named line is required.
- 2026-11-17 (pm-lead): **APPROVE** at final review (`agents/reviews/OPS-H11/report.md`). All 10 evidence files checked; AC1–AC5 proven
  (AC4 by QA's verified dot map 05 + control comparison 06; AC4 text amended above). Finding 1 [spec] → follow-up **OPS-H12** (backend, P2, Ready:
  `-rA` in `stack.yml` only). Finding 2 [nit], no task: on a dev stack where `raw/<id>_v<N>.pdf` was deleted from MinIO, the new real-stack test
  makes one arXiv fetch and then fails on `updated_at`. That's a loud failure, never a false pass; re-crawl the paper first. PRD OPS-4 note goes in
  pm-lead's next `docs/` PR. PR #55 description rewritten with evidence and marked ready for review.
