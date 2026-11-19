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
