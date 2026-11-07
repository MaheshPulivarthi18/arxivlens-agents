[qa-reviewer] **QA round 1: OPS-H8 (part a), PR #30, head `0d70fab`: PASS**

Ticket: [agents/tasks/OPS-H8.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/OPS-H8.md) · Design: [docs/design/OPS-H8.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/docs/design/OPS-H8.md) (approved, plus the split addendum) · PRD: Technical §8.1 L4, §8.2; Product OPS-1, OPS-3, §5.3 · Evidence pack: [agents/reviews/OPS-H8/evidence @ 42eb4a1](https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence)

### Test results
| Check | Source | Result |
|---|---|---|
| Go, Frontend, DB, Ownership | CI on head | pass ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/00-ci-checks.png?raw=true),`` 6/6 green) |
| Python M0: `make test-py` + new `tests/test_kafka_client.py` step | CI job 128515856797 | `84 passed, 1 skipped` / `16 passed` ([01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/01-ci-python-head-kafka-client.png?raw=true))``` |
| Full stack `make test-full` (real Kafka) | CI job 128515856719 | `112 passed, 1 skipped, 3 deselected`; F1 step `3 passed` ([06](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/06-ac8-m4-fullstack.png?raw=true))```` |
| kafka_client + heartbeat tests | local, QA stand-in stubs (PyPI blocked) | 22 passed ([08](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/08-local-tests.png?raw=true))````` |
| 11 extra QA mutants of `kafka_client.py` | local, stand-in stubs | 11/11 KILLED ([09](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/09-qa-extra-mutants.png?raw=true))`````` |
| `make test-unit` / `make lint` | not run locally: no Go 1.25 / torch | CI green |
| `make eval` | not run: no retrieval/answering change | n/a |

### Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 publish requires confirmation | ✅ | `test_publish_requires_confirmation[ok/err/queued/raise]` green in CI; the sentinel check is enforced (QA mutant M7 killed) ([01](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/01-ci-python-head-kafka-client.png?raw=true),``````` [09](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/09-qa-extra-mutants.png?raw=true))```````` |
| AC2 publish_dlq contract + build total | ✅ | `test_publish_dlq_direct_call_contract[ok/err/queued]`, `test_build_dlq_payload_is_total[3 rows]`; signature unchanged, fallbacks kept (M9 killed) |
| AC3 real stack trace | ✅ | `test_dlq_stack_trace_is_the_errors_own`; mutant M4 (`format_exc()`) killed |
| AC4 delivery bound | ✅ | constants at `kafka_client.py:16-19`; `test_delivery_bound_outlasts_message_timeout`; M5 and M6 killed |
| AC5 no commit past an unconfirmed DLQ write | ✅ | `test_unconfirmed_dlq_write_stops_before_commit[err/queued]` (commits == [4], calls {4:1, 5:3}, raises, close last), `test_confirmed_dlq_write_then_commit` (exact log produce@5 → commit 5 → close), `test_failing_publish_in_handler_is_retried` |
| AC6 no regressions / scope | ✅ | 3 Scope files only; workers and heartbeat test diff empty; all hunks before `def start`; `_heartbeat`..EOF IDENTICAL to main ([02](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/02-ac6-ac9-scope-diff.png?raw=true))````````` |
| AC7 CI mutations | ✅ | (b) `68f775f`: 7 failed, all AC1/AC2/AC5 err (and queued) rows plus the handler-publish row ([03](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/03-ac7b-mutation-ci.png?raw=true)).`````````` (a') `455ec67`: AC5 err/queued red in Python **and** Full stack ([04](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/04-ac7a-mutation-ci.png?raw=true)).``````````` Reverts restore the `007aecc` tree and are green. Timeline in [05](````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/05-ac7-timeline.png?raw=true).```````````` See finding 1. |
| AC8 M4 on full stack | ✅ | head stack.yml run 42409999965: `112 passed`. With `-q`, M4 = positions 103–104, both `.`. The map was cross-checked on the (a') run, where its two F's sit exactly on the AC5 rows ([06](`````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/06-ac8-m4-fullstack.png?raw=true)).````````````` See finding 3. |
| AC9 size + PR text | ✅ | 278 changed lines (CI ownership job); the three behaviour-change items are present ([07](``````````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/42eb4a1f6d1c02b4e49b3b1f9f7eabe08f82e1a7/agents/reviews/OPS-H8/evidence/07-ac9-pr-body.png?raw=true));`````````````` the interim relies on `restart: unless-stopped`, which QA confirmed on both workers via the `x-worker` anchor |

### PRD fit
Technical PRD §8.1 L4 now holds for the Python consumers (interim form): no offset is committed unless the handler succeeded or the broker confirmed the DLQ write. Both silent-loss paths are closed. For the `papers.chunked` path, QA confirmed that the processor re-emits on a retried duplicate (`services/processor/worker.py:84-89`), so the L2 ledger doesn't hide a failed publish. No shared contract changed.

### Findings
1. [nit] AC7(b): the `stack.yml` run for `68f775f` was cancelled at 17:06:17 by the revert push at 17:05:43. The `ci.yml` run that holds every AC7(b) row had finished at 17:04:55, so the evidence is complete. Strictly read, though, the Full stack run of (b) wasn't waited for.
2. [nit] PR body: it gives "278 changed lines" and per-file counts instead of the literal `git diff --stat` block, and its AC checklist/Verification still says AC6–AC8 are pending. pm-lead should refresh both when raising.
3. [spec] AC8 / design condition 3 ask for "M4 test lines" in the log, but `make test-full` runs `pytest -q` (dots only). QA derived them by position. Suggest a follow-up so `stack.yml` passes `-rA` to `make test-full`.
4. [nit] `test_publish_requires_confirmation[ok]` asserts only a truthy return, not that it equals the envelope's `event_id`.

### Missing tests (non-blocking; OPS-H8b can add them)
- `produce` raising `KafkaException` (only `BufferError` is exercised).
- `publish[ok]` return value == the produced `event_id`.
- DLQ `produce` raising, driven through `start`.

### Hand-off
PASS → pm-lead final review.


---
_Generated by [Claude Code](https://claude.ai/code)_


*Provenance: the harness refused the QA subagent's Write to report.md; the orchestrator saved the body of PR #30 comment 6712681348 verbatim (https://github.com/MaheshPulivarthi18/ArxivLens/pull/30#issuecomment-6712681348).*
