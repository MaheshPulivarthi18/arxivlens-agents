# Board

Last updated: 2026-11-07 by pm-lead (plan from the 2026-11-07 external review: 15 tasks in 3 waves; ADR-0001/0002/0003 Accepted `51d8ff5`; ADR-0014 Proposed)

WIP limit: 2 active PRs per developer agent (Ready to merge doesn't count; AGENTS.md §3). Order within a column = priority.
Wave 1 = independent now. Wave 2/3 = start after the named dependency is **merged** (or, where it says "slot", when the owner's WIP slot frees).
`rag.go` order (one file, one owner): AI-7 → AI-6 → QA-8 → AI-8.

## Ready — the 2026-11-07 plan, in execution order
| # | ID | Title | Owner | Pri | Depends on | Wave | Note |
|---|---|---|---|---|---|---|---|
| 1 | [LLM-1](tasks/LLM-1.md) | `internal/llm`: provider interface, OpenAI-compatible client, `llmtest` fake (design-required) | backend-engineer | P0 | ADR-0001/0002 (Accepted) | 1 | New dir only; Go verified in CI; no key needed |
| 2 | [EVAL-3](tasks/EVAL-3.md) | Full-stack `make eval` in GitHub Actions + first numbers (design-required) | backend-engineer | P1 | OPS-H1 (merged) | 1 | Docker + arXiv seeding only on GitHub runners; README line moved to EVAL-4 |
| 3 | [AI-7](tasks/AI-7.md) | ADR-0003 refusal with evidence + `refusal_reason` (design-required, short) | ai-engineer | P0 | ADR-0003 (Accepted); **merge after EVAL-6** | 1 | First in the `rag.go` chain |
| 4 | [EVAL-6](tasks/EVAL-6.md) | Answer eval: ADR-0003 classification, report-only citation coverage, near-miss refusal set | ai-engineer | P1 | — | 1 | Python stdlib tests run locally; no gate change |
| 5 | [FE-1](tasks/FE-1.md) (KAN-19) | Vitest harness + answer/citation state tests | frontend-engineer | P1 | — | 1 | **Env-blocked:** registry.npmjs.org; needs Mahesh (allow the host, or push the lockfile) |
| 6 | [AI-6](tasks/AI-6.md) | Context selection, token budget, prompt, structured-output parser (writes `docs/design/QA-8.md`) | ai-engineer | P0 | AI-7 merged | 2 | Pure functions, `Ask` unchanged |
| 7 | [OPS-H8](tasks/OPS-H8.md) (KAN-34) | Python consumer: commit after success or confirmed DLQ (design-required) | backend-engineer | P0 | OPS-H1 (merged); backend slot | 2 | Swap with EVAL-3 if Mahesh wants data-loss fix first |
| 8 | [AI-9](tasks/AI-9.md) | CPU rerank latency without changing scores (F1) | ai-engineer | P1 | ai slot | 2 | Timings only from `stack.yml` (HF blocked in sandbox) |
| 9 | [FE-3](tasks/FE-3.md) | Refusal-with-evidence UI; no "Verified" on unchecked citations (design-required) | frontend-engineer | P0 | FE-1, AI-7 merged | 2 | |
| 10 | [RET-2](tasks/RET-2.md) | `SearchHit` carries paper version + page (design-required) | backend-engineer | P1 | **ADR-0014 Accepted**, AI-7 + EVAL-6 merged | 2 | Blocked until Mahesh decides ADR-0014 |
| 11 | [QA-8](tasks/QA-8.md) (KAN-7) | LLM synthesis in `/v1/ask` via provider, template fallback (design addendum) | ai-engineer | P0 | LLM-1, AI-6 merged | 3 | Fake provider in tests; real-LLM numbers are EVAL-8 |
| 12 | [EVAL-7](tasks/EVAL-7.md) | Blind human-review sheet → citation precision, claim correctness | ai-engineer | P1 | EVAL-6 merged | 3 | Judging is Mahesh's, not an agent's |
| 13 | [AI-8](tasks/AI-8.md) | Claims + provenance (version, chunk, section, page, quote, status) (design-required) | ai-engineer | P0 | **ADR-0014**, QA-8, RET-2 merged | 3 | |
| 14 | [FE-4](tasks/FE-4.md) | Claim evidence panel, quote highlight, PDF page link (design-required) | frontend-engineer | P0 | **ADR-0014**, AI-8, FE-3 merged | 3 | |
| 15 | [OPS-H9](tasks/OPS-H9.md) | CI trust: `real_postgres` step, pgvector ≥ 0.8 pin, MinIO digest check | backend-engineer | P2 | EVAL-3 merged; no open README PR | 3 | |

## Ready — not in this plan (lower priority; start only with a free slot and no file overlap)
| ID | Title | Owner | Pri | Depends on |
|---|---|---|---|---|
| [OPS-H7](tasks/OPS-H7.md) | DLQ list/replay: offset checkpoints, paging, replay lock, idempotent replay (design-required) | backend-engineer | P1 | OPS-H6 (Done) |
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

## Blocked
| ID | Title | Owner | Waiting on |
|---|---|---|---|
| ADR-0014 | Claim-level evidence + citation provenance fields in `/v1/ask` / `/v1/search` (Proposed 2026-11-07) | Mahesh | human decision; blocks RET-2, AI-8, FE-4 |
| [EVAL-8](tasks/EVAL-8.md) | First answer eval with a real LLM (carries QA-8's old AC3) | backend + ai | Mahesh: model + where it runs; cost cap (ADR-0001) for a hosted model; then QA-8, EVAL-3, EVAL-6 merged |
| [ING-8](tasks/ING-8.md) | Measure PDF section-extraction quality (scorer/tests/docs built on `agent/ai/ING-8` `d2ad9c5`, pushed, no PR) | ai-engineer | arxiv.org access to license-check and hand-label `evals/extraction.jsonl` (AC1) and run the baseline (AC5) (KAN-32) |
| [AI-5](tasks/AI-5.md) | `/v1/ask` relevance bar when rerank scores are missing (reranker outage fails open) | ai-engineer | ADR-0011 (human decision); also `rag.go`, so it queues behind the plan's `rag.go` chain |
| [EVAL-2](tasks/EVAL-2.md) | `/v1/search` p95 gate key in `make eval` | ai-engineer | ADR-0012 (Proposed) |
| [EVAL-4](tasks/EVAL-4.md) | Record EVAL-3's first numbers in `evals/BASELINE.md` (+ README Testing line) | ai-engineer | EVAL-3 merged + one completed `eval.yml` run |
| ADR-0013 | Search plan cache vs HNSW (generic plans → exact scan) | Mahesh | human decision |
| ADR-0007..0009 | v2 multi-user scope · HNSW at scale · long-context embedder | Mahesh | human decision (block no Ready task) |

## Backlog (not yet specced — pm-lead grooms these)
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
- After AI-9 merges (backend, small): drop the "Known failure F1" step and `F1_TESTS` deselection in `stack.yml`
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
- From the AI-2 review + Mahesh's #11 review (ai, P2, after AI-4, same files): split the unverified log line into separate counters — sentence embed errors, missing sentence vectors, chunk embed errors, missing chunk vectors, dimension mismatches (today `sentence_embed_errors` and `chunks_without_vector` lump these); assert each counter in tests; mixed verified+unverified test (`unverified=1 citations=2`); a correct-length batch with one empty slot (AI-3 QA optional test); log sentence/chunk dimension mismatch as unverified
- pm-lead docs PR now due (#11 merged): Product PRD QA-4 ◐ → ✅, drop AI-2 caveat in §8 supported row, Technical PRD §9 known-gap paragraph
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
- OTLP span export to Jaeger/Tempo (backend) — Technical PRD §11 P1
- Prometheus metrics: consumer lag, DLQ depth, stage latency (backend) + OPS-6 dashboard (frontend)
- Auth + rate limiting on query API (backend) — before any shared deployment
- On-demand ingest via Kafka (backend) — depends on ADR-0004
- From the OPS-H1 design (backend, P1, Technical PRD §9 politeness): Go downloader has no rate limiter (PDFs can be < 3 s apart), and the query-service ingester sends no User-Agent on its Atom call, a non-identifying `ArxivLens-Bot/1.0` on its PDF call, and doesn't wait between them. Fix: a shared 3 s limiter plus the crawler's identifying UA on every arXiv request
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
