<!-- Saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/28#issuecomment-6708866533 (the QA harness could not write report.md). -->

[qa-reviewer] QA round 1: **FAIL** · AI-6 · PR #28 @ `c457576`

# QA report — AI-6 · PR #28 · round 1

**Verdict:** FAIL
**Reviewed commit:** `c45757622c2476f37128eaa4c8c0da527cb5e210` · **Date:** 2026-11-07
**Ticket:** [`agents/tasks/AI-6.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/AI-6.md) · **PRD:** Product QA-8, QA-3, §7 principle 1; Technical §7.2; ADR-0002 · **Design:** [`docs/design/QA-8.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/docs/design/QA-8.md) (APPROVED with conditions)
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence

The code is in good shape. The tests are strong (14/14 independent QA mutations killed), CI is green, and nothing in `Ask` changes.
The round fails on two binding design conditions (4 and 5). Both ask for content in the **PR description**, and it's missing.
They are fixes to the PR text only; no code change is needed. Separately, AC3 is deferred to AI-6b, and pm-lead must make that formal before APPROVE (finding 3, `[spec]`).

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 128440466634, Go 1.25.0 | **pass**: `make lint-go`, `make test-go` (`ok arxivlens/internal/query 0.310s`), `make build-go` ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/00-ci-checks.png?raw=true``), [01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/01-ci-go-job.png?raw=true```)) |
| Python M0 unit tests | CI | pass |
| Frontend (lint, test, build) | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Agent ownership check | CI + local rerun | pass: `Ownership OK for role=ai (302 changed lines)` ([07](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/07-ac6-diff-size-scope.png?raw=true))```` |
| Ticket verification commands | local, QA-built stdlib-only scratch module (Go 1.24.7, stub `internal/db` + `pgx`). Each run `cmp`s the files against the PR head first | `go vet` clean, `gofmt -l` empty, new tests PASS, 33/33 top-level tests in `rag_test.go` + `search_test.go` PASS, rag.go 98.5% |
| `make lint` / `make test-unit` | not run locally: go.mod needs Go 1.25 (toolchain download blocked), test_m0 needs HF | CI covers `lint-go`/`test-go`/M0 (above) |
| `make eval` | not run: nothing on the request path changes (`Ask` untouched, no non-test caller; [05](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/05-ac4-no-behaviour-change.png?raw=true))````` | n/a, accepted |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 `selectContext` | ✅ | `TestSelectContext` covers 10 subtests: empty, zero budget, exact fit, one over, stop-not-skip, dup ChunkID, identical content without using a cap slot, zero IDs both kept (cond. 2), cap 3, grouping A1,B1,A2,C1 → A1,A2,B1,C1. Every passage is checked for `Marker==i+1`, `Hit`/`HitIndex` link and `Tokens`. `TestSelectContextOversizeTopPassage` checks a whole-word prefix with cost ≤ budget, plus the three empty cases. Also `TestPassageTokensBoundsRenderedBlock` and `TestPassageHits`. All PASS ([02](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/02-ac1-select-context.png?raw=true)).`````` A QA property check (20k random hit lists and budgets) held every invariant: budget, cap, no dup ID or content, papers contiguous, markers 1..K, valid UTF-8, rendered estimate ≤ ΣTokens, delimiter counts ([09](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/09-qa-probes.png?raw=true)).``````` Condition 3 (empty-result contract) is in the doc comment. |
| AC2 `buildSynthesisPrompt` | ✅ | `TestBuildSynthesisPrompt`: each selected block appears exactly once, in marker order, with number/title/arXiv ID/section/text; the unselected hit is absent; the question sits inside `<question>`; the rule lines and JSON form are present (cond. 4 wording); the prompt is the constant. `TestBuildSynthesisPromptInjection` covers forged `</passage>`, `<passage n="9">`, `</PASSAGE >`, `</question>`, `<Question>` and a newline title. Both PASS ([03](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/03-ac2-build-prompt.png?raw=true)).```````` The system prompt matches design §4 line for line (read in the diff). |
| AC3 `parseSynthesis` | ❌ not in this PR (deferred) | The code has no `parseSynthesis`, no types and no `TestParseSynthesis`; `agents/tasks/AI-6b.md` doesn't exist ([04](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/04-ac3-parser-absent.png?raw=true)).````````` Design condition 1 permits the deferral, see finding 3. |
| AC4 no behaviour change | ✅ | 135+/0− and 167+/0−. `rag.go` hunks are only the import line and one block after `buildTemplateAnswer`. The `awk … Ask … \| grep -c` prints `0`. No non-test caller of the new names. `go vet` is clean, and so is CI `make lint-go`. 33 top-level tests PASS and 0 FAIL; the 19 pre-existing `rag_test.go` tests are unmodified ([05](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/05-ac4-no-behaviour-change.png?raw=true))`````````` |
| AC5 rag.go ≥ 90% | ✅ (local pasted run; CI doesn't print query coverage) | All 9 new functions at 100.0%, the lowest existing row is `embedBatch` 90.0%, and the per-file total from `c.out` is **194/197 = 98.5%** ([06](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/06-ac5-coverage.png?raw=true)).``````````` QA reproduced it independently. |
| AC6 diff < 400 | ✅ | `2 files changed, 302 insertions(+)` ([07](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/07-ac6-diff-size-scope.png?raw=true))```````````` |

### Design conditions (binding)
| # | Condition | Status |
|---|---|---|
| 1 | Diff < 400; seams; "if `rag.go` alone adds > 200 lines, take seam (c) right away" | ✅ permitted. Seam (c) was taken and stated in the PR and the ticket. The "214 lines with the parser" trigger can't be verified, because the draft was not kept. That's plausible (135 lines plus design §5's ~50-line parser). Keeping `passageHits` is fine: seam (c) supersedes (b). |
| 2 | `ChunkID == 0` not a dedup key + case | ✅ code, table case, and the mutation is killed ([08](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/08-mutations.png?raw=true`````````````)) |
| 3 | Empty-result contract documented | ✅ `selectContext` doc comment |
| 4 | Every line of the system prompt verbatim in the PR description | ❌ **missing**: finding 1 |
| 5 | Mutation results in the PR with failing test names | ❌ **missing** (ticket Notes only): finding 2 |
| 6 | "CI is the source of truth"; AC5 from a pasted run | ✅ |

## PRD fit
This is the deterministic half of QA-8 / Technical §7.2. Context selection keeps rerank priority (ADR-0010), and grouping by paper serves QA-3's multi-paper comparison. The prompt enforces evidence first (§7 principle 1: cite every factual statement, insufficient-evidence refusal), and `passageHits` makes validation score against exactly the text the model saw. Zero runtime risk, because nothing calls it yet. The honest-refusal parsing half isn't here yet; it's AI-6b.

## Findings
1. **[blocking] Design condition 4 not met: the system prompt isn't in the PR description.** The body says "system prompt verbatim from design §4" but doesn't show it. Condition 4: "Every line of the system prompt appears verbatim in the PR description for Mahesh: it's product content." Fix: paste `synthesisSystemPrompt` (the 10-line const in `internal/query/rag.go`) into the PR body as a fenced block, with `synthesisPromptVersion = "synthesis-v1"`. It's a PR-text change only.
2. **[blocking] Design condition 5 not met: no mutation-check results in the PR.** Condition 5 requires each test-plan mutation in the PR with its failing test name, and a note that it ran in the scratch module. Fix: add the table from the ticket Notes (skip-not-stop → `TestSelectContext`, `TestSelectContextOversizeTopPassage`, `TestPassageHits`; no sanitizing → `TestBuildSynthesisPromptInjection`; …) and say that the third design mutation (out-of-range marker kept) moves to AI-6b with the parser. QA's independent 14-mutation run (14/14 killed, [08](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/08-mutations.png?raw=true``````````````)) agrees.
3. **[spec] AC3 is deferred to an AI-6b that doesn't exist yet. pm-lead must resolve this before APPROVE.** Condition 1 seam (c) allows shipping without the parser and says "pm-lead *then* specs AI-6b (parser) as a QA-8 dependency". As of this review: `agents/tasks/AI-6b.md` is absent, AC3 in `AI-6.md` is still an open checkbox with no "moved" annotation, and the PR's "Follow-ups created: AI-6b" isn't true yet. pm-lead: (a) create `AI-6b.md` + Jira story with design §5 and the AC3 / `TestParseSynthesis` / `TestParseSynthesisErrorHasNoCompletionText` rows unchanged, and add AI-6b to QA-8's `Depends on`; (b) annotate AC3 in `AI-6.md` as moved (not edited), so AI-6 can close on AC1, AC2 and AC4–AC6. This is not the developer's fix: the developer followed the approved design.
4. **[nit] Unrecorded design refinement.** `passageTokens` counts the header fields with `metaField` (one line + sanitized), and design §2 says `oneLine`. The refinement is justified, because escaping lengthens `<passage` to `&lt;passage`. It's tested (`TestPassageTokensBoundsRenderedBlock`), and the overhead mutation is killed. Record it in `docs/design/QA-8.md`. The design's import list is also stale (AI-6 adds `sort`).
5. **[nit] Delimiter look-alikes pass through `sanitizeBlock`.** `< /passage>`, `</ passage>`, `<\tpassage n="9">` and fullwidth `＜/passage＞` are not escaped ([09](```````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b6c9dfb9f97745641db7c0b03740d26caee46080/agents/reviews/AI-6/evidence/09-qa-probes.png?raw=true)).``````````````` That matches the approved regexp, and system rule 3 is a second line of defence, so it doesn't block. Consider `(?i)<\s*(/?)\s*(passage|question)` in AI-6b or QA-8.
6. **[nit] Branch name.** The design's "Next" line says `agent/ai-engineer/AI-6`, but `ownership-check.sh` accepts only `agent/ai/...`. pm-lead should fix it in the design for QA-8 and AI-6b.

## Missing tests
- No case where `selectContext` reaches the truncation branch after earlier hits were **skipped** (dup/cap), so `len(taken)==0` but `i > 0`. The code handles it, but nothing pins it.
- Empty-content hits: a second `Content == ""` hit is dropped as a "duplicate", and the first is sent with an empty `text:`. That behaviour is unspecified and untested. Decide in AI-6b/QA-8 whether to skip empty passages.
- Whitespace-only question → empty `<question>` block. Low risk, because `Ask` refuses empty questions earlier.

## Hand-off
FAIL → ai-engineer for findings 1–2 (PR description only; no code change expected). Finding 3 → pm-lead. Round 2 re-checks conditions 4/5 in the PR body, CI on the head, and that AI-6b exists.
Jira: the Atlassian connector isn't available in this QA session, so the orchestrator posts the `[qa-reviewer]` Jira comment and links and moves KAN-38 → In Progress.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

# QA report — AI-6 · PR #28 · round 2

**Verdict:** PASS
**Reviewed commit:** `c45757622c2476f37128eaa4c8c0da527cb5e210` (same as round 1; branch tip and PR head both confirmed) · **Date:** 2026-11-07
**Scope of this round:** the round-1 findings. The code didn't change, so the round-1 AC verdicts for AC1, AC2 and AC4–AC6 still hold. AC3 has moved to AI-6b.
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/0c2917459820bf9e7be5bd5a913abba2219875fd/agents/reviews/AI-6/evidence (`r2-*`). The check scripts are in [`r2-scripts/`](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/0c2917459820bf9e7be5bd5a913abba2219875fd/agents/reviews/AI-6/r2-scripts).

## Test results
| Check | Source | Result |
|---|---|---|
| CI on `c457576` (5 check runs) | GitHub check-runs API, re-fetched this round | all **success**: Go (vet, gofmt, test, build), Python M0, Frontend, DB, Agent ownership. The branch tip is still `c457576`, with `2 files changed, 302 insertions(+)` ([r2-00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c2917459820bf9e7be5bd5a913abba2219875fd/agents/reviews/AI-6/evidence/r2-00-ci-checks.png?raw=true)) |
| `make lint` / `make test-unit` / `make eval` | — | not re-run: the code is unchanged since round 1. Same reasons as round 1 (Go 1.25 toolchain download blocked, HF model; no request-path change). CI is green. |

## Round-1 findings: re-check
| # | Finding | Status | Evidence |
|---|---|---|---|
| 1 | [blocking] Cond. 4: system prompt verbatim in the PR body | ✅ **fixed** | I fetched the PR body over REST and the const from `git show c457576:internal/query/rag.go`. The fenced `text` block equals `synthesisSystemPrompt` **byte for byte**, all 10 lines are present, and `synthesisPromptVersion = "synthesis-v1"` is stated ([r2-01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c2917459820bf9e7be5bd5a913abba2219875fd/agents/reviews/AI-6/evidence/r2-01-cond4-system-prompt.png?raw=true)) |
| 2 | [blocking] Cond. 5: mutation table with failing test names in the PR | ✅ **fixed** | The section "Mutation check (design condition 5)" has 6 rows and states that the runs used a scratch module with a `cmp` restore. For every row, the failing-test set is **identical** to QA's independent round-1 run ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c2917459820bf9e7be5bd5a913abba2219875fd/agents/reviews/AI-6/evidence/08-mutations.txt)). It also says the out-of-range-marker mutation moves to AI-6b ([r2-02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c2917459820bf9e7be5bd5a913abba2219875fd/agents/reviews/AI-6/evidence/r2-02-cond5-mutations.png?raw=true)) |
| 3 | [spec] AC3 deferred to a non-existent AI-6b | ✅ **resolved by pm-lead** (`8738879`) | `agents/tasks/AI-6b.md` exists. AI-6's AC3 text appears verbatim in AI-6b AC3, and both design test-plan rows (`TestParseSynthesis`, `TestParseSynthesisErrorHasNoCompletionText`) appear verbatim in it. Those design rows were only ever touched by the design commit `effaf87`, and §5 is unedited. AI-6b covers the out-of-range-marker mutation (its AC8). AC3 in `AI-6.md` carries a "Moved to AI-6b" annotation, and no AC line was edited since build (only the Status row changed). QA-8 `Depends on` lists AI-6b ([r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c2917459820bf9e7be5bd5a913abba2219875fd/agents/reviews/AI-6/evidence/r2-03-spec-and-design-record.png?raw=true)) |
| 4 | [nit] `metaField` refinement + `sort` import unrecorded | ✅ recorded | The design "Post-build record" items 2–3 and the §1 and §2 "as built" notes ([r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c2917459820bf9e7be5bd5a913abba2219875fd/agents/reviews/AI-6/evidence/r2-03-spec-and-design-record.png?raw=true)) |
| 5 | [nit] Delimiter look-alikes | ➡️ carried to AI-6b | AI-6b scope + AC4 (widened regexp). Fullwidth is explicitly out of scope there and left to system rule 3. No change in this PR, as expected. |
| 6 | [nit] Branch name in design "Next" | ✅ fixed | Now `agent/ai/AI-6`, and `agent/ai-engineer/` no longer appears ([r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/0c2917459820bf9e7be5bd5a913abba2219875fd/agents/reviews/AI-6/evidence/r2-03-spec-and-design-record.png?raw=true)) |
| — | Round-1 missing tests (truncation after skip, empty content) | ➡️ carried to AI-6b AC5 | pm-lead decided to skip empty-content passages. The whitespace-only question stays out of scope, with a stated reason. |

## Acceptance criteria (unchanged code; carried from round 1)
AC1 ✅ · AC2 ✅ · AC3 moved to AI-6b (not part of AI-6's closure, per the annotation) · AC4 ✅ · AC5 ✅ (98.5%) · AC6 ✅ (302 lines). Design conditions 1–6 are now all ✅.

## New findings
1. **[nit]** The PR body's "Follow-ups requested" line still says "pm-lead to create the spec and Jira story". AI-6b now exists, so pm-lead can update it to "created" when they write the evidence into the PR description. It doesn't block.

## Hand-off
**PASS** → pm-lead for final review (Jira KAN-38 → PM review). Jira: if this session can't reach the Atlassian connector, the orchestrator posts the `[qa-reviewer]` comment and links.
