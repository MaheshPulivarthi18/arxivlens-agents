$ bash -c git diff origin/main...HEAD -- evals/README.md | grep '^+' ; python3 scripts/answer_review.py --help
+++ b/evals/README.md
+| `answer_judgments/` | `<run-id>.jsonl` human review labels, IDs only (EVAL-7, see Human review) | — |
+## Human review of answers (EVAL-7, report-only)
+Cosine ≥ 0.50 says a sentence and a passage are related, not that the passage supports it. `scripts/answer_review.py`
+lets a person check, and its numbers are the evidence for or against an entailment verifier (ADR-0014). Not gated.
+
+- **Who:** Mahesh or a reviewer he names. Agents never fill in judgments; tests use synthetic fixtures only.
+- **Export** (query service up on the run's corpus): `python3 scripts/answer_review.py export --results
+  evals/results/<run-id>.json [--db-url ...]`. Results hold no text, so each answered case is asked again for the claim
+  text; a case whose (marker, chunk_id) pairs differ from the results is skipped as drifted. Passage text is looked up
+  by `chunk_id` in that response, or in Postgres with `--db-url`. It writes `evals/results/<run-id>.review.md` to read
+  and `<run-id>.judgments.jsonl` to fill: one row per (claim or sentence, cited marker); uncited sentences get none.
+- **Keep it blind:** the sheet hides `score`, `supported` and `status`. Don't open the results JSON or the UI for that
+  run until you're done. Judge each claim against its passage only.
+- **Labels:** `supports` = `yes | partial | no | contradicts`; `claim_correct` = `yes | no | unsure` (one value per
+  claim); `reviewer`; `date` (`YYYY-MM-DD`); optional `notes` (local only). `supports: null` = unjudged (counted, not rated).
+- **How long (estimate):** a template answer cites 2 sentences, so a 20-case run is about 40 rows, 20–40 minutes at
+  30–60 s a row; LLM answers (QA-8) have more. Replace this with the measured time after the first session.
+- **Score:** `python3 scripts/answer_review.py score --judgments <file> --results evals/results/<run-id>.json` prints
+  citation precision (`yes` / judged), partial and contradiction rates, claim correctness (`yes` / judged claims),
+  judged/unjudged counts and the confusion matrix of human `supports` × system `supported`.
+- **Where judgments go:** `--save evals/answer_judgments/` writes `<run-id>.jsonl` to commit: IDs and labels only (case,
+  unit, marker, chunk and arXiv IDs, labels, reviewer, date), never passage, answer or notes text (public repo; arXiv
+  licences vary). A test rejects any other key. Keep the run's results JSON (or EVAL-3 artifact) for the matrix.
+
usage: answer_review.py [-h] {export,score} ...

Blind human review of /v1/ask answers (EVAL-7, report-only).

positional arguments:
  {export,score}
    export        Write a blind review sheet + empty judgments file for a
                  results JSON
    score         Score a judgments JSONL

options:
  -h, --help      show this help message and exit

[exit code 0]
