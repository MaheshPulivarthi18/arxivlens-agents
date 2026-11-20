# FE-3a: Show refusals with their evidence and label citations honestly (Supported / Unsupported / Not checked)

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (ADR-0003 consequence: unsupported and unchecked citations stay visibly flagged; Product PRD §7 principles 1–2) |
| **PRD ref** | Product PRD UI-1, QA-4, QA-5, §7; ADR-0003 (Accepted), ADR-0014 (Accepted); parent [FE-3](FE-3.md) |
| **Depends on** | FE-1 #68 merged (`2410d2e`), FE-0 #69 merged (`54c4de8`), AI-7 / #46 / AI-8b merged. **Not** FE-0b #70 (no `ui/tooltip` here). No file overlap with open PRs #70, #79, #81–#85 (checked via REST 2026-11-20) |
| **Jira** | KAN-40 (parent FE-3) for now; sub-task or new story under epic KAN-5, labels `task-FE-3a`, `agent-frontend`, `arxivlens` (pm-lead creates) |
| **Design required** | yes, done: `docs/design/FE-3.md` **Approved with changes** (pm-lead 2026-11-20). Build to the design + its PM decision |
| **Status** | Ready (design approved 2026-11-20). Frontend WIP: #85 FE-0c active → one slot free; FE-3a is independent of #85 |

## Goal
A `/v1/ask` refusal reads as an honest "no answer, here is what was found" state, and no part of the UI says "Verified" about a check that didn't
happen or didn't pass. Design §1–§4 (answer and refusal modes), without the token restyle, tooltips or theme flip (those are FE-3b).

## Scope
- Files: `frontend/src/lib/citations.js` (new: `citationState`, `markdownNote`), `frontend/src/components/SynthesisView.jsx` (refusal panel, copy, footer
  summary, export, hide Copy/Export in refusal mode), `frontend/src/components/ReferencesStack.jsx` (`refusalReason` prop, headings, chips via `citationState`,
  gauge removed, `#references-heading` focus target), `frontend/src/components/ui/badge.jsx` (`supported`/`unsupported`/`unchecked` variants, remove `verified`,
  retarget `arxiv` to tokens), `frontend/src/App.jsx` (pass `refusalReason`; 1 line), `frontend/src/components/HeroSearch.jsx` (**one sentence of copy only**,
  PM decision change 1), tests: `src/test/fixtures.js`, `src/lib/citations.test.js` (new), `SynthesisView.test.jsx`, `ReferencesStack.test.jsx`, `src/App.test.jsx` (new).
- Chips use the new badge variants (tokens) already; other class restyles in these files wait for FE-3b.
- Out of scope: `ui/tooltip` wiring, the AC8 token restyle and theme flip, HeroSearch classes (FE-3b); claims/quote/page (FE-4); .bib export (FE-2);
  showing a full-stage `insufficient_evidence` (open question for Mahesh, design Q3); any API change.

## Acceptance criteria
- [ ] AC1 — `refusalA` (`all_citations_unsupported`): `role="status"` panel named "No answer shown" with the approved A copy; stack heading
  "Retrieved passages (no answer was shown)"; chips "Unsupported · 31.0%" and "Not checked" (no "0.0%"). App-level test: `document.body.textContent`
  has no `/verified/i` (whole tree, unscoped, so the HeroSearch sentence must be replaced with the approved copy). Same three checks for `refusalC`
  (`insufficient_evidence`, every chip "Not checked") with the C copy.
- [ ] AC2 — `refusalB` (`verification_unavailable`): B copy; App-level test with `fetch` stubbed: no toast ever rendered with a non-empty message, no `role="alert"`,
  "Retrieved passages" heading visible, `fetch` called once (no writing stage after a refusal).
- [ ] AC3 — `citations.test.js` covers design §1 rows 1–5: `status: supported` + `supported: false` → Unsupported; `partially_supported`, `contradicted`, `"bogus"` → Unsupported;
  no `status` + score 0 in refusal → Not checked; no output of the module matches `/verified/i`, and `text`/`tooltip` match `/\bSupported\b/` only for kind supported.
  Answer-mode `mixedAnswer` renders "Supported · 87.3%", "Unsupported · 12.0%" and "Not checked".
- [ ] AC4 — Early refusal (`citations: []`, no reason) renders as today: explicit asserts on "Relevance Protection Activated:", the echoed question in a `code`,
  the discover button (label unchanged) POSTing `/v1/papers/discover` with `{query}`, no `article` cards, no "Clinical Literature Synthesis".
- [ ] AC5 — "PostgreSQL pgvector Verified" is gone (answer and refusal); export heading is `## References`, no `/Verified/`, an unsupported entry ends
  "• Unsupported · 12.0%", an unchecked one "• Not checked"; Copy Synthesis and Export Note are absent in refusal mode; footer "n of m citations supported" in answer mode.
- [ ] AC6 — Refusal panel is `role="status"` and reachable in Tab order via its "Read the n retrieved passage(s)" link, which moves focus to `#references-heading`;
  a refusal with zero citations has no link and still renders the panel. Two-stage: quoted answer + "Writing a summary…" status, then swapped on a synthesized
  full response; a full-stage refusal keeps the quoted answer (App tests, design §AC6 rows).
- [ ] AC7 — CI `frontend` job green: `npm ci && npm run lint && npm test && npm run build`; lint warning count not above main's latest run.
- [ ] AC8 — PR body lists each FE-1 assert that was replaced/removed next to its stricter replacement (design §Risks; PM decision change 4).
- [ ] Docs: no README/API change expected. PRD QA-4 notes are pm-lead's (via `docs/` PR).

## Verification
```bash
cd app/frontend && npm ci && npm run lint && npm test && npm run build
# CI is the source of truth (sandbox can't reach registry.npmjs.org)
```

## Notes
- 2026-11-20 (pm-lead): split from FE-3 at the design review. Approved copy is in the design's PM decision (Q5) and §2 tables; hero sentence:
  "Ask research questions about the indexed arXiv papers. Every answer cites the passages it came from, and each citation is labelled supported, unsupported or not checked."
  Size: ~470 lines accepted (prod ~175); past ~550, move `App.test.jsx` to a follow-up rather than cut coverage.
