# ING-10: The stored version matches the PDF: on-demand ingest parses the version, and every PDF fetch is versioned

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (provenance: `version` in search hits and citations has to be true; Product PRD §7 principle 3) |
| **PRD ref** | Product PRD ING-7 (versions are distinct records), ING-4 (on-demand ingest), QA-3; Technical PRD §3, §7.3; ADR-0014 (Accepted: `version` / `paper_version` fields) |
| **Depends on** | ING-9 (Done, `2b71772`: same files, already merged). No open PR touches these files (checked 2026-11-07: #26 `stack.yml`/README, #27 `internal/llm`, #28 `rag.go`, #29 evals, #30 Python). Independent of RET-2: no shared files. |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-ING-10"`) |
| **Design required** | no. P1, no new command, table or service. The storage key format (`raw/<id>_v<n>.pdf`), event envelope and HTTP API are unchanged |
| **Status** | Ready (2026-11-07, from the RET-2 design review, finding 3 / Q2) |

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
- [ ] AC1: On-demand ingest of a paper whose Atom `entry.ID` ends in `v3` writes `version = 3`, storage key `raw/<id>_v3.pdf`,
  `source_url` `https://arxiv.org/pdf/<id>v3.pdf`, and sends `"version": 3` to `/internal/ingest` (unit test, fake arXiv and embedder servers).
- [ ] AC2: An `entry.ID` with no version (or a malformed one) fails the ingest with an error that names the ID. No PDF request, no DB write, no MinIO put (unit test, using counters on the fakes).
- [ ] AC3: The downloader requests `/pdf/<id>v<n>.pdf` for an envelope with version n (test with n = 1 and n = 2). The crawler's `SourceURL` is versioned (`crawler_test.go` against `testdata/arxiv_feed.xml`, which has `2307.08691v2`).
- [ ] AC4: Requests per ingest are unchanged, and all ING-9 limiter/UA tests pass **unmodified** (`git diff` shows no edits to their bodies).
- [ ] AC5: The milestone suite passes on the PR: `stack.yml` (it runs on Go PRs once OPS-H10 #26 merges; otherwise dispatch it on the branch and say so).
  If `tests/test_m3_query.py` / `test_m4_chaos.py` assume fixture `2608.20331` is v1 and arXiv has a later version, stop and file the fixture follow-up for ai. Never loosen the asserts.
- [ ] AC6: Diff < 400 changed lines. The PR lists the SQL to find possibly mislabelled on-demand rows (Notes) and does not run it against any shared DB.

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
