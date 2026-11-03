#!/usr/bin/env bash
# AC2: PR head's real rag.go + rag_test.go in a stdlib-only scratch module, run inside a network namespace
# with no network (unshare -rn), no DB, no embedder. go vet, gofmt, verbose tests, validateCitations coverage.
set -e
SC=$1; bash "$(dirname "$0")/setup.sh" "$SC"
echo "== files under test: cmp scratch copy vs PR head =="
for f in rag.go rag_test.go; do cmp -s "$SC/internal/query/$f" "internal/query/$f" && echo "identical: internal/query/$f"; done
echo "== gofmt -l internal/query (PR head) =="; gofmt -l internal/query; echo "gofmt exit $? (no files listed = clean)"
cd "$SC"; export GOTOOLCHAIN=local GOFLAGS=-mod=mod GOPROXY=off
go version
unshare -rn bash -c '
set -e
echo "== network inside sandbox: interfaces in this netns (/proc/net/dev) + curl =="; awk "NR>2{print \$1}" /proc/net/dev; (curl -sS -m 3 https://proxy.golang.org >/dev/null 2>&1 && echo "network: REACHABLE") || echo "network: unreachable (as intended)"
echo "== go vet ./internal/query/ =="; go vet ./internal/query/ && echo "vet ok"
echo "== go test -race -count=1 -v -run FailClosed|SupportThreshold|ResponseShape ./internal/query/ =="
go test -race -count=1 -v -run "TestValidateCitationsFailClosedWhenUnverifiable|TestValidateCitationsSupportThreshold|TestAskResponseShapeAndConstructor" ./internal/query/ 2>&1 | grep -v "^=== RUN"
echo "== full package, counts =="
go test -count=1 -v ./internal/query/ > out.txt 2>&1 || true
echo "top-level PASS: $(grep -c "^--- PASS" out.txt)  subtests PASS: $(grep -c "^    --- PASS" out.txt)  FAIL: $(grep -c -- "--- FAIL" out.txt)"; tail -1 out.txt
echo "== coverage: go tool cover -func (rag.go rows) =="
go test -count=1 -coverprofile=c.out ./internal/query/ >/dev/null; go tool cover -func=c.out | grep rag.go
'
