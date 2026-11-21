# OPS-H21: prefetch stops early on permanent failures, and pin the in-flight overrun guard with a test

| | |
|---|---|
| **Owner** | ai-engineer (`scripts/`, `tests/`) |
| **Priority** | P2 (harness quality) |
| **PRD ref** | Technical PRD §9 "External politeness", §10 Testing and evaluation; QA OPS-H19 r1 findings 1 and 2 `[nit]` (`agents/reviews/OPS-H19/report.md`) |
| **Depends on** | OPS-H19 (ArxivLens #111) **merged** (same two files) |
| **Jira** | needs creating: epic KAN-3 "Dev harness & infrastructure"; labels `task-OPS-H21`, `agent-ai`, `arxivlens` |
| **Design required** | no: control flow inside an existing CI script + unit tests; no flag, contract or workflow change |
| **Status** | Backlog (waits on OPS-H19 merge) |

## Goal
Two gaps QA found in OPS-H19, both small:
1. A **permanent** failure (a 404 PDF, or a 200 whose body is not a feed/PDF that persists) is re-tried every ≥ 60 s until the
   budget is spent, so the CI step exits 1 after ~17/42 min instead of seconds, and keeps asking arXiv for something that
   won't appear. Extra passes should run only while at least one failure is transient (429, 5xx, network error, or the
   `(time budget)` skip).
2. The guard "no request starts after the deadline" (`now >= self.deadline` in `Recorder.fetch`) is not pinned: QA mutant q2
   survives the suite because in the AC3 test a politeness gap always precedes the next request. On CI, a PDF download
   that runs past the deadline leaves no gap. QA's scenario (`agents/reviews/OPS-H19/evidence/04-ac3-overrun-scenario.txt`)
   shows the code is right; it should be a committed test.

## Scope
- `scripts/arxiv_replay.py`: `main`'s prefetch pass loop (and whatever minimal status plumbing it needs from `prefetch_query`).
- `tests/test_arxiv_replay.py`: new tests.
- Out of scope: retry counts/waits inside `Recorder.fetch`, `INTERVAL`, User-Agent, `serve`, workflows (`.github/`), `PASS_WAIT`.

## Acceptance criteria
- [ ] AC1: With a budget, if every failure in a pass is permanent (HTTP 4xx other than 429, or a non-feed/non-PDF 200 after
  its retries), prefetch does not start another pass: it exits 1 at once with the existing `prefetch FAILED for N: ...` line.
  Test: upstream scripted 404 for a PDF, `--budget-seconds 1000`, fake clock: exit 1, no cool-down sleep recorded,
  exactly one request for that PDF.
- [ ] AC2: A pass with mixed failures (one 404 PDF + one 429 feed) still retries, and the next pass includes only the queries
  with a transient failure. Test asserts the upstream log of pass 2.
- [ ] AC3: New test from QA's scenario: feed with 2 PDFs, `p1.pdf` takes 150 s against a 100 s budget, `INTERVAL` 3 s:
  `p2.pdf` is never requested, every request starts before the deadline, and `p2.pdf (time budget)` is reported.
- [ ] AC4: All existing tests in `tests/test_arxiv_replay.py` pass unmodified.
- [ ] AC5: Mutation check (output in an evidence file, revert each): (m1) treat all failures as transient → AC1 fails;
  (m2) remove the `now >= self.deadline` check before a request (QA's q2) → AC3 fails; (m3) treat all failures as
  permanent → AC2 fails.
- [ ] AC6: CI on the draft PR: `Lint`, the light Python job and `Full stack` green.
- [ ] Docs: the module docstring says which failures trigger another pass.

## Verification
```bash
python3 -m pytest -q tests/test_arxiv_replay.py
make test-py-light
make lint
git diff origin/main --name-only   # exactly scripts/arxiv_replay.py and tests/test_arxiv_replay.py
```

## Notes
- 2026-11-21 (pm-lead): created from QA OPS-H19 r1 findings 1 and 2. Treating `(time budget)` skips as transient keeps
  OPS-H19 AC1 behaviour for queries cut off by the deadline.
