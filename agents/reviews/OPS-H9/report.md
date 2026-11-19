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

---

# Round 2 — OPS-H9 · PR #66

**Verdict:** PASS
**Reviewed commit:** `16dacb97c6c2e026b736dbfadf3b72fa643b787d` (r1 head `e875fa8`) · **Date:** 2026-11-19
**Ticket:** `agents/tasks/OPS-H9.md` (AC2 and AC3 amended by pm-lead after r1 [spec] 6) · **PRD:** Technical PRD §5, §10; Product PRD §8
**Evidence (r2):** [files 09–14](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/c59ecb49df2b7be0e590cd107b78aa120f81e2d3/agents/reviews/OPS-H9/evidence) (commit `c59ecb4`)

**Reason:** the digest check now resolves with `docker buildx imagetools inspect <name>@<digest>` and requires the registry to report the same digest. It is green on the PR head for all 3 pins, and the same digests were pulled and run healthy by `stack.yml`. The self-test only runs on pins that resolved (positive control) and requires a not-found error. QA ran the PR's real step against a fake `docker` in 8 modes: only the all-good case passes. A broken tool, an accept-everything tool, a wrong or missing digest, an unexpected error class and a missing buildx all fail the job.

## Test results (head 16dacb9)
| Check | Source | Result |
|---|---|---|
| Pinned digests resolve | CI job 135888300539 | pass: `ok` for minio-client, minio and pgvector. The zero-digest self-test got `not found` for all 3 ([10]) |
| actionlint 1.7.7 (now `@sha256:887a259a…47e9`) | step in job 135888300539 | pass, no findings ([10]). Not run locally: actionlint/shellcheck not installed |
| DB (migrate twice, HNSW plan + recall) | CI job 135888302417 | pass ([13]) |
| Full stack (compose + make test-full) | CI job 135888299617 | pass ([14]) |
| Go / Python M0 / Frontend / ownership | CI jobs 135888301278 / 135888301352 / 135888300318 / 135888300961 | pass ([09]) |
| Self-test probe with a fake `docker` (8 modes) | QA, local | the PR's step behaves as intended in every mode ([11]) |
| `buildx imagetools inspect` against cgr.dev | not run locally: the agent proxy forbids cgr.dev (`Forbidden (agent proxy…)`) | relied on CI |
| `make lint` / `make test-unit` | not run locally: no Go/Makefile change in the diff, and CI Go/Python jobs are green | n/a |
| `make eval` | not applicable (CI-only change) | n/a |

## Round-1 findings
| # | r1 finding | r2 result | Evidence |
|---|---|---|---|
| 1 [blocking] | `docker manifest inspect` reported valid cgr.dev pins as gone | **Fixed.** `resolve()` runs `docker buildx imagetools inspect <name>@<digest>` (tag dropped) and compares the reported `Digest:` with the pin. On CI, buildx v0.38.2 printed `ok` for all 3 pins. `stack.yml` pulled the same 3 digests and ran them healthy | [10], [14] |
| 2 [blocking] | Vacuous self-test (any failure passed) | **Fixed.** The real pins are checked first. Only pins that resolved are self-tested, and the error must match `not found\|manifest unknown\|404`. Fake-docker probe of the extracted step under `bash -e`: `all_good` exit 0. `one_missing` exit 1 and names `cgr.dev/chainguard/minio:latest` with "Re-pin". **`broken_all` (tool fails on every input) exit 1**: no pin resolves, so the self-test is skipped and `exit "$failed"` = 1. `accepts_all` exit 1 (the zero digest "resolved"). `wrong_digest` and `no_digest` exit 1. `zero_unauth` (401 on the zero digest) exit 1 ("unexpected error"). `no_buildx` exit 1 | [11] |
| 3 [blocking] | CONTRIBUTING verify step used the broken command | **Fixed.** The tool row (l.33) and verify step 4 (l.58) use `docker buildx imagetools inspect <name>@sha256:<digest>` and say why not `manifest inspect`. `image-pins.yml` mentions `manifest inspect` only in a comment | [12] |
| 4 [nit] | actionlint by tag | **Fixed.** Pinned `1.7.7@sha256:887a259a…`, and the pull log shows that digest | [10] |
| 5 [nit] | `version_ge` accepts non-numeric input | Not addressed. Still a nit, harmless for `extversion` | r1 [04] |
| 6 [spec] | AC2/AC3 wording | Answered by pm-lead: AC2 accepts tag + digest, and AC3 accepts a PR-triggered run | ticket |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: real_postgres tests run and pass; no `continue-on-error` | ✅ | `test_chunk_counts_sql_against_real_postgres PASSED`, `1 passed, 121 deselected`, and the skip/none-collected guard is unchanged ([13]). r1 probe [02] still applies: `db.yml` is unchanged since r1 |
| AC2: same pin in both files (tag + digest accepted); version check passes; lower version shown failing | ✅ | DB job pulled `pg16@sha256:484e8380…579f`. The dry run gives `0.5.1`/`0.7.4`/`0.7.99`/`''` -> fail, and the real `extversion '0.8.7'` gives `>= 0.8.0: ok` ([13]). image-pins verified that compose and db.yml match ([10]) |
| AC3: digest check passes for current pins on a run (PR-triggered OK); a wrong digest fails and names the image | ✅ | PR run job 135888300539: 3 × `ok`, plus a not-found self-test that names each image ([10]). The fake-docker `one_missing` mode prints `::error::Pinned image cgr.dev/chainguard/minio:latest no longer resolves … Re-pin it` and exits 1 ([11]) |
| AC4: actionlint clean; stack.yml green | ✅ | actionlint (digest-pinned) printed nothing ([10]). Full stack success ([14]) |
| AC5: runbook (re-pin + verify, ≥ 0.8.0); no README; allowed files only; < 400 lines | ✅ | 4 files (`db.yml`, `image-pins.yml`, `CONTRIBUTING.md`, `docker-compose.yml`), 151+/2−, README count 0. The runbook has re-pin steps 1–4, ≥ 0.8.0 and why ([12]). PR mergeable `clean` |

## PRD fit
HNSW/Recall checks (Technical PRD §5/§10, Product PRD §8) now run against a pgvector pin proven to be 0.8.7, and the real_postgres eval-data test runs on every DB job. The MinIO durability check now does what the ticket asks: it is green when the pins are good, red with the image name when one disappears, and red (not green) when the tool itself breaks. The PR adds no secrets, needs only `contents: read`, and uses no new registry.

## Findings (round 2)
7. **[nit]** When the tool or registry is down for every image (probe mode `broken_all`), the job fails correctly but prints "Re-pin it" for every image. If no pin resolved, a hint like "no pin resolved: check the tool/registry before re-pinning" would save a false re-pin.
8. **[nit]** The self-test's "message names the image" `case` can never fail, because `msg` is built from `${p%@*}` on the line before it. The real error line uses the same template, so the image is named in practice (probe `one_missing`). The check is just decorative.
5. **[nit]** (carried from r1) `version_ge` on non-numeric input.

No blocking findings.

## Hand-off
PASS → pm-lead for final review. Label `qa-fail` → `qa-pass`.

[09]: https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c59ecb49df2b7be0e590cd107b78aa120f81e2d3/agents/reviews/OPS-H9/evidence/09-r2-ci-checks.png?raw=true
[10]: https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c59ecb49df2b7be0e590cd107b78aa120f81e2d3/agents/reviews/OPS-H9/evidence/10-r2-f1-ac3-image-pins-green-ci.png?raw=true
[11]: https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c59ecb49df2b7be0e590cd107b78aa120f81e2d3/agents/reviews/OPS-H9/evidence/11-r2-f2-self-test-fake-docker-probe.png?raw=true
[12]: https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c59ecb49df2b7be0e590cd107b78aa120f81e2d3/agents/reviews/OPS-H9/evidence/12-r2-f3-ac5-contributing-diffstat.png?raw=true
[13]: https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c59ecb49df2b7be0e590cd107b78aa120f81e2d3/agents/reviews/OPS-H9/evidence/13-r2-ac1-ac2-db-ci.png?raw=true
[14]: https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c59ecb49df2b7be0e590cd107b78aa120f81e2d3/agents/reviews/OPS-H9/evidence/14-r2-ac4-stack-pulled-pins.png?raw=true

---

# PM review — OPS-H9 · PR #66

**Verdict:** APPROVE
**Reviewed commit:** `16dacb97c6c2e026b736dbfadf3b72fa643b787d` (head confirmed unchanged, mergeable `clean`, 7/7 check runs success) · **Date:** 2026-11-19 · **Reviewer:** pm-lead
**Read:** ticket `agents/tasks/OPS-H9.md` (AC2/AC3 as amended in ee3e0bc), Technical PRD §5 + §10, Product PRD §8, QA r1 (FAIL) + r2 (PASS), the PR diff (4 files, +151/−2), and every evidence file 00–14 (PNG + TXT).

## Evidence check (per AC)
| AC | Evidence | PM finding |
|---|---|---|
| AC1 real_postgres step runs, passes, can fail | 01, 02 (r1 head, `db.yml` unchanged since), 13 (r2 head) | Proven. `1 passed, 121 deselected` on DB job 135888302417; no `continue-on-error`; `pipefail` + the skip/none-collected guard, and QA's probe (02) shows a skip, a deselect-only run and "no tests ran" all fail the step. Stronger than the ticket asked |
| AC2 same pgvector pin in both files; version check passes; lower version shown failing | 03, 04, 13, 10 | Proven. Both files carry `pg16@sha256:484e8380…579f` (tag + digest, accepted by the amendment); CI prints `extversion '0.8.7'` → `>= 0.8.0: ok`; the dry run fails 0.5.1 / 0.7.4 / 0.7.99 / `''`. image-pins.yml also asserts compose == db.yml. 5/6 mutants killed, survivor equivalent (04) |
| AC3 digest check green for current pins on a PR run; wrong digest fails naming the image | 05, 06 (r1 failure + why it was false), 10, 11 | Proven. Job 135888300539: `ok` × 3, zero-digest self-test `not found` × 3 naming each image. QA's 8-mode fake-docker run of the real extracted step (11) is the evidence I needed that this check is now trustworthy: only the all-good case passes; a broken tool, an accept-everything tool, a wrong/missing digest, an unexpected error class and missing buildx all fail. This was the r1 blocker and it is fixed for the right reason |
| AC4 actionlint clean; stack.yml green | 07, 10, 14 | Proven. actionlint (now digest-pinned) printed nothing; Full stack job 135888299617 success and pulled the same three digests, healthy |
| AC5 runbook; no README; allowed files; < 400 lines | 08, 12 | Proven. 4 allowed files, +151/−2, README count 0. Runbook has re-pin steps 1–4 with the corrected `buildx imagetools` verify command, ≥ 0.8.0 and why (`hnsw.iterative_scan`) |

No AC rests on a "⚠ unverified" item. The only things not run locally (Go/actionlint/cgr.dev access) are covered by CI on the reviewed head.

## PRD fit and scope
- Technical PRD §5 / Product PRD §8: the Recall@5 / HNSW checks now run on a pgvector proven to be ≥ 0.8.0, and a future re-pin to an older build fails loudly in `db.yml` with the fix in the message. The EVAL-5 SQL test, previously run once in a probe, now runs on every DB job (§10).
- The MinIO durability check delivers the ticket's goal: weekly warning naming the image to re-pin before `stack.yml` breaks. Deviation from the Scope's literal "`docker manifest inspect`" is justified (QA r1 showed it rejects valid cgr.dev digests) and documented in the workflow and CONTRIBUTING; I accept it.
- Nothing extra: no secrets, `permissions: contents: read`, no new registry, no `stack.yml` edit, no README. Nothing missing.
- Docs: CONTRIBUTING updated. No PRD status row tracks OPS-H9, and §10's suite table stays true. The README "pgvector ≥ 0.8.0" line is ING-6c AC8 by design; **ING-6c is unblocked once #66 merges** (it edits `db.yml`).

## Non-blocking follow-ups (Backlog line in `agents/board.md`, backend P3)
QA nits 5 (`version_ge` passes non-numeric input; also a two-part `0.8` reads as < 0.8.0, which fails closed), 7 (print a "check the tool/registry first" hint instead of "Re-pin" when no pin resolves) and 8 (the self-test's "message names the image" `case` is tautological). Plus, from me: CONTRIBUTING says `image-pins.yml` runs weekly, but GitHub pauses schedules after 60 days without repo activity, as already noted for `eval.yml`; say the same here.

Post-merge check (not an AC): one `gh workflow run image-pins.yml` on main to confirm `workflow_dispatch` works.

## Hand-off
APPROVE → PR #66 raised (description rewritten with evidence, marked ready for review, label `ready-to-merge`). Mahesh reviews and merges.
