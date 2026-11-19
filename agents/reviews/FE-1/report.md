# QA report — FE-1 · PR #68 · round 1

**Verdict:** PASS
**Reviewed commit:** `50f19631e91a86b3934f4ad7e88c48238b64ceac` · **Date:** 2026-11-19
**Ticket:** `agents/tasks/FE-1.md` · **PRD:** UI-1, QA-3, QA-4, QA-5, Product PRD §7
**Evidence:** [agents/reviews/FE-1/evidence/](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence) (commit `80101a5`)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI 135881876044 | pass |
| Python M0 unit tests | CI 135881875118 | pass |
| Frontend (lint, test, build) | CI 135881874709 | pass: oxlint 0 warnings / 0 errors; Vitest 3 files, 19/19 passed, Duration 2.72s; vite build ok ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/00-ci-checks.png?raw=true), [01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/01-ac1-ac4-frontend-job.png?raw=true)) |
| DB (migrate twice, HNSW plan + recall) | CI 135881874411 | pass (not affected) |
| Agent ownership check | CI 135881875252 | pass |
| Ticket verification `npm ci && npm run lint && npm test && npm run build` | local | **not run locally: registry.npmjs.org unresolvable, `npm ci --offline` → ENOTCACHED** ([09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/09-local-npm-unreachable.png?raw=true)); CI is the source of truth |
| Ticket scope commands (lockfile / package.json diff) | local | run: lockfile diff empty, package.json diff only `scripts` ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/08-ac5-scope.png?raw=true)) |
| AC3 mutation probe (real `verification()` + real fixtures, outside the PR) | local, node 22 | revert of AC3 KILLED; 4/6 mutants killed, 2 survivors on contract-inconsistent input only ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/05-ac3-mutation-probe.png?raw=true), source [06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/06-ac3-probe-source.png?raw=true)) |
| `make eval` | — | not applicable (frontend-only; no retrieval/answering change) |

CI ran on `refs/pull/68/merge` = merge of 50f1963 into `4c7d327`, which is current `origin/main` (log line "HEAD is now at 54833ce Merge 50f19631… into 4c7d3274…", in [01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/01-ac1-ac4-frontend-job.png?raw=true)). PR is open, draft, not merged. Open PRs #65/#66 touch no `frontend/` files.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 — CI runs `npm test`, passes, < 30 s, no network | ✅ | Frontend job: "Test (if FE-1…)" step runs `> vitest run`, `Tests 19 passed (19)`, `Duration 2.72s` ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/01-ac1-ac4-frontend-job.png?raw=true)). No `fetch`/axios/XHR/WebSocket/msw in tests, setup, fixtures or the three components; jsdom env, data via props ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/02-ac1-no-network.png?raw=true)). Local: not run (npm unreachable, [09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/09-local-npm-unreachable.png?raw=true)). |
| AC2 — ≥ 8 cases incl. refusal + unsupported | ✅ | 19 `it(` cases: SynthesisView 6, ReferencesStack 8, HeroSearch 5 ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/03-ac2-test-inventory.png?raw=true)); count equals CI's "19 passed". Refusal: `SynthesisView.test.jsx` "renders a refusal as a normal state…" (refusal_reason fixture, asserts answer text, "No verified answer" subtitle, no quoted/written subtitle, no `role=alert`). Unsupported: `ReferencesStack.test.jsx` "flags supported: false visibly and never calls it Verified", "…even without a status field", and "…Unverified, not 0.0% Verified". |
| AC3 — unsupported citations flagged; fix frontend-only | ✅ | `ReferencesStack.jsx` `verification()`: only `status==='supported' && supported!==false` renders "x% Verified"; otherwise amber ShieldAlert "Unsupported · x%" / "Unverified · x%" ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/04-ac3-diff.png?raw=true)). Would the tests catch a revert? Yes: running the real function on the real fixtures, the origin/main behaviour (every badge "x% Verified") fails 3 test rows; dropping the unverified branch, ignoring `status`, or mapping unknown statuses to Verified are each killed ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/05-ac3-mutation-probe.png?raw=true)). Note: the probe mirrors the test file's badge-text regexes; it is not a Vitest run (none possible locally). The citation is still listed, with its PDF link (asserted in the same test). |
| AC4 — lint + build pass in CI; README lists `npm test` | ✅ | oxlint "Found 0 warnings and 0 errors", "✓ built in 769ms" ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/01-ac1-ac4-frontend-job.png?raw=true)); `frontend/README.md:14` lists `npm test` ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/07-ac4-readme.png?raw=true)). |
| AC5 — package.json only `scripts`; lockfile unchanged | ✅ | package.json diff = one `"test": "vitest run"` line (+ trailing comma); lockfile diff 0 lines ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/08-ac5-scope.png?raw=true)). |

## Scope check
All 10 changed files are under `frontend/` (frontend-engineer's area); none of FE-0's files (`index.css`, `tailwind.config.js`, `main.jsx`, `index.html`, `components/ui/`, `Navbar.jsx`) are touched; no ticket/review/doc files leaked ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/08-ac5-scope.png?raw=true)). Small additions outside the listed test files: `aria-label` on the HeroSearch input, `role="article"` + aria-labels on citation cards and their PDF/BibTeX buttons. They exist so tests query by role/name (as the PM grooming note asks) and improve accessibility; no dependency change. Accepted, not scope creep. Vitest config went into `vite.config.js` (`test` block), which the ticket allows.

## PRD fit
Delivers the harness and locks the trust-carrying states: refusals render as a normal state (§7 honest refusals), every citation keeps a one-click PDF link (UI-1, §7 one click to source), and an unsupported or unchecked citation can no longer read "Verified" (QA-4), which closes the "0.0% Verified" case from the AI-2 review. Fixtures follow `AskResponse`/`Citation` in `internal/query/rag.go` (`status`, `answer_kind`, `synthesis_available`, `refusal_reason: all_citations_unsupported` all exist there).

## Findings
1. [nit] Two mutants of `verification()` survive the tests ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/05-ac3-mutation-probe.png?raw=true)): M1 (drop `&& cit.supported !== false`) changes the badge only for `status:"supported", supported:false` (renders "87.3% Verified"), and M2 is equivalent for any response that carries `supported` (it's a non-omitempty bool in rag.go). The backend shouldn't emit that inconsistent pair, so the guard is defensive; a one-line test row would pin it.
2. [nit] Follow-up, pre-existing on main and outside FE-1's ACs: on a refusal, `SynthesisView` still shows a ShieldCheck "PostgreSQL pgvector Verified" footer, and the Markdown export is headed "References & Verified Citations" for unsupported citations too ([10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/10-followup-synthesis-verified-footer.png?raw=true)). That conflicts with §7 / QA-4 in spirit; the developer already listed it as a follow-up. Suggest a pm-lead ticket.
3. [nit] CI step "Test (if FE-1 has added a test script)" logs an `npm error A complete log…` line (the `npm run | grep -q` pipe closing early). Harmless, step green; backend owns `ci.yml`. Now that the script exists, the conditional can become plain `npm test`.
4. [spec] The ticket says "not an error toast" for refusals; toasts live in `App.jsx`, which the ticket doesn't put under test. I confirmed by reading `App.jsx` that a refusal flows into `SynthesisView` as data (only HTTP/network failures reach `console.error`/toast), but no test covers that path. Candidate for the FE-3/FE-4 App-level tests.

## Missing tests
- `status:"supported"` with `supported:false` → must not say Verified (pins M1).
- Reserved statuses (`partially_supported`, `contradicted`, ADR-0014) → not "Verified" (behaviour is fail-closed today, but only M5 covers it indirectly).
- App-level: a `refusal_reason` response shows no toast and keeps ReferencesStack visible (needs `fetch` mocked; future task).

## UI screenshots
Not produced: `node_modules` can't be installed in the QA sandbox (npm registry unreachable, [09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/80101a5736f031f55e9469816e3f459fa311e0ea/agents/reviews/FE-1/evidence/09-local-npm-unreachable.png?raw=true)), so the dev server can't run. No mock images substituted.

## Hand-off
PASS → pm-lead final review.

---

# PM review — FE-1 · PR #68 · head `50f1963`

**Verdict:** APPROVE
**Reviewer:** pm-lead · **Date:** 2026-11-19 · **QA verdict reviewed:** PASS r1 (above), head confirmed unchanged at `50f19631e91a86b3934f4ad7e88c48238b64ceac`

## What I checked
- Ticket `agents/tasks/FE-1.md` (5 ACs, scope, out-of-scope list), Product PRD UI-1, QA-3, QA-4, QA-5 and §7.
- PR diff (`pulls/68/files`): 10 files, all under `frontend/`, +322/−17. I read the three test files and `fixtures.js` in full.
- All 11 evidence pairs (`00`–`10`, PNG and `.txt`); each PNG matches its `.txt` and is pinned to commit `50f1963`.

## Evidence vs ACs
| AC | Evidence | PM view |
|---|---|---|
| AC1 | 00 (5/5 checks green on the head), 01 (CI job log: `vitest run`, 19/19, 2.72 s; merge base `4c7d327` = current main), 02 (no network APIs; jsdom; data via props) | Proven. 2.72 s ≪ 30 s. Local "not run" is backed by 09 and allowed by AGENTS.md §4 |
| AC2 | 03 (19 `it(` cases, 6/8/5) matching CI's "19 passed" | Proven. Refusal and both unsupported/unverified cases are present and assert the right things (I read them) |
| AC3 | 04 (diff), 05 + 06 (mutation probe on the real function and fixtures) | Proven. Reverting to main's "x% Verified" fails 3 tests. The two surviving mutants only matter for input the backend doesn't send (`status: supported` with `supported: false`). This closes the "0.0% Verified" case from the AI-2 review |
| AC4 | 01 (oxlint 0/0, vite build ok), 07 (README line 14) | Proven |
| AC5 | 08 (package.json: only `"test"`; lockfile diff 0 lines; no FE-0 files; nothing outside `frontend/`) | Proven |

No AC depends on a "⚠ unverified" item. There are no UI screenshots because the dev server can't run in the sandbox (09). For FE-1 that's acceptable: it's a test harness plus one badge-label change, and the rendered badge text is asserted by tests that ran in CI. FE-3 is the user-visible refusal UI, so it will need real screenshots.

## Product fit
- **§7 "Evidence first" / QA-4:** an unsupported or unchecked citation no longer says "Verified". The card is still listed, with its score and PDF link, so the user sees the evidence and how weak it is.
- **§7 "One click to the source" / UI-1, QA-3:** the per-citation PDF link (and its arXiv fallback) is now covered by tests, and so are the `[n]` marker buttons.
- **§7 "Say I don't know" / QA-5:** a refusal renders as a normal state with no `role=alert`. The App-level "no toast" path isn't tested (QA finding 4); it goes to FE-3.
- **Scope:** right-sized. The a11y labels (`role="article"`, per-citation `aria-label`s, the input label) exist so tests can query by role, as my grooming note asked, and they help screen-reader users. No dependency changes, and FE-0's files are untouched.
- **Docs:** `frontend/README.md` updated. PRD status columns don't change: UI-1/QA-3/QA-5 are already ✅. QA-4 stays ◐ because its remaining gap is the backend fail-closed path (AI-2), not the UI label.

## QA findings: disposition
1. [nit] M1/M2 survivors → added to FE-3's notes as an extra test row (`status: supported` + `supported: false` → not Verified; reserved ADR-0014 statuses → not Verified).
2. [nit] "PostgreSQL pgvector Verified" footer and the "Verified Citations" export heading → already FE-3 AC5. No new ticket; I added a pointer to FE-3's notes.
3. [nit] ci.yml `npm run | grep -q` EPIPE noise → Backlog line (backend, P3).
4. [spec] Refusal-not-a-toast lives in `App.jsx` → FE-3 AC2 now says explicitly that it's an App-level test with `fetch` mocked (FE-3 note). I'm not counting it against FE-1: the ticket asked for `SynthesisView` tests, and those are done.

**Hand-off:** APPROVE → PR #68 raised for Mahesh (description rewritten with evidence, marked ready for review). Jira KAN-19 → Ready to merge (orchestrator).
