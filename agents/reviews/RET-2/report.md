<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-08 12:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/35#issuecomment-6721337043, because the QA harness could not write report.md. -->

[qa-reviewer] **QA RET-2 round 1: PASS** (head `3bf5dab`, CI on merge `1a9ee6c` = head + main `9651294`)

The harness refused to write `agents/reviews/RET-2/report.md` (subagent restriction), so this comment is the report of record. The orchestrator saves it verbatim. Evidence: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/main/agents/reviews/RET-2/evidence (images pinned to `d09d36b`).

**Ticket:** agents/tasks/RET-2.md · **PRD:** Product QA-3, ING-7, §7 principle 3; Technical §5, §7.1; ADR-0014 (Accepted) · **Design:** docs/design/RET-2.md (conditions 1–7)

### Pre-checks
- PR is open, draft, `merged=false`, `mergeable_state=clean`. The branch merge-base is `d3f9408` (ING-11 #33), so the PR was built on top of ING-11.
- All 6 CI jobs checked out `refs/pull/35/merge` = `1a9ee6c`, whose parents are `9651294` (current main, includes #34 and #36) and `3bf5dab` ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d09d36b795f2d8d767fc7b4cd1f6c5d3ba017b47/agents/reviews/RET-2/evidence/00-ci-checks.png?raw=true)).`` The two later main commits share no file with this PR.

### ING-11 interaction
([08](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d09d36b795f2d8d767fc7b4cd1f6c5d3ba017b47/agents/reviews/RET-2/evidence/08-ing11-interaction.png?raw=true))```
- No Go code reads `paper_chunk_pages`/`page_start` at the merge commit. The only writer is `db.py:126-132`, and only when a chunk carries `page_start`. AI-11, the chunker that emits it, has not merged. The consumer is ING-11b, which depends on RET-2 being merged. So `page` is still correctly omitted for every hit, and the title ("until ING-11b") is accurate.
- The 08:49Z comment cites job `128676482889`, but that is **#34's** DB job (head `ff1bd48`, OPS-H8b) and it **succeeded**. RET-2's real failure was job `128673836567` (`b1c5b9b` merged onto `d3f9408`, with ING-11 already on main). Its PROVENANCE lines were all correct; the job failed only in teardown: `search_provenance_integration_test.go:43: cleanup: closed pool`. Fix `3bf5dab` is test-only and one line (`t.Cleanup(d.Close)` registered first). It changes no assertion.
- Cleanup still works with migration 000003: deleting the `prov.%` papers cascades to `paper_chunks` and then to `paper_chunk_pages`.

### Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI 128681427414 on `1a9ee6c` | pass |
| Python M0 unit tests | CI 128681427223 | pass (114 passed, 1 skipped; kafka client 37 passed) |
| DB (migrate ×2, HNSW + provenance) | CI 128681427063 | pass (`--- PASS: TestHNSWVectorHits`, `--- PASS: TestSearchProvenance`) |
| Full stack / Frontend / Ownership | CI 128681427389 / 128681427461 / 128681427417 | pass / pass / pass |
| `pytest tests/test_evals_data.py` + 3 guards by node ID | local, head and merge commit | 97 passed, 1 skipped (DB opt-in); 3/3 PASSED |
| `make lint` / `make test-unit` | not run locally: Go 1.25 toolchain download blocked. CI is the source | — |
| Go unit tests, independent | local Go 1.24.7 scratch module, PR files byte-identical (`cmp`), stubs only for `db`/`pgx`, `-race` | 13/13 PASS ([01](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d09d36b795f2d8d767fc7b4cd1f6c5d3ba017b47/agents/reviews/RET-2/evidence/01-ac1-unit-tests.png?raw=true))```` |
| Integration test locally | not run: no pgvector in the sandbox. CI `db.yml` is the evidence | — |
| `make eval` | not run: no ranking change (golden == main, mutants M10–M13) | n/a |

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `Version int json:"version"` (no omitempty) and `Page *int json:"page,omitempty"`, never set. `TestSearchHitJSON` and `TestSearchHitProvenanceTravelsWithHit` pass ([01](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d09d36b795f2d8d767fc7b4cd1f6c5d3ba017b47/agents/reviews/RET-2/evidence/01-ac1-unit-tests.png?raw=true)).````` Real JSON from the production path has `version` on every hit and no `page` ([02](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d09d36b795f2d8d767fc7b4cd1f6c5d3ba017b47/agents/reviews/RET-2/evidence/02-ac2-db-provenance.png?raw=true)).`````` |
| AC2 | ✅ | `TestSearchProvenance` on real pgvector, DB job 128681427063 L1469–1473: v1 chunk → `version=1`; both v2 chunks (page_number 4, 7) → `version=2`; `page=<nil>` and no `"page"` key on **all 3** hits (condition 3). Run pattern is the literal `'TestHNSW\|TestSearchProvenance'` (L386, condition 4). [02](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d09d36b795f2d8d767fc7b4cd1f6c5d3ba017b47/agents/reviews/RET-2/evidence/02-ac2-db-provenance.png?raw=true)``````` |
| AC3 | ✅ | Whole file plus the 3 guards by node ID pass at the head and on the merge commit. The only change is one `_GO_TO_EVAL_SQL` fragment, and `scripts/` is untouched (condition 1). [03](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d09d36b795f2d8d767fc7b4cd1f6c5d3ba017b47/agents/reviews/RET-2/evidence/03-ac3-parity-guard.png?raw=true).```````` Mutants P01–P04 are each killed by `test_rrf_pool_sql_mirrors_search_go`, and the control is green ([06](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d09d36b795f2d8d767fc7b4cd1f6c5d3ba017b47/agents/reviews/RET-2/evidence/06-mutation.png?raw=true)).````````` |
| AC4 | ✅ | `search_test.go`, `search_integration_test.go`, `rag*.go` and `scripts/` have a zero diff. `search.go` changes only the struct, the outer SELECT and the scan ([04](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d09d36b795f2d8d767fc7b4cd1f6c5d3ba017b47/agents/reviews/RET-2/evidence/04-ac4-ranking-unchanged.png?raw=true)).`````````` QA check: the PR's golden SQL equals main `9651294` byte for byte, and the PR SQL = main + 11 bytes. TestHNSW: 4/57 rows differ from main, all custom-plan cs.CL rows, by ≤ 0.01. Two main runs with the same `search.go` differ in 10/57, so this is noise. 0 generic/auto/hybrid rows differ. |
| AC5 | ✅ | README row has condition 2's wording and matches `server.go:118-120`. 384 changed lines in 6 files. [05](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d09d36b795f2d8d767fc7b4cd1f6c5d3ba017b47/agents/reviews/RET-2/evidence/05-ac5-readme-size.png?raw=true)``````````` |

**Design conditions 1–7:** all met (details in the evidence). Condition 6: the version line now says ING-10 (#31) fixed the label at the source. ING-10 is merged, so that is accurate.

### PRD fit
Each hit now carries the version of the record that owns its chunk (ING-7). The section-start page is never passed off as the chunk's page, which follows ADR-0014 and the honesty principle. This is the provenance input that QA-3 and §7 principle 3 need through AI-8, at the cost of one extra column and no ranking change.

### Findings
1. [nit] `search.go:33-34` says "ING-11 fills Page … once its query side lands". The query side is now ticket **ING-11b**, so the comment should name it.
2. [nit] The PR body's PRD ref ("RET …") should list QA-3, ING-7, §7 principle 3 and Technical §5/§7.1. Condition 4's job-line links are in this pack (02, 04) for pm-lead's Evidence section.
3. [nit] The NaN and `context.Canceled` fallbacks are not in `TestSearchHitProvenanceTravelsWithHit`. They share one return path, and mutant M16 is killed, so the risk is low.
4. [info] The 08:49Z comment cites the wrong job and the wrong cause (see ING-11 interaction). Nothing needs rework for ING-11.
5. [spec] `agents/tasks/RET-2.md` Status still says the build waits for #26 (merged `54cad79`). AC2's "real chunk pages → ING-11" should now say ING-11b.

### Missing tests
- NaN and Canceled fallback rows (nit 3).
- Optional: seed one `paper_chunk_pages` row in the integration test and assert `page` is still absent until ING-11b.
- Mutant M15 (set `h.Page` in `fetchCandidates`) survives the unit tests by design. The integration assertion at `search_provenance_integration_test.go:124` covers it, and that assertion held in CI.

### Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_
