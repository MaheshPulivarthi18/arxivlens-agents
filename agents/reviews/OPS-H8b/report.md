<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-08 08:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/34#issuecomment-6719707151, because the qa-reviewer harness could not write report.md. -->

[qa-reviewer] QA report — OPS-H8b · PR #34 · round 1

**Verdict: FAIL** (3 blocking: missing test guards + PR body; product code correct in every probe)
**Reviewed commit:** `3fd4ece5001c9f5bfbf7590d21b642a36b66d487` · **Date:** 2026-11-08
**Ticket:** [`agents/tasks/OPS-H8b.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/OPS-H8b.md) · **PRD:** Product PRD OPS-1, OPS-3, §5.3; Technical PRD §8.1 (L4), §8.2 · **Design:** [`docs/design/OPS-H8.md`](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/docs/design/OPS-H8.md) (§2–§5, §7, PM decision, split addendum)
**Evidence:** [agents/reviews/OPS-H8b/evidence @ b4c8c7d](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence)

> **Post-merge review.** This PR was squash-merged at 2026-11-08T08:49:35Z as `9651294`, 54 s after the head's Full-stack job finished and before QA ran ([15](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/15-ac12-pr-body.png?raw=true)).`` `services/` and `tests/` on `main` are byte-identical to `3fd4ece` ([10](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/10-ac9-ac12-scope-size.png?raw=true)).``` The FAIL is about missing test guards and this PR's body, not product behaviour, so the remedy is a small test-only follow-up plus a body edit, not a revert.
>
> Provenance: the QA harness refused to write `agents/reviews/OPS-H8b/report.md`, so this comment is the full report. The orchestrator saves it verbatim.

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI job 128678378194 | pass ([00](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/00-ci-checks.png?raw=true))```` |
| Python M0 unit tests (`make test-py` 114 passed/1 skipped; `test_kafka_client.py` 37 passed) | CI job 128678378133 | pass ([01](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/01-ci-python-head.png?raw=true))````` |
| Frontend / Agent ownership / DB | CI jobs 128678378149 / 128678377928 / 128678378049 | pass |
| Full stack (compose + `make test-full`) | CI job 128678440243 | pass; separate F1 step red only on the 3 known F1 tests ([14](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/14-ac11-m4-fullstack.png?raw=true))`````` |
| Ticket verification (`pytest -v tests/test_kafka_client.py`, heartbeat tests, `grep time.sleep`, `git diff --stat`) | local (stubbed `confluent_kafka`/`ulid`, real pydantic 2.13.5, Python 3.13) | 37 + 6 passed; grep prints nothing (rc 1); 2 files, +255/−65 = 320 |
| `make test-unit` / `make lint` | not run locally: no Go 1.25, PyPI and BGE download blocked | CI green. `ruff` E,F,W on both files clean ([20](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/20-lint-ruff.png?raw=true)),``````` not a repo gate |
| `make eval` | n/a | not a retrieval/answering change |
| QA mutants (20 single edits, local copies, **never pushed**) | local | 14 killed, **6 survived**, each confirmed to change behaviour ([16](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/16-qa-mutants.png?raw=true),```````` [18](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/18-qa-probes-survivors.png?raw=true))````````` |
| QA behaviour probes on head, incl. real `os.kill` SIGTERM | local | all 8 correct ([17](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/17-qa-probes-head.png?raw=true));`````````` harness source in [19](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/19-qa-harness-source.txt)``````````` |

Not verified here: `start` against a real broker (librdkafka eviction, real `UNKNOWN_MEMBER_ID` commit errors). M4 drives the producer contract directly, as the design notes. Stack artifacts couldn't be downloaded (blob host blocked).

## Scope and design check
- Changed files: `services/common/kafka_client.py`, `tests/test_kafka_client.py`, both backend-owned. The heartbeat test, both workers, `shared/`, `.github/`, `Makefile` and compose are unchanged ([10](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/10-ac9-ac12-scope-size.png?raw=true)).````````````
- The code follows design §2–§5 and §7. It builds the payload once, retries the DLQ write in place with 1…30 s rounds, and never re-runs the handler. Commit catches only `KafkaException` and logs it at ERROR. Waits go through `threading.Event`, and the AC6b check runs after every failed attempt. Signals are installed on the main thread only and restored in `finally`, and a second signal raises `KeyboardInterrupt`. Poison records get one attempt and log the type only. The handler path falls back to the envelope `traceparent`.
- The `build_dlq_payload` non-dict guard is in the producer class, which the ticket puts out of scope. AC7's `[1, 2]` row needs it (M15 kills it), so I accept it (S4).
- **Deviation from design without a recorded reason:** §2 says "A test feeds it … a non-dict JSON value and a **non-UTF-8 key**." The non-UTF-8-key test doesn't exist (finding 2).

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `test_success_path[0,1,2]`, `test_commit_error_is_logged_and_loop_continues` (CI [01], local [02](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/02-ac1-success-commit-error.png?raw=true)).````````````` M09 killed. "Only `KafkaException`" holds in code and probe P2 but has no test (finding 4) |
| AC2 | ✅ | `test_confirmed_dlq_write_then_commit[header,envelope]` ([03](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/03-ac2-dlq-then-commit.png?raw=true)).`````````````` M14 killed |
| AC3 | ✅ | `test_unconfirmed_dlq_write_stops_before_commit[err,queued,raise,raise-kafka]`: commits `[4]`, handler@5 ×3, @6 never, `start` returns, `close` last ([04](```````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/04-ac3-dlq-fails-no-commit.png?raw=true)).``````````````` Part a's no-commit assertion is unchanged |
| AC4 | ✅ | `test_dlq_recovers_after_two_failures`, `test_dlq_backoff_schedule` ([05](````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/05-ac4-recovery-backoff.png?raw=true))```````````````` |
| AC5 | ✅ | `test_failing_publish_in_handler_is_retried[ok,err]` ([06](`````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/06-ac5-failing-publish.png?raw=true))````````````````` |
| AC6 / AC6b | ✅ | stop/signal tests plus the empty `time.sleep` grep ([07](``````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/07-ac6-waits-signal-grep.png?raw=true)).`````````````````` A real SIGTERM during a 5 s wait returns in 0.050 s; two real SIGTERMs mid-handler force a stop with no commit (P7/P8). M12 and M13 survive (findings 5, 6) |
| AC7 | ✅ as written, ⚠ guard gap | 3 poison rows ([08](```````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/08-ac7-poison.png?raw=true)).``````````````````` The poison-path commit gate (M03) and the non-UTF-8 key (M16) are unguarded: findings 1, 2 |
| AC8 | ✅ | `test_dlq_failure_log_has_coordinates_not_value[False,True]` ([09](````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/09-ac8-log-hygiene.png?raw=true)).```````````````````` M05, M06, M18 killed |
| AC9 | ✅ | CI `make test-py` + kafka step ([01]). Part-a tests and pm-lead carry-overs 1–3 are present |
| AC10 | ✅ | a76026f 6 failed, 60bf3c2 12 failed, bd342eb 11 failed. Reverts green, trees equal `f357f15` ([11](`````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/11-ac10-mutation-ci-runs.png?raw=true),````````````````````` [12](``````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/12-ac10-mutation-ci-failures.png?raw=true),`````````````````````` [13](```````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/13-ac10-mutation-diffs.png?raw=true))``````````````````````` |
| AC11 | ✅ | `163 passed, 1 skipped, 3 deselected`, 0 failed. `test_m4_chaos.py` has no skip path, so both M4 tests passed ([14], [14b](````````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/14b-ac11-m4-no-skip.png?raw=true))```````````````````````` |
| AC12 | ❌ | Size 320 ✅. Skeleton and final sequence are in Notes ✅. **No "Behaviour changes" section in this PR body** ([15](`````````````````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/b4c8c7d82e96ccdbe8e74cbb475e593870861b9b/agents/reviews/OPS-H8b/evidence/15-ac12-pr-body.png?raw=true)):````````````````````````` finding 3 |

## PRD fit
The change delivers Technical PRD §8.1 L4 for the Python consumer (no commit past an unconfirmed DLQ write; a DLQ outage stalls the worker instead of crash-looping it), §8.2 retry/DLQ diagnostics, and OPS-1 graceful stop. The code is right. Two L4/poison guarantees have no regression test, and the operator-facing behaviour list is missing from the merged PR body.

## Findings
1. **[blocking] The L4 commit gate on the poison path has no test.** Replacing `if not self._dead_letter(msg, e, 1, traceparent): break` with an unconditional call and commit (M03) passes all 43 tests. Probe P1 (poison record, DLQ never confirms, stop in the DLQ wait): head commits `[]`, mutant commits `[5]`. Fix: a poison row with `dlq=["err"]`, `stop_after_waits=2`, asserting no commit for @5, @6 not handled, `close` last.
2. **[blocking] The design §2 non-UTF-8 key test is missing.** Reverting `decode("utf-8", errors="replace")` (M16) passes. Probe P5: with a strict decode, a poison record with key `b"\xff\xfe"` makes `start` raise `UnicodeDecodeError`, and the worker crash-loops, which AC7 exists to stop. Fix: a non-UTF-8-key row asserting the replaced `original_key` and a commit after the DLQ write.
3. **[blocking] AC12 / condition 5: this PR body has no "Behaviour changes" section.** The DLQ-down stall with one CRITICAL line per round, commit error logged (was: worker dies), poison → DLQ `attempts=1` (was: crash loop), first signal = graceful stop / second forces, and handler warning type-only all need listing. The text is already drafted in the ticket Notes. The body also still says "AC10 … to follow" and "Pending QA". Fix: edit this PR's body.
4. [nit] "Only `KafkaException` is caught" is untested. M08 (`except Exception`) survives; P2 shows the swallow.
5. [nit] SIGINT install is untested. M12 survives, and Ctrl-C would abort mid-handler again.
6. [nit] The main-thread guard is untested. M13 survives, and `start()` off the main thread then raises `ValueError` (P4).
7. [nit] Build-once in the consumer path is unguarded. M20 survives: 4 builds and a drifting `failed_at` (P6).

## [spec] for pm-lead
- **S1:** The PR was merged before QA and PM review. Findings 1, 2, 4–7 need a test-only follow-up in `tests/test_kafka_client.py` (backend, about 30 lines). Finding 3 needs a body edit here. pm-lead decides how Jira and the Technical PRD §8.1 caveat removal reflect this.
- **S2:** AC10 / design condition 6 require mutation commits on the PR branch, but the 2026-11-08 orchestrator lesson forbids pushing mutants to the PR head and attributes these pushes to QA, when the developer made them per AC10. The two need reconciling.
- **S3:** AC11 still relies on `-q` dots. The OPS-H8 request to print test names (`-rA`) is still open.
- **S4:** Ticket Scope excluded the producer layer, but AC7 needs the `build_dlq_payload` non-dict guard. I accept it here.

## Missing tests
Poison + DLQ never confirms + stop → no commit · non-UTF-8 key · non-Kafka commit error propagates · SIGINT installed/restored · `start()` off the main thread · payload built once across DLQ rounds · (optional) real signal delivery.

## Hand-off
FAIL → backend-engineer as a test-only follow-up (the PR is merged; S1). pm-lead decides the ticket and Jira handling. There are no product-code defects.


---
_Generated by [Claude Code](https://claude.ai/code)_
