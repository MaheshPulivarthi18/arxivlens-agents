# Board

Last updated: 2026-11-07 21:00Z by orchestrator (cycle 19:59Z: OPS-H8 part a #30 and ING-10 #31 → Ready to merge; RET-2 design approved (build waits for #26 merge, README); new ING-10 KAN-54, ING-11 KAN-55)

WIP limit: 2 active PRs per developer agent (Ready to merge doesn't count; AGENTS.md §3). Order within a column = priority.
Wave 1 = independent now. Wave 2/3 = start after the named dependency is **merged** (or, where it says "slot", when the owner's WIP slot frees).
`rag.go` order (one file, one owner): AI-7 → AI-6 → AI-6b → QA-8 → AI-8.

## Ready — the 2026-11-07 plan, in execution order
| # | ID | Title | Owner | Pri | Depends on | Wave | Note |
|---|---|---|---|---|---|---|---|
| 5 | [FE-1](tasks/FE-1.md) (KAN-19) | Vitest harness + answer/citation state tests | frontend-engineer | P1 | — | 1 | **Env-blocked:** registry.npmjs.org; needs Mahesh (allow the host, or push the lockfile) |
| 6b | [AI-6b](tasks/AI-6b.md) | `parseSynthesis` structured-output parser + types/errors; delimiter look-alikes; `selectContext` edge cases | ai-engineer | P0 | **AI-6 #28 merged** (same files) | 3 | Covered by `docs/design/QA-8.md` §5 (no new design). Pure function, `Ask` unchanged |
| 7b | [OPS-H8b](tasks/OPS-H8b.md) | Python consumer loop: in-place DLQ retry, commit-error log, interruptible waits, graceful stop, poison records | backend-engineer | P0 | **OPS-H8 merged** (same files) | 3 | Covered by `docs/design/OPS-H8.md` (split addendum). Code exists at `ebe80a7`; ~325 lines; seam = poison/AC7 → OPS-H8c |
| 9 | [FE-3](tasks/FE-3.md) | Refusal-with-evidence UI; no "Verified" on unchecked citations (design-required) | frontend-engineer | P0 | FE-1, AI-7 merged | 2 | |
| 10 | [RET-2](tasks/RET-2.md) | `SearchHit` carries paper version (+ `page` field, omitted for all hits until ING-11) (design-required) | backend-engineer | P1 | ADR-0014 (Accepted 2026-11-07), AI-7 + EVAL-6 merged | 2 | **Design approved 2026-11-07** (conditions 1–7), build after #26 (OPS-H10) merges (README) |
| 11 | [QA-8](tasks/QA-8.md) (KAN-7) | LLM synthesis in `/v1/ask` via provider, template fallback (design addendum) | ai-engineer | P0 | LLM-1, LLM-1b, AI-6, AI-6b merged | 3 | Fake provider in tests; real-LLM numbers are EVAL-8 |
| 13 | [AI-8](tasks/AI-8.md) | Claims + provenance (version, chunk, section, page, quote, status) (design-required) | ai-engineer | P0 | ADR-0014 (Accepted), QA-8, RET-2 merged | 3 | |
| 14 | [FE-4](tasks/FE-4.md) | Claim evidence panel, quote highlight, PDF page link (design-required) | frontend-engineer | P0 | ADR-0014 (Accepted), AI-8, FE-3 merged | 3 | |
| 15a | [EVAL-9](tasks/EVAL-9.md) | `eval.yml` seed-step timeout headroom (45→70 min, job 100→120), seed-time summary line, two label nits | backend-engineer | P1 | **EVAL-3 merged**; no other open PR on `eval.yml` | 3 | From EVAL-3 QA finding 5 (seed at 84% of budget) |
| 15 | [OPS-H9](tasks/OPS-H9.md) | CI trust: `real_postgres` step, pgvector ≥ 0.8 pin, MinIO digest check | backend-engineer | P2 | EVAL-3 merged; no open README PR | 3 | |

## Ready — not in this plan (lower priority; start only with a free slot and no file overlap)
| ID | Title | Owner | Pri | Depends on |
|---|---|---|---|---|
| [ING-11](tasks/ING-11.md) (KAN-55) | Part a (producer): `page_breaks` in the processor, `paper_chunk_pages` table, `db.py` writes it (nothing reads it yet) | backend-engineer | P1 | Design approved 2026-11-07 (conditions 1–9). **In QA**: draft PR #33 (`3f1c32d`, CI green) |
| [AI-11](tasks/AI-11.md) | `TokenChunker` emits `page_start` from `page_breaks` (fail-safe: unknown, never guessed); AC1 end-to-end on ING-11's fixture | ai-engineer | P1 | **ING-11 merged** (its test file is in `make test-py`; `tests/test_m0.py` is held by #24) |
| [ING-11b](tasks/ING-11b.md) | Part b (consumer): `/v1/search` returns `page` from `paper_chunk_pages`; parity fragment; README; real-stack write check | backend-engineer | P1 | **AI-11 + RET-2 merged** |
| [OPS-H7f](tasks/OPS-H7f.md) | DLQ replay never publishes an empty/unreplayable envelope (B1/B2 fix; OPS-H7 part 1 of 4) | backend-engineer | P1 | OPS-H6 (Done). Touches no open-PR file: **can start now** |
| [OPS-H7a](tasks/OPS-H7a.md) | `dlq list`/`inspect` to start-time high watermark, `P/O` paging, Kafka in `db.yml` (OPS-H7 part 2) | backend-engineer | P1 | OPS-H7f merged, #26 merged (README; sequence with RET-2) |
| [OPS-H7b](tasks/OPS-H7b.md) | Resumable replay: Postgres checkpoints + log (migration 000004), filters, dry-run (OPS-H7 part 3) | backend-engineer | P1 | OPS-H7a merged |
| [OPS-H7c](tasks/OPS-H7c.md) | Replay advisory lock, deterministic IDs for raw payloads, stack replay run (OPS-H7 part 4; closes OPS-H7) | backend-engineer | P1 | OPS-H7b merged, #26 merged (`stack.yml`) |
| [OPS-H2](tasks/OPS-H2.md) | Unify Python dependencies into one `requirements.txt` | backend-engineer | P1 | OPS-H1 (merged) |
| [ING-6](tasks/ING-6.md) | Scheduled crawler with per-category `since` watermark | backend-engineer | P1 | OPS-H3 (Done) |
| [FE-2](tasks/FE-2.md) | "Export all citations" (.bib) for an answer | frontend-engineer | P2 | FE-1 |

## In progress
| ID | Title | Owner | Branch |
|---|---|---|---|

## In QA
| ID | Title | Owner | PR |
|---|---|---|---|

## PM review
| ID | Title | Owner | PR |
|---|---|---|---|

## Ready to merge (raised for Mahesh)
| ID | Title | Owner | PR | Verdicts |
|---|---|---|---|---|
| [OPS-H8](tasks/OPS-H8.md) | Python producer confirms delivery; `publish`/`publish_dlq` raise `DeliveryError` (part a; interim crash-restart until OPS-H8b) | backend-engineer | ArxivLens [#30](https://github.com/MaheshPulivarthi18/ArxivLens/pull/30) (KAN-34) @ `0d70fab` · AC7 mutations (b) `68f775f`, (a') `455ec67` red, reverted | QA PASS r1 · PM APPROVE ([report](reviews/OPS-H8/report.md)); OPS-H8b (KAN-53) starts after merge |
| [ING-10](tasks/ING-10.md) | Stored version matches the PDF: on-demand ingest parses `entry.ID` version; versioned PDF URLs | backend-engineer | ArxivLens [#31](https://github.com/MaheshPulivarthi18/ArxivLens/pull/31) (KAN-54) @ `c940779` · stack.yml dispatched on branch (run 42411848508) · no file overlap with open PRs | QA FAIL r1 (AC5 no stack run) → PASS r2 · PM APPROVE, AC4 wording amended ([report](reviews/ING-10/report.md)) |
| [LLM-1b](tasks/LLM-1b.md) | `internal/llm`: OpenAI-compatible client + `FromEnv` (transport errors carry no server bytes; no redirects) | backend-engineer | ArxivLens [#27](https://github.com/MaheshPulivarthi18/ArxivLens/pull/27) (KAN-47) · no file overlap with open PRs | QA FAIL r1 → PASS r2 · PM APPROVE ([report](reviews/LLM-1b/report.md)) |
| [OPS-H10](tasks/OPS-H10.md) | `stack.yml` runs on Go/`tests/` PRs and keeps service logs on every run | backend-engineer | ArxivLens [#26](https://github.com/MaheshPulivarthi18/ArxivLens/pull/26) (KAN-50) · **human checks:** open artifact 13579885920, view step summary, delete scratch branch `agent/backend/OPS-H10-ac3` | QA FAIL r1 → PASS r2 · PM APPROVE ([report](reviews/OPS-H10/report.md)); unblocks AI-9 AC1 |
| [AI-6](tasks/AI-6.md) | Context selection, token budget, synthesis prompt in `rag.go` (not yet called; parser → AI-6b) | ai-engineer | ArxivLens [#28](https://github.com/MaheshPulivarthi18/ArxivLens/pull/28) (KAN-38) · no file overlap with open PRs | QA FAIL r1 (PR text) → PASS r2 · PM APPROVE ([report](reviews/AI-6/report.md)); AI-6b (KAN-52) starts after merge |
| [EVAL-7](tasks/EVAL-7.md) | Blind human-review sheet → citation precision, claim correctness (report-only) | ai-engineer | ArxivLens [#29](https://github.com/MaheshPulivarthi18/ArxivLens/pull/29) (KAN-42) · no file overlap with open PRs · first real judging session is Mahesh's | QA FAIL r1 → PASS r2 · PM APPROVE ([report](reviews/EVAL-7/report.md)) |

## Blocked
| ID | Title | Owner | Waiting on |
|---|---|---|---|
| [AI-9](tasks/AI-9.md) | CPU rerank: score-neutral sort-and-batch, timing log, threads (re-scoped; does not fix F1) | ai-engineer | draft #24 (KAN-39), QA r1 FAIL. **OPS-H10 merged** (AC1 stack numbers) + #21 merged (AC5); then round-2 checklist in the ticket |
| ADR-0015 | CPU rerank latency: which ranking-changing options (int8, `max_length`; not pool/model) + adoption rule (Proposed 2026-11-07) | Mahesh | human decision; blocks AI-10 |
| [AI-10](tasks/AI-10.md) | Configurable int8/`max_length` reranker, measured, makes F1 pass (design-required) | ai-engineer | ADR-0015 Accepted, then AI-9 merged |
| [EVAL-8](tasks/EVAL-8.md) | First answer eval with a real LLM (carries QA-8's old AC3) | backend + ai | Mahesh: model + where it runs; cost cap (ADR-0001) for a hosted model; then QA-8, EVAL-3, EVAL-6 merged |
| [ING-8](tasks/ING-8.md) | Measure PDF section-extraction quality (scorer/tests/docs built on `agent/ai/ING-8` `d2ad9c5`, pushed, no PR) | ai-engineer | arxiv.org access to license-check and hand-label `evals/extraction.jsonl` (AC1) and run the baseline (AC5) (KAN-32) |
| [AI-5](tasks/AI-5.md) | `/v1/ask` relevance bar when rerank scores are missing (reranker outage fails open) | ai-engineer | ADR-0011 (human decision); also `rag.go`, so it queues behind the plan's `rag.go` chain |
| [EVAL-2](tasks/EVAL-2.md) | `/v1/search` p95 gate key in `make eval` | ai-engineer | ADR-0012 (Proposed) |
| [EVAL-4](tasks/EVAL-4.md) | Record EVAL-3's first numbers in `evals/BASELINE.md` (+ README Testing line); AC5 = AI-7's refusal counts by reason | ai-engineer | EVAL-3 merged + one completed `eval.yml` run (AC5: on a `main` with #20 + #21) |
| ADR-0013 | Search plan cache vs HNSW (generic plans → exact scan) | Mahesh | human decision |
| ADR-0007..0009 | v2 multi-user scope · HNSW at scale · long-context embedder | Mahesh | human decision (block no Ready task) |

## Backlog (not yet specced — pm-lead grooms these)
- From the OPS-H8 QA/PM review (backend, P3, after #26 merges): `stack.yml` passes `PYTEST_ARGS=-rA` to `make test-full` so the log names each test (AC evidence today needs a dot-position map)
- PR-body image embeds: an outbound filter in the agent environment rewrites `![](…)` into backticked links and swaps the footer, so evidence images don't render inline in PR descriptions (#26–#31). Pinned URLs still work. Mahesh: check whether this is expected
- From the RET-2 design (product rule, P2, Proposed: needs Mahesh): when a paper's v1 and v2 are both indexed, their near-duplicate chunks can take two top-5 search slots, and two `/v1/ask` citations. Options: search returns the latest version only, or dedupes by `arxiv_id`. RET-2 makes this visible (distinct `version`) but doesn't change it. Also decide whether on-demand ingest of `<id>vN` ingests vN or the latest (ING-10 out of scope)
- From the EVAL-7 review (ai, P3, small `tests/` + `scripts/answer_review.py` PR after #29 merges): tests for `build_rows` with a fake `fetch_passages`
  (the `--db-url` branch, unverified so far) and for an empty export; make `score --save` validate strictly *before* writing (today a strict failure leaves the file behind)
- From the EVAL-7 review (ai, P2, revisit after QA-8 merges): the drift fingerprint `(marker, chunk_id, round(score,3), supported)` can miss a changed sentence with the
  same score and verdict. If real LLM runs show many drifts or an odd confusion matrix, store a hash of each cited sentence in EVAL-6's `case_record` (no text) and compare it in `export`
- **Human (Mahesh or a reviewer he names), from EVAL-6:** review the 15 rows of `evals/refusal_near_miss.jsonl` (`answered_by` ID correct; no corpus
  paper answers the question; n005 and n009 first). ai-engineer then commits the `reviewed_by` values (small `evals/` PR)
- From the EVAL-6 review (ai, P3, fold into the next `scripts/evaluate_answers.py` change; EVAL-7 did not touch it): `classify()` treats a non-string `refusal_reason`
  as an error case instead of raising `TypeError`; tests for `main` loading the real near-miss file and `--near-miss ''`. String `claims[].markers` → note for AI-8
- *Proposed* rules PR (Mahesh decides), from EVAL-6 QA finding 5: once EVAL-3 merges, AGENTS.md §4 item 3 + qa-reviewer: PRs that change retrieval or answering get one
  `workflow_dispatch` run of `eval.yml` on their branch as DoD 3 evidence (`eval.yml` keeps its self-only PR path filter: 62 arXiv requests per run)
- pm-lead docs PR, after #20 merges: Product PRD §8 supported-citation row "answered responses only (ADR-0003)" and correct-refusal row "case B = error, not a refusal"; add the report-only metrics to the §8 method notes; after EVAL-7 #29 merges, point the supported-citation row's "Measured by" at the human review (`scripts/answer_review.py`, report-only)
- **Left out of the 2026-11-07 plan on purpose** (see PROGRESS 2026-11-07 pm-lead): Phase 2 research workflow (collections, comparison
  tables, conversational follow-ups, notes, PDF viewer; FE-2 export stays Ready) waits for Phase 1's exit; entailment verifier
  (NLI / LLM judge, ADR-0014 reserved statuses) waits for EVAL-7 human judgments to show cosine's error rate; real readiness
  checks (`/readyz` checks DB + embedder with bounded timeouts; `/healthz` stays liveness; backend P1); OTLP export, Prometheus
  metrics, auth + rate limiting, MinIO access policy, backups/restore, worker-scaling + failure-injection tests, deploy/rollback
  docs (Phase 3 rest); versioned event-schema validation; model registry with pinned revisions (touches the embedding-model
  contract → ADR first); query-category eval slices and candidate-pool sweeps (no tuning without EVAL-3 numbers). Not doing:
  Kubernetes, another database, new agent roles, HNSW tuning, admin dashboard, collaboration.
- From the 2026-11-07 merge review: `/internal/ingest` builds `ProcessorWorker()`/`EmbedderWorker()` per request (model reload; ai,
  `services/embedder/api.py`, after AI-9 which edits the same file) and ignores client cancellation (backend side: honour the
  `INGEST_TIMEOUT` ctx end to end). P2: ingest is off the Phase 1 path and F2 is fixed by the timeout
- After AI-10 merges with F1 passing (backend, small): drop the "Known failure F1" step and `F1_TESTS` deselection in `stack.yml`. (The always-keep-logs part and the `internal/**` path filter moved to OPS-H10; pm-lead reversed the earlier "don't add `internal/**`" note on 2026-11-07, because DoD 2 needs the milestone suite on pipeline/query PRs)
- From ADR-0015 option 6 (backend + ai, P3, only if AI-10's measured options fall short): ONNX Runtime fp32 export of `bge-reranker-base` (score-preserving within 1e-4 if measured so; new dependency → `requirements*.txt` + embedder Dockerfile decision)
- *Proposed* rules PR (Mahesh decides): AGENTS.md §3 "< 400 changed lines": say whether `_test.go` lines count (LLM-1 got a one-off non-test-only exception, 2026-11-07)
- From LLM-1b QA r2 nit 1 (backend, P2, fold into the next `internal/llm/openai.go` change): `transportDetail` reports TLS/x509 failures (unknown authority, handshake) as "malformed response or protocol error". Add fixed-string classes such as `*tls.CertificateVerificationError` → "TLS certificate rejected" and other TLS errors → "TLS handshake failed". Never copy server bytes (AC6), and add a test row (e.g. an `httptest.NewTLSServer` with an untrusted cert)
- ING-9 follow-ups (backend, P3, fold into the next `ingester.go`/`downloader.go`/`internal/arxiv` change; QA nits 3–5, 7): an ingester test where a cancelled ctx sends no request (kills the last surviving mutant); `TestConcurrentCallersAreSpaced` with d ≥ 100 ms; a `HandleRecord` → `fetchPDF` wiring test once db/storage are behind interfaces; check whether `arxiv.org/pdf/<id>.pdf` redirects, and if it does, make `CheckRedirect` wait on the limiter. (The ING-1 PRD caveat is dropped: ING-1 ✅ is true for every Go caller once #25 merges; until then the crawler was the only bulk caller)
- From ING-9 QA nit 6 (backend, P2, harness): CI's Go job runs `go test ./...` without `-race`; add `-race` (to `make test-go` or a separate CI step) after measuring its runtime cost; update CONTRIBUTING if the command changes
- pm-lead docs PR, after #21 merges: Product PRD QA-4/QA-5 notes and Technical PRD §7.2 say `/v1/ask` refuses with evidence + `refusal_reason` when no citation is supported (ADR-0003, AI-7); fold into the PR below
- pm-lead docs PR now due: Product PRD QA-8 row (ADR-0001/0002 Accepted; work split into LLM-1, AI-6, QA-8, AI-7, AI-8, EVAL-8),
  Technical PRD §11 P0 row and §7.2 diagram note (ADR-0003 refusal with evidence), QA-4 row text (AI-2 merged)
- QA-9 Streaming answers (frontend + ai) — after QA-8 and AI-8 (claims are validated before they can be shown)
- From OPS-H5 (#16) review, backend P2: migration version ledger (`schema_migrations`, apply only unapplied files; backfill 000001/000002) — Proposed ADR first; removes CONTRIBUTING's "every migration idempotent" rule
- From OPS-H5, backend P2: `TestHNSWVectorHits` seeds into a scratch schema / skips when `papers` non-empty (the pgvector ≥ 0.8 pin + README prerequisite are now OPS-H9)
- From OPS-H5 F2, ai P1: `scripts/evaluate_retrieval.py` applies `hnswSearchSettings` and reports both plan regimes (input for ADR-0013)
- After OPS-H1 merges: file its first green `stack.yml` run as OPS-H5 H4/AC5 evidence in `agents/reviews/OPS-H5/`
- From EVAL-5, backend P2 (needs Proposed ADR, HTTP API): query service reports its runtime `--model` (`/healthz` or `/v1/info`); eval reads it instead of `--query-model`
- From EVAL-5, ai P2: `CHUNK_COUNTS_SQL` groups by `arxiv_id` but `papers` is unique on `(arxiv_id, version)` — scope to latest version; P3: README note that default `--query-model` needs a full checkout, PEP 8 spacing, `BM25_SQL` drift guard
- From AI-4 (#18), ai P2: `Ask`-level test that the `citation support unverified` log carries the response trace ID; rerank-timeout fallback through `Ask`
- Tooling nit (pm-lead rules PR): `render_evidence.py` colours `--- PASS` red when the test name contains "Fail"; tabs render as boxes
- From the OPS-H3 review: `ExtractCleanArxivID` should match only a whole ID and support old-style IDs the crawler stores (needs a product decision); add more pinning tests; add `go test -cover` to CI (retry-sleep injection is now OPS-H6 AC6/AC7)
- From the #8 review: some code comments cite PRD sections (`§4`, `§6 Tier 1`) that now live in this repo; reword or link them (backend/ai, nit)
- From the AI-2 review + Mahesh's #11 review (ai, P2, after AI-4, same files): split the unverified log line into separate counters — sentence embed errors, missing sentence vectors, chunk embed errors, missing chunk vectors, dimension mismatches (today `sentence_embed_errors` and `chunks_without_vector` lump these); assert each counter in tests; mixed verified+unverified test (`unverified=1 citations=2`); one hit cited by two sentences, one checked < 0.50 and one unverified → evidence score = the checked score, reason B (AI-7 QA missing test); a correct-length batch with one empty slot (AI-3 QA optional test); log sentence/chunk dimension mismatch as unverified
- pm-lead docs PR now due (#11 merged): Product PRD QA-4 ◐ → ✅, drop AI-2 caveat in §8 supported row, Technical PRD §9 known-gap paragraph
- pm-lead docs PR (after EVAL-3 #22 merges): Technical PRD §9 "Reference hardware" + Product PRD §8 Latency rows: record EVAL-3's first CPU numbers (`/v1/ask` p95 12.8–14.9 s, rerank ≈ 10–12 s/query, single-paper ingest mostly 30–80 s, outliers ≈ 157 s) with the profile they came from (GitHub `ubuntu-latest`, 4 vCPU AMD EPYC 9V45, 15 GiB, torch CPU: below the *Proposed* 8-vCPU CPU-only profile). Numbers only; the gating rule stays Mahesh's decision.
- backend option (P3, only if EVAL-9's 70-min seed budget gets tight): cache the seeded Postgres/MinIO state per `evals/corpus.txt` hash + migrations hash, so nightly runs skip the 31 arXiv ingests. Needs a design (cache invalidation when ingest/chunking code changes would hide regressions).
- backend docs nit: `CONTRIBUTING.md:28,42,54` still say "once EVAL-1 lands" (folded into EVAL-3 AC7); AGENTS.md §2 ownership table omits `.gitignore` for backend (CI script allows it) (pm-lead rules PR)
- From Mahesh's #12 review (backend, P2, small): split `make test-py` into `test-m0` and `test-evals-data` (and two CI steps), so the eval-data tests still run when the ML stack (torch/sentence-transformers) fails to install/import; `test-py` keeps running both; update `CONTRIBUTING.md:23` + README Testing block. Not folded into EVAL-3 because it shouldn't wait for OPS-H1. (Where `evals/results` go and artifact retention: EVAL-3 AC3/AC7.)
- OPS-H6 design G1 (backend, P1): a redelivered `papers.discovered` record downgrades an already-`embedded` paper's status (`UpdatePaperDownloaded` forces `'downloaded'`). Don't downgrade a later status, or skip the re-publish when the status is already past `downloaded`
- From the OPS-H6 PM review (backend, P2, next `internal/kafka/consumer.go` change; not folded into OPS-H8, which is Python-only): a clean shutdown logs `Poll error (topic= partition=-1): context canceled`; skip poll-error logging when `ctx.Err() != nil` and assert no such line on shutdown
- OPS-H6 design G2 (backend, P2; pm-lead 21:02Z: `chunk_embeddings` has no `content_hash` column, so the fix lives in backend-owned `services/common/db.py` — e.g. `save_sections_and_chunks` deletes a chunk's embeddings when its `content_hash` changes — or a new column, which changes an existing table → ADR): embedder L3 dedupe joins `chunk_embeddings` on `model` only, not content. Key it on `content_hash` so a changed chunk text gets re-embedded (PRD says L3 is "content hashing")
- pm-lead docs PR: Technical PRD §8.1 L4 / §8.2 diagram caveat ("commit after DLQ" not true until OPS-H6 + OPS-H8), Product PRD OPS-1 ✅ → ◐; Proposed Product PRD row ING-8 (extraction quality measured)
- ING-8 follow-ups: detector improvements from the baseline (backend, `services/processor/`), and a pure `parse_doc_sections(doc)` seam so the scorer stops calling a private method
- backend nits from the RET-1 review (fold into the next `search.go` change): `context.Canceled` fallback test case, `±Inf` score test
- From the AI-1 review: `/internal/rerank` bi-encoder fallback (no cross-encoder) returns uncalibrated dot products → decided in ADR-0011, done in AI-5 if accepted; aux-section match is a substring (`"Notable"` contains `"table"`) → small ai follow-up after AI-5
- pm-lead PRD docs PR: Product PRD QA-5 ✅ → ◐ (fails open during reranker outages; ADR-0011/AI-5), back to ✅ when AI-5 merges
- From the OPS-H8 design review, G5 (backend, P3): a DLQ message that can never be delivered (e.g. > `message.max.bytes`, 1 MiB) stalls the Python consumer for good; on non-retriable produce errors (`MSG_SIZE_TOO_LARGE`) truncate `original_value` + `stack_trace` and retry once. Not reachable today (claim-check envelopes)
- From the OPS-H8 design review, G4 (ai, P3, fold into the next `services/embedder/worker.py` change): the embedder imports `check_and_record_ledger` but doesn't use L2; redelivery is safe via L3 but costs a SELECT + status UPDATE
- From the OPS-H8 design review (backend, P3, after OPS-H8 merges): compose `stop_grace_period` (~20 s) for processor/embedder so one confirmed `flush` (≤ 12 s) fits inside Docker's stop grace (today 10 s → SIGKILL → duplicate, never loss)
- OTLP span export to Jaeger/Tempo (backend) — Technical PRD §11 P1
- Prometheus metrics: consumer lag, DLQ depth, stage latency (backend) + OPS-6 dashboard (frontend)
- Auth + rate limiting on query API (backend) — before any shared deployment
- On-demand ingest via Kafka (backend) — depends on ADR-0004
- From the OPS-H1 design (ai owns `tests/` + EVAL-1 corpus, after OPS-H1's first `stack.yml` run): verify the hard-coded fixture `2608.20331` in `tests/test_m3_query.py` / `tests/test_m4_chaos.py` exists on arXiv and matches the G-CARL wording (EVAL-1 QA nit 8); replace it if not, and never loosen the asserts
- From the OPS-H1 design (backend, P2, rules PR first): add `.dockerignore` (`.venv/`, `node_modules/`, `bin/`, `.cache/`, `evals/results/`) so local `make stack-up` doesn't send GBs of build context; needs a pm-lead rules PR to add `.dockerignore` to backend's row in AGENTS.md §2 and the `ownership-check.sh` allow-list
- pm-lead rules PR after OPS-H1 merges: AGENTS.md §6 "workers not in docker-compose (OPS-H1)" gotcha → replace with `make stack-up` / `stack.yml`
- From the AI-3 review (#13), QA finding 2 (backend, P2): `/v1/ask` `max_citations` has no upper bound (`internal/query/server.go:52,136`), so one embed request (and the hit list) can be arbitrarily large. *Proposed (needs Mahesh's OK on the value)*: reject `max_citations` > 20 with 400, or clamp it; add a handler test. Could ride with "Auth + rate limiting"
- From the AI-3 review (#13), QA finding 3 (ai, P2, after EVAL-3 gives a full-stack `make eval`): measure AI-3's benefit. Run `make eval` on `9c1229a` (before) vs the merge of #13 (after), compare `/v1/ask` p50/p95 and the supported-citation rate (±0.01), and record the numbers in the AI-3 notes / `evals/BASELINE.md` (EVAL-4)
- pm-lead docs PR after #13 merges: Technical PRD §11 row "Batch embedding in RAG validation" (`docs/PRD-Technical.md:385`) → done, link PR #13

## Repo split (2026-11-02)
All tickets, docs, reviews and agent rules moved from ArxivLens to this repo. ArxivLens PRs #3, #4, #5, #7 were closed
(agent-only content, now here); #2 and #6 were stripped to code only. See `AGENTS.md` §0.

## Environment notes (cycles 2026-11-01 … 2026-11-07)
Agent sandbox egress blocked the Go 1.25 toolchain/modules, npm, Docker Hub and Hugging Face. Go, frontend and stack tasks (AI-1, OPS-H1/H2/H3/H5, ING-6, FE-1/2) were deferred, not blocked — they stay Ready. 2026-11-02: same limits (local Go 1.24.7); OPS-H3 was done anyway because CI verifies Go tests. OPS-H1 needs Docker, FE-1 needs npm to regenerate `package-lock.json`. 2026-11-03: unchanged (registry.npmjs.org and proxy.golang.org don't resolve, huggingface.co 403; re-checked in cycle 3, all four registries unreachable); no new task started because ai/backend are at WIP limit and FE-1 can't regenerate the lockfile. Cycle 4: unchanged; Docker CLI present but no daemon. Cycles 5–6: unchanged (npm, Go proxy, HF all time out; no Docker daemon). Cycle 14:00: also PyPI and arxiv.org unreachable; Go verified in CI, full stack via the new `stack.yml` on GitHub runners (OPS-H1). 2026-11-07 (pm-lead check): registry.npmjs.org and proxy.golang.org don't resolve, huggingface.co and export.arxiv.org get 403 from the proxy, Docker CLI present without a daemon. No LLM key or server, which the plan doesn't need (fake provider).

## Done
| ID | Title | PR |
|---|---|---|
| [EVAL-6](tasks/EVAL-6.md) | Answer eval: ADR-0003 classification, report-only coverage, near-miss set | ArxivLens [#20](https://github.com/MaheshPulivarthi18/ArxivLens/pull/20) → 1273a3b (KAN-37) |
| [AI-7](tasks/AI-7.md) | ADR-0003 refusal with evidence + `refusal_reason` | ArxivLens [#21](https://github.com/MaheshPulivarthi18/ArxivLens/pull/21) → 8406b18 (KAN-36) |
| [LLM-1](tasks/LLM-1.md) | `internal/llm`: provider interface, typed errors, config, `llmtest` fake | ArxivLens [#23](https://github.com/MaheshPulivarthi18/ArxivLens/pull/23) → 43713ce (KAN-35) |
| [EVAL-3](tasks/EVAL-3.md) | Full-stack `make eval` workflow (`eval.yml`, `make eval-seed`) | ArxivLens [#22](https://github.com/MaheshPulivarthi18/ArxivLens/pull/22) → 122eee3 (KAN-29) |
| [ING-9](tasks/ING-9.md) | arXiv politeness: one 3 s limiter per process + identifying UA | ArxivLens [#25](https://github.com/MaheshPulivarthi18/ArxivLens/pull/25) → 2b71772 (KAN-48) |
| [OPS-H1](tasks/OPS-H1.md) | Processor + embedder workers in compose; `make stack-up`; Full stack workflow (F1 known red, Mahesh) | ArxivLens [#14](https://github.com/MaheshPulivarthi18/ArxivLens/pull/14) → 71cb609 (KAN-13) |
| [EVAL-5](tasks/EVAL-5.md) | Harden retrieval eval tests + ADR-0010 parity drift guard | ArxivLens [#17](https://github.com/MaheshPulivarthi18/ArxivLens/pull/17) → 6c80d64 (KAN-33) |
| [OPS-H5](tasks/OPS-H5.md) | HNSW index migration; `migrate` applies all `*.up.sql` | ArxivLens [#16](https://github.com/MaheshPulivarthi18/ArxivLens/pull/16) → e67354c (KAN-17) |
| [AI-4](tasks/AI-4.md) | `/v1/ask` passes its trace ID to `HybridSearch` | ArxivLens [#18](https://github.com/MaheshPulivarthi18/ArxivLens/pull/18) → 3151285 (KAN-27) |
| [OPS-H6](tasks/OPS-H6.md) | Go consumer: commit only after success or confirmed DLQ write | ArxivLens [#15](https://github.com/MaheshPulivarthi18/ArxivLens/pull/15) merged (KAN-28) |
| [AI-3](tasks/AI-3.md) | Batch embedding in RAG citation validation | ArxivLens [#13](https://github.com/MaheshPulivarthi18/ArxivLens/pull/13) → 8b0a2d2 (KAN-11) |
| [AI-2](tasks/AI-2.md) | Fail closed when citation support can't be verified | ArxivLens [#11](https://github.com/MaheshPulivarthi18/ArxivLens/pull/11) → 9c1229a (KAN-10) |
| [OPS-H4](tasks/OPS-H4.md) | Ignore `evals/results/` + eval-data tests in `make test-py` | ArxivLens [#12](https://github.com/MaheshPulivarthi18/ArxivLens/pull/12) → 211adbf (KAN-16) |
| [RET-1](tasks/RET-1.md) | Rerank a 20-candidate pool and sort by rerank score (ADR-0010) | ArxivLens [#9](https://github.com/MaheshPulivarthi18/ArxivLens/pull/9) → bb9ee90 (KAN-24) |
| [AI-1](tasks/AI-1.md) | Unit tests for `rag.go` filtering and citation validation | ArxivLens [#10](https://github.com/MaheshPulivarthi18/ArxivLens/pull/10) → 4702daa (KAN-9) |
| [EVAL-1](tasks/EVAL-1.md) | Versioned golden eval sets + `make eval` gate | ArxivLens [#2](https://github.com/MaheshPulivarthi18/ArxivLens/pull/2) → a959d03 (KAN-8) |
| [OPS-H3](tasks/OPS-H3.md) | Baseline Go unit tests (arXiv ID, Atom parsing, retry backoff) | ArxivLens [#6](https://github.com/MaheshPulivarthi18/ArxivLens/pull/6) → 72c82ac (KAN-15) |
| REPO-SPLIT | ArxivLens is code-only; planning moved here | ArxivLens [#8](https://github.com/MaheshPulivarthi18/ArxivLens/pull/8) → 18a3cf9 |
| [PM-1](tasks/PM-1.md) | Reconcile PRD status columns + acceptance criteria (QA PASS r2 · PM APPROVE) | ArxivLens #3 closed; content landed in arxivlens-agents' first commit (repo split, approved by Mahesh 2026-11-02) |
