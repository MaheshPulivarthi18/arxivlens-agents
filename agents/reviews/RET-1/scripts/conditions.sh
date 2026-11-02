#!/usr/bin/env bash
# Binding conditions 1,3,4,5,6 of docs/design/RET-1.md, checked mechanically. Run inside the ArxivLens checkout at the PR head.
set -uo pipefail
B=origin/main; F=internal/query/search.go
lit() { awk '/querySQL := `/{f=1} f{print} f&&/^\t`$/{exit}'; }
echo "== C1: hybrid SQL literal, origin/main vs HEAD (extracted from 'querySQL := \`' to closing backtick)"
git show $B:$F | lit > /tmp/ret1_sql_main.txt; git show HEAD:$F | lit > /tmp/ret1_sql_head.txt
wc -l /tmp/ret1_sql_main.txt /tmp/ret1_sql_head.txt | sed 's#/tmp/ret1_##'
sha256sum /tmp/ret1_sql_main.txt /tmp/ret1_sql_head.txt | sed 's#/tmp/ret1_##'
if diff -u /tmp/ret1_sql_main.txt /tmp/ret1_sql_head.txt; then echo "diff: EMPTY (character-identical)"; else echo "diff: NOT EMPTY"; fi
for s in 'LIMIT 50' 'WHERE ce.model = $2' '1.0/(60 + v.rank)' '1.0/(60 + k.rank)' 'LIMIT $5'; do
  printf '  count %-22s main=%s head=%s\n' "\"$s\"" "$(git show $B:$F | grep -oF -- "$s" | wc -l)" "$(git show HEAD:$F | grep -oF -- "$s" | wc -l)"; done
echo "  Query call: $(grep -n 'Pool.Query(' $F)"
echo "  SQL in other files of internal/query? $(grep -lF 'WITH vector_hits' internal/query/*.go | tr '\n' ' ')"
echo; echo "== C3: no OpenTelemetry import / go.mod change"
echo "  otel refs in search.go: $(grep -c otel $F)"; echo "  go.mod/go.sum changed vs main: $(git diff --name-only $B...HEAD -- go.mod go.sum | wc -l)"
echo "  imports added:"; git diff $B...HEAD -- $F | grep -E '^\+\s+"[a-z/]+"$'
echo; echo "== C4: new exported identifiers in the diff (expect only RerankPool)"
git diff $B...HEAD -- internal/query/ | grep -E '^\+(func|type|const|var) ' | sed 's/{$//'
echo; echo "== C5: fallback log line (format + args) and any log call in search.go"
grep -n -A1 'log.Printf' $F
echo "  err.Error() occurrences in search.go:"; grep -n "err.Error()" $F
echo; echo "== C6: error messages, origin/main vs HEAD"
diff <(git show $B:$F | grep -oE 'fmt.Errorf\("[^"]*"' ) <(git show HEAD:$F | grep -oE 'fmt.Errorf\("[^"]*"') && echo "  identical:" && git show HEAD:$F | grep -oE 'fmt.Errorf\("[^"]*"' | sed 's/^/    /'
echo "  NewSearchEngine signature main: $(git show $B:$F | grep '^func NewSearchEngine')"
echo "  NewSearchEngine signature head: $(git show HEAD:$F | grep '^func NewSearchEngine')"
echo "  HybridSearch signature unchanged: $(diff <(git show $B:$F | sed -n '/^func (s \*SearchEngine) HybridSearch(/,/) {$/p') <(git show HEAD:$F | sed -n '/^func (s \*SearchEngine) HybridSearch(/,/) {$/p') >/dev/null && echo yes || echo NO)"
