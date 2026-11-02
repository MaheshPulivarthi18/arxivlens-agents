# agents/ — Team memory

Agents forget everything between sessions. This folder is what they remember. Every file is plain Markdown in git,
so the team's memory is versioned and correctable by a human. Bookkeeping (tasks, board, progress, metrics, lessons,
reviews) is committed straight to `main`; templates, tools and `jira.md` change only via PR (see `AGENTS.md` §0).

| File | Purpose | Written by | Read |
|---|---|---|---|
| `board.md` | Kanban: Ready / In progress / In QA / PM review / Ready to merge / Blocked / Done | orchestrator, pm-lead | every session |
| `tasks/<ID>.md` | One spec per task: scope, acceptance criteria, verification, notes | pm-lead (spec), owner (notes) | by the owner |
| `PROGRESS.md` | Append-only log, newest first, one entry per task per cycle | orchestrator | last 20 entries |
| `memory/lessons.md` | Short, deduplicated rules learned from friction, per role | `/retro` | every session |
| `memory/archive.md` | Retired lessons | `/retro` | rarely |
| `metrics.md` | One row per sprint cycle: throughput, first-pass rate, blocks | orchestrator | `/retro` |
| `reviews/<ID>/` | QA report + evidence screenshots + PM verdict per task, also posted on the ArxivLens PR | qa-reviewer, pm-lead | pm-lead, developer on rework |
| `jira.md` | How the repo maps to Jira (epics, stories, stages, comment tags, intake) | humans | every agent touching Jira |
| `area-notes/` | Rules per code area of the app repo (frontend, internal, services) | humans (via PR) | developers, QA |
| `tools/` | `render_evidence.py` (real output → labelled PNG) | humans (via PR) | qa-reviewer |
| `templates/` | Task spec, design, PR and QA report templates | humans | pm-lead, developers, qa-reviewer, orchestrator |

Product docs live in `docs/` (PRDs, `adr/`, `design/`). Decisions live in `docs/adr/`. Only the human owner moves an ADR to `Accepted`.

## How the loop runs

```
                    ┌──────────────── /sprint (scheduled) ────────────────┐
 memory ──► sync PRs/ADRs ──► pm-lead specs ──► developer builds ──► PR + CI
   ▲                                                                   │
   │                       FAIL / CHANGES ◄── qa-reviewer (PASS?) ◄─────┘
   │                       (back to developer)        │ PASS
   │                                                  ▼
   │                                       pm-lead final review
   │                                                  │ APPROVE
   │                                                  ▼
   └── /retro lessons ◄── record ◄── Ready to merge ──► human merges
```

## Human touchpoints (the only ones)
1. Review ArxivLens PRs that reached **Ready to merge** (QA PASS + PM APPROVE, evidence in the description): merge, or
   leave a review — the next cycle sends it back to the developer with your items as a checklist.
2. Accept or reject ADRs in `docs/adr/` (or tell an agent your decision in chat and it records it for you).
3. Approve PRs in this repo that change agent rules, templates or PRDs (`rules/…`, `docs/…` branches).
