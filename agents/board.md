# Board

Last updated: 2026-11-03 by pm-lead (external-review plan: OPS-H6, EVAL-3, EVAL-4, OPS-H7, ING-8 specced; ADR-0003 abstention question)

WIP limit: 1 open PR per engineering agent. Order within a column = priority.

## Ready
| ID | Title | Owner | Pri | Depends on |
|---|---|---|---|---|
| [OPS-H6](tasks/OPS-H6.md) | Go consumer: commit only after success or confirmed DLQ write; context-aware retry wait (design-required) | backend-engineer | P0 | — |
| [OPS-H1](tasks/OPS-H1.md) | Run processor + embedder workers in docker-compose; one-command full test | backend-engineer | P0 | — |
| [EVAL-3](tasks/EVAL-3.md) | GitHub Actions full-stack `make eval` (manual + nightly), results artifact, first numbers; carries RET-1 AC6 (design-required) | backend-engineer (ai pairs on design) | P1 | OPS-H1 |
| [OPS-H7](tasks/OPS-H7.md) | DLQ list/replay: offset checkpoints, paging, replay lock, idempotent replay (design-required) | backend-engineer | P1 | OPS-H6 |
| [ING-8](tasks/ING-8.md) | Measure PDF section-extraction quality: heading corpus + boundary P/R scorer + baseline | ai-engineer | P1 | — |
| [FE-1](tasks/FE-1.md) | Frontend test harness (Vitest) + tests for answer/citation states | frontend-engineer | P1 | — |
| [OPS-H5](tasks/OPS-H5.md) | Migration for HNSW index + `migrate` applies all migrations | backend-engineer | P1 | — (soft: OPS-H1) |
| [OPS-H2](tasks/OPS-H2.md) | Unify Python dependencies into one `requirements.txt` | backend-engineer | P1 | OPS-H1 |
| [ING-6](tasks/ING-6.md) | Scheduled crawler with per-category `since` watermark | backend-engineer | P1 | OPS-H3 |
| [AI-3](tasks/AI-3.md) | Batch embedding in RAG validation | ai-engineer | P1 | AI-1, AI-2 (both merged) |
| [FE-2](tasks/FE-2.md) | "Export all citations" (.bib) for an answer | frontend-engineer | P2 | FE-1 |
| [AI-4](tasks/AI-4.md) | `/v1/ask` passes trace ID to `HybridSearch`; harden ADR-0010 parity guard (KAN-27) | ai-engineer | P2 | — (AI-2 merged) |
| [EVAL-2](tasks/EVAL-2.md) | `/v1/search` p95 gate + eval-test hardening (EVAL-1 QA r3 nits, AC6–AC9); AC10 moved to EVAL-3 | ai-engineer | P2 | EVAL-1 |

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

## Blocked
| ID | Title | Owner | Waiting on |
|---|---|---|---|
| [QA-8](tasks/QA-8.md) | LLM answer synthesis behind citation validation | ai-engineer | ADR-0001, ADR-0002 (human decision), EVAL-1, AI-1 |
| [AI-5](tasks/AI-5.md) | `/v1/ask` relevance bar when rerank scores are missing (reranker outage fails open) | ai-engineer | ADR-0011 (human decision), AI-1 merged |
| [EVAL-4](tasks/EVAL-4.md) | Record EVAL-3's first measured numbers in `evals/BASELINE.md` | ai-engineer | EVAL-3 merged + one completed `eval.yml` run |
| ADR-0003 | Abstention policy for `/v1/ask` when all citations are unsupported / verification unavailable (question added 2026-11-03) | Mahesh | human decision (no task specced on it yet; affects QA-8, FE-1) |
| ADR-0007..0009 | v2 multi-user scope · HNSW at scale · long-context embedder | Mahesh | human decision (block no Ready task) |

## Backlog (not yet specced — pm-lead grooms these)
- From the OPS-H3 review: `ExtractCleanArxivID` should match only a whole ID and support old-style IDs the crawler stores (needs a product decision); add more pinning tests; add `go test -cover` to CI (retry-sleep injection is now OPS-H6 AC6/AC7)
- From the #8 review: some code comments cite PRD sections (`§4`, `§6 Tier 1`) that now live in this repo; reword or link them (backend/ai, nit)
- From the AI-2 review + Mahesh's #11 review (ai, P2, after AI-4, same files): split the unverified log line into separate counters — sentence embed errors, missing sentence vectors, chunk embed errors, missing chunk vectors, dimension mismatches (today `sentence_embed_errors` and `chunks_without_vector` lump these); assert each counter in tests; mixed verified+unverified test (`unverified=1 citations=2`); log sentence/chunk dimension mismatch as unverified
- pm-lead docs PR now due (#11 merged): Product PRD QA-4 ◐ → ✅, drop AI-2 caveat in §8 supported row, Technical PRD §9 known-gap paragraph
- backend docs nit: `CONTRIBUTING.md:28,42,54` still say "once EVAL-1 lands" (folded into EVAL-3 AC7); AGENTS.md §2 ownership table omits `.gitignore` for backend (CI script allows it) (pm-lead rules PR)
- From Mahesh's #12 review (backend, P2, small): split `make test-py` into `test-m0` and `test-evals-data` (and two CI steps), so the eval-data tests still run when the ML stack (torch/sentence-transformers) fails to install/import; `test-py` keeps running both; update `CONTRIBUTING.md:23` + README Testing block. Not folded into EVAL-3 because it shouldn't wait for OPS-H1. (Where `evals/results` go and artifact retention: EVAL-3 AC3/AC7.)
- OPS-H8 (backend, P0 after OPS-H6's design is approved): same DLQ-loss flaw in the Python consumer — `services/common/kafka_client.py` `publish_dlq` does `flush(timeout=5)` without checking undelivered messages or a delivery callback, then `commit` runs regardless (lines 189-199); `time.sleep` retry wait. Apply OPS-H6's semantics; M4 must pass
- pm-lead docs PR: Technical PRD §8.1 L4 / §8.2 diagram caveat ("commit after DLQ" not true until OPS-H6 + OPS-H8), Product PRD OPS-1 ✅ → ◐; Proposed Product PRD row ING-8 (extraction quality measured)
- ING-8 follow-ups: detector improvements from the baseline (backend, `services/processor/`), and a pure `parse_doc_sections(doc)` seam so the scorer stops calling a private method
- FE-1 note: `ReferencesStack.jsx` shows "{score}% Verified" even when `supported=false` (after AI-2, outage shows "0.0% Verified")
- backend nits from the RET-1 review (fold into the next `search.go` change): `context.Canceled` fallback test case, `±Inf` score test
- From the AI-1 review: `/internal/rerank` bi-encoder fallback (no cross-encoder) returns uncalibrated dot products → decided in ADR-0011, done in AI-5 if accepted; aux-section match is a substring (`"Notable"` contains `"table"`) → small ai follow-up after AI-5
- pm-lead PRD docs PR: Product PRD QA-5 ✅ → ◐ (fails open during reranker outages; ADR-0011/AI-5), back to ✅ when AI-5 merges
- QA-9 Streaming answers (frontend + ai) — after QA-8
- OTLP span export to Jaeger/Tempo (backend) — Technical PRD §11 P1
- Prometheus metrics: consumer lag, DLQ depth, stage latency (backend) + OPS-6 dashboard (frontend)
- Auth + rate limiting on query API (backend) — before any shared deployment
- On-demand ingest via Kafka (backend) — depends on ADR-0004

## Repo split (2026-11-02)
All tickets, docs, reviews and agent rules moved from ArxivLens to this repo. ArxivLens PRs #3, #4, #5, #7 were closed
(agent-only content, now here); #2 and #6 were stripped to code only. See `AGENTS.md` §0.

## Environment notes (cycles 2026-11-01, 2026-11-02, 2026-11-03)
Agent sandbox egress blocked the Go 1.25 toolchain/modules, npm, Docker Hub and Hugging Face. Go, frontend and stack tasks (AI-1, OPS-H1/H2/H3/H5, ING-6, FE-1/2) were deferred, not blocked — they stay Ready. 2026-11-02: same limits (local Go 1.24.7); OPS-H3 was done anyway because CI verifies Go tests. OPS-H1 needs Docker, FE-1 needs npm to regenerate `package-lock.json`. 2026-11-03: unchanged (registry.npmjs.org and proxy.golang.org don't resolve, huggingface.co 403; re-checked in cycle 3, all four registries unreachable); no new task started because ai/backend are at WIP limit and FE-1 can't regenerate the lockfile. Cycle 4: unchanged; Docker CLI present but no daemon. Cycles 5–6: unchanged (npm, Go proxy, HF all time out; no Docker daemon).

## Done
| ID | Title | PR |
|---|---|---|
| [AI-2](tasks/AI-2.md) | Fail closed when citation support can't be verified | ArxivLens [#11](https://github.com/MaheshPulivarthi18/ArxivLens/pull/11) → 9c1229a (KAN-10) |
| [OPS-H4](tasks/OPS-H4.md) | Ignore `evals/results/` + eval-data tests in `make test-py` | ArxivLens [#12](https://github.com/MaheshPulivarthi18/ArxivLens/pull/12) → 211adbf (KAN-16) |
| [RET-1](tasks/RET-1.md) | Rerank a 20-candidate pool and sort by rerank score (ADR-0010) | ArxivLens [#9](https://github.com/MaheshPulivarthi18/ArxivLens/pull/9) → bb9ee90 (KAN-24) |
| [AI-1](tasks/AI-1.md) | Unit tests for `rag.go` filtering and citation validation | ArxivLens [#10](https://github.com/MaheshPulivarthi18/ArxivLens/pull/10) → 4702daa (KAN-9) |
| [EVAL-1](tasks/EVAL-1.md) | Versioned golden eval sets + `make eval` gate | ArxivLens [#2](https://github.com/MaheshPulivarthi18/ArxivLens/pull/2) → a959d03 (KAN-8) |
| [OPS-H3](tasks/OPS-H3.md) | Baseline Go unit tests (arXiv ID, Atom parsing, retry backoff) | ArxivLens [#6](https://github.com/MaheshPulivarthi18/ArxivLens/pull/6) → 72c82ac (KAN-15) |
| REPO-SPLIT | ArxivLens is code-only; planning moved here | ArxivLens [#8](https://github.com/MaheshPulivarthi18/ArxivLens/pull/8) → 18a3cf9 |
| [PM-1](tasks/PM-1.md) | Reconcile PRD status columns + acceptance criteria (QA PASS r2 · PM APPROVE) | ArxivLens #3 closed; content landed in arxivlens-agents' first commit (repo split, approved by Mahesh 2026-11-02) |
