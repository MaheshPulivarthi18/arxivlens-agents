# OPS-H5: Create the HNSW vector index in a migration, and apply all migrations in order

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | QA-1; Product PRD §8 `/v1/search` p95 < 1.5 s; Technical PRD §5 (HNSW gap note) |
| **Depends on** | — (soft: OPS-H1 for AC5; without it, start the workers by hand per AGENTS.md §6) |
| **Jira** | find with JQL `labels = "task-OPS-H5"` |
| **Design required** | no (P1; additive index migration, no new command/table/service; `migrate` keeps its existing flag) |
| **Status** | In QA (draft PR #16) |

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
