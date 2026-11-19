$ bash -c row=$(git diff -U0 $(git merge-base origin/main HEAD) HEAD -- README.md | grep "^+|"); echo "$row" | sed "s/\. /.\n/g; s/; /;\n  /g" | fold -w 150; echo; for t in "quick?" answer_kind synthesis_available insufficient_evidence "ADR-0018, Proposed" prompt_version "claims?: [{text, status, markers}]" "else \`unverified\` if any is (or it has none), else \`unsupported\`" paper_version "page?" "quote?" "not checked: the verifier was unavailable, or no statement cited this passage" "whitespace/inline-reference normalisation" "/pdf/<id>v<n>.pdf" "citations[o:o+len(markers)]"; do printf "%-95s %s\n" "$t" "$(grep -cF -- "$t" <<<"$row")"; done
+| `POST` | `/v1/ask` | Cited answer: `{question, categories?, max_citations?, quick?}` → `{answer, citations: [{marker, arxiv_id, title, chunk_id, 
section, content, pdf_url, score, supported, paper_version, page?, quote?, status}], trace_id, refusal_reason?, answer_kind?, synthesis_available?, cl
aims?: [{text, status, markers}], prompt_version?}`.
Every cited claim is verified against its passage: a verbatim quote by exact match, anything else by NLI entailment (`/internal/verify`);
  an LLM claim with no verified citation is dropped.
Citation `status` (ADR-0014) is `supported`, `unsupported` (checked and failed) or `unverified` (not checked: the verifier was unavailable, or no stat
ement cited this passage);
  `supported` is `status == "supported"`.
`paper_version` is the indexed arXiv version (0 = unknown) and `pdf_url` opens that version (`…/pdf/<id>v<n>.pdf`;
  unversioned when 0);
  `page` is the page the chunk starts on, when recorded;
  `quote` (supported citations only) occurs in `content` after whitespace/inline-reference normalisation.
`answer_kind` is `quoted` (sentences quoted from the passages) or `synthesized` (LLM claims);
  `"quick": true` skips the LLM and returns the quoted answer, with `synthesis_available: true` when a written answer can be requested without `quick`
;
  `prompt_version` (e.g.
`synthesis-v1`) is set only on `synthesized` answers (`quick`, `answer_kind`, `synthesis_available`: ADR-0018, Proposed).
`claims` lists the answer's statements in order, each with its in-range `markers` (`[]` for an uncited sentence) and a `status`: `supported` if any of
 its citations is, else `unverified` if any is (or it has none), else `unsupported`.
`citations` lists each claim's citations in claim order and, within a claim, in `markers` order, so claim *i*'s citations are `citations[o:o+len(marke
rs)]` with `o` the total `markers` length of the claims before it.
When nothing is supported, the answer is withheld, `refusal_reason` is `all_citations_unsupported`, `verification_unavailable` or (LLM only) `insuffic
ient_evidence` (ADR-0018, Proposed), `citations` lists the relevant passages as evidence (ADR-0003), and `claims`, `answer_kind` and `prompt_version` 
are absent.
When no passage is relevant, the answer says so with `citations: []` and no `refusal_reason` |

quick?                                                                                          1
answer_kind                                                                                     1
synthesis_available                                                                             1
insufficient_evidence                                                                           1
ADR-0018, Proposed                                                                              1
prompt_version                                                                                  1
claims?: [{text, status, markers}]                                                              1
else `unverified` if any is (or it has none), else `unsupported`                                1
paper_version                                                                                   1
page?                                                                                           1
quote?                                                                                          1
not checked: the verifier was unavailable, or no statement cited this passage                   1
whitespace/inline-reference normalisation                                                       1
/pdf/<id>v<n>.pdf                                                                               1
citations[o:o+len(markers)]                                                                     1

[exit code 0]
