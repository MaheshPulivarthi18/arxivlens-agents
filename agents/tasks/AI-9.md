# AI-9: Cut CPU cross-encoder rerank latency without changing scores (Known failure F1)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 (`/v1/ask` takes about 10 s on a CPU runner, against a 3 s p95 target; an LLM call has to fit in the same budget) |
| **PRD ref** | Product PRD §8 (`/v1/ask` p95 < 3 s, `/v1/search` p95 < 1.5 s), §7 principle 4; Technical PRD §7.1, §9; ADR-0010 (Accepted: pool of 20, sort by rerank) |
| **Depends on** | OPS-H1 (merged `71cb609`: `stack.yml` runs the stack and the "Known failure F1" step). None open. |
| **Jira** | new story under epic KAN-2 "Retrieval & answer quality gates" (`labels = "task-AI-9"`) |
| **Design required** | no: P1, one file, no contract change. The ranking-neutral constraint (AC2) is what keeps it small. |
| **Status** | In Progress (built on `agent/ai/AI-9` @ `3e6420e`; draft PR to be opened by the orchestrator → In QA) |

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
- 2026-11-07 (ai-engineer): build on `agent/ai/AI-9` commit `3e6420e` (2 files, +241/-9; ownership check OK).
  - `services/embedder/api.py`: new `score_pairs()` keeps the same tokenizer call (truncation, `max_length=512`) and model,
    sorts pairs by token length (stable), scores batches of 8 (`RERANK_BATCH_SIZE`) under `torch.inference_mode()` and writes
    each score back to its input index. One log line per request: `rerank passages= batches= max_len= tokens= padded_tokens=
    single_batch_padded_tokens= threads= tokenize_ms= forward_ms= total_ms=` (no text). Startup: `torch.set_num_threads` from
    `EMBEDDER_TORCH_THREADS` (default = cores available to the process, logged as `torch threads: A -> B`) and a 3-passage
    warm-up rerank (logged as `rerank warm-up ...`). No change to max_length, dtype, model, pool size or timeouts.
  - `tests/test_m0.py`: mocked tokenizer/model tests for `score_pairs` and `rerank_endpoint` (20 mixed-length passages,
    batch 4, compared with the old single-batch algorithm kept in the test), a thread env test, and
    `test_rerank_real_cross_encoder_scores_match_single_batch` (real `bge-reranker-base`, 3 queries x 20 synthetic
    passages of 1-30 sentences, old vs new within 1e-4 and identical ranking; parity numbers are emitted as pytest warnings
    so they show in CI's `-q` log; it skips if the model can't load). It downloads ~1.1 GB in CI's Python job: the HF cache
    key there only covers bge-base, so the download happens on every run.
  - Sandbox: torch/transformers/fastapi can't be installed (pypi.org and download.pytorch.org are denied by the proxy, 403).
    The 4 rerank tests ran under a numpy-backed fake `torch` plus stubbed third-party modules (scratch harness, not committed):
    3 passed, 1 skipped (real model not loadable). AC3 mutation (scores appended in sorted order, write-back removed):
    `test_rerank_score_pairs_keeps_input_order_after_length_sorting` and `test_rerank_endpoint_returns_scores_in_input_order`
    FAILED with "Mismatched elements: 20 / 20". Restored: 3 passed, 1 skipped. Real torch only runs in CI.
  - AC1/AC4: need CI. The before numbers come from the previous `stack.yml` run's embedder logs (old code has no timing line;
    use the M3 client-side durations), and the after numbers from this PR's `stack.yml` run (grep `rerank passages=20` in
    `stack-logs/compose.log`). If F1 still fails after this, stop and hand the AC1 numbers to pm-lead for an ADR (int8,
    lower max_length, smaller pool). Expect limited padding savings, because fixture chunks are ~512 tokens: compare
    `padded_tokens` with `single_batch_padded_tokens` in the log line.
  - AC2: covered in CI by the real-model parity test (synthetic passages, not the fixture DB chunks). For the fixture corpus:
    the scoring path is deterministic (eval mode, no sampling), so run the embedder API at `71cb609` and at `3e6420e`, send the
    same `/internal/rerank` bodies (≥ 3 queries x the 20 pool passages, captured from the stack) to both, and diff the
    `scores` arrays (≤ 1e-4, same argsort). Not run: needs the stack plus HF access.
  - AC5: **deferred to a follow-up after #21 merges** (open PR #21 changes `README.md`). The follow-up adds an
    `EMBEDDER_TORCH_THREADS` row to the README Environment table.
  - Jira KAN-39 not updated from this session; the orchestrator mirrors the stage when it opens the PR.
