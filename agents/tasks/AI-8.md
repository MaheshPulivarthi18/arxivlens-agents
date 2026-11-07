# AI-8: Claim-level citations with provenance and a verification status in `/v1/ask` (ADR-0014)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (Phase 1 items 4–5: claims map to inspectable source passages; unverified is never shown as verified) |
| **PRD ref** | Product PRD QA-3, QA-4, §7 principles 1–3; Technical PRD §7.2; ADR-0003 (Accepted), **ADR-0014 (Proposed)** |
| **Depends on** | **ADR-0014 Accepted**, **QA-8 merged** (same file; claims come from the structured synthesis), **RET-2 merged** (`SearchHit.Version`/`Page`) |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-AI-8"`) |
| **Design required** | **yes**: P0 and an HTTP API contract change. Addendum to `docs/design/QA-8.md` or a new `docs/design/AI-8.md`. |
| **Status** | Blocked (needs ADR-0014). Wave 3 once it's Accepted and QA-8 + RET-2 are merged |

## Goal
Each factual statement in an answer becomes a claim with its own status and its own evidence. The evidence is the paper
ID and version, chunk ID, section, page when known, and a verbatim quote. A user (and the eval) can then tell a
supported claim from an unsupported one, and both from one that couldn't be checked.

## Scope (written for ADR-0014 Option 1 as recommended; pm-lead re-specs if Mahesh decides otherwise)
- `internal/query/rag.go`:
  - `AskResponse` gains `claims: [{text, status, markers}]`, `prompt_version`, `answer_source` (`llm | template`).
  - `Citation` gains `paper_version`, `page` (omitted when unknown), `quote` (omitted when none), `status`
    (`supported | unsupported | unverified`). `supported` stays, defined as `status == "supported"`.
  - Validation runs **per claim**. LLM path: claims from `parseSynthesis`. Template path: one claim per template sentence.
    `unverified` when the check couldn't run (AI-2/AI-7 conditions). The quote rule follows ADR-0014's Decision
    (recommended: verbatim, whitespace-normalised, inside the cited chunk; a fabricated quote is dropped and the citation becomes `unsupported`).
  - AI-7's refusal rule now reads claim statuses (same outcomes).
- `internal/query/rag_test.go`: claim/status/quote/provenance cases.
- App `README.md` API table: the `/v1/ask` row lists the new fields.
- Out of scope: `partially_supported` / `contradicted` (reserved by ADR-0014 until an entailment verifier exists), `search.go`
  (RET-2), the frontend (FE-4), and eval changes (EVAL-6 already reads `claims` when present).

## Acceptance criteria
- [ ] AC1 — Every claim has `text`, `status` and `markers`; every citation has `paper_version` and `status`; `supported == (status == "supported")` for every citation (property-style test over the existing fixtures).
- [ ] AC2 — Status: cosine ≥ 0.50 → `supported`; < 0.50 → `unsupported`; embed error / missing vector → `unverified`, never `supported`.
- [ ] AC3 — Quote: a verbatim quote (extra whitespace allowed) is kept; a quote not in the chunk is dropped and the citation is `unsupported` (per ADR-0014 Decision; adjust if the Decision differs).
- [ ] AC4 — `page` is present only when `SearchHit.Page` is set; `paper_version` equals the hit's version.
- [ ] AC5 — The template path yields claims too (one per sentence), `answer_source = "template"`. The LLM path yields `answer_source = "llm"` and `prompt_version`.
- [ ] AC6 — Backward compatibility: every pre-existing JSON key keeps its name and type (`TestAskResponseShapeAndConstructor` extended, nothing removed); `scripts/evaluate_answers.py` runs unchanged against a fixture response.
- [ ] AC7 — `rag.go` per-file coverage ≥ 90%; diff < 400 lines.
- [ ] AC8 — README `/v1/ask` row updated. `make eval` (template path) before/after, or "not run: <reason>" with the command.

## Verification
```bash
make lint
make test-unit
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go
make eval
```

## Notes
- 2026-11-07 (pm-lead): from the 2026-11-07 plan (Phase 1 items 4–5). The external review proposed `limitations` and `confidence`
  fields as well. Both are deferred in ADR-0014's recommendation, because model self-reported confidence isn't evidence. Wave 3.
