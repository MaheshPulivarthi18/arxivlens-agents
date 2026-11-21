> Provenance: saved verbatim by the orchestrator (cycle 2026-11-21T05:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/105#issuecomment-7058287268 (QA harness refuses to write report.md).

[qa-reviewer] QA report: RET-1e · PR #105 · round 1

**Verdict: PENDING**
**Reviewed commit:** `7d634963c128d74b496c3abca6ad13a79f5fafb3` · **Date:** 2026-11-21
**Ticket:** [agents/tasks/RET-1e.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/tasks/RET-1e.md) (Jira KAN-99) · **PRD:** Product PRD §7 (principle 2: a failure must not look like a success); Technical PRD §7 (query API); follow-up from RET-1d QA (mutants q2, e2, e3)
**Evidence pack:** [agents/reviews/RET-1e/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence) @ `7a4a313`
_Provenance: the QA harness refused to write `agents/reviews/RET-1e/report.md` ("subagents return findings as text"), so this comment is the full report. The orchestrator saves it verbatim._

## Summary
AC1, AC2 and AC3 are proven by real **Go 1.25.1** runs at the PR head. All 24 `server.go` mutants are KILLED, each by the row it targets, and in a base control the 5 AC3 mutants SURVIVE on main's test file. **AC4 is not met yet.** Five CI jobs are green, but **Full stack** is red on both attempts of run 44870494789. Both times it failed in `Prefetch arXiv responses into the replay store`: arXiv answered `429` for `id_list=2608.20331`, and every test step was skipped. Nothing in the code caused this, so the verdict is PENDING (re-run the job, then re-review), not FAIL.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136743697877 (merge `794ba27` = 7d63496 into main `11c4696`) | pass: `make lint-go`, `make test-go` (-race), `ok arxivlens/internal/query` ([05](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/05-ac4-ci-go-job.png?raw=true)) `` |
| Python M0 unit tests | CI 136743697834 | pass ([00](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/00-ci-checks.png?raw=true)) ``` |
| Frontend (lint, test, build) | CI 136743697640 | pass |
| DB (migrate twice, HNSW plan + recall) | CI 136743697539 | pass |
| Agent ownership check | CI 136743697851 | pass |
| Full stack (compose + make test-full) | CI 136747023595 (run 44870494789, attempt 2) | **fail, infra**: step 11 prefetch, `upstream 429 … id_list=2608.20331` ×4, `prefetch FAILED`. Steps 14–24 (all tests) skipped. Attempt 1 failed the same way ([00](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/00-ci-checks.png?raw=true)) ```` |
| Ticket verification commands | local, Go 1.25.1, scratch copy of go.mod + `internal/` with real deps (x/ modules via tag-pinned GitHub clones) | gofmt clean, vet ok, `-race -v` AC3 `-run` set all PASS, 30× `-race` flake run ok ([04](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/04-verification-local.png?raw=true)) ````` |
| `make test-unit` / `make lint` | not run locally as make targets: kafka/telemetry deps aren't in the sandbox module cache. CI ran both | CI green |
| `make eval` | not run: test-only, no retrieval/answering code touched | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: one row per `http.Error` path (code, `text/plain; charset=utf-8`, prefix, not JSON) | ✅ | [01](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/01-ac1-error-rows.png?raw=true): `````` `server.go` is unchanged by the PR. Its 16 `http.Error` sites map 1:1 to 15 rows (`:133` stays with `TestWriteJSON`). Every ticket-named code and prefix is present, including both 503 rows. Each row asserts code, exact Content-Type, prefix, `!json.Valid` and no log lines, and recovers a panic into `t.Fatal`. [04](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/04-verification-local.png?raw=true): ``````` all 15 PASS with -race. [03](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/03-ac3-mutants.png?raw=true): ```````` one mutant per site, each KILLED by its own row |
| AC2: `SetIngester(NewPaperIngester(nil, nil, "bucket", "", 0))` keeps that pointer | ✅ | [02](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/02-ac2-setingester.png?raw=true): ````````` goes through `NewServer` + `SetIngester` (not a struct literal), type-asserts `*PaperIngester`, compares the pointer, same shape as `ingester_test.go:132`, calls nothing on it. PASS. q2 KILLED ([03](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/03-ac3-mutants.png?raw=true)) `````````` |
| AC3: e2, e3, e5, e6, q2 killed by the ticket's `-run` command | ✅ (QA run, finding 2) | [03](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/03-ac3-mutants.png?raw=true): ``````````` all 5 KILLED under the AC3 `-run` set and under the full `./internal/query/` package, each failing exactly the intended row. 19 more site-level mutants (status, message, removed check, TrimSpace) are also KILLED, with 0 INVALID and 0 NOT-APPLIED. **Base control:** the same 5 SURVIVE against main `11c4696`'s `server_test.go`. Diffs are in [03 .txt](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/03-ac3-mutants.txt ````````````); harness in [06](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/06-harness-source.png?raw=true) ````````````` ([.txt](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/06-harness-source.txt ``````````````)) |
| AC4: test-unit + lint green in CI; Full stack green | ❌ pending | Go, Python and Frontend green ([00](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/00-ci-checks.png?raw=true), ``````````````` [05](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/05-ac4-ci-go-job.png?raw=true)). ```````````````` Full stack red twice on arXiv 429 before any test ran |
| Docs: none, said in PR | ⚠ | Nothing to document (test-only). The body says "test-only" but has no explicit "Docs: none" line (finding 3) |

## Scope check
`pulls/105/files`: only `internal/query/server_test.go` (+98 −0), inside backend paths. No ticket, review or doc files. No `server.go`, `writeJSON`, `rag.go`, `search.go`, `cmd/` or README change, and no e4 work. None of the mutants exposed a `server.go` bug.

## PRD fit
This change delivers Product PRD §7 principle 2 for the query API. Every error path, including `/v1/stats` on a DB error (the RET-1d e3 gap), is now pinned to a non-2xx, plain-text, non-JSON reply, so a failure can't pass as a success without a unit test failing. The API contract (Technical PRD §7) is unchanged.

## Findings
1. [blocking] **AC4: Full stack job red** (job 136747023595, run 44870494789, attempts 1 and 2). Step 11 got `[replay] upstream 429 for https://export.arxiv.org/api/query?id_list=2608.20331` ×4, then `prefetch FAILED … (arXiv unreachable or rate-limiting, and not in the cache)`, `stats={"hits": 3, "misses": 1, …}`. All test steps were skipped. This is infrastructure, not this PR. **Action (orchestrator/pm-lead, not the developer):** re-run the Full stack job once arXiv stops rate-limiting. QA re-reviews only that job if the head doesn't change. No code change is requested.
2. [nit] AC3 says "with output in the PR", but the PR body says "needs a Go 1.25 run (QA)" and the dev Notes say "expected killed by reading". QA evidence 03 is the only real mutant run, so link it in the Evidence section at raise time.
3. [nit] The Docs AC asks the PR to say "Docs: none". Add that line when the description is finalised.
4. [spec] (pm-lead) The Full stack prefetch hard-fails whenever live arXiv rate-limits the one fixture id (`2608.20331`) missing from the branch-scoped replay cache, even on a test-only Go PR. Consider a backend follow-up that pins that replay entry so it doesn't depend on live arXiv.

## Missing tests
- None blocking. Out of scope by the ticket: e4 argument-passing (recording fakes). A minor gap: no row has a whitespace-only `url` with an empty `arxiv_id`, so the `url` TrimSpace at `server.go:229` is unpinned. The ticket doesn't name that behaviour.

## Hand-off
PENDING: re-run Full stack on `7d63496`, and QA re-reviews next cycle (AC4 only unless the head changes). KAN-99 stays In QA.

## Evidence files (pinned @ `7a4a313`)
[00-ci-checks](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/00-ci-checks.png?raw=true) ````````````````` · [01-ac1-error-rows](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/01-ac1-error-rows.png?raw=true) `````````````````` · [02-ac2-setingester](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/02-ac2-setingester.png?raw=true) ``````````````````` · [03-ac3-mutants](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/03-ac3-mutants.png?raw=true) ```````````````````` · [04-verification-local](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/04-verification-local.png?raw=true) ````````````````````` · [05-ac4-ci-go-job](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/05-ac4-ci-go-job.png?raw=true) `````````````````````` · [06-harness-source](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7a4a31303dd5273f008c6313338b062cdeebd030/agents/reviews/RET-1e/evidence/06-harness-source.png?raw=true) ``````````````````````` (each has a `.txt` beside it)


---
_Generated by [Claude Code](https://claude.ai/code)_
