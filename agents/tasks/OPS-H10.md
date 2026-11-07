# OPS-H10: `stack.yml` keeps service logs on green runs and runs on Go/test-only PRs

| | |
|---|---|
| **Owner** | backend-engineer (`.github/workflows/stack.yml`, `CONTRIBUTING.md` row, `README.md` Full stack paragraph) |
| **Priority** | P1 (harness: unblocks AI-9 AC1 and ADR-0015's stack numbers; gives Go pipeline/query PRs the milestone suite AGENTS.md §4 item 2 asks for) |
| **PRD ref** | Technical PRD §10 (testing), §9 (latency numbers need a source); AGENTS.md §4 DoD 2. Source: AI-9 QA r1 finding 2/6 [spec], ING-9 QA r1 finding 2 [spec], AI-7 review Backlog P3 (`query.log` on every run) |
| **Depends on** | OPS-H1 (merged). **#21 (AI-7, changes `README.md`) and #22 (EVAL-3, changes `CONTRIBUTING.md`) merged** (both are Ready to merge, waiting on Mahesh), per the AGENTS.md §3 same-file rule. No open PR changes `stack.yml` (checked 2026-11-07: #20–#25 don't). OPS-H9 no longer touches `stack.yml` (its optional step was removed to keep the two apart). |
| **Jira** | not created yet (orchestrator: story under epic KAN-3 "Dev harness & infrastructure", labels `task-OPS-H10`, `agent-backend`, `arxivlens`) |
| **Design required** | no: P1 CI-only change, no new command/table/service, no shared contract |
| **Status** | Ready once #21 and #22 merge (specced 2026-11-07 by pm-lead) |

## Goal
Two gaps in the Full stack workflow keep QA from getting evidence:
1. On a green run (the normal case, because "Known failure F1" is `continue-on-error`), `stack.yml` keeps no service
   logs at all. `compose.log`, `query.log` and `downloader.log` are written only by `Diagnostics` (`if: failure()`). So
   AI-9's embedder timing lines (`rerank passages=… tokenize_ms=… forward_ms=…`) were never captured, and ADR-0015 lacks
   its fixture-pool numbers.
2. `pull_request.paths` leaves out `cmd/**`, `internal/**`, `go.mod`, `go.sum` and `tests/**`. Go-only PRs (ING-9) and
   test-only PRs never get the end-to-end check, although the workflow runs the Go downloader and query service and
   `make test-full`.

## Scope
- `.github/workflows/stack.yml`:
  1. Add `cmd/**`, `internal/**`, `go.mod`, `go.sum`, `tests/**` to `on.pull_request.paths`. Keep the existing entries,
     `workflow_dispatch`, and `concurrency` (`cancel-in-progress: true`, so a push supersedes the previous run). This reverses
     pm-lead's earlier Backlog note "don't add `internal/**`" (AI-7 review). The reason: DoD 2 requires the milestone suite for
     pipeline/query changes, and one run makes only 5 arXiv requests.
  2. A new step **"Collect service logs"** with `if: always()`, placed after "Known failure F1" and before "Diagnostics":
     `mkdir -p stack-logs`, write `docker compose --profile workers logs --no-color --timestamps` to `stack-logs/compose.log`,
     and copy `downloader.log`, `query.log` and `ingest.json` into `stack-logs/` if they exist. Then grep the embedder lines
     `rerank passages=`, `rerank warm-up` and `torch threads` from `compose.log` into `stack-logs/embedder-timing.log`, and
     append them to the step summary under `### Embedder rerank timing`, capped at 200 lines. If nothing matches, write
     `no embedder rerank timing lines (embedder predates AI-9)` instead. The step must never fail the job (`|| true` on grep;
     no `continue-on-error` needed if every command is guarded).
  3. `Diagnostics` keeps its `if: failure()`, its `ps`, its `dlq list` and the `cat` of logs. It reuses the files from step 2
     instead of collecting them again (no duplicate `docker compose logs`).
  4. Don't change the F1 step, `F1_TESTS`, any `timeout-minutes`, AC1–AC4 steps, permissions or the artifact name.
     `Upload logs` already uploads `stack-logs/`.
- `CONTRIBUTING.md:29` (`stack.yml` row) and `README.md:230-234` (the Full stack paragraph lists the triggers): the triggers now
  include Go and `tests/` paths, and the artifact keeps service logs on every run. One sentence each.
- Out of scope: removing F1 (that comes after AI-10 / ADR-0015), computing p50/max in the workflow (AI-9 does it from the
  artifact, so the workflow doesn't depend on the embedder's log format), `ci.yml`'s HF cache key (AI-9 makes its real-model test
  skip in `ci.yml` instead), `eval.yml` (EVAL-9), `db.yml` (OPS-H9).

## Acceptance criteria
- [ ] AC1: The PR's own `stack.yml` run (it triggers because the workflow file changes) finishes green apart from the known F1
  step. Its `stack-logs` artifact contains `compose.log`, `query.log`, `downloader.log` and `embedder-timing.log`, with the file
  list and sizes taken from `gh api .../actions/runs/<id>/artifacts` plus an unzip listing. On a green job,
  `compose.log` > 7,136 bytes (the size of AI-9's logs-less artifact) and contains lines from the `embedder-api` service.
- [ ] AC2: The run's step summary has the `### Embedder rerank timing` section. On this branch, without AI-9's code, it shows the
  "no embedder rerank timing lines" message, and the step concluded `success`.
- [ ] AC3: "Collect service logs" runs when an earlier step failed. Show it with a scratch dispatch on a throwaway branch
  (never on `main`), where a step before it is forced to `exit 1` (e.g. `workflow_dispatch` on a scratch branch whose seed step
  fails). Both "Collect service logs" and "Diagnostics" ran, and `compose.log` is in the artifact. Delete the scratch branch
  afterwards and link the run.
- [ ] AC4: The `git diff` of `stack.yml` shows the five new `paths` entries and no change to the F1 step, `F1_TESTS`, any
  `timeout-minutes` or permissions. `actionlint` is clean (the workflow's own "Lint the harness" step). Ownership check OK.
  Total diff < 80 changed lines.
- [ ] AC5: `CONTRIBUTING.md` `stack.yml` row and the README Full stack paragraph updated.
- [ ] Post-merge check (pm-lead, not blocking the PR): the next Go-only PR (e.g. ING-9's rework push or #21 rebased) gets a
  `stack.yml` run without a manual dispatch.

## Verification
```bash
make lint
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.7 -color .github/workflows/stack.yml   # or the run's "Lint the harness" step
gh run list --workflow stack.yml --branch agent/backend/OPS-H10 --limit 3
gh api repos/MaheshPulivarthi18/ArxivLens/actions/runs/<run-id>/artifacts
gh run download <run-id> -n stack-logs -D /tmp/stack-logs && ls -l /tmp/stack-logs/stack-logs
git diff --stat origin/main...agent/backend/OPS-H10
```

## Notes
- 2026-11-07 (pm-lead): specced from AI-9 QA r1 (findings 2 and 6: AC1 had no after-numbers) and ING-9 QA r1 (finding 2:
  `stack.yml` never ran on a Go-only PR). Folds in the AI-7-review Backlog P3 item ("copy `query.log`/`downloader.log` into
  `stack-logs/` on every run"). Scope overlap check: EVAL-9 = `eval.yml` only. OPS-H9 had an *optional* `stack.yml` pgvector check,
  which is now removed from OPS-H9 so the two tickets share no file except `CONTRIBUTING.md` (different rows, but still sequence them: whichever starts second waits for the other's merge).
- The F1 step keeps running (and failing) on every Go PR now. That's expected while ADR-0015 is pending; it's `continue-on-error`.
- Unblocks: AI-9 AC1 (rebase #24 onto a `main` with this merged), then ADR-0015's fixture-pool numbers.
