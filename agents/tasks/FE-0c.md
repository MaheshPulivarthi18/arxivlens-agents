# FE-0c: Commit the theme tests (pre-paint/`theme.js` drift guard, ThemeToggle OS + cross-tab)

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P2 (harness/quality: guards FE-3 AC8's default flip, which must change two files in lockstep) |
| **PRD ref** | Product PRD §7 (accessible, readable UI); FE-0 QA "Missing tests" (`agents/reviews/FE-0/report.md` lines 47–49); FE-0 design §AC5 |
| **Depends on** | FE-1 (#68, merged `2410d2e`: Vitest + jsdom) and FE-0 (#69, merged `54c4de8`: `theme.js`, `ThemeToggle.jsx`, pre-paint script). No open PR touches `frontend/src/lib/`, `frontend/index.html` or `ThemeToggle*` (#70 adds only six `frontend/src/components/ui/*.jsx`; checked 2026-11-20 13:00Z via REST) |
| **Jira** | needs Jira story (epic KAN-5 "Research UI & citations"; labels `task-FE-0c`, `agent-frontend`, `arxivlens`) |
| **Design required** | no: tests only, no component, contract or dependency change |
| **Status** | Ready (specced 2026-11-20 13:00Z) |

## Goal
FE-0's theme logic was verified only by QA's throwaway scripts (`agents/reviews/FE-0/checks/themejs.mjs`, `prepaint.mjs`). FE-3 AC8 will flip
`DEFAULT_THEME` from `"dark"` to `"system"` in **two** places (`src/lib/theme.js` and the inline pre-paint script in `index.html`). Commit tests so
that a change to one without the other fails CI, and so the ThemeToggle behaviours QA could only review statically are pinned.

## Scope
- New `frontend/src/lib/theme.test.js` and new `frontend/src/components/ThemeToggle.test.jsx`. Nothing else (no change to `theme.js`,
  `index.html`, `ThemeToggle.jsx`, `package.json` or the lockfile).
- Start from QA's scripts in `agents/reviews/FE-0/checks/` (`themejs.mjs`, `prepaint.mjs`); they are in this repo, read them, don't copy them to `app/`.
- Out of scope: flipping the default (FE-3 AC8), contrast checks (`contrast.mjs` stays QA tooling), any new dependency.
- Size: ~150 test lines.

## Acceptance criteria
- [ ] AC1 — Drift guard (`theme.test.js`): read `index.html` (`fs.readFileSync` relative to the test file via `new URL('../../index.html', import.meta.url)`),
  extract the inline classic `<script>` and assert its `DEFAULT_THEME` literal equals `theme.js`'s `DEFAULT_THEME`, and its storage key literal equals
  `THEME_STORAGE_KEY`. The test must **not** hard-code `"dark"` or `"system"` as the expected default (FE-3 flips it); it compares the two files.
- [ ] AC2 — Pre-paint behaviour (`theme.test.js`): run the extracted inline script with `vm` (or `new Function`) against stubbed `localStorage`,
  `matchMedia` and `document.documentElement`, for stored ∈ {none, `light`, `dark`, `system`, invalid `purple`, `""`, `getItem` throws} × OS ∈ {dark, light}.
  For each, the `.dark` class and `colorScheme` equal what `applyTheme(getStoredTheme())` from `theme.js` produces under the same stubs
  (the two implementations agree on all 14 combinations).
- [ ] AC3 — `theme.js` units: `getStoredTheme` returns `DEFAULT_THEME` for missing/invalid/throwing storage; `setStoredTheme` ignores an invalid value and
  swallows a throwing `setItem`; `resolveTheme` table (3 prefs × 2 OS); `watchSystemTheme` calls back on a change event and its returned function
  unsubscribes (a later change is not delivered), plus the `addListener`/`removeListener` fallback branch.
- [ ] AC4 — `ThemeToggle.test.jsx` (Testing Library, jsdom, `matchMedia` stubbed with a controllable `change` event): with stored `system`, firing the OS
  change dark→light toggles `document.documentElement.classList` `.dark` off without re-render from the user, and the trigger's accessible name changes
  from `Theme: System (dark)` to `Theme: System (light)`.
- [ ] AC5 — Cross-tab: dispatching `new StorageEvent('storage', { key: 'arxivlens-theme', newValue: 'light' })` after `localStorage.setItem` updates the
  trigger name to `Theme: Light` and removes `.dark`; a `storage` event for another key changes nothing.
- [ ] AC6 — Mutants, run locally (never pushed), each makes at least one new test fail (paste the failing test names):
  (a) change `DEFAULT_THEME` in `index.html` only; (b) change the key in `theme.js` only; (c) remove the `storage` listener in `ThemeToggle.jsx`;
  (d) drop `osDark` from the `applyTheme` effect's dependency list; (e) make `watchSystemTheme`'s cleanup a no-op.
- [ ] AC7 — `npm run lint`, `npm test`, `npm run build` green in CI (Frontend job); the job log lists both new test files.
- [ ] Docs: none (tests only). `frontend/README.md` only if it lists test files.

## Verification
```bash
cd app/frontend && npm ci && npm run lint && npm test && npm run build
npx vitest run src/lib/theme.test.js src/components/ThemeToggle.test.jsx
# Sandbox: registry.npmjs.org may be unreachable; CI's Frontend job is the source of truth.
```

## Notes
- 2026-11-20 13:00Z (pm-lead): specced from the Backlog line "OPS-H14 part … Still open: the frontend `theme.test.js` part" (FE-0 design review +
  FE-0 QA "Missing tests"). ID `FE-0c` is free (`grep -rn FE-0c docs/ agents/` empty before this spec) and not a PRD row.
- Picked before FE-2 because FE-2 edits `ReferencesStack.jsx` (moving the BibTeX builder), which FE-3 also edits; FE-0c touches only new files.
