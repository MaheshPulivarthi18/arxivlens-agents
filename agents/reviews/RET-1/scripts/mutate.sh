#!/usr/bin/env bash
# Usage: mutate.sh <src-root>. For each mutant: copy the PR's query files into a fresh harness, apply ONE sed edit to
# the harness copy of search.go, assert the edit changed the file, run go test; report CAUGHT (tests fail) / SURVIVED.
set -uo pipefail
SRC=$1
HARN=$(dirname "$0")/harness.sh
mutants=(
 "M1 stable->unstable sort|s/sort.SliceStable(/sort.Slice(/"
 "M2 drop the sort|/sort.SliceStable(/d"
 "M3 sort ascending|s/return hits\[i\].RerankScore > hits\[j\].RerankScore/return hits[i].RerankScore < hits[j].RerankScore/"
 "M4 pool = limit (no max)|s/max(RerankPool, limit)/limit/"
 "M5 RerankPool 20->10|s/^const RerankPool = 20/const RerankPool = 10/"
 "M6 fallback not truncated|0,/return hits\[:min(limit, len(hits))\]/s//return hits/"
 "M7 success not truncated|\$!N;s/return hits\[i\].RerankScore > hits\[j\].RerankScore })\n\treturn hits\[:min(limit, len(hits))\]/return hits[i].RerankScore > hits[j].RerankScore })\n\treturn hits/;P;D"
 "M8 count check only 'fewer'|s/case len(scores) != len(hits):/case len(scores) < len(hits):/"
 "M9 no NaN check|s/reason = \"NaN score\"/reason = \"\"/"
 "M10 log raw error|s/reason = \"rerank error\"/reason = err.Error()/"
 "M11 rerank=false uses pool|s/return s.fetch(ctx, queryString, categories, limit)/return s.fetch(ctx, queryString, categories, max(RerankPool, limit))/"
 "M12 rerank=false also reranks|s/^\tif !rerank {/\tif false {/"
 "M13 fallback returns error|s/return rerankAndSort(ctx, s.rr, queryString, hits, limit), nil/r := rerankAndSort(ctx, s.rr, queryString, hits, limit); if len(r) > 0 \&\& r[0].RerankScore == 0 { return r, errors.New(\"x\") }; return r, nil/"
 "M14 trace id dropped from log|s/trace_id=%s trace_id_source/trace_id=-%.0s trace_id_source/"
 "M15 ctx trace id ignored|s/return v, \"ctx\"/return generateTraceID(), \"ctx\"/"
 "M16 fallback keeps partial scores|s/^\t\treturn hits\[:min(limit, len(hits))\]\$/\t\tfor i := range hits { if i < len(scores) { hits[i].RerankScore = float64(scores[i]) } }; return hits[:min(limit, len(hits))]/"
 "M17 empty pool still calls rerank|s/^\tif len(hits) == 0 {/\tif false {/"
)
for m in "${mutants[@]}"; do
  name=${m%%|*}; expr=${m#*|}
  T=$(mktemp -d); mkdir -p "$T/internal/query"; cp "$SRC"/internal/query/{search,search_test,client,rag}.go "$T/internal/query/"
  sed -i "$expr" "$T/internal/query/search.go"
  if cmp -s "$SRC/internal/query/search.go" "$T/internal/query/search.go"; then echo "$name: SED DID NOT APPLY"; continue; fi
  out=$("$HARN" "$T" -count=1 2>&1)
  if echo "$out" | grep -q "^ok "; then echo "$name: SURVIVED"
  else echo "$name: CAUGHT  ($(echo "$out" | grep -m1 -E -- '--- FAIL|vet:|cannot|undefined' | sed 's/^ *//'))"; fi
done
