# ADR-0014: Claim-level evidence and citation provenance fields in `/v1/ask` and `/v1/search`

- **Status:** Accepted (Mahesh, 2026-11-07)
- **Date:** 2026-11-07
- **Deciders:** Mahesh Pulivarthi (only the human owner sets Accepted/Rejected)
- **Blocks:** RET-2, AI-8, FE-4 (Wave 2/3 of the 2026-11-07 plan). Does **not** block LLM-1, AI-6, AI-7, QA-8, EVAL-6, FE-3.

## Context
ADR-0001/0002 (Accepted) put LLM synthesis behind a provider interface in `internal/query/rag.go`. ADR-0003 (Accepted)
adds one response field, `refusal_reason`, and nothing else. The Phase 1 goal (Mahesh, 2026-11-07, after an external
review) is that every factual statement in an answer is tied to an inspectable passage, and that the user can tell a
checked-and-failed citation from one that could not be checked.

Today (`app/internal/query/rag.go` at `71cb609`):
- `Citation` has `marker, arxiv_id, title, chunk_id, section, content, pdf_url, score, supported`. No paper version, no
  page, no quote, and `supported` is a bool, so "unsupported" and "unverified because the embedder failed" (AI-2 fails
  closed to `supported=false, score=0`) look the same.
- There is no notion of a claim: validation splits the answer text into sentences and checks each `[n]` marker.
- `SearchHit` (`search.go:21`) has no `version` or `page`, though `papers.version` and `paper_chunks.page_number` exist.
  `page_number` is written by `services/common/db.py:119` with a default of 1 when the chunk has none, so it isn't
  reliable for every chunk yet.

The HTTP API is a shared contract (AGENTS.md §2): adding response fields needs an Accepted ADR.

Cosine similarity between a claim and a passage is a relevance signal, not proof of entailment. A status set with
"partially supported" or "contradicted" would need an entailment verifier (NLI model or LLM judge) that doesn't exist yet.

## Options
1. **Additive fields on the existing routes (recommended).**
   - `/v1/ask` response gains `claims: [{text, status, markers: [n...]}]`, where `status` ∈ `supported | unsupported | unverified`.
   - Each `citations[]` entry gains `paper_version` (int), `page` (int, omitted when unknown), `quote` (string, omitted
     when none) and `status` (same enum). `supported` stays, defined as `status == "supported"`, so today's clients and
     the eval keep working.
   - `/v1/search` hits gain `version` and `page` (omitted when unknown).
   - Top-level `prompt_version` and `answer_source` (`llm | template`) so an answer can be traced to the prompt that made it.
   - Pros: no new route, no client breakage, the UI and eval can adopt fields one at a time. Cons: `supported` and
     `status` are redundant for a while.
2. **A new `/v2/ask` with a nested schema** (claims own their citations; adds `limitations` and `confidence`).
   Pros: a clean shape. Cons: two answer paths to keep correct, the frontend and eval must move at once, and
   `confidence` would be the model's self-report, which isn't evidence.
3. **Replace `citations[]` with claims that nest citations on `/v1/ask`.** Pros: one shape. Cons: breaks the frontend,
   the eval (`scripts/evaluate_answers.py`) and the M3 tests in one PR.

## Recommendation (from pm-lead)
Option 1. Rules that go with it, for you to accept or change:
- **`quote`** is a verbatim span of the cited chunk. When the LLM supplies one, the server checks that it occurs in the
  chunk text (whitespace-normalised, case-sensitive). If it doesn't, the quote is dropped and the citation's `status`
  becomes `unsupported` even if cosine ≥ 0.50. A fabricated quote is a false provenance claim. This makes
  `supported_citation_rate` slightly stricter, which is why it's in this ADR. Template answers carry no quote.
- **`status`**: `unverified` means the check couldn't run (embed error, missing vector, dimension mismatch). It never
  counts as supported. `partially_supported` and `contradicted` are **reserved, not emitted** until an entailment
  verifier exists and is measured against human judgments (EVAL-7).
- **`page`** is only returned when the chunker recorded it. RET-2 checks whether `page_number` is reliable and omits it
  if it isn't.
- **`limitations` and `confidence`** are left out for now.

## Decision
**The pm-lead recommendation above, accepted as written** (Mahesh, 2026-11-07, in chat): add the new fields to `/v1/ask` and `/v1/search` without breaking existing clients; drop any quote that is not verbatim in the cited passage; statuses `supported` / `unsupported` / `unverified`, with `partially_supported` and `contradicted` reserved until a real entailment checker exists; confidence and limitations fields deferred. The app README API table is updated in the PRs that add the fields.

## Consequences
If accepted: RET-2 (backend) adds `version`/`page` to `SearchHit`, AI-8 (ai) adds claims/status/quote to `rag.go`, and
FE-4 (frontend) renders claims with their evidence. App README API table rows for `/v1/ask` and `/v1/search` are updated
in those PRs. EVAL-6's coverage metric reads `claims` once present. If rejected or changed: pm-lead re-specs RET-2, AI-8, FE-4.
