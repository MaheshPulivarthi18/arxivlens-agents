<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/51#issuecomment-6942816961 (the QA harness could not write report.md). -->

[qa-reviewer] # QA report: EVAL-4 · PR #51 · round 1

**Verdict:** FAIL (one one-line fix: Finding 1)
**Reviewed commit:** `d72ed0d1f03b5ccf3fff285e7265172f534d659c` (base `main` `40dec5a`, unchanged since) · **Date:** 2026-11-17
**Ticket:** [agents/tasks/EVAL-4.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/EVAL-4.md) · **PRD:** Product PRD §8 (metrics table); AGENTS.md §4 DoD 3 · **Design:** none (docs-only)
**Source run:** Eval run [43902662193](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/43902662193), job 133423130747, `main` `40dec5a`
**Evidence pack:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/56f275b/agents/reviews/EVAL-4/evidence (commit `56f275b`)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 133911807286 | pass ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/00-ci-checks.png?raw=true)) |
| Python M0 unit tests | CI job 133911807564 | pass (182 passed, 3 skipped; 37 passed) |
| Frontend (lint, test, build) | CI job 133911807593 | pass |
| DB (migrate twice, HNSW plan + recall) | CI job 133911807095 | pass |
| Agent ownership check | CI job 133911807544 | pass ("Ownership OK for role=ai (121 changed lines)") |
| Ticket verification: job-log diff | local, QA script against `gh api .../jobs/133423130747/logs` | 38/38 items match ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/04-baseline-vs-log.png?raw=true)); script catches 3/3 seeded edits ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/05-verifier-mutation-control.png?raw=true)) |
| Ticket verification: `git diff --stat origin/main` | local | 3 files, all in Scope ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/08-ac4-diff-scope.png?raw=true)) |
| `pytest tests/test_evals_data.py tests/test_arxiv_replay.py` | local | 128 passed, 1 skipped ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/12-local-tests.png?raw=true)) |
| `make test-unit` / `make lint` | not run locally: Go 1.25 toolchain download blocked (proxy.golang.org unreachable) | relying on CI (green) |
| `make eval` | not run: no stack/HF in sandbox; the task records an existing run and changes no code, dataset or threshold | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: every row has run 43902662193's value, run URL + job ID + SHA; "not run" only for `/v1/search` p95 with reason | ✅ values · ❌ one target cell | Run/job/SHA confirmed via REST: job `head_sha` 40dec5a, `head_branch` main, event `schedule`, `success`, artifact 14247998742 ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/01-source-run-metadata.png?raw=true)). Every value row matches ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/04-baseline-vs-log.png?raw=true)). "not run" appears only on `/v1/search` p95 with the EVAL-2/ADR-0012 reason, **but that row's target says `< 3000 (PRD §8)`; PRD §8 says `< 1.5 s`** (Finding 1, [10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/10-search-p95-target.png?raw=true)) |
| AC2: numbers match the job log of 133423130747 exactly | ✅ | QA script, independent of the developer's check: 9 retrieval/per-kind rows matched cell by cell, 15 gate-table rows matched by metric name (value, target, result), 12 summary-line numbers, `Cases evaluated: 78/78`, `GATE: PASS`. Every number in the BASELINE tables that isn't in the log is an ID (run/job/artifact/ADR/SHA) ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/04-baseline-vs-log.png?raw=true)). Raw log: [02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/02-job-log-eval-section.png?raw=true), [03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/03-job-log-profile-retrieval.png?raw=true). Verifier control (3 seeded edits → 3 DIFFs): [05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/05-verifier-mutation-control.png?raw=true); source: [06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/06-verifier-source.png?raw=true) |
| AC3: CPU-only sentence; p95 13330 ms informational; no GPU number as a baseline value | ✅ | `BASELINE.md:15-18` says "**CPU-only** profile ... `INFO (cpu-only; not gated)` ... this file has no GPU baseline"; log shows `hardware: embedder device=cpu profile=cpu-only`, healthz `device: cpu`, `torch-2.15.0+cpu`, 4 CPUs/15 GB, image ubuntu-26.04 20261111.196.1. The only GPU mention (`:71`) is labelled "reported, not re-measured", not a value ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/07-ac3-cpu-profile.png?raw=true)) |
| AC4: gate results per metric as logged (all PASS); only the 3 scoped files | ✅ | 7 PASS + ask_p95 `INFO (cpu-only; not gated)`, identical to the log. Diff: `README.md`, `evals/BASELINE.md`, `evals/README.md` only; the diff of `thresholds.json`, `*.jsonl`, `corpus.txt`, `scripts/` and `.github/` is 0 lines ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/08-ac4-diff-scope.png?raw=true)) |
| AC5: refusal numbers in BASELINE and the PR; any answer-set refusal reported to pm-lead | ✅ in BASELINE · ⚠ PR body partial · [spec] premise wrong | Log and BASELINE agree: `refusal_reason_counts {}`, correct refusals 100.00% of 22, near-miss 80.00% of 15, **in-corpus refused 4.55%** (= 1/22; consistent with `expected_paper_hit_rate` 0.9545 = 21/22). `classify()` makes a reasonless, citationless response an early refusal, and any `refusal_reason` would have been counted, so `{}` means the refusal was early: the BASELINE note is correct ([09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/09-ac5-refusals.png?raw=true)). The spec's "(none in this run)" is false; the refusal was reported (Finding 2). The PR body names only the 4.55% (Finding 3) |

## PRD fit
Product PRD §8 needs a measured reference that `make eval` regressions can be checked against. This PR replaces "not run" with the first green `main` run's numbers. All of them trace to the job log, the CPU-only profile is labelled so p95 isn't read as a gated miss, and the run, job, SHA and artifact are recorded. That serves the PRD and DoD 3. The one defect misquotes a PRD target in that same reference table.

Other claims checked against code ([11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/11-readme-claims.png?raw=true)):
- `eval.yml` has `workflow_dispatch` and `schedule`, and uploads the artifact `eval-results-${{ github.run_id }}`.
- `FusionK = 10` and `FUSION_K = 10`; the fusion formula matches `search.go:275`.
- RET-1 merged as `bb9ee90`.
- All 4 ADR links resolve, and the ADRs are Accepted.
- Every make target in the human commands exists, in the same order as the `eval.yml` steps.
- The README hunk sits in the Testing block, and the `evals/README.md` hunks are only in "Running" and "What the retrieval gate measures".

## Findings
1. **[code][blocking]** `evals/BASELINE.md`, gate table row `` `/v1/search` p95 | < 3000 (PRD §8) | not run ... ``: the target is wrong. Product PRD §8 (`/v1/search` p95 `< 1.5 s`), Technical PRD §9 (`< 1.5 s`) and ADR-0012 (`search_p95_latency_ms_max: 1500`) all say 1.5 s. 3000 is the `/v1/ask` key in `thresholds.json` ([10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/10-search-p95-target.png?raw=true)). This file is the reference every regression check and EVAL-2 will read, and the row attributes a wrong number to the PRD. Fix: `< 1500 (PRD §8)` (or `< 1.5 s`). No other change needed.
2. **[spec]** (for pm-lead, AC5 "stop and report") The ticket says "none in this run", but the log shows `In-corpus refused : 4.55%`, i.e. **1 of 22 answer-set questions was refused** (early refusal, no `refusal_reason`). The developer recorded it as-is and raised it; QA confirms it from the log ([09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/09-ac5-refusals.png?raw=true)). The job log doesn't name the case: `expected_paper_miss_ids` is only in the results JSON, and the artifact can't be downloaded from agent sandboxes. pm-lead decides whether to (a) correct AC5's premise and (b) open a follow-up to print refused/miss case IDs in the gate output (ai-engineer owns `scripts/`), or ask Mahesh to read `answers.cases` in artifact 14247998742 (expires 2026-12-16).
3. **[nit]** AC5 says the refusal counts go "in `BASELINE.md` and the PR". The PR body gives only the 4.55% refusal, not `refusal_reason_counts {}`, correct refusals 100% of 22 or near-miss 80% of 15. pm-lead can add these when filling the Evidence section. No code change.
4. **[nit]** `evals/README.md` also rewrites the "stable-sorted by score" sentence, which isn't in the ticket's literal list. It's in the named section, it was stale (ADR-0017 replaced it), and the new text matches `search.go`/`evaluate_retrieval.py` ([11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/56f275b/agents/reviews/EVAL-4/evidence/11-readme-claims.png?raw=true)). Acceptable; no action.

## Missing tests
- None required (docs-only). The baseline-vs-log check is a one-off QA script (source in evidence 06). A guard that keeps BASELINE.md in sync with the gate output would be a separate ticket.

## Hand-off
FAIL → back to ai-engineer for Finding 1 (one cell). Findings 2–3 → pm-lead. Round 2 re-runs the 06 verifier against the new head and checks the `/v1/search` target cell.

_Note: the QA harness refused to write `agents/reviews/EVAL-4/report.md` (subagent file-write restriction). This comment is the full report; the orchestrator saves it verbatim._


---
_Generated by [Claude Code](https://claude.ai/code)_
