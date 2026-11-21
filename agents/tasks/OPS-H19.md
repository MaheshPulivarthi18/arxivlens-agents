# OPS-H19: arXiv replay prefetch keeps retrying failed items until its time budget is spent

| | |
|---|---|
| **Owner** | ai-engineer (`scripts/` and `tests/` are ai-owned per AGENTS.md §2 and `.github/scripts/ownership-check.sh`; no workflow change needed) |
| **Priority** | P1 (harness: blocks Full stack runs) |
| **PRD ref** | Technical PRD §9 "External politeness" (≤ 1 arXiv request / 3 s, identifying User-Agent: unchanged), §10 Testing and evaluation (CI must be deterministic); QA RET-1e r1 finding 4 `[spec]` (`agents/reviews/RET-1e/report.md`); orchestrator cycle 05:00Z record (PROGRESS 2026-11-21) |
| **Depends on** | the replay proxy (ArxivLens #45, merged `393bcf3`). No ADR. No open PR touches `scripts/arxiv_replay.py` or `tests/test_arxiv_replay.py` (checked 2026-11-21 11:00Z against #104–#110: #107 edits `scripts/evaluate_answers.py`, `tests/test_evals_data.py`, `evals/README.md`; #110 edits `tests/test_kafka_client.py`; #106 edits `tests/test_chunk_reprocess_db.py`, `tests/test_processor_pages.py`) |
| **Jira** | needs creating: epic KAN-3 "Dev harness & infrastructure"; labels `task-OPS-H19`, `agent-ai`, `arxivlens` |
| **Design required** | no: one function's control flow in an existing CI script + unit tests; no CLI flag, table, service or contract change |
| **Status** | Ready to merge (PM APPROVE 2026-11-21 ~12:55Z; PR #111 raised) |

## Goal
The Full stack job's "Prefetch arXiv responses into the replay store" step failed six times on 2026-11-21 (#105/#106/#107, two
attempts each) before any test ran. The step has `--budget-seconds 1020` (17 min) inside a 20-min step timeout, but the script
gives up on an item after 4 attempts (waits 5/15/45 s, ~3 min) and exits 1 after ~6.5 min, leaving 10 minutes of budget unused.
Evidence (run 44870494789 attempt 1, job 136743697588): `upstream 429 for https://export.arxiv.org/api/query?id_list=2608.20331`
attempts 1–4 (05:23:55–05:26:28Z), then the search feed 429 twice and succeeded, then
`prefetch FAILED for 1: api?id_list=2608.20331` at 05:29:51Z. Later re-runs of the same heads (05:32–06:04Z) succeeded, so a
longer cool-down within the existing budget would have recovered. This ticket makes the prefetch use its whole budget.

Checked on `origin/main` `11c4696`:
- `scripts/arxiv_replay.py:101-134` `Recorder.fetch`: 4 attempts (`RETRY_WAITS = (5, 15, 45)`, `MAX_WAIT = 60`, `TIMEOUT = 120`).
- `scripts/arxiv_replay.py:264-269` `main` prefetch loop: one pass; the deadline is checked only between queries, so a query that starts
  just before the deadline can run on for several fetches (each up to `TIMEOUT` plus waits).
- Callers: `.github/workflows/stack.yml:108-109` (`timeout-minutes: 20`, `--budget-seconds 1020`) and `.github/workflows/eval.yml:91-92`
  (`timeout-minutes: 45`, `--budget-seconds 2520`). If the step is killed by its timeout, the `saved=` output is never written and the
  partial store is not saved, so the script must finish before the step timeout.
- Tests: `tests/test_arxiv_replay.py` (in `PY_LIGHT_TESTS`, `Makefile:48`), fake `Upstream` with scripted responses; the `env` fixture
  patches `INTERVAL` and `RETRY_WAITS`.

## Scope
- `scripts/arxiv_replay.py`: the prefetch path in `main` (and helpers it needs), the module docstring.
- `tests/test_arxiv_replay.py`: new tests.
- Out of scope: `.github/workflows/*` (no flag or timeout change needed; if the developer finds one is needed, stop and request a
  backend follow-up), the `serve` path and its retry behaviour, the replay store format, `Recorder.fetch`'s per-attempt politeness
  (`INTERVAL`, User-Agent), seeding a `main`-scoped cache (OPS-H13, waits on Mahesh), committing recorded responses to the repo
  (the store holds PDFs, which are forbidden in the app repo).
- Size: ~40 lines of code + ~60 lines of tests.

## Acceptance criteria
- [ ] AC1: When `--budget-seconds` > 0 and a pass ends with failed items, prefetch waits a cool-down (a module constant, e.g.
  `PASS_WAIT = 60` s, at least the last `Retry-After` seen, never past the deadline) and runs another pass over **only** the
  queries that had a failure (their already-saved feed/PDFs are hits, so they are not re-fetched). It repeats until nothing fails
  (exit 0) or the deadline passes (exit 1 with the existing `prefetch FAILED for N: ...` line naming what is still missing).
  Test: upstream scripted 429 for the `id_list` feed for more attempts than one pass makes, then 200: `main([...prefetch...,
  "--budget-seconds", "<n>"])` returns 0, the store holds the feed, and the upstream log shows the second pass requested only the
  failed query (not the query that already succeeded).
- [ ] AC2: With `--budget-seconds 0` (no limit) behaviour is unchanged: exactly one pass, exit 1 on failure. The existing
  `test_prefetch_reports_failures` still passes unmodified, and a new assert pins the request count of that one pass.
- [ ] AC3: No upstream request starts after the deadline, and no retry or cool-down sleep extends past it: a wait (politeness
  gap, retry wait or cool-down) that would reach the deadline is not taken, and the fetch it would have preceded, or any fetch
  that would start after the deadline, is skipped and reported as `(time budget)`. *(Wording amended by pm-lead 2026-11-21 after QA
  r1 `[spec]` finding 3: it said "sleeps are clipped to the time left"; skipping is stricter and wastes no wall time.)* So worst-case wall
  time is ≤ budget + `TIMEOUT` (one in-flight request): 1020 + 120 s < 20 min (stack.yml) and 2520 + 120 s < 45 min (eval.yml);
  state both sums in the docstring. Test with a fake clock (as `test_prefetch_budget_stops_early_and_reports_saved` does) and a
  recorded-sleep stub: every recorded sleep ends at or before the deadline, and no request is logged after it.
- [ ] AC4: `saved=<n>` in `$GITHUB_OUTPUT` counts everything saved across all passes (test: two passes saving 1 + 2 items →
  `saved=3`). The existing `test_prefetch_budget_stops_early_and_reports_saved` still passes unmodified.
- [ ] AC5: Politeness unchanged: every upstream fetch still goes through `Recorder.fetch` (≥ `INTERVAL` apart, same User-Agent).
  Test or grep evidence that the new loop calls no `urllib` directly.
- [ ] AC6: Mutation check (developer or QA, output in an evidence file; revert each): (m1) only one pass (old behaviour) → AC1
  test fails; (m2) cool-down not clipped to the deadline → AC3 test fails; (m3) the second pass re-runs every query → AC1's
  "only the failed query" assert fails; (m4) extra passes also when budget is 0 → AC2 fails (use a bounded fake so the test
  can't hang, e.g. a pytest timeout or a pass counter).
- [ ] AC7: CI on the draft PR: `Lint`, the light Python job (`make test-py-light`, which runs `tests/test_arxiv_replay.py`) and
  `Full stack` green. Quote the Full stack prefetch log lines (`[replay] prefetch: ... stats=...`). If arXiv happens to be
  quiet on that run, say so: the AC1/AC3 unit tests are the proof of the retry behaviour, not the CI run.
- [ ] Docs: module docstring describes the multi-pass budget behaviour; app README/CONTRIBUTING unchanged unless they describe
  the prefetch (check with `grep -n prefetch README.md CONTRIBUTING.md`).

## Verification
```bash
python3 -m pytest -q tests/test_arxiv_replay.py
make test-py-light
make lint
git diff origin/main --name-only   # exactly scripts/arxiv_replay.py and tests/test_arxiv_replay.py
```

## Notes
- 2026-11-21 11:00Z (pm-lead): specced from the Backlog P1 item. Owner is ai-engineer, not backend, because the fix lives in
  `scripts/` (ai-owned); the backend-owned `stack.yml` already passes a 17-min budget the script doesn't use. The Backlog
  alternatives (pin responses in the repo: store contains PDFs; `main`-scoped cache: OPS-H13, waiting on Mahesh) stay open.
- 2026-11-21 (ai-engineer): built on ArxivLens branch `agent/ai/OPS-H19`, commit `5b4d6a2` (not pushed; orchestrator opens
  the draft PR). Diff: `scripts/arxiv_replay.py` +77/-21, `tests/test_arxiv_replay.py` +96/-2 (196 changed lines, ownership OK).
  - Design: `Recorder(budget=)` holds the deadline; every fetch attempt, politeness gap, retry wait and the between-pass
    cool-down goes through `Recorder.budget_allows(wait)`. A wait that would reach the deadline is **not taken** (rather
    than slept up to the deadline then abandoned) and the fetch is reported `(time budget)`. That is stricter than "clipped",
    and it doesn't waste wall time. Cool-down = `max(PASS_WAIT=60, largest Retry-After seen in the pass)`, not capped by `MAX_WAIT`.
  - **Interpretation, for QA/PM:** the budget clock starts at the **first upstream request**, not at process start. The
    unmodified `test_prefetch_budget_stops_early_and_reports_saved` feeds only two `0.0` clock readings before jumping to 100.
    If the deadline were taken at start, a per-fetch deadline check (AC3) would skip that query's PDF and give `saved=1`,
    not the pinned `saved=2`. Starting the clock lazily satisfies both ACs. Cost: the seconds spent reading cached hits
    before the first miss aren't counted. The docstring states this next to the 1140 < 1200 s and 2640 < 2700 s sums.
  - Tests (new): `test_prefetch_retries_only_failed_queries_until_they_succeed` (AC1 + AC4 saved=3 + 90 s cool-down
    from Retry-After), `test_prefetch_without_budget_makes_one_pass` (AC2, request count 4),
    `test_prefetch_never_requests_or_sleeps_past_the_deadline` (AC3, fake clock + recorded sleeps, real INTERVAL/RETRY_WAITS),
    `test_prefetch_loop_fetches_only_through_recorder` (AC5). Fake `Upstream` gained exact-path scripts and an `on_request`
    hook. The `env` fixture now has a sleep guard (raises after 100 sleeps, caps real sleeps at 0.05 s), so a looping mutant
    fails instead of hanging. Without it, m4 hung the unmodified `test_prefetch_reports_failures` forever. No existing test body changed.
  - Mutants (each applied to a copy of the file, then reverted, with `pytest -q tests/test_arxiv_replay.py`): m1 single pass → 2 failed (AC1, AC3
    tests); m2 cool-down check removed → 2 failed (AC3 test + existing budget test); m3 `pending = queries` → 1 failed
    (AC1 test: request order + `"hits": 0`); m4 drop `or rec.deadline is None` → 2 failed (AC2 test + guard on
    `test_prefetch_reports_failures`). Restored: 13 passed. m3 note: B's saved feed is a hit when re-run, so the upstream log
    alone can't see m3; the AC1 test also asserts `hits == 0` and the `retrying 1 queries` line.
  - Verification run locally: `pytest -q tests/test_arxiv_replay.py` 13 passed; `pytest tests/test_evals_data.py
    tests/test_arxiv_replay.py` 155 passed, 1 skipped. Not runnable here: `make test-py-light` (`confluent_kafka` is missing
    and PyPI is blocked, so `test_worker_heartbeat.py` fails to collect); `make lint` (Go/oxlint only, nothing touched). `ruff check` on both
    files reports the same 3 findings as origin/main (EXE001, BLE001, SIM115 on lines this change doesn't touch). AC7
    (CI Lint, light job, Full stack prefetch log lines) is pending the draft PR. README/CONTRIBUTING: `grep -n prefetch` finds nothing, so unchanged.
- 2026-11-21 11:57Z (pm-lead): QA r1 PASS. **PM review held: eval check still running** (job 136830894337, in
  `make eval-seed` since 11:32Z; 15 min of polling). Evidence reviewed, all ACs covered; PR #111 stays draft. QA findings
  decided: AC3 wording amended (finding 3); follow-ups OPS-H21 (findings 1+2, ai) and OPS-H20 (finding 4, backend) in
  Backlog. Next cycle: eval green → APPROVE and raise. See `agents/reviews/OPS-H19/report.md`.
- 2026-11-21 ~12:55Z (pm-lead): **APPROVE**, PR #111 raised. The eval check on `5b4d6a2` timed out in the `make eval` step
  (30 min) on a slow EPYC 7763 runner, after the retrieval table printed with metrics identical to main. Prefetch: 0 s, warm
  store. Not caused by this PR. Re-run 136850028681 pending. Step timeout folded into OPS-H20 (now Ready). Evidence 13.
