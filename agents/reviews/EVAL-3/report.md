<!-- Provenance: written by qa-reviewer (fresh context, 2026-11-07 cycle 05:21Z); its harness could not write files, so the orchestrator saved the report text verbatim from qa-reviewer's hand-back. Evidence files were rendered by qa-reviewer with agents/tools/render_evidence.py. -->

# QA report — EVAL-3 · PR #22 · round 1

**Verdict:** PENDING (AC4 needs a second, warm-cache Eval run, which hasn't happened yet. Everything else is verified and there are no blocking findings.)
**Reviewed commit:** `8fc120916e03475bdea01c870d294e32e724496c` (PR merge ref in CI: `c2ed79a`; base `main` `71cb609`) · **Date:** 2026-11-07
**Ticket:** `agents/tasks/EVAL-3.md` · **Design:** `docs/design/EVAL-3.md` (APPROVED with conditions) · **PRD:** Product PRD §8 (Quality + Latency rows), Technical PRD §9/§10, DoD 3; ADR-0006 (paper-level Recall@5); `evals/thresholds.json` (unchanged)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 128319267398 | pass |
| Python M0 unit tests | CI job 128319267671 | pass |
| Frontend (lint, test, build) | CI job 128319267580 | pass |
| Agent ownership check | CI job 128319267785 | pass: `Ownership OK for role=backend (198 changed lines)` |
| DB (migrate twice, HNSW) | CI job 128319267889 | pass |
| Full stack (compose + make test-full) | CI job 128319267783 | pass (runs because `Makefile` changed, so the shared stack still works) |
| **Eval** (this PR's `eval.yml`, run [42344527129](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42344527129)) | CI job 128319267738 | **completed with gate exit 1** (gate FAIL on 2 metrics, not exit 2). 49 min 57 s total |
| `make eval-seed` dry run (closed port, fake API: 400, 200/0 chunks, 500→200, 2× exhausted → early stop, empty corpus, all ok) | local, PR head | matches the design. Min gap between requests 3.015 s |
| `eval`/`eval-seed` step bodies extracted from `eval.yml` run under `bash -e` (PIPESTATUS) | local, PR head | exit codes kept through `tee` (0/1/2, 127→2, 3→2; seed failure → red) |
| `make lint`, `make test-unit` | not run locally: Go 1.25 toolchain download blocked (`proxy.golang.org` unreachable). CI is green | — |
| actionlint | CI (step 5 of the Eval run, actionlint 1.7.7) | pass. Not run locally: no actionlint binary and no Docker daemon |
| Artifact contents (`gh run download`) | not run: the artifact blob host (`*.blob.core.windows.net`) returns 403 to the sandbox. Upload log + artifacts API used instead | — |
| `make eval` before → after | no prior baseline. This is the first measurement (numbers below) | — |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 triggers | ✅ | `eval.yml:4-10`: `workflow_dispatch`, one cron `17 6 * * *`, `pull_request.paths: [.github/workflows/eval.yml]`. No `pull_request_target`, `permissions: contents: read`, global `concurrency: eval`, no cancel. Open PRs #20/#21/#23 (none touch `eval.yml`) have no Eval run, and #22 does. Caveat: those PRs branch from a `main` without `eval.yml`, so their run lists are weak evidence on their own. The `on:` block plus GitHub's paths-filter semantics is what proves the AC. → `evidence/01-ac1-triggers.png` |
| AC2 clean run | ✅ (run) / ⚠ (PR link) | Run 42344527129 on a fresh `ubuntu-latest` runner: `make stack-up` (all containers Healthy), `migrate` (2 files), query `/healthz` `{"status":"ok"}`, self-test OK, **seed 31/31, every ID on its first attempt**, `make eval` completed (gate exit 1). → `evidence/02-ac2-eval-run.png`. **The PR description doesn't contain the run link yet** (finding 3) |
| AC3 artifact + summary | ✅ (artifact) / ⚠ (summary page) | On the gate-red run, `eval-results-42344527129` (5 files: results JSON + `eval.log`, `seed.log`, `seed-ids.log`, `query.log`) uploaded with `retention-days: 30` (expires 2026-12-07), plus `eval-stack-logs-…` (7 d, expires 2026-11-14) because the job failed. → `evidence/04-ac3-ac4-artifacts-cache.png`. The step-summary writes are in the log, and the exact summary code was run locally against fake gate exits (`### make eval: exit N (0 pass · 1 gate fail · 2 could not run)` plus the table) → `evidence/03-cond1-pipestatus-exit-codes.png`. **I couldn't open the rendered summary page** (github.com UI path blocked). The pm-lead should eyeball it on the run page. The pass-path upload is covered by `if: always()` but hasn't been seen on a green run |
| AC4 warm cache | ⚠ **unverified: no second run** | Cold run: `Cache not found for input keys: hf-Linux-bge-base-en-v1.5-bge-reranker-base`, `cache-hit=false HF_HUB_OFFLINE=0`, `Cache saved with key: hf-Linux-…` (step 9, before stack-up). So a re-run should hit. **Needs** a re-run of run 42344527129 (or a `workflow_dispatch` once merged) showing `Cache restored from key: hf-Linux-…`, `cache-hit=true HF_HUB_OFFLINE=1`, step 9 skipped, plus both runtimes in the PR. Cold runtime: 49 min 57 s. → `evidence/04-ac3-ac4-artifacts-cache.png` |
| AC5 seed fails on any failed ID | ✅ | CI self-test (step 12): `0000.00000` vs closed port, 3 attempts, `HTTP 000`, `OK: eval-seed exited 2 after 3 attempts`. Local dry run: 400 → fail without retry; 200 with 0 chunks → fail; 500→200 → ok on attempt 2; two IDs that use up their retries in a row → early stop listing the untried IDs, exit non-zero; empty corpus → exit non-zero; all ok → exit 0. **No ID is ever skipped or deleted** (failures are listed and still counted). Same regex as `evals/README.md:73`. Request gap ≥ 3.015 s. → `evidence/05-ac5-eval-seed-dry-run.png`, `02-ac2-eval-run.png` |
| AC6 numbers | ✅ measured / ⚠ not in PR description | See "Measured numbers" below. The workflow's gate step has no `continue-on-error`, `thresholds.json` and `RerankPool` are untouched, and the run completed (exit 1, not 2), so per AC6 the red gate does not block merging. **The PR description doesn't report the numbers, machine profile, main SHA or AI-7/EVAL-6 status yet** (finding 3). → `evidence/06-ac6-eval-numbers.png`, `02-ac2-eval-run.png` |
| AC7 CONTRIBUTING | ✅ | Rows for `make eval-seed`, `make eval` (0/1/2 exit codes, results path) and `eval.yml` (nightly 06:17 UTC, `gh workflow run eval.yml` / Actions UI, step summary, `eval-results-<run id>` 30 d, `eval-stack-logs-<run id>` 7 d, 60-day schedule pause). No "once EVAL-1" / "added by EVAL-1" left. → `evidence/07-ac7-ac8-size-contributing.png` |
| AC8 size | ✅ | `eval.yml` is 149 lines (< 150). Diff: 3 files, +194/−4; the CI ownership check counts 198 changed lines (< 400). → `evidence/07-ac7-ac8-size-contributing.png` |

### PM design conditions
1. **PIPESTATUS through `tee`:** ✅ Both steps use `set +e` + `rc=${PIPESTATUS[0]}` + `exit "$rc"` (`eval.yml:91-94`, `112-118`). Locally, the extracted bodies under `bash -e` give step exit = gate exit (0/1/2), non-0/1/2 → 2, and a failed seed turns the step red (2). In CI, the gate's exit 1 gave a red step (`Process completed with exit code 1`), and the self-test proved the seeder fails. → `evidence/03`
2. **Separate seed logs:** ✅ The target writes `seed-ids.log` (TSV) and the step tees to `seed.log`. Both are in the 5-file artifact.
3. **Don't tune timeouts / AC6 rule:** ✅ `--timeout`, thresholds, `RerankPool` and the gate step are unchanged. `ask_errors = 0`, so all asks finished inside the 30 s eval timeout.
4. **main SHA + AI-7/EVAL-6 status:** ⚠ The step summary/log record `github.sha c2ed79a` (PR merge ref) and `main (base) SHA 71cb609`. AI-7 (#21) and EVAL-6 (#20) are both **open, not merged**, so these numbers are from before both. This still has to go into the PR description (finding 3).

## Measured numbers (run 42344527129, AC6)
No prior baseline; first measurement with RET-1 (`RerankPool = 20`) live. Code = `main` `71cb609` + this PR (merge `c2ed79a`). **AI-7 and EVAL-6 not merged.**
Machine: GitHub `ubuntu-latest`, AMD EPYC 9V45 96-Core Processor, 4 vCPU, 15 GiB RAM, embedder `/healthz` `{"status":"ok","device":"cpu","reranker":true}`.

| Mode | Recall@5 | MRR | NDCG@5 | ChunkP@5 | Avg ms |
|---|---|---|---|---|---|
| BM25 | 0.1471 | 0.1324 | 0.1362 | 0.1294 | 1.11 |
| Dense | 0.9216 | 0.9412 | 0.9256 | 0.9118 | 0.84 |
| Hybrid RRF | 0.9804 | 0.9706 | 0.9627 | 0.9588 | 3.59 |
| **Hybrid RRF + Rerank (gated)** | **0.9804** | **0.9853** | **0.9735** | 0.9765 | 9964.47 |

| Gate | Value | Target | Result |
|---|---|---|---|
| rerank via production `/internal/rerank` | 1.0 | == 1.0 | PASS |
| retrieval_coverage | 1.0 | == 1.0 | PASS |
| recall@5 (Hybrid RRF + Rerank) | 0.9804 | ≥ 0.8 | PASS |
| hybrid+rerank beats BM25 & dense | 1.0 | == 1.0 | PASS |
| supported_citation_rate | 0.9032 (31 citations) | ≥ 0.9 | PASS |
| **correct_refusal_rate** | **0.9091 (of 22)** | ≥ 0.95 | **FAIL** |
| **ask_p95_ms** | **12 786.6** (p50 10 685.1) | < 3000 | **FAIL** |
| ask_errors | 0 | == 0 | PASS |
| (info) expected_paper_hit_rate | 0.7727 (of 22) | — | — |
| (info) in-corpus refused | 18.18% | — | — |

`/v1/search` p95: n/a (EVAL-2 is Blocked on ADR-0012, not merged). Runtimes: whole job 49 m 57 s cold; stack-up 3 m 07 s; seed 30 m 24 s (design estimate 15–20); `make eval` 13 m 50 s. Slowest single ingests (from log timestamps, including the 3 s politeness sleep): 2005.14165 ≈ 157 s (174 chunks), 2103.00020 ≈ 136 s.

## PRD fit
This delivers the PRD §8 "Measured by `make eval`" column for real for the first time: the gate runs end-to-end on a clean CPU runner with a fully seeded corpus, keeps the 0/1/2 semantics, and fails closed (no skip, no `continue-on-error`, thresholds untouched). The first numbers show Recall@5/MRR/NDCG@5 and citations meet v1 targets, while refusal rate and `/v1/ask` p95 don't. Those are product findings for pm-lead/Mahesh (ADR-0010, Technical PRD §9), not defects in this workflow.

## Findings
1. [nit] The seed step's summary heading and the self-test message report **make's** exit code, not the target's (`### make eval-seed: exit 2`, `OK: eval-seed exited 2 after 3 attempts`), even though the target exits 1. That's harmless (non-zero is what matters), but it reads like "could not run" next to the eval step's 0/1/2 legend.
2. [nit] On `workflow_dispatch` from a branch, `BASE_SHA` falls back to `github.sha`, and the summary labels it "main (base) SHA". That's wrong for branch dispatches, which is exactly the DoD-3 use pm-lead plans after merge. Something like `git rev-parse origin/main` would be accurate.
3. [spec] **PR #22's description is missing AC2/AC4/AC6 content:** the run link, cold and warm runtimes, the metric numbers, machine profile, main SHA `71cb609`, "AI-7/EVAL-6 not merged", and "no prior baseline; first measurement with RET-1 (`RerankPool = 20`) live". The numbers are all in this report. Per the workflow, pm-lead writes the evidence into the PR description at stage 4, so this is a hand-off item, not developer rework. AC2/AC6 aren't fully ticked until it's done.
4. [spec] **For pm-lead → Mahesh (AC6 rule, no action in this PR):** (a) `/v1/ask` p95 = 12.8 s on 4-vCPU CPU (gate 3 s), per-ask rerank ≈ 10 s, which matches F1. That goes to ADR-0010 / Technical PRD §9. (b) `correct_refusal_rate` = 0.909 < 0.95, measured *before* AI-7 (ADR-0003 refusals) merged. Re-measure after AI-7. (c) Single-paper ingest on this runner is mostly 30–80 s, with outliers of about 157 s. The PRD §8 "< 60 s" row isn't automated, but this is the first data point.
5. [spec] Runtime risk, informational: seed took 30.4 min against the design's 15–20 min estimate and the step's 45 min `timeout-minutes` (68% of the budget). The whole job took 50 min of its 100. If the corpus grows or arXiv slows down, the seed step will time out before the job does. Per condition 3 nothing is tuned here. If it bites, it's a follow-up decision.
6. [spec] The Eval check run on this PR is red (gate exit 1). That's expected and allowed by AC6, but it will show as a failing check on the PR. pm-lead should say so in the PR description so Mahesh doesn't read it as a broken workflow.

## Missing tests
- Only the closed-port path of `eval-seed` runs in CI. 4xx, 200 with 0 chunks, 5xx→retry→ok and early stop are verified only by my local dry run (evidence 05). The design accepted this (Alt 1), so it's not blocking.
- The `make eval` exit-2 path ("could not run": no results JSON, `if-no-files-found: warn`, tail of `eval.log` in the summary) hasn't been seen in CI. It was checked locally with fake gate exits only.
- AC4 warm-cache path (`HF_HUB_OFFLINE=1`, save step skipped) hasn't run yet.

## Hand-off
PENDING → re-review next cycle once a second Eval run exists (re-run attempt 2 of run 42344527129, or a `workflow_dispatch` on `agent/backend/EVAL-3` after merge). The re-review then only needs AC4 (cache-hit log lines, offline pre-fetch, save skipped, warm runtime). If AC4 holds and nothing else changes, the expected verdict is PASS, with findings 3–6 handed to pm-lead.

## Evidence
| File | Shows |
|---|---|
| `evidence/00-ci-checks.png` | All check runs for `8fc1209`: 6 green, Eval red (gate exit 1) |
| `evidence/01-ac1-triggers.png` | `on:` block; per-PR run lists |
| `evidence/02-ac2-eval-run.png` | Eval job steps + timings; stack healthy, migrate, `/healthz`, self-test, 31/31 seeded, machine profile |
| `evidence/03-cond1-pipestatus-exit-codes.png` | Step bodies from `eval.yml` under `bash -e`: exit codes through `tee`; summary heading |
| `evidence/04-ac3-ac4-artifacts-cache.png` | Artifacts + retention on a gate-red run; cold HF cache miss → save |
| `evidence/05-ac5-eval-seed-dry-run.png` | `make eval-seed` failure matrix and request gaps |
| `evidence/06-ac6-eval-numbers.png` | Full `make eval` output from the CI log |
| `evidence/07-ac7-ac8-size-contributing.png` | Line counts, ownership check output, CONTRIBUTING rows |

---

# QA report — EVAL-3 · PR #22 · round 1 (continued)

<!-- Written by qa-reviewer (fresh context, 2026-11-07 cycle, after Eval run 42344527129 attempt 2). Evidence 08-10 rendered with agents/tools/render_evidence.py from real gh api output and the downloaded job log. -->

**Verdict:** PASS
**Reviewed commit:** `8fc120916e03475bdea01c870d294e32e724496c` (same as the PENDING report; no new commits) · **Date:** 2026-11-07
**What changed since PENDING:** Eval run [42344527129](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42344527129) was re-run (attempt 2, job 128331784672, 06:48:58Z to 07:49:22Z, conclusion failure because the gate exited 1, as in attempt 1). This round only re-checks AC4 and the CI checks. AC1-AC3 and AC5-AC8 are unchanged from round 1.

## Test results (delta)
| Check | Source | Result |
|---|---|---|
| CI check runs for `8fc1209` | `commits/<sha>/check-runs` | 6 green (Go, Python M0, Frontend, Ownership, DB, Full stack). `eval` now points at attempt-2 job 128331784672: failure = gate exit 1 (allowed by AC6). → `evidence/08-ci-checks-attempt2.png` |
| Eval attempt 2 (warm) | job 128331784672 log | `Cache hit for: hf-Linux-bge-base-en-v1.5-bge-reranker-base`, `Cache Size: ~1205 MB`, `Cache restored from key: hf-Linux-bge-base-en-v1.5-bge-reranker-base`. Pre-fetch printed `cache-hit=true HF_HUB_OFFLINE=1` and loaded both models offline (199/201 weights) in 7 s. Step 9 "Save Hugging Face models" was **skipped**. No `huggingface.co` / `model.safetensors` / `pytorch_model` / `snapshot_download` line anywhere in the log (count 0). Seed 31/31 on first attempts, `make eval` completed, `GATE: FAIL`, `Process completed with exit code 1`. → `evidence/09-ac4-cold-vs-warm-steps.png`, `evidence/10-ac4-warm-cache-log.png` |
| Artifacts after attempt 2 | `runs/42344527129/artifacts` | `eval-results-42344527129` (expires 2026-12-07, 30 d) and `eval-stack-logs-42344527129` (expires 2026-11-14, 7 d), re-uploaded by attempt 2. AC3 holds on a second gate-red run |
| `make lint`, `make test-unit` | not run locally: Go 1.25 toolchain download blocked in the sandbox. CI green | — |

## Acceptance criteria (delta)
| AC | Met? | Evidence |
|---|---|---|
| AC4 warm cache | ✅ (log) / ⚠ (PR text) | Warm run restores the model cache from the exact key the cold run saved, runs the pre-fetch with `HF_HUB_OFFLINE=1` (it would fail rather than download a missing file), skips the save step, and has no model download line. Runtimes: **cold 49 m 57 s** (attempt 1, job 05:52:18Z to 06:42:15Z), **warm 60 m 24 s** (attempt 2, job 06:48:58Z to 07:49:22Z). The model steps themselves (restore + pre-fetch + save) took 64 s cold and 69 s warm. The warm run was slower overall because of seeding (37 m 48 s vs 30 m 24 s, arXiv fetch + CPU embedding) and `make eval` (16 m 07 s vs 13 m 50 s), not the models. Both runtimes still have to go into the PR description (finding 3, pm-lead stage 4). → `evidence/09`, `evidence/10` |
| AC1-AC3, AC5-AC8 | ✅ unchanged | Round 1 above. No new commits, so the round-1 evidence still applies |

### Second measurement (attempt 2, same code, informational for AC6 / finding 4)
Retrieval numbers are identical to attempt 1 (Recall@5 0.9804, MRR 0.9853, NDCG@5 0.9735 gated; BM25/Dense/RRF unchanged), as expected for a deterministic retrieval path over the same corpus. supported_citation_rate 0.9032 PASS, correct_refusal_rate 0.9091 FAIL (same), ask_errors 0. **`/v1/ask` p50/p95 = 12 178 / 14 922 ms** (attempt 1: 10 685 / 12 787 ms). Rerank avg 11 796 ms/query (attempt 1: 9 964). So latency on the 4-vCPU CPU runner varies by about 15-20 % between runs and stays 4-5x above the 3 s gate.

## Findings (round 1 continued)
Round-1 findings 1-6 stand (1-2 nits, 3-6 [spec] hand-offs to pm-lead). No blocking findings. Updates:
3. [spec] (update) The PR description also needs the warm runtime (60 m 24 s) next to the cold one (49 m 57 s), plus the attempt-2 link (run 42344527129, attempt 2). It should say plainly that the model cache works (no model download) but doesn't shorten the job, because the HF download was already quick (about 20 s on a cold run).
5. [spec] (escalated, still not blocking) Seeding took **37 m 48 s** on the warm run, which is 84 % of the step's 45-min `timeout-minutes` (round 1: 30 m 24 s, 68 %). The whole job took 60 of its 100 min. Seed time is now the main risk to the nightly run, and the cache can't help with it. Per design condition 3 nothing is tuned in this PR. pm-lead should open a follow-up (e.g. raise the seed step budget, or cache the ingested DB/MinIO state per corpus hash) before the nightly turns flaky.
7. [nit] A cache restore of ~1205 MB took 12 s, while a cold download plus save took about 27 s. The cache is worth keeping because it removes the dependency on Hugging Face availability (an offline failure is loud), not because it saves time. Optional: say so in CONTRIBUTING.

## Missing tests (unchanged)
The exit-2 path and the non-closed-port seed failure paths are still verified only locally (round 1). AC4's warm path has now been seen in CI.

## Hand-off
PASS → pm-lead final review. pm-lead must write into the PR description: the run link (both attempts), cold/warm runtimes, the AC6 numbers + machine profile + main SHA `71cb609` + "AI-7/EVAL-6 not merged" + "no prior baseline; first measurement with RET-1 (`RerankPool = 20`) live", and a note that the red Eval check is an expected gate fail (exit 1), not a broken workflow. Then record findings 4/5 for Mahesh (ADR-0010, Technical PRD §9).

## Evidence (added this round)
| File | Shows |
|---|---|
| `evidence/08-ci-checks-attempt2.png` | Check runs for `8fc1209` with the Eval check on attempt-2 job 128331784672 |
| `evidence/09-ac4-cold-vs-warm-steps.png` | Step conclusions + timings for attempts 1 and 2: step 9 save success (cold) vs skipped (warm), job runtimes |
| `evidence/10-ac4-warm-cache-log.png` | Warm job log: cache hit/restore lines, `cache-hit=true HF_HUB_OFFLINE=1`, offline weight loads, 0 model-hub download lines, 31/31 seeded, gate exit 1 |
