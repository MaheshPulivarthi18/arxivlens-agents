# OPS-H9: Keep the CI stack trustworthy: real-Postgres eval-data step, pgvector ≥ 0.8 pin, MinIO digest-pin check

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 (harness: every QA evidence pack depends on these workflows staying green for the right reasons) |
| **PRD ref** | Technical PRD §5 (HNSW, `hnsw.iterative_scan`), §10 (testing); Product PRD §8 (Recall@5 gate on real pgvector) |
| **Depends on** | OPS-H1, OPS-H5, EVAL-5 (merged). **EVAL-3 merged** (it may touch `docker-compose.yml` and `CONTRIBUTING.md`). Start when no open PR changes `.github/workflows/db.yml`, `docker-compose.yml` or `CONTRIBUTING.md` (README is out of scope since 2026-11-19). |
| **Jira** | new story under epic KAN-3 "Dev harness & infrastructure" (`labels = "task-OPS-H9"`) |
| **Design required** | no: P2 CI changes, no contract change |
| **Status** | **Done**: merged by Mahesh, ArxivLens [#66](https://github.com/MaheshPulivarthi18/ArxivLens/pull/66) → `050904d` (2026-11-20) |

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
- App `README.md`: **out of scope** (re-scoped 2026-11-19, see Notes). The "pgvector ≥ 0.8.0" prerequisite line moves to ING-6c AC8.
  The `CONTRIBUTING.md` runbook entry states the minimum (pgvector ≥ 0.8.0, why: `hnsw.iterative_scan`) next to the re-pin steps.
- Out of scope: mirroring images to GHCR (needs secrets and a decision), removing the F1 step (follows AI-9), the migration
  version ledger (Backlog, needs an ADR), any test change beyond running existing tests.

## Acceptance criteria
- [ ] AC1 — `db.yml` on the PR runs the `real_postgres` tests and they pass (job link); the step fails if they fail (no `continue-on-error`).
- [ ] AC2 — Both files use the same pinned pgvector image (tag, or tag + `@sha256` digest, which is stronger; the CI log shows the extension version it ships); the extension-version check passes on the PR and is shown failing against a fake lower version (a dry run of the comparison). *Amended 2026-11-19 (pm-lead, QA [spec] 6).*
- [ ] AC3 — The digest check passes for the current pins on a run of the workflow (link): a PR-triggered run is enough before merge, because `workflow_dispatch` only works once the workflow is on main. After merge, a manual or scheduled run is a post-merge check, not an AC. And a deliberately wrong digest makes it fail with the image name in the message (scratch run or step-level dry run).
- [ ] AC4 — `actionlint` clean for changed workflows; `stack.yml` still green on the PR.
- [ ] AC5 — CONTRIBUTING runbook updated (re-pin + verify steps, pgvector ≥ 0.8.0 minimum). `README.md` is not in the diff
  (`git diff --stat origin/main` lists only `.github/workflows/*.yml`, `docker-compose.yml`, `CONTRIBUTING.md`). Diff < 400 lines.
  *Amended 2026-11-19 (pm-lead): README line moved to ING-6c AC8.*

## Verification
```bash
make lint
actionlint .github/workflows/*.yml
gh run list --workflow db.yml --limit 3
gh run list --workflow <digest-check workflow> --branch agent/backend/OPS-H9 --limit 3   # PR-triggered run (dispatch needs the workflow on main)
```

## Notes
- 2026-11-07 (pm-lead): bundles merge-review follow-ups (5) `real_postgres` step, (6) pgvector ≥ 0.8, (2) Chainguard pin durability.
  All three are small and touch the same CI files, so one PR. Docker is available on GitHub runners only (no daemon in the sandbox). Wave 3.
- 2026-11-07 (pm-lead): dropped the optional `stack.yml` extension check so this ticket shares no workflow file with OPS-H10
  (`stack.yml` logs + path filter). Both edit `CONTRIBUTING.md` (different rows): whichever starts second waits for the other's merge.
- 2026-11-07 11:00Z (pm-lead, grooming): EVAL-3 merged. Not picked in cycle 11:00Z (P2, no backend slot; README + CONTRIBUTING overlap with OPS-H10).
- 2026-11-17 (pm-lead, grooming): the OPS-H10 overlap is gone (merged). #45 changed `stack.yml`/`eval.yml` (replay cache), not `db.yml` or
  `docker-compose.yml`, so the Scope still holds. The pgvector image is still the floating `pgvector/pgvector:pg16`; check before building.
- 2026-11-19 18:00Z (pm-lead, plan): re-scoped so this task shares no file with AI-8b (P0, owns the README `/v1/ask` row this cycle). The one-line
  README prerequisite "pgvector ≥ 0.8.0" moves to ING-6c AC8: ING-6c edits README and `db.yml`, so it can only start after this PR merges,
  and the pin is on main by then. Compose users get the pinned image without reading README; the minimum is also in CONTRIBUTING and in the
  `db.yml` check's failure message. AC5 amended. No change to what CI checks.
- 2026-11-19 18:11Z (backend-engineer, build): PR [#66](https://github.com/MaheshPulivarthi18/ArxivLens/pull/66) (draft). pgvector pinned by digest
  (`pg16@sha256:484e8380…`, ships 0.8.7 per main `db.yml` job 135749886659), not by a version tag: Docker Hub, cgr.dev and the pgvector GitHub repo
  are unreachable from the sandbox, so a tag couldn't be checked; `image-pins.yml` covers the pin weekly and on PRs touching the pins (a new workflow
  can't be dispatched before it's on main). The real_postgres step fails on a skip as well as a failure. Attempt 1 (`3c1dadb`): Image pins run
  44584826905 failed on shellcheck SC2001 (bundled in the actionlint docker image, absent from the local build); attempt 2 `e875fa8` fixes it.
- 2026-11-19 (pm-lead, QA [spec] finding 6): AC2 accepts tag + digest (stronger than a tag; CI shows 0.8.7). AC3 accepts a PR-triggered run, since `workflow_dispatch` can't run before merge. Verification line updated to match. No change to what CI checks.
- 2026-11-19 (backend-engineer, Rework r1 for QA FAIL r1, findings 1-3 + nit 4): head `16dacb9` (one push). `image-pins.yml` now resolves each pin as
  `<name>@<digest>` (tag dropped) with `docker buildx imagetools inspect` and requires the reported `Digest:` to equal the pin. `docker manifest inspect`
  rejected valid cgr.dev digests with "manifest verification failed". The step checks the real pins first. The self-test then runs only on images whose
  real pin resolved (positive control): the all-zero digest of each must fail with a `not found|manifest unknown|404` error, and the message must name the
  image. actionlint is pinned to `1.7.7@sha256:887a259a…47e9` (the digest from the r1 pull log). The CONTRIBUTING tool row and verify step 4 use the same
  command. The PR diff is 4 files, 151+/2-, ownership OK. CI on `16dacb9`, all success: Pinned digests resolve 135888300539 (`ok` for minio-client,
  minio and pgvector; the zero-digest self-test got `not found` for all three; actionlint printed no findings), DB 135888302417, Full stack 135888299617,
  Go 135888301278, Python M0 135888301352, Frontend 135888300318, ownership 135888300961. Not covered in r1: QA nit 5 (`version_ge` on non-numeric input)
  and [spec] 6 (pm-lead answered it in the note above).
- 2026-11-20 13:00Z (pm-lead, sync): merged (#66 `050904d`); Status → Done.
