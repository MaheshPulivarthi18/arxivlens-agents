# OPS-H5: Create the HNSW vector index in a migration, and apply all migrations in order

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | QA-1; Product PRD §8 `/v1/search` p95 < 1.5 s; Technical PRD §5 (HNSW gap note) |
| **Depends on** | — (soft: OPS-H1 for AC5; without it, start the workers by hand per AGENTS.md §6) |
| **Jira** | find with JQL `labels = "task-OPS-H5"` |
| **Design required** | no (P1; additive index migration, no new command/table/service; `migrate` keeps its existing flag) |
| **Status** | In QA (draft PR #16, rework r1 done; H4 blocked on OPS-H1) |

## Goal
Technical PRD §5 promises an HNSW cosine index on `chunk_embeddings.embedding`, but no migration creates it. Only
`scripts/benchmark_hnsw.py` does (`chunk_embeddings_hnsw_idx`, `m=16, ef_construction=64`). On a fresh `make migrate`,
vector search is therefore an exact scan, and `tests/test_m5_m6_telemetry_eval.py::test_pgvector_hnsw_index_presence_and_querying`
passes only if the benchmark script happened to run first. Also, `arxivlens migrate` executes a single file
(`RunMigrations(ctx, migrationFile)`), so a second migration would never be applied.

## Scope
- Files: new `migrations/000002_chunk_embeddings_hnsw.up.sql` and `.down.sql`, `internal/db/db.go` and/or `cmd/arxivlens/main.go` (`migrate` applies every `*.up.sql` in lexical order), and a Go unit test for the file ordering (no DB).
- CLI shape (pm-lead 2026-11-03 16:00, settles the open choice): `arxivlens migrate` with no flags applies every `*.up.sql`
  in `--dir` (new flag, default `migrations`) in lexical order. The existing `--file <path>` keeps working and, when set,
  applies only that file (backward compatible). Put the file selection in a pure function in `internal/db` (e.g.
  `MigrationFiles(dir string) ([]string, error)`) so AC3 needs no DB; new test file `internal/db/db_test.go`
  (picked up by `go test ./...`, no CI change).
- Docs: app `README.md` CLI reference line `arxivlens migrate  [--file ...]` (`README.md:166` at `9c1229a`) → show
  `[--dir migrations] [--file <one .up.sql>]`. That line is outside every README hunk of open PR #14 (hunks at old lines
  89–100, 108–127, 131–144, 198–204, 214–219, 227–231); touch nothing else in README.
- **Do not edit `Makefile`, `CONTRIBUTING.md`, `docker-compose.yml` or `.github/`**: all are changed by open PR #14
  (OPS-H1). `make migrate` already runs `./bin/arxivlens migrate` with no flags, so it picks up the new default unchanged.
- The index must use exactly the existing name and params: `CREATE INDEX IF NOT EXISTS chunk_embeddings_hnsw_idx ON chunk_embeddings USING hnsw (embedding halfvec_cosine_ops) WITH (m = 16, ef_construction = 64);`, so that existing databases where the benchmark already created it stay a no-op. Changing the params is out of scope (ADR-0008).
- Migrations must stay idempotent (`IF NOT EXISTS`), because there is no schema-version table. Adding a version table is out of scope.
- Never edit `000001_init_schema.*.sql`.
- Out of scope: `scripts/benchmark_hnsw.py` (ai-engineer may later drop its CREATE INDEX), and query SQL changes.

## Acceptance criteria
- [ ] AC1 — On a fresh database, `make migrate` creates `chunk_embeddings_hnsw_idx`. Paste the `\d chunk_embeddings` or `pg_indexes` output.
- [ ] AC2 — Running `make migrate` twice in a row succeeds (idempotent).
- [ ] AC3 — Go unit test: the migration runner selects `*.up.sql` only, in lexical order (`000001` before `000002`). Passes with no DB.
- [ ] AC4 — `EXPLAIN` of the vector CTE in the hybrid query from `internal/query` is pasted in the PR, with the planner's choice noted. If the planner does not use the index (e.g. because of the join or model filter), open a follow-up request in Notes instead of changing the query here.
- [ ] AC5 — `make test-full` M1 and M5/M6 pass on a fresh stack without running `scripts/benchmark_hnsw.py` first. Use OPS-H1's `make stack-up` if merged; otherwise start the processor/embedder workers by hand (AGENTS.md §6) and say so in the PR. If no Docker is available, write "not run: infra unavailable" plus the exact commands. AC3 always needs CI evidence. *(pm-lead 2026-11-03 16:00)* With no Postgres in the sandbox and `ci.yml` off-limits (open PR #15), AC1, AC2 and AC4 may also be "not run: infra unavailable" at PR time; they are then owed as post-merge evidence from the first `stack.yml` run that includes this migration (OPS-H1 #14 rebased on it), filed in `agents/reviews/OPS-H5/`. Stop-and-report: if that run shows no `chunk_embeddings_hnsw_idx` or a failing second `make migrate`, pm-lead reopens OPS-H5 as P0 before OPS-H1 is raised.

## Verification
```bash
make test-unit
make lint
make infra-up && make migrate && make migrate
psql "$DATABASE_URL" -c "SELECT indexname, indexdef FROM pg_indexes WHERE tablename='chunk_embeddings';"
make test-full
```

## Notes
- Specced by pm-lead in PM-1 after finding that no migration creates the HNSW index (`grep -rni hnsw migrations/` is empty).
- Adding an index through a new migration needs no ADR (AGENTS.md §1).
- 2026-11-03 (pm-lead, OPS-H1 design gate): OPS-H5 is now on the P0 OPS-H1 critical path, because OPS-H1's `stack.yml` can't be green until this index migration merges. **Take the next free backend slot for OPS-H5**, ahead of OPS-H7, OPS-H2, OPS-H8 and ING-6. Its files don't overlap OPS-H1's. If OPS-H1 isn't merged, AC5 may say "not run: infra unavailable" (as above). OPS-H1's green rerun after this merges is filed as post-merge AC5 evidence in `agents/reviews/OPS-H5/`.
- 2026-11-03 16:00 cycle (pm-lead, plan): picked as backend's one free slot. Independence checked against open PRs:
  #13 = `internal/query/rag*.go`, #14 = compose, both Dockerfiles, `Makefile`, `stack.yml`, README/CONTRIBUTING hunks
  listed in Scope, #15 = `internal/kafka/consumer*.go` + `ci.yml`. OPS-H5 touches `migrations/000002_*`, `internal/db/`,
  `cmd/arxivlens/main.go` (`newMigrateCmd` only) and README line 166 → no overlap. `000001_init_schema.up.sql` is already
  all `IF NOT EXISTS`, so AC2 needs no change to it. AC1/AC2/AC4/AC5 need a Postgres: in this sandbox write
  "not run: infra unavailable" with the exact commands; they get CI evidence when #14's `stack.yml` reruns after this merges
  (post-merge AC5 evidence in `agents/reviews/OPS-H5/`, as above). AC3 + `make test-unit`/`make lint` must be green in `ci.yml`.
- 2026-11-03 (backend-engineer, build): draft PR [#16](https://github.com/MaheshPulivarthi18/ArxivLens/pull/16),
  branch `agent/backend/OPS-H5`, head `47e845186d0bc2d6dc6731a5306e8d9994a95bcb` (cut from `9c1229a`). 6 files, +156/−7:
  `migrations/000002_chunk_embeddings_hnsw.{up,down}.sql`, `internal/db/db.go` (`MigrationFiles(dir)`),
  `internal/db/db_test.go`, `cmd/arxivlens/main.go` (`newMigrateCmd` only: `--dir` default `migrations`, `--file` default
  now empty and applies only that file), `README.md:166`. Ownership check: `Ownership OK for role=backend (163 changed lines)`.
  CI run 41671476133 on the head SHA: Go (vet, gofmt, test, build) 126040678034 **success** (log: `ok arxivlens/internal/db`),
  Python M0 126040678985 success, Frontend 126040678656 success, Agent ownership check 126040678981 success.
  - AC1: not run (no infra: no Docker or Postgres). Owed post-merge from OPS-H1 `stack.yml`.
  - AC2: not run (no infra). Idempotent by construction: all `IF NOT EXISTS`.
  - AC3: CI Go job green and `internal/db` ran (`TestMigrationFiles` table, `TestMigrationFilesMissingDir`,
    `TestRepoMigrationsOrder`). Locally, an isolated copy passed on Go 1.24, because the full module can't build there
    (go 1.25 directive, proxy unreachable).
  - AC4: not run (no infra). Risk noted in the PR: the `vector_hits` CTE uses `ROW_NUMBER() OVER (ORDER BY <=>)` plus
    joins and the model/category filter, so the planner may skip the index. Also, HNSW default `ef_search=40` < `LIMIT 50`.
    Follow-up to be filed from the EXPLAIN result.
  - AC5: not run (no infra). Commands in the PR. Owed post-merge from #14 `stack.yml`.
  - Caveat: the lexical-order test can't catch a removed `sort.Strings`, because `os.ReadDir` already returns entries
    sorted by name. The sort is kept so the order stays explicit.
- 2026-11-03 19:02Z cycle (orchestrator): **Human review** from Mahesh on PR #16 (2026-11-03T17:58Z, head `47e8451`) —
  top priority. PR stays draft; Jira → In Progress. Rework checklist (QA checks each item explicitly next round):
  - [ ] H1 (AC1/AC2): `make migrate` (or `arxivlens migrate`) on a **fresh real PostgreSQL + pgvector** DB; show
    `chunk_embeddings_hnsw_idx` exists; run it a second time, succeeds, index set unchanged. Output attached.
  - [ ] H2 (AC4): `EXPLAIN (ANALYZE, BUFFERS)` of the **actual** `vector_hits` query from `internal/query/search.go`
    (not a hand-written look-alike); attach the plan and state whether the HNSW index is selected.
  - [ ] H3 (recall/filtering): measure Recall@5 of the real query with the index vs an exact scan; LIMIT 50 vs default
    `hnsw.ef_search=40` and the model/category filters can shrink the candidate set. Document the chosen `ef_search` /
    iterative-scan behaviour if recall or result count is insufficient.
  - [ ] H4 (AC5): fresh-stack integration path without first running `scripts/benchmark_hnsw.py` — the migration must
    create the index. Needs OPS-H1 (#14) green → stays open, **blocked on OPS-H1**, post-merge evidence allowed.
  - [ ] H5 (note): runner re-applies every `*.up.sql` each run; document in `CONTRIBUTING.md`/README that new
    migrations must be idempotent until a version ledger exists (ledger itself → backlog).
  - Sandbox has PostgreSQL 16 binaries but no pgvector (no server headers, apt/GitHub archives unreachable), so H1–H3
    run on GitHub runners: backend adds a DB-backed workflow (e.g. `.github/workflows/db.yml` with a
    `pgvector/pgvector:pg16` service) — no overlap with #14's `stack.yml`.
- 2026-11-03 rework r1 (backend-engineer, after Mahesh's review): head `cff6fa1380406cbedb01652f90f9919f2d2c8051` on
  `agent/backend/OPS-H5` (PR #16 still draft; body updated with H1–H5). New: `.github/workflows/db.yml` (service
  `pgvector/pgvector:pg16`, pgvector 0.8.7), `internal/query/search_integration_test.go` (`//go:build integration`),
  `search.go` SQL lifted into `vectorHitsSQL`/`hybridSearchSQL` constants (text unchanged) + `hnswSearchSettings`,
  `CONTRIBUTING.md` H5 line. PR diff vs `9c1229a`: 10 files, +581/−38 (619 lines, > 400: 293 test + 71 workflow).
  Ownership check OK. **DB** run 41705021838 / job 126157913475 **success**; **CI** run 41705022138: Go 126157913608,
  Python M0 126157913991, Frontend 126157913888, ownership 126157913891, all success. (Earlier heads: c851038 green but
  its recall numbers were invalid, see below; 8c06dcf DB job failed on a test arg bug, fixed in c36a9ee.)
  - [x] H1: fresh DB (`extension|plpgsql|1.0` only) → migrate ran 000001, 000002 → `chunk_embeddings_hnsw_idx ... USING
    hnsw (embedding halfvec_cosine_ops) WITH (m='16', ef_construction='64')`, `indisvalid=true`; 2nd migrate OK,
    snapshot diff empty (`Schema identical after run 2: 67 objects`).
  - [x] H2: EXPLAIN (ANALYZE, BUFFERS) of the real constants via PREPARE/EXECUTE. Custom plan: HNSW selected
    (Index Scan using chunk_embeddings_hnsw_idx, model filter applied after the index), except the 2% filter (papers → pkey
    + sort, correct). Generic plan: HNSW never selected (exact sort over all rows; `($3 IS NULL OR ...)` estimated 15 of
    1000 papers). pgx statement cache + `plan_cache_mode=auto` → production uses generic after 5 runs per connection
    (`hybridSearchSQL` x20: generic=15 custom=5 unfiltered; generic=20 filtered). Production is therefore exact after warm-up
    (19.8 ms vs 1.2 ms vector arm at 10k rows, grows with N). Query plan not changed (per AC4) → follow-up F1.
  - [x] H3: custom plans, 20 queries, vs exact (`enable_indexscan=off`). Default ef_search=40: 40 rows unfiltered (20/20
    short), cs.CL 25% filter 9.8 rows (min 0), R@5 0.50. Shipped `SET LOCAL hnsw.ef_search=100; hnsw.iterative_scan=
    strict_order` (read-only tx in `fetchCandidates`): 50 rows always; R@5 1.00 unfiltered, 0.76 cs.CL, 1.00 cs.DL.
    ef_search 200 / 400 + strict_order: cs.CL R@5 0.83 / 0.88. Generic/auto: 50 rows, R@5 1.00 (exact). Test asserts query
    path + auto never returns fewer rows than exact. Lesson: first run (c851038) reused one generic plan built under
    `enable_indexscan=off` for every config; batches now start with `DISCARD PLANS`.
  - [ ] H4: not run: blocked on OPS-H1 (#14) `stack.yml`; post-merge evidence owed in `agents/reviews/OPS-H5/`.
  - [x] H5: `CONTRIBUTING.md` DB-schema bullet: migrate re-applies every `*.up.sql`, so migrations must be idempotent.
  - Follow-up F1 (needs Mahesh decision, recall vs p95): make HNSW apply after warm-up with `SET LOCAL plan_cache_mode =
    force_custom_plan` in `hnswSearchSettings` (1 line) and pick ef_search from the H3 table, or split the SQL by
    category filter. Follow-up F2 (ai-engineer): `scripts/evaluate_retrieval.py` (psycopg client-side binding) always
    gets custom plans at ef_search=40, so `make eval` measures neither production regime. Apply `hnswSearchSettings`.
  - Risk: `hnsw.iterative_scan` needs pgvector ≥ 0.8.0; compose image `pgvector/pgvector:pg16` is unpinned.
- 2026-11-03 QA r2 rework (backend-engineer, finding 1 + nit 9 only): head `d442c4c3c75bcce67d7ed2508822eed48a60ae2e`
  (PR #16 still draft; H3 line in the body updated with the three runs).
  - [x] Finding 1: `search_integration_test.go:160` now fails when the query path (`hnswSearchSettings`) returns fewer
    rows than the exact scan for any filter under **custom plans** (`DISCARD PLANS` + `force_custom_plan`), as well as auto.
    Fix `f69f340`: DB run 41708010366 / job 126168367800 **success** (custom: 50/50 rows, 0/20 short, all three filters).
    Mutant `d0e1123` (`hnswSearchSettings = ""`): DB run 41708319216 / job 126169467011 **failure**: `no category
    filter / query path / custom plan: 20 queries returned fewer rows than the exact scan` (cs.CL as well; cs.DL is exact
    under custom plans, so it can't fail there). Revert `d442c4c` (tree identical to `f69f340`): DB run 41708597979 /
    job 126170424459 **success**; CI run 41708597966 (Go, Python M0, Frontend, ownership) all success.
  - [x] Nit 9: `000002_*.up.sql` comment no longer says the params are "fixed by ADR-0008" (comment only; 000002 isn't merged yet).
  - Not taken (per instructions): F1/finding 3 (Mahesh), findings 2/6/7 (pm-lead), nits 4/5/8, F2.
