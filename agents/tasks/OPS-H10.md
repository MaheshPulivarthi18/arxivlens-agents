# OPS-H10: `stack.yml` keeps service logs on green runs and runs on Go/test-only PRs

| | |
|---|---|
| **Owner** | backend-engineer (`.github/workflows/stack.yml`, `CONTRIBUTING.md` row, `README.md` Full stack paragraph) |
| **Priority** | P1 (harness: unblocks AI-9 AC1 and ADR-0015's stack numbers; gives Go pipeline/query PRs the milestone suite AGENTS.md §4 item 2 asks for) |
| **PRD ref** | Technical PRD §10 (testing), §9 (latency numbers need a source); AGENTS.md §4 DoD 2. Source: AI-9 QA r1 finding 2/6 [spec], ING-9 QA r1 finding 2 [spec], AI-7 review Backlog P3 (`query.log` on every run) |
| **Depends on** | OPS-H1 (merged). **#21 (AI-7, changes `README.md`) and #22 (EVAL-3, changes `CONTRIBUTING.md`) merged** (both are Ready to merge, waiting on Mahesh), per the AGENTS.md §3 same-file rule. No open PR changes `stack.yml` (checked 2026-11-07: #20–#25 don't). OPS-H9 no longer touches `stack.yml` (its optional step was removed to keep the two apart). |
| **Jira** | not created yet (orchestrator: story under epic KAN-3 "Dev harness & infrastructure", labels `task-OPS-H10`, `agent-backend`, `arxivlens`) |
| **Design required** | no: P1 CI-only change, no new command/table/service, no shared contract |
| **Status** | **Done**: PR #26 merged by Mahesh 2026-11-08 06:00Z as `54cad79` on ArxivLens `main` |

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
- [x] AC1: The PR's own `stack.yml` run (it triggers because the workflow file changes) finishes green apart from the known F1
  step. Its `stack-logs` artifact contains `compose.log`, `query.log`, `downloader.log` and `embedder-timing.log`, with the file
  list and sizes taken from `gh api .../actions/runs/<id>/artifacts` plus ~~an unzip listing~~ the Collect step's in-log
  `ls -l stack-logs` and the upload step's file count. On a green job, `compose.log` > 7,136 bytes (the size of AI-9's
  logs-less artifact) and contains lines from the `embedder-api` service (shown by a per-service count of the Collect-produced
  `compose.log` as printed in a job log, e.g. Diagnostics' `cat` on the AC3 run). *Amended 2026-11-07 by pm-lead (QA [spec] #2):
  the sandbox proxy blocks the artifact blob host, so the unzip listing is a human check for Mahesh in the PR, not an agent AC.*
  Met: run 42384934435 + scratch run 42368916365 (QA r2 evidence 14, 19, 20).
- [x] AC2: The run's step summary has the `### Embedder rerank timing` section. On this branch, without AI-9's code, it shows the
  "no embedder rerank timing lines" message, and the step concluded `success`. *Amended 2026-11-07 by pm-lead (QA [spec] #3):
  job summaries aren't in the REST API, so agent evidence is the step conclusion + `embedder-timing.log` = 57 B (the fallback
  line); the rendered summary block is a human check for Mahesh in the PR.* Met (QA evidence 09, 20).
- [x] AC3: "Collect service logs" runs when an earlier step failed. Show it with a scratch dispatch on a throwaway branch
  (never on `main`), where a step before it is forced to `exit 1` (e.g. `workflow_dispatch` on a scratch branch whose seed step
  fails). Both "Collect service logs" and "Diagnostics" ran, and `compose.log` is in the artifact. Delete the scratch branch
  afterwards and link the run. *Amended 2026-11-07 by pm-lead (QA r2 #6): agent sandboxes can't delete refs, so the deletion
  is Mahesh's (`git push origin --delete agent/backend/OPS-H10-ac3`), listed in the PR's human checks.* Met: run 42368916365
  (QA evidence 12–15); branch deletion pending Mahesh.
- [x] AC4: The `git diff` of `stack.yml` shows the five new `paths` entries and no change to the F1 step, `F1_TESTS`, any
  `timeout-minutes` or permissions. `actionlint` is clean (the workflow's own "Lint the harness" step). Ownership check OK.
  Total diff < 80 changed lines.
- [x] AC5: `CONTRIBUTING.md` `stack.yml` row and the README Full stack paragraph updated.
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
- 2026-11-07 11:00Z (pm-lead, grooming): #21 and #22 merged; no open PR changes `stack.yml`, `README.md` or `CONTRIBUTING.md` (open PR #24 changes only `services/embedder/api.py` and `tests/test_m0.py`). AI-9's README note (AC5) is written on its rework rebase, which happens only after this merges, so the two never edit `README.md` at the same time. Cut from `origin/main` `2b71772`; re-check the README line numbers in Scope against that SHA.
- 2026-11-07 (backend-engineer, build): commit `9ebb49e` on `agent/backend/OPS-H10` (cut from `2b71772`), 3 files, 26+/6- (32 changed lines).
  - `stack.yml`: 5 new `paths` (`cmd/**`, `internal/**`, `go.mod`, `go.sum`, `tests/**`). New step "Collect service logs" (`if: always()`, between F1
    and Diagnostics; every command guarded with `|| true`) writes `stack-logs/compose.log`, copies `downloader.log`/`query.log`/`ingest.json`,
    greps `rerank passages=` / `rerank warm-up` / `torch threads` into `embedder-timing.log` (or the "no embedder rerank timing lines (embedder
    predates AI-9)" line), and puts `head -n 200` of it under `### Embedder rerank timing` in the step summary. Diagnostics keeps `ps`, `dlq list`
    and `cat` but reads the files from `stack-logs/` (no second `docker compose logs`). F1, `F1_TESTS`, existing `timeout-minutes`, permissions,
    concurrency and the artifact name are unchanged. The new step has its own `timeout-minutes: 5`.
  - README Full stack paragraph (now lines 230-235) and CONTRIBUTING `stack.yml` row updated.
  - Local checks: YAML parses (paths list + step order checked), `bash -n` on both changed `run:` blocks is clean, ownership check
    `Ownership OK for role=backend (32 changed lines)`. **Not run locally:** actionlint/shellcheck (not installed; installing it from GitHub was blocked
    by the sandbox's permission system), so the PR run's "Lint the harness" step is the first actionlint check. `make lint`/`make test-unit` can't run here
    (`go.mod requires go >= 1.25.0 (running go 1.24.7)`); this change has no Go/Python code.
  - Needs CI: AC1/AC2 (the PR's own `stack.yml` run + artifact listing), AC3 (scratch-branch dispatch with a forced `exit 1`, then delete the branch).
- 2026-11-07 (backend-engineer, rework r1, QA r1 FAIL): head `9ebb49e` → `532440e`.
  - [x] **Finding 1 [blocking], AC3 failing-run evidence.** Scratch branch `agent/backend/OPS-H10-ac3` (`0558a34` = `9ebb49e` + the
    "AC3: crawl 2 papers" step replaced with `echo "::error::OPS-H10 AC3 scratch: forced failure before the host services start"; exit 1`;
    1 file, 2+/1-), `workflow_dispatch` run [42368916365](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42368916365),
    run conclusion `failure`, job 128392773584. Step conclusions (jobs API): 14 "AC3: crawl 2 papers" = **failure**
    (`##[error]Process completed with exit code 1.`), 15–19 (host services, wait, seed, `make test-full`, F1) = skipped,
    20 "Collect service logs" = **success**, 21 "Diagnostics" = **success**, 22 "Upload logs" = **success**, 23 Teardown = success.
    Collect step's `ls -l stack-logs` in the job log:
    `total 256` / `-rw-r--r-- 1 runner runner 256934 Nov  7 11:44 compose.log` / `-rw-r--r-- 1 runner runner     57 Nov  7 11:44 embedder-timing.log`
    (no `query.log`/`downloader.log`/`ingest.json`: the run failed before the host services started, and the `if [ -f ]` guards held).
    Upload: "With the provided path, there will be 4 files uploaded" (the two above + Diagnostics' `ps.txt`, `dlq.txt`).
    Artifacts API: `stack-logs` id 13572664383, 28,662 B, expires 2026-11-14T11:44:11Z. Diagnostics' `cat` of `compose.log` printed
    36 `arxivlens-embedder-api` lines (also 1107 kafka, 66 kafka-init, 58 postgres, 12 minio, 12 minio-init, 10 processor, 7 embedder-worker),
    which is the in-log stand-in for "contains lines from `embedder-api`" that the blocked artifact download couldn't show (finding 2).
  - [x] **Nit 4, README overclaim.** `README.md:235` now: "…with `compose.log` and `embedder-timing.log`, plus `query.log` and `downloader.log`
    once the host services have started." Ownership check: `Ownership OK for role=backend (32 changed lines)`. Pushed plainly (no force).
  - Nit 5 (Diagnostics depends on Collect): no change, as QA noted it is in line with Scope item 3.
  - Findings 2 and 3 are [spec] for pm-lead; left as they are.
  - **Scratch branch `agent/backend/OPS-H10-ac3` still exists — needs Mahesh to delete it (agent sandbox can't delete refs).** AC3's
    "delete the scratch branch afterwards" is therefore open on Mahesh's side.
- 2026-11-07 (pm-lead, final review): **APPROVE** on head `532440e` after QA r2 PASS. Verdict in `agents/reviews/OPS-H10/report.md`.
  I amended AC1 (unzip listing replaced by the in-log `ls -l` + per-service count; the artifact listing is a human check), AC2 (the rendered
  step summary is a human check) and AC3 (Mahesh deletes the scratch branch). Human checks for Mahesh are in the PR #26 description:
  open artifact 13579885920 (expires ~2026-11-14), view the run summary's `### Embedder rerank timing` block, and delete
  `agent/backend/OPS-H10-ac3`. Post-merge (pm-lead): confirm the next Go-only PR triggers `stack.yml`; AI-9 #24 rebases onto it for AC1.
- 2026-11-08 (pm-lead, grooming): PR #26 merged as `54cad79` (06:00Z). Status → Done.
