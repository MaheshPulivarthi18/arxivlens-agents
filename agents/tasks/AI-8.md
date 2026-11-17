# AI-8: Claim-level citations with provenance and a verification status in `/v1/ask` (ADR-0014)

| | |
|---|---|
| **Owner** | ai-engineer |
| **Priority** | P0 (Phase 1 items 4–5: claims map to inspectable source passages; unverified is never shown as verified) |
| **PRD ref** | Product PRD QA-3, QA-4, §7 principles 1–3; Technical PRD §7.2; ADR-0003 (Accepted), **ADR-0014 (Accepted 2026-11-07)** |
| **Depends on** | **ADR-0014 Accepted** (2026-11-07). **QA-8 delivered** by Mahesh's #46 (`cc57474`) on top of #44 (`6251d1a`): claims come from `parseSynthesis` and are verified per claim. **RET-2 merged** (`6cfd836`: `SearchHit.Version`/`Page`). Not a dependency: ING-11b (fills `SearchHit.Page`; AI-8 tests `page` with hand-built hits). Soft: Proposed ADR-0018 (whether `answer_kind` replaces ADR-0014's `answer_source`; see Scope) |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-AI-8"`) |
| **Design required** | **yes**: P0 and an HTTP API contract change. New `docs/design/AI-8.md` (none exists yet). pm-lead approves before code. |
| **Status** | **Ready: design stage** (re-scoped 2026-11-17 after #44/#46). First output is `docs/design/AI-8.md`; no app code before PM approval. Branch for the build: `agent/ai/AI-8` |

## Goal
Each factual statement in an answer becomes a claim with its own status and its own evidence. The evidence is the paper
ID and version, chunk ID, section, page when known, and a verbatim quote when there is one. A user (and the eval) can then tell a
supported claim from an unsupported one, and both from one that couldn't be checked.

## What #44/#46 already did (so this ticket doesn't redo it)
- Per-claim verification exists: `scorePairs` scores each (claim, passage) pair as 1 for a verbatim quote (`isVerbatimQuote`,
  whitespace/inline-ref normalised, ≥ 40 bytes) or NLI P(entailment) from `/internal/verify`. Supported = score ≥ `SupportThreshold` (0.50).
  `labelScore` fails closed (`ok == false`) when the verifier failed or the score is out of range, and that is counted as `unverified` in logs.
- LLM path: claims parsed (text, citations, optional `quote`, which is parsed but unused, `rag.go:582`). Claims without a supported citation are
  dropped from the answer. Extractive path: one quoted sentence per top hit, each followed by its marker.
- `answer_kind` (`quoted`/`synthesized`) and `synthesis_available` are in the response (no ADR yet: ADR-0018 Proposed).
- **Not done (this ticket):** no `claims[]` in the JSON; `Citation` has no `paper_version`, `page`, `quote` or `status`, so "unsupported"
  and "couldn't be checked" still look the same (`supported: false, score: 0`); `prompt_version` is in logs only; `pdf_url` is unversioned.

## Scope (ADR-0014 Option 1 as accepted, adjusted to the code after #46)
- `internal/query/rag.go`:
  - `AskResponse` gains `claims: [{text, status, markers}]` and `prompt_version` (set on `synthesized` answers only, omitted otherwise).
    **`answer_source` is not added:** `answer_kind` already carries it (ADR-0018 Option 1, recommended). If Mahesh picks ADR-0018
    Option 2, adding `answer_source` is a follow-up (additive, nothing breaks). Write this in the design and the PR.
  - `Citation` gains `paper_version` (int, = `SearchHit.Version`), `page` (from `SearchHit.Page`, omitted when nil), `quote` (omitted when none)
    and `status` (`supported | unsupported | unverified`). `supported` stays, defined as `status == "supported"`.
  - `status` comes from the existing scoring: verified score ≥ 0.50 → `supported`; < 0.50 → `unsupported`; `labelScore` not ok (verifier
    error, count mismatch, NaN/out of range, no verifier) → `unverified`, never `supported`. Refusal evidence: `unverified` if the refusal is
    `verification_unavailable` and the hit's check didn't run, else `unsupported`. `insufficient_evidence` evidence: `unverified` (nothing was checked). The design states the rule for every refusal path.
  - `quote` (ADR-0014 Decision: "drop any quote that is not verbatim in the cited passage"): (a) when a claim is supported by exact
    match, `quote` = the matched sentence; (b) when the LLM supplies a `quote`, keep it only if it's verbatim (same normalisation as
    `isVerbatimQuote`) in the **raw** chunk text, else drop it and set that citation `unsupported` even if NLI ≥ 0.50.
    No prompt change: the `synthesis-v1` prompt doesn't ask for quotes, and changing it changes answers (eval impact). A prompt that asks for quotes is a separate, measured task.
  - Claims: LLM path = the kept claims in answer order; extractive path = one claim per quoted sentence. A claim's `status` is
    `supported` if any of its citations is supported, else `unverified` if any is unverified, else `unsupported` (the design may refine; only shown claims appear).
  - The raw-vs-sanitized question from the QA-8 design (Notes, 2026-11-08): show the raw chunk in `content`, score on the text the model saw,
    check quotes against the raw chunk. The design confirms this against `passageHits`/`finalizeClaims` as they are now.
  - `pdf_url` → `https://arxiv.org/pdf/<id>v<paper_version>.pdf` when `paper_version > 0` (value change, no new field; RET-2 design note).
    Check that nothing else (frontend fallback URLs, tests, eval) parses the old form, and list each consumer in the design.
- `internal/query/rag_test.go` and/or `synthesis_test.go`: claim/status/quote/provenance cases (both paths, every refusal path).
- App `README.md` API table, **`/v1/ask` row only**: list `quick` (request), `answer_kind`, `synthesis_available`, `prompt_version`, `claims[]`
  and the new citation fields. The #46 row omits the first three today (QA-8 Notes 2026-11-17).
- Out of scope: `partially_supported` / `contradicted` (still reserved: the NLI model hasn't been calibrated on EVAL-7 human judgments,
  ADR-0014's condition), `search.go` and `page` filling (ING-11b), the frontend (FE-3/FE-4), prompt changes, verifier model changes, eval
  script changes beyond what AC6 needs (EVAL-6 already reads `claims` when present), the README `/v1/search` row (ING-11b) and Testing block (EVAL-4).
- **Size:** likely near or over 400 lines. The design names the split seam up front at a layer boundary (lesson 2026-11-07 OPS-H8), e.g.
  **AI-8a** = `Citation` provenance + `status` + `quote` (both paths) + `pdf_url`; **AI-8b** = `claims[]` + `prompt_version` + README row. Estimate fakes and deletions separately.

## Acceptance criteria
- [ ] AC1 — Every non-refused response has `claims` (non-empty), each with `text`, `status` and `markers`; every citation (answers and refusal evidence) has `paper_version` and `status`; `supported == (status == "supported")` for every citation (property-style test over every existing fixture in `rag_test.go` and `synthesis_test.go`).
- [ ] AC2 — Status rule: verified ≥ 0.50 → `supported`; < 0.50 → `unsupported`; verifier error / wrong score count / NaN / out-of-range / nil verifier → `unverified`, never `supported`. One test row per failure case (mutation: dropping any one `labelScore` failure branch fails a row).
- [ ] AC3 — Quote: exact-match-supported citation carries `quote` = the matched sentence; an LLM quote that is verbatim (extra whitespace allowed) in the raw chunk is kept; an LLM quote not in the chunk is dropped and its citation is `unsupported` even when the fake verifier returns ≥ 0.50; a chunk containing `<passage` gets its quote checked against the raw text (test).
- [ ] AC4 — `page` is present only when `SearchHit.Page` is non-nil (hand-built hit); `paper_version` equals the hit's `Version`; `pdf_url` ends in `v<paper_version>.pdf` when the version is known.
- [ ] AC5 — Extractive path: one claim per quoted sentence, `answer_kind == "quoted"`, no `prompt_version`. LLM path: claims = kept claims in order, `answer_kind == "synthesized"`, `prompt_version == "synthesis-v1"`. Refusals: `claims` absent or empty (the design picks one and the test pins it).
- [ ] AC6 — Backward compatibility: every pre-existing JSON key keeps its name and type (`TestAskResponseShapeAndConstructor` extended, nothing removed); `scripts/evaluate_answers.py` classifies a fixture response with the new fields exactly as before (`python3 -m pytest -q tests/test_evals_data.py`), and `frontend/` reads no field whose meaning changed (grep in the PR).
- [ ] AC7 — `rag.go` per-file coverage ≥ 90% (`go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go`, paste the file rows; a scratch-module run is acceptable if CI doesn't print it). Diff < 400 changed lines per PR (split at the design's seam otherwise).
- [ ] AC8 — README `/v1/ask` row as in Scope. `make eval` on the PR branch (one `workflow_dispatch` of `eval.yml`; replay cache makes it arXiv-free when warm) shows the same gate results as nightly run 43902662193 on `40dec5a` (supported 100%, correct refusals 100%, `GATE: PASS`), or "not run: <reason>" with the command.

## Verification
```bash
make lint
make test-unit
go test -race -run 'Ask|Synth|Citation|Claim' -v ./internal/query/
go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out | grep rag.go
python3 -m pytest -q tests/test_evals_data.py
gh workflow run eval.yml --ref agent/ai/AI-8   # AC8, then read the job log's gate table
```

## Notes
- 2026-11-07 (pm-lead): from the 2026-11-07 plan (Phase 1 items 4–5). The external review proposed `limitations` and `confidence`
  fields as well. Both are deferred in ADR-0014's recommendation, because model self-reported confidence isn't evidence. Wave 3.
- 2026-11-07 11:00Z (pm-lead, grooming): ADR-0014 is Accepted (Mahesh 2026-11-07), so the ADR blocker is gone. Still waits on QA-8 and RET-2 merged.
- 2026-11-07 (pm-lead, RET-2 design review): RET-2 sets `SearchHit.Version` for every hit but never sets `SearchHit.Page`, because `page_number` is the section-heading page (`docs/design/RET-2.md` finding 2). So AC4 means no citation carries `page` until ING-11 lands. Test the set case with a hand-built hit. `paper_version` is the owning row's version. On-demand rows can be mislabelled until ING-10 merges, which doesn't block AI-8. For the AI-8 design: the citation `pdf_url` (`rag.go:164`) is unversioned, so a v1 citation opens the latest PDF. Consider `https://arxiv.org/pdf/<id>v<paper_version>.pdf`. It's a value change, not a new field, so it needs no ADR.
- 2026-11-08 (pm-lead, QA-8 addendum decision, Q13 answer 5): on QA-8's LLM path, `finalize` runs over `passageHits(passages)`, so a citation's `content` is the **sanitized** passage text (a chunk containing `<passage`/`<question` shows `&lt;passage`). Accepted until this task. The AI-8 design must decide: show the raw chunk in `content` while still scoring support on the text the model saw, and check ADR-0014 quotes against the **raw** chunk (a model quoting the sanitized text would otherwise fail the verbatim check on those rare chunks).
- 2026-11-17 (pm-lead, grooming): **re-scoped after Mahesh's #44/#46.** QA-8 is delivered, so the dependency is met. #44/#46 replaced
  cosine with quote match + NLI, added per-claim verification and `answer_kind`, and parsed (not checked) the LLM `quote`. They didn't add
  `claims[]`, any citation provenance/status field, or `prompt_version` to the JSON. Remaining scope is above. AC2's old "cosine ≥ 0.50" is
  now "verified score ≥ 0.50" (same threshold, quote-or-NLI). `answer_source` is dropped in favour of `answer_kind` (pending ADR-0018).
  Status → Ready (design stage). No design doc existed, so the developer writes `docs/design/AI-8.md` first.
- 2026-11-17 (pm-lead, cycle plan): picked for **design only** in cycle 2026-11-17 08:00Z, alongside ING-11b, EVAL-4 and OPS-H2. File rules for the
  build that follows the approved design: ING-11b (open in the same cycle) edits `tests/test_evals_data.py` and the README API table's `/v1/search`
  row. AI-8 edits only the `/v1/ask` row. If AC6 needs a new test in `tests/test_evals_data.py`, the build waits until ING-11b merges, or the
  test goes in a file ING-11b doesn't touch. AI-5 (also `rag.go`) stays blocked on ADR-0011, so no `rag.go` conflict.
- 2026-11-17 (ai-engineer, design): `docs/design/AI-8.md` written (Draft), waiting for pm-lead approval. Split: **AI-8a** = citation
  `status`/`paper_version`/`page`/`quote` + versioned `pdf_url` + raw `content` on the LLM path (~335 lines); **AI-8b** = `claims[]` +
  `prompt_version` + README `/v1/ask` row + AC6 Python test (~180 lines; depends on AI-8a merged and ING-11b merged). Fallback seam if AI-8a
  runs over 400 lines: the model-supplied quote check moves to AI-8b. Nothing depends on ADR-0018 being Accepted. Open questions Q1–Q4 are in the design,
  Q1 refines the refusal-evidence rule: hits never checked are `unverified`, not `unsupported`. Jira not updated (no Jira tool in this session).
