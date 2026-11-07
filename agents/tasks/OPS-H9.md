# OPS-H9: Keep the CI stack trustworthy: real-Postgres eval-data step, pgvector ≥ 0.8 pin, MinIO digest-pin check

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 (harness: every QA evidence pack depends on these workflows staying green for the right reasons) |
| **PRD ref** | Technical PRD §5 (HNSW, `hnsw.iterative_scan`), §10 (testing); Product PRD §8 (Recall@5 gate on real pgvector) |
| **Depends on** | OPS-H1, OPS-H5, EVAL-5 (merged). **EVAL-3 merged** (it may touch `docker-compose.yml` and `CONTRIBUTING.md`). Start when no open PR changes `README.md`. |
| **Jira** | new story under epic KAN-3 "Dev harness & infrastructure" (`labels = "task-OPS-H9"`) |
| **Design required** | no: P2 CI changes, no contract change |
| **Status** | Ready (Wave 3: starts when EVAL-3 is merged) |

## Goal
Three 2026-11-07 merge-review follow-ups that each could make CI pass or fail for the wrong reason:
1. The `real_postgres` eval-data tests (EVAL-5) ran once in a probe (PR #19) and never run in CI.
2. `hnsw.iterative_scan` (shipped by OPS-H5) needs pgvector ≥ 0.8. The images use the floating tag `pgvector/pgvector:pg16`,
   so a different pull could silently lack it.
3. The Chainguard MinIO images are pinned as `latest@sha256:...`. The free registry serves `latest` only, so an old digest can
   disappear and break `stack.yml` with no warning.

## Scope
- `.github/workflows/db.yml`: a permanent step that installs psycopg and runs `pytest -q tests/test_evals_data.py -k real_postgres`
  against the migrated pgvector service (as the PR #19 probe did, job 128158303587).
- `docker-compose.yml` and `db.yml`: pin a pgvector image tag that includes pgvector ≥ 0.8 (verify the tag exists; quote the
  registry response in the PR). Add a check that fails clearly when `SELECT extversion FROM pg_extension WHERE extname = 'vector'` is
  below 0.8.0, in `db.yml` only (not `stack.yml`: OPS-H10 owns that file's next change; pm-lead 2026-11-07).
- MinIO digests: a scheduled (weekly) + `workflow_dispatch` job, or a step in an existing scheduled workflow, that resolves
  each pinned digest (`docker manifest inspect`) and fails with a "re-pin" message naming the image. Add a `CONTRIBUTING.md`
  runbook entry: how to re-pin and verify. No new registry, no secrets, no `packages: write`.
- App `README.md` prerequisites: "pgvector ≥ 0.8.0".
- Out of scope: mirroring images to GHCR (needs secrets and a decision), removing the F1 step (follows AI-9), the migration
  version ledger (Backlog, needs an ADR), any test change beyond running existing tests.

## Acceptance criteria
- [ ] AC1 — `db.yml` on the PR runs the `real_postgres` tests and they pass (job link); the step fails if they fail (no `continue-on-error`).
- [ ] AC2 — Both files use the same pinned pgvector tag; the extension-version check passes on the PR and is shown failing against a fake lower version (a dry run of the comparison).
- [ ] AC3 — The digest check passes for the current pins on a manual run (link), and a deliberately wrong digest makes it fail with the image name in the message (scratch run or step-level dry run).
- [ ] AC4 — `actionlint` clean for changed workflows; `stack.yml` still green on the PR.
- [ ] AC5 — README prerequisite and CONTRIBUTING runbook updated. Diff < 400 lines.

## Verification
```bash
make lint
actionlint .github/workflows/*.yml
gh run list --workflow db.yml --limit 3
gh workflow run <digest-check workflow> --ref agent/backend/OPS-H9
```

## Notes
- 2026-11-07 (pm-lead): bundles merge-review follow-ups (5) `real_postgres` step, (6) pgvector ≥ 0.8, (2) Chainguard pin durability.
  All three are small and touch the same CI files, so one PR. Docker is available on GitHub runners only (no daemon in the sandbox). Wave 3.
- 2026-11-07 (pm-lead): dropped the optional `stack.yml` extension check so this ticket shares no workflow file with OPS-H10
  (`stack.yml` logs + path filter). Both edit `CONTRIBUTING.md` (different rows): whichever starts second waits for the other's merge.
