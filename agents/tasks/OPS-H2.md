# OPS-H2: Unify Python dependencies into one `requirements.txt`

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 |
| **PRD ref** | Technical PRD §11 "Unify Python deps" |
| **Depends on** | OPS-H1 (merged `71cb609`). No open PR on `requirements*.txt`, `Makefile`, `ci.yml` or the two Dockerfiles (none in cycle 2026-11-17) |
| **Jira** | not created yet (orchestrator: story under epic KAN-3 "Dev harness & infrastructure", labels `task-OPS-H2`, `agent-backend`, `arxivlens`) |
| **Design required** | no: P1 build plumbing, no contract change |
| **Status** | Ready (re-specced 2026-11-17 against `main` `40dec5a`; see Notes for the current install lines). Branch `agent/backend/OPS-H2` |

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
