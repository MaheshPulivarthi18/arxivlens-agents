#!/usr/bin/env bash
# AC1/AC2: real rag.go + rag_test.go from the PR head, stdlib-only scratch module, no network/DB/embedder.
set -e
SC=$1; bash "$(dirname "$0")/setup.sh" "$SC"
echo "== files under test: cmp scratch copy vs app/ at PR head =="
for f in rag.go rag_test.go; do cmp -s "$SC/internal/query/$f" "internal/query/$f" && echo "identical: internal/query/$f"; done
cd "$SC"; export GOTOOLCHAIN=local GOFLAGS=-mod=mod GOPROXY=off
go version
echo "== go vet ./internal/query/ =="; go vet ./internal/query/ && echo "vet ok"
echo "== gofmt -l internal/query (PR head) =="; (cd - >/dev/null; gofmt -l internal/query; echo "gofmt exit $?")
echo "== go test -race -count=1 -v ./internal/query/ (top-level results) =="
go test -race -count=1 -v ./internal/query/ 2>&1 | grep -E '^(=== RUN|--- (PASS|FAIL|SKIP)|PASS|FAIL|ok)' | grep -v '=== RUN'
echo "== counts =="
go test -count=1 -v ./internal/query/ 2>&1 > out.txt || true
echo "top-level PASS: $(grep -c '^--- PASS' out.txt)  subtests PASS: $(grep -c '^    --- PASS' out.txt)  FAIL: $(grep -c -- '--- FAIL' out.txt)  SKIP: $(grep -c -- '--- SKIP' out.txt)"
