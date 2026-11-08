$ bash -c git diff --shortstat d3f9408...HEAD; git diff --numstat d3f9408...HEAD | awk "{s+=\$1+\$2} END {print \"changed lines:\", s}"; echo; git diff -U0 d3f9408...HEAD -- README.md | grep "^[-+]|" | fold -w 140; echo; echo "condition 2 phrases:"; grep -c "arXiv version recorded for the chunk.s paper" README.md; grep -c "page. is omitted until chunk pages are recorded reliably (ADR-0014)" README.md; echo "route still in server.go:"; grep -n "/v1/search" internal/query/server.go
 6 files changed, 377 insertions(+), 7 deletions(-)
changed lines: 384

-| `POST` | `/v1/search` | Hybrid search: `{query, categories?, limit?, rerank?}` |
+| `POST` | `/v1/search` | Hybrid search: `{query, categories?, limit?, rerank?}` → `{query, count, hits: [{chunk_id, arxiv_id, version, t
itle, section, content, rrf_score, rerank_score?, page?}]}`. `version` is the arXiv version recorded for the chunk's paper; `page` is omitte
d until chunk pages are recorded reliably (ADR-0014) |

condition 2 phrases:
1
1
route still in server.go:
70:	mux.HandleFunc("POST /v1/search", s.handleSearch)

[exit code 0]
