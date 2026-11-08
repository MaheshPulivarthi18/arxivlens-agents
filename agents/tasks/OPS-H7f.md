# OPS-H7f: DLQ replay never publishes an empty or unreplayable envelope (fixes B1/B2)

| | |
|---|---|
| **Owner** | backend-engineer |
| **Priority** | P1 (first OPS-H7 part; unblocks OPS-H7a/b/c and makes OPS-H8b's raw-payload DLQ records safe to replay) |
| **PRD ref** | Product PRD OPS-2, OPS-3, §5.3; Technical PRD §4 (envelope: "`event_id` is a ULID ... dedup keys"), §8.2 |
| **Depends on** | OPS-H6 (merged). Design: `docs/design/OPS-H7.md` § Q5 table + PM decision condition 1 (approved 2026-11-07) |
| **Jira** | to create under the "Dev harness & infrastructure" epic (labels `task-OPS-H7f`, `agent-backend`, `arxivlens`); parent work KAN-31 |
| **Design required** | no (covered by the approved OPS-H7 design) |
| **Status** | Ready to merge, [PR #32](https://github.com/MaheshPulivarthi18/ArxivLens/pull/32) @ `6cd6ae4` (QA FAIL r1 → PASS r2 · PM APPROVE 2026-11-08) |

## Goal
`arxivlens dlq replay` today rebuilds the envelope with `json.Unmarshal` into `EventEnvelope` (`internal/dlq/manager.go:114-117`, `origin/main` `2b71772`).
That never fails on a map, so a raw (non-envelope) `original_value` is republished with `event_id: ""`, `event_type: ""`, `paper_id: ""` (B1).
A nil `original_value` (Go consumer, `internal/kafka/consumer.go:163-164`) is republished as an all-empty envelope (B2). Every envelope
replay publishes must be well-formed, and anything that can't be replayed must be skipped and reported, not published.

## Scope
- Files: new `internal/dlq/envelope.go` (pure helper, e.g. `replayEnvelope(p events.DLQPayload, targetTopic string) (events.EventEnvelope, string /*skip reason*/, bool)`),
  new `internal/dlq/envelope_test.go`, and `internal/dlq/manager.go` (`Replay` calls the helper for **both** dry-run and real runs, and logs skips).
  Keep `manager.go`'s changed lines at their current indentation (backend lesson OPS-H6).
- Out of scope: paging, checkpoints, lock, deterministic IDs (OPS-H7a/b/c). `shared/events/*` and `DLQPayload` (shared contract) are unchanged.
  CLI flags are unchanged. The `cmd/arxivlens/main.go` output line stays as it is.
- README / CONTRIBUTING: no change expected (no flag or command change). If the replay output text changes, say so in the PR. Don't edit README while #26 is open.
- Size target: ~130 changed lines (≈ 35 prod, ≈ 95 test).

## Acceptance criteria
- [x] AC1: Envelope rule. A table-driven test of the helper covers every row:
  (a) `original_value` is a full envelope (`event_id`, `event_type`, `paper_id` all non-empty) → that envelope, **same `event_id`**, `Attempt = 0`, `Traceparent` = the DLQ payload's.
  (b) A non-empty object that is not a full envelope (e.g. `{"arxiv_id": "2401.00001", "version": 1}`, and the partial `{"event_id": "x"}`) with a non-empty
  `OriginalKey` → `NewEventEnvelope(target, OriginalKey, 1, value)`: `ulid.Parse(event_id)` succeeds, `event_type = target`, `paper_id = OriginalKey`, `payload = value`.
  (c) Unreplayable, nothing returned: nil `original_value` (B2), `{}`, an object whose only key is `raw_value` (`services/common/kafka_client.py:80`),
  and case (b) with an empty `OriginalKey`. Each comes with a distinct, human-readable skip reason.
- [x] AC2: No empty IDs. One test asserts the property over all AC1 inputs: every envelope the helper returns has non-empty `event_id`, `event_type` and `paper_id`.
- [x] AC3: `Replay` uses the helper in dry-run and real mode alike. A skipped record is logged with `key`, `error_type` and the reason, is **not** published, and
  is **not** counted, so a dry-run's count equals what a real run publishes. Shown by the diff plus a log-line test or a review note citing the line.
  `Replay`'s producer can't be injected today, so don't add an injection seam just for this AC; that is OPS-H7a/b's job.
- [x] AC4: Mutation check (QA runs it). Revert the full-envelope guard to today's plain `Unmarshal`: AC1 (b) and AC2 go red. Drop the `raw_value`
  case: AC1 (c) goes red.
- [x] AC5: Existing flags (`--topic`, `--error-type`, `--limit`, `--dry-run`) behave as before for full-envelope records.
- [x] Docs: the PR description lists the behaviour change ("unreplayable DLQ records are now skipped and logged, not republished empty").

## Verification
```bash
make test-unit
make lint
go test -race -count=1 -v -run 'TestReplayEnvelope|TestReplayEnvelopeNeverEmpty' ./internal/dlq/
```
CI (`ci.yml`) is the source of truth. "not run locally: Go 1.25 unavailable" is fine.

## Notes
- 2026-11-07 (pm-lead): split out of OPS-H7 at design review (B1/B2 found by backend-engineer). It goes first because OPS-H8b (poison → DLQ as raw dicts) and
  OPS-H7b (replay drains the whole topic) both widen B1's reach. The processor normally fails a B1 envelope before its ledger (`worker.py:45-52` vs `:79`), so the
  usual symptom is a record bouncing back into the DLQ with a broken `original_value`, not ledger poisoning. Fix both anyway.
- 2026-11-07 (backend-engineer): built on `agent/backend/OPS-H7f` from `2b71772`, draft PR #32, head `0120d3d`. Files: new `internal/dlq/envelope.go` (+54),
  new `internal/dlq/envelope_test.go` (+123), `internal/dlq/manager.go` (+7/-15, same indentation). 199 changed lines vs the ~130 target (the test table is bigger).
  `replayEnvelope` sets the DLQ payload's `traceparent` on re-enveloped records too (propagation rule). The new skip log line is
  `[DLQ Replay] Skipped unreplayable event key="…" error_type="…": <reason>`; the other output is unchanged. AC3 evidence: the call sits above `if !dryRun` and the skip
  `continue`s before `replayedCount++`, plus `TestReplaySkipLine`. AC4 is QA's mutation check. Not run locally: sandbox Go is 1.24.7 and proxy.golang.org module
  downloads are blocked; `gofmt -l internal/` printed nothing; ownership check OK. CI on `0120d3d`: all 5 check runs success (Go job: go1.25.0, `go vet ./...`, `ok arxivlens/internal/dlq`).
  Jira story still to be created (child of KAN-31); the PR says "story pending".
- 2026-11-08 (pm-lead): QA r1 FAIL at `0120d3d` (single-conjunct mutants M7/M8/M9 survived); rework `6cd6ae4` is test-only (+26/-4) and QA r2 PASSed
  (13/14 mutants killed, 7/7 extra). PM APPROVE: all ACs checked off against the r2 evidence ([report](../reviews/OPS-H7f/report.md), evidence pinned at `2ea3675`).
  Size 221 changed lines vs ~130 (test rows); accepted. QA nit 4 → OPS-H7c Notes; nit 5 (M14) → OPS-H7b AC4; nit 6 → PR body refreshed to `6cd6ae4`.
  PR #32 raised for review. Jira story is still to be created (orchestrator).
