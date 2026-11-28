# B-QUAL: The eval reports `/v1/search` latency, and section extraction gets a scorer

| | |
|---|---|
| **Owner** | ai-engineer (code PR). The docs part is pm-lead's, already raised as arxivlens-agents PR #22 (`docs/prd-catchup`) |
| **Priority** | P1 |
| **PRD ref** | Product PRD §8 (`/v1/search` p95 < 1.5 s, not measured today), ING-3 (✅, quality never measured); Technical PRD §6.1, §9, §10; ADR-0012 (Proposed) |
| **Depends on** | Nothing open. `agent/ai/ING-8` `d2ad9c5` holds the scorer (not merged, behind `main`). For CI to run the scorer tests, B-PIPE's `Makefile` line (wildcard, so the two bundles merge in any order) |
| **Jira** | one story for the bundle under epic KAN-2 "Retrieval & answer quality gates" (`labels = "task-B-QUAL"`); KAN-12 and KAN-32 are closed and point here |
| **Tier** | Large. Before code, a short `docs/design/B-QUAL.md` (template; one page): where the search timing runs (`evaluate_answers.py`, `eval_gate.py` or a new `scripts/evaluate_search.py`), the results-JSON keys, how the ING-8 commit is brought onto `main` and what #40/#42 changed under it. pm-lead approves it |
| **Size estimate** | ~900 changed lines: ~150 new (EVAL-2 part) + ~750 carried over from `d2ad9c5` (scorer 364, tests 315, docs 75), which is written and self-contained. One PR; the two parts are separate files, so a reviewer can follow them |
| **Absorbs** | EVAL-2 (KAN-12), ING-8 (KAN-32). AI-5 (KAN-25) stays Blocked on ADR-0011 (KAN-26) and is on the decisions list |
| **Branch** | `agent/ai/B-QUAL` (start from `origin/main`, then bring `d2ad9c5` over by cherry-pick or rebase; don't reuse `agent/ai/ING-8`) |
| **Status** | In Progress (design approved) |

## Goal
(1) Every eval run shows how fast `/v1/search` is against the PRD's 1.5 s target, without changing a gate before
Mahesh decides ADR-0012. (2) The production section detector gets a reproducible scorer, so its quality can be
measured as soon as hand labels exist.

## Why report-only (ADR-0012)
ADR-0012 is Proposed. Its Option 2, which pm-lead recommends, is "measure and report now, gate later, **no threshold key yet**". Options 1 and 3
add the key `search_p95_latency_ms_max`, and AGENTS.md §2 allows that only through an Accepted ADR. So this bundle builds only the part that changes no
gate. The p50/p95 and the error count are **report-only**, `evals/thresholds.json` is untouched, and no new check can fail the run. Search
errors are reported, not gated, because Option 2's "failed calls fail the run" would also be a new failing check. If Mahesh accepts an
option, the follow-up is a few lines in `eval_gate.py` plus the key, done as a rework item on whatever is open, not a new ticket.

## Scope
- EVAL-2 part: `scripts/eval_gate.py` (plus either `scripts/evaluate_answers.py` or a new `scripts/evaluate_search.py`, which the design picks), `tests/test_evals_data.py`
  (it is in `make test-py-light`, so CI runs it), `evals/README.md`, and an `evals/BASELINE.md` note.
- ING-8 part: `scripts/evaluate_extraction.py`, `tests/test_evaluate_extraction.py`, `evals/README.md` (extraction section), `evals/EXTRACTION_BASELINE.md`,
  and `evals/extraction.jsonl` **only if** hand labels are provided (see Notes).
- Out of scope: `evals/thresholds.json`; any gate or exit-code change; `services/processor/` (backend: the detector, and a pure
  `parse_doc_sections` seam); the `Makefile` (B-PIPE carries the line); `rag.go`; AI-5.

## Acceptance criteria
- [ ] AC1 (EVAL-2): `make eval` times `POST /v1/search` (`rerank: true`, the production path) once per `evals/retrieval.jsonl` query, after one
  warm-up call that isn't counted. The results JSON gets `search_p50_ms`, `search_p95_ms`, `search_count` and `search_error_count`, next to the existing
  `hardware` block, and the summary prints `/v1/search p50/p95 (ms): a / b (report-only, ADR-0012 Proposed; target 1500)`.
- [ ] AC2 (EVAL-2): No gate change. The new keys are in `REPORT_ONLY_KEYS`. `git diff origin/main -- evals/thresholds.json` is empty. A unit test with fixed numbers shows that
  `search_p95_ms = 5000` and `search_error_count = 2` leave the exit code exactly as it would be without them (0 when the rest passes), and that
  the warm-up call is excluded from the percentile.
- [ ] AC3 (EVAL-2): One `workflow_dispatch` run of `eval.yml` on the branch prints the AC1 line in the job log (quote the run ID and the line), or "not run: <reason>"
  plus the command. The retrieval and answer metrics on that run match the latest nightly (no regression; this PR doesn't touch retrieval).
- [ ] AC4 (ING-8): The scorer is on `main`'s parser. After the cherry-pick, the scorer still calls the production
  `services.processor.worker.ProcessorWorker._parse_doc_sections` (test with a monkeypatched module). It copies no heuristic
  (`grep -n "heading_threshold\|1.15" scripts/evaluate_extraction.py` is empty). ING-8's AC2 scoring tests and AC4 politeness/cache tests are green
  (≥ 3 s between requests, PDFs only under `.cache/`, none under `evals/`, no `*.pdf` in `git status`).
- [ ] AC5 (ING-8): Dataset. If `evals/extraction.jsonl` with ≥ 10 hand-labelled rows is provided, the dataset test enforces the schema (≥ 3 layouts, pinned
  `^v\d+$` version, CC BY / CC BY-SA / CC0 licence, unique IDs, ≥ 1 heading) and the baseline (micro and per-paper P/R/F1, commit SHA, row
  count) goes in `evals/EXTRACTION_BASELINE.md`. Otherwise the dataset test **skips** with the explicit reason "AC1 not met: no hand labels",
  `--help` works, the script exits 2 "could not run: dataset … not found", and the baseline file says how to label and run. **No labels written by an agent from memory.**
- [ ] AC6: `python3 -m pytest -q tests/test_evaluate_extraction.py tests/test_evals_data.py` is green, with output pasted. In CI the extraction tests run once B-PIPE's
  wildcard line is on `main`; before that, QA's local run of that command on the PR head is the evidence. CI `Python` light/ML, `Go`, and `Agent
  ownership check` (only `scripts/`, `evals/`, `tests/`) are green. Ruff (E,F,W, line length 130) is clean on added lines.
- [ ] AC7: Docs. `evals/README.md` gets the search-latency lines (what is measured, why it's report-only, the follow-up when ADR-0012 is decided) and the extraction
  section (how to run, the scoring rules, the licence rule, how to add labels).

## Verification
```bash
cd app
make test-unit && make lint
python3 -m pytest -q tests/test_evals_data.py tests/test_evaluate_extraction.py
python3 scripts/eval_gate.py --help && python3 scripts/evaluate_extraction.py --help
git diff origin/main -- evals/thresholds.json services/    # empty
gh workflow run eval.yml --ref agent/ai/B-QUAL             # AC3, then read the job log
# No mutation testing: measurement/report code, not delivery, verification, ranking or auth.
```

## Checklist
- [ ] (QA r1 optional item 4, for pm-lead) On `cpu-only`, `/v1/search` timing adds ~13 min to eval.yml (79 × ~10 s). A fixed sample (first 20 queries) on cpu-only would need AC1's "once per query" reworded; not done in r1.

## Notes
- 2026-11-28 (ai-engineer): QA r1 rework on #131, head `32f1166` (+33/−6; 219 changed lines outside the carried commit). AC2 exit-code test now on a passing baseline, asserts 0 == 0; local mutant M2 killed (not pushed). `http.client.HTTPException` counted per call + test. PR body refreshed (AC3 run 46058471495: 9831/10092 ms cpu-only, GATE PASS). Item 4 → Checklist.
- 2026-11-28 (ai-engineer): built as draft PR ArxivLens #131 (head `f9434b2`). Commits: (1) `77adfcc` verbatim `cherry-pick -x d2ad9c5` +754, (2) `81c2e8a` rebase edits +18/−2, (3) `972a90f` search timing +155/−5, (4) `f9434b2` docs +11/−1; 192 changed lines outside (1). Local: 328 passed, 2 skipped (`tests/test_evals_data.py`, `tests/test_evaluate_extraction.py`); ruff clean; ownership OK (942-line warning, waived by PM). AC3: eval.yml dispatched, run 46058471495 (QA quotes the line). No hand labels (still Mahesh's decision).
- 2026-11-28 (pm-lead): design approved as ONE PR (the cap is waived for the carried scorer), with 3 conditions (`docs/design/B-QUAL.md` › PM decision).
- 2026-11-28 (pm-lead): bundle created in the process reset. **Docs part (done by pm-lead, PR #22)**: Technical PRD §7.1 (RRF pool → rerank →
  fusion FusionK=10 → top-5 ≤ 2 per paper), §7.2 (two stages, LLM only with `LLM_MODEL` and not quick, quoted answers, quote/NLI verification,
  ADR-0003 refusals), §11 roadmap, §12; Product PRD ING-6 ✅ (QA-4/QA-8 were already ✅); new ADR-0022 (quote/NLI verification), 0023 (quoted
  answers), 0024 (opt-in LLM, local Ollama, qwen2.5:3b-instruct), recorded as Accepted from Mahesh's #44/#46; ADR-0015 Superseded by §9.
- ING-8 hand labels are a **decision for Mahesh**: label about 10 CC-licensed corpus papers (he inspected 77 PDFs by hand for #42), or name someone, or accept
  merging the scorer without a baseline. Agents in this sandbox can't reach arxiv.org.
- AI-5 remains `Blocked (needs ADR-0011)`. Since #119 the relevance cutoff runs over the whole pool, so during a reranker outage `/v1/ask` answers
  from about 20 unchecked hits (citation verification still runs). It is on the decisions list.
