<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/33#issuecomment-6713440989 (the QA harness could not write report.md). -->

[qa-reviewer] **QA report: ING-11 · PR #33 · round 1. Verdict: PASS**

**Reviewed commit:** `3f1c32d92bd7ccae55b97af3f310cf8a43780844` · 2026-11-07 · Ticket `agents/tasks/ING-11.md` · Design `docs/design/ING-11.md` (conditions 2, 3, 7, 8) · PRD: Product ING-3, QA-3, §7 principle 3; Technical §5, §6.1–6.2; ADR-0014
Evidence (commit `a30c246`): https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence
I reviewed independently from the spec, the design, the diff and the CI job logs I fetched myself. I didn't rely on the developer's notes.

### Test results
| Check | Source | Result |
|---|---|---|
| All 6 check runs on head | CI | green ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/00-ci-checks.png?raw=true))`` |
| Python M0 (`make test-py`, now incl. `tests/test_processor_pages.py`) | CI job 128533106203 | `92 passed, 1 skipped` |
| Go (vet, gofmt, test) | CI job 128533106017 | `ok arxivlens/internal/db` |
| DB migrate twice | CI job 128533105508 | 000003 applied in both runs, diff empty, 71 objects (67 before) |
| Full stack | CI job 128533181081 | `104 passed, 1 skipped, 3 deselected`, DLQs 0. The "Known failure F1" step (`continue-on-error`) has its documented, pre-existing 3 M3 timeouts |
| PR's AC2b/AC2c tests vs real `worker.py`/`db.py` | local, stubbed PyMuPDF/psycopg/kafka/minio | `6 passed` |
| AC2 snapshot + vocabulary tests | not run locally: no PyPI/HF in the sandbox | CI only |
| `TestRepoMigrationsOrder` | local go1.24 scratch module with the real sources + `migrations/` (go.mod needs 1.25) | PASS; negative control FAILs |
| `make eval` | not run: chunk text identical (AC2) | n/a |

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| **AC2** chunk output unchanged, before/after | ✅ | `59bbae1` (test + Makefile only): python job 128531883258 red by design, prints the snapshot, and the only failure is the snapshot test. `ef238b5` (literal pinned, production code identical to main 2b71772): job 128532662362 **green** `86 passed`. `3f1c32d`: job 128533106203 **green** `92 passed` ([01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/01-ac2-before-after-ci.png?raw=true)).``` The literal at `ef238b5` and at head equals the JSON CI printed on unchanged code. The head test file is append-only, and the snapshot test, fixture builder, `snapshot` and vocabulary test are byte-identical before/after ([02](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/02-ac2-snapshot-provenance.png?raw=true)).```` On 3000 random fake docs, sections from `_parse_doc_sections` at main and at head are byte-identical (`title/level/text/page`, key and section order), and `page_breaks` is the only added key ([04](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/04-ac2-random-identity-oracle.png?raw=true)).````` |
| **AC2b** `page_breaks` invariants, vocabulary asserted up front | ✅ | `test_page_breaks_invariants` + `test_fixture_vocabulary_is_single_wordpiece` are green in CI and locally ([03](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/03-ac2b-ac2c-local-pytest.png?raw=true)).`````` An independent per-line page oracle matches `page_breaks` exactly on 13,190 random sections (3,934 with ≥ 2 breaks) ([04](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/04-ac2-random-identity-oracle.png?raw=true)).``````` |
| **AC2c** `db.py` write path (fake cursor, table-driven) | ✅ | `test_save_chunks_page_rows` (4 rows) + `test_save_chunks_page_rows_use_each_returned_id` cover the `RETURNING id` id, the upsert value, `DELETE` when missing, the unchanged `page_number` and no commit ([03](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/03-ac2b-ac2c-local-pytest.png?raw=true)).```````` Mutation run: 14/17 killed. The survivors: W6 (text bytes) is the CI snapshot's job and QA check 04 kills it; W8 is finding 1; D9 (`page_start == 0`) is outside the 1-based contract ([05](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/05-mutation.png?raw=true)).````````` |
| **AC5** migrate twice; `TestRepoMigrationsOrder`; `stack.yml` | ✅ | db.yml: 000003 runs in both migrate runs, the schema diff is empty, 71 vs 67 objects (+2 columns, +pkey, +index_valid). The rows themselves aren't printed, so the table's presence is inferred from that count ([06](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/06-ac5-db-migrate-twice.png?raw=true)).`````````` Go job `ok arxivlens/internal/db`, plus a local PASS with a FAIL negative control ([07](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/07-ac5-migrations-order.png?raw=true)).``````````` stack.yml: processor image built from the PR, both papers `chunked` → `embedded` (through the new `RETURNING id` + `DELETE` path), DLQs 0 ([08](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/08-ac5-stack.png?raw=true)).```````````` |
| **AC6** < 400 changed lines | ✅ | 7 files, +244 −5 = 249. Ownership check OK ([09](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/09-ac6-diffstat-scope.png?raw=true)).````````````` |

**Design conditions:** 2 ✅ (fallback path: red literal-printing first commit, then green on unchanged code; test unaltered afterwards). 3 ✅ (own file, no `page_start` dependency, module-level helpers). 7 ✅ (249 lines). 8 ✅ (backfill section marked as Mahesh's decision, no reprocessing: [11](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/11-cond8-pr-backfill.png?raw=true)).`````````````` Decisions 2/3/4: DDL verbatim, the append reads only `len(text)`, signature kept ([10](```````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a30c24636ebdf0ba9574487da22335a9b0eb7e6c/agents/reviews/ING-11/evidence/10-design-prod-diff.png?raw=true)).```````````````

**Scope:** all files backend-owned, nothing out of scope, no file overlap with open PRs #24 and #26–#32.
**PRD fit:** lays the producer side of §7 principle 3 / QA-3 with "no row = unknown" by construction (ADR-0014), written in the processor's L2 transaction. Chunk text, embeddings and search are unchanged.

### Findings
1. [nit] **The Abstract-bucket path (`worker.py:118`) is untested.** The fixture opens with a 16 pt title, so the initial `Abstract` dict never receives text. Mutant W8 drops its `page_breaks` key, which would raise `KeyError` on papers with body text before the first heading, and it survives the PR's tests. The code is correct (QA check 04 kills W8). Suggest AI-11 or a follow-up add a fixture with body text before the first heading, plus a "heading at the bottom of page N, body on N+1" case.
2. [spec] AC2's wording ("first pushed commit ... green") is stricter than the binding design condition 2, which allows the print-then-pin fallback the PR used. pm-lead: align the ticket.
3. [spec] `CONTRIBUTING.md:23` lists the `make test-unit` pytest files and now omits `tests/test_processor_pages.py`. The developer correctly deferred it because open PR #26 edits that file (AGENTS.md §3). It isn't on the board: pm-lead should file the follow-up for after #26 merges.

### Missing tests
- Abstract bucket receives text (finding 1). Heading at a page bottom with its body on the next page.
- For AI-11: `page_start == 0` → `CHECK` violation → transaction rollback → retry/DLQ (fail-loud). Worth asserting that the chunker never emits 0.

**Hand-off:** PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_
