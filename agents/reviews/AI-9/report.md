<!-- Provenance: written by qa-reviewer (fresh context, cycle 2026-11-07T10:00Z); its harness could not write files, so the orchestrator saved the PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/24#issuecomment-6705637854 verbatim (role tag dropped). Evidence rendered by qa-reviewer with agents/tools/render_evidence.py. -->

# QA report — AI-9 · PR #24 · round 1

**Verdict:** FAIL
**Reviewed commit:** `3e6420e3a8a5dcea1ac8610906f493c0c1ad581b` · **Date:** 2026-11-07
**Ticket:** [`agents/tasks/AI-9.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/AI-9.md) · **PRD:** Product PRD §8 (`/v1/ask` p95 < 3 s, `/v1/search` p95 < 1.5 s), §7 principle 4; Technical PRD §7.1, §9; ADR-0010 (Accepted)
**Evidence:** [folder @ cd2ced2](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence). The harness blocked writing `report.md`, so this comment is the report of record; the orchestrator saves it verbatim.

**One-line reason:** the change is score-neutral (real-model diff ≤ 5.4e-7) and the order test kills the mutation, but F1 still fails exactly as on the baseline (3 × read timeout 10 s, AC4). The stack never captured the new embedder timing lines, so AC1 has no before/after numbers to hand to pm-lead.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 128374515040 | pass |
| Python M0 unit tests | CI job 128374515303 | pass: 72 passed, 1 skipped (the skip is pre-existing; baseline was 68 passed, 1 skipped). The real-model parity test **ran** ([03](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/03-ac2-real-model-parity.png?raw=true))`` |
| Frontend (lint, test, build) | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Agent guardrails (ownership) | CI job 128374515251 | pass |
| Full stack (compose + make test-full) | CI run 42362802353 | job green, AC4 `make test-full` 84 passed. **"Known failure F1" step: 3 failed** (step is `continue-on-error`) ([01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/01-ac4-f1-pr-run.png?raw=true))``` |
| `pytest -k rerank` (ticket verification) | local, **QA stub harness** | 3 passed, 1 skipped (real model not loadable). Sandbox has no torch/fastapi (PyPI blocked), so this ran under a QA numpy-backed `torch` stub. Real torch ran only in CI |
| `make lint` | CI | pass (Go/frontend only; no Python linter covers these files) |
| `make eval` | not run: needs the stack + Hugging Face; the change is meant to be ranking-neutral, and AC2 parity stands in for it | n/a |

CI checks: [00-ci-checks](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/00-ci-checks.png?raw=true````)

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: before/after stack timing | ❌ | **Before** (run [42344527109](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42344527109), `8fc1209`, `api.py` identical to `71cb609`): all 3 F1 requests > 10 s client read timeout; the old code has no timing line ([02](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/02-ac4-f1-baseline-run.png?raw=true)).````` **After** (run [42362802353](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42362802353)): no `rerank passages=` line exists in any stack output. Embedder container logs go into `stack-logs/compose.log` only in "Diagnostics" (`if: failure()`), which was **skipped** because F1 is `continue-on-error`. The artifact is 7,136 bytes, and the full job log has 0 matches ([04](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/04-ac1-no-embedder-timing-in-stack.png?raw=true)).`````` The only measured split is from CI's Python job (synthetic passages, not the stack): tokenize 5.4–6.0 ms, forward 4,621–4,890 ms per 20 pairs at threads=2, padded tokens 5,328–5,488 vs 10,240 single-batch ([03](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/03-ac2-real-model-parity.png?raw=true)).``````` No p50/max over M3 + seed requests. |
| AC2: scores within 1e-4, ranking identical | ⚠ partial | `test_rerank_real_cross_encoder_scores_match_single_batch` on the real `bge-reranker-base`: max_abs_diff 0.00e+00 / 5.36e-07 / 2.56e-09 for 3 queries × 20 passages, and the ranking assert passed ([03](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/03-ac2-real-model-parity.png?raw=true)).```````` It also passed in the stack's AC4 run. Shortfall: the passages are **synthetic**, not the fixture corpus (finding 4). |
| AC3: input order preserved, mutation shown | ✅ | Mocked tests pass in CI. QA mutation ([05](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/05-ac3-mutation-diff.png?raw=true))````````` dropped the `scores[i] = …` write-back. Unmodified copy: 3 passed ([06](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/06-ac3-tests-unmodified.png?raw=true)).`````````` Mutated: `test_rerank_score_pairs_keeps_input_order_after_length_sorting` and `test_rerank_endpoint_returns_scores_in_input_order` **FAIL** with "Mismatched elements: 20 / 20" ([07](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/07-ac3-tests-mutated.png?raw=true)).``````````` Caveat: this ran under QA's numpy `torch` stub; the logic under test is pure Python index bookkeeping, so the stub doesn't change what is being checked. |
| AC4: three F1 tests pass | ❌ | PR run: `FFF`, "3 failed in 30.59s", each `ReadTimeout … (read timeout=10)` ([01](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/01-ac4-f1-pr-run.png?raw=true)).```````````` Same as the baseline "3 failed in 30.55s" ([02](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/02-ac4-f1-baseline-run.png?raw=true)).````````````` Timeouts are untouched (good). |
| AC5: README env note | ❌ | `EMBEDDER_TORCH_THREADS` was added (`services/embedder/api.py:41-50`); README.md is not in the diff and has no `EMBEDDER_` row ([09](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/09-ac5-readme.png?raw=true)).`````````````` Deferred because of #21 (finding 5). |

## PRD fit
The change does not yet deliver the requirement. Product PRD §8 asks for `/v1/ask` p95 < 3 s, and the F1 requests still exceed 10 s on CI. It does respect the protected constraints: same tokenizer call, `max_length=512`, model, dtype, ADR-0010 pool of 20, no timeout changes, and a counts/timings-only log line. The ticket anticipated this outcome ("stop, paste the AC1 numbers, and hand them to pm-lead"). The stop condition has been reached, but the AC1 numbers were never produced.

QA arithmetic, **an estimate, not a measurement**: ~4.7 s of forward time for ~5.3k padded tokens at 2 threads. Fixture chunks are ~512 tokens each, so 20 pairs come to ~10k tokens with almost no padding to remove. That projects to roughly 9 s of forward time per `/v1/ask` on the same runner. Reaching < 3 s needs about a 3× cut, which only the ADR-gated options (pool, `max_length`, int8) plausibly give. Use the stack numbers from finding 2 once they exist.

## Findings
1. [blocking] **AC4 not met**: the three F1 tests still time out at 10 s (01), unchanged from baseline (02). Per the ticket this escalates to pm-lead for an ADR on the ranking-changing options. It does not count as a pass of AC4.
2. [blocking] **AC1 not met: the after-numbers don't exist.** The plan to grep `rerank passages=20` in `stack-logs/compose.log` can't work on a green job. `stack.yml` writes compose.log only in `Diagnostics` (`if: "failure()"`, lines 232-233), and the F1 step's `continue-on-error: true` (line 219) keeps `failure()` false (04). So no p50/max and no tokenize/forward split on fixture passages. It also stays unknown whether the warm-up ran, and what the container's thread count was. Fixing the capture needs a backend-owned `stack.yml` change (finding 6).
3. [nit] **CI cost/flakiness of the real-model parity test.** It loads `bge-reranker-base` (~1.1 GB) on every CI Python run. `ci.yml`'s HF cache key `hf-Linux-bge-base-en-v1.5` restores as an exact hit, so it never re-saves with the reranker inside ([08](```````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cd2ced2b19d21ac8d9558707fdf0a529e4dbebce/agents/reviews/AI-9/evidence/08-ci-cost-parity-test.png?raw=true)).``````````````` Cost: Python pytest 5.76 s → 59.86 s (job 73 s → 108 s), and stack AC4 8.66 s → 74.30 s. The test already runs in the stack, where the reranker is cached, so the ci.yml copy duplicates it. QA judgement: acceptable for this PR (the spec only required the *mocked* test to need no download, and AC2 allows a CI run). Before merge, either skip it in ci.yml and keep it in the stack, or have backend add the reranker to ci.yml's cache key. Also: `pytest.skip` on *any* load exception means an HF outage turns the only real-model guard into a silent green skip. Consider failing instead when `CI` is set.
4. [spec] AC2 says "on the fixture corpus"; the parity test uses synthetic passages. The property doesn't depend on the corpus, and the synthetic set has *more* padding difference than ~512-token fixture chunks. pm-lead decides whether this suffices.
5. [spec] AC5 conflicts with the WIP/independence rule while #21 (open, changes `README.md`) is unmerged. The AC was deferred without a spec change. pm-lead should amend it into an explicit follow-up, or sequence it after #21.
6. [spec] AC1's evidence source isn't produced by `stack.yml` on a green job. A backend follow-up is needed so AC1 can be met (e.g. always `docker compose logs embedder-api | grep -E 'rerank|torch threads'` after F1 and upload it). Alternatively, pm-lead accepts the Python-job numbers as the ADR input.

## Missing tests
- `load_models`: the warm-up failure path (startup must continue) and the early `return` when the cross-encoder fails to load.
- A single-passage request (the old code special-cased a scalar `probs`), plus `batch_size >= len(passages)` / an exact multiple of `batch_size`.
- `_torch_threads` fallback when `os.sched_getaffinity` is missing (minor).

## Scope
2 files, both owned by ai-engineer, and the ownership check is green. No ticket or review files leaked. +241/-9. Nothing "Not allowed" was touched. The `/internal/rerank` contract is unchanged.

## Hand-off
FAIL → per the ticket's AC4 clause this goes to **pm-lead**, not back to the build loop. More code within the allowed changes won't make F1 pass. pm-lead needs (a) AC1 stack numbers, via a backend `stack.yml` log-capture follow-up, and then (b) a Proposed ADR on the ranking-changing options. pm-lead also decides findings 4 and 5. The developer can address nit 3 and the missing tests in any rework.


---
_Generated by [Claude Code](https://claude.ai/code)_
