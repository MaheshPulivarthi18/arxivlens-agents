# FE-4a: Claims list with per-claim status chips; `[n]` markers focus their own card

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (Phase 1 item 8, first half of FE-4; Product PRD §7 principles 1 and 3) |
| **PRD ref** | Product PRD UI-1, QA-3, QA-4, §7 principles 1–3; ADR-0003, ADR-0014 (Accepted), ADR-0019 (Accepted); ADR-0018 (Proposed, not depended on) |
| **Depends on** | FE-3b #104, FE-0i #109, AI-8b #65, ADR-0019 #120 (all merged). Design `docs/design/FE-4.md` **approved with conditions** 2026-11-22 |
| **Jira** | create: story under epic KAN-5 "Research UI & citations", labels `task-FE-4a`, `design-required`; link to KAN-44 (FE-4 umbrella) |
| **Design required** | yes: covered by `docs/design/FE-4.md` (approved; §1 `claimState`/`claimCitations`/`groupByMarker`, §2, §3 grouping/focus/rows, §4, §5, §6) |
| **Status** | Done (#128 merged `4c61adc`) |

## Goal
A researcher sees every statement of an answer with its own verdict (Supported / Unsupported / Not checked), and each `[n]` marker takes
keyboard and mouse users straight to that passage's card. Fixes the duplicate `ref-<n>` cards for written answers that cite one passage twice
and the stray active ring in refusal mode.

## Scope
- Files expected to change (app repo):
  - `frontend/src/lib/citations.js` + `citations.test.js`: `claimState`, `claimCitations`, `groupByMarker` (design §1).
  - `frontend/src/components/SynthesisView.jsx` + `SynthesisView.test.jsx`: claims mode list, marker buttons with `aria-controls`, `(marker, pos)` callback, `ui/tooltip` preview (§2).
  - `frontend/src/components/ReferencesStack.jsx` + `ReferencesStack.test.jsx`: cards from `groupByMarker`, keyed by `trace_id` + marker, `tabIndex={-1}`, focus ring,
    `data-active`, "Cited by claim n" / "Check n" rows with `aria-current`, heading count = cards, ignore `active` in refusal mode (§3 first two bullets only).
  - `frontend/src/App.jsx` + `App.test.jsx`: `active = {marker, pos} | null`, initial `null`, cleared on new search and on the quoted → written swap,
    `handleCitationClick` focuses + scrolls (reduced-motion aware) (§4).
  - `frontend/src/test/fixtures.js`: `quotedClaims`, `synthesizedSkips`, `brokenPositional` (+ malformed-claims variants).
- Out of scope (FE-4b): quote highlight / `locateQuote`, meta line (`arXiv:IDvN · § · p. N`, "Chunk #id", "General"), passage box / collapsible, PDF `#page=N` link,
  `ReferencesStack.test.jsx:30` assertion. Also out: app `README.md` (no line needed), `ui/badge.test.jsx` (FE-0j), any API change, a "Back to claim" link.

## Acceptance criteria
- [ ] AC1 — With `claims`, each claim renders in order as an item of the list "Claims in this answer" with a text + icon chip: `supported` → "Supported",
  `unverified` → "Not checked", anything else (`unsupported`, reserved, unknown, missing) → "Unsupported"; the three use different `Badge` variants;
  no `unverified` claim or chip contains "Supported" or "verified" (any case). A claim with `markers: []` shows its chip and no buttons. `synthesizedSkips`
  renders markers `[1]`, `[1]`, `[3]`, no `[2]`, and no "hidden" text (ADR-0019). Tests: `citations.test.js › claimState`, `SynthesisView.test.jsx`.
- [ ] AC2 — Click, Enter and Space on a claim marker each call `onCitationClick(marker, pos)` (`pos` = positional citation index) and, in `App`, move
  `document.activeElement` to the article "Citation [n]", which has `data-active`; for a repeated marker the matching "Cited by claim n" row has
  `aria-current="true"`. The marker has `aria-controls="ref-<n>"`. The preview tooltip opens on keyboard focus with title + status, and after Enter focus is on the card
  (design condition 4). With a broken positional invariant, markers still map by number and rows read "Check n".
- [ ] AC2b — Nothing is active on load in any mode; refusal A/B/C never shows `[data-active]`; after the written answer replaces the quoted one, no card is active (App tests).
- [ ] AC2c — One card per distinct marker: no duplicate `id="ref-n"` in the DOM for `synthesizedSkips`; the heading count (cards) and footer "x of y citations supported" (entries)
  are both pinned in a test for that fixture (design condition 3).
- [ ] AC5 — Responses without `claims`, with `claims: []`, or with malformed claims render the FE-3 prose with `[n]` buttons and no "Claims in this answer" list. Every existing
  FE-1/FE-3 test in `SynthesisView.test.jsx`, `ReferencesStack.test.jsx` and `App.test.jsx` passes **unmodified** (design condition 1; list any unavoidable change in the PR body with its stricter replacement).
- [ ] AC6 — CI `frontend` job green: `npm ci`, `npm run lint` (warning count not above main's latest run), `npm test`, `npm run build`.
- [ ] Docs: update `docs/design/FE-4.md` §2 item 3 wording per condition 1 (direct to main here). No app README change.

## Verification
```bash
cd frontend && npm ci && npm run lint && npm test && npm run build
# QA: kill the FE-4a mutants from docs/design/FE-4.md §Test plan: claimState unverified→supported;
# claimCitations without the marker-equality check; active initial value back to 1; drop tabIndex={-1}/.focus()
```

## Notes
- 2026-11-22 (pm-lead, design gate): split from FE-4 (design §Size and split, ≈ 365 changed lines). If it goes over 400, move the multi-entry
  "Cited by claim n" rows to FE-4b instead of growing this PR. Keep the card body (meta line `ReferencesStack.jsx:100`, passage `:106`, PDF link) untouched (condition 2).
  The tooltip replaces the 2026-11-19 popover Note (Q1). Evidence: screenshots of quoted claims (three chip kinds), `synthesizedSkips` (skip + grouping + both counts), and a refusal with no ring.
- 2026-11-22 (frontend-engineer, build): `agent/frontend/FE-4a` commit `a57c758` on `53171d6` (local, not pushed; no PR yet). 9 files under `frontend/src/`,
  +590/−52 = 642 changed lines (ownership-check: OK for role=frontend, size warning > 400). Prod ≈ 230 lines, tests + fixtures ≈ 410.
  - **Size → scope moved to FE-4b (per the 400-line rule above):** the multi-entry "Cited by claim n" / "Check n" rows and their `aria-current`
    are **not** in FE-4a. Until FE-4b, a card for a repeated marker shows one status chip per check in its header, so no check's status is hidden.
    So the AC2 clauses "the matching 'Cited by claim n' row has `aria-current`" and "rows read 'Check n'" move to FE-4b. FE-4a still records
    `active.pos` and still maps markers by number when the positional check fails (`claimRows`), so FE-4b only adds the rows. Even with this cut the
    diff is over 400 because the AC test plan is mostly tests; pm-lead to accept or ask for a further split.
  - Design §2 item 3 wording updated per condition 1 (direct to main). Deviation to confirm: a fallback marker that has a card drops its old
    `title="Click to inspect Evidence [n]"` (the tooltip replaces it; markers with no matching citation keep it). No existing test checks `title`.
  - Existing tests: no existing test body changed; only import lines in the four test files were extended. No assertion replaced (the `:30` one is FE-4b).
    The fallback still calls `onCitationClick(marker)` with one argument, so `toHaveBeenCalledWith(2)` holds.
  - Local verification: **not run**. `npm ci` fails with `getaddrinfo ENOTFOUND registry.npmjs.org` (registry unreachable from the sandbox, no
    node_modules anywhere), so lint/test/build depend on CI. What I did run: a TypeScript syntax parse of all 9 files (OK) and a plain-Node logic check
    of `claimState`/`claimCitations`/`claimRows`/`groupByMarker` on the new fixtures (results as expected). Jira story not created from this session (left for the orchestrator).
- 2026-11-22 (pm-lead, cycle 2026-11-22T02:00Z): **the previous build is lost.** `a57c758` was local only and the cycle
  died holding RUN_LOCK before a push; no branch or PR exists. Rebuild from app `main` `53171d6` this cycle, and push the
  branch + open the draft PR **in the same session as the build** (don't leave a local-only commit).
  **Size decision: accepted as one PR at ≈ 650 changed lines, no further split**, on these conditions:
  1. The multi-entry "Cited by claim n" / "Check n" rows and their `aria-current` stay in FE-4b (as the build Notes did).
     So in AC2 the clauses "for a repeated marker the matching 'Cited by claim n' row has `aria-current="true"`" and
     "rows read 'Check n'" are **FE-4b's**, not FE-4a's. FE-4a's broken-invariant check is: markers still map by number
     (focus lands on "Citation [n]"). Until FE-4b, a repeated-marker card shows one status chip per check in its header.
  2. Production code (`citations.js`, `SynthesisView.jsx`, `ReferencesStack.jsx`, `App.jsx`) stays ≤ ~250 changed lines;
     the overage is tests + fixtures only. The PR body states the prod/test split (from `git diff --numstat`).
     If prod goes over ~300, stop and report instead of pushing.
  3. No existing test body changes (AC5); import-line extensions are fine and must be listed in the PR body.
  Why accept rather than split: a further cut would separate the claim chips (AC1) from marker focus (AC2/AC2b) and the
  card grouping (AC2c), which share `claimRows`/`groupByMarker` and `App`'s `active` state; either half alone would
  ship a P0 UI that is half-wired, and the extra lines are the AC test plan, which is what makes review safe.
  The dropped `title="Click to inspect Evidence [n]"` on a fallback marker that has a card is accepted (the tooltip
  replaces it, design Q1); keep it on markers with no matching citation.
- 2026-11-27 (pm-lead, cycle 2026-11-27T03:59Z): **re-picked.** The 2026-11-22T02:00Z cycle died before building; `agent/frontend/FE-4a`
  doesn't exist on origin. Build from app `main` `53171d6` under the 2026-11-22 size decision (conditions 1–3 above unchanged) and
  **push the branch + open the draft PR in the same session as the build**. Independent of open #125 FE-0j (only `ui/badge.test.jsx`)
  and of #122–#124 (no `frontend/` files). Frontend WIP after this pick: 2 (#125 + FE-4a).
- 2026-11-27 (frontend-engineer, build, cycle 2026-11-27T03:59Z): branch `agent/frontend/FE-4a` **pushed**. Commit `34cbd2e` is on `53171d6`, with **draft PR #128**.
  9 files under `frontend/src/`, +608/−49 = 657 changed lines. **Prod 221** (`App.jsx` 23, `ReferencesStack.jsx` 64, `SynthesisView.jsx` 77, `citations.js` 57), which is under the ~250 cap.
  Tests + fixtures 436. Ownership check: OK for role=frontend, with a size warning > 400.
  - Per size condition 1, the "Cited by claim n" / "Check n" rows and `aria-current` stay in FE-4b. A repeated-marker card shows one chip per check in its header.
    `claimRows` maps markers by number when `claimCitations` returns `null`.
  - Added `hasClaims` to `lib/citations.js`. It's the §2 item 2 mode test, moved out of the component so it can be unit-tested.
    `ReferencesStack` takes `traceId` (card key `trace_id-marker`) but not `claims`: that prop is only needed for FE-4b's rows.
  - Existing tests: no test body or assertion changed. Only import lines were extended, all listed in the PR body.
    Fallback markers still call `onCitationClick(marker)` with one argument.
    A fallback marker with a card drops `title`; markers with no citation keep it (accepted deviation).
  - Docs: `docs/design/FE-4.md` §2 item 3 already carries the condition-1 wording (line 72, from the earlier cycle), so no edit was needed.
  - Local: `npm ci` fails with `getaddrinfo ENOTFOUND registry.npmjs.org`, so I ran a TypeScript syntax parse of all 9 files (OK) and a plain-Node logic check of the helpers on the new fixtures (OK).
    **CI on `34cbd2e`: all 5 checks green.** Frontend job: `npm ci` OK; oxlint `Found 0 warnings and 0 errors` (main `53171d6` also 0); Vitest 12 files, 207 tests passed (main 155); `vite build` OK.
    Jira was skipped (orchestrator instruction). Evidence screenshots are still to come from QA.
- 2026-11-27 (frontend-engineer, rework round 1 after QA round 1 FAIL on `34cbd2e`, cycle 2026-11-27T03:59Z): commit `529ad12` on top of `34cbd2e`, +50/−2 (prod +1 in `SynthesisView.jsx`, tests +49/−2 in `App.test.jsx`, PR-added tests only). Prod total now 222 changed lines.
  - [x] F1 [blocking] AC2b swap test was vacuous. It now clicks `[1]`, which has a card in both `quotedClaims` and `synthesizedSkips`. It asserts card 1 `data-active` and 1 active card before the swap, and after it asserts card 1 has no `data-active` and there are 0 active cards. So removing `setActive(null)` at `App.jsx:113` (M6) fails the test.
  - [x] F2 [nit] New App test "a new search clears the active card": search, click `[3]`, assert card 3 active, search again, wait for the 2nd fetch and the list, assert none active (kills M10, `App.jsx:84`).
  - [x] F3 [nit] New `it.each` App test (true→`auto`, false→`smooth`): stubs `matchMedia` and spies on `Element.prototype.scrollIntoView` (restored in `finally`). It asserts the last call is `{ behavior, block: 'nearest' }` on card 3 via `mock.contexts` (kills M13).
  - [x] F4 [nit] Claims list: `{entries.length > 0 && ' '}` between the sentence and its first marker, matching the prose fallback. Uncited claims are unchanged. No test added (cosmetic).
  - [x] F5 [spec] M3 equivalence noted for FE-4b/QA. Nothing to change in FE-4a, and F2 now tests the reset directly. (pm-lead 2026-11-27: noted in the `docs/design/FE-4.md` §Test plan and in the FE-4b spec.)
  - Local: no `node_modules` (registry blocked), not run. Ownership check OK (size warning, 706 lines). **CI on `529ad12`: all 5 checks green.** Frontend: oxlint 0 warnings/0 errors; Vitest 12 files **210 passed** (was 207; App.test.jsx 17→20); `vite build` OK. Mutant kills for M6/M10/M13 are by static reading. I have not run them.
- 2026-11-27 (pm-lead, final review, cycle 2026-11-27T03:59Z): **APPROVE** at `529ad12`. I opened all evidence 00–25. AC1, AC2 (FE-4a part), AC2b, AC2c, AC5, AC6 and Docs are covered. Size conditions 1–3 and
  design conditions 1–4 hold. Size is 706 lines in total (prod 222), accepted. The [spec] item about the M3 equivalent mutant went into the design §Test plan and the FE-4b Notes (with M11 to be killed at runtime by AC2d).
  The PR description was rewritten with the Evidence section, the PR was marked ready for review and labelled `ready-to-merge`. FE-4b stays Blocked until #128 merges. Jira was skipped (orchestrator instruction).
