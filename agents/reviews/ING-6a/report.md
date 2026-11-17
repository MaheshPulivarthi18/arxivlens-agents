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


## Round 2 — part ING-6a2 · PR #56

[qa-reviewer] **QA round 2: ING-6a (part ING-6a2, PR #56): PASS** · reviewed `3f8e903457da2ae023babcb5c16488b23ff05da7` (base main `40dec5a`; CI ran on merge `bf3b33c`) · round 1 FAILed at `3756173` · date 2026-11-17 · evidence commit [`12b2bae`](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/12b2bae8e0ff3d1c3fc9cc20a93a85aa5f2bb9b1/agents/reviews/ING-6a/evidence)

**Ticket:** `agents/tasks/ING-6a.md` (Done rule and AC4/AC10 amendments of 2026-11-17) · **PRD:** Product ING-6, Technical PRD §11 "Scheduled crawler", §9 · **Design:** `docs/design/ING-6.md` (approved).
**Scope:** this PR owns AC1–AC5, AC8, AC10, and AC9 for its two files (Done rule). AC6 and AC7 belong to ING-6a1 (#57), so they are out of this PR's scope, not unmet.

### What changed since round 1
`git diff 3756173 3f8e903`: `internal/crawler/loop_test.go` only, +29/−1. `loop.go` is byte-identical to round 1. The changes are 3 walk rows, a `ctx cancelled between requests` subtest (the fake gets a `cancel` field) and `TestNewArxivFeedDefaults`. No existing row was changed (the only "−" line is the `fakeFeed` doc comment).

### Harness control
I rebuilt the round-1 harness from evidence 06 and ran it on the round-1 head `3756173`. The verdict columns (27 mutants × 2 runs) are identical to round-1 evidence 04 ([r2-01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12b2bae8e0ff3d1c3fc9cc20a93a85aa5f2bb9b1/agents/reviews/ING-6a/evidence/r2-01-control-run.png), [r2-02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12b2bae8e0ff3d1c3fc9cc20a93a85aa5f2bb9b1/agents/reviews/ING-6a/evidence/r2-02-control-verdicts.png)).
- One byte differs: M11's diagnostic column. Round 1 printed `TIMEOUT` there; the control printed nothing. M11 is still KILLED in both columns, and 3 reruns of M11 alone all end in `panic: test timed out` (r2-02). So the variation is in how the infinite-walk mutant dies, not in its verdict.
- Round-1 evidence 06 left out `stubs/ulid/go.mod`, which a `replace` directory needs. I recreated it (3 lines) and rendered it with the other round-2 harness files in [r2-08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12b2bae8e0ff3d1c3fc9cc20a93a85aa5f2bb9b1/agents/reviews/ING-6a/evidence/r2-08-harness-source.png).

### Test results
| Check | Source | Result |
|---|---|---|
| All 6 check runs | CI, head 3f8e903 | success: Go, Python M0, Frontend, Ownership, DB, Full stack ([r2-00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12b2bae8e0ff3d1c3fc9cc20a93a85aa5f2bb9b1/agents/reviews/ING-6a/evidence/r2-00-ci-checks.png)) |
| Go (vet, gofmt, test, build) | CI job 134254277910 (`head_sha` 3f8e903, `HEAD is now at bf3b33c Merge 3f8e903… into 40dec5a…`) | `make lint-go` ok, `ok arxivlens/internal/crawler` ([r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12b2bae8e0ff3d1c3fc9cc20a93a85aa5f2bb9b1/agents/reviews/ING-6a/evidence/r2-03-ci-go-job.png)) |
| Ownership | CI job 134254277918 | `Ownership OK for role=backend (426 changed lines)`, with a warning for > 400 (r2-03) |
| Ticket `-run` set + `TestNewArxivFeedDefaults`, `-race -v` | local scratch module, Go 1.24.7 (Go 1.25 and module downloads unavailable). Real arxiv/crawler/events; stubs only for db (`PaperRecord` diffed identical to the head's), kafka, ulid | 20/20 PASS (14 walk rows + ctx subtest); full crawler + arxiv packages ok; vet ok; gofmt empty ([r2-04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12b2bae8e0ff3d1c3fc9cc20a93a85aa5f2bb9b1/agents/reviews/ING-6a/evidence/r2-04-local-tests.png)) |
| Round-1 27-mutant table, unchanged | local only, never pushed | 27/27 KILLED in the full package. M23/M24 show SURVIVED under `-run '^TestArxivFeedRequest$'`, which is the round-1 table's target, not their killing test ([r2-05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12b2bae8e0ff3d1c3fc9cc20a93a85aa5f2bb9b1/agents/reviews/ING-6a/evidence/r2-05-mutants-27.png)) |
| Round-2 table: findings 1–4 mutants with the right `-run` target, plus M28–M34 | local only | **11/11 KILLED in both the full package and `-run '^T$'`**; every failing subtest listed ([r2-06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12b2bae8e0ff3d1c3fc9cc20a93a85aa5f2bb9b1/agents/reviews/ING-6a/evidence/r2-06-mutants-r2.png)) |
| `make eval` | not run: no retrieval or answering change | n/a |

### Round-1 findings, checked one by one
| # | Round-1 finding | Round 2 |
|---|---|---|
| 1 | [blocking] M5 (undated-skip guard dead) survived | **Fixed.** M5 is killed in both runs by 3 rows: `page_ending_[<=W,_undated]_stops`, `out_of_order_across_an_undated_entry`, `first_run:_undated_not_a_candidate`. These match round-1 probe cases (a), (b) and (c). Each row also pins its own part of the guard: M33 (an undated entry resets only the boundary) is killed only by the page-ending row, M34 (resets only `prev`) only by the out-of-order row, and M32 (both) by those two (r2-06) |
| 2 | [nit] `DefaultRetry` unasserted (M23) | **Fixed.** `TestNewArxivFeedDefaults` compares Attempts/Base/Max (the unexported `wait` is nil in `DefaultRetry`). M23 and M30 (Max dropped) are killed in both runs |
| 3 | [nit] nil-limiter fallback untested (M24) | **Fixed.** The test asserts non-nil and `Interval() == arxiv.DefaultInterval`. M24, M28 (`NewLimiter(0)`) and M29 (given limiter ignored) are killed in both runs |
| 4 | [nit] `ctx.Err()` in walk untested (M27) | **Fixed.** Subtest `ctx_cancelled_between_requests` asserts `context.Canceled`, `got == nil` and exactly one request. M27 and M31 (returns partial candidates on cancel) are killed in both runs |
| 5–8 | for pm-lead | Decided in the ticket on 2026-11-17: nit 5 needs no action; AC4 amended (6); ING-6f created for Risk 1 (7); Done rule added (8) |

### Acceptance criteria (this PR's part)
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | Every design row is present and passes (r2-04). The undated guard is now pinned (finding 1, r2-06) |
| AC2 | ✅ | `out_of_order` is asserted in every row, including the new `1` row across an undated entry. M7 and M34 are killed (r2-05, r2-06) |
| AC3 | ✅ | `TestSelectBatch`; M3 and M14 killed in both runs (r2-05) |
| AC4 (amended) | ✅ | `loop_test.go:189` asserts exactly the amended bytes `max_results=2&search_query=cat%3Acs.LG&sortBy=submittedDate&sortOrder=descending&start=0` ([r2-07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/12b2bae8e0ff3d1c3fc9cc20a93a85aa5f2bb9b1/agents/reviews/ING-6a/evidence/r2-07-ac4-ac10-body.png)). Limiter spacing, UA, 429 retry, and non-200 → `*arxiv.StatusError` (not parsed) are all covered; M20–M22, M25, M26 killed (r2-05) |
| AC5 | ✅ | `TestParseCategories`; M16–M19 killed (r2-05) |
| AC6, AC7 | n/a here | ING-6a1, #57 (Done rule) |
| AC8 | ✅ | M1–M4 killed by the named tests in the full package and with `-run '^T$'` (r2-05) |
| AC9 (this part) | ✅ | Only the 2 new files, 426 added lines (r2-04). CI Go job (vet, gofmt, `go test ./...`) and all 6 checks green (r2-00, r2-03) |
| AC10 (decided) | ✅ met as worded | The PR body quotes the fixture's `2023-07-17T17:50:36Z` then `2024-01-22T09:00:00Z` and says they're ascending. The fixture is unchanged by the PR (r2-07). Risk 1 now goes to ING-6f, per the pm-lead decision |

**Design check:** the rework is test-only, and conditions 1, 3–6, 8 and 10 still hold. Condition 6's defaults are now tested. No new deviation.
**PRD fit:** this is the pure "decide" half of the scheduled crawler (Technical PRD §11). Politeness (§9) holds: one shared limiter, never unthrottled (now pinned by M24/M28/M29), `DefaultRetry`, and an identifying UA. Nothing calls the code yet, so runtime behaviour is unchanged.
**Regression risk:** no contract file is touched. No other open PR (#51–#55, #57) touches `internal/crawler/` or `internal/arxiv/`.

### Findings
1. **[nit]** The PR description is stale since the rework. It still says `398 lines`, "ING-6a1 … **No PR yet**" (now #57), "11 walk rows", and leaves AC10 unticked as "not met as worded", although pm-lead ruled it met. Its mutant table also lacks M5/M23/M24/M27 and their killing rows. pm-lead rewrites the body at the raise (r2-07, PR-body lines 7, 8, 57, 72).
2. **[nit]** At 426 changed lines the PR is over the 400 target (CI warning) but under the condition-8 gate of 480. Informational only; no action.

No blocking findings. All 4 round-1 developer findings are fixed and proven by mutants.

### Missing tests
None found in round 2: every round-1 gap now has a test, and none of the 34 distinct mutants (M1–M27 + M28–M34) survives.

### Hand-off
**PASS** → pm-lead final review (ING-6a2 / #56). ING-6a stays not Done until #57 (ING-6a1) also merges (Done rule).
