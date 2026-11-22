# OPS-H21: prefetch stops early on permanent failures, reports `saved=` as soon as it records, and pin the in-flight overrun guard with a test

| | |
|---|---|
| **Owner** | ai-engineer (`scripts/`, `tests/`) |
| **Priority** | P2 (harness quality; item 3 protects eval-store convergence) |
| **PRD ref** | Technical PRD §9 "External politeness", §10 Testing and evaluation; QA OPS-H19 r1 findings 1 and 2 `[nit]` (`agents/reviews/OPS-H19/report.md`); QA OPS-H20 r1 finding 2 `[spec]` (`agents/reviews/OPS-H20/report.md`) |
| **Depends on** | OPS-H19 (ArxivLens #111) **merged** (same two files: #111 = `scripts/arxiv_replay.py`, `tests/test_arxiv_replay.py`, REST `pulls/111/files` 2026-11-21 13:10Z). No overlap with OPS-H20 #114 (`eval.yml` only; this ticket edits no workflow) |
| **Jira** | KAN-119 (epic KAN-3 "Dev harness & infrastructure"; labels `task-OPS-H21`, `agent-ai`, `arxivlens`) |
| **Design required** | no: control flow inside an existing CI script + unit tests; no flag, contract or workflow change |
| **Status** | Ready to merge: ArxivLens #123 @ `0970737` raised for review 2026-11-22 (QA r1 PASS, PM APPROVE) |

## Goal
Three gaps QA found in OPS-H19 and OPS-H20, all small and all in `main`'s prefetch path:
1. A **permanent** failure (a 404 PDF, or a 200 whose body is not a feed/PDF that persists) is re-tried every ≥ 60 s until the
   budget is spent, so the CI step exits 1 after ~17/42 min instead of seconds, and keeps asking arXiv for something that
   won't appear. Extra passes should run only while at least one failure is transient (429, 5xx, network error, or the
   `(time budget)` skip).
2. The guard "no request starts after the deadline" (`now >= self.deadline` in `Recorder.fetch`) is not pinned: QA mutant q2
   survives the suite because in the AC3 test a politeness gap always precedes the next request. On CI, a PDF download
   that runs past the deadline leaves no gap. QA's scenario (`agents/reviews/OPS-H19/evidence/04-ac3-overrun-scenario.txt`)
   shows the code is right; it should be a committed test.
3. (OPS-H20 QA finding 2) `saved=<n>` goes to `$GITHUB_OUTPUT` only at the very end of `main` (`arxiv_replay.py:328-330`
   @ #111 head `5b4d6a2`). If the step is killed at its `timeout-minutes: 45` (possible: the budget is checked only between
   queries, and one query can run ~22 min in flight), `saved` is never written, "Save arXiv replay store" is skipped
   (`if: always() && steps.prefetch.outputs.saved != '' && ... != '0'`) and that run's partial recording is lost, which
   breaks convergence in exactly the slow, rate-limited case. Report it as soon as the store gains its first entry.

## Scope
- `scripts/arxiv_replay.py`: `main`'s prefetch pass loop (and whatever minimal status plumbing it needs from `prefetch_query`).
- `tests/test_arxiv_replay.py`: new tests.
- Out of scope: retry counts/waits inside `Recorder.fetch`, `INTERVAL`, User-Agent, `serve` behaviour, workflows (`.github/`:
  the existing `saved != '' && saved != '0'` conditions already work with item 3), `PASS_WAIT`, a per-request deadline.

## Acceptance criteria
- [x] AC1: With a budget, if every failure in a pass is permanent (HTTP 4xx other than 429, or a non-feed/non-PDF 200 after
  its retries), prefetch does not start another pass: it exits 1 at once with the existing `prefetch FAILED for N: ...` line.
  Test: upstream scripted 404 for a PDF, `--budget-seconds 1000`, fake clock: exit 1, no cool-down sleep recorded,
  exactly one request for that PDF.
- [x] AC2: A pass with mixed failures (one 404 PDF + one 429 feed) still retries, and the next pass includes only the queries
  with a transient failure. Test asserts the upstream log of pass 2.
- [x] AC3: New test from QA's scenario: feed with 2 PDFs, `p1.pdf` takes 150 s against a 100 s budget, `INTERVAL` 3 s:
  `p2.pdf` is never requested, every request starts before the deadline, and `p2.pdf (time budget)` is reported.
- [x] AC4: All existing tests in `tests/test_arxiv_replay.py` pass unmodified.
- [x] AC5: Mutation check (output in an evidence file, revert each): (m1) treat all failures as transient → AC1 fails;
  (m2) remove the `now >= self.deadline` check before a request (QA's q2) → AC3 fails; (m3) treat all failures as
  permanent → AC2 fails.
- [x] AC7 (item 3): `prefetch` keeps exactly **one** `saved=<n>` line in `$GITHUB_OUTPUT`: it is appended right after
  the first entry it adds to the store is on disk, and rewritten in place (same offset, never a second `saved=` key)
  after each later save, so at any moment it holds the count saved so far. It writes none if it adds nothing (the step
  output stays `''`, the save step is skipped as today). No separate final `saved=<count>` append at exit.
  `serve --record` never writes `$GITHUB_OUTPUT`. The stats line still prints the full count. Tests (with
  `GITHUB_OUTPUT` pointed at a tmp file): (a) first query saves, second query's fetch raises (simulating a kill): the
  file already holds `saved=1`; (b) a run that saves 3 entries leaves exactly one `saved=` line, `saved=3`; (c) an
  all-hit run writes none; (d) `serve --record` saving an entry writes none. *(Reworded 2026-11-22, see Notes.)*
- [x] AC8: Mutation (same evidence file as AC5): (m4) move the write back to the end of `main` → AC7(a) fails.
- [x] AC6: CI on the draft PR: `Python M0 unit tests` (runs `make test-py-light`), `Full stack (compose + make test-full)`
  and `eval` (triggered by `scripts/arxiv_replay.py`; its "Lint the harness" step runs actionlint) green. There is no
  separate `Lint` check.
- [x] Docs: the module docstring says which failures trigger another pass and when `saved=` is written.

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
- 2026-11-21 13:00Z (pm-lead): folded QA OPS-H20 r1 finding 2 `[spec]` in as item 3 / AC7-AC8 instead of a new ticket:
  same file, same owner, same dependency (#111), and a second ticket would have to queue behind this one anyway.
  Chose "write once on first save" over a per-request deadline: it survives any kill (step or job timeout,
  cancellation) and needs no workflow change; a repeated `saved=` key is avoided so nothing relies on last-write-wins.
  AC6 wording fixed to the real check names (same fix as OPS-H20 AC3, QA finding 4).
- 2026-11-22 (ai-engineer): built on `agent/ai/OPS-H21` @ `0970737` (2 files, 170+/23-, ownership OK).
  `transient()` = 429, >= 500 (504 = network error) or `BUDGET`. `Recorder.fetch` now returns `BAD_BODY` (-1) for a
  200 that isn't a feed/PDF after its retries, so it isn't counted as a real 502 (serve still answers 502; retry
  counts/waits unchanged). Queries whose failures are all permanent are kept in `given_up` and reported at exit.
  **AC4 vs AC7 conflict, needs a decision:** two existing tests assert `saved=2` / `saved=3` at the end of a run, but a single
  line written only at the first save would hold `saved=1`, which breaks AC4 ("existing tests unmodified"). To meet both, the line is
  appended at the first save and then **rewritten in place** (same byte offset) after each later save. n only grows, so the line is
  never shortened, and there is exactly one `saved=` key, no last-write-wins. A kill leaves the last completed value.
  If pm-lead prefers a strict write-once `saved=1`, those two existing assertions would have to change.
  Local: `pytest tests/test_arxiv_replay.py` 20 passed (13 old, unmodified + 7 new). Mutants m1-m4 are each killed by
  their target test (temp copies, worktree clean). `make test-py-light` can't collect `tests/test_worker_heartbeat.py`
  (no `confluent_kafka`, PyPI unreachable), so the other 3 light files were run: 303 passed, 1 skipped. `make lint` is Go/frontend
  only (no Go 1.25 or npm here). ruff shows the same 3 findings as origin/main, none new. CI (AC6) is pending the PR.
- 2026-11-22 (pm-lead): **AC7 reworded** (QA OPS-H21 r1 finding 3 `[spec]`). The intended reading is the one the PR
  implements: a single `saved=` line created at the first save and kept current in place. The old text ("writes exactly
  one `saved=` line ... right after the first entry") read as write-once `saved=1`, which contradicted AC4 (existing
  tests assert `saved=2` / `saved=3` at the end) and the goal (the save step only needs `!= ''`/`!= '0'`, but the value
  should be truthful). The rewrite never shortens the line (n only grows) and nothing else writes to the step's
  `$GITHUB_OUTPUT` after it, so it is safe; QA probe 05 covers the 9 -> 12 digit growth.
- 2026-11-22 (pm-lead): QA findings 1 and 2 `[nit]` (no committed test for 5xx/network-error = transient, mutant x5; no
  test for one query with a 404 and a 429 PDF, mutant x6) -> follow-up **OPS-H22** (ai-engineer, P2, tests only,
  depends on this PR merged). QA's side note (pass 2 re-requests the permanent PDF of a query that is retried) is
  accepted as-is: bounded by the pass count, and AC2 retries per query by design; no per-name skip set.
  Finding 4 (equivalent BUDGET mutants): no action. PM verdict APPROVE in `agents/reviews/OPS-H21/report.md`.
