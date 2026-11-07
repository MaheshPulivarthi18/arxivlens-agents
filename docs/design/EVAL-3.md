# Tech design — EVAL-3: Run `make eval` on the full stack in GitHub Actions (manual + nightly)

**Author:** backend-engineer · **Ticket:** `agents/tasks/EVAL-3.md` · **PRD:** Product PRD §8 (all Quality/Latency rows), Technical PRD §9 (reference hardware, *Proposed*), §10; DoD 3 · **Status:** Draft

## Problem
`make eval` has never run against a real stack, so `evals/BASELINE.md` has no numbers. GitHub-hosted runners have
Docker, so a workflow can bring up the OPS-H1 stack, ingest the 31 IDs in `evals/corpus.txt` from arXiv, and run the gate.
That gives the first Recall@5 / MRR / NDCG@5, citation, refusal and latency numbers, and a repeatable way to check "doesn't regress".
Covers AC1–AC8. AC6 is a measurement reported in the PR, not code.

## Approach

### Files
| File | Change | Est. lines |
|---|---|---|
| `.github/workflows/eval.yml` (new) | Workflow below | ~140 |
| `Makefile` | `eval-seed` target (+ `.PHONY`, help text) | ~30 |
| `CONTRIBUTING.md` | Rows for `make eval-seed` and `eval.yml` (trigger, results, retention); remove the stale EVAL-1 text, now at lines 30, 44, 58 (the ticket's 28/42/54 moved when OPS-H1 merged) | ~15 |

There is no new query-service target. The workflow starts `./bin/arxivlens query` with `nohup` and waits for `/healthz`, as `stack.yml` does.
`scripts/`, `evals/`, `README.md`, thresholds and `stack.yml` are not touched.

### `make eval-seed`
- IDs come from `grep -oE '^[0-9]{4}\.[0-9]{4,5}' $(EVAL_CORPUS)` (default `evals/corpus.txt`), the same regex as
  `evals/README.md`. If 0 IDs are found, the target fails. The target POSTs to `$(ARXIVLENS_API_URL)/v1/papers/ingest`
  (default `http://localhost:8080`) with `curl -m 360`. That is longer than the server's 5 min `INGEST_TIMEOUT`, so a slow ingest shows the server's own error.
- **Politeness:** every two ingest requests are at least 3 s apart, retries included. The 3 s is hard-coded and is not a variable, so nobody can lower it.
- **Retry:** up to 3 attempts per ID, with backoff of 10 s and then 30 s. A retry happens on HTTP `000` (transport) or `5xx`. The server turns
  every ingest error into a 500, including arXiv 429/5xx (`arxiv returned status 429 …`). A `4xx` (bad ID) fails at once.
  An HTTP 200 counts as success only if the body has `chunks > 0` and `embeddings > 0` (parsed with `python3 -c`, no `jq` dependency).
- **Failure:** the target keeps going through the corpus and then exits 1 with `::error::eval-seed: N/31 failed: <id> (HTTP <code>: <body>) …`.
  It **never skips or deletes an ID**. If 2 IDs in a row use up all their retries, it stops early (arXiv is probably down or blocking the runner),
  lists the IDs it did not try, and exits 1, so we stop calling arXiv. One line per ID goes to `seed.log` (id, attempts, HTTP code, chunks, seconds).
- The eval gate already fails when corpus coverage is < 1.0, which is a second check.

### `eval.yml` (one job, `ubuntu-latest`, `timeout-minutes: 100`)
```
on: workflow_dispatch | schedule: '17 6 * * *' | pull_request: paths: ['.github/workflows/eval.yml']
permissions: contents: read                       concurrency: { group: eval, cancel-in-progress: false }
env: ARXIVLENS_HF_CACHE=/home/runner/.cache/huggingface, PIP_EXTRA_INDEX_URL=<cpu torch>
 1 checkout · setup-go (go.sum cache) · setup-python 3.11 (pip cache on requirements*.txt)
 2 actionlint 1.7.7 on eval.yml + `docker compose config --quiet`             (3 min)
 3 actions/cache/restore  key hf-${{runner.os}}-bge-base-en-v1.5-bge-reranker-base   (id: hf)
 4 make setup-py                                                                (10 min)
 5 pre-fetch BGE + bge-reranker-base on the host; HF_HUB_OFFLINE=1 when hf.cache-hit (10 min)
 6 actions/cache/save  if: hf.cache-hit != 'true'   (right after the prefetch, before any container writes) (5 min)
 7 make build-go · make stack-up · make migrate                                 (5 / 25 / 2 min)
 8 start query service on the host, wait for /healthz                           (2 min)
 9 self-test: `make eval-seed` with a 1-ID corpus against a closed port must exit non-zero (AC5 guard, no arXiv request) (2 min)
10 make eval-seed 2>&1 | tee seed.log; seed counts go to the step summary       (45 min)
11 machine profile → summary: lscpu model, nproc, free -g, github.sha, embedder /healthz `device`  (1 min)
12 make eval 2>&1 | tee eval.log; rc → summary; exit rc (no continue-on-error)    (30 min)
13 if: always()  upload-artifact eval-results-<run_id>: evals/results/*.json, eval.log, seed.log; retention-days: 30
14 if: failure() collect + upload eval-stack-logs (compose logs, ps, query.log): retention-days: 7
15 if: always()  kill query service; docker compose --profile workers down -v
```

**Exit codes and summary (Q4).** GNU make exits 2 whenever a recipe fails, which would hide the gate's 0/1/2. Step 12 reads the
gate's code from make's `*** [eval] Error N` line (0 if make exits 0). If make fails without that line, the code is 2.
The step exits with that code. The summary shows `### make eval: exit N (0 pass · 1 gate fail · 2 could not run)`, the `main` SHA, the machine
profile, and a code fence with the gate's printed table (from the first `====` line to `GATE:`). We use the printed table on purpose,
not a re-render of the JSON: the JSON schema belongs to ai-engineer, and metrics added later (EVAL-6) appear without changes here. On exit 2 there is
no results JSON, so the upload uses `if-no-files-found: warn` and the logs still upload.

### Runtime budget (Q1)
The budget assumes a 4 vCPU / 16 GB public-repo runner, CPU torch, and 34 retrieval + 44 `/v1/ask` cases with about 10 s CPU rerank per ask (the F1 figure).

| Phase | Cold | Warm |
|---|---|---|
| setup + actionlint + setup-py | 6 | 3 |
| model pre-fetch (~1.5 GB per the compose comment) | 2 | 0.3 |
| image build + `stack-up` (Docker layers not cached, see Alt 2) | 10 | 9 |
| seed: 31 × (≥ 3 s + 2 arXiv fetches + CPU chunk/embed ≈ 20–40 s) | 15–20 | 15–20 |
| `make eval`: retrieval ≈ 4, asks 44 × ~10 s ≈ 8 | 12–15 | 12–15 |
| upload + teardown | 2 | 2 |
| **total** | **≈ 50–55 min** | **≈ 42–48 min** |

Job `timeout-minutes: 100` gives about 1.8× headroom over the cold run. Every step also has its own timeout (listed above), so a hang
fails in the step that hangs and does not use up the whole job. Seeding can't be cached: every run starts from a clean DB and fetches from arXiv on purpose (determinism, see Alt 3).

### Caching (Q2)
- **HF models:** the host pre-fetch fills `~/.cache/huggingface`, which compose bind-mounts into all three Python containers through
  `ARXIVLENS_HF_CACHE` (the OPS-H1 mechanism). The cache key is the model names, and it is the **same key as `stack.yml`**, so either workflow warms the other.
  We use explicit `cache/restore` + `cache/save` because `actions/cache` saves only in a post step with `post-if: success()`.
  A nightly that is red only on latency (expected, Q7) would then never save the cache. Saving right after the pre-fetch also
  happens before the root-owned container writes, so no `chown` is needed for the save. On a hit, the pre-fetch runs with
  `HF_HUB_OFFLINE=1`, so a missing file fails loudly instead of being downloaded quietly. That run plus the
  `Cache restored from key: …` line is the AC4 evidence. Cache scope: the nightly runs on `main`, so its cache is visible to every branch.
  The landing PR's first run saves under the PR ref, and the second run (re-run) hits that cache.
- **pip / Go:** the built-in `setup-python` (`cache: pip`) and `setup-go` caches, the same as `stack.yml`/`ci.yml`.
- **Docker layers:** not cached in v1 (Alt 2).

### arXiv failures (Q3)
These are handled in `eval-seed` (retry, backoff, keep going, early stop, exit 1). The seed step fails the job and `make eval` does not run,
so a run with a missing paper never produces numbers. One run makes 62 arXiv requests (31 × Atom + PDF). The global concurrency group
means two runs never call arXiv at the same time.

### Security (Q5), concurrency (Q6), hardware (Q7)
- Q5: `permissions: contents: read`, no `secrets.*`, `pull_request` only (fork PRs get a read-only token), no `pull_request_target`.
  The paths filter means only edits to `eval.yml` run it on PRs.
- Q6: one global group `eval` with `cancel-in-progress: false`. Nightly and manual runs queue and never overlap. The global group is chosen over
  one group per ref because the shared resource is arXiv politeness, not the runner.
- Q7: the step summary records the runner profile. The gate step has no `continue-on-error` and nothing is edited in `evals/thresholds.json`.
  A nightly that is red only because of `/v1/ask` p95 ≥ 3 s is a finding for pm-lead (ADR-0010, Technical PRD §9).

## Alternatives considered
1. **Seeder as a Go subcommand (`arxivlens seed`) with httptest unit tests.** This is cleaner to test, but it adds ~200 lines of Go and tests,
   which puts the diff past the 400-line budget with the workflow. The shell target plus the step-9 self-test in CI covers AC5. It could become a follow-up if seeding grows.
2. **Cache Docker layers (buildx `type=gha` / `cache_from`).** This needs compose `build.cache_from`/`cache_to` changes that also affect
   `stack.yml` and local builds. It also competes with the ~1.5 GB HF cache for the 10 GB per-repo cache quota, and saves only ~5 min on a ~45 min nightly. Not worth it now.
3. **Cache the seeded Postgres/MinIO volumes** to skip arXiv. This saves ~15 min, but numbers would come from a stale index built
   by older chunking/embedding code, which defeats the purpose of a regression run. Rejected.
4. **Shared composite action with `stack.yml`.** This removes the duplicated stack bring-up, but it rewrites a workflow that just went green.
   It could be a follow-up harness task.
5. **Call `scripts/eval_gate.py` directly** to keep the 0/1/2 exit code. The ticket and DoD say `make eval`, so we parse make's `Error N` instead.

## Contracts and invariants
- Shared contracts: **none**. No HTTP API, event, schema, model or threshold change. The seeder only uses the existing `POST /v1/papers/ingest`.
- arXiv politeness: ≥ 3 s between ingests, hard-coded; at most 3 attempts per ID; early stop on an outage; no parallel runs.
  **Pre-existing gap (not changed here):** `PaperIngester.IngestPaper` makes the Atom request and the PDF request back to back
  (`export.arxiv.org` then `arxiv.org`), so inside one ingest two requests are < 3 s apart. I propose a backend follow-up ticket
  (a shared rate limiter in `internal/query/ingester.go`) and ask pm-lead to file it.
- Reliability layers (idempotency, DLQ, traceparent) are not touched. Workers run unchanged under `make stack-up`.

## Test plan
| Acceptance criterion | Test (name / type) | Runs in CI? |
|---|---|---|
| AC1 triggers | the `on:` block + GitHub path-filter docs; the run list of an unrelated open PR shows no `eval.yml` run; actionlint step | yes (actionlint), QA checks the run list |
| AC2 clean run | the landing PR's paths-filtered run: stack-up, migrate, `/healthz`, seed 31/31, `make eval` finishes (exit 0 or 1) | yes |
| AC3 artifact + summary | `eval-results-<run_id>` present on the green or gate-red run; `gh run download`; summary shows table + exit code. A fail-path upload is shown by step 13's `if: always()` on a red gate run | yes |
| AC4 warm cache | re-run of the PR workflow: `Cache restored from key: hf-Linux-…`, pre-fetch passes with `HF_HUB_OFFLINE=1`, cache-save step skipped; cold and warm durations in the PR | yes |
| AC5 seed fails | step 9 self-test (closed port → non-zero, 3 attempts logged, no skip); a local dry run `make eval-seed EVAL_CORPUS=<tmp: 0000.00000> ARXIVLENS_API_URL=http://127.0.0.1:9` → exit 1; QA can also point it at `python3 -m http.server` (POST → 501 → fails without retry) | yes + local |
| AC6 numbers | copied from the AC2 run's summary + JSON into the PR description, with runner profile and `main` SHA; "no prior baseline; first measurement with RET-1 (`RerankPool = 20`) live" | n/a (report) |
| AC7 CONTRIBUTING | diff review; `grep -n "once EVAL-1" CONTRIBUTING.md` prints nothing | no |
| AC8 size | `wc -l .github/workflows/eval.yml` < 150; ownership-check output with changed-line total < 400 | yes (ownership check) |

Also: `make lint` and `make test-unit` (unchanged code, still green), and `stack.yml` runs on this PR because `Makefile` changes, so it also confirms the shared stack still works.
Failure paths covered: arXiv 429/5xx (retry → exit 1), bad ID (no retry → exit 1), arXiv outage (early stop), 200 with 0 chunks
(fail), eval could not run (exit 2 reported and job red), gate fail (exit 1, artifact still uploaded), stack unhealthy (compose logs artifact).

## Risks and rollout
- **arXiv throttles or blocks GitHub runner IPs.** This shows up as seed failures with the arXiv status in `seed.log`/summary. No skip is added. If it keeps
  happening, pm-lead decides (for example a follow-up to cache corpus PDFs keyed on `corpus.txt`).
- **A large paper takes longer than the 5 min `INGEST_TIMEOUT` on CPU.** The server error is visible; the fix is a follow-up `INGEST_TIMEOUT` env in the workflow, not a skip.
- **The nightly is red on latency** (expected on CPU). This is reported, not hidden. The `pull_request` check is not required, so a red gate doesn't block the merge (AC6).
- GitHub disables scheduled workflows in public repos after 60 days without activity. This goes in CONTRIBUTING.
- Rollback: `gh workflow disable eval.yml` or revert the PR. Nothing else depends on it.

## PM decision
**APPROVED with conditions** (pm-lead, 2026-11-07, reviewed at design commit `d33b8ef` against `agents/tasks/EVAL-3.md`,
Product PRD §8, Technical PRD §9 "External politeness"; app `origin/main` `71cb609`).

Why: all seven "Design must answer" items are answered with numbers, and each AC maps to a step. It fails closed where it
should: no skip or delete of corpus IDs, no `continue-on-error` on the gate, no threshold edits, exit 2 shown as "could not
run". Two choices are especially good. Explicit `cache/restore` + `cache/save` means a latency-red nightly still warms the cache,
and the cache key matches `stack.yml:63`. Rejecting cached DB volumes (Alt 3) keeps the run a real regression check. The shell
seeder plus the CI self-test (step 9) is enough for AC5 at this size (Alt 1). No shared contract is touched, and the diff (~185
lines, workflow ~140) fits AC8.

### Conditions (binding; QA checks each)
1. **Don't lose exit codes through `| tee`.** Steps 10 and 12 pipe into `tee`. A `run:` step with no `shell:` runs as `bash -e {0}`,
   **without** `pipefail`, so `make eval-seed … | tee` would report tee's 0 and step 12 would read the wrong code. Use the
   `stack.yml` pattern (`set +e`, `rc=${PIPESTATUS[0]}`, then `exit "$rc"`, as at `stack.yml:206-214`) in both steps. QA checks
   that the AC5 self-test and a failed seed really turn the step red.
2. **One writer per log file.** The design has `eval-seed` write one line per ID to `seed.log` while step 10 also tees the target's
   output into `seed.log`, so one overwrites the other. Give them different names (for example the target writes `seed-ids.tsv`,
   the step tees to `seed.log`) and upload both.
3. **AC6 rule stands as written.** On CPU runners `/v1/ask` takes about 10 s (F1). That's under the eval's 30 s `--timeout`, so asks
   should complete. If they don't (timeouts counted as `ask_errors`, gate exit 1), that's a finding to paste, not a reason to raise
   `--timeout`, change `RerankPool` or edit the gate step.
4. **Record the `main` SHA and say where AI-7 / EVAL-6 stood** (merged or not) in the PR's AC6 numbers, as the ticket's Notes ask.
   The step summary already carries `github.sha`.

### Decision on the developer's question (ingester politeness)
**Agreed, and filed as [ING-9](../../agents/tasks/ING-9.md)** (backend-engineer, P1, Ready, *not in this plan*; board
"Ready — not in this plan"). It covers the query-side ingester (Atom then PDF back to back; no User-Agent on Atom, a
non-identifying one on the PDF) and the Go downloader (no wait between PDFs). It doesn't block EVAL-3. The seeder's ≥ 3 s gap
between ingests holds, and each ingest makes 2 requests to two different arXiv hosts. That's 62 requests per nightly, a known
gap that ING-9 closes. **Don't fold any `internal/query/ingester.go` change into this PR** (out of EVAL-3's scope). If arXiv
starts returning 429/403 to the runner (seen in `seed.log`), stop and report it; pm-lead then moves ING-9 ahead.

## Build deviations (backend-engineer, recorded by orchestrator 2026-11-07)
1. Test plan correction: `python3 -m http.server` answers POST with 501 (a 5xx), so under this design's retry rule it is retried 3 times and then fails; it does not "fail without retry".
2. The eval step maps any make exit code other than 0/1/2 to 2 ("could not run").
