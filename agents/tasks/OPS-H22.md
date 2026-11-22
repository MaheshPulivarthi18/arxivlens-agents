# OPS-H22: pin the transient-failure classification of prefetch with tests (5xx, network error, mixed query)

| | |
|---|---|
| **Owner** | ai-engineer (`tests/`) |
| **Priority** | P2 (harness quality) |
| **PRD ref** | Technical PRD §9 "External politeness", §10 Testing and evaluation; QA OPS-H21 r1 findings 1 and 2 `[nit]` (`agents/reviews/OPS-H21/report.md`) |
| **Depends on** | OPS-H21 (ArxivLens #123) **merged**: same test file, and the tests target its `transient()` / per-query retry logic |
| **Jira** | to be created under epic KAN-3 (labels `task-OPS-H22`, `agent-ai`, `arxivlens`) |
| **Design required** | no: tests only, no code, flag, contract or workflow change |
| **Status** | Backlog (waits for #123 to merge; then Ready) |

## Goal
OPS-H21 made prefetch retry only transient failures, but two parts of that rule are not pinned by any committed test:
QA mutant x5 (`status >= 500` -> `>= 505`, which makes 503 and the 504 used for network errors permanent) and mutant x6
(`any(transient)` -> `all(transient)` per query) both survive the suite. Add the tests so a later change can't silently
stop retrying arXiv outages or mixed-failure queries.

## Scope
- `tests/test_arxiv_replay.py`: new tests only (reuse the existing `env`, `Clock`, `FEED`, `PDF` fixtures).
- Out of scope: any change to `scripts/arxiv_replay.py` (if a test exposes a bug, stop and report it in Notes);
  a per-PDF-name skip set for permanent failures inside a retried query (PM decision 2026-11-22: not wanted).

## Acceptance criteria
- [ ] AC1: A PDF answered 503 (all in-fetch retries) in pass 1, then 200 in pass 2, with `--budget-seconds 1000` and a
  fake clock: prefetch runs a second pass after one cool-down, saves the PDF and exits 0.
- [ ] AC2: Same as AC1 with the PDF fetch raising a network error (`TimeoutError` / `URLError`) in pass 1.
- [ ] AC3: One feed with a 404 `p1.pdf` and a 429 `p2.pdf` (429 for all in-fetch retries in pass 1, 200 in pass 2):
  the query gets a second pass, `p2.pdf` is saved, and the exit report (exit 1) names only `p1.pdf`.
- [ ] AC4: All existing tests in `tests/test_arxiv_replay.py` pass unmodified; `git diff origin/main --name-only` is
  exactly `tests/test_arxiv_replay.py`.
- [ ] AC5: Mutation check (evidence file, each on a temp copy and reverted): x5 (`or status >= 500` -> `or status >= 505`
  in `transient`) fails AC1 and AC2; x6 (`if any(transient(s) for _, s in f):` -> `if f and all(transient(s) for _, s in f):`)
  fails AC3.
- [ ] AC6: CI on the draft PR: `Python M0 unit tests` green (this ticket touches no file that triggers `eval`).

## Verification
```bash
python3 -m pytest -q tests/test_arxiv_replay.py
make test-py-light
git diff origin/main --name-only   # exactly tests/test_arxiv_replay.py
```
QA's ready-made probes are in `agents/reviews/OPS-H21/evidence/08-harness-sources.txt` (`test_qa_probe.py`:
`test_probe_5xx_gets_another_pass`, `test_probe_network_error_gets_another_pass`,
`test_probe_query_with_404_and_429_pdf_is_retried`); adapt them, don't import from the evidence folder.

## Notes
- 2026-11-22 (pm-lead): created from QA OPS-H21 r1 findings 1 and 2 during PM review of #123. Kept out of #123 so the
  approved PR isn't reopened for non-blocking nits.
