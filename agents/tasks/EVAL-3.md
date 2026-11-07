# EVAL-3: Run `make eval` on the full stack in GitHub Actions (manual + nightly) and record the first measured numbers

| | |
|---|---|
| **Owner** | backend-engineer (workflow, Makefile, CI docs). **ai-engineer pairing:** reviews the design for how `scripts/eval_gate.py` is invoked and how results are read; ai owns any `scripts/`/`evals/` change (see EVAL-4). |
| **Priority** | P1 (first real quality numbers; unblocks every "`make eval` doesn't regress" DoD item) |
| **PRD ref** | Product PRD §8 (every Quality/Latency row is measured by `make eval`; none has a number yet); Technical PRD §9 (reference hardware, *Proposed*), §10; DoD 3 |
| **Depends on** | OPS-H1 (merged `71cb609`: compose stack with workers + embedder API, `make stack-up`). Carries RET-1 AC6 (moved here from EVAL-2 AC10). |
| **Jira** | not created yet (orchestrator: story under epic "Retrieval & answer quality gates", labels `task-EVAL-3`, `agent-backend`, `design-required`, `arxivlens`) |
| **Design required** | **yes**: new CI workflow with real runtime/cost (nightly full stack, ~440 MB embedder + cross-encoder downloads, arXiv fetches for 31 papers). The design must fix caching, timeouts and politeness before any YAML is written. |
| **Status** | Ready (Wave 1, 2026-11-07 plan). Next stage: Design (`docs/design/EVAL-3.md`) |

## Goal
`evals/BASELINE.md` still says "not run: infra unavailable". No agent sandbox can bring up the stack, but GitHub-hosted
runners have Docker. A workflow that brings up the stack, ingests `evals/corpus.txt`, and runs `make eval` gives the team
its first measured Recall@5, MRR/NDCG@5, supported-citation rate, refusal rate and `/v1/ask` p95. It also gives a
repeatable way to check "doesn't regress".

## Scope
- New `.github/workflows/eval.yml`. Triggers: `workflow_dispatch`, `schedule` (nightly, one cron), and `pull_request`
  **only** with `paths: ['.github/workflows/eval.yml']`. That way the landing PR gets a real run, and no other PR runs the eval
  (`workflow_dispatch` only works once the file is on `main`).
- `Makefile`: a target that seeds the eval corpus (e.g. `eval-seed`). It reads `evals/corpus.txt` with the same ID regex
  as `evals/README.md` "Seeding the corpus", calls `POST /v1/papers/ingest` per ID with ≥ 3 s between calls (Technical
  PRD §9 politeness), and **exits non-zero if any ingest fails**. Plus, if needed, a target that starts the Go query
  service in the background and waits for `/healthz`.
- `CONTRIBUTING.md`: commands table rows for the new targets and the workflow (how to trigger it, where results go, how
  long the artifacts are kept). Fix the stale "once EVAL-1 lands" wording at `CONTRIBUTING.md:28,42,54` in the same edit
  (board Backlog nit). App `README.md` is **not** touched here (2026-11-07: AI-7 edits it in parallel); the README Testing line moved to EVAL-4.
- Out of scope: any change to `scripts/`, `evals/` (ai-owned; `evals/BASELINE.md` and `evals/README.md` go in EVAL-4),
  thresholds, the Recall@5 definition, `RerankPool`, or running the eval on every PR.

## Design must answer (in `docs/design/EVAL-3.md`)
1. Runtime budget and `timeout-minutes` (estimate cold vs warm cache). Ingest is ≥ 31 × 3 s plus CPU embedding; give a number.
2. Model caching: how the Hugging Face cache used by the embedder containers (OPS-H1's volume) is restored/saved with
   `actions/cache` (key on model names), so a warm run downloads nothing. Also pip/Go caches.
3. arXiv failures: retry/backoff for a 429/5xx during seeding, and what the job reports if a corpus paper can't be ingested.
   The eval gate already fails when coverage < 1.0. Don't add a skip.
4. Result handling: `evals/results/` uploaded with `if: always()` and an explicit `retention-days`. Compose logs are uploaded on
   failure. The metric table and `make eval` exit code (0 pass / 1 gate fail / 2 could not run) go into `$GITHUB_STEP_SUMMARY`.
5. Security: `permissions: contents: read`, no secrets (no LLM yet), and no `pull_request_target`.
6. `concurrency` so two nightly/manual runs don't overlap.
7. Hardware: a GitHub `ubuntu-latest` runner is the CPU-only profile in Technical PRD §9 (*Proposed*). Until Mahesh decides
   that rule, latency gates apply unchanged, so a red nightly caused only by latency is expected and is a finding, not
   something to work around (no `continue-on-error` on the gate step, no threshold edits).

## Acceptance criteria
- [ ] AC1: `eval.yml` triggers exactly as in Scope: a normal PR that doesn't touch the file does not start it (QA shows the
  run list of an unrelated PR, or the `on:` block plus GitHub's path-filter docs).
- [ ] AC2: One run, from a clean runner: compose stack up (OPS-H1 target), `migrate`, query service healthy, corpus
  seeded, `make eval` runs to completion. The run link is in the PR.
- [ ] AC3: `evals/results/*.json` is uploaded as an artifact on pass **and** fail, with the retention you chose. The step
  summary shows the metric table and the exit code.
- [ ] AC4: A second run with a warm cache shows a cache hit for the model cache and doesn't download the models (log line in evidence). Both runtimes are given in the PR.
- [ ] AC5: The seeding target fails the job if any corpus ID fails to ingest. QA shows this with a bogus ID in a scratch
  run, or a unit-style dry run of the target. It never deletes or skips corpus IDs.
- [ ] AC6 (RET-1 AC6 / formerly EVAL-2 AC10): The PR description reports, from the AC2 run, Recall@5 / MRR / NDCG@5
  (gated mode and baselines), supported-citation rate, correct-refusal rate, `/v1/ask` p50/p95, and `/v1/search` p95 if EVAL-2
  AC2 has merged, together with the runner's machine profile (CPU model, cores, RAM, torch device). The pre-RET-1 baseline was
  never measured, so say "no prior baseline; first measurement with RET-1 (`RerankPool = 20`) live". **If `/v1/ask` p95 ≥ 3 s
  or any gate fails: don't touch `RerankPool`, `RRF_POOL_SIZE`, thresholds or the workflow's gate step. Paste the numbers and
  hand them to pm-lead, who records them for Mahesh in ADR-0010 (pool decision) and Technical PRD §9 (hardware rule).** A red gate
  does not block merging the workflow; a run that didn't complete (exit 2) does.
- [ ] AC7: `CONTRIBUTING.md` as in Scope (how to trigger the workflow, where results go, artifact retention). The stale EVAL-1 wording is gone.
- [ ] AC8: The workflow is < 150 lines, and the total diff is < 400 changed lines (ownership check output).

## Verification
```bash
make lint
make test-unit
actionlint .github/workflows/eval.yml        # or: docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint
gh workflow run eval.yml --ref agent/backend/EVAL-3   # after merge; before merge the paths-filtered PR run is the evidence
gh run list --workflow eval.yml --limit 5
gh run download <run-id> -n <artifact-name>   # results JSON for AC3/AC6
```

## Notes
- 2026-11-03 (pm-lead): specced from the external reviews of `bb9ee90` (approved by Mahesh). Ownership: the workflow,
  Makefile and CONTRIBUTING are backend-owned. `evals/BASELINE.md` is ai-owned (`ownership-check.sh`: backend's allow-list has
  no `evals/`), so the landing PR can't edit it. The numbers go in this PR's description and artifact, and
  **EVAL-4** (ai-engineer) copies them into `evals/BASELINE.md` and adds the workflow to `evals/README.md`.
- RET-1 AC6 / EVAL-2 AC10 dedupe: the measurement now lives only here (AC6). EVAL-2 AC10 points here, and OPS-H1's note was updated to match.
- Folded in from Mahesh's #12 review: where `evals/results` go and how CI artifacts are kept (AC3, AC7). The `make test-py`
  split into `test-m0` / `test-evals-data` is a separate Backlog item, because it shouldn't wait for OPS-H1.
- 2026-11-07 (pm-lead, plan): OPS-H1 merged, so this is Wave 1 (backend slot 2 of 2, with LLM-1). The README Testing line moved to EVAL-4 so this PR
  and AI-7 don't both edit `README.md`. Since AI-7 (ADR-0003 refusals) and EVAL-6 (eval classification) land in parallel, AC6's
  numbers may come from before or after them. Record the `main` SHA the run used. Answer metrics added by EVAL-6 show up in
  the step summary automatically if EVAL-6 merged first. Don't add them here.
