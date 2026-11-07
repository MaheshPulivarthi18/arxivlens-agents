# EVAL-6: Answer eval understands ADR-0003 refusals; report-only citation coverage and an in-domain near-miss refusal set

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P1 (harness/quality: Phase 1 exit criterion "the evaluation suite measures answer quality") |
| **PRD ref** | Product PRD §8 (supported-citation and correct-refusal rows), QA-4, QA-5; ADR-0003 (Accepted: case B counts as an error) |
| **Depends on** | EVAL-1 (merged). None open. Must merge **before** AI-7 (see AI-7 Notes). |
| **Jira** | new story under epic KAN-2 "Retrieval & answer quality gates" (`labels = "task-EVAL-6"`) |
| **Design required** | no: no gate key or threshold changes, and no contract change. Metric definitions go in `evals/README.md` and pm-lead checks them in review. |
| **Status** | Done: ArxivLens #20 merged by Mahesh → `1273a3b` (KAN-37) |

## Goal
Make the answer eval correct for the answers Phase 1 will produce, and add the first answer-quality numbers that don't
need a human: does every statement carry a citation, and does `/v1/ask` refuse questions that sound like the corpus but
aren't answered by it? Human judgments (citation precision, claim correctness) come in EVAL-7.

## Scope
- `scripts/evaluate_answers.py`:
  - `is_refusal`: a response with `refusal_reason == "all_citations_unsupported"` **is a refusal** even though it carries
    evidence citations. A response with `refusal_reason == "verification_unavailable"` is an **error** (ADR-0003): it counts in
    `ask_error_count`, plus a new `verification_unavailable_count`, and never as a correct refusal. An unknown
    `refusal_reason` value is an error too (fail closed).
  - `supported_citation_rate` counts only citations of **answered** responses (no `refusal_reason`). A refusal's evidence
    passages are not answer citations. This is pm-lead's reading of ADR-0003, so the PR description asks Mahesh to confirm it.
  - New report-only metrics: `citation_coverage` (over answered responses: the share of answer sentences, or `claims[]`
    items when present, with ≥ 1 in-range citation marker; document the sentence splitter used), `refusal_reason_counts`,
    and `near_miss_correct_refusal_rate`.
  - Per-case records in the output (case id, refused or not, reason, citation `arxiv_id`/`chunk_id`/`marker`/`supported`/`score`,
    latency) for EVAL-7's review export. **No passage or answer text** goes in the results, because CI artifacts of this public repo are downloadable.
- `scripts/eval_gate.py`: print the new metrics in a "report-only" block. No new key in `check_thresholds`.
- New `evals/refusal_near_miss.jsonl`: ≥ 10 in-domain questions (ML/IR topics) whose answering paper is **not** in
  `evals/corpus.txt`. Each row: `id`, `question`, `answered_by` (arXiv ID of the paper that would answer it), `why_near`
  (which corpus paper it resembles), and `reviewed_by: null`. A test asserts no `answered_by` ID is in the corpus. Rows
  are unreviewed drafts until a human sets `reviewed_by` (protocol in README). Because the metric is report-only, an
  unreviewed row can't change a gate.
- `tests/test_evals_data.py` (already in `make test-py`, so no Makefile change): fixture `AskFn` cases for every branch above.
- `evals/README.md`: definitions of each new metric, the ADR-0003 classification table, and a short "human review" note
  (who reviews the near-miss rows, what `reviewed_by` means).
- Out of scope: `evals/thresholds.json` (unchanged; promoting any new metric to a gate needs an ADR), `rag.go`, the Go
  side, real-LLM runs (EVAL-8), human judgments (EVAL-7).

## Acceptance criteria
- [x] AC1 — Classification tests with fixture responses: A-refusal → correct refusal on the refusal set and `answer_refusal` on the answer set;
      B → error (`ask_error_count` and `verification_unavailable_count` +1), never a refusal; unknown reason → error; early refusal (`citations: []`) → refusal as today.
- [x] AC2 — `supported_citation_rate` excludes refusal evidence: a run with one answered response (2/2 supported) and one A-refusal
      (3 unsupported evidence passages) reports 1.0, not 0.4.
- [x] AC3 — `citation_coverage` unit tests: all sentences cited → 1.0; one of three uncited → 0.667; `claims[]` present → computed from claims; no answered responses → reported as null, not 0 or 1.
- [x] AC4 — `evals/refusal_near_miss.jsonl` has ≥ 10 valid rows; the test fails if any `answered_by` is in `evals/corpus.txt` or a field is missing.
- [x] AC5 — Results JSON per-case records hold IDs and numbers only (a test asserts no key named `answer`/`content`/`text` in them).
- [x] AC6 — Gates unchanged: `git diff origin/main -- evals/thresholds.json` is empty and `check_thresholds` returns the same check names as before (test).
- [x] AC7 — `make test-py` passes. `make eval` run on the stack (after EVAL-3), or "not run: no stack in sandbox" with the exact command.
- [x] AC8 — `evals/README.md` defines every new metric and the ADR-0003 table.

## Verification
```bash
make lint
python3 -m pytest -q tests/test_evals_data.py
make test-py
python3 scripts/eval_gate.py --help
git diff origin/main -- evals/thresholds.json
make eval   # needs the stack (EVAL-3 workflow or make stack-up)
```

## Notes
- 2026-11-07 (pm-lead): specced from the 2026-11-07 plan (Phase 1 item 7, automatic half). Sandbox: Python stdlib tests run
  locally. PyPI and arxiv.org are unreachable, so don't fetch papers to write rows; `answered_by` is checked against
  `corpus.txt` only, and a human confirms the rest via `reviewed_by`.
- Wave 1. Files are disjoint from AI-7 (rag.go/README), LLM-1, EVAL-3 (eval.yml/Makefile/CONTRIBUTING).
- 2026-11-07 (ai-engineer): built on `agent/ai/EVAL-6` (commit `4dc4846`, not pushed). `classify()` handles ADR-0003 A/B/unknown;
  supported rate covers answered responses only; report-only `citation_coverage` (rag.go sentence splitter port, abbreviation
  list drift-guarded), `refusal_reason_counts`, `verification_unavailable_count`, `near_miss_correct_refusal_rate` (near-miss calls
  are kept out of gated latency/errors); per-case records hold IDs and numbers only. 15 near-miss rows, `reviewed_by: null`;
  **arXiv IDs come from memory and were not checked online** (arxiv.org blocked), so a human reviewer must confirm them.
  `tests/test_evals_data.py`: 75 passed, 1 skipped; each new branch was mutation-checked. `make test-py`/`make lint` fail in the sandbox
  for environmental reasons (no confluent_kafka/torch; Go 1.25 download blocked), same on origin/main. `make eval` not run: no stack in sandbox
  (`make eval`). Diff is 443 lines (ownership-check warns at > 400). PR must ask Mahesh to confirm the supported-rate reading of ADR-0003.
- 2026-11-07 (pm-lead, final review): **APPROVE** on `4dc4846` after QA PASS r1 (`agents/reviews/EVAL-6/report.md`). 443 lines accepted without a
  rule exception (182 are tests). QA [spec] decisions: (5) `eval.yml` keeps its PR path filter; once EVAL-3 merges, answering/retrieval PRs get one
  `workflow_dispatch` run on their branch (*Proposed* rules item, board Backlog); (6) the near-miss rows are reviewed by Mahesh or someone he names
  (n005, n009 first), and ai-engineer then commits the `reviewed_by` values; (7) the supported-rate reading is in the PR's "Decisions for Mahesh", and merging confirms it.
  QA nits 1 and 2 plus the missing tests → Backlog follow-up (ai, P3). PRD §8 row method text → pending pm-lead docs PR.
- 2026-11-07 11:00Z (pm-lead, grooming): merged by Mahesh as `1273a3b` (#20); Jira Done. EVAL-7 and RET-2's EVAL-6 dependency are cleared.
