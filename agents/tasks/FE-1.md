# FE-1: Frontend test harness (Vitest) + tests for answer/citation states

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P1 (frontend agent has no way to verify its work beyond `build`) |
| **PRD ref** | UI-1, QA-3, QA-4, QA-5; Product PRD §7 principles |
| **Depends on** | — |
| **Status** | Ready |

## Goal
Give the frontend agent a fast feedback loop and lock down the states that carry the product's trust promise.

## Scope
- Add Vitest + @testing-library/react + jsdom as devDependencies; `npm test` script (`vitest run`); config in `vite.config.js` or `vitest.config.js`.
- Tests (with fixture `AskResponse` objects matching `internal/query/rag.go`):
  - `SynthesisView`: renders answer text with `[n]` markers; renders a refusal as a normal state (not an error toast)
  - `ReferencesStack`: each citation shows title, section, and a link to `pdf_url`; `supported: false` is visibly flagged; BibTeX copy calls `onCopy` with an `@article{arxiv_...` string
  - `HeroSearch`: submitting calls the provided handler with the trimmed question; empty input does not submit
- Out of scope: visual redesign, E2E (Playwright) — later task.

## Acceptance criteria
- [ ] AC1 — `npm ci && npm test` passes in < 30 s locally, no network.
- [ ] AC2 — ≥ 8 test cases across the three components, including refusal and unsupported-citation cases.
- [ ] AC3 — If a test reveals that unsupported citations are *not* flagged in the UI, fix it (frontend-only) and note it.
- [ ] AC4 — `npm run lint` and `npm run build` still pass; `frontend/AGENTS.md` Commands table lists `npm test`.

## Verification
```bash
cd frontend && npm ci && npm run lint && npm test && npm run build
```

## Notes
- 2026-11-03 (pm-lead, from AI-2 PM review): concrete AC3 case. `ReferencesStack.jsx:70-73` renders `<ShieldCheck/> {score}% Verified` for every citation and changes only the badge variant when `supported` is false. Once AI-2 (ArxivLens #11) merges, an embedder outage shows "0.0% Verified". An unsupported citation must not be labelled "Verified" (QA-4, §7), so a test with `supported: false` should assert the badge text does not say "Verified" (e.g. "Unsupported · 0.0%"). Fix it frontend-only under AC3. The `/v1/ask` shape is unchanged.
