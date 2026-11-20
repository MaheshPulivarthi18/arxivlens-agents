$ git diff origin/main...HEAD -- README.md
diff --git a/README.md b/README.md
index 36cb674..c4ba087 100644
--- a/README.md
+++ b/README.md
@@ -183,11 +183,18 @@ arxivlens crawl    [--query "cat:cs.AI OR cat:cs.LG"] [--limit 5] [--rate-limit
 arxivlens download [--group downloader-v1]
 arxivlens status   --arxiv-id <id>
 arxivlens query    [--port 8080] [--embedder-url http://localhost:8081] [--model BAAI/bge-base-en-v1.5]
-arxivlens dlq list    [--topic papers.downloaded.dlq] [--limit 50]
+arxivlens dlq list    [--topic papers.downloaded.dlq] [--partition P] [--from P/O] [--page-size 50] [--all]
 arxivlens dlq inspect [--topic ...] [--key <arxiv_id>]
 arxivlens dlq replay  [--topic ...] [--error-type PdfParseError] [--limit 100] [--dry-run]
 ```
 
+`dlq list` and `dlq inspect` read up to the high watermarks taken when the run starts (no consumer group, nothing committed).
+Each record line starts with `P/O` (partition/offset); an undecodable record prints `P/O  UNDECODABLE (n bytes)`. `dlq list`
+prints `--page-size` records (default 50; `--limit` is an alias) and ends with `next page: arxivlens dlq list --topic T --from P/O`
+or `end of topic (high watermarks at start: 0=H0 1=H1 ...; N records)`, where N is the number of records listed in this run.
+`--all` prints every page in one run. `inspect` scans the whole topic and stops at the first `--key` match. Expired offsets
+(`WARNING partition P: offsets a..b expired`) go to stderr. A missing topic, a poll error or a stalled partition exits non-zero.
+
 ---
 
 ## Configuration

[exit code 0]
