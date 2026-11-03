#!/usr/bin/env bash
# Test quality: run the PR head's rag_test.go against origin/main's (fail-open) rag.go. The new test must FAIL there.
SC=$1; bash "$(dirname "$0")/setup.sh" "$SC" || exit 1
git show origin/main:internal/query/rag.go > "$SC/internal/query/rag.go"
echo "rag.go under test = origin/main $(git rev-parse --short origin/main); rag_test.go = PR head $(git rev-parse --short HEAD)"
cd "$SC"; export GOTOOLCHAIN=local GOFLAGS=-mod=mod GOPROXY=off
go test -count=1 -v -run TestValidateCitationsFailClosedWhenUnverifiable ./internal/query/ 2>&1 | grep -v '^=== RUN' | cut -c1-200
echo "go test exit: ${PIPESTATUS[0]}"
