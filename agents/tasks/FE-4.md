# FE-4: Claim evidence panel: each claim's status, its source passage and quote, one click to the PDF page

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (Phase 1 item 8; Product PRD §7 principle 3 "one click to the source") |
| **PRD ref** | Product PRD UI-1, QA-3, QA-4, §7 principles 1–3; ADR-0014 (Proposed) |
| **Depends on** | **AI-8 merged** (claims + provenance JSON), **FE-3 merged** (same components), **ADR-0014 Accepted** |
| **Jira** | new story under epic KAN-5 "Research UI & citations" (`labels = "task-FE-4"`) |
| **Design required** | **yes** (`docs/design/FE-4.md`: layout, states, interaction; P0) |
| **Status** | Blocked (needs ADR-0014). Wave 3 once AI-8 and FE-3 are merged |

## Goal
Let a researcher check any statement in an answer in one or two clicks: see whether it was supported, unsupported or
couldn't be checked, read the exact quote inside its passage, and open the PDF at that page.

## Scope
- `SynthesisView.jsx`: render `claims[]` in order, each with a status chip (supported / unsupported / "not checked" for
  `unverified`, visually distinct from unsupported) and its `[n]` markers as buttons that focus the matching citation card.
  Without `claims`, fall back to today's rendering (older responses).
- `ReferencesStack.jsx`: each card shows "arXiv:ID vN · Section · p. N" (page only when present), the passage with the
  `quote` highlighted (exact substring match; if not found, show the quote separately and say it wasn't located), and a PDF
  link to `pdf_url#page=N` when a page is known.
- Vitest tests with ADR-0014-shaped fixtures.
- Out of scope: a PDF viewer (Phase 2), collections, any API change.

## Acceptance criteria
- [ ] AC1 — Each status renders a distinct chip with text (not colour only); `unverified` never shows "Supported" or "Verified" (tests).
- [ ] AC2 — Clicking or pressing Enter on a claim marker focuses the matching citation card (`aria-controls`/focus test).
- [ ] AC3 — The quote is highlighted inside the passage when it's an exact substring; the fallback is shown otherwise (tests).
- [ ] AC4 — The PDF link has `#page=N` only when `page` is present; version is shown as `vN` (tests).
- [ ] AC5 — A response without `claims` renders as FE-3 left it (test).
- [ ] AC6 — `npm run lint`, `npm test`, `npm run build` pass in CI.

## Verification
```bash
cd frontend && npm ci && npm run lint && npm test && npm run build
```

## Notes
- 2026-11-07 (pm-lead): from the 2026-11-07 plan (Phase 1 item 8, claim-evidence half). Wave 3.
