<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-08 12:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/37#issuecomment-6721627270, because the QA harness could not write report.md. -->

[qa-reviewer] QA report: EVAL-9 · PR #37 · round 1

**Verdict:** PENDING. AC1, AC3, AC5 and the local half of AC4 are verified with no blocking findings. AC2 and the PR-run half of AC4 depend on Eval run [42478602587](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42478602587), and its seed step was still running when my 15-minute polling window ended at 12:41Z.
**Reviewed commit:** `ec60ab76f3f8856ac87e5931c1d163109265040b` (base `main` `9651294`, still current; PR open, draft, not merged) · **Date:** 2026-11-08
**Ticket:** `agents/tasks/EVAL-9.md` · **PRD:** Product PRD §8 ("Measured by `make eval`"), Technical PRD §9/§10, DoD 3; source: EVAL-3 QA findings 1, 2, 5, 7 · **Design:** not required
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 128725381999 | pass |
| Python M0 unit tests | CI job 128725381678 | pass |
| Frontend (lint, test, build) | CI job 128725381612 | pass |
| DB (migrate twice, HNSW) | CI job 128725381639 | pass |
| Agent ownership check | CI job 128725381632 | pass: `Ownership OK for role=backend (25 changed lines)` |
| Eval (`eval.yml`, run 42478602587) | CI job 128725381504 | **in progress**. Steps 1–12 succeeded, including step 5 "Lint the harness" (actionlint 1.7.7) and step 12, the self-test. Step 13 (`make eval-seed`) started 12:11:46Z and was still running at 12:41:37Z. Steps 14–19 are pending |
| Seed-step body under the runner shell (`bash --noprofile --norc -eo pipefail`), stub `make`, faked and real `SECONDS` | local, PR head | 10 cases, step exit equals stub exit in each one. The warning appears only at ≥ 75% → [03](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/03-ac3-seed-warning-path.png?raw=true)`` |
| Machine-profile body for workflow_dispatch / schedule / pull_request | local, PR head, real `git ls-remote origin` | labels correct → [04](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/04-ac4-sha-labels-local.png?raw=true)``` |
| `make lint`, `make test-unit` | not run locally: sandbox has Go 1.24.7 and the Go 1.25 toolchain download is blocked. CI is green | — |
| actionlint / shellcheck | not run locally (no binaries; Docker daemon unavailable). CI Eval step 5 passed | — |
| `make eval` before → after | the PR changes no retrieval or answering code. Numbers come from run 42478602587 when it completes | pending |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 budgets + arithmetic, no other control-line change | ✅ | The seed step has `timeout-minutes: 70` (`eval.yml:92`) and the job has `120` (`eval.yml:24`). Both arithmetic comments are present and match the ticket (37.8 × ~1.6 ≈ 60 + ~1.5 → 70; ~10 + 1 + 70 + 30 + 2 ≈ 113 → 120). I compared every trigger, permission, concurrency, `timeout-minutes`, gate and `continue-on-error` line between base and head. The only differences are the two timeouts plus the in-scope `BASE_SHA` line (Scope 4). The `make eval` step keeps `timeout-minutes: 30`. → [01](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/01-ac1-eval-yml-diff.png?raw=true)```` |
| AC2 PR's own Eval run completes (eval exit 0/1, not 2 or cancelled) and shows the `seed: …% of the 70-min step budget` line; run link in PR | ⏳ **pending** | The run is in progress (seed step at ~30 min when polling stopped) → [07](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/07-ac2-eval-run-pending.png?raw=true).````` The PR body still says "Run link: _pending_". Still to check: the job log has the `seed: …` line (the step echoes it to the log, so I can check it over REST), the `make eval` step's exit is 0 or 1, the run isn't cancelled, and the run link is in the PR body |
| AC3 ≥ 75% warning fires and never changes the exit | ✅ | I extracted the step body verbatim (PyYAML) and ran it under the runner's shell. 50%/rc0 → no warning, exit 0. 50%/rc2 → no warning, exit 2. 80%/rc0 → warning, exit 0. 80%/rc2 → warning, exit 2. Boundary: 74% → none, 75% → warning. With a real clock (stub sleeps 3 s, rc 2) the output is `seed: 0m3s for 31 IDs (0% …)` and exit 2. `n` = 31 matches `evals/corpus.txt`. → [03](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/03-ac3-seed-warning-path.png?raw=true)`````` (the full harness source is in the .txt) |
| AC4 wording + SHA labels + CONTRIBUTING | ✅ local / ⏳ PR run | Wording at `eval.yml:88`: `OK: make eval-seed failed (make exit $rc) after 3 attempts`. At `eval.yml:98`: `### make eval-seed: make exit $rc (non-zero = at least one corpus ID failed; see seed-ids.log)`. SHA block run locally: workflow_dispatch on `agent/backend/EVAL-9` gives `run SHA/ref: ec60ab7… (agent/backend/EVAL-9); main SHA: 9651294…`, two different SHAs. Schedule gives `run SHA/ref: 9651294… (main); main SHA: 9651294…`. pull_request gives `… (37/merge); main (PR base) SHA: 9651294…`. The CONTRIBUTING `eval.yml` row has the 70/120 budgets, the seed-line format, the ≥ 75% warning and the HF-cache clause. → [04](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/04-ac4-sha-labels-local.png?raw=true),``````` [05](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/05-ac4-wording-contributing.png?raw=true).```````` **Still needed from the PR run's job log:** the self-test `OK: make eval-seed failed (make exit 2) after 3 attempts` line and the Machine-profile `run SHA/ref: … (37/merge); main (PR base) SHA: 9651294…` line. The REST API doesn't serve logs for an in-progress job |
| AC5 actionlint, ≤ 165 lines, < 60 changed lines, ownership | ✅ | `eval.yml` is 156 lines. Diff is 2 files, +16/−9 = 25 lines. CI ownership: `Ownership OK for role=backend (25 changed lines)`. Eval step 5 "Lint the harness (actionlint, compose config)", which runs `rhysd/actionlint:1.7.7` (with shellcheck) on this PR's `eval.yml`, succeeded. → [06](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/06-ac5-size-lint-ownership.png?raw=true),````````` [00](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/00-ci-checks.png?raw=true)`````````` |

**Scope:** only `.github/workflows/eval.yml` and `CONTRIBUTING.md` changed. Both are backend-owned and both are in the ticket's scope. No ticket, review or doc files leaked into the PR. `Makefile`, `scripts/`, `evals/`, thresholds, triggers and the gate step are untouched. The ticket gives `git fetch` + `git rev-parse origin/main` only as an example ("e.g."). The PR uses `git ls-remote origin refs/heads/main` instead, which is equivalent and avoids shallow-clone ref issues, so that's acceptable.

## PRD fit
The change keeps the nightly `make eval`, which measures every PRD §8 Quality/Latency row, from being cancelled by a slow seed. It also surfaces seed-time drift as a warning that never turns the run red. It changes no gate, threshold or arXiv request pattern (Technical PRD §9 politeness is unchanged), so it serves DoD 3 without weakening anything.

## Findings
1. [nit] The new seed heading (`### make eval-seed: make exit N (…)`) goes only to `$GITHUB_STEP_SUMMARY`, and step summaries aren't available through REST (`check-runs.output.summary` is null). So in CI, only someone viewing the run page can confirm the heading. The `seed:` line and the SHA line are echoed to the log, so those two are fine. Optional fix: `tee` the heading too, like the Machine-profile block.
2. [nit] If `git ls-remote origin` fails (a network blip), the summary prints `main SHA: ` with nothing after it and the step stays green. That's acceptable for a label, but `|| echo unknown` would make the gap explicit.

No blocking findings so far.

## Missing tests
- None for the harness. The local cases cover the 50/74/75/80% boundary, both exit codes and the real clock. Remaining: the real CI observation for AC2/AC4.

## Hand-off
**PENDING:** re-review next cycle once run 42478602587 completes. Round 2 must: (a) fetch job 128725381504's log and quote the `seed: …% of the 70-min step budget` line (plus a `::warning::` if ≥ 75%), the self-test `OK: make eval-seed failed (make exit 2) …` line, the `run SHA/ref: … (37/merge); main (PR base) SHA: 9651294…` line and the `make eval` exit (0 or 1, not 2 and not cancelled); (b) confirm the run link and seed time are in the PR body; (c) recheck that all checks on the head are still green. Do not re-dispatch `eval.yml` (62 arXiv requests).

Evidence (pack commit `3edd54ccde91a3849550695e3495342d18dca268`): [00](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/00-ci-checks.png?raw=true)``````````` · [01](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/01-ac1-eval-yml-diff.png?raw=true)```````````` · [03](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/03-ac3-seed-warning-path.png?raw=true)````````````` · [04](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/04-ac4-sha-labels-local.png?raw=true)`````````````` · [05](```````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/05-ac4-wording-contributing.png?raw=true)``````````````` · [06](````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/06-ac5-size-lint-ownership.png?raw=true)```````````````` · [07](`````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/3edd54ccde91a3849550695e3495342d18dca268/agents/reviews/EVAL-9/evidence/07-ac2-eval-run-pending.png?raw=true)`````````````````


---
_Generated by [Claude Code](https://claude.ai/code)_
