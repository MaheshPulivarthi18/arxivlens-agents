<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/52#issuecomment-6942973559 (the QA harness could not write report.md). -->

[qa-reviewer] QA round 1 for ING-11b, PR #52: **PASS**

**Reviewed commit:** `706e43e` (CI ran on merge ref `2ab3fa8` = 706e43e into current main `40dec5a`) · **Date:** 2026-11-17
**Ticket:** [agents/tasks/ING-11b.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/tasks/ING-11b.md) · **PRD:** Product PRD QA-3, §7 principle 3; Technical PRD §5, §7.1; ADR-0014 · **Design:** docs/design/ING-11.md decision 6, conditions 4/5/6/9
**Evidence pack:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence (pack commit `7fb95e288e81de7fd91bb5516d3b135ff9ee0779`)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 133911818097 | pass ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/00-ci-checks.png?raw=true)) `` |
| DB (migrate twice, HNSW, TestSearchProvenance) | CI job 133911818026 | pass ([02](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/02-AC3-db-provenance.png?raw=true)) ``` |
| Full stack (`make test-full`) | CI job 133911818738 | pass: 234 passed, 1 skipped, 3 deselected (F1) ([10](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/10-AC5-stack-test-full.png?raw=true)) ```` |
| Python M0 / Frontend / Ownership | CI | pass / pass / "Ownership OK for role=backend (139 changed lines)" ([01](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/01-scope-diffstat.png?raw=true)) ````` |
| `make test-unit` / `make lint` | not run locally: go.mod needs Go 1.25, sandbox has 1.24.7 and no proxy | CI green |
| Go unit tests, independent | scratch go1.24 module with the PR's real search.go, client.go, search_test.go, search_provenance_test.go (cmp-identical) + stubs for db/pgx/generateTraceID only | all PASS with -race ([05](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/05-AC4-go-unit-harness.png?raw=true)) `````` |
| Ticket verification (pytest test_evals_data.py + 3 node IDs) | local, PR head | 119 passed, 1 skipped; 3/3 passed ([03](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/03-AC4-parity-pytest.png?raw=true)) ``````` |
| Mutants on search.go (local only, never pushed) | local | 10/10 killed, 0 invalid ([07](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/07-mutants-go.png?raw=true)) ```````` |
| New M2 test probe + mutants (stub psycopg) | local | correct on 8 inputs; 7/7 single-operand mutants killed ([08](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/08-AC5-m2-test-probe.png?raw=true)) ````````` |
| `make eval` | not run: ranking SQL unchanged (AC4) | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC3 | ✅ | [02](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/02-AC3-db-provenance.png?raw=true): `````````` DB job log lines 1490-1492 `PROVENANCE`. "zyxprov beta two" (page_number 7, page row 6) → `page=6`, JSON `"page":6`. "alpha two" (page_number 4, no row) and the v1 NULL chunk → `page=nil`, no `"page"` key. `TestSearchProvenance` PASS. The migrate grep matches `column\|paper_chunk_pages.page_start\|integer` (line 370). |
| AC4 | ✅ | [03](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/03-AC4-parity-pytest.png?raw=true): ``````````` 1 fragment hunk, 0 `scripts/` paths. [04](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/04-AC4-sql-diff.png?raw=true): ```````````` search.go = comment + one outer-SELECT line + scan; search_test.go 0 lines changed. [05](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/05-AC4-go-unit-harness.png?raw=true): ````````````` golden + ordering tests pass. [07](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/07-mutants-go.png?raw=true): `````````````` LEFT JOIN, `c.page_number`, wrong key, `+1`, dropped column/scan, swapped scan, fallback clearing Page, and NaN guard off are all killed. [06](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/06-AC4-hnsw-recall-compare.png?raw=true): ``````````````` TestHNSW identical except 5 iterative custom-plan lines, which also drift main-to-main (finding 2). |
| AC5 | ✅ (PR-text clause: finding 1) | [10](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/10-AC5-stack-test-full.png?raw=true): ```````````````` stack job success; offline collection of the same args = 235 ids = 234 passed + 1 skipped. `tests/test_m2_pipeline.py::test_embedded_chunks_have_recorded_start_pages` is **position 196 (row 3, col 52) → `.`**. Check: the only skipif test (pos 85) lands on the log's only `s`. [12](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/12-AC5-stack-baseline-pr50.png?raw=true): ````````````````` the baseline PR #50 had 233 passed (+1 = the new test). Sources: [13](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/13-dotmap-sources.png?raw=true). `````````````````` |
| AC6 | ✅ | [09](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7fb95e288e81de7fd91bb5516d3b135ff9ee0779/agents/reviews/ING-11b/evidence/09-AC6-readme-size.png?raw=true): ``````````````````` README row has the Scope wording verbatim; CONTRIBUTING lists the six test-py files in Makefile:49 order; 139 changed lines. |

Design conditions 4, 5, 6 and 9 are met; there is no deviation from decision 6. Scope: 8 files, all backend-owned + README, nothing from Out of scope. No contract change beyond ADR-0014's `page?`.

## PRD fit
`/v1/search` hits now carry the page the chunk's text starts on, and only from `paper_chunk_pages`: 6 ≠ 7 proves the section-start `page_number` is never used. When the page is unknown, the field is left out instead of guessed. This is the search half of QA-3 and principle 3 ("one click to the source"); AI-8 and FE-4 build the `#page=N` link on top of it.

## Findings
1. [nit] AC5's last clause ("The PR names the test and how its result shows in the log") is not in this PR's description. QA established it: `test_embedded_chunks_have_recorded_start_pages` at dot 196 (row 3, col 52), summary `234 passed, 1 skipped, 3 deselected` (evidence 10). pm-lead: carry that line into the stage-4 description.
2. [spec] AC4/condition 5 says "TestHNSW recall lines unchanged". The iterative-scan custom-plan lines vary run to run on unchanged main (3 lines differ between 538b2ea and 40dec5a). Here, 5 differ by ≤ 0.01, all upward, while every deterministic line is identical and `vectorHitsSQL` is golden. Suggest wording: "non-iterative lines identical; iterative within main-to-main variance".
3. [nit] Evidence 06 ends `[exit code 1]`: it comes from `grep -c` printing 0 (the expected "no non-iterative line differs") and is not a failure.
4. [nit] `test_m2_pipeline.py`: a NULL `page_number` with a page row is reported as "page_start N < page_number None". It is correctly flagged, but the message is misleading.

## Missing tests
- The M2 check's SQL runs only in stack.yml, which prints dots only (`pytest -q`). A future failure shows up only as an `F` at about position 196. `-rA` for test-full would name it (cf. the OPS-H8 [spec]).
- No real-DB `rerank=true` row with a page row. The unit rows cover Page surviving `rerankAndSort` (mutant M9 killed), so the risk is low.

## Hand-off
PASS → pm-lead final review.

Note: the QA harness refused to write `agents/reviews/ING-11b/report.md`. This comment is the full report; the orchestrator saves it verbatim.


---
_Generated by [Claude Code](https://claude.ai/code)_
