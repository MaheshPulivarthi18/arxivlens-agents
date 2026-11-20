# ING-6f: `stack.yml` prints the `published` order of the recorded arXiv search feed (ING-6 design Risk 1, before ING-6b)

| | |
|---|---|
| **Owner** | backend-engineer (`.github/workflows/stack.yml`) |
| **Priority** | P1 (unblocks ING-6b: its crash-safe advance assumes `sortBy=submittedDate&sortOrder=descending` returns entries in descending `<published>` order) |
| **PRD ref** | Product ING-6; Technical PRD §11 "Scheduled crawler", §9 (arXiv politeness: no new arXiv requests). Design `docs/design/ING-6.md` §"Risks and rollout" (Risk 1) and PM condition 3. Source: ING-6a QA r1 finding 7 [spec] (`agents/reviews/ING-6a/report.md`), ING-6a AC10 |
| **Depends on** | none to build. Independence (checked 2026-11-17): no open PR touches `.github/workflows/stack.yml` (#51–#57: docs/evals, `db.yml`, `ci.yml`/Makefile, `rag.go`, `internal/db`/`internal/downloader`, `internal/crawler/loop*.go`, `migrations/000005_*`). **Not in parallel with OPS-H12** (same file): ING-6f goes first (P1); OPS-H12 starts after this PR merges or rebases on it |
| **Jira** | not created yet (orchestrator: story under KAN-18's epic, `labels = "task-ING-6f"`, `agent-backend`, `arxivlens`) |
| **Design required** | no: CI-only, ~25 lines, no CLI/table/service/contract change, informational (not a gate) |
| **Status** | **Done**: merged by Mahesh, ArxivLens [#58](https://github.com/MaheshPulivarthi18/ArxivLens/pull/58) → `8b55af2` (2026-11-19) |

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
- [x] AC1 — The PR's own `stack.yml` run (it triggers on `.github/workflows/stack.yml`) contains the step by its exact name, and the job log
  has the `RISK1 query=…` line for `cat:cs.LG`, one `RISK1 entry` line per entry, and one `RISK1 ORDER …` line. Evidence: the step's lines
  from `gh api repos/MaheshPulivarthi18/ArxivLens/actions/jobs/<job id>/logs` (job log, not an artifact or step summary), pasted in the PR
  body and rendered by QA. If the run printed `RISK1 none`, say so and stop (the replay store has no search feed; pm-lead decides).
- [x] AC2 — Verdict logic, run locally (no CI needed) on two scratch stores built from `internal/crawler/testdata/arxiv_feed.xml` (body file +
  `{"query": "search_query=cat%3Acs.LG&sortBy=submittedDate&…"}` meta): the file as committed (ascending, `2023-07-17T17:50:36Z` then
  `2024-01-22T09:00:00Z`) prints `RISK1 ORDER NOT descending (first violation: entry 1 …)`; a copy with the two `<entry>` blocks swapped
  prints `RISK1 ORDER descending`; a store with only a non-`sortBy` meta (`id_list=…`) prints `RISK1 none` and exits 0; a body that isn't
  XML prints a `::warning::` and exits 0. Paste the four outputs and exit codes in the PR (extract the step's script to a scratch file to run it).
- [x] AC3 — The job's result isn't changed by the probe: the step exits 0 in the PR run, every other `stack.yml` step's outcome matches a
  same-base control `stack.yml` run of another PR branch (list both runs' step conclusions; a cache-hit control may differ only in
  `Save arXiv replay store` = skipped), and `actionlint` (the existing `Lint the harness` step) passes.
  *Amended 2026-11-17 (pm-lead, QA r1 finding 4 / r2 finding 4 [spec]): the original text compared against "the latest `main` run of
  `stack.yml`", but `stack.yml` triggers only on `pull_request` and `workflow_dispatch`, so it has 0 runs on `main`. QA compared against
  ING-6a1 run 44143443574 (same cache-miss path) and ING-6a2 run 44144065272 (cache hit).*
- [x] AC4 — `git diff --stat origin/main` lists only `.github/workflows/stack.yml`, < 40 changed lines; `ownership-check.sh` OK for backend.
- [x] AC5 — The PR body quotes the verdict line and the `published` values, and says in one line what it means for ING-6b:
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
- ~~The sample is the 2 entries the cache recorded once (fixed until the cache key changes).~~ *Corrected 2026-11-17 (pm-lead, QA r1 finding 5
  [spec]):* the replay cache is **branch-scoped** and `stack.yml` never runs on `main`, so each new PR branch's first `stack.yml` run misses the
  cache and records the 2 newest `cat:cs.LG` entries live from arXiv (~5 requests, ≥ 3 s apart, identifying User-Agent). ING-6f's sample is
  therefore a fresh live response recorded on this branch (its `Save arXiv replay store` step ran, i.e. cache miss; QA evidence 05/09), which is
  both "the recorded CI feed" and "one live sample" in design Risk 1's sense. A bigger sample would need new arXiv requests and isn't worth it,
  because rule (a) already tolerates a few out-of-order entries and ING-6c prints `out_of_order` every pass.
- 2026-11-17 (backend-engineer): built on `agent/backend/ING-6f`, head `61e44e1`; `.github/workflows/stack.yml` only, +35/-0
  (ownership-check: OK, 35 lines). Step `ING-6 Risk 1: published order of recorded search feeds` sits between `Save arXiv replay store`
  and `Start the arXiv replay proxy (replay-only)`, `if: ${{ !cancelled() }}` (prints even after an incomplete prefetch), `timeout-minutes: 1`,
  stdlib Python behind `|| echo "::warning::…"` so the step always exits 0; header comment line added. Local checks: `yaml.safe_load` OK;
  the step's script was extracted from the parsed YAML and run on scratch stores built from `arxiv_feed.xml`: as committed → `RISK1 ORDER NOT
  descending (first violation: entry 1 2023-07-17T17:50:36Z < entry 2 2024-01-22T09:00:00Z)`; entries swapped → `RISK1 ORDER descending`;
  `id_list` meta only → `RISK1 none` + `::warning::`; non-XML body → `::warning::… ParseError`; also a missing body and no store dir; all exit 0.
  The full `run:` block under `bash -e` also exits 0. Not run locally: actionlint (no binary; Docker image run not permitted in the sandbox),
  so CI's `Lint the harness` step covers it. AC1/AC3/AC5 need the PR's `Full stack` run.
- **Risk 1 verdict (recorded for ING-6b), 2026-11-17:** `RISK1 ORDER descending`. Published values in file order:
  entry 1 `2611.21608v1` published=`2026-11-16T18:59:38Z`, entry 2 `2611.21602v1` published=`2026-11-16T18:58:55Z`, for query
  `max_results=2&search_query=cat%3Acs.LG&sortBy=submittedDate&sortOrder=descending&start=0`. Source: PR #58 Full stack job `134275963367`
  (run `44150168163`, head `61e44e1`), step 13, REST job log (`gh api …/actions/jobs/134275963367/logs | grep RISK1`), verified by QA r1.
  Meaning: Risk 1 cleared for this sample (2 entries; ongoing detection via ING-6c's `out_of_order`). The sample was recorded live on this
  branch's first run (the replay cache is branch-scoped; see QA r1 finding 5 [spec]), so the Notes line above about a fixed cached sample is pm-lead's to correct.
- 2026-11-17 (backend-engineer) rework r1: QA r1 FAILed on the PR body only (finding 1). Fixed by a PR-description edit, no commit; head stays
  `61e44e1`, PR stays draft. The body now has: the 4 `RISK1` lines copied from job 134275963367's log, with job/run ids; the four AC2 outputs
  with exit codes, re-run now from the script re-extracted from `stack.yml` at `61e44e1` (byte-identical to round 1's), with output unchanged
  from round 1; the AC5 line; AC1/AC3/AC5 ticked; AC3 reworded to compare against ING-6a1 run 44143443574 / ING-6a2 run 44144065272 (step
  conclusions re-checked via the jobs API: identical apart from new step 13; 44144065272 also skipped `Save arXiv replay store` on its cache hit).
  Nit 2 (`continue-on-error: true`) and nit 3 are listed under "Not verified / risks" as follow-ups. Code was left alone this round to keep the reviewed head.
  Harness quirk: the PR-body PATCH strips the `🤖 Generated with [Claude Code](…)` line and appends `_Generated by [Claude Code](https://claude.ai/code)_`
  (seen on 2 attempts). The session link line survives. That rewrite happens outside the request body we send.
- 2026-11-17 (pm-lead) final review: **APPROVE** at `61e44e1` (QA r1 FAIL on PR body only → r2 PASS, same head; 6/6 CI green). Verdict in
  `agents/reviews/ING-6f/report.md` "PM final review". [spec] fixes above (AC3 wording, cache-scope Note). QA nit 2 (`timeout-minutes: 1` without
  `continue-on-error: true`) folded into **OPS-H12** (same file, starts after #58 merges). Nit 3 (lexical `published` compare): accepted, no
  follow-up (arXiv always emits fixed-width `YYYY-MM-DDTHH:MM:SSZ`; the probe is informational and ING-6c's Go `out_of_order` uses parsed times).
  Main-scoped replay cache seed: Backlog candidate **OPS-H13** (PROGRESS 2026-11-17 pm-lead ING-6f entry), not specced now: §9's rate rule is
  met on every recording run. **Risk 1 verdict `descending` satisfies ING-6b's ING-6f precondition**; ING-6b still waits on #56 + #57 merged.
- 2026-11-20 13:00Z (pm-lead, sync): merged (#58 `8b55af2`); Status → Done.
