#!/usr/bin/env bash
# Test quality: one mutation at a time to the PR head's rag.go (scratch copy), run the PR's tests.
# KILLED = tests fail (good); SURVIVED = tests still pass with the bug in place.
SC=$1; bash "$(dirname "$0")/setup.sh" "$SC"; cd "$SC"; export GOTOOLCHAIN=local GOFLAGS=-mod=mod GOPROXY=off
F=internal/query/rag.go; O=$SC/rag.orig; cp $F $O
m() {
  cp $O $F; perl -0pi -e "$3" $F
  if cmp -s $F $O; then echo "$1 NOT-APPLIED  $2"; return; fi
  if go test -count=1 ./internal/query/ >$SC/mut.out 2>&1; then r=SURVIVED; else r=KILLED; fi
  printf '%-4s %-9s %s   [%s]\n' "$1" "$r" "$2" "$(grep -m1 -oE -- '--- FAIL: [^ ]+|build failed|vet: .{0,60}' $SC/mut.out)"
}
m N1  "restore fail-open (score 0.75, supported)"        's/\t\t\t\tunverified\+\+\n/\t\t\t\tunverified++\n\t\t\t\tscore, supported = 0.75, true\n/'
m N2  "fallback score 0.75 but unsupported"             's/\t\t\t\tunverified\+\+\n/\t\t\t\tunverified++\n\t\t\t\tscore = 0.75\n/'
m N3  "fallback supported=true, score 0"                's/\t\t\t\tunverified\+\+\n/\t\t\t\tunverified++\n\t\t\t\tsupported = true\n/'
m N4  "drop marker when unverified"                     's/\t\t\t\tunverified\+\+\n/\t\t\t\tunverified++\n\t\t\t\tcontinue\n/'
m N5  "drop empty-sentence-vector guard"                's/ && len\(sentVecs\[0\]\) > 0//'
m N6  "drop chunk-vector guard"                         's/ && len\(chunkEmbeddings\[markerIdx-1\]\) > 0//'
m N7  "log on every request (also verified)"            's/if unverified > 0 \{/if true {/'
m N8  "log once per citation, not per request"          's/\t\t\t\tunverified\+\+\n/\t\t\t\tunverified++\n\t\t\t\tlog.Printf("unverified citation")\n/'
m N9  "log leaks the answer text"                       's/sentence_embed_errors=%d",/sentence_embed_errors=%d answer=%q",/; s/chunkMissing, k, sentenceErrs\)/chunkMissing, k, sentenceErrs, answer)/'
m N10 "log leaks chunk content"                         's/sentence_embed_errors=%d",/sentence_embed_errors=%d content=%q",/; s/chunkMissing, k, sentenceErrs\)/chunkMissing, k, sentenceErrs, hits[0].Content)/'
m N11 "trace id dropped from log"                       's/id, src := traceIDFrom\(ctx\)/id, src := "-", "none"/'
m N12 "unverified count wrong (always 1)"               's/id, src, unverified, len/id, src, 1, len/'
m N13 "sentence_embed_errors never counted"             's/\t\t\t\tif err != nil \{\n\t\t\t\t\tsentenceErrs\+\+\n\t\t\t\t\}\n//'
m N14 "chunks_without_vector never counted"             's/\t\tif len\(chunkEmbeddings\[i\]\) == 0 \{\n\t\t\tchunkMissing\+\+\n\t\t\}\n//'
m N15 "support >= -> > (verified path)"                 's/score >= SupportThreshold/score > SupportThreshold/'
m N16 "verified path always supported"                  's/supported = score >= SupportThreshold/supported = true/'
