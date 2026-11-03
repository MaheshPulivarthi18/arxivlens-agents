# AGENTS.md — Operating manual for the ArxivLens agent team

This repo (`arxivlens-agents`, public) is the team's **workspace and memory**: product docs, decisions, tickets,
designs, QA evidence, agent definitions and the sprint loop. The product itself lives in a separate repo,
[`MaheshPulivarthi18/ArxivLens`](https://github.com/MaheshPulivarthi18/ArxivLens) (public), which contains **only
runnable code, tests, evals and CI**. Agents have no memory between sessions; everything they need is in these two repos.

## 0. Two repos, one workspace

```
arxivlens-agents/          ← sessions start here (this repo)
  app/                     ← clone of ArxivLens (git-ignored). All code work happens in here.
  docs/  agents/  .claude/ ← product docs, team memory, agent definitions
```

At session start: `git clone https://github.com/MaheshPulivarthi18/ArxivLens app` (or `git -C app fetch origin`).
**Code paths in these docs are relative to the app repo** (e.g. `internal/query/rag.go` means `app/internal/query/rag.go`).
Build and test commands (`make test-unit`, ...) run inside `app/`; see `app/CONTRIBUTING.md`.

| Goes in **ArxivLens** (via PR) | Goes in **arxivlens-agents** |
|---|---|
| Code, tests, `evals/` datasets, Makefile, compose, CI, README, CONTRIBUTING | PRDs, ADRs, designs, tickets, board, progress, metrics, lessons, QA evidence, agent rules |
| Never: tickets, reviews, evidence, PRDs, agent prompts (CI rejects them) | Never: product code |

### How changes land in this repo
- **Direct to `main`** (no PR, it's the team's notebook): `agents/tasks/`, `agents/board.md`, `agents/PROGRESS.md`,
  `agents/metrics.md`, `agents/memory/`, `agents/reviews/`, `docs/design/`, and *new* ADRs with `Status: Proposed`.
  Pull before you push (`git pull --rebase`); never force-push.
- **Via PR for Mahesh's approval** (branch `rules/<topic>` or `docs/<topic>`): `.claude/`, `AGENTS.md`, `CLAUDE.md`,
  `agents/templates/`, `agents/tools/`, `agents/jira.md`, `agents/area-notes/`, `docs/PRD-*.md`, and any ADR status change.
  The `rules-guard` workflow turns `main` red if one of these is pushed directly.

## 1. Session protocol (every time)
1. Read this file, then `agents/area-notes/<area>.md` for the code area you will touch.
2. Read `agents/board.md`, the last 20 entries of `agents/PROGRESS.md`, and your role's section of `agents/memory/lessons.md`.
3. Read your task spec `agents/tasks/<ID>.md`. **No spec → no code.**
4. At the end: update the spec's Status/Notes, the board, append to PROGRESS, add lessons; commit to this repo's `main`.

## 2. The team

| Agent | Definition | Edits in ArxivLens (`app/`) | Edits here |
|---|---|---|---|
| **PM / Lead** | `.claude/agents/pm-lead.md` | nothing | `docs/` (PRDs via PR, ADRs as *Proposed*), `agents/`, rules via `rules/` PRs |
| **AI engineer** | `.claude/agents/ai-engineer.md` | `services/embedder/*.py`, `internal/query/rag.go` + `rag_test.go`, `scripts/`, `evals/`, `tests/` | own task notes, `docs/design/<ID>.md` |
| **Backend & distributed systems** | `.claude/agents/backend-engineer.md` | `cmd/`, `internal/` (except `rag.go`), `services/processor/`, `services/common/`, `services/embedder/Dockerfile`, `shared/`, `migrations/`, `tests/`, `docker-compose.yml`, `Makefile`, `.github/`, `requirements*.txt`, `go.mod`, `CONTRIBUTING.md` | own task notes, `docs/design/<ID>.md` |
| **Frontend** | `.claude/agents/frontend-engineer.md` | `frontend/` | own task notes, `docs/design/<ID>.md` |
| **QA / PR reviewer** | `.claude/agents/qa-reviewer.md` | nothing | `agents/reviews/<ID>/` |

Every role may also update `README.md` in the app repo when user-facing behaviour changes. App-repo CI enforces the
ownership column on `agent/*` branches (`.github/scripts/ownership-check.sh`).

### Workflow (every task, no exceptions)

| Stage | Who | Output | Jira status |
|---|---|---|---|
| 1. Spec | pm-lead | `agents/tasks/<ID>.md` with PRD ref + acceptance criteria; Jira story under the PRD's epic | To Do |
| 1a. Design *(design-required only)* | owning developer | `docs/design/<ID>.md`; pm-lead approves before any code | Design |
| 2. Build | owning developer | branch `agent/<role>/<ID>` in ArxivLens + **draft** PR (CI runs on it) | In Progress → In QA |
| 3. QA | qa-reviewer (independent, fresh context) | `agents/reviews/<ID>/report.md` + `evidence/` screenshots of real test/CI output, committed **here**; PR comment + Jira links | PASS → PM review · FAIL → In Progress |
| 4. Final review + raise PR | pm-lead | checks ticket, PRD, design and every evidence file; APPROVE → writes the evidence into the PR description and marks the PR ready for review | Ready to merge |
| 5. PR review + merge | **Mahesh** | reviews the PR and merges, or leaves a review | Done |

**Human review = top priority.** A review or comment from Mahesh on an agent PR (or an untagged Jira comment) goes
back to the developer first thing next cycle: the PR returns to **draft**, Jira to **In Progress**, and the ticket's
Notes get a checklist of every item in the review. QA's next round checks each item explicitly. If an item needs a
decision only Mahesh can make (an ADR, a product trade-off), mark the task `Blocked (needs <ADR/decision>)` and say so
on the PR — don't guess.

Max 2 rework rounds (QA FAIL or PM CHANGES) per task per cycle, then Blocked with the reports linked.
Nobody reviews their own work. The developer's self-report is never passed to QA.

### Shared contracts (change only through an Accepted ADR)
- Event envelope and topics: `shared/events/events.go` + `shared/events/events.py` (must stay in sync)
- HTTP API: routes in `internal/query/server.go` and the API table in the app `README.md`
- DB schema: `migrations/`. A new numbered migration that only *adds* a table or index is fine without an ADR;
  changing or dropping existing tables/columns needs one. Never edit an applied migration.
- Embedding model + dimension (`BAAI/bge-base-en-v1.5`, 768-d `halfvec`)
- Quality gates: definitions in `docs/adr/` (e.g. ADR-0006 Recall@5) and values in `evals/thresholds.json`.

If a task needs a contract change: write `docs/adr/NNNN-*.md` with `Status: Proposed`, mark the task
`Blocked (needs ADR-NNNN)`, and move on. **Only Mahesh sets an ADR to Accepted or Rejected.**

## 3. Hard rules
- **Never push to ArxivLens `main`. Never merge a PR.** One branch per task: `agent/<role>/<TASK-ID>`. Mahesh merges.
- Never put tickets, reviews, evidence, PRDs or agent prompts in the ArxivLens repo.
- Stay inside your owned paths. Need a change elsewhere → follow-up task for the owner.
- Never weaken a test, threshold or eval gate to make it pass. If a threshold is wrong, propose an ADR.
- Never commit secrets, `.env`, PDFs, model weights or `node_modules/`. Never force-push either repo.
- **WIP:** max **2 active PRs per developer agent**, and only for independent tasks. Active = draft, In QA, PM review or rework. A PR that is raised and
  waiting only on Mahesh (**Ready to merge**) does **not** count, so the developer picks the next independent task.
  Max **4 new tasks per cycle**, built in parallel, each in its own `app` worktree. Tasks started together, and any task
  started while PRs are open, must be **independent**: their `Depends on` are merged (not just Ready to merge) and they
  don't change the same files as each other or as any open PR.
- Max **2 attempts** per task per session; then Blocked with the exact error in Notes.
- Keep code diffs small (target < 400 changed lines). Split bigger work into new tasks.

## 4. Definition of Done
1. Every acceptance criterion met and checked off with evidence.
2. `make test-unit` and `make lint` pass in CI; pipeline/query changes also pass the relevant milestone suite.
3. Retrieval/answering changes: `make eval` doesn't regress (before/after numbers), or "not run: <reason>".
4. App `README.md` / `CONTRIBUTING.md` updated if behaviour or commands changed; PRD status column updated here (via PR).
5. QA **PASS** and pm-lead **APPROVE** in `agents/reviews/<ID>/report.md`; PR raised with evidence in its description.

**CI is the source of truth for test results.** Agent sandboxes may lack Go 1.25, npm, Docker or Hugging Face;
"not run locally" is acceptable, "passes" without CI or command output is not.

## 5. Map of this repo
```
.claude/agents/        the five role definitions
.claude/commands/      /sprint (one cycle), /retro (self-improvement)
docs/PRD-*.md          product + technical PRDs
docs/adr/              decisions (Proposed → Accepted by Mahesh)
docs/design/           tech designs for design-required tasks
agents/tasks/          one spec per task        agents/board.md       kanban mirror of Jira
agents/reviews/<ID>/   QA report + evidence     agents/PROGRESS.md    append-only log
agents/memory/         lessons per role         agents/metrics.md     one row per cycle
agents/area-notes/     per-code-area rules      agents/jira.md        Jira mapping
agents/templates/      task, design, PR, QA     agents/tools/         render_evidence.py
```

## 6. Known gotchas
- `go.mod` requires Go 1.25; older local toolchains try to download it (blocked in agent sandboxes).
- `tests/test_m0.py` downloads `BAAI/bge-base-en-v1.5` (~440 MB) on first run.
- Processor and embedder workers are not yet in `docker-compose.yml` (OPS-H1), so `make test-full` needs them by hand.
- `/v1/ask` answers are templated, not LLM-generated (QA-8).
- Agent sandboxes can't upload files to Jira (media host blocked); link evidence instead.
- Both repos are public: never commit secrets, tokens, credentials or private data to either one. Evidence images render in ArxivLens PRs for everyone.
