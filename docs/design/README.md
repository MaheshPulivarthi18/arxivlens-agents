# Tech designs

One file per task that needs a design (`docs/design/<TASK-ID>.md`, from `agents/templates/design.md`).

**When a design is required:** the ticket is **Large**: ≥ 150 changed lines, or it changes a shared contract (events,
HTTP API, schema, embedding model) or the architecture (AGENTS.md §2 "Size tiers"). An already approved design that
covers the ticket is enough; a short addendum section covers any new part. **Small** tickets skip it.

**Flow:** the owning developer writes the design here and commits it to `main` → pm-lead approves or requests
changes (filling "PM decision") → only then does the developer write code. qa-reviewer later checks the implementation
against both the ticket and the approved design. A design that changed during the build is updated here in the same cycle.
