$ bash -c echo '== README.md hunk location (Testing block):'; git diff -U0 origin/main...HEAD -- README.md | grep '^@@'; sed -n '213,215p' README.md | cut -c1-60; echo; echo '== eval.yml triggers / artifact name:'; grep -n -E '^on:|workflow_dispatch|schedule|cron|name: eval-results' .github/workflows/eval.yml; echo; echo '== FusionK / FUSION_K and fusion formula:'; grep -n -E '^const FusionK|^FUSION_K' internal/query/search.go scripts/evaluate_retrieval.py; grep -n 'key\[i\] = ' internal/query/search.go; echo; echo '== RET-1 merge commit:'; git log --oneline -1 bb9ee90; echo; echo '== ADR files linked from evals/README.md exist (+status):'; for f in $(grep -o -E 'adr/[0-9]{4}-[a-z0-9-]+\.md' evals/README.md | sort -u); do printf '%s: ' $f; grep -m1 -o -E 'Status:\*\* [A-Za-z]+' /home/claude/arxivlens-agents/docs/$f || echo MISSING; done; echo; echo '== make targets named in BASELINE.md commands:'; grep -n -E '^(setup-py|build-go|stack-up|migrate|eval-seed|eval):' Makefile | cut -c1-70; echo; echo '== evals/README.md hunks (Running / What the gate measures only):'; git diff -U0 origin/main...HEAD -- evals/README.md | grep '^@@'
== README.md hunk location (Testing block):
@@ -219,0 +220 @@ make eval                                  # Quality gate vs Product PRD §8 (sc
## Testing, evaluation and benchmarks

```bash

== eval.yml triggers / artifact name:
5:on:
6:  workflow_dispatch:
7:  schedule:
8:    - cron: "17 6 * * *"
165:          name: eval-results-${{ github.run_id }}

== FusionK / FUSION_K and fusion formula:
internal/query/search.go:35:const FusionK = 10
scripts/evaluate_retrieval.py:111:FUSION_K = 10
275:		key[i] = 1/float64(FusionK+rank+1) + 1/float64(FusionK+i+1)

== RET-1 merge commit:
bb9ee90 Merge pull request #9 from MaheshPulivarthi18/agent/backend/RET-1

== ADR files linked from evals/README.md exist (+status):
adr/0006-recall-at-5-definition.md: Status:** Accepted
adr/0010-ask-sorts-by-rerank.md: Status:** Accepted
adr/0016-top5-paper-diversity.md: Status:** Accepted
adr/0017-rerank-rank-fusion.md: Status:** Accepted

== make targets named in BASELINE.md commands:
17:setup-py: ## Install Python deps into the active environment
26:build-go: ## Build bin/arxivlens
68:stack-up: ## Infra + processor, embedder worker, embedder API (:808
82:migrate: build-go ## Apply DB schema
86:eval: ## Retrieval/answer eval; uses the gate from EVAL-1 when pres
97:eval-seed: ## Ingest every evals/corpus.txt ID via the query API (E

== evals/README.md hunks (Running / What the gate measures only):
@@ -24,0 +25,4 @@ python3 scripts/evaluate_answers.py      # /v1/ask only (ARXIVLENS_API_URL, defa
@@ -44,2 +48,4 @@ Decisions: [ADR-0006](https://github.com/MaheshPulivarthi18/arxivlens-agents/blo
@@ -52,5 +58,5 @@ Decisions: [ADR-0006](https://github.com/MaheshPulivarthi18/arxivlens-agents/blo

[exit code 0]
