# OPS-H5c: Unit-test the `TestHNSWVectorHits` refusal guard; actionable hint in `TestHNSWSeedCleanup` (a)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 (harness) |
| **PRD ref** | Technical PRD §11 harness/quality; follow-up from the OPS-H5b QA/PM review (QA nits 1 + 2, `agents/reviews/OPS-H5b/report.md:40-41`, PM decision `:80`) |
| **Depends on** | OPS-H5b (#81, merged `36ceac0`). No open PR touches `internal/query/search_integration_test.go` (checked 2026-11-20 20:00Z: #94 changes `internal/query/server.go` + `server_test.go` only; #91–#93 are outside `internal/query/`) |
| **Jira** | KAN-101 (epic KAN-3 "Dev harness & infrastructure"; labels `task-OPS-H5c`, `agent-backend`, `arxivlens`) |
| **Design required** | no: test-only, one build-tagged test file |
| **Status** | Done: ArxivLens [#97](https://github.com/MaheshPulivarthi18/ArxivLens/pull/97) merged by Mahesh 2026-11-21 as `0a68283` (QA r1 PASS, PM APPROVE) |

## Goal
The guard that stops `TestHNSWVectorHits` from seeding a non-empty DB (`search_integration_test.go:77-83`: `others > 0` → `Fatalf` when `CI`
is set, else `Skipf`) has no automated test, because CI's DB is always empty and never reaches it. Pull the decision into a pure function
and table-test it so the "never let a skip pass as green in db.yml" rule can't regress silently. Also make the (a) message in
`TestHNSWSeedCleanup` tell a developer with a pre-OPS-H5b polluted DB how to clean it.

Checked on `origin/main` `230f617`: guard inline at `:77-83`; message at `:292` is
`"(a) leftover corpus after TestHNSWVectorHits: %d synth.* papers, %d synthetic chunks; want 0, 0"` with no hint.

## Scope
- `internal/query/search_integration_test.go` only (keeps `//go:build integration`).
- Add a pure helper, e.g. `hnswGuard(others int, ci bool) (skip, fatal bool)` (name must not collide with anything in package `query`, e.g. `refusedLines` in `rag_test.go`; avoid the bare name `refuse`), use it in `TestHNSWVectorHits` with the same messages, and a table test whose name starts with `TestHNSW` (so the existing `db.yml` step `-run 'TestHNSW|TestSearchProvenance'` runs it) and that needs no `DATABASE_URL`.
- Append to the (a) message: `; on a dev DB seeded before OPS-H5b run: DELETE FROM paper_chunks WHERE content LIKE 'synthetic chunk %'` (wording may vary; the SQL must be exact).
- Out of scope: `db.yml`, seed/cleanup SQL, `TestSearchProvenance`, any non-test file, CONTRIBUTING/README.
- Size: ~40 lines.

## Acceptance criteria
- [ ] AC1 — Table test rows (all four must exist): `others=0, ci=false` → no skip, no fatal; `others=0, ci=true` → no skip, no fatal; `others=1, ci=false` → skip only; `others=1, ci=true` → fatal only. Plus one row with `others=5` (either ci value) to pin "any non-zero count".
- [ ] AC2 — `TestHNSWVectorHits` calls the helper; behaviour and messages are unchanged (same `why` format string, `Fatalf` under CI, `Skipf` otherwise). The `others` count still comes from `itPrepare`.
- [ ] AC3 — `TestHNSWSeedCleanup` (a) message contains the exact SQL `DELETE FROM paper_chunks WHERE content LIKE 'synthetic chunk %'`; the condition and the other assertions are unchanged.
- [ ] AC4 — CI `db.yml` on the draft PR is green and its log shows `--- PASS` for the new test, `TestHNSWVectorHits` and `TestHNSWSeedCleanup` (quote the lines with run ID). `go vet -tags integration ./internal/query/` passes (same step).
- [ ] AC5 — Mutation check (developer runs the new test locally or in a scratch CI push, reports output in Notes, reverts): (m1) drop the CI branch (always skip) → the `ci=true` rows fail; (m2) `others > 0` → `others > 1` → the `others=1` rows fail; (m3) swap skip/fatal → rows fail; (m4) treat `ci` as always true → the `ci=false` rows fail. One mutant per operand of the guard (pm-lead lesson 2026-11-08 OPS-H7f).
- [ ] AC6 — `make test-unit` / `make lint` CI jobs green (the file is tag-excluded there; this proves nothing else broke).
- [ ] Docs: none (test-only).

## Verification
```bash
# CI (source of truth): db.yml "HNSW integration" step on the draft PR
go vet -tags integration ./internal/query/
go test -tags integration -count=1 -v -run 'TestHNSWGuard' ./internal/query/     # no DATABASE_URL needed (sandbox may lack Go 1.25: "not run locally" OK)
DATABASE_URL=... go test -tags integration -count=1 -v -run 'TestHNSW|TestSearchProvenance' ./internal/query/   # CI
git diff origin/main --name-only   # exactly internal/query/search_integration_test.go
```

## Notes
- 2026-11-20 20:00Z (pm-lead): the OPS-H5b PM review said "fold into the next change to this file, not worth a ticket by itself". No other
  change to this file is planned, backend's queue (`main.go`, `server_test.go`) is blocked behind #93/#94, and the guard is the only thing
  keeping a CI skip from passing as green, so it gets its own small ticket now.
- 2026-11-21 (pm-lead): final review APPROVE ([report](../reviews/OPS-H5c/report.md#pm-review-pm-lead--2026-11-21)). I raised PR #97: Evidence section added, marked ready for review, label `ready-to-merge`. All of AC1–AC6 are proven by QA evidence pinned at `ed872a8`.
  Process note: AC5 asked the developer to report the mutation output here, and that didn't happen. QA's independent 10-mutant run covers the AC instead.
  Follow-up (Backlog, P3): the call-site mutants c1–c3 survive. Have `hnswGuard` return a single action so the call site holds no boolean logic, and fold this into the next change to this file.
