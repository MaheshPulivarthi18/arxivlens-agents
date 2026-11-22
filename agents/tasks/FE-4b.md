# FE-4b: Citation card shows the quote highlighted in its passage, `arXiv:IDvN · § · p. N`, and opens the PDF at that page

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (Phase 1 item 8, second half of FE-4; Product PRD §7 principles 1 and 3) |
| **PRD ref** | Product PRD UI-1, QA-3, §7 principles 1–3; ADR-0014 (Accepted: quote = whitespace-normalised, case-sensitive match) |
| **Depends on** | **FE-4a merged** (same `ReferencesStack.jsx`, `lib/citations.js`, `test/fixtures.js`). ING-10 merged (`4c15275`). ING-11b for real `page` values (fixtures suffice) |
| **Jira** | create: story under epic KAN-5 "Research UI & citations", labels `task-FE-4b`, `design-required`; link to KAN-44 (FE-4 umbrella) |
| **Design required** | yes: covered by `docs/design/FE-4.md` (approved; §1 `locateQuote`/`pdfHref`/`arxivLabel`, §3 meta line, passage + quote, long passages, PDF link) |
| **Status** | Blocked (needs FE-4a merged). Specced 2026-11-22 at the FE-4 design gate |

## Goal
On every citation card a researcher reads the exact words that support the claim, highlighted inside the passage, sees which paper version,
section and page it comes from, and opens the PDF at that page in one click.

## Scope
- Files expected to change (app repo):
  - `frontend/src/lib/citations.js` + `citations.test.js`: `locateQuote`, `pdfHref`, `arxivLabel` (design §1, condition 5).
  - `frontend/src/components/ReferencesStack.jsx` + `ReferencesStack.test.jsx`: meta line, passage with `<mark>` + sr-only "Quote: ", the four passage states,
    `ui/collapsible` excerpt for passages > 480 chars (removes the `max-h-36` scroll box), PDF link text/href/aria-label (design §3).
  - `frontend/src/test/fixtures.js`: `quoteNotLocated`, `quoteOnUnsupported`, `longPassage`, `noVersion`, page variants; a `normQuote`-form quote on `quotedClaims` citation 1.
- Out of scope: app `README.md` (no line needed), PDF viewer (Phase 2), any API change, FE-2 export.

## Acceptance criteria
- [ ] AC3 — A supported citation's `quote` is highlighted in its passage when it occurs after the server's `normQuote` normalisation (inline refs removed,
  whitespace collapsed, no space before `.,;:!?`; case-sensitive). The `<mark>` covers only raw text that normalises to the quote. Otherwise: quote present but not located →
  the "Quoted text (not found in the passage shown above)" block with the quote; supported with no quote → the no-quote note; unsupported/not checked → no highlight, no note,
  even if a quote is present. `locateQuote` table includes `\n` inside, double spaces, `[12]`, `[3, 4]`, `[5–7]`, space before `.`, case mismatch → null,
  empty/whitespace → null, and the NBSP row `[3, 4]` → ref kept (condition 5). Long passages: excerpt contains the `<mark>`, "Show full passage" toggles `aria-expanded` and shows the full text.
- [ ] AC4 — Meta line reads `arXiv:<id>v<N> · § <section> · p. <N>` (`v` only when `paper_version > 0`, section omitted when empty, page only for an integer ≥ 1; no "Chunk #", no "General").
  PDF href is `pdf_url` (or the arXiv fallback) + `#page=N` only for a valid page, with an existing fragment replaced; link text "Open PDF at p. N ↗" / "Open PDF ↗"; tests for page 4, 0, null, `"4"`, absent, and `paper_version` 0.
- [ ] AC2d (moved from FE-4a, pm-lead 2026-11-22) — A card for a repeated marker lists one row per check: "Cited by claim n" when the positional
  invariant holds, "Check n" when it doesn't; after a click on a marker, the row for that `(marker, pos)` has `aria-current="true"` and no other row does.
  These rows replace FE-4a's interim one-chip-per-check header. Tests: `ReferencesStack.test.jsx`, `App.test.jsx` (`synthesizedSkips`, `brokenPositional`).
- [ ] AC6 — CI `frontend` job green: `npm ci`, `npm run lint` (warnings not above main's latest run), `npm test`, `npm run build`. `ReferencesStack.test.jsx:30` replaced by an exact meta-line assertion (listed in the PR body); no other existing test weakened.
- [ ] Docs: after merge, pm-lead updates FE-4 umbrella and the Product PRD UI-1 note (via `docs/` PR). No app README change.

## Verification
```bash
cd frontend && npm ci && npm run lint && npm test && npm run build
# QA: kill the FE-4b mutants from docs/design/FE-4.md §Test plan: drop the kind==='supported' highlight guard; pdfHref >= 1 → >= 0;
# locateQuote case-insensitive; drop the inline-ref step; ASCII whitespace class → \s in the regex steps (condition 5)
```

## Notes
- 2026-11-22 (pm-lead, design gate): split from FE-4 (≈ 250 changed lines). Label format `arXiv:2401.01234v2` approved (Q3); copy approved (Q5). `page` is absent on every
  real response until ING-11b, so the `#page=N` path is fixture-only; say so in the PR evidence. FE-2 (`ReferencesStack.jsx`) waits on this task.
- 2026-11-22 (pm-lead, cycle 2026-11-22T02:00Z): FE-4a size decision moved the multi-entry "Cited by claim n" / "Check n" rows and their
  `aria-current` here (new AC2d; design `docs/design/FE-4.md` §3 multi-entry bullet). Size estimate grows to ≈ 320 changed lines; split again if it passes 400.
