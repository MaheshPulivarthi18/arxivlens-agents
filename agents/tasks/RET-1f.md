# RET-1f: query test hardening: `hnswGuard` owns the whole skip/fatal decision; rerank fallback rows for NaN+Inf and `MaxFloat32`

| | |
|---|---|
| **Owner** | backend-engineer (`internal/` except `rag.go`) |
| **Priority** | P3 (test quality; no product behaviour change) |
| **PRD ref** | Technical PRD §10 Testing and evaluation; Product PRD QA-2 (cross-encoder reranking; fallback behaviour), Technical PRD §7.1 (rerank fallback; the diagram note says only "NaN", the ±Inf case from RET-1b is not yet in the PRD text, follow-up docs PR). Sources: QA OPS-H5c finding 1 (`agents/reviews/OPS-H5c/report.md`, call-site mutants c1-c3) and QA RET-1b optional rows (board backlog) |
| **Depends on** | none (OPS-H5c #97 and RET-1b #75 merged). No open PR touches `internal/query/search_integration_test.go` or `internal/query/search_test.go` (checked 2026-11-21 13:10Z against #104-#114; #105 touches only `server_test.go`) |
| **Jira** | KAN-122 (created 2026-11-21 13:00Z): epic KAN-2 "Retrieval & answer quality gates"; labels `task-RET-1f`, `agent-backend`, `arxivlens` |
| **Design required** | no: test files only |
| **Status** | Ready to merge (QA r1 PASS, PM APPROVE 2026-11-21; PR #116 raised) |

## Goal
Two small gaps in the query package's tests, both found by QA mutation checks:
1. `TestHNSWVectorHits` decides at its call site (`search_integration_test.go:77-82` @ `11c4696`):
   `if skip, fatal := hnswGuard(others, os.Getenv("CI") != ""); fatal || skip { ... if fatal { Fatalf } ; Skipf }`.
   Mutants c1 (`fatal || skip` → `fatal`), c2 (`if fatal` → `if skip`) and c3 (`CI != ""` → `CI == ""`) survive,
   because `TestHNSWGuard` pins only the pure function. A c2/c3 mutant turns a dirty DB under CI into a green skip,
   the exact case OPS-H5b/H5c exist to prevent.
2. `TestHybridSearchRerankFallback` (`search_test.go:181`) has no row with NaN and Inf in the same response (which reason
   is logged) and none proving a large finite score (`math.MaxFloat32`) is **accepted**, not treated as Inf.

## Scope
- `internal/query/search_integration_test.go`: move the call-site logic into one helper that takes the raw `CI` env
  value and a `testing.TB` (e.g. `applyHNSWGuard(tb testing.TB, others int, ciEnv string)` calling `tb.Fatalf` / `tb.Skipf`
  with today's message), so the call site is a single statement; test the helper with a recording fake that embeds
  `testing.TB` and overrides `Fatalf`/`Skipf`. Replacing `hnswGuard` and adapting `TestHNSWGuard` to the new helper is
  fine, as long as the AC1 table is still covered.
- `internal/query/search_test.go`: new rows/cases for the rerank fallback.
- Out of scope: `search.go` (no behaviour change; if a new row fails on main, stop and report it as a finding instead of
  changing code), `db.yml`, other tests.

## Acceptance criteria
- [ ] AC1: The guard helper is pinned by a table test that needs no `DATABASE_URL`, for `others` ∈ {0, 1, 5} ×
  `CI` env ∈ {"", "true", "1"}: `others > 0` with non-empty `CI` → exactly one `Fatalf`, message contains the count and
  "use an empty, migrated DB"; `others > 0` with empty `CI` → exactly one `Skipf`, same message; `others == 0` → neither.
- [ ] AC2: `TestHNSWVectorHits` calls the helper in one statement and holds no boolean logic about skip/fatal/CI.
- [ ] AC3: Rerank fallback rows: (a) NaN at rank 2 and +Inf at rank 3 → `reason="NaN score"`; (b) +Inf at rank 2 and NaN
  at rank 3 → `reason="Inf score"` (the first non-finite score by position wins, as `search.go:241-249` does today);
  (c) `math.MaxFloat32` and `-math.MaxFloat32` scores → **no** fallback line, rerank order applied, `RerankScore` set, and
  `json.Marshal(hits)` succeeds.
- [ ] AC4: Mutation check, output in an evidence file (revert each): c1, c2, c3 above (applied to the helper's
  equivalent logic) each fail AC1's test; in `search.go`, (m4) swap the NaN and Inf checks' order inside the loop body so
  Inf is tested first → still passes (both rows by position), and (m5) replace `math.IsInf(float64(sc), 0)` with
  `math.Abs(float64(sc)) >= math.MaxFloat32` → AC3(c) fails. Mutants in `search.go` are local-only and reverted.
- [ ] AC5: Every existing test passes; `git diff origin/main --name-only` lists exactly the two test files.
- [ ] AC6: CI on the draft PR: `Go (vet, gofmt, test, build)` (runs `-race`) and `DB (migrate twice, HNSW plan + recall)`
  green; the DB job log shows `TestHNSWVectorHits` ran (PASS, not SKIP).

## Verification
```bash
go test ./internal/query/ -run 'HNSWGuard|RerankFallback' -v
make test-unit
make lint
git diff origin/main --name-only   # exactly internal/query/search_integration_test.go, internal/query/search_test.go
```

## Notes
- 2026-11-21 13:00Z (pm-lead): two "fold into the next change" backlog lines combined into one test-only ticket, since
  every Ready backend ticket waits on an open PR this cycle. AC4 (m4) is expected to survive: the two rows pin "first
  by position", not which check runs first, and that is the intended behaviour.
- 2026-11-21 (pm-lead, final review): PRD ref corrected from Product QA-5 to QA-2 (QA r1 finding 1 [spec]; QA-5 is the
  relevance-bar refusal). Technical PRD §7.1 line 243 still says "wrong score count or NaN"; proposed docs-PR text is
  in `agents/reviews/RET-1f/report.md` (PM review). Residual q8 (call site passes `""`) is accepted: only a dirty-DB
  run can kill it and AC2's one-statement form keeps it visible in review. PR title fixed to `applyHNSWGuard`.
- 2026-11-21 16:00Z cycle (backend-engineer): built `14346e4` on `agent/backend/RET-1f`, PR [#116](https://github.com/MaheshPulivarthi18/ArxivLens/pull/116), test-only +100/−26. `hnswGuard` → `applyHNSWGuard(tb, others, ciEnv)`; 9-row `TestHNSWGuard` via `guardRecorder`; NaN+Inf rows and `TestHybridSearchRerankLargeFiniteScores`. Mutants c1–c3, x1–x3, m5 killed; m4 survives (expected). QA r1 PASS (`4633893`; DB job `TestHNSWVectorHits` PASS 41 s); nit q8 (call-site `""`) accepted as known gap.
