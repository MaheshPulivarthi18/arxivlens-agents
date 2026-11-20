# Tech design — FE-0: Classic research theme: fonts, tokens, dark mode, ui primitives

**Author:** frontend-engineer · **Ticket:** `agents/tasks/FE-0.md` · **PRD:** Product PRD UI-1, UI-2; §7 principles 1 "Evidence first" and 3 "One click to the source" · **Status:** Approved with conditions (pm-lead, 2026-11-19; see PM decision)

All code references are to the app repo at `origin/main` `4c7d327` (`frontend/`).

## Problem
The UI is a dark "clinical AI" dashboard: Google-hosted Inter/Outfit/JetBrains Mono, emerald gradients, one dark-only
token set in `src/index.css`. Mahesh wants it to read like a research tool: serif for what researchers read, a quiet
sans for chrome, a neutral paper/ink palette with one accent, light and dark mode, and calm trust-status colours that
FE-3/FE-4 can build on. FE-0 lays the foundation only (tokens, self-hosted fonts, theme switch, seven Radix/sonner
wrappers) and moves Navbar onto it. Feature components adopt it in FE-3, FE-4 and FE-2. Covers AC1–AC9.

## Findings that shape the design
1. **Fonts.** The lockfile pins `@fontsource-variable/inter@5.3.0` and `@fontsource-variable/source-serif-4@5.3.1`. I read
   those exact versions in `fontsource/font-files` (sparse clone): the families are `'Inter Variable'` and
   `'Source Serif 4 Variable'`; each package's `index.css` is the `wght` axis, normal style, split into unicode-range
   subsets (7 for Inter, 6 for the serif); `wght-italic.css` is the matching italic file. Vite emits every subset
   `woff2`, and the browser downloads only the subsets a page uses.
2. **Fonts we lose.** `index.html` also loads **Outfit** (`font-title`, used for headings) and **JetBrains Mono**
   (`font-mono`, 26 usages with `font-title`) from Google. No fontsource package exists for them in the lockfile and FE-0
   may not add dependencies, so after the `<link>` goes, `font-title` falls back to Inter and `font-mono` to the
   system monospace stack. Both fallbacks are acceptable (Inter for headings is the direction anyway; IDs stay monospaced).
3. **Nobody uses `Button variant="default"`** (every caller passes `clinical`, `outline`, `secondary` or `ghost`),
   so retargeting `default` to the primary tokens changes no existing screen. Navbar's "Index Paper" will use it.
4. **`App.css` is not imported anywhere.** It stays untouched.
5. **`tailwindcss-animate` is not installed**, so the `animate-in`/`fade-in-0` classes in `dialog.jsx` are dead. The new
   primitives won't add them (no motion by default fits "calm", and there's no dependency change).
6. **Alpha modifiers** (`bg-background/90`, `border-border/80`) already work with `hsl(var(--x))` in Tailwind ≥ 3.3, so
   the colour config keeps that form.
7. **Interim light mode is unreadable on the ask flow** (see "Interim state" below): the answer prose is 1.16:1.

## Approach

### 1. Palette and accent
**Accent: ink blue** (`216 60% 32%` light, `214 72% 72%` dark), not arXiv red. Red is the colour this product needs
for *unsupported* citations and destructive actions; if links, focus rings and the primary button were red too, a
reader could not tell "click here" from "this claim failed verification", which is exactly the confusion principle 1
("evidence first") must avoid. Ink blue is the journal/hyperlink convention, so `[n]` markers and "Open PDF" read as
links at a glance (principle 3, "one click to the source").

Token roles (shadcn names kept):
- `--primary` = **the** accent: links (`text-primary`), primary button, focus `--ring`. Link text is `text-primary`
  (no extra `--link` token).
- `--accent` keeps its shadcn meaning, a *subtle hover/highlight surface* (menu item highlight), tinted from the accent hue.
- `--border` is a decorative hairline (card edges, dividers). `--input` is the outline of form controls and meets 3:1.
- New status tokens: `--supported`, `--unsupported`, `--unchecked` are **chip backgrounds** (quiet tints) and
  `-foreground` is the chip text. Hues: supported = green (145°), unsupported = brick red (2–4°), not checked = ochre
  (30–40°). *Not checked* differs from *unsupported* in hue (ochre vs red, ~35° apart and different lightness) and FE-3
  adds distinct text ("Not checked" vs "Unsupported") and icon, so colour is never the only signal (FE-4 AC1).
- `--radius` drops from `0.65rem` to `0.375rem` (squarer, more "paper"; cards and inputs only).
- No gradients or glows anywhere in the new code; Navbar loses its gradient tile and coloured shadows.

Values (HSL as written in `src/index.css`; hex for reference):

| Token | Light (`:root`) | hex | Dark (`.dark`) | hex |
|---|---|---|---|---|
| `--background` | `40 23% 97%` | `#f9f8f6` | `30 7% 8%` | `#161413` |
| `--foreground` | `222 22% 13%` | `#1a1e28` | `40 20% 90%` | `#ebe7e0` |
| `--card` | `0 0% 100%` | `#ffffff` | `30 6% 11%` | `#1e1c1a` |
| `--card-foreground` | `222 22% 13%` | `#1a1e28` | `40 20% 90%` | `#ebe7e0` |
| `--popover` | `0 0% 100%` | `#ffffff` | `30 6% 12%` | `#201f1d` |
| `--popover-foreground` | `222 22% 13%` | `#1a1e28` | `40 20% 90%` | `#ebe7e0` |
| `--primary` | `216 60% 32%` | `#214883` | `214 72% 72%` | `#84b1eb` |
| `--primary-foreground` | `40 23% 98%` | `#fbfaf9` | `220 35% 10%` | `#111722` |
| `--secondary` | `40 14% 91%` | `#ebe9e5` | `30 5% 18%` | `#302e2c` |
| `--secondary-foreground` | `222 22% 13%` | `#1a1e28` | `40 20% 90%` | `#ebe7e0` |
| `--muted` | `40 14% 93%` | `#f0eeeb` | `30 5% 16%` | `#2b2927` |
| `--muted-foreground` | `220 9% 37%` | `#565c67` | `35 8% 64%` | `#aba49c` |
| `--accent` | `214 45% 93%` | `#e5ecf5` | `214 22% 20%` | `#28323e` |
| `--accent-foreground` | `216 60% 26%` | `#1b3a6a` | `214 70% 86%` | `#c2d8f4` |
| `--destructive` | `2 64% 40%` | `#a72925` | `2 62% 44%` | `#b62f2b` |
| `--destructive-foreground` | `40 23% 98%` | `#fbfaf9` | `40 23% 98%` | `#fbfaf9` |
| `--border` | `40 10% 85%` | `#dddad5` | `30 5% 20%` | `#363330` |
| `--input` | `220 8% 55%` | `#838995` | `30 5% 42%` | `#706b66` |
| `--ring` | `216 60% 32%` | `#214883` | `214 72% 72%` | `#84b1eb` |
| `--supported` | `140 32% 91%` | `#e1efe6` | `145 28% 15%` | `#1c3124` |
| `--supported-foreground` | `145 55% 22%` | `#195733` | `140 45% 72%` | `#97d8ad` |
| `--unsupported` | `4 70% 94%` | `#fae6e5` | `4 38% 17%` | `#3c1d1b` |
| `--unsupported-foreground` | `2 64% 33%` | `#8a221e` | `4 80% 80%` | `#f5a9a3` |
| `--unchecked` | `38 55% 90%` | `#f4e9d7` | `38 35% 15%` | `#342a19` |
| `--unchecked-foreground` | `30 70% 24%` | `#683d12` | `40 70% 72%` | `#eac886` |
| `--radius` | `0.375rem` | | (same) | |

### 2. Contrast (WCAG 2.1, computed, not estimated)
Computed with the script in the appendix (exact HSL → sRGB, WCAG relative luminance). Every AC4 pair passes in both themes.

| Pair (text on surface) | Min | Light | Dark | Result |
|---|---|---|---|---|
| `foreground` on `background` | ≥ 4.5:1 | 15.66:1 | 14.88:1 | PASS |
| `card-foreground` on `card` | ≥ 4.5:1 | 16.63:1 | 13.79:1 | PASS |
| `popover-foreground` on `popover` | ≥ 4.5:1 | 16.63:1 | 13.40:1 | PASS |
| `muted-foreground` on `background` | ≥ 4.5:1 | 6.37:1 | 7.45:1 | PASS |
| `muted-foreground` on `card` | ≥ 4.5:1 | 6.77:1 | 6.91:1 | PASS |
| `muted-foreground` on `muted` | ≥ 4.5:1 | 5.84:1 | 5.91:1 | PASS |
| `primary-foreground` on `primary` | ≥ 4.5:1 | 8.73:1 | 8.11:1 | PASS |
| `secondary-foreground` on `secondary` | ≥ 4.5:1 | 13.73:1 | 10.99:1 | PASS |
| `accent-foreground` on `accent` | ≥ 4.5:1 | 9.47:1 | 8.98:1 | PASS |
| `destructive-foreground` on `destructive` | ≥ 4.5:1 | 6.74:1 | 5.89:1 | PASS |
| `primary` (link text) on `background` | ≥ 4.5:1 | 8.56:1 | 8.25:1 | PASS |
| `primary` (link text) on `card` | ≥ 4.5:1 | 9.09:1 | 7.65:1 | PASS |
| `supported-foreground` on `supported` | ≥ 4.5:1 | 7.23:1 | 8.41:1 | PASS |
| `unsupported-foreground` on `unsupported` | ≥ 4.5:1 | 7.55:1 | 7.99:1 | PASS |
| `unchecked-foreground` on `unchecked` | ≥ 4.5:1 | 7.71:1 | 8.82:1 | PASS |
| `ring` on `background` (1.4.11) | ≥ 3:1 | 8.56:1 | 8.25:1 | PASS |
| `ring` on `card` (1.4.11) | ≥ 3:1 | 9.09:1 | 7.65:1 | PASS |
| `input` (control outline) on `background` (1.4.11) | ≥ 3:1 | 3.30:1 | 3.48:1 | PASS |
| `input` (control outline) on `card` (1.4.11) | ≥ 3:1 | 3.50:1 | 3.23:1 | PASS |
| `border` (decorative hairline) on `background` | n/a | 1.31:1 | 1.46:1 | decorative |

Extra, for FE-3/FE-4 (status text used without its tint, e.g. an outlined chip):

| Pair | Light | Dark |
|---|---|---|
| `supported-foreground` on `background` / `card` | 8.07 / 8.57 | 11.10 / 10.29 |
| `unsupported-foreground` on `background` / `card` | 8.50 / 9.02 | 9.65 / 8.94 |
| `unchecked-foreground` on `background` / `card` | 8.71 / 9.25 | 11.44 / 10.61 |

**How I read AC4's last clause.** "`ring` and `border` used as the input outline" is satisfied by the token form
controls actually use: `--input` (shadcn convention `border-input`) at ≥ 3:1. `--border` is the decorative hairline on
cards and dividers, which 1.4.11 doesn't cover; at 3:1 it would draw heavy grey boxes everywhere, the opposite of a
journal page. Rule for FE-3/FE-4/FE-2: **any form control or control-identifying outline uses `border-input`, never
`border-border`.** If pm-lead reads AC4 as requiring `--border` ≥ 3:1 too, the fix is one value per theme (open question 2).

### 3. Type scale
Families (`tailwind.config.js` `fontFamily`):
- `sans`: `"Inter Variable", Inter, ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif` (chrome; body default).
- `serif`: `"Source Serif 4 Variable", "Source Serif Pro", ui-serif, Georgia, Cambria, "Times New Roman", serif` (reading areas).
- `mono`: `"JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, Consolas, "Liberation Mono", monospace` (IDs, code; JetBrains used only if installed locally).
- `title` (**deprecated**, kept for existing callers until FE-2/3/4): `Outfit, "Inter Variable", sans-serif`; Outfit is no longer loaded, so it renders as Inter.

Scale (Tailwind's default sizes; no custom `fontSize`, this is the usage contract for FE-3/FE-4/FE-2):

| Role | Family | Class | Size / line-height |
|---|---|---|---|
| Page / view title (e.g. the question) | serif | `font-serif text-2xl sm:text-3xl font-semibold tracking-tight` | 24→30 px / 1.25 |
| Section heading in reading area | serif | `font-serif text-xl font-semibold` | 20 px / 1.4 |
| Answer prose, abstracts, passages | serif | `prose font-serif` (16 px / 1.75), `sm:prose-lg` (18 px / 1.78) | measure 70ch |
| Paper title in a reference card | serif | `font-serif text-base font-semibold leading-snug` | 16 px / 1.375 |
| Chrome: nav, buttons, labels | sans | `text-sm font-medium` | 14 px |
| Metadata, chips, authors, section names | sans | `text-xs` (chips `font-medium`) | 12 px |
| arXiv IDs, BibTeX | mono | `font-mono text-xs` | 12 px |

`index.css` base: `body { @apply font-sans bg-background text-foreground }` keeping the existing
`font-feature-settings`/smoothing. Reading areas opt in with `font-serif`; nothing becomes serif implicitly.

**Typography plugin** (`@tailwindcss/typography`, already a devDependency): registered in `plugins`, with a token-based
`DEFAULT` theme so `.prose` follows `.dark` automatically (no `dark:prose-invert` needed, one code path):
`--tw-prose-body/headings/bold/quotes/code` → `hsl(var(--foreground))`, `--tw-prose-links` → `hsl(var(--primary))`,
`--tw-prose-counters/captions/lead` → `hsl(var(--muted-foreground))`, `--tw-prose-bullets/hr/quote-borders/th-borders/td-borders`
→ `hsl(var(--border))`, `--tw-prose-pre-bg` → `hsl(var(--muted))`, `--tw-prose-pre-code` → `hsl(var(--foreground))`,
and `maxWidth: '70ch'`. Links in prose: underline with `text-underline-offset: 2px`.

### 4. Colours in `tailwind.config.js`
Existing token colours unchanged. Added:
`supported: { DEFAULT: "hsl(var(--supported))", foreground: "hsl(var(--supported-foreground))" }`, same for `unsupported`, `unchecked`.
`clinical` stays, with a `// deprecated: FE-2/3/4 move callers to tokens` comment. `darkMode: ["class"]` stays.
`import typography from "@tailwindcss/typography"` → `plugins: [typography]`.

### 5. Theme preference, toggle and pre-paint script
**Storage:** `localStorage["arxivlens-theme"]` ∈ `"light" | "dark" | "system"`. Anything else (missing, garbage,
storage throws in private mode) → the default preference (see open question 1: `"system"` per AC5, or `"dark"` for the interim).

**Pre-paint script** (`index.html`, inline classic `<script>` in `<head>` *before* the stylesheet and the module script,
plus `<meta name="color-scheme" content="light dark">`). Vite leaves inline non-module scripts as they are. ~12 lines:
```html
<script>
  (function () {
    var pref = 'system';
    try { pref = localStorage.getItem('arxivlens-theme') || pref; } catch (e) {}
    if (pref !== 'light' && pref !== 'dark' && pref !== 'system') pref = 'system';
    var dark = pref === 'dark' ||
      (pref === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);
    document.documentElement.classList.toggle('dark', dark);
    document.documentElement.style.colorScheme = dark ? 'dark' : 'light';
  })();
</script>
```
It runs synchronously before first paint and before React, so there is no flash. `colorScheme` makes native
scrollbars, form controls and autofill match. The key and the default are duplicated in `src/lib/theme.js`; a comment
in both points at the other.

**`src/lib/theme.js`** (plain ESM, no imports, so it runs in bare Node for tests without `node_modules`):
| Export | Behaviour |
|---|---|
| `THEME_STORAGE_KEY`, `THEMES`, `DEFAULT_THEME` | constants (`["light","dark","system"]`) |
| `getStoredTheme()` | returns a valid preference or `DEFAULT_THEME`; never throws |
| `setStoredTheme(pref)` | writes `localStorage`; swallows storage errors (choice then lasts for the session only) |
| `resolveTheme(pref, prefersDark)` | `"light"`/`"dark"`; pure |
| `systemPrefersDark()` | `matchMedia('(prefers-color-scheme: dark)').matches`, `false` if `matchMedia` is missing |
| `applyTheme(pref)` | toggles `.dark` and `style.colorScheme` on `<html>`, returns the resolved theme |
| `watchSystemTheme(onChange)` | `matchMedia(...).addEventListener('change', …)`; returns an unsubscribe |

**`src/components/ThemeToggle.jsx`** (default export, the only export):
- State `pref` initialised from `getStoredTheme()` (the class is already right thanks to the pre-paint script).
- Effect on `pref`: `applyTheme(pref)`; when `pref === "system"`, subscribe with `watchSystemTheme(() => applyTheme("system"))`
  and unsubscribe on change/unmount. That is AC5's "OS change applies without reload".
- Effect: `window` `storage` event for `THEME_STORAGE_KEY` → `setPref` (other tabs follow; 5 lines).
- UI: a `DropdownMenu` (the new primitive). Trigger = `Button variant="ghost" size="icon"` showing Sun / Moon / Monitor
  (lucide) for the current preference, `aria-label="Theme: System (dark)"`-style name that says both preference and
  resolved theme. Content = `DropdownMenuRadioGroup` with three `DropdownMenuRadioItem`s labelled "Light", "Dark",
  "System", each with its icon (`aria-hidden`). Radix gives `role="menuitemradio"`, `aria-checked`, arrow-key roving
  focus, Enter/Space select, Esc closes and returns focus to the trigger. Selecting calls `setStoredTheme` + `setPref`.

### 6. Primitives API (`src/components/ui/*.jsx`)
All follow the existing `dialog.jsx` pattern: `import * as XPrimitive from "@radix-ui/react-x"`, `React.forwardRef`
for every element that renders DOM, `displayName` copied from the primitive, classes merged with `cn()`, colours only
from tokens, `font-sans` on floating content so it doesn't inherit `font-serif` from a reading area. Each file exports
only components (`react/only-export-components`). No motion classes (finding 5). Keyboard focus:
`focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background` (short: **FV ring**) on anything focusable we style.

| File | Exports | Notes |
|---|---|---|
| `tooltip.jsx` | `TooltipProvider`, `Tooltip`, `TooltipTrigger`, `TooltipContent` | Content forwardRef, `sideOffset=4`, in `TooltipPrimitive.Portal`; `z-50 rounded-md border border-border bg-popover text-popover-foreground px-2.5 py-1.5 text-xs shadow-sm max-w-xs`. `Tooltip` wraps Root in its own `Provider` (`delayDuration=300`) so callers don't need a top-level provider. Tooltips are supplementary only (never the sole carrier of a status: FE-3 chips have visible text). |
| `popover.jsx` | `Popover`, `PopoverTrigger`, `PopoverAnchor`, `PopoverContent` | Content forwardRef, `align="center"`, `sideOffset=4`, portal; `z-50 w-80 rounded-md border border-border bg-popover text-popover-foreground p-4 shadow-md outline-none`. For FE-4's `[n]` previews. |
| `collapsible.jsx` | `Collapsible`, `CollapsibleTrigger`, `CollapsibleContent` | Thin aliases of Root/Trigger/CollapsibleContent (no styling: callers style the trigger as a Button). For FE-4's passage. |
| `scroll-area.jsx` | `ScrollArea`, `ScrollBar` | Root `relative overflow-hidden`; Viewport `h-full w-full rounded-[inherit]` + FV ring (viewport is focusable for keyboard scrolling); `ScrollBar` forwardRef with `orientation` (`vertical` default), thumb `bg-border hover:bg-muted-foreground/50 rounded-full`; Corner. |
| `separator.jsx` | `Separator` | forwardRef; `orientation="horizontal"`, `decorative=true` defaults; `shrink-0 bg-border`, `h-px w-full` / `h-full w-px`. |
| `dropdown-menu.jsx` | `DropdownMenu`, `DropdownMenuTrigger`, `DropdownMenuContent`, `DropdownMenuGroup`, `DropdownMenuLabel`, `DropdownMenuItem`, `DropdownMenuRadioGroup`, `DropdownMenuRadioItem`, `DropdownMenuSeparator` | Content forwardRef, `sideOffset=4`, portal, `z-50 min-w-[8rem] rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md`. Items: `relative flex cursor-default select-none items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-none data-[highlighted]:bg-accent data-[highlighted]:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50` (Radix moves real focus to the highlighted item, so `data-[highlighted]` is the visible focus). RadioItem shows a `Check` (`aria-hidden`) in an `ItemIndicator`. Sub-menus, checkbox items and shortcuts are left out (no caller; FE-2 needs Item only). |
| `sonner.jsx` | `Toaster` | Wraps sonner's `Toaster` with `className="toaster"`, `position="bottom-right"`, and `style` setting sonner's CSS variables to tokens: `--normal-bg: hsl(var(--popover))`, `--normal-text: hsl(var(--popover-foreground))`, `--normal-border: hsl(var(--border))`, `--border-radius: var(--radius)`. Because the tokens flip with `.dark`, toasts follow the theme with no `theme` prop or theme store. Callers `import { toast } from "sonner"`. Not mounted in FE-0. |

**Amendments from FE-0b (2026-11-20, pm-lead, QA r3 N4; built in PR #70, see `agents/tasks/FE-0b.md` Notes):** the code differs from the table in two rows. Copy the code, not the table:
- `scroll-area.jsx`: the Viewport ring is **inset** (`focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-ring`, no `ring-offset`). The Root's `overflow-hidden` clips the outset FV ring completely (WCAG 2.4.7). Callers that put plain text (no focusable children) in a ScrollArea pass `tabIndex={0}` and an `aria-label` on it: Radix sets no `tabindex`, and Safari doesn't make scroll containers focusable (FE-4).
- `sonner.jsx`: the four variables alone are not enough. Sonner hard-codes `[data-description] { color: #3f3f3f }` unless its own theme is dark (1.56:1 on the dark toast), so `Toaster` also passes `toastOptions.classNames.description = "!text-muted-foreground"`, merged with caller `toastOptions`/`classNames`. Still no `theme` prop. A caller's description colour needs `!` to win.

Existing `ui/` files: **one** token-only tweak, listed explicitly: `button.jsx` `default` variant
`bg-emerald-600 text-white shadow hover:bg-emerald-500` → `bg-primary text-primary-foreground shadow-sm hover:bg-primary/90`
(no current caller, finding 3). `badge.jsx`, `card.jsx`, `dialog.jsx`, `progress.jsx`, `tabs.jsx` unchanged; `clinical`
variants stay (deprecated comment).

### 7. Navbar (`src/components/Navbar.jsx`)
- Brand: the clickable `div` becomes a `<button type="button">` (it isn't keyboard-reachable today) with FV ring.
  Gradient tile + coloured shadow → `rounded-md border border-border bg-card text-primary` with the Microscope icon
  (`aria-hidden`). Name `font-serif text-xl font-semibold`. Tagline `text-xs text-muted-foreground` in sans (not mono).
- The "Clinical Research AI" badge is removed (contradicts the new direction; open question 4).
- Active tab: `text-emerald-400` → `text-foreground` on `bg-secondary`, plus `aria-current="page"`; inactive stays `text-muted-foreground`.
- "Index Paper": `variant="clinical"` + emerald shadow → `variant="default"` (ink primary).
- The `div` divider stays as is (Separator ships in FE-0b if split, see Size).
- `<ThemeToggle/>` after the Infrastructure button.
- Header `bg-background/90 backdrop-blur-md` stays (subtle, token-based).

### 8. Other files
- `src/main.jsx`: `import "@fontsource-variable/inter"`, `import "@fontsource-variable/source-serif-4"`,
  `import "@fontsource-variable/source-serif-4/wght-italic.css"` (italics are used in academic prose: emphasis, species,
  journal titles; without the file browsers synthesise a slanted roman). Imported before `./index.css`.
- `index.html`: remove the three Google Fonts tags; add `color-scheme` meta and the pre-paint script.
- `src/index.css`: `:root` light + `.dark` dark token blocks (table above); base `body` font; scrollbar thumb stays
  `hsl(var(--border))`, hover → `hsl(var(--input))` (re-tinted through the tokens, both themes).
- App `README.md` "### 4. Run the UI": one sentence on the light/dark/system toggle and that the choice is stored in the browser.

### Interim state (until FE-3/FE-4/FE-2 land)
Dark mode: fine. Feature components keep their emerald/slate/amber classes on the new warm near-black; they look
slightly off-brand but readable (they were tuned for dark).

Light mode is **not readable on the screens that matter** (computed against the new light `background`/`card`):

| Hard-coded class | Where | on `background` | on `card` |
|---|---|---|---|
| `text-slate-200` | SynthesisView answer prose | 1.16:1 | 1.23:1 |
| `text-amber-200` | App refusal banner body | 1.17:1 | 1.25:1 |
| `text-amber-300` | App refusal banner heading | 1.36:1 | 1.44:1 |
| `text-slate-300` | ReferencesStack passage | 1.40:1 | 1.48:1 |
| `text-emerald-300` | SynthesisView `[n]` marker | 1.44:1 | 1.52:1 |
| `text-emerald-400` | links/actions in Hero, References, Library, modals | 1.81:1 | 1.92:1 |

The answer, the refusal and the evidence passage would be near-invisible: that breaks principles 1 and 2 for any
first-time visitor whose OS is in light mode. **Recommendation:** ship the toggle and `system` exactly as specified, but
make `DEFAULT_THEME = "dark"` (both in `theme.js` and the pre-paint script) until FE-3 lands; FE-3 flips it to
`"system"` as an AC once SynthesisView/ReferencesStack/App's refusal use tokens. A user who picks Light or System gets it.
This contradicts AC5's "first load follows prefers-color-scheme", so it needs pm-lead's call (open question 1). The code
is the same either way except one constant in two places.

## Size and split plan
Estimated changed lines (additions + deletions, `git diff --stat`):

| File | Lines |
|---|---|
| `src/index.css` | ~80 |
| `tailwind.config.js` | ~50 |
| `index.html` | ~20 |
| `src/main.jsx` | 3 |
| `src/lib/theme.js` (new) | ~55 |
| `src/components/ThemeToggle.jsx` (new) | ~60 |
| `src/components/Navbar.jsx` | ~35 |
| `src/components/ui/button.jsx` | 2 |
| `README.md` | 2 |
| `ui/dropdown-menu.jsx` (new) | ~95 |
| **Subtotal FE-0a** | **~400** |
| `ui/tooltip.jsx` ~30, `ui/popover.jsx` ~35, `ui/collapsible.jsx` ~10, `ui/scroll-area.jsx` ~45, `ui/separator.jsx` ~25, `ui/sonner.jsx` ~25 | ~170 |
| **Total** | **~570** |

That is over the < 400 target, so I propose **two PRs**:
- **FE-0a** "theme foundation": everything except six primitives. `dropdown-menu` stays here because ThemeToggle uses it.
  ACs: AC1–AC5, AC6 for `dropdown-menu` only, AC7–AC9. Branch `agent/frontend/FE-0a`. Unblocks FE-2 (dropdown) and
  the FE-3 *design* (tokens, type scale).
- **FE-0b** "remaining ui primitives": the six new files, nothing else (new files only, so no overlap with FE-0a or FE-1).
  ACs: AC1, AC6, AC7. Unblocks FE-3 (tooltip) and FE-4 (popover, collapsible). Navbar's divider moves to `Separator` here only
  if it's cheap; otherwise it stays a div.
- Order: FE-0a now. FE-0b when a WIP slot frees (FE-1 + FE-0a = 2 active PRs), or in parallel if pm-lead allows a third.
- Alternative: one PR of ~570 lines, of which ~265 are boilerplate wrappers. Reviewable, but it breaks the rule; pm-lead's call.

## Alternatives considered
1. **arXiv red accent** — the brand nod is nice, but red already means *unsupported* and *destructive*; links in the same
   hue would blur the trust signal (principle 1). Red stays reserved for failure states.
2. **Toggle as a 3-state cycling icon button** — fewer lines and no dropdown, but the next state is invisible until you
   press it, and "system" is undiscoverable. A menu with three labelled radio items states the options and the current one.
3. **`dark:prose-invert`** for prose — needs a second colour set kept in sync by hand. Token-mapped prose variables flip with `.dark` for free.
4. **A React theme context/provider** (next-themes style) — only ThemeToggle reads the preference today, and the toaster
   follows the theme through CSS variables, so a context would be unused plumbing. `theme.js` can grow a
   `useSyncExternalStore` hook if a second reader appears.
5. **Keep Google Fonts for Outfit/JetBrains Mono** — violates "local-first, no request to fonts.googleapis.com" (AC2);
   adding fontsource packages for them needs a dependency change FE-0 can't make. System fallbacks are fine.
6. **Fix the six unreadable lines in feature components now** — they're in `App.jsx`, `SynthesisView.jsx`,
   `ReferencesStack.jsx` (FE-1 owns the latter this cycle; FE-3 owns all three). Out of scope; the interim default handles it.

## Contracts and invariants
- Shared contracts touched: **none** (no API, events, schema or model). No new fields read from `AskResponse`/`Citation`.
- Product invariants: "one click to the source" and "refusal is a state" are untouched (no feature component changes).
- No dependency change: `package.json`, `package-lock.json`, `vite.config.js`, vitest config and tests are FE-1's this cycle.
- `react/only-export-components`: `theme.js` is a `.js` module (constants and functions, no JSX); every `.jsx` exports components only.
- No network requests for fonts (local-first).

## Test plan
FE-1 owns vitest config and tests this cycle, so FE-0a commits **no test files**. The checks below run in CI, in the
sandbox (Node 22 is available without `node_modules`), or by QA.

| AC | Test | Runs in CI? |
|---|---|---|
| AC1 build + lint | CI `frontend` job: `npm ci && npm run lint && npm run build`; lint warning count compared with the `origin/main` run's log | yes |
| AC2 fonts self-hosted | CI build log lists the emitted `inter-*-wght-normal-*.woff2` and `source-serif-4-*-wght-{normal,italic}-*.woff2` assets (Vite prints every asset). `grep -En 'fonts\.(googleapis\|gstatic)\.com' index.html` empty (sandbox). `@font-face` in `dist/*.css`: see open question 3 | partly |
| AC3 tokens | Script (sandbox/QA): parse `index.css`, assert all 26 tokens (25 colours + `--radius`) present in both `:root` and `.dark`; grep `tailwind.config.js` for `serif`, `sans`, `supported`, `unsupported`, `unchecked`, `typography`. `.prose`/`.font-serif` in built CSS: see open question 3 | partly |
| AC4 contrast | Appendix script run against the values parsed **from `src/index.css`** (not this doc), both themes, every pair listed in AC4; QA computes independently | no (sandbox/QA) |
| AC5 dark mode | Node script (sandbox, uncommitted): run the pre-paint snippet extracted from `index.html` against stubbed `document`/`localStorage`/`matchMedia`: {no key, `light`, `dark`, `system`, garbage, storage throws} × {OS dark, OS light} → expected class. Import `theme.js` in bare Node with the same stubs: `resolveTheme` table, `getStoredTheme` fallbacks, `watchSystemTheme` fires and unsubscribes. Toggle a11y: code review of the Radix radio-menu + `aria-label`; manual keyboard walk-through if a browser is available (screenshots). Follow-up: commit these as `theme.test.js` once FE-1's harness is merged | no (sandbox/QA) |
| AC6 primitives | Static check: each of the seven files imports its Radix/sonner package, uses `cn`, `forwardRef` on DOM elements, no hard-coded palette classes (`grep -E '(slate\|emerald\|teal\|zinc\|gray)-'` empty), FV ring on focusable parts, exports only PascalCase components. Build succeeds with unused files (tree-shaken) | build in CI |
| AC7 scope | `git diff origin/main --name-only -- frontend/ README.md` ⊆ Scope list; `package.json`/lockfile/`vite.config.js` diff empty | sandbox |
| AC8 visual | Playwright screenshots (light/dark, hero + Navbar + open toggle menu, `emulateMedia` both schemes) if `node_modules` can be installed; else CI build log + token diff (old → new) + the contrast table, marked as the fallback | if env allows |
| AC9 docs | This design approved; README line present | review |

Failure paths covered: storage unavailable or throwing; invalid stored value; `matchMedia` missing; OS theme change
while in `system`; change in another tab; keyboard-only operation; no JS (the page falls back to light tokens; the app needs JS anyway).

## Risks and rollout
- **Interim light mode** unreadable on the ask flow (above) → mitigated by the default (open question 1); fully fixed by FE-3/FE-4.
- **Font weight in dist**: ~13 `woff2` subsets are emitted (~20–50 KB each), but browsers fetch only Latin (+ italic when used),
  roughly 120 KB on first load, cached after. Detected in the CI build log sizes.
- **Font swap shift**: fontsource uses `font-display: swap`; the system fallbacks are metrically close enough for a
  one-time reflow. No preload links (they'd need hashed file names in `index.html`).
- **Inline script vs a future CSP**: none today; a CSP would need a hash for the snippet. Noted for whoever adds one.
- **Rollback**: revert the PR; nothing else depends on FE-0 until FE-3/FE-4/FE-2 merge.

## Open questions for pm-lead
1. **Interim default**: `DEFAULT_THEME = "dark"` until FE-3 (recommended; amends AC5's first-load clause, and FE-3 gets
   an AC to flip it to `"system"`), or AC5 as written (OS-light visitors see unreadable answers until FE-3)?
2. **AC4 border clause**: OK to meet 1.4.11 with `--input` (≥ 3:1, used for every control outline) and keep `--border` a
   decorative hairline (1.31:1 / 1.46:1)? If `--border` must be ≥ 3:1 too, I'll set it equal to `--input`.
3. **AC2/AC3 `dist/` greps**: the CI job doesn't print `dist/` CSS contents and the artifact host is unreachable from
   sandboxes (QA lesson, AI-9). Options: (a) QA builds locally if npm egress works for them; (b) a backend follow-up adds
   a "theme assets" step to the `frontend` job (`grep -c '@font-face\|\.prose\|\.font-serif' dist/assets/*.css`, `ls dist/assets | grep woff2`);
   (c) accept the Vite asset list in the log for AC2 and source-level checks for AC3. I suggest (b) + (c) meanwhile.
4. **Navbar copy**: OK to drop the "Clinical Research AI" badge and change the tagline style (copy kept:
   "Precision-Grounded Literature Engine")? If Mahesh wants new copy, that's a separate decision.
5. **Split**: FE-0a (~400 lines) + FE-0b (~170 lines) as above, or one ~570-line PR?

## Appendix: contrast script
Run with `python3 contrast.py` (stdlib only). QA should replace `T` with values parsed from `src/index.css`.
```python
import colorsys
def rgb(h):
    H, S, L = [float(x.rstrip('%')) for x in h.split()]
    return colorsys.hls_to_rgb(H / 360, L / 100, S / 100)
def lum(c):
    f = lambda v: v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = map(f, c); return 0.2126 * r + 0.7152 * g + 0.0722 * b
def ratio(a, b):
    la, lb = lum(rgb(a)), lum(rgb(b)); return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
# T = {"light": {"background": "40 23% 97%", ...}, "dark": {...}}  (the token table above)
# for fg, bg, minimum in PAIRS: print(fg, bg, ratio(T[t][fg], T[t][bg]) for t in ("light", "dark"))
```

## PM decision
**Approved with conditions** (pm-lead, 2026-11-19). The conditions are already written into the amended ACs in
`agents/tasks/FE-0.md` and the new `agents/tasks/FE-0b.md`. Code may start on the FE-0a part now.

Why it's approved: the design does what UI-1/UI-2 need without changing any feature screen, and it reads principles 1 and 3
correctly. Using ink blue for links and keeping red for *unsupported* and *destructive* is the right call, so "click here"
never looks like "this claim failed". The status tokens differ in hue, lightness and (in FE-3) text and icon. The contrast
table is computed, covers every AC4 pair in both themes, and comes with a script QA can rerun against `src/index.css`. The
theme logic is a small pure module, so it can be tested without a browser, and the design has no unused provider. Contracts
and dependencies are unchanged.

Answers to the open questions:
1. **Interim default: dark. Approved.** Showing 1.16:1 answer prose to every OS-light first-time visitor would break
   principle 1 on the main screen, which is worse than defaulting to dark for a while. `DEFAULT_THEME = "dark"` goes in
   `theme.js` **and** the pre-paint script (one constant each, with comments pointing at each other). Light, Dark and System
   all ship and work. A stored `system` follows `prefers-color-scheme`, live. I amended AC5. FE-3 gets an AC to flip the
   default to `"system"` once the ask flow uses tokens (added to `agents/tasks/FE-3.md`). This is a reversible UI choice and
   it's flagged for Mahesh in the ticket Notes.
2. **AC4 border clause: yes.** WCAG 1.4.11 covers the parts needed to identify a control, not decorative hairlines. If
   `--border` were ≥ 3:1, every card and divider would get a heavy grey box, which works against the journal look Mahesh
   asked for. The rule "every form control or control-identifying outline uses `border-input`, never `border-border`" is
   now part of the contract. Put it as a comment next to `--input` in `src/index.css` so the FE-3/FE-4/FE-2 designs see it.
   QA checks that every control outline styled in this PR (dropdown trigger, if outlined) uses `border-input`. AC4 amended.
3. **`dist/` greps: (c) now, with (a) when QA can build and (b) as a backend follow-up.** One correction to the plan:
   Tailwind only generates classes it finds in `content`, and nothing uses `prose` until FE-3. So "built CSS contains
   `.prose`" can't pass in FE-0 whatever the CI setup. Instead, AC3 checks the plugin registration and the token-mapped
   `DEFAULT` theme in source, plus `.font-serif` in the built CSS when a `dist/` is available (Navbar uses it). The `.prose`
   built-CSS check moves to FE-3. AC2 accepts the Vite asset list in the CI build log (Inter normal and Source Serif 4
   normal + italic `woff2`) plus the source checks (the fontsource imports in `main.jsx`, no Google hosts in `index.html`
   or `src/`). The CI `dist/` grep step is backlog item **OPS-H14** (backend, `.github/workflows/ci.yml`).
4. **Drop the "Clinical Research AI" badge: approved** as a reversible UI choice. It contradicts the direction Mahesh set
   ("classic UI, think like a pro"), and ArxivLens isn't clinical-specific. The tagline copy stays. The PR description must
   show it as a visible copy change (before/after) so Mahesh can veto it at merge. New brand copy, if he wants any, is his decision.
5. **Split: yes.** FE-0 (= the design's "FE-0a", ~400 lines) is built now on branch `agent/frontend/FE-0`. The ticket ID and
   Jira label stay `FE-0`, so the CI ownership check and Jira links keep working. The six other primitives go to
   **`agents/tasks/FE-0b.md`** (new files only, branch `agent/frontend/FE-0b`). FE-0b may not change Navbar (the divider
   stays a `div`; moving it to `Separator` belongs in the token-migration follow-up). FE-0b shares no file with FE-0 or FE-1,
   but frontend WIP is full (FE-1 #68 + FE-0), so it starts when a slot frees. If FE-0 is still well under 400 lines once
   built, that doesn't reopen the split.

Further conditions (no answer needed, just do them):
- a. **Tests:** the uncommitted Node checks for AC5 (the pre-paint snippet matrix and `theme.js` functions) are the
  developer's self-check. QA re-runs them independently, and their output is AC5's evidence. Committing them as
  `src/lib/theme.test.js` is a follow-up for after FE-1 merges, recorded in the ticket Notes. It is not a reason to touch FE-1's files now.
- b. **Bundle impact:** the PR description lists the font `woff2` count and total size from the CI build log (risk "font weight in dist").
- c. **Keyboard:** the Navbar brand `<button>`, the tabs and the theme menu must be reachable and operable with the keyboard
  alone, with a visible focus ring in both themes. This is AC5/AC8 evidence (a screenshot of the focus ring if a browser is
  available, otherwise a code reference).
