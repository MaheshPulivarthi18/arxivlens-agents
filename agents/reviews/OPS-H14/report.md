# QA report — OPS-H14 · PR #71 · round 1

**Verdict:** PASS
**Reviewed commit:** `84392b480343892cd59b498850f850b676b392ea` · **Date:** 2026-11-20
**Ticket:** `agents/tasks/OPS-H14.md` · **PRD:** Technical PRD §11 (dev harness); FE-0 design Q3; FE-1 review EPIPE nit
**Evidence commit:** `abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0` (arxivlens-agents)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI run 44665341877 | pass ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/00-ci-checks.png?raw=true)) |
| Python M0 unit tests | CI | pass |
| Frontend (lint, test, build) | CI job 136053135284 | pass; all 8 steps success ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/04-ac3-ci-dist-report.png?raw=true)) |
| Agent guardrails (ownership) | CI + local | pass; local `Ownership OK for role=backend (64 changed lines)` ([06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/06-ac5-scope.png?raw=true)) |
| DB (migrate twice, HNSW) | CI run 44665341890 | pass |
| Ticket verification commands | local | run: `bash -n` OK, fixtures, mutants, `grep 'npm run |'` (no match), ownership. **shellcheck not run**: not installed in the sandbox, not on the PyPI mirror (I chose not to execute a downloaded release binary) |
| `make test-unit` / `make lint` | CI | green; no Go/Python change |
| `make eval` | not run | CI-only change, no retrieval/answering code |

The CI checkout was `HEAD is now at d3029ac Merge 84392b4… into 4c7d327…`, so the run was on current main (4c7d327). PR #68 and #69 are both unmerged, so the "before #69" and "#68 not merged" cases apply.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | [01-ac1-fixtures](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/01-ac1-fixtures.png?raw=true). pos: `woff2 files: 2`, `x.woff2`, `y.woff2`, `@font-face rules: 2`, `.font-serif: yes`, `.prose: yes`, `google font hosts: 1`, `host files: index.html`, exit=0. neg: 0 / 0 / no / no / 0 / none, exit=0. A missing dir gives exit=1, a dir with no index.html gives exit=1, and a missing argument gives exit=1. |
| AC2 | ✅ | [02-summary](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/02-ac2-mutants-summary.png?raw=true), [03-full diffs](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/03-ac2-mutants-full.png?raw=true). M1 (drop gstatic): the gstatic-only fixture goes 1 → 0, KILLED. M2 (`--include=*.css`): the index.html host is missed, 1 → 0, KILLED. M3/M4/M5 (drop `|| true` at each of the 3 greps, one at a time): neg goes exit 0 → 1, KILLED. I also ran 12 more single-edit mutants (woff2 glob, sort, has(), hard-coded yes, index.html-only host search, `none` default, final exit). Every one that the fixture can tell apart was KILLED. The labelled SURVIVED rows are controls whose fixture can't tell them apart (M8/M12 have their M8b/M12b twins KILLED; M13 is the neg fixture with an index.html). M14 (count files instead of occurrences) survives on the AC fixtures, but CI's `google font hosts: 3` for one file proves the script counts occurrences. |
| AC3 | ✅ | [04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/04-ac3-ci-dist-report.png?raw=true), [08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/08-ac3-base-values.png?raw=true). Run **44665341877**, job 136053135284, step 8 `dist/ report (fonts, CSS)` success. Case: **before #69 merges**. The lines, in order: `DIST woff2 files: 0` · `DIST css @font-face rules: 0` · `DIST css .font-serif: no` · `DIST css .prose: no` · `DIST google font hosts: 3` · `DIST google font host files: index.html`. These match the base: 4c7d327 `frontend/index.html` has 3 Google host occurrences on lines 8–10, there are no woff2 files, and `git grep` finds no font-serif/prose/@font-face. There is no `DIST woff2:` line because n = 0, which is what the format specifies (see finding 3). |
| AC4 | ✅ | [05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/05-ac4-test-step.png?raw=true). The Test step runs `npm run test --if-present` and its only output is the runner header, with exit success. The whole job log has 0 lines starting `npm error` and 0 `Tests ` lines. Case: **#68 not merged**, because base `package.json` has no `test` script. `grep -n 'npm run |' ci.yml` finds no match (exit 1). |
| AC5 | ✅ | [06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/06-ac5-scope.png?raw=true). Diff stat: only `.github/scripts/frontend-dist-report.sh` (+58, mode 100755) and `.github/workflows/ci.yml` (+4/-2). The single ci.yml hunk is `@@ -66,9 +66,11`, inside `frontend:` (lines 54–74), so `go`/`python`/`agent-ownership` are untouched. `bash -n` OK; shellcheck not available. Ownership OK for role=backend. |
| Docs | ✅ | [06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/06-ac5-scope.png?raw=true). The script header says what it prints (all 7 lines), that it is report-only (with its exit rules), and why (agent QA can't build `dist/`; FE-0 design Q3). No README/CONTRIBUTING change. |

## PRD fit
This delivers the harness item. Frontend QA can now read real `dist/` font/CSS facts from the CI job log without running npm locally, which closes FE-0 QA finding 3. The Test step no longer pipes into `grep -q`, so the EPIPE `npm error` can't occur. The step is report-only and adds no gate, as the ticket requires.

## Findings
1. [nit] AC3/AC4 say "write in the PR which case applies and quote the lines / run ID". The PR body still has AC3/AC4 unchecked and quotes nothing. The quotes and case statements are in the AC table above. pm-lead should copy them into the PR description at stage 4 (or the developer adds them).
2. [nit] `.font-serif` / `.prose` are plain substring matches, so CSS containing only `.prose-sm` or `.font-serif-x` reports `yes` (extra probe in [03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/03-ac2-mutants-full.png?raw=true)). That is fine for a report. If the Backlog gate is built on these lines, match a selector boundary (e.g. `\.prose[^-a-zA-Z0-9_]`).
3. [spec] AC3 says "all 7 line types". But the fixed format emits no `DIST woff2: <name>` line when n = 0, which is always the case before #69. So on this base only 6 line types can appear. The script does what the format says. Re-word this for the gate follow-up ("all 7 line types, the per-file line only when n ≥ 1").
4. [nit] shellcheck wasn't run by the developer or by QA (not installed in either sandbox). The ticket accepts `bash -n`. Adding shellcheck to CI would be a separate Backlog item.

## Missing tests
- No repo-level test drives the script; the ticket asks for none (the CI run is the integration check). The QA fixture and mutant harness is rendered in full in [07-harness-sources](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/07-harness-sources.png?raw=true) for reuse in later rounds.

## Evidence
- [00-ci-checks](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/00-ci-checks.png?raw=true) · [01-ac1-fixtures](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/01-ac1-fixtures.png?raw=true) · [02-ac2-mutants-summary](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/02-ac2-mutants-summary.png?raw=true) · [03-ac2-mutants-full](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/03-ac2-mutants-full.png?raw=true) · [04-ac3-ci-dist-report](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/04-ac3-ci-dist-report.png?raw=true) · [05-ac4-test-step](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/05-ac4-test-step.png?raw=true) · [06-ac5-scope](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/06-ac5-scope.png?raw=true) · [07-harness-sources](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/07-harness-sources.png?raw=true) · [08-ac3-base-values](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0/agents/reviews/OPS-H14/evidence/08-ac3-base-values.png?raw=true) (full text in the matching `.txt`)

## Hand-off
PASS → pm-lead final review

---

# PM final review — OPS-H14 · PR #71 · round 1

**Verdict:** APPROVE
**Reviewer:** pm-lead · **Date:** 2026-11-20 · **Reviewed head:** `84392b480343892cd59b498850f850b676b392ea` (unchanged since QA) · **Evidence commit:** `abc66350eb2dd4c2d6d4bf93ab7f8ef55728d7d0`

## What I checked
- I opened all nine evidence files (00–08 `.png` + `.txt`). Each one shows real command output on head 84392b4, and each covers the AC it is labelled for:
  - 00: all 5 check runs succeeded on the head.
  - 01: AC1 pos/neg values and exit codes, matching the ticket's fixture definitions exactly. The fixture files are printed.
  - 02/03: AC2's three named mutants (M1, M2, M3–M5) are KILLED, with the output diffs shown.
  - 04 + 08: AC3 real CI lines from run 44665341877, compared against the base's facts.
  - 05: AC4 Test step log, 0 `npm error` lines, #68 not merged, no `npm run |` left.
  - 06: AC5 diff stat, the single ci.yml hunk inside `frontend:`, mode 100755, ownership OK, the Docs header.
  - 07: the harness can be reproduced.
- **PRD fit:** this is a dev-harness item (Technical PRD §11). It closes FE-0 QA finding 3: frontend QA now gets `dist/` font/CSS facts from the CI log without a local npm build. It also removes the EPIPE `npm error` noise seen on FE-1 #68. It is report-only, as specced, so no new gate is added without a decision.
- **Scope:** exactly the two files in Scope, +62/-2. Nothing extra, and nothing the ticket intended is missing. `--if-present` behaves correctly on both sides of #68: it is a no-op now and will run Vitest after #68 merges.
- **Docs:** the script header covers what it prints, that it is report-only, and why. No README/CONTRIBUTING change was needed (CI-only). No PRD status row tracks this harness item, so there is no PRD edit.
- **"⚠ unverified":** shellcheck was not run by either sandbox. The ticket accepts `bash -n`, and the script's real CI run is green, so this is not blocking.

## Findings from QA
1. QA nit 1 (the PR body lacked AC3/AC4 quotes, run ID and case): **fixed by pm-lead** in the raised PR description. It now has run 44665341877, the case "before #69 / #68 not merged", and the six quoted `DIST` lines.
2. QA [spec] 3 ("all 7 line types" when n = 0): this is my ticket wording. The script follows the fixed format, which omits the per-file `DIST woff2:` line when n = 0, so the code is correct. The wording gets fixed in the follow-up gate ticket (Backlog below), not in this PR.
3. QA nit 2 (`.prose` / `.font-serif` substring match) is acceptable for a report and gets addressed in the gate follow-up.

## Backlog (follow-ups, not tasks yet)
- **OPS-H14 gate (*Proposed*, after FE-0 #69 merges):** make the dist report fail CI when `google font hosts` > 0 or `woff2 files` = 0. AC wording for that ticket: "all 7 line types, the per-file `DIST woff2:` line only when n ≥ 1". Match selectors at a boundary (e.g. `\.prose[^-a-zA-Z0-9_]`) before treating `.prose`/`.font-serif` as gate inputs.
- **shellcheck in CI** (backend, harness): add a shellcheck step for `.github/scripts/*.sh`. Neither sandbox has it.
- **Spec-writing lesson:** when a fixed output format has conditional lines, ACs must say "line types that apply" rather than give a fixed count.

## Hand-off
APPROVE → PR #71 description rewritten with Evidence, marked ready for review, label `ready-to-merge`. Jira → Ready to merge (orchestrator). Merge: Mahesh.
