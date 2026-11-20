# FE-3a2: App-level regression tests for FE-3a (refusal states, early refusal, focus, two-stage)

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P0 (the regression coverage FE-3a's ACs required; moved out of #86 by the size rule in `docs/design/FE-3.md` PM decision change 5, not optional) |
| **PRD ref** | Product PRD UI-1, QA-4, QA-5, §7 principles 1–2; ADR-0003, ADR-0014 (Accepted); parent [FE-3a](FE-3a.md) (amended AC1/AC2/AC4/AC6) |
| **Depends on** | **FE-3a #86 merged** (fixtures `earlyRefusal`, `refusalA/B/C`, `mixedAnswer`, `quotedAnswer`/`synthesizedAnswer` in `src/test/fixtures.js`, the refusal panel and `#references-heading`). Must not overlap any open PR's files (re-check via REST at start) |
| **Jira** | KAN-93 |
| **Design required** | no (design done: `docs/design/FE-3.md` §Test plan rows AC1, AC2, AC4, AC6, AC6 two-stage are the spec for this file) |
| **Status** | Ready (after #86 merges) |

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
