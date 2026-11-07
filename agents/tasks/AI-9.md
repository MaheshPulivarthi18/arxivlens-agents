# AI-9: Cut CPU cross-encoder rerank latency without changing scores (Known failure F1)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 (`/v1/ask` takes about 10 s on a CPU runner, against a 3 s p95 target; an LLM call has to fit in the same budget) |
| **PRD ref** | Product PRD §8 (`/v1/ask` p95 < 3 s, `/v1/search` p95 < 1.5 s), §7 principle 4; Technical PRD §7.1, §9; ADR-0010 (Accepted: pool of 20, sort by rerank) |
| **Depends on** | OPS-H1 (merged `71cb609`: `stack.yml` runs the stack and the "Known failure F1" step). None open. |
| **Jira** | new story under epic KAN-2 "Retrieval & answer quality gates" (`labels = "task-AI-9"`) |
| **Design required** | no: P1, one file, no contract change. The ranking-neutral constraint (AC2) is what keeps it small. |
| **Status** | Ready (Wave 2: starts when an ai slot frees, i.e. AI-7 or EVAL-6 reaches Ready to merge) |

## Goal
On GitHub's CPU runners, `/internal/rerank` scoring the ADR-0010 pool of 20 passages takes about 10 s, so three M3 tests
time out ("Known failure F1", accepted by Mahesh on 2026-11-04 as a known red). Find where the time goes and make it fast
**without changing what is ranked or how it scores**, so retrieval quality and ADR-0010 stay as they are.

## Scope
- `services/embedder/api.py` (`rerank_endpoint`, `load_models`):
  - First measure, per request: tokenize ms, forward ms, total ms, passage count, padded length. Log one line with counts and
    timings only (no text).
  - Allowed, score-preserving changes: `torch.inference_mode()`; a CPU thread setting (`torch.set_num_threads`, env-configurable,
    default = available cores); sorting pairs by length and scoring in batches to cut padding, then restoring input order; a
    warm-up rerank at startup so the first request doesn't pay one-time costs; anything else that leaves scores within 1e-4.
  - **Not allowed here** (each changes ranking, so each needs a Proposed ADR): a lower `max_length`, int8/fp16 quantisation,
    a different reranker model, a smaller pool (ADR-0010), and any timeout change in tests.
- `tests/test_m0.py` (already run by `make test-py` and CI's Python job, which installs torch/transformers): a new test that
  mocks the tokenizer/model (no download) and checks scores come back in input order after length sorting and batching.
  A new test file would need a backend `Makefile` change, so don't add one.
- Out of scope: `stack.yml` (backend-owned). Once F1 passes, backend drops the "Known failure F1" step in a follow-up. Also
  out: `/internal/ingest` model reuse (Backlog), the Go `search.go` client timeout.

## Acceptance criteria
- [ ] AC1 — Before/after timing from `stack.yml` runs (embedder container log lines), for a 20-passage rerank: p50 and max over
      the M3 + seed requests, and the split tokenize/forward. Paste both runs' links.
- [ ] AC2 — Scores unchanged: on the fixture corpus, the new endpoint's scores match the old ones within 1e-4 for the same
      requests (a CI or stack run that calls both code paths, or the old and new commits, on ≥ 3 queries × 20 passages). Ranking order identical.
- [ ] AC3 — Input order preserved after length sorting: the mocked-model unit test passes, and it fails when the reorder-back step is removed (mutation shown).
- [ ] AC4 — The three F1 tests (`test_rag_ask_with_groundedness_support`, `test_rag_early_refusal_on_unrelated_query`,
      `test_hybrid_search_with_rrf_and_rerank`) pass in the "Known failure F1" step on the PR's `stack.yml` run. **If the allowed
      changes can't get there: stop, paste the AC1 numbers, and hand them to pm-lead** for an ADR on the ranking-changing options. Don't loosen any timeout.
- [ ] AC5 — README: a note on the thread env var, if one was added (Environment table).

## Verification
```bash
make test-py
python3 -m pytest -q tests/test_m0.py -k rerank
# stack.yml on the PR: embedder logs (timings), "Known failure F1" step result
```

## Notes
- 2026-11-07 (pm-lead): from the 2026-11-07 merge-review follow-up "F1 CPU rerank latency fix". Sandbox: Hugging Face is blocked
  (403), so model timings only come from `stack.yml` on GitHub runners. Follow-up for backend after merge: remove the "Known
  failure F1" step and its `F1_TESTS` deselection in `stack.yml`.
- Wave 2: `api.py` is touched by no other planned task.
