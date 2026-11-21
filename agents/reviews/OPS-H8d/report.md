# QA report — OPS-H8d · PR #110 · round 1

**Verdict:** PASS
**Reviewed commit:** `3cc94a7c9c30cee46271478ad1831a225367b172` · **Date:** 2026-11-21
**Ticket:** `agents/tasks/OPS-H8d.md` · **PRD:** Product OPS-1, OPS-3; Technical §8.1 (L4 commit-after-process); OPS-H8c QA r1 "Missing tests"

Design: not design-required (no `docs/design/OPS-H8d.md`). PR #110 is open, draft, not merged; head = `3cc94a7`.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136770341084 | pass |
| Python M0 unit tests | CI job 136770341128 (ran on merge `62e15a9` = head into `11c4696`, still current `origin/main`) | pass; step "Kafka client tests" `48 passed` |
| Frontend (lint, test, build) | CI job 136770340880 | pass |
| Agent ownership check | CI job 136770341171 | pass |
| DB (migrate twice, HNSW plan + recall) | CI job 136770340795 | pass |
| Full stack (compose + make test-full) | CI job 136770340992 | pass |
| Ticket verification: pytest -v | local, stub `confluent_kafka`/`ulid` (PyPI unreachable: `Failed to resolve 'pypi.org'`); a logic check only, CI with the real packages is the source of truth | `48 passed` |
| Ticket verification: ruff | local, ruff 0.16.9 | `All checks passed!` |
| Ticket verification: changed files | local + REST `pulls/110/files` | `tests/test_kafka_client.py` only, +53/-0 |
| `make eval` | n/a: test-only change, no retrieval/answering code | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 discovery | ✅ | `test_worker_stop_grace_period_outlasts_confirmed_flush` (tests/test_kafka_client.py:376-379). The parser finds all 9 top-level services, workers = `['embedder-worker', 'processor']`, `embedder-api` excluded ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/03-ac1-ac3-local-run.png?raw=true)). m5 (drop embedder-worker's anchor), x12 (embedder-api uses `*heartbeat_check`) and x13 (new worker service) are all killed by the set assertion ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/05-ac4-mutants.png?raw=true)). A commented `# *heartbeat_check` stays green (x11): comments are stripped. |
| AC2 duration + bound | ✅ | Per-service own 4-space key, exactly one required (lines 382-385); `kc.DELIVERY_TIMEOUT_S` imported, `POLL_S = 1.0` with a comment naming `consumer.poll(timeout=1.0)` in `ServiceKafkaConsumer.start` (true: `kafka_client.py:209`, inside `start` at :201). `Ns`/`Nms`/`NmNs` rows PASS in CI ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/02-ac5-ci-kafka-step.png?raw=true)). Missing, commented, nested-under-healthcheck, moved-to-`x-worker`, duplicated and bare `20` values all fail naming `processor` (x6-x10). Strictness: `13s` (== 12+1) fails (x3), `13100ms` and `"1m"` pass (x4, x5). |
| AC3 message | ✅ | Real messages: `embedder-worker: stop_grace_period 10.0s <= DELIVERY_TIMEOUT_S 12.0s + 1.0s poll`, `processor: stop_grace_period 13.0s <= DELIVERY_TIMEOUT_S 12.0s + 1.0s poll` ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/05-ac4-mutants.png?raw=true), 05-ac4-mutants.txt) |
| AC4 mutants m1-m5 | ✅ | All five KILLED by the new test only (`1 failed, 47 passed`), each in a fresh copy, diff printed; control on the unmutated head `48 passed` ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/05-ac4-mutants.png?raw=true)). m1 names `embedder-worker` (sorted order, the loop stops at the first failure); the AC only requires that it fails. Extra boundary checks: `19.0001` fails, `18.9` stays green (x1, x2). |
| AC5 CI -v log | ✅ | Job 136770341128 `head_sha=3cc94a7…`, step "Kafka client tests (commit-after-process, DLQ, shutdown; fakes only)" success; the log lists `test_worker_stop_grace_period_outlasts_confirmed_flush PASSED` and all 10 `test_compose_duration_parsing[...] PASSED`, `48 passed in 0.28s` ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/02-ac5-ci-kafka-step.png?raw=true), [00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/00-ci-checks.png?raw=true)) |
| AC6 ruff | ✅ | `ruff check --isolated --no-cache --select E,F,W --line-length 130 tests/test_kafka_client.py` → `All checks passed!` (whole file, so the added lines too) ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/04-ac6-ruff.png?raw=true)) |
| Docs: none | ✅ | No doc changes needed; none made. |

Scope: one file, `tests/test_kafka_client.py` (ai-owned per AGENTS.md §2), +53/-0; `ownership-check.sh` → `Ownership OK for role=ai (53 changed lines)` ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/01-scope-ownership.png?raw=true)). No `docker-compose.yml`/`kafka_client.py` edits, no PyYAML (imports only `pathlib`, `re`), no new test file, no ticket/review files in the PR.

## PRD fit
This serves OPS-1/OPS-3 and Technical §8.1. The SIGKILL-mid-flush guard from OPS-H8c is now tied to `DELIVERY_TIMEOUT_S` by a test that runs in the existing broker-free CI step. Raising the timeout, dropping or shrinking a worker's grace period, or adding a new heartbeat worker without a grace period now turns CI red.

## Findings
1. [nit] `compose_duration_s`'s full-match guard (`"".join(n + u …) != value`, line 371) isn't pinned by any parsing row. If you replace it with `not parts` (x14), every test still passes, and the mutant then accepts `20sec`→20.0, `20s5x`→20.0, `x20s`→20.0, `1h foo`→3600.0, where the head returns None ([06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/06-x14-survivor-probe.png?raw=true)). All the negative rows (`20`, `s`, `20 s`, `10x`) have zero regex matches, so they never reach that guard. The real-world risk is low: compose itself rejects such values. A row like `("20sec", None)` would pin it.

## Missing tests
- A partial-match parsing row (e.g. `20sec` or `1h foo` → None), see finding 1.

## Evidence
| File | Shows |
|---|---|
| [00-ci-checks.png](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/00-ci-checks.png?raw=true) | 6/6 check runs completed/success at `3cc94a7`; PR draft, unmerged |
| [01-scope-ownership.png](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/01-scope-ownership.png?raw=true) | diff stat, REST file list, ownership check |
| [02-ac5-ci-kafka-step.png](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/02-ac5-ci-kafka-step.png?raw=true) | CI job log: Kafka step, new tests PASSED, merge commit |
| [03-ac1-ac3-local-run.png](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/03-ac1-ac3-local-run.png?raw=true) | local -v run, discovered services and workers, values seen |
| [04-ac6-ruff.png](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/04-ac6-ruff.png?raw=true) | ruff output |
| [05-ac4-mutants.png](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/05-ac4-mutants.png?raw=true) | m1-m5 + 16 extra mutants with diffs and failure messages; control |
| [06-x14-survivor-probe.png](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/06-x14-survivor-probe.png?raw=true) | survivor x14 changes behaviour on partial-match inputs |
| [07-harness-sources.png](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f5f455637492ffec44119e226a22dc3b4b592cb2/agents/reviews/OPS-H8d/evidence/07-harness-sources.png?raw=true) | stubs, run.sh, mutate.py, probe source (full in .txt) |

## Hand-off
PASS → pm-lead final review. The nit is optional, with no rework round required.
