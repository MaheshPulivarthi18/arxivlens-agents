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


---

## Round 2

[qa-reviewer] QA report — EVAL-7 · PR #29 · round 2

**Verdict:** PASS
**Reviewed commit:** `d01ffcb59ee7fe05f7ad78d2f2b05eab0f9f8c95` · **Date:** 2026-11-07
**Ticket:** [agents/tasks/EVAL-7.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/tasks/EVAL-7.md) · **PRD:** Product PRD §8 (supported-citation row), QA-4, §7 principle 1; ADR-0003; ADR-0014
**Design:** none (not design-required)

Evidence: [agents/reviews/EVAL-7/evidence/ (r2-* files)](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence). Each `.png` has a matching `.txt` with the full output. The round-1 probes were rerun unchanged against the new head. The only new probe source is `mutants_r2.py` ([r2-10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-10-qa-probe-sources.png?raw=true)): M03 points at the new export line, and M21–M29 target the rework. Its docstring says "M21-M30"; there are 9 new mutants. Worktree `/root/wt/qa-EVAL-7-r2` at the head.

## Test results
| Check | Source | Result |
|---|---|---|
| All 5 check runs (Go, Python M0, Frontend, DB, ownership) | CI @ d01ffcb | all `completed success` on the first poll ([r2-00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-00-ci-checks.png?raw=true)) |
| `make test-py` | CI job 128451485649 | `106 passed, 1 skipped in 4.08s` ([r2-01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-01-AC5-ci-make-test-py.png?raw=true)) |
| `pytest -k review` (ticket verification) | local @ d01ffcb | 22 passed, 76 deselected ([r2-02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-02-AC1-AC4-review-tests.png?raw=true)) |
| `pytest tests/test_evals_data.py` + `answer_review.py --help`, `score --help` | local | 97 passed, 1 skipped; help OK, `--force` on `score` ([r2-09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-09-test-evals-data-full-help.png?raw=true)) |
| Diffstat + ownership | local | `4 files changed, 398 insertions(+), 1 deletion(-)`; `Ownership OK for role=ai (399 changed lines)` ([r2-08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-08-AC6-diffstat-ownership.png?raw=true)) |
| `make test-py` / `make test-unit` locally | not run locally: the sandbox has no torch or confluent_kafka. CI ran `make test-py` (row above). |
| `make lint` | CI Go + Frontend jobs green. `make lint` has no Python linter. |
| `make eval` | not run: no retrieval or answering code changed. This is report-only tooling; `rag.go`, the embedder and `evaluate_answers.py` are untouched. |

## Scope check
The same 4 files as round 1, all in ai-engineer paths. No ticket, review or doc files leaked into the PR. `evals/thresholds.json` and `rag.go` are untouched. The rework diff (`ca21768..d01ffcb`) only touches `scripts/answer_review.py`, `tests/test_evals_data.py` and `evals/README.md`. The removed `blank_judgment`, `pct` and `RESULTS_DIR` helpers were inlined, and behaviour is the same (M03 still killed; the e2e probe passes).

## Round-1 findings, verified
| # | Round-1 finding | Round-2 result | Evidence |
|---|---|---|---|
| 1 | [blocking] drift guard compares only `(marker, chunk_id)` | **Fixed.** `build_rows` now fingerprints each citation as `(marker, chunk_id, round(score or 0, 3), supported)` on both sides. On the new head, the unchanged probe 06 prints `0 rows ...; drifted cases skipped: a001`, the sheet has no claim, and `RESULT: drift detected (no hazard)`. It printed `drifted cases skipped: none` at ca21768. Mutants M21 (pairs only), M22 (no score) and M23 (no supported) are all killed, and fixtures x002 and x004 cover the score and verdict changes. | [r2-06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-06-finding1-text-drift.png?raw=true), [r2-05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-05-mutation-run.png?raw=true) |
| 2 | [nit] M05/M06 survived | **Fixed.** M05 (a re-ask that comes back refused gets exported) and M06 (refused cases get re-asked) are both KILLED. The test asserts the exact tail `drifted cases skipped: x001, x002, x003, x004`, and x003 is the `all_citations_unsupported` re-ask. The mutation run kills 28/29. Only M17 survives (`--save` skips the strict re-check), which round 1 already accepted as defence in depth. | [r2-05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-05-mutation-run.png?raw=true) |
| 3 | [nit] AC4 scan accepted ≤ 64 chars of free text in ID fields | **Fixed.** In committed mode the validator now checks shapes: `arxiv_id` must match `^\d{4}\.\d{4,5}$`, `run_id`/`case_id` must match `^[\w.-]+$`, and `row_id` must equal `<case_id>:u<unit>:m<marker>`. The AC4 scan probe went from 9/10 to **10/10**, and the round-1 failing scenario "short passage text in arxiv_id" now fails the test. Mutants M24–M27 are killed. The scan test's own ≤ 64-char assertion was removed. That is not a weakening: every string field is now bounded by the validator, through the length cap, a shape, the label enum or the date regex. | [r2-04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-04-AC4-scan-probe.png?raw=true), [r2-05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-05-mutation-run.png?raw=true) |
| 4 | [nit] `score --save` silently overwrote | **Fixed.** Without `--force`, `--save` returns 2 when the target exists. The round-trip test checks both paths, and M28 and M29 are killed. The export no-overwrite guard still works over HTTP (exit 2). | [r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-03-AC1-AC2-e2e-http-probe.png?raw=true), [r2-05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-05-mutation-run.png?raw=true) |
| 5 | [spec] (pm-lead) amend `--api-url \| --db-url` | **Still open (pm-lead).** Ticket Scope still reads `export --results ... --api-url ... \| --db-url ...`. It should read `--api-url [--db-url]`, and say that drift is fingerprinted with `score`/`supported`. The AC5 checkbox is also still unticked even though CI is green. Neither blocks QA. | ticket |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 export: one row per (claim, citation), passage text, no `score`/`supported` | ✅ | `test_review_export_one_row_per_claim_citation_and_blind` ([r2-02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-02-AC1-AC4-review-tests.png?raw=true)). End-to-end over real HTTP: 66 rows = 22 × 3, `drifted: none` on a consistent server, `a001, a002` listed on a drifting one. The sheet hides the verdict and the JSONL has no text, 14/14 checks ([r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-03-AC1-AC2-e2e-http-probe.png?raw=true)). M01–M06 and M19–M23 killed. |
| AC2 score: precision, partial, contradiction, claim correctness, judged/unjudged, confusion matrix | ✅ | Known-numbers and round-trip tests ([r2-02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-02-AC1-AC4-review-tests.png?raw=true)). The e2e numbers (61/5, 44/61, rates, 0.5 over 44 claims, matrix) match QA's independent count ([r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-03-AC1-AC2-e2e-http-probe.png?raw=true)). M07–M10 killed. |
| AC3 validator rejects invalid labels and text fields | ✅ | 17 parametrised validator cases plus the conflict/duplicate test ([r2-02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-02-AC1-AC4-review-tests.png?raw=true)). M11–M15, M18 and M24–M27 killed. |
| AC4 committed judgments hold no passage/answer text (scan test) | ✅ | Scan probe 10/10 ([r2-04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-04-AC4-scan-probe.png?raw=true)). It still passes vacuously in the repo today because only `.gitkeep` is there. |
| AC5 README "Human review" section; `make test-py` passes | ✅ | The README section covers who, export, the drift rule (now with the fingerprint), keeping the sheet blind, labels, time (marked as an estimate), score, and where judgments go, including no overwrite without `--force`. `make test-py` is green in CI ([r2-01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-01-AC5-ci-make-test-py.png?raw=true)). |
| AC6 diff < 400 lines | ✅ | 398+/1- = 399 ([r2-08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9adae8295a31905791223dbc016f3d706ea2aa42/agents/reviews/EVAL-7/evidence/r2-08-AC6-diffstat-ownership.png?raw=true)) |

## PRD fit
The round-1 gap is closed. A re-asked answer whose cited sentence changed now drifts and is skipped. The confusion matrix of human `supports` against system `supported` therefore compares the same verdict the run recorded, which is the evidence ADR-0014 and the supported-citation row need. The tool is still report-only, the sheet is still blind, and the committed files still hold IDs and labels only.

## Findings (round 2)
1. **[nit] Leftover limit of the fingerprint, for after QA-8.** A sentence that changed but has the same cosine to the same passage, to 3 decimals, and the same verdict is not detected. That is very unlikely with template answers. In the other direction, small embedding nondeterminism near a rounding edge can mark a case as drifted when it isn't. That is the safe direction, because the case is skipped and listed. If LLM answers (QA-8) produce many drifts, a follow-up could have EVAL-6's `case_record` store a hash of each cited sentence (no text, so it is still safe for the public repo). Not blocking.
2. **[nit] Still no tests for the `--db-url` / `fetch_passages` branch or for an empty export.** Round 1 marked both as optional. The developer cites the diff budget, which is at 399/400. `--db-url` remains **unverified** because there is no psycopg or Postgres in the sandbox. Worth a small follow-up test with a fake `fetch_passages`.
3. **[spec] (pm-lead)** Round-1 finding 5 is still open (see table above).

## Missing tests
- `build_rows` with a fake `fetch_passages` (the `--db-url` path): untested and not run.
- An export with no answered cases: QA saw this work in round 1, but there is no test.

## Hand-off
PASS → pm-lead for final review. Finding 3 is a ticket amendment for pm-lead. Findings 1 and 2 are optional follow-ups.

---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM verdict

[pm-lead] Final review — EVAL-7 · PR #29 · head `d01ffcb59ee7fe05f7ad78d2f2b05eab0f9f8c95` · 2026-11-07

**Verdict: APPROVE**

Inputs read: the ticket, Product PRD §8 (supported-citation row) and QA-4, §7 principle 1, ADR-0003, ADR-0014, the full diff
(4 files, 398+/1-), the PR body, both QA rounds, and every evidence file: all 11 round-1 PNGs (added in `9d6255c`) and all
10 round-2 PNGs (added in `9adae82`), each checked against its `.txt`. CI check runs at the head were re-read from the API
(all 5 success; run 42388697691/42388697671).

**Product fit.** The ticket exists because "cosine ≥ 0.50" (the §8 supported-citation metric and QA-4) is not proof of
support. The tool gives Mahesh a cheap, repeatable way to measure that (§7 principle 1, evidence first):
- The sheet is blind (no score, supported or status), so the reviewer isn't anchored.
- Judgments are IDs and labels only, so the public repo never holds arXiv text.
- The confusion matrix of human `supports` × system `supported` is exactly the data ADR-0014's reserved statuses and a
  future entailment verifier are waiting on.
- It stays report-only, as the ticket requires.

QA r1's blocking finding mattered most for product fit: a matrix that silently pairs a label with the wrong verdict would
look trustworthy and mislead the verifier decision. It is fixed (fingerprint incl. score/supported; r2-06 shows the probe
going from `drifted: none` to `drifted: a001`, and mutants M21–M23 are killed).

**Scope.** Everything the ticket intended is there: export, score with every metric, validator, AC4 scan, README section,
`answer_judgments/` folder. Nothing extra: no gate, no LLM judge, no `rag.go`, `thresholds.json` or `evaluate_answers.py`
change. The two departures are accepted:
1. `--api-url [--db-url]` is forced by EVAL-6's text-free results. I amended the Scope (QA [spec] finding 5).
2. A Markdown-only sheet is allowed by "Markdown or CSV".

**Evidence vs ACs.** Every AC has convincing evidence at the head:
- AC1: test plus the real-HTTP e2e, 66 = 22 × 3 rows, blind sheet (r2-02, r2-03).
- AC2: known-numbers test plus e2e numbers matching QA's own count (r2-02, r2-03).
- AC3: 17 validator cases and 28/29 mutants killed (r2-02, r2-05).
- AC4: scan probe 10/10, including the r1 gap (r2-04).
- AC5: CI `make test-py` 106 passed (r2-01). The README text is in the diff (r1 screenshot 07, plus the r2 wording
  "fingerprint" and "no overwrite without `--force`" that I checked in the diff).
- AC6: 399 lines (r2-08).

No "⚠ unverified" sits on anything an AC depends on. The unverified items are the optional `--db-url` passage source, a
real export against a stack and the README time estimate (labelled as an estimate). They are disclosed in the PR and are
acceptable for report-only tooling whose first real use is Mahesh's.

**Docs.** `evals/README.md` is updated. App `README.md`: no change needed, since there is no new API route or user-facing
command beyond eval tooling, and `evals/README.md` is where eval scripts are documented. PRD: no status column changes
(QA-4 stays ◐; EVAL-7 measures it, it doesn't change it). The §8 supported-citation "Measured by" note gets a pointer to
the human review in the pending pm-lead docs PR (Backlog item updated).

**Non-blocking (logged to Backlog, not CHANGES):**
1. QA r2 nit 1: after QA-8, consider a hash of each cited sentence in EVAL-6's `case_record` as a stronger drift fingerprint
   (no text, safe for the public repo). Trigger: if real LLM runs show many drifted cases or a suspicious matrix.
2. QA r2 nit 2: tests for `build_rows` with a fake `fetch_passages` (the `--db-url` branch) and for an empty export.
3. PM observation: `score --save` writes the committable file *before* the strict re-validation, so a strict-mode failure
   would leave a bad file in `evals/answer_judgments/`. The AC4 scan in CI would catch it before merge, so this is not a
   public-repo risk. Fold it into item 2.

**Raise.** PR description rewritten with the Evidence section (pinned screenshots, CI at the head, QA r1 FAIL → r2 PASS,
this verdict). Merge note for Mahesh: no file overlap with open PRs (#24, #26, #27, #28, #30); the branch already contains
`origin/main`.

---
_Generated by [Claude Code](https://claude.ai/code)_
