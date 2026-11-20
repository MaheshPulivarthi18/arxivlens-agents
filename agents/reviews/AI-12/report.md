<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/73#issuecomment-7029310890 (the QA harness could not write report.md). -->

[qa-reviewer] **QA report: AI-12 · PR #73 · round 1 · Verdict: PASS**

**Reviewed commit:** `e34ebb98e25684405df86f815fa06c9fbd38e661` (CI merge commit `4d5370c` = e34ebb9 into current main `4c7d327`) · 2026-11-20
**Ticket:** `agents/tasks/AI-12.md` (KAN-76) · **PRD:** ING-4, §8 "On-demand ingest (single paper) < 60 s"
**Evidence:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/158054c12e29ed87d4f18884e4f32953f181bfc3/agents/reviews/AI-12/evidence
_The QA harness refused to write `agents/reviews/AI-12/report.md`, so this comment is the report. The orchestrator saves it verbatim._

### Test results
| Check | Source | Result |
|---|---|---|
| Go / Frontend / DB | CI jobs 136053169922 / 136053169923 / 136053169650 | pass ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/158054c12e29ed87d4f18884e4f32953f181bfc3/agents/reviews/AI-12/evidence/00-ci-checks.png?raw=true)) `` |
| Python M0 unit tests (`make test-py`) | CI job 136053169640 | pass: `190 passed, 3 skipped` ([07](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/158054c12e29ed87d4f18884e4f32953f181bfc3/agents/reviews/AI-12/evidence/07-ac7-test-py-and-names.png?raw=true)) ``` |
| Agent ownership check | CI job 136053169776 | `Ownership OK for role=ai (190 changed lines)` ([01](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/158054c12e29ed87d4f18884e4f32953f181bfc3/agents/reviews/AI-12/evidence/01-ac7-scope-numstat.png?raw=true)) ```` |
| Full stack | stack.yml run 44665352254, job 136053170077 | pass: every step green, `243 passed, 1 skipped, 3 deselected`, F1 step `3 passed` ([06](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/158054c12e29ed87d4f18884e4f32953f181bfc3/agents/reviews/AI-12/evidence/06-ac6-stack-ingest.png?raw=true)) ````` |
| Ticket verification commands | local, with stubs | The 6 new tests pass at the head with the real api.py/worker.py and stubbed torch/fastapi/psycopg/ulid/kafka/minio. 20-run loop: 20/20. ruff: 0 new issues. The 7 pre-existing torch tests were not run locally (no torch); they pass in CI. |
| `make eval` | not run | No retrieval or answering change: only object lifetimes change. |

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 reuse | ✅ | `test_ingest_builds_each_worker_once` passes locally ([02](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/158054c12e29ed87d4f18884e4f32953f181bfc3/agents/reviews/AI-12/evidence/02-ac1-ac5-new-tests-local.png?raw=true)) `````` and in CI (07). Mutants M1 (today's per-request construction), M7 and M8 (one worker left uncached) are KILLED ([03](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/158054c12e29ed87d4f18884e4f32953f181bfc3/agents/reviews/AI-12/evidence/03-mutants.png?raw=true ```````)). |
| AC2 shared model | ✅ | The sentinel test and the `None` test both pass. M3 (never pass the model) and M4 (ternary swapped) are KILLED (03). |
| AC3 injected model | ✅ | `test_embedder_worker_uses_injected_model` passes. M10 (ignore the injected model) and M11 (drop `model_name`) are KILLED (03). `main()` still calls `EmbedderWorker()`. |
| AC4 concurrency | ✅ | Real code: 20/20 pass ([05](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/158054c12e29ed87d4f18884e4f32953f181bfc3/agents/reviews/AI-12/evidence/05-ac4-20-run-loop.png?raw=true)). ```````` No-lock mutant M2: **20/20 fail, each run with both `proc_inits 2 != 1` and `no_overlap False != True`** ([04](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/158054c12e29ed87d4f18884e4f32953f181bfc3/agents/reviews/AI-12/evidence/04-ac4-lock-mutants.png?raw=true)). ````````` Extra mutant M13 (lock only around construction) fails 20/20 on `no_overlap`. M9 (a fresh lock per call) fails 20/20. |
| AC5 no poisoned cache | ✅ | First request gets 500, the slot stays `None`, and the second request rebuilds and succeeds. M5 (placeholder cached) and M6 (construction outside the `try`) are KILLED (03). |
| AC6 full stack | ✅ | Run **44665352254**. Seed step line: `{"status":"success","arxiv_id":"2608.20331","version":1,"title":"G-CARL: …","sections":69,"chunks":53,"embeddings":53}` (06) |
| AC7 CI / scope / ruff | ✅ | `make test-py` green. All 6 new tests are listed by name as PASSED in stack.yml's `-rA` output (07). Numstat: api.py 28/2, worker.py 3/2, tests/test_verify.py **155/0**, and only the 3 Scope files are touched (01). ruff: the same 12 issues at head and on main, 0 on added lines ([08](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/158054c12e29ed87d4f18884e4f32953f181bfc3/agents/reviews/AI-12/evidence/08-ac7-ruff-and-docs.png?raw=true)). `````````` |
| Docs | ✅ | The docstring lists `POST /internal/ingest` with fields that match the models. README is unchanged (08). |

### Scope / design
No design doc is required. Every changed file is in ai-engineer paths and in the ticket's Scope. The out-of-scope items (duplicated paper-id query, hard-coded `occurred_at`, processor worker, Makefile, README) are untouched. Both workers open and close their own DB connection inside `process_message`, so reusing them doesn't cache a connection that could go stale.

### PRD fit
The change serves ING-4 and the §8 single-paper ingest latency row. It removes the second BGE load and the per-call Kafka producer leak, and it changes no contract. CI can't show the gain, because it does one ingest per process from a warm cache. The Seed step took 54 s here, against 55 s on the concurrent OPS-H6b run and 73 s on AI-8b. So the speed claim rests on the unit tests.

### Findings
No blocking findings.
1. [nit] M12 (`embedder or …` instead of `is not None`) survives. It is equivalent for real inputs, so no action is needed.
2. [nit] Residual risk: the startup `embedder` is now shared between `/internal/ingest` (locked) and `/internal/embed` plus the rerank fallback (unlocked). Concurrent embed calls already shared it, and every caller uses identical tokenizer args, but no test covers concurrent embed and ingest.
3. [spec] AC6 proves only the first ingest in a fresh process. The second-call reuse path is covered only by the unit tests with fakes. Optional follow-up: have the stack ingest a second paper and log both durations.

### Missing tests (optional)
- Concurrent `/internal/embed` and `/internal/ingest` on the shared model.
- Embedder-worker construction failing while the processor slot is already cached.

### QA harness
The sources are in [09](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/158054c12e29ed87d4f18884e4f32953f181bfc3/agents/reviews/AI-12/evidence/09-harness-source.png?raw=true) ``````````` (full text in `09-harness-source.txt`). It uses a MagicMock meta-path plugin and minimal fastapi/psycopg/ulid stubs. Each mutant is a copy of the real sources in a fresh mktemp dir with one edit, and a mutant that doesn't compile counts as INVALID. Nothing was pushed to the PR branch.

**Hand-off:** PASS → pm-lead final review


---
_Generated by [Claude Code](https://claude.ai/code)_
