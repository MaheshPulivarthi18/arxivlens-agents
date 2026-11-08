# OPS-H10b: `stack.yml` prints the embedder rerank timing lines to the job log

| | |
|---|---|
| **Owner** | backend-engineer (`.github/workflows/stack.yml`) |
| **Priority** | P1 (harness: unblocks AI-9 AC1 and ADR-0015's numbers; agent sandboxes can't read artifacts or step summaries) |
| **PRD ref** | Technical PRD §9 (latency numbers need a source), §10; AGENTS.md §4 ("CI is the source of truth"). Source: AI-9 QA r2 finding 1(b) (`agents/reviews/AI-9/report.md`), OPS-H10 QA lesson (step summaries aren't in REST) |
| **Depends on** | OPS-H10 (merged `54cad79`). No open PR changes `stack.yml` (checked 2026-11-08: #24, #35, #37, #38 don't) |
| **Jira** | not created yet (orchestrator: story under epic KAN-3 "Dev harness & infrastructure", labels `task-OPS-H10b`, `agent-backend`, `arxivlens`) |
| **Design required** | no: P1 CI-only, a few lines, no command/table/service/contract change |
| **Status** | Ready |

## Goal
OPS-H10 writes `stack-logs/embedder-timing.log` to the step summary and the artifact only. Neither is reachable from agent
sandboxes (blob host and web UI refused by the proxy; `output.summary` is `null` in REST), so AI-9's AC1 numbers exist but nobody
on the team can read them. Print the same lines to the job log, which `gh run view --log` / the jobs API can fetch.

## Scope
- `.github/workflows/stack.yml`, the log-collection step (around line 250 on `9651294`): also write the timing block to stdout,
  e.g. `{ echo "### Embedder rerank timing"; echo '```'; head -n 200 "$t"; echo '```'; } | tee -a "$GITHUB_STEP_SUMMARY" || true`.
  Keep the step summary, the artifact, the `|| true` guards and the 200-line cap.
- Out of scope: any test, timeout, F1 step or `F1_TESTS` change; `api.py` (AI-9); extra rerank requests (if AI-9's sample count is ever
  too small, that is a separate ticket).

## Acceptance criteria
- [ ] AC1 — On this PR's `stack.yml` run, the job log (fetched with `gh run view <run> --log` or the jobs log API, not the UI) contains the
      `### Embedder rerank timing` header followed by the file's lines (on `main` without AI-9 that is the "no embedder rerank timing lines" line).
- [ ] AC2 — The step summary and the `stack-logs` artifact still contain `embedder-timing.log` (step's `ls -l` output in the job log).
- [ ] AC3 — No other step changes: `git diff origin/main -- .github/workflows/stack.yml` touches only that step; all CI checks green.

## Verification
```bash
gh run view <stack run id> --repo MaheshPulivarthi18/ArxivLens --log | grep -A5 'Embedder rerank timing'
git diff --stat origin/main
```

## Notes
- 2026-11-08 (pm-lead): from AI-9 QA r2 finding 1(b). After this merges, AI-9's #24 merges `origin/main` (no force-push) so its own
  `stack.yml` run prints the AI-9 timing lines; QA then re-reviews AI-9 AC1 only.
