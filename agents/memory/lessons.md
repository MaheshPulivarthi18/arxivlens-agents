# Lessons

Short rules learned from friction. Loaded every session, so keep it under ~60 lines.
Format: `- [YYYY-MM-DD][TASK-ID] what happened → rule for next time (seen N×)`
A lesson seen ≥ 2× gets promoted into `AGENTS.md` or an agent definition via a `retro:` PR, then removed here.

## All agents
- [2026-11-01][SETUP] Local Go toolchains older than 1.25 try to download 1.25 and fail offline → use CI or `GOTOOLCHAIN=local` only for quick checks; never downgrade `go.mod`. (seen 1×)
- [2026-11-01][SETUP] PRD status columns can lag the code (UI-5 per-citation BibTeX already exists in `ReferencesStack.jsx`) → grep the code before assuming a ⏳ feature is missing. (seen 1×)
- [2026-11-02][SPRINT] Four commits were pushed with a Claude-Session trailer copied from an older commit → take attribution trailers from the current session's instructions, never from git history. (seen 1×)
- [2026-11-01][SPRINT] Agent sandbox egress blocked the Go 1.25 toolchain/modules, npm, Docker Hub and Hugging Face → check which tasks the environment can verify before picking them; prefer Python/docs tasks there and state that Go/frontend checks rely on CI. Go unit-test tasks are fine (CI runs Go 1.25); npm-dependency and Docker tasks are not. Never route around egress blocks. (seen 2× — promote via retro PR)
- [2026-11-01][SPRINT] Builder subagents edited board/PROGRESS during the build step, which collides with the separate record branch → tell builders to touch only their task spec under agents/. (seen 1×)


## pm-lead
- [2026-11-01][PM-1] A PRD edit quietly added a policy (which machine gates latency) → anything that changes what a gate or threshold means must be labelled Proposed or go into an ADR. (seen 1×)
- [2026-11-01][PM-1] `migrations/` didn't match the PRD data model (no HNSW index) and "Recall@5" computes something closer to precision@5 → grep migrations and the metric code, not just names. (seen 2×: OPS-H3 spec described a backoff schedule and old-style ID support the code doesn't have)
- [2026-11-02][EVAL-1] PM APPROVEd a gate whose gated metric's meaning depended on a still-Proposed ADR (0006); Mahesh's review sent it back → never APPROVE work whose gate semantics wait on a Proposed ADR; mark it Blocked (needs ADR) instead. (seen 1×)
- [2026-11-03][RET-1] An AC allowed "not run: infra unavailable" for a measurement an Accepted ADR depends on (p95 for pool 20), so it would have floated with no owner → when you accept a deferred measurement, attach it as a numbered AC on an existing task with a stop-and-report rule, and say in the PR where it went. (seen 1×)
- [2026-11-03][AI-1] AC2 said "coverage of `rag.go` ≥ 80% (`go test -cover`, paste number)", but `-cover` prints a package-wide figure (68.1% or 52.5% depending on which files are compiled, against a real 97.9% for `rag.go`) and CI prints no coverage at all → in a per-file coverage AC, name the exact measurement: `go test -coverprofile=c.out ./<pkg>/ && go tool cover -func=c.out | grep <file>` (paste the file rows), and say whether a scratch or local run is acceptable when CI doesn't print it. (seen 1×)
- [2026-11-03][OPS-H4] AC4 limited the diff to `.gitignore` + `Makefile`, so the dev couldn't update `CONTRIBUTING.md`/`README.md` for the changed `make test-unit` command and PM had to send it back (DoD 4) → when a ticket changes a command or its output, list the README/CONTRIBUTING lines to update in Scope, and never write a file-whitelist AC that excludes them. (seen 1×)

- [2026-11-03][OPS-H6] PRD OPS-1 ✅ and Technical PRD §8.1 L4 ("all consumers commit only after success or DLQ") were false in both Go and Python consumers; only an external review caught it → when marking a reliability row ✅, read the failure branch (what happens when the DLQ write / commit itself fails), not just the happy path. (seen 1×)
- [2026-11-03][ING-8] A requested task ID (ING-7) collided with an existing Product PRD row ID with a different meaning → before creating a task ID in a series that mirrors PRD rows (ING, QA, OPS), grep the PRD tables for it. (seen 1×)
- [2026-11-07][PLAN] Planning parallel waves, the file-overlap rule caught `README.md` (EVAL-3 Testing line vs AI-7 API row) and `tests/test_evals_data.py` (EVAL-6 vs RET-2's parity list), and the API contract caught claim fields ADR-0003 didn't cover → when picking parallel tasks, list every shared doc/test file (README, CONTRIBUTING, test_evals_data.py, rag.go) per task and move or sequence edits; check each new response field against the Accepted ADR's exact wording. (seen 1×)

- [2026-11-07][LLM-1] A design's diff-size estimate (~380 prod) was 72% low (655), and I'd already granted a size exception on that estimate → when a design is near the 400 target, ask for a counted skeleton (`wc -l` of the stubbed files plus doc comments) before approving, and name the split seam in the PM decision up front. (seen 1×)
- [2026-11-07][EVAL-6] QA proposed widening an expensive workflow's triggers to satisfy a DoD item → check the cost of a trigger (external requests, runtime) before accepting; a manual `workflow_dispatch` on the branch often meets the DoD item without the cost. (seen 1×)

## ai-engineer
- [2026-11-01][SETUP] Eval queries are hardcoded inside `scripts/evaluate_retrieval.py` → don't add more there; EVAL-1 moves them to `evals/`. (seen 1×)
- [2026-11-01][EVAL-1] The first gate draft let failed /v1/ask calls drop out of the gated metrics, so a dead service could PASS → eval gates must fail closed: count errors, put failures into latency (timeouts at ≥ timeout), and add a test where some requests fail. (seen 1×)
- [2026-11-02][EVAL-1] Calling the production rerank endpoint still didn't measure production, because `/v1/ask` never orders by the rerank score → when a gate claims to measure "the production path", trace the whole path (candidate pool, filters, ordering), not just the model call. (seen 1×)
- [2026-11-02][EVAL-1] When copying production SQL into the eval, copy it literally: the round-2 eval's vector CTE had `LIMIT` with no `ORDER BY`, so it returned arbitrary rows. Add a test that reads the Go source and asserts the mirrored fragments, so drift fails CI. (seen 1×)

- [2026-11-03][AI-1] Go 1.25 unavailable locally → run the real files in a stdlib-only scratch module (stub non-stdlib imports, `GOTOOLCHAIN=local GOPROXY=off`) for vet/test/per-file coverage; CI stays the source of truth. (seen 3×: OPS-H3, AI-1, AI-3)
- [2026-11-03][AI-3] To prove a refactor (e.g. batching) keeps results, keep the old algorithm as a per-item reference helper in the test and compare outputs, then run the new tests against the old file from git as the mutation check. (seen 1×)
- [2026-11-03][ING-8] A dataset task needing hand labels from external sources (arXiv PDFs, licence pages) can't be finished in a sandbox without that host → ship the scorer + rule validator unit-tested on fixtures, let the real-dataset test skip with an explicit "AC NOT met" reason, and never write labels from memory. Specs that need external labelling should name who labels and where. (seen 1×)

## backend-engineer
- [2026-11-03][OPS-H6] Under a mutation, a test that indexes a result slice (`f.payloads[2]`) panicked, and the panic stopped every later test in the package → in tests, guard indexes (`len(x) != n ||`, `x[:min(n, len(x))]`) so a mutant fails assertions instead. (seen 1×)
- [2026-11-03][OPS-H6] `git revert … -q` is not a valid option; with `;` chaining, the following `commit --amend` renamed an already-pushed commit (the push was rejected, so nothing was lost) → chain revert/amend steps with `&&` and check the tree with `git diff --quiet <base> HEAD`, not `--stat`. (seen 1×)
- [2026-11-03][OPS-H6] Extracting a loop body into a function re-indents every line, so the diff doubled (~570 vs 392). To stay under 400, keep changed code at its original indentation (for example a labelled `break`) and record the shape change in the design. (seen 1×)
- [2026-11-03][OPS-H1] When a registry pull fails in CI, read the status code before picking the next reference. quay.io answers anonymous requests with `401 UNAUTHORIZED` for a missing or private *repo* (a missing tag is 404), and Docker Hub's "repository does not exist" covers the whole repo. A different tag in the same repo won't help, so spend the limited attempts on a different repo or registry. (seen 1×)

- [2026-11-03][OPS-H5] When measuring a pgx query under different `SET LOCAL` settings on one connection, PostgreSQL reused the generic plan cached after 5 runs (built under `enable_indexscan=off`), so every config looked exact (recall 1.0) → `DISCARD PLANS` before each batch, measure `force_custom_plan`/`force_generic_plan`/auto separately, and read `pg_prepared_statements.generic_plans`. The same mechanism means production pgx queries can silently bypass an index after warm-up. (seen 1×)
- [2026-11-03][OPS-H1] A Docker healthcheck that only exits non-zero gave a 15-min "unhealthy" with no reason in any log. Print the probe's view to stdout and have the wait loop dump `docker inspect -f '{{json .State.Health}}'` on failure: the first run that did showed `TimeoutError` at line 5 (describe_consumer_groups hanging). Make the harness's first failing run diagnostic, not just red. (seen 1×)
- [2026-11-03][OPS-H1] For "is this process a consumer-group member", a worker-local heartbeat (touched after each poll while `assignment()` is non-empty, kept on a tmpfs so restarts start clean) is deterministic and testable without a broker; client-side admin APIs can hang on some broker/client version pairs. In CI, count members with the broker's own `kafka-consumer-groups.sh --members`. (seen 1×)
- [2026-11-07][OPS-H1] An unquoted `$VAR` I left for word-splitting in a workflow `run:` block failed stack.yml's actionlint step (shellcheck SC2086) and used one of the 2 CI attempts. The sandbox has no shellcheck/actionlint → in `run:` blocks, split lists with `read -ra arr <<< "$VAR"` and `"${arr[@]}"`; never rely on unquoted expansion. (seen 1×)

## frontend-engineer

## qa-reviewer
- [2026-11-02][EVAL-1] Round-1 QA passed a gate whose PRD metric definition was pending ADR-0006 (flagged only as [spec]) → a gated metric that doesn't match the PRD definition is [blocking] until the ADR is Accepted. (seen 1×)
- [2026-11-02][EVAL-1] A SQL "parity" test built from substring asserts passed with the vector arm's `ORDER BY … LIMIT` removed, because the same text sits inside `ROW_NUMBER() OVER (ORDER BY …)` → to check SQL mirroring, diff the normalised query text against the source of truth (QA r3 evidence 307) and mutate the ORDER BY/LIMIT clauses specifically. (seen 1×)
- [2026-11-03][OPS-H5] A DB test's only guard ran in `plan_cache_mode=auto`, which the CI log showed was 100% generic plans, so the HNSW settings it claimed to guard never executed. Read the logged plan counts and modes to confirm the guarded branch really ran the feature before you accept an assertion as a regression test. (seen 1×)
- [2026-11-03][OPS-H5] Two PRs with no shared files still conflicted: #17's test parsed a Go identifier (`querySQL :=`) that #16 renamed. For open PRs whose tests read source files (drift/parity guards), run their tests against this PR's version of those files. (seen 1×)
