<!-- Saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/29#issuecomment-6709322297 (the QA harness could not write report.md). -->

[qa-reviewer] QA report — EVAL-7 · PR #29 · round 1

**Verdict:** FAIL
**Reviewed commit:** `ca21768a0ea537d732e6b288101c01237abb373a` · **Date:** 2026-11-07
**Ticket:** [agents/tasks/EVAL-7.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/tasks/EVAL-7.md) · **PRD:** Product PRD §8 (supported-citation row), QA-4, §7 principle 1; ADR-0003; ADR-0014
**Design:** none (not design-required)

Evidence: [agents/reviews/EVAL-7/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence) (each `.png` has a matching `.txt` with the full output; the probe sources are in `10-qa-probe-sources.txt`). The QA harness couldn't write `report.md`, so this comment is the report.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI @ ca21768 | success ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/00-ci-checks.png?raw=true))`` |
| Python M0 unit tests (`make test-py`) | CI job 128448538200 | success: `101 passed, 1 skipped in 5.21s` ([01](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/01-AC5-ci-make-test-py.png?raw=true))```` |
| Frontend (lint, test, build) | CI | success |
| DB (migrate twice, HNSW plan + recall) | CI | success |
| Agent ownership check | CI + local | success; local `Ownership OK for role=ai (399 changed lines)` ([08](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/08-AC6-diffstat-ownership.png?raw=true))````` |
| `pytest -k review` (ticket verification) | local @ ca21768 | 17 passed, 76 deselected ([02](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/02-AC1-AC4-review-tests.png?raw=true))`````` |
| `pytest tests/test_evals_data.py` | local | 92 passed, 1 skipped ([09](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/09-test-evals-data-full.png?raw=true))``````` |
| `answer_review.py --help` | local | OK ([07](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/07-AC5-readme-help.png?raw=true))```````` |
| `make test-py` / `make test-unit` | not run locally: no torch / confluent_kafka in the sandbox, PyPI blocked. CI ran `make test-py` (row above). |
| `make lint` | CI (Go + frontend jobs green); no Python linter in `make lint` |
| `make eval` | not run: no retrieval/answering code changed (`rag.go`, embedder untouched; report-only tooling) |

## Scope check
4 files, 398+/1-: `scripts/answer_review.py` (new), `tests/test_evals_data.py`, `evals/README.md`, `evals/answer_judgments/.gitkeep`. All inside the ai-engineer's paths. No ticket/review/doc files in the PR. `evals/thresholds.json`, `scripts/evaluate_answers.py`, `rag.go` untouched. Nothing from "Out of scope" (no gating, no LLM judge).

## Departures from the spec (as asked)
1. **`export` always re-asks `/v1/ask` (`--api-url`), `--db-url` optional, instead of `--api-url | --db-url`.** Justified in principle: `evaluate_answers.case_record` (EVAL-6) deliberately stores IDs and numbers only, and Postgres has no answer text, so the claim text can't come from the results file or the DB. A `--db-url`-only export is impossible. Accepted as a [spec] correction, **but** the guard that is supposed to make the re-asked answer equal to the judged run is incomplete (finding 1).
2. **Markdown-only sheet.** The spec says "Markdown or CSV", so either one meets it. Accepted.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 export: one row per (claim, citation), passage text, no `score`/`supported` | ✅ (with finding 1 on drift) | `test_review_export_one_row_per_claim_citation_and_blind` ([02](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/02-AC1-AC4-review-tests.png?raw=true)).````````` QA end-to-end over real HTTP ([03](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/03-AC1-AC2-e2e-http-probe.png?raw=true)):`````````` `evaluate_answers --json-out` → `export` produced 66 rows = 22 answered cases × 3 (claim, citation) pairs; every passage and claim is on the sheet; the sheet has no `score`/`supported`/`status`/score values; the JSONL has no text; a second export refuses to overwrite (exit 2); a server with changed chunk_ids for a001/a002 gets both skipped and listed. Mutants M01–M04, M19, M20 killed ([05](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/05-mutation-run.png?raw=true)).``````````` |
| AC2 score: precision, partial, contradiction, claim correctness, judged/unjudged, confusion matrix | ✅ | `test_review_score_known_numbers_and_unjudged_excluded` (known numbers), `test_review_round_trip_export_score_save`. QA probe [03](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/03-AC1-AC2-e2e-http-probe.png?raw=true):```````````` 61/5 judged/unjudged, precision 44/61, rates, claim correctness 0.5 over 44 claims and the matrix all equal QA's independent count. Mutants M07–M10 killed. |
| AC3 validator rejects invalid labels and text fields | ✅ | `test_review_validator_rejects_bad_labels_and_text_fields` (12 cases), `test_review_load_rejects_conflicting_claim_labels_and_duplicates`. Mutants M11–M15, M18 killed. |
| AC4 committed judgments hold no passage/answer text (scan test) | ✅ (nit 3) | `test_review_committed_judgments_hold_ids_and_labels_only` passes vacuously today (only `.gitkeep`). QA dropped files into scratch copies ([04](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/04-AC4-scan-probe.png?raw=true)):````````````` the scan fails on `passage`/`answer`/`claim`/`notes` keys, unknown labels, file name ≠ run_id, a CSV and an 80-char reviewer; it passes a valid file. It does **not** fail on ≤ 64 chars of free text in an ID field (nit 3). |
| AC5 README "Human review" section; `make test-py` passes | ✅ | Section in `evals/README.md` covers who, export, keeping it blind, labels, time (marked as an estimate), score, where judgments go ([07](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/07-AC5-readme-help.png?raw=true)).`````````````` `make test-py` green in CI: `101 passed, 1 skipped` ([01](```````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/01-AC5-ci-make-test-py.png?raw=true)).``````````````` |
| AC6 diff < 400 lines | ✅ | `4 files changed, 398 insertions(+), 1 deletion(-)` = 399 ([08](````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/08-AC6-diffstat-ownership.png?raw=true)).```````````````` |

## PRD fit
The tool serves the PRD's supported-citation row and QA-4: it is the human measurement of whether cosine ≥ 0.50 "supported" means supported, and the confusion matrix is the evidence ADR-0014's reserved statuses wait on. It stays report-only, keeps the sheet blind, and keeps text out of the public repo. The one gap is that the confusion matrix can silently pair a human label for one sentence with the system verdict for another (finding 1). That breaks the "evidence first" purpose of the ticket.

## Findings
1. **[blocking] The drift guard compares only `(marker, chunk_id)`, so a re-asked answer with different text is exported as the judged run's claim, and `score --results` then pairs the human label with the old run's `supported`.** `scripts/answer_review.py:62-64`:
   ```python
   want = sorted((c["marker"], c["chunk_id"]) for c in case.get("citations") or [])
   got = sorted((c.get("marker"), c.get("chunk_id")) for c in (resp or {}).get("citations") or [])
   ```
   Probe [06](`````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/06-finding1-text-drift.png?raw=true):````````````````` the results file says marker 1 → chunk 11, `supported: true`, `score: 0.81`. The re-ask returns the same pair with a different sentence, `score: 0.22` and `supported: false`. Output: `drifted cases skipped: none`, and the sheet shows the new sentence. With template answers (today) the text is a function of the hits, so this rarely fires. But QA-8 (LLM synthesis, same wave, P0) makes the text vary run to run while chunk ids often repeat, and an embedder or threshold change does the same. The README tells the reviewer that drifted cases are skipped, so a corrupted matrix would look trustworthy. **Fix (cheap, no new data in the public artifact):** the results already hold per-citation `score` and `supported`, which are a fingerprint of the cited sentence. Add them to both tuples, e.g. `(marker, chunk_id, round(score or 0, 3), supported)`, and add one fixture case with the same pairs and a different score that must be listed as drifted. In-place edits keep AC6 within budget.
2. **[nit] Drift/skip outputs aren't pinned by the tests.** Mutants M05 (a re-ask that comes back as a refusal with the same citations, `refusal_reason: all_citations_unsupported`, is exported) and M06 (refused cases are no longer skipped, so they're re-asked and reported as "drifted") both survive ([05](``````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/05-mutation-run.png?raw=true)).`````````````````` Assert the exact drift list (`drifted cases skipped: x001`) and add a re-ask-refused fixture. (M17, "`--save` skips strict re-validation", is defence in depth on already validated rows and behaves the same: not a gap.)
3. **[nit] The AC4 scan accepts up to 64 chars of free text in ID fields** (`arxiv_id: "attention is all you need, text here"` passes, [04](```````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9d6255cea8fb2a7266d2f875784aba7faa28cda3/agents/reviews/EVAL-7/evidence/04-AC4-scan-probe.png?raw=true),``````````````````` last row). Validate shapes in committed mode: `arxiv_id` against the arXiv ID regex the test file already has (`ARXIV_ID`), `row_id` as `^<case_id>:u\d+:m\d+$`, `run_id` as `^[\w.-]+$`.
4. **[nit] `score --save` silently overwrites an existing `evals/answer_judgments/<run-id>.jsonl`.** `export` guards its judgments file with `--force`, but `--save` doesn't. Git makes this recoverable, but a second partial session could replace the first reviewer's labels without a warning.
5. **[spec] (pm-lead)** Amend the ticket's `export --api-url ... | --db-url ...` to `--api-url [--db-url]` (departure 1 is forced by EVAL-6's text-free results). If finding 1 is fixed by fingerprinting with `score`/`supported`, say so in the ticket.

## Missing tests
- Re-ask returns the same (marker, chunk_id) pairs with a different `score`/`supported` → must be drifted (finding 1).
- Re-ask comes back refused (`all_citations_unsupported`, same citations) → must be drifted (M05).
- Exact drift list asserted, so refused cases are proven not re-asked (M06).
- `--db-url` (`fetch_passages_db`) has no test and wasn't exercised (no psycopg or Postgres in this sandbox): unverified. A test with a fake `fetch_passages` passed to `build_rows` would cover the "passage by chunk_id from another source" branch without a DB.
- Empty export (no answered cases) works in the QA run (0 rows, empty sheet) but has no test.

## Hand-off
FAIL → back to ai-engineer (finding 1 blocking; 2–4 nits; 5 for pm-lead).


---
_Generated by [Claude Code](https://claude.ai/code)_
