# OPS-H8d: Test that every Kafka worker's compose `stop_grace_period` outlasts one confirmed flush

| | |
|---|---|
| **Owner** | ai-engineer (`tests/` is shared by ai and backend per AGENTS.md §2; backend is at its WIP limit, and this ticket only reads backend-owned files) |
| **Priority** | P3 (harness/reliability) |
| **PRD ref** | Product PRD OPS-1, OPS-3; Technical PRD §8.1 (L4 commit-after-process); OPS-H8c QA r1 "Missing tests" (`agents/reviews/OPS-H8c/report.md`) |
| **Depends on** | OPS-H8c (#100, merged `3c9b133`), OPS-H8 (merged). No ADR |
| **Jira** | KAN-112 |
| **Design required** | no: one unit test reading two existing files |
| **Status** | In QA: branch `agent/ai/OPS-H8d` pushed (head `3cc94a7`), PR to be opened by the orchestrator; AC5 waits on CI |

## Goal
OPS-H8c set `stop_grace_period: 20s` on `processor` and `embedder-worker` (`docker-compose.yml:192,210`) because a worker inside a producer
`flush` can need `DELIVERY_TIMEOUT_S` (12.0 s, `services/common/kafka_client.py:21`) plus one 1 s poll (`kafka_client.py:209`). Nothing ties the
two numbers together, so raising the timeout could silently outgrow the grace and bring back SIGKILL mid-flush. Add a test that fails when it does.

## Scope
- Files expected to change: `tests/test_kafka_client.py` only (append the test(s)). It is the file CI already runs with fakes only
  (`.github/workflows/ci.yml:61-62`), so no `Makefile`/`ci.yml` change is needed. Do **not** add a new test file (it would need a backend-owned
  `Makefile` `PY_LIGHT_TESTS` change).
- Reads, never edits: `docker-compose.yml`, `services/common/kafka_client.py`.
- Parse the compose file with the standard library (no PyYAML: it isn't in `requirements-light.txt`, and CI must not depend on a transitive install).
- Not in scope: the optional `stack.yml` stop-during-flush run; changing any value.
- Size: ~40–60 lines.

## Acceptance criteria
- [ ] AC1 — **Discovery:** the test finds the Kafka-worker services as the top-level `services:` entries whose block uses the heartbeat healthcheck
  anchor (`*heartbeat_check`) and asserts that set is exactly `{"processor", "embedder-worker"}` (so a new worker service must be added on purpose,
  and an empty match fails). `embedder-api` merges `<<: *worker` but is an HTTP service with its own healthcheck; it must not be in the set.
- [ ] AC2 — For each discovered service, its own block's `stop_grace_period` is parsed as a compose duration (at least `Ns`, `Nms`, `NmNs` forms;
  an unparseable or missing value fails with the service name in the message) and asserted strictly greater than
  `kc.DELIVERY_TIMEOUT_S + 1.0` (the constant is imported, never hard-coded; the 1.0 s poll gets a comment pointing at `kafka_client.py`).
- [ ] AC3 — The failure message names the service and both numbers (e.g. `processor: stop_grace_period 20.0s <= DELIVERY_TIMEOUT_S 12.0s + 1.0s poll`).
- [ ] AC4 — **Mutation check, one mutant per case** (local only, reverted, output pasted in Notes or QA evidence): (m1) `DELIVERY_TIMEOUT_S = 19.0`
  fails (boundary: 20 > 20 is false); (m2) delete `processor`'s `stop_grace_period` line fails naming `processor`; (m3) same for `embedder-worker`;
  (m4) `embedder-worker` `stop_grace_period: 10s` fails; (m5) remove the `*heartbeat_check` healthcheck from `embedder-worker` fails AC1's set check.
  Unmutated, the new test passes.
- [ ] AC5 — CI "Python M0 unit tests" job, step "Kafka client tests", is green on the draft PR and its `-v` log lists the new test name(s) as `PASSED`.
- [ ] AC6 — `ruff check --isolated --select E,F,W --line-length 130 tests/test_kafka_client.py`: no findings on added lines (paste output).
- [ ] Docs: none.

## Verification
```bash
python -m pytest -v tests/test_kafka_client.py     # needs confluent-kafka (requirements-light.txt), no broker
ruff check --isolated --select E,F,W --line-length 130 tests/test_kafka_client.py
git diff origin/main --name-only                   # exactly tests/test_kafka_client.py
```

## Notes
- 2026-11-21 07:00Z (pm-lead): specced from the OPS-H8c QA "Missing tests" (Backlog). Owner question resolved: ai-engineer, because `tests/` is
  shared and backend has 2 active PRs. `tests/test_kafka_client.py` imports `kafka_client` with fakes only, so the M0 job needs no broker.
  Independent of open PRs: #106 edits `services/common/db.py`, `tests/test_chunk_reprocess_db.py`, `tests/test_processor_pages.py`; #107 edits
  `tests/test_evals_data.py`, `scripts/evaluate_answers.py`, `evals/README.md`; #104/#105 touch no Python. Neither `docker-compose.yml` nor
  `kafka_client.py` is changed by any open PR.
- All `<<: *worker` consumers on `11c4696` (OPS-H8c lesson): `embedder-api` (line 161), `processor` (190), `embedder-worker` (209).
- 2026-11-21 (ai-engineer): built on `agent/ai/OPS-H8d` (`1a806c2` test, `3cc94a7` E501 wrap; head `3cc94a7`). `git diff origin/main --name-only`
  = `tests/test_kafka_client.py` only, +53/-0; `ownership-check.sh origin/main agent/ai/OPS-H8d`: `Ownership OK for role=ai (53 changed lines)`.
  New tests: `test_worker_stop_grace_period_outlasts_confirmed_flush` (AC1-AC3) and `test_compose_duration_parsing` (10 cases: `20s`, `1500ms`,
  `1m30s`, quoted, plus bare `20`, empty, None, `s`, `20 s`, `10x` → unparseable). Stdlib-only line parser: top-level `services:` entries
  are 2-space keys, only the service's own 4-space `stop_grace_period:` counts (exactly one must exist), comments stripped.
  - Local runs use **stub `confluent_kafka`/`ulid` modules** in the scratchpad (sandbox has no PyPI), pytest run from `/tmp` with
    `PYTHONDONTWRITEBYTECODE=1`. CI with the real packages is the source of truth (AC5 not yet verified: no PR/CI run yet).
  - Unmutated: `48 passed`. AC6: `ruff check --isolated --select E,F,W --line-length 130 tests/test_kafka_client.py` → `All checks passed!`
  - AC4 mutants (each applied alone, reverted with `git checkout`, control re-run `48 passed` after):
    - m1 `DELIVERY_TIMEOUT_S = 19.0` → `embedder-worker: stop_grace_period 20.0s <= DELIVERY_TIMEOUT_S 19.0s + 1.0s poll` (1 failed)
    - m2 delete processor's `stop_grace_period` → `processor: stop_grace_period missing or unparseable: []` (1 failed)
    - m3 delete embedder-worker's → `embedder-worker: stop_grace_period missing or unparseable: []` (1 failed)
    - m4 embedder-worker `10s` → `embedder-worker: stop_grace_period 10.0s <= DELIVERY_TIMEOUT_S 12.0s + 1.0s poll` (1 failed)
    - m5 drop embedder-worker's `*heartbeat_check` healthcheck test line → `Kafka workers (healthcheck uses *heartbeat_check): ['processor']` (1 failed)
  - m1 names embedder-worker because services are checked in sorted order and the loop stops at the first failure (processor fails too).
  - Gotcha hit: m1 changes `12.0` to `19.0` (same size), and the revert came within the same second, so Python reused the stale `.pyc` and later
    mutant runs still saw 19.0. Rerun with `__pycache__` cleared + `PYTHONDONTWRITEBYTECODE=1`; the results above come from that clean run.
  - First commit pushed with 3 ruff E501 lines (my commit chain didn't stop on ruff); fixed in `3cc94a7`, no force-push.
