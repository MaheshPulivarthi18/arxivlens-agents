[qa-reviewer] **QA report: FE-0h · PR #101 · round 1: PASS**

**Reviewed commit:** `2c8452727b2273d057b80ffec36beef2adc3634e` · 2026-11-21 · Ticket `agents/tasks/FE-0h.md` · Evidence: [agents/reviews/FE-0h/evidence @ bdea793](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence)

Scope: `pulls/101/files` is exactly the 4 Scope files, all under `frontend/`, and the ownership check is green. No overlap with open frontend PRs #91, #92 or #95.

## Test results
| Check | Source | Result |
|---|---|---|
| Go / Python M0 / DB / Agent ownership | CI | all success |
| Frontend (lint, test, build) | CI job 136652677439 (merge of 2c84527 into main 230f617) | lint `0 warnings and 0 errors`; `Test Files 8 passed (8)`, `Tests 118 passed (118)` incl. `src/test/controls.test.js (4 tests)`; `built in 922ms`. Main baseline 7 / 114 |
| Ticket verification | local, partial | grep and diff run locally. npm ci/lint/test/build not run locally: npm registry unreachable, so CI is the source of truth. The test ran locally under a Vitest shim as a logic check only |
| make eval | n/a | not a retrieval/answering change |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | [01-ac1-diff](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/01-ac1-diff.png?raw=true ``): one changed line per component (IngestModal.jsx:82, PapersLibrary.jsx:53), `border-border` → `border-input`. The other `border-border` uses are decorative and out of scope |
| AC2 | ✅ | [02-ac2-contrast](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/02-ac2-contrast.png?raw=true): ``` QA computation from index.css at head. IngestModal (fill background / parent card): light 3.30 / 3.50, dark 3.48 / 3.23. PapersLibrary (fill card / parent background): light 3.50 / 3.30, dark 3.23 / 3.48. All >= 3:1 (pre-PR `--border` 1.31-1.46). Render cross-check [05-ac2-render-probe](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/05-ac2-render-probe.png?raw=true): ```` Tailwind compile gives `.border-input { border-color: hsl(var(--input)); }`, and Chromium measured a 1px border at 3.31/3.51 (light) and 3.48/3.22 (dark). Screenshots [05a light](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/05a-render-light.png?raw=true), ````` [05b dark](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/05b-render-dark.png?raw=true) `````` |
| AC3 | ✅ | [03-ac3-test](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/03-ac3-test.png?raw=true ```````): node:path + fileURLToPath, 0 `new URL(`, whole-token regex (`/80` and variants count as hits), per-file non-empty assertion, fails closed on a non-static className |
| AC4 | ✅ | [04-ac4-mutants-summary](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/04-ac4-mutants-summary.png?raw=true) ```````` (full: [04b](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/04b-ac4-mutants-full.png?raw=true)): ````````` control 4/4 (= CI). M1/M2 (revert either swap) FAIL, naming the file. M3 `border-border/80`, M4 token dropped, M5 `focus:border-border` and M8 template-literal className are killed. M6 Toast.jsx is killed by `no <input found`. M7 (Toast.jsx without that assertion) passes vacuously. Mutants ran only in throwaway copies, never on the PR |
| AC5 | ✅ | [06-ac5-readme](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/06-ac5-readme.png?raw=true): `````````` README:14 `src/**/*.test.{js,jsx}` = vite.config.js:20 include. One line changed |
| AC6 | ✅ | [07-ac6-ci-frontend](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/07-ac6-ci-frontend.png?raw=true): ``````````` job 136652677439, lint 0 warnings, 8 files / 118 tests vs main's 7 / 114, build OK. [00-ci-checks](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/00-ci-checks.png?raw=true): ```````````` all 5 checks success |

Harness source: [08-harness-source](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/bdea79380b0b25d76da87c4da68a06b5ff8192c7/agents/reviews/FE-0h/evidence/08-harness-source.png?raw=true). ````````````` Screenshots: the real pages couldn't be built because npm is blocked (no Radix, lucide or Vite). 05a/05b are real Chromium renders of the head's exact class strings on their real surfaces, with CSS compiled from the real Tailwind config and tokens. They are not mock images, but they are not the full page either.

## PRD fit
This delivers the FE-0 rule that form controls use `--input` at >= 3:1 (WCAG 1.4.11). Both inputs move from 1.31-1.46:1 to >= 3.23:1 in both themes, and a guard test pins the change. No contract is touched.

## Findings
1. [nit] The PR body says AC6 is unchecked and "CI Frontend job | pending", but the job is green. pm-lead refreshes the body when raising the PR.
2. [spec] Ticket PRD ref "Product PRD §7 (readable, accessible UI)": PRD §7 has no accessibility principle. The real anchor is docs/design/FE-0.md lines 107-108 and 120 (for pm-lead).

## Missing tests
- None blocking. Outside scope: the guard covers only `<input` in these two files, not HeroSearch (FE-3b), future `<textarea`/`<select` elements or new components. A repo-wide control scan could be a follow-up.

## Hand-off
PASS → pm-lead final review.

_Note: the QA harness refused to write `agents/reviews/FE-0h/report.md` ("subagents return findings as text"). This comment is the full report, and the orchestrator saves it verbatim._


---
_Generated by [Claude Code](https://claude.ai/code)_


_Provenance: saved verbatim by the orchestrator from the QA PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/101#issuecomment-7053940589 (QA harness refused to write report.md)._
