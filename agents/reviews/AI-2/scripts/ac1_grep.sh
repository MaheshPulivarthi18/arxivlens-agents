#!/usr/bin/env bash
# AC1: every assignment to `supported` in rag.go, on origin/main (before) and PR head (after).
echo "== ticket command: grep -n \"supported = true\" internal/query/rag.go (PR head) =="
grep -n "supported = true" internal/query/rag.go; echo "grep exit $? (1 = no match)"
echo "== all assignments to supported / Supported / score in rag.go, PR head =="
grep -nE '\bsupported\s*:?=|Supported:|\bscore\s*:?=' internal/query/rag.go
echo "== same, origin/main (before) =="
git show origin/main:internal/query/rag.go | grep -nE '\bsupported\s*:?=|Supported:|\bscore\s*:?=|0\.75'
echo "== literal 0.75 in rag.go code at PR head (comments stripped) =="
sed 's|//.*||' internal/query/rag.go | grep -n '0\.75'; echo "grep exit $? (1 = no match)"
echo "== SupportThreshold definition: main vs head =="
git show origin/main:internal/query/rag.go | grep -n 'SupportThreshold *='; grep -n 'SupportThreshold *=' internal/query/rag.go
