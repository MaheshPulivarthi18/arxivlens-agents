# OPS-H15: Run the CI Go unit tests under the race detector

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P2 (harness) |
| **PRD ref** | Technical PRD §11 harness/quality; follow-up from ING-9 QA nit 6 (`agents/reviews/ING-9/report.md:46`, again at `:93`): "The CI Go job runs without `-race`, so AC1's `-race` requirement is proven only by the local scratch run" |
| **Depends on** | OPS-H14 (#71, merged `1b443f5`; it was the last open PR on `ci.yml`). No open PR touches `.github/workflows/ci.yml` (checked 2026-11-20 08:00Z against #65, #66, #68, #69, #70, #76, #77, #78, #79 via REST) |
| **Jira** | KAN-83 |
| **Design required** | no: one CI step's environment, no production code, contract, CLI, table or service change |
| **Status** | Ready |

## Goal
Every Go package has concurrent code (limiter, consumer, crawler loop, rerank fallback, LLM client), but CI's `make test-go` step runs
`go test ./...` **without** `-race`. Only `internal/kafka/` and `internal/llm/` get `-race`, in their own verbose steps. Make the
whole-repo Go unit test step run under the race detector, so a data race anywhere fails CI instead of being "proven only locally".

## Scope
- File expected to change (and only this one): `.github/workflows/ci.yml`, job `go`, step `- run: make test-go`.
- How: keep the `make test-go` command and give that step `env: GOFLAGS: -race` (`go test` honours `GOFLAGS`), and a `name:` that says
  so, e.g. `Go unit tests (make test-go, race detector)`. Don't change the `Makefile` (local `make test-go` stays as it is: `-race` needs
  cgo + a C compiler, and documenting that would need `CONTRIBUTING.md`, which open PR #66 changes). Keep the existing Kafka and LLM
  steps unchanged (they add `-v` and coverage).
- Out of scope: `Makefile`, `CONTRIBUTING.md`, `README.md`, every other job (`python`, `frontend`, `agent-ownership`), `db.yml`.
  **If the race detector reports a race or a timing test becomes flaky under `-race`: stop and report.** Paste the `WARNING: DATA RACE`
  block or the failing test line into Notes, set the task `Blocked (race found: <package>)`, and request a follow-up task for the
  owning package. Don't fix production code here, and don't skip, loosen or `-race`-exclude any test.

## Acceptance criteria
- [ ] AC1: On the PR's head, the CI job `Go (vet, gofmt, test, build)` passes. Its renamed step's log shows `GOFLAGS: -race` in the
  step's `env:` header and an `ok` line for every package that has tests (at least `internal/arxiv`, `internal/config`,
  `internal/crawler`, `internal/db`, `internal/dlq`, `internal/downloader`, `internal/kafka`, `internal/llm`, `internal/query`). Quote
  the run ID, the env line and the `ok` lines.
- [ ] AC2: The detector really runs (one mutant). Push a temporary commit to the task branch that adds a deliberately racy test (e.g.
  `internal/arxiv/race_probe_test.go`: two goroutines increment a shared int without a lock, then `wg.Wait()`). The CI step fails with
  `WARNING: DATA RACE` and `--- FAIL` for that test. Then remove it with a second commit (`git revert`, not a force-push) and show the
  next run green. Quote both run IDs and the `WARNING: DATA RACE` line. The probe file must not be in the final diff.
- [ ] AC3: Runtime. Report the renamed step's duration from the REST jobs API (`started_at` → `completed_at`) next to the baseline on
  `main` `e6cffba`: run 44677460170, job 136092606453, step `Run make test-go` 04:54:33Z → 04:54:39Z (6 s). If the step takes more than
  5 min, stop and report it in Notes instead of raising the PR (pm-lead decides).
- [ ] AC4: Flake check. Re-run the PR's CI Go job once (`gh run rerun <id> --job <job-id>` or the UI) and show it green a second time
  (quote both run attempts). The timing tests in `internal/arxiv/limiter_test.go` (`slack` margins) are the likely flake source under
  `-race`; a failure there is a stop-and-report (Scope), not a reason to change the test.
- [ ] AC5: Final diff is `.github/workflows/ci.yml` only (`git diff --stat origin/main`), a few lines in job `go`. The ownership check
  passes for role=backend. `actionlint` if available, otherwise "not run" plus the green CI run as proof the YAML parses.
- [ ] Docs: none. The local `make test-go` command is unchanged, so `CONTRIBUTING.md`/`README.md` need no edit. (If Mahesh later wants
  `-race` in the `Makefile` too, that's a follow-up with a CONTRIBUTING cgo note, after #66 merges.)

## Verification
```bash
git diff --stat origin/main && git diff origin/main -- .github/workflows/ci.yml
.github/scripts/ownership-check.sh origin/main agent/backend/OPS-H15
# CI (source of truth): ci.yml job "Go (vet, gofmt, test, build)" on the PR, plus the probe run (AC2) and one re-run (AC4)
gh api repos/MaheshPulivarthi18/ArxivLens/actions/runs/<run>/jobs --jq '.jobs[] | select(.name|startswith("Go")) | .steps[] | "\(.name) \(.conclusion) \(.started_at) \(.completed_at)"'
gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/<job>/logs | grep -E 'GOFLAGS|^.{29}(ok|FAIL|---)|DATA RACE'
```
`make lint` / `make test-unit` locally: not needed (no Go/Python/frontend source changes); CI is the source of truth. `make eval`: not
run, nothing in retrieval or answering changes. `stack.yml` does not trigger on `ci.yml`-only PRs; that's expected.

## Notes
- 2026-11-20 08:00Z (pm-lead): specced from the Backlog line "From ING-9 QA nit 6 (backend, P2, harness): CI's Go job runs `go test ./...`
  without `-race` …". Earlier groomings (2026-11-19 23:00Z, 2026-11-20 04:00Z) skipped it because `ci.yml` was open in OPS-H14 #71 and the
  `Makefile` route needs a CONTRIBUTING cgo note (#66). #71 merged as `1b443f5`, and the `GOFLAGS` route needs neither the `Makefile` nor
  CONTRIBUTING. Checked on app `origin/main` `e6cffba`: `ci.yml` job `go` runs `make lint-go`, `make test-go`, the Kafka `-race` step,
  the LLM `-race` step and `make build-go`. `make test-go` is `go test ./...` (`Makefile:45-46`). The baseline timing in AC3 comes from
  `actions/runs/44677460170/jobs`.
- Independent of every open PR (#65 `internal/query/rag*.go`, `tests/test_evals_data.py`, `README.md`; #66 `db.yml`, `image-pins.yml`,
  `CONTRIBUTING.md`, `docker-compose.yml`; #68/#69/#70 `frontend/**` + root `README.md`; #76 `internal/kafka/consumer_test.go`; #77
  `tests/test_verify.py`; #78 `tests/test_m2_pipeline.py`; #79 `internal/llm/openai_test.go`) and of OPS-H5b (groomed in the same pass,
  `internal/query/search_integration_test.go`, which only `db.yml` runs). The race detector will also run the tests that #76/#79 add once
  they merge; that's intended.
