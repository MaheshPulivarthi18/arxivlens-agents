#!/usr/bin/env bash
# Splitter fix: run origin/main's splitIntoSentences (renamed oldSplit) and the PR head's side by side on the
# answers Ask's template actually produces and on extra edge cases. Prints every input where they differ.
set -e
SC=$1; bash "$(dirname "$0")/setup.sh" "$SC"
echo "== splitter fix size: git diff origin/main...HEAD, splitter hunks only =="
git diff origin/main...HEAD -- internal/query/rag.go | awk '/^@@.*splitIntoSentences|^@@.*func cosineSimilarity/{p=1} /^@@.*(func \(r \*RAGService\) Ask|type AskResponse)/{p=0} p' | grep -E '^[+-][^+-]' | awk '{print} /^\+/{a++} /^-/{d++} END {printf "added %d, removed %d\n", a, d}'
git show origin/main:internal/query/rag.go | awk '/^func splitIntoSentences/{p=1} p{print} p&&/^}/{exit}' | sed 's/func splitIntoSentences/func oldSplit/' > "$SC/internal/query/old.go"
sed -i '1i package query\n\nimport "strings"\n' "$SC/internal/query/old.go"
cat > "$SC/internal/query/qa_split_test.go" <<'EOT'
package query

import (
	"fmt"
	"reflect"
	"strings"
	"testing"
)

func TestQASplitterOldVsNew(t *testing.T) {
	titles := []string{"Attention Is All You Need", "BERT: Pre-training of Deep Bidirectional Transformers", "Adam: A Method for Stochastic Optimization", "Scaling Laws vs. Data Quality", "Smith et al. Revisited", "Graph Nets, e.g. GCNs", "Q&A? Yes!", "3.5 Billion Params"}
	sections := []string{"Introduction", "4.2 Results", "Appendix A", "Methods", "Fig. 3 Analysis", "Eq. 2 derivation"}
	same, diff, diffNoAbbr, noAbbr := 0, 0, 0, 0
	hasAbbr := func(x string) bool { return strings.Contains(x, ".") && strings.ContainsAny(x, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ") && (strings.Contains(x, "vs.") || strings.Contains(x, "et al.") || strings.Contains(x, "e.g.") || strings.Contains(x, "Fig.") || strings.Contains(x, "Eq.")) }
	for _, ti := range titles {
		for _, s1 := range sections {
			for _, s2 := range sections {
				ans := fmt.Sprintf("Based on the indexed research, the paper %q addresses this in the %s section [1].", ti, s1) +
					fmt.Sprintf(" Furthermore, experimental evaluation in %s demonstrates relevant improvements [2].", s2)
				abbr := hasAbbr(ti) || hasAbbr(s1) || hasAbbr(s2)
				if !abbr {
					noAbbr++
				}
				o, n := oldSplit(ans), splitIntoSentences(ans)
				if reflect.DeepEqual(o, n) {
					same++
				} else {
					diff++
					if !abbr {
						diffNoAbbr++
					}
					if diff <= 6 {
						fmt.Printf("TEMPLATE DIFF title=%q s1=%q s2=%q\n  old(%d)=%q\n  new(%d)=%q\n", ti, s1, s2, len(o), o, len(n), n)
					}
				}
			}
		}
	}
	fmt.Printf("template answers: %d total, %d identical, %d differ; inputs with no abbreviation: %d, of which differ: %d\n", same+diff, same, diff, noAbbr, diffNoAbbr)
	extra := []string{"We compare to Smith et al. They report 90%.", "Results vs. baselines. Next.", "See Fig. 2. It shows X [1].",
		"Values are 3.14 and 2.71 [1].", "U.S. data is used [1].", "Ends with e.g.", "cf. prior work [2]. Done.", "Model (e.g. BERT) wins [1]! Really? Yes.",
		"Spaces  twice.  Here.", "Eq. 3 holds [1]. Also Eq.4 [2].", "Use i.e., this [1]."}
	for _, e := range extra {
		o, n := oldSplit(e), splitIntoSentences(e)
		tag := "same"
		if !reflect.DeepEqual(o, n) {
			tag = "DIFF"
		}
		fmt.Printf("%s %q\n  old=%q\n  new=%q\n", tag, e, o, n)
	}
}
EOT
cd "$SC"; export GOTOOLCHAIN=local GOFLAGS=-mod=mod GOPROXY=off
go test -count=1 -v -run TestQASplitterOldVsNew ./internal/query/ | grep -v '^=== RUN'
