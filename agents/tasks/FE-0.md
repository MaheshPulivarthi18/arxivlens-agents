# FE-0: Classic research theme: fonts, tokens, dark mode, ui primitives

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P1 (foundation for FE-3, FE-4, FE-2) |
| **PRD ref** | Product PRD UI-1, UI-2; §7 principles 1 "Evidence first" and 3 "One click to the source" |
| **Depends on** | none. ArxivLens #64 (`085183e`) and #67 (`4c7d327`), which added the Radix, sonner, fontsource and typography packages, are merged. Independent of FE-1 (disjoint files, see Scope) |
| **Jira** | story under epic KAN-5 "Research UI & citations" (`labels = "task-FE-0"`) |
| **Design required** | **yes**: `docs/design/FE-0.md` (palette with HSL values and contrast ratios, type scale, primitives API, theme toggle behaviour). pm-lead approves before any code |
| **Status** | Ready (design stage: write `docs/design/FE-0.md` first) |

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
    from the stored choice or `prefers-color-scheme`, so there's no flash of the wrong theme.
  - New `src/components/ui/{tooltip,popover,collapsible,scroll-area,separator,dropdown-menu,sonner}.jsx`: shadcn-style
    wrappers over `@radix-ui/react-*` and `sonner`, using `cn()` from `src/lib/utils.js` and the tokens. Export
    components only (`.oxlintrc.json` has `react/only-export-components`). `sonner.jsx` exports a themed `<Toaster/>`. Callers
    import `toast` from `sonner` directly.
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
- [ ] AC2 — **Fonts self-hosted:** the built `dist/assets/` contains Inter and Source Serif 4 `woff2` files and `@font-face`
  rules for both. Neither `index.html` nor `dist/` references `fonts.googleapis.com` or `fonts.gstatic.com` (grep).
- [ ] AC3 — **Tokens:** `index.css` defines every token listed in Scope for both `:root` and `.dark`. `tailwind.config.js` exposes
  `font-serif`, `font-sans`, `supported`/`unsupported`/`unchecked` colours and the typography plugin. The built CSS contains
  `.prose` and `.font-serif` rules (grep).
- [ ] AC4 — **Contrast (WCAG 2.1 AA) in both themes**, computed by QA from the HSL token values (the design lists each ratio):
  ≥ 4.5:1 for `foreground` on `background`, `card-foreground` on `card`, `popover-foreground` on `popover`,
  `muted-foreground` on `background` **and** on `card` and `muted`, `primary-foreground` on `primary`, `secondary-foreground`
  on `secondary`, `accent-foreground` on `accent`, `destructive-foreground` on `destructive`, the accent used as link text on
  `background`, and each status chip's text on its chip background. ≥ 3:1 for `ring` and `border` used as the input outline
  against `background` (WCAG 1.4.11).
- [ ] AC5 — **Dark mode:** first load follows `prefers-color-scheme` when no choice is stored. The toggle offers
  light / dark / system, persists the choice in `localStorage`, has an accessible name and is keyboard-operable. In `system` mode
  an OS theme change applies without reload. The pre-paint script in `index.html` sets the class before React mounts.
- [ ] AC6 — **Primitives:** the seven new `ui/*.jsx` files exist, wrap the matching Radix/sonner package in shadcn style
  (forwardRef where Radix expects it, `cn()` class merging, token colours, visible `focus-visible` ring) and export only components.
  Nothing imports them yet except Navbar/ThemeToggle, so the build must still tree-shake cleanly.
- [ ] AC7 — **Scope guard:** `git diff origin/main --name-only` lists only files in Scope. No change to `package.json`,
  `package-lock.json`, `vite.config.js` or the five out-of-scope feature components.
- [ ] AC8 — **Visual evidence:** screenshots of the built page (`vite preview`) in light and dark mode, hero and Navbar
  with the toggle, if the environment can produce them (needs `node_modules`). Otherwise the CI build output plus a token diff
  (old vs new values) and the computed contrast table stand in. Mark which one was used.
- [ ] AC9 — Docs: `docs/design/FE-0.md` approved before code. The app `README.md` mentions the light/dark toggle if it has a UI section.
  No PRD status change (UI-1/UI-2 are already ✅).

## Verification
```bash
# CI (source of truth): frontend job in .github/workflows/ci.yml on the draft PR
cd frontend && npm ci && npm run lint && npm run build

# After a CI or local build (dist/ available)
ls dist/assets | grep -Ei 'inter|source-serif' | grep woff2
grep -l '@font-face' dist/assets/*.css
grep -rEn 'fonts\.(googleapis|gstatic)\.com' index.html dist/ ; test $? -eq 1   # must find nothing
grep -c '\.prose' dist/assets/*.css ; grep -c '\.font-serif' dist/assets/*.css

# Scope guard (works in the sandbox)
git diff origin/main --name-only -- frontend/
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
