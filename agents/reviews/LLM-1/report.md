<!-- Provenance: written by qa-reviewer (fresh context, 2026-11-07 cycle 05:21Z); its harness could not write files, so the orchestrator saved the report text verbatim from qa-reviewer's hand-back. Evidence files were rendered by qa-reviewer with agents/tools/render_evidence.py. -->

# QA report — LLM-1 · PR #23 · round 1

**Verdict:** FAIL
**Reviewed commit:** `8e3277163505cedb3955439d5297dc387d8afe85` · **Date:** 2026-11-07
**Ticket:** `agents/tasks/LLM-1.md` (part a after the pm-lead split; client and `FromEnv` are LLM-1b) · **PRD:** Product QA-8; Technical §7.2, §11 P0 "LLM answer synthesis"; ADR-0001, ADR-0002 (Accepted) · **Design:** `docs/design/LLM-1.md` (APPROVED with conditions + split addendum)

One-line reason: CI is green and the code is correct, but the **AC4 `errors.Is` table (design condition 2, binding) is missing**. No test in the PR calls `errors.Is` or `errors.As` on an `*llm.Error`, and two mutations that break the contract QA-8 will depend on pass the whole suite.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 128322231178 ([00](evidence/00-ci-checks.png), [01](evidence/01-ci-llm-step.png)) | pass, including the new `internal/llm` step: `-race`, 100.0% per file |
| Python M0 unit tests | CI | pass |
| Frontend (lint, test, build) | CI | pass |
| DB (migrate twice, HNSW plan + recall) | CI | pass |
| Agent guardrails (ownership check) | CI | pass |
| `make lint` / `make test-unit` | CI (`make test-go` is in the Go job) | pass. Not run locally: the sandbox has Go 1.24, `go.mod` needs 1.25 and the proxy is blocked |
| `go vet`, `gofmt -l`, `go test -race -count=3 ./internal/llm/...` | local, Go 1.24 scratch-module copy ([03](evidence/03-local-vet-race-ac1.png)) | clean / clean / pass |
| Mutation runs (llm.go/config.go 8 mutants, fake.go 7 mutants) | local scratch module ([04](evidence/04-mutations-llm.png), [06](evidence/06-mutations-fake.png)) | 2 of 8 survive (both on AC4), 0 of 7 survive |
| `make eval` | n/a | not run: nothing imports `internal/llm`, so retrieval and answering can't change ([02](evidence/02-scope-ac8.png)) |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 (split): `ConfigFromEnv` table + key absent from every print form | ✅ | `config_test.go` `TestConfigFromEnv` (21 rows: unset → nil/nil, defaults `http://localhost:11434/v1` / 2s / 256, bad/zero/negative timeout, bad/0/neg/8193 max tokens, relative/no-scheme/ftp/no-host/unparseable/userinfo/query/empty-query/fragment base URL, `noEcho` on the values); `TestConfigRedactsKey` covers `%v/%+v/%#v/%s` of `Config`, `*Config`, a struct holding the config in an unexported field, `Secret`, plus `json.Marshal`; `llm_test.go` `TestPrintFormsShowSizesOnly` covers `Request`/`Response`/`Message`. CI [01](evidence/01-ci-llm-step.png), local [03](evidence/03-local-vet-race-ac1.png). Mutants M6, M7 (key printed) and M8 (query check removed) are killed ([04](evidence/04-mutations-llm.png)) |
| AC4 (split): `errors.Is` table on `*Error` built with `newError` (each sentinel; nil Kind + `context.Canceled` → `llm: canceled`, nil entry dropped, `errors.Is` false for every sentinel) | ❌ | **Half of it is there.** `TestErrorShape` (`llm_test.go:32-72`) checks `Error()` text, `%#v`, `len(Unwrap())` and that no entry is nil, so the `llm: canceled` text and the dropped nil entry are proven (M3, M5 killed). The `errors.Is` part has **no test**: `grep -rn "errors.Is\|errors.As" internal/llm/*_test.go` finds nothing, and there's no row for 4 of the 5 sentinels (`ErrRateLimited`, `ErrBadResponse`, `ErrInvalidRequest` never appear in a test; `ErrTimeout` and `ErrProvider` appear only as `newError` arguments). Mutant M1 (every typed error unwraps to `ErrTimeout`) and mutant M2 (a cancel unwraps to `ErrTimeout`, not `context.Canceled`) both **pass the suite** ([04](evidence/04-mutations-llm.png)). The shipped code does behave correctly: my out-of-tree probe ([05](evidence/05-ac4-probe.png)) shows `errors.Is` true for its own sentinel and false for the other four, and a cancel matches `context.Canceled` and no sentinel. That is QA's probe, not a test in the PR. See finding 1 |
| AC6 (split): `newError` strips a sentinel key from detail/cause text | ✅ | `TestErrorShape/key_redacted_from_detail` (`llm_test.go:47-48`); M4 (redaction removed) is killed. `Error()` prints only Kind + `detail`, never `cause`. `GoString` is `Error()`, so `%#v` can't dump the cause chain. The probe also checks `%v/%+v/%#v/%s` with the key in both detail and cause ([05](evidence/05-ac4-probe.png)) |
| AC7: fake scripted in order, `Requests()`, blocking returns `ctx.Err()`, `-race` passes | ✅ | `fake_test.go` `TestFakeScript`, `TestFakeReturnsCopies`, `TestFakeRequests`, `TestFakeHang` (deadline + cancel, 40–500 ms window), `TestFakeConcurrent` (50 goroutines calling `Complete` + `Requests`). CI runs them under `-race` ([01](evidence/01-ci-llm-step.png)). All 7 fake mutants are killed, including both mutex removals (the race detector catches them), shallow copies, aliasing the scripted `*Response`, and a non-blocking `Hang` ([06](evidence/06-mutations-fake.png)) |
| AC8: scope, ci.yml ≤ 5 lines, go.mod/go.sum unchanged, non-test < 400, no `openai.go`/`FromEnv` | ✅ | [02](evidence/02-scope-ac8.png): 7 files, all `internal/llm/{llm.go,config.go,llmtest/**}` + tests + `.github/workflows/ci.yml` (+4/−0); **prod 375, test 373**; go.mod/go.sum diff 0 lines; no importer outside the package; no `openai.go`; `func FromEnv` count 0 in every file |
| AC9: per-file coverage ≥ 85% from CI | ✅ | CI step output ([01](evidence/01-ci-llm-step.png)): `config.go 100.0%`, `llm.go 100.0%`, `llmtest/fake.go 100.0%`. `llm.go` gets there through `newError`/`Error`/print-form tests, not a client. But 100% line coverage didn't catch M1/M2 (finding 1) |

Design conditions: **1** (CI step) met, see AC8/AC9. **2** (cancel error shape + `errors.Is` table) only partly met: the shape is right and tested, the table is missing. **4** (budget wording in the `config.go` doc) met, `config.go:12-21` says it's a budget, names EVAL-8, and says local 7–8B models will usually fall back. **5** (nothing outside `internal/llm/**` + the CI step, no README) met. 3 needs no code.

## PRD fit
This is the seam QA-8 (Product PRD) and ADR-0001/0002 call for: one stdlib-only `Provider`, typed errors for the template-fallback decision, a nil config meaning "template answers", and a fake for `rag_test.go`. Nothing is wired in, so `/v1/ask` can't change. Under ADR-0001, the fallback logic in QA-8 depends on `errors.Is` telling "LLM slow/failing → template" apart from "client went away". That branch is exactly the one this PR leaves untested.

## Findings
1. **[blocking] AC4 / design condition 2: add the `errors.Is` table to `llm_test.go`.** Build one `*Error` per sentinel with `newError` (and a cause, e.g. `context.DeadlineExceeded` for the timeout row). Assert that `errors.Is(err, own)` is true and `errors.Is(err, s)` is false for each of the other four sentinels, and that `errors.As(err, &e)` gives back `e.Kind`. For the cancel row (`newError(nil, …, context.Canceled, …)`), assert `errors.Is(err, context.Canceled)` is true and `errors.Is` is false for **all five** sentinels, `ErrTimeout` included. Pass the value through an `error` interface variable, the way callers will. Done means mutants M1 and M2 in `evidence/04-mutations-llm.txt` fail. The ticket names this table explicitly, and condition 2 calls it binding.
2. [nit] `attemptsText` (`llm.go:140-145`) has no caller in this PR. Only LLM-1b's `openai.go` will use it, and `TestErrorShape` calls it directly just to get coverage (`llm_test.go:69-71`). Consider moving it to LLM-1b with its caller. Not blocking: `go vet` doesn't flag unused unexported functions, and it's tested.
3. [nit] `Config.String()` prints `BaseURL` exactly as stored. `ConfigFromEnv` → `normalize` rejects userinfo and queries first, but a hand-built `Config{BaseURL: "https://u:pw@h/v1?key=…"}` that hasn't been normalized would print them. No path in this PR does that. Worth keeping in mind for LLM-1b's `New` (normalize before any print or log).
4. [nit] The CI step is named "LLM client tests", but the client is LLM-1b. "LLM package tests" would match what it runs. Cosmetic.
5. [spec] AC1 lists "JSON output of `Request`, `Response`, `Message`" among the forms that must not contain the key. Those types never hold the key, so that part is true by construction. The broader Scope promise ("no error message, log line or panic contains … the prompt or the completion") isn't covered for JSON: `json.Marshal(req)` prints the prompt in full, because only `fmt` forms are size-only. That's fine as long as callers never JSON-log a `Request`/`Response`. pm-lead should decide whether QA-8 needs a "never JSON-log these" rule or whether these types should get a `MarshalJSON`. Not held against this PR.

## Missing tests
- The `errors.Is` / `errors.As` table for all five sentinels and the cancel case (finding 1).
- (Optional) `Error()` text for a nil-Kind error that has a `detail`, e.g. `llm: canceled: after 1 attempt`. LLM-1b's client will likely produce that shape.

## Hand-off
FAIL → back to backend-engineer. Fix finding 1 (tests only, about 25 lines). Nothing else blocks, and prod stays at 375. The round-2 check is that M1/M2 are killed and CI is green on the new head.
