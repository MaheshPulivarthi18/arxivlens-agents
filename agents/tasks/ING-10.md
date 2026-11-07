# ING-10: The stored version matches the PDF: on-demand ingest parses the version, and every PDF fetch is versioned

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (provenance: `version` in search hits and citations has to be true; Product PRD §7 principle 3) |
| **PRD ref** | Product PRD ING-7 (versions are distinct records), ING-4 (on-demand ingest), QA-3; Technical PRD §3, §7.3; ADR-0014 (Accepted: `version` / `paper_version` fields) |
| **Depends on** | ING-9 (Done, `2b71772`: same files, already merged). No open PR touches these files (checked 2026-11-07: #26 `stack.yml`/README, #27 `internal/llm`, #28 `rag.go`, #29 evals, #30 Python). Independent of RET-2: no shared files. |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-ING-10"`) |
| **Design required** | no. P1, no new command, table or service. The storage key format (`raw/<id>_v<n>.pdf`), event envelope and HTTP API are unchanged |
| **Status** | Ready to merge (2026-11-07: QA PASS r2 + pm-lead APPROVE on `c940779`; PR #31 raised, waiting on Mahesh) |

## Goal
A paper row says `version = N` only when the PDF that was chunked is version N. Today on-demand ingest hard-codes
`version := 1` (`internal/query/ingester.go:179`) and fetches the unversioned `https://arxiv.org/pdf/<id>.pdf` (`ingester.go:181`),
which arXiv serves as the latest version. So a paper at v3 is stored, chunked and cited as "v1". The downloader
(`internal/downloader/downloader.go:80`) and the crawler's `SourceURL` (`internal/crawler/crawler.go:236`) also use the
unversioned URL, so a version released between crawl and download gets the wrong label. Once RET-2 and AI-8 expose
`version`, that wrong number becomes a false provenance claim.

## Scope
- `internal/query/ingester.go`: take the version from the Atom `entry.ID` (`http://arxiv.org/abs/<id>v<n>`), the same way the
  crawler does (`crawler.go:200-212`). Prefer a small shared helper (for example in `internal/arxiv/`) that both call, so the
  two parsers can't drift. If `entry.ID` has no parseable version, **fail the ingest with an error and write no row**. Don't
  default to 1: that would be the "default as if real" case. Use `version` for `pdfStorageKey`, `sourceURL`, the DB record
  and the `/internal/ingest` payload (all of them already take the variable).
- PDF URL is `https://arxiv.org/pdf/<id>v<n>.pdf` in the ingester, in `downloader.go:80` (from the envelope's version), and
  in the crawler's `SourceURL` (`crawler.go:236`). Keep the request count and the ING-9 limiter path unchanged: still one request per PDF.
- Tests: `ingester_test.go`, `downloader_test.go`, `crawler_test.go` (fake servers already exist from ING-9). Assert the request
  path the fake server saw, and the version written.
- App `README.md`: only if it describes the PDF source (check the "On-demand ingest" text). Technical PRD §7.3: pm-lead docs PR.
- Out of scope:
  - Relabelling or re-ingesting rows already stored with a wrong version. That is an ops decision: list the affected on-demand rows in the PR (query in Notes) and leave them.
  - A user who asks for a specific version (`2401.12345v2`). `ExtractCleanArxivID` strips it, and the ingest still takes the latest. Which version to ingest is a product rule → Backlog.
  - Which version(s) search returns (board Backlog, from RET-2).
  - The citation `pdf_url` (`rag.go:164`, ai-owned) and the frontend fallback URLs (`ReferencesStack.jsx:45`, `SynthesisView.jsx:47`, `PapersLibrary.jsx:129`), which are unversioned. AI-8 and FE-4 Notes point at them.
  - The downloader's `version == 0 → 1` default (`downloader.go:50-52`) for envelopes without a version. Keep it, but log a warning when it fires (one line).

## Acceptance criteria
- [x] AC1: On-demand ingest of a paper whose Atom `entry.ID` ends in `v3` writes `version = 3`, storage key `raw/<id>_v3.pdf`,
  `source_url` `https://arxiv.org/pdf/<id>v3.pdf`, and sends `"version": 3` to `/internal/ingest` (unit test, fake arXiv and embedder servers).
  Evidence: `TestIngestUsesEntryVersion` ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/01-ci-go-job.png?raw=true), [02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/02-local-ticket-tests.png?raw=true), [03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/03-mutation.png?raw=true)).
- [x] AC2: An `entry.ID` with no version (or a malformed one) fails the ingest with an error that names the ID. No PDF request, no DB write, no MinIO put (unit test, using counters on the fakes).
  Evidence: `TestIngestRejectsUnversionedEntry`, mutants M01/M02/M08 killed ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/02-local-ticket-tests.png?raw=true), [03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/03-mutation.png?raw=true)).
- [x] AC3: The downloader requests `/pdf/<id>v<n>.pdf` for an envelope with version n (test with n = 1 and n = 2). The crawler's `SourceURL` is versioned (`crawler_test.go` against `testdata/arxiv_feed.xml`, which has `2307.08691v2`).
  Evidence: `TestHandleRecordFetchesTheEnvelopesVersion`, `TestParseAtomFeed`, mutants M10–M13 killed ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/02-local-ticket-tests.png?raw=true), [03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/03-mutation.png?raw=true)).
- [x] AC4 *(amended 2026-11-07, see Notes)*: Requests per ingest are unchanged, and all ING-9 limiter/UA tests pass. Their count, order, spacing and UA
  assertions are unchanged (`git diff` shows no edits to them); expected PDF URL literals may only become versioned (`<id>.pdf` → `<id>v<n>.pdf`).
  ~~all ING-9 limiter/UA tests pass **unmodified** (`git diff` shows no edits to their bodies)~~
  Evidence: only changed ING-9 line is the `TestIngestSpacesArxivRequests` URL literal, `limiter_test.go` untouched ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/04-ac4-ing9-test-diff.png?raw=true)); all ING-9 tests pass ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/05-ac4-ing9-tests.png?raw=true)); T01/M17 ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/03-mutation.png?raw=true)).
- [x] AC5: The milestone suite passes on the PR: `stack.yml` (it runs on Go PRs once OPS-H10 #26 merges; otherwise dispatch it on the branch and say so).
  If `tests/test_m3_query.py` / `test_m4_chaos.py` assume fixture `2608.20331` is v1 and arXiv has a later version, stop and file the fixture follow-up for ai. Never loosen the asserts.
  Evidence: dispatched run https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42411848508 on `c940779`, success; seed ingest `"version":1`, M4 fixture holds, no ai follow-up ([10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2512967/agents/reviews/ING-10/evidence/10-ci-checks-c940779.png?raw=true), [11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2512967/agents/reviews/ING-10/evidence/11-ac5-stack-run-meta.png?raw=true), [12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2512967/agents/reviews/ING-10/evidence/12-ac5-seed-ingest-version.png?raw=true), [13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2512967/agents/reviews/ING-10/evidence/13-ac5-test-full.png?raw=true), [14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2512967/agents/reviews/ING-10/evidence/14-ac5-m3-m4-dot-map.png?raw=true)).
- [x] AC6: Diff < 400 changed lines. The PR lists the SQL to find possibly mislabelled on-demand rows (Notes) and does not run it against any shared DB.
  Evidence: 322 changed lines (CI ownership check); SQL in the PR body, marked do-not-run ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/08-ac6-diff-size-sql.png?raw=true), [15](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2512967/agents/reviews/ING-10/evidence/15-r1-r2-diff.png?raw=true)).

## Verification
```bash
make lint
make test-unit
go test ./internal/query/ ./internal/downloader/ ./internal/crawler/ ./internal/arxiv/ -run 'Ingest|Download|Crawl|Version|Limiter' -v
# stack.yml on the PR (AC5): run URL + the ingest step's log lines
```

## Notes
- 2026-11-07 (pm-lead): filed from the RET-2 design review (finding 3, Q2). RET-2 ships `version` as the record's version now. This ticket makes the record true.
  FE-4 is the first place users see "vN", so its design approval checks that ING-10 has merged.
- Rows that may be mislabelled (for the PR text, not to run): `SELECT arxiv_id, version FROM papers WHERE source_url = 'https://arxiv.org/pdf/' || arxiv_id || '.pdf';`
  (every unversioned source URL is suspect; the on-demand rows are the likely wrong ones).
- 2026-11-07 (backend-engineer): built on `agent/backend/ING-10` @ `d2b133f` (worktree `/root/wt/ING-10`; not pushed, no PR yet).
  - Diff (`git diff --stat origin/main...HEAD`): 8 files, +288 / -33. `ownership-check.sh origin/main agent/backend/ING-10` → `Ownership OK for role=backend (321 changed lines)`.
    New `internal/arxiv/id.go` (`SplitVersion`, `PDFURL`) + `id_test.go`; `crawler.go`, `downloader.go`, `ingester.go` + their tests.
  - Shape: crawler and ingester both call `arxiv.SplitVersion`. Ingester fails with `arXiv entry ID "<id>" for <arxiv_id> has no valid version; not ingesting`
    before the PDF request. Downloader fetches `arxiv.PDFURL(id, envelope version)` and logs a warning when the `version==0 → 1` default fires.
    Crawler: versioned `SourceURL` when the entry has a version; a version-less entry keeps the unversioned URL (version unknown; stored 1 is a default),
    so the suspect-rows SQL above still finds it. To get infra-free tests, `downloader` and `ingester` now hold small interfaces over `*db.DB`, `*storage.Storage`,
    `*kafka.Producer` and `*minio.Client` (constructors unchanged; a nil `*minio.Client` stays a nil interface).
  - **AC4 wording conflict (needs pm-lead/QA decision):** one ING-9 test body line changed. `TestIngestSpacesArxivRequests` expected the substring
    `arxiv.org/pdf/2307.08691.pdf`, and a versioned URL can't contain it. The literal is now `arxiv.org/pdf/2307.08691v1.pdf` (the stub's entry is v1).
    That is stricter, not weaker: the request count, order, spacing and UA checks are unchanged. No other ING-9 test line changed (`limiter_test.go`, `checkSpaced`, `TestConcurrentIngestsShareOneLimiter`, `TestFetchPDFIsSpacedAndIdentified` untouched).
  - Commands: Go 1.25 isn't available here (`go: download go1.25.0 … Forbidden` via the proxy; no module cache), so `make lint` / `make test-unit` were **not run locally: no Go 1.25 toolchain or modules**.
    Instead, Go 1.24 (`GOTOOLCHAIN=local`) on a scratch module: the real `internal/arxiv`, `crawler`, `downloader`, `query/ingester{,_test}.go`, `config`, `shared/events` with
    stub `db`/`kafka`/`storage`/minio/kgo/ulid whose method signatures copy the real ones. `go vet ./internal/...` was clean. `go test -race ./internal/...` gave `ok` for all 4 packages, and the
    verification `-run` set passed (TestIngestUsesEntryVersion, TestIngestRejectsUnversionedEntry, TestHandleRecordFetchesTheEnvelopesVersion, TestParseAtomFeed, TestSplitVersion, the ING-9 tests).
    Mutation check: 6/6 killed (ingester default-v1, unversioned ingester URL, payload version 1, downloader unversioned URL, crawler unversioned SourceURL, helper accepts v0).
    `gofmt -l` on every tracked file + new files printed nothing.
  - AC status: AC1 met (unit test `TestIngestUsesEntryVersion`: requests [Atom, `/pdf/2401.12345v3.pdf`], row v3 + key + source_url, MinIO put, payload `version: 3`).
    AC2 met (`TestIngestRejectsUnversionedEntry`: no version, `v`, `v0`, `vx`; error names the ID; only the Atom request; 0 DB/MinIO/ingest calls).
    AC3 met (`TestHandleRecordFetchesTheEnvelopesVersion` n = 1, 2, plus 0 → v1; crawler `2307.08691v2` → `…/2307.08691v2.pdf`). AC4: request count unchanged (2 per ingest, 1 per download, asserted); see the conflict above.
    AC5 **not verified**: needs `stack.yml` on the PR. Risk: `tests/test_m4_chaos.py` hard-codes `raw/2608.20331_v1.pdf` and `version: 1`. If arXiv now has 2608.20331 at v2+, the seeded row becomes v2 and M4 fails.
    I couldn't check arXiv from here (proxy 403); if it fails that way, file the fixture follow-up for ai and don't loosen it. AC6: 321 changed lines (< 400); the PR should carry the suspect-rows SQL above, not run.
  - README: the "On-demand ingest" row doesn't describe the PDF source, so no change. Optional follow-up wording for `README.md` line 164 (after #26 merges):
    `| POST | /v1/papers/ingest | On-demand ingest by arXiv ID or URL (stores the latest arXiv version; a vN suffix in the input is ignored) |`.
- 2026-11-07 (backend-engineer): rework round 1 for the QA report (`agents/reviews/ING-10/report.md`, FAIL on `d2b133f`). New head is `c940779`.
  - Finding 1 [blocking, AC5]: I dispatched `stack.yml` on the branch with the REST API, because the path filter skips `internal/**` until #26 merges.
    Run https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42411848508 (head `c940779`) concluded **success**. Seed step: the on-demand ingest of
    `2608.20331` returned `"version":1` (57 chunks, 57 embeddings), and `arxivlens status` reported `(v1)` with key `raw/2608.20331_v1.pdf`. arXiv still serves v1, so the M4
    fixture holds and no ai follow-up is needed. `make test-full` (F1 deselected) gave `96 passed, 1 skipped, 3 deselected`, including M3 and M4 chaos. The skip is the opt-in
    `DATABASE_URL` evals test. The known-failure F1 step (`continue-on-error`) gave `2 failed, 1 passed`, the documented CPU rerank timeout. ci.yml on `c940779` is all green.
    PR comment: https://github.com/MaheshPulivarthi18/ArxivLens/pull/31#issuecomment-6712826852
  - Finding 2 [spec, pm-lead]: AC4 wording. I made no change and left the ACs untouched. This is pm-lead's call.
  - Finding 3 [nit]: I reworded only the `crawler.go:198-200` comment, which now says the row is stored as v1, the downloader fetches v1, and `source_url` stays unversioned on purpose for the
    suspect-rows query. Behaviour is unchanged. Commit `c940779`.
- 2026-11-07 (pm-lead): **AC4 amended** (QA r1 finding 2 / r2 finding 1, `[spec]`). The original wording "ING-9 tests pass **unmodified**" couldn't be met
  together with this ticket's own scope: ING-9's `TestIngestSpacesArxivRequests` expected the substring `arxiv.org/pdf/2307.08691.pdf`, and a versioned URL can never
  contain it (QA mutant T01: reverting the literal fails against the new code). The amendment is **not a weakening**: the ING-9 count/order/spacing/UA
  assertions are byte-identical, `limiter_test.go` is untouched, and the new literal `…2307.08691v1.pdf` is stricter (on its own it kills an unversioned-URL regression, M17).
  New rule in AC4: those assertions stay unchanged; expected PDF URL literals may only become versioned. My spec error: I wrote "unmodified" without checking which ING-9 asserts embed the URL.
- 2026-11-07 (pm-lead): final review **APPROVE** on `c940779` (`agents/reviews/ING-10/report.md`). PR #31 marked ready for review, label `ready-to-merge`, evidence in the description.
  Follow-up (pm-lead, docs PR): Technical PRD §7.3 step 2 should say the PDF is the version named in the Atom entry ID and a version-less entry is refused.
