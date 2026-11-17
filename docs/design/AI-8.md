# Tech design: AI-8, claim-level citations with provenance and a verification status in `/v1/ask`

**Author:** ai-engineer · **Ticket:** `agents/tasks/AI-8.md` · **PRD:** Product PRD QA-3, QA-4, §7 principles 1–3; Technical PRD §7.2; ADR-0003 (Accepted), ADR-0014 (Accepted), ADR-0018 (Proposed) · **Status:** Draft

All code references are to the app repo at `origin/main` `40dec5a`. `rag.go` line numbers are from that commit.

## Problem
Since #44/#46, `/v1/ask` checks each (claim, cited passage) pair, using an exact quote match or NLI. But the JSON hides the result. A citation is `supported: true|false`,
so a passage that was checked and failed looks the same as one the verifier never saw (`supported: false, score: 0`). No claim list
exists. A citation doesn't say which paper version or page it came from, and `pdf_url` opens the latest version. This design adds
the rest of ADR-0014 Option 1 on top of the #46 shape: `claims[]`, `prompt_version`, citation `paper_version`/`page`/`quote`/`status`,
a versioned `pdf_url`, and the README `/v1/ask` row. Covers AC1–AC8, built as two PRs (AI-8a, AI-8b; see Split).

## Response shape (exact)
New keys are marked **+**. Every existing key keeps its name, type and meaning. The two value changes are listed under "Consumers".

```jsonc
{
  "answer": "string",
  "citations": [{
    "marker": 1, "arxiv_id": "2401.00001", "title": "…", "chunk_id": 7, "section": "Results",
    "content": "…raw chunk text…",              // LLM path: now the raw chunk, no longer the sanitized prompt text (decision 6)
    "pdf_url": "https://arxiv.org/pdf/2401.00001v2.pdf",   // versioned when paper_version > 0 (decision 7)
    "score": 0.91, "supported": true,            // supported == (status == "supported"), by construction
    "paper_version": 2,                          // + int, always present (0 = unknown, only for hand-built hits)
    "page": 4,                                   // + int, omitted when SearchHit.Page is nil (every hit until ING-11b)
    "quote": "…verbatim sentence…",              // + string, omitted when none; present ⇒ status == "supported"
    "status": "supported"                        // + "supported" | "unsupported" | "unverified", always present
  }],
  "trace_id": "32 hex",
  "refusal_reason": "…",                         // unchanged (omitempty)
  "answer_kind": "quoted" | "synthesized",       // unchanged (#46, omitempty)
  "synthesis_available": true,                   // unchanged (#46, omitempty)
  "claims": [{"text": "…", "status": "supported", "markers": [1, 3]}],   // + omitted on every refusal (decision 4)
  "prompt_version": "synthesis-v1"               // + only when answer_kind == "synthesized" (omitempty)
}
```

Go types (`rag.go`):
```go
type Citation struct {
    // … the 9 existing fields unchanged …
    PaperVersion int    `json:"paper_version"`
    Page         *int   `json:"page,omitempty"`
    Quote        string `json:"quote,omitempty"`
    Status       string `json:"status"`
}
type Claim struct {
    Text    string `json:"text"`
    Status  string `json:"status"`
    Markers []int  `json:"markers"` // never nil: [] for an uncited sentence
}
// AskResponse gains:
    Claims        []Claim `json:"claims,omitempty"`
    PromptVersion string  `json:"prompt_version,omitempty"`

const (StatusSupported = "supported"; StatusUnsupported = "unsupported"; StatusUnverified = "unverified")
```
No `answer_source`: `answer_kind` does that job (ADR-0018 Option 1, recommended). If Mahesh picks ADR-0018 Option 2, adding
`answer_source` is a small additive follow-up that breaks nothing. The AI-8a and AI-8b PR bodies both say so.

**Ordering invariant (new, tested).** On both paths `citations[]` lists each claim's citations in claim order, and within a claim in
`markers` order. Claim *i*'s citations are therefore `citations[o_i : o_i + len(markers_i)]` with `o_i = Σ_{j<i} len(markers_j)`.
The LLM path can cite the same marker from two claims with different statuses, so position is the only way to tell which
citation belongs to which claim. FE-4 relies on this (open question Q3).

## Approach

### 1. Status from the existing verification (AI-8a)
`newCitation(marker, hit, score, supported bool)` becomes `newCitation(marker, hit, score, status string)`, and it sets
`Supported = status == StatusSupported`. The AC1 invariant then holds for every citation by construction, and no call site can set the two
fields apart. Each call site already has the information it needs:

| Path (function) | Rule | Source in code today |
|---|---|---|
| Answer citation, extractive (`checkCitations`, rag.go:793-806) and LLM (`finalizeClaims`, rag.go:257-269) | `labelScore` ok and score ≥ `SupportThreshold` → `supported`; ok and < 0.50 → `unsupported`; **not ok → `unverified`** | `labelScore(scores[i], failed[i])`. Not ok covers: verifier nil, verifier error, wrong score count (all three set `failed` in `scorePairs`), NaN, < 0, > 1 |
| LLM citation with a model-supplied `quote` that isn't verbatim in the raw chunk | `unsupported`, quote dropped, even when NLI ≥ 0.50 (decision 3b) | new |
| Refusal evidence, `all_citations_unsupported` / `verification_unavailable` (`refusal`, rag.go:658-673) | hit *i* `unsupported` if `check.hitScored[i]` (it was checked; in a refusal no check passed); else `unverified` | `citationCheck.hitScored` (exists, unused for the label today) |
| Refusal evidence, `insufficient_evidence` (`synthesize`, rag.go:222-230) | every passage `unverified` (nothing was checked) | the path makes no verifier call |
| Early refusal (no relevant hit, rag.go:152-158) | `citations: []`, so nothing to label | — |

Every refusal path, listed out:
- **`verification_unavailable`**: hits with a check that ran → `unsupported`; hits whose check failed → `unverified`. This matches the ticket.
- **`all_citations_unsupported` after an extractive draft**: the cited hits (≤ 3, `maxAnswerHits`) → `unsupported`. Evidence hits that no
  sentence cited (ranks 4–5, or a hit with no quotable sentence) → **`unverified`**. *This refines the ticket's "else `unsupported`"*
  (open question Q1). Those passages were never checked against anything, and calling them `unsupported` would report a check that never ran,
  which is the confusion this ticket exists to remove. The eval is unaffected either way: the refusal's evidence citations never count
  as supported, and `classify` reads only `refusal_reason`.
- **`all_citations_unsupported` from "no in-range marker"** (extractive answer empty, `TestAskRefusesNoInRangeMarker`): no hit was
  checked, so every evidence citation is `unverified`. The reason string stays as it is today (changing it is ADR-0003 territory).
- **`insufficient_evidence`**: every evidence passage → `unverified`.
- **LLM claims all unsupported → quoted fallback**: no LLM citation is returned. The fallback is labelled by the extractive rules above.

Statuses never emitted: `partially_supported` and `contradicted` stay reserved (ADR-0014). The NLI model hasn't been calibrated on EVAL-7 judgments.

### 2. `scorePairs` reports exact matches (AI-8a)
`scorePairs` (rag.go:830) gains a fourth return value, `exact []bool` (pair *i* scored 1 by `isVerbatimQuote`). The two callers use
it to set `quote` (decision 3a). This is cheaper than calling `isVerbatimQuote` a second time, and it guarantees the quote and the score come from the same check.

### 3. `quote` (AI-8a)
Quote matching uses a new helper `inPassage(quote, passage string) bool`, true when `normQuote(quote) != ""` and
`strings.Contains(normQuote(passage), normQuote(quote))`. The normalisation is the same as `isVerbatimQuote`: inline references removed, whitespace
collapsed, no space before punctuation. It is case-sensitive, as ADR-0014 requires. There is **no** 40-byte minimum. That minimum exists because a verbatim
sentence *alone* earns score 1. A model quote never earns support by itself (decision 3b), so a short true quote shouldn't count as fabricated.

- **(a) Exact-match support.** When `exact[i]` is true and the citation is `supported`, set `quote` to the claim's marker-free sentence
  (`cleanSent` in `checkCitations`, `claim.Text` in `finalizeClaims`). The value can differ from the raw chunk bytes in exactly the
  `normQuote` ways (an inline `[12]` removed, whitespace collapsed). `normQuote(content)` always contains `normQuote(quote)`, and the
  README row says so. On the LLM path the exact match ran on the sanitized text. The quote is set only if `inPassage(quote, rawContent)`
  also holds (the `<passage` edge case), otherwise it is omitted and the status stays as scored.
- **(b) Model-supplied quote** (`synthesisClaim.Quote`, parsed since AI-6b, unused until now). The quote belongs to the claim, and the check runs on every citation of that
  claim: if `inPassage(claim.Quote, rawChunk)` fails, that citation is `unsupported` (score kept, so the evidence still shows it) and gets
  no quote. If it holds and the citation is `supported`, `quote = claim.Quote` (trimmed). This follows ADR-0014's per-citation wording
  literally. A claim that quotes passage 1 but also cites passage 2 loses citation 2 (open question Q2 names the per-claim alternative).
  The `synthesis-v1` prompt doesn't ask for quotes, so today this path runs only when a model adds one unprompted. Asking for quotes in the prompt is a separate, measured task.
- **Invariant:** `quote` present ⇒ `status == "supported"`. A verbatim quote on an unsupported or unverified citation is dropped,
  so the UI never shows a quote as evidence for a claim that failed its check.
- Exact-match support (a) and a model quote (b) can both apply to one citation, when the claim is itself a verbatim sentence. Then (a) wins, because the claim text *is* the quote.

### 4. `claims[]` (AI-8b)
- **LLM path** (`finalizeClaims`): one `Claim` per **kept** claim, in answer order. `text = claim.Text` (marker-free, as parsed),
  `markers = claim.Citations` (distinct, 1..K), `status = claimStatus(itsCitations)`. A kept claim always has a supported citation, so
  its status is `supported`. Dropped claims don't appear, because they aren't in the answer.
- **Extractive path** (`checkCitations` → `finalize`): one `Claim` per sentence of `splitIntoSentences(answer)`, in order, **including any
  sentence without an in-range marker** (`markers: []`, status `unverified`). The extractive builder always writes exactly one in-range
  marker per sentence, so in practice every claim has one marker. The rule is there so that `claims` covers the whole answer: EVAL-6's
  `coverage_units` switches to `claims` when they're present, and counting only cited sentences would inflate coverage to 100%.
  An extractive claim's `markers` are its in-range markers **in occurrence order, not deduplicated**. That's how `checkCitations` already emits
  citations (one per occurrence), and it keeps the ordering invariant exact. `checkCitations` builds the claims in its sentence loop
  and returns them (its third return value). `validateCitations` ignores them.
- `claimStatus(cites)`: `supported` if any citation is supported, else `unverified` if any is unverified, else `unsupported`. With no
  citation at all it returns `unverified`.
- **Refusals: `claims` absent** (`nil` + `omitempty`), on every refusal path including the early one. The refusal JSON keeps exactly
  today's keys, and nothing in a refusal is a claim the server makes. AC5 pins absence with `_, ok := m["claims"]; ok == false`.
- `prompt_version = synthesisPromptVersion` is set only on the response `finalizeClaims` returns. Quoted answers, the quick stage and refusals leave it empty.

### 5. Provenance (AI-8a)
`newCitation` sets `PaperVersion = hit.Version` and copies `hit.Page` by value (`p := *hit.Page; c.Page = &p`, so the citation
doesn't alias the hit). No `search.go` change: RET-2 sets `Version` on every hit. `Page` stays nil until ING-11b, so tests use
hand-built hits (AC4).

### 6. Raw chunk in `content` on the LLM path; scoring on the text the model saw (AI-8a)
This settles the QA-8 Notes question (2026-11-08) against the code as it is now:
- `synthesize` passes `passages []contextPassage` to `finalizeClaims` instead of `passageHits(passages)`.
- `finalizeClaims` builds each `VerifyPair` with `Passage: passages[m-1].Text` (sanitized and possibly truncated, i.e. the text the model saw;
  scoring is unchanged). It builds each citation from `passages[m-1].Hit`, the original hit with **raw** `Content`, and checks quotes (3a/3b) against
  `passages[m-1].Hit.Content`.
- The `insufficient_evidence` evidence uses `p.Hit` as well, so the raw chunk is shown.
- `passageHits` then has no caller. It is deleted along with `TestPassageHits` (rag_test.go:918-931). Both deletions are counted in the estimate.
- Effect: in the rare chunk containing `<passage`/`<question`, the user now sees the chunk as stored, not `&lt;passage`. A truncated top
  passage (one over-budget chunk, practically never at 512-token chunks against a 3000-token budget) shows the whole chunk, while the score is over the prefix
  the model saw. A claim supported by the prefix is supported by the whole chunk too.

### 7. Versioned `pdf_url` (AI-8a)
When `hit.Version > 0`, `newCitation` uses `arxiv.PDFURL(hit.ArxivID, hit.Version)` (`internal/arxiv/id.go:36`, already used by the downloader
and ingester, so `query` already imports the package). When it is 0, it keeps today's `https://arxiv.org/pdf/<id>.pdf`. `papers.arxiv_id` is stored without a
version suffix (the crawler strips it with `arxiv.SplitVersion`, crawler.go:183, and on-demand ingest with `ExtractCleanArxivID`,
ingester.go:100), so this can't produce `…v2v2.pdf`.

**Consumers of the old `pdf_url` form and other changed values** (grep at `40dec5a`):

| Consumer | Reads | Effect |
|---|---|---|
| `frontend/src/components/ReferencesStack.jsx:45`, `SynthesisView.jsx:52` | `pdf_url \|\| unversioned fallback` | Link opens the cited version. The fallback only runs when `pdf_url` is empty, which never happens. No change needed |
| `frontend/src/components/PapersLibrary.jsx:129` | builds its own URL from `/v1/papers` | Not an `/v1/ask` consumer |
| `frontend/src/components/ReferencesStack.jsx:96` | `content` | LLM path shows the raw chunk instead of the sanitized one (decision 6). That is what the field always meant |
| `ReferencesStack.jsx:70` badge | `supported` | Unchanged meaning. FE-3/FE-4 can switch to `status` later |
| `App.jsx` | `answer`, `citations[].marker`, `answer_kind`, `synthesis_available`, `refusal_reason` | Unchanged |
| `scripts/evaluate_answers.py` (`classify`, `coverage_units`, `case_record`) | `refusal_reason`, `citations[].{marker,arxiv_id,chunk_id,supported,score}`, `claims[].markers` | Same classification. Coverage is the same because claims = all answer sentences (decision 4). AC6 test |
| `scripts/answer_review.py:35-39` | `claims[].{text,markers}` when present | Units become claims, which on the extractive path are the same sentences |
| `tests/test_m3_query.py:49-53` | `marker`, `score`, `supported`, `title` | Unchanged |
| `internal/query/rag_test.go:178, 575` | assert the unversioned `pdf_url` | Hits there have `Version` 0, so the assertions still hold. AC4 adds the versioned case |
| `scripts/arxiv_replay.py:44`, `internal/downloader` | the downloader's fetch URL | Not citation links. Unaffected |

## Alternatives considered
1. **Claims nest their citations** (ADR-0014 Option 3): this would break the frontend, the eval and M3, and ADR-0014 rejected it. The ordering invariant gives
   FE-4 the same information without a shape change.
2. **Derive `status` from `score` alone** (e.g. `score == 0 → unverified`): wrong. A checked NLI score can be exactly 0, which is the whole reason
   for the distinction. The status has to come from `labelScore`'s `ok`.
3. **Refusal evidence: `unsupported` for every hit unless `verification_unavailable`** (the ticket's literal rule): rejected in favour of
   "checked → unsupported, else unverified" (Q1). One rule covers all four refusal paths and never claims a check that didn't run.
4. **Model quote checked per claim** (keep the quote on the citations whose chunk contains it, and mark the claim's citations `unsupported` only when it's in
   none of them): kinder to multi-citation claims, but looser than ADR-0014's per-citation wording. Rejected for now (Q2). It is a
   one-function change if pm-lead or Mahesh prefer it.
5. **Keep `passageHits` and add a raw-content map**: two hit slices that must agree on index. Passing `contextPassage` (which already holds both
   texts) is simpler and deletes code.
6. **`claims: []` on refusals**: also allowed by AC5. Rejected because it adds a key to today's refusal JSON for no reader.

## Contracts and invariants
- **HTTP API** (shared contract): additive `/v1/ask` fields as ADR-0014 (Accepted) Option 1 lists them. `pdf_url`'s value change and `content`'s raw
  text on the LLM path are value changes within the fields' existing meaning (RET-2 design note; QA-8 Notes, 2026-11-08, item 5).
- **ADR-0018 (Proposed)**, what depends on it:
  - *Not added:* `answer_source`. If Option 2 is chosen, it's an additive follow-up.
  - *README row (AI-8b):* documents `quick`, `answer_kind`, `synthesis_available` and `insufficient_evidence` as implemented, marked
    "(ADR-0018, Proposed)". If ADR-0018 takes Option 3 (revert), those words change again. That's a README edit, not a code change.
  - *Status rules:* follow the code as it is (quote or NLI ≥ 0.50). If the meaning of `SupportThreshold` changes, only the numbers move, not the rule.
  - *`insufficient_evidence` evidence = `unverified`:* if Option 3 removes the path, the rule goes with it.
  - **Nothing in AI-8a or AI-8b waits on ADR-0018.** Both are buildable now.
- **Grounding invariants** (kept and tested): `supported == (status == "supported")` for every citation. `unverified` is never `supported`.
  `quote` present ⇒ supported and `inPassage(quote, content)`. Markers outside 1..K are still discarded (no change to `parseSynthesis`/`checkCitations`).
  An LLM claim without a supported citation is still never shown. Refusal evidence is never `supported`.
- **Unchanged:** embedding model, chunk format, `SupportThreshold`, `EarlyRefusalThreshold`, the prompt (`synthesis-v1`), verifier
  calls (same pairs, same single batch), logs (counts only. The quote check adds no text to logs).
- **Eval impact:** CI's eval runs without an LLM (quoted path). There, statuses only relabel what `supported` already says, quotes need no
  extra check, and `pdf_url`/`content`/`paper_version` don't enter any metric. Expected: identical gate numbers. The model-quote rule (3b) can only
  lower `supported_citation_rate` on the LLM path, which CI doesn't measure (EVAL-8's job). AC8 runs `eval.yml` once per PR.

## Test plan
All Go tests use the existing fakes (`fakeSearcher`, `fakeVerifier`, `fakeReranker`, `llmtest.Fake`): no network, no key, no infra.

| AC | Test (name / type) | PR | CI? |
|---|---|---|---|
| AC1 | `checkAskInvariants(t, resp)` helper: claims non-empty on non-refusals, each claim has text/status ∈ enum/non-nil markers; every citation has `status` ∈ enum, `supported == (status == supported)`, `quote ⇒ supported ∧ inPassage`; the ordering invariant; refusals have no `claims`. Called from **every existing test that gets an `AskResponse`** in `rag_test.go` and `synthesis_test.go` (one added line each, about 20 sites) | 8b (citation half in 8a: `checkCitationInvariants`) | yes (`make test-go`) |
| AC2 | `TestCitationStatusRule`, table over both `checkCitations` (paraphrased sentence → NLI) and `finalizeClaims` (LLM reply): rows `score 0.9 → supported`, `0.50 → supported`, `0.49 → unsupported`, `0 checked → unsupported (not unverified)`, `verifier error`, `wrong score count`, `nil verifier`, `NaN`, `-0.1`, `1.1` → `unverified`, `supported == false`, score 0. Mutation: delete each `labelScore`/`scorePairs` failure branch in turn; every mutant fails a row | 8a | yes |
| AC2 (refusals) | `TestRefusalEvidenceStatus`: `verification_unavailable` mixed (hit 1 checked 0.3 → unsupported, hit 2 failed → unverified); `all_citations_unsupported` with 5 hits (cited 1–3 unsupported, 4–5 unverified); no in-range marker (all unverified); `insufficient_evidence` (all unverified); early refusal (`citations == []`) | 8a | yes |
| AC3 | `TestCitationQuote`: (a) extractive exact match → `quote` == the answer sentence without its marker, `inPassage(quote, content)`; (b) LLM quote with extra whitespace/newlines, verbatim → kept; (c) LLM quote not in chunk, fake verifier 0.9 → `unsupported`, no quote, claim dropped (or kept via another citation); (d) chunk containing `<passage`: `content` is raw (no `&lt;`), the pair sent to the verifier is the sanitized text, and a model quote of the raw text is kept; (e) NLI-supported paraphrase without a model quote → no `quote` | 8a | yes |
| AC4 | `TestCitationProvenance`: hand-built hit with `Version: 3, Page: &4` → `paper_version 3`, `page 4`, `pdf_url` ends `v3.pdf`, the citation's page pointer isn't the hit's; `Page: nil` → no `"page"` key in JSON; `Version: 0` → unversioned URL. Both paths | 8a | yes |
| AC5 | `TestAskClaims`: extractive: one claim per quoted sentence, markers `[i]`, `answer_kind quoted`, no `prompt_version` key; LLM (`twoClaims`): claims = kept claims in order with their markers, `answer_kind synthesized`, `prompt_version == "synthesis-v1"`; dropped claim absent; quick stage → no `prompt_version`; every refusal path → no `claims` key | 8b | yes |
| AC6 | `TestAskResponseShapeAndConstructor` extended: the old key lists are still present with the same JSON types (string/number/bool/array), new keys added (`paper_version`, `status` always; `page`, `quote`, `claims`, `prompt_version` only when set). Python: a new test in `tests/test_evals_data.py` feeding `classify`/`coverage_units`/`case_record` the same response with and without the new fields → equal results. PR body: `grep -rn` of `frontend/src` for every field (table above) | 8a (Go keys) + 8b (Python, after ING-11b merges, see Split) | yes (`make test-py`) |
| AC7 | `go test -coverprofile=c.out ./internal/query/ && go tool cover -func=c.out \| grep rag.go` rows pasted in each PR (scratch module if Go 1.25 is unavailable locally, as before; CI is the source of truth); `git diff --stat` < 400 per PR | 8a, 8b | partly (coverage printed locally) |
| AC8 | README `/v1/ask` row (8b). `gh workflow run eval.yml --ref agent/ai/AI-8a` (and `-8b`), with the gate table compared to nightly 43902662193 (supported 100%, correct refusals 100%, `GATE: PASS`) | 8a, 8b | yes (dispatch) |

Failure paths covered: every `labelScore`/`scorePairs` failure branch, all five refusal paths, fabricated model quote with high NLI, the
sanitized-vs-raw chunk, nil page, version 0, an uncited extractive sentence (direct `checkCitations` call with a hand-written answer).

Mutation checks (run locally, never pushed): (1) `Supported` set independently of `Status`; (2) `!ok → unsupported`; (3) refusal
evidence always `unsupported`; (4) model quote checked against `p.Text` instead of the raw chunk; (5) quote kept on an unsupported
citation; (6) claims only for cited sentences; (7) `prompt_version` on quoted answers. Each must fail at least one test.

## Split and size (AGENTS.md §3, < 400 changed lines per PR)
The seam is at a layer boundary: **AI-8a = per-citation labelling** (what one citation says about one passage) and **AI-8b = per-answer
structure** (claims, prompt, docs). AI-8b builds on AI-8a's statuses, so it depends on **AI-8a merged**. Both edit `rag.go` and the
same test files, so they run one after the other, not in parallel.

| | AI-8a (provenance + status + quote + pdf_url + raw content) | AI-8b (claims + prompt_version + README + AC6 Python) |
|---|---|---|
| Production `rag.go` | ~95 (fields/consts 15, `newCitation` 15, call sites + refusal rule 15, `scorePairs` exact 8, `inPassage` 6, quote logic 25, `finalizeClaims` takes passages 11) | ~55 (`Claim`/fields 12, `checkCitations` claims 18, `finalizeClaims` claims 10, `claimStatus` 10, prompt_version 2, `finalize` 3) |
| Deletions | ~25 (`passageHits` 10, `TestPassageHits` 15) | ~0 |
| New tests | ~175 (AC2 table 55, refusal statuses 40, quote 55, provenance 25) | ~75 (claims 55, shape additions 10, Python AC6 10) |
| Fakes / helpers | ~25 (`checkCitationInvariants`, a hit builder with version/page) | ~45 (`checkAskInvariants` 25, ~20 one-line call sites) |
| Edited existing tests | ~15 (shape test keys, `finalizeClaims` callers, `citeLabel` sites) | ~5 |
| README | 0 | ~2 (one row) |
| **Total** | **~335** | **~180** |

If AI-8a measures over 400 once built (lesson 2026-11-07, OPS-H8: fakes ran over the estimate), the fallback seam is **decision 3b (model-supplied
quote)**, which moves to AI-8b. It's the only piece no current prompt exercises, and deferring it violates nothing: until it lands, no
model quote is ever emitted, so no unchecked quote can appear. Moving it takes about 20 production and 30 test lines.

**File rule with ING-11b** (cycle plan, 2026-11-17): ING-11b edits `tests/test_evals_data.py` and the README `/v1/search` row. AI-8a touches
neither. AI-8b's AC6 Python test goes in `tests/test_evals_data.py`, so **AI-8b starts after ING-11b merges** (it already waits on AI-8a).
AI-8b edits only the `/v1/ask` README row.

## Risks and rollout
- **R1, the strict model-quote rule drops a real claim** (a model quote that is slightly paraphrased, or a quote shared across citations): only on the LLM
  path, and only when the model adds a quote unprompted. This is detected by the `dropped unsupported claims` log count, plus EVAL-8 when it runs with an LLM. Rolled back by
  reverting 3b (one function) or switching to alternative 4.
- **R2, a client keys on the unversioned `pdf_url`**: none found (consumers table). The frontend fallbacks are untouched.
- **R3, `unverified` on refusal evidence reads oddly next to `refusal_reason: all_citations_unsupported`** (no-marker case): FE-3 copy
  can say "not checked". Q1 decides whether that's acceptable.
- **R4, raw `content` with `<passage` in it**: harmless to the UI (React escapes text). The model never sees `content`, only `p.Text`.
- **R5, size overrun**: the fallback seam above.
- Rollout: two draft PRs, AI-8a then AI-8b, each with a before/after `eval.yml` run. Rollback is a revert of each PR. Every change is additive or a value refinement.

## Open questions (for pm-lead)
- **Q1, refusal evidence that was never checked** (decision 1): `unverified` (this design) or `unsupported` (the ticket's literal rule)? It only
  affects evidence hits no sentence cited under `all_citations_unsupported`. No metric changes either way.
- **Q2, model quote on a multi-citation claim** (decision 3b): per citation (this design, ADR-0014 literal) or per claim (alternative 4)?
  Inert until a prompt asks for quotes.
- **Q3, FE-4 claim→citation mapping**: is the positional ordering invariant enough for FE-4, or should a later ADR add explicit per-claim
  citation indices? Nothing in AI-8 needs the answer, but FE-4's design does.
- **Q4, `quote` vs raw bytes**: `quote` matches `content` under `normQuote` (inline references removed, whitespace collapsed), not
  byte-for-byte. FE-4's highlight would need the same normalisation, or character offsets (a later ADR). Acceptable for now?
- **Jira:** AI-8's story under KAN-1 isn't linked in the ticket yet, and this agent session has no Jira tool. The move to Design and the design link
  are left to the orchestrator/pm-lead.

## PM decision
_(pm-lead fills)_
