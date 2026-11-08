<!-- Provenance: saved verbatim by the orchestrator from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/32#issuecomment-6713422064 (the QA harness could not write report.md). -->

[qa-reviewer] **QA round 1: OPS-H7f, PR #32, head `0120d3d`: FAIL** (1 blocking test gap; the production code is correct)

Ticket: [agents/tasks/OPS-H7f.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/OPS-H7f.md) · Design: [docs/design/OPS-H7.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/docs/design/OPS-H7.md) § Q5 + PM condition 1 · PRD: Product OPS-2, OPS-3, §5.3; Technical §4, §5, §8.2 · Evidence pack: [agents/reviews/OPS-H7f/evidence @ 60c3f02](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence)

### Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build), Python M0, Frontend, DB, Ownership | CI on head | 5/5 success ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/00-ci-checks.png?raw=true));`` Go job: `go1.25.0`, `make lint-go`, `make test-go` → `ok arxivlens/internal/dlq` ([01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/01-ci-go-job.png?raw=true))``` |
| Scope / ownership / gofmt | local | 3 files, `Ownership OK for role=backend (199 changed lines)`, `gofmt -l` empty ([02](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/02-scope-ownership.png?raw=true))```` |
| Ticket's `go test -race -count=1 -v -run 'TestReplayEnvelope\|TestReplayEnvelopeNeverEmpty'` | local scratch module, go1.24.7. Uses the PR's **real** `envelope.go`/`envelope_test.go`/`manager.go`/`events.go`; only ulid/kgo/internal/kafka are stubbed (Go 1.25 + module downloads unavailable) | all PASS ([03](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/03-ac1-ac2-pr-tests.png?raw=true)).````` CI runs dlq only without `-v`/`-race` |
| `make test-unit` / `make lint` | not run locally: no Go 1.25 | CI green |
| `make eval` | not run: no retrieval/answering change | n/a |

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 envelope rule | ✅ (see finding 1) | `TestReplayEnvelope` has 10 rows covering (a)/(b)/(c), each skip with its exact reason, and the reasons are distinct ([03](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/03-ac1-ac2-pr-tests.png?raw=true))`````` |
| AC2 no empty IDs | ✅ as written, ⚠ weak | `TestReplayEnvelopeNeverEmpty` catches the whole-guard revert (M1) but none of the single-conjunct drops (M7/M8/M9), see finding 1 |
| AC3 dry-run = real, skips logged/not published/not counted | ✅ | `manager.go:104-108`: the helper runs above `if !dryRun` and skips `continue` before `replayedCount++` (`:119`). `TestReplaySkipLine` covers the log line. QA harness on the real `Manager.Replay` (stubbed kgo/producer): dry-run count = real count = publishes (3/3, 2/2, 0/0), each skip logged with key/error_type/reason, nothing empty published ([04](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/04-ac3-replay-head.png?raw=true)).``````` The same harness on `origin/main` reproduces B1/B2: count 7, empty envelopes published ([05](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/05-ac3-replay-base.png?raw=true))```````` |
| AC4 mutation check | ✅ | M1 (plain `Unmarshal`): KILLED, with `b_raw_object`, `b_partial_envelope` and `TestReplayEnvelopeNeverEmpty` red. M2 (drop `raw_value`): KILLED, with `c_raw_value_only` red. 14 mutants in total: 8 killed, 6 survived, 0 invalid ([06](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/06-ac4-mutation.png?raw=true))````````` |
| AC5 flags unchanged for full envelopes | ✅ | 5 combinations of `--topic`/`--error-type`/`--limit`/`--dry-run` on a full-envelope DLQ: counts, logs and published JSON are **IDENTICAL** on base `2b71772` and head ([08](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/08-ac5-before-after.png?raw=true))`````````` |
| Docs: behaviour change in PR | ✅ | PR body states it and names the new skip line |

### PRD fit
The fix serves §8.2 / OPS-2 / §5.3. Replay can no longer publish an empty `event_id`/`event_type`/`paper_id`, so the L2 ledger can't be poisoned by `""`. Unreplayable records are reported, not republished, and full envelopes keep their ID (OPS-3). The head code meets PM condition 1 (i)-(iv); the probe in [07](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/07-finding1-probe-near-full.png?raw=true)``````````` shows it handles every "one ID field missing" input correctly.

### Findings
1. **[blocking]** The tests don't guard condition 1(iii) field by field. Any **one** conjunct of `env.EventID != "" && env.EventType != "" && env.PaperID != ""` (`envelope.go:37`) can be removed and every PR test stays green: M7/M8/M9 SURVIVED ([06](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/06-ac4-mutation.png?raw=true)).```````````` These are real regressions. With an envelope that lacks only `event_id`, M7 publishes `event_id=""` (B1 again). M8 publishes `event_type=""` and M9 publishes `paper_id=""` ([07](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/07-finding1-probe-near-full.png?raw=true)).````````````` No table row has exactly two of the three ID fields, and OPS-H8b's partial dicts and OPS-H7c's rewrite of this helper make that input likely. **Fix (~6 test lines):** add three (b) rows: a full envelope minus `event_id`, minus `event_type`, minus `paper_id`, each with a key and `want: "wrap"` (`TestReplayEnvelopeNeverEmpty` picks them up). Optionally add one with an empty key → `skip`/`skipNoKey`.
2. [nit] The (a) rows use `event_type == testTarget` and `paper_id == key`, so "keep the envelope's fields" can't be told apart from "overwrite with target/key". M11 SURVIVED. Use a distinct `event_type` and assert `payload`/`occurred_at`/`version` are kept.
3. [nit] Condition 1(ii) boundary: `{"raw_value":…, "other":…}` should be re-enveloped, but M13 (skip whenever `raw_value` is present) SURVIVED. Add one (b) row.
4. [nit] (code reading, not run) An envelope with all three IDs but a mistyped non-ID field (e.g. `"version":"2"`) fails `Unmarshal` and gets a **fresh** `event_id`. That is consistent with the rule and rare, but worth a line in OPS-H7c (which owns IDs).
5. [nit] M14 (apply the rule only in real runs) isn't caught by the PR's tests. AC3 allows a review note, and QA's harness catches it. OPS-H7a/b should add a dry-run-vs-real count test once `Publisher` is injectable.
6. [spec] AC4's mutation set (whole-guard revert, drop `raw_value`) was too coarse to expose finding 1. For ACs that guard a conjunction, specs should ask for one mutant per conjunct.

### Not verified
- A Go 1.25 `-v -race` run of the ticket's test set (CI runs plain `go test ./...`). Local runs used go1.24.7 with stubs; harness sources are in [09](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/60c3f026e0cee2d58a944aa860912ca5b15378de/agents/reviews/OPS-H7f/evidence/09-qa-harness-source.png?raw=true)`````````````` (full text in the `.txt`). The `ulid.Parse` stub checks length, alphabet and overflow only.
- Replay against a real Kafka (OPS-H7c AC8).

### Hand-off
FAIL → back to backend-engineer (rework round 1). Finding 1 needs only test rows. The re-review will re-run the mutants, and M7/M8/M9 must go red.


---
_Generated by [Claude Code](https://claude.ai/code)_


---

# QA report: OPS-H7f · PR #32 · round 2

**Verdict:** PASS
**Reviewed commit:** `6cd6ae4` (`6cd6ae47f23936bb114a053ed4e4e7c19fde1ade`) · **Date:** 2026-11-08
**Ticket:** [agents/tasks/OPS-H7f.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/OPS-H7f.md) · **Design:** [docs/design/OPS-H7.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/docs/design/OPS-H7.md) § Q5 + PM condition 1 · **PRD:** Product OPS-2, OPS-3, §5.3; Technical §4, §5, §8.2
**Evidence:** [agents/reviews/OPS-H7f/evidence @ 2ea3675](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence) (files `r2-00` to `r2-10`; the round-1 files are unchanged)

### What changed since round 1 (`0120d3d` to `6cd6ae4`)
There is one commit, and it only touches tests: `internal/dlq/envelope_test.go` +26/-4. `envelope.go` and `manager.go` are byte-identical to round 1, so the design check, PRD check and code reading from round 1 still apply. The PR as a whole is still 3 files, all backend-owned: `Ownership OK for role=backend (221 changed lines)`, and `gofmt -l` prints nothing. The merge base is still `origin/main` `2b71772` ([r2-02](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-02-scope-delta.png?raw=true)). The new test rows:
- (b) three rows, each a full envelope minus exactly one of `event_id`, `event_type` or `paper_id` (round-1 finding 1)
- (b) `raw_value` plus another key (nit 3)
- (c) a full envelope minus `event_id` with an empty key → `skipNoKey`
- (a) a full envelope whose `event_type` differs from the target and whose key differs from `paper_id`. The keep-path assertions now compare `event_id`, `event_type`, `paper_id`, `occurred_at`, `version` and `payload` against the input (nit 2).

### Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build), Python M0, Frontend, DB, Agent ownership | CI on `6cd6ae4` | 5/5 completed/success ([r2-00](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-00-ci-checks.png?raw=true)). The Go job 128539420920 ran `go1.25.0`, `make lint-go` (`go vet ./...`) and `make test-go`, and printed `ok arxivlens/internal/dlq` ([r2-01](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-01-ci-go-job.png?raw=true)) |
| Ticket's `go test -race -count=1 -v -run 'TestReplayEnvelope\|TestReplayEnvelopeNeverEmpty'` (+`TestReplaySkipLine`) | local scratch module, go1.24.7. It uses the PR's real `envelope.go`, `envelope_test.go`, `manager.go` and `events.go`, checked with `cmp` against the worktree. Only ulid, kgo and internal/kafka are stubbed | all 16 table rows and 4 tests PASS, `go vet` clean ([r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-03-ac1-ac2-pr-tests.png?raw=true)) |
| `make test-unit` / `make lint` | not run locally: no Go 1.25, and the module proxy is blocked | CI green (above) |
| `make eval` | not run: no retrieval or answering change | n/a |

**Harness integrity.** The round-1 scratch directory was gone, so I rebuilt the harness from evidence 09's text. The sources are identical apart from the scratch path, and I added two minimal stub `go.mod` files that 09 had not captured ([r2-10](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-10-qa-harness-source.png?raw=true)). As a control, I ran the rebuilt harness on the round-1 head `0120d3d`. Its output is byte-identical to round-1 evidence 06: 8 killed, 6 survived ([r2-05](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-05-harness-control-r1head.png?raw=true)).

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 envelope rule | ✅ | `TestReplayEnvelope`, 16 rows. (a) 3 rows; (b) 7 rows, including one row per guard conjunct; (c) 6 rows, each with its exact skip reason. `TestReplayEnvelopeSkipReasonsDistinct` passes ([r2-03](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-03-ac1-ac2-pr-tests.png?raw=true)) |
| AC2 no empty IDs | ✅ | `TestReplayEnvelopeNeverEmpty` now goes red for each single-conjunct mutant M7, M8 and M9, as well as M1 and M3 ([r2-04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-04-ac4-mutation-head.png?raw=true)) |
| AC3 dry-run = real; skips logged, not published, not counted | ✅ | The code is unchanged since round 1: the helper is called above `if !dryRun`, and a skip `continue`s before `replayedCount++`. On the real `Manager.Replay` with a stubbed producer, dry-run count = real count = publishes for each filter (3/3, 2/2, 0/0). Each skip is logged with `key`, `error_type` and the reason, and nothing empty is published ([r2-08](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-08-ac3-replay-head.png?raw=true)) |
| AC4 mutation check | ✅ | I re-ran the same 14 mutants on `6cd6ae4`: **13 killed, 1 survived, 0 invalid**. M1 (plain `Unmarshal`) turns AC1 (b) and AC2 red. M2 (drop `raw_value`) turns `c_raw_value_only` red. **M7, M8 and M9, which survived round 1, are now KILLED.** M11 and M13 (nits 2 and 3) are also KILLED. Only M14 survives; see nit 5 ([r2-04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-04-ac4-mutation-head.png?raw=true)). I also ran 7 extra mutants aimed at the new keep-path assertions, the guard operator and the wrap `event_type`: all **7/7 KILLED** ([r2-06](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-06-extra-mutants.png?raw=true)) |
| AC5 flags unchanged for full envelopes | ✅ | I ran 5 combinations of `--topic`, `--error-type`, `--limit` and `--dry-run`. Counts, log lines and published JSON are **IDENTICAL** between base `2b71772` and head `6cd6ae4` ([r2-09](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-09-ac5-before-after.png?raw=true)) |
| Docs: behaviour change in PR | ✅ | The PR body states "unreplayable DLQ records are now skipped and logged, not republished empty" and names the new skip line |

**Finding 1 re-check.** The near-full probe passes on the head. The same probe on M7, M8 and M9 still publishes `event_id=""`, `event_type=""` and `paper_id=""` respectively, so the new rows guard real regressions and not cosmetic ones ([r2-07](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-07-probe-near-full.png?raw=true)).

### PRD fit
Unchanged from round 1. Replay can no longer publish an envelope with an empty `event_id`, `event_type` or `paper_id`, so the §8.2 ledger can't be poisoned with `""`. Unreplayable records are reported and not republished (OPS-2, §5.3), and full envelopes keep their `event_id` (OPS-3, now also killed by mutant R5). Each of these invariants is now guarded field by field.

### Findings (round 2)
1. ~~[blocking] single-conjunct mutants M7/M8/M9 survive~~ **Resolved.** All three are KILLED ([r2-04](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/2ea367571df656b4135ece114f085a0c052f16cf/agents/reviews/OPS-H7f/evidence/r2-04-ac4-mutation-head.png?raw=true)).
2. ~~[nit] (a) rows can't tell "keep" from "overwrite" (M11)~~ **Resolved.** There is a distinct `event_type`/key row, and `occurred_at`, `version` and `payload` are asserted. M11, R1, R2, R3 and R4 are KILLED.
3. ~~[nit] `raw_value` + another key boundary (M13)~~ **Resolved.** M13 is KILLED.
4. [nit] Carried over (code reading, not run). An envelope with all three IDs but a wrongly typed non-ID field gets a fresh `event_id`. That is consistent with the rule; OPS-H7c owns the follow-up.
5. [nit] Carried over. M14 (apply the rule only in real runs) still survives the PR's own tests. AC3 allows a review note, and QA's harness catches M14. OPS-H7a/b should add a dry-run-vs-real count test once `Publisher` is injectable.
6. [nit] The PR description's "Evidence (filled by pm-lead)" block still cites CI on `0120d3d`. pm-lead should refresh it to `6cd6ae4` when raising the PR.
7. [spec] Carried over from round 1: for a guard that is a conjunction, AC4-style mutation lists should name one mutant per operand. No new spec issues.

### Not verified
- A Go 1.25 `-v -race` run of the ticket's test set. CI runs plain `go test ./...` and shows `ok arxivlens/internal/dlq`. My local runs used go1.24.7 with infra stubs, and the `ulid.Parse` stub checks only length, alphabet and overflow.
- Replay against a real Kafka (OPS-H7c AC8).

### Hand-off
PASS → pm-lead final review. No blocking findings remain. Nits 4 and 5 belong to OPS-H7c and OPS-H7a/b, and nit 6 is for pm-lead when raising the PR.

---

# PM review: OPS-H7f · PR #32 · head `6cd6ae4`

**Verdict:** APPROVE · **Date:** 2026-11-08 · **Reviewer:** pm-lead
**Inputs:** ticket `agents/tasks/OPS-H7f.md`; design `docs/design/OPS-H7.md` § Q5 + PM decision condition 1; Product PRD OPS-2, OPS-3, §5.3; Technical §4, §5, §8.2; QA r1 (FAIL, `0120d3d`) and r2 (PASS, `6cd6ae4`); PR #32 files via REST.

### Evidence opened
I opened all 11 round-2 images and their `.txt` files (`r2-00` … `r2-10`, pinned at `2ea3675`). Each PNG shows the *result* for its AC, not only the command:
r2-00 (5/5 check runs success on `6cd6ae4`), r2-01 (go1.25.0, `go vet ./...`, `ok arxivlens/internal/dlq`), r2-02 (r1→r2 delta is test-only, 3 files, `Ownership OK … 221`, `gofmt` empty),
r2-03 (16 table rows + 3 tests PASS on the PR's real sources, `cmp`-checked), r2-04 (13/14 mutants killed, M7/M8/M9 now red), r2-05 (control: rebuilt harness reproduces r1's 8/6 byte-for-byte),
r2-06 (7/7 extra mutants killed), r2-07 (near-full probe: head PASS, M7/M8/M9 publish an empty ID), r2-08 (dry-run count = real count = publishes 3/3, 2/2, 0/0; skips logged with key/error_type/reason),
r2-09 (5 flag combinations base vs head IDENTICAL), r2-10 (harness sources; its `exit code 1` is `diff` reporting the expected mutate.py/mutate_r2.py difference). I re-checked live: PR head `6cd6ae4`, 5/5 checks success, `mergeable_state: clean`, base `2b71772` = `main`.

### Checks QA can't make
1. **Product fit.** Meets Technical §8.2 and Product OPS-2/§5.3: replay can no longer publish `event_id: ""` (B1) or an all-empty envelope (B2), so the L2 ledger can't be keyed on `""`; unreplayable records are reported, not silently republished; full envelopes keep their `event_id` (OPS-3, killed by R5). An operator running `--dry-run` now sees the same count a real run publishes (§7 principle: no surprises in ops tools).
2. **Design condition 1 (i)-(iv).** Read in the diff: (i) wrap needs a non-empty `OriginalKey` (`skipNoKey`); (ii) `raw_value`-only is unreplayable, `raw_value` + other keys is wrapped (M13 killed); (iii) every returned envelope has the three IDs (AC2 + M7/M8/M9 killed); (iv) the helper runs above `if !dryRun` and a skip `continue`s before `replayedCount++`.
3. **Scope.** Exactly the three ticketed files in `internal/dlq/`; no shared contract, flag, README or CLI-output change beyond the new skip line, which the PR names. Size 221 vs the ~130 target (76 prod incl. doc comments, 145 test); the overrun is test rows that QA asked for. Under 400, accepted.
4. **AC coverage.** AC1-AC5 all have result-bearing evidence; no ⚠ left on anything that matters. The two "not verified" items (Go 1.25 `-race -v` run; real Kafka) are covered by CI's plain `go test ./...` and by OPS-H7c AC3 respectively.
5. **Docs.** No README/CONTRIBUTING change needed (no flag or command change; README is held by #26 anyway). PRD status: OPS-2 should read ◐ until OPS-H7c (design condition 7); that pm-lead docs PR is still owed and is now a board Backlog line. This PR doesn't change it.

### Observation (not blocking)
- Old code logged and skipped a record whose `original_value` failed `json.Marshal`; new code falls through to the wrap path. `original_value` is a `map[string]any` decoded from JSON, so `Marshal` can't fail in practice. No action.

### QA open items, dispositioned
- Nit 4 (all IDs present but a mistyped non-ID field → fresh `event_id`) → note added to `agents/tasks/OPS-H7c.md` (its deterministic-ID AC2 must cover row `b_envelope_with_wrong_field_type`, and its PR must name the case).
- Nit 5 (M14: dry-run-only rule not caught by the PR's tests) → `agents/tasks/OPS-H7b.md` AC4 extended: `TestReplayDryRun` includes OPS-H7f unreplayable records and asserts dry-run count = real-run publishes (M14 must go red). OPS-H7b owns `fakePublisher`; OPS-H7a has no publisher seam.
- Nit 6 (PR body cites CI on `0120d3d`) → fixed in the PR #32 description rewrite (CI on `6cd6ae4`, evidence pinned at `2ea3675`).
- Finding 7 `[spec]` (one mutant per conjunct) → pm-lead lesson added; template change proposed there, no rules PR opened.

### Hand-off
APPROVE → PR #32 description rewritten with the Evidence section and marked ready for review. Merge is Mahesh's. OPS-H7a still waits for **OPS-H7f merged and #26 merged**.
