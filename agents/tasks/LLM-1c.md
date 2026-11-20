# LLM-1c: LLM client names TLS failures instead of "malformed response or protocol error"

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 |
| **PRD ref** | Product PRD QA-8 (LLM synthesis; operators must be able to tell why it fell back); Technical PRD §7.2; follow-up from LLM-1b QA r2 nit 1 / PM review (`agents/reviews/LLM-1b/report.md`) |
| **Depends on** | LLM-1b (#27, merged `70b0afe`). No open PR touches `internal/llm/` (re-checked 2026-11-20 04:00Z against #65–#73 via REST) |
| **Jira** | KAN-77 (epic KAN-1 "Grounded LLM answers"; labels `task-LLM-1c`, `agent-backend`, `arxivlens`) |
| **Design required** | no: two fixed-string branches in one private helper; no contract, CLI, table or service change |
| **Status** | Ready to merge (PR [#74](https://github.com/MaheshPulivarthi18/ArxivLens/pull/74) `de27269`; QA PASS r1, PM APPROVE r1; waiting on Mahesh) |

## Goal
When `LLM_BASE_URL` points at an HTTPS endpoint and TLS fails (untrusted/invalid certificate, or the peer doesn't speak TLS), the
query service today reports `transport: malformed response or protocol error`, which sends an operator looking at the wrong layer.
Report a fixed TLS class instead, still without copying any server bytes, URL or raw error text into the error (LLM-1b AC6).

## Scope
- Files expected to change (and only these): `internal/llm/openai.go` (`transportDetail`, `openai.go:239-256` on `4c7d327`, and its
  doc comment), `internal/llm/openai_test.go` (new test function or new rows; existing rows unmodified).
- Rule to implement, checked **before** the existing `*net.OpError`/errno case:
  - `errors.As(err, new(*tls.CertificateVerificationError))` → detail `"TLS certificate rejected"`, cause `nil`.
  - `errors.As(err, new(tls.RecordHeaderError))` → detail `"TLS handshake failed"`, cause `nil`.
  - Everything else is unchanged (errno, DNS, EOF, default). The returned cause stays "the errno or nil, never the raw error".
- Out of scope: Go's plain-string `http: server gave HTTP response to HTTPS client` (not type-matchable; stays in the default class),
  TLS alerts sent by the server (`remote error: tls: …`, a `*net.OpError` without errno), retry policy, `Config`, README, `internal/query/`.

## Acceptance criteria
- [x] AC1: New test, certificate: `httptest.NewTLSServer` (self-signed, so the client's default roots reject it) as `BaseURL`.
  `Complete` returns an error with `errors.Is(err, ErrProvider)`, `Status == 0`, and `err.Error()` contains
  `transport: TLS certificate rejected`. It does **not** contain the server URL, `127.0.0.1`, `x509` or `certificate signed by`, and
  `errors.As(err, new(*tls.CertificateVerificationError))` is false (the raw error isn't kept as cause).
- [x] AC2: New test, handshake: a `net.Listen` TCP server that, on accept, writes a few non-TLS bytes that do **not** start with
  `HTTP/` (e.g. `"garbage\r\n"`, otherwise `net/http` rewrites the error) and closes; client `BaseURL` = `https://<addr>`. Error has
  `ErrProvider`, `Status == 0`, contains `transport: TLS handshake failed`, and contains none of the bytes written nor the address.
- [x] AC3: The AC1/AC2 errors pass the same leak sweep `TestNoSecretLeaks` uses (every `Unwrap` cause and `%v %+v %#v %s` of err,
  client and request contain no key/prompt sentinel), either by adding rows to that table or by reusing its sweep.
- [x] AC4: Existing tests pass unmodified: `git diff --numstat origin/main -- internal/llm/openai_test.go` shows 0 deletions (or
  only deletions inside a table the developer extended, listed in Notes with the reason).
- [x] AC5: Mutation, one per branch (QA applies each to `openai.go`, runs `go test -count=1 ./internal/llm/`, shows a named test
  failing): (a) remove the certificate branch → AC1 test fails; (b) remove the handshake branch → AC2 test fails; (c) return the raw
  `err` as cause in the certificate branch → AC1's `errors.As` check fails; (d) swap the two detail strings → both fail.
- [x] AC6: CI `ci.yml` job `Go (vet, gofmt, test, build)` green; its LLM step (`go test -race -count=1 -v -coverprofile=llm.out
  ./internal/llm/...`) shows the new test names as `--- PASS` and the `transportDetail` row of `go tool cover -func` (quote run ID,
  before vs after; it was 75% at LLM-1b r2). `make lint-go` clean. Ownership check passes for role=backend. `stack.yml` (triggered by
  `internal/**`) concludes success, or any failure is shown to fail identically on a main-based run.
- [x] Docs: the `transportDetail` doc comment lists the TLS classes. No README change (no flag, env or API change).

## Verification
```bash
gofmt -l internal/llm/ && go vet ./internal/llm/
go test -race -count=1 -v -run 'TLS|Transport' ./internal/llm/
go test -count=1 -coverprofile=llm.out ./internal/llm/ && go tool cover -func=llm.out | grep -E 'transportDetail|openai.go'
.github/scripts/ownership-check.sh origin/main agent/backend/LLM-1c
git diff --stat origin/main && git diff --numstat origin/main
```
Agent sandboxes may lack Go 1.25 (AGENTS.md §6): "not run locally" is fine; CI's Go job is the source of truth. QA runs the AC5
mutants in a scratch checkout if Go 1.25 is available, else on a throwaway branch's CI (say which). `make eval`: not run, no
retrieval/answering change (only an error string on a failure path).

## Notes
- 2026-11-20 04:00Z (pm-lead): specced from the Backlog line "From LLM-1b QA r2 nit 1 … `transportDetail` reports TLS/x509 failures …".
  Verified on `4c7d327`: `transportDetail` (`openai.go:243-256`) has errno, DNS and EOF cases only; a TLS error falls to
  `"malformed response or protocol error"`. `rawServer` (`openai_test.go:572`) reads an HTTP request first, so it can't produce a
  handshake error (a TLS ClientHello fails `http.ReadRequest` and the client sees EOF): AC2 needs its own small listener.
- Independent of every open PR: #65 (`internal/query/rag*.go`, `tests/test_evals_data.py`, `README.md`), #66 (workflows,
  CONTRIBUTING, compose), #68–#70 (`frontend/**`), #71 (`ci.yml`, `.github/scripts/`), #72 (`internal/kafka/`), #73
  (`services/embedder/`, `tests/test_verify.py`), and of RET-1b (`internal/query/search*.go`) groomed in the same cycle.
- 2026-11-20 04:10Z (backend-engineer): built on `agent/backend/LLM-1c` (app commit `de27269`, base `4c7d327`; not pushed, the
  orchestrator opens the draft PR). Diff: `openai.go` +8/-0 (two `case`s before the errno case, doc comment lists the TLS classes),
  `openai_test.go` +95/-0. New `TestTLSError` (rows `certificate_rejected` via `httptest.NewTLSServer`, `handshake_failed` via a
  `net.Listen` server writing `"garbage\r\n"`, then `CloseWrite` + draining the ClientHello so the client reads the bad record
  rather than a reset). AC3: two rows added to the `TestNoSecretLeaks` table (the sweep lives there, not in `TestTransportError`)
  through a new `url func(*testing.T) string` field, placed between `closed` and `raw` so gofmt doesn't realign existing lines;
  AC4 numstat shows 0 deletions. Local run: Go 1.24.7 in a scratch copy with `go 1.24` in go.mod (not committed), `GOTOOLCHAIN=local`:
  `go vet ./internal/llm/` clean, `go test -race -count=1 ./internal/llm/...` ok, `transportDetail` coverage 75.0% (base) → 80.0%.
  Mutants a–d each fail `TestTLSError` (a: certificate_rejected; b: handshake_failed; c: certificate_rejected at the cause-chain
  check; d: both). `gofmt -l` clean on all Go files; ownership check OK (role=backend, 103 lines). Not run locally: `go vet ./...`
  (module downloads blocked), Go 1.25, `stack.yml`; CI to verify AC6. The cert row's httptest server logs one
  `http: TLS handshake error … bad certificate` line per run (expected stderr noise).
- 2026-11-20 (pm-lead, final review): **APPROVE** r1 on PR #74 head `de27269` (QA PASS r1; report and evidence in
  `agents/reviews/LLM-1c/`). Fixed QA [spec] finding 2: AC3 said the sweep was the one "`TestTransportError` uses". The sweep lives in
  `TestNoSecretLeaks` (as the developer found), and AC3 now says so. QA nit 1 (the `` `\r\n` `` raw-string in the handshake row's `absent`
  list) is not blocking; it is a Backlog line in `agents/board.md` (fold into the next `internal/llm` test change). PR raised with
  the Evidence section and marked ready for review.
