<!-- Saved verbatim by the orchestrator (cycle 2026-11-03 19:02Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/17#issuecomment-6613981061, because the QA harness could not write report.md. -->

[qa-reviewer] QA report — EVAL-5 · PR #17 · round 1

**Verdict: PASS**, with two explicit **merge gates** for Mahesh (Findings 1 and 2).
**Reviewed commit:** `557f4e12bbbb02b2dd3d6e28a7122af9ac460dbd` · 2026-11-03 · Ticket [EVAL-5](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/EVAL-5.md) · PRD: Product PRD §8, QA-2; ADR-0006, ADR-0010
Evidence pack: [agents/reviews/EVAL-5/evidence](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence) (commit `5419d05`). The harness wouldn't let me write `report.md`, so this comment is the report.

### Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 126147657013 | pass ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/00-ci-checks.png?raw=true),`` [01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/01-ci-job-logs.png?raw=true))``` |
| Python M0 unit tests | CI job 126147657540 | pass, `61 passed, 1 skipped` |
| Frontend | CI job 126147657411 | pass |
| Agent ownership | CI job 126147657276 | pass, `Ownership OK for role=ai (319 changed lines)` |
| `pytest -q tests/test_evals_data.py` | local | `58 passed, 1 skipped` ([02](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/02-local-pytest.png?raw=true))```` |
| `evaluate_retrieval.py --help` | local | ok, shows `--query-model` ([12](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/12-scope-help-merge.png?raw=true))````` |
| `make test-unit && make lint` | not run locally: no Go 1.25 or npm | CI green |
| Mutation checks (temporary, reverted, worktree clean) | local | 31 of 31 mutants caught |
| `make eval` | not run: no stack; no change to retrieval behaviour on a healthy stack | n/a |

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | Count mismatch raises `RerankError`. **M13** (catch in `rerank_pool`, fall back to RRF order): `5 failed`. Dropping the count check: `3 failed`. The `main --json-out` test asserts no JSON is written. [03](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/03-ac1-mutations.png?raw=true)`````` |
| AC2 | ✅ fake cursor (real DB: H3) | `chunk_coverage` plus warnings, gate unaffected. 5/5 mutants caught (incl. "gate fails on partial", `COUNT(*)`). [04](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/04-ac2-mutations.png?raw=true).``````` Supplementary PG16 run, with pgvector removed from the schema: [05](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/05-ac2-h3-pg16-substitute.png?raw=true)```````` |
| AC3 | ✅ | README paragraph is in the retrieval section (`evals/README.md:43`). `embedding_model` is kept. Warning tested; 2/2 mutants caught. [06](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/06-ac3-readme-mutations.png?raw=true)````````` |
| AC4 (a)(b)(c) | ✅ | All the ticket's edits fail the test on both sides (rename, `RerankPool` 25, vector arm ORDER BY+LIMIT dropped, `rrf_score ASC`, `LIMIT 40`). So do extra QA mutants: ORDER-BY-only drop (M16 shape), RRF k 61, arm `OR`→`AND`, `english`→`simple`, `<=>`→`<->`. 15/15. [09](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/09-ac4-parity-mutations.png?raw=true)`````````` |
| AC5 | ✅ | The only removed test lines are the `if os.path.exists(go):` skip (its asserts are kept unconditionally) and the extended `_FakeCursor.__init__`. No test function was removed; 9 were added. [10](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/10-ac5-ac6-no-weakening.png?raw=true)``````````` |
| AC6 | ✅ | 319 changed lines. [10](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/10-ac5-ac6-no-weakening.png?raw=true)```````````` |

### Mahesh's review checklist
| Item | Met? | Evidence |
|---|---|---|
| H1 Go default single source of truth | ✅ | `GO_DEFAULT_MODEL` removed. The default is parsed from `cmd/arxivlens/main.go:246`. Changing the Go default to `bge-large`: `1 failed`. Changing the Python default: `1 failed`. Removing the flag: `8 failed` (`ValueError`). [07](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/07-h1-go-default-mutations.png?raw=true)````````````` |
| H2 explicit override | ✅ | `--query-model` / `ARXIVLENS_QUERY_MODEL`, and `query_model` recorded. Tests cover default parity and the override (match, differ, env, CLI). 4/4 mutants caught (override ignored, env ignored, `main` not wiring it, field not recorded). [08](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/08-h2-override-mutations.png?raw=true).`````````````` Reporting the runtime model from the service is backend-owned and an API change, so it's a follow-up (Finding 5). |
| H3 `CHUNK_COUNTS_SQL` on real PG+pgvector | ⚠ **not run: merge gate** | Sandbox: `pgvector available: 0`, no `psycopg`. The opt-in test is skipped locally and in CI (no `DATABASE_URL`), so it has **never been executed**. Its INSERTs match the migration (checked by reading). QA ran the exact SQL on PG16 with the real migration minus pgvector: `full 2/2, part 1/2, zero 0/2`, other-model vector not counted. That is supplementary only, not the run you asked for. [11](```````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/11-h3-not-run.png?raw=true),``````````````` [05](````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/05-ac2-h3-pg16-substitute.png?raw=true)```````````````` |

### PRD fit
The change closes three silent-failure paths in the Recall@5 gate (rerank error, SQL drift, model mismatch) and makes
partly embedded papers visible. ADR-0006, ADR-0010 and the thresholds are unchanged.

### Findings
1. [nit][**merge gate**] **H3 not run.** Don't merge until `test_chunk_counts_sql_against_real_postgres` has run green on the real migrations with pgvector (in the OPS-H5 DB-backed job or a manual run with output attached), unless you waive it.
2. [**merge gate**] **Merge order with open PR #16 (OPS-H5).** The two PRs share no files, but #16 splits `search.go` into `vectorHitsSQL` + `hybridSearchSQL` constants. With #16's `search.go` on top of this head, `test_rrf_pool_sql_mirrors_search_go` fails with `HybridSearch querySQL not found exactly once` ([13](`````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/5419d05783f0a35fae5f3cf6d857173c29d3827a/agents/reviews/EVAL-5/evidence/13-cross-pr16-merge-order.png?raw=true)).````````````````` The guard is working as intended. Whichever PR merges second must be rebased on the first and CI re-run. If #16 lands first, this test's extraction (ai-engineer) needs an update before #17 can merge. #16's `main.go` change does **not** break the H1 parser.
3. [nit] `CHUNK_COUNTS_SQL` groups by `arxiv_id`, but `papers` is `UNIQUE (arxiv_id, version)`. With two versions stored, chunks are summed, which can cause a spurious partial warning. Warning-only, so this is a follow-up.
4. [nit] When no `--query-model` is given, the eval reads `cmd/arxivlens/main.go` at runtime and fails loudly outside a full checkout. A README sentence would help. There's also cosmetic PEP 8 blank-line spacing around the opt-in test.
5. [spec] Backlog item for pm-lead: the query service reports its runtime `--model` (`/healthz` or `/v1/info`). Backend-owned, HTTP API change, needs an ADR.
6. [spec] AC3's text ("differs from `BAAI/bge-base-en-v1.5`") is superseded by H2, which compares against the resolved query model. The ticket header still cites `910f2f8`.

### Missing tests
- A real-Postgres run of `CHUNK_COUNTS_SQL` (H3): the test exists but isn't wired to a DB job.
- Out of scope: `BM25_SQL` (ungated baseline) has no drift guard.

### Hand-off
PASS → pm-lead final review. Merge gates for Mahesh: H3, and the #16/#17 merge order.


---
_Generated by [Claude Code](https://claude.ai/code)_
