# FE-0e: Move the secondary screens (ingest, infrastructure, library, toast) to theme tokens

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P1 (unblocks P0 FE-3b's theme flip; WCAG 1.4.3 in light mode) |
| **PRD ref** | Product PRD §7 (readable, accessible UI); FE-0 design (tokens); FE-3 design PM decision Q1 |
| **Depends on** | FE-0 #69 merged (`54c4de8`), FE-1 #68 merged. No overlap with FE-3a or open PRs #70, #79, #81–#85 (checked via REST 2026-11-20) |
| **Jira** | KAN-91 (epic KAN-5 "Research UI & citations"; labels `task-FE-0e`, `agent-frontend`, `arxivlens`) |
| **Design required** | no: class swaps to existing tokens + one grep test; no new component, contract or dependency |
| **Status** | Ready (WIP: start when a frontend slot frees; independent of FE-3a, so they may run together) |

## Goal
When FE-3b flips the default theme to "system", an OS-light visitor must not see hard-coded dark-palette text (emerald-400 ≈ 1.8–1.9:1 and red-300 on the
light card). Move these four components to FE-0's tokens and add a guard so the palette classes don't come back.

## Scope
- Files: `frontend/src/components/IngestModal.jsx`, `InfrastructureModal.jsx`, `PapersLibrary.jsx`, `Toast.jsx`; new `frontend/src/test/tokens.test.js`.
- Mapping (guide; QA checks contrast, not the exact class): accent text → `text-primary`; icon tiles → `bg-accent text-accent-foreground`; success panels/borders →
  `bg-muted border-border` or the `supported` token; error text/panels (`red-*`) → `text-destructive`, `bg-destructive/10 border-destructive/30`; warning icon
  (`amber-400`) → `text-muted-foreground` or `unsupported` (no new token); spinners → `border-primary`; Toast border/icon → `border-border`, `text-primary`.
  Every new class must be a mapped colour in `tailwind.config.js` (frontend rule: classes must generate CSS).
- Out of scope: copy, layout, `ui/badge.jsx` (FE-3a retargets `arxiv`), the ask-flow files (FE-3a/FE-3b), mounting sonner, the theme default.

## Acceptance criteria
- [ ] AC1 — `src/test/tokens.test.js` (Node `fs` in Vitest) asserts the four files contain no
  `/\b(?:[a-z-]+:)*(text|bg|border|ring|from|via|to|shadow)-(slate|emerald|amber|cyan|teal|red|green)-\d/`. The file list is an exported/obvious array so FE-3b can extend it.
- [ ] AC2 — QA evidence: contrast of every text colour now used in the four files on its surface, light and dark, ≥ 4.5:1 (≥ 3:1 for icons/large text),
  computed from `src/index.css` with FE-0's appendix script.
- [ ] AC3 — Existing tests pass; no behaviour, copy or DOM-structure change (diff is class strings + the new test).
- [ ] AC4 — CI `frontend` job green (`npm ci && npm run lint && npm test && npm run build`), lint warnings not above main.

## Verification
```bash
cd app/frontend && npm ci && npm run lint && npm test && npm run build
```

## Notes
- 2026-11-20 (pm-lead): specced at the FE-3 design review (Q1 option b). Counts at `c37d27c`: InfrastructureModal 7, IngestModal 8, PapersLibrary 4, Toast 2
  palette-class lines (text, bg, border).
