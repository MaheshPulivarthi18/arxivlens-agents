# EVAL-8d: Pin `main`'s rate wiring to `llm_warnings` and the `sha256:` digest prefix (EVAL-8c QA r2 nits)

| | |
|---|---|
| **Owner** | ai-engineer (`tests/`, `scripts/`) |
| **Priority** | P2 (test-only hardening of report-only metadata) |
| **PRD ref** | Product PRD QA-8, §8; EVAL-8 AC1; follow-up of [EVAL-8c](EVAL-8c.md) QA round 2 Findings 1–2 |
| **Depends on** | EVAL-8c (#122) **merged** (same `tests/test_evals_data.py`). Queue on that file: this, then the EVAL-6c nits / EVAL-7 / EVAL-5 follow-ups |
| **Jira** | needs a story (orchestrator) under epic KAN-2; labels `task-EVAL-8d`, `agent-ai`, `arxivlens`; link the EVAL-8c story |
| **Design required** | no: tests only, no behaviour change |
| **Status** | Ready (startable once #122 merges) |

## Goal
Two EVAL-8c behaviours have no test: `main` passing `rate` to `llm_warnings`, and stripping a `sha256:` prefix from the
`/api/tags` digest. QA showed both mutants survive (`agents/reviews/EVAL-8c/evidence/14-r2-AC6-mutants.txt`, r2b and r2e).
If either regresses, all-refused runs get the misleading "(every answer was quoted)" warning again, or
`digest_short` becomes `sha256:357c5`, and that breaks the digest comparison EVAL-8a/8b will rely on (ADR-0021 R3).

## Scope
- `tests/test_evals_data.py`: two tests, using the existing `_gate_main`, `LLM_ENV` and `_fake_ollama` helpers.
- `scripts/eval_gate.py`: **no change expected.** If a test exposes a real bug, fix it minimally and say so in Notes.
- Out of scope: any other EVAL-8c behaviour, `check_thresholds`, `evals/thresholds.json`, exit codes, docs.
- Size target: < 60 changed lines.

## Acceptance criteria
- [ ] AC1: a `main`-level test with `LLM_ENV` (model set) and the ask fake returning only refusals (0 answered, rate `None`)
      asserts stderr does **not** contain "0 answers were synthesized" and the exit code is the same as without the LLM env.
      Mutant r2b (`main` calls `llm_warnings(llm["model"], synthesized)` without `rate`) fails it.
- [ ] AC2: `/api/tags` faked with `"digest": "sha256:" + 64 hex` for the model gives `digest` = the 64 hex (no prefix) and
      `digest_short` = the first 12 hex. Mutant r2e (keep the prefix) fails it. The existing unprefixed-digest test still passes.
- [ ] AC3: no existing test is modified or removed (`git diff origin/main -- tests/test_evals_data.py` shows additions only);
      the diff is exactly `tests/test_evals_data.py` (plus `scripts/eval_gate.py` only if AC1/AC2 found a bug).
- [ ] AC4: CI `Python M0 unit tests` and `Agent ownership check` are green on the draft PR; ruff is clean on the added lines.

## Verification
```bash
cd app
python -m pytest -q tests/test_evals_data.py
ruff check --isolated --select E,F,W --line-length 130 tests/test_evals_data.py scripts/eval_gate.py
git diff origin/main --name-only
# mutants r2b / r2e: apply locally to scripts/eval_gate.py, run the file, confirm a failure, revert (never pushed)
```
`make eval` not required (tests only).

## Notes
- 2026-11-27 (pm-lead): split from the EVAL-8c PM review. Both nits were non-blocking for EVAL-8c (stderr text and a
  report-only field), and the developer left out the `sha256:` test to stay under the 300-line stop.
