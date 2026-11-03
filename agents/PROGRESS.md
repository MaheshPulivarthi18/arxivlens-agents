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
