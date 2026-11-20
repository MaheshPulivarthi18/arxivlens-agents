<!-- Provenance: qa-reviewer's harness refused to write report.md; saved verbatim by the orchestrator from the PR comment https://github.com/MaheshPulivarthi18/ArxivLens/issues/comments/7030392657 on 2026-11-20T04:28Z. -->

[qa-reviewer] QA report — LLM-1c · PR #74 · round 1

**Verdict: PASS** → pm-lead final review
**Reviewed commit:** `de2726988b08a96202d7b30cde9888cf1dd10371` · 2026-11-20 · Ticket `agents/tasks/LLM-1c.md` · PRD QA-8, Technical PRD §7.2
Evidence pack: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence (the QA harness refused to write `report.md`; this comment is the report, and the orchestrator saves it verbatim)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI run 44672616661 / job 136076869340 | pass, on merge ref `16a0b47` = de27269 into current main 4c7d327 ([00](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/00-ci-checks.png ```), [02](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/02-ci-go-job-tls-tests-coverage.png)) ```` |
| Python M0, Frontend, DB | CI | pass ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/00-ci-checks.png)) |
| Agent ownership | CI job 136076869021 | `Ownership OK for role=backend (103 changed lines)` ([04](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/04-ci-ownership-stack.png)) ````` |
| stack.yml | CI run 44672616095 / job 136076867487 | success: `237 passed, 1 skipped, 3 deselected` + `3 passed`, 0 `##[error]` ([04](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/04-ci-ownership-stack.png)) `````` |
| Ticket verification | local: Go 1.24.7, scratch module with the PR's real `internal/llm` (stdlib-only; go directive lowered in the scratch copy only) | gofmt/vet clean, `-race -run 'TLS\|Transport'` PASS, package PASS, transportDetail 80.0% ([05](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/05-local-verify.png ```````)). Not run locally: module-wide `go vet ./...` (no module proxy); CI ran it |
| AC5 mutants | local (not pushed anywhere) | a–d KILLED in the full suite and in `-run ^TestTLSError$`; extras e–g KILLED; h equivalent ([06](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/06-ac5-mutants.png ````````)) |
| Flake | local `-race -count=100` | ok ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/07-flake-x100.png)) |
| make eval | not run | not a retrieval/answering change (only a failure-path detail string) |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `TestTLSError/certificate_rejected`: `ErrProvider`, Status 0, 1 attempt, contains `transport: TLS certificate rejected`; none of URL / host:port / `127.0.0.1` / `x509` / `certificate signed by` appear; `errors.As(*tls.CertificateVerificationError)` is false. CI PASS ([02](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/02-ci-go-job-tls-tests-coverage.png)), ````````` local PASS ([05](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/05-local-verify.png ``````````)) |
| AC2 | ✅ | `TestTLSError/handshake_failed`, raw `net.Listen` server writing `garbage\r\n` + CloseWrite: contains `transport: TLS handshake failed`; none of address / `garbage` / `record` appear. CI + local PASS |
| AC3 | ✅ | Rows `TLS: certificate rejected` and `TLS: not a TLS server` (that server writes the prompt+key+completion bytes) run through the `TestNoSecretLeaks` sweep (every Unwrap cause, `%v %+v %#v %s` of err, client and request). CI `--- PASS` ([02](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/02-ci-go-job-tls-tests-coverage.png)) ``````````` |
| AC4 | ✅ | numstat `8/0`, `95/0`; 0 deleted lines in openai_test.go ([01](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/01-scope-numstat-ownership.png)) ```````````` |
| AC5 | ✅ | a: certificate_rejected FAIL; b: handshake_failed FAIL; c: certificate_rejected FAIL at the `errors.As` cause check (`:608`); d: **both** rows FAIL ([06](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/06-ac5-mutants.png `````````````)) |
| AC6 | ✅ | LLM step shows `--- PASS: TestTLSError` plus both subtests; `transportDetail` **75.0%** on main (run 44585775176, job 135778169056, [03](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/03-ci-main-baseline-coverage.png)) `````````````` → **80.0%** at head (run 44672616661, [02](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/02-ci-go-job-tls-tests-coverage.png)); ``````````````` `make lint-go` green; ownership OK; stack.yml success |
| Docs | ✅ | The doc comment at `openai.go:244-246` lists both TLS classes (nil cause). No README change needed |

## PRD fit
Operators running QA-8's LLM synthesis against an HTTPS endpoint now see an actionable TLS class instead of "malformed response or protocol error". The LLM-1b no-leak invariant still holds (no server bytes, URL or x509 host text; nil cause), and the sweep checks it. No contract change.

## Findings
No blocking findings.
1. [nit] In the handshake row, `absent` has `` `\r\n` `` as a raw-string literal: that's the 4-char text, not CR LF. Harmless (`garbage` already pins the bytes), but misleading.
2. [spec] AC3 says the sweep is "the one `TestTransportError` uses"; it lives in `TestNoSecretLeaks`. The developer reused the correct one (recorded in Notes).
3. [note] Extra mutant h (both TLS cases moved after the EOF case) survives, and it is equivalent for both real error shapes: neither error matches the errno, DNS or EOF cases. The required "before errno" order is in the code.
4. [note] In my first mutation pass, mutant d's substitution hit the doc-comment copy of the strings. I re-anchored it on the `return` lines; the rendered run shows the code diff.

## Missing tests
None required. Optional: a hostname-mismatch row; it needs a RootCAs hook in `Config`, which is out of scope.

## Evidence
[00 CI checks](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/00-ci-checks.png) · [01 scope/numstat/ownership](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/01-scope-numstat-ownership.png) ```````````````` · [02 CI Go job](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/02-ci-go-job-tls-tests-coverage.png) ````````````````` · [03 main baseline coverage](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/03-ci-main-baseline-coverage.png) `````````````````` · [04 ownership + stack](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/04-ci-ownership-stack.png) ``````````````````` · [05 local verify](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/05-local-verify.png ````````````````````) · [06 AC5 mutants](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/06-ac5-mutants.png `````````````````````) · [07 flake x100](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/07-flake-x100.png) · [08 harness source](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/08-harness-source.png ``````````````````````)

[AC5 mutants](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/328451f1cd9f7ebef8a639410e3d68892aafd32b/agents/reviews/LLM-1c/evidence/06-ac5-mutants.png?raw=true) ```````````````````````


---
_Generated by [Claude Code](https://claude.ai/code)_
