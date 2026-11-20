> Provenance: saved verbatim by the orchestrator (cycle 2026-11-20T08:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/80#issuecomment-7034662438 (QA's harness could not write report.md).

[qa-reviewer]

# QA report — OPS-H15 · PR #80 · round 1

**Verdict:** FAIL
**Reviewed commit:** `9df6944431bbe3224720caf97f7b15664922a4fa` (base `main` `e6cffba`) · **Date:** 2026-11-20
**Ticket:** `agents/tasks/OPS-H15.md` · **PRD:** Technical PRD §10/§11 (harness/quality), from ING-9 QA nit 6 (`agents/reviews/ING-9/report.md:46`)

The change is correct: every AC has CI evidence and the detector has been shown to catch a race. **It fails on one blocking finding only. The PR description is OPS-H5b's (PR #81) description, with OPS-H15's AC list pasted into the middle.** Fixing it is a body edit. No new commit and no CI re-run are needed.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI run 44700878368 att 1 job 136168682100 + att 2 job 136169622172 | pass (both attempts) ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/00-ci-checks.png?raw=true), `` [01](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/01-ac1-race-step-ok-lines.png?raw=true), ``` [04](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/04-ac4-rerun-attempt2.png?raw=true)) ```` |
| Python M0 unit tests | CI job 136169624788 | pass |
| Frontend (lint, test, build) | CI job 136169624104 | pass |
| Agent guardrails (ownership) | CI job 136169625051 + local `ownership-check.sh` | pass: `Ownership OK for role=backend (5 changed lines)` ([05](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/05-ac5-diff-ownership.png?raw=true)) ````` |
| DB (migrate twice, HNSW) | CI run 44700878356 | pass (not affected) |
| Ticket verification commands | local (diff, ownership, REST steps/log greps) | run, see evidence 01–05 |
| `make test-unit` / `make lint` | not run locally: sandbox Go 1.24.7 < go.mod 1.25 and no module proxy. CI is the source of truth | n/a |
| `actionlint` | not run: not installed in the sandbox. `yaml.safe_load` parses the file ([05](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/05-ac5-diff-ownership.png?raw=true)), `````` and the green CI run shows GitHub accepted the workflow | n/a |
| `make eval` | not run: no retrieval or answering change | n/a |

All PR checks ran on the merge commit with current `main`: `HEAD is now at ff5e450 Merge 9df6944… into e6cffba…` ([01](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/01-ac1-race-step-ok-lines.png?raw=true) ``````` line 120). `main` is still at `e6cffba`.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: Go job passes; the renamed step shows `GOFLAGS: -race` in its env header and an `ok` for every package with tests | ✅ | [01](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/01-ac1-race-step-ok-lines.png?raw=true): ```````` run 44700878368 att 1, job 136168682100, step `Go unit tests (make test-go, race detector)`. Log line 216 `  GOFLAGS: -race`, then `ok` for `internal/arxiv` 2.570s, `config`, `crawler`, `db`, `dlq`, `downloader`, `kafka`, `llm`, `llm/llmtest`, `query` (lines 220–229). That matches the 10 directories at the head that contain `*_test.go` (`git ls-files '*_test.go'`). `cmd/arxivlens`, `storage`, `telemetry` and `shared/events` report `[no test files]`. No result is `(cached)`. |
| AC2: the detector really runs (probe commit fails with `WARNING: DATA RACE`, reverted by a new commit, next run green, probe not in the final diff) | ✅ | [02](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/02-ac2-race-probe.png?raw=true): ````````` probe `d63caf9` adds only `internal/arxiv/race_probe_test.go` (+23). Run 44700583617, job 136167700565 = failure. Log: `GOFLAGS: -race` (215), `WARNING: DATA RACE` (220, 246), `--- FAIL: TestRaceProbe (0.00s)` (271), `testing.go:1617: race detected during execution of test` (273), `FAIL	arxivlens/internal/arxiv	1.573s` (275), `make: *** [Makefile:46: test-go] Error 1`. The revert `9df6944` is a new commit. The timeline has only `committed` events (no force-push). `git diff 6e1e9cd 9df6944` is empty, so the revert is exact, and no `race_probe` file is tracked at the head. The next run, 44700878368 job 136168682100, is a success. The race step therefore failed only on the race, and every other package was `ok`. |
| AC3: renamed step duration vs the `main` baseline of 6 s, under 5 min | ✅ | [03](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/03-ac3-step-durations.png?raw=true), `````````` REST `started_at → completed_at`: baseline `main` `e6cffba` run 44677460170, job 136092606453, `Run make test-go` 04:54:33Z → 04:54:39Z = **6 s**. PR head att 1: 08:14:08Z → 08:14:55Z = **47 s**. Att 2: **43 s**. First commit `6e1e9cd`: 33 s. Probe: 50 s. All are far under 5 min. The whole Go job grew only 47 s → 65 s, because the following Kafka step dropped from 20 s to 2 s: it reuses the race-instrumented build that this step now produces. |
| AC4: one re-run of the Go job is green | ✅ | [04](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/04-ac4-rerun-attempt2.png?raw=true) ``````````` + [03](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/03-ac3-step-durations.png?raw=true): ```````````` run 44700878368 **attempt 2**, job 136169622172 = success, same head `9df6944`. All 10 packages are `ok`, including `internal/arxiv` (the limiter timing tests). There are no `FAIL`/`DATA RACE` lines (the only match for the grep is the command line itself). Attempt 1 = job 136168682100 (AC1). |
| AC5: final diff is `ci.yml` only, a few lines in job `go`; ownership passes for backend; actionlint or "not run" | ✅ | [05](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/05-ac5-diff-ownership.png?raw=true): ````````````` `git diff --stat origin/main...HEAD` = `.github/workflows/ci.yml` 4+/1-. The step is renamed, `run: make test-go` is unchanged, `env: GOFLAGS: -race` is added, and the Kafka and LLM steps are unchanged. The Makefile, CONTRIBUTING and README are untouched. Ownership is OK both locally and in CI. actionlint was not run (not installed), but the YAML parses and the CI run is green. No other open PR touches `ci.yml`. |
| Docs: none | ✅ | Local `make test-go` is unchanged (`Makefile:45-46` `go test ./...`), so no doc edit is needed. |

## PRD fit
This closes ING-9 QA nit 6. Every Go package's unit tests now run under the race detector in CI, so a data race in the limiter, crawler, consumer, rerank fallback or LLM client fails the PR instead of being "proven only locally". It serves the reliability NFRs (Technical PRD §8/§9) and costs about 40 s of CI time per run. No product code, contract, threshold or gate changes. The Go test step only gains a check and loses nothing.

## Findings
1. [blocking] **The PR #80 description belongs to the wrong task.** The body starts with `## OPS-H5b: \`TestHNSWVectorHits\` cleans up its synthetic corpus and refuses a non-empty DB`. It links **Spec: `agents/tasks/OPS-H5b.md`** and **Jira KAN-84**. "What changed" says "`internal/query/search_integration_test.go` only". The Verification table cites `ownership-check.sh … agent/backend/OPS-H5b` → `(100 changed lines)`. None of that matches this PR, which changes only `.github/workflows/ci.yml` (5 lines), is OPS-H15 and is KAN-83. Only the Acceptance criteria block is OPS-H15's. Lines 1–12 and 20–31 are word-for-word the same as PR #81's body ([06](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15/evidence/06-finding-pr-body.png?raw=true)). `````````````` This is the text Mahesh reviews before merging, and it currently misstates what the PR changes and points to the wrong ticket. pm-lead only fills the Evidence section at Step 4, so the error would survive into the raised PR. **Fix (body edit only, no commit):** rewrite the header, Spec/PRD/Jira line, "What changed", "Verification" and "Not verified / risks" for OPS-H15 from `agents/templates/pr.md`. Keep the AC block. QA round 2 can then re-check the body without new CI.
2. [nit] Merge-order note for pm-lead and Mahesh: after this merges, the Go tests of open PRs run under `-race` in `make test-go` too. #76 (`internal/kafka/consumer_test.go`) and #79 (`internal/llm/openai_test.go`) already run under `-race` in their dedicated steps. #65 (`internal/query/rag.go`, `rag_test.go`) has only been tested without `-race`, though its diff adds no goroutines, `sync` or channels. #81's test is `integration`-tagged and not run by `make test-go`. No action is needed. If #65 merges after this one, its first CI run will be under the detector.
3. [spec] The ticket's PRD ref is "Technical PRD §11 harness/quality", but §11 (Roadmap) has no harness row. The closest section is §10 "Testing and evaluation". The real driver is ING-9 QA nit 6. pm-lead may want to point the ref at §10, or add a harness row.

## Missing tests
- None for this change. AC2's probe was the meaningful test: it showed the step fails on a real race and then reverted cleanly. A permanent race canary would need a test that deliberately fails, which the ticket rightly excludes.

## Hand-off
FAIL → back to backend-engineer (finding 1: PR body only). Round 2 only needs the corrected PR description. The code, CI evidence and AC1–AC5 above stand unless the head changes.

_Evidence pack: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/39b4ee84a44c470682fe4a2ed723e574bf57b28e/agents/reviews/OPS-H15 (commit `39b4ee8` in arxivlens-agents). report.md is not committed: the QA harness refused to write it, so the orchestrator saves this comment body verbatim as `agents/reviews/OPS-H15/report.md`._


---
_Generated by [Claude Code](https://claude.ai/code)_
