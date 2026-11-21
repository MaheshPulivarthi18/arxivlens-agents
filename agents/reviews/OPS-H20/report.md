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

---

## PM final review (pm-lead) — 2026-11-21

**Verdict: CHANGES** (PM rework round 1 of 2) · Reviewed head `ece17a72cd32b0d4b6178b18049156809cbf68b5` (PR #114, draft)

**What I checked:** the ticket, Technical PRD §10, the PR diff (`gh api .../pulls/114/files`: `eval.yml` only, +6/-3), the check
runs on `ece17a7` (all 6 success, `eval` 136863495174 13:39:48Z → 15:00:42Z), and every evidence file, rounds 1 and 2. I opened all 14 PNGs
and checked each against its `.txt`: 00-09 were added in `8623246`, 10-13 in `8f641b4`.

**The change itself works.** It delivers what the ticket asked for:
- AC1: comment "~10 + prefetch 44 + 1 + 70 + eval 45 + 2 = ~172 -> 180" and `timeout-minutes: 180` (≤ 360). The arithmetic is recomputed
  from real job timings in 04, and the prefetch `run:` is unchanged in 02. 180 also covers the prefetch step's own 45-min cap (173), see 05.
- AC2: the YAML diff (02) shows exactly 2 of 23 timeouts changed, and the parsed documents are otherwise identical. The grep is in 03.
- AC3: `eval` is green on the head. "Lint the harness" succeeded in 5 s, and the CI log shows actionlint 1.7.7 ran (11, 12). `make eval`
  ended with `GATE: PASS`, all gated metrics passing. Job total 80m54s (11, 13).
- AC4: the step is 45 and the comment cites both runs (01, 08). The r2 run proves the point: it landed on an EPYC 7763 again, and
  `make eval` took 32m52s. The old 30-min cap would have killed it, and 45 leaves 1.37x headroom (12, 13).
- Product fit: it serves PRD §10 (deterministic CI) by removing two non-code red-eval causes without touching any gate,
  threshold, eval case or politeness setting. Scope inside `eval.yml` is exact. QA's nits are acceptable: "prefetch 44" understates
  the in-flight worst case, but the 45-min step cap bounds it. QA r1 `[spec]` 2 is tracked in OPS-H21 AC7.
- Evidence quality: 13's header overlaps the command text when rendered (cosmetic), and 13.txt is clean. 06/07 are local
  actionlint runs, superseded by the CI step in 12.

**Changes requested:**
1. **Docs (DoD item 4): app `CONTRIBUTING.md:34` becomes wrong after this PR.** Its `eval.yml` row says "Budgets: 70 min for the seed
   step, **120 min for the job**". Contributors read that table to judge whether a long eval run is normal, so it must say 180. It
   should also give the new 45-min `make eval` step budget, the value that actually bit on #111. This is **my spec miss**: Scope listed only
   `eval.yml`. I added AC5 and a rework checklist to the ticket (one line in `CONTRIBUTING.md`, backend-owned; no open PR touches it).
   QA r3: verify AC5, verify `eval.yml` is byte-identical to `ece17a7`, and re-quote AC3 on the new head. The `eval` check re-runs because
   the PR still changes `eval.yml`.

No other changes. Once AC5 is in and QA r3 passes, I expect to APPROVE without re-reviewing AC1-AC4.

## Round 3 — 2026-11-21 (qa-reviewer)

**Verdict: PENDING** (AC3 only: the `eval` check on the new head is still running) · Head `3224fb296fff00836b5bdc22d0124f7218e7acb1` (PR #114, draft) · previous QA'd head `ece17a7`

Ran in a detached worktree of the app at `3224fb2`. Every command and its output is in the evidence files below, rendered with `agents/tools/render_evidence.py`.

### PM rework checklist (PM CHANGES r1)
| Item | Result | Evidence |
|---|---|---|
| `CONTRIBUTING.md:34` says "Budgets: 70 min for the seed step, 45 min for `make eval`, 180 min for the job" | Met. Matches the AC5 text word for word. The values match `eval.yml`: `make eval-seed` 70 (l.128), `make eval` 45 (l.152), job 180 (l.27) | `17-r3-ac5-wording` |
| No other line of `CONTRIBUTING.md` changes | Met. `ece17a7..3224fb2` changes 1 file, +1/-1 | `15-r3-rework-diff` |
| `eval.yml` byte-identical to `ece17a7` | Met. `git diff --exit-code` exits 0, and the blob SHA is the same at both commits (`9108395a…`) | `16-r3-evalyml-identical` |
| PR scope is exactly `eval.yml` + `CONTRIBUTING.md` | Met. `origin/main...3224fb2`: 2 files, +7/-4 | `14-r3-scope-stat` |
| No stale budgets in README/CONTRIBUTING | Met. `git grep '120 min'` finds nothing (exit 1). Every "N min" mention in README/CONTRIBUTING is one of 70/45/180 on line 34 | `18-r3-no-stale-budgets` |

### Test results (CI on 3224fb2, fetched 16:23:44Z)
- Agent ownership check, Go, Frontend, DB, Python M0 unit tests: all **success** (`19-r3-ci-checks`).
- `eval` (job 136903946034, started 16:13:14Z): **in progress**. Steps 1-16 succeeded, including step 5 "Lint the harness (actionlint, compose config)" (11 s). Step 17 `make eval-seed` has been running since 16:20:12Z, and `make eval` is still pending (`20-r3-ac3-eval-steps-in-progress`). Per the orchestrator's instruction I did not wait for it.
- Not run locally: `make lint` / actionlint (no Docker daemon in the sandbox; actionlint already ran in CI step 5 at this head, and r1/r2 covered it).

### Acceptance criteria
- AC1, AC2, AC4: unchanged from r2. `eval.yml` is byte-identical to the head QA'd in r2 (`16`), so the r2 evidence (01-05, 13) still applies.
- AC2 (its second clause, "the only other changed file is `CONTRIBUTING.md`"): met (`14`).
- AC5: met (`15`-`18`).
- AC3: **open**. The lint step is green on this head (`20`), but `GATE: PASS` and the job total are not available yet.

### Findings
None. No blocking findings and no nits on the rework.

### Hand-off
PENDING on AC3 only. Next QA round: once job 136903946034 completes, quote the `make eval` `GATE:` line and the job's total duration. If it is green, the verdict is PASS → pm-lead, and nothing else needs re-checking. If it fails for a non-code reason (runner or arXiv), report it as such.

Evidence (new in r3): `14-r3-scope-stat`, `15-r3-rework-diff`, `16-r3-evalyml-identical`, `17-r3-ac5-wording`, `18-r3-no-stale-budgets`, `19-r3-ci-checks`, `20-r3-ac3-eval-steps-in-progress` (`.png` + `.txt` each).

## Round 4 — 2026-11-21 (qa-reviewer)

**Verdict: PASS** · Head `3224fb296fff00836b5bdc22d0124f7218e7acb1` (PR #114, draft, not merged; head unchanged since r3) · Evidence folder: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/04fe71007d671ee358d99e7f250a40d9f868906d/agents/reviews/OPS-H20/evidence

This round closes the one open item from r3: AC3 on the new head. I polled job 136903946034 from 17:19:56Z, and it completed at 17:23:06Z.

### Test results (CI on 3224fb2, all 6 check runs completed)
| Check | Result |
|---|---|
| Agent ownership, Go, Frontend, DB, Python M0 | success ([21](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/04fe71007d671ee358d99e7f250a40d9f868906d/agents/reviews/OPS-H20/evidence/21-r4-ci-checks.png?raw=true)) |
| **eval** (job 136903946034, `head_sha` = 3224fb2, runner "GitHub Actions 1000002332", Intel Xeon Platinum 8573C) | **success**, 16:13:14Z → 17:23:06Z = **69m52s (4192 s)** ([22](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/04fe71007d671ee358d99e7f250a40d9f868906d/agents/reviews/OPS-H20/evidence/22-r4-ac3-eval-job-steps.png?raw=true)) |
| make test-unit / make lint | not run locally (no Go 1.25 / npm / Docker in the sandbox). The CI Go, Python M0 and Frontend jobs are green |
| make eval | CI: `GATE: PASS`. Recall@5 (Hybrid RRF + Rerank) 0.9850 ≥ 0.8, supported_citation_rate 1.0 ≥ 0.9, correct_refusal_rate 1.0 ≥ 0.95, ask_errors 0, 78/78 cases. These match r2 exactly. No retrieval or answering code changed ([23](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/04fe71007d671ee358d99e7f250a40d9f868906d/agents/reviews/OPS-H20/evidence/23-r4-ac3-eval-log-gate.png?raw=true)) |

### Step timing vs timeouts (job 136903946034)
| Step | Duration | timeout-minutes |
|---|---|---|
| 5 Lint the harness (actionlint, compose config) | 11 s, success | 3 |
| 12 Prefetch arXiv responses | 0 s (replay store hit) | 45 |
| 17 make eval-seed | 2373 s = 39m33s | 70 |
| 19 make eval | 1391 s = 23m11s, success (Xeon 8573C, so close to the 22m11s baseline) | 45 |
| job total | 69m52s | 180 |

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1, AC2, AC4 | ✅ | Unchanged since r3. `eval.yml` is byte-identical to the head QA'd in r2 (r3 `16`), so r1/r2 evidence 01-05 and 13 still apply |
| AC3 | ✅ | `eval` check success on 3224fb2. Step 5 "Lint the harness (actionlint, compose config)" success. `make eval` success with `GATE: PASS`. Job total duration **69m52s** ([22](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/04fe71007d671ee358d99e7f250a40d9f868906d/agents/reviews/OPS-H20/evidence/22-r4-ac3-eval-job-steps.png?raw=true), [23](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/04fe71007d671ee358d99e7f250a40d9f868906d/agents/reviews/OPS-H20/evidence/23-r4-ac3-eval-log-gate.png?raw=true)) |
| AC5 | ✅ | Unchanged since r3 (`15`-`18`) |

### Findings
None new. The r2 nits (prefetch-44 wording, prefetch budget not exercised, the 1.37x EPYC margin) still stand and are non-blocking. No [blocking] and no [spec] findings.

### Hand-off
PASS → pm-lead final review. Per PM r1, only AC5 needed re-review, and it is met (r3). New evidence in r4, rendered from real CI output with `render_evidence.py`: [21](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/04fe71007d671ee358d99e7f250a40d9f868906d/agents/reviews/OPS-H20/evidence/21-r4-ci-checks.png?raw=true) · [22](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/04fe71007d671ee358d99e7f250a40d9f868906d/agents/reviews/OPS-H20/evidence/22-r4-ac3-eval-job-steps.png?raw=true) · [23](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/04fe71007d671ee358d99e7f250a40d9f868906d/agents/reviews/OPS-H20/evidence/23-r4-ac3-eval-log-gate.png?raw=true) (`.png` + `.txt` each).

---

## PM final review round 2 (pm-lead) — 2026-11-21

**Verdict: APPROVE** · Reviewed head `3224fb296fff00836b5bdc22d0124f7218e7acb1` (PR #114, draft → raised) · after QA r4 PASS

**What I checked:** the ticket (AC1-AC5), Technical PRD §10, the PR diff (`gh api .../pulls/114/files`: `eval.yml` +6/-3 and
`CONTRIBUTING.md` +1/-1), the 6 check runs on `3224fb2` (all `success`, re-fetched now), and every new evidence file, r3 14-20 and
r4 21-23. I opened each PNG against its `.txt`. Files 00-13 were reviewed in PM r1, and they still apply because `eval.yml` is byte-identical
(blob `9108395a` at both `ece17a7` and `3224fb2`, file 16).

**PM CHANGES r1 item 1 (AC5): met.**
- `CONTRIBUTING.md:34` now reads "Budgets: 70 min for the seed step, 45 min for `make eval`, 180 min for the job". That matches the AC5
  text word for word and the values in `eval.yml` (l.27 180, l.128 70, l.152 45) (17). The rework is one line, +1/-1 (15), and the PR
  touches exactly two files (14). `git grep '120 min'` finds nothing, and every remaining "N min" in README/CONTRIBUTING is one of the new budgets (18).
- AC3 has new evidence on the new head. `eval` job 136903946034 (`head_sha` 3224fb2) succeeded, "Lint the harness" passed in 11 s,
  `make eval` passed in 23m11s on a Xeon 8573C with `GATE: PASS` and 78/78 cases, metrics are identical to r2, and the job total was **69m52s** (21, 22, 23).
  Together with r2's EPYC run (32m52s, which the old 30-min cap would have killed), this covers both runner types the ticket named.

**Product fit / scope:** unchanged from r1. This removes two non-code causes of a red eval (PRD §10 deterministic CI) and touches no gate,
threshold, eval case or politeness setting. The contributor docs are now truthful (DoD item 4). Technical PRD §10 has no status column
that this ticket changes. There are no follow-ups beyond OPS-H21 (already specced) and QA's non-blocking nits (prefetch-44 wording; the
1.37x EPYC margin, which belongs to a future reranker speed-up ticket).

**Evidence quality:** sufficient. Lines in 22/23 that the renderer coloured red (steps 8 and 16, `ask_errors`) are success/PASS rows; the
.txt files confirm it. This is a cosmetic keyword-highlight issue.

→ PR #114 raised for review (description rewritten with the evidence, marked ready for review). Jira KAN-118 → Ready to merge.
