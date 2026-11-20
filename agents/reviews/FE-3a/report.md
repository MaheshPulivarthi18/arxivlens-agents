<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/86#issuecomment-7041340032; QA's harness could not write report.md (sprint.md Step 5). -->

[qa-reviewer] QA round 1 for FE-3a: **FAIL**

_Provenance: the qa-reviewer harness refused to write `agents/reviews/FE-3a/report.md`, so this comment is the full report. The orchestrator should save it there verbatim. The evidence pack is committed at arxivlens-agents `23e8eeb`._

# QA report: FE-3a · PR #86 · round 1

**Verdict:** FAIL
**Reviewed commit:** `e90de796a01dd22f59b846c4883bb2ceb62745de` (base `c37d27c`) · **Date:** 2026-11-20
**Ticket:** `agents/tasks/FE-3a.md` · **PRD:** Product PRD UI-1, QA-4, QA-5, §7 (principles 1–2); ADR-0003, ADR-0014 · **Design:** `docs/design/FE-3.md` (Approved with changes, incl. PM decision)
**Evidence:** [agents/reviews/FE-3a/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence)

**Reason:** The product change is correct. CI is green, and a QA browser run of the real `App.jsx` passes 44 of 44 App-level checks. But the App-level **tests** that AC1, AC2, AC4 and AC6 require are not in the PR: `App.test.jsx` is absent and AC4 has no test at all. The ticket ACs were never amended to move these tests to a follow-up, so pm-lead has to decide before the developer can act (finding 1).

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136324730177 | success ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/00-ci-checks.png?raw=true)) `` |
| Python M0 unit tests | CI job 136324730414 | success |
| DB (migrate twice, HNSW plan + recall) | CI job 136324729924 | success |
| Frontend (lint, test, build) | CI job 136324730223 | success. oxlint: "Found 0 warnings and 0 errors." vitest: **4 files** passed, 66 tests (citations 35, ReferencesStack 11, SynthesisView 15, HeroSearch 5). `vite build`: ok ([01](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/01-ac7-frontend-job-head.png?raw=true)). ``` Main `c37d27c` baseline: 0 warnings ([02](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/02-ac7-frontend-job-main-baseline.png?raw=true)) ```` |
| Agent ownership check | CI job 136324729966 + local script | success. Local run: "Ownership OK for role=frontend (496 changed lines)" ([03](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/03-scope-diffstat.png?raw=true)) ````` |
| Ticket verification (`npm ci && lint && test && build`) | not run locally: npm registry unreachable from the sandbox | relied on CI (above) |
| QA browser run of the real `App.jsx` in headless Chrome; `/v1/ask` and `/v1/papers/discover` answered with the PR's own `src/test/fixtures.js` | local QA harness (not CI) | **44 PASS, 0 FAIL** ([05](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/05-ac1-ac6-qa-browser-app-run.png?raw=true)). `````` Negative control: with the old hero sentence restored, the 6 whole-tree `/verified/i` checks fail as they should ([06](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/06-ac1-negative-control.png?raw=true)). ``````` Harness sources: ([07](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/07-qa-harness-sources.png?raw=true)) ```````` |
| `make eval` | n/a | frontend-only change, nothing in retrieval or answering |

**Harness limits:**
- **Stubbed** because they can't be installed offline:
  - `lucide-react`: icons render as circles.
  - `class-variance-authority`: replaced by a 10-line stand-in with the same variant lookup.
  - Radix primitives: `Slot`, a closed `Dialog`, `Tabs` and `DropdownMenu`.
- **Real code from the PR:** `App.jsx`, `HeroSearch`, `SynthesisView`, `ReferencesStack`, `Toast`, `Navbar`, `ui/badge|card|button`, `lib/citations.js` and `lib/utils.js`, running on real `react-dom` 19.2.8, `clsx` and `tailwind-merge`.
- **CSS:** built from the PR's `index.css` and `tailwind.config.js` with Tailwind 4.3.3 in v3-compat `@config` mode. `@tailwindcss/typography` is not installed, but FE-3a doesn't use `prose`. Fonts aren't loaded.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: A and C refusals show a `role=status` "No answer shown" panel with the approved copy, the stack heading, the chips and no "0.0%". **App-level whole-tree `/verified/i` test** | ⚠ behaviour ✅, App-level test ❌ | Component tests in CI ([08](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/08-ac1-ac6-component-test-names.png?raw=true)): ````````` `SynthesisView › refusal %s shows its copy in a "No answer shown" status panel` (A/B/C, exact copy, `getByRole('status', {name})`), `ReferencesStack › refusal A: heading…, "Unsupported · 31.0%" and "Not checked"…, no "0.0%"` and `› refusal C: every chip reads "Not checked"`. The hero sentence is replaced with the PM's exact text ([03](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/03-scope-diffstat.png?raw=true)). `````````` In the real App the whole tree has no `/verified/i` for A (dark and light), B, C and the mixed answer ([05](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/05-ac1-ac6-qa-browser-app-run.png?raw=true)). ``````````` Screenshots: [10 A dark](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/10-screenshot-refusalA-dark.png?raw=true), ```````````` [11 A light](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/11-screenshot-refusalA-light.png?raw=true), ````````````` [13 C](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/13-screenshot-refusalC-dark.png?raw=true). `````````````` **No App-level test in the PR** ([04](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/04-ac1-ac2-ac4-ac6-app-tests-absent.png?raw=true)). ``````````````` See finding 1 |
| AC2: B copy. **App-level test** with `fetch` stubbed: no toast with a message, no `role=alert`, heading visible, `fetch` called once | ⚠ behaviour ✅, App-level test ❌ | B copy, `role=status` and no alert are covered by `SynthesisView › refusal B …` in CI. In the real App a MutationObserver saw no toast over 3.5 s, there was no `role=alert`, the "Retrieved passages" heading was visible, and `/v1/ask` was called once with `quick: true` ([05](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/05-ac1-ac6-qa-browser-app-run.png?raw=true), ```````````````` [12](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/12-screenshot-refusalB-dark.png?raw=true)). ````````````````` The App-level test is absent. See finding 1 |
| AC3: `citations.test.js` covers rows 1–5, `/verified/i` never appears, `\bSupported\b` only for kind supported; `mixedAnswer` shows the three chips | ✅ | `citations.test.js` (35 tests, CI) covers all of these: `status: supported` with `supported: false` → Unsupported; `partially_supported`, `contradicted` and `"bogus"` → Unsupported; legacy score 0 in a refusal → Not checked; per-row `/verified/i` and `\bSupported\b` asserts; no method names in tooltips. Also `ReferencesStack › answer mode: chips…` and `SynthesisView › Export Note…` on `mixedAnswer`. Real App: [16](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/16-screenshot-mixedAnswer-dark.png?raw=true), `````````````````` [17](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/17-screenshot-mixedAnswer-light.png?raw=true). ``````````````````` I re-derived the rule from `citations.js` and it matches design §1 rows 1–5 in order |
| AC4: early refusal renders as today, with **explicit asserts** (banner, echoed question in `code`, discover button POSTs `{query}`, no cards, no "Clinical Literature Synthesis") | ⚠ behaviour ✅, test ❌ | **No test in the PR at all.** The `earlyRefusal` fixture is defined but no test uses it ([04](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/04-ac1-ac2-ac4-ac6-app-tests-absent.png?raw=true)). ```````````````````` The App.jsx diff is one prop line, so the code path is unchanged. QA's browser run confirms every listed assert, including the discover POST body `{"query":"how are citations checked"}` ([05](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/05-ac1-ac6-qa-browser-app-run.png?raw=true), ````````````````````` [15](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/15-screenshot-earlyRefusal-dark.png?raw=true)). `````````````````````` See finding 1 |
| AC5: no "PostgreSQL pgvector Verified"; export uses `## References` and chip-text suffixes; Copy and Export absent on a refusal; footer "n of m citations supported" | ✅ | CI tests: `SynthesisView › no "PostgreSQL pgvector Verified" in answer or refusal mode`, `› Export Note writes "## References"…` (reads `onCopy.mock.calls[0][0]`), `› refusal mode hides Copy Synthesis and Export Note`, `› answer-mode footer… "1 of 3 citations supported"`, and `citations.test.js › markdownNote`. In the real App the exported markdown (captured from the clipboard) is printed in [05](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/05-ac1-ac6-qa-browser-app-run.png?raw=true), ``````````````````````` with `• Unsupported · 12.0%` and `• Not checked` |
| AC6: panel is `role=status` and Tab-reachable via "Read the n retrieved passage(s)"; the link focuses `#references-heading`; zero citations → no link; two-stage rows (**App tests**) | ⚠ behaviour ✅, App tests ❌ | CI tests: `SynthesisView › refusal panel is in the tab order through its passages link` and `› a refusal with zero citations still renders the panel, without a link`; the heading's `id` and `tabindex=-1` are checked in `ReferencesStack › refusal A…`. Not tested in the PR: the link moving focus across components, and both two-stage rows. Real App results: the link is reached after 6 Tab presses, and Enter sets `activeElement.id=references-heading` with a visible focus ring ([14](```````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/14-screenshot-refusalA-focus-heading.png?raw=true)). ```````````````````````` The quoted answer shows with "Writing a summary…" and is then swapped when the deferred synthesized response arrives ([18](````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/18-screenshot-twoStage-writing.png?raw=true)). ````````````````````````` A full-stage `refusalC` keeps the quoted answer ([05](`````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/05-ac1-ac6-qa-browser-app-run.png?raw=true)). `````````````````````````` See finding 1 |
| AC7: CI frontend job green, lint warnings ≤ main | ✅ | 0 warnings at the PR head and on main `c37d27c` ([01](``````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/01-ac7-frontend-job-head.png?raw=true), ``````````````````````````` [02](```````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/02-ac7-frontend-job-main-baseline.png?raw=true)) ```````````````````````````` |
| AC8: PR body lists each replaced FE-1 assert next to its replacement | ✅ | [09](````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/09-ac8-pr-body-replacements.png?raw=true). ````````````````````````````` I checked each row against the diff and none is weaker. `getByText(/87\.3% Verified/)` becomes exact text on two cards plus a whole-render `/verified/i`. `Unverified · 0.0%` becomes exact "Not checked" plus no `0.0%`. The single refusal test becomes A/B/C tests with exact copy and `getByRole('status', {name})` |
| Docs | ✅ | No README or API change. Only documented `AskResponse`/`Citation` fields are read |

## Scope and design check
- **Scope:** 10 files, +398/−98 = 496 lines ([03](`````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/03-scope-diffstat.png?raw=true)). ``````````````````````````````
  - Every file is in the ticket's file list and the frontend role's paths. No ticket, review or doc files.
  - `HeroSearch.jsx` changes only the one approved sentence, with no class change. `App.jsx` adds only the `refusalReason` prop line.
  - The out-of-scope items (tooltip wiring, token restyle, theme flip) are untouched.
- **Design:** followed.
  - The §1 rule order (rows 1–5) and all copy match the PM-approved text exactly.
  - Also as designed: the refusal panel structure, the `useId` title, `focusEvidence` with `scrollIntoView?.`, the footer summary and `markdownNote`.
  - The gauge is removed. The `verified` badge variant is removed (no callers left at head), and `arxiv` is retargeted.
  - PM changes 1, 3 and 4 are done. Change 5 was invoked (see finding 1).
  - One deviation: `Info` instead of `CircleHelp` (finding 2).
- **Contracts:** none touched.
  - ADR-0003 holds: unsupported and unchecked citations stay visible and flagged, and every card keeps "Open PDF".
  - ADR-0014 holds: reserved or unknown statuses, and any `status`/`supported` disagreement, never read as Supported.

## PRD fit
The change serves QA-4 and §7 principle 2 (honest labels): nothing says "Verified", and an unchecked citation reads "Not checked" instead of "0.0%". It also serves QA-5 and principle 1: a refusal is a calm `role=status` state that leads to the evidence, with each PDF one click away. The behaviour is right; what's missing is the App-level regression coverage the ticket asked for.

## Findings
1. **[blocking] [spec] The App-level tests required by AC1, AC2, AC4 and AC6 are not in the PR.**
   - **What's missing** ([04](``````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/04-ac1-ac2-ac4-ac6-app-tests-absent.png?raw=true)): ``````````````````````````````` there is no `frontend/src/App.test.jsx`, CI ran 4 test files, nothing renders `<App>` or stubs `fetch`, and the `earlyRefusal` fixture is unused. AC4 has **no** test in this PR.
   - **Why it's a spec problem:** the design's PM change 5 does allow moving `App.test.jsx` to a follow-up once the diff passes ~550 lines (with it, this PR would be about 640). But FE-3a's ACs still require these tests, and no follow-up ticket exists (`agents/tasks/` has only FE-3, FE-3a and FE-3b). So the coverage has been moved out of the PR and nothing tracks it.
   - **Why QA's run isn't enough:** the browser run ([05](```````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/05-ac1-ac6-qa-browser-app-run.png?raw=true), ```````````````````````````````` 44/44) shows today's behaviour is correct, but it's a one-off check, not a regression test.
   - **To close (pm-lead decides first), pick one:**
     - (a) Amend FE-3a's AC1, AC2, AC4 and AC6 so the App-level asserts move to a specced follow-up, for example FE-3a2: `src/App.test.jsx` only, with the exact asserts from design §Test plan rows AC1, AC2, AC4, AC6 and AC6 two-stage; Depends on #86; P0, not optional. QA round 2 then accepts the component tests plus [05] for this PR.
     - (b) Have the developer add `App.test.jsx` to #86 and accept a PR of about 640 lines.
   - Developer action: none until pm-lead picks one.
2. **[nit] Unrecorded design deviation.** Design §3 specifies `CircleHelp` for the "Not checked" chip, but the PR uses `Info` (`ReferencesStack.jsx` `CHIP_ICONS`). The reason, a risk that the icon name doesn't exist in lucide-react 1.x with no local install to check, is only in the developer's notes. Either record it in `docs/design/FE-3.md` or switch to `CircleHelp`: CI's `vite build` would catch a missing export. `Info` is also the glyph the refusal panel uses, which is harmless.
3. **[nit] The chip tooltip is a `title` on a badge that can't take focus.** Keyboard and touch users can't open it. That's acceptable for FE-3a because the chip text carries the meaning, and FE-3b wires `ui/tooltip` on a real button. FE-3b should drop the `title` so screen readers don't hear the tooltip twice.
4. **[nit] Missing component cases**, cheap to add the next time these files are touched:
   - `ReferencesStack` with `refusalB`: "Unsupported · 22.0%", "Not checked" and "2 passages".
   - The singular strings "1 passage" and "Read the 1 retrieved passage", which nothing asserts.
   - The answer-mode footer with empty `citations`, which renders "0 of 0 citations supported".

**Observation (not a FE-3a finding):** in light mode the passage text is nearly invisible ([11](````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/11-screenshot-refusalA-light.png?raw=true), ````````````````````````````````` [17](`````````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/17-screenshot-mixedAnswer-light.png?raw=true)). `````````````````````````````````` Its classes, `text-slate-300 bg-background/80`, are unchanged by this PR. They're on FE-3b's restyle list (design §3 tokens) and the default theme is still dark, so pm-lead should make sure FE-3b's QA screenshots this exact state.

## Missing tests
- **App-level** (per design §Test plan):
  - A and C: unscoped whole-tree `/verified/i` check on `document.body.textContent`.
  - B with `fetch` stubbed and `Toast` mocked: the toast is only ever `''`, no `role=alert`, the heading is visible, `fetch` is called once.
  - Early refusal: the explicit asserts, plus the discover POST with `{query}`.
  - The panel link moving focus to `#references-heading` across components.
  - Two-stage: the swap on a deferred full response, and a full-stage refusal keeping the quoted answer.
- **Component:** the finding 4 cases.

## Hand-off
FAIL → **pm-lead first**, because finding 1 is a spec decision: amend the ACs and spec FE-3a2, or accept a PR of about 640 lines. Then it goes back to frontend-engineer for option (b) and/or the nits. Round 2 checks finding 1 against whichever option pm-lead records in the ticket.


---
_Generated by [Claude Code](https://claude.ai/code)_


---

<!-- Round 2: written by qa-reviewer directly. -->

# QA report: FE-3a · PR #86 · round 2

**Verdict:** PASS
**Reviewed commit:** `fa92c301e7f0fd5b71a0c0d25e4aadf2732e66a2` (base `c37d27c`, unchanged since r1) · **Date:** 2026-11-20
**Ticket:** `agents/tasks/FE-3a.md` (ACs amended 2026-11-20 + Rework checklist r1) · **PRD:** Product PRD UI-1, QA-4, QA-5, §7; ADR-0003, ADR-0014 · **Design:** `docs/design/FE-3.md` (incl. amendments after QA r1)
**Evidence:** [agents/reviews/FE-3a/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence) (round-2 files 19–26; r1 files 00–18 unchanged)

**Reason:** The r1 blocker was a spec gap. pm-lead resolved it by amending AC1, AC2, AC4 and AC6 and speccing [FE-3a2](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/FE-3a2.md) (KAN-93, P0, after #86 merges). The rework adds the four finding-4 component cases, test-only (+36/−1, 2 files, no product code). CI is green with 70/70 tests, and the 4 new tests are proven to have run. A QA probe of those cases kills 7 of 7 single-edit mutants. Every amended AC now has evidence.

## Test results
| Check | Source | Result |
|---|---|---|
| All 5 check runs on `fa92c30` | CI | DB, Go, Python M0, Frontend and Agent ownership: all completed/success, each with `head_sha` fa92c30 ([19](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/19-r2-ci-checks.png?raw=true)) |
| Frontend (lint, test, build) | CI job 136473216598 | Ran on merge `22dbda7` = fa92c30 into current main `c37d27c`. oxlint: "Found 0 warnings and 0 errors." (main 0, r1 [02]). vitest: 4 files, **70 passed** (r1: 66). Per file: ReferencesStack 11→13, SynthesisView 15→17, citations 35, HeroSearch 5. `vite build` ok ([20](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/20-r2-ac7-frontend-job-head.png?raw=true)) |
| New tests ran | CI counts vs source | The `it()` count went up by exactly 2 in each changed file, matching CI's per-file deltas. The 4 new titles are listed ([22](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/22-r2-f4-test-count-map.png?raw=true)). Vitest's default reporter doesn't print test names, so "ran and passed" comes from the counts plus the green file result |
| Ownership / scope | CI + local `ownership-check.sh` at fa92c30 | "Ownership OK for role=frontend (531 changed lines)" (warning > 400; under the ~550 PM limit). 10 files, all in `frontend/` and in the ticket's file list. The `App.jsx` diff is the one `refusalReason` line ([26](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/26-r2-scope-ownership.png?raw=true)) |
| Ticket verification (`npm ci && lint && test && build`) | not run locally: npm registry unreachable from the sandbox | relied on CI |
| QA mutation probe of the 4 new cases | local: real `SynthesisView`/`ReferencesStack`/`citations.js`/`badge`/`card`/`button` + real react-dom 19, esbuild, headless Chrome; lucide-react and `@radix-ui/react-slot` stubbed | Unmutated control: 8/8 pass. **7 of 7 mutants KILLED**, 0 survived, 0 invalid ([23](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/23-r2-f4-mutants.png?raw=true), sources [24](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/24-r2-harness-sources.png?raw=true)). Caveat: the probe re-implements the new tests' assertions on the live DOM. It isn't vitest. |
| `make eval` | n/a | frontend-only change |

## Rework checklist r1 (each item)
| Item | Verdict | Evidence |
|---|---|---|
| **F1** [blocking][spec] App-level tests | ✅ resolved | The ACs are amended in the ticket, and FE-3a2 exists with AC1–AC5 covering every App-level assert r1 listed: whole-tree `/verified/i` for A and C; B with `fetch`/`Toast` (all calls); early refusal plus discover POST `{query}`; link focus; both two-stage rows; plus a negative-check AC6. The design records the move (§ "Amendments after FE-3a QA round 1"). The PR body has the required line: "F1: App-level tests (AC1 whole-tree, AC2 fetch/toast, AC4 explicit asserts + discover POST, AC6 focus + two-stage) → FE-3a2, after this PR merges." (body line 58, [25](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/25-r2-f1-pr-body.png?raw=true)). As the checklist says, I accept the component tests plus r1 browser evidence [05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/23e8eeb547ea8559af3f5cb8ae835d2b66fa83f2/agents/reviews/FE-3a/evidence/05-ac1-ac6-qa-browser-app-run.png?raw=true) (44/44) for those ACs in this PR. |
| **F2** [nit] `Info` vs `CircleHelp` | ✅ closed | Recorded as an accepted deviation in `docs/design/FE-3.md` (amendments, "Accepted deviation: `Info` instead of `CircleHelp`"). No code change, as decided (r1→r2 diff touches no product file, [21](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/21-r2-diff-r1-to-r2.png?raw=true)). |
| **F3** [nit] chip `title` tooltip | ✅ closed | Accepted for FE-3a only. `agents/tasks/FE-3b.md` AC1 now requires removing the `title` from every chip (with a test). No code change here. |
| **F4** [nit] missing component cases | ✅ done | All three asks are in fa92c30 ([21](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/21-r2-diff-r1-to-r2.png?raw=true)). (1) `ReferencesStack › refusal B: "Unsupported · 22.0%" and "Not checked" chips under "2 passages"`: exact chip text scoped to cards [1]/[2], the refusal heading, "2 passages", and no `/0\.0%\|verified/i`. (2) `ReferencesStack › refusal mode with one passage: heading badge reads "1 passage"` (`/\b1 passage$/`, anchored, so "1 passages" fails) and `SynthesisView › a refusal with one passage links "Read the 1 retrieved passage"` (exact accessible name). (3) `SynthesisView › answer-mode footer with no citations reads "0 of 0 citations supported"`. The probe confirms each case catches its mutant: plural heading M1, plural link M2, footer hidden for an empty answer M3, footer total dropped M4, B-specific "all Not checked" M5, unverified→unchecked rule dropped M6, B keeps the answer heading M7 ([23](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/23-r2-f4-mutants.png?raw=true)). |
| Observation (light-mode passage text) | ✅ routed | `FE-3b.md` AC5 names it explicitly: "passage text (today `text-slate-300` on `bg-background/80`, nearly invisible in light mode per FE-3a QA r1 evidence 11/17) is in the contrast table". Nothing in #86. |

## Acceptance criteria (as amended)
| AC | Met? | Evidence |
|---|---|---|
| AC1: A and C panel, copy, heading, chips, hero sentence (component); whole-tree assert → FE-3a2 | ✅ | r1 component tests (r1 [08]), still green at fa92c30 ([20](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/20-r2-ac7-frontend-job-head.png?raw=true)); r1 browser run [05]; App-level part tracked by FE-3a2 AC1 |
| AC2: B copy in `role=status`, no alert; `ReferencesStack` B shows "Unsupported · 22.0%", "Not checked", "2 passages" | ✅ | `SynthesisView › refusal B…` (r1) plus the new `ReferencesStack › refusal B…` ([22](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/22-r2-f4-test-count-map.png?raw=true), [23](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/23-r2-f4-mutants.png?raw=true): M5, M6, M7 killed); fetch/toast part → FE-3a2 AC2 |
| AC3: `citations.test.js` rows 1–5; `mixedAnswer` chips | ✅ | Unchanged since r1 (35 tests green, [20](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/20-r2-ac7-frontend-job-head.png?raw=true)) |
| AC4: early-refusal path unchanged (App.jsx = one prop line); `earlyRefusal` fixture ships | ✅ | [26](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/26-r2-scope-ownership.png?raw=true): the App.jsx diff is `+ refusalReason={searchResult.refusal_reason}`; fixture in `src/test/fixtures.js` (now also used by the 0-of-0 test). r1 [05] accepted for the behaviour; explicit asserts → FE-3a2 AC3 |
| AC5: no "PostgreSQL pgvector Verified"; export; Copy/Export hidden on refusal; footer, incl. "0 of 0 citations supported" | ✅ | r1 tests plus the new `› answer-mode footer with no citations…` (M3, M4 killed) |
| AC6: `role=status` panel, Tab-reachable link, zero citations → no link, `tabindex=-1`; singular "1 passage" and "Read the 1 retrieved passage" | ✅ | r1 tests plus the two new singular tests (M1, M2 killed); cross-component focus and two-stage → FE-3a2 AC4–AC5 |
| AC7: CI frontend green, lint ≤ main | ✅ | 0 warnings at head, main `c37d27c` 0 ([20](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/20-r2-ac7-frontend-job-head.png?raw=true)) |
| AC8: PR body FE-1 replacement table | ✅ | Unchanged since r1 (table at body lines 14–23, [25](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/25-r2-f1-pr-body.png?raw=true)); r2 changed only tests that were added, not replaced |
| Docs | ✅ | No README/API change |

## Scope, design, contracts
- **Scope:** the r1→r2 delta is 2 test files, +36/−1, and no product file ([21](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/21-r2-diff-r1-to-r2.png?raw=true)). The whole PR is 10 files and 531 lines, all inside the ticket's file list ([26](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/26-r2-scope-ownership.png?raw=true)). No ticket, review or doc files.
- **Design:** unchanged from r1 and followed. The one deviation (`Info`) is now recorded in the design.
- **Contracts:** none touched. ADR-0003 and ADR-0014 hold as in r1.
- PR #86 is open, draft, not merged; main hasn't moved since r1 (`c37d27c`). No human review or comment on the PR.

## PRD fit
Unchanged from r1. The PR serves QA-4 and §7 principle 2: no "Verified" anywhere, and "Not checked" replaces "0.0%". It serves QA-5 and principle 1: a calm `role=status` refusal that leads to the evidence, one click from each PDF. r2 adds regression coverage for the B-refusal chips and the singular and empty edge cases.

## Findings
1. **[nit] Parts of the PR body are stale after the rework.** pm-lead rewrites the body when raising the PR, so fix them then ([25](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b80b45f96626f9fb888eb2eb2ba82c08ec9d1bb3/agents/reviews/FE-3a/evidence/25-r2-f1-pr-body.png?raw=true)):
   - "Follow-ups created" (line 53) still says the App-level tests are "requested in the ticket Notes for pm-lead to spec". FE-3a2 / KAN-93 now exists, so link it.
   - "Size" (line 36) and the Verification ownership row (line 44) still say 496 changed lines; the current figure is 531.
   - AC4 and AC7 are still unticked (AC7 is green; AC4 is met as amended).
   - The AC2, AC5 and AC6 lines don't name the new tests; they appear only under "Rework r1".
2. **[nit]** The "0 of 0 citations supported" test reuses the `earlyRefusal` fixture as an *answer-mode* response. That's valid at component level (no `refusal_reason`, `citations: []`), and `App.jsx` never renders `SynthesisView` for an early refusal. But the fixture name reads as a refusal. A one-line comment would help. No action required.

No blocking findings.

## Missing tests
- None for FE-3a as amended. The App-level tests are FE-3a2 AC1–AC6 (P0, after #86 merges).

## Hand-off
PASS → **pm-lead** final review. While raising the PR, refresh the stale body lines (finding 1). FE-3a2 becomes Ready once #86 merges.


---

# PM final review: FE-3a · PR #86

**Verdict:** APPROVE
**Reviewed commit:** `fa92c301e7f0fd5b71a0c0d25e4aadf2732e66a2` (QA r2 PASS on the same head) · **Date:** 2026-11-20 · **Reviewer:** pm-lead

**Inputs read:** `agents/tasks/FE-3a.md` (amended ACs + Rework checklist r1), `docs/design/FE-3.md` (PM decision + amendments after QA r1), Product PRD UI-1 / QA-4 / QA-5 / §7,
ADR-0003, ADR-0014, QA rounds 1–2 above, `gh api …/pulls/86/files` (10 files, all `frontend/`, +433/−98) and **every file in `evidence/`** (00–26, PNG + TXT).
PR state at review: open, draft, head `fa92c30`, no human review or comment (only the two QA comments).

## Evidence check (each file opened)
| Files | Proves | Accepted? |
|---|---|---|
| 19, 20 (r2), 00–02 (r1) | All 5 CI checks success on `fa92c30`; Frontend job 136473216598: 0 lint warnings (main 0), 70/70 tests, build ok; per-file counts 11→13 and 15→17 | yes: AC7 |
| 21, 22 | r1→r2 delta is 2 test files, +36/−1, no product file; the 4 new `it()` titles map exactly to the CI count deltas | yes: F4, AC2/AC5/AC6 additions |
| 23, 24 | QA probe on the real components: control 8/8, 7/7 mutants killed (plural heading, plural link, footer hidden/total dropped, B-specific chip/heading, unverified rule). Harness sources shown | yes, as supporting evidence (not vitest; CI is the authority) |
| 26, 03 | 10 files in ticket scope, App.jsx = the one prop line, ownership OK 531 lines (≤ ~550 PM limit) | yes: scope, AC4 code-path claim |
| 05, 06, 07 | r1 real-App browser run 44/44 incl. whole-tree `/verified/i`, B no toast/alert/fetch once, early refusal + discover POST, focus, two-stage; negative control fails the 6 whole-tree checks with the old hero sentence | yes, as the one-off App-level evidence the amended AC1/2/4/6 accept; regression coverage is FE-3a2 |
| 08, 09 | Component test names; FE-1 replacement table in the PR body | yes: AC1/3/5/6, AC8 |
| 04 | r1: App.test.jsx absent (the r1 finding) | superseded by the AC amendment + FE-3a2 |
| 10–18 | Screenshots: A/B/C refusal panels with approved copy, honest chips, "Retrieved passages (no answer was shown)", focus ring on the heading, early-refusal banner unchanged, answer mode with "1 of 3 citations supported", two-stage writing state, light mode | yes. UI matches design §2 copy and Q2 (no Copy/Export on refusal) |

No "⚠ unverified" remains on anything this PR claims. The only gap (App-level regression tests) is a deliberate, specced split: FE-3a2 / KAN-93, P0, after #86 merges.

## PRD / persona fit
- **§7 principle 2 (honest labels), QA-4:** nothing in the tree says "Verified" any more (hero sentence fixed, footer, export, badge variant removed), and an unchecked citation reads "Not checked" instead of a misleading "0.0%".
  ADR-0014's conservative rule holds: reserved/unknown statuses and `status`/`supported` disagreement never read Supported.
- **§7 principle 1 / QA-5 (calm refusal that leads to evidence):** a refusal is a `role="status"` panel, not an error; one link takes keyboard users to the passages; every card keeps one-click "Open PDF" (ADR-0003).
- **UI-1:** status stays ✅; this is a quality change to an existing row.
- The remaining "…Sentence-Level Verification" tagline was explicitly kept by the PM decision (change 1); not re-litigated here.

## Scope
Right size for what the ticket intended after the amendment: nothing missing (every amended AC has a named test or accepted evidence), nothing extra (no file outside the ticket list, HeroSearch is copy-only, App.jsx is one line).
531 lines is above the 400 target but within the explicit ~550 allowance (prod ~175).

## Docs
No README/API change needed (only documented `AskResponse`/`Citation` fields are read). PRD QA-4's notes column still describes the pre-AI-2 cosine/fail-open state; refreshing it is a pm-lead `docs/` PR,
not a blocker for this PR (recorded as a follow-up for the orchestrator).

## Changes made when raising the PR (QA r2 finding 1)
- "Follow-ups created" now links FE-3a2 (KAN-93) and FE-3b instead of "requested … for pm-lead to spec".
- Size and the ownership row now say 531 (+433/−98), not 496.
- AC4 and AC7 ticked (AC7 green in CI; AC4 met as amended), and AC2/AC5/AC6 name the new r2 tests.
- Evidence section with one row per AC (commit-pinned image URLs: `23e8eeb` for 00–18, `b80b45f` for 19–26), CI results, QA and PM verdicts.
- QA r2 nit 2 (the `earlyRefusal` fixture reused as an answer-mode response for "0 of 0") needs no action; FE-3a2 can add a one-line comment when it touches the fixtures.

**PM verdict: APPROVE.** PR #86 rewritten and marked ready for review; Mahesh reviews and merges. FE-3a2 becomes startable once #86 merges.
