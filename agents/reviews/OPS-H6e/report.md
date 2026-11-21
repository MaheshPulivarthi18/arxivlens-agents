> Provenance: saved verbatim by the orchestrator (cycle 2026-11-21T05:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/106#issuecomment-7058178117 (QA harness refuses to write report.md).

[qa-reviewer] QA report — OPS-H6e · PR #106 · round 1

**Verdict: PENDING.** Reviewed `f1b156e` (CI merge `c92184f` = head into main `11c4696`) · 2026-11-21 · Ticket [agents/tasks/OPS-H6e.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/tasks/OPS-H6e.md) (KAN-108) · PRD OPS-3, Tech PRD §8.1 L3
Evidence folder: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence

> The QA harness refused to write `agents/reviews/OPS-H6e/report.md` (subagents may not write report files), so this comment is the full report. The orchestrator should save it verbatim with a provenance note. The evidence is committed in arxivlens-agents `86f7f7f6658ec24b3b6daad85907ebb7a08706de`.

PENDING, not FAIL: everything I could check is correct, and every AC except AC5 has evidence. **AC5** (real-PG test green in `Full stack`, quoted from `-rA`) and the Full stack part of **AC7** have no CI result. Both attempts of run 44870497705 (jobs 136743706973, 136746049463) failed in step 11 "Prefetch arXiv responses into the replay store" after 8/8 arXiv `429`s. That is before compose, migrate or `make test-full`. Step 23 was skipped, and `test_chunk_reprocess_db` appears 0 times in either log ([02](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/02-AC5-AC7-fullstack-infra-failure.png)). `` It's an infra failure, not a product failure.

### Test results
| Check | Source | Result |
|---|---|---|
| Go | CI 136743707273 | pass ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/00-ci-checks.png)) |
| Python M0 unit tests | CI 136743707091 | pass: `test_m0/test_verify/test_processor_pages` step **66 passed**, 2 skipped vs **60**/2 on main `11c4696` (job 136736533291), i.e. exactly the 6 new tests ([03](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/03-AC1-AC4-ci-unit-count.png)) ``` |
| Frontend / DB | CI | pass |
| Agent ownership check | CI 136743707272 | `Ownership OK for role=backend (197 changed lines)` ([01](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/01-scope-ownership.png ````)) |
| Full stack | CI run 44870497705 ×2 | **failure, infra** (arXiv 429 in prefetch, no tests ran) ([02](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/02-AC5-AC7-fullstack-infra-failure.png)) ````` |
| pytest `tests/test_processor_pages.py` | local, heavy deps stubbed | 15 passed (6 new + 9 existing `save_chunks`) ([04](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/04-AC1-AC4-local-unit.png)) `````` |
| ruff E,F,W 130 | local | 2 findings, identical on `origin/main`, on unchanged lines (db.py:1, test_processor_pages.py:212). None on added lines ([07](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/07-AC7-ruff-head-vs-base.png)) ``````` |
| `git diff --name-only` | local | exactly the 3 allowed files ([01](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/01-scope-ownership.png ````````)) |
| Real DB test | not run locally | no psycopg / pgvector in the sandbox. Replaced by a real **PostgreSQL 16** probe of the PR's own statements ([05](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/05-AC2-AC4-real-pg-probe.png)), ````````` not a substitute for AC5 |
| `make eval` | not run | write path only, and the new branch is unused until the worker follow-up |

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | 3-tuple SQL/params pinned to a literal copy of main's. Base control: the PR tests on main's db.py, where only the 4-tuple tests fail ([06](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/06-AC6-mutants.png ``````````) row `base`). M3a/M3b/M8 killed. Existing tests green ([04](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/04-AC1-AC4-local-unit.png), ``````````` [03](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/03-AC1-AC4-ci-unit-count.png)) ```````````` |
| AC2 | ✅ · ⚠ CI real-PG pending | PG16: insert `INSERT 0 1`, then update-on-conflict `INSERT 0 1`, vector updated ([05](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/05-AC2-AC4-real-pg-probe.png)). ````````````` M10 (DO NOTHING) killed |
| AC3 | ✅ · ⚠ CI pending | PG16: `INSERT 0 0`, existing `[kept]` row untouched. Concurrent new-hash UPDATE: embedder waits 1.3 s, then writes 0 rows ([05](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/05-AC2-AC4-real-pg-probe.png)). `````````````` M1 killed |
| AC4 | ✅ · ⚠ CI pending | PG16: tail-deleted chunk gives `INSERT 0 0`, and the txn is still usable. Control: the unguarded statement gives `violates foreign key constraint "chunk_embeddings_chunk_id_fkey"` and then `current transaction is aborted`. Concurrent DELETE: 0 rows, no error ([05](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/05-AC2-AC4-real-pg-probe.png)). ``````````````` M2 killed |
| AC5 | ⚠ **unverified (PENDING)** | Full stack never reached `AC4: make test-full` ([02](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/02-AC5-AC7-fullstack-infra-failure.png)). ```````````````` Test reviewed: AC2-AC4 + mixed batch on the module's rolled-back conn |
| AC6 | ✅ | 10 mutants + base control, all KILLED by the PR's unit tests: no-hash, no-existence, 3-tuple via hash path, 3-tuples rejected, count-all, no FOR SHARE, no length check, param swap, 3-tuple rowcount, hash-only lookup, DO NOTHING ([06](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/06-AC6-mutants.png `````````````````)). Local `mktemp -d` copies, never pushed |
| AC7 | ⚠ partial | Python M0, Go and ownership green. Ruff clean on added lines. Full stack has no result |
| Docs | ✅ | none changed |

### PRD fit
Serves OPS-3 / L3: once the worker passes the hash, a vector computed from text that changed or was deleted mid-run is dropped instead of being kept for good or failing the message. Backward compatible, so production 3-tuples behave exactly as on main.

### Findings
1. [spec] (pm-lead) AC5/AC7 can't be evidenced while arXiv rate-limits this uncached branch. The replay cache is branch-scoped (`Cache not found … arxiv-replay-Linux-stack-v1-`), so each attempt prefetches from live arXiv and got 8/8 `429`. Re-run `Full stack` later. Round 2 then only needs the `-rA` line for `test_chunk_reprocess_db.py::test_save_embeddings_only_for_current_chunk_text`. No code change needed.
2. [spec] (pm-lead, backend follow-up) **The residual race is real on PG16** ([05](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/05-AC2-AC4-real-pg-probe.png), `````````````````` last block). In `save_sections_and_chunks`' order (stale-vector DELETE → chunk UPSERT), an embedder insert that lands between them keeps the old text's vector under the new hash (`final: hb-new|m|[0.500000]`). The developer disclosed it, and it's out of this ticket's scope, but it's the same symptom as Goal race 1. Suggested follow-up: lock the chunk row (`SELECT … FOR UPDATE`) before deleting its vectors. The PR body's "Follow-ups created: none" should list this and the ai-engineer worker follow-up.
3. [nit] `FOR SHARE OF pc` is pinned only by the exact SQL string. The real-PG test is single-session and would pass without it. The two-session probe shows that dropping it really changes behaviour (R1 writes a stale vector, R2 errors). A two-connection real-PG test would guard the behaviour.

### Missing tests
- Two-session real-PG test (finding 3).
- A real-PG row with a duplicate `content_hash` on another paper. The mutant "look up by hash only, without `pc.id`" is invisible to the real-PG fixture (all hashes unique) and is killed only by the SQL-string test.

### Evidence (commit-pinned)
[00 CI checks](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/00-ci-checks.png) · [01 scope/ownership](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/01-scope-ownership.png ```````````````````) · [02 Full stack infra failure](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/02-AC5-AC7-fullstack-infra-failure.png) ```````````````````` · [03 CI unit count](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/03-AC1-AC4-ci-unit-count.png) ````````````````````` · [04 local unit](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/04-AC1-AC4-local-unit.png) `````````````````````` · [05 real-PG probe](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/05-AC2-AC4-real-pg-probe.png) ``````````````````````` · [06 mutants](```````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/06-AC6-mutants.png ````````````````````````) · [07 ruff](````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/07-AC7-ruff-head-vs-base.png) ````````````````````````` · [08 harness sources](`````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/86f7f7f6658ec24b3b6daad85907ebb7a08706de/agents/reviews/OPS-H6e/evidence/08-harness-sources.png ``````````````````````````). Each has a `.txt` with the full output. The probe uses sandbox PostgreSQL 16.15 with `halfvec` as a text DOMAIN, because pgvector can't be built here.

### Hand-off
PENDING → re-review next cycle once a `Full stack` run on this head reaches `AC4: make test-full`. If it's green with the new test in the `-rA` summary and nothing else changes, round 2 is expected to PASS. Findings 2-3 don't block.


---
_Generated by [Claude Code](https://claude.ai/code)_

---

# QA report — OPS-H6e · PR #106 · round 2

**Verdict:** PASS
**Reviewed commit:** `f1b156ec66ed0005003c8ce69304122172b43974` (unchanged since round 1; CI merge `c92184f` = head into main `11c4696`, which is still ArxivLens `main`) · **Date:** 2026-11-21
**Ticket:** `agents/tasks/OPS-H6e.md` (KAN-108) · **PRD:** Product OPS-3, Technical §8.1 L3
**Evidence folder:** https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence

Round 1 was PENDING only because `Full stack` had not reached `AC4: make test-full` (arXiv 429s in the prefetch step). The head hasn't changed, so this round only re-checks AC5 and AC7 against the new CI run. Everything else carries over from round 1.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 136743707273 | success ([09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/09-r2-ci-checks.png)) |
| Python M0 unit tests | CI job 136743707091 | success ([09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/09-r2-ci-checks.png)) |
| Frontend (lint, test, build) | CI job 136743707292 | success |
| DB (migrate twice, HNSW plan + recall) | CI job 136743707170 | success |
| Agent ownership check | CI job 136743707272 | success |
| Full stack (compose + make test-full) | CI run 44870497705 attempt 3, job 136768749810 | **success**. `head_sha=f1b156e`, checkout `HEAD is now at c92184f Merge f1b156e… into 11c4696…`. Steps 1-26 and 28-29 succeeded and step 27 (Diagnostics) was skipped ([10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/10-r2-AC7-fullstack-steps.png)) |
| `AC4: make test-full` (`-rA`) | same job, log l.3095-3375 | `278 passed, 1 skipped, 3 deselected`, and no `FAILED`/`ERROR tests/` result line ([11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/11-r2-AC5-test-full-rA.png)) |
| Known failure F1 (step 24) | same job | `continue-on-error` step, runs only the 3 F1-deselected `test_m3_query` tests (CPU rerank latency, tracked in OPS-H1). 2 failed with a 10 s ReadTimeout, as expected on CPU. This PR doesn't touch them ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/12-r2-known-f1-step.png)) |
| Ticket verification commands | local (round 1) | unchanged head, see round-1 evidence 01, 04, 05, 06, 07 |
| `make eval` | not run | write path only, and the 4-tuple branch is unused until the ai-engineer worker follow-up |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | round 1 (03, 04, 06). AC4 step also green on the merge commit ([11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/11-r2-AC5-test-full-rA.png)) |
| AC2 | ✅ | round 1 PG16 probe (05) + mutant M10 (06). Now also covered by the real-PG CI test below |
| AC3 | ✅ | round 1 (05, 06 M1) + the real-PG CI test below |
| AC4 | ✅ | round 1 (05, 06 M2) + the real-PG CI test below |
| AC5 | ✅ | `Full stack` run **44870497705** (attempt 3, job 136768749810), `-rA` summary, log line 3106: `PASSED tests/test_chunk_reprocess_db.py::test_save_embeddings_only_for_current_chunk_text`. The existing `test_reprocess_drops_stale_vectors_and_tail` also PASSED (l.3105) ([11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/11-r2-AC5-test-full-rA.png)) |
| AC6 | ✅ | round 1 (06): 10 mutants + base control, all killed |
| AC7 | ✅ | All 6 check runs on `f1b156e` completed/success, including `Python M0 unit tests`, `Go`, `Agent ownership check` and `Full stack` ([09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/09-r2-ci-checks.png)). Ruff is clean on added lines (round 1, 07) |
| Docs | ✅ | none changed |

## PRD fit
Same as round 1: once the worker passes the hash, a vector computed from chunk text that changed or was deleted mid-run is dropped instead of being kept for good or failing the message (OPS-3, L3). 3-tuple callers (all of production today) behave exactly as on `main`.

## Findings
1. [spec] (pm-lead, backend follow-up) Round-1 finding 2 still stands and is not blocking. The processor-side residual race (embedder insert between the stale-vector DELETE and the chunk UPSERT in `save_sections_and_chunks`) is real on PG16 (round-1 evidence 05, last block). It needs a follow-up ticket. The PR body's "Follow-ups created: none" should list that ticket and the ai-engineer worker follow-up.
2. [nit] Round-1 finding 3 still stands: `FOR SHARE OF pc` is pinned only by the SQL-string test. A two-connection real-PG test would guard the behaviour.
3. Round-1 finding 1 (Full stack never ran) is **resolved** by run 44870497705 attempt 3.

## Missing tests
- Two-session real-PG test for the `FOR SHARE` lock (nit 2).
- A real-PG fixture row with a duplicate `content_hash` on another paper (the "look up by hash only" mutant is killed only by the SQL-string test).

## Evidence (round 2, commit-pinned)
[09 CI checks](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/09-r2-ci-checks.png) · [10 Full stack steps](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/10-r2-AC7-fullstack-steps.png) · [11 AC5 -rA summary](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/11-r2-AC5-test-full-rA.png) · [12 Known failure F1 step](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/07688d0ed28558e734e34f0e19355e72fccc9c0e/agents/reviews/OPS-H6e/evidence/12-r2-known-f1-step.png). Each has a `.txt` with the full output, rendered by `agents/tools/render_evidence.py` from live `gh api` output at app HEAD `f1b156e`.

## Hand-off
PASS → pm-lead final review. The PR description should quote AC5's `-rA` line with run ID 44870497705 and list the two follow-ups (finding 1).
