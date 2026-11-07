[qa-reviewer] QA round 1 for ING-10: **FAIL** (1 blocking finding: AC5 stack.yml run missing)

# QA report — ING-10 · PR #31 · round 1

**Verdict:** FAIL (one blocking finding: AC5 has no evidence because `stack.yml` never ran on the PR. Everything else checks out.)
**Reviewed commit:** `d2b133f035242ca5ffeff60fd6944c0433dab950` · **Date:** 2026-11-07
**Ticket:** `agents/tasks/ING-10.md` · **PRD:** Product ING-7, ING-4, QA-3; Technical §3, §7.3; ADR-0014 (Accepted)

> Provenance: the QA harness refused to write `agents/reviews/ING-10/report.md`. This text is the report; the evidence pack is committed at `7cc504d`.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 128518966336 | pass: `make lint-go` and `make test-go`, every package `ok`, including `internal/arxiv`, `crawler`, `downloader`, `query` ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/01-ci-go-job.png?raw=true)) |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Python M0 unit tests | CI | pass |
| Frontend (lint, test, build) | CI | pass (no frontend changes) |
| Agent ownership check | CI job 128518966381 | pass: `Ownership OK for role=backend (321 changed lines)` ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/08-ac6-diff-size-sql.png?raw=true)) |
| Full stack (`stack.yml`, AC5) | CI | **not run**: no run exists for `d2b133f` ([06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/06-ac5-stack-not-run.png?raw=true)) |
| Ticket verification `go test … -run …` | local, scratch module | pass ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/02-local-ticket-tests.png?raw=true), [05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/05-ac4-ing9-tests.png?raw=true)). Go 1.25 and the module proxy can't be reached from this sandbox (`proxy.golang.org` 403/no DNS). So the **real** PR sources for `internal/{arxiv,config,crawler,downloader}`, `query/ingester{,_test}.go` and `shared/events` were built with local Go 1.24 (`-race`), and only `db`/`kafka`/`storage`/minio/kgo/ulid were stubbed (method signatures copied from the real code). |
| Mutation check | local, same scratch module | 18/18 KILLED, 0 SURVIVED, 0 INVALID ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/03-mutation.png?raw=true)) |
| `make lint` / `make test-unit` | not run locally: no Go 1.25 toolchain or modules. CI ran both Go halves (`lint-go`, `test-go`) and Python M0. `gofmt -l internal/` with local gofmt printed nothing. | — |
| `make eval` | not run: ingest/label path only, retrieval and answering code unchanged | — |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: `entry.ID …v3` → `version = 3`, key `raw/<id>_v3.pdf`, `source_url …v3.pdf`, `"version": 3` to `/internal/ingest` | ✅ | `ingester.go:169-174, 199-200`. `TestIngestUsesEntryVersion` checks the request list [Atom, `/pdf/2401.12345v3.pdf`], the DB record (v3, key, source_url), `UpdatePaperDownloaded` at v3, the MinIO put key, the payload `version == 3` from a real `httptest` embedder, and `res.Version`. Passes in CI ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/01-ci-go-job.png?raw=true)) and locally ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/02-local-ticket-tests.png?raw=true)). Mutants M03–M07 and M09 (unversioned URL, payload v1, key v1, record v1, update v1, result v1) are all killed ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/03-mutation.png?raw=true)). |
| AC2: no or malformed version → error naming the ID; no PDF request, DB write or MinIO put | ✅ | `ingester.go:171-174` returns before any PDF request. `TestIngestRejectsUnversionedEntry` covers no suffix, `v`, `v0` and `vx`: the error contains the entry ID, exactly 1 arXiv request (Atom), and 0 DB/MinIO/ingest calls. Mutants M01 (default to 1), M02 (no check) and M08 (error omits the ID) are killed. |
| AC3: downloader fetches `/pdf/<id>v<n>.pdf` (n = 1, 2); crawler `SourceURL` versioned | ✅ | `downloader.go:103` `arxiv.PDFURL(arxivID, version)`. `TestHandleRecordFetchesTheEnvelopesVersion` covers n = 1, 2 and 0 → v1: exactly one URL, put key, DB key/version and published envelope version. The crawler fixture `2307.08691v2` gives `…/2307.08691v2.pdf` (`crawler_test.go:40`). Mutants M10–M13 are killed. |
| AC4: requests per ingest unchanged; ING-9 limiter/UA tests unmodified | ✅ (see finding 2 `[spec]` on wording) | The count is still asserted: 2 per ingest (`checkSpaced` length, `len(arxivURLs)==2`) and 1 per download. `limiter_test.go` diff is 0 lines. In the ING-9 test files the **only** removed line is the `TestIngestSpacesArxivRequests` URL literal (`…2307.08691.pdf` → `…2307.08691v1.pdf`); everything else is additions ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/04-ac4-ing9-test-diff.png?raw=true)). All 9 ING-9 tests pass on the PR sources ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/05-ac4-ing9-tests.png?raw=true)). |
| AC5: milestone suite (`stack.yml`) passes on the PR | ❌ no evidence | `stack.yml`'s `pull_request.paths` has no `internal/**`. The PR changes only `internal/**`, #26 (OPS-H10) is still open, and nobody ran `workflow_dispatch` on the branch: 0 Full stack runs for `d2b133f` ([06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/06-ac5-stack-not-run.png?raw=true)). The ticket says "otherwise dispatch it on the branch and say so". The fixture risk is still open ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/07-ac5-m4-fixture-risk.png?raw=true)); see finding 1. |
| AC6: diff < 400 lines; PR lists the suspect-rows SQL and doesn't run it | ✅ | 8 files, +288/−33 = 321 changed lines (CI ownership check agrees). The PR body has the `SELECT … WHERE source_url = 'https://arxiv.org/pdf/' \|\| arxiv_id \|\| '.pdf'` line marked "do **not** run against a shared DB" ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/08-ac6-diff-size-sql.png?raw=true)). |

## Scope check
- All 8 files are under `internal/`, so they're backend-owned (CI ownership OK). No tickets, reviews or docs leaked into the PR. The README "On-demand ingest" row (`README.md:164`) doesn't describe the PDF source, so not editing it is correct.
- **Interface refactor (ruling: in scope, small).** `downloader` gets `paperDB`/`pdfStore`/`publisher` and `ingester` gets `ingestDB`/`objectPutter`, about 30 lines of production code. AC1/AC2 ask for DB/MinIO counters on fakes, and `area-notes/internal.md` requires "fake or interface the dependencies". Constructor signatures are unchanged and `go build ./cmd/arxivlens` passed in CI. A nil `*minio.Client` is kept as a nil interface (`ingester.go:88-90`), so the existing "skip upload" branch still works. A nil `*db.DB` or `*storage.Storage` would still panic on use, same as on `main`. `d.storage.Bucket` → `d.bucket`, captured once at construction, which is equivalent because `Storage.Bucket` is set once. No unrelated refactor.
- Out-of-scope items untouched: `rag.go:164` `pdf_url`, frontend fallback URLs, `ExtractCleanArxivID` (still strips `vN`), no relabelling of stored rows. The downloader's `0 → 1` default is kept and now logs one warning line (`downloader.go:73`).

## PRD fit
This delivers ING-7's "versions are distinct records" honestly for on-demand ingest (ING-4, Technical §7.3): the row, MinIO key, `source_url` and `/internal/ingest` payload now carry the version of the PDF that was actually fetched. An unversioned entry is refused instead of defaulted, as the "honest refusals" principle requires. QA-3 / ADR-0014 `paper_version` gets a true number. arXiv politeness is unchanged: the same request count goes through the ING-9 limiter with the same UA (AC4). L1 natural keys and the `ObjectExists` check are unchanged.

## Findings
1. **[blocking][dev] AC5 has no evidence: `stack.yml` never ran on `d2b133f`.** The path filter excludes `internal/**` and #26 hasn't merged, so the ticket's fallback applies: dispatch it on the branch, `gh workflow run stack.yml --repo MaheshPulivarthi18/ArxivLens --ref agent/backend/ING-10`, then put the run URL in the PR and the ticket Notes. That run is the only place the M3/M4 fixture risk can be settled. This PR changes the "Seed the M3/M4 fixture" step's on-demand ingest of `2608.20331` from a hard-coded v1 to arXiv's current version. If arXiv has a v2+, the row and object become `raw/2608.20331_v2.pdf`, while `tests/test_m4_chaos.py:42-48, 62-65` still sends `version: 1` / `raw/2608.20331_v1.pdf` (object absent), and M4 fails ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/07-ac5-m4-fixture-risk.png?raw=true)). The seed step prints `ingest.json` (which has `version`), so the run log answers this directly. If it fails that way: stop, file the fixture follow-up for ai, and don't loosen the asserts (per AC5). Neither the sandbox nor QA could reach arXiv (`export.arxiv.org` CONNECT 403), and runs of `main`'s code can't answer it because `main` hard-codes v1.
2. **[spec][pm-lead] AC4's "unmodified" can't be met literally, and the one-line change meets its intent.** Ruling: not a weakening, so not a dev finding. The scope requires the ingester's PDF URL to be versioned (`…2307.08691v1.pdf`), so ING-9's substring `arxiv.org/pdf/2307.08691.pdf` can no longer match any request. Reverting the literal against the new code fails `TestIngestSpacesArxivRequests` (mutation T01, [03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/03-mutation.png?raw=true)), so the edit was necessary. The new literal is strictly more specific: it also kills an unversioned-URL regression on its own (M17). Request count, order, spacing (`checkSpaced`) and UA asserts are byte-identical ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/04-ac4-ing9-test-diff.png?raw=true)). Suggested AC4 wording: "ING-9 count/order/spacing/UA assertions unchanged; expected PDF URL literals may only become versioned."
3. **[nit][dev] Crawler entry without a version: `source_url` stays unversioned while the downloader now fetches v1 explicitly.** `crawler.go:196-205` keeps `https://arxiv.org/pdf/<id>.pdf` with `version = 1` "because the version is unknown". After this PR the downloader fetches `arxiv.PDFURL(id, 1)`, so the stored PDF really is v1, but its `source_url` still points at "latest". That keeps the row inside the suspect-rows SQL, which may be intended. Real Atom entries always carry `vN`, so impact is low. Either leave it and reword the comment ("the downloader will fetch v1"), or version it. Not blocking.

## Missing tests
- No blocking gaps: every behaviour change in the diff is pinned (18/18 mutants killed).
- Nice to have: an Atom **error entry** (arXiv answers a bad `id_list` with `<id>http://arxiv.org/api/errors#…</id>` and title `Error`). It is now refused by the version check before any PDF request, which is the right outcome, but no test pins that honest refusal.
- Nice to have: a downloader case where the object already exists in MinIO for v2 (`ObjectExists → true`), showing no PDF request and the v2 labels. This path isn't changed by this PR.

## Hand-off
FAIL → back to backend-engineer. Only finding 1 blocks: dispatch `stack.yml` on the branch and attach the run (or file the ai fixture follow-up if M4 fails on the version). Finding 2 is for pm-lead (AC4 wording). Re-review checks the stack run's seed `ingest.json` version, `make test-full` results and the M4 outcome.


## Evidence images (commit 7cc504d)
- [00-ci-checks](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/00-ci-checks.png?raw=true)
- [01-ci-go-job](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/01-ci-go-job.png?raw=true)
- [02-local-ticket-tests](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/02-local-ticket-tests.png?raw=true)
- [03-mutation](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/03-mutation.png?raw=true)
- [04-ac4-ing9-test-diff](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/04-ac4-ing9-test-diff.png?raw=true)
- [05-ac4-ing9-tests](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/05-ac4-ing9-tests.png?raw=true)
- [06-ac5-stack-not-run](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/06-ac5-stack-not-run.png?raw=true)
- [07-ac5-m4-fixture-risk](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/07-ac5-m4-fixture-risk.png?raw=true)
- [08-ac6-diff-size-sql](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7cc504d/agents/reviews/ING-10/evidence/08-ac6-diff-size-sql.png?raw=true)

Evidence folder: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/7cc504d/agents/reviews/ING-10/evidence


---
_Generated by [Claude Code](https://claude.ai/code)_


*Provenance: the harness refused the QA subagent's Write to report.md; the orchestrator saved the body of PR #31 comment 6712679245 verbatim (https://github.com/MaheshPulivarthi18/ArxivLens/pull/31#issuecomment-6712679245).*
