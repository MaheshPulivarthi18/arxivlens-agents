# FE-0c: Commit the theme tests (pre-paint/`theme.js` drift guard, ThemeToggle OS + cross-tab)

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P2 (harness/quality: guards FE-3 AC8's default flip, which must change two files in lockstep) |
| **PRD ref** | Product PRD §7 (accessible, readable UI); FE-0 QA "Missing tests" (`agents/reviews/FE-0/report.md` lines 47–49); FE-0 design §AC5 |
| **Depends on** | FE-1 (#68, merged `2410d2e`: Vitest + jsdom) and FE-0 (#69, merged `54c4de8`: `theme.js`, `ThemeToggle.jsx`, pre-paint script). No open PR touches `frontend/src/lib/`, `frontend/index.html` or `ThemeToggle*` (#70 adds only six `frontend/src/components/ui/*.jsx`; checked 2026-11-20 13:00Z via REST) |
| **Jira** | KAN-87 (epic KAN-5 "Research UI & citations"; labels `task-FE-0c`, `agent-frontend`, `arxivlens`) |
| **Design required** | no: tests only, no component, contract or dependency change |
| **Status** | Done: ArxivLens #85 merged by Mahesh → `d7d35ab` (2026-11-20 ~18:54Z) |

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
- 2026-11-20 ~13:45Z (frontend-engineer) **Build note** (Jira KAN-87). Draft PR [#85](https://github.com/MaheshPulivarthi18/ArxivLens/pull/85),
  branch `agent/frontend/FE-0c`, head `969c4fb` (2 commits on main `c37d27c`; 2 attempts). Files, both new: `frontend/src/lib/theme.test.js` (187 lines),
  `frontend/src/components/ThemeToggle.test.jsx` (98 lines). Nothing else changed. `ownership-check.sh origin/main agent/frontend/FE-0c` →
  `Ownership OK for role=frontend (285 changed lines)` (over the ~150 estimate: the 14-row agreement table plus the unit tables).
  - Attempt 1 `00630c3`: CI Frontend job 136312211020 failed with `TypeError: The URL must be of scheme file` at `theme.test.js:10` (file had 0 tests;
    ThemeToggle 4/4 passed). Cause: under jsdom, Vite's asset plugin rewrites the literal `new URL('<str>', import.meta.url)` to an http:// URL. Fix `969c4fb`:
    `const testFile = import.meta.url; fs.readFileSync(fileURLToPath(new URL('../../index.html', testFile).href))` (same file-relative URL).
  - Attempt 2 `969c4fb`: all 5 checks success. Frontend job [136313918021](https://github.com/MaheshPulivarthi18/ArxivLens/actions/runs/44743832355/job/136313918021)
    (merge `ea24147` into `c37d27c`): `Found 0 warnings and 0 errors.` · `✓ src/lib/theme.test.js (35 tests)` · `✓ src/components/ThemeToggle.test.jsx (4 tests)` ·
    `Test Files  5 passed (5)` · `Tests  58 passed (58)` · `✓ built in 760ms`.
  - Local: `npm ci` not run (registry ENOTFOUND; `--offline` → ENOTCACHED). Instead I used scratch harnesses (not committed): a minimal vitest stand-in;
    `theme.test.js` in bare Node with a fake `document`/`Storage` (35/35); `ThemeToggle.test.jsx` bundled by esbuild and run in headless Chromium with real
    React/react-dom 19.2.8 and stubbed Radix dropdown/`Button`/lucide (4/4).
  - [x] AC1 drift guard: `drift guard > uses the same DEFAULT_THEME as theme.js`, `> reads the same storage key as theme.js` (literals compared to the imports;
    no hard-coded default). Control with both files flipped to `"system"` (FE-3 AC8): 35/35 + 4/4 pass.
  - [x] AC2: 14 `it.each` rows (7 stored × OS dark/light). Each runs the extracted script in `vm` and `applyTheme(getStoredTheme())` from both `.dark` start states
    and compares `{dark, colorScheme}`.
  - [x] AC3: `theme.js > …` getStoredTheme (valid ×3, missing/invalid/empty/wrong-case/throwing), setStoredTheme (persist, invalid ignored + `setItem` not called,
    throwing swallowed), resolveTheme 3×2, watchSystemTheme (delivery, unsubscribe, later change not delivered), addListener/removeListener fallback.
  - [x] AC4: `ThemeToggle > in System mode follows an OS change dark -> light without user action` (name System (dark) → (light), `.dark` off, colorScheme light).
  - [x] AC5: `ThemeToggle > follows a theme change made in another tab` (Theme: Light, `.dark` off); `> ignores a storage event for another key` (stored value
    changed underneath, the event names another key → still Theme: Dark with `.dark`).
  - [x] AC6 local mutants, each a fresh copy (`mktemp -d`), never pushed. All 5 killed. (a) index.html default only → `uses the same DEFAULT_THEME` + 4 agreement
    rows (none/invalid/empty/throws, OS light); (b) theme.js key only → `reads the same storage key` + 3 agreement rows + 2 ThemeToggle tests; (c) no `storage`
    listener → `follows a theme change made in another tab`; (d) deps `[pref]` → `in System mode follows an OS change…` (`expected true toBe false`);
    (e) no-op cleanup → `watchSystemTheme calls back on change and its cleanup unsubscribes` + `removes its OS listener on unmount`. Re-run on `969c4fb`: same result.
  - [x] AC7: CI job above.
  - Unverified: the mutants ran only in the stand-in harnesses (real vitest/jsdom/Radix unavailable). In CI only the unmutated code ran.
- 2026-11-20 (pm-lead) **PM final review: APPROVE r1** (`agents/reviews/FE-0c/report.md`). All 6 evidence files at `e527bef` checked against AC1–AC7.
  PR #85 description rewritten with the Evidence section (stale AC1 bullet and line count fixed) and marked ready for review.
  QA nit 1 (`frontend/README.md:14` glob says `*.test.jsx`) and the optional no-`matchMedia` tests → Backlog (frontend, P3). QA [spec] finding 3 → pm-lead lesson.
