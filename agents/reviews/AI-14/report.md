# QA report — AI-14 · PR #115 · round 1

**Verdict:** PASS
**Reviewed commit:** `f2337c3218cb315169a831ae990852e2d1698a94` · **Date:** 2026-11-21
**Ticket:** `agents/tasks/AI-14.md` (Jira KAN-121) · **PRD:** Product QA-6; Technical §7.2 (aux cutoff 0.70) · **Design:** none (not design-required)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136902184318 | pass (`ok arxivlens/internal/query`) — [00](evidence/00-ci-checks.png), [05](evidence/05-ci-go-job.png) |
| Full stack (compose + make test-full) | CI job 136902184347 | pass (completed 16:20:19Z) — [00](evidence/00-ci-checks.png) |
| Python M0 unit tests | CI | pass |
| Frontend (lint, test, build) | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Agent ownership check | CI | pass |
| `go test ./internal/query/ -run 'Filter\|Relevant' -v` | local, partial | not runnable as-is: sandbox has Go 1.24.7, `go.mod` needs 1.25 and the toolchain download is blocked. Instead, `filterRelevantHits`, `tableWordRegex`, `isAuxiliarySection`, `SearchHit`, `hitContent`, `ragHit` and `TestFilterRelevantHits` were extracted **verbatim via go/ast** from the PR head into a Go 1.24 scratch module: 19/19 subtests pass — [01](evidence/01-ac1-ac2-filter-tests.png); harness source [06](evidence/06-qa-harness.png). Line numbers like `rag_test.go:59` in local output refer to the scratch file |
| `make test-unit`, `make lint` | not run locally (Go 1.25 / modules unavailable) | CI Go job runs `make lint-go` + `make test-go` (race): pass |
| `gofmt -l internal/query/` | local (Go 1.24 gofmt) | clean |
| `git diff origin/main --name-only` | local | exactly `internal/query/rag.go`, `internal/query/rag_test.go` — [02](evidence/02-ac2-ac3-test-diff.png) |
| `make eval` | not run | `eval.yml` triggers only on `workflow_dispatch`, schedule, or PR paths `.github/workflows/eval.yml` / `scripts/arxiv_replay.py`; this PR's paths don't trigger it and no dispatch run is attached. PR states "not run: <reason>" as AC6/DoD 3 allow. Retrieval (Recall@5) is untouched; see nit 2 |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 whole-word `table`/`tables`, case-insensitive; Notable/Stable/Suitable/Timetable kept, "Table 3: Hardware"/Tables/"Results tables"/table-2 dropped at 0.5 | ✅ | `rag.go` `tableWordRegex = (?i)(^\|[^\pL])tables?([^\pL]\|$)` + `isAuxiliarySection`; rows `word containing table kept: {Notable,Stable,Suitable,Timetable}`, `tables plural section dropped`, `tables as last word dropped`, `table followed by hyphen dropped`, existing `table section dropped` ("Table 3: Hardware", 0.5) all pass — [01](evidence/01-ac1-ac2-filter-tests.png); CI `ok arxivlens/internal/query` — [05](evidence/05-ci-go-job.png) |
| AC2 appendix/supplementary unchanged (substring, case-insensitive) + "Supplementary Material" 0.5 dropped | ✅ | Helper keeps `strings.Contains(lower, "supplementary"/"appendix")`; existing rows (Appendix A 0.69/0.70, SUPPLEMENTARY Material, appendix@0, mixed) unmodified and pass; new row `supplementary material dropped` passes — [01](evidence/01-ac1-ac2-filter-tests.png), [02](evidence/02-ac2-ac3-test-diff.png). Mutations m4 (drop appendix) and m5 (drop supplementary) are caught — [03](evidence/03-ac4-mutations.png) |
| AC3 every existing `internal/query` test passes unmodified | ✅ | `rag_test.go` diff: 0 removed lines, 9 added — [02](evidence/02-ac2-ac3-test-diff.png); CI `go test ./...` (`-race`) `ok arxivlens/internal/query` — [05](evidence/05-ci-go-job.png) |
| AC4 mutations m1/m2/m3 each fail a named row | ✅ | QA re-ran independently on copies of the PR-head `rag.go`: m1 (substring `table`) → 4 "kept" rows FAIL; m2 (no plural) → `tables plural section dropped`, `tables as last word dropped` FAIL; m3 (no `(?i)`) → `table section dropped` ("Table 3: Hardware") + `tables plural section dropped` FAIL — [03](evidence/03-ac4-mutations.png). Extra probes: m6 (no left boundary) caught; m7 (no right boundary) **survives** — [03b](evidence/03b-ac1-boundary-probes.png), see nit 1 |
| AC5 `parseSynthesis` comment fixed, comment-only | ✅ | Hunk `@@ -663,4 +663,5` changes only `//` lines; new text names the quoted-answer fallback `claims_unsupported` and drops the `all_citations_unsupported` claim. Matches code: `synthesize` → `finalizeClaims` nil → `return fallback("claims_unsupported")` (`rag.go:287`), pinned by `synthesis_test.go` "citations fabricated" (claims=0 → quoted answer, `reason=claims_unsupported`) — [04](evidence/04-ac5-comment-hunk.png) |
| AC6 CI Go + Full stack green; eval "not run: <reason>" stated | ✅ | All 6 check runs `completed success` on `f2337c3` — [00](evidence/00-ci-checks.png); PR body Verification table: `make eval` "not run: only rag.go/rag_test.go changed ..." |

## Scope check
- Changed files: `internal/query/rag.go`, `internal/query/rag_test.go` only — both ai-engineer paths (AGENTS.md §2); ownership CI green. No ticket/review/doc files in the PR.
- Cutoffs `0.45` / `0.70` unchanged; no change to the zero-rerank bypass (AI-5/ADR-0011 territory); "Appendices" not added (listed in the PR as a follow-up, as the ticket asks). No contract, schema, threshold or API change. Diff is +26/−4.

## PRD fit
QA-6 asks to de-prioritize appendix/supplementary/**table** passages. The old substring match also penalized ordinary sections like "Notable results" or "Stable training", silently dropping relevant 0.45-0.70 passages from `/v1/ask` evidence (against "evidence first"). The whole-word match removes those false positives and keeps every true table section penalized, so it serves QA-6 more faithfully. Technical §7.2's filter diagram and constants are unchanged.

## Findings
1. [nit] [code/test] The right-hand word boundary is not pinned by any test: removing `([^\pL]|$)` from `tableWordRegex` (m7) leaves all 19 subtests green ([03b](evidence/03b-ac1-boundary-probes.png)). The implementation is correct, but a regression would again penalize e.g. "Tablet-based evaluation" or "Tableau". Suggest one row at 0.5, e.g. `ragHit(1, "Tablet experiments", 0.5)` → kept. AC1's listed rows are all present, so this does not block.
2. [nit] [PR text] The PR's eval note says "no Recall@5 regression expected". Recall@5 doesn't depend on `filterRelevantHits` at all (retrieval is in `search.go`). What this change can affect is `/v1/ask`: passages from "Notable/Stable/..." sections at 0.45-0.70 are now kept, which can move supported-citation and correct-refusal rates slightly. The direction is intended and the nightly `eval.yml` schedule will show it. The reason given is acceptable for DoD 3, just slightly misaimed.
3. [spec] none. The ticket was clear and testable.

## Missing tests
- Right boundary: a title with "table" as a prefix of a longer word ("Tablet ...", "Tableau") should be kept (nit 1).
- Optional: an uppercase whole-word title such as "TABLES" (case-insensitivity is already covered by "Table 3: Hardware" vs m3, so this is low value).

## Hand-off
PASS → pm-lead final review. Nits 1-2 are optional for the developer.

### Evidence files
- `evidence/00-ci-checks.png` — AC6: CI check runs on head
- `evidence/01-ac1-ac2-filter-tests.png` — AC1/AC2: TestFilterRelevantHits at PR head (verbatim-extracted scratch module)
- `evidence/02-ac2-ac3-test-diff.png` — AC2/AC3: changed files, test diff with 0 removed lines
- `evidence/03-ac4-mutations.png` — AC4: mutations m1-m7 (full text in `.txt`)
- `evidence/03b-ac1-boundary-probes.png` — test quality: m6 caught, m7 survives
- `evidence/04-ac5-comment-hunk.png` — AC5: comment-only hunk + code path
- `evidence/05-ci-go-job.png` — AC3/AC6: CI Go job lint-go/test-go excerpt
- `evidence/06-qa-harness.png` — QA harness source (extract.go, run.sh, mutate.sh)

---

## PM final review (pm-lead) · 2026-11-21

**Verdict:** APPROVE · **Reviewed head:** `f2337c3218cb315169a831ae990852e2d1698a94` · **QA:** round 1 PASS (evidence commit `78d47f7`)

**PRD fit.** QA-6 asks to de-prioritize appendix, supplementary and *table* passages. The old substring match also penalized ordinary sections ("Notable results", "Stable training"), which dropped relevant 0.45-0.70 passages from `/v1/ask` evidence. That works against Product PRD §7 "evidence first" and hurts the researcher persona. The whole-word `table|tables` rule is the narrowest reading of QA-6: it removes those false positives, adds none, and keeps every true table section penalized. Technical §7.2 constants (0.45 / 0.70) are unchanged. The PRD QA-6 row is already ✅ and stays correct. No README change is needed because the API and commands are unchanged.

**Scope.** Exactly `rag.go` and `rag_test.go`, +26/-4, all within ai-engineer paths. Nothing is missing: AC1 has all 8 listed rows, AC2 has the new "Supplementary Material" row, and the AC5 hunk is comment-only. Nothing extra: "Appendices" is listed as a follow-up and was not added, and the zero-rerank bypass (AI-5/ADR-0011) is untouched.

**Evidence (all 8 files opened):**
- 00: six CI check runs succeed on `f2337c3` (AC6). I re-queried them at review time and all are still success.
- 01: 19/19 subtests pass, including every AC1/AC2 row by name. The PR code was extracted verbatim via go/ast, and 06 shows the harness, so the result is reproducible.
- 02: only the two expected files changed, and `rag_test.go` has 0 removed lines (AC2/AC3).
- 03: m1, m2 and m3 each fail the named rows (AC4). m4 and m5 are an extra check that appendix/supplementary are still pinned.
- 03b: m6 is caught and m7 survives (nit 1 below).
- 04: the comment-only hunk, plus `return fallback("claims_unsupported")` at `rag.go:287`, proves AC5.
- 05: the CI Go job ran `go vet`, then `go test -race ./...`, with `ok arxivlens/internal/query` (AC3/AC6).

No "unverified" item remains on any AC. The local Go 1.25 gap is covered by CI, which is the source of truth (AGENTS.md §4).

**QA nits:**
1. Nit 1 (right word boundary not pinned, so m7 survives) is **not blocking**. Every AC1 row is present, the regex is correct, and AC1 did not ask for a prefix row. That was a gap in my spec, not in the code. It goes to a follow-up: add a `"Tablet experiments"` at 0.5 → kept row. Pair it with the "Appendices" follow-up so both land in one small ai-engineer ticket on `rag_test.go`/`rag.go`.
2. Nit 2 (the eval reason names Recall@5) is **accepted, and I fixed it in the PR description** when raising the PR. `filterRelevantHits` doesn't affect retrieval Recall@5. It can only change `/v1/ask` supported-citation and correct-refusal rates, in the intended direction, and the nightly `eval.yml` will show any shift.

**Lesson for pm-lead:** when an AC lists keep/drop rows for a word-boundary rule, include at least one row per boundary side, for example a prefix-of-longer-word row like "Tablet".

**Action:** I'm raising PR #115 (ready for review) with the evidence in its description. Next: Mahesh reviews and merges.
