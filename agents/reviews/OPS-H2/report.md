<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/53#issuecomment-6943024446 (the QA harness could not write report.md). -->

[qa-reviewer] # QA report — OPS-H2 · PR #53 · round 1

**Verdict:** PASS
**Reviewed commit:** `95ea3bb6447ca586a64d3c1607904f31929f6ac4` (CI merge commit `33d5c69` onto main `40dec5a`) · **Date:** 2026-11-17
**Ticket:** [`agents/tasks/OPS-H2.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/tasks/OPS-H2.md) · **PRD:** Technical PRD §11 "Unify Python deps" · no design doc (not design-required)
**Evidence pack:** [agents/reviews/OPS-H2/evidence](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence) (commit `fb334b7`)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 133911829248 | pass ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/00-ci-checks.png)) |
| Python M0 unit tests | CI job 133911829081 | pass: `182 passed, 3 skipped` + kafka `37 passed`, same as base job 132852478871 ([05](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/05-ac1-ci-python.png ``)) |
| Frontend (lint, test, build) | CI job 133911829033 | pass |
| Agent ownership check | CI job 133911828867 | pass |
| DB (migrate twice, HNSW plan + recall) | CI job 133911828416 | pass |
| Full stack (compose + make test-full) | CI job 133911828707 (stack.yml run 44046036021) | pass: 3 images built, all healthy, `233 passed, 1 skipped, 3 deselected`; the known-failure F1 step (continue-on-error) shows `3 failed`, the same as the previous green stack job 132833622346 ([06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/06-ac3-stack.png)) |
| Ticket verification: AC2 grep | local, PR worktree at 95ea3bb | empty, exit 1 ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/02-ac2-grep.png)) |
| Ticket verification: fresh venv + pytest, `docker compose build` | not run locally: no PyPI and no Docker daemon in the sandbox; covered by the CI jobs above | — |
| `make test-unit` / `make lint` | not run locally: the sandbox has Go 1.24.7 and go.mod needs 1.25; the PR has no Go changes; CI Go and Frontend jobs are green | — |
| Independent pin-set diff at every install site | local, `packaging.Requirement` flatten, base vs head ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/03-pin-diff.png), source [04](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/04-pin-harness-source.png)) ``` | no specifier changed, no duplicates |
| `make eval` | not applicable (build plumbing, no retrieval/answering change); `eval.yml` paths don't match this PR | — |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1: fresh env, `pip install -r requirements-dev.txt && pytest tests/test_m0.py` passes | ✅ | [05](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/05-ac1-ci-python.png ````): on a fresh runner the CI Python job runs exactly `pip install --extra-index-url …/whl/cpu -r requirements-dev.txt`. Its log collects every direct requirement from `requirements.txt` lines 4-17 and `requirements-dev.txt` lines 3-4, with torch `2.15.0+cpu`. `make test-py` (which includes `tests/test_m0.py`) then gives `182 passed, 3 skipped`, the same counts as the base commit's job. Note: this used setup-python's interpreter with the pip wheel cache, not a literal `venv`. That is equivalent for this AC. |
| AC2: no `minio ulid-py` / `ulid-py fastapi` install strings | ✅ | [02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/02-ac2-grep.png): the ticket grep exits 1 at 95ea3bb. A full `git grep` for `pip install`/`requirements*` finds only the 4 install sites, all using `-r requirements(-dev).txt`, plus the shim. |
| AC3: both Docker images build; `make stack-up` healthy | ✅ | [06](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/06-ac3-stack.png `````): BuildKit runs `COPY requirements.txt .` and `RUN pip install … -r requirements.txt`. The log shows `Image arxivlens-embedder-api/processor/embedder-worker Built` and `stack-up: … healthy` for all three. `make test-full` counts match the baseline. |
| AC4: CI green | ✅ | [00](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/00-ci-checks.png ``````): all 6 check runs on 95ea3bb are `completed success`. |

Scope ([01](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/01-diff-scope.png ```````)): 7 files, +28/−17, all inside backend ownership. README and CONTRIBUTING are untouched, as the ticket required. No ticket, review or doc files are in the PR.

## PRD fit
The PR delivers Technical PRD §11 "Unify Python deps". There is one runtime file (`requirements.txt`) used by both images and one dev file used by `make setup-py` and CI, and CI and the images keep CPU torch. The install set behind `make setup-py` is unchanged, package for package and specifier for specifier ([03](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/03-pin-diff.png ````````)). So `eval.yml` and `stack.yml`, which call `make setup-py` and cache on `requirements*.txt`, get the same environment as before.

## Findings
1. [spec] The `requirements-m0.txt` shim points at the runtime-only `requirements.txt`, as the ticket specified. The old file contained `pytest>=8.0.0`, so an old instruction like `pip install -r requirements-m0.txt … && pytest` now lacks pytest ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/03-pin-diff.png), the two `requirements-m0.txt` rows). "So old instructions still work" is only partly true. pm-lead may want `-r requirements-dev.txt` in the shim (a one-word change). Not blocking: the code follows the spec's explicit decision.
2. [spec] `agents/area-notes/services.md:9` in arxivlens-agents still documents `pip install -r requirements-m0.txt minio ulid-py fastapi uvicorn   # until OPS-H2 unifies deps`. It needs a pm-lead `rules/` PR after merge. The file is outside the app repo, so AC2's grep doesn't see it.
3. [nit] Both image changes are intended and harmless. Both images drop `pytest`, and nothing under `services/`, `scripts/`, `shared/` or compose references it ([07](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/07-setup-and-image-pytest.png)). ````````` The processor image gains `fastapi`/`uvicorn`, which the ticket accepted. The two Dockerfiles' install layers (lines 1-13) are now byte-identical, so BuildKit built the pip layer once for all three images (`#12 [processor 5/8]`, [06](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/06-ac3-stack.png ``````````)). Worth one line in the PR description.
4. [nit] The CI Python job now also installs `opentelemetry-sdk`, which `make test-py` doesn't need. It's harmless, and having one dev file is the point of the change.

No blocking findings.

## Missing tests
- None needed for build plumbing. Residual risk: this PR's paths don't trigger `eval.yml`. That workflow runs `make setup-py`, whose resolved package set is proven identical to before ([03](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fb334b72516eab875697e09e28a42b2e75784391/agents/reviews/OPS-H2/evidence/03-pin-diff.png ```````````)). The nightly schedule will confirm.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

# PM final review — OPS-H2 · PR #53 · round 1

**Verdict:** APPROVE
**Reviewer:** pm-lead · **Date:** 2026-11-17 · **Reviewed head:** `95ea3bb6447ca586a64d3c1607904f31929f6ac4` (re-checked via `git rev-parse origin/agent/backend/OPS-H2` and the PR API just before raising)

## Evidence check (each file opened)
| File | Proves | OK |
|---|---|---|
| 00-ci-checks.png | AC4: 6/6 check runs on 95ea3bb `completed success` | yes |
| 01-diff-scope.png | Scope: 7 files, +28/−17, all backend-owned; README and CONTRIBUTING untouched | yes |
| 02-ac2-grep.png | AC2: ticket grep exit 1; every install site is `-r requirements(-dev).txt` | yes |
| 03-pin-diff.png + 04-pin-harness-source.png | AC1/AC3 support: install set per site, base vs head; setup-py unchanged (16/16), no specifier changed, no duplicates; harness source is reproducible | yes |
| 05-ac1-ci-python.png | AC1: a fresh CI runner installs only `-r requirements-dev.txt` (direct requirements traced to the new files' lines), then `182 passed, 3 skipped` + `37 passed`, same as base. A runner instead of a literal venv is acceptable | yes |
| 06-ac3-stack.png | AC3: `COPY requirements.txt .`, then 3 images built and healthy; `make test-full` 233/1/3 matches the baseline; F1 known-failure step unchanged | yes |
| 07-setup-and-image-pytest.png | No regression from images dropping pytest; Dockerfile install layers identical | yes |

No AC is left "⚠ unverified".

## Product and scope
- Delivers Technical PRD §11 "Unify Python deps": one runtime file used by both images, one dev file used by `make setup-py` and CI, and the setup command is unchanged for contributors. DoD 4: README and CONTRIBUTING need no edit, because `make setup-py` is still the documented command (ticket Notes, re-spec 2026-11-17).
- Nothing extra, nothing missing against the ticket's edit list (Makefile:18, ci.yml:49, both Dockerfiles, shim).

## QA findings: decisions
1. **[spec] Shim → `requirements.txt` drops pytest: accepted as specced, no rework.** The only public instruction that ever used this file
   (app README from `ff19d80` until it was removed in `71cb609`) was `pip install -r requirements-m0.txt minio ulid-py fastapi uvicorn`, which
   set up the environment to *run* the workers and API. With the shim that command still installs the same runtime set (pip tolerates
   the duplicate names), so the old instruction still works for its purpose. Pointing a file called "runtime m0" at dev deps would
   reintroduce test tooling into whatever still installs it, and the shim is deprecated for one release with a comment pointing at
   `make setup-py`. The one test-oriented instruction left is our own area note (finding 2), which the follow-up rewrites. The PR body states the residual
   risk.
2. **[spec] `agents/area-notes/services.md:9` stale → follow-up**, owned by pm-lead, after PR #53 merges: a `rules/` PR that changes the setup
   line to `make setup-py` (or `pip install -r requirements-dev.txt`). In the same cycle, a `docs/` PR marks the Technical PRD §11 "Unify Python deps" row done.
   Not opened now, because it must not describe unmerged behaviour.
3. [nit] Image changes (pytest dropped; processor gains fastapi/uvicorn; shared pip layer): one line in the PR body under risks.
4. [nit] CI also installs `opentelemetry-sdk`: one line in the PR body under risks.

## Action
PR #53 description rewritten from `agents/templates/pr.md` with the Evidence section (images pinned to `fb334b7`), CI results, and the QA and PM verdicts.
PR marked ready for review. Jira KAN-14 → Ready to merge (mirrored by the orchestrator).
