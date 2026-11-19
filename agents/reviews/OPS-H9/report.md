<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/66#issuecomment-7022217266 (QA harness could not write report.md), 2026-11-19T21:13:03Z -->

[qa-reviewer] **FAIL**: OPS-H9 · PR #66 · round 1

# QA report — OPS-H9 · PR #66 · round 1

**Verdict:** FAIL
**Reviewed commit:** `e875fa8ae2fc6a18fcc096a5e564c4696a706975` · **Date:** 2026-11-19
**Ticket:** `agents/tasks/OPS-H9.md` · **PRD:** Technical PRD §5 (HNSW, `hnsw.iterative_scan`), §10 (testing); Product PRD §8 (Recall@5 gate on real pgvector)
**Evidence pack:** [agents/reviews/OPS-H9/evidence](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/23514dc08bdcf71cc4bbe99b8c5c1fafd1626694/agents/reviews/OPS-H9/evidence) (commit `23514dc`). The harness wouldn't let QA write `report.md`, so this comment is the report; the orchestrator saves it verbatim.

**Reason:** the new digest check (`image-pins.yml`, "Pinned digests resolve") fails on the current MinIO pins, and those same digests were pulled and run by `stack.yml` on the same commit. The check reports a false "re-pin", has never passed, and its self-test can't tell a missing digest from a broken tool. AC3 is not met and CI is red.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 135776032908 | pass |
| Python M0 unit tests | CI job 135776033848 | pass |
| Frontend (lint, test, build) | CI job 135776033385 | pass |
| Agent ownership check | CI job 135776033506 | pass |
| DB (migrate twice, HNSW plan + recall) | CI job 135776199582 | pass (new pgvector-version and real_postgres steps ran) |
| Full stack (compose + make test-full) | CI job 135776193851 | pass |
| **Pinned digests resolve** (new) | CI job 135776032179 | **fail**: MinIO and minio-client `manifest verification failed for digest` |
| actionlint | CI (step in job 135776032179) | pass, no findings. Not run locally: actionlint not installed in the QA sandbox |
| `make lint` / `make test-unit` | not run locally: Go 1.24 in sandbox, go.mod needs 1.25 | CI Go job green |
| `docker manifest inspect` reproduction | not run locally: no Docker daemon, and the proxy refuses cgr.dev (CONNECT 403) | n/a |
| `make eval` | not applicable (CI-only change) | n/a |

[00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23514dc08bdcf71cc4bbe99b8c5c1fafd1626694/agents/reviews/OPS-H9/evidence/00-ci-checks.png?raw=true) ``

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: real_postgres tests run and pass; the step fails if they fail | ✅ | CI: `test_chunk_counts_sql_against_real_postgres PASSED`, `1 passed, 121 deselected` ([01](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23514dc08bdcf71cc4bbe99b8c5c1fafd1626694/agents/reviews/OPS-H9/evidence/01-ac1-real-postgres-ci.png?raw=true)). ``` There's no `continue-on-error`, and `pipefail` covers `pytest \| tee`. QA probe of the PR's real guard: skipped, deselect-only and "no tests ran" summaries all fail the step ([02](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23514dc08bdcf71cc4bbe99b8c5c1fafd1626694/agents/reviews/OPS-H9/evidence/02-ac1-skip-guard-probe.png?raw=true)) ```` |
| AC2: same pin in both files; version check passes; lower version shown failing | ✅ (see [spec] 6) | Both files use `pgvector/pgvector:pg16@sha256:484e8380…579f`. CI: `extversion: '0.8.7'`, `pgvector 0.8.7 >= 0.8.0: ok`, dry run `'0.7.4' -> fail`, `'0.7.99' -> fail`, `'' -> fail` ([03](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23514dc08bdcf71cc4bbe99b8c5c1fafd1626694/agents/reviews/OPS-H9/evidence/03-ac2-pin-and-version-ci.png?raw=true)). ````` Of 6 mutants of the extracted `version_ge`, the PR's dry run killed 5. The survivor (dropping `-n`) is equivalent ([04](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23514dc08bdcf71cc4bbe99b8c5c1fafd1626694/agents/reviews/OPS-H9/evidence/04-ac2-version-probe.png?raw=true)) `````` |
| AC3: digest check passes for current pins; wrong digest fails with the image name | ❌ | The check **fails for the current pins** ([05](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23514dc08bdcf71cc4bbe99b8c5c1fafd1626694/agents/reviews/OPS-H9/evidence/05-ac3-image-pins-fail-ci.png?raw=true)). ``````` The same digests were `Pulled` and run `healthy` by stack.yml on this head ([06](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23514dc08bdcf71cc4bbe99b8c5c1fafd1626694/agents/reviews/OPS-H9/evidence/06-ac3-stack-pulled-same-digests.png?raw=true)), ```````` so this is a false positive. The wrong-digest self-test failed with the same error class as the valid pins, so it proves nothing |
| AC4: actionlint clean; stack.yml green | ✅ | The actionlint 1.7.7 step printed no findings ([07](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23514dc08bdcf71cc4bbe99b8c5c1fafd1626694/agents/reviews/OPS-H9/evidence/07-ac4-actionlint-ci.png?raw=true)). ````````` Full stack is green, and its `paths` include `docker-compose.yml` |
| AC5: runbook (re-pin + verify, ≥ 0.8.0); no README; allowed files; < 400 lines | ⚠ partly | 4 allowed files, 132+/2−, README count 0 ([08](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23514dc08bdcf71cc4bbe99b8c5c1fafd1626694/agents/reviews/OPS-H9/evidence/08-ac5-diffstat-contributing.png?raw=true)). `````````` The runbook states ≥ 0.8.0 and why (`search.go:150`). Verify step 4 uses `docker manifest inspect`, which fails for the valid MinIO pins (finding 3) |

## PRD fit
The pgvector pin, the ≥ 0.8.0 check and the always-on real_postgres step deliver what Technical PRD §5/§10 and Product PRD §8 need: the HNSW/Recall checks now run against a pgvector version that is pinned and proven to have `hnsw.iterative_scan`. The MinIO durability check does the opposite of the ticket's goal. It fails for the wrong reason, and on main it would raise a weekly false "re-pin" alarm.

## Findings
1. **[blocking]** `image-pins.yml` reports valid pins as gone. `docker manifest inspect` on `cgr.dev/chainguard/minio:latest@sha256:3c60a2a8…` and `minio-client:latest-dev@sha256:39768db4…` returns `manifest verification failed for digest`, yet `stack.yml` pulled and ran both digests about 80 s later on the same commit (job 135776193851, log lines 1208/1254/1392-1393). The Docker Hub pgvector pin passes, so the problem is the tool against Chainguard's registry, not the pins. Root cause not reproduced (no daemon/registry access here). **Fix:** resolve with a tool that handles OCI indexes, e.g. `docker buildx imagetools inspect "$1" >/dev/null` (the runbook already uses it), or `skopeo inspect --raw "docker://$1" | sha256sum` compared with the pinned digest. Then show a green "Pinned digests resolve" run on the PR head.
2. **[blocking]** The wrong-digest self-test is vacuous. It accepts *any* failure, and here the zero digest failed with the same "manifest verification failed" error as the valid pins, so a tool that fails on every input passes it. **Fix:** check the real pins first, and only self-test an image whose real pin just resolved (positive control). Then assert that the zero digest of that image fails and names it. Optionally require a not-found class error.
3. **[blocking]** CONTRIBUTING "Pinned images" step 4 (`docker manifest inspect <name>:<tag>@sha256:<digest>` exits 0) gives the same false result for the MinIO pins, so the documented verify step doesn't work for 2 of 3 images (AC5). The tool-table row (line 33) names the same command. **Fix:** use the same command as the fixed workflow.
4. **[nit]** The pin-hygiene job runs `rhysd/actionlint:1.7.7` by tag, not by digest.
5. **[nit]** `version_ge` treats non-numeric strings as ≥ 0.8.0 (`missing -> pass`, probe 04), and its `-n` guard is redundant. It's harmless for `extversion` output.
6. **[spec]** (pm-lead) AC2 says "pinned **tag**", and the PR pins tag plus digest (`pg16@sha256:…`), which is stronger, and CI proves 0.8.7. Accept the wording or amend it. AC3 says "manual run (link)", but `workflow_dispatch` can't run before the workflow is on main, so a PR-triggered run is the only possible pre-merge evidence. Amend AC3 to say so.

## Missing tests
- A positive control in `image-pins.yml`: a known-good pin must resolve before the negative self-test counts.
- A green "Pinned digests resolve" run on the PR head (required for AC3 after the fix).

## Hand-off
FAIL → back to backend-engineer (findings 1–3). pm-lead: finding 6 [spec].


---
_Generated by [Claude Code](https://claude.ai/code)_
