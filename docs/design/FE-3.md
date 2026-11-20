# Tech design — FE-3: Show refusals with their evidence, and stop labelling unchecked citations "Verified"

**Author:** frontend-engineer · **Ticket:** `agents/tasks/FE-3.md` · **PRD:** Product PRD UI-1, QA-4, QA-5, §7 principles 1–3; ADR-0003 (Accepted), ADR-0014 (Accepted), ADR-0018 (Proposed) · **Status:** Approved with changes (pm-lead, 2026-11-20; see PM decision). Split into FE-3a + FE-3b

All code references are to the app repo at `origin/main` `c37d27c` (`frontend/`). The tooltip API is from FE-0b PR #70 at `d10dc7f` (not merged yet).

## Problem
`/v1/ask` can now withhold an answer and still return the passages it found, with a `refusal_reason`
(`all_citations_unsupported`, `verification_unavailable`, `insufficient_evidence`). The UI shows that as a normal answer
card under the subtitle "No verified answer…". It renders the server's sentence as if it were the answer, offers "Copy Synthesis",
and still prints trust labels the system never checked: a static "PostgreSQL pgvector Verified" footer, a
"References & Verified Citations" export heading, and "x% Verified" on supported cards. The ask flow is also still
hard-coded dark (emerald, slate, amber), which is why FE-0 shipped with `DEFAULT_THEME = "dark"`. This design covers
AC1–AC8 and the QA follow-ups folded into the ticket Notes: an App-level "no toast" test, `status: supported` with
`supported: false`, the reserved ADR-0014 statuses, "not checked" for score 0 in a refusal, and the two-stage states.

## What the server sends (the contract this design reads)
Fields used: `answer`, `citations[].{marker, arxiv_id, title, chunk_id, section, content, pdf_url, score, supported, status}`,
`trace_id`, `refusal_reason`, `answer_kind`, `synthesis_available`. All of them are in `AskResponse`/`Citation` (`rag.go:42-96`) and the README `/v1/ask` row.
`claims`, `quote`, `page` and `paper_version` are FE-4's and are not read here.

| Response | How to recognise it | `citations` | Who renders it |
|---|---|---|---|
| Answer (quoted / synthesized) | no `refusal_reason`, `answer_kind` set | cited passages. `status` is `supported`, `unsupported` or `unverified` (a kept claim's other citations can be unchecked) | SynthesisView answer mode |
| Early refusal | `citations: []`, answer contains "No indexed papers are relevant" (`rag.go:205-210`) | `[]` | App banner (`App.jsx:84`, unchanged detection) |
| A: `all_citations_unsupported` | `refusal_reason` | every relevant hit. `unsupported` + best checked score if a check ran on it, else `unverified` + 0 (`rag.go:740-756`) | refusal mode |
| B: `verification_unavailable` | `refusal_reason` | as A; at least one hit is `unverified` | refusal mode |
| C: `insufficient_evidence` | `refusal_reason` (LLM path only) | every passage `unverified`, score 0 (`rag.go:274-280`) | refusal mode |

Two-stage flow (`App.jsx:73-117`, ADR-0018): the quick answer is always quoted. Refusals never set `synthesis_available`
(`rag.go:222`), so a quick-stage refusal never starts the writing stage. The full-stage response only replaces the quick one when
`answer_kind === "synthesized"`. A full-stage refusal (including C) is dropped and the verified quoted answer stays.
**So today C only renders if something calls the component with it directly.** The component supports it and App keeps this rule
(ticket Note 2026-11-17, open question 3).

## Approach

### 1. One status rule, shared: `src/lib/citations.js` (new, plain ESM, no JSX)
Today's `verification()` in `ReferencesStack.jsx` moves here so the card chip, the Markdown export and FE-4 all use the
same rule (and so `react/only-export-components` stays quiet).

```js
export function citationState(cit, { refusal = false } = {}) // → { kind, text, tooltip }
export function markdownNote(answer, citations)              // → string (answer mode only)
```

`kind` is one of `supported | unsupported | unchecked`. The rule is evaluated in this order:

| # | Input | `kind` | Chip text |
|---|---|---|---|
| 1 | `status === "supported"` **and** `supported !== false` | supported | `Supported · 87.3%` |
| 2 | `status === "unverified"` | unchecked | `Not checked` (no %, the score is 0 and means nothing) |
| 3 | no `status` (pre-ADR-0014 response), `refusal` and `score === 0` | unchecked | `Not checked` (ticket Note 2026-11-07) |
| 4 | no `status` and `supported === true` (answer mode) | supported | `Supported · x%` |
| 5 | anything else: `unsupported`, `supported` + `supported: false`, reserved `partially_supported` / `contradicted`, unknown strings | unsupported | `Unsupported · x%` |

The score is always `(score * 100).toFixed(1)`, the same format FE-1 tests use. Row 5 is deliberately conservative: an
unknown or reserved status can never say Supported, and `\bSupported\b` doesn't match inside "Unsupported" or "partially_supported".
"Verified" appears in no output of this module.

Tooltip text (extra help only: the chip text carries the meaning without it):

| kind | Answer mode | Refusal mode |
|---|---|---|
| supported | "Supported: a check found that this passage backs the sentence citing it (support score 87.3%)." | (never sent by the server; same text) |
| unsupported | "Unsupported: this passage was checked and doesn't back the sentence citing it (support score 12.0%). Read it before relying on that sentence." | "Unsupported: a draft statement citing this passage was checked and not supported (best support score 31.0%)." |
| unchecked | "Not checked: no check ran for this passage, because the checker was unavailable or no sentence cited it." | same |

### 2. `SynthesisView.jsx`
- **Refusal mode** (`refusalReason` truthy). The prose area becomes a refusal panel, and the `[n]` renderer is not used:
  ```jsx
  <section role="status" aria-labelledby={titleId} className="rounded-md border border-border bg-muted p-4 font-sans">
    <h3 id={titleId} className="flex items-center gap-2 text-sm font-semibold text-foreground">
      <Info aria-hidden="true" className="h-4 w-4 text-muted-foreground" /> No answer shown
    </h3>
    <p className="mt-1 text-sm text-foreground">{REFUSAL_COPY[refusalReason] ?? answer}</p>
    {citations?.length > 0 && <a href="#references-heading" onClick={focusEvidence} className="… text-primary underline underline-offset-2 FV-ring">
      Read the {n} retrieved passage{s}</a>}
  </section>
  ```
  `titleId` comes from `React.useId()`. `focusEvidence` calls `preventDefault`, then focuses `#references-heading` (it has `tabIndex={-1}`, see §3) and
  scrolls it into view (`scrollIntoView?.` because jsdom lacks it). The link makes the panel reachable in the normal Tab order (AC6)
  without the `tabIndex=0`-on-a-div anti-pattern, and it's useful: on the `lg` layout the evidence is in the right-hand column.
  Neutral styling: muted surface, an info icon, no amber or red, no `role="alert"`, no toast.
- **Copy** (for pm-lead; it avoids the word "verified" on purpose, so AC1 can assert `/verified/i` is absent from the whole tree):

  | Reason | Panel body |
  |---|---|
  | `all_citations_unsupported` (A) | "A draft answer was written, but none of its statements was supported by the passages it cited, so it isn't shown. The passages that were found are listed as evidence." |
  | `verification_unavailable` (B) | "Citation checking is unavailable right now, so the answer couldn't be checked and isn't shown. The passages that were found are listed as evidence. Try again in a moment." |
  | `insufficient_evidence` (C) | "The passages found don't answer this question, so no answer is shown. They are listed as evidence. Try rephrasing the question or indexing more papers." |
  | unknown future reason | the server's `answer` text (the server is the source of truth for a reason the UI doesn't know) |

  Header subtitle in refusal mode: "Evidence only — no answer was shown" (replaces "No verified answer — …").
- **Footer.** "PostgreSQL pgvector Verified" (`:113-116`) is removed. In answer mode the footer instead shows a plain summary from the same rule:
  "2 of 3 citations supported" (`text-xs text-muted-foreground`). This covers the *partial* state honestly. "Copy Synthesis" and "Export Note"
  render only in answer mode (open question 2 for Export).
- **Markdown export** (`markdownNote`, answer mode only): the heading `## References & Verified Citations` becomes `## References`. Each entry ends
  with `• <chip text>` instead of `• Support: x%`:
  `- [2] **Entailment Checks for Citations** (§ Results) - [arXiv:2402.05678](https://arxiv.org/pdf/2402.05678v1) • Unsupported · 12.0%`.
  The document title and the toast text are unchanged (copy, out of scope).
- **Writing indicator** (two-stage): text unchanged, `role="status"` kept; `text-emerald-400/80 animate-pulse` → `text-muted-foreground motion-safe:animate-pulse`.
- **Tokens (AC8).** The answer prose becomes `prose font-serif sm:prose-lg max-w-none` (FE-0's token-mapped typography, so `.prose` appears in the built CSS).
  `[n]` markers become `font-sans text-xs font-semibold text-primary bg-accent hover:bg-accent/70 rounded px-1 mx-0.5` + FV ring.
  The marker keeps its `title` and its accessible name `[n]` (FE-1's tests query it by that name; FE-4 owns marker semantics).
  The gradient bar is removed, and the icon tile becomes `bg-accent text-accent-foreground`.

### 3. `ReferencesStack.jsx`
- New prop `refusalReason` (string or undefined), passed by App.
- Heading `<h3 id="references-heading" tabIndex={-1} className="… focus-visible:ring…">`:
  - answer mode: "References" + badge "n cited" + the hint "Click [n] in text to inspect" (unchanged);
  - refusal mode: "Retrieved passages (no answer was shown)" + badge "n passages", no hint (there are no markers).
- Chip: `citationState(cit, { refusal: !!refusalReason })` → `<Badge variant={kind}>` with an icon
  (`ShieldCheck` / `ShieldAlert` / `CircleHelp`, all `aria-hidden`) and the chip text. The tooltip is wired as
  `<Tooltip><TooltipTrigger asChild><button type="button" className="rounded-full FV-ring">…badge…</button></TooltipTrigger><TooltipContent>{tooltip}</TooltipContent></Tooltip>`.
  The trigger is a real button, so keyboard users can open it on focus (WCAG 1.4.13). Its accessible name is the chip text, and Radix adds `aria-describedby` while it's open.
- The gauge ("Cosine Semantic Support" + `Progress`, `:102-108`) is removed. The label is wrong (the score is NLI/exact-match support, not cosine),
  it duplicates the chip's number, and in refusal mode a bar at 0 for "not checked" reads as "0% relevant", which the ticket Note forbids.
  `ui/progress.jsx` is left in place, with no callers.
- **Tokens (AC8).** Marker tile `bg-accent text-accent-foreground font-mono`. The section line goes from `text-emerald-400 font-mono` to `text-muted-foreground`.
  The passage goes from `font-mono text-slate-300 bg-background/80 border-emerald-500` to `font-serif text-sm text-foreground bg-muted/50 border-l-2 border-border`.
  The active card goes from emerald to `border-primary ring-2 ring-ring/30`. "Open PDF" gets `text-primary border-input hover:bg-accent`; the link and its `aria-label` are unchanged.
  Card `role="article"`, `id="ref-n"` and the aria-label are kept (FE-4 builds on them).
- `ui/badge.jsx`: add the `supported`, `unsupported` and `unchecked` variants (`border-transparent bg-<kind> text-<kind>-foreground font-medium`).
  Remove `verified` (its only caller goes away). Retarget `arxiv` to `border-border bg-secondary text-secondary-foreground font-mono text-[11px]`.
  Today `arxiv` is `text-cyan-400`, about 1.9:1 on light. It's also used by the trace badge, IngestModal and PapersLibrary, which all get more readable.

### 4. `App.jsx`
- Pass `refusalReason={searchResult.refusal_reason}` to `ReferencesStack`. The two-stage logic and the early-refusal detection are unchanged.
- Early-refusal banner (AC4 "renders as today": same copy, same discover button and behaviour). Only the classes move to tokens:
  `bg-muted border-border text-foreground`, with secondary text `text-muted-foreground`, the code chip `bg-secondary font-mono` and the icon `text-muted-foreground`.
  The raw gradient `<button>` becomes `<Button size="sm">` (default = ink primary), with the same label. `role="status"` is added (no visual change).
- Root `selection:bg-emerald-500/20 selection:text-emerald-300` becomes `selection:bg-accent selection:text-accent-foreground`.

### 5. Theme default flip (AC8) and `HeroSearch.jsx`
- `src/lib/theme.js` `DEFAULT_THEME = "system"` and `index.html` `var DEFAULT_THEME = 'system'`. Both "interim" comments are reworded.
  FE-0c's drift guard (if merged first) compares the two literals and needs no change.
- `HeroSearch.jsx`, 3 class swaps. The tagline pill goes from `text-emerald-400` (1.81:1 on light) to `text-primary bg-accent border-transparent`;
  the input focus ring goes from emerald to `focus-within:border-input focus-within:ring-ring/30`; the chip icons go to `text-primary`.
  It's the first screen a light-mode visitor sees after the flip. **Not in the ticket's file list → open question 1.**

### Contrast after the change (computed from `src/index.css` at `c37d27c` with FE-0's appendix script, WCAG 2.1)
| Pair | Used for | Light | Dark |
|---|---|---|---|
| `foreground` on `card` | answer prose (`--tw-prose-body`) | 16.63 | 13.79 |
| `primary` on `accent` | `[n]` marker | 7.64 | 5.88 |
| `foreground` on `muted` | refusal panel body, early-refusal banner | 14.35 | 11.80 |
| `muted-foreground` on `muted` | banner secondary text | 5.84 | 5.91 |
| `foreground` on `muted/50` over `card` | passage text | 15.46 | 12.81 |
| `accent-foreground` on `accent` | marker tile | 9.47 | 8.98 |
| `muted-foreground` on `card` | section line, footer summary | 6.77 | 6.91 |
| `{supported,unsupported,unchecked}-foreground` on their tint | chips | 7.23 / 7.55 / 7.71 | 8.41 / 7.99 / 8.82 |
| `primary` on `background` | hero tagline, refusal link | 8.56 | 8.25 |
| `ring` on `card` (1.4.11, ≥ 3:1) | focus rings | 9.09 | 7.65 |

All ≥ 4.5:1 for text. QA reruns the script against the PR's `src/index.css`.

## Alternatives considered
1. **Keep showing the server's refusal sentence as the "answer"** and only add a banner. Rejected: the server text already
   duplicates the reason, and it would sit in the prose slot styled like an answer, which is exactly the confusion principle 2 is about.
   The server text is kept as the fallback for unknown reasons.
2. **`tabIndex={0}` on the `role="status"` panel** for AC6. Rejected: a focusable non-interactive region is an a11y smell, and screen readers
   announce it oddly. A real link inside the panel puts it in the Tab order *and* does something.
3. **Keep the gauge, relabel it "Support score".** Rejected: it duplicates the chip, and a 0-width bar for "not checked" still reads as a
   measurement. Fewer elements per card also helps "evidence first": the passage is the thing to read.
4. **Status logic stays inside `ReferencesStack.jsx`.** Rejected: the export, the footer summary and FE-4's claim chips need the same rule,
   and exporting a helper from a `.jsx` trips `react/only-export-components`.
5. **Show refusal C after a quoted answer** (replace the quotes when the LLM says "insufficient"). Rejected for this ticket: the quoted
   sentences are already verified evidence, so the pm-lead Note keeps them. That's open question 3.

## Contracts and invariants
- Shared contracts touched: **none**. No API, event, schema or model change. Only documented fields are read (table above); no new field is needed.
- Product invariants: every citation stays one click from `pdf_url` (link and fallback unchanged); `supported: false` and unchecked
  citations are always listed and visibly flagged, never hidden (ADR-0003 consequence); a refusal is a `role="status"` state,
  never an error or a toast; nothing in the UI says "Verified".
- `react/only-export-components`: new helpers live in `src/lib/citations.js`. No `setState` in effect bodies (lesson 2026-11-19); this design adds no effects.
- No new dependency: `@radix-ui/react-tooltip` is already in `package.json`, and `ui/tooltip` comes from #70.

## Test plan
Fixtures (`src/test/fixtures.js`, added): `earlyRefusal` (`citations: []`, "No indexed papers are relevant…", no reason),
`refusalA` (rename of today's `refusalAnswer`: one `unsupported` 0.31, one `unverified` 0), `refusalB` (`verification_unavailable`,
one `unsupported` 0.22, one `unverified` 0), `refusalC` (`insufficient_evidence`, two `unverified` 0), `mixedAnswer` (quoted: supported +
unsupported + unverified), and citation variants `contradictorySupported` (`status: "supported", supported: false`),
`partialCitation` (`partially_supported`), `contradictedCitation` (`contradicted`) and `legacyRefusalZero` (no `status`, score 0).

| AC | Test (file › name) | Runs in CI? |
|---|---|---|
| AC1 | `SynthesisView.test.jsx › refusal A shows the A copy in a status panel`. `ReferencesStack.test.jsx › refusal mode: heading "Retrieved passages (no answer was shown)", "Unsupported · 31.0%" and "Not checked" chips, no "0.0%"`. `App.test.jsx › refusal A: whole tree has no /verified/i` (`document.body.textContent`) | yes (`npm test`) |
| AC1/AC2 (C) | the same three for `refusalC` with the C copy; every chip reads "Not checked" | yes |
| AC2 | `SynthesisView.test.jsx › refusal B copy`. **`App.test.jsx › refusal B: no toast, references visible`**: `fetch` is stubbed (`vi.stubGlobal`) to return `refusalB` for `quick: true`, and `Toast` is mocked with `vi.mock` so the test can assert it's only ever rendered with `message === ''`. Also asserts there's no `role="alert"`, the "Retrieved passages" heading is visible, and `fetch` was called once (no writing stage after a refusal) | yes |
| AC3 | `ReferencesStack.test.jsx › answer mode: "Supported · 87.3%" and "Unsupported · 12.0%"` (FE-1's "87.3% Verified" test is replaced by this, a stricter assert). `citations.test.js` table: rows 1–5 of §1, including `status: supported` + `supported: false` → Unsupported, `partially_supported` / `contradicted` / `"bogus"` → Unsupported, and for every row `text` and `tooltip` don't match `/\bSupported\b/` unless kind is supported, and never `/verified/i` (kills both FE-1 QA mutants) | yes |
| AC3 (tooltip) | `ReferencesStack.test.jsx › focusing a chip opens a tooltip with its meaning`: `user.tab()` to the chip, `findByRole('tooltip')` has text "Supported: …". Needs a `ResizeObserver` stub in `src/test/setup.js` (Radix popper; jsdom lacks it) | yes |
| AC4 | `App.test.jsx › early refusal renders as today`: the banner has "Relevance Protection Activated:", the echoed question in a `code`, and the button "⚡ Search arXiv for "…" & Index". Clicking it POSTs `/v1/papers/discover` with `{query}`. No `article` (no cards) and no "Clinical Literature Synthesis". Explicit asserts, not a snapshot (classes change for AC8) | yes |
| AC5 | `SynthesisView.test.jsx › no "PostgreSQL pgvector Verified"` (answer and refusal). `› export: "## References" heading, no /Verified/, the unsupported entry ends "• Unsupported · 12.0%", the unchecked one "• Not checked"` (clicks Export Note and reads `onCopy.mock.calls[0][0]`). `› refusal hides Copy Synthesis` (and Export, pending Q2). `› footer summary "1 of 3 citations supported"` for `mixedAnswer` | yes |
| AC6 | `SynthesisView.test.jsx › refusal panel is role=status and in the tab order`: `getByRole('status', {name: /no answer shown/i})`; `user.tab()` from the body until `document.activeElement` is inside the panel (bounded loop). `App.test.jsx › the panel link moves focus to the passages heading` | yes |
| AC6 (two-stage) | `App.test.jsx › quoted answer while writing, then swapped`: quick → `quotedAnswer`, full held on a deferred promise. "Writing a summary…" status is shown with the quoted text, then after resolving with `synthesizedAnswer` the text is swapped and the indicator is gone. `› full-stage refusal keeps the quoted answer` (full → `refusalC`) | yes |
| AC7 | CI `frontend` job: `npm ci && npm run lint && npm test && npm run build`. Lint warnings compared to main's latest run (lesson 2026-11-19) | yes |
| AC8 | `src/test/tokens.test.js` (Node `fs` in Vitest) reads `SynthesisView.jsx`, `ReferencesStack.jsx`, `App.jsx` (and `HeroSearch.jsx` if Q1 = yes) and asserts no `/\b(?:[a-z-]+:)*text-(slate|emerald|amber)-\d/`. `theme.js` `DEFAULT_THEME === "system"`, and the `index.html` literal is the same (or FE-0c's guard). Built CSS contains `.prose`: CI's `frontend-dist-report.sh` step output. Contrast table: QA reruns the script on the PR's `index.css`. Light/dark screenshots of answer, A-refusal and early refusal if QA can run a browser | yes, except contrast and screenshots (QA) |

Failure paths covered: unknown `refusal_reason`; a refusal with zero citations (no link, panel still `role=status`); missing `status`
(older server); `status`/`supported` disagreeing; reserved and unknown statuses; score 0 with and without `status`; full stage failing
(existing `catch`: quoted answer stays, no toast). FE-1 tests that change: "labels a supported citation as Verified" is replaced (AC3),
"Unverified · 0.0%" becomes "Not checked", and the refusal test's `getByText(refusalAnswer.answer)` becomes the A-copy assert.
Each replacement asserts more than before, and the PR body lists them so QA can check none was weakened.

## Size and split
| Part | Files | Prod | Tests |
|---|---|---|---|
| **FE-3a: honest labels + refusal state** (AC1–AC7) | `lib/citations.js` (new ~50), `SynthesisView.jsx` ~70, `ReferencesStack.jsx` ~45, `ui/badge.jsx` ~8, `App.jsx` 1 | ~175 | fixtures ~50, `citations.test.js` ~60, `SynthesisView.test.jsx` ~50, `ReferencesStack.test.jsx` ~35, `App.test.jsx` (new) ~100 → ~295 |
| **FE-3b: tokens, tooltip, theme flip** (AC3 tooltip, AC8, AC7) | `SynthesisView.jsx` ~25, `ReferencesStack.jsx` ~35, `App.jsx` ~20, `HeroSearch.jsx` ~6, `theme.js` 3, `index.html` 1 | ~90 | `tokens.test.js` ~25, tooltip test ~15, `setup.js` ~8 → ~50 |

Total ≈ 610 changed lines, over the 400 target, so I propose **two sequential PRs**. FE-3a is ~470 (prod ~175; the rest is
tests and fixtures). FE-3b is ~140. In FE-3a the new chips already use the status badge variants, but the rest of the restyle waits for FE-3b.
**FE-3a doesn't use `ui/tooltip`, so it doesn't need #70**: it can start as soon as pm-lead approves, if a frontend WIP slot is free
(#70 + FE-0c this cycle). FE-3b needs #70 merged and FE-3a merged (same files). If pm-lead prefers one PR, it's ~610 lines and waits for #70 (Q4).

## Risks and rollout
- **Light mode outside the ask flow after the flip.** `InfrastructureModal` (6), `IngestModal` (4), `PapersLibrary` (2) and `Toast` (1 icon) keep
  hard-coded emerald text classes. Their links and accents are about 1.8–1.9:1 on light. OS-light visitors get those screens in light after AC8.
  Mitigation: open question 1 (a follow-up token sweep, or delaying the flip until it lands). It's detected by the same `tokens.test.js` grep extended to those files.
- **`role="status"` inserted already filled** is announced inconsistently by screen readers. The panel heading and the link still make it
  findable, and the subtitle change is visible. A fix (mount an empty live region and fill it) would add App-level state; not worth it here.
- **Radix tooltip in jsdom** needs `ResizeObserver`. The stub is in `setup.js`. If `findByRole('tooltip')` is flaky, assert `aria-describedby`
  on the trigger instead (still proves the wiring).
- **FE-1 test replacements** could look like weakening. The PR body maps each old assert to its stricter replacement.
- **Rollback**: revert FE-3b to go back to the dark default and the old classes. Reverting FE-3a brings back the "Verified" labels (not desirable). Both are frontend-only.

## Open questions for pm-lead
1. **Flip scope.** OK to add `HeroSearch.jsx`'s 3 class swaps to FE-3b (first screen after the flip)? And for the modals, Library and Toast:
   (a) flip anyway and spec a follow-up token sweep now (my recommendation; they are secondary screens), or (b) hold the flip until that sweep merges?
2. **Export in refusal mode.** I hide both "Copy Synthesis" and "Export Note" on a refusal (there is no answer to export; FE-2 adds .bib export
   of the passages). Or should Export stay, writing an evidence-only note ("No answer was shown" + the passages with their chips)?
3. **Refusal C after a quoted answer.** Keep today's rule (a full-stage refusal is dropped, the quoted answer stays), so C doesn't reach users
   today? Or should a full-stage `insufficient_evidence` add a quiet note under the quoted answer ("The written answer was skipped: …")?
   The latter is new App state and copy; I'd make it a follow-up.
4. **Split.** FE-3a (~470, can start before #70 merges) + FE-3b (~140, after #70 and FE-3a), or one ~610-line PR after #70?
5. **Copy.** Approve the three panel bodies, the heading "No answer shown", the subtitle "Evidence only — no answer was shown", the stack heading
   "Retrieved passages (no answer was shown)", the chip texts and the tooltips above. Also: the answer-mode stack heading goes from "Referenced Studies & Evidence"
   to "References", to match the export.
6. **Discover on refusal C.** The early refusal offers "Search arXiv & Index". Should C ("the passages don't answer this") offer it too? Not in
   this design; it would only matter once Q3 makes C visible.

## PM decision
**Approved with changes** (pm-lead, 2026-11-20). Reviewed against `agents/tasks/FE-3.md` (AC1–AC8 + Notes), Product PRD UI-1/QA-4/QA-5/§7,
ADR-0003, ADR-0014 / `docs/design/AI-8.md` (status enum, reserved statuses, `supported == (status == "supported")`), ADR-0018 (Proposed) and
FE-0 design §6 + the FE-0b amendment. Code claims spot-checked at app `origin/main` `c37d27c`: the footer (`SynthesisView.jsx:115`), the export heading (`:50`),
the `verification()` rule (`ReferencesStack.jsx:10-13`), `Progress` as the gauge (`:110`), `arxiv` badge callers (IngestModal, PapersLibrary, trace badge), the
token colours in `tailwind.config.js` (`supported`/`unsupported`/`unchecked`/`accent`/`muted`/`popover` all mapped, `@tailwindcss/typography` loaded) and
`SupportThreshold` now being NLI entailment (`rag.go:24`), so the "Cosine Semantic Support" label really is wrong. The status rule (§1) is the right
conservative reading of ADR-0014: reserved/unknown statuses and `status`/`supported` disagreement can never say Supported. The test plan maps every AC to a CI test.

**Required changes** (fold into the build; no re-review of this design needed, QA checks them):
1. **AC1's whole-tree assert fails as designed.** `HeroSearch` is always rendered above the results (`App.jsx:166`), and its subtitle (`HeroSearch.jsx:58`)
   says "Every claim is mathematically verified against underlying PostgreSQL vector embeddings", which matches `/verified/i` and is itself an untrue trust
   claim (the check is NLI entailment / verbatim match, not embeddings; unchecked citations exist). FE-3a replaces that one sentence (copy only, no classes) with:
   **"Ask research questions about the indexed arXiv papers. Every answer cites the passages it came from, and each citation is labelled supported, unsupported or not checked."**
   Keep the App-level `document.body.textContent` assert unscoped. The tagline "…Sentence-Level Verification" stays (doesn't match, and per-claim checks do exist).
2. **Theme flip waits for the secondary-screen sweep** (Q1, option b): FE-3b depends on the new **FE-0e** (token sweep of `IngestModal`, `InfrastructureModal`,
   `PapersLibrary`, `Toast`) being merged. FE-0e creates `src/test/tokens.test.js` for its four files; FE-3b extends the same test with `SynthesisView.jsx`,
   `ReferencesStack.jsx`, `App.jsx` and `HeroSearch.jsx` (one guard, not two).
3. **Tooltip copy never names a method.** Keep the design's "a check found that this passage backs…" wording; don't use "entails", "NLI" or "cosine"
   (the ticket Note's 2026-11-19 example "the passage entails this sentence" is superseded: the method may change, the meaning shouldn't). FE-3b's tooltip test
   asserts the supported tooltip text exactly.
4. **Test replacements listed in the PR body** (as the design says, §Risks): each removed/rewritten FE-1 assert next to its replacement, so QA can confirm none got weaker.
   This is now an AC in FE-3a.
5. **Size.** FE-3a is ~470 lines, over the 400 target, but ~295 are tests/fixtures and prod is ~175: accepted as one PR. If the build passes ~550, stop and split the
   App-level tests (`App.test.jsx`) into a follow-up rather than trimming coverage.

**Answers to the open questions**
1. **Flip scope:** yes, HeroSearch's 3 class swaps go in FE-3b. Hold the flip until FE-0e merges (option b), not (a): an OS-light visitor would otherwise get
   ~1.8–1.9:1 emerald/red text in the ingest modal, library and toast, a known WCAG 1.4.3 failure we'd ship knowingly. FE-0e is small and doesn't touch any FE-3a
   file, so it runs in parallel with FE-3a and shouldn't delay FE-3b.
2. **Export on a refusal:** hide both "Copy Synthesis" and "Export Note". There's no answer to export; exporting the passages is FE-2 (.bib), which will get its own refusal rule.
3. **Full-stage `insufficient_evidence`:** keep today's rule (dropped; the quoted answer stays) for FE-3. Whether the user should also see that the writing stage
   judged the passages insufficient is a product trade-off in Mahesh's two-stage design (ADR-0018, Proposed) → **open question for Mahesh**, recorded on the board.
   No follow-up specced until he answers.
4. **Split:** approved. FE-3a = AC1–AC7 + change 1 (no `ui/tooltip`, can start now). FE-3b = AC3 tooltip + AC8 tokens/flip + HeroSearch swaps, after #70, FE-3a and FE-0e merge.
5. **Copy:** approved as written: the three panel bodies, "No answer shown", "Evidence only — no answer was shown", "Retrieved passages (no answer was shown)",
   "n passages", chip texts `Supported · x%` / `Unsupported · x%` / `Not checked`, the three tooltips, the footer "n of m citations supported", the export
   "• <chip text>" suffix, and "Referenced Studies & Evidence" → "References". Plus the hero sentence in change 1. The export title and toast texts stay (out of scope).
6. **Discover on refusal C:** no, not in FE-3 (C can't reach users today). Revisit together with Q3 if Mahesh wants C visible.
