[qa-reviewer] QA report — OPS-H20 · PR #114 · round 1

**Verdict: PENDING** (AC3 only: the `eval` check on ece17a7 is queued behind the #111 re-run in `concurrency: eval`). AC1, AC2 and AC4 are fully evidenced, so next cycle only AC3 needs a re-check.
**Reviewed commit:** `ece17a72cd32b0d4b6178b18049156809cbf68b5` (base `11c4696` = origin/main) · **Date:** 2026-11-21
**Ticket:** [agents/tasks/OPS-H20.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/tasks/OPS-H20.md) · **PRD:** Technical PRD §10 · **Jira:** KAN-118 · Evidence folder: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence

## Test results
| Check | Source | Result |
|---|---|---|
| Go / Python M0 / Frontend / DB / Agent ownership | CI on ece17a7 | all success ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/00-ci-checks.png?raw=true)) `` |
| **Eval** (harness-lint step = actionlint + compose config, then `make eval`) | CI run 44905935487 | **pending**: queued at 12:51:06Z behind #111 re-run 44899068259 (attempt 2, in_progress since 12:45:31Z). Checked at 12:56Z and again before posting |
| actionlint v1.7.7 on `eval.yml` | local, built from tag-pinned GitHub clones | exit 0 at head and on main. Negative control (planted `timeout-minutes: one-eighty`) caught with exit 1 ([06](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/06-ac3-actionlint-local.png?raw=true), ``` [07](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/07-ac3-actionlint-negative-control.png?raw=true)). ```` No shellcheck locally; no `run:` block changed |
| Ticket verification: `git diff --stat`, `grep -n -B1 timeout-minutes` | local at ece17a7 | only `.github/workflows/eval.yml`, +6/-3 ([01](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/01-ac2-scope-diff.png?raw=true), ````` [03](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/03-ac2-grep-timeouts.png?raw=true)) `````` |
| `make lint` | not run locally | go vet/gofmt + oxlint only, and no Go or frontend files changed. The CI Go job is green |
| `make eval` | CI (pending) | no retrieval/answering code changed, so no before/after is expected; AC3 needs a green run |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `eval.yml:25-27`: "~10 + prefetch 44 (2520 s budget + 120 s TIMEOUT) + 1 + 70 + eval 45 + 2 = ~172 -> 180", `timeout-minutes: 180` ≤ 360. Recomputed: 172 → 180 ([04](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/04-ac1-ac4-arithmetic.png?raw=true)). ``````` `TIMEOUT = 120` is `arxiv_replay.py:49`. The prefetch `run:` is unchanged (`--budget-seconds 2520`) ([02](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/02-ac2-yaml-timeouts.png?raw=true)). ```````` The total differs from the ticket's example 165 only because of AC4's eval 45. A worst realistic job from the measured runs is ≈125-127 min |
| AC2 | ✅ | PyYAML diff of all 23 timeout entries, main vs head: changed = 2 (job 120→180, `make eval` 30→45). With timeouts removed, the parsed documents are identical ([02](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/02-ac2-yaml-timeouts.png?raw=true)) ````````` |
| AC4 | ✅ | `make eval` `timeout-minutes: 45`, and the comment cites both runs. Recomputed from the REST logs ([04](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/04-ac1-ac4-arithmetic.png?raw=true), `````````` [08](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/08-source-log-lines.png?raw=true)). ``````````` Main job 136386731578: Xeon 8573C, step 22m12s (REST, second-rounded; cited 22m11s), rerank 9271.75 ms, `GATE: PASS`. #111 job 136830894337: EPYC 7763, rerank 13619.42 ms, retrieval 17m53s vs 12m11s, "timed out after 30 minutes", no `GATE:`. Slowdown 1.469x / 1.467x; 1331 s × 1.47 = 32.61 min, × 1.35 = 44.02 → 45 ✅. The job total uses eval 45 ✅ |
| AC3 | ⚠ pending | The Eval run 44905935487 hasn't started ([00](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/00-ci-checks.png?raw=true)). ```````````` Local actionlint passes, but it doesn't replace the CI step |

## PRD fit
Serves Technical PRD §10 (deterministic CI): it removes two non-code failure modes (prefetch budget, slow runner CPU) by sizing the timeouts from measured data. No gate, threshold, eval case or arXiv-politeness setting changes.

## Findings
1. [nit] "prefetch 44 (2520 s budget + 120 s TIMEOUT)" understates the in-flight worst case. The budget is checked only before each query, and one query (API feed + PDF) can take up to 2 × (4 × (3 + 120) + 3 × 60) = 1344 s, so the step could run to about 64 min ([05](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/05-prefetch-worst-case.png?raw=true)). ````````````` The prefetch step's own 45-min cap bounds it, though: 10 + 45 + 1 + 70 + 45 + 2 = 173 ≤ 180, so the 180 is still right. The wording came from the ticket's example, so this is non-blocking.
2. [spec] (pm-lead, outside this ticket) If the prefetch step is *killed* at 45 min, `saved=` is never written, so "Save arXiv replay store" is skipped and that run's partial recording is lost. That breaks convergence in exactly the slow, rate-limited case. It is an ai-owned follow-up (a per-request deadline or incremental `saved=` in `scripts/arxiv_replay.py`).
3. [spec] AC4's phrase "covers every step's worst case" isn't literally true: the sum of every step's cap is 241 min ([02](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/02-ac2-yaml-timeouts.png?raw=true)), `````````````` because setup/stack-up is counted at its typical ~10 min (measured 5.3-6.5). That follows the ticket's own formula. No change requested.
4. [spec] AC3 names "`Lint`", but no such check exists on this head. actionlint runs only in the Eval job's "Lint the harness" step.

## Missing tests
None expected for a config-only change. The Eval run itself is the test (AC3).

## Hand-off
PENDING → re-review next cycle, **AC3 only**: in run 44905935487, check that "Lint the harness (actionlint, compose config)" = success, that `make eval` = success with `GATE: PASS`, and quote the job's total duration. A `make eval` timeout at 45 min would be a [blocking] finding against AC4's sizing.

Evidence (rendered from real output with `render_evidence.py`): [00](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/00-ci-checks.png?raw=true) ``````````````` · [01](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/01-ac2-scope-diff.png?raw=true) ```````````````` · [02](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/02-ac2-yaml-timeouts.png?raw=true) ````````````````` · [03](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/03-ac2-grep-timeouts.png?raw=true) `````````````````` · [04](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/04-ac1-ac4-arithmetic.png?raw=true) ``````````````````` · [05](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/05-prefetch-worst-case.png?raw=true) ```````````````````` · [06](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/06-ac3-actionlint-local.png?raw=true) ````````````````````` · [07](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/07-ac3-actionlint-negative-control.png?raw=true) `````````````````````` · [08](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/08-source-log-lines.png?raw=true) ``````````````````````` · [09 harness sources](```````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/09-harness-sources.png?raw=true) ````````````````````````

Note: the QA harness refused to write `agents/reviews/OPS-H20/report.md`. This comment is the report, for the orchestrator to save verbatim.


---
_Generated by [Claude Code](https://claude.ai/code)_


_Provenance: saved verbatim by the orchestrator from the [qa-reviewer] PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/114#issuecomment-7062942676 (the QA harness refused to write report.md)._

---

## Round 2 — 2026-11-21

**Verdict: PASS**
**Reviewed commit:** `ece17a72cd32b0d4b6178b18049156809cbf68b5` (unchanged since round 1; PR #114 head, still draft) · base `11c4696` = origin/main
Evidence folder: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence

### Test results (CI on ece17a7, all 6 check runs completed)
| Check | Result |
|---|---|
| Agent ownership, Go, Python M0, DB, Frontend | success (unchanged from r1) ([10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/10-r2-ci-checks.png?raw=true)) |
| **eval** (check run / job 136863495174, runner "GitHub Actions 1000002309") | **success**, 13:39:48Z → 15:00:42Z = **80m54s (4854 s)** ([11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/11-r2-ac3-eval-job-steps.png?raw=true), [13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/13-r2-ac3-ac4-durations-vs-timeouts.png?raw=true)) |
| make test-unit / make lint | not run locally (no Go 1.25 / npm in sandbox); CI Go, Python M0 and Frontend jobs green |
| make eval | CI: `GATE: PASS`. Recall@5 (Hybrid RRF + Rerank) 0.9850 ≥ 0.8, supported_citation_rate 1.0 ≥ 0.9, correct_refusal_rate 1.0 ≥ 0.95, ask_errors 0. No retrieval code changed, so no before/after delta applies ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/12-r2-ac3-eval-log-gate.png?raw=true)) |

### Step timing vs the new timeouts (job 136863495174)
| Step | Duration | timeout-minutes |
|---|---|---|
| 5 Lint the harness (actionlint, compose config) | 5 s, success; actionlint 1.7.7 printed no findings (only compose's `version` obsolete warning) | 3 |
| 12 Prefetch arXiv responses | 0 s (replay store hit; budget not exercised) | 45 |
| 17 make eval-seed | 42m00s | 70 |
| 19 **make eval** | **32m52s (1972 s)** | **45** (was 30) |
| job total | 80m54s | **180** (was 120) |

### Acceptance criteria (re-confirmed on the current head)
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | unchanged commit; `eval.yml:27 timeout-minutes: 180` read at head ([13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/13-r2-ac3-ac4-durations-vs-timeouts.png?raw=true)); arithmetic as r1 [04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/04-ac1-ac4-arithmetic.png?raw=true). The real job (80.9 min with a 0 s prefetch) + the 44-min prefetch worst case = ~125 min, inside 180 |
| AC2 | ✅ | `git diff --stat origin/main...ece17a7` still only `.github/workflows/eval.yml` (+6/-3); r1 [02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86232469caa9bf95d50c92931957583e2886bcb2/agents/reviews/OPS-H20/evidence/02-ac2-yaml-timeouts.png?raw=true) holds (same SHA) |
| AC3 | ✅ | `eval` check success; "Lint the harness (actionlint, compose config)" success; `make eval` success with `GATE: PASS`; job total duration **80m54s** ([11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/11-r2-ac3-eval-job-steps.png?raw=true), [12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/12-r2-ac3-eval-log-gate.png?raw=true)) |
| AC4 | ✅ (and validated by this run) | `eval.yml:152 timeout-minutes: 45`. This run again got an **AMD EPYC 7763** (rerank 13736.59 ms/query) and `make eval` took **32m52s**: it **would have been killed by the old 30-min step timeout**, and it is 1.48x the 22m11s Xeon run, matching the ticket's 1.47x / ~32.5 min projection. Margin 45 / 32.9 = 1.37x ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/12-r2-ac3-eval-log-gate.png?raw=true), [13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/13-r2-ac3-ac4-durations-vs-timeouts.png?raw=true)) |

### Findings
1. [nit] (carried from r1 finding 1, non-blocking) The comment's "prefetch 44" is the budget + one TIMEOUT, not the in-flight worst case; the prefetch step's own 45-min cap bounds it and 180 still covers it.
2. [nit] The prefetch worst case (2520 s budget) was not exercised by this run (cache hit, 0 s); it is covered by arithmetic only. Exercising it needs a cold, rate-limited store and is not something this ticket can reasonably require.
3. [nit] (info, outside scope) The EPYC margin on `make eval` is 1.37x; a runner ~1.37x slower than EPYC 7763 would hit 45 again. A reranker speed-up is already called out as a separate AI ticket in the Scope.

No [blocking] findings. No [spec] findings this round (r1's [spec] 2 is in OPS-H21; [spec] 4 fixed in the ticket at 13:00Z).

### Hand-off
PASS → pm-lead final review. Evidence (round 2, rendered from real CI output with `render_evidence.py`): [10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/10-r2-ci-checks.png?raw=true) · [11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/11-r2-ac3-eval-job-steps.png?raw=true) · [12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/12-r2-ac3-eval-log-gate.png?raw=true) · [13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8f641b429618dc10c015ce310b1859d48301a71a/agents/reviews/OPS-H20/evidence/13-r2-ac3-ac4-durations-vs-timeouts.png?raw=true)
