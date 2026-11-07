<!-- Provenance: written by qa-reviewer (fresh context, cycle 2026-11-07T10:00Z); its harness could not write files, so the orchestrator saved the PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/25#issuecomment-6705673402 verbatim (role tag dropped). Evidence rendered by qa-reviewer with agents/tools/render_evidence.py. -->

QA report: ING-9 · PR #25 · round 1

**Verdict:** FAIL
**Reviewed commit:** `c5dc8737813c1f01a4e6c252a79ae237000047fc` · **Date:** 2026-11-07
**Ticket:** [agents/tasks/ING-9.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/ING-9.md) · **PRD:** Technical PRD §9 "External politeness"; Product PRD ING-1 (also ING-4, ING-5)
**Evidence:** [agents/reviews/ING-9/evidence/ @ b1b104b](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/)

The code, the unit tests and the mutation results are sound. AC1–AC7 have evidence. **AC8 has none**: `stack.yml` never ran for this PR because its `pull_request` path filter doesn't match `internal/**`. Nobody has a green full-stack run showing the 3 s waits leave crawl → download → embed and on-demand ingest working. The fix is a CI run, not a code change.

_Note: the QA harness wouldn't let me write `report.md`, so this comment is the full report. The orchestrator saves it verbatim to `agents/reviews/ING-9/report.md`._

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 128376093647 | pass. `go test ./...` ran `internal/arxiv`, `internal/downloader` and `internal/query` (all `ok`), no `-race` ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/00-ci-checks.png?raw=true),`` [01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/01-ci-go-job-log.png?raw=true))``` |
| DB / Python M0 / Frontend | CI | pass |
| Agent ownership check | CI | pass (6 files, all under `internal/`, backend-owned) |
| Full stack (`stack.yml`, needed by AC8) | CI | **not triggered**: the path filter has no `internal/**`; the branch has no run ([08](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/08-ac8-stack-and-diff.png?raw=true))```` |
| Ticket verification commands | local, scratch module | `go test -race -v` for arxiv, downloader and `Ingest\|Discover`: pass. Coverage: 100%. `grep ArxivLens-Bot`: empty. `-race -count=20`: pass. Full-repo `make lint` / `make test-unit` not run locally because the sandbox has Go 1.24 (go.mod needs 1.25) and no module proxy, so CI's Go job stands in for them. The scratch module copies the real PR files and replaces minio, kgo, db, storage, kafka and events with stubs ([11](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/11-scratch-harness.png?raw=true))````` |
| Mutation run (QA) | local, scratch module | 19 of 20 mutants killed ([09](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/09-mutants.png?raw=true``````)) |
| `make eval` | not run | not a retrieval/answering change |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 limiter | ✅ | `TestFirstWaitIsImmediate`, `TestSequentialWaits`, `TestConcurrentCallersAreSpaced`, `TestCancelledWaiter` (covers a waiter cancelled while queued and one cancelled while sleeping). Pass under `-race` ([02](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/02-ac1-limiter-race.png?raw=true))``````` and are stable at `-count=20` ([10](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/10-stress.png?raw=true````````)). Each of these mutants is killed: no sleep, no serialization, cancelled sleeper consumes the slot, ctx ignored while sleeping, ctx ignored while queued, first call waits. `-race` is shown locally only |
| AC2 IngestPaper Atom → PDF spaced, with the UA | ✅ | `TestIngestSpacesArxivRequests` with `discover=false` ([03](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/03-ac2-ac3-ingester.png?raw=true)).````````` Mutants killed: Atom call bypasses `doArxiv`, PDF call bypasses it, Wait removed, UA removed, a new limiter per call |
| AC3 Discover search → Atom → PDF; 2 concurrent ingests → 4 spaced requests | ✅ | `TestIngestSpacesArxivRequests` with `discover=true`, plus `TestConcurrentIngestsShareOneLimiter` ([03](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/03-ac2-ac3-ingester.png?raw=true)).`````````` Mutants killed: search bypasses `doArxiv`, limiter not serialized |
| AC4 downloader `fetchPDF` spaced, with the UA | ✅ | `TestFetchPDFIsSpacedAndIdentified` ([04](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/04-ac4-downloader.png?raw=true)).``````````` It also covers a cancelled ctx (no request is sent) and a 503 response. Mutants killed: Wait removed, UA removed. `HandleRecord` → `fetchPDF` checked by reading the code (finding 4) |
| AC5 3 s constant, used by both constructors, no env var or flag | ✅ | `TestDefaultsAndUserAgent`, `TestNewPaperIngesterTimeouts` and `TestFetchPDFIsSpacedAndIdentified`. `config/` and `cmd/` don't mention the limiter ([05](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/05-ac5-interval.png?raw=true)).```````````` Mutants killed: DefaultInterval = 1 s, each constructor at 1 s |
| AC6 no `ArxivLens-Bot`; no arXiv request without a UA | ✅ | grep finds nothing (exit 1). Every arXiv `Do(` goes through `doArxiv`, `fetchPDF` or the crawler, and each sets a UA. `query/client.go` is the embedder client ([06](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/06-ac6-grep.png?raw=true`````````````)) |
| AC7 `limiter.go` coverage ≥ 90% | ✅ | 100.0% ([07](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/07-ac7-coverage.png?raw=true))`````````````` |
| AC8 `stack.yml` green apart from F1; diff < 400; `cmd/`, `go.mod`, `go.sum` unchanged | ❌ (partly) | Diff is 376+22 = 398 lines. `cmd/`, `go.mod` and `go.sum` are untouched ✅. **`stack.yml` did not run**: no `internal/**` in its `paths`; the branch has only `CI` and `DB` runs ([08](```````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b1b104b8574f8f441a1e385cb7db47f32285ee81/agents/reviews/ING-9/evidence/08-ac8-stack-and-diff.png?raw=true))``````````````` |

## PRD fit
This delivers Technical PRD §9 for the two non-compliant Go callers. On-demand ingest and the downloader now space request starts at least 3 s apart within one process, through one shared limiter per process, and send `ArxivLens/1.0 (<component>; mailto:…)`. The package doc says honestly that the guarantee is per process, as the ticket asked. The PR description states the latency cost: about +3 s per ingest and +6 s per discover-ingest.

## Findings
1. [blocking] **AC8 has no evidence: `stack.yml` was never run on this PR.** No code change is needed. Dispatch it on the branch (`gh workflow run stack.yml --ref agent/backend/ING-9` at `c5dc873`) and link the run in the ticket Notes and the PR. QA re-reviews once it's green apart from the known F1 step. That workflow runs the host Go downloader and query service, so it's the only check that the 3 s waits keep the "wait until both crawled papers are embedded" step and the on-demand ingest step inside their timeouts.
2. [spec] `stack.yml`'s `pull_request.paths` leaves out `internal/**`, `cmd/**` and `go.mod`, so no Go-only PR gets the full-stack check. AC8 assumed it would run by itself. pm-lead can either word AC8 as "a dispatched `stack.yml` run" or open a backend follow-up to widen the path filter.
3. [nit] One mutant survives: `doArxiv` ignoring the `Wait` error. It's almost equivalent in production, because the real transport refuses a cancelled ctx. Add an ingester test that cancels the ctx and asserts the stub transport saw no request, as the downloader test does.
4. [nit] No test covers the `HandleRecord` → `fetchPDF` wiring. That would need db/storage fakes, which this ticket leaves out of scope. I verified it by reading `downloader.go:80-84`.
5. [nit] `TestConcurrentCallersAreSpaced` uses d = 30 ms with 20 ms slack, so it only proves gaps of at least 10 ms. That meets the AC's wording and still kills the no-serialization mutant, but d ≥ 100 ms would be a tighter guard.
6. [nit] The CI Go job runs without `-race`, so AC1's `-race` requirement is proven only by the local scratch run.
7. [nit] Not in scope, for the backlog: `http.Client` follows redirects inside one `Do`, so a redirect hop from arXiv is an extra request that isn't spaced.

## Missing tests
- Ingester with a cancelled or expired ctx: returns an error and no request reaches the transport (finding 3).
- `HandleRecord` downloads through `fetchPDF` (optional; needs fakes).

## Hand-off
FAIL → back to backend-engineer (or the orchestrator) for finding 1. This needs only a `stack.yml` dispatch on `c5dc873`, no code change. Finding 2 goes to pm-lead.


---
_Generated by [Claude Code](https://claude.ai/code)_
