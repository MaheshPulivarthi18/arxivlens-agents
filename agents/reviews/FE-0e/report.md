_Provenance: saved verbatim by the orchestrator from the qa-reviewer's PR #87 comment (https://github.com/MaheshPulivarthi18/ArxivLens/pull/87#issuecomment-7047301183); the QA harness could not write this file._

[qa-reviewer] QA report — FE-0e · PR #87 · round 1

**Verdict: FAIL**
**Reviewed commit:** `50ef4d50cb38281e9aeda9f7d287836a04f597ea` (CI ran on merge `bef7c5a` = head + main `c37d27c`) · **Date:** 2026-11-20
**Ticket:** `agents/tasks/FE-0e.md` · **PRD:** Product PRD §7; `docs/design/FE-0.md` (tokens, contrast appendix); `docs/design/FE-3.md` PM decision Q1(b)
**Evidence:** evidence files are committed at arxivlens-agents `9f1ddf2` (https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9f1ddf2ba5ac8548e65c02e79a6547974f110201/agents/reviews/FE-0e/evidence). The QA harness refused to write `report.md`; this comment is the full report, and the orchestrator saves it verbatim.

## Test results
| Check | Source | Result |
|---|---|---|
| Go / Python M0 / DB / Agent ownership | CI | success (evidence 00); local ownership rerun `Ownership OK for role=frontend (85 changed lines)` (evidence 04) |
| **Frontend (lint, test, build)** | CI job 136475098430 | **failure**: lint `Found 0 warnings and 0 errors`; vitest **4 failed / 20 passed**, all 4 in `src/test/tokens.test.js`; `npm run build` **never ran** (evidence 01) |
| Main baseline Frontend | CI job 136207398197 (`c37d27c`) | 0 warnings, 19/19 tests, `✓ built in 911ms` (evidence 02) |
| Ticket verification commands | not run locally: npm registry blocked | relies on CI (red) |
| `make eval` | n/a: no retrieval/answering change | — |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 guard test | ❌ | Exports `GUARDED_FILES` (the 4 files) and `PALETTE_CLASS` (identical to the AC regex), **but all 4 per-file tests fail in CI** with `ENOENT …/frontend/src/test/undefined` at `tokens.test.js:18:23` (evidence 01). Root cause (evidence 03): Vite 8.2.2's `assetImportMetaUrl` plugin (Vitest applies it to test files) rewrites `new URL(\`../${rel}\`, import.meta.url)` into `new URL(import.meta.glob("../*")[\`../${rel}\`], import.meta.url)`. `../*` doesn't descend into `components/`, so the lookup is `undefined` and the path becomes `src/test/undefined`. The guard *logic* is sound: under a plain-Node vitest **stub**, it passes 5/5 at head, fails base `c37d27c` with 8/7/4/2 hits (the ticket's counts) and catches 4 single-line mutants, one per file (evidence 05). A stub is also what hid this bug from the developer. |
| AC2 contrast | ✅ for every class in the diff · ⚠ [spec] for ui/ variants | QA-independent script (own CSS Color 4 HSL→sRGB, tokens parsed from head `src/index.css`, alpha surfaces composited): **49/49 in-file text, icon and non-text pairs pass in light and dark** (evidence 06). The lowest text pair is muted-foreground on muted, 5.84/5.91. The numbers match the developer's table to 2 decimals. Base rows confirm the problem being fixed: emerald-400 1.75:1 and red-300 1.67:1 in light. Still below 4.5 from ui/ variants rendered in these files: `ui/button` clinical 3.77/3.74 (both themes), and `ui/badge` arxiv 1.41 (light, Ingest supported panel) and 1.65 (light, Library). See finding 3. |
| AC3 no behaviour/copy/DOM change | ✅ diff · ❌ suite | With every `className="…"` blanked, all 4 components are byte-identical base↔head. No changed line outside `className=`; 5 files, all `frontend/` (evidence 04). The 19 pre-existing tests pass in CI, but the suite is red (AC1). |
| AC4 CI frontend green, lint ≤ main | ❌ | Job `failure` (evidence 00). Lint 0 = main 0 ✅; tests red; build not reached. |

Other checks:
- **Classes generate CSS** (frontend rule): all 14 classes added by the diff produce CSS with Tailwind 4.3.3 `compile()` against the real `tailwind.config.js`. Controls `bg-popoverx`/`text-supportedx-foreground` produce none (evidence 07). Caveat: the project builds with TW 3.4, and the CI build never ran.
- **twMerge 3.6.0**: the Library Badge resolves to `… border-border bg-supported text-supported-foreground` with every `emerald` class dropped, and View PDF to `text-primary hover:text-accent-foreground hover:bg-accent` (evidence 07).
- **Deviation** (error text `text-unsupported-foreground`, not `text-destructive`): justified. `destructive` as text on card is 7.01 light but **2.77 dark** (evidence 06). Accepted.
- Scope: no ticket, review or doc files; `ui/badge.jsx`, the ask-flow files and the theme default are untouched.

## PRD fit
The swaps deliver PRD §7 / FE-3 Q1(b): an OS-light visitor no longer gets ~1.7:1 emerald/red text in the ingest modal, library or toast. The PR still can't unblock FE-3b's flip, because its guard test is red and the build hasn't run.

## Findings
1. **[blocking]** `frontend/src/test/tokens.test.js:18`: the template-literal `new URL(\`../${rel}\`, import.meta.url)` breaks under real Vitest/Vite (4 × ENOENT). Build the path so that it doesn't match Vite's pattern. Options: `path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', rel)`; a non-literal arg (`new URL('../' + rel, import.meta.url)`); or `/* @vite-ignore */`. Then show a green CI Frontend job. Also show, with real Vitest (CI is the only one available), that the guard fails on a palette class, e.g. via a throwaway local commit that you don't push to this PR head.
2. **[blocking]** AC4 / DoD: the Frontend job is red, and `npm run build` didn't run at this head. Re-review needs `Tests … passed` (expect 24) and `✓ built in`.
3. **[spec]** (pm-lead) AC2 says "every text colour now used in the four files". `ui/button` `variant="clinical"` (Index Paper, Ask a question…, Replay DLQ) is 3.77/3.74 in both themes (pre-existing), and `ui/badge` `variant="arxiv"` is 1.41/1.65 in light. Both live in `ui/`, outside this ticket's Files scope (badge explicitly → FE-3a #86), so I don't count this against the developer. FE-3b's flip still ships the arxiv badge at ~1.4:1 unless FE-3a lands first, and the clinical button needs a follow-up task. Please spec it and clarify AC2's wording.
4. **[nit]** The guard reports only the first hit per line (`line.match` without `g`). A `matchAll` would make failure output complete when FE-3b extends the list.
5. **[spec]** (for FE-3b) The AC regex misses `fill-/stroke-/outline-/divide-/decoration-/ring-offset-`, other palettes (zinc, gray, sky, blue, rose…) and `text-white`/`bg-black`. None are present in these 4 files today.
6. **[nit]** Pre-existing: the inputs use `border-border`, while FE-0's rule says form controls use `border-input` (≥3:1). Suggest a follow-up.

## Missing tests
- A real-Vitest run proving the guard fails on a palette class (finding 1). The only negative evidence so far is the stub (evidence 05).

## Hand-off
FAIL → back to frontend-engineer (findings 1–2). Findings 3 and 5 go to pm-lead.

Evidence files (arxivlens-agents @ 9f1ddf2, plain URLs):
- 00 CI checks: https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9f1ddf2ba5ac8548e65c02e79a6547974f110201/agents/reviews/FE-0e/evidence/00-ci-checks.png?raw=true
- 01 Frontend job head: `` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9f1ddf2ba5ac8548e65c02e79a6547974f110201/agents/reviews/FE-0e/evidence/01-ac4-frontend-job-head.png?raw=true ``
- 02 main baseline: ``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9f1ddf2ba5ac8548e65c02e79a6547974f110201/agents/reviews/FE-0e/evidence/02-ac4-frontend-job-main-baseline.png?raw=true ```
- 03 root cause: ```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9f1ddf2ba5ac8548e65c02e79a6547974f110201/agents/reviews/FE-0e/evidence/03-ac1-root-cause-vite-url-rewrite.png?raw=true ````
- 04 AC3/scope: ````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9f1ddf2ba5ac8548e65c02e79a6547974f110201/agents/reviews/FE-0e/evidence/04-ac3-scope-class-strings-only.png?raw=true `````
- 05 guard logic (stub): `````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9f1ddf2ba5ac8548e65c02e79a6547974f110201/agents/reviews/FE-0e/evidence/05-ac1-guard-logic-stub.png?raw=true ``````
- 06 AC2 contrast: ``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9f1ddf2ba5ac8548e65c02e79a6547974f110201/agents/reviews/FE-0e/evidence/06-ac2-contrast.png?raw=true ```````
- 07 classes/twMerge: ```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9f1ddf2ba5ac8548e65c02e79a6547974f110201/agents/reviews/FE-0e/evidence/07-classes-generate-css.png?raw=true ````````
- 08 harness sources: ````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/9f1ddf2ba5ac8548e65c02e79a6547974f110201/agents/reviews/FE-0e/evidence/08-qa-harness-sources.png?raw=true `````````

Not produced: light/dark screenshots of the four screens. That needs the app's node_modules (registry blocked), so contrast is computed from the tokens.


---
_Generated by [Claude Code](https://claude.ai/code)_
