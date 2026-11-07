<!-- Saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/26#issuecomment-6706327888 (the QA harness could not write report.md). -->

[qa-reviewer] QA report — OPS-H10 · PR #26 · round 1

**Verdict:** FAIL
**Reviewed commit:** `9ebb49ec90a4dd676a8ced2f1cafa88f1e804de1` · **Date:** 2026-11-07
**Ticket:** `agents/tasks/OPS-H10.md` · **PRD:** Technical PRD §10 (testing), §9 (latency numbers need a source); AGENTS.md §4 DoD 2
**Evidence folder (pinned):** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence

**Summary:** The workflow change is correct and the PR's own `stack.yml` run is green. The new step collected 5 files, `compose.log` is 281,388 bytes, and the step concluded `success`. **AC3 (the failing-run case) has no run behind it**, so this can't PASS yet. The code itself has no blocking defect.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI, head `9ebb49e` | success ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/00-ci-checks.png?raw=true))`` |
| Python M0 unit tests | CI | success |
| Frontend (lint, test, build) | CI | success |
| Agent ownership check | CI + local (`Ownership OK for role=backend (32 changed lines)`) | success ([07](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/07-ac4-ownership.png?raw=true))``` |
| DB (migrate twice, HNSW plan + recall) | CI | success |
| Full stack (compose + make test-full), run [42367580479](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42367580479) | CI, `event=pull_request` | success. `make test-full`: `96 passed, 1 skipped, 3 deselected`; F1 step `3 failed` (exit 2) under `continue-on-error`, as expected ([01](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/01-ac1-stack-run-steps.png?raw=true))```` |
| actionlint 1.7.7 | CI step "Lint the harness" | success, no findings printed ([11](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/11-ac4-actionlint-ci.png?raw=true)).````` Not run locally: the sandbox denied the Docker run |
| `make lint` / `make test-unit` | not run locally | `go.mod requires go >= 1.25.0` (sandbox has 1.24.7, toolchain download blocked). CI Go job is green |
| Artifact download + unzip listing | not run | `actions/artifacts/13573030487/zip` redirects to `productionresultssa3.blob.core.windows.net`, which returns `Forbidden` through the sandbox proxy ([03](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/03-ac1-artifact-download-blocked.png?raw=true))`````` |
| `make eval` | not run | no retrieval/answering change (CI workflow + docs only) |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 green PR run, `stack-logs` holds the 4 files, `compose.log` > 7,136 B with `embedder-api` lines | ⚠ mostly verified | Run 42367580479 (`pull_request`, head `9ebb49e`) concluded `success`. Only F1 failed, under `continue-on-error`; Diagnostics `skipped`, so this is the green path ([01](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/01-ac1-stack-run-steps.png?raw=true)).``````` The step's own `ls -l stack-logs` in the job log shows `compose.log 281388`, `downloader.log 819`, `embedder-timing.log 57`, `ingest.json 211`, `query.log 1794`. Artifacts API: `stack-logs` id 13573030487, 39,022 B (zip), 7 files uploaded ([02](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/02-ac1-artifact-files.png?raw=true)).```````` **Not seen by QA:** the unzip listing and the `embedder-api` lines inside `compose.log`, because the blob host is blocked ([03](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/03-ac1-artifact-download-blocked.png?raw=true)).````````` `embedder-api` is a compose service built and started in this run, and `docker compose --profile workers logs` covers it, but QA did not read the file. |
| AC2 `### Embedder rerank timing` section shows the fallback line; step `success` | ⚠ indirectly verified | Step 20 "Collect service logs": `conclusion=success`. `embedder-timing.log` is 57 bytes, the exact byte length of `no embedder rerank timing lines (embedder predates AI-9)\n`. The summary write is `stack.yml:250` ([09](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/09-ac2-timing-fallback.png?raw=true)).`````````` The step summary itself isn't in the REST API (check-run `output.summary` is `null`, and `summary_raw` returns 403), so QA did not see the rendered section. |
| AC3 Collect + Diagnostics both run after an earlier failure, `compose.log` in artifact; scratch branch deleted, run linked | ❌ no evidence | No such run exists. The only `stack.yml` run for this branch is 42367580479 (green) ([10](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/10-ac3-static-step-conditions.png?raw=true)).``````````` Static check only: Collect is `if: always()` (l.239) and sits before Diagnostics `if: "failure()"` (l.254) and Upload `if: always()` (l.267). By Actions semantics it should work, but the AC asks for a run. See finding 1. |
| AC4 5 new `paths`; F1 / `F1_TESTS` / `timeout-minutes` / permissions unchanged; actionlint clean; ownership OK; < 80 lines | ✅ | Diff: 3 files, 26+/6- ([04](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/04-ac4-stack-yml-diff.png?raw=true),```````````` [05](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/05-ac4-stack-yml-fulldiff.png?raw=true)).````````````` The 5 entries `cmd/**`, `internal/**`, `go.mod`, `go.sum`, `tests/**` are present, and the existing entries, `workflow_dispatch` and `concurrency` are kept. The only changed line that matches F1 / timeout / permissions / concurrency / artifact name is the new step's own `+ timeout-minutes: 5` ([06](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/06-ac4-protected-lines.png?raw=true)).`````````````` actionlint is clean in CI ([11](```````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/11-ac4-actionlint-ci.png?raw=true)).``````````````` Ownership OK, 32 changed lines ([07](````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/07-ac4-ownership.png?raw=true)).```````````````` |
| AC5 CONTRIBUTING `stack.yml` row + README Full stack paragraph | ✅ | Both now list the Go and `tests/` triggers and the every-run `stack-logs` artifact ([08](`````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/97914923df41e943ec2021d7710fbd0e43308cc8/agents/reviews/OPS-H10/evidence/08-ac5-docs-diff.png?raw=true)).````````````````` See nit 4 on README wording. |
| Post-merge check (pm-lead) | n/a | not blocking |

Scope check: only `.github/workflows/stack.yml`, `CONTRIBUTING.md`, `README.md` change, all inside backend-engineer's paths or common files. No ticket, review or doc files are in the PR. Nothing from Out of scope: F1 and `eval.yml`/`db.yml`/`ci.yml` are untouched, and there is no p50/max computation. Diagnostics keeps `ps`, `dlq list` and `cat`, and no longer runs `docker compose logs` a second time.

## PRD fit
This serves Technical PRD §10 and AGENTS.md DoD 2: Go and test-only PRs now get the end-to-end milestone suite. It also serves §9, because every green run now keeps service logs, so ADR-0015 and AI-9 get a source for embedder timing. arXiv politeness is unchanged: one run still makes 5 requests through the rate-limited crawler, and `cancel-in-progress` drops superseded runs.

## Findings
1. **[blocking] [code] AC3 has no run evidence.** The PR body lists AC3 as "(QA)", but QA does not edit CI in ArxivLens: a scratch branch with a forced `exit 1` is a workflow edit, and QA only writes `agents/reviews/`. The owner (backend-engineer, owns `.github/`) should:
   1. push a throwaway branch (not `main`, not the PR branch) whose `stack.yml` makes an early step fail, e.g. `exit 1` at the start of "Seed the M3/M4 fixture", or a new step right after "Build Go CLI";
   2. dispatch it with `gh api -X POST repos/MaheshPulivarthi18/ArxivLens/actions/workflows/stack.yml/dispatches -f ref=<scratch-branch>`;
   3. record the run id, the step conclusions (forced step `failure`, Collect `success`, Diagnostics `success`, Upload `success`), the Collect step's `ls -l stack-logs` lines from the job log showing `compose.log`, and the artifacts API entry;
   4. delete the branch and put the run link in the ticket Notes.

   Failing early (before stack-up finishes) also shows how the step behaves when `query.log`/`downloader.log` don't exist yet.
2. **[spec] AC1's "unzip listing" and "contains lines from `embedder-api`" can't be produced from the agent sandbox.** The artifact zip redirects to the Azure blob host, which the proxy refuses (same as ING-9 QA r1). Options: pm-lead or Mahesh opens artifact 13573030487 in the Actions UI (it expires after 7 days), or the ticket accepts the Collect step's in-log `ls -l` plus a count of lines per service printed by the step (a later follow-up, not this PR).
3. **[spec] AC2's step-summary check needs a browser.** GitHub doesn't expose job summaries in the REST API. QA verified it only indirectly (57-byte file = fallback line, step `success`). pm-lead should look at the run's summary page for the `### Embedder rerank timing` block.
4. **[nit] [code] README overclaims for early failures.** "Every run, green or red, uploads a `stack-logs` artifact with `compose.log`, `query.log`, `downloader.log` and `embedder-timing.log`" isn't true for a run that fails before "Start Go downloader and query service". Then only `compose.log` and `embedder-timing.log` exist (the step copies the others only `if [ -f ]`). Suggested wording: "…with `compose.log` and `embedder-timing.log`, plus `query.log`/`downloader.log` once the host services have started."
5. **[nit] [code] Diagnostics depends on Collect.** If "Collect service logs" hits its 5-min timeout, Diagnostics now prints no compose logs at all, where it used to collect its own. Low risk and in line with Scope item 3. Only noted.

## Missing tests
- The failing-run path (AC3) has never run. See finding 1.
- No run yet with AI-9's embedder, which would produce real `rerank passages=` lines. That is expected (AI-9 rebases after merge) and is covered by AI-9's own AC1.

## Hand-off
FAIL → back to backend-engineer for finding 1 (evidence only; no code change needed unless they take nit 4). The pm-lead handles findings 2 and 3 in the ticket.

_The QA harness refused to write `agents/reviews/OPS-H10/report.md` itself; this comment is the report of record for the orchestrator to save verbatim._


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## Round 2

[qa-reviewer] QA report: OPS-H10 · PR #26 · round 2

**Verdict:** PASS
**Reviewed commit:** `532440e04dad297fc08ed31fbaca4945e5fed73d` · **Date:** 2026-11-07
**Evidence folder (pinned):** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence (round-2 files are 12–20; round-1 files 00–11 are unchanged)

**Summary:** The blocking round-1 finding (AC3 had no failing run) is fixed. I checked scratch run 42368916365 myself through the REST API. The forced step failed, "Collect service logs", "Diagnostics" and "Upload logs" all concluded `success`, and `compose.log` (256,934 B) is in the uploaded artifact. The scratch commit's only change from `9ebb49e` is the forced `exit 1`, and `stack.yml` is byte-identical between `9ebb49e` and the PR head, so the run tests the code under review. Nit 4 (README wording) is fixed. The new head's Full stack run is green, and every other check is green too.

### Round-1 findings, checked one by one
| # | Round-1 finding | Round-2 status | Evidence |
|---|---|---|---|
| 1 | [blocking] AC3 has no run evidence | **Fixed.** Run [42368916365](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42368916365): `event=workflow_dispatch`, `branch=agent/backend/OPS-H10-ac3`, `sha=0558a34523bb…`, run `conclusion=failure`. Job 128392773584 steps: 14 "AC3: crawl 2 papers" = **failure**; 15–19 = skipped; 20 "Collect service logs" = **success**; 21 "Diagnostics" = **success**; 22 "Upload logs" = **success**; 23 Teardown = success. Artifacts API: `stack-logs` id 13572664383, 28,662 B, expires 2026-11-14T11:44:11Z | [12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/12-r2-ac3-run-steps.png?raw=true) |
| | | Job log: l.2721 `##[error]OPS-H10 AC3 scratch: forced failure…`, l.2722 `Process completed with exit code 1.`, then the Collect step's `ls -l stack-logs` (l.2746–2748): `total 256`, `compose.log 256934`, `embedder-timing.log 57`. `query.log`/`downloader.log`/`ingest.json` are missing because they never existed, so the `if [ -f ]` guards held and the step stayed green. Upload: "there will be 4 files uploaded" (2 from Collect + Diagnostics' `ps.txt`, `dlq.txt`), "Artifact ID is 13572664383" | [13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/13-r2-ac3-job-log.png?raw=true) |
| | | Diagnostics' `cat stack-logs/compose.log` (log l.2749–4099) prints lines from every compose service, including **37 `arxivlens-embedder-api`** (the developer's notes say 36, a counting difference with no effect; kafka 1108, postgres 59, processor 11, embedder-worker 8, …). So Diagnostics reuses the Collect file, as Scope item 3 asks | [14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/14-r2-ac3-compose-services.png?raw=true) |
| | | Scratch commit check: `9ebb49e..0558a34` = 1 commit, `stack.yml` only, 2+/1-, and the only change is the crawl step's `run:` replaced with the `::error::` + `exit 1`. `git diff --stat 9ebb49e 532440e -- .github/` is empty, so the scratch run used the PR head's workflow plus that one forced failure | [15](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/15-r2-ac3-scratch-diff.png?raw=true) |
| 2 | [spec] AC1 unzip listing / `embedder-api` lines in the artifact can't be produced from the sandbox | **Still open (pm-lead).** I tried artifact 13572664383/zip again: the redirect to `productionresultssa17.blob.core.windows.net` still fails through the proxy. The new head's in-log `ls -l` plus finding 1's per-service count of the same `compose.log` content are the best evidence the sandbox allows. A human opening artifact [13579885920](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42384934435) in the Actions UI would close this | – |
| 3 | [spec] AC2 step summary needs a browser | **Still open (pm-lead).** Same indirect proof on the new head: Collect `success`, `embedder-timing.log` 57 B (= the fallback line), and in the scratch log the summary command (l.2732) ran in a step that ended `success` | [20](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/20-r2-ac1-job-log.png?raw=true) |
| 4 | [nit] README overclaims for early failures | **Fixed.** `README.md:235`: "…with `compose.log` and `embedder-timing.log`, plus `query.log` and `downloader.log` once the host services have started." That matches the scratch run exactly (only those two files when the run fails early) | [16](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/16-r2-nit4-readme-and-refs.png?raw=true) |
| 5 | [nit] Diagnostics depends on Collect | No change, as round 1 accepted (in line with Scope item 3). Not blocking | – |

### Test results (head `532440e`)
| Check | Source | Result |
|---|---|---|
| Go, Python M0, Frontend, Ownership, DB | CI | all `success` ([18](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/18-r2-ci-checks.png?raw=true)) |
| Full stack, run [42384934435](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/42384934435) | CI, `event=pull_request` | `success` (polled until it finished, 15:20Z). `make test-full`: `96 passed, 1 skipped, 3 deselected`; F1 `3 failed` (exit 2) under `continue-on-error` (expected); Diagnostics skipped (green path); Collect `success` ([19](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/19-r2-ac1-stack-run.png?raw=true), [20](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/20-r2-ac1-job-log.png?raw=true)) |
| actionlint 1.7.7 | CI step 5 "Lint the harness" | `success` on both the head run and the scratch run |
| Ownership check | local at head | `Ownership OK for role=backend (32 changed lines)`; 3 files, 26+/6- ([17](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/17-r2-ac4-diffstat-ownership.png?raw=true)) |
| `make lint` / `make test-unit` | not run locally | `go.mod` requires Go ≥ 1.25 and the sandbox has 1.24.7. The CI Go job is green |
| `make eval` | not run | no retrieval/answering change |

### Acceptance criteria (round 2)
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ (unzip listing [spec] #2 still open) | New head run green except F1. Collect's `ls -l`: `compose.log 280074` (> 7,136), `downloader.log 819`, `embedder-timing.log 57`, `ingest.json 211`, `query.log 1794`. 7 files uploaded (5 + `test-full.log` + `test-f1.log`, matching the `path:` list); artifact 13579885920, 38,284 B ([19](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/19-r2-ac1-stack-run.png?raw=true), [20](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/20-r2-ac1-job-log.png?raw=true)). `embedder-api` lines in `compose.log` are seen in the scratch run's Diagnostics `cat` ([14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/14-r2-ac3-compose-services.png?raw=true)) |
| AC2 | ✅ indirectly ([spec] #3) | Collect `success`; 57-byte fallback file |
| AC3 | ✅ run evidence; ⚠ branch cleanup open (Mahesh) | [12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/12-r2-ac3-run-steps.png?raw=true), [13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/13-r2-ac3-job-log.png?raw=true), [14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/14-r2-ac3-compose-services.png?raw=true), [15](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/15-r2-ac3-scratch-diff.png?raw=true). Run linked in the ticket Notes. `agent/backend/OPS-H10-ac3` @ `0558a34` **still exists** (`git ls-remote`, [16](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/cf925cba217074ca5e1ca3a8c8c9b864a3238178/agents/reviews/OPS-H10/evidence/16-r2-nit4-readme-and-refs.png?raw=true)) |
| AC4 | ✅ | Unchanged since round 1 (the round-2 commit touches only `README.md`). 26+/6-, ownership OK, actionlint clean |
| AC5 | ✅ | CONTRIBUTING row unchanged since r1; README wording fixed (nit 4) |

### New findings
6. **[nit] [follow-up for Mahesh, not blocking] Delete the scratch branch `agent/backend/OPS-H10-ac3`** (`0558a34`). I don't block on this for three reasons. It is housekeeping, not part of the code under review. No agent sandbox can delete refs, so blocking would stall the task with no fix available. And the branch has no PR, so its forced failure can't reach `main` without a deliberate PR. Command: `git push origin --delete agent/backend/OPS-H10-ac3`. pm-lead should keep AC3's checkbox note "branch deletion pending Mahesh" until it's gone. The scratch run and its logs stay available after the branch is deleted (the artifact expires 2026-11-14).

### Hand-off
PASS → pm-lead for final review. Open items for pm-lead: [spec] #2 and #3 (a human checks the artifact zip and the step summary in the UI), and #6 (Mahesh deletes the scratch branch).
