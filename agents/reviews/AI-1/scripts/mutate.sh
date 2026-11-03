#!/usr/bin/env bash
# Test quality: apply one mutation at a time to the PR head's rag.go (scratch copy) and run the PR's tests.
# KILLED = the tests fail (good); SURVIVED = the tests still pass with the bug in place.
SC=$1; bash "$(dirname "$0")/setup.sh" "$SC"; cd "$SC"; export GOTOOLCHAIN=local GOFLAGS=-mod=mod GOPROXY=off
F=internal/query/rag.go; cp $F /tmp/rag.orig.$$
m() { # id, description, perl substitution
  cp /tmp/rag.orig.$$ $F; perl -0pi -e "$3" $F
  if cmp -s $F /tmp/rag.orig.$$; then echo "$1 NOT-APPLIED  $2"; return; fi
  if go test -count=1 ./internal/query/ >/tmp/mut.$$ 2>&1; then r=SURVIVED; else r=KILLED; fi
  printf '%-4s %-9s %s   [%s]\n' "$1" "$r" "$2" "$(grep -m1 -oE -- '--- FAIL: [^ ]+|panic: [^\n]{0,50}|build failed' /tmp/mut.$$)"
}
m M1  "relevance cutoff 0.45 -> 0.40"               's/h\.RerankScore < 0\.45/h.RerankScore < 0.40/'
m M2  "relevance cutoff < -> <="                     's/h\.RerankScore < 0\.45/h.RerankScore <= 0.45/'
m M3  "aux cutoff 0.70 -> 0.60"                      's/h\.RerankScore < 0\.70/h.RerankScore < 0.60/'
m M4  "aux cutoff < -> <="                           's/h\.RerankScore < 0\.70/h.RerankScore <= 0.70/'
m M5  "drop \"table\" from aux sections"             's/ \|\| strings\.Contains\(lowerSec, "table"\)//'
m M6  "drop \"appendix\" from aux sections"          's/ \|\| strings\.Contains\(lowerSec, "appendix"\)//'
m M7  "aux match case-sensitive (no ToLower)"        's/strings\.ToLower\(h\.SectionTitle\)/h.SectionTitle/'
m M8  "zero rerank no longer bypasses cutoff"        's/h\.RerankScore > 0 && h\.RerankScore < 0\.45/h.RerankScore < 0.45/'
m M9  "refusal returns nil citations"                's/Citations: \[\]Citation\{\},/Citations: nil,/'
m M10 "refusal text changed"                         's/No indexed papers are relevant to this question\./No relevant papers./'
m M11 "Ask cites unfiltered hits"                    's/r\.validateCitations\(ctx, answer, hits\)/r.validateCitations(ctx, answer, append(hits[:1:1], hits...))/'
m M12 "support >= -> >"                              's/score >= SupportThreshold/score > SupportThreshold/'
m M13 "upper marker bound k -> k+1"                  's/markerIdx > k\b/markerIdx > k+1/'
m M14 "only first marker per sentence"               's/FindAllStringSubmatch\(sent, -1\)/FindAllStringSubmatch(sent, 1)/'
m M15 "marker left in embedded sentence"             's/cleanSent := strings\.TrimSpace\(markerRegex\.ReplaceAllString\(sent, ""\)\)/cleanSent := strings.TrimSpace(sent)/'
m M16 "fallback score 0.75 -> 0.5"                   's/score = 0\.75/score = 0.5/'
m M17 "no score rounding"                            's/score = math\.Round\(float64\(sim\)\*10000\) \/ 10000/score = float64(sim)/'
m M18 "pdf url drops .pdf"                           's/arxiv\.org\/pdf\/%s\.pdf/arxiv.org\/pdf\/%s/'
m M19 "splitter fix reverted"                        's/ && !endsWithAbbreviation\(current\.String\(\)\)//'
m M20 "abbrev match ignores word boundary"           's/rest == "" \|\| strings\.HasSuffix\(rest, " "\)/true || rest == ""/'
m M21 "abbrev match case-sensitive"                  's/lower := strings\.ToLower\(s\)/lower := s/'
m M22 "cosine zero-norm guard removed"               's/\tif normA == 0 \|\| normB == 0 \{\n\t\treturn 0\n\t\}\n//'
m M23 "cosine length-mismatch guard removed"         's/len\(a\) != len\(b\) \|\| len\(a\) == 0/len(a) == 0/'
m M24 "default maxCitations 5 -> 3"                  's/maxCitations = 5/maxCitations = 3/'
m M25 "Ask disables rerank"                          's/maxCitations, true\)/maxCitations, false)/'
rm -f /tmp/rag.orig.$$ /tmp/mut.$$
