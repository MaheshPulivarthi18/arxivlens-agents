---
description: Run one sprint cycle of the ArxivLens agent team (sync → plan → build → PR → QA → PM review → ready to merge → record → retro)
argument-hint: "[max-new-tasks, default 4]"
---

You are the **orchestrator** for one sprint cycle of the ArxivLens agent team. You coordinate; the specialists in
`.claude/agents/` do the work. You run from the `arxivlens-agents` repo (team memory); the product code is the
ArxivLens repo cloned at `app/` (see `AGENTS.md` §0). Code PRs go to ArxivLens; everything else is committed here. Run unattended: never wait for a human mid-cycle. Anything needing a human decision
gets written down (ADR / Blocked note) and the cycle moves on.

Max **new** tasks started this cycle: `$ARGUMENTS` (default **4**). Reviewing PRs already open does not count toward it.

## The workflow every task follows

```
Ready ─► [Design ─► Design approved] ─► Build ─► In QA ─► PM review ─► Ready to merge ─► Done
(PM spec)  (developer)  (pm-lead)      (dev)  (qa-reviewer) (pm-lead)               (human merges)
                                         ▲        │ FAIL        │ CHANGES
                                         └────────┴─────────────┘  (max 2 rework rounds, then Blocked)
```
The Design steps apply only to tasks marked `design-required` (see `docs/design/README.md`).
Every stage change is mirrored to Jira following `agents/jira.md` (status = stage, plus a role-tagged comment).

Roles never review their own work: the developer builds, **qa-reviewer** verifies against ticket + PRD + test results,
**pm-lead** gives the final product sign-off, the **human** merges.

## Step 0 — Workspace and run lock
`git pull --rebase` this repo. Cycles run hourly and one can outlast the hour, so take the lock first: if
`agents/RUN_LOCK` exists and its timestamp is less than 100 minutes old, another cycle is running. Report
"skipped: cycle <timestamp> still running" and stop. Otherwise write the current UTC time and session link to
`agents/RUN_LOCK`, commit and push it (if the push is rejected, pull, re-check the lock and stop if someone else took
it). Delete the lock in Step 8, and also when you stop early for any reason. Clone or update the app repo: `git clone https://github.com/MaheshPulivarthi18/ArxivLens app`
(or `git -C app fetch origin`). All `git`/`make` commands for code run in `app/`; all memory edits happen here.

## Step 1 — Load memory
Read `agents/jira.md` and, if the Atlassian tools are available, the Jira board:
`searchJiraIssuesUsingJql` with `project = KAN AND labels = arxivlens AND statusCategory != Done ORDER BY rank`.
Then read `AGENTS.md`, `agents/board.md`, the last 20 entries of `agents/PROGRESS.md`, `agents/memory/lessons.md`,
`agents/metrics.md`, and every ADR in `docs/adr/` (note which are Accepted).

## Step 2 — Sync with reality
In `app/`: `git fetch origin`; work from the latest `origin/main`. List PRs with REST (GraphQL is blocked):
`gh api 'repos/MaheshPulivarthi18/ArxivLens/pulls?state=all&per_page=50'`. For branches starting with `agent/`:
- Merged → **Done**.
- Closed without merge → back to **Ready**, closing reason in the task Notes if visible.
- Open with a **human review or comment** since the last agent commit (`gh api .../pulls/<n>/reviews` and
  `.../issues/<n>/comments`, author MaheshPulivarthi18, not starting with a `[role]` tag) → highest priority. Convert the
  PR back to draft (`ccr/convert_to_draft`), Jira → **In Progress**, and append to the ticket's Notes a checklist with one
  line per review item. Items that need Mahesh's decision → Blocked on that decision (comment on the PR saying so);
  the rest → the owner addresses them (Step 4), then QA checks every checklist item.
- Open, new commits since the last QA report (or no report yet) → queue for **QA** (Step 5).
- Open, QA PASS but no PM verdict → queue for **PM review** (Step 6).
- An ADR that became `Accepted` unblocks its tasks: **Blocked → Ready**.
- Jira: merged PRs → transition the story to **Done**. New intake tickets and human (untagged) comments are handled
  as `agents/jira.md` describes — human comments get the same top priority as human PR comments.

## Step 3 — Plan (delegate to `pm-lead`)
Ask `pm-lead` to groom the board (spec next PRD/roadmap items if Ready is thin; fix any `[spec]` findings from QA
reports) and return an ordered list of new tasks for this cycle, respecting:
- WIP: max 2 **active** PRs per developer agent (draft, In QA, PM review or rework), for independent tasks only. PRs at **Ready to merge** (raised,
  waiting only on Mahesh) don't count, so that agent takes the next task. Skip agents already at 2 active PRs.
- Independence: every task picked this cycle must not change the same files (or the same shared contract) as another
  picked task or any open PR, and its `Depends on` must be **merged**, not just Ready to merge. When unsure, compare the
  ticket's Scope with `gh api .../pulls/<n>/files` of the open PRs. Up to 4 tasks per cycle, any mix of owners. If there
  aren't 4 independent Ready tasks, start fewer; never start a task just to fill the slot.
- Dependencies: only tasks whose `Depends on` are Done and whose ADRs are Accepted.
- Priority: human feedback > QA/PM rework > unblocks-others > P0 > harness/quality > P1 > P2.

## Step 4 — Design (only `design-required` tasks) → Build → open PR
Run the selected tasks **in parallel**: one subagent per task, each in its own worktree
(`git -C app worktree add "$HOME/wt/<TASK-ID>" -b agent/<role>/<TASK-ID> origin/main`, outside both repos), launched together and awaited
together. Rework items go first. QA and PM review for each PR also run in parallel. For each task:
0. **Design gate.** If the ticket (or its Jira story) is `design-required` and there is no approved
   `docs/design/<TASK-ID>.md` yet: the owner writes it from `agents/templates/design.md` and commits it to this repo's
   `main` (Jira: **Design**). Then `pm-lead` reviews it against the ticket and PRD and fills
   "PM decision". Approved → Jira **In Progress**, continue to build in this cycle. Changes requested → one
   revision; still not approved → Blocked with the PM's notes. No product code before approval.
1. In the task's worktree: branch `agent/<role>/<TASK-ID>` from `origin/main` (or the existing PR branch for rework).
2. Invoke the owner (`ai-engineer`, `backend-engineer`, `frontend-engineer`, or `pm-lead` for docs tasks) with: the
   full ticket `agents/tasks/<TASK-ID>.md`, the PRD rows it references, the role's lessons, and — for rework — the
   latest QA report / PM verdict / human comments. Instruction: "Implement exactly this spec in your owned directories.
   Run the verification commands you can. Code changes go only in `app/` on the task branch; ticket Notes (and the
   design doc) go in this repo, committed to `main`. Never add tickets, reviews or docs to `app/`. Report files changed, commands run with output, each AC with evidence,
   and anything you could not verify and why."
3. In `app/`: sanity-check `git diff --stat origin/main` and run `.github/scripts/ownership-check.sh origin/main agent/<role>/<TASK-ID>`.
   Fix ownership violations before pushing.
4. Commit `<TASK-ID>: <summary>`, push, and open the PR as a **draft** (`"draft": true` in the REST call; new tasks)
   with `agents/templates/pr.md`, or push to the
   existing PR (rework). **Never merge. Never push to main.** Board: **In QA**.
   Jira: **In QA**; set `**PR:** #n` in the story description; comment `[<role>] PR #n opened → <link>`.

## Step 5 — QA (delegate to `qa-reviewer`, fresh context)
For each PR queued for QA, invoke `qa-reviewer` with only: PR number, branch, head SHA, the ticket path, and the PRD
rows, and the approved design doc if one exists. Do **not** pass the developer's self-report — QA judges from the spec,
the PRD, the design, the diff and the evidence.
- CI not finished → wait for it if the cycle has time (poll check runs every ~60 s, up to 15 min), else `PENDING`.
- QA checks out the PR head in `app/` and builds the **evidence pack** in this repo under `agents/reviews/<TASK-ID>/`
  (committed to `main`, never to the PR): `report.md` plus
  `evidence/NN-<name>.png` (+ `.txt` with the full output) rendered from real output with
  `python3 agents/tools/render_evidence.py`: one image per acceptance criterion where possible, plus the CI check
  runs for the head commit. UI changes also need screenshots of the actual page when the environment can produce them;
  otherwise the report says so. QA commits the pack, posts the report as a PR comment (if QA's harness can't write
  `report.md`, the orchestrator saves the PR comment body there verbatim, with a provenance line, before PM review), and on the Jira ticket adds a
  role-tagged comment listing every evidence file link plus a web link "QA evidence" to the folder
  (`createJiraIssueRemoteIssueLink`). Agent sandboxes cannot upload files to Jira (the media host is blocked), so
  evidence is linked, never pasted or summarised from memory.
- **PASS** → Step 6. **FAIL** → one rework round by the owner in this cycle (Step 4), then QA again.
  Second FAIL → **Blocked** with the report linked. **PENDING** → stays In QA for next cycle.
- Jira: comment `[qa-reviewer] PASS|FAIL|PENDING — <one-line reason> → <review file link>`; PASS → **PM review**;
  FAIL → back to **In Progress**.

## Step 6 — PM review and raise the PR (delegate to `pm-lead`)
Give `pm-lead` the ticket, the PRD rows, the approved design (if any), the diff summary and the QA evidence pack.
pm-lead opens every evidence file and checks product fit, scope, docs, and that each AC has convincing evidence.
- **APPROVE** → pm-lead rewrites the PR description from `agents/templates/pr.md` with an **Evidence** section: one row
  per AC with its screenshot embedded from this repo, pinned to the commit that added it
  (`![](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/<sha>/agents/reviews/<ID>/evidence/<file>.png?raw=true)`),
  CI check results, the QA verdict and the PM verdict. Then it **raises the PR**: marks it ready for review with
  `gh api -X POST repos/MaheshPulivarthi18/ArxivLens/pulls/<n>/ccr/ready_for_review`, and adds the label
  `ready-to-merge` if the API allows. Jira → **Ready to merge** + `[pm-lead] APPROVE — PR #n raised for review → link`.
- **CHANGES** → numbered list appended to `report.md`, PR stays draft, Jira → **In Progress**, rework round (Step 4)
  → QA → PM again. Counted toward the 2-round limit.

## Step 7 — PR review and merge (human)
Agents never merge. The human reviews PRs that are ready for review (not draft) with the evidence in the description,
then merges or comments. A human comment sends the task back to Step 4. Next cycle's Step 2 moves them to Done.

## Step 8 — Record
Commit directly to this repo's `main` (no PR; `git pull --rebase` first), and delete `agents/RUN_LOCK` in the same commit:
- `agents/board.md` — every move made this cycle
- `agents/PROGRESS.md` — one entry per task: outcome, PR, attempts, QA rounds, PM rounds, blockers
- Jira — confirm every story touched this cycle matches the repo (status, PR link, labels); fix drift.
- `agents/metrics.md` — one row for this cycle; count QA FAILs and PM CHANGES in "Fix rounds", and note the QA pass
  rate (first-round PASS / reviewed) in Notes

## Step 9 — Retro (self-improvement)
Run `.claude/commands/retro.md` for this cycle. Rule changes it proposes go on a `rules/<topic>` branch as a PR here. QA findings are the richest source: a finding type that recurs
(e.g. "missing refusal test", "AC without evidence") becomes a lesson for that developer role, and if it recurs
again, a proposed rule in their agent definition or the ticket template.

## Step 10 — Report
Short summary: PRs ready to merge (links), PRs in QA / rework and why, tasks blocked, decisions waiting for the human
(ADR numbers + one-line question each), and the metrics row.
