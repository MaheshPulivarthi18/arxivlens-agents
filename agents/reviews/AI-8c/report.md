<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/59#issuecomment-7013361135 (QA harness could not write report.md), 2026-11-19T15:20:24Z -->

[qa-reviewer] QA report: AI-8c, PR #59, round 1

**Verdict:** PASS
**Reviewed commit:** `dd5dac58fc4f47753e899458e15ad150f71babdb` · **Date:** 2026-11-19
**Ticket:** `agents/tasks/AI-8c.md` · **PRD:** Product QA-3, QA-4, §7 principle 1; Technical §7.2; ADR-0014; design `docs/design/AI-8.md` condition 3
**Evidence:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 135653652705 (merge `d1f0d81` = `dd5dac5` into main `8b55af2`) | pass: `go vet`, gofmt check, `go test ./...` → `ok arxivlens/internal/query`, 0 FAIL lines ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/00-ci-checks.png?raw=true), `` [09](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/09-ac3-ci-go-job.png?raw=true), ``` [10](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/10-ci-go-job-full.txt ````)) |
| Python M0 / Frontend / DB / Full stack | CI | all pass |
| Agent ownership check | CI job 135653652453 | pass: `Ownership OK for role=backend (11 changed lines)` ([11](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/11-ac4-ci-ownership.png?raw=true)) ````` |
| Ticket verification: `grep -c`, `git diff --stat`, `ownership-check.sh` | local at `dd5dac5` | 11 / 1 file +11 −0 / OK ([01](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/01-ac1-call-sites.png?raw=true), `````` [03](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/03-ac2-diff-stat.png?raw=true), ``````` [04](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/04-ac4-ownership-local.png?raw=true)) ```````` |
| Ticket verification: `go test -race -run 'Synth\|QuickAnswer\|WithLLMNil' -v ./internal/query/` | local go1.24 scratch module: the PR head's real `internal/` (`diff -r` clean) + pgx/minio stubs | all 12 matching tests PASS, including the 8 Scope tests ([05](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/05-ac3-targeted-go-test-local.png?raw=true), ````````` harness [06](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/06-harness-sources.txt ``````````)) |
| `make test-unit` / `make lint` | CI (no Go 1.25 locally) | pass in CI; local `gofmt -l` clean |
| `make eval` | not run: test-only change | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: 11 calls, one per site, after the err check, before other assertions | ✅ | [01](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/01-ac1-call-sites.png?raw=true): ``````````` `grep -c` = 11. There are 11 `Ask`/`AskWith` sites, each followed by exactly one check in the same func (+1 line, or +4 after the err `if` block at L39→43 and L132→136). [02](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/02-ac1-site-context.png?raw=true) ```````````` shows each site in context. The re-derived site list matches the ticket's. See finding 1 for L136. |
| AC2: additions only, 1 file, 0 deletions | ✅ | [03](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/03-ac2-diff-stat.png?raw=true): ````````````` merge-base = main `8b55af2`; `1 file changed, 11 insertions(+)`; 0 removed lines |
| AC3: all 8 tests pass | ✅ | CI Go job green on the merge with current main ([09](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/09-ac3-ci-go-job.png?raw=true)). `````````````` CI's `go test` isn't `-v`, so the per-test names come from the local `-race -v` run ([05](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/05-ac3-targeted-go-test-local.png?raw=true)) ``````````````` |
| AC4: ownership check for backend | ✅ | CI [11](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/11-ac4-ci-ownership.png?raw=true), ```````````````` local [04](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/04-ac4-ownership-local.png?raw=true) ````````````````` |
| Docs: none | ✅ | no other file in the diff ([03](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/03-ac2-diff-stat.png?raw=true)) `````````````````` |

## Test quality (do the 11 calls add protection?)
I ran 9 single-edit `rag.go` mutants in a local scratch copy (nothing pushed). Each ran against the 8 Scope tests twice: with origin/main's `synthesis_test.go` (0 calls) and with the PR's (11 calls). Control M0 was green in both. No mutant failed to build ([07](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/07-mutation-base-vs-pr.png?raw=true)). ```````````````````
- **Killed only because of the new calls:** M7 (non-verbatim quote on the quoted fallback path; fails at new lines 136/164/196/248) and M8 (invalid status on unsupported LLM-path citations; fails at line 43). Both passed every synthesis test before this PR.
- Killed with or without the calls: M2 (supported ≠ status) and M3 (invalid status on supported citations).
- Survived the 8 tests, killed by the full `internal/query` suite ([08](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/7ca9a4bd495e6894031faa61c4bdfa788183f361/agents/reviews/AI-8c/evidence/08-mutation-full-suite.png?raw=true)): ```````````````````` M1 (quote on an unsupported LLM citation), M4 (non-verbatim exact quote on the LLM path), M5 (refusal evidence marked supported), M9. These are fixture gaps in `synthesis_test.go`, not unguarded code. M6 is equivalent: `scorePairs` scores every exact match 1, so `exact[pi]` already implies `Supported`.

## PRD fit
Test-only. The LLM-path tests now apply the same ADR-0014 / QA-4 citation invariants as `rag_test.go`, so a synthesis-path regression that shows unverified or non-verbatim evidence as verified now fails CI (M7/M8). No contract, threshold or gate changed.

## Findings
1. [nit] `TestSynthesisFallsBackToExtractive` L136: the call comes after the combined `if err != nil || resp.Answer != extractive || …` Fatalf, not strictly "before the response's other assertions". This is unavoidable without editing that existing line, which AC2 forbids. The placement is correct and the PR body discloses it. No action.
2. [spec] AC1's wording can't be met when one existing `if` holds both the err check and the answer check. Next time, word it as "after the err check (or the combined err/answer check)".
3. [spec] `agents/tasks/AI-8c.md` still says `Status: Blocked (needs AI-8a merged)`. AI-8a is on main (base `8b55af2` contains `checkCitationInvariants`). pm-lead to update.

## Missing tests (out of scope here: the ticket rules out new tests)
- `synthesis_test.go` has no fixture for these cases: a kept claim with a mixed supported/unsupported citation that carries a model quote (M1); an exact verbatim claim on the LLM path (M4); an LLM-path refusal that returns evidence (M5). The `TestSynthesisRefusals` call at L102 is vacuous for evidence. `rag_test.go` covers all three today.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_
