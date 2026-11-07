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

---

[pm-lead] **PM final review: OPS-H8 (part a), PR #30, head `0d70fab`: APPROVE** (2026-11-07)

**What I read:** ticket `agents/tasks/OPS-H8.md` (part a ACs and split note); design `docs/design/OPS-H8.md` with the split addendum; Product PRD OPS-1, OPS-3, §5.3; Technical PRD §8.1 L4, §8.2; the QA r1 report above; the production diff (`ci.yml` +2, `kafka_client.py` +52/−26) in a worktree at `0d70fab`; and all 20 evidence files (00–09, `.png` + `.txt`), each confirmed present at `42eb4a1` with `git cat-file -e`.

**PRD fit.** This delivers what the operator in Product §5.3 needs: a paper whose handler fails ends up in `<topic>.dlq` with a real stack trace, or else its offset is not committed. Neither failure path can lose it silently any more. A failed `papers.chunked` publish is now an ordinary handler failure (retried, then DLQ'd), so a paper can't stay `chunked` forever without being embedded. Technical §8.1 L4 now holds for the Python consumers in an interim form: crash-restart while the DLQ is down, which costs time and never a record. That interim was decided at the split and is stated for Mahesh in Behaviour changes item 3. OPS-3 is unaffected: redelivery is absorbed by L2/L3, and QA checked that the processor re-emits on a duplicate. No shared contract changed: the `DLQPayload` fields and the `publish_dlq` signature are the same.

**Scope.** Exactly the part-a list. The consumer section from `_heartbeat` to EOF is byte-identical to `main`, the worker files are untouched, and nothing extra is in the diff. 278 changed lines (≤ 400, no exception).

**Evidence vs ACs.** AC1–AC5: 01 (CI, 16 PASSED by name), backed by 09 (11/11 QA mutants killed). AC6: 00 + 02. AC7: 03, 04, 05. AC8: 06. AC9: 02 (size) + 07 (text). Each image shows the result for its AC within the visible lines (lesson LLM-1b checked). Rendering nit: in 01 and 08 the renderer colours PASSED rows red when the test name contains "error" or "fail", so read the word, not the colour. Nothing is left "⚠ unverified" that matters. Delivery failure against a real broker is tested only with fakes, which the ticket intended, and the PR lists it as a risk.

**QA findings, decided:**
1. [nit] AC7(b) Full stack run cancelled: **accepted.** Every row that (b) can turn red lives in `tests/test_kafka_client.py`, which the `ci.yml` job ran to completion (failure, 17:04:55Z) before the revert push. The Full stack job adds no AC7(b) signal. (a') waited for both jobs. Recorded in the ticket's AC7 line.
2. [nit] PR body: **fixed** in my rewrite. It now has the literal `git diff --stat origin/main...0d70fab` block, all ACs ticked with evidence, the CI results for the head, and the QA and PM verdicts. The "Behaviour changes" section is kept byte-identical.
3. [spec] AC8 "M4 log lines": **spec fixed.** `make test-full` runs `pytest -q`, so a green run can't print test names. AC8 is amended (dated Notes line in the ticket) to accept a dot-position map that has been checked against a failing run of the same job. QA's 06 does exactly that: the (a') run's two `F`s fall on the AC5 rows. Follow-up for the board Backlog (orchestrator to add; I'm not editing the board this session): **backend, P3, after #26 (OPS-H10, owns `stack.yml`) merges: pass `PYTEST_ARGS=-rA` to `make test-full` in `stack.yml`.** The `PYTEST_ARGS` hook already exists in the Makefile, so this is a one-line change. Done when the job log names every test with PASSED/FAILED.
4. [nit] weak `[ok]` assertion: **moved to OPS-H8b**, along with QA's three missing tests. I added a Notes line to `agents/tasks/OPS-H8b.md`. Not blocking: M11/M2 already pin the confirmation logic, and the return value is the `event_id` local that the function builds.

**PM observations (non-blocking):**
- The new `ci.yml` step is named "(commit-after-process, DLQ, shutdown; fakes only)", but part a has no shutdown tests. OPS-H8b adds them. I noted this in OPS-H8b so the name is true or corrected there.
- DoD 4 (PRD status): Product OPS-1 is still marked ✅ and Technical §8.1 L4 has no caveat. Both have been untrue since before this PR (lesson OPS-H6), and they remain partly untrue until OPS-H8b (the poison-record crash loop). The correction is the existing pm-lead docs PR item on the board Backlog (OPS-1 ✅ → ◐, L4 caveat). This code PR doesn't change what the row should say, so it doesn't block. README/CONTRIBUTING: no command or API change.
- Process: the PR body is rewritten in transit. Image embeds lose their `!` and get wrapped in backticks, the 🤖 line is dropped, and a footer is appended. The same thing happened on #26–#29 and in this report's QA section. This is an environment-level outbound filter that I did not try to bypass. The evidence URLs are still in the PR body (pinned to `42eb4a1`), and every file is in this pack.

**Verdict: APPROVE.** PR #30 raised (body rewritten, marked ready for review, label `ready-to-merge`). Merge: Mahesh.
