# Tech design — FE-4: Claim evidence panel: each claim's status, its source passage and quote, one click to the PDF page

**Author:** frontend-engineer · **Ticket:** `agents/tasks/FE-4.md` · **PRD:** Product PRD UI-1, QA-3, QA-4, §7 principles 1–3; ADR-0003 (Accepted), ADR-0014 (Accepted), ADR-0018 (Proposed), ADR-0019 (Accepted) · **Status:** Approved with conditions (pm-lead, 2026-11-22; see PM decision). Built as FE-4a then FE-4b

All code references are to the app repo at `origin/main` `53171d6` (`frontend/`, `internal/query/rag.go`, `README.md`).

## Problem
An answer is checked claim by claim, but the UI doesn't show that yet. `SynthesisView` regex-parses `answer` for `[n]`. `ReferencesStack` shows one
chip per citation, the whole passage in a small scroll box, and a PDF link that opens page 1. A researcher can't see which statement
was supported, which exact words in the passage back it, or which page it is on. This design covers AC1 (claim chips, *not checked* distinct
from *unsupported*), AC2 (`[n]` focuses its card), AC3 (quote highlighted in the passage, with a fallback), AC4 (`vN` and `#page=N`), AC5
(responses without `claims` render as FE-3 left them) and AC6 (CI). It also covers the ticket Notes: marker semantics in refusal mode, defensive `answer_kind`,
ADR-0019 skipped markers, `ui/popover`/`ui/collapsible`, and the FE-0b N3 scroll-area rule.

## What the server sends (the contract this design reads)
Fields read, all in `AskResponse`/`Citation`/`Claim` (`rag.go:42-104`) and in the README `/v1/ask` row (`README.md:166`). No new field is needed.

| Field | Meaning (from code) | Used for |
|---|---|---|
| `claims[]` `{text, status, markers}` | The answer's statements in order. `text` is marker-free. `markers` holds in-range markers in citation order (`[]` for an uncited sentence). Absent on every refusal | claim list, claim chip, marker buttons |
| `citations[]` order | **Positional:** claim *i*'s citations are `citations[o_i : o_i+len(markers_i)]`, `o_i` = Σ earlier `len(markers)` (`rag.go:91-92`, README) | marker → the exact citation entry for that claim |
| `citations[].marker` | Passage number. In a written answer **the same marker can appear more than once**, one entry per claim that cites it (`finalizeClaims` appends per (claim, marker), `rag.go:318-367`). Numbers can skip, e.g. `[1] … [3]` (ADR-0019) | card id `ref-<marker>`, grouping |
| `citations[].status` / `supported` / `score` | FE-3's `citationState` rule (unchanged) | per-entry chip |
| `citations[].quote` | Only on supported citations. It occurs in `content` **after `normQuote`**: inline refs `[12]` removed, whitespace collapsed, no space before `.,;:!?` (`rag.go:429-446`, README "after whitespace/inline-reference normalisation") | highlight |
| `citations[].paper_version` | indexed arXiv version, `0` = unknown | `arXiv:<id>v<N>` label |
| `citations[].page` | start page of the chunk, omitted when not recorded (absent on every real response until ING-11b) | `p. N`, `#page=N` |
| `citations[].pdf_url` | already versioned when `paper_version > 0` (`rag.go:800`) | PDF link base |
| `refusal_reason`, `answer_kind` | FE-3 modes | mode switch only |

Where quotes actually appear (this corrects the 2026-11-17 Note):
- **Quoted answers** (`answer_kind: quoted`, the quick stage, the fallback): every sentence is verbatim, so a supported citation nearly always
  carries `quote = normQuote(sentence)`. The highlight is the **common** case here. It's also where a literal `indexOf` fails whenever the
  sentence spans a line break or contains an inline `[12]` in the chunk.
- **Written answers** (`synthesized`): NLI-supported claims carry **no `quote`** (the `synthesis-v1` prompt doesn't ask for one). A quote exists only
  when the claim is itself verbatim or the model added one unprompted. So the common written-answer case is **"no quote"**. That's a third
  state, different from "quote not located", which only happens if the client and server normalisation disagree (defensive, should be ~never).

## Approach

### 1. `src/lib/citations.js` (extend; plain ESM, no JSX)
```js
export function claimState(claim)                  // → { kind, text }  kind ∈ supported | unsupported | unchecked
export function claimCitations(claims, citations)  // → [{ claim, index, entries: [{ marker, citation|null, pos }] }] | null
export function groupByMarker(citations)           // → [{ marker, entries: [{ citation, pos }] }] in first-seen order
export function locateQuote(content, quote)        // → { start, end } in raw `content`, or null
export function pdfHref(cit)                       // → `${pdf_url || arxiv fallback}` + `#page=N` only for a valid page
export function arxivLabel(cit)                    // → "arXiv:2401.01234v2", or "arXiv:2401.01234" when paper_version is 0/absent
```
- **`claimState`**: same conservative order as FE-3 §1, applied to the claim's `status` (claims carry no score):
  `supported` → "Supported"; `unverified` → "Not checked"; anything else (`unsupported`, reserved `partially_supported`/`contradicted`,
  unknown, missing) → "Unsupported". Text only: no "%" and never "Verified".
- **`claimCitations`** validates the positional invariant. It returns `null` (caller falls back to per-marker lookup) when `Σ len(markers) !==
  citations.length` or any `citations[o+j].marker !== markers[j]`. A malformed server response can then never pin a claim to the wrong passage.
  Each entry's `pos` is the index into `citations`. A marker with no card (impossible with a valid response) gets `citation: null` and
  renders as plain text, not a button.
- **`groupByMarker`**: one card per distinct marker. This fixes a latent bug: today a written answer where claims 1 and 2 both cite `[1]`
  renders two cards with `id="ref-1"` and the same React `key`.
- **`locateQuote`** mirrors `normQuote` with an offset map. Fast path: `content.indexOf(quote)`. Otherwise both strings are normalised with the
  same three steps as `rag.go:429-433` in the same order, each normalised character remembers its raw index, the match is
  `indexOf` (case-sensitive, per ADR-0014), and the result is mapped back to a raw `[start, end)`. Empty/whitespace-only quote → `null`. Invariant:
  **a highlight only covers raw text that equals the quote up to the server's documented normalisation.** Where JS `\s` and Go's
  whitespace differ (exotic Unicode spaces), the result is `null` → the fallback is shown, so it fails safe and never highlights the wrong span.
- **`pdfHref`**: `page` counts only when `Number.isInteger(page) && page >= 1`. An existing `#…` fragment on the base is replaced, not doubled.

### 2. `SynthesisView.jsx`: claims mode
Mode selection (top to bottom):
1. `refusalReason` → FE-3 refusal panel, unchanged (no claims, no markers).
2. `Array.isArray(claims) && claims.length > 0 && claims.every(c => typeof c?.text === 'string')` → **claims list** (new).
3. otherwise → today's prose with regex `[n]` buttons (AC5). The prose text, header, footer and Copy/Export are unchanged. Marker buttons keep
   `type="button"`, the name `[n]` and their classes, and *gain only* `aria-controls`, the focus behaviour (§4) and the tooltip preview; a marker
   with a card drops the old `title` hover hint, which the tooltip replaces (two hover popups otherwise). Every existing FE-1/FE-3
   `SynthesisView`/`App` test passes unmodified (PM condition 1; updated in the FE-4a cycle 2026-11-21T21:59Z).

Claims list layout (inside the existing `prose font-serif` container):
```
<ol aria-label="Claims in this answer" class="list-none pl-0 space-y-2">
  <li>                      ← one per claim, in order
    {claim.text}            ← serif prose
    [1] [3]                 ← marker buttons (same look and accessible name "[n]" as today)
    <Badge variant={kind}>  ← icon (aria-hidden) + "Supported" | "Unsupported" | "Not checked", font-sans text-[11px]
  </li>
</ol>
```
A list rather than flowing prose: each statement and its verdict stays visible together (evidence first). The claims are single sentences by construction,
so it still reads as a paragraph of short lines. The chip is a plain `Badge` span (FE-0i). It isn't focusable, its text carries the meaning, so no
tooltip, which also keeps the Tab order to one stop per marker. Icons: `ShieldCheck` / `ShieldAlert` / `Info`, the same as the card chips.
A claim with `markers: []` shows its chip ("Not checked") and no buttons.

Marker button (both claims mode and the AC5 fallback keep `type="button"`, name `[n]`, current classes):
- `aria-controls="ref-<marker>"` (only when a card with that id will exist).
- Click/Enter/Space → `onCitationClick(marker, pos)`. `pos` is the positional citation index in claims mode, `undefined` in the fallback.
- **Preview via `ui/tooltip`** (opens on hover *and* keyboard focus, closes on Escape/blur, never takes focus). Content:
  `[3] <title> · § <section> · <entry chip text>`. Plain text, nothing interactive inside. See Alternatives 1 for why not `ui/popover`.
- Written answers (ADR-0019): markers render exactly as the server numbers them. `[1] … [3]` is fine, and no "hidden citations" count is shown.

Unchanged: header and subtitles (`SUBTITLES[answerKind] || 'Grounded answer'`), writing indicator, Copy Synthesis (copies `answer`), Export Note, and the
footer "x of y citations supported" (counts entries, as FE-3).

### 3. `ReferencesStack.jsx`
Cards come from `groupByMarker(citations)`. The heading badge counts cards ("n cited" / "n passages"), which equals `citations.length` for every
FE-3 fixture and every quoted answer and refusal (no repeats there).

Card anatomy (top to bottom):
```
[3]  arXiv:2401.01234v2                         [Supported · 100.0%]   ← chip button + FE-3 tooltip (single entry)
Grounded Retrieval for Scientific QA                                     ← title
§ Methods · p. 4                                                         ← section (omitted if empty) · page (only when valid)
┃ …retrieve passages with hybrid search and ▓verify each claim▓ against… ← passage, <mark> on located quotes
  [Show full passage ▾]                                                  ← only for long passages (ui/collapsible)
  (fallback / note line, see below)
[Open PDF at p. 4 ↗]   [Copy BibTeX]
```
- **Card element**: `id="ref-<marker>"`, `role="article"`, same `aria-label`, **`tabIndex={-1}`** (programmatic focus target for AC2, not a
  Tab stop), `focus-visible:ring-2 ring-ring`, and `data-active` when active (the same `border-primary ring` style as today).
- **Several entries for one marker** (written answers only): the single header chip becomes a short list under the title,
  "Cited by claim 1 — [chip]", "Cited by claim 3 — [chip]". Each chip is the FE-3 tooltip button. The row matching the clicked entry
  (`activePos`) gets `aria-current="true"` and a left rule. Claim numbers come from `claimCitations`. If that returned `null`, the label is "Check 1", "Check 2".
- **Meta line (AC4)**: `arxivLabel(cit)` in the existing `arxiv` badge. "Chunk #id" is removed from the visible line (it's internal, and the
  card has a better provenance line now). The FE-1 assertion on `Section: …` is replaced by an exact assertion on the new line (listed in the PR body).
  `section` empty → omitted (no invented "General").
- **Passage + quote (AC3)**. Highlight only for entries whose `citationState` kind is `supported`. A quote on any other status would be shown as evidence for a
  failed check, so it's ignored, matching the server invariant `quote ⇒ supported`. Located ranges from every supported entry of the card are merged
  (written answers can quote the same passage twice). `<mark class="bg-accent text-accent-foreground underline decoration-2 underline-offset-2 rounded-sm">`.
  The underline means it isn't colour-only. Inside it, `<span class="sr-only">Quote: </span>` so screen readers hear where it starts.
  States per card:

  | State | Rendering |
  |---|---|
  | quote located | passage with `<mark>` |
  | quote present, not located | plain passage, then `<blockquote>`: "Quoted text (not found in the passage shown above): “…”" |
  | supported entry, no quote (common for written answers) | plain passage, then `text-xs text-muted-foreground`: "No exact quote for this citation: the check compared the claim with the whole passage." |
  | unsupported / not checked | plain passage, no note (the chip says it) |
  | `content` empty | today's fallback text, unchanged |

  Copy never names the method (FE-3 PM change 3).
- **Long passages (`ui/collapsible`)**: if `content.length > 480`, the collapsed view shows an excerpt: ±200 chars around the first highlight (word
  boundaries, `…` at cut ends), or the first 320 chars when there's no highlight. `CollapsibleTrigger asChild` → `<Button variant="ghost" size="sm">` "Show full passage" /
  "Show less" (Radix sets `aria-expanded`/`aria-controls`). Short passages render whole, with no trigger. The `max-h-36 overflow-y-auto` scroll box is
  **removed**, so the FE-0b N3 rule (focusable `ScrollArea` with an `aria-label`) doesn't apply. There is no non-focusable scroll container left. Collapsed
  state is per card and resets with a new result (cards are keyed by `trace_id` + marker).
- **PDF link (AC4)**: `href={pdfHref(cit)}`. Text "Open PDF at p. 4 ↗" when a page is valid, else "Open PDF ↗". `aria-label` "Open PDF for [3] at page 4 (opens in
  a new tab)" / today's label. Still one click from every card (principle 3).

### 4. `App.jsx`: what is "active"
- `activeMarker` becomes `active = { marker, pos } | null`, initial `null`. **Nothing is active on load, in any mode.** The ring now means "you
  went here from a marker". So in refusal mode (no markers) no card is ever active. This resolves the FE-3b PM review item (card [1] ringed in refusal mode).
  `ReferencesStack` also ignores `active` when `refusalReason` is set, as a guard.
- `handleSearch` sets `active = null` on a new search and again when the written answer replaces the quoted one: marker numbers refer to a different
  passage set after the swap (`selectContext` order), so a stale ring would point at the wrong passage.
- `handleCitationClick(marker, pos)`: set `active`, then `el.focus({ preventScroll: true })` and `el.scrollIntoView?.({ block: 'nearest', behavior })`,
  with `behavior` `'auto'` under `prefers-reduced-motion`, else `'smooth'`. Focus moves to the card, so screen readers read its label. The tooltip closes on blur.
- Pass `claims={searchResult.claims}` to SynthesisView and `claims` + `active` to ReferencesStack.

### 5. States checklist
| State | Behaviour |
|---|---|
| loading (quick stage) | unchanged (HeroSearch busy state; no result card) |
| writing (quoted answer shown, written pending) | quoted claims list + "Writing a summary…" status; on swap, claims replaced and `active` cleared |
| answer, all supported (typical written) | every claim "Supported"; cards with no-quote note |
| partial (quoted: mixed statuses) | per-claim chips + per-card chips + footer "x of y" |
| refusal (A/B/C) | FE-3 panel + evidence cards; no claims, no markers, no active card; quotes absent by contract, highlight code inert |
| early refusal | unchanged banner |
| request error | unchanged toast |
| no `claims` / `claims: []` / malformed claims | AC5 prose fallback |
| positional invariant broken | claims list still renders; markers map by marker number; multi-entry rows labelled "Check n" |
| no `page` / `page` 0, null or non-integer | no "p. N", no fragment |
| `paper_version` 0 | `arXiv:<id>` without `v` |
| `answer_kind` absent (ADR-0018 Proposed) | treated like `quoted`: nothing is assumed hidden. FE-4 never branches on `answer_kind` or `synthesis_available`; chips come from `status` only |

### 6. Accessibility
- Tab order per answer: each `[n]` marker (one stop each) → card chips (FE-3) → "Show full passage" → Open PDF → Copy BibTeX. Cards are `tabIndex=-1`, only reached by marker activation.
- Every status has text plus an icon. The token colour is a third cue. The claim chips use the FE-0 `supported`/`unsupported`/`unchecked` tokens (FE-3 contrast table: ≥ 7.2:1).
- `<mark>`: `accent-foreground` on `accent` is 9.47 light / 8.98 dark (FE-3 table). The underline gives a non-colour cue.
- No toasts added, so the FE-0b description-colour rule (b) doesn't apply.
- Return path: a keyboard user on a card goes back with Shift+Tab through the stack. A "Back to claim" link is a possible follow-up (not in the ACs).

## Alternatives considered
1. **`ui/popover` for the `[n]` preview (ticket Note 2026-11-19).** Radix Popover opens on *click* and is a dialog-like widget: it sets
   `aria-haspopup`/`aria-expanded` on the trigger and moves focus into the content. Click must focus the card (AC2), so a popover would either fight that or
   need a controlled hover/focus open with `onOpenAutoFocus` suppressed, which announces a popup that never opens on activation. The preview is
   non-interactive text shown on hover/focus, which is the Tooltip pattern (WAI-ARIA), and `ui/tooltip` is already used by the card chips. **Proposed deviation; pm-lead to confirm** (Q1).
2. **One card per citation entry (positional ids `ref-<pos>`)**: simplest mapping, but a written answer where three claims cite passage 1 would show that passage three times,
   and FE-1/FE-3 tests and FE-2 rely on `ref-<marker>`. Rejected for grouping + a per-claim row.
3. **Literal `content.indexOf(quote)` only** (AC3's "exact substring"): it would show "not located" for most quoted answers whose sentence crosses a line break or holds an
   inline `[12]`, although the server matched them by its documented rule. Mirroring `normQuote` is still exact, case-sensitive matching, on the same text the server
   compared. (Q2)
4. **Keep the inline prose and put a chip after each sentence**: chips mid-paragraph break the reading line, and line-wrapping separates chip from sentence. The list keeps both together.
5. **Keep the scroll box and make it focusable** (N3): it hides the highlight below the fold. The excerpt around the quote + collapsible always shows the evidence first.
6. **Auto-activate the first citation (today)**: in refusal mode it suggests a link that doesn't exist, and after the two-stage swap it can point at a different passage. Rejected.

## Contracts and invariants
- Shared contracts touched: **none**. No API, event, schema or model change. Only documented fields (table above) are read. No follow-up API request.
- Invariants: every card stays one click from its PDF; unsupported and not-checked citations stay visible and flagged (ADR-0003, ADR-0019 for quoted answers/refusals);
  `unverified` never renders "Supported" or "Verified"; a highlight is shown only on a supported citation and only on text that matches the quote under `normQuote`;
  a marker activates only the card for its own passage, and with a valid response the exact entry for its own claim; no "hidden citations" count (the API has none).
- No `setState` in effect bodies (lesson 2026-11-19); this design adds no effects. New helpers live in `lib/citations.js` (`react/only-export-components`).
- Source-reading tests (`tokens.test.js` already guards both files) stay green: only token classes are used.
- No new dependency. Not touched: `ui/badge.test.jsx` (FE-0j), app `README.md` (ING-6c this cycle; **no README line is needed**, since the API row already documents every field used).

## Test plan
Fixtures (`src/test/fixtures.js`, added; shapes copied from `rag.go` behaviour):
- `quotedClaims`: quoted answer, three claims → markers `[1]`,`[2]`,`[3]`, statuses supported / unsupported / unverified. Citation 1's `content` has the sentence split
  by `\n` and an inline `[12]`, and its `quote` is the `normQuote` form. Plus a claim with `markers: []`.
- `synthesizedSkips`: `answer_kind: synthesized`, claims `{markers:[1]}`, `{markers:[1,3]}`, so `citations` = `[m1, m1, m3]` (repeat + skip), all supported, no quotes, `page` on m3 only.
- `quoteNotLocated` (quote absent from content), `quoteOnUnsupported` (invariant-violating), `brokenPositional` (claims/markers disagree with citations),
  `longPassage` (> 480 chars, quote near the end), `noVersion` (`paper_version: 0`, unversioned `pdf_url`), page variants `0`, `null`, `"4"`.

| AC | Test (file › name) | Runs in CI? |
|---|---|---|
| AC1 | `citations.test.js › claimState`: table supported/unsupported/unverified/`partially_supported`/`contradicted`/`"bogus"`/missing → kinds; for every non-supported row `text` ∌ `/\bSupported\b/`, and no row matches `/verified/i` | yes |
| AC1 | `SynthesisView.test.jsx › quoted claims: each claim shows its own chip text`: `within(li[n])` has "Supported" / "Unsupported" / "Not checked"; the three chips have different `Badge` variants and icons; the unverified `li` text ∌ `/\bSupported\b\|verified/i` | yes |
| AC1 | `› written answer with skipped markers`: `synthesizedSkips` renders buttons `[1]`, `[1]`, `[3]` and no `[2]`; every chip "Supported"; no text matching `/hidden/i` | yes |
| AC2 | `SynthesisView.test.jsx › marker has aria-controls ref-<n> and reports (marker, pos)`: claim 2's `[3]` → `onCitationClick(3, 2)`; Enter and Space via `user.keyboard` give the same call | yes |
| AC2 | `App.test.jsx › clicking [3] focuses card [3]` and `› Tab to [1], Enter focuses card [1]` (fetch stubbed with `synthesizedSkips`): `document.activeElement` is the article "Citation [3]", it has `data-active`, and the matching "Cited by claim 2" row has `aria-current` | yes |
| AC2 | `› the preview tooltip opens on focus and doesn't trap focus`: after `user.tab()` onto `[1]`, `findByRole('tooltip')` has the title and "Supported"; Enter moves focus to the card and the tooltip closes | yes |
| AC2 (refusal) | `App.test.jsx › refusal A: no card is active` (no `[data-active]`), and `› after the written answer replaces the quoted one, no card is active` | yes |
| AC3 | `citations.test.js › locateQuote`: exact; `\n` inside; double spaces; inline `[12]` and `[3, 4]` and `[5–7]`; space before `.`; case differs → null; empty/whitespace → null; absent → null; returned raw slice, normalised, equals the normalised quote | yes |
| AC3 | `ReferencesStack.test.jsx › highlights the located quote`: `<mark>` text (minus sr-only) equals the raw span for `quotedClaims` citation 1 · `› quote not located shows the fallback with the quote` · `› supported without quote shows the no-quote note` · `› quote on an unsupported citation is not highlighted` · `› long passage: excerpt contains the mark, "Show full passage" toggles aria-expanded and shows the full text` | yes |
| AC4 | `citations.test.js › pdfHref / arxivLabel` tables · `ReferencesStack.test.jsx › page 4: link href ends "v2#page=4", text "Open PDF at p. 4", meta "§ Methods · p. 4"` · `› no page / 0 / null / "4": href === pdf_url, no "p."` · `› arXiv:2401.01234v2 shown; paper_version 0 → "arXiv:…" with no "v0"` | yes |
| AC5 | Every existing FE-3/FE-1 `SynthesisView` test runs unchanged on fixtures without `claims` · new `› claims absent, [] or malformed → prose with [n] buttons, no "Claims in this answer" list` (rendered DOM identical between `quotedAnswer` and `{...quotedAnswer, claims: []}`) | yes |
| AC6 | CI `frontend` job: `npm ci && npm run lint && npm test && npm run build`; lint warning count compared with main's latest run (lesson 2026-11-19) | yes |

Failure paths covered: broken positional invariant (markers map by number, rows "Check n"); marker without a card (plain text); invariant-violating quote
on unsupported; reserved/unknown claim status; page/version edge values; empty `content`; long passage.
Tests replaced (to be listed in the PR body with their stricter replacements): `ReferencesStack.test.jsx:30` `Section: <s>` → exact meta-line assert.
Mutants QA can use (each must be killed): drop the `kind === 'supported'` highlight guard; `claimState` mapping `unverified` → supported; `pdfHref` `>= 1` → `>= 0`;
`locateQuote` case-insensitive match; drop the inline-ref step; `claimCitations` skipping the marker-equality check; `active` initial value back to `1`; drop `tabIndex={-1}`/`.focus()`.
_pm-lead 2026-11-27 (FE-4a QA r1 F5): "`active` initial value back to `1`" is an **equivalent mutant**. `handleSearch` calls `setActive(null)` before any result renders,
so the initial value is never visible. Use instead: drop `setActive(null)` on a new search (alone it is killed by `App.test.jsx › a new search clears the active card`), or
combine it with the initial `{marker: 1}` to reproduce the pre-FE-4a "card 1 active on load". Also used by FE-4a QA: drop `setActive(null)` on the quoted → written swap; ignore reduced
motion; marker ignores `pos` (visible in FE-4b via `aria-current`)._

## Size and split
| Part | Content | Prod | Tests |
|---|---|---|---|
| **FE-4a: claims, chips, marker focus** (AC1, AC2, AC5, AC6) | `claimState`, `claimCitations`, `groupByMarker` (~45); SynthesisView claims list + marker tooltip (~55); ReferencesStack grouping, `tabIndex`, active/`aria-current`, per-claim rows (~45); App `active` (~12) | ~155 | fixtures ~45, citations ~35, SynthesisView ~60, ReferencesStack ~30, App ~40 → ~210 |
| **FE-4b: quote highlight, provenance line, PDF page** (AC3, AC4, AC6) | `locateQuote`, `pdfHref`, `arxivLabel` (~45); ReferencesStack passage/mark/collapsible/fallbacks, meta line, link (~65) | ~110 | fixtures ~30, citations ~50, ReferencesStack ~60 → ~140 |

Total ≈ 615 changed lines, over the 400 target, so I propose **two sequential PRs**: FE-4a ≈ 365, FE-4b ≈ 250. The seam is the card body. 4a
changes how cards are chosen, keyed and focused; 4b changes what a card shows. Both touch `ReferencesStack.jsx` and `lib/citations.js`, so 4b starts after 4a merges.
4a ships value alone (claim verdicts + working markers + the duplicate-id fix). 4b is the provenance half.

## Risks and rollout
- **`#page=N` support**: Chrome's and Firefox's built-in viewers honour it; Safari's and some external viewers ignore it and open page 1. The link still opens the right
  PDF version (no regression). `page` is the chunk's **start** page, so a quote can sit on the next page. The label says "p. 4" and the aria-label "at page 4".
  This only goes live with ING-11b; until then every real response has no `page` (fixtures only).
- **Normalisation drift**: if `normQuote` changes server-side, quotes fall back to "not located" (visible, safe). The `locateQuote` test table copies the Go cases, so
  a drift shows up as a fallback spike, not a wrong highlight.
- **Focus moving on click** could surprise mouse users on the `lg` layout; `preventScroll` + `block: 'nearest'` keeps the viewport stable, and the ring shows where focus went.
- **FE-2 (Export .bib)** waits on FE-4 (`ReferencesStack.jsx`); grouping gives it one card per passage, which is what an export wants.
- **Rollback**: revert FE-4b to get FE-4a's cards without highlight/page; revert FE-4a to return to FE-3. Frontend only, no data migration.

## Open questions
For pm-lead (none needs Mahesh):
1. **Preview primitive**: OK to use `ui/tooltip` instead of `ui/popover` for the `[n]` preview (Alternatives 1)? `ui/collapsible` is used as the Note asks.
2. **AC3 wording**: confirm "exact substring" means exact after the server's documented `normQuote` normalisation (case-sensitive), not a raw `indexOf` (Alternatives 3).
3. **Label format**: `arXiv:2401.01234v2` (the canonical arXiv form) rather than the ticket's `arXiv:ID vN` with a space.
4. **Split**: FE-4a then FE-4b as above, or one ~615-line PR?
5. **Copy**: claim chips "Supported" / "Unsupported" / "Not checked" (no %); list label "Claims in this answer"; "Cited by claim n"; "Open PDF at p. N ↗";
   "Show full passage" / "Show less"; the not-located fallback; the no-quote note. Dropping "Chunk #id" from the card.
6. **Nothing active on load** (§4): accept as the answer to the FE-3b PM review item, for answer mode too, not only refusal mode?

For Mahesh: **none that block code.** ADR-0018 is still Proposed, but this design doesn't depend on its outcome (`answer_kind` is only used for the existing subtitle and
absent is handled). If Mahesh rejects ADR-0018 Option 1, nothing here changes.

## PM decision
**APPROVED with conditions** — pm-lead, 2026-11-22, cycle 2026-11-21T21:59Z. Split approved: **FE-4a** (build now) then **FE-4b** (after FE-4a
merges). The conditions below are build rules, not a redesign; QA checks them alongside the ACs. No item needs Mahesh.

Checked against: ticket ACs 1–6 and Notes 2026-11-07 … 2026-11-22; Product PRD UI-1, QA-3, QA-4, §7 principles 1–3; ADR-0003, ADR-0014 (Accepted;
"whitespace-normalised, case-sensitive" quote match), ADR-0018 (Proposed; design doesn't branch on it), ADR-0019 (Accepted; skipped markers, no hidden count);
and the code at `53171d6`: `rag.go:42-104` (fields, positional `citations` comment), `rag.go:423-445` (`inlineRefRegex`, `spaceBeforePunct`, `normQuote`, `inPassage`),
`App.jsx:22/95/113` (`useState(1)`, first marker set on load), `ReferencesStack.jsx:58-59` (`key`/`id` = marker, so repeats collide), `:100` (`Section: … 'General' • Chunk #`),
`:106` (`max-h-36` scroll box), `ui/tooltip.jsx` ("supplementary only"), README `/v1/ask` row. The contract table is accurate. ING-10 is merged (`4c15275`), so `vN` labels are trustworthy (2026-11-07 Note).

**Answers to the open questions**
1. **`ui/tooltip` instead of `ui/popover`: approved.** The 2026-11-19 Note chose popover for "preview on hover/focus that must not trap focus"; that *is* the tooltip
   pattern, and a popover would announce a dialog that never opens on activation. The preview stays supplementary (`ui/tooltip.jsx` rule): status text is also on the claim chip and card. The ticket Note is superseded.
2. **AC3 "exact substring" = exact, case-sensitive match after the server's `normQuote`: approved.** That is ADR-0014's definition and what `inPassage` checks; a raw `indexOf`
   would report "not located" for quotes the server verified. The highlight must still only cover raw text that equals the quote under that normalisation (condition 5).
3. **`arXiv:2401.01234v2`: approved** (canonical arXiv form; satisfies AC4 "version shown as vN"). `paper_version` 0 → `arXiv:2401.01234`.
4. **Split: approved, sequential** (shared `ReferencesStack.jsx` + `lib/citations.js`). FE-4a = AC1, AC2, AC5, AC6; FE-4b = AC3, AC4, AC6. FE-4 becomes the umbrella and closes when both merge. FE-2 now waits on **FE-4b**.
5. **Copy: approved as listed**: "Supported" / "Unsupported" / "Not checked"; "Claims in this answer"; "Cited by claim n" ("Check n" when the positional check fails); "Open PDF at p. N ↗";
   "Show full passage" / "Show less"; "Quoted text (not found in the passage shown above): “…”"; "No exact quote for this citation: the check compared the claim with the whole passage."
   Dropping "Chunk #id" and the invented "General" section is approved (FE-4b).
6. **Nothing active on load, in every mode: approved.** It closes the FE-3b PM review item. The ring means "you came here from a marker" (principle 3), and clearing it on the
   quoted → written swap prevents a ring on the wrong passage. No existing test depends on the initial `1` (checked `*.test.jsx`).

**Conditions**
1. **AC5 wording (FE-4a).** §2 item 3 says the fallback is "byte-for-byte unchanged", but §2 also gives fallback markers `aria-controls`, card focus and the tooltip. That's
   wanted (AC2 applies to every marker), so the rule is: in the fallback the prose text, header, footer and Copy/Export are unchanged; marker buttons keep `type`, name `[n]`
   and classes and *gain only* `aria-controls`, the focus behaviour and the tooltip. **Every existing FE-1/FE-3 `SynthesisView`/`App` test passes unmodified**; the one replaced
   assertion (`ReferencesStack.test.jsx:30`) belongs to FE-4b, not FE-4a. Update §2 item 3 in this file in the FE-4a PR's cycle.
2. **FE-4a leaves the card body alone.** No change to the meta line (`ReferencesStack.jsx:100`), the passage box (`:106`) or the PDF link in FE-4a; those are FE-4b. The existing
   non-focusable scroll box is out of FE-4a's scope (not a new instance of the N3 rule); FE-4b removes it.
3. **Two counts, one view (FE-4a).** With grouping, a written answer citing [1] twice shows "2 cited" in the heading and "3 of 3 citations supported" in the footer. Accepted
   (heading counts passages, footer counts checks), but pin both numbers for `synthesizedSkips` in a test so it's deliberate, and show it in a screenshot in the PR evidence.
4. **Tooltip test in jsdom (FE-4a).** The AC2 "tooltip opens on focus and doesn't trap focus" test must assert `document.activeElement` is the card after Enter, not only that the
   tooltip closed. If Radix Tooltip can't open under jsdom focus, say so in the PR and keep the focus assertion; don't drop it.
5. **`locateQuote` mirrors RE2 exactly (FE-4b).** Go RE2 `\s` is ASCII (`[\t\n\f\r ]`), JS `\s` is Unicode. In the two regex steps (`inlineRefRegex`, `spaceBeforePunct`) use the
   ASCII class explicitly; the collapse step mirrors `strings.Fields` (Unicode `unicode.IsSpace`). Same order as `normQuote`. Add the row that tells them apart: content `"…shown in [3, 4] that…"`. Go's `inlineRefRegex` does
   *not* match `[3, 4]` (NBSP isn't RE2 `\s`), so the ref stays in the normalised text and a quote without it must return `null`. Mutant to kill: ASCII class → `\s`.
   (Leading NBSP before a ref and NBSP before punctuation normalise the same either way, because `strings.Fields` runs before `spaceBeforePunct`.)
6. **Highlight guard (FE-4b)**: `<mark>` only on entries whose `citationState` kind is `supported` (as designed); keep the mutant list in §Test plan for QA.

**Size**: FE-4a ≈ 365 changed lines, FE-4b ≈ 250; both under 400. If FE-4a goes over 400, move the multi-entry "Cited by claim n" rows to FE-4b rather than growing the PR.

## B-UI addendum (2026-11-28)
frontend-engineer, for pm-lead review. Bundle B-UI (KAN-133) = FE-4b + FE-2, one PR on `agent/frontend/B-UI`, code read at app `5fcbd5f`.
§1, §3 and conditions 5–6 above stand unchanged for AC1–AC3; this adds the export (AC4–AC5) and the wiring FE-4a left out.

**1. Remaining FE-4b (claim → passage → PDF page).** FE-4a ships marker → focused card. Left: `locateQuote`, `pdfHref`, `arxivLabel` (§1, ASCII-class
regex steps per condition 5); meta line `arXiv:<id>v<N> · § <section> · p. <N>` replacing `ReferencesStack.jsx:114`; `<mark>` + sr-only "Quote: " and the four
passage states (§3 table); `ui/collapsible` excerpt > 480 chars replacing the `max-h-36` box (`:120`); link `pdfHref(cit)`, "Open PDF at p. N ↗" / "Open PDF ↗".
Cited-by rows: a card with > 1 entry replaces FE-4a's chip strip (`:86-105`) with one row per entry, "Cited by claim n" (or "Check n" when
`claimCitations` is `null`); `aria-current="true"` only on the row whose `pos === active.pos`. **Gap found:** `App.jsx:216` passes no `claims` to
ReferencesStack, so the rows can't be labelled today. B-UI adds `claims` and `answerKind` props there (+2 lines in `App.jsx`, inside `frontend/`).

**2. `.bib` export (FE-2). Fields available today** (`rag.go:42-57`): `arxiv_id`, `title`, `paper_version`, `pdf_url`. No authors, no published date, no venue.
New `src/lib/bibtex.js` (plain ESM):
```js
export function arxivYear(id)    // "2401.01234" → 2024, "cs/0601001" → 2006 (YY ≥ 91 → 19YY), "2401.01234v3" → 2024; unparseable → null
export function bibKey(id)       // "arxiv" + id minus version and non-alphanumerics: "arxiv240101234", "arxivcs0601001"; empty id → null
export function bibEntry(cit)    // one entry string, or null when bibKey is null
export function bibFile(cits, { answerKind }) // → { text, count }: unique arxiv_id in first-seen order; synthesized → supported only
export function bibFilename(d = new Date())   // "arxivlens-20261128-142530.bib" (local time, zero-padded)
```
Entry (`@misc`, arXiv's own export convention; `@article` needs a `journal` we don't have):
```
@misc{arxiv240101234,
  title = {Grounded Retrieval for Scientific QA},
  eprint = {2401.01234},
  archivePrefix = {arXiv},
  year = {2024},
  url = {https://arxiv.org/abs/2401.01234}
}
```
- **No author/year:** no `author` field ever (no data; adding it needs the HTTP-contract ADR on Mahesh's list). `year` only when `arxivYear` parses, else the line is
  omitted: never `2026`, never a guess. `primaryClass = {cs.AI}` is dropped (fabricated). Empty title → no `title` line (no "Untitled").
  The file starts with one BibTeX comment: `% ArxivLens export. Author fields are not included: ArxivLens does not return authors yet; see each url.`
- Escaping: one pass over the title, `[\\{}&%$#_]` → `\textbackslash{}`, `\{`, `\}`, `\&`, `\%`, `\$`, `\#`, `\_`.
- Which citations: what the answer shows. Quoted → all; synthesized → `citationState(c).kind === 'supported'` (the server already drops the rest per
  ADR-0019; the filter is a guard). `answerKind` absent → treated as quoted (§5, ADR-0018).
- **Trigger:** references header, right side, next to "Click [n] in text to inspect". `ui/dropdown-menu`: `<Button variant="outline" size="sm">` with
  `Download` icon (`aria-hidden`) + visible text "Export" (its accessible name); item "BibTeX (.bib)". Selecting builds the file, downloads it via
  `Blob` + `URL.createObjectURL` + a temporary `<a download>`, revokes the URL, toasts "Exported n references (.bib)". `count === 0` → item disabled.
- **Refusal: trigger absent** (not disabled). A disabled button is skipped by Tab, so its explanation would be unreachable by keyboard, and the heading
  already says "Retrieved passages (no answer was shown)". Per-card "Copy BibTeX" stays on refusal cards: copying a retrieved paper's reference claims nothing.
- Per-card "Copy BibTeX" calls `bibEntry(cit)`; hidden when it returns `null`. The handler at `ReferencesStack.jsx:23-34` is deleted.

**3. Leftover label honesty (FE-3).** In scope: the empty-`content` fallback (`:121`) prints `"<title> — [Section: <s>]"` in quote marks inside the passage box,
which reads as a quote the paper doesn't contain; it becomes "Passage text isn't available. Open the PDF to read it." (§3's "unchanged" row is superseded).
Out of scope, flagged only for pm-lead: the hero tagline "…with Sentence-Level Verification" (`HeroSearch.jsx:51`) overstates "Not checked" answers; the
Markdown note heading "Clinical & Academic Research Note" and its bare "§ " on an empty section (`citations.js:45-48`, ticket excludes Export Note wording).

**4. Files.** `lib/citations.js` + test · new `lib/bibtex.js` + test · `components/ReferencesStack.jsx` + test · `App.jsx` (2 props) · `App.test.jsx` (AC3) · `test/fixtures.js`. No new dependency.

**5. Test plan** (Vitest, all run in CI `frontend` job)
| AC | Tests |
|---|---|
| AC1 | `citations.test.js › locateQuote` table from §Test plan + NBSP `[3, 4]` row; `ReferencesStack.test.jsx` › mark equals raw span · not-located block · no-quote note · quote on unsupported/unchecked → no mark, no note · long passage: excerpt holds the mark, trigger toggles `aria-expanded` |
| AC2 | `› pdfHref/arxivLabel` tables (page 4, 0, null, `"4"`, absent; fragment replaced; version 0); exact meta-line assert replacing `ReferencesStack.test.jsx:30`; no "Chunk #", no "General" |
| AC3 | `App.test.jsx` (`synthesizedSkips`): click the second `[1]` → "Cited by claim 2" row `aria-current="true"`, claim-1 row none; `brokenPositional` → "Check 1/2" |
| AC4 | `bibtex.test.js`: 3× same id → 1 entry; key stable across calls; escaping table; `eprint`/`archivePrefix`/`url`; year 2024 / 2006 / omitted; no `author`, no `primaryClass`, no `2026` unless the ID says so; card copy === `bibEntry` (spy on `onCopy`) |
| AC5 | `ReferencesStack.test.jsx`: Tab to "Export", Enter opens, Enter on "BibTeX (.bib)" → one download; blob text has the expected entries (quoted all; synthesized with an injected unsupported → excluded); filename matches `/^arxivlens-\d{8}-\d{6}\.bib$/`; refusal → no "Export" button. `URL.createObjectURL` stubbed |
| AC6 | legacy fixtures without `claims`/`page`/`quote`/`paper_version` render as main bar the meta line; whole-tree no-"Verified" tests untouched |
| AC7 | CI: `npm ci && npm run lint && npm test && npm run build`, lint warnings ≤ main |

**6. Size.** FE-4b ≈ 320 (prod ~120, tests+fixtures ~200), FE-2 ≈ 190 (prod ~70, tests ~120), App +2 → **≈ 510 changed lines**, one PR, under 800.

**As built (2026-11-28, PR #132; QA r1 judged all three OK).** These are three small deviations from the text above:
1. The no-quote note ("No exact quote for this citation: …") shows only when a supported entry has an explicit `status: "supported"`. A legacy citation with `supported: true` and no `status` comes from before the API had quotes, and adding the note there would break AC6 ("renders as `main` does").
2. ReferencesStack takes a third new prop, `onNotify` (App's `showToast`), for the "Exported n references (.bib)" toast, in addition to `claims` and `answerKind`. That is one extra line in `App.jsx`.
3. The separate `arXiv:` badge in the card header is removed. The ID and version are now only in the meta line `arXiv:<id>v<N> · § <section> · p. <N>`, under the title, so they aren't shown twice.

### PM decision (2026-11-28): B-UI addendum
**Approved.** The addendum covers AC4–AC5 (builder API, `@misc` entry, trigger, refusal = trigger absent) and closes the `App.jsx` `claims` gap. It fabricates no field. Both flagged items are trivial string edits that make the labels more honest, so they **are folded into B-UI** (ticket scope amended):
1. **Tagline** (`HeroSearch.jsx:51`): becomes "Evidence-Grounded Answers with Cited Passages". It no longer claims verification that "Not checked" answers don't have. One assert in an existing or new test checks the new text and that "Sentence-Level Verification" is gone.
2. **Markdown note** (`citations.js:45-48`): the heading becomes `# ArxivLens Research Note`. The ` (§ <section>)` part appears only when `section` is non-empty. Add a `markdownNote` test for both. Nothing else in the note changes, and the other "Clinical" strings stay out of scope.
3. **Size**: with these the PR stays at about 520 lines, under the 800 cap. The PR body lists the two string changes under "Label honesty".
