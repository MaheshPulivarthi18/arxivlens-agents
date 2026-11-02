# Tech design — RET-1: `/v1/ask` and `/v1/search` rerank a candidate pool and return results sorted by rerank score

**Author:** backend-engineer · **Ticket:** `agents/tasks/RET-1.md` · **PRD:** QA-1, QA-2 (Product PRD §6.2); Technical PRD §7.1; ADR-0010 (Accepted) · **Status:** Approved (pm-lead, 2026-11-02, with binding conditions below)

## Problem
`SearchEngine.HybridSearch(rerank=true)` asks Postgres for exactly `limit` RRF hits, calls the cross-encoder, and
attaches `RerankScore` to each hit **without reordering**. `/v1/ask` asks for `maxCitations` (5) hits, so the
cross-encoder can only filter the RRF top 5 (in `rag.go`); it can never promote a better passage from RRF rank 6–20.
ADR-0010 decides that `rerank=true` reranks a pool of 20 RRF candidates (or `limit`, if larger), sorts by rerank
score with RRF order as the tie-break, and truncates to `limit`, falling back to RRF order (logged with the trace ID)
if reranking fails. `rerank=false` must not change. Covers AC1–AC5 in code; AC6 (eval + latency) and AC7 (PRD diagram)
are verification/docs steps described below.

## Approach

### Files
| File | Change |
|---|---|
| `internal/query/search.go` | `RerankPool` const, `reranker` interface, candidate-fetch seam, `rerankAndSort` pure-ish function, trace-ID helper, fallback log line. SQL text unchanged. |
| `internal/query/search_test.go` (new) | Table-driven tests, no Postgres, no embedder. |
| `internal/query/rag.go`, `client.go`, `server.go`, `cmd/` | **No change.** `rag.go` already calls `HybridSearch(ctx, q, cats, maxCitations, true)` and gets the sorted top 5; its filters (< 0.45 dropped; appendix/table/supplementary < 0.70 dropped) stay in `rag.go` and run **after** the sort, per the PM note on the ticket. `NewSearchEngine` signature is unchanged. |

### Flow (`rerank=true`)
```
HybridSearch(ctx, q, cats, limit, rerank=true)
  limit <= 0 → 20                       (existing default, unchanged)
  pool := max(RerankPool=20, limit)
  hits := s.fetch(ctx, q, cats, pool)    embed query + existing hybrid SQL with LIMIT $5 = pool
  if len(hits) == 0 → return hits
  scores, err := s.rr.Rerank(ctx, q, passages(hits))      exactly one call, len(passages) == len(hits)
  if err != nil || len(scores) != len(hits) || any score is NaN:
      log.Printf("[Query Service] rerank fallback trace_id=%s reason=%q pool=%d scores=%d", ...)
      return hits[:min(limit, len(hits))]                  RRF order, RerankScore left 0 (as today on failure)
  assign hits[i].RerankScore = float64(scores[i])
  sort.SliceStable(hits, by RerankScore desc)              stable ⇒ ties keep RRF order (SQL ORDER BY rrf_score DESC)
  return hits[:min(limit, len(hits))]
```

### Flow (`rerank=false`)
`s.fetch(ctx, q, cats, limit)`, return the hits as-is. Same SQL, same `LIMIT $5 = limit`, no rerank call, no sort,
no truncation. Byte-for-byte identical to today.

### Seams for unit testing (kept minimal)
```go
const RerankPool = 20 // ADR-0010; if latency forces a smaller pool, change here and record it in ADR-0010

// reranker is the one method HybridSearch needs from *EmbedClient (which already satisfies it).
type reranker interface {
    Rerank(ctx context.Context, query string, passages []string) ([]float32, error)
}

type SearchEngine struct {
    database    *db.DB
    embedClient *EmbedClient
    modelName   string
    // test seams; NewSearchEngine wires the real implementations
    rr    reranker
    fetch func(ctx context.Context, query string, categories []string, n int) ([]SearchHit, error)
}
```
- `fetch` defaults to a new unexported method `s.fetchCandidates`, which is today's steps 1–2 (embed query, build
  `halfvec` literal, run the hybrid SQL, scan) moved verbatim, with `n` bound to `$5`.
- `rr` defaults to `embedClient`.
- Tests build `&SearchEngine{rr: fake, fetch: fakeFetch}` directly (same package), so no Postgres or HTTP.
- The rerank/sort/truncate/fallback logic lives in one unexported function
  `rerankAndSort(ctx, rr reranker, query string, hits []SearchHit, limit int) []SearchHit` so the core can also be
  tested without the fetch seam. Two seams total, both unexported; no new exported API apart from `RerankPool`.

Why a func field rather than a second interface for the DB: the only DB use is one query; a one-method interface plus
an adapter type would add more code than the closure for no gain. The SQL itself stays in `search.go` as a literal
so the eval's parity test (`test_rrf_pool_sql_mirrors_search_go`, landing with EVAL-1) keeps reading it from the same
place. I will not change any SQL fragment; if the parity test keys on the surrounding Go code (e.g. the
`Pool.Query(...)` line), I'll flag it to ai-engineer in the same cycle as the ticket asks.

### Trace ID for the fallback log
The query service has no trace context today: `internal/telemetry` (OpenTelemetry, `StartSpan`, `ExtractTraceparent`)
is not wired into the HTTP server, and `rag.go` makes its own `trace_id` with `generateTraceID()` but keeps it local.
So `search.go` gets a small helper:
```go
type traceIDKey struct{}
func WithTraceID(ctx context.Context, id string) context.Context // store an ID for downstream logs
func traceIDFrom(ctx context.Context) string
//   1. OTel span in ctx with a valid SpanContext → its TraceID (works once telemetry is wired into the server)
//   2. else the value set by WithTraceID
//   3. else generateTraceID() + "(generated)" so the line is never empty
```
Follow-up for **ai-engineer** (one line in `rag.go`, not a RET-1 dependency): in `Ask`, call
`ctx = WithTraceID(ctx, traceID)` before `HybridSearch` so the fallback log line matches the `trace_id` returned to
the user. Until then `/v1/ask` fallback logs carry a generated ID; AC3 is tested via `WithTraceID` in the unit test.

### Latency
- SQL: both CTEs already compute 50 rows per arm; raising the outer `LIMIT` from 5 to 20 only adds 15 rows of
  scan/transfer (chunk content, a few KB). Negligible.
- Rerank: the cost moves from 5 to 20 (query, passage) pairs in one `/internal/rerank` call to `bge-reranker-base`.
  On CPU this is roughly linear in pairs, so expect ~4× the current rerank time; this is the main new cost and the
  number AC6 must measure. One call (not 4) avoids extra HTTP round trips and lets the embedder batch.
- `/v1/search` with `limit > 20` reranks `limit` passages (ADR says `max`); there is no cap on `limit` today, so a
  client could ask for 200 and pay for 200 pairs. Not changed here (API contract); noted as a risk below.
- No new timeout is added; the existing 30 s HTTP client timeout applies, and a timeout falls back to RRF order.

## Alternatives considered
1. **Rerank only the requested `limit` and sort** — trivial, but keeps the bug ADR-0010 exists to fix: the cross-encoder
   still can't surface RRF rank 6–20 for `/v1/ask`.
2. **Move the 0.45 / 0.70 filters into `search.go`** — rejected by the PM note: filters stay in `rag.go` after the sort,
   and `/v1/search` would otherwise silently drop hits.
3. **Interfaces for both the embedder and a `db.Querier`** (pgx-style `Query` returning rows) — testable but needs a fake
   `pgx.Rows`; much more code than a single fetch closure. Rejected for size.
4. **Fall back to returning an error on rerank failure** — the ADR says fall back to RRF order; an error would turn an
   embedder blip into a failed `/v1/ask`.
5. **Rerank in parallel batches** — premature; one call of 20 is within the expected budget. Revisit only if AC6 fails.

## Contracts and invariants
- **HTTP API:** response shape unchanged (`SearchHit` fields, `omitempty` on `rerank_score`). Ordering semantics of
  `rerank=true` change, which ADR-0010 (Accepted) approves. `rerank=false` unchanged.
- **Events, schema, embedding model:** not touched. SQL text not touched (only the bound `$5` value differs for `rerank=true`).
- **Reliability invariants:** no Kafka/DLQ/idempotency code touched; `tests/test_m4_chaos.py` unaffected.
  No silent failure: every fallback is logged with a trace ID (ADR-0010).
- `RerankScore == 0` keeps meaning "not reranked" on fallback, which is what `rag.go`'s `> 0 &&` guard relies on today.

## Test plan
All in `internal/query/search_test.go`, table-driven, fake `reranker` (records call count, passages, returns scripted
scores/error) and fake `fetch` (records `n`, returns N synthetic hits in RRF order). Log capture via `log.SetOutput`
to a buffer, restored in `t.Cleanup`.

| Acceptance criterion | Test (name / type) | Runs in CI? |
|---|---|---|
| AC1 ordered by rerank score; RRF rank 8 with top score comes first | `TestHybridSearchRerankOrdersByScore` (cases: rank-8 winner → index 0; fully reversed scores; already-sorted scores) / unit | Yes (`go test ./internal/query/...`) |
| AC2 pool = `max(RerankPool, limit)`, exactly one rerank call | `TestHybridSearchRerankPoolSize` (cases: limit 5 → fetch n=20, 1 call, 20 passages, 5 returned; limit 20 → n=20; limit 50 → n=50, 50 passages; limit 0 → default 20; fetch returns only 7 → 7 passages, 1 call, 5 returned; fetch returns 0 → 0 calls) / unit | Yes |
| AC3 rerank error / count mismatch → RRF order, top `limit`, no error, log with trace ID | `TestHybridSearchRerankFallback` (cases: error; too few scores; too many scores; NaN score) asserting order == RRF, len == limit, `err == nil`, `RerankScore == 0`, log contains `rerank fallback` and the ID set via `WithTraceID`) + `TestTraceIDFrom` (WithTraceID value; empty ctx → non-empty generated) / unit | Yes |
| AC4 ties keep RRF order | `TestHybridSearchRerankTiesKeepRRFOrder` (all-equal scores → identity order; two tied pairs interleaved with distinct scores) / unit | Yes |
| AC5 `rerank=false` unchanged | `TestHybridSearchNoRerankUnchanged` (fetch n == limit for limit 5/20/0→20; 0 rerank calls; output `json.Marshal` equals marshal of fetched hits, i.e. no `rerank_score` key, same order) / unit; plus code review that the SQL literal diff is empty | Yes |
| AC6 `make eval` before/after; `/v1/ask` p95 < 3 s | Manual: `make infra-up`, start workers + query service, `make eval` on `main` then on the branch; paste both tables and p95 into the PR. If infra is unavailable in the sandbox: PR says "not run: infra unavailable" with these exact commands. Latency numbers labelled with the machine profile (Technical PRD, Proposed rule). | No (needs Docker, indexed corpus, HF model) |
| AC7 Technical PRD §7.1 diagram | Not code. I leave pm-lead a note in the ticket with the new steps: `PG-->>Q: top max(20, limit) by rrf_score`, `Q->>EA: rerank pool (one call)`, `Q: stable sort by rerank_score desc, truncate to limit; on failure keep RRF order + log trace_id`. pm-lead raises the `docs/` PR in arxivlens-agents. | n/a |

Failure paths covered: rerank error, short and long score arrays, NaN scores, empty candidate set (no rerank call),
fewer candidates than `limit`, `limit <= 0` default, fetch error propagated unchanged (`TestHybridSearchFetchError`).
Also `make test-unit` and `make lint` (gofmt, vet) in CI; `make test-full` M3 query suite when infra is available.

## Risks and rollout
- **Answers change for existing questions** (expected; ADR-0010). Detected by AC6 before/after eval; QA compares.
- **Latency:** 4× rerank pairs on `/v1/ask`. Detected by AC6 p95. Mitigation per ADR: lower `RerankPool` and record the
  new number in ADR-0010 (a one-constant change).
- **Large `limit` on `/v1/search`** reranks `limit` passages; no cap exists. Out of scope (API change); I'll suggest a
  follow-up to cap `limit` if pm-lead wants one.
- **Eval parity drift:** EVAL-1's parity test reads `search.go`. SQL is unchanged, but the move of the query into
  `fetchCandidates` could break a test that keys on surrounding Go; coordinated with ai-engineer in the same cycle.
- **Trace ID mismatch** between fallback log and `/v1/ask` response until the one-line `rag.go` follow-up lands.
- **Rollback:** revert the PR (single-file logic change + new test file; no migration, no contract or config change).

Estimated diff: ~70 lines in `search.go`, ~220 in `search_test.go`.

## PM decision
**Approved** — pm-lead, 2026-11-02. Binding conditions for the build are numbered below; QA checks each one.

**Why approved.** The flow matches ADR-0010 point by point: pool `max(20, limit)` via a `RerankPool` const, exactly one
`Rerank` call over the whole pool, `sort.SliceStable` by `RerankScore` desc (ties keep the SQL's `rrf_score DESC`
order), truncate to `limit`, and on error / count mismatch fall back to RRF order with a logged trace ID and no error to
the caller. `rerank=false` keeps `LIMIT $5 = limit`, no call, no sort. The 0.45 / 0.70 filters stay in `rag.go` after
the sort, per the ticket note. Scope is `search.go` + new `search_test.go` (backend-owned); no `rag.go`, `server.go`,
`client.go`, schema, event or response-shape change; the only API change is the ordering ADR-0010 approved. The test
plan maps every AC (AC1–AC5 unit, AC6 manual with "not run" fallback, AC7 via pm-lead). Two unexported seams (`rr`,
`fetch`) are the minimum needed to test without Postgres; the func field over a `db.Querier` interface is the right call.
Estimated ~290 lines is under the 400 target.

**EVAL-1 parity test, checked concretely.** `test_rrf_pool_sql_mirrors_search_go` (PR #2 branch `agent/ai/EVAL-1`,
`tests/test_evals_data.py`) reads `internal/query/search.go` as plain text and asserts only:
`src.count("LIMIT 50") == 2`, `"WHERE ce.model = $2" in src`, and both `1.0/(60 + v.rank)` / `1.0/(60 + k.rank)`.
Moving the SQL literal verbatim into `fetchCandidates` *inside `search.go`* keeps all four true, so the refactor as
designed does not break it. Raising the pool from 5 to 20 is a bound-parameter change (`$5`) and isn't checked by the
test at all. I ran it from an archive of the EVAL-1 branch: passes on current `search.go`; **fails** if one extra
comment containing `LIMIT 50` is added to `search.go`; and **silently passes** if `search.go` is moved/renamed (the
`os.path.exists` guard). Hence conditions 1–2, and the guard-hardening follow-up in AI-4.

**Binding conditions**
1. The hybrid SQL literal stays in `internal/query/search.go` (same file, character-identical text, still bound with
   `$1..$5`, pool passed as `$5`, never interpolated). `search.go` must not gain any other occurrence of the strings
   `LIMIT 50` or `WHERE ce.model = $2`, including in comments or the `RerankPool` doc comment (one extra `LIMIT 50`
   fails the parity test). Don't move the SQL to another file or package.
2. Because the parity test is not on `main` yet, RET-1's CI won't run it. The developer runs it against the branch's
   `search.go` and pastes the output in the PR; QA reruns it:
   ```bash
   cd app && git fetch -q origin agent/ai/EVAL-1 && D=$(mktemp -d) && git archive FETCH_HEAD | tar -x -C "$D" \
     && cp internal/query/search.go "$D/internal/query/search.go" \
     && (cd "$D" && python -m pytest -q tests/test_evals_data.py::test_rrf_pool_sql_mirrors_search_go)
   ```
   If EVAL-1 has merged by build time, rebase on `main` instead and let CI run it. Merge order stays EVAL-1 then RET-1.
3. Drop the OpenTelemetry branch from `traceIDFrom`: telemetry isn't wired into the query server, and importing
   `go.opentelemetry.io/otel/trace` directly would promote an indirect dependency in `go.mod` for dead code. Two steps
   only: the ctx value, else a generated ID. Wiring OTel is a separate task when telemetry reaches the server.
4. The trace-ID helpers are **unexported** (`withTraceID`, `traceIDFrom`): `rag.go` is in package `query`, so nothing
   needs to be exported. `RerankPool` stays the only new exported identifier.
5. Fallback log line keeps the ID grep-able: `trace_id=<32 hex>` plus a separate `trace_id_source=ctx|generated`
   field (don't append "(generated)" to the ID). Log the reason, pool size and score count only — never the query text
   or passage content.
6. `rerank=false` and the fetch path keep today's error messages verbatim (`failed to get query vector: ...`,
   `no vector returned for query`, `hybrid search query failed: ...`, `failed to scan search hit: ...`); AC5's
   "byte-for-byte" covers errors too. `NewSearchEngine` signature unchanged.
7. `RerankPool = 20` is the ADR value. If AC6's p95 forces a smaller pool, don't just change the constant: say so in
   the PR and the ticket Notes so pm-lead records it in ADR-0010 (and EVAL-1's `RRF_POOL_SIZE` must follow).
8. The NaN-score fallback is fine (defensive, same fallback path). No cap on `/v1/search` `limit` in this PR (that's an
   API change; pm-lead tracks it as a possible Proposed follow-up, not part of RET-1).

**Follow-ups (not RET-1 dependencies)**
- `agents/tasks/AI-4.md` (ai-engineer, P2): pass `rag.go`'s `traceID` into ctx before `HybridSearch` so `/v1/ask`
  fallback logs carry the user-visible `trace_id`; harden the parity drift guard (fail if `search.go` is missing,
  assert `RerankPool = 20` matches `RRF_POOL_SIZE`).
- AC7: pm-lead raises the Technical PRD §7.1 diagram `docs/` PR from the note in this design at final review.
