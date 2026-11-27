# ING-6d: Optional compose service `crawler` (profile `crawler`) running `crawl-loop`

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 |
| **PRD ref** | Product ING-6 (optional item of the original ticket). Umbrella: [ING-6](ING-6.md) |
| **Depends on** | ING-6c **merged**; no open PR on `docker-compose.yml` or `.github/workflows/stack.yml` |
| **Jira** | to create when it leaves Backlog, `labels = "task-ING-6d"` |
| **Design required** | no (design `docs/design/ING-6.md` §5 "Compose", PM answer 4) |
| **Status** | Closed — deferred, not ticketed (2026-11-28, process reset) |

## Goal
Let an operator run the scheduled crawler with `docker compose --profile crawler up -d` instead of a host process.

## Scope
- Files: new `cmd/arxivlens/Dockerfile` (Go 1.25 build stage, static runtime image), `docker-compose.yml` (service `crawler`, **profile `crawler`**,
  not `workers`, so `make stack-up` in CI never starts it; command `crawl-loop --categories ${CRAWL_CATEGORIES:-cs.AI,cs.LG} --interval
  ${CRAWL_INTERVAL:-6h} --limit-per-run ${CRAWL_LIMIT_PER_RUN:-100}`; `stop_grace_period: 30s`; depends on `postgres` healthy and `kafka-init`
  completed), `.github/workflows/stack.yml` (one lint line `docker compose --profile crawler config --quiet`), app `README.md` (one line).
- Out of scope: running it in CI (it would call live arXiv), any `crawl-loop` change.

## Acceptance criteria
- [ ] AC1 — `docker compose --profile crawler config --quiet` passes in `stack.yml`; `docker compose config --services` without the profile does
  not list `crawler` (job log).
- [ ] AC2 — The image builds in CI (`docker build -f cmd/arxivlens/Dockerfile .`) and `docker run <image> crawl-loop --help` prints the flags.
- [ ] AC3 — README says how to start it and that it must be the only `crawl-loop` (the ING-6c lock enforces it).
- [ ] AC4 — `make test-unit`, `make lint`, `stack.yml` green.

## Verification
```bash
cd app
docker compose --profile crawler config --quiet
docker compose config --services | grep -vx crawler
docker build -f cmd/arxivlens/Dockerfile -t arxivlens-cli . && docker run --rm arxivlens-cli crawl-loop --help
```

## Notes
- 2026-11-17 (pm-lead): deferred from ING-6 (the ticket called it optional). Profile `crawler` per PM answer 4.
