#!/usr/bin/env bash
# Scope + AC3: files changed, exported API / JSON tags / constants of rag.go on main vs PR head, thresholds untouched.
echo "== git diff --stat origin/main...HEAD =="; git diff --stat origin/main...HEAD
echo "== changed files vs ai-engineer owned paths (AGENTS.md §2: internal/query/rag.go + rag_test.go) =="
git diff --name-only origin/main...HEAD | while read f; do case "$f" in internal/query/rag.go|internal/query/rag_test.go) echo "owned: $f";; *) echo "NOT OWNED: $f";; esac; done
echo "== untouched contracts (no diff expected) =="
for f in internal/query/server.go internal/query/search.go evals/thresholds.json shared/events/events.go README.md cmd/arxivlens/main.go; do
  n=$(git diff --numstat origin/main...HEAD -- "$f" | wc -l); echo "$f: $([ "$n" = 0 ] && echo unchanged || echo CHANGED)"; done
sig() { local t; t=$(cat); printf '%s\n' "$t" | awk '/^func \([^)]*\) [A-Z]/{p=1} p{print} p&&/\{$/{p=0}'; printf '%s\n' "$t" | grep -E '^(func|type|const|var) [A-Z]|^[[:space:]]+[A-Z][A-Za-z]+[[:space:]]+[^[:space:]]+[[:space:]]+`json|^[[:space:]]+[A-Z][A-Za-z]+[[:space:]]+=[[:space:]]'; }
echo "== exported decls, JSON tags, constants: origin/main vs HEAD (diff; empty = identical) =="
diff <(git show origin/main:internal/query/rag.go | sig) <(sig < internal/query/rag.go) && echo "(identical)"
echo "== HEAD exported surface of rag.go =="; sig < internal/query/rag.go
nocomment() { sed 's|//.*||'; }
echo "== numeric literals in rag.go code (comments stripped): main vs HEAD =="
diff <(git show origin/main:internal/query/rag.go | nocomment | grep -oE '[0-9]+\.[0-9]+' | sort | uniq -c) <(nocomment < internal/query/rag.go | grep -oE '[0-9]+\.[0-9]+' | sort | uniq -c) && echo "(identical)"
nocomment < internal/query/rag.go | grep -oE '[0-9]+\.[0-9]+' | sort | uniq -c
