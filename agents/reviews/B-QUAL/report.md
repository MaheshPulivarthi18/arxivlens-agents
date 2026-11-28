# QA report — B-QUAL · PR #131 · round 1 · tier Large

> Provenance: written by qa-reviewer. The QA harness refused to write this file, so the orchestrator saved qa-reviewer's text verbatim (2026-11-28). Same content as the PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/131#issuecomment-7234389707. Evidence: `agents/reviews/B-QUAL/evidence/` at `e1510b0`.

**Verdict:** FAIL (1 blocking finding, the rest nits)
**Reviewed commit:** `f9434b2543fef03dfb651985ad6d57fa97c8bce9` · **Date:** 2026-11-28
**Ticket:** `agents/tasks/B-QUAL.md` · **Design:** `docs/design/B-QUAL.md` (Approved, PM decision with 3 conditions) · **PRD:** Product §8 (`/v1/search` p95 < 1.5 s), ING-3; Technical §6.1, §9; ADR-0012 (Proposed)

Inputs used: the ticket, the design and its PM decision, `git diff origin/main...origin/agent/ai/B-QUAL` (merge base `5fcbd5f`), the CI check runs and the eval.yml job logs. I did not use the developer's self-report.

## Test results
| Check | Source | Result |
|---|---|---|
| Go, Python M0, Frontend, DB, Full stack, Agent ownership, eval | CI on head | all success (00-ci-checks) |
| `pytest -q -rs tests/test_evals_data.py tests/test_evaluate_extraction.py` | local worktree at `f9434b2` | 328 passed, 2 skipped. Skips: DB opt-in, and "AC1 not met: no hand labels…" (01-pytest) |
| ruff E,F,W, line length 130, on touched .py files | local | All checks passed |
| `evaluate_extraction.py` with no labels, `--help`, heuristic grep, PDFs | local | exit 2 with message; `--help` OK; grep empty; no PDF (04) |
| `make test-unit` / `make lint` | not run locally: no Go 1.25 or npm | CI green |
| `make eval` | not run locally: no Docker. CI dispatch run 46058471495 | GATE: PASS; gated metrics = nightly 46036660815 (05, 06) |

## PM conditions
| # | Condition | Met? | Evidence |
|---|---|---|---|
| 1 | Verbatim cherry-pick first, then rebase-only commit, then search commits | ✅ | Same patch-id `55ddebaa…` for `d2ad9c5` and `77adfcc`. The `c^..c` diffs differ only in one README hunk offset (`-66`→`-199`); the `+` lines are the same and `-x` is kept. The `d2ad9c5..77adfcc` diff of scorer, tests and EXTRACTION_BASELINE is 0 lines. `81c2e8a` changes only the skip reason, adds `test_missing_dataset_exits_2` and adds the labelling steps (02) |
| 2 | ≤ ~200 lines outside commit 1 | ✅ | 184 + 8 = 192 (02) |
| 3 | No gate change; AC2 test proves exit code unchanged | ⚠ | thresholds/services/Makefile diffs empty; `check_thresholds` byte-identical; no `search` key in thresholds (03). Exit-code proof missing (finding 1) |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `evaluate_search.py` POSTs `{"query","limit":5,"rerank":true}`, makes one uncounted warm-up call on `queries[0]`, then times one call per query. The result goes in `results["search"]` and the summary line is printed. `test_search_measure_warmup_excluded_and_keys` and `test_search_line_printed` pass. The CI log line is quoted under AC3 (05) |
| AC2 | ❌ | Keys in `REPORT_ONLY_KEYS`; no thresholds diff; `test_search_latency_is_report_only` shows the checks list is unchanged. But `main`'s exit code is only compared on a fixture that already exits 1, and mutant M2 survives (07). See finding 1 |
| AC3 | ✅ | Run 46058471495 (head `f9434b2`, success) prints `/v1/search p50/p95 (ms): 9831 / 10092 (report-only, ADR-0012 Proposed; target 1500) errors=0/78 profile=cpu-only`. Rerank R@5 / MRR / NDCG@5 = 0.9850 / 0.9765 / 0.9707 on both this run and nightly 46036660815; citations 1.0, refusals 1.0, expected_paper_hit 1.0, near-miss 0.80, GATE: PASS on both (05, 06) |
| AC4 | ✅ | Production-call, no-copied-heuristic, scoring and politeness/cache tests (≥ 3.0 s, no PDF under `evals/`) green; grep empty; no `*.pdf` in `git status` (01, 04) |
| AC5 | ✅ (no-labels branch) | Skip reason "AC1 not met: no hand labels. …"; exit 2 "could not run: dataset … not found"; `--help` works; EXTRACTION_BASELINE has the labelling steps; no agent-written labels (01, 04) |
| AC6 | ✅ | Local 328 passed / 2 skipped; ruff clean; CI green (00, 01) |
| AC7 | ✅ | README: what is measured, why report-only, `--skip-search`, the ADR-0012 follow-up; extraction section carried; BASELINE row updated |

**Scorer with no labels:** sensible. It refuses with exit 2, writes no results, never fetches (`test_missing_dataset_exits_2` makes `PoliteFetcher.fetch` fail the test), and produces no fake baseline.

## PRD fit
The PR implements ADR-0012 Option 2 for Product PRD §8 without a gate, and gives the first real number: `/v1/search` p95 ≈ 10.1 s on CPU CI against the 1.5 s target. It also makes ING-3's detector scoreable once hand labels exist. It fits the PRD once finding 1 is fixed.

## Findings
1. **[blocking]** The AC2 exit-code proof is missing. Mutant M2 (`passed = all(c["passed"] for c in checks) and not (results.get('search') or {}).get('search_error_count')` in `eval_gate.main`) survives both suites (328 passed). `test_search_errors_never_exit_2` uses the `_gate_main` stubs, whose baseline exit is already 1 (`correct_refusal_rate` fails), so `code == skipped` compares 1 == 1. AC2 says "0 when the rest passes". Fix: stub `/v1/ask` so the answer and refusal sets pass, then assert `skipped == 0 and code == 0` for both parametrizations. The fix is accepted when it kills M2.
2. [nit] The PR body is stale: AC3 "not run yet", "CI: pending".
3. [nit] `make_http_search` doesn't catch `http.client.HTTPException` (e.g. `IncompleteRead`). One such response makes `run_search` report all 78 calls as errors and lose the timings already measured.
4. [info] Ungated Dense Vector R@5 is 0.9060 on dispatch vs 0.9188 on the nightly. The nightly is on `53171d6`, not the PR base, and retrieval is untouched, so this isn't attributed to this PR.
5. [info] On CPU the search phase adds ≈ 13 min to eval.yml (79 × ~10 s); the design estimated 1–2 min.

## Missing tests
- An exit-code test where the rest of the gate passes (finding 1).

## Mutation (only the requested check; local worktree, never pushed)
| Mutant | Result |
|---|---|
| M1: `main` appends a failing check when search p95 > 1500 | killed |
| M2: `main`'s pass decision also requires zero search errors | **survived** (07) |
| M3: `run_search` re-raises instead of returning `failed()` | killed |
| M4: `check_thresholds` fails on search errors | killed (3 tests) |

## Hand-off
FAIL → ai-engineer, rework round 1 on this PR. Fix finding 1; fix nits 2–3 here or append them to the ticket's `## Checklist`. No follow-up tickets.

## Evidence
00-ci-checks · 01-pytest · 02-commit-seams · 03-no-gate-change · 04-scorer-no-labels · 05-ac3-eval-dispatch · 06-ac3-nightly · 07-mutant-M2-survives (each `.png` + `.txt`)
