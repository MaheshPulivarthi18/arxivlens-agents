# FE-2: "Export all citations" (.bib) for an answer

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P2 |
| **PRD ref** | UI-5 (per-citation BibTeX copy already exists in `ReferencesStack.jsx`; this completes the "export" half) |
| **Depends on** | **FE-1 merged** (harness) and **FE-0 merged** (theme, `ui/dropdown-menu`) |
| **Status** | Ready by deps (FE-3b #104 merged), but held behind FE-4 (P0, picked 2026-11-21T21:59Z): both edit `ReferencesStack.jsx`. Start after FE-4 merges |

## Goal
Priya (Product PRD persona) copies citations into a related-work draft. Let her take all of an answer's references at once.

## Scope
- A button in the references area: "Export .bib" → downloads `arxivlens-<timestamp>.bib` containing one entry per unique `arxiv_id` in the answer (dedupe papers cited multiple times).
- Reuse the existing per-citation BibTeX builder; move it to `src/lib/bibtex.js` so both paths share it.
- Out of scope: saved questions (rest of UI-5).

## Acceptance criteria
- [ ] AC1 — Unit tests for `bibtex.js`: dedupe by arxiv_id, escaping of `{ } &` in titles, stable keys.
- [ ] AC2 — Button is keyboard accessible and labelled; disabled when the answer is a refusal.
- [ ] AC3 — Lint, test, build pass.

## Verification
```bash
cd frontend && npm ci && npm run lint && npm test && npm run build
```

## Notes
- 2026-11-19 (pm-lead, grooming): added **FE-0** as a dependency. Put "Export" in a `ui/dropdown-menu` from FE-0 (items: "BibTeX (.bib)"
  now; room for Markdown later), styled with the theme tokens. AC2 applies to the trigger and the items (Radix gives keyboard support;
  test it). The trigger is disabled for refusals. FE-2 and FE-3 both touch `ReferencesStack.jsx`/`SynthesisView.jsx`, so run FE-2 after FE-3 merges, or
  keep the button in a file FE-3 doesn't change.
- 2026-11-20 13:00Z (pm-lead, sync): FE-1/FE-0 merged. Held behind FE-3 (shared `ReferencesStack.jsx`; FE-3 is P0 and also restyles the references area FE-2's button sits in).
