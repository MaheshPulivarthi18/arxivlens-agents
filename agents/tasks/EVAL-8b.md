# EVAL-8b: PR eval runs replay recorded real-LLM answers (no Modal call)

| | |
|---|---|
| **Owner** | ai-engineer (`scripts/`, `tests/`, `evals/`) |
| **Priority** | P2 (cost and determinism for PR runs; the nightly real-LLM run is EVAL-8a) |
| **PRD ref** | Product PRD QA-8, §8; ADR-0021 (Proposed) Q3, options P1–P3 |
| **Depends on** | **ADR-0021 Accepted** with a P option chosen; **EVAL-8c merged** (per-case `answer_kind` shows replay misses). For P1 (recommended) also **EVAL-8a merged**: the real-LLM run on `main` is what records the cache, and the `eval.yml` wiring is backend's, so the workflow lines are a backend follow-up or part of EVAL-8a (decided at finalisation) |
| **Jira** | needs a story (orchestrator) under epic KAN-2 "Retrieval & answer quality gates"; labels `task-EVAL-8b`, `agent-ai`, `arxivlens`; link KAN-46 (EVAL-8) |
| **Design required** | yes if P1 (a new CI-side service, like `arxiv_replay.py`); no for P2 |
| **Status** | Blocked (needs ADR-0021: which replay option, P1/P2/P3) |

## Goal
PRs that change answering get real-model output in the eval without paying for (or waiting on) Modal, and every answer
that was *not* replayed is visible instead of passing quietly as a quoted fallback.

## Scope (draft for the recommended P1; rewritten if Mahesh picks P2/P3)
- New `scripts/llm_replay.py` (`record` proxy in front of `LLM_BASE_URL`, and `serve --replay-only`), on the
  `scripts/arxiv_replay.py` pattern. The key is sha256 of the canonical JSON request body (model, messages, temperature,
  max_tokens, response_format; sorted keys). The store dir is the Actions cache path. Replay-only returns 404 on a miss
  and counts hits and misses, exposed on `GET /stats`. The bearer key is forwarded upstream when recording, and never
  stored or logged.
- New `tests/test_llm_replay.py`, added to `PY_LIGHT_TESTS` (a `Makefile` line is backend's: either a one-line backend
  follow-up, or ai asks for it in the PR; decided at finalisation).
- `evals/README.md`: replay section.
- Out of scope: `.github/workflows/eval.yml` wiring (backend); thresholds.

## Acceptance criteria (draft, finalised when ADR-0021 is Accepted)
- [ ] AC1 — Record then replay round-trip: the same request returns the byte-identical body; a request differing only in
      key order hits the same entry; a different message misses (404) and increments `misses` (tests, fake upstream).
- [ ] AC2 — The key never appears in the store files or logs (test greps the store dir and captured output).
- [ ] AC3 — A full-stack run with the replay proxy as `LLM_BASE_URL` (dispatch on the branch once EVAL-8a records a
      cache): summary prints `llm replay: hits H / misses M`, and the missed cases show `answer_kind: quoted` in the
      results JSON.
- [ ] AC4 — Mutants named at finalisation (key canonicalisation, miss → 404, key redaction).

## Verification
```bash
cd app && python -m pytest -q tests/test_llm_replay.py
ruff check --isolated --select E,F,W --line-length 130 scripts/llm_replay.py tests/test_llm_replay.py
```

## Notes
- 2026-11-22 (pm-lead): specced from Mahesh's direction ("EVAL-8b (ai: replayed `/v1/ask` fixtures)"). The phrase fits
  P1 (replay the LLM behind the real `/v1/ask`) and P2 (replay recorded `/v1/ask` bodies into the scorer), which test
  different things, so ADR-0021 Q3 asks him to choose. Blocked until then: either option changes what a PR eval run's
  answer gate measures.
