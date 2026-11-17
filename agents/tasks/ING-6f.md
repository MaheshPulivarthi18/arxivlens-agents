# ING-6f: `stack.yml` prints the `published` order of the recorded arXiv search feed (ING-6 design Risk 1, before ING-6b)

| | |
|---|---|
| **Owner** | backend-engineer (`.github/workflows/stack.yml`) |
| **Priority** | P1 (unblocks ING-6b: its crash-safe advance assumes `sortBy=submittedDate&sortOrder=descending` returns entries in descending `<published>` order) |
| **PRD ref** | Product ING-6; Technical PRD §11 "Scheduled crawler", §9 (arXiv politeness: no new arXiv requests). Design `docs/design/ING-6.md` §"Risks and rollout" (Risk 1) and PM condition 3. Source: ING-6a QA r1 finding 7 [spec] (`agents/reviews/ING-6a/report.md`), ING-6a AC10 |
| **Depends on** | none to build. Independence (checked 2026-11-17): no open PR touches `.github/workflows/stack.yml` (#51–#57: docs/evals, `db.yml`, `ci.yml`/Makefile, `rag.go`, `internal/db`/`internal/downloader`, `internal/crawler/loop*.go`, `migrations/000005_*`). **Not in parallel with OPS-H12** (same file): ING-6f goes first (P1); OPS-H12 starts after this PR merges or rebases on it |
| **Jira** | not created yet (orchestrator: story under KAN-18's epic, `labels = "task-ING-6f"`, `agent-backend`, `arxivlens`) |
| **Design required** | no: CI-only, ~25 lines, no CLI/table/service/contract change, informational (not a gate) |
| **Status** | Ready (specced 2026-11-17 by pm-lead) |

## Goal
Answer ING-6 design Risk 1 from data before ING-6b is built. The only committed feed (`internal/crawler/testdata/arxiv_feed.xml`) is a
hand-written ascending fixture. The real arXiv response for the crawler's first-page query is recorded only in the `stack.yml` Actions
cache (`.arxiv-replay`), which agent sandboxes can't download. One informational step prints each recorded search feed's entries in file
order, with a one-line verdict, into the job log, where QA and pm-lead can read it through the REST job-log API.

## Scope
- File: `.github/workflows/stack.yml` only. One new step, named exactly `ING-6 Risk 1: published order of recorded search feeds`, placed
  after `Save arXiv replay store` and before `Start the arXiv replay proxy (replay-only)`. Inline `python3 -I - <<'PY' … PY` (stdlib only:
  `glob`, `json`, `xml.etree.ElementTree`) or an equivalent shell + Python block.
- Behaviour: for every `.arxiv-replay/api/*.json` meta file whose `query` contains `sortBy=submittedDate`, read the sibling body file
  (same name without `.json`), parse the Atom feed and print, in file order:
  - `RISK1 query=<meta query>`
  - one line per entry: `RISK1 entry <n> <arxiv id incl. version> published=<published text as in the feed>`
  - one verdict line: `RISK1 ORDER descending` (every `published` ≥ the next one; ties count as descending), `RISK1 ORDER NOT descending
    (first violation: entry <i> <published> < entry <i+1> <published>)`, or `RISK1 ORDER n/a (<k> entries)` for fewer than 2 dated entries.
  - When no such meta file exists: `RISK1 none: no recorded sortBy=submittedDate feed in .arxiv-replay/api` and a `::warning::`.
  - Parse/IO errors: `::warning::` with the error, and the step still exits 0.
- The step **never fails the job** (it is a probe, not a gate; ING-6c's `out_of_order` summary field gives ongoing detection). It makes no
  network request and doesn't change the replay store (read-only; the cache save step is before it).
- One header-comment line in `stack.yml` naming the step's purpose (`ING-6 Risk 1`). No README/CONTRIBUTING change (no user-facing
  command or behaviour changes).
- Out of scope: any change to `scripts/arxiv_replay.py`, the prefetch arguments (no larger or new recording: that would add arXiv requests),
  `Makefile` (#53), `eval.yml`, `db.yml`, any Go code, OPS-H12's `-rA` change.

## Acceptance criteria
- [ ] AC1 — The PR's own `stack.yml` run (it triggers on `.github/workflows/stack.yml`) contains the step by its exact name, and the job log
  has the `RISK1 query=…` line for `cat:cs.LG`, one `RISK1 entry` line per entry, and one `RISK1 ORDER …` line. Evidence: the step's lines
  from `gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/<job id>/logs` (job log, not an artifact or step summary), pasted in the PR
  body and rendered by QA. If the run printed `RISK1 none`, say so and stop (the replay store has no search feed; pm-lead decides).
- [ ] AC2 — Verdict logic, run locally (no CI needed) on two scratch stores built from `internal/crawler/testdata/arxiv_feed.xml` (body file +
  `{"query": "search_query=cat%3Acs.LG&sortBy=submittedDate&…"}` meta): the file as committed (ascending, `2023-07-17T17:50:36Z` then
  `2024-01-22T09:00:00Z`) prints `RISK1 ORDER NOT descending (first violation: entry 1 …)`; a copy with the two `<entry>` blocks swapped
  prints `RISK1 ORDER descending`; a store with only a non-`sortBy` meta (`id_list=…`) prints `RISK1 none` and exits 0; a body that isn't
  XML prints a `::warning::` and exits 0. Paste the four outputs and exit codes in the PR (extract the step's script to a scratch file to run it).
- [ ] AC3 — The job's result isn't changed by the probe: the step exits 0 in the PR run, every other `stack.yml` step's outcome matches the
  latest `main` run of `stack.yml` (list both runs' step conclusions), and `actionlint` (the existing `Lint the harness` step) passes.
- [ ] AC4 — `git diff --stat origin/main` lists only `.github/workflows/stack.yml`, < 40 changed lines; `ownership-check.sh` OK for backend.
- [ ] AC5 — The PR body quotes the verdict line and the `published` values, and says in one line what it means for ING-6b:
  `descending` → Risk 1 cleared for this sample (2 entries; ongoing detection via ING-6c's `out_of_order`); `NOT descending` → "ING-6b stays
  Blocked; pm-lead revisits design §2 rule (a)".

## Verification
```bash
cd app
git diff --stat origin/main                       # AC4: only stack.yml
bash .github/scripts/ownership-check.sh origin/main agent/backend/ING-6f
# AC2 (local): extract the step's Python to a scratch file, then for each scratch store:
#   (cd <scratch-store-parent> && python3 -I <scratch>/risk1.py); echo "exit=$?"
# AC1/AC3 (CI): the PR's "Full stack" run
gh api 'repos/MaheshPulivarthi18/ArxivLens/commits/<head sha>/check-runs' --jq '.check_runs[] | "\(.id) \(.name) \(.conclusion)"'
gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/<full stack job id>/logs | grep -E 'RISK1|::warning::'
```

## Notes
- 2026-11-17 (pm-lead): created from ING-6a QA r1 finding 7 [spec] (design Risk 1 triggered: the only committed feed is a synthetic ascending
  fixture). Why a separate task and not ING-6b or ING-6c: ING-6c is after 6b, and ING-6b needs the answer *before* it's built, so it can't be
  one of 6b's own ACs. It's a different file from 6a/6b (`stack.yml` vs `internal/**`), so it can run now while #56/#57 are in review.
  The answer arrives with the PR's own CI run; **ING-6b needs the result recorded here (verdict `descending`), not this PR merged**, because
  they share no files. pm-lead records the verdict line and run/job IDs in these Notes when QA reports it.
- The sample is the 2 entries the cache recorded once (fixed until the cache key changes). That's what design Risk 1 asked for; a bigger sample
  would need new arXiv requests and isn't worth it, because rule (a) already tolerates a few out-of-order entries and ING-6c prints `out_of_order`
  every pass.
