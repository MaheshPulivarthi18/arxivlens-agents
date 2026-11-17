# OPS-H2: Unify Python dependencies into one `requirements.txt`

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Technical PRD §11 "Unify Python deps" |
| **Depends on** | OPS-H1 (merged `71cb609`). No open PR on `requirements*.txt`, `Makefile`, `ci.yml` or the two Dockerfiles (none in cycle 2026-11-17) |
| **Jira** | KAN-14 (epic KAN-3) |
| **Design required** | no: P1 build plumbing, no contract change |
| **Status** | Ready to merge (PR #53 raised 2026-11-17 at head `95ea3bb`; QA PASS r1, PM APPROVE r1) |

## Goal
Setup currently needs `pip install -r requirements-m0.txt minio ulid-py fastapi uvicorn` (plus `opentelemetry-sdk` in `make setup-py`),
repeated in the Makefile, `ci.yml` and both Dockerfiles. One file, one command. (Dockerfiles `COPY` the file they install; with the
shim, an image must copy `requirements.txt` too, or install it directly.)

## Scope
- New `requirements.txt` with every runtime dep (lower-bound pins as today); `requirements-dev.txt` with `pytest` and dev-only tools, `-r requirements.txt` at the top.
- Keep `requirements-m0.txt` as a one-line `-r requirements.txt` shim for one release, with a comment, so old instructions still work.
- Update both Dockerfiles, Makefile `setup-py` (`Makefile:18`) and `ci.yml:49`. *(2026-11-17: README and `CONTRIBUTING.md` already say `make setup-py` and stay unchanged; `services/AGENTS.md` no longer exists. Full edit list in Notes.)*
- CI: install CPU-only torch (`--extra-index-url https://download.pytorch.org/whl/cpu`) to keep CI fast.

## Acceptance criteria
- [ ] AC1 — Fresh venv: `pip install -r requirements-dev.txt && pytest tests/test_m0.py` passes.
- [ ] AC2 — No remaining `pip install ... minio ulid-py fastapi uvicorn` strings in the repo (`grep -rnE "minio ulid-py|ulid-py fastapi" . --exclude-dir=.git --exclude-dir=node_modules` empty, except the shim comment). The processor Dockerfile's `minio ulid-py` counts too.
- [ ] AC3 — Both Docker images build; `make stack-up` still healthy.
- [ ] AC4 — CI green.

## Verification
```bash
python3 -m venv /tmp/v && /tmp/v/bin/pip install -r requirements-dev.txt && PYTHONPATH=$PWD /tmp/v/bin/pytest tests/test_m0.py
docker compose --profile workers build
grep -rnE "minio ulid-py|ulid-py fastapi" . --exclude-dir=.git --exclude-dir=node_modules
# CI: ci.yml Python job (AC1), stack.yml on the PR (AC3; triggered by requirements*/Dockerfiles/Makefile)
```

## Notes
- 2026-11-03 (pm-lead, OPS-H1 design gate): OPS-H1 adds `opentelemetry-sdk` to `make setup-py`, because `tests/test_m5_m6_telemetry_eval.py` imports `opentelemetry`. Fold it into the unified `requirements.txt` (test/dev deps) and keep `make test-full` collecting every suite.
- 2026-11-17 (pm-lead, grooming): **re-specced to today's tree.** `services/AGENTS.md` no longer exists (drop it from Scope). The five places
  that install Python deps today, which are the whole edit list:
  `Makefile:18` (`setup-py`: `-r requirements-m0.txt minio ulid-py fastapi uvicorn opentelemetry-sdk`), `.github/workflows/ci.yml:49`
  (CPU torch index + `-r requirements-m0.txt minio ulid-py fastapi uvicorn`), `services/embedder/Dockerfile:12-13`, `services/processor/Dockerfile:12-13`
  (`minio ulid-py`, no fastapi), and `requirements-m0.txt` itself (now includes `sentencepiece`, #44). `eval.yml`/`stack.yml` call `make setup-py`
  and cache on `requirements*.txt`, so they need no edit. README `:145` and `CONTRIBUTING.md:14` say `make setup-py`, which stays the
  command, so neither changes. **Do not touch `README.md` or `CONTRIBUTING.md`** in this cycle (ING-11b and EVAL-4 hold them).
  Decisions for the build (no open question): `requirements.txt` = runtime (the m0 list minus `pytest`, plus `minio`, `ulid-py`, `fastapi`, `uvicorn`);
  `requirements-dev.txt` = `-r requirements.txt` + `pytest` + `opentelemetry-sdk`; the processor image installs `requirements.txt` (it gains
  fastapi/uvicorn, a few MB, acceptable for one file; say so in the PR); `requirements-m0.txt` becomes the one-line shim. Verification is CI
  only (PyPI and Docker aren't reachable from the sandbox): `ci.yml` Python job (AC1), `stack.yml` (triggered by `requirements*.txt`,
  Dockerfiles and `Makefile`: AC3, both images build and the stack is healthy), and AC2's grep.
- 2026-11-17 (backend-engineer, build): branch `agent/backend/OPS-H2` head `95ea3bb` (base `40dec5a`), 7 files, +28/-17 (ownership check: 45 changed lines, OK for backend).
  - New `requirements.txt` (runtime: the old m0 pins minus `pytest`, same specifiers, plus unpinned `minio`, `ulid-py`, `fastapi`, `uvicorn`, as they were unpinned before) and `requirements-dev.txt` (`-r requirements.txt`, `pytest>=8.0.0`, `opentelemetry-sdk`).
  - `requirements-m0.txt` = one line `-r requirements.txt  # Deprecated shim ...`, as specced. Trade-off for QA/PM: the old file contained `pytest`, and the shim (runtime only) doesn't, so an old `pip install -r requirements-m0.txt && pytest` needs pytest installed separately. Pointing it at `requirements-dev.txt` would keep pytest. That's a one-word change if pm-lead prefers it.
  - `Makefile:18` and `ci.yml:49` install `-r requirements-dev.txt` (CI keeps the CPU torch `--extra-index-url`). Both Dockerfiles `COPY requirements.txt .` and install `-r requirements.txt`, so the processor image gains fastapi/uvicorn (a few MB). The CI Python job now also installs `opentelemetry-sdk`, which `make test-py` doesn't need, but it's harmless.
  - Verified locally: AC2 grep is empty (exit 1). `requirements-m0` is no longer referenced anywhere except the shim. A static flatten script (packaging.Requirement) showed requirements-dev.txt == the old `make setup-py` set, requirements.txt == dev minus pytest/otel, every old pin identical, no duplicates. `pip install --dry-run --no-index -r requirements-dev.txt` parsed every file and failed only at resolution (no index). The compose build context is the repo root with no `.dockerignore`, so `COPY requirements.txt` resolves.
  - Not run locally: AC1 (PyPI unreachable: `NameResolutionError pypi.org`), AC3 (no Docker daemon: `/var/run/docker.sock` missing), `make test-unit`/`make lint` (Go 1.25 download blocked; the change has no Go code). CI is the source of truth: `ci.yml` Python job (AC1) and `stack.yml` (AC3, triggered by requirements*/Dockerfiles/Makefile).
- 2026-11-17 (pm-lead, final review): **APPROVE** → PR #53 raised (ready for review), see `agents/reviews/OPS-H2/report.md`. QA finding 1 (shim omits pytest)
  accepted as specced: the old public instruction was runtime-only (run workers and API) and still works. Follow-up after merge (pm-lead):
  a `rules/` PR to update `agents/area-notes/services.md:9` to `make setup-py`, plus a `docs/` PR to mark the Technical PRD §11 "Unify Python deps" row done.
