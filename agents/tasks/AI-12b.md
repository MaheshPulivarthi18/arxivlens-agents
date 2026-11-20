# AI-12b: Tests for `/internal/embed` during an in-flight ingest, and a failed embedder-worker build (test-only)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P2 |
| **PRD ref** | Product PRD ING-4 (on-demand ingest) and QA latency rows (§8: `/v1/ask` must not queue behind an ingest); follow-up from the AI-12 QA/PM review (`agents/reviews/AI-12/report.md`: QA nit 2 and the two missing tests, PM follow-up line 90) |
| **Depends on** | AI-12 (#73, merged `e6cffba`). No open PR touches `tests/test_verify.py` or `services/embedder/` (checked 2026-11-20 05:00Z against #65, #66, #68, #69, #70 via REST) |
| **Jira** | KAN-80 |
| **Design required** | no: two tests, no production code, contract, CLI, table or service change |
| **Status** | **Done**: merged by Mahesh, ArxivLens [#77](https://github.com/MaheshPulivarthi18/ArxivLens/pull/77) → `3835dee` (2026-11-20) |

## Goal
AI-12 made `/internal/ingest` reuse the startup-loaded embedding model and serialized the whole ingest pipeline under `_ingest_lock`
(`services/embedder/api.py:288,305`). `/internal/embed` (`api.py:229`), which `/v1/search` and `/v1/ask` call for every query, uses the
same model object **without** the lock. That's on purpose: a query must not wait behind a 30–80 s ingest. No test pins it, though,
and no test covers an `EmbedderWorker` build that fails after the `ProcessorWorker` slot is already cached. Add both tests, so a later
change that locks `/internal/embed`, or that drops and rebuilds the processor on an embedder failure, goes red.

## Scope
- Files expected to change (and only this one): `tests/test_verify.py`. Use the existing `ingest` fixture (`tests/test_verify.py:179`).
  It may gain one knob for the embedder-construction failure (e.g. `emb_init_failures`, mirroring `proc_init_failures`) and the
  matching lines in `FakeEmbedderWorker.__init__`. Those fixture lines are the only allowed deletions/edits. Every existing test function
  stays unmodified.
- Out of scope: `services/embedder/api.py`, `worker.py`, or any other production change. If a test shows current behaviour differs
  from an AC, **stop and report** in Notes, and don't change the code. Also out of scope: the `/internal/rerank` bi-encoder fallback
  (same unlocked model, different endpoint; mention in Notes if worth a row later) and `stack.yml` second-paper timing (separate Backlog line).

## Acceptance criteria
- [ ] AC1 (embed isn't serialized behind ingest): set `api.embedder` to a fake model whose `embed_texts(texts, is_query)` returns a
  `numpy` array of shape `(len(texts), 768)`. Start one `ingest_paper_endpoint` call in a thread with the fixture's `call_sleep`
  widened (e.g. 0.5 s), and wait on a `threading.Event` (or poll the fixture log) until its first `process_message` has **entered**. Then
  call `api.embed_texts_endpoint(api.EmbedRequest(texts=["q"], is_query=True))`. Assert that it returns `dim == 768` and one vector
  **while the ingest is still in progress** (`api._ingest_lock.locked()` is True at return, or the fixture log has no matching "exit"
  yet). After joining the thread, assert that the ingest returned `status == "success"`.
- [ ] AC2 (same model object): in the AC1 test, the fake `EmbedderWorker` was built with `embedder=<the same fake model object>` that
  served the embed call (identity, `is`), and that object's `embed_texts` was called by the embed endpoint (call recorded).
- [ ] AC3 (embedder build fails while processor is cached): fresh slots, embedder construction fails once. The first request
  raises `HTTPException` with `status_code == 500`. After it, `api._processor_worker` is **not None** and `ingest.proc_inits == 1`, and
  `api._embedder_worker is None`. A second request returns `status == "success"`, and the processor was still built only once
  (`proc_inits == 1`, same object as after the first request, checked with `is`). The embedder fake saw 2 construction attempts.
- [ ] AC4 (mutation, one per behaviour; QA applies each to `services/embedder/api.py` in a scratch checkout and names the failing test):
  (a) wrap the body of `embed_texts_endpoint` in `with _ingest_lock:` → the AC1 test fails. It must **fail, not hang**: use
  `join(timeout=…)` / a bounded wait so the mutant reports within 10 s.
  (b) in `_ingest_workers`, build the embedder worker before the processor, or reset `_processor_worker = None` when the embedder build
  raises (any one variant that rebuilds the processor) → the AC3 test fails on `proc_inits` or identity.
  (c) cache a placeholder in `_embedder_worker` before construction (it stays set on failure) → the AC3 test fails.
- [ ] AC5 (stable): `for i in $(seq 20); do python3 -m pytest -q -k 'ingest or embed' tests/test_verify.py || break; done` passes
  20/20 on the real code (paste the loop result). The new tests together add < 2 s to `tests/test_verify.py`.
- [ ] AC6: CI `ci.yml` job `Python M0 unit tests`, step `make test-py` passes (`tests/test_verify.py` is in `test-py`, `Makefile:49`).
  The step uses `pytest -q`, so also quote `python3 -m pytest -rA tests/test_verify.py` locally, or the `stack.yml` `-rA` lines naming
  the new tests as `PASSED` (`stack.yml` runs on `tests/**` PRs). `ruff` reports no findings on added lines. The diff touches only
  `tests/test_verify.py`, with deletions limited to the fixture lines named in Scope. The ownership check passes for role=ai.
- [ ] Docs: none (test-only). Each test's docstring says what it pins and why (embed must not wait behind ingest).

## Verification
```bash
python3 -m pytest -rA tests/test_verify.py
for i in $(seq 20); do python3 -m pytest -q -k 'ingest or embed' tests/test_verify.py || break; done   # AC5
ruff check --isolated --select E,F,W --line-length 130 tests/test_verify.py   # no findings on added lines
.github/scripts/ownership-check.sh origin/main agent/ai/AI-12b
git diff --stat origin/main && git diff --numstat origin/main
```
Importing `services.embedder.api` needs torch/transformers/fastapi (installed in CI's Python job). If the sandbox lacks them, a
scratch-only stub plugin like AI-12's is fine for local runs (say so), and CI is the source of truth. `make eval`: not run, because
nothing in retrieval or answering changes.

## Notes
- 2026-11-20 05:00Z (pm-lead): specced from the Backlog line "From the AI-12 PM review (ai, P2): … tests for concurrent
  `/internal/embed` + `/internal/ingest` on the shared startup model, and for `EmbedderWorker` construction failing while the processor
  slot is cached". Checked on app `origin/main` `e6cffba`: `_ingest_workers` (`api.py:293-301`) builds the processor first and the
  embedder second, each only if its slot is `None`. `embed_texts_endpoint` (`api.py:229-243`) takes no lock. The existing AC5 test
  `test_ingest_failed_worker_construction_is_not_cached` covers only a **processor** failure.
- PM decision (within the ticket, no contract involved): the property to pin is "embed doesn't wait for the ingest lock", not
  "embed and ingest run truly in parallel on the model". The BGE model is already shared by concurrent `/internal/embed` calls (QA AI-12
  nit 2), and a threading race on the model itself can't be shown reliably with fakes.
- The `stack.yml` second-paper timing half of the same AI-12 Backlog line is **not** in this ticket. It changes `stack.yml`
  (backend-owned) and the arXiv replay prefetch list (`--id`), so it needs its own spec.
- Independent of every open PR (#65 touches `tests/test_evals_data.py` but not `tests/test_verify.py`), and of OPS-H6c, ING-11c and LLM-1d.
- 2026-11-20 (ai-engineer): built on `agent/ai/AI-12b` @ `249ff5d` (from `e6cffba`), one file, `tests/test_verify.py` +80/-1. The only
  deletion is the fixture's `SimpleNamespace(...)` line gaining `emb_init_failures=0`; `FakeEmbedderWorker.__init__` gains the matching
  3 lines (raise after recording the attempt). No existing test function changed, no production code changed.
  - AC1+AC2 `test_embed_is_not_serialized_behind_an_in_flight_ingest`: fake model (`embed_texts` -> `np.zeros((n, 768))`) set as
    `api.embedder`; ingest in a daemon thread with `call_sleep=0.5`; poll the fixture log (bounded 5 s) for the first "enter"; embed runs in
    its own thread with `join(timeout=5)` and records `_ingest_lock.locked()` and the log's "exit" count at return. Asserts `dim == 768`,
    one 768-d vector, `{locked_at_return: True, exits_at_return: 0}`, ingest `status == "success"`, `emb_inits[0]["embedder"] is model`,
    and the model recorded the embed call `(["q"], True, ...)`.
  - AC3 `test_ingest_failed_embedder_build_keeps_cached_processor`: `emb_init_failures=1` -> first call HTTP 500, `_processor_worker`
    not None, `proc_inits == 1`, `_embedder_worker is None`; second call success, `proc_inits == 1`, same processor (`is`), 2 embedder
    construction attempts, `emb_calls == 1`.
  - AC4 mutants (scratch copies, not committed), `-k 'ingest or embed'`: (a) `embed_texts_endpoint` body under `with _ingest_lock:` ->
    only the AC1 test fails, at the `at_return` assert (`exits_at_return: 2`), run finished in 1.6 s (no hang). (b1) embedder built
    before processor -> only AC3 test fails (`_processor_worker` None). (b2) `_processor_worker = None` on embedder build failure -> only
    AC3 test fails. (c) placeholder in `_embedder_worker` before construction -> only AC3 test fails (`_embedder_worker is None`).
  - AC5: loop 20/20 pass. Durations: AC1 test 1.00 s call, AC3 test < 0.005 s (combined about 1.0 s, under 2 s).
  - AC6 local: `pytest -rA tests/test_verify.py` -> both new tests and all 8 ingest/embed tests PASSED; the 3 torch/FastAPI-router tests
    (`test_verify_pairs_...`, `test_real_nli_...`, `test_startup_handler_...`) fail only under the stubs (pre-existing, need real torch
    / FastAPI). ruff (E,F,W, 130): 3 pre-existing E501 at lines 22, 71, 126 before and after, none on added lines.
    `ownership-check.sh origin/main agent/ai/AI-12b` -> `Ownership OK for role=ai (81 changed lines)`. `make lint` is Go + frontend only;
    neither touched.
  - Local env: sandbox has no torch/transformers/fastapi/psycopg/ulid/confluent_kafka/minio (pypi blocked), so local runs used a
    scratch-only pytest plugin (`-p`, MagicMock torch etc., minimal FastAPI/HTTPException/psycopg/ulid), as for AI-12. Not verified here:
    `make test-py` in CI and the `stack.yml` `-rA` lines; CI is the source of truth. `make eval`: not run (no retrieval/answering change).
  - Possible later row (out of scope): `/internal/rerank`'s bi-encoder fallback uses the same unlocked startup model; it has no
    concurrency test either, but it's only used when the cross-encoder failed to load.
- 2026-11-20 (qa-reviewer): round 1 **PASS** at `249ff5d`. 8/8 mutants killed, CI 6/6 green, 2 nits (not blocking). See `agents/reviews/AI-12b/report.md`.
- 2026-11-20 (pm-lead): round 1 **APPROVE**. Opened every evidence file 00–08, and each AC is proven by CI with real deps (06, 08) plus QA's mutants (03). PR description rewritten with the Evidence section, PR marked ready for review. Follow-up: the `/internal/rerank` bi-encoder fallback concurrency test went to Backlog as P3, to ride with AI-5. QA nit 1 (a daemon thread can outlive the test after a failure) wasn't worth a rework round.
- 2026-11-20 08:00Z (pm-lead): the 05:00Z cycle recorded APPROVE but stopped before raising PR #77 (it was still a draft, with an empty Evidence section and PM line). Raised now: description rewritten with per-AC evidence pinned to `1428bfb`/`c5c97d3`, CI 6/6 on `249ff5d`, QA + PM verdicts; marked ready for review (`draft: false` checked by GET); label `ready-to-merge` added. The Backlog follow-up (`/internal/rerank` fallback test, P3, ride with AI-5) is on the board. See the addendum in `agents/reviews/AI-12b/report.md`.
- 2026-11-20 13:00Z (pm-lead, sync): merged (#77 `3835dee`); Status → Done.
