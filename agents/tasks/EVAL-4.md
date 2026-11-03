# EVAL-4: Record EVAL-3's first measured eval numbers in `evals/BASELINE.md`

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 |
| **PRD ref** | Product PRD §8; DoD 3 |
| **Depends on** | EVAL-3 (merged, with one completed run of `eval.yml`) |
| **Jira** | not created yet (orchestrator: story under epic "Retrieval & answer quality gates", labels `task-EVAL-4`, `agent-ai`, `arxivlens`) |
| **Design required** | no: docs-only change in `evals/` |
| **Status** | Blocked (needs EVAL-3 merged + a completed run) |

## Goal
`evals/BASELINE.md` is the reference every "`make eval` doesn't regress" check compares against, and it still says "not
run". EVAL-3 lands the workflow but can't edit `evals/` (ai-owned). This task copies the first measured numbers into it, so
the baseline is real.

## Scope
- Files: `evals/BASELINE.md` (numbers, run link, commit SHA, machine profile, ordering live = ADR-0010 pool 20) and
  `evals/README.md` "Running" (how to trigger `eval.yml`, where the artifact is).
- Out of scope: thresholds, datasets, scripts, the workflow.

## Acceptance criteria
- [ ] AC1: Every row of the `BASELINE.md` table has the value from one named `eval.yml` run (run URL + `origin/main` SHA). "not run" stays only where the gate doesn't measure the metric yet (e.g. `/v1/search` p95 before EVAL-2 AC2), with the reason.
- [ ] AC2: The numbers match the run's `evals/results/*.json` artifact exactly. QA diffs them.
- [ ] AC3: The machine profile is recorded, along with a sentence that it is the CPU-only profile (Technical PRD §9, *Proposed*) and so latency is informational until Mahesh decides.
- [ ] AC4: If any gate failed in that run, the file says so per metric. No case, corpus ID or threshold changed.

## Verification
```bash
make test-unit
gh run download <run-id> -n <artifact-name> && python3 -m json.tool evals/results/*.json
```

## Notes
- 2026-11-03 (pm-lead): split from EVAL-3 because of ownership (`.github/` is backend's, `evals/` is ai's).
