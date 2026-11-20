# FE-3a: Show refusals with their evidence and label citations honestly (Supported / Unsupported / Not checked)

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (ADR-0003 consequence: unsupported and unchecked citations stay visibly flagged; Product PRD §7 principles 1–2) |
| **PRD ref** | Product PRD UI-1, QA-4, QA-5, §7; ADR-0003 (Accepted), ADR-0014 (Accepted); parent [FE-3](FE-3.md) |
| **Depends on** | FE-1 #68 merged (`2410d2e`), FE-0 #69 merged (`54c4de8`), AI-7 / #46 / AI-8b merged. **Not** FE-0b #70 (no `ui/tooltip` here). No file overlap with open PRs #70, #79, #81–#85 (checked via REST 2026-11-20) |
| **Jira** | KAN-40 (parent FE-3) for now; sub-task or new story under epic KAN-5, labels `task-FE-3a`, `agent-frontend`, `arxivlens` (pm-lead creates) |
| **Design required** | yes, done: `docs/design/FE-3.md` **Approved with changes** (pm-lead 2026-11-20). Build to the design + its PM decision |
| **Status** | In QA: draft PR #86 |

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
- 2026-11-20 (frontend-engineer, Build): draft PR [#86](https://github.com/MaheshPulivarthi18/ArxivLens/pull/86), branch `agent/frontend/FE-3a`, head `e90de79`
  (base `c37d27c`). 10 files, +398 / −98 = 496 changed lines: `lib/citations.js` +51 (new), `lib/citations.test.js` +85 (new), `SynthesisView.jsx` +75/−37
  (~24 of those are the footer re-indented under `!refusalReason`), `SynthesisView.test.jsx` +75/−7, `ReferencesStack.jsx` +18/−38, `ReferencesStack.test.jsx` +43/−8,
  `test/fixtures.js` +42/−4, `ui/badge.jsx` +7/−3, `HeroSearch.jsx` +1/−1 (PM sentence, copy only), `App.jsx` +1.
  - **Size split (PM change 5):** with `src/App.test.jsx` (+144) the diff was 640 lines (> ~550), so App.test.jsx is **not** in #86. **Follow-up request for pm-lead:**
    "FE-3a2: App-level tests for FE-3a" — new `frontend/src/App.test.jsx` only, after #86 merges: whole-tree `document.body.textContent` has no `/verified/i` for
    `refusalA` and `refusalC`; `refusalB` with `fetch` stubbed and `Toast` mocked via `vi.hoisted` + `vi.mock` (only ever rendered with `''`, no `role=alert`, heading visible,
    `fetch` called once); early refusal (banner text, echoed question in `code`, discover button POSTs `/v1/papers/discover` `{query}`, no `article`, no "Clinical Literature
    Synthesis"); the panel link focuses `#references-heading`; two-stage swap on a deferred full response; full-stage refusal keeps the quoted answer. Fixtures are already in #86.
    A draft (parses with `bun build`, never run) was left in the session scratchpad; not durable, recreate from design §Test plan.
  - Commands: `npm ci`/lint/test/build not runnable locally (registry blocked). `bun build --no-bundle` on each changed file: all parse. `node` run of `citationState`/`markdownNote`
    over every fixture: outputs match design §1. `.github/scripts/ownership-check.sh origin/main agent/frontend/FE-3a` → `Ownership OK for role=frontend (496 changed lines)` (+ >400 warning).
  - **CI on `e90de79`: all 5 checks success.** Frontend job 136324730223: `oxlint` "Found 0 warnings and 0 errors." (main 0); `vitest run` 4 files, **66 passed**
    (citations.test.js 35, ReferencesStack 11, SynthesisView 15, HeroSearch 5); `vite build` "built in 784ms".
  - AC1: component level done (`SynthesisView › refusal A/C shows its copy in a "No answer shown" status panel`, `ReferencesStack › refusal A: heading…/chips/no 0.0%`,
    `› refusal C: every chip reads "Not checked"`); hero sentence replaced. App-level whole-tree assert → follow-up.
  - AC2: `SynthesisView › refusal B` (copy, role=status, no alert, no `/verified/i`). App-level fetch/toast test → follow-up.
  - AC3: `citations.test.js` (rows 1–5 incl. `supported`+`supported:false`, `partially_supported`, `contradicted`, `"bogus"`, legacy score 0 in refusal; `/verified/i` never;
    `/\bSupported\b/` only for kind supported; no "entail/NLI/cosine/embedding" in tooltips), `ReferencesStack › answer mode…`, `SynthesisView › Export Note…` on `mixedAnswer`.
  - AC4: code path unchanged (App.jsx diff is the one prop line); its explicit test → follow-up. **Not verified in #86.**
  - AC5: `SynthesisView › no "PostgreSQL pgvector Verified"…`, `› Export Note writes "## References"…` (unsupported entry ends `• Unsupported · 12.0%`, unchecked `• Not checked`),
    `› refusal mode hides Copy Synthesis and Export Note`, `› answer-mode footer … "1 of 3 citations supported"`.
  - AC6: `SynthesisView › refusal panel is in the tab order through its passages link`, `› a refusal with zero citations still renders the panel, without a link`;
    heading `id="references-heading"` + `tabindex=-1` asserted in ReferencesStack. Link→focus across components and the two-stage rows → follow-up.
  - AC7: CI green (above). AC8: PR body has the FE-1 replaced-assert table (4 rows + fixture rename).
  - Not verified / notes: chip tooltip is a `title` attribute until FE-3b wires `ui/tooltip`; the `Info` icon is used for "Not checked" (design said `CircleHelp`; avoided an
    icon-name risk on lucide-react 1.x with no local install). No Jira/board change (orchestrator).
