# B-UI: Answer evidence UI: read the exact quote in its passage, open the PDF at that page, export the answer's references

| | |
|---|---|
| **Owner** | frontend-engineer (no ai part: the API already returns every field needed, see Notes) |
| **Priority** | P0 (Phase 1 item 8; Product PRD §7 principles 1 and 3, "one click to the source") |
| **PRD ref** | Product PRD UI-1, UI-5, QA-3, QA-4, §7; ADR-0003, ADR-0014, ADR-0019 (Accepted); ADR-0018 (Proposed: render `answer_kind` defensively) |
| **Depends on** | Nothing open. FE-4a (#128), FE-3a (#86), FE-3b (#104), AI-8a (#54), AI-8b (#65), ING-11b (#52) and ING-10 (#31) are merged |
| **Jira** | one story for the bundle under epic KAN-5 "Research UI & citations" (`labels = "task-B-UI"`); KAN-40, KAN-43, KAN-44 and KAN-20 are closed and point here |
| **Tier** | Large. Design: `docs/design/FE-4.md` (approved 2026-11-22, §1 `locateQuote`/`pdfHref`/`arxivLabel`, §3 card) covers AC1–AC3. **Before code**, the developer adds a short "B-UI addendum: .bib export" section to that file (AC4–AC5: builder API, entry format, trigger placement, refusal state) and pm-lead approves it |
| **Size estimate** | ~500 changed lines incl. tests (the FE-4b part ~320, the FE-2 part ~180). One PR |
| **Absorbs** | AI-8 (KAN-43, API done), FE-3 (KAN-40, done in FE-3a/3b), FE-4 (KAN-44), FE-4b (no key), FE-2 (KAN-20) |
| **Branch** | `agent/frontend/B-UI` |
| **Status** | In QA (PR #132) |

## Goal
A researcher checks any answer sentence in one or two clicks: the card shows the exact supporting words highlighted
inside the passage, which paper version, section and page they come from, and opens the PDF at that page. When they're
done, they take every reference in the answer at once as a `.bib` file. No label claims more than the system checked.

## What is already done (checked on app `main` `5fcbd5f`, don't redo)
- `/v1/ask` citations carry `status`, `paper_version`, `page` (from `paper_chunk_pages`), `quote` (only on supported
  citations; it occurs in `content` after `normQuote`) and a versioned `pdf_url`, and the response has `claims[]` (`rag.go:42-57,100-104`).
- Status chips use `citationState` (`lib/citations.js`): "Supported · x%", "Unsupported · x%", "Not checked". No output says
  "Verified" (FE-3a). The "PostgreSQL pgvector Verified" footer and the "Verified Citations" export heading are gone.
- Claims list with per-claim chips. `[n]` markers focus their own card, and nothing is active on load (FE-4a).

## Scope
- `frontend/src/lib/citations.js` + `citations.test.js`: `locateQuote`, `pdfHref`, `arxivLabel` (FE-4 design §1, condition 5).
- New `frontend/src/lib/bibtex.js` + `bibtex.test.js`: the one BibTeX builder (the per-card "Copy BibTeX" in
  `ReferencesStack.jsx:23-34` moves onto it).
- `frontend/src/components/ReferencesStack.jsx` + `.test.jsx`: the meta line, the passage with `<mark>` and an sr-only
  "Quote: ", the four passage states, a `ui/collapsible` excerpt for passages > 480 chars (this replaces the `max-h-36`
  scroll box), the PDF link, the "Cited by claim n" / "Check n" rows (these replace FE-4a's interim one-chip-per-check
  header), and the "Export" `ui/dropdown-menu` with the item "BibTeX (.bib)".
- `frontend/src/test/fixtures.js`, and `App.test.jsx` only where AC3 needs it.
- Label honesty (added at design approval 2026-11-28): the hero tagline in `HeroSearch.jsx:51` and the Markdown note heading plus the empty `§ ` in `citations.js:45-48`
  (see `docs/design/FE-4.md` › PM decision B-UI addendum).
- Out of scope: any API or `rag.go` change; a PDF viewer; saved questions (rest of UI-5); other Markdown "Export Note"
  wording; app `README.md` (no line describes these cards).

## Acceptance criteria
- [ ] AC1: Quote in passage (FE-4b AC3). A **supported** citation's `quote` is highlighted inside its passage when it occurs
  after the server's `normQuote` normalisation (inline refs `[12]`, `[3, 4]`, `[5–7]` removed, whitespace collapsed, no space before `.,;:!?`, case-sensitive).
  The `<mark>` covers only raw text that normalises to the quote. A quote that is present but not located gets the "Quoted text (not found in the passage shown
  above)" block. A supported citation with no quote gets the no-quote note. Unsupported and not-checked citations get no highlight and no note, even with a quote.
  `locateQuote` table: `\n` inside, double spaces, each ref form, space before `.`, case mismatch → null, empty/whitespace → null,
  and the NBSP `[3, 4]` row keeps the ref. Long passages: the excerpt contains the `<mark>`, and "Show full passage" toggles `aria-expanded`.
- [ ] AC2: Provenance and PDF page (FE-4b AC4). The meta line reads `arXiv:<id>v<N> · § <section> · p. <N>`: the `v` part only when
  `paper_version > 0`, the section omitted when empty, the page only for an integer ≥ 1. No "Chunk #" and no "General" (`ReferencesStack.jsx:114` today).
  The PDF href is `pdf_url` (or the arXiv fallback) + `#page=N`, only for a valid page; an existing fragment is replaced. The link text is "Open PDF at p. N ↗" or "Open PDF ↗".
  Tests for page 4, 0, null, `"4"`, absent, and `paper_version` 0.
- [ ] AC3: Cited-by rows (FE-4b AC2d). A card for a repeated marker lists one row per check: "Cited by claim n" when the positional
  invariant holds, "Check n" when it doesn't. After a click on a marker, the row for that `(marker, pos)` has `aria-current="true"` and no other row does.
  Test with `synthesizedSkips`: click the **second** `[1]`, and the claim-2 row is current, not claim 1 (kills "marker ignores pos" at runtime). Also `brokenPositional`.
- [ ] AC4: One honest BibTeX builder (`lib/bibtex.js`). Tests cover: one entry per unique `arxiv_id` (a paper cited 3× → 1 entry), stable keys
  (`arxiv<id without punctuation>`, the same on every call), escaping of `{ } & % $ # _` in titles, `eprint` + `archivePrefix = {arXiv}` +
  `url = {https://arxiv.org/abs/<id>}`, and `year` **derived from the arXiv ID** (`2401.01234` → 2024, `cs/0601001` → 2006), omitted when the ID
  doesn't parse. No fabricated field: today's hard-coded `year = {2026}` and `primaryClass = {cs.AI}` are removed, and no `author` field (the API has
  no authors, see Notes). The per-card "Copy BibTeX" uses the same builder (test).
- [ ] AC5: Export all (FE-2). In answer mode the references header has an "Export" dropdown (`ui/dropdown-menu`) with "BibTeX (.bib)". It downloads
  `arxivlens-<YYYYMMDD-HHMMSS>.bib` holding the AC4 entries for the citations the answer **shows**: on a written answer only the verified ones
  (ADR-0019), on a quoted answer all of them. The trigger is a labelled button, and keyboard-operable (open with Enter/Space, item with Enter; test).
  In refusal mode the trigger is absent or disabled with an explanation (test). The design addendum picks which.
- [ ] AC6: Older and partial responses. A response without `claims`, `page`, `quote` or `paper_version` renders as `main` does today, apart from the
  intended meta-line change (test). No test asserts "Verified" text anywhere, and the existing no-"Verified" whole-tree tests stay.
- [ ] AC7: CI `frontend` job green: `npm ci`, `npm run lint` (warnings not above main's latest run), `npm test`, `npm run build`. No existing test
  is weakened. `ReferencesStack.test.jsx:30` becomes an exact meta-line assertion, and the PR body lists it. `Agent ownership check` green.
- [ ] Docs: the design addendum is in `docs/design/FE-4.md`. After merge, pm-lead flips Product PRD UI-5 to ✅ for export (saved questions stay open) and updates the UI-1 note (docs PR, no ticket).

## Verification
```bash
cd app/frontend && npm ci && npm run lint && npm test && npm run build
# QA mutation (citation evidence shown to the user only, locally, never pushed): drop the kind==='supported' highlight guard;
# locateQuote case-insensitive; drop the inline-ref step; pdfHref >= 1 → >= 0; row click ignores pos.
# No mutation on styling/classNames.
```

## Checklist
- [ ] (none yet)

## Notes
- 2026-11-28 (frontend-engineer): QA r1 rework (round 1 of 2) pushed on #132, head `5fa2790`. Added `locateQuote` rows for F1 (M9: raw start after a normalised prefix, exact `{start, end}`), F2 (M13: NBSP and U+2009 collapse) and F3 (M7: whitespace-only quote on content holding it). Stand-in run: 83/83 on head, all three mutants killed (scratch copy, not pushed). F4: as-built notes in `docs/design/FE-4.md` (`804f86c`). F5: PR Size corrected to 756 lines (prod 428, tests 328). CI green on all 5 jobs (Frontend: 0 warnings, 266/266, build OK). Back to In QA.
- 2026-11-28 (frontend-engineer): draft PR ArxivLens #132, head `5cc1cdd`, 745 changed lines (prod 360, tests 385; over the ~520 estimate, under the 800 cap: pm-lead to rule). CI green on every job (Frontend: 0 oxlint warnings, same as main; 261/261 tests; build OK). Tagline and Markdown note changes are listed under "Label honesty" in the PR. Status: In QA.
- 2026-11-28 (pm-lead): design addendum approved with 3 conditions (`docs/design/FE-4.md` › PM decision B-UI addendum). The tagline and the note heading are folded in.
- 2026-11-28 (pm-lead): bundle created in the process reset. No API change is needed: `Citation` already has `status`, `paper_version`, `page`,
  `quote` and `pdf_url`, and `claims[]` exists. So there is no B-UI-api part and the PR is frontend-only. The API has **no authors or published date**
  on citations (`papers.authors`/`published_at` exist in the schema but aren't returned). Adding them is an HTTP-contract change, so it needs an ADR.
  It's on the decisions list for Mahesh, and until then the `.bib` has no `author`. The year comes from the arXiv ID: that is the first-version month, the
  usual convention for arXiv BibTeX.
- `page` is real since ING-11b (#52), so AC2's `#page=N` is reachable on real responses as well as fixtures.
- History: FE-4 design and conditions are in `docs/design/FE-4.md`, and the older specs are in `agents/tasks/FE-4b.md` and `FE-2.md` (closed).
