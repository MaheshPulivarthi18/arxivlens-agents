# EVAL-7: Human review of answers: export a blind judging sheet, import judgments, report citation precision and claim correctness

| | |
|---|---|
| **Owner** | ai-engineer (tooling). **Judgments:** Mahesh, or a reviewer he names. Agents never fill them in. |
| **Priority** | P1 (Phase 1 exit: answer quality measured by a human-reviewed benchmark, not by similarity alone) |
| **PRD ref** | Product PRD §8 (supported-citation row), QA-4, §7 principle 1; ADR-0003; ADR-0014 (reserved statuses wait on this data) |
| **Depends on** | **EVAL-6 merged** (per-case records in the results JSON; shared `tests/test_evals_data.py` and `evals/README.md`) |
| **Jira** | new story under epic KAN-2 "Retrieval & answer quality gates" (`labels = "task-EVAL-7"`) |
| **Design required** | no: offline tooling, report-only, no gate or contract change |
| **Status** | Ready (Wave 3: starts when EVAL-6 is merged) |

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
- [ ] AC1 — `export` on a fixture results file produces one row per (claim, citation) with passage text and without `score`/`supported` (test).
- [ ] AC2 — `score` on a fixture judgments file reports precision, partial, contradiction, claim correctness, judged/unjudged counts and the confusion matrix (test with known numbers).
- [ ] AC3 — Invalid labels and rows with text fields are rejected by the validator (tests).
- [ ] AC4 — `evals/answer_judgments/` files contain no passage/answer text (a test scans them).
- [ ] AC5 — README "Human review" section. `make test-py` passes.
- [ ] AC6 — Diff < 400 lines.

## Verification
```bash
python3 -m pytest -q tests/test_evals_data.py -k review
make test-py
python3 scripts/answer_review.py --help
```

## Notes
- 2026-11-07 (pm-lead): from the 2026-11-07 plan (Phase 1 item 7, human-review half). The first real judging session needs a
  results file from a stack run (EVAL-3 workflow artifact) and a person. That session is Mahesh's, not an agent's. Wave 3.
