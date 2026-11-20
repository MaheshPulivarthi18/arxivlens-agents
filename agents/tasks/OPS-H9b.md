# OPS-H9b: Pin checks: numeric-only `version_ge`, "no pin resolved" hint, no tautological self-test, schedule-pause note

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P3 (harness) |
| **PRD ref** | Technical PRD §10 Testing and evaluation (CI harness; no PRD row). Follow-up from the OPS-H9 QA/PM review: QA nits 5, 7, 8 and the PM note (`agents/reviews/OPS-H9/report.md:48`, `:109-111`, `:151`) |
| **Depends on** | OPS-H9 (#66, merged `050904d`). No open PR touches `.github/workflows/db.yml`, `.github/workflows/image-pins.yml` or `CONTRIBUTING.md` (REST check 2026-11-20 18:00Z of #70, #79, #81, #82, #83, #84, #85, #86) |
| **Jira** | needs story (epic for Technical PRD §10 harness; label `task-OPS-H9b`) |
| **Design required** | no: CI shell checks and one doc line; no production code, contract, CLI, table or service |
| **Status** | Ready to merge (QA PASS r1 · PM APPROVE 2026-11-21; PR #88 raised, Mahesh merges) |

## Goal
The OPS-H9 pin checks have three small honesty gaps: `db.yml`'s `version_ge` lets a non-numeric `extversion` (e.g. `missing`) pass as
≥ 0.8.0; when the tool or registry is down for every image, `image-pins.yml` tells you to re-pin every image (a false re-pin); and one
self-test line can never fail. Close them, and document that GitHub pauses the weekly schedule after 60 days without activity.

## Scope
- Files expected to change (only these): `.github/workflows/db.yml` (step `pgvector >= 0.8.0 (hnsw.iterative_scan, OPS-H5)` only),
  `.github/workflows/image-pins.yml` (step `Every pinned digest resolves …` only), `CONTRIBUTING.md` (the `image-pins.yml` row at line 33
  and, if it repeats "weekly", the MinIO bullet in "Pinned images").
- How (hints, not required syntax):
  - `version_ge`: return false unless `$1` matches `^[0-9]+(\.[0-9]+)*$` (e.g. `[[ $1 =~ ^[0-9]+(\.[0-9]+)*$ ]]`); the `-n` guard becomes
    redundant and may go. Keep `MIN=0.8.0`, the existing pass/fail dry-run values and the real `extversion` check and its error message.
  - "No pin resolved": after the loop, if `${#resolved[@]}` is 0, the job fails with **one** `::error::` line containing
    `no pin resolved: check the tool/registry before re-pinning`, and the per-image error lines in that case must not say `Re-pin it`.
    When at least one pin resolves, today's per-image `Pinned image <name> no longer resolves at <digest> (<err>). Re-pin it: …` line
    stays byte-for-byte as it is.
  - Self-test `case "$msg" in *"${p%@*}"*)` (`image-pins.yml:78-79`): drop it (preferred). If you keep a check, it must be able to fail,
    e.g. the main loop and the self-test build the line through one function and the self-test asserts on that function's output.
- Out of scope: the pgvector pin/digests, `docker-compose.yml`, `stack.yml`, `ci.yml`, `README.md`, the actionlint step, the pin grep,
  the `>= 3` pin-count check, the "same pgvector pin" step, the `not found|manifest unknown|404` self-test check. ING-6c also edits
  `db.yml` later (it waits on #83 + OPS-H7a2b); it rebases on this.

## Acceptance criteria
- [ ] AC1 (`version_ge` numeric only): the `db.yml` dry run adds at least `missing`, `abc` and `0.8.0-dev` to the must-fail list and still
  prints `'<v>' -> fail (expected)` for `0.5.1`, `0.7.4`, `0.7.99`, `''` and `'<v>' -> pass (expected)` for `0.8.0`, `0.8.7`, `0.10.0`,
  `1.0.0`. On the PR's `DB` job the step is green and prints `pgvector 0.8.7 >= 0.8.0: ok` (or the current extversion). Quote run ID and
  lines. Mutant: with the regex guard removed (scratch copy of the function, not committed), `missing` passes; show it.
- [ ] AC2 ("no pin resolved" hint): run the step's script in a scratch harness with a stub `docker` (QA's fake-docker probe in
  `agents/reviews/OPS-H9/evidence/11-r2-f2-self-test-fake-docker-probe.txt` is a starting point) in three modes and paste each output:
  (a) all pins resolve → exit 0, no `::error::`; (b) one pin missing → exit 1, that image's line is byte-identical to today's
  (`… no longer resolves at … Re-pin it: CONTRIBUTING.md "Pinned images".`), no `no pin resolved` line; (c) every `inspect` fails (tool
  or registry down) → exit 1, exactly one `::error::…no pin resolved: check the tool/registry before re-pinning…` line and no `Re-pin it`.
- [ ] AC3 (self-test): the tautological `case` is gone (or replaced by a check that a mutant can make fail; if kept, show that mutant
  failing in the harness). The self-test still fails on an all-zero digest that resolves and on an error that isn't `not found`
  (harness rows for both, as in evidence 11).
- [ ] AC4 (real CI): on the PR's head, `image-pins.yml` (triggered by the `db.yml`/`image-pins.yml` path filter) is green, prints
  `ok      <pin>` for every pin and the self-test `(expected)` lines; actionlint in that job passes on both workflows. Quote run IDs.
- [ ] AC5 (docs): `CONTRIBUTING.md`'s `image-pins.yml` row says GitHub pauses the weekly schedule after 60 days without repo activity
  (same wording style as the `eval.yml` row), and mentions the `no pin resolved` message. Diff is the three files in Scope only
  (`git diff --stat origin/main`), well under 400 lines; ownership check passes for role=backend.

## Verification
```bash
git diff --stat origin/main && git diff origin/main -- .github/workflows/db.yml .github/workflows/image-pins.yml CONTRIBUTING.md
.github/scripts/ownership-check.sh origin/main agent/backend/OPS-H9b
# scratch harness (AC1 mutant, AC2 a/b/c, AC3): bash script outside the repo that sources the step body with a stub docker on PATH
# CI (source of truth): DB job and "Pinned digests resolve" job on the PR
gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/<job>/logs | grep -E "expected|>= 0.8.0|ok      |::error::|no pin resolved"
```
`make test-unit` / `make lint`: not needed (no Go/Python/frontend source change); CI is the source of truth. `make eval`: not run, nothing
in retrieval or answering changes.

## Notes
- 2026-11-20 18:00Z (pm-lead): specced from the Backlog line "From the OPS-H9 QA/PM review (backend, P3 …)". It said "fold into the next
  `db.yml`/`image-pins.yml` change, e.g. ING-6c"; ING-6c is queued behind #83 and OPS-H7a2b, and backend has no unblocked work this cycle,
  so it runs standalone. Checked on app `origin/main` `c37d27c`: `version_ge` at `db.yml:87`, per-image "Re-pin it" at
  `image-pins.yml:68`, tautological `case` at `image-pins.yml:78-79`, CONTRIBUTING row at `:33` says "Weekly" with no pause note. QA's
  extra observation that a two-part `0.8` reads as < 0.8.0 fails closed and stays as is.
- Independent of OPS-H16 (groomed in the same pass, `Makefile` only).
- 2026-11-20 (backend-engineer, build, status **In QA**): branch `agent/backend/OPS-H9b` head `9a6907c` (base `c37d27c`), 3 files,
  +13/-9, ownership check OK (22 changed lines). `db.yml`: `version_ge` is `[[ $1 =~ ^[0-9]+(\.[0-9]+)*$ ]] && …sort -V…` (the `-n`
  guard went), must-fail list adds `missing abc 0.8.0-dev`. `image-pins.yml`: per-image errors are buffered; if `${#resolved[@]}` is 0,
  per-image `FAIL    <pin> (<err>)` lines (no `::error::`, no "Re-pin it") then one `::error::no pin resolved: check the tool/registry
  before re-pinning (all N pins failed, FAIL lines above)`; otherwise each buffered `::error::Pinned image … Re-pin it: …` line is printed
  after the loop (byte-identical to main's, `cmp` in harness; it now appears after the `ok` lines, not inline). Tautological `case` removed.
  CONTRIBUTING row: no-pin-resolved message + "GitHub pauses the weekly schedule after 60 days without repo activity"; MinIO bullet left as is.
  Local harness (step bodies extracted with PyYAML, `bash -e`, fake docker/psql): AC1 dry run all `(expected)`, stub extversion 0.8.7 →
  `pgvector 0.8.7 >= 0.8.0: ok`; on main's step `missing` → `pgvector missing >= 0.8.0: ok` rc 0 (the bug); mutant without the regex →
  `::error::self-test: 'missing' passed, want fail`. AC2 a/b/c and AC3 (accepts_all, zero_unauth) exit codes as specified.
  Not run: actionlint/shellcheck (not in sandbox; CI job runs actionlint), real CI runs (AC1 DB job, AC4) pending the PR.
- 2026-11-21 (pm-lead, final review): QA PASS r1 (`agents/reviews/OPS-H9b/report.md`, evidence 00–07 at `b55a09d`) → **PM APPROVE**.
  All five ACs are proven by CI (DB job 136478144250, Image pins job 136478143438) plus QA's harness and mutants. PR #88 description
  rewritten with Evidence, then marked ready for review. QA nits: (1) the `^` anchor has no dry-run row → Backlog, fold into ING-6c
  (add `v0.8.7` to the must-fail list); (2) the MinIO bullet wording → same Backlog line; (3) the duplicate FAIL + `::error::` line is
  accepted as is. Jira: needs story (orchestrator). Status → Ready to merge.
