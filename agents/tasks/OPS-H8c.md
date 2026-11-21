# OPS-H8c: Compose `stop_grace_period` for the workers so one confirmed flush fits before SIGKILL

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 (reliability) |
| **PRD ref** | Product PRD OPS-1, OPS-3; Technical PRD §8.1 (L4 commit-after-process), §8.2; follow-up from the OPS-H8 design review (`docs/design/OPS-H8.md:118-119,288-289,298`, PM answer 2) |
| **Depends on** | OPS-H8 (merged), OPS-H1 (workers in compose, merged). No open PR touches `docker-compose.yml` (checked 2026-11-21 00:00Z: #91–#98 file lists) |
| **Jira** | to be created by the orchestrator (epic KAN-3 "Dev harness & infrastructure"; labels `task-OPS-H8c`, `agent-backend`, `arxivlens`; link KAN-34) |
| **Design required** | no: one compose key on the existing `x-worker` anchor; the value comes from the approved OPS-H8 design |
| **Status** | Ready (picked 2026-11-21 00:00Z) |

## Goal
On `docker compose stop`, a worker that is inside a producer `flush` (up to `DELIVERY_TIMEOUT_S = 12.0`,
`services/common/kafka_client.py:21`) can outlast Docker's default 10 s stop grace. It then gets SIGKILLed before it commits, and
the record is redelivered as a duplicate. Give the processor and embedder workers a 20 s grace, so one confirmed flush plus the
shutdown path fits.

Checked on `origin/main` `230f617`: `docker-compose.yml` has no `stop_grace_period` anywhere. `processor` (`:189`) and
`embedder-worker` (`:205`) both merge `<<: *worker` (anchor `x-worker`, `:5-18`).

## Scope
- `docker-compose.yml`: add `stop_grace_period: 20s` to the `x-worker` anchor (with a one-line comment that cites `DELIVERY_TIMEOUT_S` 12 s and the 10 s default), so both workers inherit it.
- Out of scope: `kafka_client.py` (timeouts unchanged), infra services, `embedder-api`, `stack.yml`, README/CONTRIBUTING (no command changes; README is held by #93 anyway).
- Size: ~3 lines.

## Acceptance criteria
- [ ] AC1: The resolved config gives `processor` and `embedder-worker` a 20 s grace, and no other service gets one. Check with `docker compose --profile workers config` (Docker normalises it to `stop_grace_period: 20s`) or, without Docker, with the PyYAML one-liner in Verification. Paste the output into an evidence file.
- [ ] AC2: 20 s > `DELIVERY_TIMEOUT_S` (12.0 at `services/common/kafka_client.py:21`) + 1 s poll bound (`docs/design/OPS-H8.md:113`). Note the numbers in the PR body. No Python change.
- [ ] AC3: CI `Full stack` (`stack.yml`, triggered by the `docker-compose.yml` path filter) is green on the draft PR, including `docker compose config --quiet` (`stack.yml:69`) and the `dc stop processor` step (`stack.yml:210`). Quote that step's duration from the run. It should stay well under 20 s, since an idle worker exits within about 1 s. Quote the run ID.
- [ ] AC4: `make test-unit` / `make lint` CI jobs are green.
- [ ] Docs: none. Optional: if `docs/design/OPS-H8.md` needs a "done in OPS-H8c" note, pm-lead adds it here (not the developer).

## Verification
```bash
docker compose --profile workers config | grep -n -B30 'stop_grace_period'   # CI / any host with Docker
python3 -c "import yaml; s=yaml.safe_load(open('docker-compose.yml'))['services']; print({k: v.get('stop_grace_period') for k, v in s.items()})"
git diff origin/main --name-only   # exactly docker-compose.yml
```

## Notes
- 2026-11-21 00:00Z (pm-lead): the OPS-H8 design review filed this as a Backlog item (backend P3, after OPS-H8 merges). It is still open on `230f617`. The value 20 s is the one recorded in the approved design review, so it is not a new decision.
