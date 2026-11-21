[qa-reviewer] QA report: OPS-H8c · PR #100 · round 1

**Verdict:** PASS
**Reviewed commit:** `ffe4b45f43cc090b0b39772da7e2a6cd98de4a7a` · **Date:** 2026-11-21
**Ticket:** [agents/tasks/OPS-H8c.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/OPS-H8c.md) · **PRD:** Product OPS-1, OPS-3; Technical §8.1 (L4), §8.2; OPS-H8 design review answer 2 (`docs/design/OPS-H8.md:118`, `:288-289`, `:298`)
**Evidence:** [agents/reviews/OPS-H8c/evidence](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/fa3393edb6f53fb521ab09e9166e2169591d2863/agents/reviews/OPS-H8c/evidence) @ `fa3393e`

PR state at review time: open, draft, not merged. 1 file changed (`docker-compose.yml`, +3/-0), inside backend-engineer's owned paths. CI checked out `b75f7d1` = merge of `ffe4b45` into current `origin/main` `230f617`.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI 136652664413 | pass |
| Python M0 unit tests | CI 136652664176 | pass |
| Frontend (lint, test, build) | CI 136652664493 | pass |
| DB (migrate twice, HNSW plan + recall) | CI 136652664253 | pass |
| Pinned digests resolve | CI 136652664431 | pass |
| Agent guardrails (ownership check) | CI 136652664452 | pass |
| Full stack (compose + make test-full) | CI job 136652664685, run 44842072980 | pass (`248 passed, 1 skipped, 3 deselected`; F1 step shows the 3 tracked known failures, by design) |
| Ticket verification commands | local, Docker Compose v5.7.1 + PyYAML, at `ffe4b45` | pass: only `processor` and `embedder-worker` = `20s`; `config --quiet` rc=0 with and without `--profile workers`; diff = `docker-compose.yml` only |
| `make test-unit` / `make lint` | not run locally: Go 1.25 toolchain download blocked in sandbox. CI is the source of truth | CI green (above) |
| `make eval` | not run: compose-only change, no retrieval/answering code touched | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: only `processor` and `embedder-worker` get a 20 s grace | ✅ | [01](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fa3393edb6f53fb521ab09e9166e2169591d2863/agents/reviews/OPS-H8c/evidence/01-ac1-compose-config.png?raw=true): `` `docker compose --profile workers config` per service gives `embedder-worker 20s`, `processor 20s`, the other 7 `None` (the `embedder-api` row is `None` too). [02](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fa3393edb6f53fb521ab09e9166e2169591d2863/agents/reviews/OPS-H8c/evidence/02-ac1-pyyaml-and-scope.png?raw=true): ``` the ticket's PyYAML one-liner agrees, and the diff is one file. [03](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fa3393edb6f53fb521ab09e9166e2169591d2863/agents/reviews/OPS-H8c/evidence/03-ac1-base-head-anchor-variant.png?raw=true): ```` base `230f617` has none. A variant that puts the key on the `x-worker` anchor, as the ticket's Scope says, also gives `embedder-api=20s`, which would fail AC1. So the developer's per-service placement is necessary (see Finding 1). |
| AC2: 20 s > `DELIVERY_TIMEOUT_S` 12.0 + 1 s poll; no Python change | ✅ | [04](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fa3393edb6f53fb521ab09e9166e2169591d2863/agents/reviews/OPS-H8c/evidence/04-ac2-timing-bound.png?raw=true): ````` `kafka_client.py:21 DELIVERY_TIMEOUT_S = 12.0`, `:209 poll(timeout=1.0)`, design `:113`/`:118`. The arithmetic gives 13 s with 7 s headroom. 0 `.py` files changed. The PR body states "20 s > `DELIVERY_TIMEOUT_S` 12 s + 1 s poll". |
| AC3: CI `Full stack` green, including `config --quiet` and `dc stop processor`, with step duration and run ID | ✅ | [05](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fa3393edb6f53fb521ab09e9166e2169591d2863/agents/reviews/OPS-H8c/evidence/05-ac3-fullstack-stop-timing.png?raw=true): `````` run **44842072980**, job 136652664685, `success`, head_sha `ffe4b45`. Step 5 "Lint the harness" (bash -e) runs `docker compose config --quiet`: success. Step 17 `dc stop processor`: `Stopping 00:16:45.285` → `Stopped 00:16:46.828` = **1.543 s**, well under 20 s. In Teardown (`down -v`), processor stopped in 0.82 s and embedder-worker in 1.70 s. Raw job log: [05b](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fa3393edb6f53fb521ab09e9166e2169591d2863/agents/reviews/OPS-H8c/evidence/05b-fullstack-job-136652664685.log.txt). ``````` |
| AC4: `make test-unit` / `make lint` CI jobs green | ✅ | [00](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fa3393edb6f53fb521ab09e9166e2169591d2863/agents/reviews/OPS-H8c/evidence/00-ci-checks.png?raw=true): ```````` all 7 check runs on `ffe4b45` concluded `success`. |
| Docs: none | ✅ | No README/CONTRIBUTING change. That is correct here, because no command changed. |

## PRD fit
This serves OPS-3 / Technical §8.1 L4 (commit-after-process): a worker stopped mid-`flush` now gets enough time to confirm and commit instead of being SIGKILLed, so `docker compose stop` causes fewer redeliveries and duplicates. Safety is unchanged: as before, a kill only ever produces a duplicate, never a loss. The value 20 s is the one the approved OPS-H8 design review recorded. It is not a new decision.

## Findings
1. [spec] The ticket's Scope says "add `stop_grace_period: 20s` to the `x-worker` anchor … so both workers inherit it". But `embedder-api` (`docker-compose.yml:160-161`) also merges `<<: *worker`, so the Scope as written contradicts AC1 (evidence 03 shows the anchor variant gives 3 services). The developer's deviation (the key on each of the two services, with an inline comment) is correct, and it is recorded in the ticket Notes and the PR body. pm-lead: correct the Scope line so the spec matches what ships.
2. [spec] The grace covers one `flush` plus the 1 s poll bound, as the ticket asks. The design (`docs/design/OPS-H8.md:118`) also lists a running handler call (for example an embedding batch) as uninterruptible. Handler time + flush can still exceed 20 s on the embedder-worker, and the result is then a duplicate, never a loss, which the design already accepts. No action is required for this PR. If pm-lead wants stop to be duplicate-free in that case too, it needs its own ticket with a measured batch time.
3. [nit] PR body "PRD ref" reads "OPS-H8 design review (graceful shutdown)". The ticket names Product OPS-1/OPS-3 and Technical §8.1/§8.2. pm-lead rewrites the body when raising the PR, so it can fix this then.

## Missing tests
- No automated guard ties the compose value to the code constant. If someone raises `DELIVERY_TIMEOUT_S` (or `MESSAGE_TIMEOUT_MS`), nothing fails, and the 20 s grace silently stops covering one flush. A cheap unit test (parse `docker-compose.yml`, assert each Kafka-worker service has `stop_grace_period` > `DELIVERY_TIMEOUT_S + 1`) would catch that drift. This is a suggested backlog item for backend and does not block this PR (the AC doesn't ask for it).
- CI exercises only an idle stop (1.5 s). No run shows a stop *during* a flush completing within 20 s. The AC doesn't require one, and it would need fault injection (a broker pause) in `stack.yml`.

## Hand-off
PASS → pm-lead final review.

Note: the QA harness refused to write `agents/reviews/OPS-H8c/report.md` ("subagents return findings as text"). This comment is the full report. The orchestrator saves it verbatim with a provenance note. The evidence files are committed at `fa3393e`.


---
_Generated by [Claude Code](https://claude.ai/code)_


_Provenance: saved verbatim by the orchestrator from the QA PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/100#issuecomment-7054073727 (QA harness refused to write report.md)._

---

## PM decision (pm-lead) · 2026-11-21

**Verdict: APPROVE**. Reviewed head `ffe4b45f43cc090b0b39772da7e2a6cd98de4a7a`, QA r1 PASS, evidence pinned at `fa3393e`.

I opened all seven evidence files (00–05 PNG + TXT, and the raw job log 05b):
- **Scope (02, 03):** exactly `docker-compose.yml`, +3/−0, inside backend's paths. 03 shows why the key sits on each service: with the key on the `x-worker` anchor, `embedder-api` (`:160-161`) would also get 20 s and AC1 would fail. That makes the developer's change a correct reading of AC1, not scope creep.
- **AC1 (01, 02):** `docker compose --profile workers config` (Compose v5.7.1) and the ticket's PyYAML one-liner agree. Only `processor` and `embedder-worker` are `20s`; the other 7 services, `embedder-api` included, are `None`. `config --quiet` rc=0 with and without the profile.
- **AC2 (04):** `kafka_client.py:21 DELIVERY_TIMEOUT_S = 12.0`, `:209 poll(timeout=1.0)`, and the design's bound give 20 > 13 s, with 7 s headroom. No `.py` changed, and the PR body states the numbers.
- **AC3 (05, 05b):** Full stack run 44842072980, job 136652664685 on `head_sha ffe4b45`, conclusion success. Step 5 runs `docker compose config --quiet` under `bash -e`. In the raw log, `dc stop processor` goes Stopping `00:16:45.285` → Stopped `00:16:46.828`, which is 1.54 s. I checked lines 2419/2451/2452 of 05b myself. `make test-full` gave 248 passed. The F1 failures in step 24 are the tracked known-failure step (continue-on-error), the same as on every recent run.
- **AC4 (00):** all 7 check runs on `ffe4b45` are `success`, including Go (`make lint-go`/`test-go`) and Python M0.

**Product fit:** this serves OPS-1/OPS-3 (Technical §8.1 L4, §8.2). `docker compose stop` no longer SIGKILLs a worker in the middle of a confirmed `flush`, so a routine stop causes fewer redeliveries. Safety is unchanged: a kill still costs at most a duplicate, never a loss. The value 20 s is the one from the approved OPS-H8 design review (answer 2), so it is not a new decision. No contract, threshold or command changed, so README/CONTRIBUTING and the PRD status columns (OPS-1/OPS-3 already ✅) need no edits.

**On the QA findings:**
1. [spec] Scope wording. **Fixed** in `agents/tasks/OPS-H8c.md`: the Scope now says the key goes on `processor` and `embedder-worker` directly, because `embedder-api` merges `x-worker` too. My spec error. Lesson logged: check every consumer of a YAML anchor before you spec a change to it.
2. [spec] Handler time + flush can still exceed 20 s on the embedder-worker. **Accepted, no ticket.** The ticket's goal is "one confirmed flush plus the shutdown path", and the design (`OPS-H8.md:118`) already accepts that the cost is a duplicate, never a loss. A bigger grace would need a measured embedding-batch time. If that ever matters, it will be its own ticket.
3. [nit] PRD ref in the PR body. Fixed when I raised the PR.

**Missing tests →** filed in `agents/board.md` Backlog as backend P3 **OPS-H8d**: a unit test that parses `docker-compose.yml` and asserts that each Kafka-worker service's `stop_grace_period` > `DELIVERY_TIMEOUT_S + 1`. The mid-flush stop under fault injection is noted on the same line as optional.

**Raised:** I rewrote the PR #100 description with the Evidence section, marked it ready for review and added the label `ready-to-merge`. Waiting on Mahesh to merge.
