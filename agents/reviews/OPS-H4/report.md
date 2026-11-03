# QA report: OPS-H4 · PR #12 · round 1

**Verdict:** PASS
**Reviewed commit:** `31682fb0dce718286a504e73e3809a3305389181` · **Date:** 2026-11-03
**Ticket:** `agents/tasks/OPS-H4.md` · **PRD:** Product PRD §8; EVAL-1 AC5 (+ Notes follow-up)
**Design:** none (not design-required)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 125824920370 | pass ([00](evidence/00-ci-checks.png), [07](evidence/07-ac3-ci-test-unit.png)) |
| Python M0 unit tests (`make test-py`) | CI job 125824920242 | pass, `50 passed in 6.47s` (main `bb9ee90`: `3 passed`) ([05](evidence/05-ac5-ci-python-job.png)) |
| Frontend (lint, test, build) | CI | pass ([00](evidence/00-ci-checks.png)) |
| Agent ownership check | CI | pass ([00](evidence/00-ci-checks.png)) |
| `git check-ignore -v evals/results/x.json` | local | `.gitignore:29:evals/results/`, exit 0 ([01](evidence/01-ac1-check-ignore.png)) |
| `pytest -q tests/test_evals_data.py` | local | `47 passed` ([02](evidence/02-ac2-test-py.png)) |
| `make test-py` | local | fails in this sandbox: `tests/test_m0.py` collection error (no torch / HF blocked). CI is the source of truth ([02](evidence/02-ac2-test-py.png)) |
| `make test-unit`, `make lint` | not run locally | Go 1.24.7 here, go.mod needs 1.25 (download blocked). CI ran `make lint-go`, `make test-go`, `make test-py`: all green ([07](evidence/07-ac3-ci-test-unit.png)) |
| `git diff --stat origin/main...HEAD` | local | 2 files, +4/-3 ([04](evidence/04-ac4-diff.png)) |
| Mutation check on eval data | local, scratch copy of HEAD | duplicate ID → 2 failed; off-corpus relevant ID → 1 failed ([06](evidence/06-mutation-eval-data.png)) |
| `make eval` | not run: no retrieval/answering change (only `.gitignore` + `Makefile` test target) | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: `git check-ignore evals/results/x.json` prints path, exit 0 | ✅ | `.gitignore:29:evals/results/	evals/results/x.json`, `exit=0`. `git ls-files -ci --exclude-standard` is empty, so the new rule hides no tracked file; the tracked `evals/*` files are unaffected. [01-ac1-check-ignore.png](evidence/01-ac1-check-ignore.png) |
| AC2: `make test-py` runs `tests/test_evals_data.py`, passes | ✅ | `make -n test-py` → `python3 -m pytest -q tests/test_m0.py tests/test_evals_data.py` (Makefile:47-48). Local eval-data run: `47 passed in 0.11s` [02](evidence/02-ac2-test-py.png). The full `make test-py` passes in CI: `50 passed in 6.47s` [05](evidence/05-ac5-ci-python-job.png) |
| AC3: `make test-unit` passes; `make help` lists `test-py` accurately | ✅ | `make help`: `test-py  Python unit tests: M0 + eval data (M0 downloads BGE model on first run)`; `test-unit  Fast tests, no infra (Go + M0 + eval data)...`. Both match the recipes (`make -n test-unit`) [03](evidence/03-ac3-make-help.png). `test-unit = test-go test-py`, both green in CI on 31682fb [07](evidence/07-ac3-ci-test-unit.png) |
| AC4: diff touches only `.gitignore` and `Makefile` | ✅ | `.gitignore | 1 +`, `Makefile | 6 +++---`, single commit [04](evidence/04-ac4-diff.png). Both paths are in backend's allow-list (`.github/scripts/ownership-check.sh:15`); the CI ownership check passed |
| AC5: CI "Python M0 unit tests" job runs `tests/test_evals_data.py`, pass count ≥ 47 | ✅ | Head job log: `python3 -m pytest -q tests/test_m0.py tests/test_evals_data.py` → `50 passed`. Baseline main job log: `pytest -q tests/test_m0.py` → `3 passed`; `test_m0.py` has 3 tests and `test_evals_data.py` collects 47, so 50 = 3 + 47 [05](evidence/05-ac5-ci-python-job.png). No extra CI package was needed and `requirements*.txt` is unchanged |

## PRD fit
Yes. Product PRD §8 gates quality on the `evals/*.jsonl` datasets. With this change the CI job that runs on every PR checks those datasets' schema, sizes, corpus membership and unique IDs, and per-run `make eval` outputs can't be committed by accident. That closes the EVAL-1 AC5 / QA r3 finding 8 follow-up. Contracts, thresholds and eval gates are untouched.

## Findings
1. [spec] Stale docs that AC4 doesn't allow fixing in this PR: `CONTRIBUTING.md:23` still says ``make test-unit`` = "Go tests + `pytest tests/test_m0.py`", and `README.md:199` lists only `pytest tests/test_m0.py` as the unit run. AGENTS.md DoD 4 asks for CONTRIBUTING to be updated when commands change, but AC4 limits the diff to `.gitignore` + `Makefile`. pm-lead: either relax AC4 to allow a one-line CONTRIBUTING/README update in this PR, or open a backend follow-up. This doesn't block, because the developer followed the ticket.
2. [spec] AC5 asks for "its pass count", but `pytest -q` prints one combined summary for both files (`50 passed`). I derived the 47 by comparing against main's `3 passed` and the collected counts ([05](evidence/05-ac5-ci-python-job.png)). That proof is fine. If a separate per-file count is ever wanted, the AC (or the recipe) has to ask for it explicitly.
3. [nit] Both files run in one pytest invocation, so a collection error in `tests/test_m0.py` (e.g. no torch in an agent sandbox) aborts the whole run and the eval-data tests don't execute either ([02](evidence/02-ac2-test-py.png)). In CI this doesn't matter because torch is installed. Locally, `python3 -m pytest -q tests/test_evals_data.py` (as in `evals/README.md:67`) remains the workaround. No change requested.

## Missing tests
- None required. The change adds no new test logic and wires existing tests into the suite. The mutation check ([06](evidence/06-mutation-eval-data.png)) shows the newly wired tests catch broken eval data (duplicate case ID; relevant paper missing from `evals/corpus.txt`), so CI now fails on those cases.

## Hand-off
PASS → pm-lead final review (see [spec] items 1-2).

---

## PM review (round 1)

**Reviewer:** pm-lead · **Date:** 2026-11-03 · **PR:** #12 (draft) · **Head reviewed:** `31682fb0dce718286a504e73e3809a3305389181` (unchanged since QA; CI 4/4 green) · **Evidence commit:** `2a5c36f238c59e4eb2d8316ab58844b1e5845cb0`

**Verdict: CHANGES** (round 1 of 2). The code is correct and AC1-AC5 are proven. The only gap is DoD 4, and it comes from my spec, not the developer.

### Why CHANGES and not APPROVE + follow-up
DoD 4 says "App README.md / CONTRIBUTING.md updated if behaviour or commands changed". This PR changes what `make test-unit` runs, and `CONTRIBUTING.md:23` would be wrong on `main` the moment it merges (`| make test-unit | Go tests + pytest tests/test_m0.py | No |`). CONTRIBUTING is the file every developer agent reads for commands, so a stale row there causes real confusion. The fix is two lines in files backend already owns (`CONTRIBUTING.md`) or any role may edit (`README.md`). A separate PR for two lines would cost more (spec, branch, QA, PM, merge) than one short rework round. My AC4 ("only `.gitignore` and `Makefile`") was too tight and caused this. **[spec] fixed:** AC4 now allows `CONTRIBUTING.md` + `README.md`, and new AC6 covers the doc lines (`agents/tasks/OPS-H4.md`).

### Required changes (backend-engineer, branch `agent/backend/OPS-H4`, push to PR #12)
1. `CONTRIBUTING.md:23`: change the row to
   `| \`make test-unit\` | Go tests + \`pytest tests/test_m0.py tests/test_evals_data.py\` | No |`
2. `README.md:199` (Testing block): keep the `test_m0.py` line and add this line directly under it, with the `#` aligned to the lines above:
   `pytest tests/test_evals_data.py            # Unit: eval datasets — schema, sizes, corpus membership, unique IDs (no infra)`
3. Change nothing else. Leave `.gitignore` and `Makefile` as they are, and leave the other stale EVAL-1 wording in `CONTRIBUTING.md` (line 28 `make eval` row, "once EVAL-1, PR #2, lands"; line 54 "once EVAL-1 lands") alone. That is a separate follow-up.

QA round 2 then needs: AC4 (diff = `.gitignore`, `Makefile`, `CONTRIBUTING.md`, `README.md`), AC6 (the two lines, verbatim), and CI green on the new head. AC1-AC5 evidence carries over if `.gitignore`/`Makefile` are byte-identical to `31682fb`.

### Evidence check (every file opened, PNG and .txt)
| File | Proves | OK? |
|---|---|---|
| `00-ci-checks` | 4/4 check runs success on `31682fb` | yes |
| `01-ac1-check-ignore` | `.gitignore:29:evals/results/` matches `evals/results/x.json`, exit 0; no tracked file newly ignored; the 7 tracked `evals/*` files are intact (AC1) | yes |
| `02-ac2-test-py` | `make -n test-py` includes `tests/test_evals_data.py`; `47 passed` locally; full local `make test-py` fails only on `test_m0.py` collection (no torch), and the image says so (AC2, local part) | yes, with 05 for the full run |
| `03-ac3-make-help` | `make help` shows accurate `test-unit` / `test-py` text; `make -n test-unit` = `go test` + both pytest files (AC3) | yes |
| `04-ac4-diff` | `.gitignore` +1, `Makefile` +3/−3, nothing else (AC4 as written) | yes |
| `05-ac5-ci-python-job` | CI head job runs both files, `50 passed`; main job ran `test_m0.py` only, `3 passed`; 50 − 3 = 47 eval tests (AC5) | yes. The derived count is acceptable (QA [spec] 2); AC5 is reworded to say "combined count rises by ≥ 47" |
| `06-mutation-eval-data` | duplicate id → 2 failures; off-corpus paper → 1 failure. The wired tests do catch bad eval data | yes |
| `07-ac3-ci-test-unit` | CI `make lint-go` + `make test-go` (`ok` for crawler/kafka/query) + `make test-py` `50 passed` = `test-unit` green (AC3) | yes |

No secrets in any evidence file.

### Product fit
Product PRD §8 gates quality on the `evals/*.jsonl` datasets. After this PR, every PR's CI validates them, and per-run results can't be committed. This closes EVAL-1 AC5 / QA r3 finding 8. No gate, threshold or contract changes.

### QA findings → disposition
1. [spec] stale CONTRIBUTING/README → this CHANGES list (items 1-2); spec fixed.
2. [spec] AC5 per-file count → accepted as proven; AC5 wording clarified in the spec.
3. [nit] a `test_m0.py` collection error locally aborts the eval tests too → no change. CI has torch, and `evals/README.md:67` documents the standalone command for sandboxes.

### Follow-ups
- Backlog (backend-engineer, docs-only, P2): `CONTRIBUTING.md:28` `make eval` row still says "quality gate over `evals/` once EVAL-1, PR #2, lands", and `CONTRIBUTING.md:54` says "`evals/thresholds.json` once EVAL-1 lands". EVAL-1 has merged, so reword both (for example "Quality gate vs Product PRD §8 (`scripts/eval_gate.py`, thresholds in `evals/thresholds.json`)").

---

## QA round 2

**Verdict:** PASS
**Reviewed commit:** `0edd8fd378f2ae07d49f38a3b1be150ba23e21be` (round 1: `31682fb`) · **Date:** 2026-11-03 · **Reviewer:** qa-reviewer (fresh context)
**Scope of this round:** PM CHANGES round 1 checklist, widened AC4, new AC6, and proof that the AC1-AC5 evidence still applies.

### Test results
| Check | Source | Result |
|---|---|---|
| CI check runs on `0edd8fd` | GitHub check-runs API | 4/4 `completed success`: Python M0 unit tests, Go (vet, gofmt, test, build), Frontend (lint, test, build), Agent ownership check ([10](evidence/10-r2-ci-checks.png)) |
| Python M0 unit tests (`make test-py`) | CI job 125831741281 | `python3 -m pytest -q tests/test_m0.py tests/test_evals_data.py` → `50 passed in 6.23s` ([14](evidence/14-r2-ci-job-logs.png)) |
| Go `make lint-go`, `make test-go`, `make build-go` | CI job 125831741186 | `ok` for crawler/kafka/query; job success ([14](evidence/14-r2-ci-job-logs.png)) |
| Ownership check | CI job 125831740663 | `Ownership OK for role=backend (10 changed lines)` ([14](evidence/14-r2-ci-job-logs.png)) |
| `.gitignore` / `Makefile` vs `31682fb` | local, `app/` at `0edd8fd` | `git diff --exit-code` exit 0; same blob SHAs and same sha256 for both files ([11](evidence/11-r2-byte-identical.png)) |
| `git check-ignore -v evals/results/x.json` | local | `.gitignore:29:evals/results/`, exit 0 ([11](evidence/11-r2-byte-identical.png)) |
| `make test-unit`, `make lint` | not run locally: Go 1.24.7 in the sandbox (go.mod needs 1.25, download blocked), and no torch for `test_m0.py` | CI ran the same targets, all green (see above) |
| `make eval` | not run: docs-only rework; no retrieval/answering change | n/a |

### Carry-over of AC1-AC5 evidence
`git diff --exit-code 31682fb HEAD -- .gitignore Makefile` → exit 0. Blob IDs match (`.gitignore` `ae45223…`, `Makefile` `7b75a9b…` at both commits), and so do the sha256 sums ([11](evidence/11-r2-byte-identical.png)). The only commit since round 1 (`0edd8fd`) touches `CONTRIBUTING.md` and `README.md` only ([12](evidence/12-r2-ac4-diff.png)). So round-1 evidence 01-07 still proves AC1-AC5. CI evidence for AC3/AC5 was also re-taken on the new head ([14](evidence/14-r2-ci-job-logs.png)).

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: `evals/results/x.json` ignored | ✅ | Re-checked on `0edd8fd`: `.gitignore:29:evals/results/`, exit 0 ([11](evidence/11-r2-byte-identical.png)); round 1 [01](evidence/01-ac1-check-ignore.png) |
| AC2: `make test-py` runs and passes `tests/test_evals_data.py` | ✅ | `make -n test-py` lists both files ([11](evidence/11-r2-byte-identical.png)); CI head `50 passed` ([14](evidence/14-r2-ci-job-logs.png)) |
| AC3: `make test-unit` passes; `make help` accurate | ✅ | Makefile byte-identical, so round-1 [03](evidence/03-ac3-make-help.png) holds; `make -n test-unit` = `go test ./...` + both pytest files ([11](evidence/11-r2-byte-identical.png)); CI `make lint-go`/`test-go`/`test-py` green on `0edd8fd` ([14](evidence/14-r2-ci-job-logs.png)) |
| AC4: diff touches only `.gitignore`, `Makefile`, `CONTRIBUTING.md`, `README.md` (docs: only the AC6 lines) | ✅ | `git diff --stat origin/main...HEAD`: `.gitignore` +1, `CONTRIBUTING.md` +1/-1, `Makefile` +3/-3, `README.md` +1; 4 files, 2 commits. `git diff 31682fb HEAD` shows exactly the two AC6 hunks: CONTRIBUTING line 23 replaced, README line 200 added. `CONTRIBUTING.md:28,54` untouched ([12](evidence/12-r2-ac4-diff.png)) |
| AC5: CI Python job runs `tests/test_evals_data.py`; combined count rises by ≥ 47 over main | ✅ | Head job: `python3 -m pytest -q tests/test_m0.py tests/test_evals_data.py` → `50 passed` ([14](evidence/14-r2-ci-job-logs.png)) vs main's `3 passed` (round 1 [05](evidence/05-ac5-ci-python-job.png)), +47. No `requirements*.txt` change |
| AC6: docs match the new command | ✅ | `grep -nFx` exact match of the spec string: `CONTRIBUTING.md:23` (exit 0), and `README.md:200` directly under the `test_m0.py` line at 199 (exit 0). `#` sits at column 44 on lines 199-201, aligned ([13](evidence/13-r2-ac6-docs.png)) |

### PM rework checklist (verified independently)
- [x] `CONTRIBUTING.md:23` row verbatim: exact-line grep match ([13](evidence/13-r2-ac6-docs.png))
- [x] README Testing block line added under `test_m0.py`, `#` aligned: exact-line grep match + column check ([13](evidence/13-r2-ac6-docs.png))
- [x] Nothing else changed; `.gitignore`/`Makefile` byte-identical to `31682fb`; `CONTRIBUTING.md:28,54` untouched ([11](evidence/11-r2-byte-identical.png), [12](evidence/12-r2-ac4-diff.png))

### PRD fit
Unchanged from round 1. The docs now describe what `make test-unit` actually runs (DoD 4). No contracts, thresholds or eval gates changed.

### Findings
1. [nit][spec] AC6 says "`README.md:199`", but that line number points at the `test_m0.py` line; the new line sits *under* it at 200, which is what the AC wording ("under the `test_m0.py` line") asks for. No change requested.
2. Round-1 [nit] 3 (a local `test_m0.py` collection error also stops the eval-data tests) still stands; PM disposition was no change.

No blocking findings.

### Missing tests
None. This round changes docs only.

### Hand-off
PASS → pm-lead final review (round 2). Follow-up already logged by PM: stale EVAL-1 wording at `CONTRIBUTING.md:28,54`.

---

## PM review (round 2)

**Reviewer:** pm-lead · **Date:** 2026-11-03 · **PR:** #12 · **Head reviewed:** `0edd8fd378f2ae07d49f38a3b1be150ba23e21be` (live head checked; CI 4/4 success) · **Evidence:** r1 `2a5c36f238c59e4eb2d8316ab58844b1e5845cb0`, r2 `5a1ade598c3f5686ab111ff97da2cd3e437f17c6`

**Verdict: APPROVE**

### Round-1 CHANGES list, item by item
1. `CONTRIBUTING.md:23` row: done, and it matches the spec string exactly (13: `grep -nFx` exit 0).
2. README Testing block line: done at `README.md:200`, directly under the `test_m0.py` line, with `#` at column 44 like its neighbours (13).
3. Nothing else changed: `.gitignore`/`Makefile` have the same blob ids and sha256 as `31682fb` (11). `git diff 31682fb HEAD` shows only the two doc hunks, and `CONTRIBUTING.md:28,54` are untouched (12).

### Evidence check (round-2 files, PNG and .txt opened)
| File | Proves | OK? |
|---|---|---|
| `10-r2-ci-checks` | 4/4 check runs success on `0edd8fd` | yes |
| `11-r2-byte-identical` | `.gitignore`/`Makefile` byte-identical to `31682fb`; check-ignore exit 0; `make -n test-py`/`test-unit` include both pytest files, so the round-1 evidence 01-07 for AC1-AC5 still applies | yes |
| `12-r2-ac4-diff` | 4 files, +6/−4, 2 commits; the round-2 delta is only the two AC6 hunks (AC4) | yes |
| `13-r2-ac6-docs` | exact-line matches for both doc lines plus the column check (AC6) | yes. In the rendered image the `#` on the grep-output line looks shifted only because of the `200:` prefix; the .txt and the column check confirm alignment |
| `14-r2-ci-job-logs` | CI on the new head: `make test-py` runs both files → `50 passed` (AC2/AC5, +47 over main's 3); `make lint-go`/`test-go` ok (AC3); ownership OK, 10 changed lines | yes |

No secrets in any file. DoD 1-5 are now met: all ACs evidenced, CI green, `make eval` n/a (no retrieval change), docs updated in the same PR, QA PASS plus this APPROVE.

### QA round-2 findings
1. [nit][spec] AC6 line reference: I corrected the spec wording to "`README.md:200`, directly under the `test_m0.py` line at :199".
2. The round-1 nit 3 stays at "no change".

### Follow-ups
- Unchanged from round 1: stale EVAL-1 wording at `CONTRIBUTING.md:28,54` (backend, docs-only, P2).
