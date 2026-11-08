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

---

# PM review — ING-11 (part a) · PR #33 · head `3f1c32d92bd7ccae55b97af3f310cf8a43780844`

[pm-lead] **Verdict: APPROVE** · **Date:** 2026-11-08 · **Reviewer:** pm-lead

## What I checked
- **Ticket vs diff.** `gh api …/pulls/33/files` returns 7 files, +244/−5 = 249 lines, all in the ticket's Scope and all owned by backend. Base `2b71772` is still `main`, so CI ran against the current main, and the PR is `mergeable_state: clean`. Every Scope bullet is delivered: `page_breaks` on both section-dict sites, with the append just before the only text write (it reads only `len(text)`); migration 000003, matching design decision 2 word for word; `RETURNING id`, then upsert or `DELETE` in the same cursor, with no commit and `page_number` unchanged; `TestRepoMigrationsOrder` `want` updated; the new test file runs in `make test-py`, and its helpers (`build_fixture_doc`, `parse_fixture_sections`, `first_word_page`, `snapshot`, `PAGE_VOCAB`) are module-level. Nothing extra: no chunker, search, README or reprocessing changes.
- **Design conditions.** 2: the fallback path the design allowed (`59bbae1` prints the snapshot, `ef238b5` pins it and is green on unchanged production code, `3f1c32d` is green with the test unmodified). 3: own file, no `page_start` dependency, reusable helpers. 7: 249 lines, no split. 8: the backfill how-to is in the PR body, marked as Mahesh's decision. Decision 4 (ING-8 contract): name, `(self, doc)` signature and no instance state are kept (evidence 10).
- **PRD fit.** This is the producer half of Product PRD §7 principle 3 ("one click to the source") and QA-3 / ADR-0014's "`page` only when the chunker recorded it". "No row = unknown" holds by construction, so every legacy and fixture chunk stays unknown without being touched, and the row is written inside the processor's L2 transaction (Technical PRD §8.1). Nothing changes for users yet: chunk text, embeddings and `/v1/search` are byte-identical until AI-11 and ING-11b. That's right for a part-a PR; the persona value lands with ING-11b → AI-8 → FE-4.
- **Evidence.** I opened all 12 PNGs and their `.txt` files (00–11 at `a30c246`). Each image shows the *result* for its AC, not just the command: 00 six checks success; 01 the red→green→green sequence with `86 passed` → `92 passed` (+6 = the AC2b/AC2c tests, so they ran in CI on real PyMuPDF/BGE); 02 literal == CI-printed and test/helpers byte-identical before → after, no production diff before the pin; 03 the 6 named tests PASSED; 04 `failures=0` over 3000 docs / 13,190 sections (the renderer colours the whole line red, but the text and exit code 0 are what count); 05 14/17 killed with the survivors explained; 06 000003 in both migrate runs, `Schema identical after run 2: 71 objects` vs 67; 07 CI `ok arxivlens/internal/db` plus a local PASS/negative-control FAIL; 08 both papers `embedded`, DLQs 0, `104 passed`, job conclusion success; 09 diffstat 249 and ownership OK; 10 the production diff; 11 the backfill paragraph. No AC rests on "⚠ unverified".
- **AC5 table presence.** `db.yml` doesn't print the table's rows, so its presence is inferred: the +4 objects (2 columns, pkey, index_valid) match exactly what 000003 creates. I accept that for part a. ING-11b adds the explicit `grep paper_chunk_pages.page_start` to `db.yml` (its Scope), which closes the gap.
- **Docs (DoD 4).** README: no change needed (no command, API or behaviour change). PRD status columns: no change (design condition 9; ING-3/QA-3 are already ✅). Technical PRD §5/§6.2 get a pm-lead docs PR after ING-11b. `CONTRIBUTING.md:23` is stale (QA finding 3, below). The developer correctly didn't edit it, because open PR #26 edits that file (AGENTS.md §3).

## Decisions on QA findings
1. **[nit] Abstract bucket / heading at the page bottom untested.** Agreed. Mutant W8 survives the PR's own tests, and only QA's random-doc oracle kills it. This doesn't block: the code is correct, and the AC2 snapshot plus QA's oracle prove it. The CI gap moves to a new **AI-11 AC5** (a second fixture with body text before the first heading and a heading as the last line of page N; `page_start >= 1` on every chunk). AI-11 appends to this test file anyway, and at that point the layout produces observable `page_start` values.
2. **[spec] AC2 wording stricter than design condition 2.** Fixed in `agents/tasks/ING-11.md`: AC2 now states condition 2's fallback (print, then pin, both green on unchanged production code) and has a dated note. This isn't a weakening: the binding design already allowed it, and the before/after proof is the same.
3. **[spec] `CONTRIBUTING.md:23` misses `tests/test_processor_pages.py`.** Filed: a board Backlog line (backend, P3, one line, first backend PR that starts after #26 merges), with ING-11b's Scope as the backstop.

## Non-blocking notes
- A `DELETE FROM paper_chunk_pages` per chunk runs on every processing until AI-11 merges. It's a PK lookup in the same transaction and negligible next to PDF parsing. Noted in case of future profiling.
- Pre-existing, unchanged: a reprocess that yields fewer chunks leaves old higher-index chunk rows and their page rows in place (design Risks).
- The `if chunk.get("page_start") is not None` check means a `0` would reach the `CHECK` and fail the transaction loudly (retry/DLQ), which is the right fail-loud behaviour. AI-11 AC5 asserts the chunker never emits it.

## Process note
A previous pm-lead session (session `…UhFvHPuToYXMWFNo2`) had already PATCHed PR #33's body at 21:50Z with an APPROVE text. That body cited AI-11 AC5, an aligned AC2 and a board follow-up, none of which existed in this repo, and it committed nothing here. This review re-derives the verdict from the evidence, makes those repo records true, and rewrites the body. See the lessons entry.

## PR raised (2026-11-08)
- Description rewritten from `agents/templates/pr.md` with REST `PATCH`: What changed, the literal `git diff --stat`, all ACs ticked with run IDs, Verification, the backfill section (Mahesh's decision), risks, follow-ups, and an Evidence table with 12 rows. Each row links the PNG, links its `.txt`, and embeds the image, all pinned to `a30c246`. CI results for the head and the QA and PM verdicts are included.
- **Body after PATCH (diffed against what I sent):** lines 1–65 (everything up to the Evidence table) are identical. The environment's outbound filter rewrote the 12 table rows: the `![](…)` embeds lost their `!` and got wrapped in growing backtick runs, so the images don't render inline. It also dropped the 🤖 line and appended `---` / `_Generated by [Claude Code](https://claude.ai/code)_`. This is the same known filter as on #26–#31 (board Backlog). I didn't try to work around it. The pinned URLs still resolve, and the evidence folder link stays the record.
- `POST …/pulls/33/ccr/ready_for_review` → `{"draft":false}`. The PR is open and not merged, and the head is still `3f1c32d`. The `ready-to-merge` label was not added: the label call was denied in this session's environment, so the orchestrator or Mahesh can add it.

Hand-off: Ready to merge → Mahesh. Jira KAN-55 → Ready to merge is the orchestrator's job (not touched here).
