# <TASK-ID>: <outcome, in the user's words>

| | |
|---|---|
| **Owner** | ai-engineer / backend-engineer / frontend-engineer / pm-lead |
| **Priority** | P0 / P1 / P2 |
| **PRD ref** | e.g. QA-8, Technical PRD §11 |
| **Depends on** | task IDs and/or ADR numbers (must be Done / Accepted) |
| **Jira** | `KAN-n` (one story per bundle; find with JQL `labels = "task-<ID>"`) |
| **Tier** | Small (< 150 lines, no contract/schema/architecture change: no design, one combined QA+PM review) / Large (design doc, QA, then PM) |
| **Size estimate** | ~N changed lines incl. tests (bundle limit ~800; split only if a reviewer couldn't follow it) |
| **Absorbs** | older task IDs / KAN keys this bundle replaces (they are closed with a pointer here) |
| **Status** | Ready / Design / In progress / In QA / PM review / Ready to merge / Blocked (reason) / Done |

## Goal
One or two sentences: the user-visible or system outcome, and why it matters.

## Scope
- Files/directories expected to change:
- Out of scope:

## Acceptance criteria
- [ ] AC1 — observable, testable statement
- [ ] AC2 —
- [ ] Docs: PRD status / README updated if behaviour changed

## Checklist
Review findings and human review items that are not fixed in the PR round they were found in. They are part of this
ticket, never new tickets. QA checks every open line in its next round.
- [ ] (none yet)

## Verification
```bash
make test-unit
make lint
# task-specific commands
```

## Notes
(Owner appends: decisions made, things tried, blockers with exact errors.)
