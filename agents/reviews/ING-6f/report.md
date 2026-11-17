<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-17T18:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/58#issuecomment-6957791732 (the QA harness could not write report.md). -->

[qa-reviewer] QA report — ING-6f · PR #58 · round 1

**Verdict:** FAIL (one PR-body item; the code, CI and the Risk 1 answer are verified)
**Reviewed commit:** `61e44e191d5ec05c8cf38026fb38c9b11c5dc291` (base main `40dec5a`; CI merge `efdb1cb`) · **Date:** 2026-11-17
**Ticket:** [agents/tasks/ING-6f.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/tasks/ING-6f.md) · **PRD:** Product ING-6; Technical PRD §11, §9 · **Design:** `docs/design/ING-6.md` Risk 1, PM condition 3
**Evidence:** [agents/reviews/ING-6f/evidence @ 27b6692](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence)
_The QA harness refused to write `agents/reviews/ING-6f/report.md`; this comment is the report, to be saved verbatim by the orchestrator._

## Risk 1 answer (PR's own CI run, REST job log)
Full stack job `134275963367` (run `44150168163`), step 13 `ING-6 Risk 1: published order of recorded search feeds` => success:
```
RISK1 query=max_results=2&search_query=cat%3Acs.LG&sortBy=submittedDate&sortOrder=descending&start=0
RISK1 entry 1 2611.21608v1 published=2026-11-16T18:59:38Z
RISK1 entry 2 2611.21602v1 published=2026-11-16T18:58:55Z
RISK1 ORDER descending
```
[01](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/01-ac1-risk1-job-log.png?raw=true) ``

Per AC5: Risk 1 cleared for this sample (2 entries; ongoing detection via ING-6c's `out_of_order`). See finding 5: this run recorded the sample live because the cache missed. It is not the feed from design run 44092000441.

## Test results
| Check | Source | Result |
|---|---|---|
| Go / Python M0 / Frontend / DB / Agent ownership | CI | all success ([00](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/00-ci-checks.png?raw=true)) ```` |
| Full stack (compose + make test-full) | CI 134275963367 | success, every step ([05](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/05-ac3-step-conclusions.png?raw=true)) ````` |
| actionlint (`Lint the harness`) | CI step 5 | success, 0 `stack.yml:L:C:` error lines ([06](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/06-ac3-actionlint.png?raw=true)) `````` |
| diffstat + ownership-check | local, PR-head worktree | 1 file +35/-0; `Ownership OK for role=backend (35 changed lines)` ([07](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/07-ac4-diffstat-ownership.png?raw=true)) ``````` |
| AC2 scratch stores | local | 4 AC stores + 8 QA edge stores, all exit 0 ([02](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/02-ac2-local-stores.png?raw=true), ```````` [02b](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/02b-ac2-qa-edge-stores.png?raw=true)) ````````` |
| `make test-unit` / `make lint` | not run locally: workflow-only diff, no Go 1.25 in sandbox; CI above | — |
| `make eval` | not run: no retrieval/answering change | n/a |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ⚠ CI part ✅ · PR-body part ❌ | [01](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/01-ac1-risk1-job-log.png?raw=true): `````````` exact step name, success; counts query=1 entry=2 order=1 none=0; job head_sha 61e44e1 merged into 40dec5a. Lines not "pasted in the PR body" ([08](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/08-ac5-pr-body.png?raw=true)). ``````````` |
| AC2 | ✅ (QA's runs); PR body has a summary, not "the four outputs and exit codes" | [02](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/02-ac2-local-stores.png?raw=true): ```````````` script extracted from the *parsed* stack.yml. As committed → `NOT descending (first violation: entry 1 2023-07-17T17:50:36Z < entry 2 2024-01-22T09:00:00Z)`; swapped → `descending`; id_list only → `RISK1 none` + `::warning::`; non-XML → `::warning::… ParseError`. All exit 0, both as `python3 -I` and as the full `run:` block under `bash -eo pipefail`. [02b](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/02b-ac2-qa-edge-stores.png?raw=true): ````````````` missing body, bad meta, meta not dict, tie, 1 entry, undated entry, 2 feeds one broken, no dir: all as specified, exit 0. [03](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/03-ac2-failsafe-readonly.png?raw=true): `````````````` python3 exit 1 / SIGKILL → step exit 0 with `::warning::`; store sha256 unchanged; runs in an empty netns. [04](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/04-ac2-verdict-mutants.png?raw=true): ``````````````` 6/8 verdict-logic mutants killed. The 2 survivors need ≥2 violations or padded `published`, which can't occur in a 2-entry feed. |
| AC3 | ✅ (see [spec] 4) | [05](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/05-ac3-step-conclusions.png?raw=true): ```````````````` 0 stack.yml runs on main exist. Against same-base controls: ING-6a1 run 44143443574 (same cache-miss path) matches step for step apart from the new step. ING-6a2 run 44144065272 differs only in `Save arXiv replay store`, which was skipped on its cache hit. actionlint success ([06](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/06-ac3-actionlint.png?raw=true)). ````````````````` |
| AC4 | ✅ | [07](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/07-ac4-diffstat-ownership.png?raw=true): `````````````````` 1 file, 35 lines; ownership exit 0. Step sits between `Save arXiv replay store` and `Start the arXiv replay proxy (replay-only)`; header line present. |
| AC5 | ❌ | [08](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/08-ac5-pr-body.png?raw=true): ``````````````````` body last updated 18:39:09Z, before CI finished. AC5 is unticked ("quoted here once CI runs"). `published=`, `2611.`, `ING-6b`, `Risk 1 cleared`, `out_of_order` all have 0 matches. |

Scope: 1 file, inside backend ownership, nothing from "Out of scope". `if: !cancelled()` and `timeout-minutes: 1` go beyond the spec but don't conflict with it.

## PRD fit
Serves ING-6 (design Risk 1, PM condition 3). The PR's CI run shows descending `published` order for the recorded `cat:cs.LG` first page. The probe reads the replay store only and makes no arXiv request itself (§9). It's a probe, not a gate, as specced.

## Findings
1. [blocking] **The PR body is missing the AC1/AC2/AC5 content.** AC5 is entirely about the PR body and is unmet; AC1 and AC2 also require pastes there. Fix (PR-description edit only, no commit):
   (a) paste the 4 `RISK1` lines above with job 134275963367 / run 44150168163;
   (b) paste the four AC2 outputs with their exit codes;
   (c) add the AC5 line "Risk 1 cleared for this sample (2 entries; ongoing detection via ING-6c's `out_of_order`)";
   (d) tick AC1/AC3/AC5 and reword AC3's "vs latest `main` run".
   If the head stays 61e44e1, round 2 only re-checks the body.
2. [nit] `timeout-minutes: 1` is the one remaining path where the probe can fail the job: a timeout is a step failure, and `|| echo` can't catch the runner killing the step. In practice it's unreachable (the step ran in ~33 ms). `continue-on-error: true` would make "never fails the job" structural.
3. [nit] Order is a lexical comparison of the `published` text. That is correct for arXiv's fixed `YYYY-MM-DDTHH:MM:SSZ` form; mixed offsets would mis-order.
4. [spec] AC3 names "the latest `main` run of `stack.yml`", but `stack.yml` triggers only on `pull_request`/`workflow_dispatch`, so it has 0 runs on main. QA compared against same-base PR runs instead.
5. [spec] Ticket Notes call the sample "the 2 entries the cache recorded once (fixed until the cache key changes)". It isn't. Actions caches are branch-scoped and `stack.yml` never runs on main, so each new PR branch's first run misses the replay cache and re-records from live arXiv. Here that was 5 upstream fetches, identical to ING-6a1's first run 44143443574 ([09](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/09-cache-scope-fresh-recording.png?raw=true)). ```````````````````` This is pre-existing, not caused by this PR. It means:
   (a) this answer is a fresh sample of the 2 newest cs.LG papers at 2026-11-17T18:41Z, published 43 s apart;
   (b) "0 arXiv requests per run once recorded" holds only per branch.
   For §9, pm-lead may want an OPS follow-up, e.g. seeding a main-scoped cache via `workflow_dispatch` on main.

## Missing tests
- None required for an informational probe. Un-probed, and irrelevant for 2 entries: ≥2 violations (which one is reported) and whitespace-padded `published`.

QA harness source (for round 2's control run): [10](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/10-harness-source.png?raw=true) ````````````````````` / [.txt](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/27b6692a26661adc4ad484c1ecbe201b2985cdab/agents/reviews/ING-6f/evidence/10-harness-source.txt ``````````````````````).

## Hand-off
FAIL → back to backend-engineer for finding 1 (PR description only). The Risk 1 answer is verified from the job log: `RISK1 ORDER descending`. ING-6b needs that verdict recorded, not this PR merged, so pm-lead can record it now (run 44150168163, job 134275963367).


---
_Generated by [Claude Code](https://claude.ai/code)_

## Round 2

**Verdict:** PASS
**Reviewed commit:** `61e44e191d5ec05c8cf38026fb38c9b11c5dc291` (unchanged since round 1; rework was a PR-description edit only, body `updated_at` 2026-11-17T18:57:52Z) · **Date:** 2026-11-17
**Evidence:** [agents/reviews/ING-6f/evidence @ e352052](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/e35205265340a624e0e201335c314f8230ba3387/agents/reviews/ING-6f/evidence) (files `r2-*`)

### Head and CI
- `pulls/58` `.head.sha` = `61e44e1…` (draft). All 6 check runs for that commit are `completed success`, including Full stack job 134275963367. ([r2-00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e35205265340a624e0e201335c314f8230ba3387/agents/reviews/ING-6f/evidence/r2-00-ci-checks.png?raw=true))
- Because the code and CI are unchanged, the round-1 results for AC2 (QA stores, fail-safe, mutants), AC3 (step conclusions, actionlint) and AC4 (diffstat, ownership) still apply to this head.

### Finding 1 re-check (PR body)
| Item | Result | Evidence |
|---|---|---|
| (a) 4 `RISK1` lines + job/run ids | ✅ The body's block equals the REST job-log output lines of job 134275963367, byte for byte *including* the log timestamp prefix (sha256 `89f05b6e0a353fa6` for both; `cmp` identical). The job's `head_sha` is 61e44e1, and step 13 has the exact name and `success`. The body names job `134275963367`, run `44150168163`. | [r2-01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e35205265340a624e0e201335c314f8230ba3387/agents/reviews/ING-6f/evidence/r2-01-ac1-body-vs-joblog.png?raw=true) |
| (b) four AC2 outputs + exit codes | ✅ I re-extracted the step script from `stack.yml` at 61e44e1. It is byte-identical to round 1's (`aa2626d884235fbf`). Re-running it on QA's round-1 stores asc/desc/id_list/non-XML gives output that matches the body's "AC2 local runs" block, byte for byte: 16 lines, 4 × `exit=0`. Two things were excluded from the comparison: the `$ …` command lines (they name the developer's own paths) and the key name (the store key was renamed `k1` → the body's `0123456789abcdef…` so the `::warning::` path is comparable; file contents unchanged). | [r2-02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e35205265340a624e0e201335c314f8230ba3387/agents/reviews/ING-6f/evidence/r2-02-ac2-body-vs-rerun.png?raw=true) |
| (c) AC5 Risk 1 line | ✅ The exact line "Risk 1 cleared for this sample (2 entries; ongoing detection via ING-6c's `out_of_order`)" appears twice (under "For ING-6b" and in AC5). The verdict line and both `published` values are quoted. | [r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e35205265340a624e0e201335c314f8230ba3387/agents/reviews/ING-6f/evidence/r2-03-ac5-body-checks.png?raw=true) |
| (d) AC ticks + AC3 wording | ✅ AC1–AC5 are all `[x]`, with 0 unticked. "latest `main`" has 0 matches. AC3 now compares against ING-6a1 run 44143443574 and ING-6a2 run 44144065272, notes that stack.yml never runs on main and that 44144065272 skipped `Save arXiv replay store`, and gives `Lint the harness (actionlint, compose config)` success. All of that matches QA r1 evidence 05/06. | [r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e35205265340a624e0e201335c314f8230ba3387/agents/reviews/ING-6f/evidence/r2-03-ac5-body-checks.png?raw=true) |

The body also lists r1 nits 2 and 3, and the branch-scoped fresh sample (r1 [spec] 5), under "Not verified / risks". The footer reads `_Generated by [Claude Code](https://claude.ai/code)_` in place of the template's line. That is the known outbound-filter rewrite (lesson OPS-H8), so it is not a finding.

### Acceptance criteria (round 2)
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | r1 01 + [r2-01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e35205265340a624e0e201335c314f8230ba3387/agents/reviews/ING-6f/evidence/r2-01-ac1-body-vs-joblog.png?raw=true): pasted in the PR body, identical to the job log |
| AC2 | ✅ | r1 02/02b/03/04 + [r2-02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e35205265340a624e0e201335c314f8230ba3387/agents/reviews/ING-6f/evidence/r2-02-ac2-body-vs-rerun.png?raw=true): the body's four outputs and exit codes reproduce exactly |
| AC3 | ✅ | r1 05/06; body wording fixed ([r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e35205265340a624e0e201335c314f8230ba3387/agents/reviews/ING-6f/evidence/r2-03-ac5-body-checks.png?raw=true)); ticket text still says "main" ([spec] 4, pm-lead) |
| AC4 | ✅ | r1 07 (head unchanged) |
| AC5 | ✅ | [r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e35205265340a624e0e201335c314f8230ba3387/agents/reviews/ING-6f/evidence/r2-03-ac5-body-checks.png?raw=true) |

### Findings (round 2)
1. Round-1 finding 1 [blocking] is **resolved**. (a)–(d) were each verified against real output.
2. [nit] (carried from r1 nit 2) `timeout-minutes: 1` without `continue-on-error: true`. The PR lists it as a follow-up. Non-blocking.
3. [nit] (carried from r1 nit 3) Lexical `published` comparison. Listed in the PR body. Non-blocking.
4. [spec] (carried) The ticket's AC3 still names "the latest `main` run of `stack.yml`". The second Notes bullet still says the sample is "fixed until the cache key changes" (r1 [spec] 5). Both are pm-lead's to correct; neither blocks.

QA harness for this round: [r2-04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/e35205265340a624e0e201335c314f8230ba3387/agents/reviews/ING-6f/evidence/r2-04-harness-source.png?raw=true) (sources), reusing round-1 stores and `extract.py` (r1 evidence 10).
`make test-unit` / `make lint`: not run locally (workflow-only diff, no Go 1.25 in sandbox); CI green (r2-00). `make eval`: n/a.

### Hand-off
PASS → pm-lead final review. Risk 1 verdict `RISK1 ORDER descending` (job 134275963367) stands as recorded in the ticket Notes.
