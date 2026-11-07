# EVAL-9: Give `eval.yml`'s seed step timeout headroom, report seed time, and fix two summary labels

| | |
|---|---|
| **Owner** | backend-engineer (`.github/workflows/eval.yml`, `CONTRIBUTING.md`) |
| **Priority** | P1 (harness/quality: keeps the nightly eval from timing out instead of measuring) |
| **PRD ref** | Product PRD §8 (every Quality/Latency row is "Measured by `make eval`"); Technical PRD §9 (external politeness), §10; DoD 3. Source: EVAL-3 QA findings 1, 2, 5, 7 (`agents/reviews/EVAL-3/report.md`) |
| **Depends on** | EVAL-3 merged (ArxivLens #22). No other open PR may touch `eval.yml` or the CONTRIBUTING commands table rows for `eval-seed`/`eval.yml`. |
| **Jira** | not created yet (orchestrator: story under epic "Retrieval & answer quality gates", labels `task-EVAL-9`, `agent-backend`, `arxivlens`) |
| **Design required** | no (P1, no new command/table/service, no shared contract; timeouts are not quality gates) |
| **Status** | Ready (EVAL-3 merged `122eee3`). Not in cycle 11:00Z: shares `CONTRIBUTING.md` with OPS-H10 |

## Goal
On EVAL-3's two runs, `make eval-seed` took 30 m 24 s (cold) and 37 m 48 s (warm), which is 68% and 84% of the seed step's
45-min `timeout-minutes`. Seed time comes from arXiv fetches + CPU embedding (≈ 59–73 s per paper on a 4-vCPU runner), and
the model cache can't shorten it. One slow night would make the nightly time out (exit "cancelled") instead of producing
numbers. Give the step a budget with stated headroom, make seed time visible on every run so drift is caught early,
and fix two misleading summary labels QA found.

## Scope
- `.github/workflows/eval.yml`:
  1. Seed step `timeout-minutes: 45` → **70**. Job `timeout-minutes: 100` → **120**. Arithmetic (put it in a YAML comment):
     worst observed seed 37.8 min × ~1.6 ≈ 60, plus ~1.5 min for ING-9's extra per-process 3 s waits, rounded to 70;
     job = setup + stack-up ≈ 10 + self-test 1 + seed 70 + eval step 30 + upload/teardown 2 ≈ 113 → 120.
     The `make eval` step's own 30-min timeout is unchanged (observed 13–16 min).
  2. The seed step measures its wall time (bash `SECONDS`) and adds to the step summary one line:
     `seed: <m>m<s>s for <n> IDs (<pct>% of the 70-min step budget)`. If `pct` ≥ 75, it also prints
     `::warning::eval-seed used <pct>% of its time budget` (a warning annotation, never a failure; the step's exit code stays the target's).
  3. QA nit 1: the seed step's summary heading and the self-test's OK message say **make's** exit code
     (`make` returns 2 for any failed recipe). Reword them so they don't read as the eval's "2 = could not run", e.g.
     `### make eval-seed: make exit 2 (non-zero = at least one corpus ID failed; see seed-ids.log)` and
     `OK: make eval-seed failed (make exit 2) after 3 attempts`. Text only; the exit-code handling does not change.
  4. QA nit 2: on `workflow_dispatch`/`schedule`, the summary labels `github.sha` as "main (base) SHA", which is wrong for a
     branch dispatch. Record the real `origin/main` SHA (e.g. `git fetch --no-tags --depth=1 origin main` then
     `git rev-parse origin/main`) as "main SHA" and `github.sha` + `github.ref_name` as "run SHA/ref". On `pull_request` keep the
     PR base SHA as today.
- `CONTRIBUTING.md`: the `eval.yml` row states the 70-min seed / 120-min job budgets and the seed-time summary line, and one
  short clause on why the model cache is kept (it removes the run's dependency on Hugging Face being up; a missing model
  fails loudly offline), since it doesn't make the job faster (QA nit 7).
- Out of scope: `Makefile`'s `eval-seed` retry/politeness logic, `scripts/`, `evals/`, thresholds, `RerankPool`, the gate step,
  the workflow's triggers, and caching the seeded DB/MinIO state (Backlog option if 70 min ever gets tight).

## Acceptance criteria
- [ ] AC1: `eval.yml` has seed step `timeout-minutes: 70` and job `timeout-minutes: 120`, with the arithmetic comment. No other
  `timeout-minutes`, trigger, permission, concurrency or gate-step line changes (`git diff` of `eval.yml` shown in evidence).
- [ ] AC2: This PR's own `pull_request` Eval run (the workflow's path filter triggers it) completes with `make eval` exit 0 or 1, not 2
  and not cancelled, and its step summary / log shows the `seed: …% of the 70-min step budget` line. The run link is in the PR.
- [ ] AC3: The ≥ 75% warning path is shown to fire and not change the exit code: run the extracted seed-step body locally under
  `bash -e` with a stubbed `make eval-seed` (sleep or faked `SECONDS`) at ~80% and ~50% of budget, and with a stub that exits 2.
  Output shows the warning only at ~80%, and the step exit equals the stub's exit in every case.
- [ ] AC4: Nit wording (Scope 3) and the SHA labels (Scope 4) are fixed. Evidence: the PR run's summary/log lines for the
  `pull_request` case, plus the extracted SHA block run locally with `GITHUB_EVENT_NAME=workflow_dispatch` on a branch
  whose HEAD ≠ `origin/main`, printing two different SHAs with the right labels. CONTRIBUTING row updated as in Scope.
- [ ] AC5: `actionlint` clean (CI's harness-lint step); workflow ≤ 165 lines; total diff < 60 changed lines; ownership check OK.

## Verification
```bash
make lint
make test-unit
actionlint .github/workflows/eval.yml        # or the Eval run's "Lint the harness" step
gh run list --workflow eval.yml --branch agent/backend/EVAL-9 --limit 3
gh api repos/MaheshPulivarthi18/ArxivLens/actions/runs/<run-id>/jobs   # step timings, seed step duration
git diff --stat origin/main...agent/backend/EVAL-9
```

## Notes
- 2026-11-07 (pm-lead): specced from EVAL-3 PM review (QA findings 1, 2, 5, 7). Numbers: seed 30 m 24 s / 37 m 48 s for 31 IDs,
  0 retries, no arXiv 429/403; job 49 m 57 s / 60 m 24 s of 100. The PR's own run costs 62 arXiv requests (≈ 1 h); one run is enough,
  don't re-run for cosmetics. If ING-9 lands first, the PR's run already includes its extra waits; quote that in the PR.
- Don't raise the budget further "to be safe": if a run needs > 70 min of seeding, that's a signal for the Backlog caching option, not a bigger number.
- 2026-11-07 11:00Z (pm-lead, grooming): EVAL-3 merged. Not picked in cycle 11:00Z: no backend slot, and it edits `CONTRIBUTING.md` (the `eval.yml` row) while OPS-H10 edits the `stack.yml` row of the same file. Start once OPS-H10 merges.
