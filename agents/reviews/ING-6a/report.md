<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-17T13:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/56#issuecomment-6950578410 (the QA harness could not write report.md). -->

[qa-reviewer] **QA round 1: ING-6a (part ING-6a2): FAIL** · reviewed `3756173f995e385e0e6b5effa8c640d4734203dc` (base main `40dec5a`) · evidence commit [`57f679e`](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence)

Note: the QA harness refused to write `agents/reviews/ING-6a/report.md`. This comment is the full report; the orchestrator saves it verbatim.

Scope: this PR is ING-6a2 (`internal/crawler/loop.go` + `loop_test.go`). AC6 and AC7 belong to ING-6a1 (branch `agent/backend/ING-6a1` @ `c86bd5a`, no PR yet), so they are **out of this PR's scope and not met here**.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 134087571745 (head_sha 3756173, on merge `83c762d` into 40dec5a) | pass: `make lint-go` ok, `ok arxivlens/internal/crawler` ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/00-ci-checks.png ``), [01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/01-ci-go-job.png)) |
| Python M0, Frontend, Ownership, DB, Full stack | CI | all 6 checks success |
| Ticket `-run` set | local scratch module, Go 1.24.7 (Go 1.25 unavailable). Real arxiv/crawler/events; stubs only for db (PaperRecord copied verbatim), kafka, ulid | 4/4 tests and 11 walk rows PASS with `-race`; full crawler + arxiv packages ok ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/03-unit-tests.png)) |
| `make eval` | not run: no retrieval or answering change | n/a |
| 27 local mutants (never pushed), each in the full package and with `-run '^T$'` | scratch module | 23 killed in both runs; M5, M23, M24, M27 survived ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/04-mutants.png)) |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ⚠ rows present, one guard unpinned | All design rows are in `TestWalkStopsAtWatermark` and pass. Deleting the undated-skip guard still passes every row (M5); the probe shows 3 behaviour changes ([05](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/05-probe-undated.png ```)). Finding 1 |
| AC2 | ✅ | `out_of_order` asserted in every row; M7 killed |
| AC3 | ✅ | `TestSelectBatch`; M3 and M14 killed |
| AC4 | ✅ | Asserted query = `Crawl`'s bytes in CI run 44092000441; the replay key is order-independent ([07](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/07-ac4-ac10-feed.png ````)). Limiter spacing, UA, 429 retry and 503 → `*arxiv.StatusError` (not parsed) all tested; M20–M22, M25, M26 killed |
| AC5 | ✅ | All accept/reject inputs; M16–M19 killed |
| AC6, AC7 | n/a here (not met in this PR) | ING-6a1 branch ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/02-diff-scope.png)) |
| AC8 | ✅ for the 4 listed | M1–M4 killed by the named tests, in both runs ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/04-mutants.png)) |
| AC9 | ✅ (this part) | Only 2 added files, 398 lines ([02](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/02-diff-scope.png `````)); CI green |
| AC10 | ⚠ met as worded, escalation triggered | Fixture values `2023-07-17T17:50:36Z` then `2024-01-22T09:00:00Z` checked (ascending, synthetic OPS-H3 fixture) ([07](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/07-ac4-ac10-feed.png ``````)). [spec] 7 |

Design check:
- Conditions 1, 3, 4, 5 and 10: followed.
- Condition 6: implemented, but two defaults are untested (nits 2, 3).
- Condition 8: the split is at the named seam, 107 + 398 = 505, and it is recorded in "Build notes (ING-6a)". There is no separate skeleton commit (nit 5).

## Findings
1. **[blocking] AC1's "zero `published` is ignored" guard is unpinned.** Mutant M5 (the `if p.PublishedAt.IsZero() { …; continue }` branch made dead) survives the full package and `-run '^TestWalkStopsAtWatermark$'`. The undated row only runs with a watermark, where a zero time is filtered anyway by `!After(w)`. The probe ([05](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/05-probe-undated.png ```````)) shows three changes under the mutant:
   - (a) On a first run, `feed(15, undated, 14)` returns `p15 undated1 p14`: the undated paper becomes a candidate.
   - (b) With W=10, the page `[15, 9, undated]` no longer stops the walk. That is an extra arXiv request (`0,3 3,3` instead of `0,3`).
   - (c) `out_of_order` reads 0 instead of 1 across an undated entry, which weakens condition 3.

   Fix (test-only): add a first-run row with an undated entry, and a W row whose page ends `[…, ≤W, undated]` and expects one request.
2. **[nit]** `NewArxivFeed` setting `arxiv.DefaultRetry` is unasserted (M23 survives): the test overwrites `f.retry`. Compare `Attempts`/`Base`/`Max`.
3. **[nit]** The `NewArxivFeed(client, nil)` → `DefaultInterval` fallback is untested (M24: nil stays nil, so requests go out unthrottled). Assert `f.lim != nil`.
4. **[nit]** `walk`'s `ctx.Err()` check between requests is untested (M27). The design lists "ctx cancel in walk" as covered; add a cancelled-ctx row.
5. **[nit]** Condition 8's "counted skeleton first" commit is missing on both branches (single commits). The outcome is fine; this is audit trail only.
6. **[spec]** AC4's literal string (`search_query=…&start=0&…`) is not the byte order `Crawl` or the prefetch uses (sorted encode). The test asserts the real bytes; pm-lead should amend the AC text.
7. **[spec]** AC10 / Risk 1 is triggered: the only committed feed is ascending and synthetic. pm-lead must place the CI `published_at` print (6c or a harness task) **before ING-6b**. This does not block 6a2.
8. **[spec]** ING-6a can't reach Done from this PR alone: AC6/AC7 sit on the 6a1 branch with no PR. The ticket needs a Done rule for both parts, and 6a1 must merge before 6b.

## Missing tests
- A first-run walk with undated entries.
- A page ending in an undated entry after a ≤W entry.
- `out_of_order` across an undated entry.
- A cancelled ctx in `walk`.
- `NewArxivFeed` defaults (retry, nil limiter).

Harness source for the round-2 control run: [06](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/57f679e2fe7cd662b35449453d5dbbd86ea205e1/agents/reviews/ING-6a/evidence/06-harness-source.png ````````).

Hand-off: FAIL → backend-engineer (finding 1 is test-only). [spec] 6–8 → pm-lead.


---
_Generated by [Claude Code](https://claude.ai/code)_
