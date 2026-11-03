$ git diff 9c1229a...HEAD -- evals/README.md
diff --git a/evals/README.md b/evals/README.md
index cc8b769..cf42926 100644
--- a/evals/README.md
+++ b/evals/README.md
@@ -40,6 +40,18 @@ Decisions: [ADR-0006](https://github.com/MaheshPulivarthi18/arxivlens-agents/blo
   results record the production rerank path.
 - The baselines (BM25, dense, RRF without rerank) are scored the same way on their top 5 chunks. Dense and RRF only
   use embeddings for the current `EMBEDDING_MODEL`.
+- **Model name: two sources that must match.** The eval reads `EMBEDDING_MODEL` (`services/common/config.py`,
+  default `BAAI/bge-base-en-v1.5`) and records it as `embedding_model` in the results JSON. The Go query service
+  takes its model from its `--model` flag (default `BAAI/bge-base-en-v1.5`). If they differ, the eval scores
+  different vectors than production serves. The eval prints a warning when `EMBEDDING_MODEL` is not
+  `BAAI/bge-base-en-v1.5`; the warning does not fail the gate.
+- **Partly embedded papers are reported, not gated.** For every relevant paper the results JSON records
+  `chunk_coverage[arxiv_id] = {embedded_chunks, total_chunks}` for the current model, and the run prints a warning
+  for each paper with `embedded_chunks < total_chunks`. Such a paper still counts as indexed (making it fail the
+  gate needs an ADR).
+- The SQL parity test in `tests/test_evals_data.py` compares the RRF pool query with `internal/query/search.go`
+  (whole normalised query, explicit list of allowed differences, `RerankPool` = pool size) and fails if that file
+  is missing.
 
 Coverage is checked per arXiv ID. A paper counts as indexed only if it has chunks **with embeddings for the current
 model** (`chunk_embeddings.model`). A case is skipped unless every one of its `relevant_arxiv_ids` is indexed,

[exit code 0]
