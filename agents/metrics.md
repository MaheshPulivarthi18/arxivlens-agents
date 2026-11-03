# Team metrics

One row per sprint cycle, appended by `/sprint` Step 8. `/retro` compares the last 5 rows.

- **Attempted**: tasks picked this cycle
- **Shipped**: PRs opened with pm-lead APPROVE
- **First-pass**: shipped tasks that passed verification and review with zero fix rounds
- **Fix rounds**: total verify-fail + review-CHANGES rounds
- **Blocked**: tasks moved to Blocked this cycle
- **Merged since last**: agent PRs merged by the human since the previous cycle (the real throughput)
- **Awaiting human**: open agent PRs + Proposed ADRs

Targets once the harness is stable: first-pass ≥ 70%, blocked ≤ 1 per cycle, merged ≈ shipped.

| Date | Attempted | Shipped | First-pass | Fix rounds | Blocked | Merged since last | Awaiting human | Notes |
|---|---|---|---|---|---|---|---|---|
| 2026-11-01 | 0 | 0 | — | 0 | 0 | 0 | 5 ADRs | Setup, baseline |
| 2026-11-01 | 2 | 2 | 0% (0/2) | 2 | 0 | 0 | 2 PRs + 9 ADRs | Cycle 1. Both tasks needed 1 review fix round. Sandbox egress blocked Go/npm/Docker/HF, so only Python and docs tasks were possible; Go and frontend checks rely on CI. |
| 2026-11-02 | 1 new + 2 reviews | 2 (PM-1, OPS-H3) | 100% (1/1 new: OPS-H3) | 2 (EVAL-1: human-review rework + QA FAIL) | 1 (EVAL-1) | 0 | 3 PRs (#2 blocked, #3, #6) + record PR + 9 ADRs | QA pass rate this cycle 2/3 (OPS-H3 r1 PASS, PM-1 r2 PASS, EVAL-1 r2 FAIL); first-round PASS 1/1. A human review overturned an APPROVE (EVAL-1). Only Go-in-CI work was feasible (no Go 1.25/npm/Docker/HF). |
| 2026-11-03 | 0 new + 1 review (RET-1 PM) | 1 (RET-1 raised) | — (no new tasks) | 0 | 0 | 0 | 2 PRs ready (#2, #9) + docs PR agents#2 + ADR-0001..0005, 0007..0009 | No human reviews/comments since last agent commits. RET-1 QA r1 PASS (prior session) → PM APPROVE r1; QA pass rate 1/1 first-round. No new tasks: ai-engineer (#2) and backend-engineer (#9) at WIP limit; frontend FE-1 needs npm, registry.npmjs.org still unreachable (also Go 1.25 toolchain, HF blocked). |
| 2026-11-03 (2) | 1 new (AI-1) + 1 docs PR | 1 (AI-1 raised, #10) | 100% (1/1) | 0 | 1 (AI-5, needs ADR-0011) | 1 (EVAL-1 #2) | 2 code PRs ready (#9, #10) + 2 docs PRs (agents#2, #3) + ADR-0001..0005, 0007..0009, 0011 | QA pass rate 1/1 first-round. No human reviews to pick up. Backend at WIP (#9); frontend needs npm (blocked). |
| 2026-11-03 (3) | 0 | 0 | — | 0 | 0 | 0 | 2 code PRs ready (#9, #10) + 3 agents PRs (#2, #3, #4) + ADR-0001..0005, 0007..0009, 0011 | No-op cycle: no human reviews, nothing to QA/PM, ai/backend at WIP limit, frontend blocked on npm egress. |
| 2026-11-03 (4) | 2 new (AI-2, OPS-H4) | 2 (AI-2 #11, OPS-H4 #12 raised) | 50% (1/2: AI-2) | 1 (OPS-H4 PM CHANGES r1, spec fault) | 0 | 1 (RET-1 #9) | 2 code PRs ready (#11, #12) + docs PR agents#5 + ADR-0001..0005, 0007..0009, 0011 | QA pass rate 2/2 first-round (3/3 reviews PASS); PM first-pass 1/2. No human reviews to pick up. Same egress limits (Go 1.25, npm, HF, Docker Hub); Go verified in CI. |
| 2026-11-03 (5) | 0 | 0 | — | 0 | 0 | 0 | 2 code PRs ready (#11, #12) + ADR-0001..0005, 0007..0009, 0011 | No-op cycle: no human reviews, nothing to QA/PM, ai/backend at WIP limit, frontend blocked on npm egress. |
