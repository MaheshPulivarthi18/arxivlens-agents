# FE-0: Classic research theme: fonts, tokens, dark mode, theme toggle (part a of the split; FE-0b = other primitives)

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P1 (foundation for FE-3, FE-4, FE-2) |
| **PRD ref** | Product PRD UI-1, UI-2; §7 principles 1 "Evidence first" and 3 "One click to the source" |
| **Depends on** | none. ArxivLens #64 (`085183e`) and #67 (`4c7d327`), which added the Radix, sonner, fontsource and typography packages, are merged. Independent of FE-1 (disjoint files, see Scope) |
| **Jira** | story under epic KAN-5 "Research UI & citations" (`labels = "task-FE-0"`) |
| **Design required** | **yes**: `docs/design/FE-0.md` (palette with HSL values and contrast ratios, type scale, primitives API, theme toggle behaviour). pm-lead approves before any code |
| **Status** | In QA: draft [ArxivLens #69](https://github.com/MaheshPulivarthi18/ArxivLens/pull/69), head `ca76bea`, CI green (2026-11-19). Split: the six other primitives are [FE-0b](FE-0b.md) |

## Goal
Mahesh asked for a "classic UI, think like a pro". Give ArxivLens the look of a research tool (arXiv, Semantic Scholar,
a journal page) instead of today's dark "clinical AI" dashboard: serif for what researchers read, a quiet sans for the
chrome, a neutral palette with one restrained accent, in light and dark mode. Answers and citations should read like a
paper, and trust states should be calm and legible (§7: evidence first). This ticket lays the foundation (tokens, fonts,
primitives, theme switch). Feature components adopt it in FE-3, FE-4 and FE-2.

## Direction (agreed with Mahesh, 2026-11-19)
- **Type:** Source Serif 4 (`@fontsource-variable/source-serif-4`) for paper titles, answer prose and headings in reading
  areas. Inter (`@fontsource-variable/inter`) for UI chrome (nav, buttons, labels, chips, metadata). Mono stays for IDs/code.
  Fonts are self-hosted through fontsource: no request to fonts.googleapis.com (local-first).
- **Palette:** neutral off-white paper and ink text in light mode, and a warm near-black with off-white text in dark mode.
  **One** restrained accent (e.g. a deep arXiv-style red or an ink blue; the design picks one and justifies it) for
  links, focus and the primary action. No gradients or glow.
- **Trust status tokens:** quiet chips for *supported*, *unsupported* and *not checked*. They must differ in text and
  hue, not colour only, and *not checked* must look distinct from *unsupported* (FE-4 AC1).
- **Measure and density:** reading text ~65–75ch (`prose` from `@tailwindcss/typography`). Reference cards stay dense.
- **Stack:** React 19 + Vite + Tailwind 3 + shadcn-style Radix wrappers in `frontend/src/components/ui/`. No new UI
  framework. Phase-2 libraries (router, react-query, react-pdf, markdown/katex, cmdk, tables) stay out.

## Scope
- Files expected to change (ArxivLens `frontend/`):
  - `src/index.css`: CSS variables for `:root` (light) and `.dark` (dark). Keep the existing shadcn names (`--background`,
    `--foreground`, `--card`, `--popover`, `--primary`, `--secondary`, `--muted`, `--accent`, `--destructive`, `--border`,
    `--input`, `--ring`, each with `-foreground` where it exists today) and add status tokens `--supported`, `--unsupported`,
    `--unchecked` (+ `-foreground`). Base styles: body in Inter, `font-serif` utility available. Keep the scrollbar styles, re-tinted.
  - `tailwind.config.js`: `fontFamily.sans` = Inter Variable stack, `fontFamily.serif` = Source Serif 4 Variable stack,
    keep `mono`. Colours `supported`, `unsupported`, `unchecked` mapped to the new tokens. Register `@tailwindcss/typography`
    in `plugins` with a `prose` theme mapped to the tokens (light and `dark:prose-invert` or token-based). Keep `darkMode: ["class"]`.
    The `clinical` palette and the `title`/Outfit family stay defined (feature components still use them until FE-2/3/4), but
    the design may mark them deprecated.
  - `src/main.jsx`: font imports only (`@fontsource-variable/inter`, `@fontsource-variable/source-serif-4`, with the
    italic file for the serif if the design wants italics).
  - `index.html`: remove the Google Fonts `<link>`s. Add a small inline pre-paint script that sets the `dark` class
    from the stored choice (or the interim default, dark; `system` resolves via `prefers-color-scheme`), so there's no flash of the wrong theme.
  - New `src/components/ui/dropdown-menu.jsx`: a shadcn-style wrapper over `@radix-ui/react-dropdown-menu`, using `cn()` from
    `src/lib/utils.js` and the tokens, with the exports in design §6. Export components only (`.oxlintrc.json` has
    `react/only-export-components`). *Split 2026-11-19: the other six primitives (`tooltip`, `popover`, `collapsible`,
    `scroll-area`, `separator`, `sonner`) are in [FE-0b](FE-0b.md).*
  - `src/components/ui/button.jsx`: only the `default` variant moves to `bg-primary text-primary-foreground` (design §6).
  - App `README.md`: one sentence in "Run the UI" about the light/dark/system toggle (AC9).
  - New `src/lib/theme.js` (read/write the stored theme, resolve `system` from `prefers-color-scheme`, react to OS changes
    while in `system`) and new `src/components/ThemeToggle.jsx` (accessible button or dropdown: light / dark / system).
  - `src/components/Navbar.jsx`: mount `<ThemeToggle/>`. It may also swap Navbar's own hard-coded emerald/gradient classes
    for tokens, since no other ticket owns Navbar.
- Out of scope:
  - Feature components `SynthesisView.jsx`, `ReferencesStack.jsx`, `HeroSearch.jsx`, `App.jsx`, `Toast.jsx`: they adopt
    the theme in FE-3, FE-4 and FE-2. Mounting `<Toaster/>` and retiring `Toast.jsx` is not part of this ticket.
  - `PapersLibrary.jsx`, `IngestModal.jsx`, `InfrastructureModal.jsx`: follow-up (see Notes).
  - `package.json`, `package-lock.json`, `vite.config.js`, vitest config and tests: FE-1 owns those this cycle. **No dependency changes**
    (every package needed is already in the lockfile).
  - Existing `components/ui/{badge,button,card,dialog,progress,tabs}.jsx`: unchanged, except token-only class tweaks the design
    lists explicitly. New badge variants for trust states come in FE-3.
  - Any API change.

## Acceptance criteria
- [ ] AC1 — `npm run build` and `npm run lint` pass in CI on the draft PR (lint: no new warnings versus `origin/main`).
- [ ] AC2 — **Fonts self-hosted:** the Vite asset list in the CI build log shows Inter (`wght-normal`) and Source Serif 4
  (`wght-normal` and `wght-italic`) `woff2` files. `src/main.jsx` imports the three fontsource CSS files. Neither
  `index.html` nor `frontend/src/` references `fonts.googleapis.com` or `fonts.gstatic.com` (grep). If QA can build
  locally (`dist/` available), also: `@font-face` in `dist/assets/*.css` and no Google font host anywhere in `dist/`.
  *Amended 2026-11-19 (pm-lead, design Q3): CI doesn't print `dist/` contents; the CI grep step is backlog item OPS-H14.*
- [ ] AC3 — **Tokens:** `index.css` defines every token listed in Scope for both `:root` and `.dark`. `tailwind.config.js` exposes
  `font-serif`, `font-sans`, `supported`/`unsupported`/`unchecked` colours and the typography plugin (registered in `plugins`
  with the token-mapped `DEFAULT` theme from design §3, `maxWidth: '70ch'`). If `dist/` is available: the built CSS contains
  `.font-serif` (Navbar uses it). *Amended 2026-11-19 (pm-lead, design Q3): Tailwind only emits classes that are used, and
  nothing uses `prose` until FE-3, so the built-CSS `.prose` check moved to FE-3.*
- [ ] AC4 — **Contrast (WCAG 2.1 AA) in both themes**, computed by QA from the HSL token values (the design lists each ratio):
  ≥ 4.5:1 for `foreground` on `background`, `card-foreground` on `card`, `popover-foreground` on `popover`,
  `muted-foreground` on `background` **and** on `card` and `muted`, `primary-foreground` on `primary`, `secondary-foreground`
  on `secondary`, `accent-foreground` on `accent`, `destructive-foreground` on `destructive`, the accent used as link text on
  `background` **and** on `card`, and each status chip's text on its chip background. ≥ 3:1 (WCAG 1.4.11) for `ring` and for
  `input` (the outline of every form control) against `background` and `card`. `--border` is a decorative hairline with no
  minimum. Every control outline styled in this PR uses `border-input`, never `border-border`, and a comment next to
  `--input` in `src/index.css` states that rule. *Amended 2026-11-19 (pm-lead, design Q2).*
- [ ] AC5 — **Dark mode:** with no stored choice (or an invalid one, or storage that throws), the first load is **dark**
  (interim `DEFAULT_THEME = "dark"`, the same constant in `src/lib/theme.js` and the pre-paint script, each with a comment
  pointing at the other; FE-3 flips it to `"system"`). A stored `system` follows `prefers-color-scheme`. The toggle offers
  light / dark / system, persists the choice in `localStorage`, has an accessible name and is keyboard-operable. In `system` mode
  an OS theme change applies without reload. The pre-paint script in `index.html` sets the class before React mounts.
  Evidence: QA's run of the pre-paint matrix ({none, `light`, `dark`, `system`, invalid, storage throws} × {OS dark, OS light})
  and of the `theme.js` functions in bare Node. *Amended 2026-11-19 (pm-lead, design Q1): the first-load default was
  `prefers-color-scheme`. Until FE-3 the ask flow's hard-coded text is ~1.16:1 on light.*
- [ ] AC6 — **Primitive:** `ui/dropdown-menu.jsx` exists with the design §6 exports and wraps
  `@radix-ui/react-dropdown-menu` in shadcn style (forwardRef where Radix expects it, `cn()` class merging, token colours only:
  no `slate|emerald|teal|zinc|gray-` classes, `data-[highlighted]` visible focus, `font-sans` on content) and exports only
  components. ThemeToggle uses it. *Amended 2026-11-19 (split): the other six primitives are FE-0b AC2.*
- [ ] AC7 — **Scope guard:** `git diff origin/main --name-only` lists only files in Scope (none of FE-0b's six files). No change
  to `package.json`, `package-lock.json`, `vite.config.js` or the five out-of-scope feature components. Diff ≈ 400 changed lines.
- [ ] AC8 — **Visual evidence:** screenshots of the built page (`vite preview`) in light and dark mode, hero and Navbar
  with the toggle menu open and a visible keyboard focus ring, if the environment can produce them (needs `node_modules`). Otherwise the CI build output plus a token diff
  (old vs new values) and the computed contrast table stand in. Mark which one was used.
- [ ] AC9 — Docs: `docs/design/FE-0.md` approved before code. The app `README.md` mentions the light/dark toggle if it has a UI section.
  No PRD status change (UI-1/UI-2 are already ✅). The PR description shows the removed "Clinical Research AI" badge as a
  visible copy change (before/after) and lists the font `woff2` count and total size from the CI build log.

## Verification
```bash
# CI (source of truth): frontend job in .github/workflows/ci.yml on the draft PR
cd frontend && npm ci && npm run lint && npm run build

# After a CI or local build (dist/ available)
# CI build log (always): the Vite asset list shows inter-*-wght-normal-*.woff2 and source-serif-4-*-wght-{normal,italic}-*.woff2
grep -n '@fontsource-variable' src/main.jsx                                   # 3 imports
grep -rEn 'fonts\.(googleapis|gstatic)\.com' index.html src/ ; test $? -eq 1   # must find nothing
grep -En 'DEFAULT_THEME|arxivlens-theme' index.html src/lib/theme.js           # same key and default ("dark") in both
# Only if dist/ is available (QA local build)
grep -l '@font-face' dist/assets/*.css ; grep -c '\.font-serif' dist/assets/*.css
grep -rEn 'fonts\.(googleapis|gstatic)\.com' dist/ ; test $? -eq 1

# Scope guard (works in the sandbox)
git diff origin/main --name-only -- frontend/ README.md
git diff origin/main --shortstat
git diff origin/main --stat -- frontend/package.json frontend/package-lock.json frontend/vite.config.js   # must be empty

# Contrast: QA computes WCAG ratios from the HSL values in src/index.css (both :root and .dark), e.g. a short python script

# Screenshots if node_modules can be installed
npm run build && npx vite preview --port 4173 &   # then playwright: light + dark, emulate prefers-color-scheme
```

## Notes
- 2026-11-19 (pm-lead): created after Mahesh merged #64 (`085183e`) and #67 (`4c7d327`), which added the Radix primitives
  (tooltip, popover, collapsible, scroll-area, dropdown-menu, separator), sonner, fontsource Inter and Source Serif 4 and
  `@tailwindcss/typography`. The agent sandbox still can't reach registry.npmjs.org, so CI is the verification and screenshots
  depend on whether QA's environment can install `node_modules`.
- Runs in parallel with FE-1. The files don't overlap: FE-1 has `package.json` scripts, vitest config, `src/test/`, `*.test.jsx`,
  `ReferencesStack.jsx` (AC3 badge fix) and `frontend/README.md`. FE-0 has the files in Scope. If either needs the other's file, stop and tell pm-lead.
- Known interim state: until FE-3/FE-4/FE-2 land, feature components still carry hard-coded dark classes (`slate-*`,
  `emerald-*`, `clinical-*`), so light mode will look mixed on those screens. The design should say how bad that is. If it's
  unreadable (e.g. light text on a light background), the design may propose defaulting to dark until FE-3 lands, but
  the toggle and the `system` behaviour still ship.
- Follow-up, not yet groomed: move `PapersLibrary.jsx`, `IngestModal.jsx`, `InfrastructureModal.jsx` to the tokens, and replace
  `Toast.jsx` with sonner's `<Toaster/>` (mounted in `App.jsx`). pm-lead will spec it after FE-0's design is approved.
- Downstream: FE-3 puts `tooltip` on status chips, FE-4 uses `popover` for `[n]` previews and `collapsible` for the passage,
  FE-2 uses `dropdown-menu` for "Export". Their designs should use the tokens and primitives defined here.
- 2026-11-19 (pm-lead, **PM decision on the design**): **Approved with conditions** (full text in `docs/design/FE-0.md` "PM decision").
  (1) Interim default dark until FE-3, AC5 amended, and FE-3 gets the flip-to-`system` AC. (2) `--input` ≥ 3:1 for control outlines, while
  `--border` stays a decorative hairline. AC4 amended, plus the `border-input` rule. (3) `dist/` greps: the CI Vite asset list plus
  source checks now. The `.prose` built-CSS check moves to FE-3 (Tailwind doesn't emit unused classes), and the CI grep step is
  backlog item OPS-H14. AC2/AC3 amended. (4) Drop the "Clinical Research AI" badge (reversible; shown in the PR). (5) **Split:** this ticket =
  the design's "FE-0a" (branch `agent/frontend/FE-0`, ID and Jira label unchanged); the six other primitives are [FE-0b](FE-0b.md).
  AC6/AC7/Scope amended. Downstream: FE-2 needs only FE-0; FE-3 needs FE-0 + FE-0b (tooltip); FE-4 needs FE-0 + FE-0b (popover, collapsible).
- 2026-11-19 (pm-lead) **For Mahesh (reversible, not blocking):** (a) first visit is dark until FE-3 even for OS-light users;
  (b) the navbar loses the "Clinical Research AI" badge; (c) accent is ink blue, not arXiv red (red stays reserved for unsupported/destructive).
  Overrule any of them in a PR review and it goes back to the developer.
- Follow-ups recorded (not yet specced): commit the AC5 Node checks as `src/lib/theme.test.js` once FE-1 (#68) merges, and
  OPS-H14 (backend: `frontend` CI job greps `dist/` for `@font-face`, `.font-serif`, `.prose`, `woff2`, and no Google font hosts).
- 2026-11-19 (frontend-engineer, **build**): draft [#69](https://github.com/MaheshPulivarthi18/ArxivLens/pull/69), branch `agent/frontend/FE-0`,
  head `ca76bea` (attempt 1 `dcf93c5`: CI green but oxlint 1 warning, `ThemeToggle.jsx:23` "Calling setState synchronously within an effect",
  versus 0 on main `4c7d327`. Attempt 2 derives the resolved theme in render; OS state is set only by the media-query listener).
  Diff +382/−58 = 440 lines, 10 files: `README.md` 3, `frontend/index.html` 18, `Navbar.jsx` 62, `ThemeToggle.jsx` (new) 75,
  `ui/button.jsx` 2, `ui/dropdown-menu.jsx` (new) 71, `index.css` 90, `lib/theme.js` (new) 64, `main.jsx` 3, `tailwind.config.js` 51.
  Ownership check OK. No file shared with #68; no dependency, `package.json`, lockfile or `vite.config.js` change.
  CI on `ca76bea`: Frontend, Go, Python M0, DB and ownership all pass; lint `Found 0 warnings and 0 errors.`; `✓ built in 1.01s`.
  Fonts: 19 `woff2`, 583.69 kB total (Inter normal 7, Source Serif 4 normal 6 + italic 6); about 99 kB for Latin, 151 kB with italics.
  AC status (developer self-check; QA verifies): AC1 ✅ CI · AC2 ✅ CI asset list + source greps (the `dist/` greps need a local build, OPS-H14) ·
  AC3 ✅ Node check (25 colour tokens × 2 themes + radius, config strings) · AC4 ✅ contrast parsed from `index.css`, all pairs pass,
  and the only outlined control uses `border-input` (`border-border` only on the header hairline, logo tile and menu panel) ·
  AC5 ✅ pre-paint matrix 12/12 + `theme.js` 31 checks in bare Node · AC6 ✅ static check · AC7 ✅ (440 lines, over the 400 warning) ·
  AC8 fallback (no `node_modules`: Tailwind 4 / no Vite locally) = CI log + token diff + contrast table in the PR body · AC9 ✅ README line,
  badge before/after, font count and size, and the veto note for Mahesh's three choices in the PR body.
  Self-check scripts (uncommitted, for QA to rerun or rebuild): `/tmp/fe0/theme-checks.mjs` and `/tmp/fe0/token-checks.mjs` (sandbox-local).
  Follow-up unchanged: commit them as `src/lib/theme.test.js` after #68 merges.
