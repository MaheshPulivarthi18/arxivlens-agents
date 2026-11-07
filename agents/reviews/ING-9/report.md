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

<!-- Provenance: round 2 written by qa-reviewer (fresh context, cycle 2026-11-07T10:00Z); harness could not write files, so the orchestrator appended PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/25#issuecomment-6705814932 verbatim (role tag dropped). -->

QA report: ING-9 · PR #25 · round 2

**Verdict:** PASS
**Reviewed commit:** `c5dc8737813c1f01a4e6c252a79ae237000047fc` (unchanged since round 1) · **Date:** 2026-11-07
**Ticket:** [agents/tasks/ING-9.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/ING-9.md) (AC8 reworded by pm-lead in 4748ccb to "a dispatched `stack.yml` run of the PR head") · **PRD:** Technical PRD §9 "External politeness"; Product PRD ING-1
**Evidence (round 2):** [agents/reviews/ING-9/evidence/ @ ac6e824](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/ac6e8240853a43f31d4b31c4698933cf1fe16f72/agents/reviews/ING-9/evidence/), files 12–15. Round 1 evidence (00–11) still applies, since the head hasn't changed.

Round 1's only blocking finding was that AC8 had no `stack.yml` run. That is now resolved. [Run 42364519257](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42364519257) was dispatched on `agent/backend/ING-9` at `c5dc873` and finished `success`. Every gated step passed. The only failures are the known F1 tests, and they match the baseline runs.

## Test results
| Check | Source | Result |
|---|---|---|
| Full stack (`stack.yml`) | CI run 42364519257, job 128379663308, `workflow_dispatch` | **success**. `head_sha` = `c5dc8737…`. Steps 1–19, 21 and 22 succeeded; Diagnostics was skipped because nothing failed ([12](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ac6e8240853a43f31d4b31c4698933cf1fe16f72/agents/reviews/ING-9/evidence/12-ac8-stack-run.png?raw=true))`` |
| Other checks on `c5dc873` | CI | Go, DB, Python M0, Frontend and ownership: all success, same as round 1 ([15](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ac6e8240853a43f31d4b31c4698933cf1fe16f72/agents/reviews/ING-9/evidence/15-head-unchanged.png?raw=true))``` |
| Head / diff unchanged | PR API + `git diff` in `app/` | The PR has one commit, `c5dc873`. It touches 6 files under `internal/`, +376/−22. The `cmd/`, `go.mod` and `go.sum` diff is 0 lines ([15](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ac6e8240853a43f31d4b31c4698933cf1fe16f72/agents/reviews/ING-9/evidence/15-head-unchanged.png?raw=true))```` |
| `make eval` | not run | not a retrieval/answering change |

## Acceptance criteria (round 2 delta)
| AC | Met? | Evidence |
|---|---|---|
| AC1–AC7 | ✅ (carried over) | The head is unchanged since round 1, so round 1 evidence 00–11 stands |
| AC8 dispatched `stack.yml` green apart from F1; diff < 400; `cmd/`/`go.mod`/`go.sum` unchanged | ✅ | **Crawl → download → embed** ([13](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ac6e8240853a43f31d4b31c4698933cf1fe16f72/agents/reviews/ING-9/evidence/13-ac8-pipeline-ingest-log.png?raw=true)):````` the crawler sent its own 3 s sleep and published 2 papers. The host downloader and query service, built from this head, started; `/healthz` returned ok at 10:40:22. Both papers reached `embedded` by 10:42:57, well inside the 15 min deadline, and all 3 DLQs had Total 0. The second paper was still `discovered` at 10:40:22 and `chunked` at 10:40:32, which fits the downloader waiting for its slot before the second PDF. **On-demand ingest** of 2608.20331 returned HTTP 200 `{"status":"success",…,"chunks":57,"embeddings":57}` and status `embedded`. **`make test-full`** with F1 deselected: `80 passed, 1 skipped, 3 deselected`. **F1** (`continue-on-error: true`, step 19): `2 failed, 1 passed`, both `ReadTimeout` on `/v1/ask`. In the AI-9 and EVAL-3 baseline runs all 3 F1 tests failed the same way, so this run is no worse ([14](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ac6e8240853a43f31d4b31c4698933cf1fe16f72/agents/reviews/ING-9/evidence/14-ac8-f1-vs-baseline.png?raw=true)).`````` The ingest step took about 48 s, against about 62 s in both baselines, so the 3 s waits didn't measurably slow it. Diff: 398 lines < 400; `cmd/`, `go.mod` and `go.sum` untouched ([15](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/ac6e8240853a43f31d4b31c4698933cf1fe16f72/agents/reviews/ING-9/evidence/15-head-unchanged.png?raw=true))``````` |

**Limits of the AC8 evidence.** The job log doesn't record per-request timestamps or the User-Agent header. Those are in `downloader.log` and `query.log` inside the `stack-logs` artifact (6 KB), and the QA sandbox can't download it: the egress proxy refuses the artifact blob host. So in CI, AC8 proves the end-to-end paths still work with the limiter in place, not the spacing or UA themselves. The spacing and UA are proven by the AC2–AC4 unit tests and the mutation run from round 1 (03, 04, 09). AC8 doesn't ask for more.

## PRD fit
Unchanged from round 1. On-demand ingest and the downloader now follow Technical PRD §9: at least 3 s between request starts within a process, and an identifying User-Agent. The full stack shows this costs no measurable latency or correctness in the paths ING-1/4/5 depend on.

## Findings
1. ~~[blocking] AC8 had no `stack.yml` run~~: **resolved** by run 42364519257 (12–14).
2. ~~[spec] path filter~~: handled by pm-lead (AC8 reworded; widening the filter is OPS-H10).
3. [nit] Still open, not blocking: the round 1 nits 3–7. They are an ingester cancelled-ctx test, the `HandleRecord`→`fetchPDF` wiring test, a tighter `d` in `TestConcurrentCallersAreSpaced`, no `-race` in the CI Go job, and unspaced redirect hops.
4. [nit] For the PR description: the run's `stack-logs` artifact (`downloader.log`, `query.log`) would show the real 3 s spacing between the two PDF GETs. Anyone with artifact access can quote it, but it isn't needed for PASS.

## Missing tests
- Same as round 1: an ingester with a cancelled ctx sends no request, and `HandleRecord` downloads through `fetchPDF`. Neither blocks.

## Hand-off
PASS → pm-lead final review. Link run 42364519257 in the ticket Notes and the PR description, as AC8 asks.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM review (pm-lead) · 2026-11-07

**Verdict:** APPROVE
**Reviewed commit:** `c5dc8737813c1f01a4e6c252a79ae237000047fc` (PR #25 head, re-checked via the REST API: draft, one commit, 6 files under `internal/`, +376/−22)
**Inputs:** ticket `agents/tasks/ING-9.md` (AC8 as reworded at `4748ccb`), Technical PRD §9 "External politeness", Product PRD ING-1 (and ING-4/ING-5), QA rounds 1 (FAIL) and 2 (PASS), the PR diff (`gh api .../pulls/25/files`), every evidence file 00–15.
Evidence pins checked with `git cat-file`: `b1b104b8574f8f441a1e385cb7db47f32285ee81` holds 00–11, `ac6e8240853a43f31d4b31c4698933cf1fe16f72` holds 00–15.

### Product fit
Technical PRD §9 says at most 1 arXiv request per 3 s and an identifying User-Agent. Before this PR that held only for the crawler. Now the two other Go callers comply, per process:
- **On-demand ingest:** `IngestPaper` and `DiscoverAndIngest` go through one `doArxiv`, which waits on a single limiter per query-service process and sets `ArxivLens/1.0 (Query Ingester; mailto:…)`. The anonymous `ArxivLens-Bot/1.0` UA is gone.
- **Downloader:** `fetchPDF` waits before every PDF GET.

The package doc states the per-process limit honestly. The constant can't be lowered by config, which fits the "be a good citizen" principle and the risk row in Product PRD §11 ("Built-in 3 s rate limit, descriptive User-Agent"). That row and ING-1 ✅ are now true for all Go arXiv callers. The PRD caveat I had planned ("crawler only") was never written, so no PRD status change is needed when this merges. The researcher persona does pay for it: on-demand ingest takes about 3 s longer (6 s longer with discover), and concurrent ingests queue. The stack run's ingest step took about 48 s against about 62 s in the baselines, so the cost is lost in the noise. The PR description has to state it, and it does.

### Scope
The PR matches the ticket. It touches the new `internal/arxiv/` package, `ingester.go` and `downloader.go` with their tests, and nothing else. Both constructor signatures are unchanged. The crawler, `cmd/`, `go.mod` and `go.sum` are untouched. The diff is 398 changed lines, under 400. No README change is needed: the ticket puts the latency note in the PR body, not the README, and no command or API changed.

### Evidence, AC by AC (I opened every file)
| AC | Files | PM check |
|---|---|---|
| AC1 | 02, 10, 09 | All 4 limiter tests pass under `-race`, stable at `-count=20`. The mutants for no-sleep, no-serialization, cancelled-slot and ignored-ctx are all killed. `-race` ran locally only, because CI's Go job has no `-race` (nit 6). I accept that: the AC names the command, and the limiter is a capacity-1 channel with no shared state outside it |
| AC2, AC3 | 03, 09 + diff | The test's `checkSpaced` asserts URL order, ≥ interval − 10 ms between starts and the exact `Query Ingester` UA, for Atom→PDF, search→Atom→PDF, and 2 concurrent ingests (4 requests). I read the assertions in the diff, because 03 only shows PASS lines. The mutants for bypassing `doArxiv` on each call site and for a per-call limiter are killed |
| AC4 | 04, 09 + diff | `TestFetchPDFIsSpacedAndIdentified`: two calls ≥ 40 ms apart, exact UA, and a cancelled ctx sends no request |
| AC5 | 05 | `DefaultInterval` is a `const`, both constructors use it, tests assert 3 s, and `config/` and `cmd/` don't mention it |
| AC6 | 06 | `grep ArxivLens-Bot` exits 1. Every arXiv `Do(` goes through `doArxiv`/`fetchPDF`/the crawler. `query/client.go` calls the embedder, not arXiv |
| AC7 | 07 | `limiter.go` coverage is 100%. This is a scratch-module run (11 shows the harness copies the real PR files and stubs only infrastructure), which the AC allows (lesson AI-1) |
| AC8 | 12, 13 (+ .txt), 14, 15, 00, 01 | Dispatched run [42364519257](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42364519257), `head_sha` c5dc873, `success`. The `.txt` confirms both crawled papers reached `embedded` by 10:42:57 with all 3 DLQs at 0. The second paper sat in `discovered` while the downloader waited its turn. On-demand ingest returned 200 `success`, 57 chunks. `make test-full`: 80 passed / 1 skipped / 3 deselected. F1: 2 failed / 1 passed, all `ReadTimeout`, no worse than the 3/3 baseline failures. Diff is 398 lines, and `cmd`/`go.mod`/`go.sum` have 0 lines changed |

Nothing that matters is left "unverified". The spacing and UA aren't visible in CI logs, because the `stack-logs` artifact can't be fetched from the sandbox. The unit tests and 19/20 killed mutants prove them, and AC8 only asks that the end-to-end paths still work.

### Docs
- App README/CONTRIBUTING: no change needed.
- PRD: ING-1 ✅ and §11 risk row are now accurate. The Backlog "caveat" item is dropped once this merges.
- Formatting note for the orchestrator: the verbatim QA r1/r2 text above has stray backtick runs around its evidence links. The links resolve, so the text stays as saved, but the PR description uses clean links.

### QA nits 3–7: decisions
3. Ingester cancelled-ctx test (the one surviving mutant) → Backlog **ING-9 follow-ups** (backend, P3), folded into the next `ingester.go` change.
4. `HandleRecord` → `fetchPDF` wiring test → same Backlog item, but only once db/storage are behind interfaces. Code reading (`downloader.go:80-84`) and the `HandleRecord bypasses fetchPDF` mutant, which is killed (09), are enough for now.
5. Tighter `d` in `TestConcurrentCallersAreSpaced` (≥ 100 ms) → same Backlog item.
6. `-race` in CI's Go job → Backlog (backend, P2, harness): add `-race` to `make test-go`, or as a separate CI step, after checking the runtime cost. This is a repo-wide quality gap, not something specific to ING-9.
7. Redirect hops not spaced → Backlog (backend, P3). First check whether `arxiv.org/pdf/<id>.pdf` actually redirects. If it does, make `CheckRedirect` wait on the limiter. This sits next to the out-of-scope 429/retry handling.

None of these block the PR. None is a `[spec]` gap in this ticket.

### Hand-off
APPROVE → PR body written to `/tmp/claude-0/s/pr25-body.md`. The orchestrator raises PR #25 (ready for review, `ready-to-merge` label), moves KAN-48 → Ready to merge, and adds the comment `[pm-lead] APPROVE — PR #25 raised for review → <report link>`.
