$ git diff origin/main...HEAD -- evals/README.md
diff --git a/evals/README.md b/evals/README.md
index e97cd65..3896bc0 100644
--- a/evals/README.md
+++ b/evals/README.md
@@ -123,7 +123,8 @@ Promoting one to a gate needs an ADR and a key in `thresholds.json`.
   `split_sentences()`, a port of `splitIntoSentences` in `internal/query/rag.go`: a sentence ends at `.`, `!` or `?`
   followed by a space or the end of the text, unless it ends with `e.g.`, `i.e.`, `et al.`, `cf.`, `vs.`, `fig.` or
   `eq.` (a test checks that list against `rag.go`). The value is `null` when there are no answered responses.
-- **`refusal_reason_counts`**: how many responses carried each `refusal_reason` value, over all three sets.
+- **`refusal_reason_counts`**: how many responses carried each `refusal_reason` value, over all three sets. String
+  values only: a non-string `refusal_reason` (e.g. a list or a number) is not counted here; it counts as an error.
 - **`verification_unavailable_count`**: ADR-0003 case B responses in the answer and refusal sets (also in `ask_error_count`).
 - **`near_miss_correct_refusal_rate`** = refused / all rows of `refusal_near_miss.jsonl`, classified as above (errors
   and B count as not refused); `null` when the set is empty. Near-miss calls are kept out of the gated latency and
@@ -132,8 +133,8 @@ Promoting one to a gate needs an ADR and a key in `thresholds.json`.
   `cited_units`/`total_units` (answered only), and per citation `arxiv_id`, `chunk_id`, `marker`, `supported`, `score`.
   **No question, passage or answer text is saved**, because CI artifacts of this public repo can be downloaded.
 - **Summary IDs** (EVAL-10): the printed `/v1/ask` summary in the job log lists the case IDs behind the misses, as
-  `refused IDs` (`answer_refused_ids`), `miss IDs` (`expected_paper_miss_ids`: refusals plus wrong-paper answers) and
-  `near-miss answered IDs` (`near_miss_failure_ids`, errors included). Each line is printed only when it has IDs, and it holds IDs only, no text.
+  `refused IDs` (`answer_refused_ids`), `miss IDs` (`expected_paper_miss_ids`: refusals, errored calls and
+  wrong-paper answers) and `near-miss answered IDs` (`near_miss_failure_ids`, errors included). Each line is printed only when it has IDs, and it holds IDs only, no text.
 
 ### Near-miss rows and human review
 `refusal_near_miss.jsonl` holds in-domain (ML/IR) questions that sound like the corpus but are answered by a paper

[exit code 0]
