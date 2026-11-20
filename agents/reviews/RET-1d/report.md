<!-- Provenance: saved verbatim by the orchestrator from PR #94 comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/94#issuecomment-7048775984 (QA harness could not write report.md), cycle 2026-11-20T19:00Z -->

[qa-reviewer] QA report — RET-1d · PR #94 · round 1

**Verdict:** PASS
**Reviewed commit:** `a5bf0f4ee52235509d63cf217a57d9c843d2a4c7` (base `230f617`) · **Date:** 2026-11-21
**Ticket:** [agents/tasks/RET-1d.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/RET-1d.md) (KAN-92) · **PRD:** Product PRD §7 (honest failure), Technical PRD §7 (query API); follow-up to RET-1c QA findings 1 and 2
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence
(The QA harness refused to write `report.md`, so this comment is the report. The orchestrator saves it verbatim.)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136509407953, head `a5bf0f4` | pass: `make lint-go` (vet + gofmt), `make test-go` with `-race` (`ok arxivlens/internal/query`), `make build-go` ([07](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/07-ac7-ci-go-job.png ``)) |
| Full stack (compose + make test-full) | CI job 136509406826, head `a5bf0f4` | pass: real `POST /v1/papers/ingest` through the interface-typed ingester → 200, `248 passed, 1 skipped, 3 deselected`, F1 M3 trio `3 passed` ([08](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/08-ac7-ci-stack-job.png ```)) |
| Python M0 / Frontend / DB / Agent ownership | CI | pass ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/00-ci-checks.png)) |
| Ticket verification commands | local: scratch go1.24 module with the PR's real `internal/{query,db,arxiv,llm,config}` + real pgx v5.6.0 clone + minio stub | `gofmt -l` empty, `go vet ./internal/query/` clean, `-race` run set ok, `./internal/...` all ok, `cmd/ shared/ migrations/` diff empty ([09](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/09-verification-local.png)) ```` |
| `make test-unit` / `make lint` | not run locally: Go 1.25 and the module proxy are unreachable, npm blocked | CI (above) is the source of truth |
| `make eval` | not run: no retrieval/answering behaviour change (types + tests only) | n/a |

CI's `go test ./...` isn't `-v`, so the CI log shows the package result, not the new test names. The per-row PASS lines come from my local run of the identical sources (09 shows `diff -r` = identical).

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 `/v1/ask` NaN → 500, one log line with `route=/v1/ask` + `trace_id=t-ret1d` | ✅ | row `ask unencodable` (`server_test.go:249-251`), PASS ([01](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/01-ac1-ask-trace-id.png)); ````` mutant m (`""` trace ID) and z (wrong trace value) KILLED ([06](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/06-ac6-mutants.png ``````)) |
| AC2 ingest/discover `boom` → 500, `application/json`, body `{"error":"boom"}\n`, no log | ✅ | rows `ingest error`/`discover error` check the code, Content-Type, encoder-identical body, exact body and zero log lines, PASS ([02](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/02-ac2-error-paths.png ```````)); mutants n, o, w KILLED (06) |
| AC3 per-route "unencodable" + "ok" rows | ✅ with accepted deviation | ok + unencodable rows for search, ask, status, stats; ok rows for ingest, discover ([03](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/03-ac3-route-rows.png ````````)). There's no unencodable row for ingest/discover: `IngestResult` has only string/int fields (shown in 03), so `json.Marshal` can't fail and that route label can't be observed (mutant e1 is equivalent). status/stats use a year-10000 `time.Time` instead of NaN, because `PaperRecord`/`SystemStats` have no float fields. See finding 3. Route-label mutants p, r, s KILLED (06) |
| AC4 `SetIngester(nil)` and never-set → 503 | ✅ | rows `{ingest,discover} {never set,set nil}` with the exact body `paper ingester not configured on server\n`, PASS ([04](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/04-ac4-nil-ingester.png)); ````````` mutants q (guard removed), x (nil check removed), y (503→500) KILLED; the recover wrapper turns a nil-pointer panic into a row failure (06) |
| AC5 no `os.Stderr` in `server_test.go`; previous writer restored | ✅ | `grep` exit 1; `redirectServerLog` saves and restores `log.Writer()` and flags and is used by both tests ([05](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/05-ac5-log-restore.png ``````````)) |
| AC6 mutants m–q killed by the AC6 `-run` set | ✅ (QA-run) | all five AC-named mutants KILLED by `go test -count=1 -run '^(TestWriteJSON\|TestHandlersEncodeContract)$'`, each with the intended row as the first failure (06). 0 INVALID, 0 NOT-APPLIED. The PR body doesn't carry the output: finding 1 |
| AC7 `make test-unit`/`make lint` green, Full stack green | ✅ | 00, 07, 08 (all six check runs `completed/success` on `a5bf0f4`) |
| Docs: none, say so in the PR | ⚠ | no docs needed (tests + unexported types only; routes and fields unchanged), but the PR body never says "Docs: none": finding 2 |

## Scope and design
- Changed files: `internal/query/server.go` (+35/-4) and `internal/query/server_test.go` (+226/-4). Both are backend-owned and in scope. No ticket, review or doc files are in the PR. `cmd/`, `shared/`, `migrations/` and the README are untouched (09). The task isn't design-required.
- `NewServer` and `SetIngester` keep their exported signatures. The four interfaces are unexported and hold exactly the methods the handlers call. Their signatures match the concrete types, which `NewServer` assigns, so the build proves the match.
- Nil trap: `SetIngester(nil)` stores a nil interface. `NewServer(nil, …)` would store typed-nil pointers in the other three fields, but no handler compares those fields to nil and `main.go` never passes nil, so behaviour matches `main`.
- Open PRs: #93 (OPS-H7a2b) edits `cmd/arxivlens/main.go` but not the `query.NewServer`/`SetIngester` lines, so there's no conflict.

## PRD fit
A no-infra unit test now catches the four RET-1c call-site mutants: an error path answering 200, the dropped trace ID and the wrong route labels. An encode failure or an ingest/discover error can no longer regress into a success-looking response unnoticed. That serves Product PRD §7's honest-failure rule and the Technical PRD §7 query API contract, and no route, field or status code changes.

## Findings
1. [nit] AC6 says the mutant output goes "in the PR". The PR body has only the unchecked box "AC6 mutants m–q killed (local stubbed harness)" and no output. QA's independent run (06) proves the AC. pm-lead: put 06 in the PR's evidence section when you raise it.
2. [nit] The ticket asks the PR to say "Docs: none". The PR body doesn't. Add the line when the PR is raised.
3. [spec] AC3's "every fallible route has an unencodable row with NaN" can't be met as written. `IngestResult` (string/int only) can't fail to marshal, so ingest/discover have no reachable encode-failure path. `db.PaperRecord`/`SystemStats` have no floats, so there's nowhere to put a NaN; the developer used a year-10000 `time.Time`, which does make `MarshalJSON` fail. QA accepts the deviation: it's recorded in the ticket Notes and the test comment, and the observable call-site contract is fully covered. pm-lead: amend AC3's wording.

## Missing tests (non-blocking, beyond this ticket's ACs)
- `SetIngester(non-nil)` storing the ingester: mutant q2 ("never store a non-nil ingester") SURVIVES the unit tests, because the fixtures build `&Server{ingester: fake}` directly. Only the Full stack ingest step (08: real ingest → 200) would catch it. A row that calls `SetIngester` with a real `*PaperIngester` (built from fakes, as `ingester_test.go` does) would close this.
- `http.Error` paths of the fallible routes: mutants e2 (search error 500→502) and e3 (`/v1/stats` error 500→**200**, an error that looks like a success) SURVIVE, and so would a change to the status 404 path. These aren't `writeJSON` call sites, so they're outside RET-1d's scope. But e3 is the exact Product PRD §7 failure this ticket targets. Suggested follow-up: one row per route with fake `err` → expected code, `text/plain` and a body prefix.
- Argument passing: the fakes ignore their inputs, so mutants like e4 (`AskOptions{Quick: req.Quick}` → `AskOptions{}`) survive. Out of scope here; a recording fake would cover it.

## What was not executed
- `make test-unit`, `make lint` and `make test-full` locally (no Go 1.25, module proxy, npm or Docker). CI is the evidence (00, 07, 08).
- Local runs used go1.24.7 with the PR's real sources, a real pgx v5.6.0 clone and a minio stub containing only `Client`/`PutObject`/`PutObjectOptions`/`UploadInfo` ([10](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/10-harness-source.png ```````````)). `cmd/` wasn't compiled locally; CI's `make build-go` did that.
- Jira (KAN-92) comment and transition: no Jira tool in this QA session, so they're left to the orchestrator.

## Evidence
| File | Shows |
|---|---|
| [00-ci-checks.png](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/00-ci-checks.png) | all 6 check runs on `a5bf0f4` completed/success |
| [01-ac1-ask-trace-id.png](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/01-ac1-ask-trace-id.png ````````````) | AC1 rows PASS + row source |
| [02-ac2-error-paths.png](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/02-ac2-error-paths.png `````````````) | AC2 rows PASS + row source + no-log assertion |
| [03-ac3-route-rows.png](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/03-ac3-route-rows.png ``````````````) | AC3 ok/unencodable rows PASS, route labels in server.go, `IngestResult` fields |
| [04-ac4-nil-ingester.png](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/04-ac4-nil-ingester.png ```````````````) | AC4 503 rows PASS + `SetIngester` source |
| [05-ac5-log-restore.png](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/05-ac5-log-restore.png ````````````````) | AC5 grep empty + `redirectServerLog` |
| [06-ac6-mutants.png](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/06-ac6-mutants.png `````````````````) | 19 mutants: 14 KILLED (incl. m, n, o, p, q), 5 SURVIVED (q2; e1 equivalent; e2–e4 outside AC), 0 INVALID |
| [07-ac7-ci-go-job.png](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/07-ac7-ci-go-job.png ``````````````````) | CI Go job: lint-go, test-go (-race), build-go |
| [08-ac7-ci-stack-job.png](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/08-ac7-ci-stack-job.png ```````````````````) | CI Full stack: real ingest 200, test-full 248 passed, F1 3 passed |
| [09-verification-local.png](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/09-verification-local.png) ```````````````````` | ticket verification commands, scope diff, scratch copy identical to PR head |
| [10-harness-source.png](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c01cc9df53bc6ad92bb05100a278cd37dedf0c71/agents/reviews/RET-1d/evidence/10-harness-source.png `````````````````````) | full harness source (module builder, mutant list, runner, stubs, dep tags) |

## Hand-off
PASS → pm-lead final review. Fold findings 1–2 into the PR description. Finding 3 is a ticket wording fix. Consider a follow-up ticket for the `http.Error`-path rows and the `SetIngester(non-nil)` row.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM verdict (pm-lead) · 2026-11-21 · PR #94 @ `a5bf0f4`

**Verdict: APPROVE**. The PR is raised: description rewritten with the Evidence section (images pinned to `c01cc9d`), `draft=false`, label `ready-to-merge`.

I opened all 22 evidence files (00–10, `.png` + `.txt`). Each one shows real command output for the reviewed head:
- AC1 (01): the `ask_unencodable` row asserts `route=/v1/ask ` and `trace_id=t-ret1d:`, and mutants m and z are killed (06). ✔
- AC2 (02): the error rows assert 500, the exact `{"error":"boom"}\n` body and zero log lines, and n, o and w are killed. ✔
- AC3 (03): ok + unencodable rows for the four routes that can fail to encode, ok rows for ingest/discover, and the `IngestResult` field
  types shown. Route-label mutants p, r and s are killed. The deviation is real (Go can't fail to marshal string/int structs) and the
  ticket now says so: **AC3 amended** per QA `[spec]` finding 3. ✔
- AC4 (04): never-set and set-nil rows give 503 with the exact body, and q, x and y are killed. ✔
- AC5 (05): `grep` exit 1, and the previous writer and flags are restored. ✔
- AC6 (06): QA ran it independently; m–q are all KILLED, with the first failing row named. It is now in the PR's Evidence section (finding 1). ✔
- AC7 (00, 07, 08): all 6 check runs succeed on `a5bf0f4`, and I re-checked them through the REST API at review time. The stack job does a real ingest through
  the interface-typed ingester → 200. ✔
- Docs: none. That is correct for unexported types and tests, and it is stated in the PR (finding 2). ✔

**Product fit.** This serves Product PRD §7 principle 2 (a failure must not pass as a success) for the encode and ingest-error paths, with no
change to routes, fields or status codes. **Scope** is right: two files in `internal/query/`, `cmd/`/`shared/`/`migrations/` untouched, +253/-8,
nothing extra. **Contracts:** no shared contract touched; `NewServer`/`SetIngester` signatures unchanged.

**Follow-up:** the gaps QA flagged that the ticket didn't cover (q2 `SetIngester(non-nil)`; e2/e3 `http.Error` paths, where e3
`/v1/stats` 500→200 is the same §7 failure) are specced as **[RET-1e](../../tasks/RET-1e.md)** (backend, P2, after #94 merges).

**Known limitation (lesson OPS-H8):** the outbound filter rewrote the PATCHed PR body again: image embeds lost `!` and were wrapped
in backticks, so they render as links. Text, links and pins are intact; this pinned evidence pack is the record.
