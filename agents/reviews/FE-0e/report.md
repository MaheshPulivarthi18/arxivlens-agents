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


---

## Round 2

[qa-reviewer] QA report — FE-0e · PR #87 · round 2

**Verdict: PASS**
**Reviewed commit:** `27953fdcee2fbc8ece4480b0ad553e5dc56462db` (CI ran on merge `dd2d0e7` = head + main `c37d27c`; main hasn't moved since) · **Date:** 2026-11-21 · **Previous round:** r1 FAIL at `50ef4d5`
**Evidence:** arxivlens-agents `175d597`, files 09–13 in https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/175d59748128721936c0892468f74eaccfd5b8ac/agents/reviews/FE-0e/evidence. Files 00–08 from r1 are still valid for AC2 and AC3, because no component, `index.css` or `tailwind.config.js` changed (evidence 11).

## Test results
| Check | Source | Result |
|---|---|---|
| DB / Go / Agent ownership / Python M0 | CI, head `27953fd` | all `completed success` (evidence 09) |
| **Frontend (lint, test, build)** | CI job 136486858137 | **success**: `Found 0 warnings and 0 errors.` · `✓ src/test/tokens.test.js (5 tests)` · `Test Files 4 passed (4)` · `Tests 24 passed (24)` · `✓ built in 1.07s` (evidence 10) |
| Ownership (local rerun) | `ownership-check.sh origin/main agent/frontend/FE-0e` | `Ownership OK for role=frontend (92 changed lines)` (evidence 11) |
| Ticket verification commands | not run locally: npm registry blocked (`npm view vitest` timed out); no vite or vitest in the sandbox | relies on CI (green) |
| `make eval` | n/a: no retrieval or answering change | — |

## Rework checklist (r1 findings, checked independently)
| r1 finding | Status | Evidence |
|---|---|---|
| 1 [blocking] Vite URL rewrite → ENOENT | ✅ fixed | The r1→r2 diff touches only `frontend/src/test/tokens.test.js` (+12/−5). `read()` now uses `path.join(path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..'), rel)`. The file has 0 `new URL(` occurrences (evidence 11, 12). In real Vitest 4.1.12 on CI, `tokens.test.js` runs **5 tests, all pass** (1 pattern test + 4 per-file tests). Each per-file test asserts `lines.length > 1` before its `toEqual([])`, so passing proves the real files were read under the Vite transform and the pass isn't vacuous (evidence 10). |
| 1 (cont.) negative proof with real Vitest | ⚠ partly: real-Vitest evidence plus a plain-Node mutant run | **Real Vitest (CI):** the self-test `pattern catches palette classes, with and without variants` passes, so under Vitest `PALETTE_CLASS` matches `text-emerald-400`, `hover:bg-emerald-500/10`, `focus:border-red-500`, `dark:md:ring-slate-700` and `shadow-cyan-900`, and rejects the token classes. **No real-Vitest run has failed on a palette class**: CI triggers only on `pull_request` and pushes to `main`, and npm is blocked here. **Plain Node, not Vitest** (head `tokens.test.js` imported unchanged, with a vitest API stub and no Vite transform; evidence 12, sources 13): 5/5 pass at head. Base `c37d27c` components fail all 4 per-file tests. Each of 4 single-line mutants (one per file: `hover:text-emerald-300`, `border-emerald-500/40`, `text-amber-400`, `bg-red-500/10`) fails exactly the right test with the right `file:line`. Residual risk: the only Vite-sensitive part, path resolution, is proven by the CI pass. The rest is plain `String.prototype.matchAll` plus `toEqual`, so I don't block on this. |
| 2 [blocking] Frontend job red, build not run | ✅ fixed | Job 136486858137 `success`. Lint 0 warnings = main baseline 0 (r1 evidence 02). Tests 24 = 19 pre-existing + 5 new. Build `✓ built in 1.07s` (evidence 10). |
| 4 [nit] first hit per line only | ✅ fixed | `PALETTE_CLASS_ALL = new RegExp(PALETTE_CLASS.source, 'g')` with `line.matchAll`. A mutant with two palette classes on one line (`IngestModal.jsx:121` `bg-red-500/10 border border-red-500/30`) reports **both** `:121 bg-red-5` and `:121 border-red-5` (evidence 12, plain Node). |
| 3 [spec], 5 [spec], 6 [nit] | open, for pm-lead / follow-up | Not in this rework's scope, as stated in r1. |

## Acceptance criteria (round 2)
| AC | Met? | Evidence |
|---|---|---|
| AC1 guard test | ✅ | `GUARDED_FILES` (4 files, exported array) and `PALETTE_CLASS` are unchanged from r1 and identical to the AC regex. Green in real Vitest (evidence 10). Detects palette classes (plain Node mutants, evidence 12). |
| AC2 contrast | ✅ for every class in the diff (r1 evidence 06 still applies: no component or `index.css` change since r1, evidence 11) · [spec] finding 3 still open for `ui/` variants | r1 06, r2 11 |
| AC3 no behaviour/copy/DOM change; existing tests pass | ✅ | Components are byte-identical to r1, where every `className` was blanked and the files compared equal to base (r1 evidence 04). The 19 pre-existing tests pass in CI, and the whole suite is 24/24 (evidence 10, 11). |
| AC4 CI frontend green, lint ≤ main | ✅ | evidence 09, 10 |

Scope: PR = 4 components + `src/test/tokens.test.js`, all under `frontend/`. No ticket, review or doc files. `ui/badge.jsx`, the ask-flow files and the theme default are untouched (evidence 11).

## PRD fit
This delivers Product PRD §7 and FE-3 Q1(b): an OS-light visitor no longer sees ~1.7:1 emerald/red text on the ingest, infrastructure, library and toast screens, and a green guard keeps the palette classes from coming back. FE-3b can extend `GUARDED_FILES`. FE-3b's theme flip still depends on FE-3a for the `arxiv` badge (finding 3).

## Findings (round 2)
1. **[nit]** No real-Vitest run has failed on a palette class (see the checklist). The guard's negative behaviour is shown in plain Node only. Optional: when FE-3b extends the list, look at its CI run on any red step.
2. **[spec]** (pm-lead, carried from r1 #3) AC2 wording vs `ui/button` `clinical` (3.77/3.74 in both themes) and `ui/badge` `arxiv` (1.41/1.65 in light). Needs a follow-up task, and FE-3a must land before FE-3b's flip.
3. **[spec]** (pm-lead / FE-3b, carried from r1 #5) the regex doesn't cover `fill-/stroke-/outline-/divide-/decoration-/ring-offset-`, other palettes, or `text-white`/`bg-black`.
4. **[nit]** (carried from r1 #6) inputs use `border-border` instead of `border-input`. Follow-up.

No blocking findings.

## Hand-off
PASS → pm-lead for final review. Spec items 2–3 go to pm-lead.

Evidence (round 2, arxivlens-agents @ 175d597):
- 09 CI checks at head: https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/175d59748128721936c0892468f74eaccfd5b8ac/agents/reviews/FE-0e/evidence/09-r2-ci-checks.png?raw=true
- 10 Frontend job green (lint/test/build): https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/175d59748128721936c0892468f74eaccfd5b8ac/agents/reviews/FE-0e/evidence/10-r2-frontend-job-green.png?raw=true
- 11 r1→r2 diff, scope, ownership: https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/175d59748128721936c0892468f74eaccfd5b8ac/agents/reviews/FE-0e/evidence/11-r2-diff-scope.png?raw=true
- 12 guard negative proof + matchAll (plain Node, not Vitest): https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/175d59748128721936c0892468f74eaccfd5b8ac/agents/reviews/FE-0e/evidence/12-r2-guard-negative-plain-node.png?raw=true
- 13 r2 QA harness sources: https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/175d59748128721936c0892468f74eaccfd5b8ac/agents/reviews/FE-0e/evidence/13-r2-qa-harness-sources.png?raw=true

Not produced: light/dark screenshots of the four screens. They need the app's node_modules, and the registry is blocked, so contrast stays computed from the tokens (r1 evidence 06).

---

## PM final review (pm-lead)

**Reviewed commit:** `27953fdcee2fbc8ece4480b0ad553e5dc56462db` (QA r2 PASS on the same head; CI on merge `dd2d0e7` = head + main `c37d27c`, main unchanged) · **Date:** 2026-11-20 (UTC) · **Reviewer:** pm-lead
**Inputs:** `agents/tasks/FE-0e.md`; `docs/design/FE-0.md` (tokens, `border-input` rule, contrast appendix); `docs/design/FE-3.md` PM decision Q1(b); PRD UI-2/UI-3/UI-4; `gh api …/pulls/87/files` (5 files, +69/−23, all `frontend/`); QA r1 + r2 above.

### Evidence check (every file opened)
| File | Proves | Accepted? |
|---|---|---|
| 00, 01, 02 (r1) | r1 head red: Frontend job 4 failed in `tokens.test.js` (ENOENT `src/test/undefined`), build not run; main baseline 0 warnings, 19 tests, built | yes, as the r1 FAIL record and the lint/test baseline |
| 03 (r1) | root cause: Vite 8.2.2 `assetImportMetaUrl` rewrites a template-literal `new URL(…, import.meta.url)` into an `import.meta.glob('../*')` lookup | yes |
| 04 (r1) | AC3: the 4 components are byte-identical to base with every `className` blanked; 0 non-`className` changed lines; 5 files | yes (components unchanged since, evidence 11) |
| 05 (r1) | guard logic: base fails 8/7/4/2 (= ticket counts), 4 single-line mutants caught (stub) | yes, as logic evidence |
| 06 (r1) | AC2: 49/49 in-file text/icon/non-text pairs ≥ min in light and dark (lowest text 5.84/5.91); base emerald-400 1.75, red-300 1.67 in light; `ui/` variants listed below min | yes for AC2 as clarified. The pgvector node outline `border-primary/40` (2.06/2.32, min 1.0) is a decorative border: the node is identified by its `text-primary` label (9.09/7.65), so 1.4.11 doesn't apply |
| 07 (r1) | all 14 new classes generate CSS against `tailwind.config.js` (controls `bg-popoverx` → none); twMerge drops the Badge's emerald classes | yes |
| 08, 13 | QA harness sources (r1, r2) | yes |
| 09 (r2) | 5/5 check runs `success` on head `27953fd` | yes (re-checked via REST today: same 5 job IDs, all success) |
| 10 (r2) | AC1/AC3/AC4: oxlint `Found 0 warnings and 0 errors.`, `✓ src/test/tokens.test.js (5 tests)`, `Tests 24 passed (24)`, `✓ built in 1.07s` | yes |
| 11 (r2) | r1→r2 diff = `tokens.test.js` only (+12/−5), uses `fileURLToPath` + `path`; components/`index.css`/`tailwind.config.js` untouched; ownership OK (92 lines) | yes |
| 12 (r2) | head test file under plain Node: 5/5 at head, base 4 fail, 4 single-class mutants + 1 two-class mutant (both hits reported via `matchAll`) | yes, with QA's caveat: not real Vitest |

### Judgement
1. **PRD fit.** UI-2 (library), UI-3 (ingest modal) and UI-4 (infrastructure modal) stay ✅ and become readable for an OS-light visitor: the ~1.7:1 emerald/red text is gone, every class-string colour is ≥ 4.5:1 (text) / ≥ 3:1 (icons) in both themes. This is exactly what FE-3 PM decision Q1(b) needed before FE-3b flips the default.
2. **Scope.** Right size: 4 components (class strings only) + the guard, 92 changed lines. Two departures from the mapping guide, both accepted: error text uses `text-unsupported-foreground` (dark `destructive` as text is 2.77:1, evidence 06), and the pre-existing `text-muted-foreground/60` "(vN)" became `text-muted-foreground` (2.72 light before, inside AC2's "every text colour"). Nothing missing: `ui/badge.jsx`, the ask-flow files, sonner and the theme default are untouched as the ticket required.
3. **AC coverage.** AC1–AC4 all have CI or computed evidence. The one ⚠ (no real-Vitest run failing on a palette class) doesn't matter for the AC: the only Vite-sensitive step is path resolution, and the CI pass with `lines.length > 1` proves it; the matching is plain `matchAll` + `toEqual`, shown failing on mutants in Node. No "⚠ unverified" left on anything that affects users.
4. **Docs.** No README/CONTRIBUTING change needed (no behaviour or command change). No PRD status change (UI-2/3/4 already ✅; there is no theme row). Light/dark screenshots were not produced (registry blocked); contrast is computed from the tokens, which is what AC2 asks for.

### QA `[spec]` findings (pm-lead decisions)
- **(a) AC2 wording vs `ui/` variants** (r1 #3, r2 #2): AC2 now reads "every text colour **set by a class string in** the four files"; `ui/` variant colours are reported, not owed. `ui/badge` `arxiv`: FE-3a #86 (Ready to merge, `fa92c30`) retargets it to opaque `bg-secondary text-secondary-foreground` = **13.73:1 light / 10.99:1 dark** on any surface (pm-lead calc with the FE-0 appendix functions on `src/index.css`), so the 1.41/1.65 light cases go away when #86 merges. FE-3b's flip already waits on FE-3a #86 **merged** (FE-3b `Depends on`; confirmed). `ui/button` `clinical` (3.77/3.74, both themes, pre-existing, also `HeroSearch.jsx:75`): new task **[FE-0f](../../tasks/FE-0f.md)** (frontend, P1, Ready, needs Jira story) retargets the variant in `button.jsx` to `bg-primary text-primary-foreground` (8.73/8.11), independent of every open PR.
- **(b) Guard regex gaps** (r1 #5, r2 #3): folded into **FE-3b AC2** — `ring-offset/outline/divide/decoration/fill/stroke/placeholder/caret`, all Tailwind palettes, and `white`/`black` on every utility except `shadow` (`Toast.jsx`'s `shadow-black/80` is legitimate; pm-lead ran the widened pattern on #87's head: 0 other hits).
- **(c) Inputs `border-border` vs `border-input`** (r1 #6, r2 #4): Backlog (frontend, P3), per FE-0 design's rule for form controls.

**PM verdict: APPROVE.** PR #87 description rewritten from `agents/templates/pr.md` with the Evidence section (one row per AC, commit-pinned images: `9f1ddf2` for 00–08, `175d597` for 09–13), CI results, QA r1 FAIL → r2 PASS and this verdict; marked ready for review. Mahesh reviews and merges. Jira KAN-91 → Ready to merge is left to the orchestrator.
