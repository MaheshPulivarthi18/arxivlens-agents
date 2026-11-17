# OPS-H12: `stack.yml` prints one `PASSED <node id>` line per test in `make test-full`

| | |
|---|---|
| **Owner** | backend-engineer (`.github/workflows/stack.yml`) |
| **Priority** | P2 (harness/quality: removes the dot-map workaround QA needed 3 times: OPS-H8, ING-11b, OPS-H11) |
| **PRD ref** | AGENTS.md §4 ("CI is the source of truth"); Technical PRD §10 (test harness). Source: OPS-H11 QA r1 finding 1 [spec] (`agents/reviews/OPS-H11/report.md`), lessons OPS-H8 / ING-11b (qa-reviewer) |
| **Depends on** | **ING-6f #58 merged** (same file; AC6 edits its step). Otherwise none to build. Independence: no open PR touches `.github/workflows/stack.yml` (checked 2026-11-17: #51 docs/evals, #52 `db.yml`/README/CONTRIBUTING/`internal/query/search*`/2 tests, #53 `ci.yml`/Makefile/requirements/Dockerfiles, #54 `rag.go`, #55 `internal/db`, `internal/downloader`, `tests/test_m4_chaos.py`). Don't touch `Makefile` (held by #53) |
| **Jira** | not created yet (orchestrator: story under epic KAN-3 "Dev harness & infrastructure", labels `task-OPS-H12`, `agent-backend`, `arxivlens`) |
| **Design required** | no: P2, CI-only, a few lines, no CLI/table/service/contract change |
| **Status** | Blocked (needs ING-6f #58 merged: same file, AC6 edits its step). Specced 2026-11-17 by pm-lead |

## Goal
On a green run, `make test-full` in `stack.yml` runs `pytest -q`, which prints only dots, so no log line names a test. ACs like
"green in `stack.yml`, quote the test's line" can't be met without QA mapping dot positions to ids by hand. After this task the
job log has a `PASSED tests/…::<name>` line for every passing test, so ACs can quote the line directly.

## Scope
- File: `.github/workflows/stack.yml` only.
  - In the "AC4: make test-full" step, add `-rA` to the `PYTEST_ARGS` passed to `make test-full`, after the `--deselect` list.
    `-rA` makes pytest's short test summary list every outcome, including `PASSED <node id>`.
  - In the same step, the `$GITHUB_STEP_SUMMARY` block keeps its current size. It must not copy ~235 `PASSED` lines: filter
    `^PASSED ` out of what it copies from the "short test summary info" section, but keep FAILED/ERROR/SKIPPED and the final count line.
  - The "Known failure F1" step: unchanged (it already prints `tail -n 5`).
  - *Folded in 2026-11-17 (pm-lead, ING-6f QA r1/r2 nit 2):* on the step `ING-6 Risk 1: published order of recorded search feeds` (added by
    ING-6f #58), add `continue-on-error: true` next to its `timeout-minutes: 1`. A runner-enforced timeout is a step failure that the step's
    `|| echo ::warning::` can't catch, so this makes "the probe never fails the job" structural. No other change to that step.
- Out of scope: `Makefile` (`test-full` keeps `-q`; `PYTEST_ARGS` already exists), `ci.yml` / `make test-py` (#53 holds them;
  follow-up only if asked), trigger paths, any test file.

## Acceptance criteria
- [ ] AC1: on this PR's `stack.yml` run, the "AC4: make test-full" job log has a `short test summary info` section with one
  `PASSED tests/<file>::<test>` line per passing test. Quote these log lines in the PR: `PASSED tests/test_m4_chaos.py::test_redelivered_discovered_keeps_embedded_status`
  (if OPS-H11 #55 is merged first) or `PASSED tests/test_m4_chaos.py::test_corrupt_pdf_dlq_routing_and_diagnostic_payload` (otherwise),
  plus the final `N passed, …` line.
- [ ] AC2: the number of `PASSED ` lines in that log equals the `N passed` count, and the `[n]` counts on the `SKIPPED [n] …` lines sum to the skipped count (pytest groups skips that share a reason). Paste the `grep` output.
- [ ] AC3: the step's exit status still propagates. The job is green on this PR, and the step still ends with `exit "$rc"` with `rc=${PIPESTATUS[0]}` unchanged (show the diff).
- [ ] AC4: the step summary block has no `PASSED ` lines. Show the `run:` diff of the filter. Agents can't read step summaries through REST, so the rendered summary is a named human check in the PR, not an agent AC.
- [ ] AC5: actionlint and shellcheck pass (the workflow's own actionlint step is green). Diff < 30 changed lines. The ownership check passes.
- [ ] AC6: the `ING-6 Risk 1: …` step has `continue-on-error: true` (show the diff line) and still prints its `RISK1 ORDER …` (or `RISK1 none`)
  line in this PR's Full stack job log with conclusion `success` (paste the line and the step conclusion from `actions/jobs/<id>`).
- [ ] Docs: none (CI output only). If CONTRIBUTING describes how to read `stack.yml` output, leave it alone (#52 holds it) and note the follow-up.

## Verification
```bash
cd app
git diff origin/main -- .github/workflows/stack.yml
# CI: stack.yml runs on the PR (its own path is in the trigger list)
gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/<stack job id>/logs > stack.log
grep -c '^.*Z PASSED tests/' stack.log; grep -E 'Z [0-9]+ passed' stack.log
grep -E 'PASSED tests/test_m4_chaos.py::' stack.log
```

## Notes
- 2026-11-17 (pm-lead): decided at the OPS-H11 final review. Put `-rA` in `stack.yml`, not in the `Makefile`, so this lands without
  waiting for #53, and `make test-full` stays quiet locally. In `run:` blocks keep `"${arr[@]}"` quoting (lesson OPS-H1, SC2086).
- 2026-11-17 (pm-lead): **sequencing with ING-6f**. Both edit `.github/workflows/stack.yml`, so they must not run in parallel. ING-6f (P1, it
  unblocks ING-6b) goes first, and OPS-H12 starts after ING-6f's PR merges, or rebases on it. Independence check at start: no open PR on `stack.yml`.
- 2026-11-17 (pm-lead, ING-6f final review): folded ING-6f nit 2 in as the last Scope bullet + AC6 (1 line). Start only after #58 is merged (`pulls/58.merged`), branch from the new `origin/main`.
