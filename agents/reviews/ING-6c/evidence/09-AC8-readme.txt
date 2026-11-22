$ bash -c git diff origin/main...HEAD -- README.md | grep '^[+-]' ; echo; grep -n 'pgvector' docker-compose.yml
--- a/README.md
+++ b/README.md
+- PostgreSQL 16 + **pgvector ≥ 0.8.0** (search uses `hnsw.iterative_scan`); `docker-compose.yml` pins an image with 0.8.7, so this matters only for your own database
+arxivlens crawl-loop [--categories cs.AI,cs.LG] [--interval 6h] [--limit-per-run 100] [--max-scan 2000] [--once]
+**Scheduled crawl.** `crawl-loop` runs a pass every `--interval` (at least `1m`, counted from the end of a pass; SIGINT/SIGTERM
+stop it cleanly). Per category it lists arXiv newest-first down to the category's watermark (table `crawl_watermarks`), publishes
+`papers.discovered` for at most `--limit-per-run` new papers, oldest first, and moves the watermark only past papers Kafka acked. So a
+pass with nothing new emits nothing, and a crash or kill re-emits some papers (absorbed by the idempotent pipeline) but never skips one.
+- **First run** of a category (no watermark) takes only its newest `--limit-per-run` papers; backfill older ones with `arxivlens crawl --query`.
+- **One instance per database**: a second `crawl-loop` exits with `another crawl-loop is running` (PostgreSQL advisory lock), so arXiv
+  sees one process at ≤ 1 request / 3 s. `--once` runs one pass and exits non-zero if any category failed.
+- Each pass logs one line per category: `[CrawlLoop] cat=cs.LG pages=1 scanned=2 candidates=0 emitted=0 backlog=0 out_of_order=0 watermark=… (unchanged)`.
+  `backlog=` > 0 means more new papers than `--limit-per-run`; they wait for the next pass. If it stays > 0, raise `--limit-per-run`
+  (and `--max-scan`, which must be ≥ it). A backlog deeper than `--max-scan` fails the category loudly instead of skipping papers.
+  `out_of_order=` counts feed entries newer than the one before them (arXiv's order is assumed newest-first; this checks it).
+- **Reset a category** (the next pass is a first run again): `DELETE FROM crawl_watermarks WHERE category = 'cs.LG';`
+- **Known gap**: a paper arXiv announces late (e.g. after moderation) with a `published` time already below the watermark is never
+  picked up by `crawl-loop`; fetch it with `arxivlens crawl` or on-demand ingest. A lookback window is planned (ING-6e).
+

36:    # pgvector >= 0.8.0 required (hnsw.iterative_scan); this digest ships 0.8.7. Same pin as .github/workflows/db.yml.
38:    image: pgvector/pgvector:pg16@sha256:484e838076e04939d27d3e176e91c86eea96236126023be8d3059761122e579f

[exit code 0]
