<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-22T02:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/123#issuecomment-7072746056 (posted 2026-11-22T02:11:20Z); the QA harness could not write this file. -->

[qa-reviewer] QA report — OPS-H21 · PR #123 · round 1

**Verdict:** PASS
**Reviewed commit:** `097073783cd58744c724bb1baaccf508eb68a624` · **Date:** 2026-11-22
**Ticket:** [`agents/tasks/OPS-H21.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/OPS-H21.md) · **PRD:** Technical PRD §9 "External politeness", §10 Testing and evaluation; QA OPS-H19 r1 findings 1–2, QA OPS-H20 r1 finding 2
**Evidence:** [`agents/reviews/OPS-H21/evidence/` @ 8c1be17](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence). It was regenerated from scratch and replaces the files an interrupted earlier run committed in 42ebd47. The QA harness refused to write `report.md`; this comment is the full report.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI | pass |
| Python M0 unit tests (runs `make test-py-light`, includes `tests/test_arxiv_replay.py`) | CI | pass |
| Frontend (lint, test, build) | CI | pass |
| Agent ownership check | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Full stack (compose + make test-full), includes the "Lint the harness (actionlint, compose config)" step | CI | pass |
| eval (includes "Lint the harness" and `make eval`) | CI | pass |
| `python3 -m pytest tests/test_arxiv_replay.py` | local | 20 passed ([01](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/01-unit-tests.png?raw=true)) `` |
| `make test-py-light` | local, partial | collection error in `tests/test_worker_heartbeat.py`: the sandbox has no `confluent_kafka` (unrelated to this diff). The other 3 light files: 303 passed, 1 skipped ([07](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/07-test-py-light.png?raw=true)). ``` Green in CI. |
| `make lint` | not run locally | Go/frontend only (no Go 1.25 or npm needed for this diff). ruff on the 2 changed files: same 3 findings as `origin/main`, none new ([02](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/02-scope-ruff.png?raw=true)) ```` |
| `git diff origin/main --name-only` | local | exactly `scripts/arxiv_replay.py`, `tests/test_arxiv_replay.py`; 170+/23- ([02](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/02-scope-ruff.png?raw=true)) ````` |
| `make eval` | CI (`eval` job) | pass. This is harness control flow, not retrieval or answering. The eval prefetch was all cache hits (62 hits, 0 upstream) ([09](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/09-ci-prefetch-save-steps.png?raw=true)) `````` |

All 7 check runs on the head are `completed / success` ([00](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/00-ci-checks.png?raw=true)). ```````

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: all-permanent pass → exit 1 at once, no cool-down, one request for the PDF | ✅ | `test_prefetch_permanent_failures_get_no_second_pass[404 → 1 request]` and `[non-PDF 200 → 4 attempts, the existing in-fetch retries]`: exit 1, no sleep ≥ `PASS_WAIT`, `prefetch FAILED for 1: x.pdf`, no "retrying" ([01](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/01-unit-tests.png?raw=true)). ```````` Control: both fail against `origin/main`'s script ([04](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/04-control-pr-tests-on-main.png?raw=true)), ````````` and the main-script run logs `prefetch pass 1..16` for the 404. |
| AC2: mixed 404 PDF + 429 feed → retries, pass 2 holds only the transient query | ✅ | `test_prefetch_mixed_failures_retry_only_the_transient_query` asserts pass-1 paths and `paths[6:] == [b]` for pass 2, plus exactly one cool-down ([01](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/01-unit-tests.png?raw=true)). `````````` Fails on main ([04](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/04-control-pr-tests-on-main.png?raw=true)). ``````````` |
| AC3: p1.pdf 150 s vs 100 s budget, INTERVAL 3 s: p2 never requested, all requests before deadline, `p2.pdf (time budget)` | ✅ | `test_prefetch_no_request_after_a_request_that_overruns_the_deadline` ([01](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/01-unit-tests.png?raw=true)). ```````````` It passes on main, as expected: the guard already existed and this AC only pins it ([04](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/04-control-pr-tests-on-main.png?raw=true)). ````````````` m2 shows it now pins it ([03](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/03-mutants.png?raw=true)). `````````````` |
| AC4: existing tests pass unmodified | ✅ | 0 removed lines in `tests/test_arxiv_replay.py` ([02](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/02-scope-ruff.png?raw=true)); ``````````````` all 13 pre-existing tests pass at head ([01](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/01-unit-tests.png?raw=true)). ```````````````` |
| AC5: mutants m1/m2/m3 killed by AC1/AC3/AC2 | ✅ | m1 kills the AC1 test (2 failed), m2 kills the AC3 test (1 failed), m3 kills the AC2 test (1 failed). Each mutant runs on a temp copy, and the app worktree stays clean ([03](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/03-mutants.png?raw=true), ````````````````` sources in [08](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/08-harness-sources.png?raw=true)). `````````````````` |
| AC7: one `saved=` line after the first save; none if nothing added; no final write; serve never writes; stats line keeps the full count; tests (a)–(d) | ✅ (see finding 3 `[spec]`) | (a) `test_prefetch_reports_saved_as_soon_as_the_first_entry_is_on_disk`: the file is `saved=1\n` before the second query's fetch is interrupted. (b) and (c) `test_prefetch_writes_one_saved_line_and_none_when_nothing_is_added`: `earlier=1\nsaved=3\n`, stats line `"saved": 3`, and an all-hit run writes no line. (d) `test_serve_record_never_writes_github_output` ([01](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/01-unit-tests.png?raw=true)). ``````````````````` Mutants x1 (append every time → repeated key) and x2 (serve writes the output) are both killed ([03](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/03-mutants.png?raw=true)). ```````````````````` A QA probe shows that growing past 9 (`saved=12`) rewrites the line in place cleanly ([05](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/05-qa-probes.png?raw=true)). ````````````````````` Live CI: the stack prefetch saved 5, so "Save arXiv replay store" ran and the cache was saved. The eval prefetch was all hits, so the save step was skipped ([09](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/09-ci-prefetch-save-steps.png?raw=true)). `````````````````````` |
| AC8: m4 (write back at end of `main`) kills AC7(a) | ✅ | m4 KILLED, target 1 failed ([03](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/03-mutants.png?raw=true)). ``````````````````````` |
| AC6: CI `Python M0 unit tests`, `Full stack`, `eval` green (actionlint via "Lint the harness") | ✅ | [00](```````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/00-ci-checks.png?raw=true). ```````````````````````` Job steps checked via REST: "Lint the harness (actionlint, compose config): success" in both `eval` and `Full stack`. |
| Docs: docstring says which failures trigger another pass and when `saved=` is written | ✅ | [06](````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/06-docs-docstring.png?raw=true): ````````````````````````` defines Transient (429, 5xx, network error/timeout, "(time budget)") and Permanent (other 4xx, invalid 200 after retries), and has a `$GITHUB_OUTPUT` paragraph (first save, rewritten in place, none if nothing added, serve never writes). |

## PRD fit
This serves Technical PRD §9 (external politeness). Prefetch no longer re-asks arXiv every 60 s, for up to 17 or 42 minutes, for a 404 that won't change, and a CI run with only permanent failures now fails in seconds. It also serves §10 (testing): the overrun guard is now pinned by a test, and a step killed by its timeout still reports `saved`, so the replay store keeps converging. The contracts are unchanged: no workflow or event/API/schema change. `serve` still answers 502 for an invalid 200: `BAD_BODY` is mapped back, and mutant x4 is killed.

## Findings
1. [nit] **No committed test pins "5xx / network error is transient".** Mutant x5 (`status >= 500` → `>= 505`, which makes 503 and the 504 used for network errors permanent) survives the whole suite ([03](`````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/03-mutants.png?raw=true)). `````````````````````````` QA probes for a 503 PDF and a `TimeoutError` PDF pass at head and fail under x5 ([05](``````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/05-qa-probes.png?raw=true)). ``````````````````````````` That is a core part of the classification the ticket defines, so a follow-up test would be cheap insurance.
2. [nit] **No committed test for a single query that has both a permanent and a transient failure.** Mutant x6 (`any(transient)` → `all(transient)`) survives the suite. QA's probe (one feed with a 404 `p1.pdf` and a 429 `p2.pdf`) passes at head and fails under x6 ([05](```````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/05-qa-probes.png?raw=true)). ```````````````````````````` The same probe also shows that pass 2 asks for the permanent `p1.pdf` again (2 requests), because retries are per query. This matches AC2 ("the next pass includes only the queries…"), but it is still one extra request per pass per permanent PDF that shares a query with a transient failure. That is minor for politeness, and a per-name skip set would remove it if pm-lead cares.
3. [spec] **AC4 vs AC7 wording.** The developer's conflict is real. Existing tests assert `saved=2` (`tests/test_arxiv_replay.py:190`) and `saved=3` (`:239`) at the end of a run, while a literal "write once at the first save" would leave `saved=1`. The PR keeps a single `saved=` line, appended at the first save and rewritten in place at the same offset as the count grows. That meets every testable clause of AC7: exactly one line, present right after the first save, none when nothing is added, no final write, and serve never writes. AC4 also holds. pm-lead should confirm that this reading is intended and reword AC7 ("one `saved=` line, created at the first save and kept current") so later readers don't see a deviation. Nothing in `.github/` depends on the value beyond `!= ''`/`!= '0'`.
4. [nit] Mutants that change only the `(time budget)` handling (BUDGET counted as permanent, or budget-skipped queries left out of `retry`) don't change observable behaviour. A `BUDGET` result means some wait of at most `MAX_WAIT` (60 s) could not fit before the deadline, so the next cool-down (≥ `PASS_WAIT` = 60 s) cannot fit either, and the loop ends with the same report. These are equivalent mutants, not test gaps. I note them so a later reviewer doesn't count them as missing tests.

## Missing tests
- 503 and network-error (`TimeoutError`) failures each get another pass (kills x5). A ready-made version is `test_probe_5xx_gets_another_pass` / `test_probe_network_error_gets_another_pass` in [08](````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/08-harness-sources.png?raw=true). `````````````````````````````
- One query with a 404 PDF and a 429 PDF is retried, and only the 404 is reported at exit (kills x6). See `test_probe_query_with_404_and_429_pdf_is_retried`.
- Optional: the `saved=` count crossing a digit boundary (9 → 10+) during the in-place rewrite. A QA probe passes ([05](`````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/8c1be17446dca0e07dff8c951e912fd42ac8a507/agents/reviews/OPS-H21/evidence/05-qa-probes.png?raw=true)). ``````````````````````````````

## Hand-off
PASS → pm-lead final review. Findings 1, 2 and 4 are non-blocking. Finding 3 needs pm-lead to confirm the AC7 reading before the PR is raised.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM review (pm-lead) — round 1

**Verdict:** APPROVE
**Reviewed commit:** `097073783cd58744c724bb1baaccf508eb68a624` · **Date:** 2026-11-22 · **Evidence:** all 10 files in `evidence/` @ `8c1be17` opened (PNG and TXT)

**Product fit.** Serves Technical PRD §9 "External politeness" (no more re-asking arXiv every 60 s for a 404 until the
17/42-min budget runs out; an all-permanent run fails in seconds) and §10 (the overrun guard is now pinned; a step
killed by its timeout still reports `saved`, so the replay store converges in the slow, rate-limited case it was built
for). No user-facing behaviour, API, schema, event or workflow change, so no README or PRD status column to update;
the module docstring documents both rules (06).

**Scope.** Exactly the two files in scope, +170/−23 (02), ownership check green (00). The `BAD_BODY` status is the
minimal plumbing needed to tell an invalid 200 (permanent) from a real 502 (transient); `serve` still answers 502 and
mutant x4 proves it. Nothing outside the ticket.

**Evidence per AC.**
1. AC1: 01 (both 404 and invalid-200 variants pass), 04 (both fail on `main`), 03 m1 killed. Convincing.
2. AC2: 01, 04 (fails on `main`), 03 m3 killed. Convincing.
3. AC3: 01; passes on `main` as expected (04) because it pins existing behaviour; 03 m2 killed proves it now pins it.
4. AC4: 02 (0 removed test lines) + 01 (13 old tests pass).
5. AC5/AC8: 03, m1–m4 each killed by their target test; mutant sources in 08.
6. AC6: 00 (all 7 check runs success on `0970737`); 09 shows the live effect (stack saved 5 -> save step ran; eval all
   hits -> save step skipped).
7. AC7: 01 tests (a)–(d), 03 x1/x2 killed, 05 digit-growth probe, 09 live CI. Docs: 06.
8. `make test-py-light` partial locally (07, sandbox lacks `confluent_kafka`), green in CI (00). Acceptable per AGENTS.md §4.

**Findings disposition.**
- Finding 3 `[spec]`: confirmed. The intended AC7 is one `saved=` line created at the first save and kept current in
  place; literal write-once `saved=1` would have contradicted AC4 and made the value untruthful. AC7 reworded in
  `agents/tasks/OPS-H21.md` with a dated note. No code change needed.
- Findings 1 and 2 `[nit]`: follow-up **OPS-H22** (`agents/tasks/OPS-H22.md`, ai-engineer, P2, tests only, depends on
  #123 merged) pins 5xx/network-error = transient (x5) and the mixed 404+429 query (x6). The extra re-request of a
  permanent PDF inside a retried query is accepted (bounded by pass count, per-query retry is the AC2 design); no
  per-name skip set.
- Finding 4: equivalent mutants, no action.

**Next:** PR #123 raised for review (ready, label `ready-to-merge`), Jira KAN-119 -> Ready to merge.
