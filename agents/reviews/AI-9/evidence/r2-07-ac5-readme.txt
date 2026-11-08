$ bash -c git diff origin/main...HEAD -- README.md; echo; echo '== env reads in services/embedder/api.py =='; grep -nE 'getenv|environ' services/embedder/api.py; echo; grep -n 'RERANK_BATCH_SIZE' services/embedder/api.py
diff --git a/README.md b/README.md
index 4e63b0c..5a79b6e 100644
--- a/README.md
+++ b/README.md
@@ -201,6 +201,7 @@ All services read the same environment variables (defaults target the local Dock
 | `MINIO_USE_SSL` (Go) / `MINIO_SECURE` (Python) | `false` |
 | `EMBEDDING_MODEL` | `BAAI/bge-base-en-v1.5` |
 | `INGEST_TIMEOUT` (Go query service) | `5m`: limit for the synchronous chunk + embed call of `POST /v1/papers/ingest` (Go duration) |
+| `EMBEDDER_TORCH_THREADS` (embedder API) | Cores available to the process: CPU threads for torch (`torch.set_num_threads`). Invalid or non-positive values fall back to the default. Logged at startup as `torch threads: A -> B` |
 
 > ⚠️ The default credentials are for local development only. Override them with your own values (e.g. a git-ignored `.env`) before deploying anywhere.
 

== env reads in services/embedder/api.py ==
42:    raw = os.getenv("EMBEDDER_TORCH_THREADS", "").strip()

37:RERANK_BATCH_SIZE = 8
58:                batch_size: int = RERANK_BATCH_SIZE) -> Tuple[List[float], dict]:

[exit code 0]
