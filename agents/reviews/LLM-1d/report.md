<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/issues/comments/7031244392 (qa-reviewer's harness could not write report.md), 2026-11-20. -->

[qa-reviewer] QA report — LLM-1d · PR #79 · round 1

**Verdict:** PASS
**Reviewed commit:** `fc6d79d98433191f8932310a8db9c723523f633a` · **Date:** 2026-11-20
**Ticket:** `agents/tasks/LLM-1d.md` (Jira KAN-82) · **PRD:** Product PRD QA-8 (follow-up to LLM-1c QA nit 1)

Evidence pack: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence. The QA harness refused to write `report.md`, so this comment is the report, and the orchestrator saves it verbatim.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI run 44679354389 / job 136098767376 | pass, on merge ref `3a1d141` = fc6d79d into current main `e6cffba` ([00](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/00-ci-checks.png ```), [02](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/02-ac2-ci-go-job.png ````)) |
| Python M0 unit tests, Frontend, DB | CI | pass ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/00-ci-checks.png)) |
| Agent ownership | CI job 136098767098 | `Ownership OK for role=backend (2 changed lines)` ([03](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/03-ac2-ownership-lint.png)) ````` |
| Full stack (`stack.yml`) | CI run 44679354343 / job 136098767606 | success: `243 passed, 1 skipped, 3 deselected` + `3 passed`, 0 `##[error]` lines in the job log ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/00-ci-checks.png)) |
| Ticket verification commands | local, go1.24.7 scratch module with the real `internal/llm` sources (`git archive`) | `gofmt -l` empty, `go vet` clean, `TestTLSError` PASS ([06](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/06-ac3-head-control.png)); `````` ownership-check OK ([04](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/04-ac2-ownership-local.png)). ``````` Repo-wide `make lint-go` / `make test-unit` not run locally: the sandbox has go1.24.7 and `go.mod` needs 1.25 (toolchain download blocked). CI covers both. |
| `make eval` | not run | test-only change, no retrieval or answering code touched |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `git diff --numstat origin/main...HEAD` → `1 1 internal/llm/openai_test.go`, the only file. The single hunk changes line 585's `absent` entry `` `\r\n` `` → `"\r\n"`, and nothing else ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/01-ac1-diff.png)) |
| AC2 | ✅ | Run **44679354389**, step `LLM package tests (verbose, race, per-file coverage)` success, log line 578: `--- PASS: TestTLSError/handshake_failed (0.00s)`; `internal/llm` 96.6% coverage ([02](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/02-ac2-ci-go-job.png ````````)). `Run make lint-go` step success (go vet + gofmt check, silent) and ownership OK for role=backend ([03](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/03-ac2-ownership-lint.png), ````````` [04](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/04-ac2-ownership-local.png)) `````````` |
| AC3 | ✅ | go1.24.7 scratch module (harness source in [05](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/05-ac3-harness-source.png)). ``````````` The mutant is `openai.go:255` `return "TLS handshake failed\r\n", nil`, anchored on the `return …, nil` code line, with its diff printed. **Head:** `--- FAIL: TestTLSError/handshake_failed`, `openai_test.go:604: error "llm: provider error: transport: TLS handshake failed\r\n after 1 attempt" contains "\r\n"` ([07](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/07-ac3-head-mutant-killed.png)). ```````````` **Base e6cffba:** same mutant, `--- PASS: TestTLSError/handshake_failed` ([08](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/08-ac3-base-mutant-survives.png)). ````````````` Unmutated head control passes ([06](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/06-ac3-head-control.png)). `````````````` In the full `./internal/llm/...` suite with the mutant, only `TestTLSError/handshake_failed` fails ([09](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/09-ac3-full-suite.png ```````````````), source [10](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e18ac943d167a9249caf0da939c262660481f3af/agents/reviews/LLM-1d/evidence/10-full-suite-source.png)) ```````````````` |
| Docs | ✅ | none required; none changed |

## PRD fit
QA-8 says fallback errors name the reason without leaking server bytes. The `notTLSServer` fixture sends `"garbage\r\n"`, and the row now really asserts that the server's CR LF can't reach `err.Error()`. Before this change the entry was a 4-character string that could never match, so it checked nothing.

## Scope
One file inside backend's owned paths (`internal/`), no ticket, review or doc files, `openai.go` untouched (out of scope respected). The PR is still a draft and not merged.

## Findings
None blocking.
1. [nit] The new entry catches only the full CR LF pair. A message that leaked a lone `\n` or `\r` would still pass this entry (the `garbage` entry covers the fixture's text, not its line ending). This is in line with the ticket's scope ("CR LF"), so no change is asked for in this PR.

## Missing tests
- None required by the ticket. Optional, per the nit: also put `"\n"` in `absent`.

## Hand-off
PASS → pm-lead final review


---
_Generated by [Claude Code](https://claude.ai/code)_

## PM decision — pm-lead, 2026-11-20 — round 1

**Verdict: APPROVE**

Reviewed head `fc6d79d98433191f8932310a8db9c723523f633a` against base `e6cffba` (still ArxivLens `main` at review time). Ticket `agents/tasks/LLM-1d.md`, Product PRD QA-8, the live PR files list, the check runs for the full head SHA and all 11 evidence PNGs plus their `.txt` siblings.

- **Product fit (QA-8, no server bytes in fallback reasons):** the `absent` entry now holds a real CR LF, so the handshake row asserts that the `notTLSServer` fixture's line ending can't reach `err.Error()`. Before, it was a 4-char raw string that could never match. The test now checks what it claims to.
- **Scope:** `pulls/79/files` = `internal/llm/openai_test.go` +1/−1, nothing else. `openai.go` isn't touched, and the hostname-mismatch row stays out of scope as the ticket says. Inside backend's owned paths.
- **AC1** ✅ 01-ac1-diff.png: numstat `1 1`, one file, and `cat -A` shows the backticks replaced by double quotes on the single changed line.
- **AC2** ✅ 02-ac2-ci-go-job.png: run 44679354389, job 136098767376, log line 578 `--- PASS: TestTLSError/handshake_failed (0.00s)` in the `go test -race ... ./internal/llm/...` step, on merge ref `3a1d141` = fc6d79d into e6cffba. `make lint-go` step ran clean (03). Ownership `OK for role=backend (2 changed lines)` in CI (03) and locally (04).
- **AC3** ✅ 07 (head + mutant → `--- FAIL: TestTLSError/handshake_failed`, `openai_test.go:604 ... contains "\r\n"`) vs 08 (base e6cffba + the same mutant → PASS), with the unmutated control (06) and the harness source (05). In the go1.24 scratch module (allowed by the AC, and labelled). 09/10 show that the mutant fails only this subtest in the full package.
- **CI:** all 6 check runs on `fc6d79d…` completed/success, including `stack.yml` Full stack (QA: 0 `##[error]` lines).
- **Docs/PRD:** none needed. The change is test-only and leaves the QA-8 row's status unchanged. `make eval` not run: no retrieval or answering code touched, which is correct.
- **QA nit 1 (lone `\n`/`\r`):** no follow-up. The fixture's only leakable text is `garbage\r\n`, and the `garbage` entry already catches any leak of its bytes. A bare line-ending leak without them isn't a realistic failure mode, so a ticket isn't worth its cost.

Next: PR #79 description rewritten with evidence, marked ready for review, label `ready-to-merge`. Jira is left to the orchestrator.
