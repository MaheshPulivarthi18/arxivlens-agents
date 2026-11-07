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
