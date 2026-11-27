# FE-0k: repo-wide form-control outline guard; hero search box outlined with `border-input` and a full-strength focus ring

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P3 (accessibility polish + regression guard) |
| **PRD ref** | FE-0 design token rule, `docs/design/FE-0.md:107-108` (`input` on `background` 3.30/3.48:1, on `card` 3.50/3.23:1, light/dark, WCAG 1.4.11), `:105-106` (`ring` on `background` 8.56/8.25, on `card` 9.09/7.65) and `:120-123` ("**any form control or control-identifying outline uses `border-input`, never `border-border`**"), `:210` (focus ring = `ring-2 ring-ring`). Sources: QA FE-0h r1 "Missing tests" (repo-wide scan) and QA FE-3b nit 2 + PM review item 2 (`agents/reviews/FE-3b/report.md:57,92`: hero halo `ring-ring/30` is 1.68/1.83:1; unfocused outline is `border-border/90`) |
| **Depends on** | FE-0h (#101, merged `d646d63`, added `src/test/controls.test.js`), FE-3b (#104, merged `dcb326a`, last edit of `HeroSearch.jsx`). No open PR touches the files below (checked 2026-11-27T09:00Z: #125 `ui/badge.test.jsx`; #128 `App.{jsx,test.jsx}`, `ReferencesStack.*`, `SynthesisView.*`, `lib/citations.*`, `test/fixtures.js`; no other open PR is under `frontend/`) |
| **Jira** | KAN-132, story under epic KAN-5 "Research UI & citations"; labels `task-FE-0k`, `agent-frontend`, `arxivlens` |
| **Design required** | no: one className edit applying an existing FE-0 design rule, plus a test file; no new component, token, dependency or API field |
| **Status** | Done (#130 merged `4b3b9b0`) |

## Goal
The FE-0h guard checks only the two files it was written for (`CONTROL_FILES = ['components/IngestModal.jsx',
'components/PapersLibrary.jsx']`, `controls.test.js:10`), so a new component with a `border-border` text field, or a
`<textarea>`/`<select>`, would regress WCAG 1.4.11 unnoticed. And the main search box, the first control every user sees,
breaks the FE-0 rule today: its outline is drawn by the wrapper `div` (`HeroSearch.jsx:63` @ `53171d6`:
`bg-card border border-border/90 … focus-within:border-input focus-within:ring-2 focus-within:ring-ring/30`), so the
unfocused box is outlined with the decorative hairline, and once it is `border-input` the only focus change left is a
1.68/1.83:1 halo. Make the hero box follow the rule, and turn the guard into a scan of every control under
`src/components/`.

## Scope
- Files expected to change:
  - `frontend/src/components/HeroSearch.jsx`: the wrapper `div` className at line 63 only.
  - `frontend/src/test/controls.test.js`: discovery + wrapper rule + self-tests (keep `BORDER_BORDER`, `BORDER_INPUT` and their
    existing self-test samples; extend `inputClassNames` or replace it with a general extractor).
- Out of scope: `HeroSearch.test.jsx` (must pass unchanged), `tokens.test.js` (unchanged; `border-input`/`ring-ring` are
  tokens), `index.css` token values, the suggestion chips (`HeroSearch.jsx:103`, buttons with text labels, not form controls),
  `ui/button.jsx`, every file in #128, any new `Input` primitive.

## Acceptance criteria
- [ ] AC1 (hero box): the wrapper `div` at `HeroSearch.jsx:63` has `border-input` (whole token) and no `border-border`
  token in any form (`border-border/90` gone). Its focused state is shown by a full-strength focus ring:
  `focus-within:ring-2` and `focus-within:ring-ring` (whole token, **no** `/NN` opacity), per the FE-0 focus-ring rule.
  `focus-within:border-input` may be dropped (it no longer changes anything) or kept. Every other class on that line and
  every other line of `HeroSearch.jsx` is unchanged.
- [ ] AC2 (discovery): `controls.test.js` finds the files to check itself: every `.jsx` file under `src/components/`,
  recursively (including `ui/`), excluding `*.test.jsx`, that contains an intrinsic `<input`, `<textarea` or `<select` tag
  (lowercase, followed by whitespace, `>` or `/`, so `<Input`/`<inputs` don't count). The test asserts the discovered set
  **contains** `components/HeroSearch.jsx`, `components/IngestModal.jsx` and `components/PapersLibrary.jsx` (so a broken
  scan can't pass vacuously), and the hard-coded `CONTROL_FILES` list is gone.
- [ ] AC3 (rule): for every discovered control, one of these holds, otherwise the test fails naming the file and tag:
  (a) the control's own static className contains `border-input` and no `border-border` token; or
  (b) the control's own className has no `border` / `border-*` token, and its outline wrapper (the nearest enclosing
  element whose className contains `focus-within:`) has `border-input`, no `border-border` token, and
  `focus-within:ring-ring` at full strength. A control with neither (no border and no such wrapper), or without a static
  className, fails.
- [ ] AC4 (self-tests on synthetic sources, no product file): the extractor handles `<textarea … />`,
  `<textarea …>{v}</textarea>` and `<select …>…</select>` whose props contain an arrow function (`onChange={(e) => f(e)}`,
  i.e. a `>` inside braces), and returns the right className for each; a `<textarea className="border border-border" />`
  is rejected; a wrapper-outlined input (`<div className="border border-input focus-within:ring-2 focus-within:ring-ring"><input className="outline-none" /></div>`)
  is accepted and the same with `border-border/90` or `focus-within:ring-ring/30` is rejected; `<Input className="border-border" />` is not discovered.
- [ ] AC5 (mutants, developer or QA harness; evidence file with each mutant, command and the FAIL line; one per rule part):
  M1 hero wrapper back to `border-border/90` → FAIL; M2 hero `focus-within:ring-ring` → `focus-within:ring-ring/30` → FAIL;
  M3 a temporary `src/components/Probe.jsx` with `<textarea className="border border-border" />` → FAIL;
  M4 the same file as `src/components/ui/probe.jsx` → FAIL (recursion); M5 a temporary file with only
  `<select className="border border-border">…</select>` → FAIL (`<select` discovered); M6 `IngestModal.jsx` input
  `border-input` → `border-border` → FAIL; M7 `PapersLibrary.jsx` likewise → FAIL; unmutated tree → PASS.
- [ ] AC6 (contrast + screenshots, developer or QA harness): computed from the PR's `index.css`, the hero outline
  `input` on `background` and on `card` is ≥ 3:1 in light and dark, and the focus `ring` on `background` is ≥ 3:1 in both
  (expected ≈ the FE-0 design values above). Browser screenshots of the hero box unfocused and focused (keyboard Tab), light and
  dark (4 images).
- [ ] AC7: `HeroSearch.test.jsx`, `tokens.test.js` and every other existing test pass unchanged. CI on the PR head: check-run
  `Frontend (lint, test, build)` green (steps `npm run lint`, `Test` = `npm test`, `npm run build`), and
  `Agent ownership check` green.
- [ ] Docs: none (`frontend/README.md`, app `README.md` don't mention the guard or the hero outline; checked with
  `git grep -n -i "controls.test\|border-input\|form control" origin/main -- frontend/README.md README.md CONTRIBUTING.md` → no hits).

## Verification
```bash
cd app/frontend
npm ci
npm run lint
npx vitest run src/test/controls.test.js src/components/HeroSearch.test.jsx src/test/tokens.test.js
npm test
npm run build
# AC5: apply each mutant on a scratch copy, re-run `npx vitest run src/test/controls.test.js`, paste the FAIL lines, revert
```
Agent sandboxes usually can't reach the npm registry; then CI's `Frontend (lint, test, build)` job is the evidence for AC7
and QA's Chromium harness for AC5/AC6.

## Notes
- 2026-11-27T09:00Z (pm-lead): specced from two Backlog lines (FE-0h QA/PM review "repo-wide form-control scan"; FE-3b
  QA nit 2 "hero halo", folded into it). Checked on `origin/main` `53171d6`: the only intrinsic controls under
  `src/components/` are `HeroSearch.jsx:65`, `IngestModal.jsx:80`, `PapersLibrary.jsx:51` (all `<input`); no `<textarea`/`<select`.
  The hero `<input>` itself has no border (`outline-none`); its outline is the wrapper at `:63`, hence rule (b).
  No product decision needed: the FE-0 design (PM-approved) already says control-identifying outlines use `border-input`
  and focus uses `ring-ring`; `ring-ring/60` (QA's suggestion) would be weaker than that standard ring.
- Hint (known-good from FE-0h): resolve `src/` with `path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')` and
  walk it with `node:fs` (`readdirSync(dir, { recursive: true })` or a small recursive walk); never `new URL(…, import.meta.url)`
  or `import.meta.glob` (area notes, lessons FE-0c/FE-0e). Finding the end of a non-void opening tag needs brace-depth
  tracking, since `=>` contains `>`.
- 2026-11-27 (frontend-engineer): built on `agent/frontend/FE-0k` @ `3056e80` (2 files, +167/-26). The hero wrapper now
  has `border-input` and `focus-within:ring-ring` (kept `focus-within:ring-2` and `focus-within:border-input`). The guard
  discovers controls by walking `src/components/` with `readdirSync({ withFileTypes })` and checks rules (a)/(b) through
  `violation()`. The wrapper is found with a tag stack, so a closed sibling `focus-within:` div doesn't count. npm,
  vitest and oxlint aren't available offline (no `node_modules`). I ran the test as a logic check only, under a plain-Node
  `vitest` shim: 9/9 pass on the unmutated tree. M1-M7 each FAIL with the expected message, and main's `HeroSearch.jsx`
  also FAILs. The real pass/fail is CI. Contrast computed from `index.css` (light/dark): input on background 3.30/3.48,
  on card 3.50/3.23; ring on background 8.56/8.25. AC6 screenshots are left for QA's Chromium harness, because the
  sandbox's only Tailwind is 4.3.3 and the project is on 3.4.
- 2026-11-27 (pm-lead): QA r1 PASS; PM APPROVE (`agents/reviews/FE-0k/report.md`). PR #130 raised (Evidence section, ready for review). QA finding 3 `[spec]` (a drawn border width) and the "Missing tests" self-tests went to the Backlog as a P3 frontend follow-up.
