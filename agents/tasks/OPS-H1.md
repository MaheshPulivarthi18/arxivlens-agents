# OPS-H1: Run processor + embedder workers in docker-compose; one-command full test

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (unblocks every agent's ability to verify end-to-end; EVAL-3, OPS-H2, OPS-H5 AC5 and OPS-H6 AC11 wait on it) |
| **PRD ref** | Technical PRD §11 "Containerize processor + embedder in compose"; README Known limitations |
| **Depends on** | — |
| **Jira** | find with JQL `labels = "task-OPS-H1"` |
| **Design required** | **yes** (pm-lead 2026-11-03): P0, adds three compose services and a CI workflow that runs the full stack on GitHub runners. Design in `docs/design/OPS-H1.md`; pm-lead approves before code. |
| **Status** | **Blocked (needs decision: MinIO image source)** (backend-engineer 2026-11-03, rework round 1): neither MinIO-published reference pulls on the GitHub runner (R7). PR #14 stays draft at `7522eab`. After a pullable source is decided: one image-line push, then the R9 run, which is still expected to end `Blocked (needs OPS-H5 merged)`. |

## Goal
Today `make test-full` only works if someone starts three Python processes by hand. Agents can't verify pipeline or
query changes on their own. Put the workers in compose so the full stack starts with one command, and prove it on a
GitHub runner (agent sandboxes have no Docker daemon, so CI is the only place this can be verified).

## Scope
- Change: `docker-compose.yml`, `services/processor/Dockerfile`, `services/embedder/Dockerfile`, `Makefile`,
  `README.md` (Quick start `README.md:84-143`, Testing `README.md:196-218`, Known limitations `README.md:227-230`),
  `CONTRIBUTING.md` commands table (`:27` `make test-full` row, `:31` Python services line; add `make stack-up`).
  **Do not edit `README.md:39` or `CONTRIBUTING.md:50-60`** (pipeline reliability text): OPS-H6 owns those lines.
- New `.github/workflows/stack.yml` (the only way to verify AC2–AC4): triggers `workflow_dispatch` and `pull_request`
  with `paths:` limited to `docker-compose.yml`, `services/*/Dockerfile`, `requirements*.txt`, `Makefile` and the workflow
  file itself. Do **not** change `.github/workflows/ci.yml`. EVAL-3 later adds `eval.yml` and may reuse this job's steps.
- Add compose services `processor`, `embedder-worker`, `embedder-api` (port 8081) under a compose **profile** `workers`,
  so `docker compose up -d` keeps today's infra-only behaviour and `docker compose --profile workers up -d` starts everything.
- Inside the network, services use `kafka:9092`, `postgres:5432`, `minio:9000` via env vars
  (`services/common/config.py` reads `DATABASE_URL`, `KAFKA_BROKERS`, `MINIO_ENDPOINT`; no code changes expected, verify).
- Mount a named volume for the Hugging Face cache so models download once.
- Root `AGENTS.md` §6 still lists the old gotcha. Note it in this task's Notes so pm-lead updates it (pm owns AGENTS.md).
- Out of scope: GPU passthrough (document it as a note; CPU must work), Go services in compose (the workflow runs the Go
  downloader and query service on the runner host), unifying deps (OPS-H2), `make eval` (EVAL-3), any code change under
  `internal/` or `services/*/` other than the two Dockerfiles.

## Design must answer (in `docs/design/OPS-H1.md`)
1. Compose service definitions: images/build contexts, env, healthchecks (embedder API `/healthz` or equivalent), `depends_on` order, HF cache volume.
2. The `stack.yml` job, step by step: build Go, `make stack-up`, wait for health (with a timeout), `migrate`, start
   `arxivlens download` and the query service in the background, crawl, poll status, run `make test-full`, always dump
   `docker compose logs` on failure. Job timeout; caching of HF models and pip; expected runtime.
3. arXiv politeness in CI: total requests per run (crawl `--limit 2` plus anything the suites fetch), ≤ 1 req / 3 s, identifying User-Agent.
4. What data the M1–M4 suites need (e.g. `tests/test_m3_query.py:70` asks for paper `2608.20331`) and how the job provides it.
   If a suite fails for a reason unrelated to compose (a hard-coded fixture, a pre-existing bug), the design says so;
   the build then reports it (log + follow-up request in Notes) instead of editing or skipping the test.
5. Test plan: which CI step proves each AC.

## Acceptance criteria
- [ ] AC1: `docker compose up -d` behaves exactly as before (infra only). Proven in the workflow: `docker compose ps --services`
  after a plain `up -d` lists only the infra services (paste the CI step output).
- [ ] AC2: `make stack-up` (new target) runs `docker compose --profile workers up -d --build` and all services become
  healthy; the embedder API has a healthcheck. Proven by the workflow's `docker compose ps` step.
- [ ] AC3: With the stack up, `./bin/arxivlens crawl --query "cat:cs.LG" --limit 2` results in both papers reaching status
  `embedded` (the workflow prints `arxivlens status`; paste it in the PR).
- [ ] AC4: `make test-full` passes M1–M4 against the compose stack in the workflow (paste the pytest summary). How the Go
  query service and downloader are started is documented in README/CONTRIBUTING. A failure caused by something outside
  this task: stop and report per design item 4; never weaken or skip a test.
  The pasted summary is the full, unfiltered `make test-full` run. Until OPS-H5 merges, the only allowed failure is
  `tests/test_m5_m6_telemetry_eval.py::test_pgvector_hnsw_index_presence_and_querying` (missing `chunk_embeddings_hnsw_idx`).
  Any other failure in any suite is a finding to report.
- [ ] AC5: README Quick start shows the one-command path; host-run path kept as "Apple-silicon MPS acceleration" option.
  Known-limitations bullet updated. CONTRIBUTING commands table lists `make stack-up` and the workflow.
- [ ] AC6: `stack.yml` runs on the PR itself (the paths filter includes the workflow file) and is green; link the run.
  `make lint` and `make test-unit` (CI `ci.yml`) are green. Diff < 400 changed lines.
  "Green" means the whole job, M5/M6 included. With the known HNSW failure the PR stays draft and the task is
  `Blocked (needs OPS-H5 merged)`. After OPS-H5 merges, rebase and rerun, and only then go to QA.
- [ ] AC7: `make setup-py` installs `opentelemetry-sdk`, so `make test-full` collects every suite, and `stack.yml` installs
  host deps only through `make setup-py`.

## Verification
```bash
make lint
actionlint .github/workflows/stack.yml          # or: docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint
docker compose config --profiles                 # lists "workers" (works without a daemon)
# In CI (stack.yml), link the run in the PR:
make stack-up && docker compose ps
go build -o bin/arxivlens ./cmd/arxivlens && ./bin/arxivlens migrate
./bin/arxivlens crawl --query "cat:cs.LG" --limit 2 && ./bin/arxivlens status
make test-full
```
Agent sandboxes have the Docker CLI but no daemon: AC1–AC4 are proven only by the `stack.yml` run on the PR.

## Notes
- 2026-11-03 (pm-lead, RET-1 PM review): once EVAL-1 (#2) and RET-1 (#9) are on `main`, the AC4 full-stack run should also run `make eval` and paste the `/v1/ask` p95. That's the first real measurement of the 20-candidate rerank pool. It's owned by EVAL-2 AC10; whichever task first has a working stack reports it.
- 2026-11-03 (pm-lead): the p95/eval measurement above now belongs to **EVAL-3 AC6** (GitHub Actions eval workflow, depends on this task), no longer EVAL-2 AC10. OPS-H1 AC4 doesn't need to run `make eval`. Keep `make stack-up` scriptable and non-interactive, because EVAL-3 calls it from CI.
- 2026-11-03 14:00 cycle (pm-lead): deferred for six cycles because nothing could run Docker. GitHub runners can, so the
  task now ships its own verification (`stack.yml`, AC6) and is design-required (P0 + CI workflow, per the task template).
  Started in parallel with OPS-H6: OPS-H1 must not touch `README.md:39`, `CONTRIBUTING.md:50-60`, `internal/` or `ci.yml`.
- 2026-11-03 (pm-lead, design gate): design APPROVED with 8 binding conditions (see the design's "PM decision").
  Decisions: build now and block on OPS-H5 for the green run; `opentelemetry-sdk` goes in `make setup-py` (AC7);
  `.dockerignore` is a follow-up, with a README note for now. Follow-ups in the board Backlog: arXiv politeness for the
  downloader and ingester, verifying the `2608.20331` fixture, `.dockerignore` plus its allow-list rules PR, and the
  AGENTS.md §6 workers gotcha (pm-lead rules PR after merge).
- 2026-11-03 (backend-engineer, build): branch `agent/backend/OPS-H1`, head `bb5ce42`, **draft PR #14**
  (https://github.com/MaheshPulivarthi18/ArxivLens/pull/14). 7 files, 343+/25− (ownership-check: `Ownership OK for role=backend (368 changed lines)`).
  - `ci.yml` run 41652931263: Go, Python M0, Frontend and Agent ownership all **success** (so `make lint` / `make test-unit` green).
  - `stack.yml` run 41652931431 (https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/41652931431), attempt 1 (job 125975570178)
    and attempt 2 = one rerun to rule out flakiness (job 125978544535): **both failed at the AC1 step** (`docker compose up -d`) with the
    same error. That's before any OPS-H1 service starts, so `make test-full` **never ran** (no pytest summary exists):
    ```
    Image minio/mc:latest Error pull access denied for minio/mc, repository does not exist or may require 'docker login'
    Image minio/minio:latest Interrupted
    Error response from daemon: pull access denied for minio/mc, repository does not exist or may require 'docker login'
    ##[error]Process completed with exit code 1.
    ```
    Other Docker Hub pulls on the same runner work (`rhysd/actionlint:1.7.7` pulled in step 5), so this is the image, not the
    runner. It is a **pre-existing break of the infra stack on `main`** (`minio-init` service, `image: minio/mc:latest`): plain
    `docker compose up -d` / `make infra-up` fails for everyone. `minio/minio:latest` was interrupted, not refused, so whether it
    still pulls is **unverified** (the sandbox can't reach Docker Hub: proxy 403).
  - **Why I stopped instead of fixing it:** the fix is a change to an infra service block, and binding condition 1 requires those
    blocks to stay byte-identical. A workflow-only pre-pull and retag (e.g. from another registry) would turn AC1 green while
    `make infra-up` stayed broken for developers, so I didn't do that either. **Decision needed (pm-lead / Mahesh):** either
    allow OPS-H1 to change the `minio-init` (and, if needed, `minio`) image to a pullable, pinned source (e.g. `quay.io/minio/mc`,
    after someone checks it exists), or open a separate backend task for it that OPS-H1 depends on. The second run of this task
    should then be the first that reaches AC2–AC4.
  - Verified by the runs so far: step "Lint the harness" passed (actionlint 1.7.7 on `stack.yml`, `docker compose config --quiet`,
    `--profiles` = `workers`). `make setup-py` installed `opentelemetry-sdk-1.45.2` and `torch-2.15.0+cpu` (AC7). Pre-fetch and Go build passed.
    Diagnostics, artifact upload and teardown ran on failure.
  - **Not verified (blocked by the above):** AC1 output, AC2 `ps -a` health, worker consumer-group healthcheck (binding condition 3:
    still the group check, no fallback yet), AC3 crawl → `embedded`, fixture ingest (D1/D3), `make test-full` (D2, M5 HNSW).
  - AC5 docs are done in the PR. `README.md:39` and `CONTRIBUTING.md:50-60` are unchanged. In `docker-compose.yml` the diff adds lines only.
  - One small deviation from design step 12, recorded in the design: `arxivlens dlq list` is printed, but the "DLQ empty" assertion
    uses `kafka-get-offsets.sh` end offsets, because `dlq list` gives up after a 1 s / 2 s poll and can report 0 on a slow first fetch.
  - For pm-lead (per Scope): root `AGENTS.md` §6 still says "Processor and embedder workers are not yet in `docker-compose.yml`
    (OPS-H1)". Update it in the rules PR after merge.
  - Not run locally: `make lint` / `make test-unit` (sandbox Go 1.24, no PyPI/HF), actionlint (not installed), and anything that
    needs a Docker daemon. Locally checked: `docker compose config` (5 services without the profile, 8 with it), `make -n stack-up`,
    and `bash -n` on every workflow `run:` block.
- 2026-11-03 (pm-lead, unblock decision): **option (a)**. OPS-H1 fixes the image itself, with no separate task. Binding condition 1 is
  amended (design "PM decision", addendum 2026-11-03): only the `image:` line of `minio-init`, and of `minio` if needed, may change
  in the infra blocks. Scope now includes that change. No file overlap with OPS-H6 (#15: `internal/kafka/`, `ci.yml`).
  **Rework checklist (QA checks each item):**
  - [x] R1: Rebase `agent/backend/OPS-H1` on current `origin/main`. Keep PR #14 in **draft**.
  - [x] R2: Replace `minio/mc:latest` with a **pinned** image that MinIO publishes (e.g. a `RELEASE.*` tag of `quay.io/minio/mc`,
        or the same pinned `quay.io/minio/minio` server image, which ships `/usr/bin/mc`). No `latest`, no third-party mirror.
        A digest is preferred.
  - [x] R3: Change the `minio` `image:` line only if it fails to pull, lacks `mc` (the healthcheck runs `mc ready local`), or you
        reuse it for `minio-init`. Say which case applies in the PR.
  - [x] R4: No other infra-block edits: `git diff origin/main -- docker-compose.yml` evidence shows at most those two lines
        changed inside the infra blocks.
  - [x] R5: `stack.yml` has no pre-pull, retag, `docker login` or mirror workaround, and doesn't reference a MinIO image directly.
  - [ ] R6: Prove that the image exists in the next `stack.yml` run: AC1 step log shows the pinned reference `Pulled`, AC2
        evidence includes `docker compose images` (or `RepoDigests`) for minio + minio-init, `minio` `(healthy)` and
        `minio-init` `Exited (0)`.
  - [x] R7: If no MinIO-published image pulls: stop, `Blocked (needs decision: MinIO image source)`, list the references you
        tried with their errors. Don't switch S3 servers.
  - [x] R8: PR description gets a "Fixes on `main`" line (old and new reference; `make infra-up` was broken for everyone).
  - [ ] R9: Then continue the original plan: AC1–AC4 evidence from the run, full unfiltered `make test-full` summary (only allowed
        failure: the M5 HNSW test), diff < 400 lines, then `Blocked (needs OPS-H5 merged)` per design decision 1.
- 2026-11-03 (backend-engineer, rework round 1): **Blocked (needs decision: MinIO image source).** No MinIO-published image pulls.
  Branch `agent/backend/OPS-H1` `bb5ce42` → `5896745` → **`7522eab`**, PR #14 still **draft**. 2 files touched this round
  (`docker-compose.yml`: 2 image lines; `.github/workflows/stack.yml`: +6 lines of AC2 image/digest evidence). Ownership check:
  `Ownership OK for role=backend (378 changed lines)`.
  - R1: `origin/main` is still `9c1229a` (the branch base), so the rebase was a no-op.
  - R2/R3: both `minio` and `minio-init` use **one pinned MinIO server image** (R3 case: *reuse*, because the server image ships
    `/usr/bin/mc` and `/bin/sh`, so the unchanged `entrypoint` and `mc ready local` healthcheck still work). No digest:
    the sandbox can't reach quay.io or Docker Hub (proxy 403), so the AC2 step was set up to print the digest.
  - **Attempt 1** `quay.io/minio/minio:RELEASE.2025-04-22T22-12-26Z`: stack.yml run 41670021121, job 126035577598, failed at AC1:
    ```
    Image quay.io/minio/minio:RELEASE.2025-04-22T22-12-26Z Error unknown: failed to resolve reference "quay.io/minio/minio:RELEASE.2025-04-22T22-12-26Z": unexpected status from HEAD request to https://quay.io/v2/minio/minio/manifests/RELEASE.2025-04-22T22-12-26Z: 401 UNAUTHORIZED
    ```
    (Anonymous quay returns 401 for a missing or private *repository*; a missing tag in a public repo would be 404. So
    `quay.io/minio/mc` is very likely in the same state. I didn't try it, because only 2 image pushes were allowed.)
  - **Attempt 2** `minio/minio:RELEASE.2025-04-22T22-12-26Z` (MinIO's own Docker Hub repo): stack.yml run 41670533303, job 126037375691, failed at AC1:
    ```
    Image minio/minio:RELEASE.2025-04-22T22-12-26Z Error pull access denied for minio/minio, repository does not exist or may require 'docker login'
    Error response from daemon: pull access denied for minio/minio, repository does not exist or may require 'docker login'
    ```
    **New finding:** the `minio/minio` *server* repo is gone from Docker Hub too (not only `minio/mc`). So on `main`
    `minio/minio:latest` is broken as well, and `make infra-up` can't start MinIO at all.
  - ci.yml on both heads is green: run 41670021062 (5896745) and run 41670533256 (7522eab). Go, Python M0, Frontend and Agent
    ownership all `success`. In stack.yml every step before AC1 passed both times (actionlint, `compose config`, `make setup-py`,
    pre-fetch, Go build). Diagnostics, artifact and teardown ran.
  - R4: `git diff origin/main -- docker-compose.yml` changes exactly 2 lines inside the infra blocks
    (`-image: minio/minio:latest` / `-image: minio/mc:latest` → `+image: minio/minio:RELEASE.2025-04-22T22-12-26Z` ×2); every other change is an added line.
  - R5: `stack.yml` has no pre-pull, retag, login or mirror, and names no MinIO image. The evidence loop reads the image from the containers.
  - R6: **not met**. The AC2 step now prints `docker compose images minio minio-init` and each container's `RepoDigests`, but AC1
    never got past the pull, so no `Pulled`, `(healthy)` or `Exited (0)` exists.
  - R7: done. Stopped after 2 references, no S3-server switch.
  - R8: PR body has a "Fixes on `main`" section listing the old refs, both attempted refs with errors and run links, and the blocked status.
    Note: after my PATCH something rewrote the PR footer to end with `---` / `_Generated by [Claude Code](https://claude.ai/code)_`
    (the session URL line stayed). It wasn't from my request body.
  - R9: **not reached**. AC1–AC4 have no evidence and `make test-full` never ran (no pytest summary).
  - **Decision needed (pm-lead / Mahesh):** where the S3 image comes from. Options: (a) a MinIO-published reference someone has
    confirmed pulls anonymously (e.g. a specific `quay.io/minio/mc` or `quay.io/minio/minio` tag, or a digest from a registry
    MinIO documents now). Check with `docker manifest inspect` from a machine with registry access. (b) Build MinIO from source in
    compose. (c) Another S3-compatible server, which is Mahesh's call per the addendum. Whatever is chosen should also update
    `README`/area notes, since `make infra-up` is broken on `main` for everyone today.

