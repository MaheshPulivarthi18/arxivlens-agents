# FE-0j: Pin `Badge` className precedence (caller classes override conflicting defaults)

| | |
|---|---|
| **Owner** | frontend-engineer |
| **Priority** | P3 (test hardening) |
| **PRD ref** | Product PRD §7 (readable, accessible UI); FE-0i QA r1 nit 1 + PM review (`agents/reviews/FE-0i/report.md`) |
| **Depends on** | FE-0i (#109) **merged** (same file `ui/badge.test.jsx`). No ADR |
| **Jira** | KAN-115 (frontend epic KAN-5) |
| **Design required** | no: test-only, one primitive |
| **Status** | Ready (#109 merged `8337086`). Not picked cycle 2026-11-21T21:59Z: 4-task cap, P3 (independent of FE-4: only `ui/badge.test.jsx`), next frontend slot |

## Goal
`Badge` builds its classes with `cn(badgeVariants({ variant }), className)`, so a caller's class wins over a conflicting default.
`ReferencesStack.jsx:42` relies on this (`className="text-xs px-2 py-0"` overrides the default `px-2.5 py-0.5`). No test pins it:
QA's mutant M5 `cn(className, badgeVariants({ variant }))` passes all 3 FE-0i tests and silently restores the default padding.

## Scope
- Files expected to change: `frontend/src/components/ui/badge.test.jsx` only (add one test or extend the AC2 test).
- Out of scope: `badge.jsx` (no product change), callers, `ReferencesStack.test.jsx`.
- Size: ~10 lines.

## Acceptance criteria
- [ ] AC1: `render(<Badge className="px-2 py-0">x</Badge>)` → element has `px-2` and `py-0` and **not** `px-2.5` / `py-0.5`.
- [ ] AC2: **Mutation check** (developer if Vitest runs, else QA's harness, evidence file): mutant M5 (`cn(className, badgeVariants({ variant }))`
  in `badge.jsx`) fails the new test, and the unmutated file passes. The FE-0i mutants M0–M4 stay killed.
- [ ] AC3: `npm run lint` (0 warnings) and `npm test` pass in the CI Frontend job. The Vitest test count is main + 1 (or +0 if an existing test is extended; say which), and the file count is unchanged.
- [ ] Docs: none.

## Verification
```bash
cd frontend && npm ci && npm run lint && npm test && npm run build   # CI Frontend job is the source of truth
git diff origin/main --name-only    # exactly frontend/src/components/ui/badge.test.jsx
```

## Notes
- 2026-11-21 (pm-lead): specced from FE-0i QA r1 nit 1 at the FE-0i PM review. Independent of #104 and FE-0g (`ui/primitives.test.jsx`).
