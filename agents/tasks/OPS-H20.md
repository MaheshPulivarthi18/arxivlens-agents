# OPS-H20: size the eval job timeout (prefetch budget) and the `make eval` step timeout (slow runner CPU)

| | |
|---|---|
| **Owner** | backend-engineer (`.github/` is backend-owned per AGENTS.md §2) |
| **Priority** | P2 (harness: only bites when arXiv rate-limits a cold eval store) |
| **PRD ref** | Technical PRD §10 Testing and evaluation (CI must be deterministic); QA OPS-H19 r1 finding 4 `[spec]` + PM OPS-H19 eval-timeout analysis (`agents/reviews/OPS-H19/report.md`, evidence 13) |
| **Depends on** | none. The job-timeout arithmetic assumes OPS-H19's 2520 s prefetch budget, which is already in `eval.yml` on main; raising the timeout before #111 merges is harmless. No open PR touches `eval.yml` (checked 2026-11-21 ~12:50Z) |
| **Jira** | KAN-118 (epic KAN-3 "Dev harness & infrastructure"; labels `task-OPS-H20`, `agent-backend`, `arxivlens`) |
| **Design required** | no: two timeouts and their comments in one workflow file |
| **Status** | In Progress: rework after PM CHANGES r1 (2026-11-21; one-line `CONTRIBUTING.md` fix, AC5). PM rework round 1 of 2 |

## Goal
After OPS-H19 the eval prefetch step can legitimately run up to 2520 + 120 = 2640 s (44 min) when arXiv rate-limits.
`eval.yml:25-26` budgets the job as "setup + stack-up ~10 + self-test 1 + seed 70 + eval 30 + upload/teardown 2 = ~113 -> 120"
with **no** prefetch time, so a run that spends its prefetch budget can hit the 120-min job timeout during `make eval`
(QA estimate ~112-157 min; the last green eval on main took 68 min with a 0 s prefetch, evidence
`agents/reviews/OPS-H19/evidence/09-time-budget-eval-history.txt`). The store is still saved, so the next run
converges, but that run is a red eval for a non-code reason. Make the job timeout cover the worst case.

Second, the `make eval` step's own `timeout-minutes: 30` is too tight for slower runners. On 2026-11-21 the eval check on
#111 (job 136830894337) got an AMD EPYC 7763 runner. It reranked at 13619 ms/query against 9272 on main's Intel Xeon 8573C
run of 11-20 (1.47x slower), finished retrieval in 17m54s against 12m12s, and was killed at 30 min in the answering phase,
before `GATE:` was printed. Main's step took 22m11s, and 1.47x of that is ~32.5 min. Evidence:
`agents/reviews/OPS-H19/evidence/13-pm-eval-timeout-analysis.txt`. Size the step for the slowest runner seen.

## Scope
- `.github/workflows/eval.yml`: the job `timeout-minutes` and its arithmetic comment (line ~25-26), and the `make eval`
  step's `timeout-minutes` (line ~149) with a comment giving the measured basis.
- `CONTRIBUTING.md:34` (added at PM review 2026-11-21, AC5): the `eval.yml` row says "Budgets: 70 min for the seed step,
  120 min for the job". That text is wrong once this PR lands. Nothing else in `CONTRIBUTING.md` changes.
- Out of scope: `scripts/arxiv_replay.py` and the `--budget-seconds 2520` value (ai-owned; unchanged), the prefetch step's
  own `timeout-minutes: 45`, any change to eval cases, thresholds or the reranker (speed-ups are a separate AI ticket), `stack.yml` (Full stack fits: ~11 min job + 19 min worst-case prefetch < 45), eval thresholds.

## Acceptance criteria
- [ ] AC1: The eval job comment lists the prefetch worst case explicitly, e.g. "setup + stack-up ~10 + prefetch 44 (2520 s
  budget + 120 s TIMEOUT) + self-test 1 + seed 70 + eval 30 + upload/teardown 2 = ~157 -> 165", and `timeout-minutes`
  equals the rounded-up total (≤ 360, the GitHub-hosted maximum). If the developer prefers lowering `--budget-seconds`
  instead, stop: that changes ai-owned behaviour and needs a PM decision, not this ticket.
- [ ] AC2: Every other step's `timeout-minutes` is unchanged (`git diff` of `eval.yml` shows only the job timeout, the `make eval` step
  timeout and their comments; the only other changed file is `CONTRIBUTING.md`, AC5).
- [ ] AC4: The `make eval` step `timeout-minutes` is at least 45 (≥ 1.35x the ~32.5 min EPYC 7763 projection), and its comment
  cites both measurements: 22m11s on Intel Xeon 8573C (run 44764887789) and the 1.47x slower EPYC 7763 run (job 136830894337).
  The AC1 job total uses this new step value (eval 45 instead of 30), so the job timeout still covers every step's worst case.
- [ ] AC3: CI on the draft PR: the `eval` check green, including its "Lint the harness (actionlint, compose config)" step
  and `make eval` with `GATE: PASS`; quote the job's total duration. (There is no separate `Lint` check; wording fixed
  2026-11-21 13:00Z after QA r1 finding 4, intent unchanged.)
- [ ] AC5 (added at PM review, DoD item 4): In `CONTRIBUTING.md:34` (`eval.yml` row), "120 min for the job" becomes "180 min for
  the job", and the row also gives the `make eval` step budget: "Budgets: 70 min for the seed step, 45 min for `make eval`,
  180 min for the job". No other line of `CONTRIBUTING.md` changes. After this, `git grep -n '120 min' -- README.md CONTRIBUTING.md`
  returns nothing. `eval.yml` stays byte-identical to `ece17a7`. AC3 has to be re-evidenced on the new head, because the `eval`
  check re-runs whenever the PR changes `eval.yml`.
## Verification
```bash
git diff origin/main --stat                       # exactly .github/workflows/eval.yml and CONTRIBUTING.md
git diff ece17a7 -- .github/workflows/eval.yml    # empty (rework touches only CONTRIBUTING.md)
git grep -n '120 min' -- README.md CONTRIBUTING.md  # no output
grep -n -B1 'timeout-minutes' .github/workflows/eval.yml
make lint
```

## Notes
- 2026-11-21 ~12:55Z (pm-lead): scope widened by AC4 (`make eval` step timeout) after the #111 eval check timed out on a
  slow runner (see Goal). Dependency on #111 dropped, Backlog → Ready. Same file and owner, so no parallel ticket.
- 2026-11-21 (pm-lead): created from QA OPS-H19 r1 finding 4. The global `concurrency: eval` queue means a longer timeout
  can delay a queued run; acceptable because the worst case only happens on a cold, rate-limited store.
- 2026-11-21 (backend-engineer): built on `agent/backend/OPS-H20` (commit ece17a7, from origin/main 11c4696). It is not pushed yet; the orchestrator pushes it and opens the PR.
  Only `.github/workflows/eval.yml` changed (+6/-3). Job `timeout-minutes` went from 120 to 180. The comment now reads "~10 + prefetch 44 (2520 s budget + 120 s TIMEOUT) + 1 + 70 + eval 45 + 2 = ~172 -> 180", which is under the 360 maximum.
  The `make eval` step went from 30 to 45. Its comment cites 22m11s on Xeon 8573C (run 44764887789) and the 1.47x slower EPYC 7763 run (job 136830894337): 1331 s x 1.47 = 32.6 min, and x 1.35 = 44.0, so 45.
  No other `timeout-minutes` changed (checked with grep -B1), the YAML parses, and the ownership check passes. actionlint did not run locally: there is no Docker daemon, and the sandbox denied downloading the binary.
  AC1/AC2/AC4 are met in the diff. AC3 is still open: it needs the PR's CI `Lint` and `eval` runs, plus the job's total duration.
- 2026-11-21 13:00Z (pm-lead): QA r1 `[spec]` findings handled. 4: AC3 names the real check (above). 2: the lost
  partial recording on a killed prefetch is folded into OPS-H21 (AC7, ai-owned `scripts/arxiv_replay.py`), not this
  ticket. 3: no change (AC4's total follows the ticket's own formula; QA requested none).
- 2026-11-21 (pm-lead): **PM CHANGES r1** (`agents/reviews/OPS-H20/report.md`). AC1-AC4 are met and well evidenced,
  but app `CONTRIBUTING.md:34` still says "120 min for the job", so merging would leave the contributor docs wrong (DoD item 4).
  My spec scoped only `eval.yml`, so this is a spec miss, not a developer error. Rework checklist for backend-engineer on the existing branch
  `agent/backend/OPS-H20` (PR #114):
  - [ ] `CONTRIBUTING.md:34`: "Budgets: 70 min for the seed step, 120 min for the job" → "Budgets: 70 min for the seed step,
    45 min for `make eval`, 180 min for the job" (AC5). No other edits; `eval.yml` unchanged.
  - [ ] Push to the PR (it stays draft). QA r3 checks AC5, confirms `eval.yml` is identical to `ece17a7`, and re-checks AC3 on the new head.
  No open PR touches `CONTRIBUTING.md` (checked via REST 2026-11-21).
