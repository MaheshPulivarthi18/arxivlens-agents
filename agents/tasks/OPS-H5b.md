# OPS-H5b: `TestHNSWVectorHits` cleans up its synthetic corpus and refuses a non-empty DB

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 (harness) |
| **PRD ref** | Technical PRD §11 harness/quality; follow-up from OPS-H5 QA nit 8 (`agents/reviews/OPS-H5/report.md:117`): "`TestHNSWVectorHits` seeds 1000 `synth.*` papers permanently into whatever `DATABASE_URL` points at, and it is likely not re-runnable on the same DB (`UNIQUE (arxiv_id, version)`). On a developer's real DB it would pollute search results." |
| **Depends on** | OPS-H5 (#16, merged `e67354c`). No open PR touches `internal/query/search_integration_test.go` (checked 2026-11-20 08:00Z against #65, #66, #68, #69, #70, #76, #77, #78, #79 via REST) |
| **Jira** | KAN-84 |
| **Design required** | no: test-only, no production code, contract, CLI, table or service change |
| **Status** | Done: ArxivLens #81 merged by Mahesh → `36ceac0` (2026-11-20 ~18:54Z) |

## Goal
`TestHNSWVectorHits` (`internal/query/search_integration_test.go:60`, build tag `integration`) inserts 1000 `synth.NNNNN` papers, 10,000
chunks and 13,000 embeddings into the real `papers`/`paper_chunks`/`chunk_embeddings` tables and never removes them. Its seed also
inserts chunks for **every** row in `papers` (`INSERT INTO paper_chunks … FROM papers p, generate_series(0, 9) k`), not just its own. So:
(1) a second run on the same DB fails on `UNIQUE (arxiv_id, version)`; (2) run against a developer's DB, it adds 1000 fake papers to real
search results and synthetic chunks to real papers. Make the test leave the DB as it found it and refuse to seed a DB that already holds
other papers. CI's numbers must not change.

## Scope
- File expected to change (and only this one): `internal/query/search_integration_test.go`.
- What to add:
  1. Before seeding, a helper (e.g. `itPrepare`) that deletes leftover `synth.%` papers from an earlier crashed run (FK `ON DELETE CASCADE`
     removes their chunks, embeddings and `paper_chunk_pages` rows, `migrations/000001_init_schema.up.sql:30,40,57`,
     `000003_paper_chunk_pages.up.sql:5`) and returns how many **other** papers remain.
  2. If other papers remain: `t.Skipf` with a message naming the count and why (the seed adds chunks to every paper; use an empty, migrated
     DB). When the env var `CI` is set (GitHub Actions sets `CI=true`), `t.Fatalf` instead, so a skip can never pass as green in `db.yml`.
  3. Cleanup after the test: delete `synth.%` papers, registered so it runs even when the test fails. Careful with ordering: today the
     test `defer`s `d.Close()` and `conn.Release()`, and `t.Cleanup` runs **after** the deferred calls. Use the pattern from
     `search_provenance_integration_test.go:32` (`t.Cleanup(d.Close)` registered first, so it runs last) or delete inside a `defer`
     registered after the others. Temp tables (`it_centers`, `it_scale`) are session-scoped and need no cleanup.
  4. A second test whose name starts with `TestHNSW`, so `db.yml`'s existing `-run 'TestHNSW|TestSearchProvenance'` picks it up without
     a workflow change, e.g. `TestHNSWSeedCleanup`. It's placed after `TestHNSWVectorHits` in the file, so it runs after it. It asserts:
     (a) first, before anything deletes rows: 0 `papers` rows `LIKE 'synth.%'` and 0 `paper_chunks` rows with
     `content LIKE 'synthetic chunk %'` remain;
     (b) a leftover row (insert `synth.99999`) is removed by the helper from item 1;
     (c) a foreign row (insert e.g. `hnswb.foreign`) makes the helper report 1 other paper.
     It deletes its own rows (`synth.99999`, `hnswb.%`) at the end, and its `hnswb.%` rows also at the start, after (a)
     (as `TestSearchProvenance` does with `prov.%`).
- Keep `itSeedSQL`, `itQueryVecSQL`, the configs, the assertions and all `RESULT`/`EXPLAIN` log lines unchanged.
- Out of scope: `db.yml` (open in #66), `search.go`, a scratch schema or rolled-back-transaction rewrite (bigger; not needed once the test
  refuses non-empty DBs), `search_provenance_integration_test.go`.

## Acceptance criteria
- [x] AC1: CI `db.yml` job `DB (migrate twice, HNSW plan + recall)` passes on the PR head. Step `HNSW plan + recall + search provenance
  (real search.go SQL)` shows `--- PASS: TestHNSWVectorHits`, `--- PASS: TestHNSWSeedCleanup` (or the name chosen) and
  `--- PASS: TestSearchProvenance`, with **no** `--- SKIP` for any of them. Quote the run ID and the three lines.
- [x] AC2: The seed is unchanged. The log line `pgvector 0.8.7; seeded 13000 embeddings in …` appears with the count `13000`, as on `main`
  `e6cffba` (run 44677459328, job 136092604706: `search_integration_test.go:87: pgvector 0.8.7; seeded 13000 embeddings in 24.474s`).
  The line number may move; the count may not. `RESULT` lines aren't compared (iterative-scan rows vary between runs of unchanged main).
- [x] AC3: Mutation, one per mutant. The developer pushes each as a temporary commit on the task branch and reverts it with a new commit
  (no force-push), as OPS-H5 did with `d0e1123`. Quote each red run's ID and the failing line:
  (a) remove the post-test cleanup (item 3) → `TestHNSWSeedCleanup` fails on assertion (a);
  (b) remove the leftover `DELETE` in the helper (item 1) → `TestHNSWSeedCleanup` fails on assertion (b);
  (c) make the helper always report 0 other papers → `TestHNSWSeedCleanup` fails on assertion (c).
  The final diff contains none of the mutants, and the last run is green.
- [x] AC4: The `CI` → `t.Fatalf` / otherwise `t.Skipf` branch (item 2) is in the diff and QA quotes it. It can't run in CI without a
  non-empty DB, so it's reviewed by reading.
- [x] AC5: Final diff is `internal/query/search_integration_test.go` only (`git diff --stat origin/main`), well under 400 lines.
  `gofmt -l internal/query/` is empty; `go vet -tags integration ./internal/query/` passes (the `db.yml` step runs it). CI `ci.yml` is green.
  The ownership check passes for role=backend.
- [x] Docs: the file's header comment (lines 3–9) says the test needs an **empty** migrated DB and cleans up after itself. No README or
  CONTRIBUTING change.

## Verification
```bash
gofmt -l internal/query/ && go vet -tags integration ./internal/query/
# local, only if a migrated pgvector >= 0.8 DB is available (not in agent sandboxes: no Docker daemon):
DATABASE_URL=postgres://... go test -tags integration -count=2 -v -run 'TestHNSW|TestSearchProvenance' ./internal/query/
.github/scripts/ownership-check.sh origin/main agent/backend/OPS-H5b
git diff --stat origin/main
gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/<db-job>/logs | grep -E 'seeded|--- (PASS|FAIL|SKIP)'
```
`-count=2` locally is the direct re-run check. In CI, `TestHNSWSeedCleanup` (a)+(b) stand in for it. `make eval`: not run, nothing in
retrieval or answering changes. `stack.yml` triggers on `internal/**` and must be green apart from the documented F1 step.

## Notes
- 2026-11-20 08:00Z (pm-lead): specced from the Backlog line "From OPS-H5, backend P2: `TestHNSWVectorHits` seeds into a scratch schema /
  skips when `papers` non-empty". I chose skip-when-non-empty plus cleanup over a scratch schema: the production constants
  (`vectorHitsSQL`, `hybridSearchSQL`) use unqualified table names, so a scratch schema would mean copying tables and the HNSW index and
  setting `search_path`, which is a bigger diff that would change what the test plans. Checked on app `origin/main` `e6cffba`: the seed
  reads `FROM papers p` for chunks (all papers), `UNIQUE (arxiv_id, version)` is in `000001_init_schema.up.sql:21`, and the only
  cleanup in the package is `TestSearchProvenance`'s `prov.%` delete. On a fresh CI DB nothing else is in `papers` when the test runs:
  #66's new real-Postgres eval-data step, which runs before it, rolls back its `eval5.*` rows (`tests/test_evals_data.py`
  `finally: conn.rollback()`).
- Independent of every open PR (#65 `internal/query/rag*.go`, `tests/test_evals_data.py`, `README.md`; #66 `db.yml`, `image-pins.yml`,
  `CONTRIBUTING.md`, `docker-compose.yml`; #68/#69/#70 `frontend/**` + root `README.md`; #76 `internal/kafka/consumer_test.go`; #77
  `tests/test_verify.py`; #78 `tests/test_m2_pipeline.py`; #79 `internal/llm/openai_test.go`) and of OPS-H15 (groomed in the same pass,
  `ci.yml` only; this file has the `integration` build tag, so `ci.yml`'s `go test ./...` doesn't compile it).
- 2026-11-20 08:30Z (backend-engineer): built on `agent/backend/OPS-H5b`, draft PR **#81**
  (https://github.com/MaheshPulivarthi18/ArxivLens/pull/81). Final head `8cae68b`; diff vs `origin/main` is
  `internal/query/search_integration_test.go | 100 +++-` (97+/3-) only; ownership check `OK for role=backend (100 changed lines)`;
  `gofmt -l internal/query/` empty. `go vet -tags integration` not run locally (Go 1.24.7, no module proxy); db.yml runs it (green).
  - What: `itPrepare(ctx, pool)` deletes `synth.%` and returns `count(*) … NOT LIKE 'synth.%'`; `TestHNSWVectorHits` registers
    `t.Cleanup(d.Close)` first, then `itPrepare` → `t.Fatalf` if `CI` set / `t.Skipf` otherwise when others > 0, then a `t.Cleanup`
    deleting `synth.%`. `TestHNSWSeedCleanup` (a)/(b)/(c) as specced; (c) asserts `others == base+1` (base = count after (b), 0 on CI),
    so it doesn't false-fail on a dev DB; on CI that is exactly "reports 1".
  - AC1/AC2 (final head, run 44702290490, DB job 136173317940): `search_integration_test.go:105: pgvector 0.8.7; seeded 13000 embeddings in 17.773s`,
    `--- PASS: TestHNSWVectorHits (27.19s)`, `--- PASS: TestHNSWSeedCleanup (0.02s)`, `--- PASS: TestSearchProvenance (0.07s)`, no SKIP.
    First head `3e1baea` also green (run 44700495052, job 136167400131, same three PASS, `seeded 13000`).
  - AC3 mutants (each pushed, then reverted with `git revert` commit, no force-push):
    (a) `d341c7a` remove post-test cleanup → run 44701014164 job 136169129675:
        `search_integration_test.go:287: (a) leftover corpus after TestHNSWVectorHits: 1000 synth.* papers, 10000 synthetic chunks; want 0, 0` → `--- FAIL: TestHNSWSeedCleanup`; reverted `55f5b38`.
    (b) `4ebca83` remove the DELETE in itPrepare → run 44701294532 job 136170052860:
        `search_integration_test.go:311: (b) itPrepare left 1 synth.* papers; want 0` → `--- FAIL: TestHNSWSeedCleanup`; reverted `49e266a`.
    (c) `b2cb615` itPrepare returns 0 → run 44702017953 job 136172426145:
        `search_integration_test.go:326: (c) itPrepare reported 0 other papers after inserting hnswb.foreign; want 1` → `--- FAIL: TestHNSWSeedCleanup`; reverted `8cae68b`.
    `git diff --stat 3e1baea` after each revert was empty.
  - AC5: ci.yml Go job 136173317186 (run 44702290628) success; ownership, frontend, Python M0 checks success. stack.yml Full stack job 136173363764 (run 44702290543) success (`AC4: make test-full` success; F1 step as documented).
- 2026-11-20 (pm-lead): **PM APPROVE r1** (`agents/reviews/OPS-H5b/report.md`, "PM decision — round 1"). All 13 evidence files opened, and each AC is
  proven (AC1 01, AC2 02, AC3 03+04, AC4 05 plus real-PG 06/07, AC5 08+09+00, Docs 10). The PR body was checked against the title, ticket and files:
  it is OPS-H5b's own. Base drift checked: #66 (`db.yml` eval-data step) rolls back its `eval5.*` rows, so the CI guard still sees an empty DB.
  QA nits 1+2 went to the board Backlog (backend P3, next change to this file); nits 3 and 4 were accepted with no action. PR #81 raised for Mahesh.
