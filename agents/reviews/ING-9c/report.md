[qa-reviewer] **QA ING-9c round 1: PASS** (head `6afd06d`)

The QA harness refused to write `agents/reviews/ING-9c/report.md`, so this comment is the full report; the orchestrator saves it verbatim. Evidence: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence

# QA report — ING-9c · PR #99 · round 1

**Verdict:** PASS
**Reviewed commit:** `6afd06d871486563640a4e84a6244fdb1547d1b9` · **Date:** 2026-11-21
**Ticket:** `agents/tasks/ING-9c.md` · **PRD:** Technical PRD §9 "External politeness"; Product PRD ING-1 (~1 req / 3 s)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136652656390 (merge `de2159b` = head into main `230f617`, `GOFLAGS=-race`) | pass ([05](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/05-AC5-ci-go-job.png?raw=true)) `` |
| Python M0 unit tests | CI | pass |
| Frontend (lint, test, build) | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Full stack (compose + make test-full) | CI 136652656673 | pass |
| Agent ownership check | CI | pass ([00](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/00-ci-checks.png?raw=true)) ``` |
| Ticket verification commands | local scratch module, Go 1.24.7. PR-head `internal/arxiv`, `internal/config` and `internal/query/ingester{,_test}.go` are byte-identical to the head; only `internal/db` and `minio` are stubbed ([06](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/06-harness-sources.png?raw=true)) ```` | all pass ([02](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/02-verification-commands.png?raw=true)) ````` |
| `make test-unit` / `make lint` | CI (Go 1.25 not available locally) | CI green; `gofmt -l` on both files is empty locally ([01](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/01-diff-scope.png?raw=true)) `````` |
| `make eval` | not run: test-only change, no retrieval or answering code touched | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 already-cancelled ctx → `context.Canceled`, 0 requests (IngestPaper + DiscoverAndIngest) | ✅ | `TestIngestCancelledCtxSendsNoRequest` (`ingester_test.go:178`) checks `errors.Is(err, context.Canceled)` and `len(stub.reqs) == 0` for both paths. `--- PASS` locally, `-count=20` ok ([02](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/02-verification-commands.png?raw=true)); ``````` CI `internal/query` ok under `-race` ([05](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/05-AC5-ci-go-job.png?raw=true)). ```````` Mutant m1 kills it, see AC4. |
| AC2 cancelled while serving `id_list=` → `context.Canceled`, exactly 1 request, no `.pdf` | ✅ | `cancelOnAtomStub` + `TestIngestCancelledAfterAtomSendsNoPDFRequest` (`ingester_test.go:198-225`) check `errors.Is`, `len(reqs)==1` and that the request is `id_list=2307.08691`. `--- PASS` ([02](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/02-verification-commands.png?raw=true)). ````````` Under m2, `http.Client` does call `RoundTrip` with the cancelled ctx: the stub records the `.pdf` request and the error becomes the 503 ([04](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/04-AC4-mutants.png?raw=true)), `````````` so the AC's fallback clause doesn't apply. |
| AC3 d >= 100 ms, slack 20 ms, passes `-count=10`, runtime +< 1.5 s | ✅ | `limiter_test.go:64` `const n, d = 10, 100 * time.Millisecond`; `slack` still 20 ms (`:13`, not in the diff, [01](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/01-diff-scope.png?raw=true)). ``````````` `-count=10` ok ([02](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/02-verification-commands.png?raw=true)). ```````````` Runtime 0.27 s on main's test → 0.90 s at the head (+0.63 s) ([03](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/03-AC3-base-control.png?raw=true)). ````````````` |
| AC4 mutants m1-m4 each fail their test | ✅ | [04](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/04-AC4-mutants.png?raw=true): `````````````` m1 (`_ = lim.Wait(ctx)` in `GetAPI`) KILLED by AC1's test (1 or 2 requests recorded); m2 (`ingester.go:199`) KILLED by AC2's test (`.pdf` sent, 503 error); m3 (no `turn`) KILLED (gaps of 1-57 µs); m4 (`interval/2`) KILLED (gaps of 50 ms). Each mutant was run with `-run` on the named test and on the full arxiv+query suites. Base control ([03](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/03-AC3-base-control.png?raw=true)): ``````````````` m4 PASSES main's d=30 ms test and FAILS the PR's d=100 ms test. All mutants ran in throwaway local copies; nothing was pushed. |
| AC5 `-race -count=5` arxiv+query; CI Go + lint green; PASS lines or job ID | ✅ | `go test -race -count=5 ./internal/arxiv/... ./internal/query/...` ok ([02](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/02-verification-commands.png?raw=true), ```````````````` QA harness). CI Go job 136652656390 ran `go vet` + gofmt (`make lint-go`) and `go test ./...` with `GOFLAGS=-race`, success ([05](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/05-AC5-ci-go-job.png?raw=true)). ````````````````` Both new tests' `--- PASS` lines are in 02. |
| Docs: none | ✅ | Test-only, 2 files ([01](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/01-diff-scope.png?raw=true)). `````````````````` |

## PRD fit
Technical PRD §9 and ING-1 require at most one arXiv request per interval and no traffic for work nobody is waiting for. These tests pin both: a cancelled ingest sends nothing (before any request, and between Atom and PDF), and the limiter test now proves gaps of at least 80 ms, not 10 ms. So a half-interval limiter, which the PRD would count as a politeness violation, can no longer pass.

## Findings
None blocking.

1. [nit] (observation, outside this ticket's ACs) Extra mutant x6 (drop the `ctx.Done()` case in the limiter's timer `select`) survives both new `internal/query` tests. The AC2 path is stopped by `Limiter.Wait`'s up-front `ctx.Err()` check before the timer starts. The existing `TestCancelledWaiter` kills x6 in the full suite ([04](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/04-AC4-mutants.png?raw=true)), ``````````````````` so no guard is uncovered. x7 (drop `ctx.Err() != nil` in `Retry.Do`) survives everything, but it is equivalent: on a cancelled ctx, `sleepCtx` returns at once and `Do` returns the same `err`.

## Missing tests
- No required tests are missing. One optional backlog item for `internal/arxiv`: extra mutant x5 (drop `Limiter.Wait`'s up-front `ctx.Err()` check) leaves Go's random `select` choice between a free turn slot and a done ctx. AC1's test kills it 24/30 times and `TestFirstWaitIsImmediate` 14/30 ([07](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/07-x5-kill-rate.png?raw=true)), ```````````````````` so a regression there would show up as a flaky test, not a steady red. A limiter test that loops `Wait` on a cancelled ctx (for example 50 times, with a fresh limiter each time) and requires `ctx.Err()` every time would make it deterministic.

## Scope / process
- Changed files: exactly `internal/arxiv/limiter_test.go` and `internal/query/ingester_test.go`, +55/-1 ([01](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/6fa37101cdb0016cf167c1df54eb2dc0e506f55d/agents/reviews/ING-9c/evidence/01-diff-scope.png?raw=true)), ````````````````````` inside backend-engineer's paths. No product code, tickets or docs leaked into the PR. The PR body's heading, Spec link, Jira key (KAN-103) and "What changed" paths match this ticket.
- CI ran on the merge with current main (`230f617` = `origin/main`).

## Hand-off
PASS → pm-lead final review


---
_Generated by [Claude Code](https://claude.ai/code)_


_Provenance: saved verbatim by the orchestrator from the QA PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/99#issuecomment-7054066316 (QA harness refused to write report.md)._
