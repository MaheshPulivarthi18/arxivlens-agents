# Tech design — RET-2: Search hits carry the paper version and page (citation provenance)

**Author:** backend-engineer · **Ticket:** `agents/tasks/RET-2.md` · **PRD:** Product PRD QA-3, ING-7, §7 principle 3; Technical PRD §5, §7.1; ADR-0014 (Accepted) · **Status:** Approved with conditions (pm-lead, 2026-11-07)

All code references are to the app repo at `origin/main` `2b71772`.

## Problem
A `/v1/search` hit names the paper (`arxiv_id`) and chunk, but not which version of the paper the chunk came from or
which page it is on, even though `papers.version` and `paper_chunks.page_number` exist (`migrations/000001_init_schema.up.sql`).
ADR-0014 adds `version` (always) and `page` (only when the chunker recorded it) to search hits. This design adds them
in the outer SELECT and scan of the hybrid query only, leaves ranking untouched, and decides from the code whether
`page_number` can be trusted. Covers AC1–AC5.

## Findings (the ticket's Scope questions)

### 1. Which SQL changes
- There is **one** SQL path. `fetchCandidates` (`internal/query/search.go:144`) runs `hybridSearchSQL` (`search.go:98-121`)
  after `hnswSearchSettings`; both `rerank=false` (`search.go:71-72`) and `rerank=true` (`search.go:76`) use it through
  `s.fetch`. The rerank fallback (`search.go:224-228`) is not SQL: it reuses the fetched hits, so whatever columns the
  scan fills travel with them. No other query builds `SearchHit`s (`grep SearchHit internal/`: only `search.go` and `rag.go`'s consumers).
- Change: the outer SELECT list at `search.go:111` gains `p.version` (the `papers p` join is already there at
  `search.go:114`), and the scan at `search.go:180` gains `&h.Version` in the same position. Nothing else:
  `vectorHitsSQL` (`search.go:85-95`), `keyword_hits` (`search.go:100-110`), the `rrf_score` expression (`search.go:112`),
  `FROM/JOIN/WHERE/ORDER BY/LIMIT` (`search.go:113-120`) stay byte-identical.
- `c.page_number` is **not** selected (see finding 2). Selecting a column we then throw away would only add a parity
  fragment and a dead scan target.

New line 111:
```sql
SELECT c.id, c.content, p.arxiv_id, p.title, COALESCE(ps.title, '') AS section_title, p.version,
```
`papers.version` is `INT NOT NULL DEFAULT 1`, so it scans into Go `int` with no NULL handling.

### 2. Page reliability: **not reliable, so `page` is omitted for all hits**
Trace for every chunk the pipeline writes (all ingest paths go through `ProcessorWorker`: the Kafka worker,
`scripts/ingest_batch.py:12`, and on-demand `services/embedder/api.py:135-179`):
1. `services/processor/worker.py:113-172` (`_parse_doc_sections`) records **one** `page` per section: the page on
   which the section's heading line was found (`worker.py:164`), or 1 for the leading "Abstract" bucket (`worker.py:118`).
   Body text is appended to the current section across page boundaries (`worker.py:167`) with no page marker, so the
   section dict has no information about where page breaks fall in its text.
2. `TokenChunker.chunk_sections` (`scripts/m0_skeleton.py:183-235`, **ai-owned**) slides a token window over the whole
   section text and gives every chunk `"page_number": sec.get("page", 1)` (`m0_skeleton.py:225`).
3. `services/common/db.py:119` writes `chunk.get("page_number", 1)`. On the processor path the key is always set by
   step 2, so the default 1 is never the source; the value is already the section's start page.

Result: `page_number` is the **start page of the chunk's section**, not the chunk's page. It is right for the first
chunk of each section and wrong for any later chunk of a section that crosses a page break (a 5-page Method section
gives all its chunks the heading's page). It is a real number, not a NULL, so search cannot tell a right value from a
wrong one. Rows written by tests and fixtures (`tests/test_evals_data.py:715`, the OPS-H5 seed in
`search_integration_test.go`) leave it NULL. Returning it would be the "default as if real" case the ticket forbids.

**Rule for RET-2:** `SearchHit` gains `Page *int \`json:"page,omitempty"\``, which is never set, so `page` is absent from every
hit. AI-8 can map it into `citations[].page` now (nil means omitted), and the field fills in, without a contract change, once the
follow-up below lands.

**Processor follow-up (for pm-lead to spec; backend-owned plus one paired ai change):** "PROC-n: record the real
start page of each chunk".
- `_parse_doc_sections` keeps, per section, the character offset at which each new page starts (`page_breaks: [(offset, page)]`).
- The chunker maps each chunk's first token back to a character offset and then to a page (`tokenizer(..., return_offsets_mapping=True)`),
  emitting `page_start`. `TokenChunker` is in ai-owned `scripts/m0_skeleton.py`, so that part is a paired ai-engineer change
  (or the processor does the mapping after `chunk_sections` using the same tokenizer; the follow-up's design picks one).
  The chunk text/format contract (`area-notes/services.md`) must not change, so `make eval` should show no difference.
- Additive migration `000003`: `paper_chunks.page_start INT NULL`, written only by the fixed processor. Existing rows
  stay NULL (= unknown), so no legacy row can be mistaken for a reliable one, with no backfill and no edit to an applied migration.
  `db.py:119` writes `chunk.get("page_start")` (no default) to the new column and leaves `page_number` as it is.
- Search: add `c.page_start` to the outer SELECT, scan into `h.Page` (NULL → nil → omitted), plus one parity-fragment change like RET-2's.
- Reprocessing the existing corpus to fill `page_start` is a separate ops decision.

### 3. Version semantics and the join
- ING-7: each `(arxiv_id, version)` is its own `papers` row (`UNIQUE (arxiv_id, version)` in migration 000001;
  natural-key upsert `internal/db/db.go:106-121`). The crawler parses the version from the Atom entry ID (`internal/crawler/crawler.go:200-212`).
- Chunks belong to one `papers` row: `paper_chunks.paper_id → papers.id`. The processor looks up the row by
  `(arxiv_id, version)` from the event (`worker.py:46,63`, `db.py:12-23`) and writes chunks with that `paper_id`
  (`worker.py:81`). The outer query joins `papers p ON p.id = c.paper_id` (`search.go:114`), so `p.version` is the version of the
  row that owns the chunk. A v1 chunk and a v2 chunk of the same paper are different rows with different `paper_id`s and
  return 1 and 2. The join is correct.
- **Caveat (labelling, not the join; follow-up recommended):** the stored PDF may not be the version the row says.
  `internal/downloader/downloader.go:80` and `internal/query/ingester.go:181` both fetch the *unversioned*
  `https://arxiv.org/pdf/<id>.pdf` (always the latest), and on-demand ingest hard-codes `version := 1` (`ingester.go:179`)
  even when arXiv already has v3. So a paper ingested on demand reports `version: 1` for v3 content. A crawler-ingested paper
  is only wrong if a new version comes out between crawl and download. Suggested follow-up "ING-n" (backend):
  parse the version from `entry.ID` in the ingester the way the crawler does, and download `https://arxiv.org/pdf/<id>v<version>.pdf`
  in both places. Politeness limits stay the same: it is the same single request. See open question Q2.
- Which version(s) search returns when several are indexed (today: all, so v1 and v2 chunks can both appear) is out of scope
  per the ticket. I flag it as Backlog input in Risks.

### 4. ADR-0010 parity guard
- `tests/test_evals_data.py::test_rrf_pool_sql_mirrors_search_go` rebuilds `hybridSearchSQL` from the Go consts and compares
  the whole normalised query to `scripts/evaluate_retrieval.py`'s `RRF_POOL_SQL` after applying `_GO_TO_EVAL_SQL`. The outer SELECT
  list is one of those allowed differences (`test_evals_data.py:274-276`), so **the change touches what it compares** and the guard
  would fail without an edit (fragment not found once).
- Allowed-difference change (one line in the test, backend may edit `tests/`):
  ```
  - ("SELECT c.id, c.content, p.arxiv_id, p.title, COALESCE(ps.title, '') AS section_title,",
  + ("SELECT c.id, c.content, p.arxiv_id, p.title, COALESCE(ps.title, '') AS section_title, p.version,",
     "SELECT c.id, p.arxiv_id, c.content,"),
  ```
  plus its comment: "outer SELECT: the eval needs only (id, arxiv_id, content); no titles or version". The eval side of the
  pair is unchanged, so `RRF_POOL_SQL` keeps its text and **no change to ai-owned `scripts/evaluate_retrieval.py` is needed**.
  The other four fragments (both arm filters, the `paper_sections` join, the tiebreak) still match exactly once. An extra
  column in the outer SELECT doesn't change which rows or which order, so the guard still proves the ranking SQL is identical.
- Verification gap: `pytest tests/test_evals_data.py -k parity` (the ticket's command) selects **only**
  `test_adr0010_parity_pool_one_call_stable_ties_top5` (checked: "1/76 tests collected"). The SQL mirror test is
  `test_rrf_pool_sql_mirrors_search_go`, which has no "parity" in its name. The PR evidence will use
  `-k "parity or mirrors"` (3 tests: pool parity, SQL mirror, HNSW settings order) and the full file. See Q1.

## Approach

### Files
| File | Change | ~lines |
|---|---|---|
| `internal/query/search.go` | `SearchHit` + `Version int \`json:"version"\`` and `Page *int \`json:"page,omitempty"\`` (with a comment pointing to this design: page not reliable yet). Outer SELECT `+ p.version`, scan `+ &h.Version`. | +6 −2 |
| `internal/query/search_test.go` | Table-driven, no infra: (a) JSON shape: `version` always present, `page` absent when nil and present when set; (b) `Version`/`Page` stay with their hit through the rerank sort and through each fallback reason (reuse `fakeReranker`); (c) a source check that the outer SELECT names `p.version` and the scan names `&h.Version` in the same position, so a column/scan mismatch fails in unit tests rather than only in `db.yml`; (d) `TestSearchSQLOuterSelectOnly`: `hybridSearchSQL` with `", p.version"` removed equals a golden copy of today's text. Existing tests are **not edited**. | +95 |
| `internal/query/search_provenance_integration_test.go` (new, `//go:build integration`) | `TestSearchProvenance` (below). Kept out of the OPS-H5 file so that file's diff is zero. | +110 |
| `.github/workflows/db.yml` | `-run TestHNSW` → `-run 'TestHNSW\|TestSearchProvenance'` in the existing step. Step name gains "+ search provenance". | +2 −2 |
| `tests/test_evals_data.py` | The one allowed-difference fragment + comment (finding 4). | +2 −2 |
| `README.md` | `/v1/search` row (below). | +1 −1 |

**Estimated diff: ~215 changed lines** (production ~8, fakes/helpers in tests ~60 of the test total, deletions ~7), well
under 400. Per my OPS-H8 lesson, the fake embed server and seeding are counted separately inside the integration-test estimate.

### `TestSearchProvenance` (real pgvector, `db.yml`)
- Skips without `DATABASE_URL` (same as `TestHNSW`). It goes through the **production path** `SearchEngine.HybridSearch(..., rerank=false)`
  → `fetchCandidates` → `hybridSearchSQL` + real scan, not a copy of the query. The embedder is an `httptest` server that answers
  `/internal/embed` with a fixed 768-d vector, wired via `NewEmbedClient(srv.URL)` and `NewSearchEngine`.
- Seed (committed, so the engine's own read-only tx sees it; `t.Cleanup` deletes `papers WHERE arxiv_id LIKE 'prov.%'`,
  which cascades). Unique category `test.prov`, so both RRF arms only see these rows even after `TestHNSW`'s 1000 synthetic papers:
  - `prov.00001` v1 (title "Provenance v1"): chunk 0, content "zyxprov alpha one", `page_number` NULL.
  - `prov.00001` v2 (title "Provenance v2"): chunk 0 "zyxprov alpha two", `page_number = 4`; chunk 1 "zyxprov beta two", `page_number = 7`.
  - An itModel embedding for every chunk (same direction as the query vector, so the vector arm returns them too).
- Query "zyxprov", `categories = ["test.prov"]`, limit 10. Assertions:
  1. 3 hits, all `arxiv_id = prov.00001`.
  2. Each hit's `Version` equals the version of the row whose chunk it is (keyed by `ChunkID` from the seed's `RETURNING id`): v1 chunk → 1, both v2 chunks → 2. A swapped join would fail this.
  3. `Title` matches the version ("Provenance v1"/"v2"), a second check that the hit and its version came from the same row.
  4. The chunk with `page_number = 4` (a known page) has `Page == nil`, and its `json.Marshal` has no `"page"` key. This is the
     page rule from finding 2. **This replaces AC2's "a chunk with a known page returns it"** until the processor follow-up. See Q3.
  5. `t.Logf` prints each hit's `chunk_id, version, page, rrf_score` so the `db.yml` log is readable QA evidence.

### README `/v1/search` row
```
| `POST` | `/v1/search` | Hybrid search: `{query, categories?, limit?, rerank?}` → `[{chunk_id, arxiv_id, version, title, section, content, rrf_score, rerank_score?, page?}]`. `version` is the arXiv version of the paper the chunk came from; `page` is omitted until chunk pages are recorded reliably (ADR-0014) |
```

## Alternatives considered
1. **Return `page_number` as is.** Rejected: for most chunks of multi-page sections it is the wrong page, and there is no signal to tell which (finding 2). ADR-0014 and the ticket both forbid it.
2. **Return `page` only for the first chunk of each section** (where section-start page = chunk start page), via a `MIN(chunk_index) OVER (PARTITION BY section_id)` subquery in the outer query. Rejected: it adds a window/subquery to the parity-guarded SQL, covers only part of the hits, and becomes dead code once the processor follow-up lands. Chunks whose section has `section_id` NULL (title lookup miss in `db.py:96-97`) would also need a special case.
3. **Select `c.page_number` now and hide it behind a flag.** Rejected: a second parity fragment and a scan target with no use.
4. **Fix the processor first and fold it into RET-2.** Rejected: it needs a migration, a paired ai change to `TokenChunker`, and corpus reprocessing, which would put it over 400 lines and mix ingestion with the query contract. It is better as its own ticket.
5. **Leave `Page` out of the struct entirely.** Possible, but adding it now lets AI-8 map `citations[].page` once, and the JSON is the same (omitted). Kept.

## Contracts and invariants
- **HTTP API** (`/v1/search` response): adds `version` (always) and `page` (omitted). Allowed by ADR-0014 (Accepted 2026-11-07).
  Existing fields keep their names and types, so clients that ignore unknown keys are unaffected. `/v1/ask` is unchanged by
  this PR (`rag.go` builds its own `Citation`; AI-8 maps the fields).
- **Schema:** none (reads existing `papers.version`).
- **Ranking (AC4):** RRF arms, `rrf_score`, `ORDER BY`, `LIMIT`, `hnswSearchSettings`, `RerankPool` and `rerankAndSort` unchanged.
  `search_test.go`'s ordering tests are not edited. `TestHybridSearchNoRerankUnchanged` compares JSON of fetched vs expected
  `rrfHits`, and both gain `"version":0` the same way, so it passes unmodified.
- **ADR-0010 parity:** guard kept, eval SQL unchanged (finding 4).
- **Reliability invariants** (idempotency layers, retry/DLQ, commit-after-process, traceparent, arXiv politeness): not touched. No change to `kafka/`, `dlq/`, workers or migrations, so `test_m4_chaos.py` is unaffected.

## Test plan
| Acceptance criterion | Test (name / type) | Runs in CI? |
|---|---|---|
| AC1 `version` on every hit, `page` only when reliable | `TestSearchHitJSON` (unit, table: version present incl. after rerank/fallback; page nil → absent, set → present); `TestSearchProvenance` assertions 1–4 (integration) | `make test-unit` (CI), `db.yml` |
| AC2 v1/v2 return the right version per chunk; known-page chunk | `TestSearchProvenance` (real pgvector, production `HybridSearch` path): assertions 2–3 for version; assertion 4 shows the known-page chunk's `page` is **omitted** per finding 2 (pending Q3) | `db.yml` (run pattern extended) |
| AC3 parity guard green; allowed-difference change shown | `pytest -q tests/test_evals_data.py -k "parity or mirrors"` and the full file; PR shows the one-fragment diff | `make test-unit` / CI python job |
| AC4 ranking unchanged | `git diff origin/main -- internal/query/search.go` shows only the struct, line 111 and the scan line; `search_test.go` ordering tests unmodified and green; `TestSearchSQLOuterSelectOnly` (unit: `hybridSearchSQL` with `", p.version"` removed equals a golden copy of today's text, so any change elsewhere fails); `TestHNSW` recall numbers in `db.yml` unchanged | CI |
| AC5 README row; diff < 400 | README diff; `git diff --stat origin/main` in the PR | PR |

Failure paths covered: rerank error / count mismatch / NaN fallback keep `Version` with its hit (unit). Version and page are
never zeroed or mixed up by the stable sort (unit, distinct versions per rank). A missing `p.version` in the SELECT with
`&h.Version` still in the scan (or the reverse) fails the unit source check and the integration scan. A swapped join fails
integration assertion 2.

Also run: `make lint`, `make test-unit`, `go vet -tags integration ./internal/query/` (in `db.yml`). `make eval` is not needed
because ranking doesn't change. The PR will say "not run: no ranking change (AC4)" and point to the unchanged `TestHNSW` recall lines.
Go 1.25 is not available in this sandbox (it tries to download it), so Go results come from CI.

## Risks and rollout
- **Parity guard breaks on the wrong line** if the column is placed elsewhere (e.g., after `rrf_score`): mitigated by putting it on the existing allowed-difference line, so only one fragment changes.
- **OPS-H5 test interaction:** `TestHNSW` leaves 1000 synthetic papers in the job DB. The provenance test isolates with a unique category and keyword and cleans up its own rows. Run order doesn't matter.
- **Version label vs content** (finding 3 caveat): `version` is exactly what the DB says, but for on-demand ingests it can be wrong about the PDF. That is a provenance-accuracy issue that predates RET-2 and is now *visible*. Detection: compare against the arXiv Atom `entry.ID`. Fix: ING-n follow-up.
- **Multiple versions in results:** with v1 and v2 indexed, near-duplicate chunks of both can take two top-5 slots (and in `/v1/ask`, two citations). RET-2 makes this visible (distinct `version`) but doesn't change it. Backlog input for pm-lead: "search returns latest version only / dedupe by arxiv_id" is a product rule (ticket Out of scope).
- **Rollback:** revert the PR. The new fields are additive and nobody reads them until AI-8.

## Open questions for pm-lead
- **Q1 (verification command):** AC3's `pytest ... -k parity` doesn't run the SQL mirror test (`test_rrf_pool_sql_mirrors_search_go`). Change the ticket's Verification to `-k "parity or mirrors"` (or the full file)? I'll use that in the PR either way.
- **Q2 (version accuracy):** OK to ship `version` as the DB record's version now and spec "ING-n: versioned PDF URL + ingester parses version" as a follow-up? Or should AI-8 wait for ING-n before it shows `paper_version` in citations?
- **Q3 (AC2 wording):** Given finding 2, AC2's "a chunk with a known page returns it" can't hold without a false page. Proposal: AC2 becomes "…and a chunk with a stored `page_number` returns no `page`", and the page half moves to the processor follow-up (PROC-n). Please confirm, and spec PROC-n (and note the paired ai change to `TokenChunker`).

## PM decision
**APPROVE with conditions** (pm-lead, 2026-11-07, design at `ab4a2fc`). Build starts after ArxivLens #26 (OPS-H10) merges
(both edit `README.md`; same-file rule, AGENTS.md §3).

Spot-checked against `origin/main` `2b71772`, all as the design says: `SearchHit` has no version/page (`search.go:21-29`), there
is one SQL path and the outer SELECT at `search.go:111` with the `papers p` join at `:114` and a 6-column scan at `:180`;
`worker.py:118` (Abstract bucket `page: 1`), `:164` (`page: page_idx + 1` only on a heading), `:167` (body text appended
with no page marker); `m0_skeleton.py:225` `"page_number": sec.get("page", 1)`; `db.py:119` `chunk.get("page_number", 1)`;
`downloader.go:80` and `ingester.go:181` fetch the unversioned PDF, `ingester.go:179` hard-codes `version := 1`, while
`crawler.go:200-212` parses the version from `entry.ID`; the outer-SELECT fragment is in `_GO_TO_EVAL_SQL`
(`test_evals_data.py:274-276`) and each fragment must occur exactly once. `db.yml` runs on every `pull_request`, so the
new integration test gets a run without a dispatch.

The approach meets AC1–AC5, leaves the RRF arms and the eval SQL alone, and the test plan has a test for every AC.
Finding 2 is correct: `page_number` is the section-heading page, which is wrong for every later chunk of a section that
crosses a page break, so returning it would break ADR-0014's "page is only returned when the chunker recorded it".

### Answers to the open questions
- **Q1 → run the whole file, and name the guards.** Verification becomes `python3 -m pytest -q tests/test_evals_data.py`
  (76 tests, 0.16 s locally). The PR evidence must also run the three guards by node ID so they show by name:
  `test_rrf_pool_sql_mirrors_search_go`, `test_adr0010_parity_pool_one_call_stable_ties_top5`,
  `test_rrf_pool_query_runs_with_production_hnsw_settings_then_resets`. Correction to finding 4: `-k "parity or mirrors"`
  does select 3 tests, but the third is `test_split_sentences_mirrors_rag_go`, not the HNSW-settings test (checked:
  `--collect-only`). Don't use that filter as evidence. The ticket's AC3 and Verification are amended (dated Notes line).
- **Q2 → ship `version` now as the version of the `papers` row that owns the chunk.** ING-7 makes each version its own row,
  and the join is correct, so RET-2 reports the record faithfully. The wrong label on on-demand ingests (v1 hard-coded,
  latest PDF fetched) is an ingestion bug that predates RET-2 and is fixed at the source in **ING-10** (Ready, backend, P1).
  RET-2 doesn't wait for it, and neither does AI-8 (it copies the field). FE-4 is the first place a user sees "vN", so
  ING-10 merged is a check at FE-4's design approval (Notes line added to FE-4). This stays within ADR-0014: `version` is
  always present as an int, as the ADR says.
- **Q3 → confirmed. `page` is omitted for every hit, and AC2's page half is reworded.** ADR-0014 lists `page` as
  "(int, omitted when unknown)" and says "RET-2 checks whether `page_number` is reliable and omits it if it isn't". Omitting
  it for every hit is the outcome the ADR planned for, so it is consistent with the Accepted ADR and needs no decision from
  Mahesh. The new AC2 wording ("a chunk with a stored `page_number` returns no `page`") is not a weakening. AC1 and the
  Scope always made `page` conditional on reliability, and the old "known page" assumed a reliability the code doesn't
  have. The new assertion tests the case the ticket forbids (a stored but wrong page must not leak). Real per-chunk pages
  are not dropped: they move to **ING-11** with their own testable ACs (it includes the paired ai-owned `TokenChunker` part).

### Conditions (QA checks each one)
1. **AC3 evidence:** the whole-file run plus the three node-ID runs from Q1. The PR shows the one-fragment diff in `_GO_TO_EVAL_SQL`,
   and the eval-side string and `scripts/evaluate_retrieval.py` are unchanged (`git diff --stat` shows no `scripts/` path).
2. **README row wording:** `version` is "the arXiv version recorded for the chunk's paper", not "the version the chunk came
   from". The second wording is only true after ING-10. Keep "`page` is omitted until chunk pages are recorded reliably (ADR-0014)".
3. **Integration assertion 4 covers every hit:** all 3 hits have `Page == nil` and no `"page"` key in their JSON (the v1 chunk with
   NULL `page_number` and both v2 chunks with stored 4 and 7), not only the page-4 chunk.
4. **`db.yml`:** the step's run pattern is the literal regex `'TestHNSW|TestSearchProvenance'` (the `\|` in the design's
   table is Markdown escaping). The PR links the `db.yml` job log lines from `t.Logf` (assertion 5) and the unchanged `TestHNSW` recall lines (AC4).
5. **`Page` comment** in `search.go` says why it is never set and names ING-11, so the next reader doesn't "fix" it by
   selecting `c.page_number`.
6. **PR description** states both limits in one line each: `page` is omitted for all hits (finding 2 → ING-11), and `version`
   on on-demand ingests can be wrong about the PDF (finding 3 → ING-10).
7. **Size:** about 215 lines estimated. If the build goes over 400, the split seam is unit tests (c)+(d) to a follow-up commit
   on the same ticket. Never drop the integration test, because it is AC2's only evidence.

### Follow-ups filed
- [ING-10](../../agents/tasks/ING-10.md) (backend, P1, Ready): the on-demand ingester parses the version from `entry.ID`, and
  the ingester, downloader and crawler fetch `https://arxiv.org/pdf/<id>v<n>.pdf`.
- [ING-11](../../agents/tasks/ING-11.md) (backend + paired ai part, P1, Ready for design, build after RET-2 merges): record
  each chunk's real start page and return it as `page`.
- Board Backlog line: v1/v2 near-duplicates can take two top-5 slots (product rule: latest version only, or dedupe by `arxiv_id`).
