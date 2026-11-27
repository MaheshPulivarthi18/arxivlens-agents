$ bash -c git diff origin/main...HEAD -- README.md
diff --git a/README.md b/README.md
index fa71582..da8e04d 100644
--- a/README.md
+++ b/README.md
@@ -180,14 +180,14 @@ curl -s localhost:8080/v1/ask -H 'content-type: application/json' \
 
 ```
 arxivlens migrate  [--dir migrations] [--file <one .up.sql>]
-arxivlens crawl    [--query "cat:cs.AI OR cat:cs.LG"] [--limit 5] [--rate-limit 3s]
+arxivlens crawl    [--query "cat:cs.AI OR cat:cs.LG"] [--limit 5] [--rate-limit 3s]   # --rate-limit below 3s is rejected
 arxivlens crawl-loop [--categories cs.AI,cs.LG] [--interval 6h] [--limit-per-run 100] [--max-scan 2000] [--once]
 arxivlens download [--group downloader-v1]
 arxivlens status   --arxiv-id <id>
 arxivlens query    [--port 8080] [--embedder-url http://localhost:8081] [--model BAAI/bge-base-en-v1.5]
 arxivlens dlq list    [--topic papers.downloaded.dlq] [--partition P] [--from P/O] [--page-size 50] [--all]
 arxivlens dlq inspect [--topic ...] [--key <arxiv_id>]
-arxivlens dlq replay  [--topic ...] [--error-type PdfParseError] [--limit 100] [--dry-run]
+arxivlens dlq replay  [--topic ...] [--error-type PdfParseError] [--limit 100] [--dry-run]   # needs a migrated PostgreSQL
 ```
 
 **Scheduled crawl.** `crawl-loop` runs a pass every `--interval` (at least `1m`, counted from the end of a pass; SIGINT/SIGTERM
@@ -207,10 +207,24 @@ pass with nothing new emits nothing, and a crash or kill re-emits some papers (a
 
 `dlq list` and `dlq inspect` read up to the high watermarks taken when the run starts (no consumer group, nothing committed).
 Each record line starts with `P/O` (partition/offset); an undecodable record prints `P/O  UNDECODABLE (n bytes)`. `dlq list`
-prints `--page-size` records (default 50; `--limit` is an alias) and ends with `next page: arxivlens dlq list --topic T --from P/O`
-or `end of topic (high watermarks at start: 0=H0 1=H1 ...; N records)`, where N is the number of records listed in this run.
+prints `--page-size` records (default 50; `--limit` is an alias) and ends with
+`next page: arxivlens dlq list --topic T [--partition P] [--page-size N] --from P/O` (the optional flags only when given, so the line
+can be pasted as-is) or `end of topic (high watermarks at start: 0=H0 1=H1 ...; N records)`, where N is the number of records listed in this run.
 `--all` prints every page in one run. `inspect` scans the whole topic and stops at the first `--key` match. Expired offsets
 (`WARNING partition P: offsets a..b expired`) go to stderr. A missing topic, a poll error or a stalled partition exits non-zero.
+`inspect` on an empty topic prints `No DLQ events in topic: <T>`. Every error is printed once, as `Error: ...`.
+
+**DLQ replay.** `dlq replay` republishes the DLQ's unresolved records, in partition then offset order, up to the high watermarks
+taken at the start, with `attempt` reset to 0. It keeps its progress in PostgreSQL (`dlq_replay_checkpoints`, `dlq_replay_log`,
+migration `000004`), so it needs `DATABASE_URL` and `arxivlens migrate`; without them it fails before reading Kafka.
+- **Resumable:** repeated `--limit N` runs work through the whole DLQ; each record is resolved once (replayed, or
+  `unreplayable` when there is nothing valid to republish). A record is marked resolved only after the broker acked its publish,
+  so a crash re-publishes at most that record, with the same `event_id` for a full envelope (the consumers' idempotency absorbs it).
+- **Filters:** with `--error-type X`, records of other types stay unresolved and the next run without the filter picks them up.
+- **Run `--dry-run` first after deploy:** the first run has no checkpoint and replays everything still in retention. A dry run
+  lists each would-be `P/O` and `event_id` under `DRY RUN`, writes nothing and publishes nothing.
+- **Don't run two replays of the same DLQ at once** (a lock that refuses the second run is coming in B-PIPE-2).
+- **Reset a DLQ** (replay everything again): `DELETE FROM dlq_replay_log WHERE dlq_topic = $1; DELETE FROM dlq_replay_checkpoints WHERE dlq_topic = $1;`
 
 ---
 

[exit code 0]
