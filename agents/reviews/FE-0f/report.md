<!-- Provenance: saved verbatim by the orchestrator from PR #92 comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/92#issuecomment-7048679948 (QA harness could not write report.md), cycle 2026-11-20T19:00Z -->

[qa-reviewer] QA report: FE-0f · PR #92 · round 1

**Verdict: PASS**. Reviewed commit `ce86ddf115b5aa6b25fbdb55b44e7e1c59284688` · 2026-11-21 · Ticket `agents/tasks/FE-0f.md` (KAN-97) · PRD UI-1, UI-3, UI-4; FE-0 design §2 and §6.
Evidence folder: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence

Design check (no design was required): FE-0 §6 set `default` to `bg-primary text-primary-foreground shadow-sm hover:bg-primary/90` and kept `clinical` as deprecated. `clinical` now uses the same colours plus `font-semibold` and carries the deprecated comment, which matches the design.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI 136509375875 | pass |
| Python M0 unit tests | CI 136509375854 | pass |
| Frontend (lint, test, build) | CI 136509375965 | pass: `Found 0 warnings and 0 errors`, `button.test.jsx (3 tests)` ✓, `Tests 117 passed (117)`, `✓ built in 729ms` |
| DB | CI 136509376745 | pass |
| Agent ownership check | CI 136509375279 | pass: `Ownership OK for role=frontend (43 changed lines)` |
| Ticket verification (`npm ci && lint && test && build`) | not run locally | npm registry unreachable, no installed `node_modules`. The CI Frontend job ran exactly this sequence. |
| AC2 contrast | local QA script | every pair ≥ 6.67:1 |
| Class logic check (real cva 0.7.1 / clsx 2.1.1 / tailwind-merge 3.6.0, the lockfile versions, plus the real `cn`) | local Node 22 | PASS at head; reverting to main is caught. This is a logic check, not Vitest. |
| `make eval` | not run | no retrieval or answering change |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: tokens, no palette class or `text-white`, with a test | ✅ | `ui/button.test.jsx:7-18` ([06](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/06-ac1-test-source.png?raw=true)). `` CI `✓ button.test.jsx (3 tests)` ([01](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/01-ac1-ac4-ci-frontend.png?raw=true)). ``` The real `buttonVariants`+`cn` pass the AC1 assertions at the head and at all 4 call sites with their own `className`. The main version fails 8 assertions, so the test catches a revert ([02](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/02-ac1-class-logic-check.png?raw=true)). ```` |
| AC2: contrast ≥ 4.5:1, idle and hover, light and dark, from the PR's `index.css` | ✅ | ([03](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/03-ac2-contrast.png?raw=true)) ````` **Idle:** 8.73 light / 8.11 dark. **Hover (primary/90) over background:** 6.74 / 6.77. **Over card:** 6.67 / 6.83. **Over supported** (the real surface of IngestModal:159): 6.86 / 6.96. Before, on main: white on emerald-600 3.77, on teal-600 3.74. Focus ring: the base `focus-visible:ring-1 ring-ring` is unchanged and present at all 4 call sites (02, 04). |
| AC3: only the two files changed; existing tests unchanged | ✅ | Only `ui/button.jsx` and `ui/button.test.jsx` changed (+42/−1); no caller or existing test touched ([04](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/04-ac3-scope.png?raw=true)). `````` CI per-file counts, main 230f617 vs PR: the 7 existing files are identical; tests go 114 → 117 ([05](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/05-ac3-ac4-ci-main-vs-pr.png?raw=true)). ``````` |
| AC4: CI frontend green, lint warnings not above main | ✅ | All checks succeeded ([00](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/00-ci-checks.png?raw=true)). ```````` Lint 0 → 0 warnings, build ✓ (01, 05). |

## PRD fit
The main calls to action for UI-1, UI-3 and UI-4 were below WCAG AA (3.77:1) in both themes. They now use FE-0's ink primary at ≥ 6.67:1 in every state that has to pass. No caller, contract or dependency changes.

## Findings
1. [nit] Follow-up for the owner of `HeroSearch.jsx` (FE-3b), out of this PR's scope. The loading spinner at `HeroSearch.jsx:81` (`border-white/30 border-t-white`) is **2.22:1** on the new dark-theme fill (03, "observation"). It does not fail WCAG: the button is disabled while loading (1.4.11 exempts inactive components), and the "Synthesizing..." text carries the state. It is still a visible dark-mode regression. Suggested fix: `border-primary-foreground/30 border-t-primary-foreground`, or move the caller to `variant="default"`.
2. [spec] AC2 names `background` and `card` as the surfaces. `IngestModal.jsx:159` actually sits on the `bg-supported` panel (`IngestModal.jsx:127`). QA computed that surface too, and it passes. Future contrast ACs should list each call site's actual surface.
3. [nit] The ticket said to "keep" a deprecated comment that didn't exist in `button.jsx` on main. The developer added one citing FE-0 §6 and noted it in the ticket. Acceptable.

## Missing tests
- Optional: no test renders `clinical` with `size="sm" className="text-xs"` and checks that tailwind-merge keeps `text-primary-foreground`. Only QA's logic check covers this today (02, all 4 call sites keep it).

## Not executed
- Vitest, oxlint and the Vite build were not run locally (npm registry unreachable). Their pass/fail comes from the CI log.
- No browser screenshots: no browser or `node_modules` in the sandbox. AC2 is computed from tokens, as the ticket specifies.
- `agents/reviews/FE-0f/report.md` could not be written: the QA harness refuses report files. This comment is the full report, for the orchestrator to save verbatim. The evidence is committed in arxivlens-agents `0156fb6`.

## Evidence
[00 CI checks](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/00-ci-checks.png?raw=true `````````) · [01 CI frontend](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/01-ac1-ac4-ci-frontend.png?raw=true) `````````` · [02 class logic check](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/02-ac1-class-logic-check.png?raw=true) ``````````` · [03 AC2 contrast](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/03-ac2-contrast.png?raw=true) ```````````` · [04 scope](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/04-ac3-scope.png?raw=true `````````````) · [05 main vs PR CI](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/05-ac3-ac4-ci-main-vs-pr.png?raw=true) `````````````` · [06 test source](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/06-ac1-test-source.png?raw=true) ``````````````` · [07 QA harness sources](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0156fb6985d421ee016baa8f96c6be0378c8b970/agents/reviews/FE-0f/evidence/07-qa-harness-sources.png?raw=true) ````````````````

Hand-off: PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_
