$ bash -c B=$(git merge-base origin/main HEAD); echo "merge-base $B"; git diff --stat $B HEAD; echo; echo "## numstat total:"; git diff --numstat $B HEAD | awk "{a+=\$1;d+=\$2} END {print a\"+\"d\"=\"a+d\" changed lines\"}"; echo; echo "## ownership-check.sh (agent/ai/AI-8b):"; .github/scripts/ownership-check.sh $B agent/ai/AI-8b; echo "exit=$?"; echo; echo "## README.md diff: hunk headers and changed-line prefixes"; git diff -U0 $B HEAD -- README.md | grep -E "^(@@|[-+]\|)" | cut -c1-60; echo; echo "## synthesis_test.go unchanged by PR? (empty = yes):"; git diff --stat $B HEAD -- internal/query/synthesis_test.go; echo "## grep -c checkCitationInvariants synthesis_test.go:"; grep -c checkCitationInvariants internal/query/synthesis_test.go
merge-base 670108ee74de0a886c1e466e405b2c85fd1049a9
 README.md                  |   2 +-
 internal/query/rag.go      |  60 +++++++++++++++++++----
 internal/query/rag_test.go | 118 +++++++++++++++++++++++++++++++++++++++++++--
 tests/test_evals_data.py   |  18 +++++++
 4 files changed, 182 insertions(+), 16 deletions(-)

## numstat total:
182+16=198 changed lines

## ownership-check.sh (agent/ai/AI-8b):
Ownership OK for role=ai (198 changed lines)
exit=0

## README.md diff: hunk headers and changed-line prefixes
@@ -163 +163 @@ CUDA in compose is untested: `TORCH_INDEX_UR
-| `POST` | `/v1/ask` | Cited answer: `{question, categories
+| `POST` | `/v1/ask` | Cited answer: `{question, categories

## synthesis_test.go unchanged by PR? (empty = yes):
## grep -c checkCitationInvariants synthesis_test.go:
11

[exit code 0]
