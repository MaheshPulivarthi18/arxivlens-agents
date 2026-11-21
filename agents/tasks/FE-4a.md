# FE-4a: Claims list with per-claim status chips; `[n]` markers focus their own card

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (Phase 1 item 8, first half of FE-4; Product PRD §7 principles 1 and 3) |
| **PRD ref** | Product PRD UI-1, QA-3, QA-4, §7 principles 1–3; ADR-0003, ADR-0014 (Accepted), ADR-0019 (Accepted); ADR-0018 (Proposed, not depended on) |
| **Depends on** | FE-3b #104, FE-0i #109, AI-8b #65, ADR-0019 #120 (all merged). Design `docs/design/FE-4.md` **approved with conditions** 2026-11-22 |
| **Jira** | create: story under epic KAN-5 "Research UI & citations", labels `task-FE-4a`, `design-required`; link to KAN-44 (FE-4 umbrella) |
| **Design required** | yes: covered by `docs/design/FE-4.md` (approved; §1 `claimState`/`claimCitations`/`groupByMarker`, §2, §3 grouping/focus/rows, §4, §5, §6) |
| **Status** | Ready. Picked cycle 2026-11-21T21:59Z (follows the FE-4 design gate) |

## Goal
A researcher sees every statement of an answer with its own verdict (Supported / Unsupported / Not checked), and each `[n]` marker takes
keyboard and mouse users straight to that passage's card. Fixes the duplicate `ref-<n>` cards for written answers that cite one passage twice
and the stray active ring in refusal mode.

## Scope
- Files expected to change (app repo):
  - `frontend/src/lib/citations.js` + `citations.test.js`: `claimState`, `claimCitations`, `groupByMarker` (design §1).
  - `frontend/src/components/SynthesisView.jsx` + `SynthesisView.test.jsx`: claims mode list, marker buttons with `aria-controls`, `(marker, pos)` callback, `ui/tooltip` preview (§2).
  - `frontend/src/components/ReferencesStack.jsx` + `ReferencesStack.test.jsx`: cards from `groupByMarker`, keyed by `trace_id` + marker, `tabIndex={-1}`, focus ring,
    `data-active`, "Cited by claim n" / "Check n" rows with `aria-current`, heading count = cards, ignore `active` in refusal mode (§3 first two bullets only).
  - `frontend/src/App.jsx` + `App.test.jsx`: `active = {marker, pos} | null`, initial `null`, cleared on new search and on the quoted → written swap,
    `handleCitationClick` focuses + scrolls (reduced-motion aware) (§4).
  - `frontend/src/test/fixtures.js`: `quotedClaims`, `synthesizedSkips`, `brokenPositional` (+ malformed-claims variants).
- Out of scope (FE-4b): quote highlight / `locateQuote`, meta line (`arXiv:IDvN · § · p. N`, "Chunk #id", "General"), passage box / collapsible, PDF `#page=N` link,
  `ReferencesStack.test.jsx:30` assertion. Also out: app `README.md` (no line needed), `ui/badge.test.jsx` (FE-0j), any API change, a "Back to claim" link.

## Acceptance criteria
- [ ] AC1 — With `claims`, each claim renders in order as an item of the list "Claims in this answer" with a text + icon chip: `supported` → "Supported",
  `unverified` → "Not checked", anything else (`unsupported`, reserved, unknown, missing) → "Unsupported"; the three use different `Badge` variants;
  no `unverified` claim or chip contains "Supported" or "verified" (any case). A claim with `markers: []` shows its chip and no buttons. `synthesizedSkips`
  renders markers `[1]`, `[1]`, `[3]`, no `[2]`, and no "hidden" text (ADR-0019). Tests: `citations.test.js › claimState`, `SynthesisView.test.jsx`.
- [ ] AC2 — Click, Enter and Space on a claim marker each call `onCitationClick(marker, pos)` (`pos` = positional citation index) and, in `App`, move
  `document.activeElement` to the article "Citation [n]", which has `data-active`; for a repeated marker the matching "Cited by claim n" row has
  `aria-current="true"`. The marker has `aria-controls="ref-<n>"`. The preview tooltip opens on keyboard focus with title + status, and after Enter focus is on the card
  (design condition 4). With a broken positional invariant, markers still map by number and rows read "Check n".
- [ ] AC2b — Nothing is active on load in any mode; refusal A/B/C never shows `[data-active]`; after the written answer replaces the quoted one, no card is active (App tests).
- [ ] AC2c — One card per distinct marker: no duplicate `id="ref-n"` in the DOM for `synthesizedSkips`; the heading count (cards) and footer "x of y citations supported" (entries)
  are both pinned in a test for that fixture (design condition 3).
- [ ] AC5 — Responses without `claims`, with `claims: []`, or with malformed claims render the FE-3 prose with `[n]` buttons and no "Claims in this answer" list. Every existing
  FE-1/FE-3 test in `SynthesisView.test.jsx`, `ReferencesStack.test.jsx` and `App.test.jsx` passes **unmodified** (design condition 1; list any unavoidable change in the PR body with its stricter replacement).
- [ ] AC6 — CI `frontend` job green: `npm ci`, `npm run lint` (warning count not above main's latest run), `npm test`, `npm run build`.
- [ ] Docs: update `docs/design/FE-4.md` §2 item 3 wording per condition 1 (direct to main here). No app README change.

## Verification
```bash
cd frontend && npm ci && npm run lint && npm test && npm run build
# QA: kill the FE-4a mutants from docs/design/FE-4.md §Test plan: claimState unverified→supported;
# claimCitations without the marker-equality check; active initial value back to 1; drop tabIndex={-1}/.focus()
```

## Notes
- 2026-11-22 (pm-lead, design gate): split from FE-4 (design §Size and split, ≈ 365 changed lines). If it goes over 400, move the multi-entry
  "Cited by claim n" rows to FE-4b instead of growing this PR. Keep the card body (meta line `ReferencesStack.jsx:100`, passage `:106`, PDF link) untouched (condition 2).
  The tooltip replaces the 2026-11-19 popover Note (Q1). Evidence: screenshots of quoted claims (three chip kinds), `synthesizedSkips` (skip + grouping + both counts), and a refusal with no ring.
