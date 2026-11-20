# AI-8c: Call `checkCitationInvariants` from the 11 `AskResponse` sites in `synthesis_test.go`

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P0 (finishes AI-8a AC1 on the LLM path; Phase 1 item 5: unverified is never shown as verified) |
| **PRD ref** | Product PRD QA-3, QA-4, §7 principle 1; Technical PRD §7.2; ADR-0014 (Accepted). Follow-up from AI-8a QA r1 finding 4 [spec] |
| **Depends on** | **AI-8a merged** (it adds `checkCitationInvariants` to `internal/query/rag_test.go`). Independence at start: no open PR touches `internal/query/synthesis_test.go` |
| **Jira** | new story under epic KAN-1 "Grounded LLM answers" (`labels = "task-AI-8c"`), linked to KAN-60 (AI-8a) |
| **Design required** | no (test-only, 11 added lines, no contract change; covered by `docs/design/AI-8.md` condition 3) |
| **Status** | **Done**: merged by Mahesh, ArxivLens [#59](https://github.com/MaheshPulivarthi18/ArxivLens/pull/59) → `d5fc08b` (2026-11-19) |

## Goal
The LLM-path tests in `synthesis_test.go` check the same citation invariants as `rag_test.go`. Every citation has
`paper_version` and a valid `status`, and `supported == (status == "supported")`. A `quote` is present only on a supported
citation and only when it is verbatim in `content`. So a regression on the synthesis path can't show unverified evidence
as verified.

## Scope
- `internal/query/synthesis_test.go` only. Add one line `checkCitationInvariants(t, <resp>)` right after each of the 11
  `Ask`/`AskWith` calls that return an `AskResponse` (after its `err` check where there is one; most sites discard `err`).
  At `origin/main` `40dec5a` they are at lines 39, 82, 99, 129, 159, 173, 189, 193, 197, 215 and 237 (AI-8a QA evidence 05/06):
  - `TestSynthesisAnswersWithVerifiedClaims` (1)
  - `TestSynthesisDropsUnsupportedClaims` (1)
  - `TestSynthesisRefusals` (1, inside the table loop)
  - `TestSynthesisFallsBackToExtractive` (1)
  - `TestSynthesisClaimsUnsupportedFallBackToQuotes` (2)
  - `TestQuickAnswerSkipsSynthesis` (3: `resp`, `full`, `plain`)
  - `TestSynthesisMarkersFollowPromptOrder` (1)
  - `TestWithLLMNilKeepsExtractive` (1)
- Out of scope: `rag.go`, `rag_test.go` and the helper itself (ai-owned; a helper bug is a follow-up for ai-engineer). Also
  out: changing any existing assertion, new tests, and the AI-8b claims checks (AI-8b extends the helper in place, so these
  sites pick them up with no further edit here).

## Acceptance criteria
- [x] AC1: `grep -c 'checkCitationInvariants' internal/query/synthesis_test.go` == 11, one per site listed above, each placed
  right after its call (after the `err` check where one exists) and before the response's other assertions.
- [x] AC2: The diff only adds lines. No existing line in `synthesis_test.go` is changed or removed, and no other file changes
  (`git diff --stat origin/main` shows 1 file, about 11 insertions, 0 deletions).
- [x] AC3: All 8 tests listed in Scope pass with the calls in place: CI Go job green, plus the targeted `go test` below (CI log
  or local output). If a site fails, don't weaken or skip it. Mark the task Blocked with the failing invariant message and
  ask pm-lead for an ai-engineer fix in `rag.go`.
- [x] AC4: The `ownership-check.sh` CI job passes for role `backend`.
- [x] Docs: none (test-only; README/PRD unchanged).

## Verification
```bash
make lint
make test-unit
go test -race -run 'Synth|QuickAnswer|WithLLMNil' -v ./internal/query/
grep -c 'checkCitationInvariants' internal/query/synthesis_test.go    # expect 11
git diff --stat origin/main                                           # 1 file, ~11 insertions, 0 deletions
bash .github/scripts/ownership-check.sh origin/main agent/backend/AI-8c
```

## Notes
- 2026-11-17 (pm-lead): created from AI-8a QA r1 finding 4 [spec], option (a). ai can't edit `synthesis_test.go`
  (`ownership-check.sh` ai allow-list is `internal/query/rag(_test)?\.go`; AGENTS.md §2 agrees). QA's local probe at AI-8a head
  `12e70b4` added exactly these 11 calls and all 8 tests passed (AI-8a evidence 06), so this is expected to be a one-pass task.
  The site list comes from QA evidence 05. If AI-8a's rework renames or moves tests, re-derive the list from every
  `Ask`/`AskWith` call in the file that returns an `AskResponse` (a nil response on an expected error is skipped).
- 2026-11-19 (pm-lead): AI-8a merged (main `8b55af2` contains `checkCitationInvariants`), so the task was unblocked and built as
  PR #59. QA PASS round 1 (`agents/reviews/AI-8c/report.md`), PM APPROVE. The PR is raised with evidence and now Ready to merge.
  [spec] AC1's "before the response's other assertions" can't hold at `TestSynthesisFallsBackToExtractive` L136
  (the err and answer checks share one `if`, and AC2 forbids editing it). Accepted as is. No follow-up for the synthesis-fixture gaps
  (M1/M4/M5); `rag_test.go` already catches them (see the PM review).
- 2026-11-20 13:00Z (pm-lead, sync): merged (#59 `d5fc08b`); Status → Done.
