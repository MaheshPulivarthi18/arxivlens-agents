#!/usr/bin/env bash
# QA scratch: copy the PR head's real internal/query/{rag,rag_test,client,search}.go from app/ (cwd) into a
# stdlib-only module with a stub internal/db (no pgx), so Go 1.24.7 with GOTOOLCHAIN=local can build it.
set -e
SC=$1; APP=$(pwd)
rm -rf "$SC"; mkdir -p "$SC/internal/query" "$SC/internal/db"
cp "$APP"/internal/query/{rag.go,rag_test.go,client.go,search.go} "$SC/internal/query/"
printf 'module arxivlens\n\ngo 1.24\n' > "$SC/go.mod"
cat > "$SC/internal/db/db.go" <<'EOD'
package db

import "context"

type Rows struct{}

func (*Rows) Next() bool        { return false }
func (*Rows) Scan(...any) error { return nil }
func (*Rows) Close()            {}

type Pool struct{}

func (*Pool) Query(context.Context, string, ...any) (*Rows, error) { return &Rows{}, nil }

type DB struct{ Pool *Pool }
EOD
