# Tech design — ING-11: Record each chunk's real start page and return it as `page` in search hits

**Author:** backend-engineer · **Ticket:** `agents/tasks/ING-11.md` · **PRD:** Product PRD ING-3, QA-3, §7 principle 3; Technical PRD §5, §6.1–6.2, §7.1; ADR-0014 (Accepted) · **Status:** Approved with conditions (pm-lead, 2026-11-07)

Code references are to the app repo at `origin/main` `2b71772` unless marked "after RET-2" (text from the approved `docs/design/RET-2.md`).

## Problem
Each chunk's `page_number` is the page of its section's heading. `_parse_doc_sections` sets `page` only when it sees a heading
(`services/processor/worker.py:160-165`, Abstract bucket `:118`) and appends body text across pages with no marker (`:167`).
`TokenChunker.chunk_sections` then copies `sec.get("page", 1)` to every chunk (`scripts/m0_skeleton.py:225`). Because of that,
RET-2 leaves `page` out of every hit. This ticket records the page on which each chunk's text starts, stores it so that every
row written so far stays "unknown", and returns it as `page` from `/v1/search` (omitted when unknown, ADR-0014). Covers AC1–AC6.

## Decisions (the Scope's "the design picks one")

### 1. Chunk → page mapping: **(a) inside `TokenChunker`** (paired ai ticket, proposed id AI-11)
- Only the chunker knows where each window starts. The window is `tokens[start_i : start_i + effective_target]` over
  `sec_text = sec["text"].strip()` (`m0_skeleton.py:197,202,212-213`), and its parameters come from the prefix length and
  the constructor values (`:206-211`). Some windows are skipped (`:214-215`) or ended early (`:232-233`), and so are whole
  sections (`:194-195, :198-199, :203-204`). For (b) the processor would have to copy those ~20 lines and keep them in step
  with an ai-owned file. A drift test only catches drift on the fixtures it runs, so after a chunker change a chunk on some
  untested layout would get a plausible but **wrong** page. ADR-0014 forbids exactly that.
- (b) also can't find a chunk's section reliably. Chunks carry only `section_title` (`:224`), and titles repeat in real papers
  ("Proof", "Discussion"). The same title-keyed map is already lossy in `db.py:92,97`. Matching the decoded text back is out
  too, because BGE's uncased tokenizer lowercases and re-spaces it (`:218`).
- With (a), the ai change is about 12 lines: tokenize once with offsets, then look the page up. The windowing exists in one
  place, so drift is impossible by construction.

**Contract between the two parts** (the AI-11 spec; the ai-engineer owns the code):
- Input: a section may carry `page_breaks: list[tuple[int, int]]`, sorted by offset. Each entry is `(offset into sec["text"]
  as given, not stripped; 1-based page)`, and the first offset is 0.
- `enc = self.tokenizer(sec_text, add_special_tokens=False, return_offsets_mapping=True)` and `tokens = enc["input_ids"]`.
  For the fast BERT tokenizer these ids are the same as `encode(..., add_special_tokens=False)` at `:202`, and AC2 proves it on
  the fixture. `lead = len(raw) - len(raw.lstrip())`.
- For every emitted chunk: `char = lead + enc["offset_mapping"][start_i][0]`, and `page_start` = the page of the last break
  whose offset is `<= char` (`bisect_right - 1`). Set the key **only** when `page_breaks` is present, `self.tokenizer.is_fast`
  is true and `char >= page_breaks[0][0]`. Otherwise leave it out. Never default it, never guess.
- `content`, `content_hash`, `chunk_index`, `token_count`, `section_title` and `page_number` stay byte-identical. The chunk text
  contract in `area-notes/services.md` doesn't change.
- AI-11 tests (no PDF): hand-made section dicts with breaks at known offsets, overlap windows that straddle a break, a section
  with no `page_breaks` (no key), and the existing `test_m0.py` unchanged. Estimate: +14/−2 prod, +45 test.

### 2. Storage: **(a) new table `paper_chunk_pages`**
`migrations/000003_paper_chunk_pages.up.sql`:
```sql
CREATE TABLE IF NOT EXISTS paper_chunk_pages (
  chunk_id   BIGINT PRIMARY KEY REFERENCES paper_chunks(id) ON DELETE CASCADE,
  page_start INT NOT NULL CHECK (page_start >= 1)
);
```
The down file is `DROP TABLE IF EXISTS paper_chunk_pages;`. `IF NOT EXISTS` is required, because `arxivlens migrate` re-applies
every `*.up.sql` in order (`cmd/arxivlens/main.go:89`) and `db.yml` runs it twice and diffs the schema snapshot
(`db.yml:61-66`, which lists columns and indexes, so the new table shows in both runs). `TestRepoMigrationsOrder`
(`internal/db/db_test.go:82-95`) checks a prefix, so it stays green. I add `000003` to its `want` list as well.

Why (a) and not (b):
- It needs no ADR (AGENTS.md §2: adds a table). (b) changes `paper_chunks` and would keep the ticket Blocked until Mahesh decides.
- "Unknown" is structural: no row means unknown. Every existing chunk, and every test/fixture writer
  (`tests/test_evals_data.py:715`, `internal/query/search_integration_test.go:41`), stays unknown without being touched.
- The cost is small and I found nothing that makes it a real one. `db.py` needs the chunk id. The upsert `ON CONFLICT (paper_id,
  chunk_index) DO UPDATE` (`db.py:106`) keeps the id stable across reprocessing, and `... DO UPDATE ... RETURNING id`
  returns it on both paths. Then one more statement per chunk, in the **same transaction** (L2 kept, `worker.py:79-82`):
  - `page_start` set → `INSERT INTO paper_chunk_pages ... ON CONFLICT (chunk_id) DO UPDATE SET page_start = EXCLUDED.page_start`
  - `page_start` missing → `DELETE FROM paper_chunk_pages WHERE chunk_id = %s`, so a reprocess without pages can't leave a stale page.
  The search side costs one PK lookup per result row (below).
- `page_number` and `db.py:119` stay as they are (ticket Scope).

### 3. Page breaks without changing section text bytes
In `_parse_doc_sections`, every new section dict (`worker.py:118`, `:160-165`) gets `"page_breaks": []`. The only text write is
`:167`, and just before it:
```python
pb = current_section["page_breaks"]
if not pb or pb[-1][1] != page_idx + 1:
    pb.append((len(current_section["text"]), page_idx + 1))
```
This only reads `len(text)`, so `text`, `title`, `level`, `page` and the order of sections stay byte-identical (AC2 checks it).
The first entry is always at offset 0. A section whose heading sits at the bottom of page 3 with its text starting on page 4
gets `[(0, 4)]`, so its first chunk is on page 4 even though `page` is 3. That is the "page its first characters are on" from
AC1. The attribution is exact even for two-column layouts: text is appended page by page (`:133`), so reading order inside a
page doesn't matter. Diff: +4/−0 (the existing lines keep their indentation, per my OPS-H6 lesson).

### 4. Effect on ING-8 (`origin/agent/ai/ING-8` `d2ad9c5`)
The scorer calls `ProcessorWorker._parse_doc_sections(None, doc)` (`scripts/evaluate_extraction.py:245`), and its test checks
that source string (`tests/test_evaluate_extraction.py:276`). It reads only `title` and `level` (`evaluate_extraction.py:259`).
This design keeps the method's name, its `(self, doc)` signature and the fact that it uses no instance state. It only adds a
key, so ING-8 is not broken and the two branches share no files. The pure `parse_doc_sections(doc)` seam (board follow-up)
stays a separate task.

### 5. RET-2 dependency
RET-2 provides `SearchHit.Page *int \`json:"page,omitempty"\`` (never set), the outer SELECT ending `..., p.version,` with the
`_GO_TO_EVAL_SQL` fragment to match, `TestSearchProvenance` in `db.yml`, `TestSearchSQLOuterSelectOnly` and the README
`/v1/search` row. Part b edits all of those again, so **part b starts after RET-2 merges**. Part a touches none of RET-2's
files (see the split below), so it only waits for AI-11.

### 6. Search (part b)
Line 111 (after RET-2) gains a correlated PK lookup at its end. The scan at `search.go:180` gains `&h.Page` in the same
position, and pgx v5 (`go.mod:6`) scans NULL into `**int` as nil.
```sql
SELECT c.id, c.content, p.arxiv_id, p.title, COALESCE(ps.title, '') AS section_title, p.version,
       (SELECT cp.page_start FROM paper_chunk_pages cp WHERE cp.chunk_id = c.id) AS page,
```
A scalar subquery and not a `LEFT JOIN`: a join would also change the `JOIN papers p ... LEFT JOIN paper_sections ...` fragment
(`tests/test_evals_data.py:277-278`). The subquery keeps the ticket's "one `_GO_TO_EVAL_SQL` fragment update" (the
outer-SELECT fragment, `:275`, eval side unchanged). On a PK it returns at most one row, so it can't add or drop hits. The RRF
arms, `rrf_score`, `ORDER BY` and `LIMIT` stay byte-identical. The `Page` comment changes from "never set (ING-11)" to "start
page when recorded (paper_chunk_pages), omitted otherwise".

## Approach: files and size (counted with fakes and deletions, per the OPS-H8 lesson)

**Part a, producer (page written, not read).** Depends on AI-11 merged.
| File | Change | ~lines |
|---|---|---|
| `services/processor/worker.py` | `page_breaks` (decision 3) | +4 |
| `migrations/000003_paper_chunk_pages.{up,down}.sql` | new table (decision 2) | +10 |
| `services/common/db.py` | `RETURNING id`, then upsert or delete the page row | +16 −2 |
| `internal/db/db_test.go` | `want` gains `000003` | +1 −1 |
| `tests/test_processor_pages.py` (new) | PyMuPDF fixture builder ~35, AC1 ~25, AC2 snapshot + compare ~40, `page_breaks` invariants ~20, `db.py` fake-cursor table test ~50 | +170 |
| `Makefile` | `test-py` runs the new file | +1 −1 |
| **Total** | | **~205** |

**Part b, consumer (as RET-3).** Depends on part a and RET-2 merged.
| File | Change | ~lines |
|---|---|---|
| `internal/query/search.go` | SELECT line, scan, `Page` comment | +4 −3 |
| `internal/query/search_test.go` | RET-2's golden/source checks also strip the page column and expect `&h.Page` | +8 −4 |
| `internal/query/search_provenance_integration_test.go` | seed one `paper_chunk_pages` row; assertions (AC3) | +30 −10 |
| `.github/workflows/db.yml` | after migrate run 1: `grep -E '^column\|paper_chunk_pages\.page_start\|integer$' /tmp/run1.txt` | +1 |
| `tests/test_evals_data.py` | the one outer-SELECT fragment | +1 −1 |
| `README.md` | `/v1/search` row | +1 −1 |
| **Total** | | **~65** |

**Split decision: split.** The whole is about 270–310 lines once fakes are counted, which is at the ticket's 300-line seam.
Part a also doesn't share files with RET-2, so splitting lets it go ahead before RET-2 merges. The split is at a layer
boundary (producer/consumer), the kind my OPS-H8 lesson asks for. Part a alone is safe: the new table is never read, and
search output doesn't change.

Order: **AI-11 → ING-11a** (any time) and **RET-2 → ING-11b** (after ING-11a). AC1, AC2 and AC5 (migrate twice) belong to
part a. AC3, AC4 and AC6 belong to part b. `stack.yml` must pass on both PRs.

## Alternatives considered
1. **Mapping in the processor (b)**: rejected, see decision 1 (copied windowing, drift on layouts the tests don't cover, no
   reliable chunk→section key). A runtime self-check (re-decode each window and compare it to `content`) would make (b) fail
   safe, but at the price of tokenizing every section twice and copying even more chunker logic.
2. **Chunker emits only a char offset and the processor looks up the page**: rejected, because the processor can't tell which
   section a chunk came from (repeated titles). Adding a `section_position` key would also fix that, but it is a bigger change
   to the chunker's output than `page_start`.
3. **Nullable column `paper_chunks.page_start` (b)**: rejected, see decision 2 (needs an ADR, so it is blocked, for no real gain).
4. **`LEFT JOIN paper_chunk_pages` in the outer query**: works too, but changes a second parity fragment. Kept as a fallback
   if QA prefers readability.
5. **Overwrite `page_number`**: rejected. Legacy rows would look reliable (the RET-2 finding 2 problem), and the ticket says leave it.

## Contracts and invariants
- **Schema:** adds a table only (AGENTS.md §2, no ADR). Applied migrations aren't edited. No backfill and no default.
- **HTTP API:** `/v1/search` `page` is now filled when recorded. ADR-0014 (Accepted) already defines it ("omitted when
  unknown"). No new field.
- **Events:** none. The section and chunk dicts aren't in any event payload (`worker.py:92-97`).
- **Chunk text contract and embedding:** unchanged (AC2). The embedder's L3 skip is unaffected because content and chunk ids are unchanged.
- **Reliability:** the page row is written in the processor's single transaction with the `processed_events` ledger row
  (L2). A duplicate event writes nothing. Retry/DLQ, commit-after-process and traceparent aren't touched. No `kafka/` or `dlq/` change.
- **ADR-0010 parity:** one fragment changes, `scripts/evaluate_retrieval.py` stays the same, and the ranking SQL is byte-identical.
- **ING-8:** `_parse_doc_sections(None, doc)` call contract kept (decision 4).

## Test plan
**Fixture** (built in the test, no download, nothing committed except code): `pymupdf.open()` and `page.insert_text(...,
fontname="helv")`. Page 1 has a title line and `1 Introduction` at 16 pt. The Introduction body is 10 pt (the median, so the
heading threshold is 11.5 at `worker.py:130-131`) and runs over pages 1–3. `2 Method` starts mid-page 3 with a short body.
Body words come from **page-specific vocabularies** (page 1 animals, page 2 colours, page 3 number words), and every one is a
single BGE wordpiece (asserted in the test). So each chunk starts on a whole word, and the first word of its text (content
minus prefix) says which page it's on, **independently of the implementation**. With about 450 tokens per page and a step of
about 410, the Introduction gives about 4 chunks, at least 2 of them starting on page 2 or 3.

**Pre-change output (AC2):** `_snapshot(doc)` records each section's `(title, level, page, sha256(text))` and each chunk's
`(chunk_index, token_count, content_hash, sha256(content))` as a literal in the test. The literal is captured from `origin/main`
code (before AI-11 and part a). The **first commit** of part a adds only the test file plus the Makefile line, and its CI run
is green on the unchanged code: that's the "before" evidence. The next commit changes the code, and the same test stays
green: that's the "after" evidence. If the sandbox can't run PyMuPDF and BGE, the literal is taken from that first commit's CI
log, where the test prints it on mismatch.

| Acceptance criterion | Test (name / type) | Runs in CI? |
|---|---|---|
| AC1 recorded page = page of first characters; one chunk > heading page | `test_chunk_page_start_matches_first_word_page` (production `_parse_doc_sections(None, doc)` + `TokenChunker(MODEL_NAME)`; every chunk has `page_start` == the oracle page; `any(page_start > section page)`), `test_page_breaks_invariants` (first offset 0, ascending, pages ascending, offsets in range) | `make test-py` (ci.yml python job) |
| AC2 chunk output unchanged | `test_chunk_output_identical_to_pre_change` (snapshot above, both commits); AI-11's own tests; `make eval`: "not run: chunk text identical (AC2)" | `make test-py` |
| AC2 (write path) | `test_save_chunks_page_rows` (fake cursor, table: `page_start` set → upsert with that value; missing → `DELETE`; `page_number` arg still `chunk.get("page_number", 1)`; all in the caller's transaction, no commit) | `make test-py` |
| AC3 unknown → no `page`, recorded → `page` | `TestSearchProvenance` extended (real pgvector, production `HybridSearch`): v2 chunk 1 gets a `paper_chunk_pages` row with page 6 (different from its `page_number` 7, which proves the new table is the column read) → `Page == 6`, `"page":6` in JSON; v2 chunk 0 (`page_number` 4, no row = pre-migration row) and the v1 chunk (NULL, no row) → `Page == nil`, no `"page"` key | `db.yml` (every PR) |
| AC4 parity + ranking unchanged | whole `tests/test_evals_data.py`, plus by node ID `test_rrf_pool_sql_mirrors_search_go`, `test_adr0010_parity_pool_one_call_stable_ties_top5`, `test_rrf_pool_query_runs_with_production_hnsw_settings_then_resets`; `search_test.go` ordering tests unmodified; `TestSearchSQLOuterSelectOnly` (strip both added columns → golden); `TestHNSW` recall lines unchanged | ci.yml, `db.yml` |
| AC5 migrate twice; milestone suite | `db.yml` "Migrate run 2" schema diff (now includes `paper_chunk_pages`) + the part-b grep; `TestRepoMigrationsOrder`; `stack.yml` on both PRs | `db.yml`, `stack.yml` |
| AC6 README; < 400 lines per PR | README diff (part b); `git diff --stat origin/main` in each PR | PR |

Failure paths covered: a section without `page_breaks` or a slow tokenizer gives no key, so no row and no `page` (AI-11 tests +
`test_save_chunks_page_rows`). A reprocess without pages deletes a stale row. A duplicate event writes nothing (existing L2 path,
which the new statement doesn't change). A SELECT/scan mismatch fails the unit source check and the integration scan.

## Risks and rollout
- **`__call__` ids ≠ `encode` ids** (a tokenizer version quirk) would change chunks. Detection: AC2 fails in CI before merge.
- **The fixture's vocabulary isn't single-wordpiece** under a future tokenizer: the test asserts it up front and fails with a clear message, not a wrong oracle.
- **PyMuPDF version changes** text extraction of the generated PDF: the snapshot shows it, and the fixture uses only base-14 `helv` and plain lines.
- **Stale chunks:** a reprocess that makes fewer chunks leaves the old higher `chunk_index` rows (existing upsert behaviour,
  `db.py:106`). Their page rows go away with them by cascade only if they are deleted. Not made worse; noted for ops.
- **Existing corpus** has no pages until reprocessed (out of scope). The part-a PR will say how: re-publish `papers.downloaded`
  with a fresh `event_id` per paper. Chunk ids are kept by the `(paper_id, chunk_index)` upsert, so no re-embedding (L3).
- **Rollback:** revert part b (search stops returning `page`), or revert part a. The table can stay, or `000003.down.sql` drops it.

## Open questions
- **Q1 (pm-lead):** spec the paired ai ticket (proposed **AI-11**, contract in decision 1), and have ING-11a depend on it?
- **Q2 (pm-lead):** confirm the split (ING-11a producer and ING-11b consumer, or a/b parts under one ticket id with two PRs) and how ACs are assigned.
- **Q3 (pm-lead):** OK to use a scalar subquery instead of a `LEFT JOIN` in the outer SELECT, to keep a single parity fragment (alternative 4)?

## PM decision
**APPROVE with conditions** (pm-lead, 2026-11-07, design at `4b95a2c`). The order and the ticket boundaries change (Q1/Q2 below),
but the approach doesn't. Nothing is built this cycle.

Spot-checked against `origin/main` `2b71772`, all as the design says: `m0_skeleton.py:197` strips `sec_text`, `:202` `encode(...,
add_special_tokens=False)`, `:206-211` prefix and window parameters, `:212-215` window loop and min-token skip, `:218` decode,
`:225` `"page_number": sec.get("page", 1)`, `:232-233` early break; `worker.py:118` Abstract bucket, `:160-165` new section dict
only on a heading, `:167` the only text write, `:133` page-by-page loop, `:130-131` median and 1.15× threshold; `db.py:92,97`
title-keyed section map, `:106` `ON CONFLICT (paper_id, chunk_index) DO UPDATE` with no `RETURNING`, `:119` `page_number`;
`paper_chunks.id` is `BIGSERIAL` (`000001_init_schema.up.sql:39`), so `BIGINT` FK is right; `main.go:77-82` re-applies every file
and `db.yml:54-67` diffs the snapshot (which includes `information_schema.columns`, so the new table is in both runs); `db.yml` runs
on every `pull_request`; `TestRepoMigrationsOrder` (`db_test.go:82-95`) is a prefix check; `go.mod:6` pgx v5.6.0;
`test_evals_data.py:275-278` outer-SELECT and join fragments; `search.go:111` outer SELECT and `:180` 6-column scan;
ING-8 `d2ad9c5` `evaluate_extraction.py:245` calls `ProcessorWorker._parse_doc_sections(None, doc)` and `:259` reads only
`title`/`level`, and the ING-8 branch touches no file this design touches. `chunk_sections` has no other caller than the
processor and `m0_skeleton.py:351` (CLI demo), so an extra `page_start` key reaches nothing else. `ci.yml`'s python job
installs PyMuPDF, psycopg and confluent-kafka (`requirements-m0.txt`), so a `make test-py` test can import the worker.

Decisions 1 (mapping inside `TokenChunker`), 2 (new table `paper_chunk_pages`, no ADR: it only adds a table) and 3
(`page_breaks` by reading `len(text)` only) are right, and the reasons hold up in the code: windowing exists once, repeated
section titles make a processor-side mapping unreliable, and "no row = unknown" keeps every legacy and fixture row unknown
without touching it. This is ADR-0014's rule ("only returned when the chunker recorded it") by construction.

### Answers to the open questions
- **Q1 → yes, AI-11 is specced** ([agents/tasks/AI-11.md](../../agents/tasks/AI-11.md), ai-engineer, P1), with decision 1's
  contract plus condition 1 below. **But the dependency is reversed: AI-11 depends on ING-11 (part a), not the other way.**
  Reason, found while specing: AI-11 needs CI for its tests, and the only CI unit entry point is `make test-py`, which lists
  files explicitly in the `Makefile` (backend-owned; the ownership check fails an `agent/ai/*` PR that edits it). The one
  ai-owned file already in that list, `tests/test_m0.py`, is edited by open draft #24 (AI-9, Blocked), so the same-file rule
  (AGENTS.md §3) rules it out. With part a first, part a creates `tests/test_processor_pages.py` and adds it to `test-py`, and
  AI-11 appends its tests to that file (`tests/` is shared by both roles). As a bonus, part a's AC2 snapshot test then runs on the
  AI-11 PR too, so it proves the chunker change keeps chunk output byte-identical without a second snapshot. Part a is still safe
  alone: until AI-11 merges no chunk carries `page_start`, so `db.py` takes the `DELETE` branch, no row is written and nothing reads the table.
- **Q2 → split, as three tickets in this order:** **ING-11** (part a, producer: `page_breaks`, migration, `db.py`, new test file,
  Makefile; keeps KAN-55) → **AI-11** (chunker emits `page_start`, plus the AC1 end-to-end test on part a's fixture) →
  **ING-11b** (consumer: search, parity fragment, README, real-stack check; also needs RET-2 merged). The `b`-suffix follows the
  repo's precedent (OPS-H8/OPS-H8b, AI-6/AI-6b). AC mapping: ING-11 = AC2 and AC5; AI-11 = AC1 (and AC2 re-run); ING-11b =
  AC3, AC4, AC6 (README) plus a new real-stack write check (condition 4). The size limit applies to each PR.
- **Q3 → approved: scalar subquery in the outer SELECT**, not a `LEFT JOIN`. It is a PK lookup on `paper_chunk_pages`, so it returns at
  most one row per hit and can't add or drop hits. It runs only over the union of the two 50-row arms, so the cost is
  negligible, and it keeps a single parity fragment. Condition 5 says how QA checks it.

### Conditions (QA checks each one)
1. **AI-11 fail-safe tokenization (changes decision 1's contract).** Keep `tokens = self.tokenizer.encode(sec_text,
   add_special_tokens=False)` exactly as at `:202`. Only when the section has a non-empty `page_breaks` and `self.tokenizer.is_fast`
   is true, call `self.tokenizer(sec_text, add_special_tokens=False, return_offsets_mapping=True)` as well. If its `input_ids != tokens`,
   leave `page_start` out for that whole section (and don't raise). Then chunk output is byte-identical *by construction*, and an id
   mismatch from a future tokenizer means "unknown", never a wrong page. Tokenizing twice is cheap next to PDF parsing and embedding.
   An empty `page_breaks` list is treated as missing (no key). The other rules in decision 1 stay (`lead`, `bisect_right - 1`,
   `char >= page_breaks[0][0]`, never a default).
2. **AC2 "before" evidence is a green CI run on unchanged production code.** ING-11's first pushed commit adds only
   `tests/test_processor_pages.py` (with the snapshot literal) and the Makefile line, and its `ci.yml` python job is green. If the
   sandbox can't produce the literal, a first commit that prints it on mismatch is fine, then a commit with the literal that is green
   on unchanged code. The PR links both run IDs. The later code commits keep the same test green, and so does the AI-11 PR.
3. **ING-11 tests in its own file** don't depend on `page_start` (it doesn't exist until AI-11). They cover the fixture builder,
   the single-wordpiece vocabulary assertion, the AC2 snapshot, `page_breaks` invariants (first offset 0, offsets and pages
   strictly ascending, offsets within `len(text)`, at least one section with ≥ 2 breaks on the fixture), and the `db.py` fake-cursor
   table test (`page_start` set → upsert with `RETURNING id` used; missing → `DELETE`; `page_number` unchanged; no commit). The
   fixture builder and oracle helpers are importable module-level functions, so AI-11 reuses them instead of copying.
4. **Real-pipeline write check (new, in ING-11b).** `tests/test_m2_pipeline.py` gains a test that, after `stack.yml` ingests its
   papers, every `paper_chunks` row of an `embedded` paper has a `paper_chunk_pages` row, `page_start >= page_number`
   (the heading's page), and `page_start` doesn't decrease with `chunk_index` within a paper (sections and windows are in
   reading order; don't group by `section_id`, which the title-keyed map at `db.py:92` can merge). It goes in ING-11b
   because rows exist only after AI-11; it is the only proof that the `INSERT ... ON CONFLICT (chunk_id)` path works on real
   Postgres. (`stack.yml` also runs on ING-11 via `services/processor/**`/`migrations/**`, which proves the `RETURNING id` and `DELETE` path.)
5. **ING-11b SQL:** the PR shows that the only change to `hybridSearchSQL` is the subquery in the outer SELECT. RRF arms, `rrf_score`,
   `ORDER BY` and `LIMIT` are byte-identical (`TestSearchSQLOuterSelectOnly` strips both added columns and compares to the golden).
   There is one changed `_GO_TO_EVAL_SQL` fragment, and `git diff --stat` shows no `scripts/` path. The three guard tests are run by node ID (RET-2 condition 1).
6. **AC3 assertions** as in the test plan: the seeded page (6) differs from the stored `page_number` (7), and both the no-row
   chunk with `page_number` 4 and the NULL v1 chunk have `Page == nil` and no `"page"` key in the JSON. `t.Logf` lines are linked from the `db.yml` log.
7. **Size and seams.** Estimates: ING-11 ~180, AI-11 ~85, ING-11b ~85 (fakes and deletions counted). If ING-11 goes over 400, the
   seam is the layer boundary: `page_breaks` + fixture tests (no DB) first, migration + `db.py` + its fake-cursor test second.
   Don't drop the AC2 snapshot from either half.
8. **No reprocessing in these PRs.** ING-11's PR description says how to backfill (re-publish `papers.downloaded` with a fresh
   `event_id`; chunk ids are kept, so no re-embedding) and that it's Mahesh's call (ticket Out of scope).
9. **Docs:** ING-11b updates the README `/v1/search` row ("`page` is the page the chunk's text starts on, when recorded; omitted
   otherwise (ADR-0014)"). Technical PRD §5 (new table) and §6.2 (`page_breaks`, `page_start`) are a pm-lead docs PR after ING-11b
   merges. Product PRD rows don't change status (ING-3/QA-3 are already ✅; this makes QA-3's citations more precise).

### Tickets
- [ING-11](../../agents/tasks/ING-11.md) (backend, P1, Ready; KAN-55): producer part a. No build dependency.
- [AI-11](../../agents/tasks/AI-11.md) (ai, P1): `TokenChunker` emits `page_start`. Depends on ING-11 merged.
- [ING-11b](../../agents/tasks/ING-11b.md) (backend, P1): consumer. Depends on AI-11 and RET-2 merged.
