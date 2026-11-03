#!/usr/bin/env bash
# AC2: statement coverage of rag.go only (package total also includes client.go/search.go, untested here).
set -e
SC=$1; bash "$(dirname "$0")/setup.sh" "$SC"; cd "$SC"; export GOTOOLCHAIN=local GOFLAGS=-mod=mod GOPROXY=off
go test -count=1 -cover -coverprofile=c.out ./internal/query/
echo "== go tool cover -func (rag.go rows) =="
go tool cover -func=c.out | grep 'rag.go'
echo "== rag.go statements covered (from c.out) =="
awk -F'[ :]' 'NR>1 && $1 ~ /rag.go$/ {n=$(NF-1); t+=n; if ($NF>0) c+=n} END {printf "rag.go: %d/%d statements = %.1f%%\n", c, t, 100*c/t}' c.out
echo "== uncovered rag.go blocks =="
awk 'NR>1 && $1 ~ /rag.go/ && $NF==0 {print $1}' c.out
