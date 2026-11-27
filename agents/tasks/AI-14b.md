# AI-14b: pin the right word boundary of the table-section rule ("Tablet" is not a table section)

| | |
|---|---|
| **Owner** | ai-engineer (`internal/query/rag_test.go`) |
| **Priority** | P2 (answer quality guard: without it, a regression silently drops relevant passages scored 0.45-0.70 from `/v1/ask`) |
| **PRD ref** | Product PRD QA-6 "De-prioritize appendix, supplementary, and table passages unless strongly relevant" (✅); Technical PRD §7.2 (aux cutoff `0.70`). Source: QA AI-14 r1 nit 1 + PM review item 1 (`agents/reviews/AI-14/report.md`, mutant m7 survived, [03b](../reviews/AI-14/evidence/03b-ac1-boundary-probes.png)) |
| **Depends on** | AI-14 (ArxivLens #115) **merged** as `53171d6` (it added `tableWordRegex`). No open PR touches `internal/query/rag_test.go` or `rag.go` (checked 2026-11-27T09:00Z against #122-#128). AI-5 (Blocked on ADR-0011) edits `rag.go` later and doesn't wait on this |
| **Jira** | KAN-131, story under epic KAN-2 "Retrieval & answer quality gates"; labels `task-AI-14b`, `agent-ai`, `arxivlens` |
| **Design required** | no: test rows only; no code, threshold, API or contract change |
| **Status** | Ready |

## Goal
AI-14 made the table rule whole-word: `tableWordRegex = (?i)(^|[^\pL])tables?([^\pL]|$)` (`internal/query/rag.go:832` @ `53171d6`).
The `TestFilterRelevantHits` table (`rag_test.go:148-189`) pins the **left** boundary ("Notable", "Stable", "Suitable",
"Timetable") but nothing pins the **right** one: QA's mutant m7 (drop `([^\pL]|$)`) leaves all 19 subtests green, and would
again push titles such as "Tablet experiments" or "Tableau dashboards" behind the 0.70 auxiliary cutoff. Add rows that
fail when the right boundary is removed.

## Scope
- Files expected to change: `internal/query/rag_test.go` only (new rows in the existing `TestFilterRelevantHits` table,
  next to the AI-14 rows at `rag_test.go:168-176`).
- Out of scope: `internal/query/rag.go` (no code or comment change; the regex is correct), the cutoff values `0.45`/`0.70`,
  the zero-rerank bypass (AI-5 / ADR-0011), and **"Appendices"**: whether it should count as auxiliary (the `appendix`
  substring doesn't match it) is a product question left *Proposed* for Mahesh on the board; don't add it here.

## Acceptance criteria
- [ ] AC1: at least two new rows at rerank `0.5`, each expected **kept** (`[]int64{1}`), whose titles start with "table" as
  the prefix of a longer word: `ragHit(1, "Tablet experiments", 0.5)` and `ragHit(1, "Tableau dashboards", 0.5)`. Row names
  follow the existing style (e.g. `"word starting with table kept: Tablet"`).
- [ ] AC2: every existing `TestFilterRelevantHits` row is unchanged (no row edited or removed; diff is additions only) and
  the whole `internal/query` package passes.
- [ ] AC3 (mutants, developer or QA harness, evidence file with the command and output; one mutant per boundary side):
  on a copy of `rag.go`,
  - m7 `(?i)(^|[^\pL])tables?([^\pL]|$)` → `(?i)(^|[^\pL])tables?` makes both AC1 rows FAIL (named in the output);
  - m6 `(?i)(^|[^\pL])tables?([^\pL]|$)` → `(?i)tables?([^\pL]|$)` still fails at least one of the AI-14 left-boundary rows ("Notable", "Stable", "Suitable", "Timetable")
    (regression check that the new rows didn't replace the old ones);
  - the unmutated file passes.
- [ ] AC4: CI on the PR head: check-run `Go (vet, gofmt, test, build)` green (it runs `make lint-go` and the step
  `Go unit tests (make test-go, race detector)`), and `Agent ownership check` green.
- [ ] Docs: none (no behaviour change; app `README.md` / `CONTRIBUTING.md` untouched).

## Verification
```bash
cd app
go test -count=1 -run 'TestFilterRelevantHits' -v ./internal/query/   # lists the new rows as PASS
make lint-go                                                          # go vet + gofmt
make test-go
# mutants (AC3): apply m7 / m6 to a copy of rag.go (or a scratch package as in agents/reviews/AI-14 evidence 03)
# and re-run the -run 'TestFilterRelevantHits' command; paste the FAIL lines
```
Local Go may be 1.24 (go.mod needs 1.25): `GOTOOLCHAIN=local` quick checks or QA's scratch-package harness are fine;
CI is the source of truth (AGENTS.md §4).

## Notes
- 2026-11-27T09:00Z (pm-lead): specced from the AI-14 follow-up Backlog line, part (a). Checked on `origin/main` `53171d6`:
  no row in `rag_test.go` contains "Tablet"/"Tableau" or any other "table"-prefixed longer word. Part (b) ("Appendices")
  stays on the board as *Proposed* for Mahesh. Lesson applied: one row per boundary side (pm-lead lesson 2026-11-21 AI-14).
