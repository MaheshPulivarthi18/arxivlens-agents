#!/usr/bin/env bash
# Scope + AC3: changed files vs owned paths, untouched contracts, exported surface + JSON tags/types of rag.go
# main vs head, and the marshalled JSON of an unverified citation (field names and JSON types).
echo "== git diff --stat origin/main...HEAD =="; git diff --stat origin/main...HEAD
echo "== changed files vs ai-engineer owned paths =="
git diff --name-only origin/main...HEAD | while read f; do case "$f" in internal/query/rag.go|internal/query/rag_test.go) echo "owned: $f";; *) echo "NOT OWNED: $f";; esac; done
echo "== untouched contracts =="
for f in internal/query/server.go internal/query/search.go internal/query/client.go evals/thresholds.json shared/events/events.go README.md frontend; do
  n=$(git diff --numstat origin/main...HEAD -- "$f" | wc -l); echo "$f: $([ "$n" = 0 ] && echo unchanged || echo CHANGED)"; done
sig() { grep -E '^(func|type|const|var) [A-Z]|^func \([^)]*\) [A-Z]|^[[:space:]]+[A-Z][A-Za-z]+[[:space:]]+[^[:space:]]+[[:space:]]+`json|^[[:space:]]+[A-Z][A-Za-z]+[[:space:]]+=[[:space:]]'; }
echo "== exported decls, struct fields with JSON tags+types, constants: origin/main vs HEAD (empty diff = identical) =="
diff <(git show origin/main:internal/query/rag.go | sig) <(sig < internal/query/rag.go) && echo "(identical)"
echo "== HEAD Citation / AskResponse structs =="; awk '/^type (Citation|AskResponse) struct/{p=1} p{print} p&&/^}/{p=0}' internal/query/rag.go
SC=$1; bash "$(dirname "$0")/setup.sh" "$SC" || exit 1
cat > "$SC/internal/query/qa_shape_test.go" <<'EOT'
package query

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"testing"
)

func TestQAUnverifiedCitationJSON(t *testing.T) {
	got := (&RAGService{embedClient: &fakeEmbedder{err: errors.New("down")}}).validateCitations(context.Background(), "Claim [1].", []SearchHit{ragHit(1, "A", 0.9)})
	b, _ := json.Marshal(AskResponse{Answer: "a", Citations: got, TraceID: "t"})
	fmt.Println(string(b))
	var m map[string]any
	_ = json.Unmarshal(b, &m)
	c := m["citations"].([]any)[0].(map[string]any)
	keys := []string{}
	for k := range c {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		fmt.Printf("citation.%s: %T\n", k, c[k])
	}
}
EOT
cd "$SC"; export GOTOOLCHAIN=local GOFLAGS=-mod=mod GOPROXY=off
echo "== /v1/ask body for an unverified citation (marshalled AskResponse) + JSON types =="
go test -count=1 -v -run 'TestQAUnverifiedCitationJSON|TestAskResponseShapeAndConstructor' ./internal/query/ 2>&1 | grep -v '^=== RUN'
