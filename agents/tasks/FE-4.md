# FE-4: Claim evidence panel: each claim's status, its source passage and quote, one click to the PDF page

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (Phase 1 item 8; Product PRD §7 principle 3 "one click to the source") |
| **PRD ref** | Product PRD UI-1, QA-3, QA-4, §7 principles 1–3; ADR-0014 (Accepted 2026-11-07); ADR-0018 (Proposed: `answer_kind`) |
| **Depends on** | **AI-8 merged** (claims + provenance JSON; design stage now), **FE-3 merged** (same components), **FE-1 merged** (harness), **FE-0 merged** (theme) and **FE-0b merged** (`ui/popover`, `ui/collapsible`; split 2026-11-19). ADR-0014 Accepted. ING-11b for real `page` values (fixtures suffice for tests) |
| **Jira** | KAN-44 under epic KAN-5 "Research UI & citations" (`labels = "task-FE-4"`) |
| **Design required** | **yes** (`docs/design/FE-4.md`: layout, states, interaction; P0) |
| **Status** | Ready (design stage). All deps merged: FE-3b #104 `dcb326a`, FE-0b #70, FE-0i #109, AI-8b #65, ADR-0019 #120. Picked cycle 2026-11-21T21:59Z: write `docs/design/FE-4.md` first; no code before pm-lead approves it |

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
- 2026-11-07 (pm-lead, RET-2 design review): at FE-4's design approval, check that **ING-10 has merged** before cards show "vN". Until then, on-demand ingests can label v3 content as v1. `page` is absent from every citation until **ING-11** lands, so the `#page=N` path is only reachable with fixtures. Today's fallback URLs (`ReferencesStack.jsx:45`, `SynthesisView.jsx:47`) are unversioned.
- 2026-11-17 (pm-lead, grooming): Status said "Blocked (needs ADR-0014)", which has been stale since 2026-11-07. Corrected. ING-10 merged (`4c15275`),
  so "vN" labels are trustworthy for new ingests. Status chips should use AI-8's `status` (which separates `unverified` from `unsupported`), not
  the `supported` bool. For NLI-verified LLM claims AI-8 gives no `quote` (the prompt doesn't ask for one), so the "quote not located"
  fallback is the common case for written answers. Say so in the design.
- 2026-11-19 (pm-lead, grooming): added **FE-0** (classic research theme) as a dependency. FE-1 is no longer env-blocked (#64/#67). Use FE-0's
  primitives: `ui/popover` for an `[n]` preview (paper title, section, status, on hover/focus) and `ui/collapsible` to expand the full passage
  on a dense reference card. AC2 still holds: Enter/click on `[n]` focuses the card, and the popover is extra help that must not trap focus.
  Status chips use the FE-0 status tokens, with *not checked* distinct from *unsupported*.
- 2026-11-20 13:00Z (pm-lead, sync): AI-8b (#65 `d121a68`), FE-1, FE-0 merged; still needs FE-3 and FE-0b.
- 2026-11-20 (pm-lead, FE-0b final review): #70 is raised (Ready to merge). Two caller-side rules from FE-0b QA for the design (also in `docs/design/FE-0.md` §6 amendment):
  (a) N3: a `ScrollArea` holding plain-text passages (no focusable children) gets `tabIndex={0}` and an `aria-label`; Radix sets no `tabindex` and Safari
  doesn't make scroll containers focusable. (b) If FE-4 shows toasts, a custom description colour in `toastOptions.classNames.description` needs `!`
  (the Toaster's `!text-muted-foreground` wins otherwise). Render tests for the primitives are FE-0d.
- 2026-11-21 21:00Z cycle (pm-lead, grooming): ADR-0019 (Accepted 2026-11-22, merged in #120 `c2b3bd6`) changes the data FE-4 renders: in a
  written answer (`answer_kind: synthesized`) every kept claim is `supported` and failed citations are removed from the answer markers, the claim's
  `markers` and `citations`, so marker numbers can skip ("[1] … [3]"). Unsupported / `unverified` chips now appear only on quoted answers and
  refusals. For the design: (a) AC1's per-status chips still need tests, but use quoted-answer fixtures for unsupported/unverified, and add one
  synthesized fixture with skipped markers (each `[n]` still focuses its own card); (b) don't render a "hidden citations" count, the API doesn't
  return one. Still waits on FE-3b (#104) merging.
- 2026-11-22 cycle 2026-11-21T21:59Z (pm-lead, pick): unblocked, since FE-3b (#104) and FE-0i (#109, `Badge` is a `<span>`) are merged. Design first
  (`docs/design/FE-4.md` from `agents/templates/design.md`); pm-lead approves before any code. For the design: (a) fold in the FE-3b PM review item:
  in refusal mode card [1] still shows the active ring (`App.jsx` `useState(1)` and the first-citation marker set on load), and FE-4 owns marker
  semantics, so say what is active in refusal mode; (b) ADR-0018 is still Proposed, so render `answer_kind` defensively (absent → treat as quoted)
  and don't depend on `synthesis_available`; (c) **don't edit app `README.md`** this cycle, because ING-6c (picked at the same time) edits it. If a
  README line is needed, list it in the design and pm-lead sequences it. (d) Leave `ui/badge.test.jsx` alone: FE-0j (Ready, next) owns it.
  Size: if the design projects > 400 changed lines, name the split seam (e.g. FE-4a claims + marker focus, FE-4b quote highlight + PDF page link).
