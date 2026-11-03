> Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/13#issuecomment-6606149011 (QA harness could not write report.md).

[qa-reviewer] QA report: AI-3 · PR #13 · round 1

**Verdict:** PASS
**Reviewed commit:** `ff9e7c1f95a27652dafc8ed8dca4b431c45ba9de` · **Date:** 2026-11-03
**Ticket:** `agents/tasks/AI-3.md` · **PRD:** Technical PRD §11 "Batch embedding in RAG validation"; Product PRD §8 `/v1/ask` p95 < 3 s · **Design:** none
**Evidence pack:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence

## Scope check
Only `internal/query/rag.go` (+85/-52) and `internal/query/rag_test.go` (+215/-0) changed. Both are ai-engineer paths, and the ownership check passed. No threshold, response-shape or embedder batch-size change. No docs or tickets leaked into the PR.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 125970111255 (Go 1.25.0, merge of ff9e7c1 into 9c1229a) | success, `ok arxivlens/internal/query` ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence/00-ci-checks.png?raw=true),`` [01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence/01-ci-go-job-log.png?raw=true))``` |
| Python M0 unit tests | CI | success |
| Frontend (lint, test, build) | CI | success |
| Agent ownership check | CI | success |
| Ticket verification (vet, gofmt, `go test -race -v`) | local stdlib-only scratch module with byte-identical `rag.go`/`rag_test.go` (sha256 shown) plus stubs, Go 1.24.7 | vet clean, gofmt clean, all PASS ([02](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence/02-ac1-call-count-test.png?raw=true),```` [05](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence/05-ac4-fail-closed.png?raw=true))````` |
| `make test-unit` / `make lint` | not run locally: sandbox Go 1.24.7, go.mod needs 1.25 | CI pass |
| `make eval` | not run: no docker daemon, no psycopg, HF unreachable, no services ([04](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence/04-ac3-eval-not-runnable.png?raw=true))`````` | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: ≤ 2 calls | ✅ | `TestAskBatchesEmbeddingCalls`: ≤ 2 calls, then exactly [3 chunks in hit order] + [2 sentences], with labels/scores equal to a per-item reference. CI green, plus local `-race` ([02](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence/02-ac1-call-count-test.png?raw=true))``````` |
| AC2: existing tests unchanged | ✅ | `rag_test.go` numstat `215 0`. The 9c1229a test file, byte for byte, passes all 9 tests against the PR-head `rag.go` ([03](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence/03-ac2-existing-tests-unchanged.png?raw=true))```````` |
| AC3: make eval or "not run" + command | ✅ (not-run branch) | Developer recorded "not run: infra unavailable" with `make eval` before on 9c1229a and after on ff9e7c1. QA confirmed the stack can't run here ([04](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence/04-ac3-eval-not-runnable.png?raw=true))````````` |
| AC4: fail-closed (a)/(b)/(c) | ✅ | `TestAskBatchFailClosed`: chunk err, sentence err (`sentence_embed_errors=2`), fewer vectors in either batch, more vectors. Each case asserts score 0/unsupported, 2 calls and the log counters ([05](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence/05-ac4-fail-closed.png?raw=true))`````````` |
| AC5: mutation | ✅ | Literal revert to 9c1229a `rag.go`: `EmbedTexts called 5 times, want <= 2`. Chunk loop alone reverted: `called 4 times`. Both FAIL ([06](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence/06-ac5-mutation-per-hit.png?raw=true))``````````` |

Extra mutants, all killed ([07](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/05c188ddba3b02b3c4297914faa05a9f096f69af/agents/reviews/AI-3/evidence/07-extra-mutants.png?raw=true)):```````````` one call per sentence, length-mismatch check removed, dedupe disabled, chunk batch reversed.

## Code review notes
- `embedBatch` returns one slot per input and empties all slots on error or count mismatch. The indexes are bounded (1..K marker check, dedupe map), so there is no panic path.
- The log line keeps its fields and meaning. A count mismatch is a missing vector, not a `sentence_embed_error`, the same as the pre-AI-3 code.
- With no in-range marker, the code now makes 0 calls (it used to make K). The return value is still nil.

## PRD fit
Delivers §11 as written: at most 2 embedder round trips per `/v1/ask` instead of K + S, with identical labels and scores and the fail-closed honesty guarantees kept. The p95 benefit is expected but not measured yet.

## Findings
1. [nit] After the chunk batch fails, the code still makes the sentence call, a wasted round trip on the failure path only. The tests pin it and it keeps the `sentence_embed_errors` meaning. No action needed.
2. [nit] / follow-up: `max_citations` (which sets K) has no upper bound in `server.go`, so one embed request can be arbitrarily large. This existed before the PR and isn't a regression (it used to be K calls). It belongs in backend input validation or rate limiting.
3. [spec] AC3's not-run branch leaves the main benefit (/v1/ask p50/p95) unmeasured. pm-lead may want a follow-up to run `make eval` before and after once the stack or EVAL-2 is available.

## Missing tests
None blocking. Optional: a correct-length batch with one empty slot (per-slot missing).

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM final review (pm-lead) · 2026-11-03

**Verdict:** APPROVE
**Reviewed:** PR #13 head `ff9e7c1f95a27652dafc8ed8dca4b431c45ba9de` · ticket `agents/tasks/AI-3.md` · Technical PRD §11 "Batch embedding in RAG validation" (`docs/PRD-Technical.md:385`) · Product PRD §8 `/v1/ask` p95 < 3 s · no design doc (not design-required: P1, internal to `rag.go`, response shape unchanged).

### Evidence check (all 8 PNG + 8 TXT files under `evidence/` opened)
| AC | File(s) | Proves the AC? |
|---|---|---|
| CI | `00-ci-checks`, `01-ci-go-job-log` | Yes. All 4 check runs on `ff9e7c1` succeed; Go job runs on the merge of `ff9e7c1` into `9c1229a` with Go 1.25.0, `go vet`, `ok arxivlens/internal/query`, build. Re-checked live with `gh api .../check-runs`: same 4 successes. |
| AC1 | `02-ac1-call-count-test` | Yes. sha256 shows the scratch copies are byte-identical to the PR head; `TestAskBatchesEmbeddingCalls` + per-item parity subtests pass with `-race`. CI runs the same tests on Go 1.25. |
| AC2 | `03-ac2-existing-tests-unchanged` | Yes, and stronger than asked. 0 removed lines in `rag_test.go`, and the pre-AI-3 test file byte-for-byte passes against the new `rag.go`. |
| AC3 | `04-ac3-eval-not-runnable` | Yes for the spec's "not run: infra unavailable + exact command" branch. No docker daemon, no psycopg, no services, HF unreachable. The latency benefit stays unmeasured; follow-up below. |
| AC4 | `05-ac4-fail-closed` | Yes. (a), (b), (c) for both batches plus a "more vectors" case; per QA and the test source, each asserts score 0 / unsupported, call count = 2 and the log counters. |
| AC5 | `06-ac5-mutation-per-hit` | Yes. A literal revert gives 5 calls, a chunk-only revert gives 4; both FAIL. `07-extra-mutants` also kills per-sentence calls, a missing length check, no dedupe and a reversed chunk order. |

### Product fit (Product PRD §7 principles)
- Honesty first is kept: every path that can't produce a vector still yields `supported=false, score=0`, and mutant M3 shows that the length-mismatch guard is pinned. The coarser failure unit (one failed sentence batch now marks every citation in that answer unverified, not just one) is explicitly allowed by the spec and errs on the honest side.
- Researchers see no change in labels or scores (parity test). They get fewer embedder round trips: K + S becomes ≤ 2, and 0 when there is no in-range marker. That directly serves the `/v1/ask` p95 < 3 s target and leaves room for QA-8's longer answers.
- I checked the embedder side: `/internal/embed` takes an arbitrary `texts` list and batches internally, so a larger single request isn't rejected. Request size is bounded by `max_citations` (see follow-up 2).

### Scope
Only `internal/query/rag.go` (+85/-52) and `rag_test.go` (+215/-0), both owned by ai-engineer. No threshold, response shape, embedder batch size or log field changed. Nothing extra, nothing missing from the ticket.

### Docs (DoD 4)
- App `README.md` / `CONTRIBUTING.md`: no update needed. No user-facing behaviour, API or command changed.
- PRD: per the ticket, pm-lead marks Technical PRD §11 "Batch embedding in RAG validation" done in the next docs PR once #13 merges (added to the Backlog docs item).

### QA findings: decisions
1. [nit] Sentence call still made after the chunk batch fails: **no action**. It only costs a round trip on the failure path, and it keeps `sentence_embed_errors` meaningful. If the log-counter split (Backlog, same files) changes counting, revisit it there.
2. [follow-up] No upper bound on `max_citations` in `server.go`: **Backlog item added** (backend, P2). The cap value is a product choice, so it's labelled *Proposed* for Mahesh.
3. [spec] AC3 latency unmeasured: **Backlog item added** (ai, P2, after EVAL-3). Run `make eval` on `9c1229a` vs the merge of #13 once the full-stack eval workflow exists, and record `/v1/ask` p50/p95 and the supported-citation rate. Accepting the not-run branch now is consistent with the spec and with every other task this cycle (sandbox has no stack).
- Missing test (optional, QA): a correct-length batch with one empty slot. Folded into the existing log-counter-split Backlog item (same test file).

### Note on this report
The QA section above was saved verbatim from the PR comment, so some of its evidence links carry stray backticks. The pinned links in the PR description are clean.

PM APPROVE → PR #13 raised (description rewritten with evidence, marked ready for review, label `ready-to-merge`).
