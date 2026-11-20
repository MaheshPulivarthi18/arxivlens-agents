# FE-3b: Ask flow on theme tokens, status-chip tooltips, and flip the theme default to "system"

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (finishes FE-3: AC3 tooltip and AC8; light mode becomes the default for OS-light visitors) |
| **PRD ref** | Product PRD UI-1, §7; parent [FE-3](FE-3.md) AC8; FE-0 design (tokens, §6 tooltip API + FE-0b amendment) |
| **Depends on** | **FE-0b #70 merged** (`ui/tooltip`), **FE-3a #86 merged** (same files; FE-3a2 should merge first or FE-3b re-checks its App-level asserts still pass), **FE-0e merged** (secondary screens on tokens before the flip; PM decision Q1). FE-0c #85 merged preferred (its drift guard checks AC3 here) but not required |
| **Jira** | KAN-89 (story under epic KAN-5; parent FE-3 KAN-40), labels `task-FE-3b`, `agent-frontend`, `arxivlens` |
| **Design required** | yes, done: `docs/design/FE-3.md` Approved with changes (pm-lead 2026-11-20) |
| **Status** | Ready (FE-0b #70, FE-3a #86, FE-0e #87 merged 2026-11-20); start after FE-3a2 merges (App-level asserts, board file order) |

## Goal
Finish FE-3: the answer, refusal panel, references and early-refusal banner use FE-0's tokens and fonts, each status chip explains itself in a
keyboard-reachable tooltip, and the default theme follows the OS.

## Scope
- Files: `frontend/src/components/SynthesisView.jsx`, `ReferencesStack.jsx`, `frontend/src/App.jsx` (banner + root selection classes, `<Button size="sm">`,
  `role="status"` on the banner), `frontend/src/components/HeroSearch.jsx` (3 class swaps, design §5), `frontend/src/lib/theme.js` + `frontend/index.html`
  (`DEFAULT_THEME = "system"`, reword the "interim" comments), `frontend/src/test/setup.js` (`ResizeObserver` stub), `frontend/src/test/tokens.test.js`
  (extend FE-0e's guard), `ReferencesStack.test.jsx` (tooltip test).
- Out of scope: copy changes (approved in FE-3a), new dependencies, an app-level `<TooltipProvider>` (it doesn't change the delay; FE-0b note).

## Acceptance criteria
- [ ] AC1 — Each status chip is a `<button type="button">` wrapped in `Tooltip`/`TooltipTrigger asChild`/`TooltipContent`; its accessible name is the chip
  text. Test: `user.tab()` to a supported chip, `findByRole('tooltip')` has exactly the design's supported text (fallback if flaky: `aria-describedby` on the
  trigger points at that text). Tooltip copy names no method ("entails"/"NLI"/"cosine" absent; test).
  The FE-3a interim `title` attribute is removed from every chip (test: no chip/button has a `title`), so the meaning isn't announced twice (FE-3a QA r1 finding 3).
- [ ] AC2 — FE-0e's `tokens.test.js` guard is extended in two ways (amended 2026-11-20 by pm-lead from FE-0e QA r1 #5 / r2 #3):
  (a) `GUARDED_FILES` also lists `SynthesisView.jsx`, `ReferencesStack.jsx`, `App.jsx`, `HeroSearch.jsx`;
  (b) `PALETTE_CLASS` also catches, with any variant prefix, the utilities `ring-offset`, `outline`, `divide`, `decoration`, `fill`, `stroke`, `placeholder`
  and `caret` (besides today's `text|bg|border|ring|from|via|to|shadow`), every Tailwind default palette (`slate gray zinc neutral stone red orange amber
  yellow lime green emerald teal cyan sky blue indigo violet purple fuchsia pink rose`), and `white`/`black` on every one of those utilities **except
  `shadow`** (`shadow-black/80` stays allowed: a shadow tint is not text or a surface). The self-test gains a positive sample for each new utility, a
  non-emerald palette (e.g. `bg-zinc-900`, `text-sky-400`) and `text-white`/`border-white/30`, and keeps the token and `shadow-black/80` negatives.
  All eight guarded files have 0 hits at the PR head. Answer prose uses `prose font-serif`; markers, passages, active card, banner as design §2–§4.
- [ ] AC3 — `DEFAULT_THEME === "system"` in `theme.js` and the same literal in `index.html` (FE-0c's drift guard, or an equivalent assert if #85 isn't merged).
- [ ] AC4 — CI `frontend-dist-report.sh` output shows `.prose` in the built CSS.
- [ ] AC5 — QA evidence: WCAG contrast ≥ 4.5:1 (text) and ≥ 3:1 (focus ring) on light **and** dark for the design's contrast table pairs, computed from the PR's
  `src/index.css`; light and dark screenshots of an answer, an A-refusal and the early refusal if QA can run a browser.
  The passage text (today `text-slate-300` on `bg-background/80`, nearly invisible in light mode per FE-3a QA r1 evidence 11/17) is in the contrast table and
  in the light screenshots of the A-refusal and `mixedAnswer`.
- [ ] AC6 — FE-1/FE-3a tests still pass unchanged except where a class assert must follow a token (listed in the PR body); AC4 early-refusal asserts unchanged.
- [ ] AC7 — CI `frontend` job green (`npm ci && npm run lint && npm test && npm run build`), lint warnings not above main.
- [ ] Docs: README screenshot/description updated if it mentions the dark default.

## Verification
```bash
cd app/frontend && npm ci && npm run lint && npm test && npm run build
```

## Notes
- 2026-11-20 (pm-lead): split from FE-3 at the design review. Waits for FE-0e so an OS-light visitor never lands on ~1.8:1 emerald/red text in the
  ingest modal, library or toast after the flip.
- 2026-11-20 UTC (pm-lead, FE-0e final review): AC2 amended to widen the guard regex (FE-0e QA `[spec]` r1 #5 / r2 #3). pm-lead checked the widened
  pattern against the PR heads: FE-0e's four files have 0 hits except `Toast.jsx`'s `shadow-black/80`, hence the `shadow` exception; FE-3a's head
  (`fa92c30`) still has the expected hits in the four ask-flow files (e.g. `App.jsx:186` `text-white`, `HeroSearch.jsx:81` `border-white`), which this
  task swaps. Flip order confirmed: `Depends on` keeps **FE-3a #86 merged** first, which retargets `ui/badge` `arxiv` to opaque `bg-secondary
  text-secondary-foreground` (13.73:1 light / 10.99:1 dark on any surface, pm-lead calc), fixing the ~1.4–1.65:1 cyan badge in the ingest panel and
  library (FE-0e QA r1 evidence 06). The `ui/button` `clinical` gradient (3.77/3.74:1, both themes, includes `HeroSearch.jsx:75`) is fixed by
  [FE-0f](FE-0f.md) in `button.jsx`, not here; it is theme-independent, so it doesn't block the flip.
