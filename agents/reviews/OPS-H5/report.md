<!-- Saved verbatim by the orchestrator (cycle 2026-11-03 19:02Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/16#issuecomment-6609319483, because the QA harness could not write report.md. -->

[qa-reviewer] **QA report: OPS-H5 · PR #16 · round 1**

**Verdict: PASS.** AC1, AC2, AC4 and AC5 are deferred to post-merge evidence, which the spec allows.
**Reviewed commit:** `47e845186d0bc2d6dc6731a5306e8d9994a95bcb` (base `9c1229a`) · 2026-11-03
**Ticket:** [agents/tasks/OPS-H5.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/OPS-H5.md) · **PRD:** QA-1, Product PRD §8 (`/v1/search` p95), Technical PRD §5 (HNSW gap)
**Evidence:** [agents/reviews/OPS-H5/evidence @ fdca888](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence)

### Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 126040678034 (merge `8968572` of 47e8451 into 9c1229a) | pass: `ok arxivlens/internal/db 0.008s`, `make lint-go` and `make build-go` green ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/00-ci-checks.png?raw=true),`` [01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/01-ac3-ci-go-job.png?raw=true))``` |
| Python M0 / Frontend | CI 126040678985 / 126040678656 | pass / pass |
| Agent ownership check | CI 126040678981 | pass: `Ownership OK for role=backend (163 changed lines)` ([07](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/07-ownership-ci.png?raw=true))```` |
| `make test-unit` / `make lint` locally | not run locally: needs Go 1.25, sandbox has 1.24.7 and no module proxy. I ran an isolated module instead: `MigrationFiles` extracted verbatim with sed, plus the PR's `db_test.go` and `migrations/`. go vet OK, 6/6 tests PASS ([02](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/02-ac3-local-isolated-test.png?raw=true)).````` `gofmt -l cmd internal` is empty ([05](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/05-scope-check.png?raw=true))`````` |
| Mutation tests on `MigrationFiles` | local, isolated | 4/4 non-equivalent mutants killed ([03](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/03-ac3-mutation-tests.png?raw=true))``````` |
| `make migrate` ×2, `pg_indexes`, `EXPLAIN`, `make test-full` | not run: infra unavailable (no Docker or Postgres) | owed post-merge, per spec |
| `make eval` | not run: needs the stack | see finding 3 |

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: fresh `make migrate` creates `chunk_embeddings_hnsw_idx` | ⚠ deferred (allowed; owed from OPS-H1 `stack.yml`) | Static check only ([04](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/04-ac1-ac2-static-migration-check.png?raw=true)).```````` `000002` matches the spec's required statement exactly, and it matches `scripts/benchmark_hnsw.py:32-35`. `TestRepoMigrationsOrder` puts it after 000001. `make migrate` runs plain `./bin/arxivlens migrate` (Makefile:64, unchanged here and in #14), so the new `--dir migrations` default applies. |
| AC2: `make migrate` twice | ⚠ deferred (allowed) | Every DDL statement in both up migrations is `IF NOT EXISTS`, and `000001_*` is untouched ([04](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/04-ac1-ac2-static-migration-check.png?raw=true)).````````` |
| AC3: Go unit test, `*.up.sql` only, lexical order, no DB | ✅ | `TestMigrationFiles` (4 table cases), `TestMigrationFilesMissingDir`, `TestRepoMigrationsOrder`. CI `ok arxivlens/internal/db` ([01](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/01-ac3-ci-go-job.png?raw=true)).`````````` Local isolated PASS ([02](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/02-ac3-local-isolated-test.png?raw=true)).``````````` Mutants killed: `.up.sql`→`.sql`, dropped `IsDir` check, dropped empty-dir error, reversed sort. Removing `sort.Strings` survives, but that mutant is equivalent because `os.ReadDir` already returns entries sorted by name ([03](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/03-ac3-mutation-tests.png?raw=true)).```````````` |
| AC4: `EXPLAIN` of the vector CTE | ⚠ deferred (allowed) | Not run. The PR names the risk for the `vector_hits` CTE ([06](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/06-ac4-vector-cte.png?raw=true)):````````````` window `ORDER BY <=>`, two joins, and `model`/`categories` filters. |
| AC5: `make test-full` M1 + M5/M6 without the benchmark | ⚠ deferred | "not run: infra unavailable", with exact commands in the PR body, as the spec requires. |

### Scope
- 6 files, +156/−7, all inside backend paths and the ticket's file list ([05](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fdca888b1a0ca79a5b7b1f3c5568da80dc77b11d/agents/reviews/OPS-H5/evidence/05-scope-check.png?raw=true)).``````````````
- Not touched: `Makefile`, `CONTRIBUTING.md`, compose, `.github/`, `000001_*`, the benchmark script, query SQL.
- README changes only line 166.
- No overlap with open PRs #13, #14 or #15.
- CLI shape matches the pm-lead decision: `--dir` defaults to `migrations`; `--file` defaults to empty and, when set, applies only that file.

### PRD fit
This closes the Technical PRD §5 gap: a fresh `make migrate` now builds the HNSW cosine index that QA-1 and the `/v1/search` p95 NFR rely on, and the migration runner now applies future migrations. Whether search actually gets faster depends on the planner using the index, which AC4's post-merge EXPLAIN must show.

### Findings
1. [nit] `migrations/000002_chunk_embeddings_hnsw.up.sql:3` says "Params are fixed by ADR-0008". ADR-0008 is *Proposed*, and it defers the at-scale params decision; it doesn't fix them. Suggested wording: "Params unchanged (pgvector defaults); revisiting them waits on ADR-0008."
2. [nit] The `--file`/`--dir` selection branch in `newMigrateCmd` has no test. It is three lines and the spec only asks for the pure function to be tested, so this is not blocking. Passing both flags silently ignores `--dir`; the `Long` help text documents this.
3. [spec] Retrieval risk for pm-lead. Once the planner uses the index, a pgvector HNSW scan returns at most `hnsw.ef_search` candidates (default 40; nothing in `internal/` sets it). Those candidates are then filtered by `ce.model` and `p.categories`, and `pgvector/pgvector:pg16` leaves iterative scans off by default. The vector arm can therefore return fewer than its `LIMIT 50`, far fewer with a category filter, and Recall@5 could move. The PR's `make eval` reason ("logic not touched") understates this, but the risk is disclosed. Request: add a post-merge `make eval` (Recall@5 against `evals/thresholds.json`) to the owed post-merge evidence, next to the AC4 EXPLAIN. Treat a drop below threshold as the same stop-and-report trigger as AC1/AC2.
4. [spec] AC1, AC2, AC4 and AC5 are owed as post-merge evidence from the first OPS-H1 `stack.yml` run with this migration, filed in `agents/reviews/OPS-H5/`. #14's workflow runs `make migrate` only once, so AC2 still needs an explicit second run.
5. [nit] `CREATE INDEX` without `CONCURRENTLY` blocks writes to `chunk_embeddings` while it builds. This only matters on an existing populated DB where the benchmark never ran. It is fine at the current corpus size, so I'm noting it for ops rather than asking for a change.

### Missing tests
- None blocking.
- An optional CLI-level test that `--file` bypasses `MigrationFiles`.
- The DB-level checks are covered by the deferred ACs.

### Hand-off
PASS → pm-lead final review. The post-merge evidence in findings 3 and 4 is still owed before OPS-H1 is raised.


---
_Generated by [Claude Code](https://claude.ai/code)_
