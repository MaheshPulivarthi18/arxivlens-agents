<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/97#issuecomment-7049892934 (QA harness could not write report.md); role tag and footer removed. -->

**QA report: OPS-H5c · PR #97 · round 1**

**Verdict: PASS**
**Reviewed commit:** `1d696c724a45d6e3c98495149c3bd7f7e86cae52` (CI merge `a0efbe7` = head + main `230f617`) · **Date:** 2026-11-21
**Ticket:** [agents/tasks/OPS-H5c.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/OPS-H5c.md) · **PRD:** Technical PRD §11 harness/quality · **Evidence:** [agents/reviews/OPS-H5c/evidence](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136544831672 | pass ([05](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/05-ac6-go-job.png ``)) |
| DB (migrate twice, HNSW plan + recall) | CI job 136544832975, run 44810300602 | pass: vet + `TestHNSW*` all `--- PASS`, 0 SKIP, 0 FAIL ([02](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/02-ac1-ac4-db-job.png ```)) |
| Full stack, Python M0, Frontend, Ownership | CI | all pass ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/00-ci-checks.png)) |
| Ticket verification commands | local, partly | The real package can't compile here (Go 1.24, no module cache), so vet and the DB run rely on CI. A standalone harness extracts the **real** `hnswGuard` + `TestHNSWGuard` from HEAD into a go1.24 scratch module: the test passes, 10/10 guard mutants are killed, the old-vs-new refusal block differential is identical, and the (a) message renders the exact SQL ([03](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/03-ac2-ac3-ac5-harness.png), ```` source [04](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/04-harness-source.png `````)). The diff is exactly 1 file ([01](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/01-scope-diff.png ``````)). |
| `make eval` | not run: test-only change | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: the 4 required rows + others=5 | ✅ | `TestHNSWGuard` (`:277-296`) has 6 rows. CI shows `--- PASS` for all 6 subtests ([02](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/02-ac1-ac4-db-job.png ```````)). It needs no DB. There's no name collision in package `query`. |
| AC2: helper used; same `why`, Fatalf/CI, Skipf otherwise; `others` from `itPrepare` | ✅ | `:77` calls `hnswGuard(others, os.Getenv("CI") != "")`; the `why` const is unchanged. Main's `:77-83` block and head's `:77-83` block give identical outcomes and messages across others∈{0,1,5} × CI∈{unset,true} ([03](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/03-ac2-ac3-ac5-harness.png) ```````` §3). |
| AC3: exact SQL in the (a) message; condition unchanged | ✅ | The rendered message ends `…; on a dev DB seeded before OPS-H5b run: DELETE FROM paper_chunks WHERE content LIKE 'synthetic chunk %'` (`%%` in the format, "exact SQL present: YES"). The condition line is byte-identical to main ([03](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/03-ac2-ac3-ac5-harness.png) ````````` §4). |
| AC4: db.yml green, `--- PASS` lines, vet | ✅ | Job 136544832975 (run 44810300602, head_sha 1d696c7): `20:21:01.7406516Z --- PASS: TestHNSWVectorHits (37.37s)`, `20:21:01.7409560Z --- PASS: TestHNSWGuard (0.00s)`, `20:21:01.7545535Z --- PASS: TestHNSWSeedCleanup (0.02s)`, `ok arxivlens/internal/query 37.418s`. The same step runs `go vet -tags integration ./internal/query/` ([02](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/02-ac1-ac4-db-job.png ``````````)). |
| AC5: mutants m1–m4 | ✅ (QA-run) | m1 killed by `others={1,5}/ci=true`, m2 by `others=1/*`, m3 by all 4 non-zero rows, m4 by `others={1,5}/ci=false`. 6 extra single-operand mutants are all killed; build failures would count as INVALID ([03](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/03-ac2-ac3-ac5-harness.png) ``````````` §2). |
| AC6: Go unit/lint CI green | ✅ | `make lint-go`, `make test-go` and `make build-go` on 1d696c7, success ([05](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/05-ac6-go-job.png ````````````)). |
| Docs: none | ✅ | No doc files changed. |

## PRD fit
The non-empty-DB refusal branch keeps a skip from passing as green in `db.yml`, and it now has a CI-run table test. A developer with a dev DB seeded before OPS-H5b gets the exact cleanup SQL. No product behaviour, contract, schema or gate changed.

## Findings
1. [nit] The call site at `:77-83` is still untested. Three single-edit mutants survive `TestHNSWGuard` and can't be reached by the always-empty CI DB: c1 `fatal || skip` → `fatal || skip && false`, c2 `if fatal` → `if skip`, c3 `CI != ""` → `== ""`. The QA differential catches them ([03](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ed872a89592d7c296f6310696e7b533a9e8d05c9/agents/reviews/OPS-H5c/evidence/03-ac2-ac3-ac5-harness.png) ````````````` §3b), but no committed test does. This is within the ticket's chosen design and doesn't block. If you want to close it later, have the helper return a single action/message so the call site holds no boolean logic.
2. [nit] AC5 asks the developer to report the mutation output in the ticket Notes. `agents/tasks/OPS-H5c.md` on main has no developer entry yet. QA's own run covers the AC.
3. [spec] none.

## Missing tests
- Call-site wiring of `hnswGuard` in `TestHNSWVectorHits` (finding 1).

## Scope / regression
Exactly `internal/query/search_integration_test.go` (+35/−3), still `//go:build integration`. Nothing out of scope was touched. File order VectorHits → Guard → SeedCleanup is preserved: the pure test changes no DB state. No contracts, thresholds or invariants are affected.

## Hand-off
PASS → pm-lead final review.


