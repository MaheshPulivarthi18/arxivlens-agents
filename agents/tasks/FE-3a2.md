# FE-3a2: App-level regression tests for FE-3a (refusal states, early refusal, focus, two-stage)

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (the regression coverage FE-3a's ACs required; moved out of #86 by the size rule in `docs/design/FE-3.md` PM decision change 5, not optional) |
| **PRD ref** | Product PRD UI-1, QA-4, QA-5, §7 principles 1–2; ADR-0003, ADR-0014 (Accepted); parent [FE-3a](FE-3a.md) (amended AC1/AC2/AC4/AC6) |
| **Depends on** | **FE-3a #86 merged** (fixtures `earlyRefusal`, `refusalA/B/C`, `mixedAnswer`, `quotedAnswer`/`synthesizedAnswer` in `src/test/fixtures.js`, the refusal panel and `#references-heading`). Must not overlap any open PR's files (re-check via REST at start) |
| **Jira** | KAN-93 |
| **Design required** | no (design done: `docs/design/FE-3.md` §Test plan rows AC1, AC2, AC4, AC6, AC6 two-stage are the spec for this file) |
| **Status** | Ready to merge (PR [#91](https://github.com/MaheshPulivarthi18/ArxivLens/pull/91) raised 2026-11-21 at `e7dc3c0`; QA r1 PASS, PM APPROVE). Waiting on Mahesh |

## Goal
Lock in, as CI regression tests on the real `<App>`, the behaviour QA r1 confirmed only by a one-off browser run for FE-3a: no "verified" claim anywhere on a
refusal, a calm refusal with no error toast and no second request, the early refusal unchanged, the panel link moving focus to the evidence, and the two-stage swap.

## Scope
- Files: `frontend/src/App.test.jsx` (new) **only**. Use the fixtures already in `src/test/fixtures.js`; if a fixture is genuinely missing, adding it to
  `fixtures.js` is allowed (say why in the PR body). No production code changes; if a test exposes a bug, stop and report it in Notes (new task), don't fix it here.
- Stubs: `fetch` via `vi.stubGlobal` (per-test, restored in `afterEach`); `Toast` mocked with `vi.hoisted` + `vi.mock` so its props can be inspected.
  Answer `/v1/ask` by request body (`quick: true` vs full) and `/v1/papers/discover` separately; assert any other URL fails the test.
- Out of scope: tooltip tests and token/class asserts (FE-3b); component-level cases (FE-3a); any change to `App.jsx`.

## Acceptance criteria
- [ ] AC1 — For `refusalA` and for `refusalC` (returned to the `quick: true` ask): after the refusal panel ("No answer shown", `role="status"`) is shown,
  `document.body.textContent` (whole tree, unscoped) does not match `/verified/i`. Both cases are separate tests.
- [ ] AC2 — `refusalB` with `fetch` stubbed: the mocked `Toast` is only ever rendered with an empty message (assert over **all** its calls), there is no
  `role="alert"`, the "Retrieved passages" heading is visible, and `fetch` was called exactly once (no writing stage after a refusal).
- [ ] AC3 — Early refusal (`earlyRefusal`): explicit asserts, not a snapshot: text "Relevance Protection Activated:", the echoed question inside a `code`
  element, the discover button with today's label; clicking it sends `POST /v1/papers/discover` whose JSON body equals `{ query: <the question> }`; no `article`
  elements; no "Clinical Literature Synthesis".
- [ ] AC4 — `refusalA`: activating the "Read the 2 retrieved passages" link (keyboard: Tab to it, then Enter, or `user.click`) makes
  `document.activeElement` the element with `id="references-heading"`.
- [ ] AC5 — Two-stage: (a) quick → `quotedAnswer`, full held on a deferred promise: the quoted text and the "Writing a summary…" status are shown; after resolving
  the full request with `synthesizedAnswer`, the synthesized text is shown, the quoted text is gone and the status is gone. (b) quick → `quotedAnswer`, full →
  `refusalC`: the quoted answer stays, no "No answer shown" panel, no toast message.
- [ ] AC6 — Negative check recorded in the PR body: each of AC1–AC5 fails when its behaviour is broken (e.g. restore the old hero sentence for AC1; make the
  link a no-op for AC4); a local mutation run or a reasoned note per AC if npm is unavailable in the sandbox (QA reruns where it can).
- [ ] AC7 — CI `frontend` job green: `npm ci && npm run lint && npm test && npm run build`; lint warnings not above main's latest run; vitest reports one more
  test file than main.
- [ ] Docs: none expected.

## Verification
```bash
cd app/frontend && npm ci && npm run lint && npm test && npm run build
# CI is the source of truth (sandbox can't reach registry.npmjs.org)
```

## Notes
- 2026-11-20 (pm-lead): specced from the FE-3a QA r1 FAIL (finding 1, option a). The developer's draft list in FE-3a Notes (2026-11-20 Build) and the
  design §Test plan rows are the source; the scratchpad draft is gone, recreate it. Expected size ~150 lines, one file.
- 2026-11-20 (frontend-engineer, Build): `frontend/src/App.test.jsx` (new, 202 lines, 7 tests), commit `e7dc3c0` on `agent/frontend/FE-3a2` (from `230f617`).
  No production code and no fixture changes (every fixture needed already existed). Open PRs re-checked via REST at start: none.
  - Harness: `fetch` stubbed per test with `vi.stubGlobal` (restored by `vi.unstubAllGlobals` in `afterEach`), routed by URL and `/v1/ask` body
    (`quick: true` vs full) and `/v1/papers/discover`; any other URL, or a stage a test didn't provide, is recorded and fails the test in `afterEach`.
    `Toast` mocked with `vi.hoisted` + `vi.mock` (spy records props, renders nothing). No `new URL(…, import.meta.url)` in the file.
  - AC1 refusal A / refusal C: two tests, unscoped `document.body.textContent` not `/verified/i` after the "No answer shown" status panel.
  - AC2 refusal B: every Toast call has `message === ''` (and at least one call), no `role="alert"`, "Retrieved passages" heading visible, `fetch` called once.
  - AC3 early refusal: explicit asserts (banner text, question in a `code`, button with today's label, no `article`, no "Clinical Literature Synthesis");
    click → exactly one `POST /v1/papers/discover` with body `{ query: <question> }`; the re-run search shows the banner again.
  - AC4 refusal A: Tab (bounded loop) to "Read the 2 retrieved passages", Enter → `document.activeElement` is `#references-heading`.
  - AC5a/b two-stage: full held on a deferred promise; (a) quoted text + "Writing a summary…" then synthesized text, quoted and status gone;
    (b) full → `refusalC`: quoted stays, no panel, no toast message.
  - AC6 (reasoned, npm unavailable; QA to rerun as mutants): old hero sentence ("…mathematically verified…") → AC1 fails both; chip text "Unverified" → AC1 fails;
    `showToast` on a refusal → AC2 toast assert fails; drop `if (!quick.synthesis_available) return` → AC2 `toHaveBeenCalledTimes(1)` fails (+ unexpected "ask full");
    discover body `{ q: … }` or no POST → AC3 fails; early-refusal check removed → refusal-free path renders cards/no banner → AC3 fails;
    `focusEvidence` a no-op → AC4 focus stays on the link → fails; never set 'writing' → AC5a/b WRITING `findByText` fails; drop the swap → AC5a synthesized text never
    appears; drop the `answer_kind === 'synthesized'` guard → AC5b panel shows → fails.
  - AC7 not verified locally: `npm ci` can't reach registry.npmjs.org (in `NO_PROXY`, DNS ENOTFOUND; via the agent proxy CONNECT 403), so no vitest/oxlint/vite run.
    Local checks only: TypeScript `transpileModule` (JSX) 0 diagnostics; ESLint 9 `no-unused-vars`/`no-undef` clean. Main baseline (CI run 44797226987, job 136502158010
    at `230f617`): `Found 0 warnings and 0 errors.`, `Test Files 7 passed (7)` → this PR should show 8 (FE-0f's button.test.jsx would add another if it merges first).
    The CI Vitest log is the pass/fail.
- 2026-11-21 (pm-lead, final review): **APPROVE** (see `agents/reviews/FE-3a2/report.md` § PM review). QA r1 PASS at `e7dc3c0` (CI 5/5 green; Frontend 8 files / 121 tests, 0 warnings).
  PR #91 description rewritten with the Evidence table (pinned to `4df0fb0`) and the AC6 mutant table (QA nit 1, marked reasoned, not executed). Marked ready + `ready-to-merge`.
  QA nit 2 (Toast mock renders `null`, so a "verified" toast escapes AC1; M19) and QA "Missing tests" (stale-search M18, full-stage network failure, zero-citation refusal, discover failure) → Backlog (frontend, P2).
  QA nit 3: whichever of #91/#92 merges second gets its Frontend job re-run on the new main. Merging #91 unblocks FE-3b.
