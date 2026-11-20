<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/issues/comments/7031307026 (qa-reviewer's harness could not write report.md), 2026-11-20. -->

[qa-reviewer] QA round 1 for AI-12b: **PASS**

# QA report — AI-12b · PR #77 · round 1

**Verdict:** PASS
**Reviewed commit:** `249ff5d` (CI merge ref `4074857` = 249ff5d into current main `e6cffba`) · **Date:** 2026-11-20
**Ticket:** `agents/tasks/AI-12b.md` (Jira KAN-80) · **PRD:** Product PRD ING-4 (on-demand ingest) and §8 latency (`/v1/ask` must not queue behind an ingest)
**Evidence:** [agents/reviews/AI-12b/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/c5c97d3c753a11e08f0c8bb0f3868610261c4c8a/agents/reviews/AI-12b/evidence) (pinned to `c5c97d3`)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136098760496 | pass ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c5c97d3c753a11e08f0c8bb0f3868610261c4c8a/agents/reviews/AI-12b/evidence/00-ci-checks.png?raw=true)) `` |
| Python M0 unit tests (`make test-py`) | CI job 136098761099 | pass: `192 passed, 3 skipped`; both new tests mapped to `.` ([06](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c5c97d3c753a11e08f0c8bb0f3868610261c4c8a/agents/reviews/AI-12b/evidence/06-ac6-ci-test-py-dotmap.png?raw=true)) ``` |
| Full stack (compose + `make test-full -rA`) | CI job 136098759832 | pass: `245 passed, 1 skipped, 3 deselected`; both new tests `PASSED` by name ([08](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c5c97d3c753a11e08f0c8bb0f3868610261c4c8a/agents/reviews/AI-12b/evidence/08-ac6-ci-stack-rA.png?raw=true)) ```` |
| DB (migrate twice, HNSW) | CI job 136098758747 | pass |
| Frontend (lint, test, build) | CI job 136098760703 | pass (untouched) |
| Agent ownership check | CI job 136098760704 | pass: `Ownership OK for role=ai (81 changed lines)` |
| Ticket verification commands | local at PR head, QA scratch stub plugin for torch/transformers/fastapi/psycopg/ulid (pypi blocked; numpy, pydantic, pytest real) | pass: `-rA` 12 passed incl. both new tests; the 3 failures are pre-existing tests needing real torch / FastAPI router, green in CI ([02](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c5c97d3c753a11e08f0c8bb0f3868610261c4c8a/agents/reviews/AI-12b/evidence/02-ac1-ac3-local-rA.png?raw=true)); ````` 20/20 loop; ruff; ownership-check |
| `make eval` | not run | test-only PR, no retrieval/answering code changed (diff = `tests/test_verify.py` only) |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 embed not serialized behind ingest | ✅ | `test_embed_is_not_serialized_behind_an_in_flight_ingest` (`tests/test_verify.py:313`): fake model returns `np.zeros((n,768))`; ingest thread with `call_sleep=0.5`; bounded 5 s poll for the first `"enter"`; embed in its own thread with `join(timeout=5)`; asserts `dim == 768`, one 768-d vector, `{locked_at_return: True, exits_at_return: 0}`, ingest `status == "success"`. PASSED locally (02), in CI by name (08), dot #185 in `make test-py` (06). |
| AC2 same model object | ✅ | Same test: `ingest.emb_inits[0].get("embedder") is model` and `calls == [(["q"], True, True)]`. QA mutants d (ingest worker ignores the startup model) and e (gets a `copy` of it) both KILLED by this test ([03](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c5c97d3c753a11e08f0c8bb0f3868610261c4c8a/agents/reviews/AI-12b/evidence/03-ac4-mutants.png?raw=true)). `````` |
| AC3 embedder build fails, processor cached | ✅ | `test_ingest_failed_embedder_build_keeps_cached_processor` (`tests/test_verify.py:370`): `emb_init_failures=1` → `HTTPException` 500; `_processor_worker` not None, `proc_inits == 1`, `_embedder_worker is None`; second call success, `proc_inits == 1`, `_processor_worker is proc`, `len(emb_inits) == 2`. PASSED locally (02) and in CI (06, 08). |
| AC4 mutants | ✅ | Each in a fresh scratch copy of the PR head, anchored single substitution, mutant diff printed next to its verdict (03): (a) embed body under `with _ingest_lock:` → AC1 test FAILS in 1.6 s, no hang (`exits_at_return: 2`, `locked_at_return: False`); (b1) embedder built before processor → AC3 test fails; (b2) `_processor_worker = None` on embedder failure → AC3 test fails; (c) placeholder in `_embedder_worker` → AC3 test fails. Extra QA mutants: a2 `acquire(timeout=3)` wait-then-release → killed; b3 processor never cached → killed. **8/8 KILLED**, both with the target test alone and in the whole `-k 'ingest or embed'` set. |
| AC5 stable, < 2 s | ✅ | 20/20 loop of the ticket command ([04](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c5c97d3c753a11e08f0c8bb0f3868610261c4c8a/agents/reviews/AI-12b/evidence/04-ac5-loop20.png?raw=true)). ``````` Durations: AC1 test 1.00 s, AC3 test 0.00 s. QA extra: both new tests 20/20 with 4 CPU-burning processes on a 2-core sandbox, load avg 3.0 ([05](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c5c97d3c753a11e08f0c8bb0f3868610261c4c8a/agents/reviews/AI-12b/evidence/05-ac5-loop20-under-cpu-load.png?raw=true)), ```````` so the 0.5 s window isn't fragile on a busy runner. |
| AC6 CI + scope + ruff + ownership | ✅ | `make test-py` green; `-q` dots mapped to offline-collected ids (195 ids = 195 outcome chars, the 3 `s` land on the 3 opt-in tests, both new tests `.`) (06). `stack.yml` `-rA` names both `PASSED` (08). Diff = `tests/test_verify.py` +80/-1; the only removed line is the fixture `SimpleNamespace(...)` gaining `emb_init_failures=0`, plus 3 added lines in `FakeEmbedderWorker.__init__`; `def test_` list at head = base + the 2 new tests. ruff E,F,W/130: the same 3 pre-existing E501 (lines 22, 71, 126) at base and head, none on added lines. Ownership OK locally and in CI ([01](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c5c97d3c753a11e08f0c8bb0f3868610261c4c8a/agents/reviews/AI-12b/evidence/01-ac6-scope-ownership-ruff.png?raw=true), ````````` [00](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c5c97d3c753a11e08f0c8bb0f3868610261c4c8a/agents/reviews/AI-12b/evidence/00-ci-checks.png?raw=true)). `````````` |
| Docs | ✅ | Test-only; both new tests have docstrings saying what they pin and why. |

## PRD fit
Yes. No behaviour change; the PR pins the §8 latency property that `/internal/embed` (used by every `/v1/search` and `/v1/ask`) never waits behind an in-flight ING-4 ingest, and the retry behaviour after an embedder-construction failure. The mutants show a later change that locks embed or rebuilds the processor now goes red.

## Findings
1. [nit] AC1 test: if a regression makes the ingest thread overrun `join(timeout=5)`, the daemon thread keeps running while monkeypatch teardown restores `api._processor_worker` / `_embedder_worker` / `embedder`, so it can write into the next test's slots and cause a confusing second failure. The first failure is still reported correctly. Not blocking.
2. [nit] AC1 test re-imports `threading`/`time` locally (the fixture already does), and `def run_embed()` follows `emb = {}` with no blank line. Style only; ruff with the ticket's rule set reports nothing.

No blocking findings. No `[spec]` findings.

## Missing tests
- None required by the ticket. Out of scope (already noted by the developer): `/internal/rerank`'s bi-encoder fallback also uses the unlocked startup model with no concurrency test; a possible Backlog line for pm-lead.

## Method notes
- Local runs used a QA-written scratch pytest plugin, not the developer's; its source and the mutation, dot-map and render scripts are in [07](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c5c97d3c753a11e08f0c8bb0f3868610261c4c8a/agents/reviews/AI-12b/evidence/07-harness-source.png?raw=true) ``````````` (full text in `07-harness-source.txt`). Claims about real torch/FastAPI rest on CI (06, 08), not on the stubs.
- The `stack.yml` job's only `##[error]` is its separate known-failure F1 step (`make test-full TESTS=$F1_TESTS`, 2 failed / 1 passed, `ReadTimeout`), expected on CPU runners; the job concluded `success` (08).
- The QA harness refused to write `agents/reviews/AI-12b/report.md`; this comment is the report, to be saved verbatim by the orchestrator.

## Evidence files
00-ci-checks · 01-ac6-scope-ownership-ruff · 02-ac1-ac3-local-rA · 03-ac4-mutants · 04-ac5-loop20 · 05-ac5-loop20-under-cpu-load · 06-ac6-ci-test-py-dotmap · 07-harness-source · 08-ac6-ci-stack-rA (each `.png` + `.txt`)

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

## PM decision — pm-lead, 2026-11-20 — round 1

**Verdict: APPROVE**

Reviewed: ticket `agents/tasks/AI-12b.md`, Product PRD ING-4 (✅) and §8 latency, the PR #77 diff at `249ff5d` (`tests/test_verify.py` +80/-1, read in full), this QA report, and every file in `evidence/` at `c5c97d3` (00–08, `.png` and `.txt`).

- **PRD fit.** Test-only, no behaviour change. It pins the property users need from §8: a `/v1/search` or `/v1/ask` query (via `/internal/embed`) is served while an on-demand ingest (ING-4) holds `_ingest_lock`, and a failed model load doesn't force a processor rebuild on the retry. No PRD status column changes; ING-4 stays ✅.
- **Scope.** As specced: one file. The only edited line is the fixture `SimpleNamespace` (01), plus 3 added lines in `FakeEmbedderWorker.__init__`. No existing test changed (01's `def test_` diff = base + 2). Nothing is missing. QA's 2 extra AC2 mutants (d, e) are review work, not extra scope.
- **Evidence per AC.**
  - AC1 and AC2: the test asserts `{locked_at_return: True, exits_at_return: 0}`, 768-d output, and `emb_inits[0]["embedder"] is model`. It passes in CI with real torch/FastAPI, named in the `-rA` output (08) and as dot #185 (06). Mutants a, a2, d and e are killed (03).
  - AC3: the asserts match the spec line by line in the diff. It passes in CI (06 #186, 08). Mutants b1, b2, b3 and c are killed (03).
  - AC4: all 3 required mutants are killed. (a) fails in 1.6 s with no hang, so the bounded `join(timeout=5)` works (03).
  - AC5: 20/20 runs (04), and 20/20 again under CPU load (05). The two tests take about 1.0 s together, under the 2 s budget.
  - AC6: all 6 CI checks pass on `249ff5d` (00, rechecked by me via REST just now). Ownership, ruff on added lines and diff scope are clean (01).
  - Docs: both docstrings say what they pin and why.
- **Gaps that don't block.** Local runs used QA's stub plugin (07). That's acceptable because every AC claim that depends on real torch/FastAPI rests on CI (06, 08). The `stack.yml` `##[error]` comes from the separate known-failure F1 step, and the job concluded `success` (08).
- **QA nits.** (1) A daemon thread can outlive the test only after a regression has already failed it. (2) Style only. Neither is worth a rework round.
- **QA's Backlog suggestion** (`/internal/rerank` bi-encoder fallback uses the unlocked startup model and has no concurrency test): accepted as a P3 Backlog line. It's low value today: the fallback runs only when the cross-encoder failed to load, and ADR-0011 / AI-5 may change how that fallback is scored. It should ride with AI-5, not run as a separate task now.

Next: PR #77 is raised (description rewritten with evidence, marked ready for review) → Ready to merge, waiting for Mahesh.
