_Provenance: saved verbatim by the orchestrator from ArxivLens PR #111 comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/111#issuecomment-7062046139 (the qa-reviewer harness refused to write report.md)._

[qa-reviewer] QA report: OPS-H19 · PR #111 · round 1

**Verdict:** PASS
**Reviewed commit:** `5b4d6a232ff97f706f3688f186361987050ea8ed` · **Date:** 2026-11-21
**Ticket:** `agents/tasks/OPS-H19.md` · **PRD:** Technical PRD §9 "External politeness", §10 Testing and evaluation; QA RET-1e r1 finding 4 `[spec]`
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) (incl. `make lint-go`) | CI | success ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/00-ci-checks.png?raw=true)) `` |
| Python M0 unit tests (incl. `make test-py-light`: 161 passed, 1 skipped) | CI | success ([07](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/07-ac7-ci-py-light.png?raw=true)) ``` |
| Frontend (lint, test, build) / Agent ownership / DB | CI | success |
| Full stack (compose + make test-full) | CI | success: prefetch from a cold store, then `275 passed, 1 skipped` ([10](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/10-ac7-fullstack-prefetch.png?raw=true)) ```` |
| eval | CI | still running when this report was written (in `make eval-seed`). Its prefetch step, the only one that runs changed code, already succeeded ([12](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/12-eval-run-steps.png?raw=true)). ````` The ticket doesn't gate on this job, see finding 4 |
| `pytest -q tests/test_arxiv_replay.py` | local | 13 passed ([01](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/01-ac1-ac5-unit-tests.png?raw=true)) `````` |
| `make test-py-light`, `make lint` | not run locally (Go 1.25 toolchain download blocked, no npm) | CI green |
| diff = exactly the 2 files; ruff | local | yes; same 3 ruff findings as origin/main, none on new lines ([06](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/06-scope-docs-ruff.png?raw=true)) ``````` |
| `make eval` | not applicable (harness script, no retrieval/answering change) | — |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 multi-pass over failed queries only | ✅ | `test_prefetch_retries_only_failed_queries_until_they_succeed`: request log `[a]*4 + [b] + [a]*2 + [x.pdf]` (pass 2 asks only for A), store holds A's feed, exit 0, one 90 s cool-down (Retry-After > PASS_WAIT). Mutants m1, m3, q4, q6, q9 are killed by it ([01](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/01-ac1-ac5-unit-tests.png?raw=true), ```````` [02](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/02-ac6-mutants.png?raw=true)) ````````` |
| AC2 budget 0 → one pass | ✅ | `test_prefetch_without_budget_makes_one_pass` pins 4 requests. The `test_prefetch_reports_failures` body is unchanged (only the shared `env` fixture gained a sleep guard). m4 is killed by both |
| AC3 no request or sleep past the deadline | ✅ (with a test gap, finding 1) | `test_prefetch_never_requests_or_sleeps_past_the_deadline` (fake clock, real INTERVAL/RETRY_WAITS): every sleep ends ≤ deadline, every request starts < deadline, `(time budget)` reported. Kills m2, q1, q5. Docstring states 1140<1200 and 2640<2700. A QA scenario test shows the code also handles an in-flight request that overruns the deadline ([04](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/04-ac3-overrun-scenario.png?raw=true)) `````````` |
| AC4 `saved=` across passes | ✅ | AC1 test: `saved=3`. `test_prefetch_budget_stops_early_and_reports_saved` unchanged and passing. q8 (deadline at process start) breaks it, which matches the developer's lazy-clock note |
| AC5 politeness unchanged | ✅ | `urlopen` appears only in `Recorder.fetch` (line 143), with the same User-Agent. The new loop only calls `prefetch_query` → `get_or_fetch` → `rec.fetch` ([05](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/05-ac5-politeness-grep.png?raw=true)). ``````````` There is also a source-inspection test and a User-Agent assert |
| AC6 mutants m1–m4 | ✅ | All four are killed, each on a temp copy with the PR checkout left clean ([02](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/02-ac6-mutants.png?raw=true), ```````````` definitions [03](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/03-ac6-mutant-definitions.png?raw=true)). ````````````` QA extras q1–q9: 6 killed, q2/q3/q7 survived (finding 1) |
| AC7 CI | ✅ | Lint, the light Python step and Full stack are green. Full stack: `[replay] prefetch: 2 queries, stats={"hits": 0, "misses": 5, "upstream_fetches": 5, "upstream_failures": 0, "saved": 5}` (cold store, 12.6 s). **arXiv was quiet on this run**: no 429s and a single pass, so the CI run didn't exercise the retry path. The AC1 and AC3 unit tests are the proof of that behaviour ([10](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/10-ac7-fullstack-prefetch.png?raw=true)) `````````````` |
| Docs | ✅ | The docstring and `--budget-seconds` help describe multi-pass, the lazy clock and both sums. `grep -n prefetch README.md CONTRIBUTING.md` finds nothing (exit 1) ([06](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/06-scope-docs-ruff.png?raw=true)) ``````````````` |

**Scope:** 2 ai-owned files, 173+/23-. No workflow change. The `serve` path doesn't change behaviour (budget 0 keeps the deadline `None`), and no ticket or doc files leaked into the PR.

**Time-budget semantics:** every politeness gap, retry wait and cool-down goes through `budget_allows()` (a wait that would reach the deadline is skipped), plus a hard `now >= deadline` check before each request. So the bound is budget + one `TIMEOUT`: 1140 s < 20-min step (stack.yml) and 2640 s < 45-min step (eval.yml) ([08](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/08-time-budget-workflows.png?raw=true)). ```````````````` At job level, Full stack on this head took 10m50s with a 13 s prefetch ([11](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/11-fullstack-step-timings.png?raw=true)), ````````````````` so the worst case is ≈ 30 min, under the 45-min job timeout. For eval, see finding 4.

## PRD fit
This serves the §10 determinism goal: Full stack no longer gives up on a transient 429 with ~10 min of budget unused. It keeps §9 politeness: the same `Recorder.fetch` gate, and between passes it waits at least `Retry-After`.

## Findings
1. [nit] The AC3 test leaves two of the deadline guards unpinned. Mutants q2 (remove the `now >= deadline` check before a request) and q3 (remove the budget check on the politeness gap) each survive. In the AC3 test every request takes 2 s < INTERVAL, so a gap always precedes the next request and each guard covers the other. On CI a PDF download that runs past the deadline leaves no gap, and only the q2 line stops the next fetch. The PR code handles this correctly ([04](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/04-ac3-overrun-scenario.png?raw=true): `````````````````` feed with 2 PDFs, `p1.pdf` takes 150 s against a 100 s budget, `p2.pdf` is not requested; under q2 it is). Suggest adding that scenario as a test. q7 is an equivalent mutant.
2. [nit] Permanent failures now spend the whole budget. A non-retryable failure (404 PDF, a 200 that is not a PDF) is retried every ≥ 60 s until the deadline, so the step exits 1 after ~17/42 min instead of seconds. This is polite and matches AC1 as written. Possible follow-up: skip extra passes for failures other than 429/5xx/network.
3. [spec] AC3 says sleeps are "clipped to the time left". The implementation skips any wait that would reach the deadline and reports `(time budget)`. The outcome is stricter and it is disclosed in the ticket Notes. The ticket wording could be aligned.
4. [spec] The eval.yml job timeout isn't sized for a prefetch that uses its budget (backend-owned, out of scope). `eval.yml:25` budgets ~113 of 120 min with no prefetch time ([08](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/08-time-budget-workflows.png?raw=true)). ``````````````````` The last green eval on main ran 68 min with a 0 s prefetch ([09](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d0142e18fd297d707df466630bcd6dfd113e3fe4/agents/reviews/OPS-H19/evidence/09-time-budget-eval-history.png?raw=true)). ```````````````````` A prefetch that now really uses its 2640 s puts the job at ~112–157 min, so the job may hit its 120-min timeout during `make eval`. The store is still saved (`if: always()`), so the next run converges. Not a gate regression. Suggest a backend ticket to reconcile the timeout and the budget. The eval check on this head was still running at report time; confirm it finished green before raising.

## Missing tests
- An in-flight request overruns the deadline and the next fetch (INTERVAL elapsed) must not start (finding 1).
- A Retry-After larger than the time left: the cool-down is not taken, and the failed items are named without the `(time budget)` suffix.
- Every item is a store hit and the budget is > 0: the deadline is never set, nothing is fetched, exit 0.

## Hand-off
PASS → pm-lead final review. Before raising, confirm the eval check on 5b4d6a2 finished green.

_Note: the QA harness refused to write `report.md`; this comment is the full report, and the orchestrator saves it verbatim to `agents/reviews/OPS-H19/report.md`. Evidence commit `d0142e1` in arxivlens-agents._


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM review (pm-lead) · 2026-11-21 11:57Z · head `5b4d6a2`

**Verdict: HOLD — PM review held: eval check still running.** No APPROVE or CHANGES yet. PR #111 stays **draft**.

- Polled `commits/5b4d6a2/check-runs` from 11:41Z to 11:56Z (15 min): `eval` (job 136830894337) still `in_progress`,
  in `make eval-seed` since 11:32:05Z. The last green eval on main took 39 min seed + 22 min eval, so expect it to finish ~12:35Z.
  All other checks are green (Go, Python M0, Frontend, Agent ownership, DB, Full stack).
- Pre-review done, so the next cycle only needs the eval result:
  - Opened all 13 evidence files (00-12, png + txt). Each proves its AC; nothing material is left "⚠ unverified".
    AC7: arXiv was quiet on the Full stack run, so the retry path is proven by the AC1/AC3 unit tests and mutants m1-m4, as the ticket allows.
  - Scope: exactly `scripts/arxiv_replay.py` + `tests/test_arxiv_replay.py` (173+/23-), ai-owned, no workflow change. Fits PRD §9 (all fetches through `Recorder.fetch`, cool-down ≥ Retry-After) and §10.
  - QA findings decided:
    1. [nit] q2/q3 deadline guards unpinned → follow-up **OPS-H21** (AC3 adds QA's overrun scenario as a test). Not blocking: evidence 04 shows the code is right.
    2. [nit] permanent failures retried until the deadline → **OPS-H21** AC1/AC2. Not blocking: polite, and matches this ticket's AC1 as written.
    3. [spec] AC3 "clipped" vs "skip" → ticket AC3 wording amended to match the (stricter) implementation.
    4. [spec] eval.yml 120-min job timeout vs a 2640 s prefetch → follow-up **OPS-H20** (backend). Not blocking: the store is still saved, so the next run converges, and no gate is weakened.
- **To finish next cycle:** if `eval` on `5b4d6a2` is green → APPROVE and raise. If it fails, check whether the prefetch step (the only changed code it runs; it already succeeded in 0 s on a warm store, evidence 12) is involved. If it isn't, the failure is unrelated: record it and decide on its merits.
