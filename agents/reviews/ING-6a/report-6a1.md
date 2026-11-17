<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-17T18:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/57#issuecomment-6956924718 (the QA harness could not write report-6a1.md). -->

[qa-reviewer] QA round 1 for ING-6a, part **ING-6a1** (PR #57)

# QA report — ING-6a (part ING-6a1) · PR #57 · round 1

**Verdict:** PASS
**Reviewed commit:** `c86bd5a5da3b44e4ad60691cae74394672938ddb` (base main `40dec5a`; CI ran on merge `1c7ea61`) · **Date:** 2026-11-17
**Ticket:** [`agents/tasks/ING-6a.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/tasks/ING-6a.md) (this part: AC6, AC7, AC9 for its four files) · **PRD:** Product ING-6; Technical PRD §11 "Scheduled crawler" · **Design:** `docs/design/ING-6.md` (watermarks.go / migration sections + "Build notes (ING-6a)")
**Evidence commit:** [`93a9349`](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence) (files `6a1-*`; the `00`–`07` files belong to the separate ING-6a2 review of #56)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 134252075323 | pass: `make lint-go` (vet + gofmt), `make test-go` all `ok`, incl. `internal/db` ([6a1-02](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-02-ci-go-lint-test.png)) `` |
| Python M0 unit tests | CI job 134252075826 | pass (`182 passed, 3 skipped`; `37 passed`) |
| Frontend (lint, test, build) | CI job 134252075938 | pass |
| Agent ownership check | CI job 134252075832 | pass: `Ownership OK for role=backend (107 changed lines)` |
| DB (migrate twice, HNSW plan + recall) | CI job 134252075045 | pass: 000005 applied in both runs; the schema snapshot is identical across the two runs; 76 objects vs 71 on main ([6a1-04](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-04-ac7-db-migrate-twice.png)) ``` |
| Full stack (compose + make test-full) | CI job 134252075840 (`head_sha` = c86bd5a) | pass, step 17 `Migrate` green, 000005 applied ([6a1-03](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-03-ac7-stack-migrate.png)) ```` |
| `go vet -tags integration ./internal/db/` | local, **scratch module** (Go 1.24.7; real `internal/db/*.go` + `migrations/` from the PR head; pgx swapped for a QA stub that runs each statement through `psql`) | exit 0 ([6a1-05](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-05-ac6-vet-and-run.png)) ````` |
| `TestAdvanceWatermarkMonotonic` on real PostgreSQL | local, same scratch module against a local **PostgreSQL 16.15** | PASS ([6a1-05](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-05-ac6-vet-and-run.png)) `````` |
| Migration up×2 / down×2 / up | local psql, PG 16.15 | all exit 0 ([6a1-06](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-06-migration-up-down.png)) ``````` |
| Mutants (local only, never pushed) | local, scratch module + PG 16 | 6 killed, 3 survived; each survivor was confirmed to change behaviour ([6a1-07](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-07-mutants.png ````````), [6a1-09](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-09-survivor-probes.png)) ````````` |
| `make test-unit` / `make lint` with Go 1.25 | not run locally: Go 1.25 and module downloads are blocked (`proxy.golang.org` no such host) | CI (above) |
| `make eval` | not run: no retrieval or answering change | n/a |

## Acceptance criteria (this part)
| AC | Met? | Evidence |
|---|---|---|
| AC6: `TestAdvanceWatermarkMonotonic` exists and compiles under `-tags integration`. Rows: no row → `ok=false`; t2 then t1 < t2 → stays t2; t3 > t2 → t3 | ✅ | `internal/db/watermarks_integration_test.go:17-56` has all three required rows plus "equal value keeps it". `go vet -tags integration ./internal/db/` exits 0 and the test PASSes against real PG 16 in a scratch module ([6a1-05](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-05-ac6-vet-and-run.png)). `````````` The rows kill the GREATEST→overwrite, GREATEST→LEAST, DO NOTHING, ErrNoRows→ok=true, ErrNoRows→error and wrong-column mutants ([6a1-07](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-07-mutants.png ```````````)). CI does not compile this file yet (see finding 4). |
| AC7: migration applies on real Postgres; the `stack.yml` `make migrate` step passes | ✅ | Stack job 134252075840, step 17 `Migrate` success: `Running migration file: migrations/000005_crawl_watermarks.up.sql` … `migrated successfully (4 file(s))` ([6a1-03](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-03-ac7-stack-migrate.png)). ```````````` The DB job also applied it twice with no schema diff ([6a1-04](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-04-ac7-db-migrate-twice.png)). ````````````` `\d crawl_watermarks` (local PG 16) shows `category text PK`, `last_published_at timestamptz NOT NULL`, `updated_at timestamptz NOT NULL DEFAULT now()`, matching the design exactly, and `crawl_watermarks_pkey` is the `ON CONFLICT (category)` target ([6a1-06](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-06-migration-up-down.png)). `````````````` |
| AC9: no existing file changed; `make test-unit` and `make lint` green in CI | ✅ | `git diff --name-status origin/main...HEAD` lists 4 files, all `A`; 0 files are M/D/R ([6a1-01](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-01-diff-scope.png ```````````````)). The 4 files are this part's share of "the six new files". Go job (`lint-go`, `test-go`) + Python M0 (`test-py`) + Frontend (`lint-fe`) all green ([6a1-00](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-00-ci-checks.png ````````````````), [6a1-02](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-02-ci-go-lint-test.png)). ````````````````` |

Other checks:
- **Monotonic GREATEST semantics:** the SQL is exactly what the design specifies (`GREATEST(crawl_watermarks.last_published_at, EXCLUDED.last_published_at)`, `updated_at = now()`). The mutants M1/M2/M3 are killed.
- **ErrNoRows → (zero, false, nil):** `watermarks.go:26-28`. M4/M5 are killed. Other errors are wrapped with `%w` and returned with `ok=false`.
- **Idempotency (CONTRIBUTING "DB schema": `IF NOT EXISTS`, safe to re-run):** up applied twice exits 0 with the NOTICE "already exists, skipping". The down migration is `DROP TABLE IF EXISTS` and also exits 0 when run twice. Up after down recreates the table and its pkey ([6a1-06](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-06-migration-up-down.png)). `````````````````` CI migrate-twice also passes.
- **Adds only, no ADR needed (AGENTS §2):** a new table only. The public relations are exactly `crawl_watermarks` + `crawl_watermarks_pkey`, and CI's schema snapshot grows 71 → 76 (3 columns + 1 index + its `index_valid` row) with nothing removed.
- **Numbering:** `000005` while main has no `000004` (reserved for OPS-H7b, per the PM decision). `TestRepoMigrationsOrder` passes in CI. All migrations are idempotent and re-applied in lexical order, so a later-merged `000004` is safe.
- **Out of scope respected:** `db.go`, `db_test.go`, `crawler.go`, `shared/events/*`, `db.yml` and `stack.yml` are untouched. No ticket, review or doc files leaked into the PR.

## PRD fit
This part delivers the storage half of Product ING-6 / Tech PRD §11 "Scheduled crawler": a per-category `since` watermark that can only move forward, which the design's no-skip invariant (§1) needs. Nothing calls it yet, so runtime behaviour doesn't change.

## Findings
1. [nit] **Test teardown never deletes its row.** `watermarks_integration_test.go:27` `defer d.Close()` is registered before `:32` `t.Cleanup(… DELETE …)`. Go runs deferred calls *before* Cleanup functions, so the DELETE runs on a closed pool and `_, _ =` swallows the error. Every run leaves an `it-test.W<ns>` row in `crawl_watermarks` ([6a1-08](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-08-teardown-order.png): ``````````````````` Go ordering demo, and rows 0 → 1 after one passing run; "closed pool" comes from the QA stub, which mirrors pgxpool's behaviour after `Close`). This is harmless in CI (fresh DB) and no crawler reads that category, but the file header invites running it against a dev `DATABASE_URL`. Fix: replace `defer d.Close()` with `t.Cleanup(d.Close)` registered *before* the DELETE cleanup (cleanups run LIFO).
2. [nit] **The store's "read error ≠ no watermark" contract is untested (mutant M6 survives).** Making `Watermark` return `(zero, false, nil)` on *any* error passes every test. The probe shows that a cancelled context then yields `ok=false err=<nil>` ([6a1-09](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-09-survivor-probes.png)). ```````````````````` The design's failure table ("Watermark read fails → category skipped, never treated as 'no watermark'") depends on this. If it regressed, a transient DB error would look like a first run: only the newest `limit` papers would be emitted, and `AdvanceWatermark` would move `W` past the gap, a permanent skip. One cheap row closes it: `Watermark(cancelledCtx, cat)` must return `err != nil, ok == false`. The ACs and the design test plan don't require it, so it's not blocking.
3. [nit] **Mutants M8 (AdvanceWatermark swallows the Exec error) and M7 (drop `updated_at = now()`) survive**, and both change behaviour ([6a1-09](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-09-survivor-probes.png)). ````````````````````` M8 is low risk: `W` stays unchanged in the DB, so the next run only re-emits duplicates, but the design's "logged" failure path would go silent. M7 is cosmetic. A cancelled-ctx row for `AdvanceWatermark` (`err != nil`) would cover M8.
4. [spec] **No CI job compiles `watermarks_integration_test.go` yet.** `ci.yml` runs `go vet ./...` without the tag, and `db.yml` vets only `-tags integration ./internal/query/`. Until ING-6c wires `go vet -tags integration ./internal/db/` + the test into `db.yml`, a compile break in this file is invisible to CI, and AC6's compile evidence rests on scratch-module runs. pm-lead: make sure ING-6c's ACs include both the vet and the test run for `./internal/db/`.

## Missing tests
- `Watermark` with a failing read (e.g. a cancelled context) → `err != nil, ok == false` (finding 2).
- `AdvanceWatermark` with a failing write → `err != nil` (finding 3).
- (optional) `updated_at` bumps on a conflicting advance.

## Method notes
- The local Go runs use a scratch module (Go 1.24.7, `GOTOOLCHAIN=local`, `GOPROXY=off`). The PR's real `internal/db/*.go` + `migrations/` are copied in, and `github.com/jackc/pgx/v5` is `replace`d by a QA stub that executes each statement through `psql` on a local PostgreSQL 16.15 and returns "closed pool" after `Close`. It is not pgx: the evidence for the SQL semantics is real, and the evidence for the driver is not. Full harness source: [6a1-10](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/93a93499edb52520b485ba674e2091c7dabe42ca/agents/reviews/ING-6a/evidence/6a1-10-harness-source.png) `````````````````````` / `.txt`.
- Mutants: a build failure counts as INVALID (none occurred), the unmodified control PASSes, and a NOOP guard confirms each edit applied. Nothing was pushed to the PR branch.
- PR #57: open, draft, not merged; head = reviewed SHA. All CI jobs checked out `1c7ea61 Merge c86bd5a… into 40dec5a…` (current main).

## Hand-off
PASS → pm-lead final review. Findings 1–3 are non-blocking test-quality nits for backend-engineer (cheap to fold in before raise). Finding 4 is for pm-lead (ING-6c ACs).


---
_Generated by [Claude Code](https://claude.ai/code)_

---

# PM final review: ING-6a part ING-6a1 · PR #57 · round 1

**Verdict:** APPROVE
**Reviewer:** pm-lead · **Date:** 2026-11-17 · **Commit:** `c86bd5a5da3b44e4ad60691cae74394672938ddb` (PR head unchanged since QA; all 6 check runs on it `completed/success`, re-queried at review)

## What I checked
- **Ticket and Done rule.** This PR owns AC6, AC7 and AC9 for its 4 files (`agents/tasks/ING-6a.md` Done rule). The diff is those 4 files, all
  added (107 lines), and matches Scope: migration `000005` up/down, `internal/db/watermarks.go` (`Watermark`, `AdvanceWatermark`), and the
  `//go:build integration` test. Nothing out of scope (`db.go`, `db_test.go`, `crawler.go`, `shared/events/*`, `db.yml`, `stack.yml`) is touched.
- **Design and contracts.** The SQL is design §1 verbatim (`GREATEST(…)`, `updated_at = now()`). `ErrNoRows` returns `(zero, false, nil)` and any
  other error is wrapped and returned (I read `watermarks.go` lines 23–33). The migration only adds a table, so no ADR is needed (AGENTS §2). It is
  idempotent (`IF NOT EXISTS` / `DROP … IF EXISTS`), which is what `arxivlens migrate`'s re-apply needs.
- **PRD fit.** This is the storage half of Product ING-6 ("stops at a stored `since` watermark"). Nothing calls it yet and no command or behaviour
  changes for users, so no README change is due. The Product PRD ING-6 row stays ⏳ until ING-6c merges.
- **Evidence.** I opened all 11 `6a1-*` PNGs and their `.txt` files. Each embedded image shows the result for its AC, not just the command:
  - AC6: 05 shows `go vet -tags integration ./internal/db/` exit 0 and `--- PASS: TestAdvanceWatermarkMonotonic` on real PG 16. 07 shows the rows killing
    the GREATEST, ErrNoRows and wrong-column mutants.
  - AC7: 03 shows `stack.yml` job 134252075840 step `Migrate` running `000005` and `migrated successfully (4 file(s))`. 04 shows `db.yml` migrate-twice
    with an identical schema (76 objects, 71 on main). 06 shows `\d crawl_watermarks` matching the design.
  - AC9: 01 shows 4 files with status `A` and 0 modified. 02 shows CI `make lint-go` + `make test-go` all `ok`, ownership OK, and Python green. 00 shows all 6 check runs green.
  - Caveat accepted: AC6 allows a scratch-module run, and the driver is a psql-backed pgx stub (QA method note). The SQL semantics are proven on
    real Postgres, but compiling and running with real pgx in CI is ING-6c AC7, which is now exact (below).

## QA findings: decisions
1. **Nit 1 (test leaves its row: `defer d.Close()` runs before `t.Cleanup(DELETE)`)** → follow-up. Added as **ING-6c AC10(a)**. ING-6c already edits
   this file (lock test) and wires it into `db.yml`, and the fix is checked there with a `count(*) = 0` line in the job log. CI uses a fresh DB, so the
   leftover row can't affect anything before then.
2. **Nit 2 (M6: read error vs no row untested)** → follow-up, not CHANGES. I considered CHANGES because this regression would permanently skip papers.
   I chose a follow-up because: (a) the shipped code is correct (`watermarks.go` returns the wrapped error with `ok=false`, and QA's probe on the head
   prints `err=… context canceled`); (b) nothing calls `Watermark` until ING-6b and no user can run it until ING-6c, both blocked on this PR; (c) a row
   added now would sit in a file no CI job compiles until ING-6c, so a rework round would add an unverified test and cost a QA cycle.
   The risk is closed at both layers before the code path is reachable:
   - **ING-6b AC9** (new): `TestRunOnceWatermarkReadError`, where the skip actually happens. A read error means 0 requests, 0 emits, no advance, and an
     error from `RunOnce`. The mutant "read error → first run" must be killed.
   - **ING-6c AC10(b)**: store row `Watermark(cancelledCtx)` → `err != nil, ok == false`, run in `db.yml`. M6 is killed locally.
3. **Nit 3 (M8 swallowed Exec error, M7 `updated_at`)** → **ING-6c AC10(c)** (`AdvanceWatermark(cancelledCtx)` → `err != nil`; kills M8) and AC10(d)
   (optional `updated_at` row, M7 cosmetic). ING-6b AC3 already covers "watermark write fails" at the caller.
4. **[spec] 4 (no CI job compiles or runs the integration test)** → spec fixed. ING-6c AC7 now names the exact commands for `db.yml`:
   `go vet -tags integration ./internal/db/` and `go test -tags integration -count=1 -v -run '^(TestAdvanceWatermarkMonotonic|TestCrawlLoopLock)$' ./internal/db/`.
   The evidence is the `--- PASS:` lines for both tests, with no SKIP. ING-6c's Verification block now lists both commands.

## Raise
Description rewritten with the Evidence section (images pinned to `93a9349`), the PR marked ready for review, and the `ready-to-merge` label added if
the API allows it. ING-6a is Done only when #56 merges as well (Done rule). ING-6b stays Blocked on both merges and on ING-6f.
