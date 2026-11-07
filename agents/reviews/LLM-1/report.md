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

---

# QA report — LLM-1 · PR #23 · round 2

**Verdict:** PASS
**Reviewed commit:** `8e333c4661ad5173bb448d1e27ec78bd863e250b` (round 1 was `8e32771`) · **Date:** 2026-11-07

One-line reason: round-2 delta is tests plus the CI step name only (`llm_test.go` +39, `ci.yml` 1 line renamed). The new `TestErrorsIsAs` table kills mutants M1 and M2, which survived in round 1. All 8 llm/config mutants and all 7 fake mutants are now killed, CI is green on `8e333c4`, and prod stays at 375 lines.

## Round-1 findings re-checked
| # | Round-1 finding | Status at 8e333c4 | Evidence |
|---|---|---|---|
| 1 | [blocking] `errors.Is`/`errors.As` table missing | **Fixed.** `TestErrorsIsAs` (`llm_test.go:74-111`) has 6 rows: one per sentinel built with `newError`, plus cancel (`newError(nil, …, context.Canceled, …)`). Each `err` is held in an `error` interface field. For every row it asserts `errors.Is(err, s) == (s == kind)` for all five sentinels, so the cancel row requires false for all five, `ErrTimeout` included. The timeout row asserts `errors.Is(err, context.DeadlineExceeded)`, the cancel row asserts `errors.Is(err, context.Canceled)`, typed rows assert `errors.Is(err, context.Canceled)` is false, and `errors.As(err, &*Error)` returns the expected `Kind` (nil for cancel). M1 is killed at `rate_limited`, M2 at `cancel` | [10](evidence/10-mutations-llm-r2.png), CI [15](evidence/15-ci-llm-step-r2.png) (6 subtests PASS) |
| 2 | [nit] `attemptsText` has no caller | Unchanged, still non-blocking | n/a |
| 3 | [nit] `Config.String` prints a non-normalized BaseURL | Unchanged, no path in this PR; carry to LLM-1b `New` | n/a |
| 4 | [nit] CI step named "LLM client tests" | **Fixed.** Now "LLM package tests (verbose, race, per-file coverage)" | [13](evidence/13-scope-r2.png) (round-2 delta) |
| 5 | [spec] JSON-logging `Request`/`Response` | Still open for pm-lead, not held against the PR | n/a |

## Test results (round 2)
| Check | Source | Result |
|---|---|---|
| All 5 check runs (Go, Python M0, Frontend, DB, ownership) | CI on 8e333c4 ([14](evidence/14-ci-checks-r2.png)) | all `completed success` |
| LLM package tests step | CI Go job 128332211740 ([15](evidence/15-ci-llm-step-r2.png)) | `-race` pass; `TestErrorsIsAs` + 6 subtests PASS; per-file coverage `config.go 100.0%`, `llm.go 100.0%`, `llmtest/fake.go 100.0%` (AC9) |
| `make lint` / `make test-unit` | CI (`make test-go` in the Go job) | pass. Not run locally: sandbox has Go 1.24, `go.mod` needs 1.25 |
| `go vet`, `gofmt -l`, `go test -race -count=3 ./internal/llm/...`, verbose `TestErrorsIsAs` | local Go 1.24 scratch-module copy ([11](evidence/11-local-vet-race-r2.png)) | clean / clean / pass / PASS |
| Mutation re-run, llm.go + config.go (M1–M8) | local ([10](evidence/10-mutations-llm-r2.png)) | **8/8 killed** (round 1: 6/8) |
| Mutation re-run, llmtest/fake.go (F1–F7) | local ([12](evidence/12-mutations-fake-r2.png)) | 7/7 killed, no regression |
| Scope / AC8 | worktree at 8e333c4 ([13](evidence/13-scope-r2.png)) | 7 files, same as round 1; prod 375 (< 400), test 412; ci.yml +4/−0 vs main; go.mod/go.sum 0 lines; no `openai.go`, `func FromEnv` count 0, 0 importers outside `internal/llm` |
| `make eval` | n/a | not run: nothing imports `internal/llm`, so retrieval and answering can't change |

## Acceptance criteria (round 2)
| AC | Met? | Evidence |
|---|---|---|
| AC1 (split) | ✅ | unchanged code and tests since round 1; M6/M7/M8 still killed ([10](evidence/10-mutations-llm-r2.png)) |
| AC4 (split) | ✅ | `TestErrorsIsAs` + `TestErrorShape`; M1, M2, M3, M5 killed ([10](evidence/10-mutations-llm-r2.png)); CI [15](evidence/15-ci-llm-step-r2.png) |
| AC6 (split) | ✅ | unchanged; M4 killed ([10](evidence/10-mutations-llm-r2.png)) |
| AC7 | ✅ | unchanged; F1–F7 killed ([12](evidence/12-mutations-fake-r2.png)); `-race` in CI ([15](evidence/15-ci-llm-step-r2.png)) |
| AC8 | ✅ | [13](evidence/13-scope-r2.png) |
| AC9 | ✅ | [15](evidence/15-ci-llm-step-r2.png) |

Design condition 2 (cancel error shape + `errors.Is` table, binding) is now fully met. Conditions 1, 4 and 5 are still met as in round 1.

## Findings (round 2)
1. [nit] In `TestErrorsIsAs`, the `provider` and `bad response` rows pass a cause (`errors.New(...)`) but set `tt.cause` to nil, so the test doesn't assert that those causes stay reachable through `errors.Is`. `TestErrorShape/kind_and_cause` covers cause unwrapping in general (M3 is killed), so this is not blocking.
2. [nit] Round-1 nits 2 and 3 carry over to LLM-1b (see the table above).

## Hand-off
PASS → pm-lead for final review. Open items for pm-lead: [spec] item 5 from round 1, and the LLM-1b carry-overs (`attemptsText` caller, normalize BaseURL before printing in `New`).

---

# PM review — LLM-1 · PR #23

**Verdict:** APPROVE
**Reviewed commit:** `8e333c4661ad5173bb448d1e27ec78bd863e250b` (PR head, draft) · **QA:** round 2 PASS · **Evidence pinned at:** `8d686761ba1cb4d5a91a58b5fd5404226717a2e4` · **Date:** 2026-11-07 · **Reviewer:** pm-lead

## What I checked
- **Ticket and split.** The PR delivers exactly part a of the split: `llm.go`, `config.go` without `FromEnv`, `llmtest/`, their tests and the CI step. 7 files, all inside the allow-list (`gh api .../pulls/23/files`: ci.yml +4, config.go +143, llm.go +145, llmtest/fake.go +87, tests +412). No `openai.go`, no `FromEnv`, `go.mod`/`go.sum` untouched, nothing outside `internal/llm` imports it, so `/v1/ask` can't change ([13](evidence/13-scope-r2.png)).
- **AC8 size.** Non-test 375 < 400. That's within 1 line of the split estimate (376), so the split worked as intended.
- **Design conditions.** 1: the CI step runs `-race` + per-file coverage (`ci.yml` diff read; output in [15](evidence/15-ci-llm-step-r2.png)). 2: `TestErrorsIsAs` has one row per sentinel + the cancel row, all five sentinels false on cancel, `ErrTimeout` included; mutants M1/M2 now die ([10](evidence/10-mutations-llm-r2.png)). 3: answered in the design, no code. 4: I read the `config.go` doc comment: it says "a budget, not a measurement", names EVAL-8, and says local 7–8B models will usually fall back at 2 s. That's the honesty QA-8's README needs. 5: met.
- **Evidence.** I opened every file I rely on: 14 (5/5 check runs success on `8e333c4`), 15 + its `.txt` tail (all `TestConfigFromEnv`/`TestConfigNormalize`/`TestErrorShape`/`TestErrorsIsAs`/`TestFake*` subtests PASS under `-race` in CI; per-file `config.go`, `llm.go`, `llmtest/fake.go` 100.0%), 13 (scope), 10 (8/8 llm/config mutants killed), 12 (7/7 fake mutants killed), 11 (local vet/gofmt/race at the new head), 03 (AC1 redaction tests, round-1 head; those tests are unchanged in round 2 and also pass in CI 15), 05 (QA's AC4/AC6 probe). Each AC has CI output plus a mutation kill behind it, which is stronger than a coverage number. Nothing is "⚠ unverified".
- **`make eval`:** correctly "not run": zero importers, so retrieval and answering can't change.
- **Human feedback:** none on PR #23 (0 reviews, 0 review comments; the only issue comment is QA's round-1 report).

## Product fit
This is the seam ADR-0001/0002 call for and QA-8 (Product PRD) needs: one stdlib `Provider`, a nil config that means "template answers" (the fallback-first principle), typed errors that let QA-8 tell "LLM slow or failing → template" apart from "client went away", and a concurrency-safe fake for `rag_test.go`. The privacy promise is right-sized: the package doc promises no key, prompt or completion in error, `String` or `GoString` output, and the tests prove exactly that.

## Docs and PRD
- No README change, correct: the env vars do nothing until QA-8 wires them, and QA-8 documents them (design condition 5).
- No PRD status change: Product QA-8 stays ⏳ until QA-8 merges. The pending pm-lead docs PR for the QA-8 row (board Backlog) is unaffected.

## Decisions on QA's open items
1. **[spec] round-1 item 5 (JSON form of `Request`/`Response`).** No `MarshalJSON` here. The package promises fmt/error forms only, and a custom `MarshalJSON` would surprise anyone who serialises these types on purpose. The rule goes to the caller: **never JSON-log a `Request` or `Response`; log their `%v` form or named metadata fields.** QA-8's AC6 captured-logger test (sentinel key, no prompt/completion in any line) already enforces it. I've added the rule to QA-8's Notes. AC1's "JSON output of `Request`/`Response`/`Message`" clause holds by construction (they never hold the key), so the LLM-1 spec needs no change.
2. **Carry-overs to LLM-1b** (added to its Notes; QA checks them there): `attemptsText` gets its real caller in `openai.go`, and `New` must `normalize` (reject userinfo/query) before any `String()`/log of `Config`, so a hand-built unnormalised `Config` can't print credentials.
3. Round-2 nit 1 (provider/bad-response causes not asserted through `errors.Is`): not needed. `TestErrorShape/kind_and_cause` covers cause unwrapping, and M3 dies.

## Hand-off
APPROVE → orchestrator: replace the PR #23 body with `/tmp/claude-0/s/pr23-body.md`, mark it ready for review, Jira KAN-35 → **Ready to merge**. Merge order: no conflict with any open PR (new directory + 4 lines appended to `ci.yml` after the Kafka step). After merge, LLM-1b becomes Ready.
