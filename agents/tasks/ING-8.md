# ING-8: Measure PDF section-extraction quality (heading corpus + boundary precision/recall scorer + baseline)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 |
| **PRD ref** | Product PRD ING-3 (✅, but its quality has never been measured); Technical PRD §6.1 (section extraction rules). *Proposed* (pm-lead, needs Mahesh): a Product PRD row ING-8 "section-extraction quality is measured", added in a docs PR |
| **Depends on** | — |
| **Jira** | KAN-32 (`labels = "task-ING-8"`) |
| **Design required** | no: measurement only. It adds a script and a dataset, with no CLI command, table, service, contract or gate. |
| **Status** | Blocked (needs arxiv.org access to annotate `evals/extraction.jsonl`: AC1 + AC5). Scorer, tests and docs are built on `agent/ai/ING-8` (`d2ad9c5`) |

> **ID note:** Mahesh's plan called this ING-7. Product PRD §6.1 already has a row **ING-7** ("Handle new arXiv versions",
> ✅), and task IDs in the ING series match PRD row IDs (ING-6), so this task is **ING-8** to avoid a clash.

## Goal
Every chunk is prefixed with its section title, and the auxiliary-section filter (QA-6) depends on correct sections.
Detection is heuristic (font size ≥ 1.15× median, numbered-heading regex, bold < 60 chars:
`services/processor/worker.py` `_parse_doc_sections`, lines 113–172), and nobody knows how often it's right. This task
adds a small, reproducible measurement and records a baseline. Improving the detector is a later task, chosen from the numbers.

## Scope
- New dataset `evals/extraction.jsonl` (or `evals/extraction/`): **≥ 10 papers**, one row each:
  `{"arxiv_id", "version" (pinned, e.g. "v2"), "license", "layout" (e.g. "single-column", "two-column", "ACL", "IEEE"),
  "expected_headings": [{"title", "level"}...]}`, in document order. Mix layouts, numbered/unnumbered, Roman-numeral and
  appendix headings. Annotate by hand from the PDF; don't generate the labels with the detector being measured.
- **Licence-safe:** only papers whose arXiv licence is CC BY, CC BY-SA or CC0 (checked on the abs page, recorded in `license`).
  PDFs are referenced by ID + version and fetched at run time into a git-ignored cache (`.cache/` is already ignored).
  **Never commit a PDF** (CI's ownership check rejects `*.pdf`).
- New `scripts/evaluate_extraction.py`: fetches each PDF (≤ 1 request / 3 s, identifying User-Agent, Technical PRD §9),
  runs the **production** detector and scores it, then writes `evals/results/extraction-<timestamp>.json` and prints a table.
- New `tests/test_evaluate_extraction.py`: no network, no PDFs.
- `evals/README.md`: a section on the extraction eval. Baseline numbers go in a new `evals/EXTRACTION_BASELINE.md` (not `evals/BASELINE.md`, which EVAL-4 edits).
- Out of scope: **any change to `services/processor/`** (backend-owned). That covers the detector, a refactor of
  `_parse_doc_sections` into a pure function, and gating (`thresholds.json`: a new gate needs an Accepted ADR).

## Ownership flag
The detector lives in `services/processor/worker.py`, which backend owns. The scorer and dataset live in `scripts/` and
`evals/`, which ai owns. The scorer calls the production code read-only: `ProcessorWorker._parse_doc_sections` uses no
instance state, so call it as `ProcessorWorker._parse_doc_sections(None, doc)` (or via `__new__`). Never construct a
`ProcessorWorker`: `__init__` connects to MinIO and Kafka. **Don't copy the heuristic into `scripts/`.** A copy would
measure something other than production. Importing `services.processor.worker` pulls in `scripts.m0_skeleton`
(torch/transformers) and `confluent_kafka`, so import it lazily inside the scorer's run path, so the unit tests don't need
the ML stack. Write a follow-up request in Notes for backend to expose a pure `parse_doc_sections(doc)` function, and switch to it once that lands.

## Scoring rules (implement exactly; documented in `evals/README.md`)
- Normalise a title: lower-case, strip leading numbering (`^\s*(\d+(\.\d+)*|[IVXLCDM]+|[A-Z])[.)]?\s+`), collapse
  whitespace, strip trailing punctuation.
- The detector's implicit leading `Abstract` section (Technical PRD §6.1 rule 4) is excluded from the predicted list, and
  `Abstract` is excluded from the expected list.
- Matching: walk the predicted headings in order and greedily match each one to the first unmatched expected heading with an
  equal normalised title at or after the last match (order-preserving). TP = matched. **Boundary precision** = TP /
  predicted, **boundary recall** = TP / expected, plus F1, per paper and micro-averaged. Level accuracy over the TPs is reported for information.
- Per paper, the output also lists false-positive and missed titles (so follow-ups can target them).

## Acceptance criteria
- [ ] AC1: The dataset has ≥ 10 rows and ≥ 3 distinct `layout` values. Every row has a pinned `version` and a `license` from
  the allowed set. Dataset tests in `tests/test_evaluate_extraction.py` (**not** `tests/test_evals_data.py`: AI-3/AI-4/EVAL-2 change that file) enforce schema, unique `arxiv_id`, allowed licences, a version pattern `^v\d+$`, ≥ 1 expected heading, and no `*.pdf` under `evals/`.
- [x] AC2: Scorer unit tests with fixed lists cover: a perfect match (P = R = 1), a spurious heading (P < 1, R = 1), a missed
  heading, numbering/case/punctuation normalisation (`"3.1 Results."` matches `"results"`), order preservation (an out-of-order
  duplicate doesn't match), the excluded implicit Abstract, an empty prediction (P defined as 0, no crash), and the micro-average over two papers.
- [x] AC3: The scorer calls the production `_parse_doc_sections`. A test (monkeypatched module) proves the scorer's run path
  calls `services.processor.worker.ProcessorWorker._parse_doc_sections`, and `grep -n "heading_threshold\|1.15" scripts/evaluate_extraction.py` is empty (no copied heuristic).
- [x] AC4: Politeness and hygiene. Requests are ≥ 3 s apart (a test with an injected clock/sleep). PDFs are cached under
  `.cache/` and never under `evals/`. `git status` after a run shows no PDF.
- [ ] AC5: **Baseline.** Micro and per-paper boundary P/R/F1, with the commit SHA and dataset row count, recorded in the
  baseline file and the PR. If the sandbox can't reach arxiv.org: "not run: <reason>" plus the exact command. pm-lead then
  attaches the measurement to EVAL-3's nightly workflow as a follow-up step for backend; it doesn't float.
- [x] AC6: No detector, threshold or gate change in the diff (ownership check output shows only `scripts/`, `evals/`, `tests/`, README).
- [ ] Docs: `evals/README.md` section (how to run it, scoring rules, licence rule). Notes list the top failure patterns
  from the baseline as proposed follow-ups (backend for detector changes).

## Verification
```bash
make test-unit
make lint
python3 -m pytest -q tests/test_evaluate_extraction.py tests/test_evals_data.py   # the second file unchanged, still green
python3 scripts/evaluate_extraction.py --help
python3 scripts/evaluate_extraction.py            # needs arxiv.org + pymupdf; writes evals/results/extraction-*.json
git status --porcelain | grep -i '\.pdf' && echo "PDF LEAK" || echo "no pdf"
```

## Notes
- 2026-11-03 (pm-lead): specced from the external review of `bb9ee90` (approved by Mahesh). Verified that both ingest paths
  use the same detector: the Kafka processor (`worker.py:70`) and on-demand `/internal/ingest` (`services/embedder/api.py:139`
  builds a `ProcessorWorker`). `scripts/m0_skeleton.py` `PaperParser.parse_pdf` is a separate M0 parser that isn't used in
  production. Don't measure it as if it were.
- 2026-11-03 14:00 cycle (pm-lead): line refs re-checked against `9c1229a` (`worker.py:113` `_parse_doc_sections`, `:70` call site, `api.py:139` `ProcessorWorker()`). To stay independent of AI-3 (same cycle) and EVAL-4, dataset tests go only in `tests/test_evaluate_extraction.py` and the baseline in `evals/EXTRACTION_BASELINE.md`. `make test-py` runs only `test_m0.py` and `test_evals_data.py`, so CI won't pick up the new test file unless it's added to `test-py`; `Makefile` is backend-owned, so paste the local pytest output and add a follow-up request in Notes (backend: add it to `test-py`, together with the #12-review `test-m0`/`test-evals-data` split). The sandbox can't reach arxiv.org or PyPI (pymupdf may be missing): AC5 is expected to be "not run" here.
- 2026-11-03 (ai-engineer): **build, commit `d2ad9c5` on `agent/ai/ING-8`** (not pushed; the orchestrator opens the draft PR). Files: `scripts/evaluate_extraction.py`, `tests/test_evaluate_extraction.py`, `evals/README.md` (new section), `evals/EXTRACTION_BASELINE.md`. Diff is 754 lines (scorer 364, tests 315); ownership check warns > 400 but passes.
  - **AC1 NOT met: no dataset committed.** The sandbox can't reach arxiv.org (proxy 403 on `arxiv.org` and `export.arxiv.org`) or any mirror, so nobody here can check licences on the abs pages or annotate headings from the PDFs. Labels written from memory would make the baseline meaningless, so I didn't write any. The validation rules (schema, unique `arxiv_id`, allowed licences `CC BY 4.0`/`CC BY-SA 4.0`/`CC0 1.0`, `^v\d+$`, ≥ 1 heading) live in `validate_dataset()` and are unit-tested on fixture rows. `test_real_dataset_schema_size_and_layout_mix` (≥ 10 rows, ≥ 3 layouts, valid) **skips** with an explicit "AC1 is NOT met" reason until `evals/extraction.jsonl` exists. QA: check that it passes and doesn't skip. `test_no_pdf_under_evals` always runs.
  - AC2: `test_perfect_match`, `test_spurious_heading_lowers_precision_only`, `test_missed_heading_lowers_recall_only`, `test_numbering_case_punctuation_normalisation`, `test_order_preserved_out_of_order_duplicate_does_not_match`, `test_implicit_abstract_excluded_from_both_lists`, `test_empty_prediction_is_zero_not_crash`, `test_micro_average_over_two_papers`.
  - AC3: `test_run_path_calls_production_parse_doc_sections` puts a fake `services.processor.worker` in `sys.modules` (its `__init__` raises) and asserts `_parse_doc_sections(None, doc)` is called. `test_no_copied_heuristic_in_scorer`: `grep -n "heading_threshold\|1.15" scripts/evaluate_extraction.py` returns exit 1 (empty). `test_scorer_import_does_not_pull_ml_stack_or_kafka` checks the lazy import.
  - AC4: `test_requests_are_at_least_3s_apart_and_cache_hits_are_free` uses an injected clock and sleep. `MIN_REQUEST_INTERVAL_S = 3.0` is deliberately not a CLI flag. `test_pdfs_cached_under_cache_dir_not_evals`: the default is `.cache/extraction`, and a cache dir under `evals/` raises. `test_cache_dir_is_git_ignored` and `test_non_pdf_response_is_rejected_and_not_cached` also cover this. `git status --porcelain | grep -i '\.pdf'` gives "no pdf". No real fetch was possible.
  - AC5: **not run** (no dataset; arxiv.org and PyPI unreachable; `pymupdf`/`torch` not installed). The reason and exact commands are in `evals/EXTRACTION_BASELINE.md`.
  - AC6: `.github/scripts/ownership-check.sh origin/main agent/ai/ING-8` gives "Ownership OK for role=ai" with only `evals/`, `scripts/`, `tests/` changed. `git diff origin/main...HEAD -- services/ evals/thresholds.json` is empty.
  - Docs: the README section is done. The failure-pattern list needs the baseline, so it's pending.
  - Local runs: `python3 -m pytest -q tests/test_evaluate_extraction.py tests/test_evals_data.py` gives 82 passed, 1 skipped (the dataset test above; `test_evals_data.py` is unchanged and green). Mutation spot checks (dropping order preservation, the 3 s wait, the Abstract exclusion, the production call, the evals/ guard, the P = 0 guard, punctuation stripping) each fail ≥ 1 test. `flake8 --max-line-length 120` and `ruff --select E,F,W,B,PLW` are clean. `scripts/evaluate_extraction.py --help` works. Without the dataset, the script exits 2 with "could not run: dataset ... not found". `make lint` and `make test-py` don't run here: Go 1.25 can't be downloaded, and `test_m0.py` needs `torch`. CI is the source of truth.
  - Design choices to review: (1) `Abstract` is dropped from **both** lists wherever it appears, not only the implicit leading one. That keeps the two lists symmetric, because an explicit detected "Abstract" heading would otherwise always count as an FP. (2) A paper that fails to fetch or parse fails closed: it counts with 0 predictions (lowering micro recall), the run is marked `complete: false`, and the exit code is 2. (3) "Predicted" means the sections the detector *emits*. `_parse_doc_sections` drops sections with empty text, so a parent heading directly followed by its first subsection counts as missed. This is probably the first failure pattern to look at once there's a baseline.
  - **To unblock (needs a human or an agent with arxiv.org access):** pick ≥ 10 CC BY / CC BY-SA / CC0 papers across ≥ 3 layouts (single-column, two-column, ACL, IEEE; numbered, Roman-numeral and appendix headings), check each licence on its abs page, annotate headings from the pinned-version PDF, then run the commands in `evals/EXTRACTION_BASELINE.md`.
  - **Follow-up requests (backend):** (a) add `tests/test_evaluate_extraction.py` to `make test-py` (together with the #12-review `test-m0`/`test-evals-data` split), since CI doesn't run it today. (b) Expose a pure `parse_doc_sections(doc)` in `services/processor/` so the scorer stops calling a method with `self=None`. The scorer has a TODO at `load_production_detector`. (c) Once a baseline exists, pm-lead attaches the run to EVAL-3's nightly workflow (AC5).
