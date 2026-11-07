$ bash -c grep -nE 'ADR-0003 classification|^\| Response|all_citations_unsupported|verification_unavailable|citation_coverage|refusal_reason_counts|near_miss_correct_refusal_rate|Per-case records|split_sentences|Near-miss rows and human review|reviewed_by' evals/README.md
12:| `refusal_near_miss.jsonl` | `{"id","question","answered_by","why_near","reviewed_by"}` (in-domain, answering paper not in corpus; report-only) | 10 |
72:**ADR-0003 classification** of each `/v1/ask` response (`classify()` in `scripts/evaluate_answers.py`):
74:| Response | Outcome | Refusal set | Answer set |
78:| `refusal_reason: "all_citations_unsupported"` (case A, carries evidence) | refusal | correct refusal | `answer_refusal_rate` |
79:| `refusal_reason: "verification_unavailable"` (case B) | **error** | `ask_error_count` and `verification_unavailable_count` +1, not refused | same |
89:- **`citation_coverage`** = cited units / all units, summed over answered answer-set responses. A unit is a `claims[]`
93:  `split_sentences()`, a port of `splitIntoSentences` in `internal/query/rag.go`: a sentence ends at `.`, `!` or `?`
96:- **`refusal_reason_counts`**: how many responses carried each `refusal_reason` value, over all three sets.
97:- **`verification_unavailable_count`**: ADR-0003 case B responses in the answer and refusal sets (also in `ask_error_count`).
98:- **`near_miss_correct_refusal_rate`** = refused / all rows of `refusal_near_miss.jsonl`, classified as above (errors
101:- **Per-case records** (`answers.cases`): `id`, `set`, `outcome`, `refused`, `refusal_reason`, `latency_ms`,
105:### Near-miss rows and human review
110:corpus paper does, then sets `reviewed_by` to their name or handle. `reviewed_by: null` means not reviewed yet.

[exit code 0]
