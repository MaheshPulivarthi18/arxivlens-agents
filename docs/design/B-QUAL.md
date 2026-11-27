# Tech design — B-QUAL: the eval reports `/v1/search` latency, and section extraction gets a scorer

**Author:** ai-engineer · **Ticket:** `agents/tasks/B-QUAL.md` (KAN-135) · **PRD:** Product §8 latency, ING-3; Technical §6.1, §9 · **Status:** Approved (2026-11-28)

## Problem
(1) Product PRD §8 sets `/v1/search` p95 < 1.5 s but nothing measures it. ADR-0012 is Proposed, so this PR follows Option 2
**without** a threshold key: it measures and prints, and gates nothing (AC1–AC3). (2) `_parse_doc_sections` has never been
scored. The scorer from `agent/ai/ING-8` `d2ad9c5` comes onto `main`, runnable as soon as hand labels exist (AC4–AC5). Docs: AC6–AC7.

## Approach
**Search latency (new `scripts/evaluate_search.py`, ~70 lines).** Stdlib only, the same shape as `evaluate_answers.py`:
- `make_http_search(api_url, timeout_s)` → `search(query) -> (ok: bool, ms)`. POSTs `{"query", "limit": 5, "rerank": true}` (the production
  path, ADR-0010) and times it with `perf_counter`. A transport error, non-2xx or bad JSON counts as an error at its elapsed time.
- `measure(queries, search)`: one warm-up call on `queries[0]` that is **not counted**, then one timed call per `evals/retrieval.jsonl`
  query (78 today). Returns `{search_p50_ms, search_p95_ms, search_count, search_error_count}`. The percentiles cover successful calls
  only and reuse `evaluate_answers.percentile` (nearest rank; `None` when nothing succeeded).
- `eval_gate.main` runs it right after the answers phase against the same `--api-url`. A `--skip-search` flag is added, and it is
  skipped when `--skip-answers` is set (no query service). The block goes in `results["search"]`, next to `results["hardware"]`.
  A failure inside `measure` is caught and recorded as `search_error_count = search_count`. It never returns exit 2.
- Report-only: the four keys join `REPORT_ONLY_KEYS`, and `print_table` reads them from `answers` or `search`. `check_thresholds`
  and `LATENCY_GATES` are not touched, so the checks list and exit code are the same with or without the block. Printed line:
  `/v1/search p50/p95 (ms): 412 / 980 (report-only, ADR-0012 Proposed; target 1500)` plus `errors=N/78 profile=<cpu-only|gpu>`.
- Which eval: `make eval` (the full mode, the default), so `eval.yml` runs it on the nightly and on `workflow_dispatch` (AC3).

**Section-extraction scorer (carried from `d2ad9c5`).** Branch `agent/ai/B-QUAL` from `origin/main`, `git cherry-pick d2ad9c5`.
Dry run on `5fcbd5f`: **no conflicts**, 4 files and 754 lines (`evals/README.md` auto-merges), and `pytest tests/test_evaluate_extraction.py`
gives 35 passed, 1 skipped. Changes under it since `9c1229a` (#33 ING-11, #40, #42): `_parse_doc_sections(self, doc)` keeps its
signature and still uses no instance state. Sections gained `page_breaks`, which the scorer ignores because it reads only `title`/`level`. The text
flags (`PDF_TEXT_FLAGS`) and the span joining (`line_text_from_spans`) moved into `scripts/m0_skeleton.py`. The scorer still calls the
production method and copies neither, so the behaviour of #40/#42 is measured automatically. Rebase work: line refs in the docstring and
README (`worker.py:113`), and reword the README section to sit after the search-latency lines. No logic change is expected.
**No labels:** the PR ships no `evals/extraction.jsonl`. `test_real_dataset_schema_size_and_layout_mix` skips with "AC1 not met: no hand
labels". The script exits 2 with `could not run: dataset evals/extraction.jsonl not found`. `EXTRACTION_BASELINE.md` says "not run" and
gives the labelling steps (CC licence check on the abs page, headings in order from the PDF, `^v\d+$` pin). No agent writes labels.
Mahesh decides who labels, or whether to merge without a baseline. If labels land before merge, the PR adds the baseline (AC5 branch 1).

## Alternatives considered
1. Time search inside `evaluate_answers.py`. Rejected: it mixes two endpoints in one file and its `ask_p95` gate code, which makes report-only harder to see.
2. Time it in `evaluate_retrieval.py`. Rejected: that script uses Postgres + `/internal/rerank` directly, not the HTTP API users hit.
3. Reuse `agent/ai/ING-8` or rewrite the scorer. Rejected by the ticket. The cherry-pick keeps authorship and history.

## Contracts and invariants
- No shared contract changes. `evals/thresholds.json`, `services/`, `Makefile`, `rag.go`: untouched. `/v1/search` is called as documented.
- No new failing check (ADR-0012 not decided). arXiv politeness kept (≥ 3 s, identifying UA, PDFs only in `.cache/`).

## Test plan
| AC | Test (name / type) | Runs in CI? |
|---|---|---|
| AC1 | `test_search_measure_warmup_excluded_and_keys` (stub search, fixed ms list; warm-up 9999 ms must not appear in p95; 4 keys present); `test_search_line_printed` (capsys, exact AC1 text) | yes, `tests/test_evals_data.py` (light) |
| AC2 | `test_search_latency_is_report_only`: `check_thresholds` + exit decision with `search_p95_ms=5000, search_error_count=2` equal to without them (0 when the rest passes); keys in `REPORT_ONLY_KEYS`; `git diff origin/main -- evals/thresholds.json` empty | yes |
| AC2 | `test_search_errors_never_exit_2` (stub raising in `measure`; `main` with stubbed phases returns 0) | yes |
| AC3 | `gh workflow run eval.yml --ref agent/ai/B-QUAL`; quote the run ID + line; compare metrics with the latest nightly | manual, in PR |
| AC4 | carried: `test_run_path_calls_production_parse_doc_sections`, `test_no_copied_heuristic_in_scorer`, AC2 scoring tests, politeness/cache tests, `test_no_pdf_under_evals` | after B-PIPE's wildcard line; before that, QA runs it locally |
| AC5 | `test_real_dataset_...` skip reason; `test_missing_dataset_exits_2` (new, ~15 lines); `--help` smoke | same as AC4 |
| AC6 | `python3 -m pytest -q tests/test_evaluate_extraction.py tests/test_evals_data.py`; ruff E,F,W on added lines; ownership check | yes / local |
| AC7 | review of `evals/README.md` (latency lines + extraction section) and `evals/BASELINE.md` note | review |

Failure paths covered: all search calls fail (p95 `None`, errors = count, exit unchanged); query service down with `--skip-answers` (search skipped);
dataset missing (exit 2 with message); detector import must not pull torch/Kafka at import time (carried test).

## Expected size
~920 changed lines: carried 754 (+~10 rebase edits); new ~160 (`evaluate_search.py` ~70, `eval_gate.py` ~25, tests ~45, docs ~20).
That is **over the ~800-line bundle cap** in AGENTS.md §2 (the ticket estimates ~900). The two file groups don't overlap, so the seam is clean.
pm-lead picks one: (a) keep one PR as the ticket specifies, or (b) split it into two PRs on this ticket, search (~160) and the carried scorer (~764).

## Risks and rollout
CPU runners may print p95 > 1500. That is expected and not a regression, and it is the data ADR-0012 asks for. Adds ~80 search calls (~1–2 min on CPU) to `make eval`.
Rollback: revert the PR. Nothing persistent changes. When ADR-0012 is decided, the gate is a rework item: key + one `_check` line + `LATENCY_GATES`.

## PM decision (2026-11-28)
**Approved, as ONE PR** (option a). The two parts share no files. 754 of the ~920 lines are the scorer that was already reviewed in `d2ad9c5`, and it comes over with no conflicts. A reviewer can follow the PR commit by commit, so the PR carries one coherent outcome and the 800-line cap is waived for it. `evaluate_search.py` is the right home, and report-only follows ADR-0012 Option 2 with no threshold key. Binding conditions:
1. **Commit seams**: (i) the verbatim `git cherry-pick -x d2ad9c5`, (ii) a separate rebase-only commit (line refs, README placement, the new `test_missing_dataset_exits_2`), (iii) the search-latency commits. The PR body gives the per-commit line counts. It also states that `git diff d2ad9c5 <commit i> -- scripts/evaluate_extraction.py tests/test_evaluate_extraction.py` is empty, and QA checks that.
2. **The new code must stay small**: no more than about 200 new and changed lines outside the carried commit. If it grows past that, stop and split.
3. **Gate-free proof**: AC2's test is part of the PR. If Mahesh decides ADR-0012 before merge, the key and the `_check` are added as a rework item on this PR, not as a new ticket.
