<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/65#issuecomment-7022357724 (QA harness could not write report.md), 2026-11-19T21:13:03Z -->

[qa-reviewer] **FAIL** — AI-8b round 1. Evidence pack: https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence (commit `1f500dc`). The QA harness refused to write `report.md`, so the full report is below. The orchestrator saves it verbatim to `agents/reviews/AI-8b/report.md`.

# QA report — AI-8b · PR #65 · round 1

**Verdict:** FAIL
**Reviewed commit:** `9b2778fa7466f49ec0eb278b2eb065dacf054461` · **Date:** 2026-11-19
**Ticket:** [agents/tasks/AI-8b.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/tasks/AI-8b.md) · **PRD:** Product PRD QA-3, QA-4, §7 principles 1–3; Technical PRD §7.2; ADR-0014 (Accepted); ADR-0018 (Proposed) · **Design:** [docs/design/AI-8.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/docs/design/AI-8.md) (approved with conditions)

One-line reason: the code does what the ticket and design ask, CI is green and the eval is unchanged. But one branch of the documented `claimStatus` rule ("else `unverified` if any citation is unverified") can be deleted with every test still green. When that branch goes, a claim whose citation was never checked is reported as `unsupported` ("checked and failed"). (Finding 1, [blocking], a small test-only fix.)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 135774827091 on merge `57009fa` (= `9b2778f` into `085183e`) | pass: `go vet`, gofmt, `ok arxivlens/internal/query` ([00](`` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/00-ci-checks.png?raw=true), `` [01](``` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/01-ci-go-python-jobs.png?raw=true)) ``` |
| Python M0 unit tests (`make test-py`, includes `tests/test_evals_data.py`) | CI job 135774827184 | pass: `185 passed, 3 skipped` ([01](```` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/01-ci-go-python-jobs.png?raw=true)) ```` |
| Frontend (lint, test, build) | CI | pass (no frontend change) |
| DB / Full stack / Agent ownership | CI | pass / pass / pass ([00](````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/00-ci-checks.png?raw=true)) ````` |
| eval (workflow_dispatch 44584838337, branch head `9b2778f`) | CI | `GATE: PASS`, all four AC9 values identical to both baselines ([06](`````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/06-ac9-eval-runs.png?raw=true)) `````` |
| Ticket `go test -race -run 'Ask\|Synth\|Citation\|Claim\|QuickAnswer\|WithLLMNil' -v` | local go1.24 harness: PR-head `internal/` copied verbatim (`diff -r` = identical) + pgx/minio stubs | 29/29 PASS ([03](``````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/03-targeted-tests.png?raw=true)) ``````` |
| `go tool cover` rag.go | local harness | rag.go 416/420 = **99.0%**; touched funcs 100% except `checkCitations` 98.2% ([04](```````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/04-ac8-coverage.png?raw=true)) ```````` |
| `python3 -m pytest -q tests/test_evals_data.py` | local | 122 passed, 1 skipped; new test PASSED ([09](````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/09-ac6-pytest.png?raw=true)) ````````` |
| `make test-unit` / `make lint` | not run locally: go.mod needs Go 1.25 (sandbox has 1.24.7, toolchain download blocked), and no npm for lint-fe | CI is the source of truth (green) |
| Mutation check: 23 single-edit `rag.go` mutants × 3 test scopes | local harness | 19 killed, 4 survived: M3 = **finding 1**; M14 and M23 equivalent (shown below); M0 = control ([07](`````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/07-mutations.png?raw=true)) `````````` |

`main` has moved from `085183e` (CI merge base) to `4c7d327` since CI ran. The only new commit is #67, frontend-only, and it merges cleanly (`git merge-tree`), so the CI result still holds.

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 extended helper at every site, claims invariants, refusals keyless | ✅ (see finding 1 on its oracle) | `checkCitationInvariants` extended in place, same signature (rag_test.go:104–129). Call-site table: every `AskResponse`-producing test calls it, including the 11 unchanged `synthesis_test.go` sites (`git diff --stat` empty for that file) ([02](``````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/02-scope-size-readme.png?raw=true), ``````````` [05](```````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/05-ac1-call-sites.png?raw=true)). ```````````` The two hand-set `answer_kind` `finalize` sites now pass `Claims: resp.Claims`, so the check isn't skipped there (amendment). Helper reach into synthesis_test.go is proven by mutants: M9/M10/M11/M12/M13/M16/M19 are killed by the **synthesis-only** scope ([07](````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/07-mutations.png?raw=true)). ````````````` AC1 command `-run 'Synth\|QuickAnswer\|WithLLMNil' -v` passes ([03](`````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/03-targeted-tests.png?raw=true)). `````````````` The PR body itself doesn't show it (finding 2) |
| AC2 `TestAskClaims` (extractive / LLM with dropped claim / quick / uncited fragment) | ✅ | `TestAskClaims`: literal claims for extractive (`[i]`, `quoted`, no `prompt_version` key), LLM (`[{"Results confirm the gain.", supported, [2,3]}]`, `synthesis-v1`, dropped claim absent), quick (no key), direct `checkCitations` with `An uncited fragment.` → `{"markers":[],"status":"unverified"}` (exact JSON asserted), and `[2][9][2]` → markers `[2,2]` (occurrence order, not deduped, out-of-range ignored). Mutants M4, M5, M6, M7, M12, M13 are killed ([07](``````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/07-mutations.png?raw=true)) ``````````````` |
| AC3 every refusal path: no `claims`/`prompt_version`; early refusal `citations == []`, no `refusal_reason` | ✅ | `TestAskClaims` refusal map covers `all_citations_unsupported`, `verification_unavailable`, no in-range marker, `insufficient_evidence`, early. M15, M16, M17 (`claims: []` on early refusal) and M18 are killed ([07](```````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/07-mutations.png?raw=true)) ```````````````` |
| AC4 `e.g.` + `0.5` sentence → one claim | ✅ | `TestAskClaims` AC4 block passes, so the splitter handles both. No pin or follow-up needed ([03](````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/03-targeted-tests.png?raw=true)) ````````````````` |
| AC5 shape test: `claims`, `prompt_version` only when set, old keys keep name and type | ✅ | `TestAskResponseShapeAndConstructor` adds a full-response type map (8 keys incl. `claims` `[]interface {}`, `prompt_version` string). The pre-existing refusal key list (exactly 4 keys) still asserts absence. M17 is killed |
| AC6 Python eval compatibility | ✅ | `test_claims_and_citation_fields_leave_eval_results_unchanged`: `classify` and `case_record` equal with and without claims or new citation fields, for an extractive answer (with an uncited claim) and a refusal; `coverage_units == (2, 3)` both ways. Passes locally and in CI ([09](`````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/09-ac6-pytest.png?raw=true), `````````````````` [01](``````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/01-ci-go-python-jobs.png?raw=true)) ``````````````````` |
| AC7 README `/v1/ask` row | ✅ | Only hunk is `@@ -163 +163 @@`, the `/v1/ask` row ([02](```````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/02-scope-size-readme.png?raw=true)). ```````````````````` All 15 required items present, including the `unverified` definition verbatim, "ADR-0018, Proposed", the versioned `pdf_url`, the claim-status rule and the ordering invariant ([11](````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/11-ac7-readme-row.png?raw=true)) ````````````````````` |
| AC8 rag.go coverage ≥ 90%; diff < 400 | ✅ | rag.go 99.0% ([04](`````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/04-ac8-coverage.png?raw=true)); `````````````````````` 182+16 = 198 changed lines, ownership OK for role=ai ([02](``````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/02-scope-size-readme.png?raw=true)). ``````````````````````` Rows not pasted in the PR body (finding 2) |
| AC9 eval run vs 43902662193 and the AI-8a run | ✅ | 44584838337 (`workflow_dispatch`, `agent/ai/AI-8b`, checked out `9b2778f`) vs 43902662193 (`40dec5a`) vs 44559854028 (first nightly after AI-8a, `8b55af2`): supported_citation_rate 1.0000 (60), correct_refusal_rate 1.0000 (22), citation_coverage 1.0000, recall@5 0.9850, GATE: PASS in all three. Coverage is unchanged even though `coverage_units` now reads `claims` (design condition 6: no coverage finding) ([06](```````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/06-ac9-eval-runs.png?raw=true)) ```````````````````````` |
| Docs: PR body notes `answer_source` not added (ADR-0018 Option 1) | ✅ | PR body: "`answer_source` is not added (ADR-0018 Option 1); it would be an additive follow-up under Option 2." |

## Design check (docs/design/AI-8.md §4, conditions 1–8)
The code follows §4. LLM claims are the kept claims with `markers = claim.Citations` and `text = claim.Text`. Extractive claims are one per `splitIntoSentences` sentence, uncited ones included, with markers in occurrence order. `claimStatus` matches the rule, `claims` is nil on all refusals, and `prompt_version` is set only in `finalizeClaims`. Condition 3 (refusal = `answer_kind == ""`) is in the helper. Condition 7 is tested and passes. Condition 8 holds: no `answer_source`, no new statuses or offsets, no prompt or splitter change. The design's mutation list items (6) "claims only for cited sentences" and (7) "`prompt_version` on quoted answers" are M4 and M9, both killed. The developer's choice of extractive `text = normQuote(sentence)` isn't fixed by the design. It's consistent with the AI-8a quote and is noted in the ticket. No unexplained deviation.

## PRD fit
The change serves QA-3/QA-4 and principle 1 (evidence first): every non-refused answer now lists its statements with the markers of their evidence, and positional mapping gives FE-4 one-click claim → citation. It also follows principle 2 (honest refusals): refusals carry no claims. The eval (quoted path, no LLM in `eval.yml`) is unchanged. The synthesized-path claims and `prompt_version` are covered by unit tests only.

## Findings
1. **[blocking] The `claimStatus` "unverified" branch is untested, and the helper can't catch it.** Mutant M3 (`unverified = unverified || c.Status == StatusUnverified` → `unverified = unverified || false`) **survives the whole package** ([07](````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/07-mutations.png?raw=true); ````````````````````````` `ok arxivlens/internal/query` on M3 in [08](`````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/08-probe-claimstatus-unverified.png?raw=true)). `````````````````````````` It changes behaviour on a real path: a quoted answer whose second sentence is a paraphrase while the verifier is down. That is the scenario of `TestAskRefusesVerificationUnavailable`'s second half. On head that claim is `unverified[2]`; on M3 it becomes **`unsupported[2]`**, while its citation is still `unverified` (probe P1). The same happens for a claim citing `[unsupported, unverified]` (P2). So `claims[].status` would tell the reader "checked and failed" about a statement nobody checked. That contradicts the README text this PR adds (`unverified` = "not checked: the verifier was unavailable…") and ADR-0014's honest-status rule. Root cause: `checkCitationInvariants` compares `cl.Status` against the **production** `claimStatus`, so any change to `claimStatus` passes the helper. Only `TestAskClaims`' literal statuses (S, V-with-no-citation, U) pin the rule, and none of them is a claim with an unverified citation. M1 and M2 are likewise killed only by `TestAskClaims`, never by the helper.
   **Fix (test-only, about 5–15 lines in `rag_test.go`):** add a literal assertion for a claim with an unverified citation, e.g. in `TestAskClaims` `finalize` the quote + paraphrase answer with `&fakeVerifier{err: …}` and assert claims `[{…, supported, [1]}, {…, unverified, [2]}]`, plus one claim citing `[unsupported, unverified]` → `unverified`. Alternatively, a small literal table for `claimStatus` (`[]`→V, `[U]`→U, `[V]`→V, `[U,V]`→V, `[V,U]`→V, `[U,S]`→S). Then M3 must fail.
2. **[nit] The PR body doesn't yet show AC1's `-v` run or AC8's coverage rows.** The verification table says "not run locally", and CI's `go test ./...` isn't `-v` and doesn't print rag.go coverage. QA evidence [03](``````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/03-targeted-tests.png?raw=true) ``````````````````````````` and [04](```````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/04-ac8-coverage.png?raw=true) ```````````````````````````` provide both. pm-lead can paste them when raising the PR.
3. **[nit] Unreachable edge, no action needed.** A marker-only fragment (e.g. a trailing `[2]`) would become a claim with `text: ""` (probe P4, [08](````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/08-probe-claimstatus-unverified.png?raw=true)). ````````````````````````````` The helper would flag that as an AC1 violation. The extractive builder never writes such a sentence, so this is recorded for the future and is not a defect.

Equivalent survivors (not findings): **M14** (LLM claim status hardcoded `supported`) is equivalent because `keep[i]` is true only when one of the claim's citations is `Supported`, so `claimStatus` always returns `supported` for a kept claim (rag.go:331). This matches the developer's Notes. **M23** (no-marker branch returns claims) is equivalent because `finalize` then refuses through `refusal()`, which never copies claims, and `validateCitations` drops them.

## Missing tests
- A claim with an unverified citation, asserted by literal value (finding 1).
- (Optional) A literal `claimStatus` table, so the helper's status check isn't the only guard of the rule.

## Hand-off
FAIL → back to ai-engineer (finding 1; findings 2–3 are nits). Re-review checks that M3 is killed and re-runs the 23-mutant set ([10](`````````````````````````````` https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/1f500dcbdf7c3eef123c36a7b7b9bb7e9b14560a/agents/reviews/AI-8b/evidence/10-harness-sources.png?raw=true) `````````````````````````````` has the full harness, stubs, mutation script and probe source).


---
_Generated by [Claude Code](https://claude.ai/code)_

---

# QA report — AI-8b · PR #65 · round 2

**Verdict:** PASS
**Reviewed commit:** `956db7824ec2f706565e02426762a7a5220f2683` (r1 head `9b2778f`) · **Date:** 2026-11-19
**Evidence commit:** `c666ded` ([folder](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence))

One-line reason: finding 1 is fixed with a test-only change. Mutant M3 is now killed by `TestAskClaims`, the rest of the 23-mutant set gives the same result as round 1, CI is green on the new head merged into current `main`, and every AC still holds.

## Round-1 findings
| # | Result | Evidence |
|---|---|---|
| 1 [blocking] `claimStatus` "unverified" branch untested (M3 survived) | **Fixed.** `TestAskClaims` now asserts by literal value that a quote + paraphrase answer with the verifier down (`fakeVerifier{err}`, direct `checkCitations`) gives claims `[supported [1], unverified [2]]`. It also has a literal 8-row `claimStatus` table (`[]`→V, `[U]`→U, `[V]`→V, `[U,V]`→V, `[V,U]`→V, `[U,S]`→S, `[V,S]`→S, `[U,U]`→U). On M3 the test fails with `verifier down claims [... Status:unsupported Markers:[2]]` and `claimStatus([unverified]) = "unsupported", want "unverified"` (3 table rows). The unmutated head passes | [16](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/16-m3-killed.png?raw=true), [15](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/15-mutations-r2.png?raw=true) |
| 2 [nit] PR body lacked the AC1 `-v` run and the AC8 coverage rows | Done. The PR body now has the AC1 `-v` row, the AC8 rows (rag.go 416/420 = 99.0%), and a mutation row. My own run matches them | [14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/14-targeted-tests-coverage.png?raw=true) |
| 3 [nit] marker-only fragment → empty claim text | Unreachable, no action needed (unchanged) | — |

## Rework scope
`9b2778f..956db78` is one commit that changes only `internal/query/rag_test.go` (+19, 0 deletions). `rag.go`, `README.md` and `tests/` are unchanged since round 1, and `synthesis_test.go` is still not in the PR (11 `checkCitationInvariants` calls, unchanged). `gofmt -l` is clean. The whole PR is 4 files, +201/−16 (217 changed lines, under 400), all in ai-owned paths ([13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/13-rework-diff.png?raw=true)).

## Test results
| Check | Source | Result |
|---|---|---|
| All 6 check runs | CI on `956db78`; Go and Python jobs checked out merge `a14c897` = `956db78` into current main `4c7d327` | Go (vet, gofmt, test, build), Agent ownership, Python M0, Frontend, DB, Full stack: **all success**. `ok arxivlens/internal/query`; `185 passed, 3 skipped` ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/12-ci-checks-r2.png?raw=true)) |
| Ticket `go test -race -run 'Ask\|Synth\|Citation\|Claim\|QuickAnswer\|WithLLMNil' -v` + full package | local go1.24 harness (`internal/` == head, `diff -r` empty) + r1 pgx/minio stubs | all `--- PASS`, `ok`; full package `ok` ([14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/14-targeted-tests-coverage.png?raw=true)) |
| rag.go coverage (AC8) | same harness | 416/420 = **99.0%**; `claimStatus`, `finalizeClaims`, `finalize`, `refusal` 100%, `checkCitations` 98.2% ([14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/14-targeted-tests-coverage.png?raw=true)) |
| Mutation re-run: r1 `bin/mutate.py` (checked byte-identical to evidence 10), 23 mutants × 3 scopes | same harness | **21/23 killed, 0 invalid.** Survivors: M14 and M23 (both equivalent, see round 1), plus control M0. That kills every non-equivalent mutant. Every other mutant gives the same result as round 1 ([15](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/15-mutations-r2.png?raw=true)) |
| `make test-unit` / `make lint` | not run locally: go.mod needs Go 1.25 (sandbox has 1.24.7, toolchain download blocked), and there's no npm | CI green (above) |
| `make eval` (AC9) | not re-run: the rework is test-only and `rag.go` is byte-identical to `9b2778f`, so round 1's run 44584838337 (GATE: PASS, all four values identical to both baselines) still applies | [06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/06-ac9-eval-runs.png?raw=true) (r1) |

Correction to round 1: the r1 mutation table had 20 of 23 mutants killed (M3, M14 and M23 survived, plus control M0), not "19 killed, 4 survived". The r1 count included the control. The verdict and finding are unchanged ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/07-mutations.png?raw=true)).

## Acceptance criteria (re-checked on 956db78)
| AC | Met? | Evidence |
|---|---|---|
| AC1 helper at every site, claims invariants, refusals keyless | ✅ | Helper unchanged since r1. The AC1 command passes. Helper-reach mutants M8–M13, M16 and M19 are still killed by the synthesis-only scope ([14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/14-targeted-tests-coverage.png?raw=true), [15](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/15-mutations-r2.png?raw=true)) |
| AC2 `TestAskClaims` | ✅ | passes; M4–M7, M12 and M13 killed, and it now also pins the unverified claim status ([15](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/15-mutations-r2.png?raw=true), [16](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/16-m3-killed.png?raw=true)) |
| AC3 refusal paths | ✅ | M15–M18 killed ([15](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/15-mutations-r2.png?raw=true)) |
| AC4 `e.g.` / `0.5` | ✅ | `TestAskClaims` passes (unchanged block) |
| AC5 shape test | ✅ | `TestAskResponseShapeAndConstructor` unchanged and passing (CI and local full package) |
| AC6 Python eval compatibility | ✅ | `tests/` unchanged since r1; CI Python M0 `185 passed, 3 skipped` ([12](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/12-ci-checks-r2.png?raw=true)) |
| AC7 README `/v1/ask` row | ✅ | README unchanged since r1 ([13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/13-rework-diff.png?raw=true)); r1 [11](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/11-ac7-readme-row.png?raw=true) still applies |
| AC8 coverage ≥ 90%, diff < 400 | ✅ | 99.0%; 217 changed lines ([14](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/14-targeted-tests-coverage.png?raw=true), [13](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/13-rework-diff.png?raw=true)) |
| AC9 eval | ✅ | r1 run 44584838337 still applies (rag.go unchanged) |
| Docs: `answer_source` note | ✅ | still in the PR body |

## Findings (round 2)
1. **[nit]** The PR body's `make eval` row still says "branch run: dispatched on this PR (AC9)" and doesn't paste the numbers. pm-lead can paste them from run 44584838337 / evidence [06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/c666dedf80cad58b67a03bcf6fe7796056aef88e/agents/reviews/AI-8b/evidence/06-ac9-eval-runs.png?raw=true) when raising the PR.

No blocking findings. No contract, threshold or eval-gate change.

## Hand-off
PASS → pm-lead for final review. Label `qa-fail` → `qa-pass`.

---

# PM review — AI-8b · PR #65

**Verdict:** APPROVE
**Reviewed head:** `956db7824ec2f706565e02426762a7a5220f2683` (unchanged since QA r2) · **Reviewer:** pm-lead · **Date:** 2026-11-19
**Read:** ticket `agents/tasks/AI-8b.md` (incl. 2026-11-17 amendments), Product PRD QA-3/QA-4 and §7 principles 1–3, Technical PRD §7.2,
ADR-0014 (Accepted), ADR-0018 (Proposed), `docs/design/AI-8.md` (PM decision + conditions 1–8), QA r1 (FAIL) and r2 (PASS), the PR diff
(4 files, +201/−16), and all 17 evidence images 00–16 (00–11 at `1f500dc`, 12–16 at `c666ded`) plus their `.txt` sources.

## PRD fit
- **Principle 1 (evidence first) / QA-3:** every non-refused answer now carries `claims[]` in answer order, each with the markers of its
  evidence, and the ordering invariant (`citations[o:o+len(markers)]`) lets FE-4 map a claim to its passages without new fields.
  That is what Phase 1 item 4 ("each claim maps to inspectable passages") needs.
- **Principle 2 (say "I don't know") / ADR-0014 honest status:** refusals carry no `claims`/`prompt_version`; a claim whose evidence was
  never checked is `unverified`, not `unsupported`. QA r1 found that this rule was not pinned by any test (M3 survived). The rework pins it
  by literal value (verifier-down case + 8-row `claimStatus` table), and evidence 16 shows M3 now fails `TestAskClaims`. This was the
  right call to block on: a reader-facing "checked and failed" on an unchecked statement would have contradicted the README text this
  PR adds.
- **Principle 3 (one click to the source):** the README documents the versioned `pdf_url`, `page` and `quote` together with claims, so API
  users and FE-3/FE-4 have one contract to build against.
- `prompt_version` only on `synthesized` answers gives traceability for the LLM path without promising anything for quoted answers.

## Scope
- Matches the ticket and design §4 exactly: `rag.go` (+50/−10), `rag_test.go`, one Python test, one README row. `synthesis_test.go`
  untouched (11 helper calls, covered via the extended helper; mutants M8–M13/M16/M19 killed by the synthesis-only scope prove the reach).
- Design condition 8 held: no `answer_source`, no reserved statuses, no offsets/indices, no prompt or splitter change.
- 217 changed lines (< 400), ai-owned paths only, ownership check green.
- Extractive claim `text = normQuote(sentence)` is a developer choice not fixed by the design; it matches the AI-8a `quote` normalisation
  and is recorded in the ticket Notes. Accepted.

## Evidence vs ACs
| AC | Evidence that proves it | PM |
|---|---|---|
| AC1 helper at every site | 05 (call-site table + helper body), 03/14 (AC1 `-v` run), 07/15 (synthesis-only scope kills helper-reach mutants) | ✅ |
| AC2 `TestAskClaims` | 03/14 (pass), 07/15 (M4–M7, M12, M13 killed), 13 + 16 (r2 literal unverified case) | ✅ |
| AC3 refusal paths | 15 (M15–M18 killed), 05 (helper refusal check) | ✅ |
| AC4 `e.g.`/`0.5` | 03/14 (`TestAskClaims` passes, splitter not changed), 13 (AC4 block context) | ✅ |
| AC5 shape test | 03/14 (`TestAskResponseShapeAndConstructor` passes); M17 killed (15) | ✅ |
| AC6 Python eval compatibility | 09 (local, new test PASSED), 01/12 (CI Python M0 185 passed) | ✅ |
| AC7 README row | 02 (single hunk `@@ -163 +163 @@`), 11 (all 15 required terms present, each once) | ✅ |
| AC8 coverage / size | 04/14 (rag.go 416/420 = 99.0%), 02/13 (217 lines) | ✅ |
| AC9 eval | 06: run 44584838337 (`9b2778f`; `rag.go` byte-identical at `956db78` per 13) vs 43902662193 vs 44559854028 — supported_citation_rate 1.0000 (60), correct_refusal_rate 1.0000 (22), citation_coverage 1.0000, recall@5 0.9850, GATE: PASS in all three. No coverage change, so no condition-6 finding | ✅ |
| Docs: `answer_source` note | PR body | ✅ |

"Not run locally" for `make test-unit`/`make lint` is acceptable: CI on `956db78` (merged into `4c7d327`) is 6/6 green (evidence 12). The
synthesized-path claims are unit-tested only (no LLM in `eval.yml`); that's a known limit of the eval, not of this PR.
Red text on some `--- PASS` lines in 03/14 and the helper body in 05 is terminal highlighting of the words "Fail"/"Error", not failures.

## Docs / PRD status
- App README `/v1/ask` row: done in this PR.
- Product PRD QA-3/QA-4 and Technical PRD §7.2 are stale (QA-4 still describes cosine + fail-open pre-AI-2/ADR-0014). Per the ticket,
  pm-lead updates them in a `docs/` PR **after merge**; Backlog line added to `agents/board.md`.

## For Mahesh (flagged per design "Kept out", not blocking)
1. README timing differs from ADR-0014 ("README updated in the PRs that add the fields"): the AI-8a fields are documented here, in AI-8b (design condition 4).
2. Q1 reading of `unverified`: a claim with no in-range marker, and a citation that no statement cited, are `unverified` ("not checked").
3. The README row documents `quick`, `answer_kind`, `synthesis_available` and `insufficient_evidence` and marks them "ADR-0018, Proposed". `answer_source` is not added (Option 1); Option 2 would be additive.

## Hand-off
APPROVE → PR #65 description rewritten with the Evidence section, marked ready for review, label `ready-to-merge`. Merge: Mahesh.
