# Board

Last updated: 2026-11-03 22:02 UTC by orchestrator (cycle 21:02Z: OPS-H1 human-review rework → Blocked on OPS-H5 + Mahesh Q-F1/Q-F2/Q-merge; OPS-H8 specced (KAN-34), waits on #14; no new task started)

WIP limit: 2 active PRs per developer agent (Ready to merge doesn't count; AGENTS.md §3). Order within a column = priority.

## Ready
| ID | Title | Owner | Pri | Depends on |
|---|---|---|---|---|
| [OPS-H8](tasks/OPS-H8.md) (KAN-34) | Python consumer: commit only after success or confirmed DLQ write; checked `publish`; interruptible waits; poison records to DLQ (design-required) | backend-engineer | P0 | OPS-H6 (Done); OPS-H1 (#14) merged (shares `services/common/kafka_client.py`) |
| [EVAL-3](tasks/EVAL-3.md) | GitHub Actions full-stack `make eval` (manual + nightly), results artifact, first numbers; carries RET-1 AC6 (design-required) | backend-engineer (ai pairs on design) | P1 | OPS-H1 |
| [OPS-H7](tasks/OPS-H7.md) | DLQ list/replay: offset checkpoints, paging, replay lock, idempotent replay (design-required) | backend-engineer | P1 | OPS-H6 |
| [FE-1](tasks/FE-1.md) | Frontend test harness (Vitest) + tests for answer/citation states — needs registry.npmjs.org to regenerate `package-lock.json` | frontend-engineer | P1 | — |
| [OPS-H2](tasks/OPS-H2.md) | Unify Python dependencies into one `requirements.txt` | backend-engineer | P1 | OPS-H1 |
| [ING-6](tasks/ING-6.md) | Scheduled crawler with per-category `since` watermark | backend-engineer | P1 | OPS-H3 (start after OPS-H5: both add a migration + edit `cmd/arxivlens/main.go`) |
| [FE-2](tasks/FE-2.md) | "Export all citations" (.bib) for an answer | frontend-engineer | P2 | FE-1 |

## In progress
| ID | Title | Owner | Branch |
|---|---|---|---|
| [OPS-H1](tasks/OPS-H1.md) | Workers in docker-compose + `stack.yml`. Human-review rework H1–H4 done on top of Mahesh's commits (head `e79867a`): workers healthy (heartbeat check, H2 test green), AC1–AC3 green; `make test-full` 68 passed / 3 failed (HNSW allowed + F1 M3 `/v1/ask` 10 s timeouts from about 10 s CPU rerank); rerun hit F2 (ingest timeout). **Blocked (needs OPS-H5 merged + Mahesh decision on F1/F2)**. pm-lead confirmed the design deviation (conditions 1/3 amended, 7 waived at 465 lines). Questions Q-F1/Q-F2/Q-merge for Mahesh are in the ticket Notes. OPS-H8 now depends on this PR being merged | backend-engineer | `agent/backend/OPS-H1` draft [#14](https://github.com/MaheshPulivarthi18/ArxivLens/pull/14) (KAN-13) |

## In QA
| ID | Title | Owner | PR |
|---|---|---|---|

## PM review
| ID | Title | Owner | PR |
|---|---|---|---|

## Ready to merge (raised for Mahesh)
| ID | Title | Owner | PR | Verdicts |
|---|---|---|---|---|
| [OPS-H5](tasks/OPS-H5.md) | HNSW index migration; `migrate` applies all `*.up.sql`; real-pgvector `db.yml` job; `ef_search=100`+`strict_order` | backend-engineer | [#16](https://github.com/MaheshPulivarthi18/ArxivLens/pull/16) `d442c4c` (KAN-17) | Mahesh review H1–H5 → rework · QA PASS r1, FAIL r2, PASS r3 · PM APPROVE · gates: H4/AC5 post-OPS-H1, ADR-0013, merge order with #17 |
| [EVAL-5](tasks/EVAL-5.md) | Harden retrieval eval tests + parity drift guard; Go `--model` default parsed from `main.go`; `--query-model` | ai-engineer | [#17](https://github.com/MaheshPulivarthi18/ArxivLens/pull/17) `557f4e1` (KAN-33) | Mahesh review H1–H3 → rework · QA PASS r1 · PM APPROVE · gates: G1 H3 not run (no pgvector), G2 merge order with #16 |
| [AI-4](tasks/AI-4.md) | `/v1/ask` passes trace ID to `HybridSearch` | ai-engineer | [#18](https://github.com/MaheshPulivarthi18/ArxivLens/pull/18) `7e26503` (KAN-27) | QA PASS r1 · PM APPROVE r1 |

## Blocked
| ID | Title | Owner | Waiting on |
|---|---|---|---|
| [ING-8](tasks/ING-8.md) | Measure PDF section-extraction quality (scorer/tests/docs built on `agent/ai/ING-8` `d2ad9c5`, pushed, no PR) | ai-engineer | arxiv.org access to license-check and hand-label `evals/extraction.jsonl` (AC1) and run the baseline (AC5); agent sandboxes can't reach arxiv.org (KAN-32) |
| [QA-8](tasks/QA-8.md) | LLM answer synthesis behind citation validation | ai-engineer | ADR-0001, ADR-0002 (human decision), EVAL-1, AI-1 |
| [AI-5](tasks/AI-5.md) | `/v1/ask` relevance bar when rerank scores are missing (reranker outage fails open) | ai-engineer | ADR-0011 (human decision), AI-1 merged |
| [EVAL-2](tasks/EVAL-2.md) | `/v1/search` p95 gate key in `make eval` (AC2–AC5; AC6–AC9 moved to EVAL-5) | ai-engineer | ADR-0012 (Proposed: gate now / report now, gate later / profile-aware) |
| [EVAL-4](tasks/EVAL-4.md) | Record EVAL-3's first measured numbers in `evals/BASELINE.md` | ai-engineer | EVAL-3 merged + one completed `eval.yml` run |
| ADR-0003 | Abstention policy for `/v1/ask` when all citations are unsupported / verification unavailable (question added 2026-11-03) | Mahesh | human decision (no task specced on it yet; affects QA-8, FE-1) |
| ADR-0013 | Search plan cache vs HNSW: prod uses generic plans → exact scan after 5 executions; forcing custom plans drops filtered Recall@5 to 0.76 (from OPS-H5) | Mahesh | human decision (Proposed; doesn't block #16) |
| ADR-0007..0009 | v2 multi-user scope · HNSW at scale · long-context embedder | Mahesh | human decision (block no Ready task) |

## Backlog (not yet specced — pm-lead grooms these)
- From OPS-H5 (#16) review, backend P2: migration version ledger (`schema_migrations`, apply only unapplied files; backfill 000001/000002) — Proposed ADR first; removes CONTRIBUTING's "every migration idempotent" rule
- From OPS-H5, backend P2: README prerequisite "pgvector ≥ 0.8.0" + pin `pgvector/pgvector` tag in compose and `db.yml` after OPS-H1 merges; `TestHNSWVectorHits` seeds into a scratch schema / skips when `papers` non-empty
- From OPS-H5 F2, ai P1: `scripts/evaluate_retrieval.py` applies `hnswSearchSettings` and reports both plan regimes (input for ADR-0013)
- After OPS-H1 merges: file its first green `stack.yml` run as OPS-H5 H4/AC5 evidence in `agents/reviews/OPS-H5/`
- From EVAL-5 (#17), backend P2 after #16 merges: `db.yml` step installs psycopg and runs `pytest tests/test_evals_data.py -k real_postgres` (closes #17 gate G1/H3)
- From EVAL-5, backend P2 (needs Proposed ADR, HTTP API): query service reports its runtime `--model` (`/healthz` or `/v1/info`); eval reads it instead of `--query-model`
- From EVAL-5, ai P2: `CHUNK_COUNTS_SQL` groups by `arxiv_id` but `papers` is unique on `(arxiv_id, version)` — scope to latest version; P3: README note that default `--query-model` needs a full checkout, PEP 8 spacing, `BM25_SQL` drift guard
- Merge order #16 ↔ #17: whichever merges second must be rebased and CI re-run; if #16 first, ai updates #17's drift guard to read `hybridSearchSQL`
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
- FE-1 note: `ReferencesStack.jsx` shows "{score}% Verified" even when `supported=false` (after AI-2, outage shows "0.0% Verified")
- backend nits from the RET-1 review (fold into the next `search.go` change): `context.Canceled` fallback test case, `±Inf` score test
- From the AI-1 review: `/internal/rerank` bi-encoder fallback (no cross-encoder) returns uncalibrated dot products → decided in ADR-0011, done in AI-5 if accepted; aux-section match is a substring (`"Notable"` contains `"table"`) → small ai follow-up after AI-5
- pm-lead PRD docs PR: Product PRD QA-5 ✅ → ◐ (fails open during reranker outages; ADR-0011/AI-5), back to ✅ when AI-5 merges
- QA-9 Streaming answers (frontend + ai) — after QA-8
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

## Environment notes (cycles 2026-11-01, 2026-11-02, 2026-11-03)
Agent sandbox egress blocked the Go 1.25 toolchain/modules, npm, Docker Hub and Hugging Face. Go, frontend and stack tasks (AI-1, OPS-H1/H2/H3/H5, ING-6, FE-1/2) were deferred, not blocked — they stay Ready. 2026-11-02: same limits (local Go 1.24.7); OPS-H3 was done anyway because CI verifies Go tests. OPS-H1 needs Docker, FE-1 needs npm to regenerate `package-lock.json`. 2026-11-03: unchanged (registry.npmjs.org and proxy.golang.org don't resolve, huggingface.co 403; re-checked in cycle 3, all four registries unreachable); no new task started because ai/backend are at WIP limit and FE-1 can't regenerate the lockfile. Cycle 4: unchanged; Docker CLI present but no daemon. Cycles 5–6: unchanged (npm, Go proxy, HF all time out; no Docker daemon). Cycle 14:00: also PyPI and arxiv.org unreachable; Go verified in CI, full stack via the new `stack.yml` on GitHub runners (OPS-H1).

## Done
| ID | Title | PR |
|---|---|---|
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
