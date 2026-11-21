# OPS-H20: size the eval job timeout for a prefetch that uses its full time budget

| | |
|---|---|
| **Owner** | backend-engineer (`.github/` is backend-owned per AGENTS.md §2) |
| **Priority** | P2 (harness: only bites when arXiv rate-limits a cold eval store) |
| **PRD ref** | Technical PRD §10 Testing and evaluation (CI must be deterministic); QA OPS-H19 r1 finding 4 `[spec]` (`agents/reviews/OPS-H19/report.md`) |
| **Depends on** | OPS-H19 (ArxivLens #111) **merged**: before it, prefetch gives up after ~6.5 min and never uses its budget |
| **Jira** | needs creating: epic KAN-3 "Dev harness & infrastructure"; labels `task-OPS-H20`, `agent-backend`, `arxivlens` |
| **Design required** | no: two numbers and one comment in one workflow file |
| **Status** | Backlog (waits on OPS-H19 merge) |

## Goal
After OPS-H19 the eval prefetch step can legitimately run up to 2520 + 120 = 2640 s (44 min) when arXiv rate-limits.
`eval.yml:25-26` budgets the job as "setup + stack-up ~10 + self-test 1 + seed 70 + eval 30 + upload/teardown 2 = ~113 -> 120"
with **no** prefetch time, so a run that spends its prefetch budget can hit the 120-min job timeout during `make eval`
(QA estimate ~112-157 min; the last green eval on main took 68 min with a 0 s prefetch, evidence
`agents/reviews/OPS-H19/evidence/09-time-budget-eval-history.txt`). The store is still saved, so the next run
converges, but that run is a red eval for a non-code reason. Make the job timeout cover the worst case.

## Scope
- `.github/workflows/eval.yml`: the job `timeout-minutes` and its arithmetic comment (line ~25-26).
- Out of scope: `scripts/arxiv_replay.py` and the `--budget-seconds 2520` value (ai-owned; unchanged), the prefetch step's
  own `timeout-minutes: 45`, `stack.yml` (Full stack fits: ~11 min job + 19 min worst-case prefetch < 45), eval thresholds.

## Acceptance criteria
- [ ] AC1: The eval job comment lists the prefetch worst case explicitly, e.g. "setup + stack-up ~10 + prefetch 44 (2520 s
  budget + 120 s TIMEOUT) + self-test 1 + seed 70 + eval 30 + upload/teardown 2 = ~157 -> 165", and `timeout-minutes`
  equals the rounded-up total (≤ 360, the GitHub-hosted maximum). If the developer prefers lowering `--budget-seconds`
  instead, stop: that changes ai-owned behaviour and needs a PM decision, not this ticket.
- [ ] AC2: Every other step's `timeout-minutes` is unchanged (`git diff` shows only the job timeout and its comment).
- [ ] AC3: CI on the draft PR: `Lint` (actionlint runs in the harness-lint step) and `eval` green; quote the job's total duration.

## Verification
```bash
git diff origin/main --stat                       # exactly .github/workflows/eval.yml
grep -n -B1 'timeout-minutes' .github/workflows/eval.yml
make lint
```

## Notes
- 2026-11-21 (pm-lead): created from QA OPS-H19 r1 finding 4. The global `concurrency: eval` queue means a longer timeout
  can delay a queued run; acceptable because the worst case only happens on a cold, rate-limited store.
