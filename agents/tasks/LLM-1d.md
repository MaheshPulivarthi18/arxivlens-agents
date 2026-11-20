# LLM-1d: `TestTLSError` checks a real CR LF, not the 4-char raw string `\r\n` (test-only nit)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 |
| **PRD ref** | Product PRD QA-8 (operators can tell why synthesis fell back, without server bytes leaking); follow-up from the LLM-1c QA/PM review (`agents/reviews/LLM-1c/report.md`, QA nit 1) |
| **Depends on** | LLM-1c (#74, merged `929e908`). No open PR touches `internal/llm/` (checked 2026-11-20 05:00Z against #65, #66, #68, #69, #70 via REST) |
| **Jira** | KAN-82 (epic KAN-1 "Grounded LLM answers"; labels `task-LLM-1d`, `agent-backend`, `arxivlens`) |
| **Design required** | no: one string literal in a test table |
| **Status** | Done: ArxivLens #79 merged by Mahesh → `65824ff` (2026-11-20 ~18:54Z) |

## Goal
In `TestTLSError`'s "handshake failed" row (`internal/llm/openai_test.go:585` on `e6cffba`), the `absent` list contains
`` `\r\n` ``. That's a Go raw string: four literal characters (backslash, r, backslash, n), not CR LF. So the check means
"the error doesn't contain the bytes `\r\n` as typed", which it never would, and it doesn't check the server's line ending. Make the
row check what it says.

## Scope
- File expected to change (and only this one): `internal/llm/openai_test.go`, the `absent` entry on line 585: replace `` `\r\n` `` with
  the interpreted string `"\r\n"` (CR LF), so the row asserts that no server line ending reaches the error message. Nothing else
  changes. The `garbage` entry already pins the server bytes.
- Out of scope: `openai.go` (no production change); the optional hostname-mismatch row (needs a `RootCAs` hook in `Config`, not planned).

## Acceptance criteria
- [ ] AC1: `git diff origin/main -- internal/llm/openai_test.go` shows exactly one changed line: the `absent` slice of the
  "handshake failed" row, where `` `\r\n` `` becomes `"\r\n"`. Numstat is `1 1` and that's the only file in the diff.
- [ ] AC2: CI `ci.yml` job `Go (vet, gofmt, test, build)`, step `LLM package tests (verbose, race, per-file coverage)`, passes and lists
  `--- PASS: TestTLSError/handshake_failed` (quote the run ID and the line). `make lint-go` is clean, and so is the ownership check for
  role=backend.
- [ ] AC3: Mutation (QA, scratch checkout): make `transportDetail`'s handshake branch return a message that ends with the server's
  line ending (e.g. `"TLS handshake failed\r\n"`) → `TestTLSError/handshake_failed` fails on the `"\r\n"` entry. On `e6cffba`, the same
  mutant passes that entry (show both runs). If go1.25 isn't available, a go1.24 scratch module like LLM-1c's QA harness is fine
  (say which).
- [ ] Docs: none.

## Verification
```bash
gofmt -l internal/llm/ && go vet ./internal/llm/
go test -race -count=1 -v -run 'TestTLSError' ./internal/llm/
.github/scripts/ownership-check.sh origin/main agent/backend/LLM-1d
git diff --stat origin/main && git diff --numstat origin/main
```
Agent sandboxes may lack Go 1.25: "not run locally" is fine, and CI is the source of truth. `make eval`: not run, because the change is
test-only. `stack.yml` runs (`internal/**`) and has to be green apart from the documented F1 step.

## Notes
- 2026-11-20 05:00Z (pm-lead): specced from the Backlog line "From the LLM-1c QA/PM review (backend, P3, fold into the next
  `internal/llm/openai_test.go` change) …". No other `internal/llm` change is planned, so it gets its own one-line ticket. It's the
  lowest-value pick of this grooming pass. If Mahesh's review queue is the constraint, the orchestrator can leave it for a later cycle.
- Independent of every open PR and of OPS-H6c (`internal/kafka/`), AI-12b and ING-11c.
- 2026-11-20 05:10Z (backend-engineer): built on `agent/backend/LLM-1d` (commit `fc6d79d`, base `e6cffba`). Line 585 changed from
  `` `\r\n` `` to `"\r\n"`. Numstat `1 1 internal/llm/openai_test.go`, the only file in the diff. `gofmt -l` is clean (package and
  repo-wide), and the ownership check prints `Ownership OK for role=backend (2 changed lines)`. The sandbox has only go1.24.7, so
  `make lint-go` / `go vet ./...` fail locally on `go.mod requires go >= 1.25.0` (not run locally; CI is the source of truth). The
  package is stdlib-only, so I ran it in a go1.24 scratch module (go.mod `go 1.24`, the real `internal/llm/*.go` copied in): `go vet`
  is clean, `go test -race -count=1 -v -run TestTLSError` gives `--- PASS: TestTLSError/handshake_failed`, and the full package passes.
  AC3 dev preview (QA runs the official one) in the same scratch harness, mutant `return "TLS handshake failed\r\n", nil`
  (openai.go:255): on head it FAILs with `openai_test.go:604: error "... TLS handshake failed\r\n after 1 attempt" contains "\r\n"`,
  and on `e6cffba` it PASSes. AC2 CI run ID: pending the orchestrator's push.
- 2026-11-20 08:00Z cycle (pm-lead): QA PASS r1 (`agents/reviews/LLM-1d/report.md`). AC2 CI run 44679354389, job 136098767376,
  log line 578 `--- PASS: TestTLSError/handshake_failed`. All 6 check runs on `fc6d79d` succeeded. PM **APPROVE** r1: the PR description
  is rewritten with pinned evidence, the PR is marked ready for review, and it has label `ready-to-merge`. QA nit 1 (lone `\n`) is closed
  with no follow-up (reason in report.md). PRD QA-8 status unchanged (test-only).
