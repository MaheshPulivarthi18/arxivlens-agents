# Progress log

Append-only. Newest entry first. One entry per task per cycle. Agents read the top 20.

Format:
```
## YYYY-MM-DD — <TASK-ID> — <outcome: shipped | blocked | in review | changes requested>
- Agent: <role> · Attempts: <n> · Review rounds: <n> · PR: <link or —>
- Summary: <one or two lines>
- Blockers / follow-ups: <or —>
```

---

## 2026-11-03 — sprint cycle — no new tasks
- Agent: orchestrator · Attempts: — · PR: — · Jira: KAN-24 → Ready to merge (description PR link + pm-lead comment)
- Summary: push access verified. No human review or untagged comment on #2/#9 or Jira since the last agent commits. Only queued work was RET-1 PM review (APPROVE, see entry below). No new task: ai-engineer and backend-engineer each have one open PR; FE-1 needs npm, still unreachable.
- Blockers / follow-ups: Mahesh to review/merge #2 then #9 (re-run #9 CI after #2), then arxivlens-agents#2.

## 2026-11-03 — RET-1 — in review
- Agent: backend-engineer (build), qa-reviewer, pm-lead · Attempts: 1 · Review rounds: QA 1 (PASS) · PM 1 (APPROVE) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/9 · Jira KAN-24
- Summary: `search.go` reranks a `max(20, limit)` RRF pool in one call, stable-sorts by rerank score and truncates. It falls back to RRF order with a trace-ID log and no content in the log. `rerank=false`, the SQL and the errors are unchanged. 391 lines, CI 4/4 green, 17/17 QA mutants caught. Raised for review with evidence in the description.
- Blockers / follow-ups: merge after #2. The p95/eval measurement is deferred to EVAL-2 AC10 (PM decision). The §7.1 diagram docs PR merges after #9. After #9: AGENTS.md §6 gotcha rules PR. Backend nits: `context.Canceled` and `±Inf` tests.

## 2026-11-02 — RET-1 — design approved
- Agent: pm-lead · Attempts: 1 · Review rounds: 0 (design gate) · PR: —
- Summary: Approved `docs/design/RET-1.md` with 8 binding conditions (SQL literal stays identical in `search.go`, no extra `LIMIT 50` text; run EVAL-1's parity test against the branch and paste output; no OTel import; unexported trace-ID helpers; grep-able log; error messages unchanged). Checked the parity test concretely: the refactor keeps it green, but a stray `LIMIT 50` comment breaks it and a moved file passes silently.
- Blockers / follow-ups: AI-4 (ai-engineer, P2, blocked on RET-1 + EVAL-1 merge). AC7 PRD §7.1 diagram docs PR by pm-lead at final review.

## 2026-11-02 — EVAL-1 — in review (ready to merge)
- Agent: ai-engineer (build) · pm-lead (review) · Attempts: 3 · QA rounds: 3 (PASS → FAIL → PASS) · PM rounds: 2 (APPROVE overturned by human review → APPROVE) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/2 · Jira KAN-8
- Summary: all 4 items from Mahesh's review closed at `d83a4c0`: paper-level Recall@5 (ADR-0006), production cross-encoder in the ADR-0010 ordering, per-paper/per-model coverage, KAN-8 linked in place of an issue. pm-lead rewrote the PR body (resolution table + evidence pinned to `b9059b2`), marked it ready, and labelled it `ready-to-merge`.
- Blockers / follow-ups: no live baseline yet (Mahesh's first run). OPS-H4 (AC5 + CI for the 47 tests), RET-1 (production ordering), EVAL-2 re-scoped with QA r3 nits as AC6–AC9, and a pm-lead PRD §8 docs PR after merge.

## 2026-11-02 — EVAL-1 — in QA (round 3)
- Agent: ai-engineer · Attempts: 3 · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/2 (draft, head `d83a4c0`) · Jira KAN-8 (not touched this session)
- Summary: paper-level Recall@5 (ADR-0006) gated, chunk_precision@5 diagnostic only. Gated mode follows ADR-0010 (search.go SQL pool of 20, one cross-encoder call, stable sort, top 5). Coverage requires embeddings for the current model. Tests check /healthz runs before any rerank. 47 tests pass; 17/17 mutants killed.
- Blockers / follow-ups: no live eval (no infra); production matches the gate only after RET-1. RET-1 must keep `test_rrf_pool_sql_mirrors_search_go` in sync. R3-7/R3-8 pm-lead. Diff is over 400 lines.

## 2026-11-02 — OPS-H3 + REPO-SPLIT — merged
- Agent: orchestrator, at Mahesh's request ("review thoroughly and merge") · PRs: ArxivLens #8 → 18a3cf9, #6 → 72c82ac (both squash)
- Summary: two fresh-context reviewers ran in parallel. #8: MERGE WITH FOLLOW-UPS. The rename bypass, empty-diff exit,
  nested AGENTS/CLAUDE files, `.env.example`, `services/embedder/*.py` and CONTRIBUTING inaccuracies were all fixed in the
  PR before merge and re-tested. #6: MERGE WITH FOLLOW-UPS. Behaviour preservation was proved with an old-vs-new
  equivalence test, and the PR description's evidence table was repaired. ArxivLens `main` is now code-only.
- Blockers / follow-ups: OPS-H3 follow-ups and #8 nits are in the board backlog; EVAL-1 (#2) is still in rework round 3 via the sprint.

## 2026-11-02 — REPO-SPLIT + EVAL-1 review triage — shipped
- Agent: orchestrator (with Mahesh in chat) · PR: ArxivLens cleanup PR (see board) · arxivlens-agents first commit
- Summary: Mahesh approved splitting the repos. arxivlens-agents now holds PRDs, ADRs, designs, tickets, board, QA
  evidence and agent rules; ArxivLens keeps code, tests, evals and CI. Mahesh's review of PR #2 was triaged. He decided
  ADR-0006 (paper-level Recall@5 gated, chunk precision@5 as a diagnostic) and ADR-0010 (production reranks a pool and
  sorts by rerank score). EVAL-1 is unblocked with a round-3 checklist, and RET-1 is created for the production change.
- Blockers / follow-ups: EVAL-1 round 3 (ai-engineer) → QA r3 → PM → raise; RET-1 needs design first.

## 2026-11-02 — OPS-H3 — in review (ready to merge)
- Agent: backend-engineer · Attempts: 1 · QA rounds: 1 (PASS) · PM rounds: 1 (APPROVE) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/6 · Jira KAN-15
- Summary: first Go tests in the repo: `ExtractCleanArxivID` (14 cases), `parseAtomFeed` extracted + fixture test (ING-7 version split), `retryBackoff` extracted + 200/400 ms test. pm-lead fixed the spec before build (it described behaviour the code doesn't have). CI green on Go 1.25.
- Blockers / follow-ups: F1 `go test -cover` in CI, F2 more pinning tests, F3 old-style arXiv IDs (product decision).

## 2026-11-02 — PM-1 — in review (ready to merge)
- Agent: pm-lead · Attempts: 1 · QA rounds: 2 (FAIL → PASS) · PM rounds: 1 (APPROVE, self-review caveat) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/3 · Jira KAN-21
- Summary: QA round 2 confirmed the QA-4 truthfulness fix; all ACs hold. Raised for review with evidence in the description.
- Blockers / follow-ups: merge after #2. Next PM docs pass: PM-1 AC1 prose, AI-2 AC5 (restore QA-4 ✅), bump §6 verified date.

## 2026-11-02 — EVAL-1 — blocked
- Agent: ai-engineer · Attempts: 2 · QA rounds: 2 (PASS → FAIL) · PM rounds: 1 (APPROVE, overturned by human review) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/2 · Jira KAN-8
- Summary: Mahesh's review found 2 blockers + 1 major after it was raised. Rework f750bb9: gated rerank mode now calls production `/internal/rerank` (fails closed), per-paper coverage. QA r2 FAIL: Recall@5 definition still precision@5-like (needs ADR-0006) and `/v1/ask` never sorts by rerank score, so the gate still ≠ user ordering.
- Blockers / follow-ups: Mahesh decides ADR-0006 and the rerank-ordering question. EVAL-2 needs re-scoping. Commits f750bb9/4f888fb (and PM-1 830fe69/b5c733f) carry a stale Claude-Session trailer (cosmetic).

## 2026-11-02 — board-2026-11-01 record (PR #4) — superseded
- Agent: orchestrator · Its commit is carried into this cycle's record branch; PR #4 is superseded by #7; Mahesh can close it without merging (the agent was not allowed to close PRs).

## 2026-11-01 — PM-1 — in review
- Agent: pm-lead · Attempts: 1 · Review rounds: 2 (CHANGES → APPROVE) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/3
- Summary: PRD §6 acceptance column (UI-5 → ◐), §8 metrics → evals/ + `make eval`, §9 concrete reference hardware (Proposed), all open questions → ADRs; new Proposed ADR-0006..0009; specs OPS-H4, OPS-H5, AI-2, AI-3, EVAL-2.
- Blockers / follow-ups: review caught an unlabelled gating policy in §9 (now Proposed). Mahesh to decide §9 + ADR-0006..0009. After PR #2 merges remove AGENTS.md §5 eval gotcha.

## 2026-11-01 — EVAL-1 — in review
- Agent: ai-engineer · Attempts: 1 · Review rounds: 2 (CHANGES → APPROVE) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/2
- Summary: evals/ datasets (34 retrieval / 22 answer / 22 refusal, 31-paper corpus), thresholds = PRD §8, `scripts/eval_gate.py` (fails closed), dataset-driven `evaluate_retrieval.py`, stdlib `evaluate_answers.py`, 20 no-infra tests.
- Blockers / follow-ups: review caught failed /v1/ask calls not affecting gated metrics (fixed). No live baseline (no infra in sandbox) — Mahesh to run. AC5 `.gitignore` → OPS-H4. make test-unit/lint only verifiable in CI this cycle.

## 2026-11-01 — SETUP — shipped
- Agent: human + setup · Attempts: 1 · Review rounds: 0 · PR: (this PR)
- Summary: Added agent team (4 roles), memory layout (`agents/`), ADRs 0001–0005 as Proposed, initial backlog of 10 tasks, Makefile harness, CI.
- Blockers / follow-ups: Human to decide ADR-0001..0005. QA-8 waits on ADR-0001/0002.

## 2026-11-03 09:15 IST — orchestrator (interactive)
- EVAL-1: PR #2 squash-merged at Mahesh's request after a final check (CI 4/4 green, 47 eval tests pass locally, no workspace files or secrets in the diff) → `a959d03`. Jira KAN-8 → Done. Unblocks the RET-1 (#9) merge, OPS-H4 and AI-4.
- Scheduled sprint task recreated with both repos attached (old one could not push to arxivlens-agents); old task disabled.

## 2026-11-03 — AI-1 — ready to merge
- Agent: pm-lead · PM rounds: 1 (APPROVE) · QA rounds: 1 (PASS) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/10 (raised, ready for review) · head `f56f80b`
- Summary: Final review of `rag.go` unit tests + splitter abbreviation fix. All 9 evidence files checked; CI 4/4 green; `rag.go` 97.9% (scratch, identical files), 25/25 mutants killed. QA finding 4 → ADR-0011 (Proposed) + AI-5 (Blocked on ADR-0011). Splitter note added to QA-8. pm-lead lesson on naming per-file coverage measurement.
- Blockers / follow-ups: Mahesh decides ADR-0011. Product PRD QA-5 → ◐ in the next pm-lead docs PR.

## 2026-11-03 (scheduled cycle 2) — orchestrator
- Sync: no human reviews/comments on open agent PRs (#9) or docs PR agents#2 since the last agent commits; no Jira intake or untagged comments. RET-1 #9 stays Ready to merge (base predates a959d03; GitHub reports mergeable clean).
- AI-1 (ai-engineer, KAN-9): built on `agent/ai/AI-1` → draft PR #10 (`f56f80b`), CI 4/4 green → QA r1 PASS (evidence `0e35400`) → PM r1 APPROVE → raised (ready for review, label `ready-to-merge`). Attempts 1, QA rounds 1, PM rounds 1. Splitter abbreviation bug fixed (≤20 lines). Jira KAN-9 → Ready to merge.
- Docs: pm-lead opened [arxivlens-agents#3](https://github.com/MaheshPulivarthi18/arxivlens-agents/pull/3) (Product PRD §8 after EVAL-1 merge, ADR-0006 paper-level, RET-1 caveat).
- New: ADR-0011 (Proposed) + AI-5 Blocked on it; Jira KAN-25 (story) and KAN-26 (human decision).
- Env unchanged: Go 1.24.7 local, proxy.golang.org / npm / HF / Docker Hub unreachable; Go verified in CI + stdlib-only scratch copy.
- qa-reviewer's harness again blocked writing `report.md`; orchestrator saved it verbatim from the PR comment (`1afa69f`).


## 2026-11-03 (scheduled cycle 3) — orchestrator — no-op
- Sync: open agent PRs ArxivLens #9 (RET-1, `831905e`) and #10 (AI-1, `f56f80b`) are ready for review, mergeable clean, QA PASS + PM APPROVE for their current heads; no reviews or untagged comments from Mahesh. Docs/rules PRs agents#2, #3, #4: no human activity. Jira: no issue updated since cycle 2, no intake, no untagged comments. No ADR status changed (0006, 0010 Accepted; rest Proposed).
- No rework, no review queue. No new task: ai-engineer (#10) and backend-engineer (#9) at WIP limit; FE-1 still needs registry.npmjs.org (unreachable, as are proxy.golang.org, huggingface.co, Docker Hub). Nothing invented.

## 2026-11-03 — AI-1 — done
- PR #10 merged by Mahesh as `4702daa`; Jira KAN-9 → Done. AI-2 now has its dependency met (Ready next cycle).

## 2026-11-03 — retro rules PR — merged
- arxivlens-agents#4 (orchestrator saves QA `report.md` when the QA harness can't) merged by Mahesh; lesson promoted into `.claude/agents/qa-reviewer.md` + `sprint.md` Step 5 and removed from `lessons.md`.

## 2026-11-03 — PRD §8 docs PR — merged
- arxivlens-agents#3 (Product PRD §8 after EVAL-1, ADR-0006 paper-level, RET-1 caveat) merged by Mahesh; backlog item removed. Row-156 RET-1 caveat comes out when ArxivLens #9 merges.

## 2026-11-03 — pm-lead — grooming after RET-1 / AI-1 merges
- RET-1 → Done (ArxivLens #9, `bb9ee90`). AI-2, OPS-H4, AI-4 → Ready (deps met); stale line refs refreshed against `bb9ee90` (AI-2: fail-open now `rag.go:182-184`, and AI-1's `TestValidateCitationsFallbackWhenUnverifiable` must be flipped, not kept). AI-4 goes after AI-2 (same files); needs a Jira story.
- Cycle picks: AI-2 (ai-engineer, P1) and OPS-H4 (backend-engineer, P1).
- Docs PR arxivlens-agents#5 drops the AGENTS.md §6 "does not yet sort by rerank score" gotcha and the Product PRD row-156 RET-1 caveat.

## 2026-11-03 (scheduled cycle 4) — orchestrator
- Setup: both repos attached, push to arxivlens-agents verified (`push --dry-run`), app cloned at `app/`. Task branches built in git worktrees outside the team repo so two developers/QA could run in parallel.
- Sync: ArxivLens #9 (RET-1) merged → Done, Jira KAN-24 → Done. No open agent PRs, no human reviews/comments on any PR, no Jira intake or untagged comments. No ADR status change. AI-4 unblocked (Jira story KAN-27 created; it had none).
- pm-lead: groomed (AI-2, AI-4, OPS-H4 → Ready; RET-1 → Done; stale line refs fixed) and opened docs PR [arxivlens-agents#5](https://github.com/MaheshPulivarthi18/arxivlens-agents/pull/5) (post-RET-1 AGENTS.md §6 gotcha + PRD row 156).

## 2026-11-03 — AI-2 — ready to merge
- Agent: ai-engineer · Attempts: 1 · QA rounds: 1 (PASS) · PM rounds: 1 (APPROVE) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/11 (ready for review, `ready-to-merge`) · head `c9ae07c` · Jira KAN-10 → Ready to merge
- Summary: unverifiable citations are now unsupported with score 0 (was supported 0.75); one count-only log line per request. 7 fail-closed cases; new test fails on old `rag.go`; 14/16 mutants killed. CI 4/4 green. `make eval` not run (no infra).
- Blockers / follow-ups: QA nits → backlog (log-counter asserts, mixed test, dim mismatch). After merge: PRD QA-4 docs PR; FE-1 "Verified" badge note. ADR-0003 still decides behaviour when all citations are unsupported. qa-reviewer harness again couldn't write `report.md`; orchestrator saved it verbatim from the PR comment (`e8b28d0`).

## 2026-11-03 — OPS-H4 — ready to merge
- Agent: backend-engineer · Attempts: 2 · QA rounds: 2 (PASS, PASS) · PM rounds: 2 (CHANGES: CONTRIBUTING/README lines per DoD 4 → APPROVE) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/12 (ready for review, `ready-to-merge`) · head `0edd8fd` · Jira KAN-16 → Ready to merge
- Summary: `evals/results/` ignored; `make test-py` runs the 47 eval-data tests (CI Python job 3 → 50 passed). PM CHANGES was a spec fault (AC4 forbade the doc edit); pm-lead widened AC4 and added AC6.
- Blockers / follow-ups: `CONTRIBUTING.md:28,54` stale EVAL-1 wording (backend docs nit).
- Note: GitHub-side attribution handling rewrote the PR-body footer on both PRs (cosmetic).

## 2026-11-03 — post-RET-1 docs PR — merged
- arxivlens-agents#5 (AGENTS.md §6 rerank gotcha removed, PRD-Product row 156 RET-1 caveat replaced) merged by Mahesh; backlog item removed.

## 2026-11-03 (scheduled cycle 5) — orchestrator — no-op
- Setup: both repos attached, push to arxivlens-agents verified (`push --dry-run`), app cloned at `app/`.
- Sync: open agent PRs ArxivLens #11 (AI-2, `c9ae07c`) and #12 (OPS-H4, `0edd8fd`) are ready for review, mergeable clean, CI 4/4 green, QA PASS + PM APPROVE for their current heads; no reviews or untagged comments from Mahesh. No open arxivlens-agents PRs. Jira: nothing updated since cycle 4, no intake, no untagged comments. No ADR status changed (0006, 0010 Accepted; rest Proposed).
- No rework, no review queue. No new task: ai-engineer (#11) and backend-engineer (#12) at WIP limit; FE-1 still needs registry.npmjs.org (DNS doesn't resolve; proxy.golang.org, huggingface.co, Docker Hub also unreachable; no Docker daemon). Nothing invented.

## 2026-11-03 (scheduled cycle 6) — orchestrator — no-op
- Setup: both repos attached, push to arxivlens-agents verified (`push --dry-run`), app cloned at `app/` (origin/main `bb9ee90`).
- Sync: open agent PRs ArxivLens #11 (AI-2, `c9ae07c`) and #12 (OPS-H4, `0edd8fd`) still ready for review, mergeable clean, label `ready-to-merge`, QA PASS + PM APPROVE for their current heads; no reviews or untagged comments from Mahesh (only `[qa-reviewer]` comments). No open arxivlens-agents PRs. Jira: no `arxivlens` issue updated since cycle 4, no intake, no untagged comments. No ADR status changed (0006, 0010 Accepted; rest Proposed).
- No rework, no review queue. No new task: ai-engineer (#11) and backend-engineer (#12) at WIP limit; FE-1 still needs registry.npmjs.org (times out, as do proxy.golang.org and huggingface.co; no Docker daemon). Nothing invented; retro skipped (no new friction).

## 2026-11-03 — OPS-H4 — done
- PR #12 merged by Mahesh as `211adbf`; Jira KAN-16 → Done. `make test-py` now runs the eval-data tests on every PR.

## 2026-11-03 — AI-2 — done
- PR #11 merged by Mahesh as `9c1229a`; Jira KAN-10 → Done. Unverifiable citations are now unsupported (score 0). AI-3 and AI-4 have their dependencies met; pm-lead's PRD QA-4 docs PR is now due.

## 2026-11-03 — pm-lead — external-review plan specced
- Input: two external reviews of ArxivLens at `bb9ee90` (before #11/#12 merged), sent to Mahesh as private attachments (not committed). Mahesh approved a plan based on them. pm-lead re-checked every finding against `origin/main` `9c1229a`. Summary: (1) the Go consumer commits the offset even when the DLQ write fails, so the message is lost, and its retry waits ignore ctx. pm-lead also found that the Python consumer has the same flaw (`flush` result ignored) and that `BlockRebalanceOnPoll` is set but `AllowRebalance` is never called. (2) DLQ list/replay reads a ~2 s window from the topic start, with no checkpoints, paging or lock. (3) Section-extraction quality has never been measured. (4) No eval numbers exist, because the full stack has never run; GitHub runners have Docker.
- New specs: OPS-H6 (backend, P0, design), EVAL-3 (backend, P1, design; carries RET-1 AC6, moved from EVAL-2 AC10), EVAL-4 (ai, P1, Blocked on EVAL-3: `evals/BASELINE.md` is ai-owned, so the landing PR can't record the numbers), OPS-H7 (backend, P1, design, after OPS-H6), ING-8 (ai, P1; Mahesh's "ING-7" collides with Product PRD row ING-7, so it was renamed). Board Ready re-ordered: OPS-H6 → OPS-H1 → EVAL-3 → OPS-H7 → ING-8.
- ADR-0003 (Proposed): appended "Question for Mahesh: abstention policy" (all citations unsupported / verification unavailable: refuse, warn or answer). Status unchanged.
- Backlog: AI-2 follow-up extended with five separate counters (Mahesh's #11 review); `make test-py` split into `test-m0` / `test-evals-data` (Mahesh's #12 review; artifact docs folded into EVAL-3); OPS-H8 (Python consumer DLQ loss); pm-lead docs PR (Technical PRD §8.1 L4 caveat, OPS-1 ✅ → ◐, Proposed PRD row ING-8).
- Jira not touched (per instructions). Orchestrator: create stories for OPS-H6, EVAL-3, EVAL-4, OPS-H7, ING-8.

## 2026-11-03 (scheduled cycle 14:00 UTC) — orchestrator
- Setup: both repos attached, push to arxivlens-agents verified (`push --dry-run`), run lock taken (`72d8ba1`), app cloned at `app/` (origin/main `9c1229a`); task worktrees under `$HOME/wt/` (= `/root/wt/`).
- Sync: no open PRs in either repo; no human reviews/comments; Jira: no intake, no untagged comments. No ADR status change (0006, 0010 Accepted). Jira stories for OPS-H6/EVAL-3/EVAL-4/OPS-H7/ING-8 already existed (KAN-28..32).
- pm-lead plan (`899cbba`): OPS-H6, OPS-H1 (now design-required + own `stack.yml` CI check), ING-8, AI-3. Independent: OPS-H6 = `internal/kafka/consumer*.go` + one `ci.yml` step; OPS-H1 = compose, Dockerfiles, Makefile, new `stack.yml`, README/CONTRIBUTING line ranges; ING-8 = new `evals/`/`scripts/`/`tests/` files + `evals/README.md`; AI-3 = `internal/query/rag.go` + test. Skipped: FE-1/FE-2 (npm unreachable), AI-4 (same files as AI-3), EVAL-2 (P2, ai at 2), EVAL-3/OPS-H2/OPS-H7 (deps), OPS-H5/ING-6 (backend at 2, need a stack).

## 2026-11-03 — AI-3 — ready to merge
- Agent: ai-engineer · Attempts: 1 · QA rounds: 1 (PASS) · PM rounds: 1 (APPROVE) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/13 (ready for review, `ready-to-merge`) · head `ff9e7c1` · Jira KAN-11 → Ready to merge
- Summary: citation validation makes ≤ 2 `EmbedTexts` calls per answer (chunks, then distinct sentences), fails closed per batch. 3 new tests; old tests unchanged; CI 4/4 green; 6 mutants killed. AC3 `make eval` not run (no stack).
- Follow-ups (board Backlog): `max_citations` cap (backend P2, value Proposed for Mahesh); before/after latency once EVAL-3 exists. QA harness again couldn't write `report.md`; orchestrator saved it verbatim from the PR comment (`d13297f`).

## 2026-11-03 — OPS-H6 — ready to merge
- Agent: backend-engineer · Attempts: 1 (+1 rework) · Design: written `e7dadd1`, PM APPROVE with C1–C7 (`6ee10f7`) · QA rounds: 2 (PASS, PASS) · PM rounds: 2 (CHANGES: missing AC6b test for ctx cancel inside the handler → APPROVE) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/15 (ready for review, `ready-to-merge`) · head `a8a2cf5` · Jira KAN-28 → Ready to merge
- Summary: Go consumer never commits past a failed DLQ write (retries the DLQ write in place, ctx-aware 1→30 s waits, CRITICAL log), no `time.Sleep`, nil producer rejected, `AllowRebalance` after each poll, partition poll errors no longer drop the poll's records (AC12). 15 fake-only tests, `Start` 100% covered; mutations AC10a/b and AC6b each turned CI red on named tests. 407 changed lines (cap raised to 420 for AC6b). AC11 (M4) not run: no stack.
- Waiting on Mahesh: confirm franz-go v1.16.1 godoc for `BlockRebalanceOnPoll`/`AllowRebalance` (C2; unreachable from sandboxes). Follow-ups: OPS-H8 (Python consumer), G1/G2, shutdown poll-error log; `make test-go -race` after OPS-H1.

## 2026-11-03 — OPS-H1 — rework (draft PR #14)
- Agent: backend-engineer · Attempts: 1 · Design: `8a9e9a9`, PM APPROVE with 8 conditions (`7e13840`) · PR: https://github.com/MaheshPulivarthi18/ArxivLens/pull/14 (draft) · head `bb5ce42` · Jira KAN-13 → In Progress
- `ci.yml` green; `stack.yml` (run 41652931431, 2 attempts) failed at `docker compose up -d`: Docker Hub denies `minio/mc:latest` — the existing `minio-init` image, so `make infra-up` on main is broken for everyone. pm-lead addendum (`210f2ca`) lets OPS-H1 pin a MinIO-published image; rework checklist R1–R9 in the ticket for next cycle. After that, expected Blocked on OPS-H5 (M5 HNSW index test). `make setup-py` now installs `opentelemetry-sdk` (M5/M6 import broke test collection).

## 2026-11-03 — ING-8 — blocked
- Agent: ai-engineer · Attempts: 1 · branch `agent/ai/ING-8` `d2ad9c5` pushed, no PR · Jira KAN-32 (label `blocked`)
- Scorer, 35 tests (82 passed incl. eval-data), README section built; AC2/3/4/6 met in tests. AC1 (license-checked, hand-labelled ≥10 papers) and AC5 (baseline) impossible: arxiv.org unreachable from agent sandboxes; labels from memory refused. Needs Mahesh: allow arxiv.org egress, provide the labelled file, or let the task run where arxiv.org is reachable.

## 2026-11-03 (scheduled cycle 16:00 UTC) — orchestrator — cut short (rate limit), superseded by cycle 19:02Z
- Setup OK: push verified, lock taken `8ad0bdb`. No human reviews at 16:00. pm-lead plan `909ab28`: OPS-H5 (backend) + EVAL-5 (ai, new, split from EVAL-2); EVAL-2 → Blocked on ADR-0012 (Proposed).
- OPS-H1 rework r1 (`e410967`): both pinned MinIO refs failed to pull on the runner (quay.io 401; Docker Hub `minio/minio` also gone) → Blocked (needs decision: MinIO image source); Mahesh notified.
- OPS-H5 → draft PR #16 (`47e8451`, CI green); EVAL-5 → draft PR #17 (`910f2f8`, CI green). QA: OPS-H5 r1 pack committed (`fdca888`); EVAL-5 QA was cut off by the account's 5-hour usage limit before committing anything, and the cycle stalled ~3 h, so its lock went stale and cycle 19:02Z took over (handling Mahesh's #16/#17 reviews). Board/metrics/Jira for this cycle left to that cycle to avoid conflicting writes; Jira story for EVAL-5 still needs creating if it doesn't exist.
- Mahesh merged #15 (OPS-H6, `e9be32e`) and #13 (AI-3, `8b0a2d2`) ~18:00.

## 2026-11-03 (cycle 19:02Z) — backend-engineer — OPS-H5 rework r1 (Mahesh review H1–H5)
- PR #16 head `cff6fa1` (draft). New DB workflow (real pgvector 0.8.7) green: run 41705021838 / job 126157913475; CI run 41705022138 green.
- H1 ✔ (index created on fresh DB, 2nd migrate identical schema), H2 ✔ (custom plan uses HNSW; generic plan, which production gets after 5 runs per connection, does not), H3 ✔ (default ef_search=40 short: 40 rows, 9.8 with a 25% filter; shipped ef_search=100 + strict_order: always 50, R@5 1.00 / 0.76 filtered), H4 blocked on OPS-H1, H5 ✔ (CONTRIBUTING).
- Follow-ups in ticket Notes: F1 force_custom_plan vs split SQL (Mahesh decision), F2 eval script ef_search/plan regime (ai-engineer).

## 2026-11-03 (scheduled cycle 19:02 UTC) — orchestrator
- Setup: both repos attached; push verified; previous RUN_LOCK (16:00Z) stale → lock taken (`dfad872`); app cloned (origin/main `8b0a2d2`). Saved OPS-H5 QA r1 report.md from the PR comment (left pending by the 16:00 cycle).
- Sync: #13 (AI-3) and #15 (OPS-H6) merged → Done (KAN-11, KAN-28). **Human reviews from Mahesh** (17:58–17:59Z) on #14, #16, #17 → checklists in the tickets (`f492378`). #14: Mahesh pushed 9 commits to the branch himself up to 19:07Z, so agents left it alone this cycle (stack.yml still red at `5c79c43`).
- OPS-H5 (#16): backend rework H1–H5 → new `db.yml` real-pgvector job, `ef_search=100`+`strict_order`; QA r2 FAIL (guard only on generic plans) → fixed, mutant proven red in CI → QA r3 PASS → PM APPROVE → raised, Jira KAN-17 Ready to merge. Found prod uses generic plans (exact scan) after 5 executions → ADR-0013 Proposed. H4/AC5 owed after OPS-H1.
- EVAL-5 (#17): ai rework H1/H2 done (Go default parsed from main.go; `--query-model`), H3 not run (no pgvector anywhere) → QA PASS r1 (31 mutants) → PM APPROVE with merge gates G1 (H3) and G2 (merge order with #16) → raised; Jira story created KAN-33 → Ready to merge.
- AI-4 (#18): new task (ai's second slot; rag.go + rag_test.go only, no overlap with #14/#16/#17; dep AI-3 merged) → CI 4/4 → QA PASS r1 → PM APPROVE → raised; KAN-27 Ready to merge.
- Not started: backend at WIP limit (#14, #16 active at cycle start); FE-1/FE-2 still need registry.npmjs.org (DNS fails); other Ready tasks depend on OPS-H1/OPS-H6 follow-ups. Retro: lessons added by roles this cycle (backend cached plans, qa-reviewer ×2); QA harness still can't write report.md (orchestrator saved AI-4/EVAL-5 verbatim, `b5dd20c`).

## 2026-11-03 (cycle 21:02Z) — pm-lead — grooming
- Open ArxivLens PRs re-checked via `gh api …/pulls/<n>/files`: #14 (compose, Makefile, stack.yml, Dockerfiles, README, CONTRIBUTING), #16 (db.yml, cmd/arxivlens/main.go, internal/db, internal/query/search*.go, migrations/000002, README, CONTRIBUTING), #17 (scripts/evaluate_retrieval.py, tests/test_evals_data.py, evals/README.md), #18 (internal/query/rag.go + rag_test.go).
- Picked: **OPS-H8** (backend, P0, design-required) → Ready. Scope `services/common/kafka_client.py`, new `tests/test_kafka_client.py`, one `ci.yml` python-job step (Makefile avoided: in #14). Adds to the Backlog item: unchecked `publish` flush (processor's `papers.chunked` can be lost), poison-record crash loop, `max.poll.interval.ms` during in-place DLQ retry. M4 deferred as AC11 with an owner (first green `stack.yml` on main).
- Skipped: OPS-H7 (needs `cmd/arxivlens/main.go` + README, both in #16; backend slot used by P0); OPS-H6 G1 (P1, backend slot used); G2 (backend-owned `services/common/db.py`, not ai; board note corrected); ai items — AI-2 split counters / AI-4 Ask-level tests / aux-section substring (rag.go/rag_test.go = #18), CHUNK_COUNTS_SQL / OPS-H5 F2 / EVAL-5 P3 (scripts/evaluate_retrieval.py = #17), fixture `2608.20331` check (arxiv.org + OPS-H1), AI-3 measurement and EVAL-4 (EVAL-3), ING-8 (arxiv.org), AI-5/QA-8/EVAL-2 (Proposed ADRs). No ai task this cycle; nothing invented. FE-1/FE-2: npm unreachable.

## 2026-11-03 (~21:55Z) — backend-engineer — OPS-H1 human-review rework (H1–H4)
- Built on Mahesh's 9 commits (none rewritten): `5c79c43` → `119f20b` → `e79867a`, PR #14 still draft. 2 pushes (limit 2) and 1 rerun (binding condition 5).
- Root cause of unhealthy workers: `describe_consumer_groups(...).result(timeout=10)` raises `TimeoutError` every time (confluent-kafka 2.16.1 vs Kafka 3.7.0), while the groups were Stable. Replaced with a worker-local heartbeat (`services/common/kafka_client.py`, tmpfs, 300 s) + `tests/test_worker_heartbeat.py`, and a `stack.yml` H2 test. MinIO images pinned by runner-resolved digest. `stack.yml` paths extended (H3). H4 stays in Backlog.
- Run 41722155825 a1: AC1–AC3 + H2 green. `make test-full`: 68 passed, 3 failed (HNSW allowed; 2× M3 `/v1/ask` 10 s timeouts, F1: about 10 s CPU rerank, pool=20). a2: fixture ingest timeout (F2, D3). Status **Blocked (needs OPS-H5 merged + decision on F1/F2)**.
- For pm-lead: deviation from binding conditions 1/3 (heartbeat touches `services/common` + `tests/`), diff 465 > 400 (condition 7), file overlap with Ready OPS-H8 (`kafka_client.py`).
- Jira sync skipped: connector unavailable.

## 2026-11-03 21:02Z cycle — pm-lead: OPS-H1 addendum decision, OPS-H8 dependency
- OPS-H1 design addendum (`a153203`) approved in "PM decision on addendum": condition 1 amended (heartbeat-only hunk in `services/common/kafka_client.py` + new `tests/test_worker_heartbeat.py`; Mahesh's Chainguard digest pins accepted), condition 3 replaced by the heartbeat (the H2 stack.yml step is required evidence), condition 7 waived at 465 lines (PR note, no further growth). Conditions 2/4/5/6/8 stand.
- OPS-H1 stays **Blocked (needs OPS-H5 merged + Mahesh decision on F1/F2)**. Q-F1 (M3 10 s vs ~10 s CPU rerank), Q-F2 (46 s ingest vs 45 s timeout) and Q-merge (wait for the fixes, or merge with known red) are written in the ticket Notes for Mahesh. No timeout or test changed.
- OPS-H8 `Depends on` now includes OPS-H1 (#14) merged (shared `kafka_client.py`); board Ready row updated. It doesn't start this cycle.

## 2026-11-03 (scheduled cycle 21:02 UTC) — orchestrator
- Setup: both repos attached; push verified (`push --dry-run`); RUN_LOCK free → taken (`213408b`); app cloned (origin/main `8b0a2d2`). Egress: npm, Go proxy, PyPI, HF, arxiv.org all unreachable; no Docker daemon.
- Sync: no merges or closes since 19:02Z. No new human reviews or untagged comments on #14/#16/#17/#18. Jira: no intake. No ADR status change (0006, 0010 Accepted). #16, #17, #18 stay Ready to merge (QA PASS + PM APPROVE for their current heads), so no QA/PM queue.
- Rework: OPS-H1 (#14). Mahesh's last commit was 19:07Z (≥ 1 h old), so backend reworked H1–H4 on top of his commits (`119f20b`, `e79867a`). Workers are now healthy via a heartbeat. AC1–AC3 green in stack.yml run 41722155825; `make test-full` 68 passed / 3 failed (M5 HNSW allowed + F1, 2 × M3 10 s timeouts from about 10 s CPU rerank); the rerun hit F2 (ingest about 46 s against a 45 s timeout). pm-lead accepted the deviation (`589f9b3`). → **Blocked (needs OPS-H5 merged + Mahesh Q-F1/Q-F2/Q-merge)**; questions posted on [#14](https://github.com/MaheshPulivarthi18/ArxivLens/pull/14#issuecomment-6616466149); KAN-13 labelled `blocked` + comment. No QA this round (task blocked, head not final).
- New work: pm-lead specced OPS-H8 (P0, design-required; KAN-34 created). Then #14 began changing `services/common/kafka_client.py` too, so OPS-H8 now depends on #14 merged and was **not started**. No ai task is independent of #17/#18; FE-1/FE-2 need npm. 0 new tasks started.

## 2026-11-07 03:20 IST — orchestrator (interactive, Mahesh: "merge the open PRs after thoroughly reviewing them")
- Scheduled cycles were paused on 2026-11-04 03:30 IST at Mahesh's request; still off.
- #18 AI-4 merged `3151285` and #16 OPS-H5 merged `e67354c` (2026-11-04, orchestrator review: QA PASS + PM APPROVE, CI green).
- #17 EVAL-5 merged `6c80d64`. G2 resolved by ai-engineer `f24e1da` (parity guard rebuilt from search.go consts, eval runs production HNSW settings). G1 closed: probe PR #19 ran `pytest -k real_postgres` in the DB workflow against migrated pgvector → PASSED (job 128158303587). The probe is closed; branch `probe/eval5-g1` is left because the proxy blocks branch deletion.
- #14 OPS-H1 merged `71cb609`. Mahesh decided Q-merge = merge with F1 known red. F2 fixed by backend (`INGEST_TIMEOUT`, 5 min default, only for /internal/ingest). F1 (CPU cross-encoder rerank ~10 s) covers 3 M3 tests, incl. `test_hybrid_search_with_rrf_and_rerank` (same cause, added by orchestrator), run visibly in the "Known failure F1" step. CI 6/6 green, Full stack 80 passed / 3 deselected.
- Follow-ups for pm-lead to spec: (1) F1 CPU rerank latency fix, then remove the F1 step; (2) Chainguard MinIO digest pins can be garbage-collected (pin/mirror plan); (3) /internal/ingest reuses the loaded models instead of building EmbedderWorker() per request; (4) /internal/ingest ignores request cancellation; (5) EVAL-5 F2: permanent `pytest -k real_postgres` step in db.yml; (6) `hnsw.iterative_scan` needs pgvector >= 0.8: pin the image or fall back cleanly.

## 2026-11-07 — pm-lead — plan from the external review (15 tasks, 3 waves)
- Board hygiene: OPS-H1 (#14 `71cb609`), OPS-H5 (#16 `e67354c`), EVAL-5 (#17 `6c80d64`), AI-4 (#18 `3151285`) → Done. QA-8's ADR blockers are gone
  (ADR-0001/0002/0003 Accepted `51d8ff5`) → Ready, re-scoped. ADR-0003 row removed from Blocked.
- Review (Mahesh's private attachment, summarised, not copied): the infrastructure (event pipeline, retries/DLQ, hybrid retrieval + rerank,
  eval discipline) is judged well ahead of the product. The main gap is that `/v1/ask` fills a template instead of synthesising, and
  cosine support isn't entailment. It recommends pausing infrastructure growth and turning retrieval into an evidence-first
  research assistant. Phase 1 is real synthesis, claim-level provenance, verification statuses that never turn an error into "verified", refusals,
  an answer-quality eval with human review, and API/UI support. Then research workflows (Phase 2) and production readiness (Phase 3). It
  explicitly advises against k8s, a new database, more agent roles, endless HNSW tuning, and dashboards or collaboration before the core workflow works.
- Plan (board "Ready — the 2026-11-07 plan"): **Wave 1** LLM-1, EVAL-3, AI-7, EVAL-6, FE-1 (env-blocked on npm). **Wave 2** AI-6, OPS-H8, AI-9,
  FE-3, RET-2. **Wave 3** QA-8, EVAL-7, AI-8, FE-4, OPS-H9. New specs: LLM-1, AI-6, AI-7, AI-8, AI-9, RET-2, EVAL-6, EVAL-7, FE-3, FE-4,
  OPS-H9; re-scoped QA-8 (split into LLM-1/AI-6/QA-8/AI-7/AI-8); updated EVAL-3 (README line → EVAL-4), OPS-H8, FE-1 (unblock options), EVAL-4.
  `rag.go` is one ai-owned file, so its four tasks run in sequence: AI-7 → AI-6 → QA-8 → AI-8.
- New decision needed: **ADR-0014 (Proposed)** covers the claims, `status`, `quote`, `paper_version`, `page`, `prompt_version` and `answer_source` response fields,
  which ADR-0003 doesn't cover. It blocks RET-2, AI-8 and FE-4 only. New Blocked spec **EVAL-8** (real-LLM eval, which carries QA-8's old AC3) needs Mahesh to choose
  the model and host, and a cost cap if the model is hosted.
- Follow-ups specced: F1 rerank latency (AI-9), `real_postgres` step + pgvector ≥ 0.8 pin + MinIO digest check (OPS-H9). Left in Backlog:
  `/internal/ingest` model reuse + cancellation (P2, off the Phase 1 path), plus the review items listed in the board's first Backlog line.
- Environment check: npm and Go proxy don't resolve; HF and arXiv get 403; no Docker daemon. No LLM key is needed (fake provider). Jira not touched (instruction).

## 2026-11-07 — pm-lead — design reviews LLM-1, EVAL-3, AI-7
- **LLM-1: APPROVED with conditions.** Diff size: the < 400 target applies to non-test code for this task only (no LLM-1b split; splitting
  `llmtest` saves ~60 prod lines and adds a PR in front of QA-8). AC8 amended. Added a `ci.yml` step for `-race` + per-file coverage (CI runs
  neither for the package; no Go 1.25 in the sandbox), a well-formed cancel error, and the ai-engineer seam questions answered.
- **EVAL-3: APPROVED with conditions.** `| tee` steps must keep the exit code (`PIPESTATUS`, as in `stack.yml`; the default `bash -e` has no
  pipefail), one writer per seed log file, AC6 "don't tune" rule unchanged. The ingester politeness gap is filed as **ING-9** (backend, P1,
  Ready, not in this plan); the Backlog line from the OPS-H1 design is folded into it.
- **AI-7: APPROVED with conditions.** The `TestAskBatchFailClosed` change (citations 2 → 3; log = unverified line + refusal line) is approved
  as ADR-0003-mandated. It must also assert reason, B sentence and markers 1..3, and be called out in the PR. AC9 counts come from the
  refusal log line in `stack.yml`'s `query.log` (the M3 ask tests are the F1 set).
- Backlog: *Proposed* rules item on whether `_test.go` lines count toward the 400-line target; PRD docs item for the ING-1 politeness caveat.

## 2026-11-07 — pm-lead — EVAL-6 final review; LLM-1 AC8 decision
- **EVAL-6 (ArxivLens #20, `4dc4846`): APPROVE** after QA PASS r1. I opened all 20 evidence files, and each AC is proven (CI green, 14/14 mutants killed, end-to-end
  stub run, gate names unchanged). 443 lines accepted without an exception (182 tests). QA [spec] items: (5) `eval.yml` keeps its PR path filter, and
  answering PRs get a `workflow_dispatch` run once EVAL-3 merges (*Proposed* rules item; noted in EVAL-3 so QA doesn't fail #22 for it); (6) near-miss
  rows reviewed by Mahesh or someone he names (Backlog, human); (7) supported-rate reading in "Decisions for Mahesh". New PR body at `/tmp/claude-0/s/pr20-body.md`
  for the orchestrator to apply (ready for review, KAN-37 → Ready to merge). Merge order: #20 before #21.
- **LLM-1 AC8: split, no second exception.** 655 non-test lines vs < 400. LLM-1 = types/errors/config without `FromEnv`/`llmtest`/CI step (≈ 376).
  New **LLM-1b** = `openai.go` + `FromEnv` (≈ 279), Ready once LLM-1 merges. QA-8 now depends on both. The split runs in parallel with the
  AI-7 → AI-6 chain that QA-8 also waits on, so QA-8's start doesn't move. Design addendum appended.

## 2026-11-07 pm-lead: AI-7 #21 final review → APPROVE
- Reviewed `9265b5f` against the ticket, design (+ 2 build deviations), ADR-0003 and the QA pack (`62b13e2`, 9 evidence files, all prove their AC).
  Verdict **APPROVE** (`agents/reviews/AI-7/report.md`). PR body at `/tmp/claude-0/s/pr21-body.md` for the orchestrator (ready for review,
  KAN-36 → Ready to merge). **Merge after EVAL-6 #20**: raised now with that as the PR's first line; design condition 4 amended.
- QA [spec] 3: AC9 accepted as not run; measurement moved to **EVAL-4 AC5** (EVAL-6 `refusal_reason_counts` on a `main` with #20 + #21). No new
  backend ticket (no `internal/**` in `stack.yml` paths: cost); `query.log` always-upload is a Backlog P3 nit with the F1-drop change.
  [spec] 4: design header fixed. QA nit 2 → Decision 4 for Mahesh (refusal `score` = support score, 0 when uncited/unverified) + FE-3 note.

## 2026-11-07 pm-lead: LLM-1 #23 final review → APPROVE
- Reviewed `8e333c4` against the ticket (split part a), the design + conditions + split addendum, ADR-0001/0002 and the QA pack (round 1 FAIL on the
  AC4 `errors.Is` table, round 2 PASS; evidence `8d68676`, every file used opened). Verdict **APPROVE** (`agents/reviews/LLM-1/report.md`).
  Prod 375 < 400 (split estimate was 376). CI 5/5 green; 100% per-file coverage; 8/8 + 7/7 mutants killed.
- QA [spec] 5 → caller rule in QA-8 Notes (never JSON-log `Request`/`Response`). Carry-overs → LLM-1b Notes. No PRD/README change (QA-8 does both).
- PR body at `/tmp/claude-0/s/pr23-body.md` for the orchestrator (ready for review, Jira KAN-35 → Ready to merge). Board: LLM-1 → Ready to merge;
  no file overlap with #20/#21/#22. LLM-1b becomes Ready once #23 merges.

## 2026-11-07 (scheduled cycle 05:21 UTC) — orchestrator (session_01ATEBeUZeXKdfm2aPTPNd3H)
- Setup: both repos attached, push verified, lock taken `2fb7597`, app cloned (origin/main `71cb609`). Egress: npm/PyPI/Go proxy blocked; Go 1.24 local.
- Sync: no open PRs, no human reviews or Jira intake. ADR-0014 Accepted (agents #8).
- Started 4 Wave-1 tasks in parallel (disjoint files, no open PRs, deps merged): EVAL-6 (ai) #20, AI-7 (ai, design) #21, EVAL-3 (backend, design) #22, LLM-1 (backend, design) #23. Designs LLM-1/EVAL-3/AI-7 approved by pm-lead with conditions; ING-9 specced (KAN-48).
- EVAL-6 #20: QA PASS r1 → PM APPROVE → raised (KAN-37 Ready to merge). AI-7 #21: QA PASS r1 → PM APPROVE → raised, merge after #20 (KAN-36 Ready to merge).
- LLM-1: production code 655 lines → pm-lead split into LLM-1 + LLM-1b (KAN-47; full implementation kept on local branch `wip/LLM-1b` `8a776d6`, not pushed). #23: QA FAIL r1 (errors.Is table missing) → rework `8e333c4` → QA PASS r2.
- EVAL-3 #22: first real eval run 42344527129 (Recall@5 0.980; ask p95 12.8 s and correct refusals 0.909 fail gates — findings for Mahesh); QA PENDING on AC4; warm-cache attempt 2 triggered.
- This session then paused ~3 h; its lock went stale and the 10:00Z cycle took over (it completed QA EVAL-3 and PM LLM-1). Recorded here without touching that cycle's lock.

## 2026-11-07 pm-lead: EVAL-3 #22 final review → APPROVE
- Reviewed `8fc1209` against the ticket, design (+ conditions, 2 build deviations), Product PRD §8, Technical PRD §9/§10, ADR-0006/0010 and the QA pack
  (round 1 PENDING on AC4 → round 1 continued PASS; evidence `753f86a` + `5b988a1`, all 11 PNGs opened). Verdict **APPROVE** (`agents/reviews/EVAL-3/report.md`).
- First measured numbers (Eval run 42344527129, `main` `71cb609`, pre-AI-7/EVAL-6): Recall@5 0.9804, MRR 0.9853, NDCG@5 0.9735 (gated), supported 0.9032 pass;
  correct refusals 0.9091 and `/v1/ask` p95 12.8 s (attempt 2: 14.9 s) fail → `make eval` exit 1 both attempts. Red Eval check allowed by AC6; nothing tuned.
- PR body at `/tmp/claude-0/s/pr22-body.md` for the orchestrator (ready for review, KAN-29 → Ready to merge). Board: EVAL-3 → Ready to merge.
- QA [spec] 5 + nits 1/2/7 → new **EVAL-9** (backend, P1, Ready once #22 merges: seed step 45→70 min, job 100→120, seed-time summary + ≥ 75% warning, label fixes).
  Finding 4 → "Decisions for Mahesh" in the PR body. Backlog: PRD numbers docs PR after merge; seeded-state cache option (P3).

## 2026-11-07 10:19Z — pm-lead — OPS-H8 design review (KAN-34)
- `docs/design/OPS-H8.md` (`f1b5c0e`) **APPROVED with conditions**; refs re-checked against ArxivLens `71cb609` (`kafka_client.py:157-219`, `shared/events/events.py:31-43`; no signal handlers in either worker).
- Open questions 1–6 decided by pm-lead, none needs Mahesh/ADR (no shared contract change): commit errors logged (KafkaException only, as OPS-H6); `message.timeout.ms=10000` + 12 s bound; poison `attempts=1`; first signal graceful / second forces; DLQ traceparent envelope fallback. Visible behaviour changes go in the PR body for Mahesh.
- Conditions: build only after #23 (LLM-1, `ci.yml`) merges; counted skeleton + named split seam OPS-H8b (§5/AC7) if > 400 lines (AC12 amended); AC11 (M4) delivered in this PR via `stack.yml` (AC11 amended); delivery-bound test; OPS-H6 mutation procedure.
- Backlog: G5 (backend P3), G4 (ai P3), compose `stop_grace_period` (backend P3). Jira not touched (orchestrator mirrors).

## 2026-11-07 pm-lead: AI-9 #24 QA r1 FAIL → decisions; ING-9 [spec] 2
- AI-9 (KAN-39, head `3e6420e`, QA evidence `cd2ced2`): the score-preserving work is correct (parity 5.36e-07, AC3 mutant killed), but F1 is
  unchanged (3/3 `ReadTimeout` at 10 s, runs 42362802353 vs 42344527109). The AC4 stop clause applies. **Decision:** keep AI-9, re-scoped as
  the score-neutral, instrumented step (AC4 replaced with "report F1, no timeout change, hand numbers to ADR-0015"; F1 pass moved to
  **AI-10**). **#24 stays draft.** Status **Blocked (needs OPS-H10 merged)**, because AC1's stack after-numbers can't exist until `stack.yml`
  keeps the embedder log on green runs. [spec] 4: synthetic passages accepted for AC2 if ≥ 3/20 exceed 512 tokens. [spec] 5: AC5 done in
  the same rebase (after #21). Nit 3: new AC6 (parity test `local_files_only`, skips in `ci.yml` only when not cached, other load errors
  fail; real-model coverage stays in `stack.yml`). No backend `ci.yml` cache-key change. Round-2 checklist in the ticket Notes.
- **ADR-0015 Proposed** (`docs/adr/0015-cpu-rerank-latency-ranking-changing-options.md`): measured numbers so far, 6 options; recommends
  int8 dynamic quantisation + `max_length` 384/256 as env-configurable candidates (defaults unchanged), measured on the eval corpus.
  Adoption rule: first config in order that passes F1 and keeps every gate with Recall@5/MRR/NDCG@5 within 0.01 abs (tolerance is
  Mahesh's). Pool and model changes not proposed. No timeout or threshold change proposed.
- New **OPS-H10** (backend, P1, Ready once #21 + #22 merge for README/CONTRIBUTING): `stack.yml` "Collect service logs" step
  (`if: always()`, `embedder-timing.log` + summary) and `pull_request.paths` += `cmd/**`, `internal/**`, `go.mod`, `go.sum`, `tests/**`.
  Folds in the AI-7 Backlog P3 (`query.log` every run). No overlap with EVAL-9 (`eval.yml`). OPS-H9's optional `stack.yml` check removed.
- New **AI-10** (ai, P1, design-required): Blocked on ADR-0015 Accepted, then AI-9 merged. F1-drop Backlog item now follows AI-10.
- ING-9 [spec] 2: AC8 reworded to "a dispatched `stack.yml` run of the PR head". The widened filter is OPS-H10. Board: ING-9 → In progress (rework).
- Board hygiene: ADR-0014 is Accepted (agents #8), so the stale Blocked row was removed and the RET-2/AI-8/FE-4 dependency notes updated.
- Jira not touched (orchestrator mirrors).

## 2026-11-07 pm-lead — ING-9 #25 final review: APPROVE
- ING-9 (KAN-48, head `c5dc873`): **APPROVE** after QA FAIL r1 (AC8 only) → PASS r2. I opened all 16 evidence files; pins verified (00–11 at `b1b104b`, 12–15 at `ac6e824`).
  AC2–AC4 spacing and UA assertions read in the diff, since the screenshots show only PASS lines. AC8 = dispatched `stack.yml` run 42364519257 `success`:
  both papers embedded, DLQs 0, on-demand ingest 200, `make test-full` 80 passed. F1 2/3 fail vs 3/3 in the baselines.
- Product fit: Technical PRD §9 is now true for every Go arXiv caller, per process. The planned "crawler only" ING-1 caveat was never written, so no PRD edit is needed.
  Behaviour note (ingest +3 s per extra arXiv request; concurrent ingests queue; downloader ≤ 1 PDF / 3 s) is in the PR body.
- QA nits 3–7 → Backlog: "ING-9 follow-ups" (backend P3) and "`-race` in CI's Go job" (backend P2). Board: ING-9 → Ready to merge.
- PR body at `/tmp/claude-0/s/pr25-body.md`. The orchestrator raises #25 (ready for review + `ready-to-merge` label) and moves KAN-48 → Ready to merge. Jira not touched.

## 2026-11-07 10:00Z — orchestrator (scheduled cycle)
- Lock: previous `RUN_LOCK` (05:21Z) was ~4.6 h old → stale, taken (`04b9656`). Push dry-run, app clone, Jira all OK.
- Sync: no merges/closes since last cycle; no human reviews or untagged comments on #20–#23; no Jira intake. ADR-0014 now Accepted (board row cleaned by pm-lead).
- Review: **LLM-1 #23** PM APPROVE (QA PASS r2) → body applied, ready for review, KAN-35 Ready to merge. **EVAL-3 #22** QA PENDING → PASS (warm-cache attempt 2 of run 42344527129, `5b988a1`) → PM APPROVE (`18da9b1`) → ready, KAN-29 Ready to merge; follow-up EVAL-9 (KAN-49).
- New: **AI-9** (#24, KAN-39; files `services/embedder/api.py`, `tests/test_m0.py`, README deferred because #21 holds it) — QA r1 FAIL (F1 still times out; no embedder timing captured on green stack runs) → pm-lead: Blocked on new **OPS-H10** (KAN-50), F1 fix moved to new **AI-10** (KAN-51) behind **ADR-0015 (Proposed)**; #24 stays draft. **ING-9** (#25, KAN-48; `internal/arxiv`, ingester, downloader — no overlap) — QA r1 FAIL (AC8: stack.yml path filter skips `internal/**`) → orchestrator dispatched stack.yml run 42364519257 (green) → QA r2 PASS → PM APPROVE (`bc6b971`) → ready, Ready to merge. **OPS-H8** design written (`f1b5c0e`) and approved with conditions (`608de9c`); build waits for #23 (both change `ci.yml`), KAN-34 in Design.
- Not started: FE-1 (npm still unreachable), OPS-H2/ING-6/OPS-H7 (lower priority; cycle time), everything gated on #20/#21/#23 merging.
- Retro notes: QA harness still can't write `report.md` (orchestrator saved 3 reports verbatim from PR comments); QA can't download Actions artifacts (proxy) — OPS-H10's run-summary section addresses part of that. Lessons added by qa-reviewer (`4d9d6f1`, `c1a3777`, `801cc60`), ai-engineer (`a458f4e`), pm-lead.

## 2026-11-07 ~11:00Z — orchestrator (interactive, Mahesh: "merge all except 24, start pending tasks, update Jira")
- Merged on Mahesh's explicit request, in order: #20 EVAL-6 `1273a3b`, #21 AI-7 `8406b18`, #23 LLM-1 `43713ce`, #22 EVAL-3 `122eee3`, #25 ING-9 `2b71772`. #24 AI-9 left open (draft, Blocked). Jira KAN-37/36/35/29/48 → Done.
- The 11:00Z scheduled cycle had taken `RUN_LOCK` at 10:59:40Z; this session overwrote it by mistake (`9ae9cc3`) and restored it (`238922e`). Starting pending tasks is left to that cycle (sprint Step 2/3) to avoid two cycles building the same tasks. Newly unblocked by these merges: LLM-1b, AI-6 (design), OPS-H8 build, OPS-H10, EVAL-9, RET-2 (design), EVAL-7, EVAL-4 (after one eval.yml run on main).
- 2026-11-07 — backend-engineer: LLM-1b rework r1 (QA FAIL finding 1, AC6) pushed `e031ac0` to draft PR #27. Transport errors now carry only op + errno or a fixed string (no net/http text, raw error not in the cause chain); 3xx not followed (`ErrProvider`); raw-TCP leak rows + `TestNoRedirect`. prod 310 / test 756 lines. Local Go 1.24 scratch run green (`-race -count=3`), CI pending. → QA r2.
- 2026-11-07 — backend-engineer: OPS-H10 rework r1 (QA r1 FAIL). AC3 evidence from scratch run 42368916365 (forced `exit 1` in the crawl step → Collect, Diagnostics, Upload all `success`; `compose.log` 256,934 B in artifact 13572664383). README nit 4 fixed, pushed `532440e` to draft #26. Scratch branch `agent/backend/OPS-H10-ac3` needs Mahesh to delete it. → QA r2.

## 2026-11-07 — pm-lead: AI-6 QA r1 finding 3 `[spec]` resolved
- New spec `agents/tasks/AI-6b.md` (ai-engineer, P0, Ready, Wave 3, depends on AI-6 #28 merged): `parseSynthesis` + `synthesisClaim`/`synthesisResult` + `errSynthesisMalformed`/`errSynthesisNoClaims`. AI-6 AC3 and the design's AC3 test rows are carried over unchanged, along with the out-of-range-marker mutation. I folded in QA nit 5 (whitespace delimiter look-alikes) and missing tests 1–2 (truncation after skips; empty-content hits are skipped, a pm-lead decision).
- AI-6 AC3 annotated "moved to AI-6b (design condition 1 seam c)". QA-8 `Depends on` + board (`rag.go` order AI-7 → AI-6 → AI-6b → QA-8 → AI-8) updated.
- `docs/design/QA-8.md`: recorded the `passageTokens`/`metaField` refinement and the as-built imports (`sort`), corrected the branch to `agent/ai/AI-6`, and added a post-build record. QA findings 1–2 (PR text) stay with ai-engineer for round 2. Jira was not touched (the orchestrator handles it).

## 2026-11-07 — ai-engineer: EVAL-7 built
- `ca21768` on ArxivLens `agent/ai/EVAL-7` (pushed, PR not opened): `scripts/answer_review.py` export/score, 16 `review` tests (synthetic fixtures; 9/9 mutants killed), evals/README "Human review". Diff 399 lines.
- Export re-asks `/v1/ask` for claim text (results JSON has none) and skips drifted cases; `--db-url` is an optional passage source, so the CLI is `--api-url [--db-url]`, not the spec's `|` (flagged in the ticket). CSV dropped to stay < 400.
- Unverified: `make test-py` (sandbox lacks torch/confluent_kafka), `--db-url` path, a real export. No judgments written.

## 2026-11-07 — backend-engineer: OPS-H8 build (stopped at the size gate)
- Built on `agent/backend/OPS-H8` from `2b71772`, head `ebe80a7` (pushed, **no PR**). Design §1–§5 and §7 implemented; 29 new fake-only tests pass locally against a stub `confluent_kafka` (PyPI is blocked by the proxy); `test_worker_heartbeat.py` unchanged and green.
- Size: 487 changed lines (174 prod + 311 tests + 2 ci). With the OPS-H8b seam (§5 + AC7 out) it's still 462. Binding condition 2 → stopped and reported. Options (split by layer: producer confirmation vs consumer loop, or a one-off exception) are in the ticket Notes for pm-lead.
- AC10 (CI mutation runs) and AC11 (M4 via `stack.yml`) need the PR, so they're not done. Local mutation smoke: a/b/c → 4/11/8 failing tests.

## 2026-11-07 — pm-lead: OPS-H8 size gate → split by layer
- Decision: option A (split by layer), no size exception. OPS-H8 is now part a: `DeliveryError`, delivery-callback confirmation, timeout constants, `publish`/`publish_dlq` raise, build/send split, stack-trace fix, `ci.yml` step. `start` stays unchanged, so an unconfirmed DLQ write raises out before commit (interim crash-restart, never a loss). ACs rewritten (AC1–AC9; added the through-`start` no-commit test and mutation a').
- New OPS-H8b (P0, depends on OPS-H8 merged, same design): in-place DLQ retry, commit-error log, stop/signals, interruptible waits, poison, log hygiene; source code at `ebe80a7`.
- Design `docs/design/OPS-H8.md`: PM decision addendum. Board: OPS-H8 row updated, OPS-H8b added. Lesson added (pm-lead: seam at a layer boundary). Jira not touched (orchestrator mirrors; OPS-H8b needs a story).

## 2026-11-07 14:59Z — orchestrator (scheduled cycle, session_01ATEBeRjABpgGEmWpBsSLGs)
- Lock: previous `RUN_LOCK` (10:59Z) was 4 h old → stale, taken (`d04e35d`). The 11:00Z cycle had stopped after QA r1 of #26/#27 without recording; this cycle picked up from its commits. Push dry-run, app clone and Jira all OK.
- Sync: no merges since the interactive merge wave (#20–#23, #25 → Done on the board now). No human reviews or untagged comments on #24/#26/#27. No Jira intake.
- **LLM-1b #27** (KAN-47): rework r1 (transport errors built from typed fields only; raw-TCP leak rows; no redirects) → QA r2 PASS (`24dfd20`) → PM APPROVE (`0160638`) → ready for review. Attempts 2, QA rounds 2, PM rounds 1.
- **OPS-H10 #26** (KAN-50): rework r1 (AC3 evidence from scratch run 42368916365; README wording) → QA r2 PASS (`cf925cb`) → PM APPROVE with AC1–AC3 amended to agent-verifiable evidence + 3 human checks (`c6ed2e8`) → ready for review. The first rework subagent was denied by the permission classifier when deleting the scratch branch; nothing was worked around; Mahesh deletes `agent/backend/OPS-H10-ac3`.
- **AI-6 #28** (KAN-38, new): built (302 lines; parser split to **AI-6b** per design condition 1 seam c) → QA r1 FAIL (design conditions 4/5 missing from PR body; AI-6b not specced) → PR body fixed + pm-lead specced AI-6b (`8738879`, Jira KAN-52) → QA r2 PASS (`0c29174`) → PM APPROVE (`573e4a4`) → ready for review.
- **EVAL-7 #29** (KAN-42, new): built (399 lines) → QA r1 FAIL (drift guard compared only marker/chunk_id) → rework r1 (fingerprint adds score/supported; exact drift list; ID shapes; `--save` no-overwrite) → QA r2 PASS (`9adae82`) → PM APPROVE (`f9a1289`) → ready for review.
- **OPS-H8 #30** (KAN-34, new; design approved): first build 487 lines > 400 (462 with the named seam) → stopped per condition 2 → pm-lead split by layer (`c4f3e71`; **OPS-H8b** KAN-53 = consumer loop) → part a rebuilt at `007aecc` (278 lines) → draft PR #30, In QA. Next cycle: AC7 CI mutation commits, then QA r1.
- Independence: AI-6 (`internal/query/rag*.go`), EVAL-7 (`scripts/answer_review.py`, `tests/test_evals_data.py`, `evals/`), OPS-H8 (`services/common/kafka_client.py`, new `tests/test_kafka_client.py`, `ci.yml`) share no file with each other or with #24/#26/#27. EVAL-9 skipped (edits `CONTRIBUTING.md`, open in #26). FE-1 still env-blocked (registry.npmjs.org doesn't resolve).
- Not done: `qa-pass`/`qa-fail` labels (QA subagents were denied external writes; left for Mahesh). Evidence links on Jira added as comments, not remote links.

## 2026-11-07 19:59Z — orchestrator (scheduled cycle, session_01ATEBeTm7Zv3zKeD29Qivnv)
- Lock: previous `RUN_LOCK` (17:00Z) was ~3 h old → stale, taken (`b75a5ca`). The 17:00Z cycle pushed only AC7(b) mutation `68f775f` + revert `5892d6e` on #30 and ended without recording; this cycle picked up from there. Push dry-run, app clone and Jira all OK.
- Sync: no merges since 14:59Z (#26–#29 still Ready to merge). No human reviews/comments on #24, #26–#30. No Jira intake or untagged comments.
- **OPS-H8 part a #30** (KAN-34): AC7(a') mutation `455ec67` (CI Python + Full stack red, waited to completion) → revert `0d70fab` (tree = `5892d6e`, all green) → QA r1 PASS (`42eb4a1`; report saved from PR comment, `c3ae74e`) → PM APPROVE, AC8 wording amended (dot-position map), PR body rewritten (`a6479db`) → ready for review. Attempts 1 this cycle, QA rounds 1, PM rounds 1.
- **RET-2** (KAN-41, design-required): design `ab4a2fc` (page_number is the section heading's page → `page` omitted for every hit; version join correct but on-demand ingest hard-codes v1) → PM APPROVE with 7 conditions (`b41a019`), AC2/AC3/Verification amended. Jira → Design. **Build held:** it edits README, which open #26 also edits (same-file rule). New follow-ups: **ING-10** (KAN-54), **ING-11** (KAN-55, design-required).
- **ING-10 #31** (KAN-54, new): built (322 lines, shared `internal/arxiv` version helper) → draft PR → QA r1 FAIL (AC5: stack.yml doesn't trigger on Go-only PRs until #26 merges; no run) → rework r1: crawler comment + stack.yml dispatched on branch (run 42411848508, success, 2608.20331 still v1, M3/M4 pass) → QA r2 PASS (`751c78f`) → PM APPROVE, AC4 wording amended (versioned URL literal) (`c53ca8d`) → ready for review. Attempts 2, QA rounds 2, PM rounds 1.
- Independence: ING-10 (`internal/arxiv/`, `internal/query/ingester*`, `internal/downloader/*`, `internal/crawler/*`) shares no file with #24/#26–#30 or RET-2. Backend had 1 active PR (#30) when ING-10 started → 2 max respected. Not started: EVAL-9, OPS-H9, RET-2 build, OPS-H7/OPS-H2/ING-6 (all edit README/CONTRIBUTING/ci.yml held by #26/#30); AI-6b, QA-8, OPS-H8b (deps not merged); FE-1/FE-3 (npm registry still blocked: `npm view` timed out).
- Orchestrator slip (no harm): a failed `git revert -q` followed by `commit --amend` relabelled the local mutation commit; the push was rejected as non-fast-forward, the local branch was reset to the remote and the revert redone. Nothing wrong was pushed.
- Not fixable here: PR-body `![](…)` embeds are rewritten by an outbound filter (images show as links). Backlog line added for Mahesh.
- Retro: lessons added this cycle by qa-reviewer (scratch-module Go evidence; `pytest -q` dot mapping) and pm-lead (verify PR body after PATCH). Recurring: stack.yml path filters hide Go PRs from M3/M4 until #26 merges — the fix is already in #26. Orchestrator lesson: use `git revert --no-edit` (no `-q`) and check the exit code before amending.
- 2026-11-07 (backend-engineer) **ING-11 #33** (KAN-55): built part a (page_breaks, migration 000003 `paper_chunk_pages`, db.py RETURNING id + page upsert/delete, new `tests/test_processor_pages.py` in `make test-py`), 249 lines. AC2 before run 42415533422 / after run 42415675504, db.yml 42415675317, stack.yml 42415675293, all green → In QA. Jira not updated (no tool in session). Follow-up: CONTRIBUTING test-unit file list after #26.

## 2026-11-08 — pm-lead: ING-11 (part a) final review → APPROVE, PR #33 raised
- Reviewed head `3f1c32d` against the ticket, the approved design (conditions 2, 3, 7, 8; decision 4) and the PRD (ING-3, QA-3, §7 p3; ADR-0014). I opened all 12 evidence images and `.txt` files (`a30c246`). Each one shows its AC's result. Base `2b71772` is still main, mergeable clean.
- QA findings: 1 → new AI-11 AC5 (Abstract bucket + heading at the page bottom, `page_start >= 1`); 2 `[spec]` → ING-11 AC2 wording aligned with condition 2; 3 `[spec]` → board Backlog line for `CONTRIBUTING.md:23` (after #26), with ING-11b Scope as the backstop.
- PR #33 body rewritten (outbound filter again de-embedded the images and swapped the footer; lines 1–65 intact) and marked ready for review (`draft: false`). The `ready-to-merge` label call was denied in this environment; not added. Board: ING-11 → Ready to merge. Jira KAN-55 left to the orchestrator.
- Found: a previous pm-lead session had PATCHed #33's body with an APPROVE at 21:50Z but committed nothing here (its body cited AI-11 AC5 / AC2 alignment / a board line that didn't exist). Re-derived the verdict and made the records true. Lesson added.

## 2026-11-08 — pm-lead: OPS-H7f final review → APPROVE, PR #32 raised
- Reviewed head `6cd6ae4` against the ticket, design OPS-H7 § Q5 + condition 1 (i)-(iv), and the PRD (OPS-2, OPS-3, §5.3; Technical §4, §8.2). Opened all 11 r2 evidence images + `.txt` (`2ea3675`); each shows its AC's result. Live: 5/5 checks success, `mergeable_state: clean`, base `2b71772` = main.
- QA nits: 4 → OPS-H7c Notes (mistyped-field envelope gets a new ID; cover it with the deterministic ULID); 5 → OPS-H7b AC4 extended (dry-run count = real publishes incl. unreplayable records, kills M14); 6 → PR body CI refreshed to `6cd6ae4`; 7 `[spec]` → pm-lead lesson (one mutant per conjunct; template line proposed for a `rules/` PR, not opened).
- Board: OPS-H7f → Ready to merge; OPS-H7a still needs OPS-H7f **and** #26 merged. Backlog line added for the owed PRD OPS-2 ✅ → ◐ docs PR (design condition 7).
- PR #32 body PATCHed and marked ready (`draft: false`). The outbound filter again de-embedded the 11 evidence images (backtick-wrapped links), dropped the 🤖 line and appended a footer; other text intact. Not worked around (lesson OPS-H8). No label added; Jira untouched (orchestrator).

## 2026-11-08 01:00Z — orchestrator (scheduled cycle, session_01ATEBeR3tnN3vKUvn6rKEGQ)
- Lock: previous `RUN_LOCK` (2026-11-07 21:00Z) was 4 h old → stale, taken (`a1eb5a6`). The 21:00Z cycle built ING-11 #33 and OPS-H7f #32, ran QA r1 on both and pushed OPS-H7f rework `6cd6ae4`, but didn't record or sync Jira; this cycle picked up from there. Push dry-run, app clone and Jira all OK. (`git fetch` showed origin/main as a forced update vs the stale local ref; history from `d8bfa24` is intact.)
- Sync: no merges since 2026-11-07 10:59Z (#26–#31 still Ready to merge, #24 Blocked draft). No human reviews, review comments or untagged comments on #24, #26–#33. No Jira intake.
- **OPS-H7f #32** (KAN-56, Jira story created this cycle under KAN-3, child of OPS-H7 KAN-31): rework r1 `6cd6ae4` (per-field guard rows; test-only) → QA r2 PASS (`2ea3675` evidence, `94e2758` report; M7/M8/M9 now killed, 13/14 mutants) → PM APPROVE (`af8b056`, `7d099aa`) → ready for review. QA rounds 2, PM rounds 1. Nits routed to OPS-H7b (dry-run vs real count, M14) and OPS-H7c (mistyped non-ID field).
- **ING-11 part a #33** (KAN-55): QA r1 PASS (prior cycle) → PM APPROVE (`7ca82a4`, `7967348`) → ready for review. AI-11 gained AC5 (untested layouts); CONTRIBUTING test-list line → backlog after #26. An earlier pm-lead session had PATCHed #33's body without committing anything; this review re-did it and made the records match (pm-lead lesson added).
- New work: **none started.** Backend has 0 active PRs now, but every backend Ready task overlaps an open PR: EVAL-9/OPS-H9 (CONTRIBUTING/README, #26), OPS-H2 (Makefile #33, README #26, ci.yml #30), ING-6 (`internal/crawler` #31, migration numbering after #33's 000003, README), OPS-H7a (needs #32 + #26 merged), RET-2 (README, #26), OPS-H8b (needs #30 merged). AI: AI-6b/QA-8 need #28, AI-11 needs #33 merged. FE-1/FE-3: registry.npmjs.org still unreachable (`npm view` timed out).
- Not done: `ready-to-merge` label (label call denied for the pm-lead subagent; not worked around). PR-body image embeds again rewritten by the outbound filter (links, not images).
- **Waiting on Mahesh: 9 PRs ready for review (#26–#33)**; merging #26, #28, #30, #33 unblocks RET-2/EVAL-9/OPS-H9, AI-6b, OPS-H8b, AI-11.

## 2026-11-08 02:00Z — orchestrator (scheduled cycle, session_01ATEBeSNMpLSv1BT8THuyVL)
- Lock: none present → taken (`d885ebc`). Push dry-run, app clone and Jira all OK.
- Sync: no merges since 2026-11-07 10:59Z (ArxivLens main still `2b71772`). No human reviews, review comments or untagged comments on #24, #26–#33; PR heads unchanged since their QA/PM verdicts. No Jira intake (last KAN update was the 01:00Z cycle).
- Review: nothing queued (#26–#33 all QA PASS + PM APPROVE at current heads; #24 Blocked draft).
- New work: **none started**, same reasons as 01:00Z (every backend Ready task overlaps an open PR or waits on a merge; AI-6b/QA-8/AI-11 wait on #28/#33; FE-1/FE-3: `npm view` still times out).
- **Waiting on Mahesh: 8 PRs ready for review (#26–#33).**

## 2026-11-08 03:00Z — orchestrator (scheduled cycle, session_01ATEBeTADqxRuN15nw7XiWQ)
- Lock: none present → taken (`4a1a9c9`). Push dry-run, app clone and Jira all OK.
- Sync: no merges (ArxivLens main still `2b71772`). No human reviews, review comments or untagged comments on #24, #26–#33; PR heads unchanged since their QA/PM verdicts. No Jira updates or intake in the last 70 min.
- Review: nothing queued (#26–#33 all QA PASS + PM APPROVE at current heads; #24 Blocked draft).
- New work: **none started**, same reasons as 01:00Z/02:00Z (backend Ready tasks overlap open PRs or wait on merges; AI-6b/QA-8/AI-11 wait on #28/#33; FE-1/FE-3: `npm view` still times out).
- **Waiting on Mahesh: 8 PRs ready for review (#26–#33).**

## 2026-11-08 04:00Z — orchestrator (scheduled cycle, session_01ATEBeR5psBKk3oLTrexCTd)
- Lock: none present → taken (`f7a662f`). Push dry-run, app clone and Jira all OK.
- Sync: no merges (ArxivLens main still `2b71772`). No human reviews, review comments or untagged comments on #24, #26–#33; PR heads unchanged since their QA/PM verdicts. No Jira updates or intake in the last 70 min.
- Review: nothing queued (#26–#33 all QA PASS + PM APPROVE at current heads; #24 Blocked draft).
- New work: **none started**, same reasons as 01:00Z–03:00Z (backend Ready tasks overlap open PRs or wait on merges; AI-6b/QA-8/AI-11 wait on #28/#33; FE-1/FE-3: `npm view` still times out).
- **Waiting on Mahesh: 8 PRs ready for review (#26–#33).**

## 2026-11-08 05:00Z — orchestrator (scheduled cycle, session_01ATEBeT2F7YdF43XFTef7LB)
- Lock: none present → taken (`494cd15`). Push dry-run, app clone and Jira all OK.
- Sync: no merges (ArxivLens main still `2b71772`). No human reviews, review comments or untagged comments on #24, #26–#33; PR heads unchanged since their QA/PM verdicts. No Jira updates or intake in the last 70 min.
- Review: nothing queued (#26–#33 all QA PASS + PM APPROVE at current heads; #24 Blocked draft).
- New work: **none started**, same reasons as 01:00Z–04:00Z (backend Ready tasks overlap open PRs or wait on merges; AI-6b/QA-8/AI-11 wait on #28/#33; FE-1/FE-3: `npm view` still times out).
- **Waiting on Mahesh: 8 PRs ready for review (#26–#33).**

## 2026-11-08 ~14:20 IST: orchestrator (interactive, Mahesh: "review the open PRs and merge if all tests pass; update Jira")
- Merged #36 AI-6b `e7ab58d` and #34 OPS-H8b `9651294` after orchestrator review, CI 6/6 green; merged ahead of the running cycle's QA round, at Mahesh's request. Jira KAN-52 and KAN-53 → Done.
- Not merged: #35 RET-2. DB job `TestSearchProvenance` fails: ING-11 (#33) now stores chunk pages, but the test still expects the page omitted. KAN-41 → In Progress, PR comment posted.
- Not merged: #24 AI-9 (draft, QA r1 FAIL, r2 rework not yet QA'd; F1 latency moved to AI-10 / ADR-0015).
- Lesson added (qa-reviewer): mutants run locally, not pushed to the PR branch.

## 2026-11-08: pm-lead (final review AI-11, PR #38)
- AI-11 **APPROVE** on `0085fee` after QA PASS r1; verdict in `agents/reviews/AI-11/report.md`. All 10 evidence files opened; the production diff matches ING-11 design decision 1 + PM condition 1.
- QA finding 1 [nit] (AC3(d) double-`lead` mutant M03): follow-up AI-11f (ai, P3, one test row), not blocking: `lead == 0` in production (worker strips every line, skips empty ones) and QA's 400-doc probe kills M03. Finding 2 [spec] (`make lint` has no Python linter): follow-ups for a backend ruff target and a *Proposed* task-template note; pm-lead lesson added. Board backlog entries left to the orchestrator (told not to edit the board).
- PR #38 description rewritten with the Evidence section (images pinned to `f7ba64a`) and marked ready for review. Merge is Mahesh's.

## 2026-11-17 pm-lead: ING-11b final review
- ING-11b **APPROVE** on `706e43e` (PR #52, KAN-59) after QA PASS r1; verdict in `agents/reviews/ING-11b/report.md`. Opened all 14 evidence files. Evidence 02's PNG cuts the AC3 `page=` values, so I added `evidence/pm-02b-AC3-page-values.png`, rendered from QA's committed `.txt`.
- QA finding 2 [spec]: ticket AC4 "TestHNSW recall lines unchanged" reworded (non-iterative identical; iterative within main-to-main variance), with an amendment note in `docs/design/ING-11.md`. Finding 1: the test name, dot 196 and the summary line are in the PR body. Finding 4: board Backlog follow-up (backend, P3). pm-lead lesson added.
- Board: ING-11b → Ready to merge; the `CONTRIBUTING.md:23` backlog line is marked done in #52. After merge: Technical PRD §5/§6.2 docs PR (pm-lead).

## 2026-11-17 ai-engineer: AI-8a build
- AI-8a built and pushed: `agent/ai/AI-8a` @ `12e70b4` (from `40dec5a`), `rag.go` + `rag_test.go`, 387 changed lines. Ownership OK. PR not opened (orchestrator).
  Citation `status`/`paper_version`/`page`/`quote`, versioned `pdf_url`, raw `content` on the LLM path, `passageHits` removed. Scratch-module run (Go 1.24.7): vet and race tests OK,
  `rag.go` 99.0%, 20/20 mutants killed.
- [spec] `synthesis_test.go` is outside ai's allow-list in `ownership-check.sh`, so its 10 existing tests don't call `checkCitationInvariants` yet (AC1 partial). Follow-up options are in the AI-8a Notes; AI-8b has the same issue.
- AC7 (`eval.yml` dispatch) not run: the dispatch was denied by this session's permission policy. Jira KAN-60 not updated (no Jira tool in session).

## 2026-11-17 pm-lead: EVAL-4 final review
- **APPROVE** PR #51 @ `156c394` (QA FAIL r1 → PASS r2). All 18 evidence files checked; every AC proven ([report](reviews/EVAL-4/report.md)).
- AC5 [spec] finding decided: my premise "(none in this run)" was wrong; BASELINE records the 1/22 early refusal truthfully; not gated, so the baseline stands.
  Ticket AC5 text corrected. Follow-up **EVAL-10** (ai, P2, Ready; tests overlap #52, or use a new test file) prints refused/miss/near-miss-failure IDs in the eval summary.
- PR #51 description rewritten with the Evidence section (pinned to `56f275b`/`ae6716a`), CI, and QA + PM verdicts; marked ready for review. Optional human check listed: artifact 14247998742 `answers.cases` (expires 2026-12-16).
- Pending pm-lead PRD docs PR gains: §8 Recall@5 row ordering (ADR-0017/0016), "Technical PRD §9 (Proposed)" → Accepted in the latency rows.
- Board not edited (orchestrator): EVAL-4 → Ready to merge; add EVAL-10.

## 2026-11-17 13:00Z pm-lead: cycle planning (board reconciliation)
- Board reconciled with ArxivLens `main` `40dec5a`: 16 rows → Done (#24 AI-9, #26–#39 agent PRs, QA-8 via Mahesh's #46). Eight stale Ready-to-merge rows dropped; #51 (PM review), #52/#53 (Ready to merge), #54 (In QA) kept.
  Correction to the sync brief: **#24 AI-9 was merged** (`d4b1cf3`, 2026-11-14 13:22Z, `merged: true`), not closed unmerged; the ticket already said so.
- New spec **OPS-H11** (backend, P1, from OPS-H6 design G1): the downloader skips re-publish when the `(arxiv_id, version)` row is `embedded` with the same sha256; unit table test + one real-stack M4 test. Files don't overlap #51–#54.
- ING-6 proposed as a design-only start (`docs/design/ING-6.md`); its build waits on README (#51/#52). OPS-H7a and OPS-H9 wait on #52 (`db.yml`, README). FE still env-blocked on npm (lockfile has no vitest). No ai picks (WIP 2/2).

## 2026-11-17 08:00Z — orchestrator (scheduled cycle, session_01ATEBeTfcg9MKvPR1TEnzjL) — interrupted
- Sync: 5 agent PRs merged 2026-11-14 → Done (KAN-39/41/49/57/58); QA-8 (KAN-7) Done via Mahesh's #46; pm-lead re-groomed 24 tickets (`0186d79`), ADR-0018 Proposed.
- Started 4: EVAL-4 #51 (QA FAIL r1 → rework 156c394 → QA PASS r2), ING-11b #52 (QA PASS r1, PM APPROVE, raised), OPS-H2 #53 (QA PASS r1, PM APPROVE, raised), AI-8 design (approved with conditions 1–8, split AI-8a KAN-60 / AI-8b KAN-61).
- AI-8a built (12e70b4, 387 lines) → draft #54. Its QA r1 subagent was cut off by an API rate limit (no comment, no evidence committed), so #54 has **no QA verdict**. AC7 (`eval.yml` dispatch on the branch) was denied by the sandbox permission policy.
- The rate limit stalled this session ~4 h, past the 100-min lock; the 13:00Z cycle took the lock over and finished EVAL-4's PM review. This cycle stops without touching that lock, the board or Jira beyond what is recorded above.

## 2026-11-17 pm-lead: AI-8a QA r1 finding 4 [spec] decision
- **Option (a)**: the AI-8a AC1 and Scope are amended to cover `rag_test.go` only, with dated amendment notes. The 11 `checkCitationInvariants` sites in `synthesis_test.go` (backend-owned per `ownership-check.sh` and AGENTS.md §2) become new task **AI-8c** (backend, P0, test-only, ~11 added lines, Blocked until AI-8a merged). QA evidence 06 shows all 8 tests pass with those calls.
- Not (b): a rules PR (AGENTS.md) plus a backend `ownership-check.sh` change would leave the AI-8a rework blocked on Mahesh this cycle. (a) weakens no test.
- AI-8b amended: it edits only `rag_test.go` and extends `checkCitationInvariants` in place, so the AI-8c sites get the claims checks with no second backend task. It now also depends on AI-8c merged. AI-8a findings 1–3 and nits 5–7 stay with ai-engineer for round 2.
- Board not edited (orchestrator): add AI-8c (backend, Blocked: AI-8a merged); AI-8b's blocker now includes AI-8c. Jira: create the AI-8c story under KAN-1, `labels = "task-AI-8c"`.

## 2026-11-17 pm-lead: ING-6 design gate
- **Approved with conditions 1–10** `docs/design/ING-6.md` (@ `dbeec46`). Walk newest-first / emit oldest-first / advance to the last fully-emitted group accepted; it closes the truncation and mid-run-crash skips the ticket's one-liner left open.
- Open questions answered: (1) max emitted = AC1's "max seen" (ticket AC1 amended); (2) late announcements: documented residual risk, **ING-6e** Backlog (FYI to Mahesh on KAN-18, non-blocking); (3) global `pg_try_advisory_lock` guard required, in ING-6c (two processes = 2 req/3 s breaks §9); (4) profile `crawler`, compose deferred to **ING-6d**; (5) defaults 6h/100/2000/`cs.AI,cs.LG` accepted (categories stay ADR-0005); (6) `crawl --rate-limit` → **ING-9b** (P3).
- Migration number fixed: `000005_crawl_watermarks` (OPS-H7b keeps `000004`; `migrate` applies all sorted files idempotently, so no renumbering race). Note added to OPS-H7b.
- New specs: **ING-6a** (Ready, buildable now: 6 new files, no overlap with #51–#55), ING-6b (Blocked: 6a merged), ING-6c (Blocked: 6b, #51, #52 merged), ING-6d / ING-6e / ING-9b (Backlog). ING-6 is now the umbrella.
- Board and Jira not edited (orchestrator): add ING-6a Ready (backend), ING-6b/6c Blocked, ING-6d/6e/9b Backlog; Jira stories under KAN-18's epic with `task-<ID>` labels.

## 2026-11-17 pm-lead: OPS-H11 final review
- **APPROVE** PR #55 @ `2039650` (QA r1 PASS). All 10 evidence files (PNG + txt) checked; AC1–AC5 proven ([report](reviews/OPS-H11/report.md)). Scope matches the ticket's 4 files, 212 lines, no contract change.
- Finding 1 [spec] (AC4 can't quote a named line under `pytest -q`, 3rd time): QA's verified dot map accepted, AC4 text amended. Follow-up **OPS-H12** (backend, P2, Ready): `-rA` via `PYTEST_ARGS` in `stack.yml` only, so it doesn't wait on #53 (`Makefile`/`ci.yml`). Finding 2 [nit] (no MinIO pre-check): no task, it fails loudly; noted in the ticket.
- PR #55 description rewritten with the Evidence section (pinned to `52e57e8`), CI, and QA + PM verdicts; marked ready for review.
- Pending pm-lead PRD docs PR gains: Product PRD OPS-4 note "redelivered `papers.discovered` no longer regresses `embedded` (OPS-H11)".
- Board not edited (orchestrator): OPS-H11 → Ready to merge; add OPS-H12 Ready (backend). Jira: OPS-H11 → Ready to merge; create the OPS-H12 story under KAN-3, `labels = "task-OPS-H12"`.

## 2026-11-17 pm-lead: AI-8a final review
- **APPROVE** PR #54 @ `990aa5a` (QA FAIL r1 → FAIL r2 → PASS r3). Opened all round-3 evidence (30–36) and the key earlier files. Every blocking finding (r1 1–3, r2 8) is closed, and r1-4 [spec] was closed by option (a)/AI-8c ([report](reviews/AI-8a/report.md), PM section).
- AC7 / DoD 3: accepted as "not run". The ai sandbox can't dispatch, and pm-lead doesn't trigger CI. On the quoted path that CI's eval measures, `supported`/`score`/`refusal_reason` are unchanged by construction. The measurement goes to the first nightly `eval.yml` on `main` after merge, compared in **AI-8b AC9** (amended, stop-and-report). An optional human dispatch is listed in the PR.
- PR #54 description rewritten (Evidence pinned to `866e12b`/`9ace78b`/`31687b9`/`d993baf`, CI, QA + PM verdicts), marked ready (`draft=false` verified), and labelled `ready-to-merge`. The outbound filter rewrote the body again: embeds lost `!` and were wrapped in backticks, the 🤖 line was dropped, and the footer was appended (lesson OPS-H8, 5×).
- Pending pm-lead PRD docs PR gains: Product PRD QA-4 note (stale pre-AI-2 fail-open text).
- Board/Jira not edited (orchestrator): AI-8a → Ready to merge (KAN-60).

## 2026-11-17 pm-lead: ING-6a QA r1 [spec] findings 6–8
- (6) AC4 amended to the real sorted-encode bytes `max_results=2&search_query=cat%3Acs.LG&sortBy=submittedDate&sortOrder=descending&start=0` (proof: stack run 44092000441's log line).
- (7) Risk 1 → new **ING-6f** (backend, P1, Ready): an informational `stack.yml` step prints the recorded `cat:cs.LG` feed's `published` order plus a `RISK1 ORDER` verdict in the job log. It is independent of #56/#57. It must not run in parallel with OPS-H12 (same file), so ING-6f goes first. ING-6b now needs ING-6f's verdict `descending` (the result only, not a merge).
- (8) Done rule in ING-6a: Done when **both** #57 (6a1: AC6, AC7) and #56 (6a2: AC1–5, AC8, AC10) merge. QA scopes each PR to its own ACs. ING-6b Depends on and Status updated. ING-6 umbrella lists 6f.
- Board/Jira not edited (orchestrator): add ING-6f Ready (backend, P1); ING-6b blocker = #56 + #57 merged + ING-6f verdict; Jira story for ING-6f under KAN-18, `labels = "task-ING-6f"`.

## 2026-11-17 13:00Z — orchestrator (scheduled cycle, session_01ATEBeVYveQa9STKGf1pSf5) — cut short by API rate limit
- Lock: 07:59Z lock was stale (last commit 08:54Z) → taken 13:00Z, refreshed 14:07Z. Push dry-run, app clone, Jira read OK.
- Sync: no human reviews/untagged comments on #51–#54. Board reconciled by pm-lead (`07e6aef`; 16 merged rows → Done).
- Review: EVAL-4 #51 QA r2 PASS (saved verbatim) → PM APPROVE, raised. AI-8a #54 QA r1 FAIL → rework r1 (`a0a2ced`) → QA r2 FAIL (finding 8) → rework r2 (`990aa5a`) → QA r3 PASS. AC1 [spec] → pm-lead option (a): new backend task AI-8c (`ace9462`).
- New work: OPS-H11 (#55, backend) built → QA r1 PASS → PM APPROVE, raised; follow-up OPS-H12. ING-6 design written (`dbeec46`) → PM approved w/ conditions 1–10 (`e7da8d2`); ING-6a built, split per condition 8 into 6a1 (branch) + 6a2 (#56) → QA r1 FAIL (finding 1, undated guard unpinned).
- Stopped at ~14:16Z: API rate limit killed the AI-8a PM review and ING-6a2 rework subagents mid-task. When the session resumed (18:19Z) a newer cycle (18:00Z, session_01ATEBeSxKE7HJwcR5ANiS3B) held the lock and had already picked both up (`7197210`, `a40af52`), so this cycle did not record board/metrics/Jira or release a lock (the current lock is the newer cycle's). Jira sync for this cycle's moves (KAN-30, KAN-60, OPS-H11/ING-6a/AI-8c/OPS-H12 stories) is left to that cycle.
- Retro note: sprint.md Step 5 ("second FAIL → Blocked") conflicts with AGENTS.md §2 ("max 2 rework rounds per cycle"); this cycle followed AGENTS.md for AI-8a.

## 2026-11-17 pm-lead: ING-6a1 (#57) final review
- **APPROVE** at `c86bd5a`. QA r1 was PASS, and all 6 CI checks are green. AC6, AC7 and AC9 are met for the 4 new files, and I checked all 11 `6a1-*` evidence files. Verdict: `agents/reviews/ING-6a/report-6a1.md` (`3e2bf73`).
- QA findings: nits 1 and 3 and the store half of nit 2 (M6, a read error treated as "no watermark") go into **ING-6c AC10**, which already edits the test file and wires it into `db.yml`. The caller half of nit 2 goes into **ING-6b AC9** (`TestRunOnceWatermarkReadError`). For [spec] 4, ING-6c AC7 now names the exact `go vet`/`go test -v` commands for `./internal/db/`.
- PR #57: description rewritten with the Evidence section (images pinned to `93a9349`), ready for review (`draft=false`), label `ready-to-merge`. The outbound filter rewrote the PATCHed body again: all 8 embeds and 3 links lost their `!` or got wrapped in backticks, and the 🤖 line was replaced by the footer (lesson OPS-H8, 6th time). I did not touch the board or Jira; the orchestrator does those. #56 was left alone.

## 2026-11-17 pm-lead: ING-6a2 (#56) final review
- **APPROVE** at `3f8e903` (QA r1 FAIL @ `3756173` → rework r1 → QA r2 PASS). I opened all 9 `r2-*` evidence files and round-1 `03`/`04`/`05`/`07`. Round-1 findings 1–4 are closed (M5, M23, M24, M27 and the extras M28–M34 are killed in both runs, r2-06), the harness control reproduces round 1 (r2-01/02), and 6/6 CI checks are green on the head. Verdict: [report](reviews/ING-6a/report.md), "PM final review" section.
- QA nit 2 (426 lines > 400 target, < 480 gate): accepted, since `loop.go` is unchanged and the +28 are the rework tests. Nit 1 (stale PR body): fixed by my rewrite.
- PR #56: description rewritten (Evidence pinned to `57f679e`/`183f7d9`/`4894a2e`/`12b2bae`, CI, QA + PM verdicts, the AC10 `published` values, Risk 1 → ING-6f), then raised. ING-6a is Done only when #56 and #57 both merge.
- Raised: `draft=false` verified, label `ready-to-merge` added. The outbound filter rewrote the PATCHed body again: all 8 image embeds and 16 links lost `!` or were wrapped in backticks, and the 🤖 line was replaced by the footer (lesson OPS-H8, 7×). Not worked around; the pinned evidence pack is the record.
- Board/Jira not edited (orchestrator): ING-6a2 → Ready to merge.

## 2026-11-17 pm-lead: ING-6f (#58) final review
- **APPROVE** at `61e44e1` (QA r1 FAIL on the PR body only → r2 PASS, same head; 6/6 CI green). I checked all 17 evidence files. Verdict: [report](reviews/ING-6f/report.md), "PM final review".
- **Risk 1:** `RISK1 ORDER descending` (`2026-11-16T18:59:38Z` ≥ `2026-11-16T18:58:55Z`, job 134275963367) satisfies ING-6b's ING-6f precondition. ING-6b's blocker text now reads: #56 + #57 merged only.
- [spec] fixes in `agents/tasks/ING-6f.md`: AC3 now compares against same-base PR controls (`stack.yml` has 0 runs on `main`); the "fixed until the cache key changes" Note is corrected (the replay cache is per branch).
- QA nit 2 (`continue-on-error: true` on the probe) is folded into **OPS-H12** (Scope + AC6). OPS-H12 is now `Blocked (needs ING-6f #58 merged)`. Nit 3 (lexical compare) is accepted with no follow-up.
- **Backlog candidate (orchestrator: add a Backlog line, not specced): OPS-H13** (backend, P2, `stack.yml`): seed a main-scoped arXiv replay cache, e.g. `workflow_dispatch` on `main` saving the store under a key PR branches restore. That way every PR replays one fixed recording instead of re-recording about 5 live requests on each new branch's first run. It should also fix the header claim "0 arXiv requests per run once recorded". It isn't a §9 violation (the replay script is ≥ 3 s apart with an identifying User-Agent), so it's P2.
- PR #58: description rewritten (Evidence pinned to `27b6692`/`e352052`), raised (`draft=false`), label `ready-to-merge`. The outbound filter rewrote the PATCHed body again: all 13 image embeds lost their `!` or were wrapped in backticks, and the 🤖 line was replaced by the footer (lesson OPS-H8, 8×). Not worked around; the pinned evidence pack is the record.
- Board/Jira not edited (orchestrator): ING-6f → Ready to merge; OPS-H12 → Blocked (needs #58 merged); ING-6b blocker text.

## 2026-11-17 18:00Z — orchestrator (scheduled cycle, session_01ATEBeSxKE7HJwcR5ANiS3B)
- Lock: the 13:00Z cycle's lock (refreshed 14:07Z) was stale (> 100 min) and never released; taken over. That cycle had not run Step 8, so this entry and the board also cover its outcomes (AI-8a QA r3 PASS, OPS-H11 raised, ING-6a split/QA r1).
- Sync: ArxivLens `main` still `40dec5a`; no merges, no PR closed. No human (untagged) review or comment on #51–#56. ADRs unchanged.
- **AI-8a** #54 (KAN-60): PM **APPROVE** @ `990aa5a` (QA FAIL r1, r2 → PASS r3, last cycle) → raised. AC7 eval "not run" accepted; AI-8b AC9 amended to compare the first nightly eval after merge.
- **ING-6a2** #56 (KAN-63): rework r1 (test-only, +29/−1, head `3f8e903`, 426 lines) → QA **PASS r2** (27/27 + 11 new mutants killed) → PM **APPROVE** → raised.
- **ING-6a1** #57 (KAN-63), new this cycle (branch already built at `c86bd5a`; backend had 1 active PR): draft opened → QA **PASS r1** → PM **APPROVE** → raised. Nits folded into ING-6b AC9 / ING-6c AC7, AC10. Independent: four new files, none in any open PR.
- **ING-6f** #58 (KAN-64), new this cycle (created by pm-lead from ING-6a [spec] 7; backend had 0 active PRs after the raises): built `61e44e1` (+35, `stack.yml` only) → QA FAIL r1 (PR body lacked AC1/AC2/AC5 content) → body-only rework → QA **PASS r2** → PM **APPROVE** → raised. Risk 1: `RISK1 ORDER descending` (`2611.21608v1` 18:59:38Z ≥ `2611.21602v1` 18:58:55Z), so ING-6b's ING-6f precondition is met. Independent: no open PR touched `stack.yml`; OPS-H12 (same file) now Blocked on #58.
- pm-lead decisions: ING-6a findings 6–8 (AC4 bytes amended, ING-6f created, two-PR Done rule); ING-6f [spec] (AC3 controls, per-branch replay cache Note); OPS-H13 Backlog.
- Not started: EVAL-10 (`evals/README.md` overlaps #51), OPS-H7a/OPS-H9 (wait on #52), FE-1 (npm still unreachable), OPS-H12 (after #58).
- Jira: drift fixed (KAN-30 EVAL-4 In QA → Ready to merge); created KAN-62 OPS-H11, KAN-63 ING-6a, KAN-64 ING-6f (Ready to merge), KAN-65 ING-6b, KAN-66 ING-6c, KAN-67 AI-8c (blocked), KAN-68 OPS-H12 (blocked), KAN-69 EVAL-10; KAN-60 → Ready to merge.
- PR bodies: the outbound filter rewrote image embeds and the footer on #54, #56, #57, #58 again (lesson OPS-H8).

## 2026-11-17 20:00Z — orchestrator (scheduled cycle, session_01ATEBeT8hKbwoyPEKnZVhdJ)
- Lock: none present → taken (`43530af`). Push dry-run (arxivlens-agents), app clone + branch push probe (ArxivLens) and Jira all OK.
- Sync: no merges (ArxivLens main still `40dec5a`). No human reviews, review comments or untagged comments on #51–#58; every PR head matches its QA PASS + PM APPROVE commit. No Jira intake or updates since the 18:00Z cycle.
- Review: nothing queued.
- New work: **none started**. OPS-H7a/OPS-H9 wait on #52; EVAL-10 needs `evals/README.md`, which #51 changes; FE-1 env-blocked (registry.npmjs.org still doesn't resolve, re-checked 20:00Z); everything else waits on #54/#56/#57/#58 merging or on ADRs.
- **Waiting on Mahesh: 8 PRs ready for review (#51–#58).**

## 2026-11-17 21:00Z — orchestrator (scheduled cycle, session_01ATEBeV2kBqJLr6VqyDKy61)
- Lock: none present → taken (`e734a2a`). Push dry-run (arxivlens-agents), app clone and Jira all OK.
- Sync: no merges (ArxivLens main still `40dec5a`). No human reviews, review comments or untagged comments on #51–#58; PR heads unchanged since their QA PASS + PM APPROVE. No ADR status changes. No Jira updates since the 18:00Z cycle.
- Review: nothing queued. New work: **none started** (same constraints as 20:00Z; registry.npmjs.org still unreachable, re-checked 21:00Z).
- **Waiting on Mahesh: 8 PRs ready for review (#51–#58).**

## 2026-11-17 22:00Z — orchestrator (scheduled cycle, session_01ATEBeQxsQv9wqXSj4DVGpJ)
- Lock: none present → taken (`49d7eff`). Push dry-run (arxivlens-agents), app clone and Jira all OK.
- Sync: no merges (ArxivLens main still `40dec5a`). No human reviews, review comments or untagged comments on #51–#58; PR heads unchanged since their QA PASS + PM APPROVE. No ADR status changes. No Jira updates since 19:06Z (18:00Z cycle).
- Review: nothing queued. New work: **none started** (same constraints as 20:00Z; registry.npmjs.org still unreachable, re-checked 22:00Z).
- **Waiting on Mahesh: 8 PRs ready for review (#51–#58).**

## 2026-11-17 23:00Z — orchestrator (scheduled cycle, session_01ATEBeUmwhLLainYSh1k9KU)
- Lock: none present → taken (`c09cc87`). Push dry-run (arxivlens-agents), app clone and Jira all OK.
- Sync: no merges (ArxivLens main still `40dec5a`). No human reviews, inline review comments or untagged comments on #51–#58; PR heads unchanged since their QA PASS + PM APPROVE. No ADR status changes, no arxivlens-agents PRs. No Jira updates since 19:06Z.
- Review: nothing queued. New work: **none started** (OPS-H7a/OPS-H9 wait on #52, EVAL-10 on #51, FE-1 env-blocked: registry.npmjs.org still unreachable, re-checked 23:00Z; the rest depend on unmerged PRs or Proposed ADRs).
- **Waiting on Mahesh: 8 PRs ready for review (#51–#58).**

## 2026-11-18 00:00Z — orchestrator (scheduled cycle, session_01ATEBeS4bUgtB4U5Ei8JzSc)
- Lock: none present → taken (`10828d4`). Push dry-run (arxivlens-agents), app clone and Jira all OK.
- Sync: no merges (ArxivLens main still `40dec5a`). No human reviews, inline review comments or untagged comments on #51–#58; PR heads unchanged since their QA PASS + PM APPROVE. No ADR status changes, no arxivlens-agents PRs. No Jira updates since 19:06Z.
- Review: nothing queued. New work: **none started** (OPS-H7a/OPS-H9 wait on #52, EVAL-10 on #51, FE-1 env-blocked: registry.npmjs.org still unreachable, re-checked 00:00Z; the rest depend on unmerged PRs or Proposed ADRs).
- **Waiting on Mahesh: 8 PRs ready for review (#51–#58).**

## 2026-11-18 01:00Z — orchestrator (scheduled cycle, session_01ATEBeUS66gUaws2SbrGAGH)
- Lock: none present → taken (`b0cf929`). Push dry-run (arxivlens-agents), app clone and Jira all OK.
- Sync: no merges (ArxivLens main still `40dec5a`). No human reviews, inline review comments or untagged comments on #51–#58; PR heads unchanged since their QA PASS + PM APPROVE. No ADR commits, no arxivlens-agents PRs. No Jira updates since 19:06Z.
- Review: nothing queued. New work: **none started** (OPS-H7a/OPS-H9 wait on #52, EVAL-10 on #51, FE-1 env-blocked: registry.npmjs.org still unreachable, re-checked 01:00Z; the rest depend on unmerged PRs or Proposed ADRs).
- **Waiting on Mahesh: 8 PRs ready for review (#51–#58).**

## 2026-11-18 02:00Z — orchestrator (scheduled cycle, session_01ATEBeVEc4feHFN34RM9zQ7)
- Lock: none present → taken (`d07be19`). Push dry-run (arxivlens-agents), app clone and Jira all OK.
- Sync: no merges (ArxivLens main still `40dec5a`). No human reviews, inline review comments or untagged comments on #51–#58; PR heads unchanged since their QA PASS + PM APPROVE. No ADR commits, no arxivlens-agents PRs. No Jira updates since 19:06Z.
- Review: nothing queued. New work: **none started** (OPS-H7a/OPS-H9 wait on #52, EVAL-10 on #51, FE-1 env-blocked: registry.npmjs.org still unreachable, re-checked 02:00Z; the rest depend on unmerged PRs or Proposed ADRs).
- **Waiting on Mahesh: 8 PRs ready for review (#51–#58).**

## 2026-11-18 03:00Z — orchestrator (scheduled cycle, session_01ATEBeVVnt8yZukoimHZzko)
- Lock: none present → taken (`3f02d2c`). Push dry-run (arxivlens-agents), app clone and Jira all OK.
- Sync: no merges (ArxivLens main still `40dec5a`). No human reviews, inline review comments or untagged comments on #51–#58; PR heads unchanged since their QA PASS + PM APPROVE. No ADR commits, no arxivlens-agents PRs. No Jira updates since 19:06Z.
- Review: nothing queued. New work: **none started** (OPS-H7a/OPS-H9 wait on #52, EVAL-10 on #51, FE-1 env-blocked: registry.npmjs.org still unreachable, re-checked 03:00Z; the rest depend on unmerged PRs or Proposed ADRs).
- **Waiting on Mahesh: 8 PRs ready for review (#51–#58).**

## 2026-11-19 — pm-lead (EVAL-10 final review, session_01ATEBeSGqS7NnAXfmeu62dA)
- EVAL-10 / PR #61 (`164305b`): **APPROVE** after QA PASS r1. I opened every evidence file in `9d8ab39`. The verdict is in `agents/reviews/EVAL-10/report.md`.
- Follow-up EVAL-10a specced (ai, P3, error-outcome tests; starts after #61 merges). The `make lint` Python target (AI-11 follow-up (a)) still needs grooming: 63 pre-existing ruff findings at line length 130.
- PR #61: description rewritten with the evidence, marked ready for review. Board and Jira are left to the orchestrator.

## 2026-11-19 14:53Z — orchestrator (manual cycle at Mahesh's request: "review and merge the PRs and pick up next tasks", session_01ATEBeSGqS7NnAXfmeu62dA)
- Lock taken (`agents/RUN_LOCK`), released in this commit.
- **Merged #51–#58 on Mahesh's explicit instruction** (agents never merge on their own; this was his call, made live in the session). Before merging, every PR was checked: head unchanged since QA PASS + PM APPROVE, `mergeable_state: clean`, all CI check runs green, and all eight test-merged together locally on `origin/main` with no conflicts. Squash-merged in dependency order #52, #51, #53, #54, #55, #57, #56, #58 → ArxivLens `main` = `8b55af2`; main CI (Go, Python M0, Frontend, DB) green after the merges. Jira KAN-59, KAN-30, KAN-14, KAN-60, KAN-62, KAN-63, KAN-64 → Done.
- New tasks (3, all independent: disjoint files, deps merged): **AI-8c** (backend, P0, `synthesis_test.go`; unblocks AI-8b), **ING-6b** (backend, P1, `internal/crawler/loop*.go`, `crawler.go`; unblocks ING-6c), **EVAL-10** (ai, P2, `scripts/evaluate_answers.py`, `tests/test_evals_data.py`, `evals/README.md`). Backend capped at 2, so OPS-H7a / OPS-H12 / OPS-H9 wait; FE-1 still env-blocked (npm).
  - AI-8c → PR [#59](https://github.com/MaheshPulivarthi18/ArxivLens/pull/59) @ `dd5dac5`: 1 attempt, QA PASS r1, PM APPROVE r1 → Ready to merge (KAN-67).
  - ING-6b → PR [#60](https://github.com/MaheshPulivarthi18/ArxivLens/pull/60) @ `ea3bf32` (443 lines): 1 attempt, QA PASS r1 (nits: cross-listed publish-fail test gap, doubled `cat:` prefix → ING-6c AC11; design build note written by pm-lead), PM APPROVE r1 → Ready to merge (KAN-65).
  - EVAL-10 → PR [#61](https://github.com/MaheshPulivarthi18/ArxivLens/pull/61) @ `164305b`: 1 attempt, QA PASS r1, PM APPROVE r1 → Ready to merge (KAN-69). Follow-up EVAL-10a specced.
- QA harnesses couldn't write `report.md`; the orchestrator saved each QA PR comment verbatim with a provenance line (`d73e36a`).
- Friction: the three PM agents shared one checkout of this repo, and one `git pull --rebase` retry failed on another agent's unstaged changes (its push had already landed). Next time give parallel memory-writing agents their own worktree.
- **Waiting on Mahesh: 3 PRs ready for review (#59–#61)**; ADRs and FE-1 npm egress / EVAL-8 question unchanged.

## 2026-11-19 16:00Z — orchestrator (scheduled cycle, session_01ATEBeSVMkYAKhRYdxuTFXH)
- Lock: none present → taken (`9c65609`), released in this commit. Push dry-run (arxivlens-agents), app clone and Jira all OK.
- Sync: ArxivLens main still `8b55af2`. No human reviews, inline comments or untagged comments on #59–#61 (heads unchanged since QA PASS + PM APPROVE); no Jira intake. No ADR changes. FE-1 still env-blocked (registry.npmjs.org unreachable, re-checked 16:00Z).
- New tasks (2, both backend, which had 0 active PRs; independent: disjoint files from each other and from #59–#61, all deps merged): **OPS-H7a** (`internal/dlq/`, `db.yml`, `go.mod`) and **OPS-H12** (`stack.yml` only). OPS-H9 shares `db.yml` with OPS-H7a, so it waits; nothing else Ready (EVAL-10a waits on #61, FE tasks on FE-1).
  - OPS-H7a → size gate fired (skeleton projected ~890 lines / ~420 non-test), so the branch ships the named **OPS-H7a1** seam only → PR [#62](https://github.com/MaheshPulivarthi18/ArxivLens/pull/62) @ `d420463` (480 lines): 1 attempt, QA PASS r1 (AC2 real-Kafka run in db.yml: 1,500 records, 123 non-empty polls; 25/28 mutants killed), PM APPROVE r1 → Ready to merge (KAN-70, created this cycle). pm-lead specced **OPS-H7a2** (KAN-71) for AC1/AC5/Docs + missing-topic decision; OPS-H7b now waits on a2 too.
  - OPS-H12 → PR [#63](https://github.com/MaheshPulivarthi18/ArxivLens/pull/63) @ `89fd583` (6 lines): 1 attempt, QA PASS r1 (235 PASSED lines = 235 passed), PM APPROVE r1 → Ready to merge (KAN-68). Human check left for Mahesh: the AC4 step summary has no PASSED lines.
- QA harnesses again refused to write `report.md`; orchestrator saved both PR comments verbatim (`ec6f82a`). Parallel memory writers each had their own arxivlens-agents worktree this time: no rebase collisions.
- **Waiting on Mahesh: 5 PRs ready for review (#59–#63)**; ADRs, FE-1 npm egress and the EVAL-8 question unchanged. pm-lead docs PR owed: Product PRD OPS-2 ✅ → ◐ (design condition 7).

## 2026-11-19 17:00Z — orchestrator (scheduled cycle, session_01ATEBeUfitpLCLt6QS9wDoW)
- Lock: none present → taken (`d12cc0f`), released in this commit. Push dry-run, app clone and Jira OK. (The sandbox's local `main` held stale idle-cycle commits not on origin; left untouched, worked on a fresh branch from `origin/main`.)
- Sync: ArxivLens main still `8b55af2`. #59–#63 open, heads unchanged since QA PASS + PM APPROVE; no human reviews, inline or untagged comments; no Jira intake or human comments. No ADR changes. FE-1 still env-blocked (registry.npmjs.org doesn't resolve, 17:00Z).
- New code tasks: **0**. Every Ready/Backlog task waits on an unmerged PR (OPS-H9/OPS-H7a2 → #62; EVAL-10a → #61; ING-6c/6d/6e/9b → #60; AI-8b → #59; OPS-H13 shares `stack.yml` with #63) or on FE-1.
- pm-lead raised the owed docs PR: Product PRD OPS-2 ✅ → ◐ partial (OPS-H7 design condition 7) → arxivlens-agents [#12](https://github.com/MaheshPulivarthi18/arxivlens-agents/pull/12), 1-line diff.
- **Waiting on Mahesh: 5 ArxivLens PRs ready for review (#59–#63) + arxivlens-agents #12**; ADRs, FE-1 npm egress and the EVAL-8 question unchanged.

## 2026-11-19 17:32Z — orchestrator (Mahesh: "i merged prs update status on jira", session_01ATEBeSVMkYAKhRYdxuTFXH)
- Mahesh merged #59 (AI-8c), #61 (EVAL-10), #63 (OPS-H12), #60 (ING-6b), #62 (OPS-H7a1) at 17:27–17:29Z. Jira KAN-67, KAN-69, KAN-68, KAN-65, KAN-70 → Done.
- Unblocked (`blocked` label removed, orchestrator comment): AI-8b (KAN-61), ING-6c (KAN-66), OPS-H7a2 (KAN-71). OPS-H9 and EVAL-10a deps now merged too. Board moved them to Ready. No open agent PRs.

## 2026-11-19 — pm-lead (FE-0 design review; OPS-H9 [spec] finding)
- **FE-0 design approved with conditions** (`docs/design/FE-0.md` "PM decision"). Interim default theme dark until FE-3 (AC5 amended; FE-3 AC8 flips to `system`).
  `--input` ≥ 3:1 for control outlines while `--border` stays decorative (AC4). `dist/` greps are replaced by the CI Vite asset list + source checks;
  the `.prose` built-CSS check moves to FE-3 because Tailwind doesn't emit unused classes (AC2/AC3). The "Clinical Research AI" badge is dropped (reversible, flagged for Mahesh).
- **Split:** FE-0 now covers the design's "FE-0a" (~400 lines, branch `agent/frontend/FE-0`). New spec `agents/tasks/FE-0b.md` has the six other primitives
  (new files only) and waits for a frontend WIP slot. FE-3 and FE-4 now also depend on FE-0b. FE-2 doesn't. Backlog: OPS-H14 (CI `dist/` greps), plus a `theme.test.js` follow-up.
- **OPS-H9:** AC2 accepts tag + digest, and AC3 accepts a PR-triggered run (`workflow_dispatch` can't run before merge). QA finding 6 [spec] is closed.

## 2026-11-19 18:00Z — orchestrator (scheduled cycle, session_01ATEBeSANjw6u4MNzB2FBiE)
- Lock: none present → taken (`daa23b0`). Push dry-run, app clone and Jira OK. No open agent PRs, no human reviews/comments, no Jira intake.
- Plan (pm-lead): only 2 independent tasks. Every Ready backend task and AI-8b touch `README.md`; EVAL-10a shares `tests/test_evals_data.py` with AI-8b;
  ING-6c/OPS-H7a2 share `cmd/arxivlens/main.go`; ING-6c/OPS-H9 share `db.yml`. pm-lead moved OPS-H9's one README prerequisite line into ING-6c
  (ING-6c now depends on OPS-H9) and picked **AI-8b** (P0) + **OPS-H9** (`4185bb8`).
- AI-8b → draft [#65](https://github.com/MaheshPulivarthi18/ArxivLens/pull/65) @ `9b2778f` (198 lines); AC9 eval dispatched on the branch (run 44584838337). KAN-61 → In QA.
- OPS-H9 → draft [#66](https://github.com/MaheshPulivarthi18/ArxivLens/pull/66): attempt 1 `3c1dadb` failed Image pins on shellcheck SC2001 (bundled in the
  actionlint image, not in the local build); attempt 2 `e875fa8`. KAN-45 → In QA. Build notes `d4ae8fa`.
- Stopped at ~18:21Z while polling CI (session suspended until 21:28Z). On resume the 21:00Z cycle (session_01ATEBeRGmCD5jzSfoDqn6n2) held the lock and had
  already run QA r1 on #65/#66 and rework on OPS-H9, so this cycle did not run QA/PM, record board/metrics, or release a lock (the current lock is that cycle's).
- 2026-11-19 (pm-lead) FE-0 final review: **APPROVE** PR [#69](https://github.com/MaheshPulivarthi18/ArxivLens/pull/69) @ `ca76bea` (QA PASS r1, evidence `b279a30`).
  PR body rewritten with the Evidence section (440 lines, QA nit 1), ready for review, label `ready-to-merge`. QA nit 2 → FE-0b Notes; theme tests → Backlog. Board: FE-0 → Ready to merge.

## 2026-11-19 21:00Z — orchestrator (scheduled cycle, session_01ATEBeRGmCD5jzSfoDqn6n2)
- Lock: `agents/RUN_LOCK` from 17:59Z (the 18:00Z cycle, which opened #65/#66 but never recorded or released) was > 100 min old → taken over (`d029bd4`), released in this commit. Push dry-run, app clone and Jira OK.
- Sync: no human reviews or untagged comments on #65/#66; Mahesh merged #64/#67 (frontend deps) himself, so FE-1 is unblocked. No ADR changes. Each parallel agent got its own arxivlens-agents worktree (`$HOME/mem/<name>`) and app worktree (`$HOME/wt/<name>`).
- **AI-8b → #65** (carried): QA FAIL r1 (claimStatus `unverified` branch untested, mutant M3 survived) → ai-engineer test-only rework `956db78` → QA PASS r2 (21/23 mutants, rest equivalent) → PM APPROVE → **Ready to merge** (KAN-61). 2 QA rounds, 1 PM round.
- **OPS-H9 → #66** (carried): QA FAIL r1 (`docker manifest inspect` false negative on cgr.dev pins; self-test accepted any failure) → pm-lead amended AC2/AC3 → backend rework `16dacb9` (buildx imagetools + digest match, positive-control self-test) → QA PASS r2 → PM APPROVE → **Ready to merge** (KAN-45). Unblocks ING-6c on merge.
- **FE-1 → #68** (new; independent: frontend test files only, deps #64/#67 merged): 1 attempt, CI green (19 Vitest tests), QA PASS r1, PM APPROVE → **Ready to merge** (KAN-19). AC3 fix: unsupported/unverified citations no longer say "Verified".
- **FE-0 → #69** (new, design-required; independent of FE-1 by file list): design `bcc377b` → pm-lead approved with conditions and split off FE-0b → build `ca76bea` (2 pushes for an oxlint warning) → QA PASS r1 → PM APPROVE → **reopened** when FE-0b's QA found `bg-popover` unmapped in `tailwind.config.js` (transparent ThemeToggle menu) → rework `dcb5420` → QA PASS r2 → PM APPROVE r2 → **Ready to merge** (KAN-72). Mahesh: three reversible UI choices to veto in the PR body (dark default until FE-3, badge removed, ink-blue accent).
- **FE-0b → #70** (new; new files only, frontend WIP free once #68/#69 were raised; Jira KAN-73 created): QA FAIL r1 (F1 popover unmapped — fixed in #69; F2 clipped focus ring) → rework `25ee640` → **In QA**: depends on #69 merging, QA r2 next cycle.
- Not started (not independent): ING-6c (needs #66 merged), OPS-H7a2 (root README with #65/#69), EVAL-10a (`tests/test_evals_data.py` with #65). FE-1 env-block resolved.
- QA harnesses again couldn't write `report.md` for AI-8b, OPS-H9, FE-0, FE-0b r1; orchestrator saved PR comments verbatim with provenance (`aac3c32`, `5d3dffb`, `ac95f88`).
- Retro (short, time-boxed): (1) a cycle that dies mid-way leaves a lock and unrecorded PRs — the next cycle's takeover worked, but Step 0 could note "previous cycle unrecorded" explicitly; (2) frontend QA must compile the diff's classes against the real Tailwind config (QA lesson `dbc8444`; pm-lead Backlog line for a `rules/` PR on `agents/area-notes/frontend.md`); (3) pm-lead commits `abfa173`/`ee3e0bc` carry a wrong Claude-Session trailer (not force-fixed).
- **Waiting on Mahesh: 4 PRs ready for review (#65, #66, #68, #69)**; ADRs and EVAL-8 question unchanged.

## 2026-11-19 23:00Z — pm-lead grooming (Step 3; Ready was empty: every Ready task waits on an unmerged PR)
- Specced 3 small tasks from existing Backlog lines, each independent of open PRs #65/#66/#68/#69/#70 and of each other (verified file lists via REST on 4c7d327):
  **OPS-H14** (backend, P3: `ci.yml` frontend job + new `.github/scripts/frontend-dist-report.sh`; report-only `dist/` font/CSS lines + `npm run test --if-present` instead of the EPIPE-prone `npm run | grep -q`),
  **OPS-H6b** (backend, P2: `internal/kafka/consumer.go` + test; skip the `Poll error … context canceled` log on clean shutdown),
  **AI-12** (ai, P2: `services/embedder/api.py`, `worker.py`, `tests/test_verify.py`; build ingest workers once, reuse the startup-loaded BGE model, serialize the pipeline).
- Not picked: `-race` in CI (needs `ci.yml` → clashes with OPS-H14, or `Makefile` + CONTRIBUTING note → #66); RET-1 `search.go` test nits (P3, backend cap of 2); `Makefile test-fe` EPIPE (Makefile, local only).
- Jira sync skipped: connector unavailable to pm-lead this session; three stories marked "to create" for the orchestrator.

## 2026-11-20 03:00Z — orchestrator (scheduled cycle, session_01ATEBeRyuD6DUxLPSWVCU4W)
- Lock: `agents/RUN_LOCK` from 2026-11-19T23:00:31Z (the 23:00Z cycle groomed + created KAN-74/75/76 but never built, recorded or released) was > 100 min old → taken over (`906f717`), released in this commit. Push dry-run, app clone and Jira OK.
- Sync: no merges since the 21:00Z cycle; no human reviews or untagged comments on #65/#66/#68/#69/#70; no Jira intake; no ADR changes. #65/#66/#68/#69 still Ready to merge; FE-0b #70 stays In QA until #69 merges.
- Plan: used the 23:00Z pm-lead grooming as-is (3 Ready tasks, independent of each other and of every open PR, re-verified against `pulls/<n>/files`). Backend and ai had 0 active PRs (their open PRs are Ready to merge). No 4th independent task (ING-6c/OPS-H7a2/EVAL-10a/FE-* all wait on unmerged PRs).
- **OPS-H14 → #71** (backend, `ci.yml` frontend job + new script): 1 attempt `84392b4`, CI green (dist/ report printed in CI, no `npm error`) → QA PASS r1 (`abc6635`/`e8f62e6`) → PM APPROVE (`35b0986`) → **Ready to merge** (KAN-74).
- **OPS-H6b → #72** (backend, `internal/kafka/consumer*.go`): 1 attempt `0fbf4e0`, CI green incl. Full stack → QA PASS r1 (mutants a/b/c killed; real franz-go probe shows the shutdown "Poll error" gone; `67faa18`) → PM APPROVE (`5192b06`) → **Ready to merge** (KAN-75).
- **AI-12 → #73** (ai, `services/embedder/api.py`, `worker.py`, `tests/test_verify.py`): 1 attempt `e34ebb9`, CI green incl. Full stack (seed ingest success, run 44665352254) → QA PASS r1 (12/13 mutants, survivor equivalent; `158054c`) → PM APPROVE (`3aea2d5`) → **Ready to merge** (KAN-76). `make eval` not run (no retrieval/answering change).
- QA harness again couldn't write `report.md` for OPS-H6b and AI-12; orchestrator saved the PR comments verbatim with provenance (`fd96e6c`). PM follow-ups → Backlog (3 lines).
- **Waiting on Mahesh: 7 PRs ready for review (#65, #66, #68, #69, #71, #72, #73)**; ADRs and EVAL-8 question unchanged.
- Retro (short): (1) second cycle in a row where a predecessor died after grooming without building — the takeover path works, and building the already-groomed tasks first kept this cycle short; (2) QA `report.md` write refusal is a standing harness limit (2/3 QA agents this cycle), fallback worked; (3) spec lesson from PM: ACs over conditional output formats should say "the line types that apply", not a fixed count (pm-lead lesson below).

## 2026-11-20 04:00Z — pm-lead grooming (Step 3; Ready column all waiting on unmerged PRs)
- Re-verified open PRs #65/#66/#68/#69/#70/#71/#72/#73 file lists via REST; app `origin/main` still `4c7d327` (no merges since the 03:00Z cycle).
- Specced 2 small backend tasks from existing Backlog lines, independent of every open PR and of each other:
  **LLM-1c** (P2: `internal/llm/openai.go` + `openai_test.go`; `transportDetail` reports `TLS certificate rejected` / `TLS handshake failed` as fixed strings, LLM-1b QA r2 nit 1),
  **RET-1b** (P3: `internal/query/search.go` + `search_test.go`; `context.Canceled` fallback row, ±Inf scores fall back like NaN; pm-lead decision in its Notes: pinning "Inf accepted" would pin an unencodable `/v1/search` body).
- Not picked: OPS-H13 (needs a seeding decision: `stack.yml` has 0 `main` runs, no `push` trigger); ING-11b finding 4 (one message string in a stack-only test; backend at 2, keep folding); EVAL-7 `build_rows` tests and EVAL-6 `classify()` follow-up (tests live in `tests/test_evals_data.py`, open in #65; a new test file needs backend's `Makefile` `test-py` list); `Makefile` `test-fe` EPIPE (backend at 2; plain `npm test` only works after #68); frontend `theme.test.js` (after #68/#69); `-race` (still `ci.yml` #71 or CONTRIBUTING #66). ai-engineer gets no task this cycle: every ai Backlog item touches #65 or #73 files.
- Jira: two stories "to create" for the orchestrator (LLM-1c under KAN-1, RET-1b under KAN-2).

## 2026-11-20 04:00Z — orchestrator (scheduled cycle, session_01ATEBeTxMFTK5Er4oL5NUyX)
- Lock: none present → taken (`2ee0467`), released in this commit. Push dry-run (both repos), app clone and Jira OK.
- Sync: no merges since 03:00Z; no human reviews or untagged comments on #65/#66/#68–#73; no Jira intake; no ADR changes. FE-0b #70 stays In QA until #69 merges.
- Plan: Ready was empty of independent work → pm-lead groomed 2 Backlog lines (`1e6815e`): **LLM-1c** (`internal/llm/`) and **RET-1b** (`internal/query/search*.go`), independent of every open PR and of each other (file lists re-checked via REST). Rejected: OPS-H13 (needs a main-cache decision), EVAL-7 tests (`test_evals_data.py` in #65), others listed in the grooming entry. Jira KAN-77/KAN-78 created.
- **LLM-1c → #74** (backend): 1 attempt `de27269` (+103/-0), CI green incl. Full stack → QA PASS r1 (mutants a–d killed, `transportDetail` coverage 75→80%; `328451f`) → PM APPROVE (`b9a36d0`) → **Ready to merge** (KAN-77).
- **RET-1b → #75** (backend): 1 attempt `8469844` (+20/-1), CI green incl. Full stack (F1 known-flake step identical to main base) → QA PASS r1 (7/7 mutants; base-control shows only the Inf rows fail on main; `12a2e57`) → PM APPROVE (`ed6a24c`) → **Ready to merge** (KAN-78). ±Inf-falls-back-like-NaN is a pm-lead spec decision, flagged for Mahesh on the PR.
- QA harnesses again couldn't write `report.md`; orchestrator saved both PR comments verbatim with provenance (`ba21d26`). PM follow-ups → Backlog (server.go ignored Encode error; optional rows; LLM-1c raw-string nit).
- **Waiting on Mahesh: 9 PRs ready for review (#65, #66, #68, #69, #71–#75)**; ADRs and EVAL-8 question unchanged.
- Retro (short): (1) 2/2 first-round PASS; small, mutant-specified ACs keep QA quick; (2) the QA `report.md` write refusal is now a standing harness limit (every QA agent for 3 cycles) — the verbatim-save fallback works, but the saved copies show the outbound filter's backtick rewrite of links (already a Backlog line); (3) the review queue for Mahesh keeps growing (9 PRs) while new Ready work depends on those merges — grooming more follow-ups adds review load rather than unblocking anything.

## 2026-11-20 05:00Z — pm-lead grooming (Step 3; Ready column all waiting on unmerged PRs)
- App `origin/main` = `e6cffba` (Mahesh merged #71–#75). Re-checked file lists of the 5 open PRs via REST: #65 (`README.md`, `internal/query/rag*.go`, `tests/test_evals_data.py`), #66 (`db.yml`, `image-pins.yml`, `CONTRIBUTING.md`, `docker-compose.yml`), #68/#69/#70 (`frontend/**`, #69 also root `README.md`).
- Specced 4 test-only tasks from existing Backlog lines, independent of every open PR and of each other (one file each, no shared contract):
  **OPS-H6c** (backend, P2, `internal/kafka/consumer_test.go`: deadline-ended ctx row, kills OPS-H6b QA mutant M9),
  **AI-12b** (ai, P2, `tests/test_verify.py`: `/internal/embed` returns while `/internal/ingest` holds `_ingest_lock` and uses the same model object; failed `EmbedderWorker` build keeps the cached processor),
  **ING-11c** (ai, P3, `tests/test_m2_pipeline.py`: "page row but NULL page_number" message; owner ai since `tests/` is shared and backend has 2),
  **LLM-1d** (backend, P3, `internal/llm/openai_test.go:585`: `"\r\n"` instead of the raw string; lowest value, droppable).
- Not picked: EVAL-6 `classify()` and EVAL-7 `build_rows` tests (both test in `tests/test_evals_data.py`, open in #65); AI-12 `stack.yml` second-paper timing (backend-owned `stack.yml` + replay prefetch list, needs its own spec); `server.go` Encode-error logging (no handler seam checked yet; next pass); frontend items (after #68/#69/#70).
- Review-load note: these add up to 4 more PRs to a Mahesh queue of 4 open Ready-to-merge PRs plus FE-0b; all are small test-only diffs.

## 2026-11-20 05:00Z — orchestrator (scheduled cycle, session_01ATEBeRtcx1qAVnuseYBn9i) — interrupted by a usage limit
- Sync: #71–#75 merged by Mahesh → Done (Jira KAN-74..78 → Done). No human reviews/comments on #65/#66/#68/#69/#70. #70 FE-0b still waits for #69 to merge before QA r2.
- Built 4 independent test-only tasks in parallel (each one file, no overlap with open PRs or each other):
  - **OPS-H6c** (KAN-79) → [#76](https://github.com/MaheshPulivarthi18/ArxivLens/pull/76) `6b1e814`: 1 attempt, QA PASS r1, PM APPROVE r1 (`agents/reviews/OPS-H6c/report.md`), raised (ready-to-merge).
  - **AI-12b** (KAN-80) → [#77](https://github.com/MaheshPulivarthi18/ArxivLens/pull/77) `249ff5d`: 1 attempt, QA PASS r1, PM APPROVE r1 recorded (`c5d177e`), but pm-lead was cut off before marking the PR ready: #77 is still draft, Jira PM review.
  - **ING-11c** (KAN-81) → [#78](https://github.com/MaheshPulivarthi18/ArxivLens/pull/78) `1f24fc9`: 1 attempt, QA PASS r1, PM APPROVE r1, raised (ready-to-merge).
  - **LLM-1d** (KAN-82) → [#79](https://github.com/MaheshPulivarthi18/ArxivLens/pull/79) `fc6d79d`: 1 attempt, QA PASS r1; PM review cut off here, completed by the 08:00Z cycle (APPROVE, raised).
- QA harness refused writing `report.md` for all four; orchestrator saved the PR comment bodies verbatim with a provenance line.
- Interrupted ~05:30Z by the 5-hour usage limit mid-PM-review; the 08:00Z cycle took over the stale lock. The 08:00Z cycle recorded the OPS-H6c/ING-11c PM verdicts (`3f75a9e`); this entry was added at ~08:10Z; the lock now belongs to the 08:00Z cycle, so this cycle did not delete it. Left for that cycle: raise #77 (AI-12b) and move KAN-80; board columns and Jira Ready to merge for #76–#79.
- Housekeeping: a push probe left an empty branch `agent/probe` (= main `e6cffba`) on ArxivLens; deleting it was refused by the sandbox's safety check. Mahesh can delete it.

## 2026-11-20 08:00Z — pm-lead grooming (Step 3; Ready column all waiting on unmerged PRs)
- App `origin/main` = `e6cffba` (#71–#75 merged). Re-checked file lists of the 9 open PRs via REST: #65 (`README.md`, `internal/query/rag*.go`, `tests/test_evals_data.py`), #66 (`db.yml`, `image-pins.yml`, `CONTRIBUTING.md`, `docker-compose.yml`), #68/#69/#70 (`frontend/**`, #69 also root `README.md`), #76 `internal/kafka/consumer_test.go`, #77 `tests/test_verify.py`, #78 `tests/test_m2_pipeline.py`, #79 `internal/llm/openai_test.go`.
- Specced 2 backend harness tasks from existing Backlog lines, independent of every open PR and of each other:
  **OPS-H15** (P2, `.github/workflows/ci.yml` job `go` only: `GOFLAGS: -race` on the `make test-go` step; racy-probe commit + revert proves the detector runs; stop-and-report on any race or `-race` timing flake; baseline step 6 s on run 44677460170),
  **OPS-H5b** (P2, `internal/query/search_integration_test.go` only: delete leftover/after-test `synth.%` papers, skip a non-empty DB locally and fail it under `CI`, new `TestHNSWSeedCleanup` picked up by `db.yml`'s existing `-run 'TestHNSW|…'`; seed line `seeded 13000 embeddings` must stay identical).
- Only 2 because backend is the only owner with eligible work and the WIP cap is 2 active PRs per developer. Not picked: `server.go` Encode-error helper (backend, P2; next backend slot, sketch on its Backlog line); ING-9 test follow-ups (backend P3); EVAL-6 `classify()`, EVAL-7 `build_rows`, EVAL-5 `CHUNK_COUNTS_SQL`, OPS-H5 F2 (ai; their tests live in `tests/test_evals_data.py`, open in #65, and a new test file needs backend's `Makefile` `test-py` list); OPS-H8 G4 embedder L2 ledger (ai P3; recording the ledger outside the processing transaction could skip a redelivery, needs a design); OPS-H6 G2 (needs `services/common/db.py` semantics or a column change → ADR); `stack.yml` second-paper timing and OPS-H13 (need a `main`-cache decision); frontend items (after #68/#69/#70).
- Board: the four 0a rows (OPS-H6c/AI-12b/ING-11c/LLM-1d) are Ready to merge per their specs and #71–#75 are merged; their board rows still need moving (left to the orchestrator's record step to avoid a parallel-edit conflict).

## 2026-11-20 13:00Z — pm-lead sync + grooming (Steps 2–3)
- Sync (app `origin/main` = `c37d27c`): #65 AI-8b, #66 OPS-H9, #68 FE-1, #69 FE-0, #76 OPS-H6c, #77 AI-12b, #78 ING-11c, #80 OPS-H15 merged 08:46–09:38Z → tickets and board Done. Also found never-recorded merges: #51–#63 (2026-11-19: EVAL-4, ING-11b, OPS-H2, AI-8a, OPS-H11, ING-6a1/a2, ING-6f, AI-8c, ING-6b, EVAL-10, OPS-H7a1, OPS-H12) and #71–#75 still said "Ready to merge" in their tickets → Done (Jira keys KAN-79/80/81 written into OPS-H6c/AI-12b/ING-11c).
- Open PRs via REST: #70 FE-0b (six `ui/*.jsx`, QA r3 running), #83 OPS-H7a2a (`cmd/arxivlens/main.go`, `internal/dlq/*`, QA r2 running), #79/#81/#82 Ready to merge. No ADR status change (0004/0005/0007–0009/0011–0013/0015/0018 still Proposed).
- Re-evaluated: ING-6c's deps all merged but it shares `cmd/arxivlens/main.go` with #83 (and README with OPS-H7a2b) → waits. FE-3/FE-2/FE-4 unblocked by #68/#69 except FE-0b #70. OPS-H7a2's README condition (#65/#69) is met. `rag.go` free; AI-5 still needs ADR-0011.
- Specced: **RET-1c** (backend, P2: `writeJSON` helper in `internal/query/server.go` + new `server_test.go`; encode failure → logged 500, success bytes identical to `Encoder.Encode`), **FE-0c** (frontend, P2 harness: new `src/lib/theme.test.js` + `ThemeToggle.test.jsx`; index.html/theme.js drift guard ahead of FE-3 AC8), **OPS-H7a2b** (backend, P1: the CLI half of OPS-H7a2, after #83 merges; folds QA OPS-H7a2 r1 findings 4, 6, 7).
- Plan for this cycle (3 picks): FE-3 design step only (P0, KAN-40), RET-1c, FE-0c. ai-engineer: no task independent of #82 (`tests/test_evals_data.py`) and of ADR-0011; nothing invented.

## 2026-11-20 08:00Z — orchestrator (scheduled cycle, session_01ATEBeV1rceor8faNPTfyTH) — interrupted by usage limit ~09:50Z
- Took over the stale 05:00Z lock. No human reviews on any agent PR. Finished the 05:00Z cycle's Step 6: PM APPROVE recorded for OPS-H6c #76 and ING-11c #78 (`3f75a9e`), AI-12b #77 raised (`f0d525f`), LLM-1d #79 PM APPROVE + raised (`9a0600a`); Jira KAN-79..82 → Ready to merge.
- Grooming picked 2 (OPS-H15, OPS-H5b); after Mahesh merged #65/#66/#68/#69 mid-cycle, 2 more were started (EVAL-10a, OPS-H7a2). 4 new tasks total, each touching files disjoint from every open PR.
  - **OPS-H15** (KAN-83) → #80: QA FAIL r1 (PR body was OPS-H5b's), body rewritten, QA PASS r2, PM APPROVE → **merged 09:38Z**.
  - **OPS-H5b** (KAN-84) → #81 `8cae68b`: QA PASS r1, PM APPROVE, raised.
  - **EVAL-10a** (KAN-85) → #82 `69aaaf4`: QA PASS r1, PM APPROVE, raised.
  - **OPS-H7a2** (KAN-71) → #83: size gate fired, split; PR is the a2a half (`Manager.List`/cursor). QA FAIL r1 (nextCursor branch untested; `Snapshot` not in design). Rework agent cut off by the usage limit after pushing `9bcd07e`; the 13:00Z cycle completed QA r2 PASS + PM APPROVE. OPS-H7a2b (CLI) specced by the 13:00Z cycle.
- **FE-0b** #70: QA FAIL r2 (F3 dark-mode toast description 1.56:1), frontend rework `d10dc7f` (CI green on main 3835dee); QA r3 PASS + PM APPROVE done by the 13:00Z cycle.
- QA reports for OPS-H15, OPS-H5b, EVAL-10a, OPS-H7a2 r1 saved verbatim from PR comments (QA harness can't write report.md).
- Not done here (lock owned by the 13:00Z cycle): board columns, retro. Jira synced; KAN-73/KAN-71 → Ready to merge at 13:17Z after their PM APPROVE commits.
- 2026-11-20 (pm-lead, FE-3 design review): `docs/design/FE-3.md` (ca6b59e) **Approved with changes**. Found: `HeroSearch.jsx:58` "Every claim is mathematically verified…" is always rendered, so AC1's whole-tree `/verified/i` assert would fail; FE-3a rewrites the sentence. Split approved: **FE-3a** Ready (P0, AC1–AC7, no #70 dependency, no overlap with open PRs #70/#79/#81–#85), **FE-3b** Blocked (after #70 + FE-3a + FE-0e). Q1: flip held until new **FE-0e** (P1, token sweep of IngestModal/InfrastructureModal/PapersLibrary/Toast + `tokens.test.js`) merges. Q2 hide Copy/Export on refusal; Q5 copy approved; Q3/Q6 (surface a full-stage `insufficient_evidence`?) left to Mahesh, on the board's Blocked list. Board: #84/#85 moved to In QA; FE-0d and FE-0e need Jira stories; FE-3a/FE-3b need Jira sub-items under KAN-40.
- 2026-11-20 (pm-lead, PM review FE-0c #85 @ `969c4fb`): **APPROVE r1**. QA PASS r1 evidence (00–05 at `e527bef`) covers AC1–AC7; scope = 2 new test files (285 lines). PR description rewritten with Evidence section (stale AC1 bullet + line count fixed), raised ready for review → board Ready to merge. QA nit 1 (README `*.test.jsx` glob) + optional no-`matchMedia` tests → Backlog (frontend P3); QA [spec] 3 → pm-lead lesson (ACs state intent, not syntax).
- 2026-11-20 (pm-lead, RET-1c #84 final review): **APPROVE** r1 on `baa6fa0` after QA PASS r1 (evidence 00–09 @ 0421dca, all opened). PR description rewritten with the Evidence section, marked ready for review → Ready to merge. QA nits: (1) call-site mutants m–p → new **RET-1d** (backend, P2, after #84 merges; `internal/query/server.go` + `server_test.go`, unexported dependency interfaces + handler contract test); (2) log restore → RET-1d AC5; (3) `/readyz` label accepted; (4) `[spec]` ticket Jira row → KAN-86. RET-1d needs a Jira story.

## 2026-11-20 13:00Z — cycle record (pm-lead, Step 8; session_01ATEBeUGNCnaoT2jfdHxb4j)
- Took over the stale 09:13Z lock (08:00Z cycle cut off by the usage limit). App `origin/main` = `c37d27c`; open PRs re-checked via REST: #70, #79, #81–#85 ready for review (Ready to merge), #86 draft.
- **FE-0b** (KAN-73) #70 `d10dc7f`: QA r3 PASS, PM APPROVE, raised → Ready to merge. QA rounds 3 (FAIL r1, FAIL r2), PM rounds 1. Follow-up FE-0d (KAN-90) specced.
- **OPS-H7a2 a2a** (KAN-71) #83 `9bcd07e`: QA r2 PASS (r1 FAIL), PM APPROVE, raised → Ready to merge. a2b CLI stays Ready after #83 merges.
- **RET-1c** (KAN-86) #84 `baa6fa0`: built, 1 attempt, QA PASS r1, PM APPROVE r1 (pm-lead entry above), raised. Follow-up RET-1d (KAN-92).
- **FE-0c** (KAN-87) #85 `969c4fb`: built, 1 attempt, QA PASS r1, PM APPROVE r1 (pm-lead entry above), raised.
- **FE-3** (KAN-40) design approved with changes (entry above) → split FE-3a (KAN-88) / FE-3b (KAN-89, Blocked) + new FE-0e (KAN-91).
- **FE-3a** (KAN-88) draft #86 `e90de79`: built, 1 attempt, 496 lines (App.test.jsx moved out per design change 5). QA **FAIL r1**: [blocking][spec] App-level tests for AC1/AC2/AC4/AC6 absent and untracked; nits: `Info` vs `CircleHelp`, chip `title`, 3 missing component cases. pm-lead decision **option (a)**: FE-3a AC1/AC2/AC4/AC6 amended, App-level tests specced as **FE-3a2** (P0, `App.test.jsx` only, after #86 merges; needs Jira story under KAN-5); `Info` accepted and recorded in `docs/design/FE-3.md`; `title` accepted until FE-3b (FE-3b AC1 now removes it); finding-4 cases added to FE-3a's ACs for the rework. Status Rework r1 (1 of 2); rework + QA r2 next cycle. Blockers: none.
- Jira keys recorded in tickets: FE-3a KAN-88, FE-3b KAN-89, FE-0d KAN-90, FE-0e KAN-91, RET-1d KAN-92 (Jira itself not touched by pm-lead).
- QA harness again couldn't write `report.md` for FE-3a; orchestrator saved the PR comment verbatim with a provenance line.


## 2026-11-20 18:00Z — pm-lead grooming (Step 3; session_01ATEBeUHm3hLaeUh4QMxhzc)
- App `origin/main` = `c37d27c`. Open PR files re-checked via REST: #70 (six `frontend/src/components/ui/*.jsx`), #79 (`internal/llm/openai_test.go`), #81 (`internal/query/search_integration_test.go`), #82 (`tests/test_evals_data.py`), #83 (`cmd/arxivlens/main.go`, `internal/dlq/{kafka,kafka_integration_test,manager,manager_test}.go`), #84 (`internal/query/server.go`, `server_test.go`), #85 (two frontend test files), #86 (FE-3a frontend files). No ADR status change.
- Specced 2 backend harness tasks, independent of every open PR and of each other: **OPS-H9b** (P3: `db.yml` `version_ge` numeric-only, `image-pins.yml` "no pin resolved" hint + drop tautological self-test `case`, CONTRIBUTING 60-day schedule-pause note) and **OPS-H16** (P3: `Makefile` `test-fe` runs `npm test` directly; removes the EPIPE `grep -q` pipe and the "no frontend tests yet" false green). Both need Jira stories.
- Not picked: `stack.yml` second-paper timing (adds live arXiv fetches and changes the replay recording; tied to the OPS-H13 cache question for Mahesh), shellcheck CI step (new failing check on a *Proposed* Backlog line), ai items (EVAL-5/6/7/10a follow-ups all add tests to `tests/test_evals_data.py`, open in #82; AI-5/EVAL-2 need ADR-0011/0012). The `tests/test_m2_pipeline.py` ruff nit (ai, P3, 2 findings) stays a fold-in candidate. Found two stale Backlog lines already done in code (AI-4 `Ask`-level trace-ID test; OPS-H5 F2 HNSW settings half) and annotated them.


## 2026-11-21 — pm-lead final review: OPS-H9b #88, OPS-H16 #89 (Step 6; session_01ATEBeUHm3hLaeUh4QMxhzc)
- **OPS-H9b #88** (`9a6907c`): QA PASS r1 → **PM APPROVE**. All 16 evidence files (00–07 at `b55a09d`) opened. All 5 ACs are proven by CI (DB job 136478144250: 11 dry-run rows + `pgvector 0.8.7 >= 0.8.0: ok`; Image pins job 136478143438: 3 × ok, 3 × (expected), actionlint clean) and by QA's harness (modes a/b/c, byte-identical re-pin line, mutants N1–N6 killed). QA nits 1–2 (`^`-anchor dry-run row, MinIO bullet) → one Backlog line folded into ING-6c. Nit 3 (FAIL + `::error::` duplicate) accepted. PR body rewritten with Evidence, marked ready for review → **Ready to merge**.
- **OPS-H16 #89** (`bf76769`): QA PASS r1 → **PM APPROVE**. All 18 evidence files (00–08 at `f0758cd`) opened. AC3 is accepted under "not run: registry blocked", with composed evidence (CI Frontend job 136478156455 runs the same `vitest run`, 19/19 tests, 0 `npm error`). QA `[spec]` finding 2 → specced **OPS-H17** (backend, P3, Ready: `ci.yml` frontend Test step `npm run test --if-present` → `npm test`; no open PR on `ci.yml`). PR body rewritten, marked ready for review → **Ready to merge**.
- Jira: both stories are being created by the orchestrator (no Jira edits by pm-lead). OPS-H17 needs a story too. Backend Active = 0; OPS-H17 is backend's only Ready task with no wait (OPS-H7a2b, RET-1d and ING-6c wait on #83/#84).
- Lesson added (pm-lead): an AC that needs a registry should name the CI job as its evidence, and a split Backlog line should be checked against its end state.

## 2026-11-20 UTC — pm-lead final review: FE-0e #87 (Step 6; session_01ATEBeUHm3hLaeUh4QMxhzc)
- **FE-0e #87** (KAN-91, `27953fd`): QA r1 FAIL (`50ef4d5`: Vite rewrote the guard's template-literal `new URL(…, import.meta.url)`, 4 × ENOENT in CI) → rework r1 → QA r2 PASS → **PM APPROVE**. All 14 evidence images (00–08 @ `9f1ddf2`, 09–13 @ `175d597`) opened. CI Frontend job 136486858137: 0 warnings, 24/24 tests, built; 5/5 checks green (re-checked via REST). PR description rewritten with the Evidence section, marked ready for review → **Ready to merge**.
- QA `[spec]` items: (a) FE-0e AC2 wording clarified ("set by a class string in the four files"); `ui/badge` `arxiv` is fixed by FE-3a #86 (opaque `bg-secondary`, 13.73/10.99:1, pm-lead calc); `ui/button` `clinical` (3.77/3.74:1, both themes) → new **FE-0f** (frontend, P1, Ready, needs Jira story; `ui/button.jsx` + new `ui/button.test.jsx`, no open-PR overlap). FE-3b's flip still waits on FE-3a #86 merged (confirmed). (b) Guard regex gaps → **FE-3b AC2** amended (more utilities, all palettes, `white`/`black` except `shadow`; widened pattern checked against #87's head: only `shadow-black/80` would hit, hence the exception). (c) `border-border` → `border-input` on inputs → Backlog (frontend, P3).
- Board: FE-0e and FE-3a (stale "In progress" row; ticket and #86 say Ready to merge at `fa92c30`) moved to Ready to merge; OPS-H17 (#90 draft) moved from Ready to In QA to match its ticket. No Jira edits by pm-lead (KAN-91 → Ready to merge left to the orchestrator; FE-0f needs a story).

## 2026-11-20 UTC: pm-lead, OPS-H17 #90 final review
- **OPS-H17 #90** (needs Jira story, head `9dae472`): QA r1 PASS with no findings, then **PM APPROVE**. I opened all 5 evidence files (00–04 at `4adb852`) and each proves its AC. The diff is only `ci.yml` +1/-1. I rewrote the PR description with the Evidence section, CI results and both verdicts, and marked it ready for review, so it is now Ready to merge. Board row moved from In QA to Ready to merge, and backend WIP is now 0. No Jira edits.

## 2026-11-20 18:00Z — cycle record (orchestrator, Step 8; session_01ATEBeUHm3hLaeUh4QMxhzc)
- Took over the stale 14:59Z lock (the 15:00Z cycle took the lock and left no other commit or record). Push access to arxivlens-agents proven (dry-run + lock push). App `origin/main` = `c37d27c` (no merges since 13:00Z). No human reviews or untagged comments on any open agent PR (#70, #79, #81–#86).
- **FE-3a** (KAN-88) #86: rework r1 (F4 test-only cases +36/−1, head `fa92c30`; F1 PR-body line by orchestrator; F2/F3 no change). QA r2 **PASS**, PM **APPROVE**, raised → Ready to merge. Rounds: QA 2 (FAIL r1), PM 1. Stale `qa-fail` label removed.
- **FE-0e** (KAN-91) #87 (new, frontend; files disjoint from #70/#85/#86): QA r1 **FAIL** (guard test: Vite rewrites a template-literal `new URL(…, import.meta.url)` → ENOENT in CI), rework r1 `27953fd` (node `path` + `matchAll`), QA r2 **PASS**, PM **APPROVE** (AC2 wording clarified for `ui/` variant colours), raised. Follow-up **FE-0f** (KAN-97, `ui/button` clinical variant 3.77:1); FE-3b AC2 widened guard regex; inputs `border-input` → Backlog.
- **OPS-H9b** (KAN-94) #88 (new, backend; `db.yml`, `image-pins.yml`, `CONTRIBUTING.md`, in no open PR): QA r1 PASS, PM APPROVE, raised. QA nits (^-anchor row, MinIO bullet) → Backlog, fold into ING-6c.
- **OPS-H16** (KAN-95) #89 (new, backend; `Makefile` only): QA r1 PASS (AC3 by composition: CI vitest + local reach `vitest run`), PM APPROVE, raised. QA [spec] 2 → specced **OPS-H17**.
- **OPS-H17** (KAN-96) #90 (new, backend; `ci.yml` 1 line, in no open PR, disjoint from #88/#89): QA r1 PASS, PM APPROVE, raised.
- Not picked: ai-engineer has no unblocked task (#82 holds `tests/test_evals_data.py`; AI-5/EVAL-2 wait on ADR-0011/0012). Backend Ready tasks OPS-H7a2b/ING-6c/OPS-H7b/RET-1d wait on #83/#84 merging. FE-3a2/FE-0d/FE-3b wait on #86/#70 merging.
- QA harness refused to write `report.md` for FE-0e r1, OPS-H9b, OPS-H16, OPS-H17; orchestrator saved the PR comments verbatim with provenance lines. Outbound filter still turns `![](…)` into backticked links in PR bodies/comments (images show as links).
- Jira: created KAN-94/95/96 (epic KAN-3) and KAN-97 (epic KAN-5); KAN-88, KAN-91, KAN-94–96 → Ready to merge with `[pm-lead]` comments; KAN-91 PR link filled.

## 2026-11-20 19:00Z — pm-lead (cycle 19:00Z sync + pick)
- Mahesh merged all 12 Ready-to-merge PRs at ~18:54Z (#70 FE-0b `4182485`, #79 LLM-1d `65824ff`, #81 OPS-H5b `36ceac0`, #82 EVAL-10a `21eb4e9`, #83 OPS-H7a2a `a0b80fe`, #84 RET-1c `110f6c7`, #85 FE-0c `d7d35ab`, #86 FE-3a `f95184b`, #87 FE-0e `1da13ee`, #88 OPS-H9b `c33110c`, #89 OPS-H16 `b1b26a7`, #90 OPS-H17 `230f617`); board rows and ticket Status → Done. No human reviews, no open agent PRs, no ADR change.
- Unblocked → Ready: FE-3a2, OPS-H7a2b, RET-1d, FE-0d, FE-3b (Blocked → Ready, starts after FE-3a2 merges). OPS-H7a2b README line refs re-checked on `230f617` (`README.md:186-188`; `main.go:322` unchanged); FE-0f line refs still valid.
- Picked (independent files): FE-3a2 (P0, unblocks FE-3b), OPS-H7a2b (P1, unblocks ING-6c/OPS-H7b), FE-0f (P1), RET-1d (P2). Not picked: FE-3b (waits on FE-3a2's App-level asserts; FE WIP 2/2), FE-0d (P2, FE WIP full), ING-6c/OPS-H7b (after OPS-H7a2b, `main.go`), FE-2/FE-4 (after FE-3b). ai-engineer has no Ready task: the `tests/test_evals_data.py`/`scripts/` follow-ups in Backlog are now unblocked and need specs next grooming.

- 2026-11-21 UTC · pm-lead · FE-0f (KAN-97) PR #92 final review: **APPROVE** (QA PASS r1; evidence 00–07 cover AC1–AC4). PR body rewritten with the Evidence section, ready for review, label `ready-to-merge`; draft=false. The body was rewritten by the outbound filter (13×). Board: FE-0f → Ready to merge. The HeroSearch spinner nit is folded into FE-3b AC2; the `[spec]` finding is a lesson. Jira → Ready to merge left to the orchestrator.

## 2026-11-21 — pm-lead (FE-3a2 final review)
- FE-3a2 / PR #91 @ `e7dc3c0`: **APPROVE** after QA r1 PASS. I checked all 10 evidence PNGs and their `.txt` twins (pinned to `4df0fb0`); CI is 5/5 green and the Frontend job shows 8 files / 121 tests and 0 warnings vs main's 7 / 114 / 0.
- Raised: PR description rewritten (Evidence table, CI per check, the AC6 M1–M19 mutant table marked reasoned, not executed, per QA nit 1, QA + PM verdicts). Marked ready, label `ready-to-merge`. Board → Ready to merge.
- Follow-ups: QA nit 2 (Toast mock hides toast text from AC1, M19) + QA missing tests (M18 stale search, full-stage failure, zero-citation refusal, discover failure) → Backlog (frontend, P2). Nit 3: re-run Frontend on whichever of #91/#92 merges second.
- 2026-11-21 UTC · pm-lead · RET-1d (KAN-92) PR #94 @ `a5bf0f4` final review: **APPROVE** (QA PASS r1). I opened all 22 evidence files (pinned `c01cc9d`) and re-checked CI 6/6 success through REST. PR body rewritten (Evidence per AC, "Docs: none", AC6 mutant table, CI links, verdicts), `draft=false`, label `ready-to-merge`. Board → Ready to merge. QA `[spec]` 3 fixed: AC3 amended (unencodable rows only where `json.Marshal` can fail; year-10000 `time.Time` for db types). New follow-up **RET-1e** (backend, P2, Backlog until #94 merges; Jira story pending): `http.Error`-path rows (e3 `/v1/stats` error 500→200 survives) + `SetIngester(non-nil)` (q2). Outbound filter de-embedded the PR images again (lesson OPS-H8). No Jira edits.

## 2026-11-20 19:00Z — cycle record (orchestrator, Step 8; session_01ATEBeRhWxo1r2DHbrmrHNz)
- Lock taken at 19:00Z (no prior lock); push access to arxivlens-agents proven (dry-run + lock push). Mahesh merged all 12 Ready-to-merge PRs (#70, #79, #81–#90) at ~18:54Z → Done in repo (pm-lead `a44070a`) and Jira (KAN-73, 82, 86, 87, 88, 91, 94, 95, 96). No human reviews or untagged comments on any agent PR; no Jira intake.
- **FE-3a2** (KAN-93) #91, frontend, `App.test.jsx` only: QA r1 **PASS** (3 nits; mutants reasoned, not executed), PM **APPROVE**, raised → Ready to merge. Follow-up tests → Backlog.
- **FE-0f** (KAN-97) #92, frontend, `ui/button.jsx` + new test: QA r1 **PASS** (8.73/8.11:1 idle, ≥6.67:1 hover), PM **APPROVE**, raised. Spinner nit folded into FE-3b AC2.
- **OPS-H7a2b** (KAN-71) #93, backend, `main.go` + `dlq_test.go` + README (395 lines): QA r1 **PASS** (Full stack `dlq list` footers in CI), PM **APPROVE** (footer `[spec]` accepted as specced), raised. Follow-up **OPS-H7a2c** (KAN-98).
- **RET-1d** (KAN-92) #94, backend, `internal/query/server.go` + test: QA r1 **PASS** (mutants m–q killed in QA harness), PM **APPROVE** (AC3 wording amended), raised. Follow-up **RET-1e** (KAN-99).
- Independence: the four PRs touch disjoint files (frontend App.test.jsx / ui/button.* ; cmd/arxivlens + README / internal/query); all `Depends on` were merged at 230f617.
- Not picked: FE-3b (waits on FE-3a2 merge; frontend at 2/2), FE-0d (frontend at 2/2), ING-6c/OPS-H7b (`main.go` queue behind #93), ai-engineer has no unblocked Ready task (EVAL-6/EVAL-7 Backlog items need specs).
- Rounds: QA 4 (all first-round PASS), PM 4 (all APPROVE), 0 rework. QA harness refused `report.md` 4×; orchestrator saved PR comments verbatim with provenance (`63075f1`). Outbound filter again un-embedded images in PR bodies. Worktrees landed at `/root/wt/<ID>` ($HOME=/root), not `/home/claude/wt` as the orchestrator told the developers.

## 2026-11-20 20:00Z — pm-lead (cycle 20:00Z grooming)
- Sync (orchestrator): no merges/closes since 19:00Z; #91–#94 all Ready to merge, no human reviews; ADRs unchanged; WIP 0 for every developer.
- Picked (independent of each other and of #91–#94's files; every `Depends on` merged at `230f617`): **FE-0d** (frontend, new `ui/primitives.test.jsx`), **EVAL-6b** (ai, new spec: `scripts/evaluate_answers.py`, `tests/test_evals_data.py`, `evals/README.md`; `classify()` raises `TypeError` on a list `refusal_reason` on `230f617`, `main` untested, EVAL-10a README/refusal-set nits), **OPS-H5c** (backend, new spec: `internal/query/search_integration_test.go`; refusal guard table test + cleanup hint), **ING-11d** (ai, new spec: `tests/test_m2_pipeline.py`; ruff F401 + W293 confirmed with ruff 0.16.9).
- Not picked: EVAL-7 `build_rows` and EVAL-5 `CHUNK_COUNTS_SQL` follow-ups (both still real, but share `tests/test_evals_data.py` with EVAL-6b; EVAL-5 "latest version" also touches the RET-2 v1/v2 product question). FE-3b/FE-2, ING-6c/OPS-H7a2c/OPS-H7b, RET-1e wait on #91/#93/#94 merging.
- Jira: not created by pm-lead (no Atlassian tools in this session); suggested epics EVAL-6b → KAN-2, OPS-H5c → KAN-3, ING-11d → KAN-4.

## 2026-11-20 20:00Z — orchestrator (cycle record)
- Setup: push dry-run OK on both repos; RUN_LOCK taken (`16cbc3a`); app cloned at `230f617`. Jira connector available (orchestrator did all Jira writes; subagents have no Atlassian tools).
- Human reviews: none on #91–#94 (only `[qa-reviewer]` comments); no Jira intake. No rework.
- **FE-0d** (frontend, KAN-90): PR [#95](https://github.com/MaheshPulivarthi18/ArxivLens/pull/95) @ `76b851c`, 1 attempt, QA r1 PASS (QA ran AC6 mutants; developer had no npm), PM APPROVE (AC5/AC6 wording amended) → Ready to merge. Follow-up FE-0g (Backlog).
- **EVAL-6b** (ai, KAN-100, new): PR [#96](https://github.com/MaheshPulivarthi18/ArxivLens/pull/96) @ `c053564`, 1 attempt, QA r1 PASS (14/14 mutants), PM APPROVE → Ready to merge. Follow-up EVAL-6c candidate (other malformed `/v1/ask` shapes).
- **OPS-H5c** (backend, KAN-101, new): PR [#97](https://github.com/MaheshPulivarthi18/ArxivLens/pull/97) @ `1d696c7`, 1 attempt, QA r1 PASS, PM APPROVE → Ready to merge. Follow-up: single-action `hnswGuard` (Backlog).
- **ING-11d** (ai, KAN-102, new): PR [#98](https://github.com/MaheshPulivarthi18/ArxivLens/pull/98) @ `03fa179`, 1 attempt, QA r1 PASS, PM APPROVE → Ready to merge.
- QA reports saved verbatim from PR comments by the orchestrator (`cdfdb14`; harness still blocks subagent writes of `report.md`). Board: the ING-11d row was left in Ready by a parallel-commit overlap; fixed in this record.
- Retro: worktree-path and shared-checkout lessons recurred → rules PR [arxivlens-agents#15](https://github.com/MaheshPulivarthi18/arxivlens-agents/pull/15) on `sprint.md` (Mahesh to merge).
- RUN_LOCK released in this commit.

## 2026-11-21 00:00Z — pm-lead (cycle 00:00Z grooming)
- Sync (orchestrator): no merges/closes since 20:00Z; app `main` = `230f617`; #91–#98 all Ready to merge, no human reviews or Jira intake; ADRs unchanged; WIP 0 for every developer. Every existing Ready task waits on an unmerged PR.
- Picked 3 new specs from Backlog follow-ups (every `Depends on` merged at `230f617`; files disjoint from each other and from #91–#98):
  **ING-9c** (backend, P3, test-only: `internal/query/ingester_test.go`, `internal/arxiv/limiter_test.go`; ING-9 QA nits 3 and 5: cancelled ctx → no arXiv request, limiter spacing d ≥ 100 ms),
  **OPS-H8c** (backend, P3: `docker-compose.yml` `stop_grace_period: 20s` on `x-worker`; OPS-H8 design follow-up, 12 s flush > 10 s default grace),
  **FE-0h** (frontend, P3: `IngestModal.jsx:82` + `PapersLibrary.jsx:53` `border-border` → `border-input` (pm-lead calc 3.23–3.50:1 vs 1.31–1.46:1), new `src/test/controls.test.js`, `frontend/README.md:14` glob `*.test.{js,jsx}`).
- Rejected: OPS-H8 `PYTEST_ARGS=-rA` (already in `stack.yml:286`; Backlog line struck); FE-0c `theme.test.js` no-`matchMedia` tests (FE-3b, P0, edits `theme.js`); RET-1b NaN+Inf/MaxFloat32 rows (real, `search_test.go` free, but backend would exceed 2 new PRs); ING-9 wiring test (needs db/storage interfaces) and redirect check (needs network); ai-engineer has no unblocked item (`tests/test_evals_data.py` held by #96, `tests/test_m2_pipeline.py` by #98, AI-5/EVAL-2 on ADRs, the AI-2 counter split is stale after the NLI verifier); `make test-py` split (needs `README.md`, held by #93).
- Jira not touched (orchestrator): suggested epics ING-9c → KAN-4, OPS-H8c → KAN-3, FE-0h → KAN-5.

## 2026-11-21 pm-lead: FE-0h final review (PR #101)
- APPROVE: QA r1 PASS; all 12 evidence files at `bdea793` opened, each AC proven (AC6 = CI Frontend job 136652677439, 8 files / 118 tests vs main 7 / 114). PR #101 raised (ready for review, label `ready-to-merge`); board → Ready to merge.
- QA [spec] #2 fixed: ticket PRD ref now points to `docs/design/FE-0.md` 107-108, 120-122 instead of Product PRD §7.
- Backlog: repo-wide form-control border scan (incl. HeroSearch, `<textarea`/`<select`), after FE-3b.

## 2026-11-21 pm-lead: OPS-H8c final review (PR #100)
- APPROVE: QA r1 PASS; I opened all 7 evidence files at `fa3393e` and each AC is proven (AC1 compose config + PyYAML: only processor/embedder-worker = 20s; AC2 20 > 12 + 1 s; AC3 Full stack run 44842072980, `dc stop processor` 1.54 s; AC4 all 7 checks green on `ffe4b45`). PR #100 raised (ready for review, label `ready-to-merge`).
- QA [spec] 1 fixed: ticket Scope now says per-service placement (`embedder-api` merges `x-worker`). [spec] 2 accepted (duplicate-not-loss, per the design). Design OPS-H8 item 6 got a "done in OPS-H8c" note.
- Backlog: OPS-H8d (backend P3), a unit test guarding compose grace > `DELIVERY_TIMEOUT_S` + 1 s.
- Note: the report/ticket/board edits landed inside FE-0h's commit `3978149` (shared working tree, swept by a parallel commit); lesson filed.

## 2026-11-21 · pm-lead · ING-9c (#99) final review
- APPROVE after QA r1 PASS. Opened evidence 00-07 and the diff (+55/-1, 2 test files). Every AC is proven, including m1-m4 kills and the m4 base control. The PM decision is in `agents/reviews/ING-9c/report.md` (commit `726565e`).
- PR #99 raised: description rewritten with the Evidence section (8 embeds pinned to `653f563`/`6fa3710`), ready for review (draft=false), label `ready-to-merge`. The outbound filter rewrote the embeds and footer again (lesson count 14×).
- Board: ING-9c moved from Ready to Ready to merge. Backlog: x5 deterministic limiter test (backend P3).

## 2026-11-21 00:00Z — orchestrator (cycle record; session_01ATEBeTermofaHXsLNayKoo)
- Setup: push dry-run OK; RUN_LOCK taken (`42153d6`, no prior lock); app cloned at `230f617`. Note: the session's stale local `origin/main` pointed at an orphan `3fa20ff` ("cycle 00:00–02:00Z idle" commits not in origin's history); origin was `92c89e7`, lock pushed fast-forward on top. Nothing lost on origin.
- Sync: no merges/closes since 20:00Z; #91–#98 Ready to merge with no human reviews or untagged comments; no Jira intake. No rework.
- Grooming (pm-lead `21f8c96`): 3 new independent tasks (files disjoint from #91–#98 and each other, all `Depends on` merged at `230f617`); ai-engineer had no unblocked item; a 4th backend task would exceed WIP 2.
- **ING-9c** (backend, KAN-103): PR [#99](https://github.com/MaheshPulivarthi18/ArxivLens/pull/99) @ `6afd06d`, 1 attempt, QA r1 PASS (m1–m4 killed), PM APPROVE → Ready to merge. Follow-up: deterministic cancelled-ctx limiter test (x5).
- **OPS-H8c** (backend, KAN-104): PR [#100](https://github.com/MaheshPulivarthi18/ArxivLens/pull/100) @ `ffe4b45`, 1 attempt, QA r1 PASS (Full stack green), PM APPROVE; ticket Scope amended (key per service: `embedder-api` also merges `x-worker`). Follow-up OPS-H8d.
- **FE-0h** (frontend, KAN-105): PR [#101](https://github.com/MaheshPulivarthi18/ArxivLens/pull/101) @ `2c84527`, 1 attempt, QA r1 PASS (≥ 3.23:1 both themes), PM APPROVE; PRD ref corrected. Follow-up: repo-wide form-control scan after FE-3b.
- QA reports saved verbatim from PR comments by the orchestrator (`9e7884c`; QA harness still refuses `report.md`). Two parallel PM reviews shared the one arxivlens-agents checkout and `3978149` swept in the other's staged edits (content correct, attribution mixed): the rule is already proposed in [arxivlens-agents#15](https://github.com/MaheshPulivarthi18/arxivlens-agents/pull/15) (one checkout per parallel QA/PM agent). Outbound filter again un-embedded PR-body images.
- RUN_LOCK released in this commit.

## 2026-11-21 01:00Z — pm-lead (cycle 01:00Z grooming)
- Sync (orchestrator): no merges since 2026-11-20 18:54Z; app `main` = `230f617`; #91–#101 all Ready to merge, no human reviews or Jira intake; WIP 0 for every developer. Open-PR file lists re-checked via REST.
- Picked 2 new backend specs (no `Depends on` open; files disjoint from each other and from #91–#101):
  **OPS-H6d** (P1, `services/common/db.py` `save_sections_and_chunks`, `tests/test_processor_pages.py`, new `tests/test_chunk_reprocess_db.py`): a reprocess with changed chunk text keeps the old vector (L3 keys on model only, OPS-H6 design G2), and stale tail chunks survive a shorter parse. Both break OPS-3. Deletes only, existing cascades, no schema change.
  **OPS-H18** (P2 harness, `Makefile`, new `requirements-light.txt`, `ci.yml` `python` job, `CONTRIBUTING.md`): Mahesh's #12-review split of `make test-py`; light tests run in CI before torch is installed. Earlier groomings had it held by #93's `README.md`, but README has no `test-py` mention.
- Skipped: RET-1e (`server_test.go`, #94), OPS-H7a2c / ING-6c / OPS-H7b (`main.go`, #93), FE-3b → FE-2 / FE-4 (#91 first), FE-0g (#95), EVAL-6c / EVAL-7 / EVAL-5 follow-ups (`tests/test_evals_data.py`, #96), x5 limiter test (#99), OPS-H8d (needs #100), form-control scan (after FE-3b), hnswGuard single action (#97). Not picked as filler: RET-1b NaN+Inf/MaxFloat32 rows. ai-engineer and frontend have no unblocked item worth a PR.
- Jira: no Atlassian tools in this session. For the orchestrator: OPS-H6d → epic KAN-4, OPS-H18 → epic KAN-3.

## 2026-11-21 — pm-lead (OPS-H6d #102 final review)
- **OPS-H6d** (backend, KAN-106): PR [#102](https://github.com/MaheshPulivarthi18/ArxivLens/pull/102) @ `5ba967b`, QA r1 PASS (13 mutants killed, CI Full stack run 44848933981 green incl. the real-Postgres test), PM **APPROVE** → PR description rewritten with the Evidence section, ready for review, label `ready-to-merge`. Jira KAN-106 → Ready to merge (orchestrator).
- QA `[spec]` finding 3 (embedder saves an old-text vector after the processor's delete commits) → new spec [OPS-H6e](tasks/OPS-H6e.md) (backend, P2, Backlog until #102 merges) + ai worker half as a Backlog line. OPS-H6e also covers the FK failure when the new tail delete removes a chunk mid-embed.
- Evidence nit: `06-AC7-mutants.png` is cut off before its kill table; AC7 accepted from the `.txt`. Lesson added for QA.

## 2026-11-21 01:00Z — orchestrator (cycle record; session_01ATEBeSXWyrhiTzMA9Kt4KJ)
- Setup: push dry-run OK; no prior RUN_LOCK, lock taken (`f68ab39`); app cloned at `230f617`.
- Sync: no merges/closes since 2026-11-20 18:54Z; #91–#101 Ready to merge, no human reviews/comments (reviews, issue and inline comments checked via REST); no Jira intake or untagged comments. No rework, no pending QA/PM.
- Grooming (pm-lead `0a0d450`): 2 new independent backend tasks (files disjoint from #91–#101 and each other — orchestrator re-checked the 11 PR file lists; no `Depends on` open). Frontend/ai have nothing unblocked (held files in open PRs or ADR-blocked).
- **OPS-H6d** (backend, KAN-106): PR [#102](https://github.com/MaheshPulivarthi18/ArxivLens/pull/102) @ `5ba967b`, 1 attempt, CI 6/6 green (real-PG test PASSED in Full stack run 44848933981), QA r1 PASS (13/13 mutants), PM APPROVE → Ready to merge. Follow-up OPS-H6e (embedder race / FK on tail delete) in Backlog, after #102.
- **OPS-H18** (backend, KAN-107): PR [#103](https://github.com/MaheshPulivarthi18/ArxivLens/pull/103) @ `2242efe`, 1 attempt, CI 6/6 green (light 139/1 + ml 56/2 = main's 195/3), QA r1 PASS, PM APPROVE → Ready to merge. QA `[spec]`: request came from the 2026-11-03 external-review plan, not a GitHub review on #12 — ticket, PR and Jira wording fixed. Nits → Backlog.
- QA reports saved verbatim from PR comments by the orchestrator (`c117694`; QA harness still refuses `report.md`). Shared-checkout sweep recurred (`f78ee5c` carried the parallel OPS-H6d PM files; content correct) and the orchestrator again wrote `/home/claude/wt` instead of `/root/wt` — both covered by open rules PR arxivlens-agents#15; lesson counters bumped.
- Retro: first-round QA pass rate 2/2; no new rule proposals (recurrences already in #14/#15). Trend: Ready work is starved by 13 unmerged PRs; merging #91–#101 would unblock RET-1e, OPS-H7a2c, FE-3b, FE-0g, EVAL follow-ups, OPS-H6e.
- RUN_LOCK released in this commit.

## 2026-11-21 02:00Z — orchestrator (cycle record; session_01ATEBeTRnDr2RMBzSVhHNKD)
- Setup: push dry-run OK; no prior RUN_LOCK, lock taken (`51f71f0`); app cloned at `230f617`.
- Sync: no merges/closes since 2026-11-20 18:54Z; #91–#103 all open, non-draft, Ready to merge; no human reviews, issue or inline comments from Mahesh (REST); no Jira intake or untagged comments. No rework, no pending QA/PM.
- Grooming (pm-lead): 0 new code tasks — every Ready/specced item waits on one of #91–#103 (or ING-6c, itself after #93). No specs written to fill slots.
- Docs: pm-lead raised the overdue PRD docs PR arxivlens-agents [#16](https://github.com/MaheshPulivarthi18/arxivlens-agents/pull/16) (`docs/prd-qa4-nli` @ `b11d654`, +31/−18): Product PRD QA-3 note, QA-4 ◐→✅ (NLI + verbatim quote, fail-closed, ADR-0014 statuses, `claims[]`), QA-8 ⏳→✅, §8 supported-row caveat; Technical PRD §7.2 diagram + Verify paragraph, §11 P0 row. Each claim cited to `rag.go`/embedder file:line @ `230f617`. Five board docs-due lines marked "raised as #16".
- Found stale: `rag.go:664` `parseSynthesis` comment (ai, P3) and AGENTS.md §6 QA-8 gotcha (rules PR, P3) → Backlog.
- Retro: nothing new to learn (no builds, no QA). Trend unchanged: 13 PRs + 3 workspace PRs (#14/#15/#16) wait on Mahesh; merging #91/#93/#94 would unblock FE-3b, ING-6c, OPS-H7a2c, RET-1e.
- RUN_LOCK released in this commit.

## 2026-11-21 03:00Z — orchestrator (cycle record; session_01ATEBeU5mEovfWGMHxgNv5d)
- Setup: push dry-run OK; no prior RUN_LOCK, lock taken (`d24fd66`); app cloned at `230f617` (unchanged).
- Sync: no merges/closes since 2026-11-20 18:54Z; ArxivLens #91–#103 open, non-draft, heads unchanged since their QA/PM verdicts; no reviews, issue or inline comments from Mahesh; workspace PRs #14/#15/#16 have no human activity; no Jira intake or untagged comments. No rework, QA or PM queue.
- New work: 0 — every Ready item still waits on an unmerged PR (FE-3b→#91, ING-6c/OPS-H7a2c/OPS-H7b→#93, FE-2→FE-3b); state identical to the 02:00Z grooming, so no re-groom and no specs written to fill slots.
- Retro: nothing new. Board unchanged. RUN_LOCK released in this commit.

## 2026-11-21 04:00Z — orchestrator (cycle record; session_01ATEBeUHoGpX5PRhvHX3gWU)
- Setup: push dry-run OK; no prior RUN_LOCK, lock taken (`d4cbbe7`); app cloned at `230f617` (unchanged).
- Sync: no merges/closes since 2026-11-20 18:54Z; ArxivLens #91–#103 open, non-draft, heads unchanged since their QA/PM verdicts; no reviews, issue or inline comments from Mahesh without a role tag; workspace PRs #14/#15/#16 no human activity; Jira: no intake (newest KAN-107), no updates since 01:35Z. No rework, QA or PM queue.
- New work: 0 — state identical to the 02:00Z grooming (every Ready item waits on an unmerged PR), so no re-groom. Retro: nothing new. RUN_LOCK released in this commit.

## 2026-11-21 05:00Z — pm-lead (cycle grooming)
- Sync: Mahesh merged #91–#103 at 04:50–04:52Z (app `main` `230f617` → `11c4696`); all 13 tickets → Status Done, board Done rows with merge SHAs, "Ready to merge" emptied. No open agent PRs, no human reviews, no ADR change.
- Picked 4 pairwise-independent tasks (all deps merged, no ADR wait): **FE-3b** (frontend, P0, design Approved), **RET-1e** (backend, P2, KAN-99), **OPS-H6e** (backend, P2, unblocks the ai worker follow-up), **EVAL-6c** (ai, P3 harness, new spec from EVAL-6b QA finding 3 + nit 1).
- Spec fixes at pick time: FE-3b Scope names the AC6 test files and the exact README line (`README.md:138-139`, "first visit starts in Dark"); RET-1e AC1 gains the two 503 rows (line list re-checked at `11c4696`); OPS-H6e test files fixed to `tests/test_processor_pages.py` (in `PY_ML_TESTS`) + `tests/test_chunk_reprocess_db.py` (test-full), so no `Makefile` change.
- Not picked: ING-6c / OPS-H7a2c / OPS-H7b (each edits app `README.md`, which FE-3b also edits; ING-6c goes first once FE-3b merges); FE-0g, x5 limiter test, OPS-H8d (unblocked, but 4-task cap and lower priority); FE-3a2 Toast-mock follow-up and form-control scan (after FE-3b).

## 2026-11-21 05:00Z — orchestrator (cycle record; session_01ATEBeRawKzi1RDhbRiuzYB)
- Setup: push dry-run OK; no prior RUN_LOCK, lock taken (`81f93ac`); app cloned at `11c4696`.
- Sync: Mahesh merged all 13 Ready-to-merge PRs #91–#103 (04:50–04:52Z) and workspace PRs #14/#15/#16. Jira stories already Done. No open agent PRs, no untagged human reviews or comments, no ADR status change.
- Grooming (pm-lead `bed1ed6`): 13 tasks → Done. Picked 4 pairwise-independent tasks (all deps merged): FE-3b, RET-1e, OPS-H6e, EVAL-6c (new spec). Skipped ING-6c/OPS-H7a2c/OPS-H7b (app `README.md` overlaps FE-3b). Jira KAN-108 (OPS-H6e, epic KAN-4) and KAN-109 (EVAL-6c, epic KAN-2) created.
- **FE-3b** (frontend, KAN-89): PR [#104](https://github.com/MaheshPulivarthi18/ArxivLens/pull/104) @ `d9b2386`, 1 attempt. CI 5/5 green. QA r1 PASS (browser harness 51/0, contrast table, 9 screenshots). PM APPROVE (`7d53f30`). Ready for review with label `ready-to-merge`; Jira → Ready to merge. Follow-ups → Backlog: Badge `span`, hero focus halo, refusal-mode active card.
- **RET-1e** (backend, KAN-99): PR [#105](https://github.com/MaheshPulivarthi18/ArxivLens/pull/105) @ `7d63496`, 1 attempt. QA r1 **PENDING**: AC1–AC3 met (QA ran 5+19 mutants with Go 1.25.1); AC4 Full stack red.
- **OPS-H6e** (backend, KAN-108): PR [#106](https://github.com/MaheshPulivarthi18/ArxivLens/pull/106) @ `f1b156e`, 1 attempt. QA r1 **PENDING**: AC1–AC4 and AC6 evidenced (CI test_processor_pages 60 → 66, 10/10 mutants); AC5 real-PG test needs Full stack. QA `[spec]`: processor-side residual race → Backlog.
- **EVAL-6c** (ai, KAN-109): PR [#107](https://github.com/MaheshPulivarthi18/ArxivLens/pull/107) @ `1f3bd31`, 1 attempt. QA r1 **PENDING**: AC1–AC7 evidenced (CI light 157 → 276); Full stack red.
- Infra: every Full stack run (3 PRs × 2 attempts, staggered re-runs 05:32–06:04Z) failed in the arXiv replay prefetch with 429 for fixture `2608.20331`, before any test ran. No code fault. → Backlog P1 harness item (pin the fixture). Next cycle: re-run Full stack on the unchanged heads; QA round 2 only re-checks that job.
- QA reports saved verbatim from the PR comments by the orchestrator (`aad5b0d`), because the QA harness still refuses to write `report.md`. PM PR-body embeds were again rewritten by the outbound filter (images → backticked links).
- Human: Mahesh asked live how to run answer evals against a real model in CI (e.g. Modal). Answered in session with options (replay fixtures per PR; nightly real-LLM eval on a Modal OpenAI-compatible endpoint; ADR needed for a new gate). Offered pm-lead ADR + EVAL-8 specs; awaiting his reply. Logged in board Backlog.
- Retro: first-round QA pass rate 1/1 decided (3 PENDING on infra). New lesson: Go 1.25.1 at `/usr/local/go1.25.1` (QA and backend). Recurring: QA `report.md` refusal, PR-body image filter. No new rules PR.
- RUN_LOCK released in this commit.

## 2026-11-21 07:00Z — pm-lead (cycle grooming)
- Sync: no merges since 04:52Z (app `main` = `11c4696`); #104 FE-3b Ready to merge; #105/#106/#107 In QA (r1 PENDING, Full stack arXiv 429; orchestrator re-running). No human reviews/comments; no ADR status change.
- WIP: backend 2 active (#105, #106) → no new backend task; ai 1 (#107) → 1 pick; frontend 0 (#104 Ready to merge doesn't count) → 2 picks.
- Picked (new specs, pairwise disjoint, deps merged, no Proposed-ADR wait): **FE-0g** (frontend, `ui/primitives.test.jsx`: mutants M35–M39), **FE-0i** (frontend, `ui/badge.jsx` → `<span>` + new `ui/badge.test.jsx`; FE-3b QA nit 1), **OPS-H8d** (ai-engineer, `tests/test_kafka_client.py`: compose `stop_grace_period` > `DELIVERY_TIMEOUT_S` + 1 s; in the file CI already runs, so no Makefile change). Checked file lists of #104–#107: no overlap.
- Not picked: Full stack arXiv-429 prefetch fix (P1, but `stack.yml` is backend-owned and backend is at WIP), ING-9c x5 limiter test (backend), `main.go` queue + FE-2/FE-4/FE-3a2 Toast follow-up/control scan/theme tests (wait for #104 to merge or share its files), EVAL-7/EVAL-5 test follow-ups (`tests/test_evals_data.py`, #107).
- Jira sync skipped (no Atlassian tools in this session): orchestrator to create stories for FE-0g, FE-0i (epic KAN-5) and OPS-H8d (epic KAN-3).

## 2026-11-21 11:00Z — orchestrator (cycle record; session_01ATEBeUeGL7pejudww1Kgz9)
- Setup: push dry-run OK. RUN_LOCK from cycle 07:00Z (session_01ATEBeRgibGdhzLhUmFpK8T) was 4 h old and never released → treated as stale, replaced (`0106091`). That cycle's work was on main (QA FE-0g r1, FE-0i r1, OPS-H8d PR #110) but it left no record entry; this entry covers it.
- Sync: no merges since 04:52Z (app `main` = `11c4696`). Open agent PRs #104–#110. No review or untagged comment from Mahesh on any PR; no Jira intake; no ADR status change.
- **RET-1e** #105: QA r2 PASS (from 07:00Z) → PM APPROVE (`0162c8d`), raised. Jira KAN-99 → Ready to merge. QA rounds 2 (r1 PENDING infra), PM 1.
- **OPS-H6e** #106: QA r2 PASS (Full stack green, new real-PG test in `-rA`; `845b2a2`) → PM APPROVE (`8598f3e`), raised. Follow-ups OPS-H6f (KAN-116), AI-13 (KAN-117). Jira KAN-108 → Ready to merge.
- **EVAL-6c** #107: QA r2 PASS → PM APPROVE (`358e439`), raised. `make eval` not run (no stack; 3000-run head-vs-main 0 diffs). Jira KAN-109 → Ready to merge.
- **FE-0g** #108: QA r2 PASS — AC6 mutants executed in the Chromium shim harness (7 killed at head, all survive vs main's tests; `2d57bdb`) → PM APPROVE (`eb1ae08`), raised. Jira KAN-110 → Ready to merge.
- **FE-0i** #109: QA r1 PASS → PM APPROVE (`609ef86`), raised; follow-up FE-0j (KAN-115). Jira KAN-111 → Ready to merge.
- **OPS-H8d** #110: QA r1 PASS (`d1399b4`; nit x14 folded into next `test_kafka_client.py` edit) → PM APPROVE (`803835a`), raised. Jira KAN-112 → Ready to merge.
- New (pm-lead plan `fd9d76a`; only 2 independent tasks — everything else waits on #104/#106/#107/#109 merging or on Mahesh):
  - **OPS-H19** (ai, P1 harness, KAN-113): `scripts/arxiv_replay.py` + `tests/test_arxiv_replay.py`; PR [#111](https://github.com/MaheshPulivarthi18/ArxivLens/pull/111) @ `5b4d6a2`, 1 attempt. QA r1 PASS (m1–m4 killed; 2 nits, 2 [spec]). PM **HOLD** (`5c66efc`): `eval` check still in `make eval-seed` after a 15-min wait; review otherwise complete. AC3 wording fixed; follow-ups OPS-H20 (KAN-118), OPS-H21 (KAN-119). Jira KAN-113 stays PM review.
  - **ING-9d** (backend, P3, KAN-114): `internal/arxiv/limiter_test.go`; PR [#112](https://github.com/MaheshPulivarthi18/ArxivLens/pull/112) @ `ac9ba42`, 1 attempt. QA r1 PASS (x5 killed 30/30, was 14/30) → PM APPROVE (`5422d44`), raised; AC4 wording fixed (no "Lint" job). Jira → Ready to merge.
  - Independence: OPS-H19 and ING-9d share no files with each other or with #104–#110; deps merged; no contract change.
- QA harness again refused `report.md` for ING-9d and OPS-H19; orchestrator saved the PR comments verbatim (`9e183a1`). PM PR-body image embeds again rewritten by the outbound filter (16×, lesson updated).
- Retro: first-round QA pass 4/4; PENDING rounds this cycle were all infra (arXiv 429) or harness (FE-0g mutant runner), both now addressed (OPS-H19; harness ran). No new rules PR.
- RUN_LOCK released in this commit.

## 2026-11-21 12:00Z — pm-lead (cycle grooming)
- Sync: no merges since 04:52Z (app `main` = `11c4696`). #104–#110, #112 Ready to merge (don't count toward WIP); #111 OPS-H19 draft, QA PASS, PM hold on `eval`. Active WIP: ai 1, backend 0, frontend 0. No human review, no ADR change, no Jira intake.
- Picked 1 task: **OPS-H18b** (backend, P3 harness, new spec from OPS-H18 QA findings 1+3): CI ML-absence guard (`ci.yml:54`) fails closed when `pip list` errors; `make help` text for `test-unit` (`Makefile:43`). Not design-required. Depends on #103 (merged). No open PR touches `Makefile` or `ci.yml`. Spec notes that `set -o pipefail` alone doesn't fix the fail-open (grep's exit 1 is the rightmost status; checked in bash).
- Not picked (all wait on an open PR merging): OPS-H20 + OPS-H21 (#111), OPS-H6f + AI-13 (#106, `db.py`), FE-0j (#109), FE-2/FE-4 + FE-0h scan + FE-3a2 follow-up (#104 `App.jsx`/`HeroSearch.jsx`/`ReferencesStack.jsx`), ING-6c → OPS-H7a2c → OPS-H7b (`README.md` in #104), EVAL-6c nits / EVAL-7 `build_rows` / EVAL-5 `CHUNK_COUNTS_SQL` (`tests/test_evals_data.py` in #107). AI-2 counters split: premise stale since NLI, marked for re-grooming on the board. Frontend and ai have no independent item.
- Jira: no Atlassian tools in this session; orchestrator to create OPS-H18b under KAN-3 and move it to In Progress.

## 2026-11-21 ~12:55Z · pm-lead · OPS-H19 final review (HOLD resolved)
- PR #111 @ `5b4d6a2`: **APPROVE**, raised (ready for review, `ready-to-merge`). The `eval` check timed out in the `make eval` step (30 min) on
  an AMD EPYC 7763 runner (rerank 1.47x slower than main's Intel run). The retrieval metrics are identical to main and the prefetch took 0 s on a warm store,
  so the PR's code is not involved. Re-run 136850028681 pending. Evidence 13 added. OPS-H20 widened (AC4: `make eval` step timeout), dependency dropped → Ready.

## 2026-11-21 12:00Z — orchestrator (cycle record; session_01ATEBeSaCT8MZpuyiJHJihL)
- Setup: push dry-run OK; previous lock released by cycle 11:00Z; lock taken (`4b693a8`); app cloned at `11c4696`.
- Sync: no merges since 04:52Z. Open agent PRs #104–#112; no review or untagged comment from Mahesh on any PR; no Jira intake; no ADR status change.
- **OPS-H19** #111 (ai, KAN-113): `eval` check on `5b4d6a2` failed at 12:44Z — `make eval` step hit its own 30-min timeout on a slower EPYC 7763 runner (rerank 1.47× slower than main's run); prefetch 0 s (warm store), retrieval metrics identical to main, no `GATE:` reached. Orchestrator re-ran the job (136850028681, pending). PM APPROVE on merits (`1f15103`, evidence 13), raised; Jira → Ready to merge. QA rounds 1, PM rounds 2 (r1 HOLD).
- New (pm-lead plan `1029fb7`; only one independent task at plan time):
  - **OPS-H18b** (backend, P3, KAN-120): `.github/workflows/ci.yml` guard + `Makefile:43`; PR [#113](https://github.com/MaheshPulivarthi18/ArxivLens/pull/113) @ `246d6d1`, 1 attempt. CI 6/6 green. QA r1 PASS (6/6 mutants killed, base control reproduces fail-open; evidence `6cd7729`) → PM APPROVE (`26de417`), raised. Jira → Ready to merge.
  - **OPS-H20** (backend, P2, KAN-118): became independent mid-cycle when pm-lead dropped its #111 dependency and widened it with AC4 (`make eval` step timeout). `.github/workflows/eval.yml` only; PR [#114](https://github.com/MaheshPulivarthi18/ArxivLens/pull/114) @ `ece17a7` draft, 1 attempt. QA r1 **PENDING** on AC3 (`eval` check queued behind the #111 re-run in `concurrency: eval`); AC1/AC2/AC4 evidenced (`8623246`). QA `[spec]` 2: a prefetch killed at its 45-min step limit never writes `saved=`, so the partial recording is lost → pm-lead to groom (ai, `scripts/arxiv_replay.py`). Jira → In QA.
  - Independence: #113 (`ci.yml`, `Makefile`) and #114 (`eval.yml`) share no files with each other or with #104–#112; deps merged (OPS-H18 #103) / none.
- Not picked: everything else in Ready waits on #104/#106/#107/#109/#111 merging (pm-lead list in `1029fb7`).
- QA harness refused `report.md` again (both); orchestrator saved PR comments verbatim (`26059c3`, `2c74d4d`).
- Retro: first-round QA pass 1/1 decided (1 PENDING on CI queue). New observation: eval runtime varies 1.47× by runner CPU; captured in OPS-H20. No new rules PR.
- RUN_LOCK released in this commit.

## 2026-11-21 13:00Z — pm-lead (cycle grooming)
- Sync: no ArxivLens merges since 04:52Z (`main` = `11c4696`). #104–#113 Ready to merge; #114 OPS-H20 draft, QA r1 PENDING on `eval` (run 44905935487 queued behind the #111 re-run). No Mahesh review or untagged comment, no Jira intake, no ADR status change (`git log docs/adr` unchanged since the FE-0g notes commit). WIP: ai 0, backend 1 (OPS-H20), frontend 0.
- Re-checked every Ready task against the open PRs' file lists (REST `pulls/<n>/files`): ING-6c, OPS-H7a2c, FE-2 (README/`ReferencesStack.jsx` in #104), OPS-H7b/c (queue), FE-0j (#109), OPS-H6f + AI-13 (#106), OPS-H21 (#111) all still wait. EVAL-7 follow-up (`answer_review.py` tests) also waits: its tests live in `tests/test_evals_data.py` (#107), and a new test file needs `Makefile`'s `PY_LIGHT_TESTS` (#113).
- OPS-H20 QA `[spec]` findings: 2 (killed prefetch never writes `saved=`, partial recording lost) folded into **OPS-H21** as item 3 / AC7-AC8 (same file `scripts/arxiv_replay.py`, owner ai and dependency #111 as OPS-H21; write `saved=` once on the first save, no workflow change). 4 (`Lint` check doesn't exist) fixed in OPS-H20 AC3 and OPS-H21 AC6 wording, intent unchanged. 3: no change.
- New specs from existing backlog lines (no new requirements):
  - **AI-14** (ai, P2, QA-6): aux-section cutoff matches `table`/`tables` as whole words ("Notable"/"Stable" no longer need rerank ≥ 0.70); `parseSynthesis` comment fixed. Files `internal/query/rag.go`, `rag_test.go`. Goes before AI-5 (Blocked on ADR-0011), which rebases.
  - **RET-1f** (backend, P3): `hnswGuard` helper owns skip/fatal/CI (kills OPS-H5c mutants c1–c3); rerank-fallback rows for NaN+Inf in one response and `±MaxFloat32`. Files `internal/query/search_test.go`, `search_integration_test.go` (test-only).
- Picked for this cycle: AI-14 (ai → 1 active) and RET-1f (backend → 2 active). Disjoint from each other and from #104–#114; no dependencies. Frontend: nothing independent (all frontend work waits on #104/#109). No other work invented.
- Jira (orchestrator): create stories for AI-14 and RET-1f (epic KAN-2); update OPS-H21 (KAN-119) summary/description for AC7.

## 2026-11-21 · pm-lead · OPS-H20 final review: CHANGES r1
- #114 @ `ece17a7` (QA r2 PASS): AC1-AC4 met. Every evidence file was checked against its `.txt` (00-09 in `8623246`, 10-13 in `8f641b4`). The r2 eval
  landed on an EPYC 7763 again: `make eval` took 32m52s, which the old 30-min cap would have killed, and `GATE: PASS`.
- **CHANGES 1**: app `CONTRIBUTING.md:34` still says "120 min for the job" for `eval.yml`, so the docs would be wrong after merge (DoD 4).
  This is a spec miss (Scope was `eval.yml` only). Added AC5 plus a rework checklist to the ticket. Board: In QA → In progress; the PR stays draft.
  No open PR touches `CONTRIBUTING.md`. The `eval` check re-runs on the new head, and QA r3 checks AC5 and re-quotes AC3.
- Jira: left to the orchestrator (KAN-118 → In Progress, comment `[pm-lead] CHANGES — CONTRIBUTING.md:34 job budget stale → report link`).

## 2026-11-21 16:00Z — orchestrator (cycle)
- Setup: push dry-run OK; RUN_LOCK from the 13:00Z cycle was 3 h old (that cycle groomed AI-14/RET-1f, then died before building; 14:00Z/15:00Z cycles left no trace) → taken over. App `main` = `11c4696`, no merges since 04:52Z. No Mahesh review/untagged comment on #104–#114; no ADR change. Re-used the 13:00Z grooming (nothing merged since, so the Ready analysis stands).
- **AI-14** (ai, KAN-121): built `f2337c3` → draft PR #115 → QA r1 PASS (`78d47f7`) → PM APPROVE (`752a456`) → raised, Ready to merge. 1 attempt, 1 QA round, 1 PM round.
- **RET-1f** (backend, KAN-122): built `14346e4` → draft PR #116 → QA r1 PASS (`4633893`) → PM APPROVE (`e5f17d3`, ticket PRD ref fixed QA-5 → QA-2) → raised, Ready to merge. 1 attempt, 1 QA round, 1 PM round.
  - Independence: #115 touches only `internal/query/rag.go` + `rag_test.go`, #116 only `search_test.go` + `search_integration_test.go`; disjoint from each other and from #104–#114; no dependencies.
- **OPS-H20** (#114, KAN-118): QA r2 PASS (`dc5a90c`; eval green, `make eval` 32m52s on EPYC vs 45) → PM CHANGES r1 (`1b500b7`: `CONTRIBUTING.md:34` still said 120-min job) → backend rework `3224fb2` → QA r3 PENDING on AC3 only (`62fd3e8`; eval re-run in progress). Stays draft / In QA.
- Not picked: every other Ready task waits on an open PR (frontend 0 independent; ai/backend items wait on #106/#109/#111). No work invented.
- QA and PM harnesses had no Jira tools; orchestrator posted the role-tagged comments and transitions.
- RUN_LOCK released in this commit.

## 2026-11-21 17:00Z — pm-lead (cycle grooming)
- Sync: no ArxivLens merges since 04:52Z (`main` = `11c4696`). #104–#113, #115, #116 Ready to merge (don't count toward WIP); #114 OPS-H20 draft, QA r3 PENDING on `eval` (backend: 1 active). No Mahesh review, no ADR status change (all `docs/adr/` statuses re-read: 0001-0003, 0006, 0010, 0014, 0016, 0017 Accepted, the rest Proposed).
- Re-checked every Ready task against the open PRs' file lists (REST `pulls/<n>/files`). They all still wait: ING-6c, OPS-H7a2c and OPS-H7b/c (`README.md` in #104, then the `main.go` queue), FE-2 (`ReferencesStack.jsx` #104), FE-0j (#109), OPS-H6f and AI-13 (#106), OPS-H21 (#111). Backlog items for backend and frontend are all either blocked on a decision (ADR or Mahesh) or behind #104/#107/#113/#114. Phase 3 items (OTLP, `/readyz`, metrics) stay deferred by the 2026-11-07 plan.
- New spec **AI-15** (ai, P3, test-only `tests/test_verify.py`): pins that `/internal/rerank` (cross-encoder and bi-encoder fallback) and `/internal/verify` return while an ingest holds `_ingest_lock`. Source: AI-12b's deferred rerank row, widened to verify because every answered `/v1/ask` calls it since NLI; AC4 folds in AI-12b QA nit 1. It has one mutant per case (m1-m4). It is not design-required, and no open PR touches the file. AI-13 (same file) now goes after it. → **Picked** (ai: 1 active).
- Docs: raised arxivlens-agents [#17](https://github.com/MaheshPulivarthi18/arxivlens-agents/pull/17) (`docs/prd-rerank-inf`): the Technical PRD §7.1 rerank note now matches `search.go:214-258` (fused order ADR-0017, paper cap ADR-0016, fallback on error/timeout/cancel/count/NaN/±Inf). It closes two Backlog lines.
- Jira (orchestrator, no Atlassian tools here): create the AI-15 Story under KAN-2, labels `task-AI-15`, `agent-ai`, `arxivlens`, status To Do. Then write the key into the ticket and the board row.

## 2026-11-21 — pm-lead — OPS-H20 #114 final review round 2: APPROVE
- QA r4 PASS on `3224fb2`. AC5 (`CONTRIBUTING.md:34` budgets 70/45/180) is met, `eval.yml` is byte-identical to `ece17a7`, and the `eval` check is green on the new head (`GATE: PASS`, job 69m52s). PM APPROVE was appended to `agents/reviews/OPS-H20/report.md`.
- PR #114 description rewritten with the per-AC evidence and raised for review. Board: In QA → Ready to merge. Jira KAN-118 → Ready to merge (orchestrator).

## 2026-11-21 17:00Z — orchestrator (cycle record)
- Sync: no ArxivLens merges since 04:52Z (`main` = `11c4696`); no human reviews or untagged comments on #104–#116; no human Jira comments; no ADR status change.
- **OPS-H20** (#114, KAN-118): QA r4 PASS (`01e2c20`; eval job 136903946034 green, `GATE: PASS`, job 69m52s, `make eval` 23m11s / 45) → PM r2 APPROVE (`5ea0dc5`) → raised, Ready to merge. Attempts 2, QA rounds 4 (2 PENDING), PM rounds 2 (1 CHANGES).
- **AI-15** (#117, KAN-123, new): specced by pm-lead, built by ai-engineer (`7699cca`, `tests/test_verify.py` +127/−31) → QA r1 PASS (`fd4b8f1`; mutants m1–m4 + q5/q6 each killed by own test; CI 6/6) → PM APPROVE (`bdb369f`) → raised, Ready to merge. Attempts 1, QA 1, PM 1. Independent: no open PR touches `tests/test_verify.py` or `services/embedder/`; deps AI-12/AI-12b merged.
- Not picked: every other Ready task still waits on an open PR (see pm-lead 17:00Z entry). No work invented.
- QA's harness refused writing `agents/reviews/AI-15/report.md`; orchestrator saved the PR comment body verbatim with a provenance line (`cbe0b9e`). QA/PM harnesses had no Jira tools; orchestrator posted role-tagged comments and transitions.
- RUN_LOCK released in this commit.

## 2026-11-21 18:00Z — pm-lead (cycle grooming)
- Sync (orchestrator, REST/Jira): no ArxivLens merges since 04:52Z (`main` = `11c4696`). #104–#117 are all Ready to merge with unchanged heads, so 0 active PRs per developer. No Mahesh review or comment, no human Jira comment or intake, no ADR status change (re-read `docs/adr/`: 0001-0003, 0006, 0010, 0014, 0016, 0017 Accepted, the rest Proposed). arxivlens-agents #17 is still open.
- **Picked: none.** All 9 Ready tasks wait on an open PR merging: ING-6c → OPS-H7a2c → OPS-H7b → OPS-H7c (README in #104, then `main.go` order), FE-2 (#104), FE-0j (#109), OPS-H6f + AI-13 (#106; AI-13 also shares `tests/test_verify.py` with #117), OPS-H21 (#111). FE-4 is blocked on FE-3b.
- Backlog re-checked for unblocked, PRD-backed items. None is startable. They are either waiting on a decision from Mahesh (ADR-0011/0012/0013/0015/0018, the `max_citations` bound, the v1/v2 dedupe question, the OPS-H14 font gate, EVAL-8/Modal), behind an open PR's files (`tests/test_evals_data.py` #107, `rag.go` #115, `services/common/db.py` #106, frontend items #104), folded into a queued task (OPS-H9b nits → ING-6c, worker L2 → AI-13), or Phase-3 roadmap items that are deliberately deferred until Phase 1 exits (OTLP, Prometheus, auth). With 14 PRs queued on Mahesh, no new spec was written.

## 2026-11-21 18:00Z — orchestrator (cycle record)
- Sync: no ArxivLens merges since 04:52Z (`main` = `11c4696`); heads of #104–#117 unchanged; no Mahesh review, review comment or untagged issue comment on any of them; no Jira update since the 17:00Z cycle (no human comments, no intake); no ADR status change.
- Rework: none (no open rework checklists). Review: none needed (every open PR has QA PASS + PM APPROVE for its current head).
- New work: pm-lead groomed (`800cb28`) → picked none; every Ready task waits on an unmerged PR. No work invented.
- Retro: no new friction this cycle beyond the known merge backlog (already in 17:00Z metrics notes); no rule change proposed.
- RUN_LOCK released in this commit.

## 2026-11-21 19:00Z — orchestrator (cycle record)
- Sync: no ArxivLens merges since 04:52Z (`main` = `11c4696`); heads of #104–#117 unchanged; no Mahesh review, inline comment or untagged comment on any of them; no Jira update since 17:33Z (no human comments, no intake); no ADR status change; arxivlens-agents #17 still open.
- Rework: none. Review: none needed (all open PRs have QA PASS + PM APPROVE for their current heads).
- New work: none. Inputs identical to the 18:00Z grooming (`800cb28`), so every Ready task still waits on an unmerged PR; pm-lead not re-run, no work invented.
- RUN_LOCK released in this commit.

## 2026-11-21 19:59Z — orchestrator (cycle record)
- Sync: one ArxivLens merge since the last cycle — Mahesh's own PR #118 (`ops/make-uses-venv`, not an agent branch; `main` = `d8f791b`, merged 19:29Z): `Makefile`, `scripts/eval_gate.py`, `tests/test_evals_data.py`. Overlaps open #113 (`Makefile`) and #107 (`tests/test_evals_data.py`); GitHub reports both `mergeable_state: clean`, heads unchanged, so their QA/PM verdicts stand. Heads of #104–#117 unchanged; no Mahesh review, inline comment or untagged comment on any of them; no Jira update since 17:33Z (no human comments, no intake); no ADR status change.
- Rework: none. Review: none needed (all open PRs have QA PASS + PM APPROVE for their current heads).
- New work: none. #118 unblocks no Ready task (each still waits on #104/#106/#109/#111 or the `main.go` queue); pm-lead not re-run, no work invented.
- RUN_LOCK released in this commit.

## 2026-11-21 21:00Z — orchestrator (cycle record)
- Sync: Mahesh merged his own PRs #119 (relevance cutoff before top-5: `rag.go`, `rag_test.go`, `search.go`) and #120 (ADR-0019: `rag.go`, `rag_test.go`, `synthesis_test.go`, `scripts/eval_gate.py`, `scripts/evaluate_answers.py`, `tests/test_evals_data.py`, READMEs); app `main` = `c2b3bd6`. He opened his own #121 (ADR-0020 fp16 reranker, `embedder/rerank-fp16`), not an agent branch. ADR-0019 and ADR-0020 now Accepted on this repo. Heads of #104–#117 unchanged, all `mergeable_state: clean`; no Mahesh review, inline or untagged comment; no Jira change in the last 2 h.
- Rework: none. Review: none needed (all open agent PRs have QA PASS + PM APPROVE for their current heads).
- Grooming (pm-lead, `0500c6f`): picked none — every Ready task still waits on an unmerged PR (#104/#106/#109/#111/#117, `main.go` queue; `README.md` now also in #121). No task unblocked or made obsolete by ADR-0019/0020; premise notes added to AI-5, AI-10, FE-4, EVAL-8 (Jira comments KAN-25/51/44/46). New Backlog item: PRD alignment docs PR for ADR-0019/0020.
- Risk flagged for Mahesh: #115 (`rag.go`/`rag_test.go`) and #107 (`evaluate_answers.py`/`test_evals_data.py`) CI ran on base `11c4696`; #119/#120 changed the same files. Both merge clean; #107 re-tested locally on `c2b3bd6` (270 passed, 1 skipped); #115 not re-run (no Go 1.25 in sandbox) — re-run CI before merging.
- RUN_LOCK released in this commit.

## 2026-11-21 ~21:25Z — orchestrator (merges on Mahesh's request)
- Mahesh asked in chat to merge every PR aligned to merge and update statuses. Merged (squash) all 14 agent PRs at Ready to merge, each with QA PASS + PM APPROVE, CI green and `mergeable_state: clean`: #104 FE-3b `dcb326a`, #105 RET-1e `92bcf1a`, #106 OPS-H6e `a4c0140`, #108 FE-0g `f7c5875`, #109 FE-0i `8337086`, #110 OPS-H8d `726eab3`, #111 OPS-H19 `1a3a7b9`, #112 ING-9d `69a0240`, #113 OPS-H18b `54f6802`, #114 OPS-H20 `71a43d1`, #116 RET-1f `c384dbc`, #117 AI-15 `f0fe4d2`, #107 EVAL-6c `bf37354`, #115 AI-14 `53171d6`.
- #107 and #115 were first updated to `main` (`update-branch`) because #119/#120 changed their files; CI re-ran green on all 6 checks (heads `e76ae63`, `82404ba`) before merging.
- Mahesh merged his own #121 (ADR-0020) in the same window. App `main` = `53171d6`.
- Board, task Status lines and Jira (14 stories → Done) updated. Unblocks the Ready queue: ING-6c, OPS-H7a2c, FE-2, FE-0j, OPS-H6f, AI-13, OPS-H21 (and FE-4's FE-3b dependency) — pm-lead re-checks independence next cycle.

## 2026-11-22 ~22:10Z — pm-lead (cycle 2026-11-21T21:59Z grooming)
- Checked `git -C app log origin/main` (`53171d6`): #104–#117 and #119–#121 merged, no open app PRs, so every "after #N" on Ready is met. Board Ready column rebuilt; FE-4 moved Blocked → Ready (design first); AI-5/AI-10 notes fixed (#115, #121 merged).
- Mahesh's EVAL-8 direction (`3d8cab1`): wrote **ADR-0021** (Proposed) for a real-LLM CI eval on Modal. It asks: which runs call the LLM (rec. nightly + dispatch + `eval-llm` label), could-not-run rules R1–R4 (missing secret, warm-up, digest mismatch, 0 synthesized → exit 2), PR replay option (rec. LLM record/replay proxy) and the monthly budget. Thresholds unchanged.
- Specs: **EVAL-8c** (ai, P1, Ready: results JSON records the LLM + per-case `answer_kind`/`status`, BASELINE real-LLM section; report-only, so no ADR wait; split out of Mahesh's "8a" because `scripts/eval_gate.py` is ai-owned), **EVAL-8a** (backend, design-required, Blocked on ADR-0021 + Modal/secrets), **EVAL-8b** (ai, Blocked on ADR-0021 Q3).
- EVAL-8: option 3 answered. AC1 is met. AC2's numbers are met (supported 1.00, refusals 1.00, quick p95 2423 ms); the BASELINE write-up goes to EVAL-8c. AC3 (tokens) goes to EVAL-8a. It stays as the umbrella until EVAL-8c and EVAL-8a merge. The three evidence observations are now a Backlog item.
- Raised arxivlens-agents #20 (`docs/adr-0019-0020-prd`): PRD wording for ADR-0019/0020, with §7.1 left to #17. The outbound filter swapped the 🤖 footer again; content otherwise intact.
- **Picked (4, pairwise disjoint files):** EVAL-8c (ai), FE-4 (frontend, P0, design-required, no design yet), OPS-H21 (ai), ING-6c (backend). Not picked (cap): OPS-H6f, AI-13, FE-0j (all Ready, next slots); OPS-H7a2c/H7b/H7c (`main.go` queue behind ING-6c); FE-2 (behind FE-4).
