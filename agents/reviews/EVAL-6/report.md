<!-- Provenance: written by qa-reviewer (fresh context, 2026-11-07 cycle 05:21Z); its harness could not write files, so the orchestrator saved the report text verbatim from qa-reviewer's hand-back. Evidence files were rendered by qa-reviewer with agents/tools/render_evidence.py. -->

# QA report — EVAL-6 · PR #20 · round 1

**Verdict:** PASS
**Reviewed commit:** `4dc4846343f1e952c5dceac864c4b036c7186e20` · **Date:** 2026-11-07
**Ticket:** `agents/tasks/EVAL-6.md` · **PRD:** Product PRD §8 (supported-citation and correct-refusal rows), QA-4, QA-5; ADR-0003 (Accepted)

Evidence base: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/main/agents/reviews/EVAL-6/evidence

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 128314276972 | pass ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/00-ci-checks.png?raw=true)) |
| Python M0 unit tests (`make test-py`, includes `tests/test_evals_data.py`) | CI job 128314276941 | pass: `84 passed, 1 skipped` (log line quoted in [00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/00-ci-checks.png?raw=true)) |
| Frontend (lint, test, build) | CI job 128314276810 | pass |
| DB (migrate twice, HNSW plan + recall) | CI job 128314276768 | pass |
| Agent ownership check | CI job 128314276974 | pass: `Ownership OK for role=ai`, with a warning: `443 changed lines (> 400)` |
| `python3 -m pytest -q tests/test_evals_data.py` | local | 75 passed, 1 skipped ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/01-pytest-evals-data.png?raw=true), [09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/09-make-test-py-local.png?raw=true)) |
| Mutation check (14 mutants, one per AC branch) | local | 14/14 killed ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/02-mutation-check.png?raw=true)) |
| `eval_gate.py --skip-retrieval` end to end against a stub `/v1/ask` | local | metrics match a hand count; results JSON has no text keys or leaked text ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/03-e2e-stub-gate.png?raw=true)) |
| `make test-py` / `make lint` | not run locally: sandbox has no `torch`/`confluent_kafka` (collection errors in `test_m0.py`/`test_worker_heartbeat.py`), and the Go 1.25 toolchain download is blocked ([09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/09-make-test-py-local.png?raw=true)). CI is the source of truth: green. | — |
| `make eval` (answering) | not run: there is no Postgres/query/embedder stack in the sandbox. The "Full stack" workflow is path-filtered and did not run on this PR, and no eval workflow exists before EVAL-3. Command: `make eval`. | no before/after numbers |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 classification | ✅ | `classify()` in `scripts/evaluate_answers.py`. Tests: `test_a_refusal_is_correct_refusal_and_answer_refusal`, `test_b_verification_unavailable_is_error_never_refusal`, `test_unknown_refusal_reason_fails_closed_as_error` and `test_early_refusal_and_classify_branches` ([01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/01-pytest-evals-data.png?raw=true)). Four mutants are killed: B→refusal, unknown→refusal, early→answered, B not counted ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/02-mutation-check.png?raw=true)). End to end: a002 (B) and x002 (unknown reason) land in `error_case_ids`, with `verification_unavailable_count = 1` and `ask_errors` FAIL. The A-refusal counts as a correct refusal on the refusal set and in `answer_refusal_rate` on the answer set ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/03-e2e-stub-gate.png?raw=true)). |
| AC2 supported rate excludes refusal evidence | ✅ | `test_supported_rate_excludes_refusal_evidence` asserts 1.0 (not 0.4) and `citations_total == 2`. The mutant that counts refusal citations is killed ([02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/02-mutation-check.png?raw=true)). End to end: 40 citations = 20 answered × 2, and the A (3 unsupported) and B (1 unsupported) evidence is excluded, giving 1.0 ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/03-e2e-stub-gate.png?raw=true)). |
| AC3 citation_coverage | ✅ | `test_citation_coverage` covers all cited → 1.0, one of three uncited → 0.667, an out-of-range `[9]` → 0.667 and `claims[]` → 0.5. `test_citation_coverage_null_without_answered_responses` gives `None` for early/A/B/failed responses. Mutants killed: null→0, claims ignored, out-of-range counted. The splitter is a faithful port of `splitIntoSentences` (same end condition, abbreviation rule and space skip), and `test_split_sentences_mirrors_rag_go` drift-guards the abbreviation list ([07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/07-splitter-port.png?raw=true)). |
| AC4 near-miss file | ✅ | 15 rows. No `answered_by` is in `corpus.txt`, every `why_near` ID is in the corpus, the field set is exact, all `reviewed_by` are null, and no question duplicates the answer/refusal sets ([05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/05-near-miss-vs-corpus.png?raw=true)). `test_near_miss_rows_valid_and_not_in_corpus` fails if an `answered_by` is in the corpus or if `reviewed_by` or `answered_by` is missing (mutants killed, [02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/02-mutation-check.png?raw=true)). See the ID review below. |
| AC5 per-case records IDs/numbers only | ✅ | `test_case_records_hold_ids_and_numbers_only` asserts no `answer`/`content`/`text`/`question`/`title` key. Mutants that leak answer text or citation `content` are killed. End to end: the stub put `LEAKANSWER`/`LEAKPASSAGE`/`LEAKTITLE` in every response, and none of the three appears anywhere in the written results JSON ([03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/03-e2e-stub-gate.png?raw=true)). |
| AC6 gates unchanged | ✅ | `git diff origin/main -- evals/thresholds.json` is 0 lines. `check_thresholds(_results(), load_thresholds())` returns the same 8 metric names on main `71cb609` and on the head ([04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/04-gates-unchanged.png?raw=true)). Test: `test_check_thresholds_names_unchanged_and_ignore_report_only`. The report-only near-miss calls stay out of the gated latency/errors (mutant killed). |
| AC7 make test-py; make eval | ✅ (eval: not run) | CI `make test-py` gives `84 passed, 1 skipped` ([00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/00-ci-checks.png?raw=true)). The ticket's alternative applies to `make eval`: "not run: no stack in sandbox" ([09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/09-make-test-py-local.png?raw=true)). |
| AC8 README | ✅ | `evals/README.md` has the ADR-0003 classification table (6 rows), definitions of `supported_citation_rate` (new scope), `citation_coverage` (with splitter and abbreviation list), `refusal_reason_counts`, `verification_unavailable_count`, `near_miss_correct_refusal_rate` and the per-case record keys, plus a "Near-miss rows and human review" section ([06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/06-readme-defs.png?raw=true)). |

### Near-miss ID review (from reviewer knowledge; arxiv.org is unreachable from the sandbox, so this is not a web check)
I believe all 15 `answered_by` IDs match the named paper: DistilBERT 1910.01108, ALBERT 1909.11942, ELECTRA 2003.10555, QLoRA 2305.14314, Self-Consistency 2203.11171, Tree of Thoughts 2305.10601, FlashAttention-2 2307.08691, Constitutional AI 2212.08073, Contriever 2112.09118 (n009, flagged by the developer: matches "Unsupervised Dense Information Retrieval with Contrastive Learning"), REALM 2002.08909, Faiss-GPU "Billion-scale similarity search with GPUs" 1702.08734, DDIM 2010.02502, AdamW 1711.05101, ALiBi 2108.12409 and Toolformer 2302.04761. The `why_near` corpus IDs also match their papers. **No ID looks wrong to me.** One row deserves extra care from the human reviewer: n005 (self-consistency). Later versions of the corpus CoT paper 2201.11903 mention self-consistency, so a retrieved CoT passage could partly answer it. The rows remain `reviewed_by: null` until a human checks them, as the ticket intends.

## PRD fit
Yes. The eval now follows ADR-0003 as Accepted: case A is an honest refusal, and case B is an error, never a correct refusal. Refusal evidence can't dilute the gated supported-citation rate (§8). The first automatic answer-quality signals (coverage, in-domain near-miss refusals) are added as report-only, and no gate is weakened.

## Findings
1. [nit] `classify()` raises `TypeError: unhashable type` for a non-string, non-hashable `refusal_reason` (list or dict). That aborts `evaluate()`, and `eval_gate` then exits 2 "could not run". It still fails closed, but the run loses all its metrics ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/08-edge-probes.png?raw=true)). A falsy reason (`""`, `0`, `False`) is treated as "no reason". The Go type is a string, so the risk is low; `isinstance(reason, str)` would close it.
2. [nit] `claims[].markers` given as strings (`["1"]`) never match the integer citation markers, so they count as uncited ([08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/08-edge-probes.png?raw=true)). ADR-0014 specifies `markers: [n...]` (ints), so this is only a note for AI-8.
3. [nit] The diff is 443 changed lines, over the 400 target (CI warning). The PR description discloses it, and about 180 of those lines are tests.
4. [nit] The PR description's "PRD ref" reads "answer-quality metrics (Technical PRD eval)". The ticket's refs are Product PRD §8 (supported-citation / correct-refusal), QA-4, QA-5 and ADR-0003. pm-lead should use the ticket's refs when raising the PR.
5. [spec] Retrieval/answering changes to `scripts/` and `evals/` don't trigger any workflow that runs `make eval`: `stack.yml` is path-filtered to compose/services/shared/migrations/Makefile. Until EVAL-3 lands, DoD item 3 can only ever be "not run" for AI-area PRs. EVAL-3 should include `scripts/**` and `evals/**` in its triggers.
6. [spec] No task or owner is named for the human review of the 15 near-miss rows (setting `reviewed_by`). The README protocol says "Mahesh or someone he names". pm-lead should add this to the PR's "Decisions for Mahesh" or create a follow-up, otherwise `near_miss_correct_refusal_rate` stays a metric over unreviewed drafts.
7. [spec] The ticket asks the PR to have Mahesh confirm the supported-rate reading of ADR-0003. The PR does ask (under "Decisions for Mahesh"). Until he confirms, AC2's semantics rest on pm-lead's interpretation.

## Missing tests
- A non-string or unhashable `refusal_reason` (see finding 1).
- `eval_gate.main` loading the real `refusal_near_miss.jsonl` path. It is only covered indirectly: the QA end-to-end run in [03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/reviews/EVAL-6/evidence/03-e2e-stub-gate.png?raw=true) exercised it.
- `evaluate_answers.main --near-miss ''` (the skip path).

## Hand-off
PASS → pm-lead final review. The nits can be fixed in this PR or in a follow-up; none blocks the merge.

---

# PM final review: EVAL-6 · PR #20 · round 1

**Verdict:** APPROVE
**Reviewer:** pm-lead · **Date:** 2026-11-07 · **Reviewed head:** `4dc4846343f1e952c5dceac864c4b036c7186e20` (same commit QA reviewed) ·
**Evidence pinned at:** arxivlens-agents `193109f0cfc33294285fdfc32fd1e9ffc3c5bd1a`

Inputs: `agents/tasks/EVAL-6.md`, ADR-0003 (Accepted), Product PRD §8 (supported-citation and correct-refusal rows, lines 158–159), QA-4, QA-5,
the PR #20 file list (`evals/README.md` +43, `evals/refusal_near_miss.jsonl` +15, `scripts/eval_gate.py` +11/−1,
`scripts/evaluate_answers.py` +162/−29, `tests/test_evals_data.py` +181/−1), and this QA report. I opened all 20 evidence files (10 `.png` + 10 `.txt`).

## Evidence check (each file against the AC it claims)
| File | Proves | OK? |
|---|---|---|
| 00-ci-checks | All 5 CI check runs on `4dc4846` succeeded. `make test-py` in CI: `84 passed, 1 skipped` (includes `test_evals_data.py`). Ownership OK with the 443-line warning. `make lint` = `lint-go` + `lint-fe` (Makefile:33), and CI runs both (Go job, Frontend job). Python has no linter target. | yes (DoD 2) |
| 01-pytest-evals-data | The 22 EVAL-6 test names pass at the head, and each AC1–AC6 test named in the AC table is present. Red colouring is the known `render_evidence.py` "Fail in the name" nit, not a failure. | yes |
| 02-mutation-check | 14/14 mutants killed, at least one per branch of AC1–AC5 plus report-only isolation. This shows the tests would catch each regression. | yes |
| 03-e2e-stub-gate | A real `eval_gate.py` run end to end: A-refusal = correct refusal and `answer_refusal_rate`, B and unknown = `ask_errors` (a002, x002), supported rate 1.0 over 40 answered citations with refusal evidence excluded, coverage 0.667, and no LEAK marker anywhere in the results file. GATE FAIL is expected (`--skip-retrieval` plus the injected errors). | yes (AC1, AC2, AC3, AC5) |
| 04-gates-unchanged | `thresholds.json` diff is 0 lines, and the 8 `check_thresholds` names are identical on `71cb609` and on the head. | yes (AC6) |
| 05-near-miss-vs-corpus | 15 rows (AC asks ≥ 10). Every `answered_by` is outside the corpus, every `why_near` is inside it, fields are exact, `reviewed_by` is null, no duplicates. | yes (AC4) |
| 06-readme-defs | ADR-0003 table, a definition for each new metric, the per-case keys, and a human-review section. | yes (AC8) |
| 07-splitter-port | Side-by-side code: the Python splitter matches `splitIntoSentences` and its abbreviation list. | yes (AC3 "document the splitter") |
| 08-edge-probes | Finding 1/2 nits (unhashable `refusal_reason`, string claim markers). Every probe fails closed. | yes (nits only) |
| 09-make-test-py-local | The sandbox can't run `make test-py`/`make lint` (no torch/confluent_kafka, Go 1.25 blocked). `make eval` is "not run: no stack", with the command. | yes (AC7's allowed alternative; CI covers the rest) |

No AC rests on a "⚠ unverified" item. `make eval` not being run is the ticket's own allowed alternative (AC7, DoD 3 "not run: <reason>"). This PR changes eval *scoring*, not retrieval or answering, so it can't move `/v1/ask` behaviour. The first real numbers will come from EVAL-3's workflow.

## Product fit
- **§7 principle 2 ("say I don't know") and ADR-0003:** the eval now rewards an honest refusal with evidence (case A) and never lets an outage (case B) or an unknown reason pass as a correct refusal (fail closed). This is the measurement side of ADR-0003, and it lands before AI-7 changes `/v1/ask`. That merge order stops the ≥ 95% refusal gate and the ≥ 90% supported gate from being misread on AI-7's first run.
- **§8 supported-citation row:** limiting the rate to citations of *answered* responses is the reading that makes the row measure what it says ("% citations marked supported" in answers the user sees). A case-A response shows the user no answer, so its evidence passages aren't answer citations. Counting them would push the rate down every time the system refuses correctly. **On lesson [EVAL-1] (no APPROVE while a gate's meaning waits on a Proposed ADR):** that lesson doesn't block this PR. ADR-0003 is Accepted, and the reading follows from its "no synthesized answer" rule. Mahesh is still asked to confirm it explicitly in the PR. If he reads it the other way, the follow-up is one predicate and one test, not a re-design.
- **Report-only metrics** (coverage, near-miss refusal rate, reason counts) give Phase 1 its first answer-quality signals without a new gate. Promoting any of them needs an ADR, as the README says.
- **Public-repo safety:** per-case records hold IDs and numbers only (AC5, LEAK scan). This matters because EVAL-3 uploads results as public artifacts.

## Scope
Everything the ticket listed is present. Nothing outside it changed: no `thresholds.json`, no Go, no `rag.go`, no Makefile/CI. The diff is
443 lines vs the 400 target; 182 of those are tests. I accept it **without** a rule exception: it's within 11%, it's disclosed, and splitting a
scoring change from its own tests would make review worse, not better. PRD status columns: QA-4 and QA-5 status values don't change
(this is measurement only). The §8 rows' *method* text should say "answered responses only; case B = error". I'm adding that to the
pending pm-lead docs PR (board Backlog), because PRD edits go via PR here, not in the app PR.

## QA [spec] findings: decisions
5. **EVAL-3 triggers: declined, with a different route.** `eval.yml` stays path-filtered to itself on `pull_request`, as in the approved
   EVAL-3 design. Each run makes 62 arXiv requests at ≥ 3 s apiece and takes up to ~100 min. Running it on every `scripts/**`/`evals/**` PR would burn arXiv
   politeness and CI time on PRs that don't change answers (e.g. README-only eval PRs). Instead, once EVAL-3 is merged, a PR that changes
   retrieval/answering scoring or behaviour gets **one `workflow_dispatch` run of `eval.yml` on its branch**. `workflow_dispatch` works on any ref once the
   workflow is on `main`, and QA cites that run for DoD 3. Writing this into AGENTS.md §4 / qa-reviewer is a *Proposed* rules-PR item (board Backlog).
   It is recorded in EVAL-3's Notes so QA doesn't fail #22 for the missing path. For EVAL-6 itself, "not run" stands. The first nightly run after both merge produces
   its numbers (EVAL-4 records them).
6. **Near-miss row review owner: Mahesh, or a reviewer he names.** Agents can't reach arxiv.org and must not self-certify their own drafts.
   This is in the PR's "Decisions for Mahesh" and on the board Backlog as a human task. Review n005 (self-consistency vs the CoT paper) and n009
   (Contriever) first. Once rows are reviewed, ai-engineer commits the `reviewed_by` values (an `evals/` change) in a small PR. Until then the README already marks
   `near_miss_correct_refusal_rate` as a metric over unreviewed drafts, and it is report-only.
7. **Supported-rate reading:** asked in the PR's "Decisions for Mahesh" (see Product fit). Merging the PR is the confirmation. A review comment
   that disagrees sends it back per AGENTS.md §2 "Human review = top priority".

## Nits (not blocking; follow-up, ai, P3)
QA 1 (`isinstance(reason, str)` guard so an unhashable `refusal_reason` is an error case, not a crashed run), QA 2 (string claim markers: note for AI-8, where
ADR-0014 fixes ints), and QA's three missing tests (non-string reason, `main` loading the real near-miss path, `--near-miss ''`). They're filed as one Backlog item to
fold into the next `scripts/evaluate_answers.py` change (EVAL-7 touches the same test file). QA 4 (PRD refs in the PR description) is fixed in the raised description.

## Hand-off
APPROVE → orchestrator: replace the PR #20 body with `/tmp/claude-0/s/pr20-body.md`, mark it ready for review, comment the verdict, and move Jira KAN-37 to
**Ready to merge**. **Merge order for Mahesh: #20 (EVAL-6) before #21 (AI-7).**
