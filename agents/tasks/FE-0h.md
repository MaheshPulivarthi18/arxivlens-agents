# FE-0h: Text inputs use `border-input` (WCAG 1.4.11); frontend README test glob

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P3 (accessibility polish) |
| **PRD ref** | Product PRD §7 (readable, accessible UI); FE-0 design token rule (`--input` = form-control outline, >= 3:1; `--border` = decorative hairline, `frontend/src/index.css:34-35,70`); follow-ups from the FE-0e QA/PM review (QA r1 #6 / r2 #4) and the FE-0c QA/PM review (README glob nit) |
| **Depends on** | FE-0e (#87, merged `1da13ee`), FE-0c (#85, merged `d7d35ab`). No open PR touches the files below (checked 2026-11-21 00:00Z: #91 `App.test.jsx`, #92 `ui/button.*`, #95 `ui/primitives.test.jsx`; no backend/ai PR is under `frontend/`) |
| **Jira** | to be created by the orchestrator (epic KAN-5 "Research UI & citations"; labels `task-FE-0h`, `agent-frontend`, `arxivlens`) |
| **Design required** | no: two class swaps, one small test file, one README line |
| **Status** | Ready (picked 2026-11-21 00:00Z) |

## Goal
The two text inputs outside the ask flow still draw their outline with the decorative `border-border` token (1.31-1.46:1), so
low-vision users can't see where to type. The FE-0 rule says form controls use `border-input` (>= 3:1). Swap them and pin it with a
test. Also fix the frontend README, which still says test files are `src/**/*.test.jsx` though Vitest includes `.test.{js,jsx}`.

Checked on `origin/main` `230f617`:
- `frontend/src/components/IngestModal.jsx:82` (arXiv ID input): `bg-background border border-border ... focus:border-primary`; it sits in `DialogContent`, which is `bg-card` (`ui/dialog.jsx`).
- `frontend/src/components/PapersLibrary.jsx:53` (filter input): `bg-card border border-border ... focus:border-primary`; it sits on the page `bg-background` (`App.jsx:155`).
- `frontend/README.md:14`: "test files are `src/**/*.test.jsx`"; `frontend/vite.config.js:20`: `include: ['src/**/*.test.{js,jsx}']`.
- pm-lead calc (WCAG relative luminance, values from `index.css`): `--input` on `--background` / `--card` = light 3.30 / 3.50, dark 3.48 / 3.23. `--border` = light 1.31 / 1.40, dark 1.46 / 1.35.

## Scope
- `frontend/src/components/IngestModal.jsx`: line 82 only, `border-border` → `border-input`.
- `frontend/src/components/PapersLibrary.jsx`: line 53 only, `border-border` → `border-input`.
- New `frontend/src/test/controls.test.js`: a source guard (see AC3).
- `frontend/README.md`: line 14 glob.
- Out of scope: every other `border-border` in these files (cards, panels, table rows: decorative, allowed); `HeroSearch.jsx` (its input is in FE-3b); `frontend/src/test/tokens.test.js` (FE-3b edits `GUARDED_FILES`); `focus:border-primary`; `theme.test.js` (the FE-0c "no `matchMedia`" tests go with FE-3b's `theme.js` change); tokens in `index.css`.
- Size: ~30-40 lines.

## Acceptance criteria
- [ ] AC1: The arXiv ID input in `IngestModal.jsx` and the filter input in `PapersLibrary.jsx` have `border-input` and no `border-border` in their `className`. Nothing else changes in either file (`git diff` shows exactly one changed line per file).
- [ ] AC2: Contrast, computed by QA from `frontend/src/index.css` at the PR head, both themes, for each call site against **its own fill and its parent surface**: IngestModal input (fill `background`, parent `card`) and PapersLibrary input (fill `card`, parent `background`). Every ratio is >= 3:1. Expected values: light 3.30 / 3.50, dark 3.48 / 3.23. Evidence is one file with the computation.
- [ ] AC3: New `src/test/controls.test.js` reads `components/IngestModal.jsx` and `components/PapersLibrary.jsx` as text. It finds each `<input` element's `className` and asserts it contains `border-input` and does not contain `border-border` (a whole-token match, so `border-border/80` also counts as a hit). It also asserts at least one `<input` was found per file, so an empty match can't pass. Resolve paths the way `src/test/tokens.test.js` does (`node:path` + `fileURLToPath(import.meta.url)`). Don't use `new URL(..., import.meta.url)`, because Vite rewrites it under Vitest (lessons FE-0c, FE-0e).
- [ ] AC4: Mutation check, run by the developer or the QA harness, with an evidence file. Revert one swap (put `border-border` back on either input) and the AC3 test fails, naming the file. Drop the "at least one input" assertion and point the test at a file with no `<input` (e.g. `components/Toast.jsx`), and it passes vacuously. That proves the assertion is needed. Then revert both mutants.
- [ ] AC5: `frontend/README.md` line 14 says test files are `src/**/*.test.{js,jsx}` (matches `vite.config.js` `include`). No other README change.
- [ ] AC6: CI `Frontend` job green on the draft PR: `npm run lint` with 0 warnings, `npm test` with one more file than `main` and every test passing, and `npm run build` OK. Quote the counts with the job ID.
- [ ] Docs: AC5 only. No PRD status change (FE-0 rows are unchanged).

## Verification
```bash
cd frontend
npm ci && npm run lint && npm test && npm run build      # CI Frontend job is the source of truth (sandbox may lack npm: "not run locally" OK)
npx vitest run src/test/controls.test.js
grep -n 'border-input\|border-border' src/components/IngestModal.jsx src/components/PapersLibrary.jsx
git diff origin/main --name-only   # exactly the 4 files in Scope
```

## Notes
- 2026-11-21 00:00Z (pm-lead): specced from two Backlog lines whose "fold into the next PR that edits these files" trigger never fired. No other task plans to edit `IngestModal.jsx`, `PapersLibrary.jsx` or `frontend/README.md`. Both are frontend, P3, and touch files no open PR or Ready task holds, so they share one small PR.
