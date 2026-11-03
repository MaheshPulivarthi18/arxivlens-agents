[qa-reviewer] **QA report: AI-2 · PR #11 · round 1. Verdict: PASS**

**Reviewed commit:** `c9ae07c3894749fcd7bb6ead5b83efd70ce791a6` (base `bb9ee90`) · 2026-11-03 · **Ticket:** [AI-2](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/tasks/AI-2.md) · **PRD:** QA-4, §7, §8 supported ≥ 90% · no design doc (not design-required)
**Evidence pack:** [agents/reviews/AI-2/](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2) (scripts in [scripts/](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/scripts)). The harness blocked me from writing `report.md`, so this comment is the report and the orchestrator will save it verbatim.

I checked the work myself and did not use the developer's self-report. Every result below comes from a command I ran or a CI log I fetched.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 125824913066 | **pass**: `go vet ./...`, `ok arxivlens/internal/query`, build ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/00-ci-checks.png?raw=true),`` [01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/01-ci-go-job-log.png?raw=true))``` |
| Python M0 / Frontend / Agent ownership check | CI | pass / pass / pass |
| Ticket verification (`go vet`, `gofmt -l internal/query`, `go test -cover`) | local, labelled scratch signal | pass. I copied the PR head's real `rag.go` and `rag_test.go` (byte-identical, checked with `cmp`) into a stdlib-only scratch module and ran it under Go 1.24.7 inside `unshare -rn`, which leaves only `lo` and no network. Results: 9 top-level and 51 subtests pass, 0 fail, `validateCitations` coverage 97.4%. `gofmt` is clean ([03](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/03-ac2-offline-tests.png?raw=true))```` |
| `make test-unit` / `make lint` | CI | not run locally, because go.mod needs Go 1.25 and the sandbox can't download it. CI runs `make lint-go` and `make test-go`, and both are green |
| `make eval` | not run: infra unavailable | I tried it. There is no Docker daemon, nothing listens on :8080, and the run exits 2 with `ModuleNotFoundError: psycopg` ([07](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/07-ac4-eval-not-runnable.png?raw=true))````` |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: no `supported = true` without a computed cosine ≥ threshold | ✅ | [02](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/02-ac1-grep.png?raw=true):`````` the ticket's grep finds nothing (exit 1). The only assignments are `supported := false` (rag.go:182) and `supported = score >= SupportThreshold` (rag.go:189), which runs only when both vectors are non-empty and there was no embed error. There is no `0.75` literal left, and `SupportThreshold = 0.50` is unchanged |
| AC2: three new cases pass with no network, DB or embedder | ✅ | `TestValidateCitationsFailClosedWhenUnverifiable` has 7 subtests: sentence-embed error, chunk-embed error, nil or empty vector on each side, and embedder down. All pass offline ([03](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/03-ac2-offline-tests.png?raw=true))``````` and in CI ([01](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/01-ci-go-job-log.png?raw=true)).```````` The same test **fails all 7** against main's fail-open `rag.go` ([04](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/04-ac2-new-test-fails-on-main.png?raw=true))````````` |
| AC3: `/v1/ask` JSON shape unchanged | ✅ | [05](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/05-ac3-json-shape-and-scope.png?raw=true):`````````` the exported declarations, JSON tags, field types and constants of `rag.go` are identical between main and the head. `server.go`, `search.go`, `client.go`, `README.md`, `shared/events` and `frontend/` are unchanged. `TestAskResponseShapeAndConstructor` passes. An unverified citation marshals with all 9 keys, `score` as a number (0) and `supported` as a bool (false) |
| AC4: `make eval` numbers, or "not run" plus the command | ✅ (not run) | The PR body says "not run: infra unavailable … Command: `make eval`", and my own attempt confirms the infra is missing ([07](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/07-ac4-eval-not-runnable.png?raw=true)).``````````` `evaluate_answers.py` counts only `supported is True`, so the rate can drop only on runs where the embedder fails. The verified path is unchanged, and mutations N15/N16 are killed |

**Scope:** only `internal/query/rag.go` and `rag_test.go` changed (both owned by ai-engineer, +94/−20). No ticket, review or doc files are in the PR, no third "unverified" state was added, and the frontend is untouched. The PR is still a draft.

## PRD fit
This delivers QA-4: a citation is labelled supported only when its similarity has actually been computed and is at or above the threshold. Otherwise it is shown as unsupported, which matches the honest-refusal principle in §7. It also removes the inflation of the §8 gated `supported_citation_rate`. The marker and its one-click source link stay in the response.

## Findings
1. [nit] The log counters are not asserted. Mutations N13 (`sentence_embed_errors` never counted) and N14 (`chunks_without_vector` never counted) survive. The other 14 of 16 are killed, including restoring fail-open, dropping either guard, logging per citation or on verified requests, leaking text, and dropping the trace id ([06](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/209432ed81528ef4dfb89041da10ca4161e4bcbb/agents/reviews/AI-2/evidence/06-mutation-tests.png?raw=true)).````````````
2. [nit] No test mixes a verified and an unverified citation in one answer, for example two hits where only hit 2's chunk embed fails. It would show marker 1 stays supported, marker 2 does not, and the log reports `unverified=1 citations=2`.
3. [nit] A dimension mismatch between the sentence and chunk vectors makes `cosineSimilarity` return 0. The citation still fails closed, but it is not counted or logged as unverified, so it can't be told apart from a real similarity of 0. This could be a follow-up.
4. [nit] The log's `trace_id` is a generated id because `Ask` doesn't put its trace id into ctx. This is already tracked by AI-4 (KAN-27) and is not a regression.
5. [spec] (pm-lead) After merge, move the QA-4 PRD row from ◐ to done and remove the AI-2 caveat in the §8 row (via a docs PR). ADR-0003 still has to decide how to treat an answer whose citations are *all* unsupported, for example during an embedder outage. Today the template answer is still returned with no refusal.

## Missing tests
- A mixed verified and unverified request (finding 2), and asserts on `sentence_embed_errors` and `chunks_without_vector` (finding 1). Optional: a dimension-mismatch case.

## Hand-off
**PASS → pm-lead final review.** All four ACs have evidence, the 4 CI checks on `c9ae07c` are green, and there are no blocking findings.


---
_Generated by [Claude Code](https://claude.ai/code)_


_Provenance: saved verbatim by the orchestrator from PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/11#issuecomment-6599796071 (qa-reviewer harness could not write report.md); evidence commit 209432e._

---

## PM review (round 1)

**Reviewer:** pm-lead · **Date:** 2026-11-03 · **PR:** #11 (draft) · **Head reviewed:** `c9ae07c3894749fcd7bb6ead5b83efd70ce791a6` (unchanged since QA; CI 4/4 green on it) · **Evidence commit:** `209432ed81528ef4dfb89041da10ca4161e4bcbb`

**Verdict: APPROVE**

### Product fit (Product PRD QA-4, §7, §8)
- QA-4 ("each citation is verified ... and labelled supported/unsupported"): after this PR, `supported` is true only when `score >= SupportThreshold` was actually computed from two non-empty vectors. The 0.75 fail-open path is gone, which closes the gap in the QA-4 row and Technical PRD line 291.
- §7 "evidence first / say I don't know": an unverifiable citation keeps its marker and its one-click `pdf_url`, so Priya and Marco still reach the source, but the claim is no longer presented as verified. This is the honest default.
- §8 "% citations marked supported ≥ 90%": the metric stops counting unverified citations as supported. The verified path is unchanged (mutations N15/N16 killed), so the rate can drop only on runs where the embedder failed. That drop is the point.
- No contract change: `Citation`/`AskResponse` fields, tags and types are identical (05), `SupportThreshold = 0.50` is unchanged (02), and `evals/thresholds.json` is untouched. No third "unverified" state was added, as the ticket required.

### Scope
Right size. Two owned files, +94/−20, exactly the ticket's Scope. The extra case (empty sentence vector also fails closed) and the one-line count-only log are both within "log the failure once per request". The renamed test flips AI-1's pinned fail-open expectation, which the ticket explicitly allows. That is not test weakening.

### Evidence check (every file opened, PNG and .txt)
| File | Proves | OK? |
|---|---|---|
| `00-ci-checks` | 4/4 check runs `success` on `c9ae07c`; PR draft, base `bb9ee90` | yes |
| `01-ci-go-job-log` | CI `go vet ./...` and `go test ./...` with `ok arxivlens/internal/query`, so the 7 new subtests pass in CI (AC2) | yes. Not verbose, but a package `ok` means every test in it passed |
| `02-ac1-grep` | the ticket grep exits 1 at head; the only assignment is `supported = score >= SupportThreshold`; main had `0.75`/`supported = true` at 183-184; no `0.75` literal left (AC1) | yes |
| `03-ac2-offline-tests` | byte-identical head files, run inside a network namespace with only `lo`: 7 fail-closed subtests pass, 51/51 subtests, `validateCitations` coverage 97.4%, gofmt clean (AC2) | yes |
| `04-ac2-new-test-fails-on-main` | the new test fails all 7 cases against main's `rag.go` (`score=0.75 supported=true`), so the test really guards the behaviour | yes |
| `05-ac3-json-shape-and-scope` | exported decls/tags/types identical; contracts untouched; an unverified citation marshals all 9 keys with `score` number 0 and `supported` bool false; diff = 2 owned files (AC3) | yes |
| `06-mutation-tests` | 14/16 mutants killed; N13/N14 (log counters) survive | yes. The survivors are non-blocking (counters are diagnostics, not product behaviour) |
| `07-ac4-eval-not-runnable` | `make eval` attempted: no Docker, :8080 refused, exit 2; PR body states "not run: infra unavailable" plus the command (AC4) | yes. "Not run" is the ticket's allowed outcome |

No secrets or private data in any evidence file.

### QA findings → disposition
1. [nit] log counters unasserted (N13/N14) → follow-up (backlog, below).
2. [nit] no mixed verified/unverified test → same follow-up.
3. [nit] dimension mismatch is scored 0 but not logged as unverified. The citation still fails closed, so users aren't affected → same follow-up (log it as unverified).
4. [nit] generated trace id in the log → already AI-4 (Ready; starts after this merges).
5. [spec] PRD rows → pm-lead does it after merge: a docs PR moves QA-4 from ◐ to ✅, drops the AI-2 caveat in the §8 row, and drops the "Known gap" paragraph in Technical PRD §9 (line 291). Per DoD 4 the PRD is updated via a PR in this repo, not in #11. The app README/CONTRIBUTING have nothing that describes the 0.75 fallback (checked), so #11 needs no doc change.

### Observations for follow-up (not blocking this PR)
- **UI wording:** `frontend/src/components/ReferencesStack.jsx:70-73` always renders `<ShieldCheck/> {score}% Verified`, with only the badge variant differing when `supported` is false. After this PR an embedder outage shows "0.0% Verified". Before, it showed a false "75.0% Verified" on the green badge, so this PR is an improvement, but the word "Verified" on an unsupported citation conflicts with QA-4/§7. This is already within FE-1 AC3; I added a note to `agents/tasks/FE-1.md`.
- **All-unsupported answers:** during an embedder outage every citation is now unsupported, but the template answer is still returned with no refusal. That is a policy question for ADR-0003 (Proposed, human decision). It is listed below as input for Mahesh and is not decided here.

### Follow-ups
- Backlog (ai-engineer, P2, test-only plus one log counter): a `rag_test.go` mixed case (2 hits, only hit 2's chunk embed fails → marker 1 supported, marker 2 not, log `unverified=1 citations=2`), assertions on `sentence_embed_errors` and `chunks_without_vector`, and counting a sentence/chunk dimension mismatch as unverified. Best bundled after AI-4 (same files).
- pm-lead docs PR after #11 merges: QA-4 → ✅, §8 caveat removed, Technical PRD §9 known-gap paragraph removed.
- FE-1 note (added): unsupported badge must not say "Verified".
