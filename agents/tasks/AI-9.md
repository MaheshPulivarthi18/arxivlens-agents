# AI-9: Cut CPU cross-encoder rerank latency without changing scores (Known failure F1)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 (`/v1/ask` takes about 10 s on a CPU runner, against a 3 s p95 target; an LLM call has to fit in the same budget) |
| **PRD ref** | Product PRD §8 (`/v1/ask` p95 < 3 s, `/v1/search` p95 < 1.5 s), §7 principle 4; Technical PRD §7.1, §9; ADR-0010 (Accepted: pool of 20, sort by rerank) |
| **Depends on** | OPS-H1 (merged `71cb609`: `stack.yml` runs the stack and the "Known failure F1" step). **OPS-H10 merged** (stack keeps embedder logs on green runs; needed for AC1). #21 merged (README, AC5). |
| **Jira** | new story under epic KAN-2 "Retrieval & answer quality gates" (`labels = "task-AI-9"`) |
| **Design required** | no: P1, one file, no contract change. The ranking-neutral constraint (AC2) is what keeps it small. |
| **Status** | Blocked (needs OPS-H10 merged for AC1's stack numbers; then rework round 2 on #24, which stays **draft**). F1 itself moved to AI-10 (needs ADR-0015) |

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
      *(Amended 2026-11-07, pm-lead.)* **Before** = run 42344527109: the old code logs no timings, so use F1's client-side
      `ReadTimeout` at 10 s and EVAL-3's rerank ≈ 10–12 s/query (Eval run 42344527129). **After** = this PR's `stack.yml`
      run on a base that includes OPS-H10, from `stack-logs/embedder-timing.log`: p50/max of `total_ms`, `tokenize_ms` and
      `forward_ms` over the `passages=20` lines, plus `threads=`, `padded_tokens` vs `single_batch_padded_tokens`, and the
      warm-up line. Paste the numbers into these Notes; pm-lead copies them into ADR-0015's table. The Python-job numbers
      (synthetic passages) don't replace this AC.
- [ ] AC2 — Scores unchanged: on the fixture corpus, the new endpoint's scores match the old ones within 1e-4 for the same
      requests (a CI or stack run that calls both code paths, or the old and new commits, on ≥ 3 queries × 20 passages). Ranking order identical.
      *(Amended 2026-11-07, pm-lead, QA [spec] 4.)* Synthetic passages are accepted instead of fixture chunks: the property
      doesn't depend on the corpus, and mixed lengths are the harder case for sort-and-batch. One condition: at least 3 of the
      20 passages per query must exceed 512 tokens (so truncation is exercised, as on ~512-token fixture chunks), and the
      emitted warning reports how many were truncated.
- [ ] AC3 — Input order preserved after length sorting: the mocked-model unit test passes, and it fails when the reorder-back step is removed (mutation shown).
- [x] ~~AC4 — The three F1 tests pass in the "Known failure F1" step on the PR's `stack.yml` run.~~ Stop clause reached
      (QA r1: 3/3 still `ReadTimeout` at 10 s, run 42362802353, same as baseline 42344527109).
- [ ] AC4 *(replaces the above, 2026-11-07, pm-lead)* — The PR's `stack.yml` run reports the F1 step result (expected: still
      failing). The F1 step, `F1_TESTS` and every timeout are unchanged, and the AC1 numbers are handed over for ADR-0015.
      Making F1 pass is now **AI-10** (needs ADR-0015 Accepted). The PR description must say plainly that this PR does
      **not** fix F1.
- [ ] AC5 — README: a note on the thread env var, if one was added (Environment table). *(2026-11-07, pm-lead, QA [spec] 5: done in this PR, on the rebase onto a `main` that contains #21. AC1 already makes that rebase necessary, so no separate follow-up.)*
- [ ] AC6 *(added 2026-11-07, pm-lead, QA nit 3)* — `ci.yml`'s Python job does not download the reranker. The real-model parity test loads with `local_files_only=True` and skips with the reason "bge-reranker-base not in local HF cache" only when it is absent from the cache. Any other load error **fails** the test. It still runs in `stack.yml` (models pre-fetched there, so an HF outage fails loudly in the pre-fetch step). Evidence: the `ci.yml` Python job log shows the skip reason and its pytest time back near baseline (≈ 6 s, not 60 s); the `stack.yml` AC4 log shows the test passed.

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
- 2026-11-07 (pm-lead, after QA r1 FAIL, `agents/reviews/AI-9/report.md`, evidence `cd2ced2`): **decision**.
  - The score-preserving work is correct (parity max diff 5.36e-07, AC3 mutation killed), but it can't make F1 pass. The
    ticket's AC4 stop clause applies. The ranking-changing options (int8, lower `max_length`, smaller pool, smaller model,
    ONNX) are in **ADR-0015** (Proposed, for Mahesh), and the work that would make F1 pass is **AI-10** (Blocked on ADR-0015 + this PR).
  - AI-9 is kept, re-scoped as the instrumented, score-neutral step AI-10 builds on: the timing log line, the `score_pairs`
    seam and the thread setting. It can merge on its own merits once AC1/AC2/AC5/AC6 pass. **#24 stays draft** and isn't raised until QA PASS + PM APPROVE.
  - It's Blocked now because AC1's after-numbers can't exist until `stack.yml` keeps the embedder log on green runs:
    backend ticket **OPS-H10**.
  - Round-2 checklist (when OPS-H10 has merged; #21 must be merged too, for AC5):
    1. [ ] Rebase `agent/ai/AI-9` onto `main` (with OPS-H10 + #21); the PR's `stack.yml` run gives AC1's numbers from `stack-logs/embedder-timing.log`.
    2. [ ] AC2: at least 3 of 20 passages per query > 512 tokens; the warning reports the truncated count.
    3. [ ] AC5: README Environment row for `EMBEDDER_TORCH_THREADS` (and `RERANK_BATCH_SIZE` if it is an env var).
    4. [ ] AC6: parity test `local_files_only=True`; skip only when not cached; other load errors fail.
    5. [ ] QA "missing tests": the `load_models` warm-up failure path (start-up continues) and the early return when the
       cross-encoder fails to load; a single-passage request (old scalar `probs` case); `batch_size >= len(passages)` and an
       exact multiple of `batch_size`; the `_torch_threads` fallback without `os.sched_getaffinity`.
    6. [ ] PR description: "does not fix F1; see ADR-0015 / AI-10".
  - Rework count: QA r1 FAIL = round 1 of 2 for this task.
