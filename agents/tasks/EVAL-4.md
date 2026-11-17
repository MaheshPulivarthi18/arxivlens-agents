# EVAL-4: Record EVAL-3's first measured eval numbers in `evals/BASELINE.md`

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 |
| **PRD ref** | Product PRD §8; DoD 3 |
| **Depends on** | EVAL-3 merged (`122eee3`) **and a completed green run**: nightly `eval.yml` run [43902662193](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/43902662193) on `main` `40dec5a` (2026-11-16, job 133423130747, `GATE: PASS`). EVAL-6 (`1273a3b`) and AI-7 (`8406b18`) are both in that SHA |
| **Jira** | not created yet (orchestrator: story under epic "Retrieval & answer quality gates", labels `task-EVAL-4`, `agent-ai`, `arxivlens`) |
| **Design required** | no: docs-only change in `evals/` + one README line |
| **Status** | **In Progress**: built, branch `agent/ai/EVAL-4` pushed at `d72ed0d`; draft PR to be opened by the orchestrator. **Finding for pm-lead on AC5** (see Notes 2026-11-17 ai-engineer) |

## Goal
`evals/BASELINE.md` is the reference every "`make eval` doesn't regress" check compares against, and it still says "not
run". This task copies the first green `main` run's numbers into it, so the baseline is real, and fixes the `evals/README.md`
sentences that are no longer true.

## Scope
- `evals/BASELINE.md`: rewrite. Title "Eval baseline: extractive `/v1/ask` (no LLM), CI CPU profile". One table with every gate row plus the
  info/report-only rows the job log prints: retrieval summary (4 modes × Recall@5/MRR/NDCG@5/ChunkP@5/Avg ms), the per-kind MRR table,
  answer-set supported citations (and citation count), correct refusals (n), p50/p95, near-miss refusals, `refusal_reason_counts`,
  `ask_errors`, and the `GATE:` line. Record: run URL, job ID, `main` SHA `40dec5a`, date, the profile (GitHub `ubuntu-latest`, PyTorch
  CPU, embedder device `cpu`), and live ordering (ADR-0010 pool 20 + ADR-0017 rank fusion + ADR-0016 two-per-paper cap; extractive quoted
  answers verified by quote match/NLI, #44). Keep the "Commands for the human" block, updated if a command changed.
- `evals/README.md`: "Running" gets 2–3 lines on `eval.yml` (nightly schedule + `workflow_dispatch`; the gate table is printed in the job log;
  results JSON in the run artifact; arXiv replay cache from #45). In "What the retrieval gate measures", fix the stale sentences:
  "Production `/v1/ask` returns this ordering only once RET-1 merges. Until then…" (RET-1 merged `bb9ee90`), and name ADR-0016/0017 as
  part of the gated ordering. Nothing else in that file.
- App `README.md` **Testing block only** (the ```` ```bash ```` list at `README.md:215-222`): one line for `eval.yml` (how to trigger it,
  where the gate table and results go). No other README section (ING-11b edits the API table's `/v1/search` row; AI-8 the `/v1/ask` row).
- Out of scope: thresholds, datasets, scripts, the workflow, GPU-profile numbers (Mahesh's reference-Mac numbers from #46–#50 are PR-body
  reports with no run artifact; at most one sentence linking them, labelled "reported, not re-measured").

## Acceptance criteria
- [ ] AC1: Every row of the `BASELINE.md` table has the value from run 43902662193 (run URL + job ID + `main` SHA `40dec5a`). "not run" stays only
  where the gate doesn't measure the metric yet (`/v1/search` p95: EVAL-2, ADR-0012 Proposed), with the reason.
- [ ] AC2: The numbers match the **job log** of job 133423130747 exactly (the gate table and summary are printed there; agent sandboxes can't
  download the artifact, lesson 2026-11-08 AI-9). QA diffs `BASELINE.md` against `gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/133423130747/logs`.
- [ ] AC3: The profile is recorded with the sentence that it is the **CPU-only** profile, so `/v1/ask` p95 (13330 ms) is informational
  (PRD-Technical §9, Accepted 2026-11-15; `INFO (cpu-only; not gated)` in the log). No GPU number appears as a baseline value.
- [ ] AC4: Gate results per metric as the log shows them (all PASS in this run). No case, corpus ID or threshold changed (`git diff --stat` shows only the 3 files in Scope).
- [ ] AC5 (AI-7's AC9): `answer_refusal_rate`/refusal counts from that run in `BASELINE.md` and the PR: `refusal_reason_counts {}`, correct refusals
  100% of 22, near-miss 80% of 15 (report-only). **Stop and report:** any answer-set refusal goes to pm-lead as a finding (none in this run).
  Note that this run has no LLM, so `insufficient_evidence` can't occur.

## Verification
```bash
make test-unit
gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/133423130747/logs | grep -A14 'Benchmark Results Summary Table'
gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/133423130747/logs | grep -E 'PASS|INFO|GATE:|Supported|refusal|Latency'
git diff --stat origin/main   # evals/BASELINE.md, evals/README.md, README.md only
```

## Notes
- 2026-11-03 (pm-lead): split from EVAL-3 because of ownership (`.github/` is backend's, `evals/` is ai's).
- 2026-11-07 (pm-lead): EVAL-3 no longer edits the app `README.md`. Add its one-line "nightly eval" note to the README Testing block
  (around line 202: how to trigger `eval.yml`, where results go) in this task.
- 2026-11-07 (pm-lead, AI-7 final review): AC5 added. AI-7's AC9 (how many of today's template answers now refuse, and why) couldn't be measured
  on the PR: `stack.yml` isn't triggered by `internal/**` and keeps `query.log` only on failure. EVAL-6's report-only metrics give the counts directly.
- 2026-11-17 (pm-lead, grooming): **unblocked and re-specced.** Nightly run 43902662193 on `main` `40dec5a` (after all of Mahesh's PRs
  through #50) is the first green `main` run (`GATE: PASS`; the 2026-11-14/15 schedule runs failed). AC2 now reads the job log, not the artifact.
  AC3 updated: §9 reference hardware is Accepted (GPU gated, CPU informational, #47). Scope gained the stale `evals/README.md` RET-1 sentence and
  ADR-0016/0017. The README Testing-line note above (2026-11-07) is now in Scope. Status → Ready.
- 2026-11-17 (ai-engineer, build): branch `agent/ai/EVAL-4` at `d72ed0d` (from `40dec5a`). `git diff --stat origin/main`: `README.md` +1,
  `evals/BASELINE.md` 100 lines, `evals/README.md` 20 lines (92+/29-). No threshold, case, corpus ID, script or workflow touched.
  - Source: `gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/133423130747/logs` (REST). Every number in `BASELINE.md` was checked
    mechanically against the log's eval section: all 9 retrieval/per-kind rows match exactly, and every metric value in the log is in the file.
    The log prints p95 as `13330.2916` (gate table) and `13330` (summary); both are recorded, gate-table value as the baseline.
  - **AC5 finding (stop and report):** the spec says no answer-set refusal in this run, but the log has `In-corpus refused : 4.55%` and
    `Answers citing expected : 95.45% of 22` (`expected_paper_hit_rate 0.9545`), i.e. **1 of 22 answer-set questions was refused**.
    `refusal_reason_counts {}` means it was an early refusal (no `refusal_reason`, `citations: []`), not `all_citations_unsupported`.
    The log does not name the case; it is in `answers.cases` of `evals/results/20261116T170152Z.json` (artifact 14247998742), which agent sandboxes
    can't download. Recorded as-is in `BASELINE.md` ("(info) in-corpus refused"); pm-lead to decide whether it needs a follow-up (e.g. ask backend
    to print refused answer-set case IDs in the log, or Mahesh to read the artifact). Correct refusals 100% of 22 and near-miss 80% of 15 match the spec.
  - Also fixed in `evals/README.md`: the "stable-sorted by score" sentence was stale too (ADR-0017 fusion replaced it); now describes fusion
    (`k = 10`, from `scripts/evaluate_retrieval.py` FUSION_K / `search.go` FusionK) and the ADR-0016 two-per-paper cap.
  - Verified: `pytest -q tests/test_evals_data.py tests/test_arxiv_replay.py` 128 passed, 1 skipped (opt-in DATABASE_URL). Not run locally:
    `tests/test_m0.py`, `test_worker_heartbeat.py`, `test_processor_pages.py`, `test_verify.py` (no torch/confluent_kafka/pymupdf in sandbox),
    `make test-go`/`make lint` (Go 1.24.7 local, go.mod needs 1.25). Docs-only change; CI is the source of truth. `make eval` not re-run (no infra;
    this task records the existing run).
  - Worktree note: the orchestrator's path `/home/claude/wt/EVAL-4` did not exist; the worktree is `/root/wt/EVAL-4` (same branch/SHA).
  - **Rework r1 (QA FAIL, Finding 1):** `evals/BASELINE.md` `/v1/search` p95 target changed `< 3000 (PRD §8)` -> `< 1500 (PRD §8)`
    (Product PRD §8 / Technical PRD §9 `< 1.5 s`, ADR-0012 1500). Grepped the file: the other `3000` mentions are `/v1/ask` and correct.
    Head `156c394`. Finding 2 (spec premise) left to pm-lead, recorded as-is; Finding 3 numbers for the PR body: `refusal_reason_counts {}`,
    correct refusals 100% of 22, near-miss 80% of 15, in-corpus refused 4.55% (1 of 22, early refusal).
