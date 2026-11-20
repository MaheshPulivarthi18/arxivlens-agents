# FE-0e: Move the secondary screens (ingest, infrastructure, library, toast) to theme tokens

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P1 (unblocks P0 FE-3b's theme flip; WCAG 1.4.3 in light mode) |
| **PRD ref** | Product PRD §7 (readable, accessible UI); FE-0 design (tokens); FE-3 design PM decision Q1 |
| **Depends on** | FE-0 #69 merged (`54c4de8`), FE-1 #68 merged. No overlap with FE-3a or open PRs #70, #79, #81–#85 (checked via REST 2026-11-20) |
| **Jira** | KAN-91 (epic KAN-5 "Research UI & citations"; labels `task-FE-0e`, `agent-frontend`, `arxivlens`) |
| **Design required** | no: class swaps to existing tokens + one grep test; no new component, contract or dependency |
| **Status** | Ready to merge: QA r1 FAIL → r2 PASS + pm-lead APPROVE on `27953fd` (2026-11-20 UTC); PR #87 raised, waiting on Mahesh |

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
- [ ] AC2 — QA evidence: contrast of every text colour **set by a class string in** the four files on its surface, light and dark, ≥ 4.5:1 (≥ 3:1 for
  icons/large text), computed from `src/index.css` with FE-0's appendix script. Colours that come from a `ui/` component variant (`ui/button` `clinical`,
  `ui/badge` `arxiv`) are reported but not owed here: `arxiv` is retargeted by FE-3a (#86), `clinical` by [FE-0f](FE-0f.md). *(Wording clarified
  2026-11-20 by pm-lead from QA `[spec]` r1 #3 / r2 #2; the check itself is unchanged.)*
- [ ] AC3 — Existing tests pass; no behaviour, copy or DOM-structure change (diff is class strings + the new test).
- [ ] AC4 — CI `frontend` job green (`npm ci && npm run lint && npm test && npm run build`), lint warnings not above main.

## Verification
```bash
cd app/frontend && npm ci && npm run lint && npm test && npm run build
```

## Notes
- 2026-11-20 (pm-lead): specced at the FE-3 design review (Q1 option b). Counts at `c37d27c`: InfrastructureModal 7, IngestModal 8, PapersLibrary 4, Toast 2
  palette-class lines (text, bg, border).
- 2026-11-20 (frontend-engineer): **build done, In QA.** Branch `agent/frontend/FE-0e`, head `50ef4d5` (base `c37d27c`), 5 files, +62/−23.
  - Swaps (class strings only, no copy/DOM/prop change): icon tiles → `bg-accent text-accent-foreground`; accent text, spinners, focus borders,
    Toast icon → `text-primary`/`border-primary`/`focus:border-primary`; pgvector node → `border-primary/40 text-primary`; Ingest success panel →
    `bg-supported border-border` + `text-supported-foreground` heading; DLQ tab icon → `text-muted-foreground`; Toast border → `border-border`;
    View PDF → `text-primary hover:text-accent-foreground hover:bg-accent`. Library status Badge keeps `variant="clinical"` but gets a className
    override `border-border bg-supported text-supported-foreground` (twMerge drops the variant's emerald classes; checked with tailwind-merge 3.6.0).
  - **Deviation from the mapping guide (contrast wins):** error text/icon use `text-unsupported-foreground`, not `text-destructive`. Dark `--destructive`
    (2 62% 44%) is a fill colour: as text it is 2.77:1 on card and 2.61:1 on the `bg-destructive/10` panel. The panel itself is
    `bg-destructive/10 border-destructive/30` as mapped. Also changed the unchanged-before `text-muted-foreground/60` "(vN)" in PapersLibrary to
    `text-muted-foreground` (it was 2.72 light / 3.35 dark, and AC2 covers every text colour in the four files).
  - AC1: `src/test/tokens.test.js` exports `GUARDED_FILES` (the four files, relative to `src/`) and `PALETTE_CLASS` (the AC regex), plus a self-test
    that the regex matches palette samples and not token samples. Self-check with a 20-line vitest shim (registry blocked, see below): head 5/5 pass;
    origin/main files fail with 8/7/4/2 hits (= the counts above); mutant `hover:text-emerald-300` back in PapersLibrary → fails at `:127`.
  - Classes: all 14 new classes generate CSS with Tailwind 4.3.3 `compile()` against a copy of `tailwind.config.js` (typography plugin stripped,
    not installed); control `bg-popoverx` generates none.
  - AC2 contrast (FE-0 appendix functions verbatim, tokens parsed from `src/index.css`; alpha surfaces composited in sRGB). Min 4.5 text, 3.0 icon/non-text.
    Every pair the PR introduces passes in both themes:
    ```
    accent-foreground       accent                   3.0   9.47   8.98 ok  Ingest/Infra header icon tile; Library View PDF hover needs 4.5
    foreground              card                     4.5  16.63  13.79 ok  dialog text, Toast text, Infra nodes, Library title
    muted-foreground        card                     4.5   6.77   6.91 ok  dialog descriptions/labels, Infra active-tab icon, Library (vN)
    foreground              background               4.5  15.66  14.88 ok  Ingest input text
    muted-foreground        background               4.5   6.37   7.45 ok  Ingest placeholder, Library header
    primary                 background               3.0   8.56   8.25 ok  Ingest focus:border-primary (non-text)
    primary                 muted/40@card            3.0   8.57   7.21 ok  Ingest loading spinner
    foreground              muted/40@card            4.5  15.69  13.01 ok  Ingest loading step, Infra topology panel
    muted-foreground        muted/40@card            4.5   6.38   6.52 ok  Ingest loading hint, Infra/Library thead
    unsupported-foreground  destructive/10@card      4.5   7.66   8.42 ok  Ingest error text + icon
    supported-foreground    supported                4.5   7.23   8.41 ok  Ingest success heading+icon, Library status badge
    foreground              supported                4.5  14.03  11.27 ok  Ingest result title
    foreground              background/80@supported  4.5  15.32  14.25 ok  Ingest stat values
    muted-foreground        background/80@supported  4.5   6.23   7.13 ok  Ingest stat labels
    primary                 background/80@supported  4.5   8.37   7.90 ok  Ingest embeddings value (16px bold)
    muted-foreground        muted                    4.5   5.84   5.91 ok  Infra inactive tab label + AlertTriangle
    primary                 card                     4.5   9.09   7.65 ok  Infra pgvector/metrics, Library View PDF, Toast icon, spinner, focus border
    primary                 muted/20@card            4.5   8.83   7.43 ok  Library View PDF on row hover
    muted-foreground        muted/20@card            4.5   6.57   6.71 ok  Library ID/(vN) on row hover
    unsupported-foreground  card                     4.5   9.02   8.94 ok  Infra DLQ FileDataError
    destructive             card                     4.5   7.01   2.77 NO  REJECTED option: text-destructive (dark fails)
    #ffffff                 #059669                  4.5   3.77   3.77 NO  OUT OF SCOPE ui/button clinical (emerald-600)
    #ffffff                 #0d9488                  4.5   3.74   3.74 NO  OUT OF SCOPE ui/button clinical (teal-600)
    #22d3ee                 #06b6d4/10@card          4.5   1.65   8.08 NO  OUT OF SCOPE ui/badge arxiv (FE-3a)
    ```
    Script (`python3 contrast_fe0e.py app/frontend/src/index.css`):
    ```python
    # python3 contrast_fe0e.py app/frontend/src/index.css  (FE-0 appendix rgb/lum/ratio; tokens parsed from index.css;
    # "tok/NN@under" = token at NN% alpha composited in sRGB over "under"; "#rrggbb" = literal palette colour)
    import colorsys, re, sys
    def rgb(h):
        H, S, L = [float(x.rstrip('%')) for x in h.split()]
        return colorsys.hls_to_rgb(H / 360, L / 100, S / 100)
    def lum(c):
        f = lambda v: v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
        r, g, b = map(f, c); return 0.2126 * r + 0.7152 * g + 0.0722 * b
    def ratio(a, b):
        la, lb = lum(a), lum(b); return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    css = open(sys.argv[1]).read()
    blk = lambda sel: dict(re.findall(r'--([a-z-]+):\s*([0-9.]+ [0-9.]+% [0-9.]+%);', re.search(re.escape(sel) + r'\s*\{(.*?)\}', css, re.S).group(1)))
    T = {"light": blk(":root")}; T["dark"] = {**T["light"], **blk(".dark")}
    def col(t, s):
        if "@" in s:
            top, under = s.split("@", 1); tok, a = top.split("/"); a = int(a) / 100
            return tuple(a * c + (1 - a) * u for c, u in zip(col(t, tok), col(t, under)))
        if s.startswith("#"): return tuple(int(s[i:i + 2], 16) / 255 for i in (1, 3, 5))
        return rgb(T[t][s])
    PAIRS = [  # fg, bg, min, where
     ("accent-foreground", "accent", 3.0, "Ingest/Infra header icon tile; Library View PDF hover needs 4.5"),
     ("foreground", "card", 4.5, "dialog text, Toast text, Infra nodes, Library title"),
     ("muted-foreground", "card", 4.5, "dialog descriptions/labels, Infra active-tab icon, Library (vN)"),
     ("foreground", "background", 4.5, "Ingest input text"),
     ("muted-foreground", "background", 4.5, "Ingest placeholder, Library header"),
     ("primary", "background", 3.0, "Ingest focus:border-primary (non-text)"),
     ("primary", "muted/40@card", 3.0, "Ingest loading spinner"),
     ("foreground", "muted/40@card", 4.5, "Ingest loading step, Infra topology panel"),
     ("muted-foreground", "muted/40@card", 4.5, "Ingest loading hint, Infra/Library thead"),
     ("unsupported-foreground", "destructive/10@card", 4.5, "Ingest error text + icon"),
     ("supported-foreground", "supported", 4.5, "Ingest success heading+icon, Library status badge"),
     ("foreground", "supported", 4.5, "Ingest result title"),
     ("foreground", "background/80@supported", 4.5, "Ingest stat values"),
     ("muted-foreground", "background/80@supported", 4.5, "Ingest stat labels"),
     ("primary", "background/80@supported", 4.5, "Ingest embeddings value (16px bold)"),
     ("muted-foreground", "muted", 4.5, "Infra inactive tab label + AlertTriangle"),
     ("primary", "card", 4.5, "Infra pgvector/metrics, Library View PDF, Toast icon, spinner, focus border"),
     ("primary", "muted/20@card", 4.5, "Library View PDF on row hover"),
     ("muted-foreground", "muted/20@card", 4.5, "Library ID/(vN) on row hover"),
     ("unsupported-foreground", "card", 4.5, "Infra DLQ FileDataError"),
     ("destructive", "card", 4.5, "REJECTED option: text-destructive (dark fails)"),
     ("#ffffff", "#059669", 4.5, "OUT OF SCOPE ui/button clinical (emerald-600)"),
     ("#ffffff", "#0d9488", 4.5, "OUT OF SCOPE ui/button clinical (teal-600)"),
     ("#22d3ee", "#06b6d4/10@card", 4.5, "OUT OF SCOPE ui/badge arxiv (FE-3a)"),
    ]
    for fg, bg, mn, where in PAIRS:
        r = [ratio(col(t, fg), col(t, bg)) for t in ("light", "dark")]
        print(f"{fg:23} {bg:24} {mn:3.1f} {r[0]:6.2f} {r[1]:6.2f} {'ok ' if min(r) >= mn else 'NO '} {where}")
    ```
  - **Not fixed, out of scope (for pm-lead):** colours that come from `ui/` variants, not from class strings in these files. (1) `ui/button`
    `variant="clinical"` (Ingest "Index Paper" + "Ask a question about this paper", Infra "Replay DLQ"): white on emerald-600→teal-600 is 3.77/3.74:1
    in both themes, under 4.5 for `text-xs`/`text-sm`. Pre-existing and theme-independent. Fixing it means retargeting the variant in `ui/button.jsx`
    (open PR #70's area) or switching these call sites to `variant="default"` (a prop change, which AC3 excludes). Suggest a follow-up task.
    (2) `ui/badge` `variant="arxiv"` (cyan-400, 1.65:1 in light) in IngestModal and PapersLibrary: FE-3a retargets it in `badge.jsx`.
    (3) Text inputs still use `border-border` (FE-0 rule: controls use `border-input`); not a palette class, left for a follow-up to keep the diff to the mapping.
  - Commands: `npm ci` **failed, registry blocked** (`ENOTFOUND registry.npmjs.org` on every tarball, then npm "Exit handler never called"), so
    `npm run lint`, `npm test` and `npm run build` were **not run locally**; AC3/AC4 rest on CI. All 5 files parse with esbuild 0.x (`--loader:.jsx=jsx`).
    `.github/scripts/ownership-check.sh origin/main agent/frontend/FE-0e` → `Ownership OK for role=frontend (85 changed lines)`. No CI run on branch
    push (0 runs for the branch); CI starts when the PR opens. Lint warnings vs main: not verifiable locally, check the CI Frontend job's `Found N warnings`.
- **2026-11-21 rework r1** (frontend-engineer; QA r1 FAIL, `agents/reviews/FE-0e/report.md`). Head `27953fd` on PR #87 (still draft). Only `frontend/src/test/tokens.test.js` changed.
  - [x] **QA 1 [blocking]** guarded paths no longer use the template-literal URL plus `import.meta.url` form that Vite's assetImportMetaUrl plugin rewrites into an `import.meta.glob`.
    The test now resolves `SRC_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')` and reads `path.join(SRC_DIR, rel)` with node `fs`/`path`/`url`.
    CI Frontend job `136486858137`: `✓ src/test/tokens.test.js (5 tests)`.
  - [x] **QA 2 [blocking]** CI Frontend job `136486858137` passed at `27953fd`: `Found 0 warnings and 0 errors.`, `Test Files 4 passed (4)`, `Tests 24 passed (24)`, `✓ built in 1.07s`.
    Go and ownership-check also passed. DB and Python M0 were still running when I checked.
  - [x] **QA 4 [nit]** a global copy `PALETTE_CLASS_ALL = new RegExp(PALETTE_CLASS.source, 'g')` with `line.matchAll` reports every hit on a line.
    Node check: `'<p className="text-emerald-400 hover:bg-red-500/10">'` → 2 hits. 0 hits in the 4 guarded files.
  - **Negative proof with real Vitest: not done.** CI only triggers on `pull_request` and on push to `main` (`.github/workflows/*.yml`), so a throwaway
    `agent/frontend/FE-0e-neg` branch would run nothing. I didn't push it and didn't open a PR. The pattern-positive test (`pattern catches palette classes…`)
    passes in CI, and the same logic in plain node finds the injected classes. I couldn't run Vitest locally because npm is blocked.
  - Ownership: `ownership-check.sh origin/main agent/frontend/FE-0e` → `Ownership OK for role=frontend (92 changed lines)`.
  - Findings 3, 5 and 6 go to pm-lead or a follow-up task; they aren't changed here.
- **2026-11-20 UTC (pm-lead, final review): APPROVE** on `27953fd` after QA r1 FAIL → r2 PASS. All 14 evidence images (00–08 @ `9f1ddf2`, 09–13 @ `175d597`)
  opened. AC1 green in real Vitest (CI job 136486858137, `tokens.test.js` 5 tests; `lines.length > 1` proves the files were read); negative behaviour shown
  in plain Node only (accepted: the Vite-sensitive part is path resolution, proven by the CI pass). AC2 49/49 in-file pairs pass both themes. AC3 class
  strings only. AC4 0 warnings, 24/24, `✓ built in 1.07s`. PR #87 description rewritten with the Evidence section and marked ready for review.
  QA `[spec]` items: (a) AC2 wording clarified above; `arxiv` badge → FE-3a (#86, computed 13.73/10.99 on any surface); `clinical` button → new
  **FE-0f** (P1, Ready). (b) Guard regex gaps folded into **FE-3b AC2** (other utilities, all palettes, `white`/`black` except `shadow`).
  (c) Inputs `border-border` → `border-input`: Backlog (frontend, P3). No PRD status change: UI-2/3/4 are already ✅; no README change (no behaviour change).
