# ADR-0013: Make `/v1/search` use the HNSW index after plan-cache warm-up (recall vs p95)

- **Status:** Proposed
- **Date:** 2026-11-03
- **Deciders:** Mahesh Pulivarthi (only the human owner sets Accepted/Rejected)
- **Blocks:** follow-up OPS-H5-F1 (not yet specced; specced once this is decided). Does **not** block OPS-H5 / PR #16.

## Context
OPS-H5 (PR #16) adds `chunk_embeddings_hnsw_idx` in a migration (Technical PRD §5). Its DB workflow measured the real
`vectorHitsSQL` / `hybridSearchSQL` from `internal/query/search.go` on pgvector 0.8.7 (evidence
`agents/reviews/OPS-H5/evidence/12`, `13`, `23`):

- **Custom plans** (actual parameter values): the planner picks the HNSW index (except a ~2% category filter, where it
  correctly picks papers → pkey + sort). Vector arm about 1.2 ms at 13k embeddings.
- **Generic plans**: never HNSW. `($3 IS NULL OR p.categories && $3)` with `$3` unknown is mis-estimated, so the
  vector arm is an exact sort over all rows: about 20 ms at 13k embeddings, growing linearly with the corpus.
- **Production** uses pgx's statement cache and `plan_cache_mode=auto`, so each pooled connection runs 5 custom plans
  and then switches to generic (`hybridSearchSQL x20: plans(generic=15 custom=5)`). Steady-state `/v1/search` is an
  exact scan: Recall@5 = 1.00, but it ignores the index. Product PRD §8 (`/v1/search` p95 < 1.5 s) is met today only
  because the corpus is small.
- With the HNSW path forced (custom plans, shipped `ef_search=100` + `iterative_scan=strict_order`), 50 rows always come
  back, but on synthetic data filtered (cs.CL, 25%) Recall@5 is **0.76**. With `ef_search=200` it is 0.83, and with
  `ef_search=400` it is 0.88. Unfiltered Recall@5 is 1.00. The synthetic clusters are harder than real embeddings, so these
  numbers are a lower bound, not a forecast.

Related: ADR-0006 (Recall@5 gate), ADR-0008 (HNSW params at scale, Proposed), ADR-0012 (search p95 gate, Proposed).

## Options
1. **Keep the current behaviour (exact after warm-up).** Pros: no code change, exact recall. Cons: the index is
   mostly unused, and latency grows with N. The p95 risk returns as the corpus grows toward Technical PRD §9 sizes.
2. **Force custom plans:** add `SET LOCAL plan_cache_mode = force_custom_plan` to `hnswSearchSettings` (one line,
   about +0.3 ms planning), and pick `ef_search` from the table (100 / 200 / 400). Pros: the index is used on every query,
   and the change is small. Cons: filtered Recall@5 drops to 0.76 to 0.88 on synthetic data. Real-corpus `make eval` must
   confirm it against the ADR-0006 gate. Today `make eval` doesn't measure this regime (OPS-H5 follow-up F2).
3. **Split the SQL** into a with-category and a no-category variant, so even the generic plan's estimate is correct. Pros:
   the planner picks the index or the exact path per filter, with no forced planning. Cons: two query strings to keep in
   sync (the EVAL-5 parity drift guard must cover both), and a larger change.
4. **Option 2 or 3, but only above a corpus-size threshold.** Pros: exact recall while the corpus is small. Cons: extra
   config and a behaviour switch that's hard to test.

## Recommendation (from pm-lead)
Option 1 for now. Defer until EVAL-3 produces real-corpus numbers, then take Option 2 with `ef_search=200`, if the real
filtered Recall@5 meets the ADR-0006 gate. If it doesn't, take Option 3. Today's corpus is small enough that exact search
is both correct and fast. Product PRD §7 favours trustworthy results over speed we don't yet need. The F2 fix (eval
applies `hnswSearchSettings` and measures both plan regimes) should land first, so the decision rests on real data.

## Decision
_(Filled by the human.)_

## Consequences
- Option 1: nothing to do now. Add a backlog item to revisit when the corpus passes ~100k chunks or the p95 gate
  (ADR-0012) shows pressure.
- Option 2/3: pm-lead specs OPS-H5-F1 for backend-engineer, with a `make eval` before/after (requires F2) and the
  `search_integration_test.go` guard extended to auto mode.
