# EVAL-7: Human review of answers: export a blind judging sheet, import judgments, report citation precision and claim correctness

| | |
|---|---|
| **Owner** | ai-engineer (tooling). **Judgments:** Mahesh, or a reviewer he names. Agents never fill them in. |
| **Priority** | P1 (Phase 1 exit: answer quality measured by a human-reviewed benchmark, not by similarity alone) |
| **PRD ref** | Product PRD §8 (supported-citation row), QA-4, §7 principle 1; ADR-0003; ADR-0014 (reserved statuses wait on this data) |
| **Depends on** | **EVAL-6 merged** (per-case records in the results JSON; shared `tests/test_evals_data.py` and `evals/README.md`) |
| **Jira** | new story under epic KAN-2 "Retrieval & answer quality gates" (`labels = "task-EVAL-7"`) |
| **Design required** | no: offline tooling, report-only, no gate or contract change |
| **Status** | In QA (round 2): rework r1 at `d01ffcb` (branch `agent/ai/EVAL-7`, PR #29 draft) |

## Goal
Cosine similarity ≥ 0.50 says a sentence and a passage are related, not that the passage supports the sentence. The
only trustworthy measure of citation precision, contradictions and claim correctness is a person reading both. Make
that review cheap and repeatable, so its results can later decide whether an entailment verifier is worth adding.

## Scope
- New `scripts/answer_review.py`:
  - `export --results <evals/results/X.json> --api-url ... | --db-url ...`: for each answered case, one row per (claim or
    sentence, cited passage). Passage text is fetched by `chunk_id`. Output is a local review sheet under `evals/results/`
    (already git-ignored, OPS-H4), in Markdown or CSV for reading and JSONL for answers. The sheet **hides** `score` and
    `supported`, so the reviewer isn't anchored by the system's verdict.
  - Reviewer fills `supports: yes | partial | no | contradicts`, `claim_correct: yes | no | unsure`, `reviewer`, `notes`.
  - `score --judgments <file>`: citation precision (`yes` / judged), partial rate, contradiction rate, claim correctness,
    the number of rows judged and not judged, and the agreement between the human `supports` and the system's `supported`
    (a confusion matrix, which is the evidence for or against cosine).
  - Committed judgments live in `evals/answer_judgments/<run-id>.jsonl` and hold **IDs and labels only** (case id, chunk id,
    marker, labels, reviewer, date), never passage or answer text: the repo is public and arXiv licences vary.
- `tests/test_evals_data.py`: export/score round trip on fixtures; label validation rejects unknown values; unjudged rows are excluded and counted.
- `evals/README.md`: a "Human review" section (who, how long a 20-case run takes, how to keep the sheet blind, where judgments go).
- Out of scope: gating on any of these numbers (an ADR later, once there is data), LLM-as-judge, `rag.go`.

## Acceptance criteria
- [x] AC1 — `export` on a fixture results file produces one row per (claim, citation) with passage text and without `score`/`supported` (test).
- [x] AC2 — `score` on a fixture judgments file reports precision, partial, contradiction, claim correctness, judged/unjudged counts and the confusion matrix (test with known numbers).
- [x] AC3 — Invalid labels and rows with text fields are rejected by the validator (tests).
- [x] AC4 — `evals/answer_judgments/` files contain no passage/answer text (a test scans them).
- [ ] AC5 — README "Human review" section. `make test-py` passes.
- [x] AC6 — Diff < 400 lines.

## Verification
```bash
python3 -m pytest -q tests/test_evals_data.py -k review
make test-py
python3 scripts/answer_review.py --help
```

## Notes
- 2026-11-07 (pm-lead): from the 2026-11-07 plan (Phase 1 item 7, human-review half). The first real judging session needs a
  results file from a stack run (EVAL-3 workflow artifact) and a person. That session is Mahesh's, not an agent's. Wave 3.
- 2026-11-07 11:00Z (pm-lead, grooming): EVAL-6 merged. Ready; ai's one free slot this cycle went to AI-6 (P0, `rag.go` chain). Fold the EVAL-6 P3 `classify()` nits (board Backlog) into this PR if `scripts/evaluate_answers.py` is touched.
- 2026-11-07 (ai-engineer): built `ca21768` on `agent/ai/EVAL-7` (cut from `2b71772`), pushed; PR not opened (orchestrator).
  Files: new `scripts/answer_review.py` (243 lines), `tests/test_evals_data.py` (+132/-1, 16 `review` tests),
  `evals/README.md` ("Human review" section + table row), `evals/answer_judgments/.gitkeep`. Diff 398+/1- (ownership
  script: "Ownership OK for role=ai (399 changed lines)"). `scripts/evaluate_answers.py` not touched (only imported), so
  the EVAL-6 P3 `classify()` nits stay in Backlog as the ticket's Notes say.
  - **Interpretation to check (pm-lead/QA):** the EVAL-6 results JSON holds no answer text, so `export` can't get claim
    text from it. It re-asks `/v1/ask` (`--api-url`, always needed) for each answered case and skips a case as "drifted"
    when its (marker, chunk_id) pairs differ from the results file. `--db-url` is an *optional* passage source (by
    `chunk_id` from `paper_chunks.content`); default is the re-asked response's `content`. So it's `--api-url [--db-url]`,
    not the spec's `--api-url | --db-url`. Template answers are deterministic, so drift should be rare until QA-8.
  - Sheet is Markdown only (spec: "Markdown or CSV"; CSV dropped to fit < 400). It hides `score`, `supported` and
    `status` (ADR-0014 claims status would also anchor). Judgments JSONL keys: `run_id,row_id,case_id,unit,marker,chunk_id,
    arxiv_id,supports,claim_correct,reviewer,date` (+ `notes` locally). `score --save` writes the committable copy
    without `notes` and re-validates it in strict mode. `claim_correct` is one value per claim (`case_id`,`unit`);
    conflicting labels and duplicate `row_id`s are rejected. Confusion matrix needs `score --results <same run>`.
  - AC1: `test_review_export_one_row_per_claim_citation_and_blind` (3 rows from 2 cited sentences incl. an out-of-range
    `[9]`; refused case skipped; drifted case listed; sheet has both passages + claim text and none of
    `score/supported/status/0.83/0.41`; JSONL has no text). AC2: `test_review_score_known_numbers_and_unjudged_excluded`
    (5 judged / 2 unjudged, precision 0.4, partial 0.2, contradicts 0.2, claim correctness 1/3, full 4x3 matrix) +
    `test_review_round_trip_export_score_save`. AC3: `test_review_validator_rejects_bad_labels_and_text_fields`
    (12 cases: bad/miscased labels, `claim`/`passage`/`answer` keys, `notes` in committed mode, missing reviewer, bad
    date, bool marker, over-long strings) + `test_review_load_rejects_conflicting_claim_labels_and_duplicates`. AC4:
    `test_review_committed_judgments_hold_ids_and_labels_only` (scans `evals/answer_judgments/*.jsonl` strictly; the
    dir holds only `.gitkeep` today, so it passes vacuously until the first real file). AC6: 399 changed lines.
  - Commands: `python3 -m pytest -v tests/test_evals_data.py -k review` → 16 passed, 76 deselected;
    `python3 -m pytest -q tests/test_evals_data.py` → 92 passed, 1 skipped; `python3 scripts/answer_review.py --help` OK;
    `.github/scripts/ownership-check.sh origin/main agent/ai/EVAL-7` → OK. Mutation check (scratch copy, restored):
    9/9 mutants killed (sheet leaks score, drift check removed, out-of-range markers kept, text keys allowed, unjudged
    counted, precision counts partial, `--save` keeps notes, overwrite allowed, conflicting claim labels allowed).
  - **Unverified:** AC5's `make test-py` fails at collection in this sandbox (`No module named 'torch'` in test_m0.py,
    `confluent_kafka` in test_worker_heartbeat.py; files untouched) → CI is the source of truth. `make lint` is Go +
    frontend only, nothing Python to lint. `--db-url` (`fetch_passages_db`, psycopg) and the real HTTP re-ask path have
    no test (no DB/stack here; diff budget). No real export was run: no results file or stack in the sandbox. No judgments
    written (they are Mahesh's). Time estimate in the README (about 40 rows, 20–40 min for 20 template cases) is a guess
    from the template's two cited sentences and is labelled as one. `make eval` not applicable (no retrieval/answer change).
- 2026-11-07 (ai-engineer, rework r1 of QA r1 FAIL, `agents/reviews/EVAL-7/report.md`): pushed `d01ffcb` on PR #29.
  Diff vs origin/main 398+/1- ("Ownership OK for role=ai (399 changed lines)"); edits in place, the README section,
  docstring and two helpers were compressed to stay under 400.
  - [x] F1 [blocking] drift fingerprint: `build_rows` compares sorted `(marker, chunk_id, round(score or 0, 3),
    supported)` per citation on both sides (results file vs re-ask). Fixtures x002 (same pair, score 0.77 → 0.22) and
    x004 (same pair and score, `supported` True → False) must be drifted.
  - [x] F2 [nit] the test asserts the exact output tail `drifted cases skipped: x001, x002, x003, x004`; x003 = re-ask
    with the same citations and `refusal_reason: all_citations_unsupported`; a002 (refused in the results, no stubbed
    response) would show up as drifted if it were re-asked, so the exact list proves it isn't.
  - [x] F3 [nit] committed mode: `arxiv_id` `^\d{4}\.\d{4,5}$` (same as the test's `ARXIV_ID`), `run_id` and `case_id`
    `^[\w.-]+$`, `row_id` must equal `<case_id>:u<unit>:m<marker>` (stricter than the regex). 5 new validator cases.
  - [x] F4 [nit] `score --save` returns 2 when the target exists unless `--force` (`--force` now on both subcommands);
    the round-trip test checks both.
  - F5 [spec] left to pm-lead. For the ticket amendment: drift is now fingerprinted with `score`/`supported`.
  - Commands: `python3 -m pytest -q tests/test_evals_data.py` → 97 passed, 1 skipped; `-k review` → 22 passed;
    `answer_review.py --help` OK; ownership check OK. Mutation check (scratch copy, restored, `cmp` clean): 12/12 killed
    (fingerprint pairs-only / no score / no supported, classify check removed, refused cases re-asked, shape checks off,
    row_id / arxiv / run_id / case_id shape each removed, `--save` overwrite, `--force` ignored).
  - Still unverified (as r1): `make test-py` locally (no torch/confluent_kafka), `--db-url` path, a real export.
    QA's optional missing tests (fake `fetch_passages`, empty export) not added: no diff budget left.
