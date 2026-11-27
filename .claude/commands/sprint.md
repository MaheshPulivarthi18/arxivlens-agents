---
description: Run one on-demand sprint cycle of the ArxivLens agent team (early exit → sync → plan → build → PR → QA → PM review → ready to merge → record)
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
The Design steps apply only to **Large** tickets (AGENTS.md §2 "Size tiers"). **Small** tickets (< 150 lines, no
contract/schema/architecture change) skip Design and Step 6: qa-reviewer gives one combined QA+PM verdict and raises
the PR itself. Real stage changes are mirrored to Jira following `agents/jira.md` (one story per bundle).

**Lean rules.** Findings never become new tickets: they are fixed in the same PR (rework round) or appended to the
parent ticket's `## Checklist`. Mutation testing only for risky code (AGENTS.md §2), locally, never pushed.

Roles never review their own work: the developer builds, **qa-reviewer** verifies against ticket + PRD + test results,
**pm-lead** gives the final product sign-off, the **human** merges.

## Step 0 — Workspace, early exit, run lock
Cycles run **on demand** (Mahesh asks, or a one-off scheduled fire), never hourly. `git pull --rebase` this repo and
clone or update the app repo (`git clone https://github.com/MaheshPulivarthi18/ArxivLens app` or `git -C app fetch origin`).

**Cheap early exit (check before anything else, read nothing else):**
1. `gh api 'repos/MaheshPulivarthi18/ArxivLens/pulls?state=all&per_page=30'`: any `agent/*` PR merged or closed since the
   last PROGRESS entry's timestamp? Any open agent PR with a review or untagged comment by MaheshPulivarthi18 newer
   than its last agent commit?
2. `agents/board.md` "Active": any ticket Ready whose `Depends on` are merged and that touches no open PR's files?
   (An ADR that Mahesh set to Accepted since the last entry counts: `git log --since=<last entry> -- docs/adr/`.)
If all answers are no: report "idle: nothing merged, no human feedback, nothing Ready" and **stop**. Don't load
memory, don't touch Jira, don't write PROGRESS or metrics, don't commit. (Release the lock if you had taken one.)

**Run lock** (only when there is work): if `agents/RUN_LOCK` exists and is less than 100 minutes old, report
"skipped: cycle <timestamp> still running" and stop. Otherwise write the UTC time and session link to it, commit and
push (push rejected → pull, re-check, stop if someone else holds it). Delete it in Step 8, or whenever you stop early.
All `git`/`make` commands for code run in `app/`; all memory edits happen here.

## Step 1 — Load memory
Read `AGENTS.md`, `agents/board.md`, the last 10 entries of `agents/PROGRESS.md`, the relevant role sections of
`agents/memory/lessons.md`, and the ADRs that the picked tickets reference (note which are Accepted). Read `agents/jira.md`
and query Jira (`project = KAN AND labels = arxivlens AND statusCategory != Done ORDER BY rank`) only if a story will
change stage this cycle.

## Step 2 — Sync with reality
In `app/`: `git fetch origin`; work from the latest `origin/main`. List PRs with REST (GraphQL is blocked):
`gh api 'repos/MaheshPulivarthi18/ArxivLens/pulls?state=all&per_page=50'`. For branches starting with `agent/`:
- Merged → **Done**.
- Closed without merge → back to **Ready**, closing reason in the task Notes if visible.
- Open with a **human review or comment** since the last agent commit (`gh api .../pulls/<n>/reviews` and
  `.../issues/<n>/comments`, author MaheshPulivarthi18, not starting with a `[role]` tag) → highest priority. Convert the
  PR back to draft (`ccr/convert_to_draft`), Jira → **In Progress**, and append to the ticket's `## Checklist` one
  line per review item. Items that need Mahesh's decision → Blocked on that decision (comment on the PR saying so);
  the rest → the owner addresses them (Step 4), then QA checks every checklist item.
- Open, new commits since the last QA report (or no report yet) → queue for **QA** (Step 5).
- Open, QA PASS but no PM verdict → queue for **PM review** (Step 6).
- An ADR that became `Accepted` unblocks its tasks: **Blocked → Ready**.
- Jira: merged PRs → transition the story to **Done**. New intake tickets and human (untagged) comments are handled
  as `agents/jira.md` describes — human comments get the same top priority as human PR comments. Human review items go
  into the ticket's `## Checklist`, not into new tickets.

## Step 3 — Plan (delegate to `pm-lead`)
Ask `pm-lead` to check the board (fix any `[spec]` findings in the ticket itself; spec new bundles only for PRD/roadmap
scope Mahesh agreed to) and return an ordered list of tickets for this cycle, respecting:
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
(`git -C app worktree add "$HOME/wt/<TASK-ID>" -b agent/<role>/<TASK-ID> origin/main`, outside both repos; run `echo $HOME` first and write the **expanded absolute path** into every subagent prompt, since `$HOME` is not the workspace parent), launched together and awaited
together. Rework items go first. QA and PM review for each PR also run in parallel. For each task:
0. **Design gate.** If the ticket is **Large** (or `design-required`) and there is no approved
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
Parallel QA and PM agents never share one `arxivlens-agents` checkout: give each its own (`git -C <workspace> worktree add --detach "$HOME/wt/agents-<role>-<TASK-ID>" origin/main`), and stage explicit paths only.
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
- **Small** tickets: QA also does the PM checks (pm-lead.md "Final review"), writes one combined verdict, and on PASS
  raises the PR itself exactly as Step 6 describes. Large tickets: **PASS** → Step 6.
- Findings go back into the same PR. Nothing QA finds becomes a new ticket; non-blocking nits the developer doesn't fix
  in this PR go on the ticket's `## Checklist`.
- **FAIL** → one rework round by the owner in this cycle (Step 4), then QA again.
  Second FAIL → **Blocked** with the report linked. **PENDING** → stays In QA for next cycle.
- Jira: comment `[qa-reviewer] PASS|FAIL|PENDING — <one-line reason> → <review file link>`; PASS → **PM review**;
  FAIL → back to **In Progress**.

## Step 6 — PM review and raise the PR (delegate to `pm-lead`)
Give `pm-lead` the ticket, the PRD rows, the approved design (if any), the diff summary and the QA evidence pack.
pm-lead opens every evidence file and checks product fit, scope, docs, and that each AC has convincing evidence.
- **APPROVE** → pm-lead first appends the PM verdict to `report.md` and pushes it to this repo's `main`, then rewrites the PR description from `agents/templates/pr.md` with an **Evidence** section: one row
  per AC with its screenshot embedded from this repo, pinned to the commit that added it
  (`![](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/<sha>/agents/reviews/<ID>/evidence/<file>.png?raw=true)`),
  CI check results, the QA verdict and the PM verdict. Then it **raises the PR**: marks it ready for review with
  `gh api -X POST repos/MaheshPulivarthi18/ArxivLens/pulls/<n>/ccr/ready_for_review`, and adds the label
  `ready-to-merge` if the API allows. Jira → **Ready to merge** + `[pm-lead] APPROVE — PR #n raised for review → link`.
- **CHANGES** → numbered list appended to `report.md`, PR stays draft, Jira → **In Progress**, rework round (Step 4)
  → QA → PM again. Counted toward the 2-round limit. PM review notes are fixed in the same PR or added to the ticket's
  `## Checklist`; never specced as follow-up tickets.

## Step 7 — PR review and merge (human)
Agents never merge. The human reviews PRs that are ready for review (not draft) with the evidence in the description,
then merges or comments. A human comment sends the task back to Step 4. Next cycle's Step 2 moves them to Done.

## Step 8 — Record
Commit directly to this repo's `main` (no PR; `git pull --rebase` first), and delete `agents/RUN_LOCK` in the same commit:
- `agents/board.md` — every move made this cycle
- `agents/PROGRESS.md` — one short entry for the cycle: per ticket outcome, PR, QA/PM rounds, blockers
- Jira — only the stories that changed stage this cycle: status, PR link. No "no change" comments.
- `agents/metrics.md` — one row for this cycle; count QA FAILs and PM CHANGES in "Fix rounds", and note the QA pass
  rate (first-round PASS / reviewed) in Notes

## Step 9 — Retro (self-improvement)
Only when the cycle had a FAIL, a CHANGES or a Blocked ticket: run `.claude/commands/retro.md` for this cycle. Rule changes it proposes go on a `rules/<topic>` branch as a PR here. QA findings are the richest source: a finding type that recurs
(e.g. "missing refusal test", "AC without evidence") becomes a lesson for that developer role, and if it recurs
again, a proposed rule in their agent definition or the ticket template.

## Step 10 — Report
Short summary: PRs ready to merge (links), PRs in QA / rework and why, tasks blocked, decisions waiting for the human
(ADR numbers + one-line question each), and the metrics row.
