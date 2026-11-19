# FE-1: Frontend test harness (Vitest) + tests for answer/citation states

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P1 (frontend agent has no way to verify its work beyond `build`) |
| **PRD ref** | UI-1, QA-3, QA-4, QA-5; Product PRD §7 principles |
| **Depends on** | ArxivLens #64 (`085183e`) and #67 (`4c7d327`): test devDependencies + lockfile, merged |
| **Jira** | story under epic KAN-5 "Research UI & citations" (`labels = "task-FE-1"`) |
| **Design required** | no |
| **Status** | In QA: draft PR [#68](https://github.com/MaheshPulivarthi18/ArxivLens/pull/68), head `50f1963`, CI green |

## Goal
Give the frontend agent a fast feedback loop and lock down the states that carry the product's trust promise.

## Scope
- **Dependencies are already present** (`vitest`, `@testing-library/react`, `@testing-library/jest-dom`,
  `@testing-library/user-event`, `jsdom` in `frontend/package.json` + `package-lock.json` since #64/#67). FE-1 adds only:
  - `frontend/package.json`: a `"test": "vitest run"` entry in `scripts`. **No change to `dependencies` or `devDependencies`**:
    the lockfile can't be regenerated in the sandbox, and a mismatch makes CI's `npm ci` fail.
  - `frontend/vitest.config.js` (or a `test` block in `frontend/vite.config.js`): `environment: 'jsdom'`, `setupFiles`, `globals` as you choose.
  - `frontend/src/test/setup.js`: imports `@testing-library/jest-dom/vitest`, runs `cleanup` after each test.
  - Test files next to the components (`*.test.jsx`) and fixtures in `frontend/src/test/fixtures.js`.
  - `frontend/README.md`: a Commands section listing `npm test` (replace the Vite template boilerplate if you like).
- Tests (with fixture `AskResponse` objects matching `internal/query/rag.go`):
  - `SynthesisView`: renders answer text with `[n]` markers; renders a refusal as a normal state (not an error toast)
  - `ReferencesStack`: each citation shows title, section, and a link to `pdf_url`; `supported: false` is visibly flagged; BibTeX copy calls `onCopy` with an `@article{arxiv_...` string
  - `HeroSearch`: submitting calls the provided handler with the trimmed question; empty input does not submit
- Out of scope: visual redesign (FE-0), E2E (Playwright) — later task, any dependency change, `index.css`/`tailwind.config.js`/`main.jsx`/`components/ui/` (FE-0 owns those this cycle).

## Acceptance criteria
- [ ] AC1 — CI's frontend job runs `npm test` (the existing "Test (if FE-1 has added a test script)" step) and it passes, with the Vitest run under 30 s and no network access in tests. Local run: "not run: npm registry unreachable" is acceptable (AGENTS.md §4).
- [ ] AC2 — ≥ 8 test cases across the three components, including refusal and unsupported-citation cases.
- [ ] AC3 — If a test reveals that unsupported citations are *not* flagged in the UI, fix it (frontend-only) and note it.
- [ ] AC4 — `npm run lint` and `npm run build` still pass in CI; `frontend/README.md` lists `npm test` (there is no `frontend/AGENTS.md`).
- [ ] AC5 — `git diff origin/main -- frontend/package.json` touches only `scripts`; `frontend/package-lock.json` is unchanged.

## Verification
```bash
# CI (source of truth): the frontend job in .github/workflows/ci.yml
cd frontend && npm ci && npm run lint && npm test && npm run build
# scope check (runs in the sandbox)
git diff origin/main --stat -- frontend/package-lock.json   # must be empty
git diff origin/main -- frontend/package.json               # only "scripts" lines
```

## Notes
- 2026-11-03 (pm-lead, from AI-2 PM review): concrete AC3 case. `ReferencesStack.jsx:70-73` renders `<ShieldCheck/> {score}% Verified` for every citation and changes only the badge variant when `supported` is false. Once AI-2 (ArxivLens #11) merges, an embedder outage shows "0.0% Verified". An unsupported citation must not be labelled "Verified" (QA-4, §7), so a test with `supported: false` should assert the badge text does not say "Verified" (e.g. "Unsupported · 0.0%"). Fix it frontend-only under AC3. The `/v1/ask` shape is unchanged.
- 2026-11-07 (pm-lead, plan): Wave 1 and on the Phase 1 critical path (FE-3 and FE-4 need the harness). Two ways to unblock it, both Mahesh's
  call: (a) allow `registry.npmjs.org` in the agent environment's network settings, or (b) run
  `cd frontend && npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom` locally and push the
  `package.json` + `package-lock.json` change to a branch `agent/frontend/FE-1`. The agent then writes the tests on top. Don't regenerate
  the lockfile any other way (e.g. from a CI artifact): that routes around the egress block.
- 2026-11-17 (pm-lead, grooming): still env-blocked (npm registry unreachable). #46 (`cc57474`) changed the components under test:
  `SynthesisView` now takes `answerKind`, `refusalReason` and `writing`, with subtitles for quoted/synthesized answers and a refusal subtitle.
  `App.jsx` runs the two-stage `quick` → full flow. Fixtures must include `answer_kind`, `synthesis_available` and a `refusal_reason`
  response. The AC3 case still applies: `ReferencesStack.jsx:72` still renders `{score}% Verified` for every citation, including unsupported ones.
- 2026-11-19 (pm-lead, grooming): **unblocked.** Mahesh merged #64 (`085183e`, vitest ^4.1.12, @testing-library/react ^16.3.3,
  @testing-library/jest-dom ^6.9.1, @testing-library/user-event ^14.6.13, jsdom ^29.1.1) and #67 (`4c7d327`, UI primitives + fonts,
  and cleared the oxlint warnings). The env block is gone for dependencies; agent sandboxes still can't reach registry.npmjs.org
  (`curl` → `000`), so verify through CI on the draft PR. Scope narrowed to the script, config, setup file and tests: don't touch
  package.json dependencies. The old AC4 named `frontend/AGENTS.md`, which doesn't exist; it's `frontend/README.md` now.
  FE-0 runs in parallel on disjoint files (`index.css`, `tailwind.config.js`, `main.jsx`, `index.html`, `components/ui/`, `Navbar.jsx`):
  keep FE-1 off those. Tests should assert on text and roles, not on class names, so FE-0's restyle doesn't break them.
  The AC3 badge fix (`ReferencesStack.jsx`) stays in FE-1.
- 2026-11-19 (frontend-engineer, build): draft PR [ArxivLens #68](https://github.com/MaheshPulivarthi18/ArxivLens/pull/68) on `agent/frontend/FE-1`, head `50f19631`.
  CI is all green on the head commit. Frontend job: oxlint "0 warnings and 0 errors". Vitest: 3 files, 19 tests passed, Duration 2.72s. The build passes.
  Not run locally because the npm registry is unreachable (`npm view` timed out).
  - [x] AC1: CI `npm test` passes in 2.72 s; data comes from fixtures through props, so no network.
  - [x] AC2: 19 cases (SynthesisView 6, ReferencesStack 8, HeroSearch 5), including refusal and unsupported/unverified.
  - [x] AC3: fixed in `ReferencesStack.jsx`. Only a supported citation says "Verified". `supported: false` shows "Unsupported · x%" and `status: unverified` shows "Unverified · x%", with an amber ShieldAlert badge. The label comes from `status` (ADR-0014), falling back to `supported`.
  - [x] AC4: lint and build pass in CI. `frontend/README.md` has a Commands table with `npm test`.
  - [x] AC5: package.json diff touches only `scripts`; package-lock.json is unchanged.
  - Also added a11y labels: `role="article"` + aria-label on citation cards, per-citation labels on Open PDF and Copy BibTeX, and a "Research question" label on the HeroSearch input.
  - Follow-up candidates: (1) SynthesisView still shows a static "PostgreSQL pgvector Verified" footer on refusals (§7 honest refusals). (2) CI's `npm run | grep -q " test"` logs a harmless `npm error` (EPIPE) in the test step (backend owns ci.yml).
  - Jira KAN-19: no Atlassian tools in this session, so I didn't transition the story or comment; pm-lead should move it to In QA and link #68.
