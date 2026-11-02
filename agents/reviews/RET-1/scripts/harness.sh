#!/usr/bin/env bash
# Usage: harness.sh <src-root> [go test args...]
# Builds a throwaway module with the PR's internal/query/{search,search_test,client,rag}.go copied VERBATIM
# and a stub arxivlens/internal/db (pgx can't be downloaded here), then runs go test with local go1.24.
set -euo pipefail
SRC=$1; shift
H=$(mktemp -d)
mkdir -p "$H/internal/db" "$H/internal/query"
printf 'module arxivlens\n\ngo 1.24\n' > "$H/go.mod"
cat > "$H/internal/db/db.go" <<'GO'
// STUB of arxivlens/internal/db for an offline harness (real package needs pgx).
package db

import (
	"context"
	"errors"
)

type Rows struct{}

func (Rows) Close()            {}
func (Rows) Next() bool        { return false }
func (Rows) Scan(...any) error { return nil }

type Pool struct{}

func (*Pool) Query(context.Context, string, ...any) (Rows, error) { return Rows{}, errors.New("stub") }

type DB struct{ Pool *Pool }
GO
for f in search.go search_test.go client.go rag.go; do cp "$SRC/internal/query/$f" "$H/internal/query/$f"; done
echo "harness: $H (go.mod 'go 1.24', stub internal/db; query files copied verbatim from $SRC @ $(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo n/a))"
sha256sum "$SRC/internal/query/search.go" "$H/internal/query/search.go" "$SRC/internal/query/search_test.go" "$H/internal/query/search_test.go" | sed "s#$H#<harness>#"
cd "$H" && GOTOOLCHAIN=local GOFLAGS=-mod=mod go version && GOTOOLCHAIN=local go vet ./internal/query/ && GOTOOLCHAIN=local go test "$@" ./internal/query/
