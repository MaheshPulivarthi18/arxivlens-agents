# arxivlens-agents

Private workspace and memory for the AI agent team that builds
[ArxivLens](https://github.com/MaheshPulivarthi18/ArxivLens). The product repo holds only runnable code; everything
about *how* it gets built lives here.

| Here | Purpose |
|---|---|
| `docs/PRD-Product.md`, `docs/PRD-Technical.md` | What we build and why |
| `docs/adr/` | Decisions (Proposed → Accepted by Mahesh) |
| `docs/design/` | Tech designs for design-required tasks |
| `agents/tasks/`, `agents/board.md` | Tickets and the kanban (mirrored to Jira project KAN) |
| `agents/reviews/<ID>/` | QA reports and evidence screenshots, embedded into ArxivLens PRs |
| `agents/PROGRESS.md`, `agents/metrics.md`, `agents/memory/` | History, cycle metrics, lessons |
| `.claude/agents/`, `.claude/commands/` | The five agents and the `/sprint` and `/retro` loops |

**Start here:** [`AGENTS.md`](AGENTS.md). A scheduled task runs `/sprint` every 6 hours from this repo, with ArxivLens
cloned at `app/`.

**Flow:** PM spec + Jira → (design) → developer draft PR in ArxivLens → QA evidence here → PM raises the PR →
Mahesh reviews and merges. A review from Mahesh goes back to the developer as a checklist on the next cycle.
