$ git diff origin/main...HEAD -- evals/README.md
diff --git a/evals/README.md b/evals/README.md
index 3896bc0..5643f06 100644
--- a/evals/README.md
+++ b/evals/README.md
@@ -104,6 +104,7 @@ applies. Every quality check is gated on every machine, and so is a missing p95.
 | Response | Outcome | Refusal set | Answer set |
 |---|---|---|---|
 | request failed (HTTP error, timeout, bad JSON) | error | `ask_error_count` +1, not refused | `ask_error_count` +1 |
+| malformed response (body not an object, `citations` not a list, a non-object citation, a non-string citation `arxiv_id`) | **error** | `ask_error_count` +1, not refused | `ask_error_count` +1 |
 | no `refusal_reason`, `citations: []` (early refusal, QA-5) | refusal | correct refusal | `answer_refusal_rate` |
 | `refusal_reason: "all_citations_unsupported"` (case A, carries evidence) | refusal | correct refusal | `answer_refusal_rate` |
 | `refusal_reason: "verification_unavailable"` (case B) | **error** | `ask_error_count` and `verification_unavailable_count` +1, not refused | same |
@@ -122,7 +123,9 @@ Promoting one to a gate needs an ADR and a key in `thresholds.json`.
   citation. The server drops markers outside 1..K, so only in-range markers get a citation. Sentences come from
   `split_sentences()`, a port of `splitIntoSentences` in `internal/query/rag.go`: a sentence ends at `.`, `!` or `?`
   followed by a space or the end of the text, unless it ends with `e.g.`, `i.e.`, `et al.`, `cf.`, `vs.`, `fig.` or
-  `eq.` (a test checks that list against `rag.go`). The value is `null` when there are no answered responses.
+  `eq.` (a test checks that list against `rag.go`). The value is `null` when there are no answered responses. Malformed
+  `claims` (an item that isn't an object, `markers` that isn't a list of integers) count as uncited units, and a
+  citation `marker` that isn't an integer is ignored; neither changes the outcome.
 - **`refusal_reason_counts`**: how many responses carried each `refusal_reason` value, over all three sets. String
   values only: a non-string `refusal_reason` (e.g. a list or a number) is not counted here; it counts as an error.
 - **`verification_unavailable_count`**: ADR-0003 case B responses in the answer and refusal sets (also in `ask_error_count`).

[exit code 0]
