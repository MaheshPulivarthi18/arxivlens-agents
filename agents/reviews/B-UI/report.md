# QA report: B-UI · PR #132 · round 1 · tier Large

**Verdict:** FAIL (2 blocking findings, both test gaps in the risky quote-locating code. The production code is correct on every probe I ran.)
**Reviewed commit:** `5cc1cdd6cc1c7d34d506172ad0deb59c4eb79984` · **Date:** 2026-11-28
**Ticket:** `agents/tasks/B-UI.md` · **Design:** `docs/design/FE-4.md` §1, §3, B-UI addendum, PM decision 2026-11-28 · **PRD:** UI-1, UI-5, QA-3, QA-4, §7
**Reviewer inputs:** ticket, design, diff `origin/main...5cc1cdd`, CI check runs and job logs. I did not use the developer's self-report.
<!-- Provenance: the qa-reviewer harness refused to write report.md ("subagents return findings as text"). This text was posted as the PR #132 comment and returned to the orchestrator to save verbatim. -->

Evidence base (E): https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/d05849e09518834f036b51dccd830f9cb96f3535/agents/reviews/B-UI/evidence/
Each `NN-*.png` (append `?raw=true`) has a `.txt` next to it with the full output.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 140708439681 | success |
| Python M0 unit tests | CI job 140708440019 | success |
| DB (migrate twice, HNSW) | CI job 140708439519 | success |
| Frontend (lint, test, build) | CI job 140708439994 | success. oxlint 0 warnings / 0 errors (main `5fcbd5f`: 0). 13 files / **261 tests** passed (main: 216). `vite build` OK (E/02) |
| Agent ownership check | CI job 140708439931 | success, "Ownership OK for role=frontend (745 changed lines)" (E/01) |
| `npm ci && npm run lint && npm test && npm run build` | not run locally: npm registry unreachable from the sandbox | CI is the source |
| Lib tests under a node shim | local, logic check only | `citations.test.js` 78/78, `bibtex.test.js` 6/6, the same counts as CI (E/04) |
| JS `normQuote` vs Go `normQuote` (copied verbatim from `rag.go`) | local, Go 1.24 stdlib-only | 25/25 identical, incl. NBSP, U+2009, U+3000, U+0085, `\v`, U+FEFF (E/07) |
| `make eval` | not applicable | frontend only, no retrieval or answering change |

CI check runs: E/00-ci-checks. Every job on `5cc1cdd` is completed / success.

## Scope
There are 10 changed files, all under `frontend/src/` (E/01). No ticket, review or doc files are in the PR, and nothing out of scope changed: no API, `rag.go`, README or PDF viewer. `test/fixtures.js` is unchanged because the existing fixtures were enough. No new dependency.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 quote in passage | ⚠ code correct, tests incomplete (F1, F2) | `locateQuote` table has every row the AC names: `\n`, double spaces, `[12]`, `[3, 4]`, `[5–7]`, space before `.`, case → null, empty/whitespace → null, NBSP `[3, 4]` keeps the ref (E/04). Ticket mutants case-insensitive and drop inline-ref, plus RE2 `\s` → JS `\s` (condition 5), are all killed (E/05). JS/Go parity is 25/25 (E/07). Component tests (CI) cover: mark = raw span with sr-only "Quote: ", the not-found block, the no-quote note, unsupported/not-checked with a quote getting no mark and no note, and the long-passage excerpt holding the mark with `aria-expanded` toggling (E/09). **But** "the `<mark>` covers only raw text that normalises to the quote" is not pinned when the quote starts after offset 0 (F1), and the Unicode collapse is not pinned (F2) |
| AC2 provenance + PDF page | ✅ | `pdfHref/arxivLabel/metaLine` tables cover page 4, 0, null, `"4"` and absent, plus fragment replaced, fallback URL, v0 and empty section. Mutants `>= 0`, `Number(page)`, keep `#fragment`, `v >= 0` and bare `§` are all killed (E/05). The exact meta-line assert replaces `ReferencesStack.test.jsx:30`, and no `Chunk #`/`General`/`Section:` remains. Link text/href per page value (E/09) |
| AC3 cited-by rows | ✅ | `App.test.jsx` (CI pass, named in E/02): with `synthesizedSkips`, clicking the second `[1]` makes row 2 `aria-current="true"` and exactly 1 current, then the first `[1]` moves it back. With `brokenPositional` the rows read "Check 1/2" and no "Cited by claim". Code: `current = isHighlighted && active?.pos === pos` (E/10). "Row ignores pos" mutant, static only: both rows would be current, so `toHaveLength(1)` fails |
| AC4 one honest BibTeX builder | ✅ | `bibtex.test.js` 6/6 (CI + shim). Real output (E/08): the only fields across every fixture export are `title, eprint, archivePrefix, year, url`. No `author =`, no `primaryClass =` and no `year = {2026}`. `year` is 2024/2006 from the ID and omitted for `nope` and for month-13 `2413.01234`. Escaping is right, keys are stable, and an empty ID gives no entry. The card's "Copy BibTeX" is `toBe(bibEntry(cit))`, and the old hard-coded handler is deleted |
| AC5 Export all | ✅ | Tests (CI): Tab to "Export", `{Enter}` and Space each open the menu, Enter on "BibTeX (.bib)" gives one download, the filename matches `^arxivlens-\d{8}-\d{6}\.bib$`, and the blob contents and toast text are checked. A written answer drops the unsupported citation, and refusal mode has no trigger (the addendum chose *absent*) (E/09). `synthesizedSkips` → 2 entries from 3 citations, deduplicated (E/08) |
| AC6 older/partial responses | ✅ | `AC6: an older citation…` (CI) shows the meta line without `v`, a plain `pdf_url`, the chip, the full content, no mark and no note. The whole-tree no-"Verified" tests are untouched: the only removed test lines are the assertions AC7 names, each replaced by a stricter one (E/03) |
| AC7 CI green, nothing weakened | ✅ | E/00, E/02: 0 lint warnings (= main), 216 → 261 tests, build OK. E/03: no test was deleted. The PR body lists the `:30` replacement |
| Docs | ✅ | The B-UI addendum and PM decision are in `docs/design/FE-4.md`. The PRD flip comes after merge (pm-lead) |

### PM conditions (design › PM decision B-UI addendum)
1. **Tagline**: ✅ The text is "Evidence-Grounded Answers with Cited Passages", and the `HeroSearch.test.jsx` assert checks both the new text and that "Sentence-Level Verification" is gone (E/12, CI E/02).
2. **Markdown note**: ✅ The heading is `# ArxivLens Research Note`, and ` (§ …)` appears only for a non-empty section. There is a test, and mutant M17 "always print `(§ )`" is killed (E/05).
3. **Size**: ✅ **acceptable**. My count from `git diff --numstat` is 745 changed lines: **production 428** (ReferencesStack 279, citations.js 76, bibtex.js 68, App 3, HeroSearch 2) and **tests 317**. The "360 + 385" split in the PR body is wrong (F5). That is over the ~520 estimate but under the 800 cap. It is one coherent outcome in 10 files, all in `frontend/`, and a reviewer can follow it. Most of the growth is ReferencesStack (+212/−67): FE-4a's chip markup moved into a `Chip` component, plus the `Passage`/`Marked`/excerpt logic. That is in scope, not creep. The PR body lists the two string changes under "Label honesty" ✅.

### Undocumented developer choices
- **No-quote note only on explicit `status: "supported"`**: **OK, keep.** AC6 needs it: a pre-quote response (`supported: true`, no `status`) must render as `main`. The note also claims "the check compared the claim with the whole passage", and a legacy response can't back that up. So the guard is the honest choice. Record it in the design (F4).
- **Extra `onNotify` prop**: **OK, keep.** The addendum requires the toast "Exported n references (.bib)". The existing `onCopy` has clipboard semantics, so a separate notifier (`showToast`) is the minimal correct wiring: +1 line in `App.jsx`, inside `frontend/`. The design says "2 props" and the code passes 3, so record it (F4).
- **arXiv badge removed from the card header**: **OK, keep.** AC2 (ticket and addendum) defines one meta line that starts with `arXiv:<id>v<N>`. Keeping the badge would show the ID twice. Design §3 put `arxivLabel` "in the existing `arxiv` badge", but the later ticket AC2 supersedes that. Record it (F4).

### Label honesty
No UI label says "Verified"/"verification" for unchecked citations. The non-test grep at head (E/12) finds only code comments, the `verification_unavailable` refusal key and fixtures. Status mutants (supported/false disagreement, unverified → Supported, unknown → Supported) are all killed (E/05). The remaining "Clinical" strings are out of scope by the PM decision. The `.bib` header states plainly that it has no authors.

## PRD fit
This delivers UI-1/QA-3/QA-4 as the PRD describes them. The exact supporting words are highlighted in their passage, the line shows the paper version, section and page, and the PDF opens at that page in one click (§7 principle 3). UI-5 export is delivered too: a `.bib` with only real fields (principle 1, no fabricated metadata). A refusal offers no export (honest refusals). It isn't PASS yet only because the highlight's raw-offset mapping, the part a reader trusts as "these are the exact words", is not pinned by any test.

## Findings
1. **[blocking] Mutant M9 survives: the raw start offset of the `<mark>` is untested.** `locateQuote` returns `start: at[k]`. Replacing it with the normalised index `k` passes all 78 lib tests (E/05). The reason is that every normalised-path row, and the `quotedClaims` component quote, starts at offset 0. The long-passage test takes the direct `indexOf` path. Under M9 a user would see the wrong words highlighted as "Quote:" whenever a ref or extra whitespace precedes the quote. **Fix:** add `locateQuote` rows where something before the quote normalises away. QA's probe rows `'As shown [12]  earlier, hybrid\nsearch works well.'` / `'hybrid search works'` and `'Intro.\n\n\nWe  verify  each claim.'` / `'We verify each claim.'` pass on head and kill M9 (E/06).
2. **[blocking] Mutant M13 survives: the Unicode whitespace collapse is untested.** PM condition 5 says the collapse step mirrors `strings.Fields`. Shrinking `GO_SPACE` to ASCII passes every test. The NBSP `[3, 4]` row covers only the regex step. On the server, `strings.Fields` collapses NBSP/U+2009 between words (E/07), and PDF-extracted text contains them. Under M13 a server-validated quote shows the "not found" block. **Fix:** add rows such as `'hybrid search works'` / `'hybrid search works'` and `'a b c'` / `'a b c'`. Both pass on head and kill M13 (E/06).
3. **[nit] Mutant M7 survives: the whitespace-only guard `!quote.trim()`.** The row uses content `'abc'`, so the later `if (!q)` returns null anyway. With content that contains the whitespace (`locateQuote('a \n b', ' \n ')`), M7 returns a range over whitespace (E/06). The server never sends a whitespace-only quote on a supported citation, so this is a nit. Change the row's content.
4. **[nit] Record the three choices in `docs/design/FE-4.md` › B-UI addendum** (a short "as built" note): the no-quote note on explicit `status` only, the `onNotify` prop, and the badge folded into the meta line. All three are judged OK above. A justified deviation is written into the design.
5. **[nit] The PR body's "Size" breakdown is wrong.** numstat gives production 428 / tests 317, not 360 / 385, so the overrun is mostly production code, not tests. pm-lead should use the corrected figures in the final description.

## Missing tests
- The F1/F2/F3 rows above (required for F1/F2).
- Optional: Export item disabled when `count === 0` (addendum: "`count === 0` → item disabled"). Not reachable on real responses under ADR-0019, but it is specified.
- Optional: a > 480-char passage with no highlight (first 320 chars, trailing `…`).

## Mutation (risky code only; local scratch copies, never pushed)
Scope for this review: quote locating and citation status in `frontend/src/lib/citations.js`. No styling or classNames. There are 18 mutants: **15 killed, 3 survived** (E/05). Harness sources are in E/13: a node vitest shim, esbuild from `/opt/npm-tools`, and each mutant asserted to apply exactly once.

| Mutant | Result | Killed by |
|---|---|---|
| M1 / M1b case-insensitive (direct / normalised path) | killed | `locateQuote › case mismatch` |
| M2 drop inline-ref step | killed | `› inline [12]`, `[3, 4]` |
| M3 RE2 ASCII class → `\s` | killed | `› NBSP [3, 4] keeps the ref` |
| M4 `page >= 0` · M5 `Number(page) >= 1` | killed | `pdfHref › page 0`, `page 4` |
| M6 drop spaceBeforePunct | killed | `› space before .` |
| **M7 whitespace guard `!quote`** | **survived** | F3 |
| M8 mark end off by one | killed | `› \n inside`, `double spaces` |
| **M9 mark start = normalised index** | **survived** | F1 |
| M10 keep `#fragment` · M11 show `v0` · M12 bare `§` | killed | `› replaces an existing fragment…` |
| **M13 collapse ASCII-only** | **survived** | F2 |
| M14/M15/M16 status → Supported (disagreement / unverified / unknown) | killed | `citationState` rows |
| M17 markdownNote `(§ )` | killed | `markdownNote › … only for a non-empty section` |

The ticket mutants in `ReferencesStack.jsx` (highlight guard, row ignores pos) were **not executed**. They are outside the lib-only scope set for this review, and the component tests need RTL/Radix, which this sandbox can't install. Static reading (E/11, E/10): without the guard, `unsupportedCitation` (content "Entailment scores fall…", quote "Entailment scores") would get a mark, and `AC1: unsupported with a quote` asserts `marks() == []`. With pos ignored, both rows would be current, and the AC3 test asserts exactly one.

## UI screenshots
Not produced this round. An offline Chromium render of the real page needs the Radix collapsible + dropdown-menu sources (git clone) and a Tailwind build. Given a FAIL on test gaps, I've left that for round 2. The jsdom component tests in CI are the UI evidence for this round. No mock images are substituted.

## Evidence index (E = base URL above)
00-ci-checks · 01-scope-diffstat · 02-ac7-ci-frontend-head-vs-main · 03-ac7-test-lines-removed · 04-ac1-ac2-ac4-lib-tests-shim-head · 05-mutants-citations · 06-gap-rows-head-vs-survivors · 07-ac1-normquote-parity-go-vs-js · 08-ac4-ac5-bib-output-probe · 09-ac1-ac2-ac5-ac6-component-tests · 10-ac3-cited-by-rows · 11-ac1-highlight-guard-static · 12-label-honesty · 13-qa-harness-sources

## Hand-off
FAIL → back to frontend-engineer (rework round 1 of 2, same PR #132). F1 and F2 are blocking. F3–F5 are nits to fix in the same rework. If any nit is left unfixed, it goes on the ticket's `## Checklist` (no follow-up tickets).

---

# Round 2 · PR #132 · head `5fa2790d7e5b242989f030186efaf7fae25aa05e` · 2026-11-28

**Verdict: PASS.** All five round-1 findings are resolved. The 3 surviving mutants are now killed (18/18), and CI is green on every job.
Round 2 checks only the round-1 findings, as instructed. The rework touches nothing else.
Evidence base (E2): https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/a272557c3b954e27e8336d2438701dd2e196d631/agents/reviews/B-UI/evidence/

## What changed since round 1
There is one commit, `5fa2790`. It changes `frontend/src/lib/citations.test.js` only (+12 / −1) and adds no production change (E2/21-r2-rework-diff).
The total against main is 756 changed lines: production 428 (unchanged), tests 328. That is under the 800 cap, and "Ownership OK for role=frontend (756 changed lines)" (E2/22-r2-ci-frontend). Round 1 judged 745 acceptable, and the +11 lines are test rows, so the size is still acceptable.

## Test results
| Check | Source | Result |
|---|---|---|
| Go, Python M0, DB, Frontend, Agent ownership | CI at `5fa2790` (E2/20-r2-ci-checks) | all completed / success |
| Frontend job 140713597717 | CI log (E2/22) | oxlint 0 warnings / 0 errors (= main). `citations.test.js` 83 tests. **266 passed** (r1: 261). Build OK |
| Lib tests under the node shim | local, logic check (E2/23) | `citations.test.js` 83/83, `bibtex.test.js` 6/6 (same counts as CI) |
| `npm ci/lint/test/build` locally | not run: npm registry unreachable | CI is the source |

## Round-1 findings
| # | Finding | Status | Evidence |
|---|---|---|---|
| F1 | [blocking] M9 mark start offset untested | ✅ fixed | Rows `ref + spaces before` and `newlines + spaces before`, plus an exact-offset test (`{start: 24, end: 43}`, `{start: 9, end: 32}`). **M9 killed** by those rows (E2/23) |
| F2 | [blocking] M13 Unicode collapse untested | ✅ fixed | Rows `NBSP between words` and `U+2009 between words`. **M13 killed** by both (E2/23). These are the inputs the Go-parity run in round 1 showed `rag.go` collapsing (E/07) |
| F3 | [nit] M7 whitespace guard | ✅ fixed | The `whitespace quote` row now uses content `'a \n b'`. **M7 killed** (E2/23) |
| F4 | [nit] record as-built choices in design | ✅ fixed | `docs/design/FE-4.md` › B-UI addendum "As built (2026-11-28, PR #132…)" items 1–3: no-quote note on explicit status, `onNotify`, badge folded into the meta line (E2/24) |
| F5 | [nit] PR body size split wrong | ✅ fixed | The PR body "Size" now reads 756 = production 428 + tests 328 (E2/24) |

## Mutation (local scratch copies, never pushed)
I used the same harness and the same 18 mutants as round 1 (sources in E/13, unchanged), run against `5fa2790`: **18 killed, 0 survived** (E2/23). The previously surviving M7, M9 and M13 are now killed by the new rows named above. The component mutants (highlight guard, row ignores pos) are still covered by static reading only, as in round 1. That code is unchanged since round 1.

## Findings (round 2)
None.

## PM-equivalent check (lean combined path; design-approved bundle)
- **Product fit against the ticket's Goal**: ✅ A researcher can check an answer sentence in one or two clicks:
  - the card highlights the exact supporting words inside the passage (`<mark>` + sr-only "Quote: ");
  - it shows `arXiv:<id>v<N> · § <section> · p. <N>`;
  - it opens the PDF at that page ("Open PDF at p. N ↗", `#page=N`).
  The whole answer's references export as one `.bib`. "No label claims more than the system checked" holds:
  - there is no "Verified" label;
  - the tagline and the note heading are honest;
  - unsupported and not-checked citations get no highlight;
  - the `.bib` has no fabricated author, year or `primaryClass` (r1 E/08, E/12).
- **PRD**: UI-1 / QA-3 / QA-4 / §7 principles 1 and 3 are delivered, and UI-5 is delivered for export (saved questions stay open, as the ticket says). ADR-0019 is respected: a written answer exports supported citations only. ADR-0018 (Proposed) is respected: `answer_kind` absent is treated as quoted.
- **Scope**: frontend-only. There is no API, `rag.go`, README or PDF-viewer change. The PM decision's two label-honesty edits are included and listed in the PR body. There are no out-of-scope edits.
- **Docs**: the design addendum, PM decision and as-built note are in `docs/design/FE-4.md`. After merge, pm-lead flips Product PRD UI-5 to ✅ for export and updates the UI-1 note (docs PR, per ticket).
- **Ticket checklist**: no open items. All five round-1 findings were fixed in this PR, with no follow-up tickets.
- **UI screenshots**: none in either round. The offline Chromium harness was not built. The UI evidence is the jsdom component tests in CI. Mahesh may want to view the cards on a live stack before merging.

## Evidence index (round 2, E2 = base URL above)
20-r2-ci-checks · 21-r2-rework-diff · 22-r2-ci-frontend · 23-r2-mutants · 24-r2-design-and-pr-size (round-1 files 00–13 still apply)

## Hand-off (round 2)
PASS → pm-lead final review and raise. `qa-fail` is removed and `qa-pass` set on PR #132. The PR stays draft. Jira is untouched (per coordinator).
