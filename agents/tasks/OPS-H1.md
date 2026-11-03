# OPS-H1: Run processor + embedder workers in docker-compose; one-command full test

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (unblocks every agent's ability to verify end-to-end; EVAL-3, OPS-H2, OPS-H5 AC5 and OPS-H6 AC11 wait on it) |
| **PRD ref** | Technical PRD §11 "Containerize processor + embedder in compose"; README Known limitations |
| **Depends on** | — |
| **Jira** | find with JQL `labels = "task-OPS-H1"` |
| **Design required** | **yes** (pm-lead 2026-11-03): P0, adds three compose services and a CI workflow that runs the full stack on GitHub runners. Design in `docs/design/OPS-H1.md`; pm-lead approves before code. |
| **Status** | Ready (design first) |

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
- [ ] AC5: README Quick start shows the one-command path; host-run path kept as "Apple-silicon MPS acceleration" option.
  Known-limitations bullet updated. CONTRIBUTING commands table lists `make stack-up` and the workflow.
- [ ] AC6: `stack.yml` runs on the PR itself (the paths filter includes the workflow file) and is green; link the run.
  `make lint` and `make test-unit` (CI `ci.yml`) are green. Diff < 400 changed lines.

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
