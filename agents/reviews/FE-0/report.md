<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/69#issuecomment-7023107900 (QA harness could not write report.md), 2026-11-19T21:47:02Z -->

[qa-reviewer] QA report — FE-0 · PR #69 · round 1

**Verdict: PASS**
**Reviewed commit:** `ca76bea2c641f852c56c3cab47c081a5c99815eb` · **Date:** 2026-11-19 · **Evidence commit:** [`b279a30`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0) (arxivlens-agents)
**Ticket:** [agents/tasks/FE-0.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/tasks/FE-0.md) (amended: FE-0 = design's FE-0a) · **Design:** [docs/design/FE-0.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/docs/design/FE-0.md) incl. PM decision · **PRD:** Product PRD UI-1, UI-2; §7 principles 1 and 3

Independent review from the ticket, design, PRD, diff and CI. All Node checks are QA's own scripts ([checks/](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/checks)), not the developer's. (The QA harness refused to write `report.md`; this comment is the report.)

### Test results
| Check | Source | Result |
|---|---|---|
| Go / Python M0 / DB | CI on `ca76bea` | pass (no Go/Python/schema change) |
| Frontend (lint, test, build) | CI job 135901760356 | pass: `Found 0 warnings and 0 errors.` (main `4c7d327` job 135778169752: also 0); `✓ built in 1.01s`; tests step "no frontend tests yet" |
| Agent ownership check | CI | pass: `Ownership OK for role=frontend (440 changed lines)` |
| Pre-paint matrix (index.html script in Node `vm`) | local, QA script | 14/14 cells + 2 edge cases PASS |
| `src/lib/theme.js` in bare Node | local, QA script | 42/42 PASS |
| Tokens + WCAG contrast parsed from `src/index.css` | local, QA script | 25/25 tokens in both themes; all 19 AC4 pairs + 4 extra PASS |
| Static checks (AC2/3/4-rule/5/6/7) | local, QA script | ALL PASS |
| `npm run build`/`lint`, `dist/` greps, `vite preview` screenshots | **not run locally**: npm registry unreachable (no `node_modules`) | CI is the source of truth |
| `make eval` | not run: no retrieval/answering change | n/a |

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 build + lint, no new warnings | ✅ | CI Frontend success; lint 0 vs main 0. [00-ci-checks](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/00-ci-checks.png?raw=true ``) · [01-ci-lint-build](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/01-ac1-ac2-ci-frontend-lint-build.png?raw=true) ``` · [01b-main-baseline](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/01b-ac1-main-lint-baseline.png?raw=true) ```` |
| AC2 fonts self-hosted | ✅ (CI log + source; `dist/` part n/a) | CI assets: 7 `inter-*-wght-normal`, 6 `source-serif-4-*-wght-normal`, 6 `…-wght-italic` = 19 woff2, 583.69 kB; 3 fontsource imports in `main.jsx` before `./index.css`; Google-host grep in `index.html` + `src/` exit=1. [02-fonts](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/02-ac2-fonts-source.png?raw=true) ````` |
| AC3 tokens + config | ✅ (`.font-serif` in built CSS n/a; Navbar uses `font-serif`) | 25/25 colour tokens in `:root` and `.dark` + `--radius`; `darkMode: ["class"]`, Inter/Source Serif 4 Variable stacks, status colours, `plugins: [typography]`, token-mapped `DEFAULT` prose with `maxWidth: "70ch"`, `clinical`/`title` kept + deprecated. [03-static](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/03-ac3-ac6-ac7-static-checks.png?raw=true) `````` · [04-contrast](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/04-ac4-contrast.png?raw=true) ``````` |
| AC4 contrast + `border-input` rule | ✅ | Independent HSL→sRGB→WCAG (within ±0.04 of the design table). Tightest: `input` on `card` dark 3.22, on `background` light 3.31 (≥3); `muted-foreground` on `muted` 5.81/5.88. Rule comment at `index.css:34-36`; the one outlined control (Infrastructure) uses `border-input` (twMerge overrides the variant's `border-border`); `border-border` only on decorative edges (header hairline, logo tile, menu panel). [04-contrast](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/04-ac4-contrast.png?raw=true) ```````` |
| AC5 dark mode / toggle | ✅ (scripts run; React wiring + keyboard by code reference) | Pre-paint {none, light, dark, system, invalid, empty, throws} × {OS dark, light}: default dark, `system` follows OS, no throw without `matchMedia`, stale `.dark` removed, script in `<head>` before the module. [05-prepaint](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/05-ac5-prepaint-matrix.png?raw=true) ````````` · `theme.js`: same key/default as `index.html` with comments both ways, storage fallbacks, `resolveTheme` table, `applyTheme`, live OS change + unsubscribe, legacy `addListener`. [06-themejs](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/06-ac5-themejs.png?raw=true) `````````` · Toggle: Radix radio menu, `aria-label` "Theme: …", persisted, OS listener re-applies via the `[pref, osDark]` effect. Keyboard (PM cond. c): brand now a `<button>`, all nav controls carry `focusRing` (`Navbar.jsx:7-8`), toggle `ring-2 ring-ring`, menu `data-[highlighted]` |
| AC6 dropdown-menu primitive | ✅ | Radix wrapper, 9 design §6 exports (component-only list), 5 forwardRef + displayName, `cn()`, no `slate|emerald|teal|zinc|gray-`, `data-[highlighted]`, `font-sans`; used by ThemeToggle. [03-static](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/03-ac3-ac6-ac7-static-checks.png?raw=true) ``````````` |
| AC7 scope guard | ✅ | 10 files all in Scope; no package/lock/vite change; no out-of-scope component, no FE-0b file; overlap with #68 empty; +382/−58 = 440 lines. [07-scope](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/07-ac7-scope-overlap.png?raw=true) ```````````` |
| AC8 visual | ✅ **fallback** (no browser/`node_modules`, so no screenshots) | CI build output + token diff + contrast table. [08-token-diff](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/08-ac8-token-diff.png?raw=true) ````````````` |
| AC9 docs | ✅ | Design approved `abfa173` 21:17 UTC before first code `dcf93c5` 21:34; README sentence; PR body has badge before/after, 19 woff2 / 583.69 kB (matches CI), veto notes. [09-pr-body](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/09-ac9-pr-body.png?raw=true) `````````````` · [10-readme](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/evidence/10-ac9-readme-design-order.png?raw=true) ``````````````` |

### PRD fit
Delivers the UI-1/UI-2 foundation as specified: self-hosted serif/sans, paper/ink tokens in both themes, an ink-blue accent kept apart from the red reserved for *unsupported*/*destructive* (principle 1), status chip pairs that clear AA, a keyboard-operable toggle with a visible focus ring, and links (`text-primary`) ≥ 7.6:1 (principle 3). No API, contract or dependency change.

### Findings
1. [nit] PR description says "+381/−58 = 439 changed lines" (AC7 line and Verification table); the diff and CI ownership check say +382/−58 = **440**. pm-lead can fix it in the final PR body.
2. [nit] `ThemeToggle.jsx:55` re-declares part of the focus ring instead of reusing Navbar's `focusRing`; it works (base `ring-ring` + twMerge keeps `ring-2`). Worth centralising when FE-0b/FE-3 add triggers.
3. [spec] AC2/AC3's conditional `dist/` checks stay unverifiable from agent sandboxes until OPS-H14 (backlog) adds the CI grep step. Not a blocker per the amended ACs.

No blocking findings.

### Missing tests
- No committed tests (FE-1 owns vitest this cycle). QA's pre-paint and `theme.js` checks ([checks/](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b279a301146c7c5492da57f0c4a30e160a3cdbe3/agents/reviews/FE-0/checks)) should become `src/lib/theme.test.js` after #68 merges (recorded follow-up), including the key/default drift guard between `index.html` and `theme.js`.
- Not covered anywhere yet: a component test that ThemeToggle re-applies `.dark` on an OS change in `system`, and that a cross-tab `storage` event updates the choice (reviewed statically only).

### Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM review (pm-lead) — round 1

**Verdict: APPROVE** · PR #69 head `ca76bea2c641f852c56c3cab47c081a5c99815eb` (checked unchanged since QA) · evidence commit `b279a30` · 2026-11-19

I read the ticket (amended ACs), my PM decision in `docs/design/FE-0.md`, Product PRD UI-1/UI-2 and §7, this QA report, every file in
`evidence/` (00–10, both `.png` and `.txt`), QA's own scripts in `checks/`, and the patches for `index.html`, `Navbar.jsx`,
`ThemeToggle.jsx`, `ui/dropdown-menu.jsx` and `lib/theme.js`.

**PRD fit.** UI-1/UI-2 stay ✅ (no status change, as AC9 requires). The theme serves principle 1 ("evidence first"): ink blue is the
only accent and red is kept for *unsupported* and *destructive*, so a link never looks like a failed claim. The three status chip pairs
are distinct in hue and lightness and all clear AA (7.2–8.8:1). Principle 3 ("one click to the source"): link text `text-primary` is
≥ 7.66:1 in both themes. The navbar is better for keyboard users than before (the brand is a real `<button>`, tabs have `aria-current`).

**Design conditions.**
1. Interim dark default: `DEFAULT_THEME = "dark"` in `theme.js` and the pre-paint script, comments both ways (05, 06). The FE-3 flip is FE-3 AC8. ✅
2. `--input` ≥ 3:1 (tightest 3.22, dark on card), `--border` decorative, rule comment at `index.css:34-36`, the one outlined control uses `border-input` (03, 04). ✅
3. `dist/` greps: CI asset list + source greps (01, 02). `.prose` built-CSS check moved to FE-3, CI grep step is OPS-H14 (Backlog). ✅
4. Badge removal shown before/after in the PR body (09). ✅
5. Split: no FE-0b file in the diff, 10 files all in Scope, no overlap with #68 (07). ✅
- a. Tests: QA re-ran its *own* scripts (pre-paint 14 + 2 cells, `theme.js` 42 checks), not the developer's. `theme.test.js` follow-up is in Backlog. ✅
- b. Font bundle: 19 woff2 / 583.69 kB, matches the CI log line by line (01). ✅
- c. Keyboard: allowed as a code reference without a browser. `focusRing` on brand, tabs and buttons (`Navbar.jsx:7-8`), Radix radio menu with `data-[highlighted]`, trigger ring via Button base + `ring-2`. ✅

**Evidence quality.** Every AC has a matching file, and each one proves its claim. AC8 used the fallback, as the ticket allows and as
it says: there are no rendered screenshots, so Mahesh judges the actual look at merge. I state that in the PR description, next to the
three reversible choices. Nothing marked "⚠ unverified" bears on an AC.

**Scope.** 440 lines, over the 400 target by 10%. That's acceptable: the split already took out ~130 lines, and I said in the design
decision that this doesn't reopen it. No dependency, contract or API change.

**QA findings.**
1. The line count in the PR body (439) → corrected to 440 in the PR description I'm raising.
2. The shared `focusRing` constant → added to `agents/tasks/FE-0b.md` Notes. FE-0b adds the next triggers (tooltip, popover), so that's where it belongs.
3. `[spec]` `dist/` checks unverifiable until OPS-H14 → already recorded in Backlog. No spec change.

The missing component test (ThemeToggle re-applies on an OS change; cross-tab `storage` event) is folded into the existing
`theme.test.js` Backlog line.

Raised: PR description rewritten with the Evidence section, marked ready for review, label `ready-to-merge`. Mahesh merges.
