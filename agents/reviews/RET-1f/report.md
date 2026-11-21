# QA report — RET-1f · PR #116 · round 1

**Verdict:** PASS
**Reviewed commit:** `14346e4a23ad46694c70cd0771267939ceba2f4f` (CI ran on merge `5f2730b` = head into main `11c4696`, the current main) · **Date:** 2026-11-21
**Ticket:** `agents/tasks/RET-1f.md` (KAN-122) · **PRD:** Technical PRD §10, §7.1 (rerank fallback); Product PRD QA-5 as cited (see finding 1)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136902192402 | pass (`make lint-go`, `make test-go` with `GOFLAGS: -race`, `ok arxivlens/internal/query`) [09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/09-ci-go-job.png) |
| DB (migrate twice, HNSW plan + recall) | CI job 136902191826 | pass; `--- PASS: TestHNSWVectorHits (41.03s)`, 9/9 `TestHNSWGuard` subtests PASS [10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/10-ci-db-job.png) |
| Python M0 unit tests | CI | pass |
| Frontend (lint, test, build) | CI | pass |
| Agent ownership check | CI + local | pass; local `ownership-check.sh`: `Ownership OK for role=backend (126 changed lines)` [01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/01-scope.png) |
| Full stack (compose + make test-full) | CI job 136902191998 | pass (completed 16:20:20Z) [00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/00-ci-checks.png) |
| Ticket verification commands | local (Go 1.25.1, git archive of the head + `replace` to tag-pinned GitHub clones of the real pgx/minio deps; [07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/07-harness-source.png)) | `-run 'HNSWGuard|RerankFallback'` pass with `-race` [02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/02-ac1-guard-table.png) [04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/04-ac3-rerank-rows.png); `go vet` (default + integration tags) clean, `gofmt -l` empty, `go test -race ./internal/query/ ./internal/db/` ok [08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/08-ac5-local-tests.png). `cmd/`, `telemetry` and Python/frontend not run locally (otel modules, npm, torch unavailable offline): CI covers them |
| `make eval` | not run | test-only change; `search.go` untouched (diff lists only the two test files) |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 guard table, no `DATABASE_URL` | ✅ | `TestHNSWGuard` is a 9-row table others {0,1,5} × CI {"", "true", "1"} via `guardRecorder` (embeds `testing.TB`, records `Fatalf`/`Skipf` and also `Fatal`/`Skip`/`FailNow`/`SkipNow`). Asserts exact counts, "no other call", the count and "use an empty, migrated DB" in each message. Local run with `DATABASE_URL` unset: 9/9 PASS [02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/02-ac1-guard-table.png); CI DB job 9/9 PASS [10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/10-ci-db-job.png). Mutants q3-q7 (double Fatalf, Fatal instead of Fatalf, Logf instead of Skipf, message text, wrong count) all KILLED [05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/05-ac4-mutants-summary.png) |
| AC2 one-statement call site | ✅ | `search_integration_test.go:77`: `applyHNSWGuard(t, others, os.Getenv("CI"))`, the only non-definition call besides the test's; the old 7-line `if skip, fatal := …` block removed [03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/03-ac2-call-site.png) |
| AC3 rerank rows | ✅ | (a) `"NaN at 2, +Inf at 3"` → `reason="NaN score"`, (b) `"+Inf at 2, NaN at 3"` → `reason="Inf score"` in `TestHybridSearchRerankFallback` (each row also checks RRF top-5, RerankScore 0, JSON encodes, trace id, no leak); (c) `TestHybridSearchRerankLargeFiniteScores`: ±MaxFloat32 → no "rerank fallback" log, 20 hits starting [3 2 4 5 6 1] (I re-derived the fused keys with FusionK=10: c3 .168, c1 1/11+1/30 = .124 > c7 .121, matching the comment), every RerankScore equals the scripted score, `json.Marshal` ok. All PASS with `-race` [04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/04-ac3-rerank-rows.png) |
| AC4 mutation check | ✅ | Local, in fresh copies, never pushed [05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/05-ac4-mutants-summary.png) [06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/06-ac4-mutants-detail.png): c1 (`others == 0 || ciEnv == ""` early return), c2 (swap Fatalf/Skipf branches), c3 (`ciEnv == ""`) KILLED by TestHNSWGuard in both the package run and `-run '^TestHNSWGuard$'`; m4 (Inf check before NaN) SURVIVED as the ticket expects; m5 (`math.Abs(…) >= math.MaxFloat32`) KILLED by `TestHybridSearchRerankLargeFiniteScores` (`unexpected fallback … reason="Inf score"`). Extra: q9/q10 (drop the `break` after NaN / Inf, so the last non-finite score wins) KILLED by the new rows (a)/(b). Base controls: main's tests vs m5, q9, q10 all SURVIVE (b5/b9/b10), so the new rows are what kill them |
| AC5 existing tests pass, two files only | ✅ | `git diff origin/main --name-only` = exactly the two test files [01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/01-scope.png); CI `go test ./...` all ok with `-race` [09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/09-ci-go-job.png); Python, frontend and full stack green [00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/00-ci-checks.png) |
| AC6 CI Go + DB green, VectorHits PASS not SKIP | ✅ | Both jobs `head_sha=14346e4…` success; DB log line 1645 `--- PASS: TestHNSWVectorHits (41.03s)`, no `--- SKIP`/`--- FAIL` lines in the extract [10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/10-ci-db-job.png) |

## PRD fit
Test-only hardening of the reliability guard on the HNSW integration test (Technical PRD §10) and of the rerank fallback rule in §7.1 (first non-finite score by position names the reason; large finite scores are kept and JSON-encodable). No product behaviour changes, no contract or threshold touched.

## Findings
1. [spec] The ticket's PRD ref "Product PRD QA-5 (rerank fallback)" points at the wrong row: QA-5 is "Refuse cleanly when no passage passes the relevance bar"; reranking is QA-2. Also, Technical PRD §7.1's diagram note still says "On rerank error, wrong score count or NaN"; the ±Inf fallback (RET-1b, `search.go` doc comment) and the ticket's "`NaN or ±Inf`" quote are not in the PRD text. For pm-lead: fix the ref and update §7.1 via a docs PR. Not blocking this PR.
2. [nit] Residual, by design: mutant q8 (call site passes `""` instead of `os.Getenv("CI")`) or deleting the call survives everything except a DB job run against a *dirty* DB, which CI never runs. AC2's one-statement form makes this visible in review; no unit test can reach it without a DB. Recorded so nobody reads AC1 as covering the call site's argument.
3. [nit] PR title and heading say "`hnswGuard` owns …", but the function is now `applyHNSWGuard` (wording inherited from the ticket title).

## Missing tests
- None required by the ticket. Optional: a row with NaN or Inf at rank 1 (first position) would pin the loop's start index; today rank 3 / rank 2 rows plus q9/q10 already pin "first by position".

## Evidence
| File | What |
|---|---|
| [00-ci-checks](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/00-ci-checks.png) | all 6 check runs on 14346e4 completed success; PR open, draft |
| [01-scope](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/01-scope.png) | name-only diff, stat, ownership script |
| [02-ac1-guard-table](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/02-ac1-guard-table.png) | local `TestHNSWGuard` -race, no DATABASE_URL |
| [03-ac2-call-site](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/03-ac2-call-site.png) | call site + diff hunk |
| [04-ac3-rerank-rows](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/04-ac3-rerank-rows.png) | local rerank rows -race |
| [05-ac4-mutants-summary](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/05-ac4-mutants-summary.png) | 20-row mutant table |
| [06-ac4-mutants-detail](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/06-ac4-mutants-detail.png) | each mutant's diff + failing lines |
| [07-harness-source](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/07-harness-source.png) | harness source, replaces, dependency tags |
| [08-ac5-local-tests](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/08-ac5-local-tests.png) | vet, gofmt, package tests |
| [09-ci-go-job](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/09-ci-go-job.png) | CI Go job extract |
| [10-ci-db-job](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0988131/agents/reviews/RET-1f/evidence/10-ci-db-job.png) | CI DB job extract |

Not done by QA: Jira KAN-122 comment/transition (no Jira tool in this QA session; orchestrator to post the verdict and evidence links).

## Hand-off
PASS → pm-lead final review.
