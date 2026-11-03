# Board

Last updated: 2026-11-03 by pm-lead (RET-1 PM APPROVE r1, PR #9 raised; EVAL-2 AC10 added)

WIP limit: 1 open PR per engineering agent. Order within a column = priority.

## Ready
| ID | Title | Owner | Pri | Depends on |
|---|---|---|---|---|
| [OPS-H1](tasks/OPS-H1.md) | Run processor + embedder workers in docker-compose; one-command full test | backend-engineer | P0 | — |
| [FE-1](tasks/FE-1.md) | Frontend test harness (Vitest) + tests for answer/citation states | frontend-engineer | P1 | — |
| [AI-1](tasks/AI-1.md) | Unit tests for `rag.go` filtering and citation validation (no infra) | ai-engineer | P1 | — |
| [OPS-H5](tasks/OPS-H5.md) | Migration for HNSW index + `migrate` applies all migrations | backend-engineer | P1 | — (soft: OPS-H1) |
| [OPS-H2](tasks/OPS-H2.md) | Unify Python dependencies into one `requirements.txt` | backend-engineer | P1 | OPS-H1 |
| [ING-6](tasks/ING-6.md) | Scheduled crawler with per-category `since` watermark | backend-engineer | P1 | OPS-H3 |
| [FE-2](tasks/FE-2.md) | "Export all citations" (.bib) for an answer | frontend-engineer | P2 | FE-1 |
| [OPS-H4](tasks/OPS-H4.md) | `.gitignore` evals/results + run eval data tests in `make test-unit` | backend-engineer | P1 | EVAL-1 |
| [AI-2](tasks/AI-2.md) | Fail closed when support-check embedding fails in `rag.go` | ai-engineer | P1 | AI-1 |
| [AI-3](tasks/AI-3.md) | Batch embedding in RAG validation | ai-engineer | P1 | AI-1, AI-2 |
| [EVAL-2](tasks/EVAL-2.md) | `/v1/search` p95 gate + eval-test hardening (EVAL-1 QA r3 nits, AC6–AC9) + RET-1 p95/eval measurement (AC10) | ai-engineer | P2 | EVAL-1 (AC10: RET-1 merged + infra) |

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
| [RET-1](tasks/RET-1.md) | Rerank a 20-candidate pool and sort by rerank score (ADR-0010), `831905e`. **Merge after #2.** | backend-engineer | [#9](https://github.com/MaheshPulivarthi18/ArxivLens/pull/9) (ready for review) | QA PASS r1 · PM APPROVE r1 ([report](reviews/RET-1/report.md)) |

## Blocked
| ID | Title | Owner | Waiting on |
|---|---|---|---|
| [QA-8](tasks/QA-8.md) | LLM answer synthesis behind citation validation | ai-engineer | ADR-0001, ADR-0002 (human decision), EVAL-1, AI-1 |
| [AI-4](tasks/AI-4.md) | `/v1/ask` passes trace ID to `HybridSearch`; harden ADR-0010 parity guard | ai-engineer | RET-1, EVAL-1 merged |
| ADR-0007..0009 | v2 multi-user scope · HNSW at scale · long-context embedder | Mahesh | human decision (block no Ready task) |

## Backlog (not yet specced — pm-lead grooms these)
- From the OPS-H3 review: `ExtractCleanArxivID` should match only a whole ID and support old-style IDs the crawler stores (needs a product decision); add more pinning tests; add `go test -cover` to CI; make the retry sleep injectable (see OPS-H3 Notes)
- From the #8 review: some code comments cite PRD sections (`§4`, `§6 Tier 1`) that now live in this repo; reword or link them (backend/ai, nit)
- pm-lead docs PR after PR #2 merges: Product PRD §8 rows 156–157 (ADR-0006 Accepted, paper-level; drop the bi-encoder caveat; add the RET-1 caveat **only if #9 hasn't merged by then**), line 151 fallback note, the AGENTS.md §5 eval gotcha
- pm-lead rules PR after PR #9 merges: drop the AGENTS.md §6 gotcha "`/v1/ask` does not yet sort by rerank score (ADR-0010, RET-1)"; merge the §7.1 diagram docs PR [arxivlens-agents#2](https://github.com/MaheshPulivarthi18/arxivlens-agents/pull/2)
- backend nits from the RET-1 review (fold into the next `search.go` change): `context.Canceled` fallback test case, `±Inf` score test
- QA-9 Streaming answers (frontend + ai) — after QA-8
- OTLP span export to Jaeger/Tempo (backend) — Technical PRD §11 P1
- Prometheus metrics: consumer lag, DLQ depth, stage latency (backend) + OPS-6 dashboard (frontend)
- Auth + rate limiting on query API (backend) — before any shared deployment
- On-demand ingest via Kafka (backend) — depends on ADR-0004

## Repo split (2026-11-02)
All tickets, docs, reviews and agent rules moved from ArxivLens to this repo. ArxivLens PRs #3, #4, #5, #7 were closed
(agent-only content, now here); #2 and #6 were stripped to code only. See `AGENTS.md` §0.

## Environment notes (cycles 2026-11-01, 2026-11-02, 2026-11-03)
Agent sandbox egress blocked the Go 1.25 toolchain/modules, npm, Docker Hub and Hugging Face. Go, frontend and stack tasks (AI-1, OPS-H1/H2/H3/H5, ING-6, FE-1/2) were deferred, not blocked — they stay Ready. 2026-11-02: same limits (local Go 1.24.7); OPS-H3 was done anyway because CI verifies Go tests. OPS-H1 needs Docker, FE-1 needs npm to regenerate `package-lock.json`. 2026-11-03: unchanged (registry.npmjs.org and proxy.golang.org don't resolve, huggingface.co 403); no new task started because ai/backend are at WIP limit and FE-1 can't regenerate the lockfile.

## Done
| ID | Title | PR |
|---|---|---|
| [EVAL-1](tasks/EVAL-1.md) | Versioned golden eval sets + `make eval` gate | ArxivLens [#2](https://github.com/MaheshPulivarthi18/ArxivLens/pull/2) → a959d03 (KAN-8) |
| [OPS-H3](tasks/OPS-H3.md) | Baseline Go unit tests (arXiv ID, Atom parsing, retry backoff) | ArxivLens [#6](https://github.com/MaheshPulivarthi18/ArxivLens/pull/6) → 72c82ac (KAN-15) |
| REPO-SPLIT | ArxivLens is code-only; planning moved here | ArxivLens [#8](https://github.com/MaheshPulivarthi18/ArxivLens/pull/8) → 18a3cf9 |
| [PM-1](tasks/PM-1.md) | Reconcile PRD status columns + acceptance criteria (QA PASS r2 · PM APPROVE) | ArxivLens #3 closed; content landed in arxivlens-agents' first commit (repo split, approved by Mahesh 2026-11-02) |
