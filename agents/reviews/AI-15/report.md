<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/117#issuecomment-7066528521 (2026-11-21, cycle 17:00Z); QA's harness could not write report.md. -->

[qa-reviewer] QA report: AI-15 · PR #117 · round 1

**Verdict:** PASS
**Reviewed commit:** `7699ccad5cc7283bde20037781fa4f0eea7e4dd9` (branch `agent/ai/AI-15`; CI merge `8d32cdf` = head + main `11c4696`, the current `origin/main`) · **Date:** 2026-11-21
**Ticket:** [`agents/tasks/AI-15.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/AI-15.md) · **PRD:** Product PRD ING-4 (on-demand ingest), §8 latency (`/v1/ask` p95 < 3 s)
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence
_The QA harness refused to write `report.md`, so this comment is the report of record; the orchestrator saves it verbatim to `agents/reviews/AI-15/report.md`._

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136919861528 | success ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/00-ci-checks.png)) |
| Python M0 unit tests (`make test-py-ml`) | CI job 136919861524 | success: `63 passed, 2 skipped` vs base main `60 passed, 2 skipped` ([09](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/09-AC7-ci-py-ml-log.png ``)). The dot map puts the 4 `*not_serialized*` tests at #38–#41, all `.` ([04](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/04-AC7-ci-dotmap.png ```)) |
| Frontend (lint, test, build) | CI | success |
| DB (migrate twice, HNSW plan + recall) | CI | success |
| Full stack (compose + make test-full) | CI job 136919861558 | success (17:21:21Z) |
| Agent ownership check | CI + local | success; `ownership-check.sh origin/main agent/ai/AI-15` → `Ownership OK for role=ai (158 changed lines)` ([01](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/01-AC7-scope-ownership.png)) ```` |
| `pytest tests/test_verify.py [-k not_serialized]` | local **stub harness** (MagicMock torch/transformers/psycopg, functional fastapi stub; torch/fastapi can't be installed, proxy 403) | 16 passed, 2 failed. The 2 failures do real torch math and fail the same way on main's file under the stub ([03](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/03-AC1-4-local-harness-rA.png), ````` [06](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/06-AC5-mutants-control-main-tests.png)). `````` Logic check only; CI is the source of truth |
| `ruff check --isolated --select E,F,W --line-length 130 tests/test_verify.py` | local, ruff 0.16.9 | 3 × E501 (lines 22, 71, 126), identical on `origin/main`; 0 on added lines ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/02-AC6-ruff.png)) |
| `make test-unit` | not run locally: needs Go 1.25 + torch | covered by the CI Go and Python jobs |
| `make eval` | not applicable: test-only change | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 rerank cross-encoder | ✅ | `test_rerank_cross_encoder_is_not_serialized_…`: sentinel tok/model, fake `score_pairs` returns `[0.5]*n, {}` and records the lock state. Asserts `scores == [0.5, 0.5]`, lock held + 0 exits at return, one call with `is tok`, `is model`, `("q", ["a","b"], True)`. CI dot #39. It also sets `embedder=_NoEmbedder` (raises if the fallback runs), which is what lets AC1 kill m4 |
| AC2 rerank bi-encoder fallback | ✅ | `reranker_model=None`; fake `embed_texts` returns `(n,768)` and records `(texts, is_query, locked)`; `score_pairs` raises. Asserts 2 finite floats, lock held + 0 exits, `calls == [(["q"], True, True), (["a","b"], False, True)]`. CI dot #40 |
| AC3 verify | ✅ | Sentinel nli model/tokenizer/idx; fake `api.nli.verify_pairs` returns `([0.9], {})`. Asserts `scores == [0.9]`, `model == api.NLI_MODEL`, lock held + 0 exits, one call with `[("c","p")]`. CI dot #41 |
| AC4 bounded / no hang / no leak | ✅ | Endpoint in its own thread, `join(timeout=5)`; ingest joined in `finally` with `timeout=10` (> 2 × 0.5 s). Every test asserts ingest `status == "success"`. Under m1 the test fails in 1.3 s with 0 threads alive; under a never-returning verify mutant it fails in 5.3 s (`endpoint call did not return: {}`) with no `run_ingest` thread left ([08](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/08-AC4-leak-probe.png ```````)). 20/20 green under N+2 busy loops ([07](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/07-AC4-stress-20x.png ````````)) |
| AC5 mutants (run by QA, stub harness, git-archive copies, never committed) | ✅ | m1 → only the cross-encoder test fails (`locked_at_return False, exits_at_return 2`); m2 → only the fallback test; m3 → only the verify test; m4 → only the cross-encoder test (`HTTPException(500, 'bi-encoder fallback must not run …')`). The other 15 tests pass, ≈5.1 s per run. Extra QA mutants q5 (verify 503 while locked) and q6 (lock only the passage embed) are also killed ([05](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/05-AC5-mutants-head.png `````````)). **Negative control:** the same 6 mutants against main's test file all SURVIVE ([06](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/06-AC5-mutants-control-main-tests.png)). `````````` Harness sources: [10](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/10-harness-sources.png ```````````) |
| AC6 ruff | ✅ | 0 findings on added lines ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/02-AC6-ruff.png)) |
| AC7 CI green + scope | ✅ | 6/6 check runs success ([00](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/00-ci-checks.png ````````````)). The dot map shows 65 chars = 65 ids, both `s` on the known skip-capable tests, #38–#41 `.` ([04](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/04-AC7-ci-dotmap.png `````````````)). `git diff origin/main --name-only` = `tests/test_verify.py` ([01](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/01-AC7-scope-ownership.png)) `````````````` |
| Docs: none | ✅ | No behaviour/command change |

**Scope.** One file, +127/−31. The AST compare of every top-level def, main vs head ([01](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/01-AC7-scope-ownership.png)): ``````````````` 20 unchanged, 6 added (2 helpers, `_NoEmbedder`, 3 tests), 1 changed: `test_embed_is_not_serialized_…`, which the ticket allows to move onto the helper. Its asserts compare the same values (`not t.is_alive()` → `not out["alive"]`, taken after the join; join timeout 5 s → 10 s). No production file touched.

## PRD fit
Every `/v1/ask` calls `/internal/rerank` and `/internal/verify`, and an ING-4 ingest holds `_ingest_lock` for 30–80 s. If either endpoint were serialized behind that lock, the §8 `/v1/ask` p95 < 3 s target would break without anyone noticing. These tests pin both endpoints, and both rerank paths. The proof is mutants that fail on head and survive on main's tests.

## Findings
None blocking.
1. [nit] (observation only) If an endpoint regression hangs, the daemon `run_call` thread stays blocked after the test ([08](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/fd4b8f1edff4daaa527aad9241082489eca89ed2/agents/reviews/AI-15/evidence/08-AC4-leak-probe.png ````````````````)). AC4 requires only that the ingest thread be joined, and that holds. Python threads can't be killed.

## Missing tests
- None required. Possible later rows: empty inputs and the `503 not ready` branches during an ingest.

## Limits
Real-torch results come from CI only. Local runs and mutants used a stub harness, which is valid here because these tests monkeypatch every model call.

## Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

## PM final review (pm-lead) · 2026-11-21

**Verdict: APPROVE** · reviewed head `7699ccad5cc7283bde20037781fa4f0eea7e4dd9` against QA r1 PASS and evidence at `fd4b8f1`.

- **PRD fit.** ING-4 ingests hold `_ingest_lock` for 30–80 s, and every `/v1/ask` calls `/internal/rerank` and `/internal/verify`. The Product PRD §8 target `/v1/ask` p95 < 3 s depends on neither endpoint waiting on that lock. Before this PR, nothing pinned it for these two endpoints. Now both rerank paths and verify are pinned. The proof is evidence 05 (m1–m4 plus QA's q5 and q6: each kills only its own test) set against evidence 06 (the same mutants all survive main's tests). This is a pure regression guard and adds no new requirement.
- **Scope.** One file, `tests/test_verify.py`, +127/−31 (158 lines, inside the 80–150 target plus helper refactor, well under the 250 stop). Evidence 01 shows the AST compare: 20 defs unchanged, 6 added, 1 changed. The changed one is the embed test moved onto the helper as the ticket allows, and I read its diff: the same values are compared. The ingest join timeout went from 5 s to 10 s as AC4 asked. No production file was touched.
- **AC coverage. I opened every evidence file I rely on (00, 01, 02, 04, 05, 06, 07, 08, 09 PNG and txt; 03 and 10 txt).**
  AC1–AC3: I read the diff, and the asserts match the ticket text, including the sentinel `is` checks and `calls == [(["q"], True, True), (["a","b"], False, True)]`. CI dot map (04) has #39–#41 as `.` in the real-torch job.
  AC4: `finally: t.join(timeout=10)`, endpoint `join(timeout=5)`, and every test asserts ingest `status == "success"`. 08 shows a regressed test fails in 1.3 s with 0 threads left, and a hung endpoint fails in 5.3 s instead of hanging. 07 shows 20/20 runs green under CPU load.
  AC5: 05 and 06 as above, each run ≈5 s, under the 30 s limit.
  AC6: 02 shows 3 pre-existing E501, identical on main, and 0 on added lines.
  AC7: 00 shows all 6 checks success at head. 09 shows `make test-py-ml` going from 60 to 63 passed on the same base `11c4696`.
- The developer added `_NoEmbedder` to the AC1 test beyond the letter of the spec. Without it, m4 can't be detected (the fixture sets `embedder = None`), so it is needed to meet AC5(m4) and is in scope. I'll note it for spec-writing (lessons).
- **Docs.** None needed. The PRD status is unchanged (ING-4 already ✅, and this is test-only).
- **Accepted limits.** Local and mutant runs used a stub harness (no torch in the sandbox). That is acceptable because these tests monkeypatch every model call, and CI (real torch) is the source of truth for green. QA nit 1 (a hung endpoint's daemon `run_call` thread outlives the test) is outside AC4, which requires only the ingest thread to be joined, and Python threads can't be killed. No follow-up.
- **Report formatting.** Several evidence links in the QA section above have stray backtick runs from the PR-comment copy. The URLs themselves are correct. I'm leaving the section verbatim as the record.

Next: PR #117 description rewritten with Evidence, marked ready for review → Jira KAN-123 Ready to merge. Merge is Mahesh's call.
