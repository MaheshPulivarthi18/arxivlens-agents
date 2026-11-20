# OPS-H16: `make test-fe` runs `npm test` directly (no `grep -q` pipe, no silent "no tests" pass)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 (harness) |
| **PRD ref** | Technical PRD §10 Testing and evaluation (local test commands; no PRD row). Follow-up from the FE-1 QA/PM review; the CI half was done in OPS-H14 (#71), the Backlog line "Still open: `Makefile` `test-fe` has the same `grep -q` pattern" is this task |
| **Depends on** | FE-1 (#68, merged `2410d2e`: `frontend/package.json` has `"test": "vitest run"`). No open PR touches `Makefile` (REST check 2026-11-20 18:00Z of #70, #79, #81, #82, #83, #84, #85, #86) |
| **Jira** | needs story (epic for Technical PRD §10 harness; label `task-OPS-H16`) |
| **Design required** | no: one Makefile recipe; no production code, contract, CLI, table or service |
| **Status** | In QA |

## Goal
`make test-fe` (`Makefile:51-52`) still runs `if npm run | grep -q " test"; then npm test; else echo "no frontend tests yet (FE-1)"; fi`.
`grep -q` closes the pipe on its first match, so `npm run` can log a spurious `npm error` (EPIPE), and if the `test` script ever goes
missing the target prints "no frontend tests yet" and exits 0, a false green. FE-1 has merged, so the guard has no purpose: run `npm test`.

## Scope
- File expected to change (only this one): `Makefile`, the `test-fe` target (recipe and its `##` help text, which still says
  "available after FE-1"). E.g. `test-fe: ## Frontend tests (Vitest; run npm ci in frontend/ first)` / `cd frontend && npm test`.
- Leave `test-unit` as it is (it does not include `test-fe`; changing that is a separate decision). Don't add `npm ci` to the recipe.
- Docs: `README.md`, `CONTRIBUTING.md` and `frontend/README.md` don't mention `make test-fe` today (`grep -n test-fe` on `c37d27c`
  finds only `Makefile`), so no doc change is expected. If the help text changes what a reader needs to do, `make help` is the doc.
- Out of scope: `.github/workflows/ci.yml` (its frontend step is OPS-H14's), `frontend/**`.

## Acceptance criteria
- [ ] AC1: `make -n test-fe` prints a recipe that runs `npm test` in `frontend/` with no pipe, no `grep` and no `npm run` listing.
  Paste the output.
- [ ] AC2 (exit codes, stub npm): with a stub `npm` first on `PATH` (a scratch script outside the repo that logs its argv to a file and
  exits with `$STUB_RC`), show three runs: (a) `STUB_RC=0 make test-fe` → exit 0 and the stub was called exactly once, with argv `test`;
  (b) `STUB_RC=1 make test-fe` → make exits non-zero (`make: *** [Makefile:…: test-fe] Error 1`); (c) the old recipe from `origin/main`
  with a stub whose `npm run` listing has no ` test` line → exit 0 with "no frontend tests yet", showing the false green this task removes.
- [ ] AC3 (real npm, if the sandbox has Node/npm; else "not run: <reason>"): after `cd frontend && npm ci`, `make test-fe` runs Vitest,
  prints its summary (`Test Files … passed`) and exits 0, with no `npm error` line. Paste the tail.
- [ ] AC4: `make help` lists `test-fe` with the new help text and no "FE-1". Diff is `Makefile` only (`git diff --stat origin/main`),
  a few lines; ownership check passes for role=backend; CI on the PR is green (`ci.yml` jobs).

## Verification
```bash
git diff --stat origin/main && git diff origin/main -- Makefile
make -n test-fe && make help | grep test-fe
# AC2: mkdir -p "$SCRATCH/bin"; write a stub npm there; PATH="$SCRATCH/bin:$PATH" STUB_RC=0 make test-fe; echo "exit=$?"
.github/scripts/ownership-check.sh origin/main agent/backend/OPS-H16
```
`make lint` / `make test-unit`: not affected (no source change); CI is the source of truth. `make eval`: not run, nothing in retrieval or
answering changes.

## Notes
- 2026-11-20 18:00Z (pm-lead): specced from the Backlog line "Still open: `Makefile` `test-fe` has the same `grep -q` pattern (local only;
  backend, fold into the next `Makefile` change)". No `Makefile` change is queued, and backend has no unblocked work this cycle, so it runs
  standalone. Checked on app `origin/main` `c37d27c`: `Makefile:51-52`; `frontend/package.json:11` `"test": "vitest run"`.
- Independent of OPS-H9b (groomed in the same pass: `db.yml`, `image-pins.yml`, `CONTRIBUTING.md`).
- 2026-11-20 18:15Z (backend-engineer): built on `agent/backend/OPS-H16` (head `bf76769`, from `c37d27c`). `Makefile` only, 2+/2-:
  `test-fe: ## Frontend tests (Vitest; run npm ci in frontend/ first)` / `cd frontend && npm test` (recipe no longer `@`-silenced, so
  the command is echoed). Ran: `make -n test-fe` → `cd frontend && npm test`; `make help | grep test-fe` → new text, no "FE-1";
  stub-npm runs (stub in the session scratchpad, outside the repo): (a) `STUB_RC=0` → exit 0, one call, argv `test`; (b) `STUB_RC=1` →
  `make: *** [Makefile:52: test-fe] Error 1`, exit 2; (c) `origin/main` Makefile with a listing lacking ` test` → "no frontend tests yet
  (FE-1)", exit 0 (the false green). Ownership check: `Ownership OK for role=backend (4 changed lines)`. AC3 not run: `npm ci` fails with
  ENOTFOUND for registry.npmjs.org in this sandbox (Node 22 is present). `make lint`/`make test-unit` not run locally (no source change);
  CI on the PR is the source of truth. Status → In QA.
