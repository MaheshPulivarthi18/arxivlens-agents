$ bash -c git diff -U0 origin/main...706e43e -- README.md CONTRIBUTING.md | grep -E '^[-+][^-+]' | cut -c1-400; echo; echo '--- Makefile test-py line:'; sed -n 49p Makefile; echo; echo '--- README row contains the Scope wording exactly:'; grep -c "\`page\` is the page the chunk's text starts on, when recorded; omitted otherwise (ADR-0014)" README.md; echo '--- changed lines (added+deleted):'; git diff --numstat origin/main...706e43e | awk '{a+=$1; d+=$2} END {print a"+"d" = "a+d}'
-| `make test-unit` | Go tests + `pytest tests/test_m0.py tests/test_evals_data.py tests/test_worker_heartbeat.py` | No |
+| `make test-unit` | Go tests + `pytest tests/test_m0.py tests/test_evals_data.py tests/test_worker_heartbeat.py tests/test_processor_pages.py tests/test_verify.py tests/test_arxiv_replay.py` | No |
-| `POST` | `/v1/search` | Hybrid search: `{query, categories?, limit?, rerank?}` → `{query, count, hits: [{chunk_id, arxiv_id, version, title, section, content, rrf_score, rerank_score?, page?}]}`. `version` is the arXiv version recorded for the chunk's paper; `page` is omitted until chunk pages are recorded reliably (ADR-0014) |
+| `POST` | `/v1/search` | Hybrid search: `{query, categories?, limit?, rerank?}` → `{query, count, hits: [{chunk_id, arxiv_id, version, title, section, content, rrf_score, rerank_score?, page?}]}`. `version` is the arXiv version recorded for the chunk's paper; `page` is the page the chunk's text starts on, when recorded; omitted otherwise (ADR-0014) |

--- Makefile test-py line:
	$(PYTEST) -q tests/test_m0.py tests/test_evals_data.py tests/test_worker_heartbeat.py tests/test_processor_pages.py tests/test_verify.py tests/test_arxiv_replay.py

--- README row contains the Scope wording exactly:
1
--- changed lines (added+deleted):
114+25 = 139

[exit code 0]
