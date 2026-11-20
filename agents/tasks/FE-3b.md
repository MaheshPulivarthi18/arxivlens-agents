# FE-3b: Ask flow on theme tokens, status-chip tooltips, and flip the theme default to "system"

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (finishes FE-3: AC3 tooltip and AC8; light mode becomes the default for OS-light visitors) |
| **PRD ref** | Product PRD UI-1, §7; parent [FE-3](FE-3.md) AC8; FE-0 design (tokens, §6 tooltip API + FE-0b amendment) |
| **Depends on** | **FE-0b #70 merged** (`ui/tooltip`), **FE-3a #86 merged** (same files; FE-3a2 should merge first or FE-3b re-checks its App-level asserts still pass), **FE-0e merged** (secondary screens on tokens before the flip; PM decision Q1). FE-0c #85 merged preferred (its drift guard checks AC3 here) but not required |
| **Jira** | KAN-89 (story under epic KAN-5; parent FE-3 KAN-40), labels `task-FE-3b`, `agent-frontend`, `arxivlens` |
| **Design required** | yes, done: `docs/design/FE-3.md` Approved with changes (pm-lead 2026-11-20) |
| **Status** | Blocked (after #70, FE-3a and FE-0e merge) |

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
- [ ] AC2 — `tokens.test.js` also covers `SynthesisView.jsx`, `ReferencesStack.jsx`, `App.jsx`, `HeroSearch.jsx`: no `/\b(?:[a-z-]+:)*(text|bg|border|ring|from|via|to|shadow)-(slate|emerald|amber|cyan|teal|red)-\d/`.
  Answer prose uses `prose font-serif`; markers, passages, active card, banner as design §2–§4.
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
