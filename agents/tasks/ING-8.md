# ING-8: Measure PDF section-extraction quality (heading corpus + boundary precision/recall scorer + baseline)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 |
| **PRD ref** | Product PRD ING-3 (✅, but its quality has never been measured); Technical PRD §6.1 (section extraction rules). *Proposed* (pm-lead, needs Mahesh): a Product PRD row ING-8 "section-extraction quality is measured", added in a docs PR |
| **Depends on** | — |
| **Jira** | KAN-32 (`labels = "task-ING-8"`) |
| **Design required** | no: measurement only. It adds a script and a dataset, with no CLI command, table, service, contract or gate. |
| **Status** | Ready |

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
- [ ] AC2: Scorer unit tests with fixed lists cover: a perfect match (P = R = 1), a spurious heading (P < 1, R = 1), a missed
  heading, numbering/case/punctuation normalisation (`"3.1 Results."` matches `"results"`), order preservation (an out-of-order
  duplicate doesn't match), the excluded implicit Abstract, an empty prediction (P defined as 0, no crash), and the micro-average over two papers.
- [ ] AC3: The scorer calls the production `_parse_doc_sections`. A test (monkeypatched module) proves the scorer's run path
  calls `services.processor.worker.ProcessorWorker._parse_doc_sections`, and `grep -n "heading_threshold\|1.15" scripts/evaluate_extraction.py` is empty (no copied heuristic).
- [ ] AC4: Politeness and hygiene. Requests are ≥ 3 s apart (a test with an injected clock/sleep). PDFs are cached under
  `.cache/` and never under `evals/`. `git status` after a run shows no PDF.
- [ ] AC5: **Baseline.** Micro and per-paper boundary P/R/F1, with the commit SHA and dataset row count, recorded in the
  baseline file and the PR. If the sandbox can't reach arxiv.org: "not run: <reason>" plus the exact command. pm-lead then
  attaches the measurement to EVAL-3's nightly workflow as a follow-up step for backend; it doesn't float.
- [ ] AC6: No detector, threshold or gate change in the diff (ownership check output shows only `scripts/`, `evals/`, `tests/`, README).
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
