# Board

Last updated: 2026-11-28 by pm-lead (process reset approved by Mahesh: bundles, no follow-up tickets, on-demand cycles;
rules PR arxivlens-agents #21, docs PR #22). App `main` = `5fcbd5f`; no open agent PRs in ArxivLens.
The old per-task board (2026-11-27 and earlier) is in `git log -p agents/board.md`.

Rules: one ticket = one coherent outcome = one PR (~800 lines max). Findings go back into the same PR or onto the
ticket's `## Checklist`, never into new tickets. WIP: 2 active PRs per developer (AGENTS.md §3).

## Active
| # | Bundle | Outcome | Owner | Tier | Size | Branch | Status |
|---|---|---|---|---|---|---|---|
| 1 | [B-UI](tasks/B-UI.md) | Quote highlighted in its passage, `arXiv:IDvN · § · p. N`, PDF at the page, "Cited by claim n" rows, `.bib` export | frontend-engineer | Large (FE-4 design + export addendum) | ~520 | `agent/frontend/B-UI` | In Progress (design approved) |
| 2 | [B-PIPE](tasks/B-PIPE.md) | DLQ replay resumes from checkpoints, is locked against a second run, deterministic IDs; list footer polish; `crawl` politeness; harness lines | backend-engineer | Large (OPS-H7 design) | ~880 (seam: C → B-PIPE-2 if > 950) | `agent/backend/B-PIPE` | #133 (B-PIPE-1) **Ready to merge** (merge first); #134 (B-PIPE-2, stacked) in rework r1 |
| 3 | [B-QUAL](tasks/B-QUAL.md) | `/v1/search` p50/p95 in every eval (report-only, ADR-0012); section-extraction scorer (from `d2ad9c5`) | ai-engineer | Large (short design) | ~920 (754 carried; one PR, cap waived) | `agent/ai/B-QUAL` | In Progress (design approved) |
| 4 | [EVAL-8](tasks/EVAL-8.md) | Real-LLM answer eval in CI on Modal | **Mahesh** | Large (ADR-0021) | his call | — | Mahesh building (2026-11-29) |

The three agent bundles are independent: their files don't overlap (B-PIPE's `Makefile` line is a wildcard, so B-QUAL
can merge before or after it). B-UI's addendum and B-QUAL's design were approved 2026-11-28.

## Decisions for Mahesh
| Decision | Question | Unblocks |
|---|---|---|
| [ADR-0021](../docs/adr/0021-real-llm-ci-eval-gate.md) (KAN-127) | Real-LLM eval in CI: which runs (A–C), could-not-run rules R1–R4, PR replay (P1–P3), monthly budget | EVAL-8 (you build it) |
| [ADR-0011](../docs/adr/0011-ask-relevance-bar-without-rerank.md) (KAN-26) | When no rerank score exists (reranker outage), should `/v1/ask` refuse, use an RRF bar, or keep answering from ~20 unchecked hits as today? | [AI-5](tasks/AI-5.md) (KAN-25) |
| [ADR-0012](../docs/adr/0012-search-p95-gate.md) | Gate `/v1/search` p95 ≤ 1500 ms (any machine / GPU only), or keep it report-only? B-QUAL reports it either way | the gate key (a few lines, no ticket) |
| [ADR-0018](../docs/adr/0018-two-stage-ask-and-answer-kind.md) | Accept the two-stage `/v1/ask` shape (`quick`, `answer_kind`, `insufficient_evidence`) as built in #46 | nothing blocked; makes the contract final |
| [ADR-0004](../docs/adr/0004-on-demand-ingest-path.md) | Should on-demand ingest go through Kafka (same idempotency/DLQ) instead of running synchronously? | backlog item |
| [ADR-0005](../docs/adr/0005-default-crawl-categories.md) | Default `crawl-loop` categories | nothing (they're configurable) |
| [ADR-0013](../docs/adr/0013-search-plan-cache-and-hnsw.md), [0007](../docs/adr/0007-multi-user-hosted-v2-scope.md)–[0009](../docs/adr/0009-long-context-embedding-model.md) | Plan cache vs HNSW; v2 multi-user scope; HNSW at scale; long-context embedder | nothing now |
| arxivlens-agents #22 | Confirm ADR-0022/0023/0024 as "Accepted (Mahesh, implemented in #44/#46)" and ADR-0015 Superseded | docs truth |
| arxivlens-agents #21 | The lean-process rules | the next cycle's process |
| ING-8 hand labels | Label ~10 CC-licensed papers' headings (or name someone), or merge the scorer without a baseline? | B-QUAL AC5 baseline |
| FE-3 design Q3/Q6 | Show a full-stage `insufficient_evidence` (the writer says the passages don't answer) under the quoted answer, and offer "Search arXiv & Index"? | nothing (today: hidden) |
| Citation authors/year (new scope) | Add `authors` and the published year to `/v1/ask` citations (an HTTP-contract change, so an ADR) so the `.bib` export has authors? | B-UI export has no `author` until then |
| "Appendices" aux section | Should a section titled "Appendices" count as auxiliary? Only the `appendix` substring matches today | a small `rag.go` change |
| Near-miss review (EVAL-6) | Review the 15 rows of `evals/refusal_near_miss.jsonl` (`n005`, `n009` first) | `reviewed_by` values |

## Done (merge ranges)
| ArxivLens PRs | Merged | What |
|---|---|---|
| #122–#130 | 2026-11-27/28 | LLM provenance in eval results (EVAL-8c), prefetch fixes (OPS-H21), `crawl-loop` + lock (ING-6c, completes ING-6), embedder content-hash save (AI-13), processor chunk-row lock (OPS-H6f), claims list + marker focus (FE-4a), aux-section word boundary (AI-14b), form-control outline guard (FE-0j/0k) |
| #113–#121 | 2026-11-21/22 | ADR-0019 verified-only written citations + quick-stage gate, ADR-0020 fp16 reranker, eval fail-closed shapes, harness timeouts, rerank/verify concurrency tests |
| #85–#112 | 2026-11-20/21 | Citation status chips + refusal panel (FE-3a/3b), theme + primitives (FE-0b–0i), DLQ list/inspect CLI (OPS-H7a2/a2b), reprocess drops stale vectors (OPS-H6d/6e), CI `-race`, Python light/ML split, arXiv limiter tests |
| #51–#84 | 2026-11-19/20 | `/v1/ask` citation status/provenance + `claims[]` (AI-8a/8b), pages (ING-11b), crawl watermarks + loop (ING-6a/6b), DLQ reader (OPS-H7a), Vitest + research theme (FE-1, FE-0), real-Postgres CI, first eval baseline (EVAL-4) |
| ≤ #50 | 2026-11-02 … 11-15 | RRF + rerank, refusals, retry/DLQ, compose stack (OPS-H1), eval gate (EVAL-1/3), Mahesh's #43/#44/#46/#47 (GPU reranker, NLI verification, quoted answers, LLM synthesis, GPU reference profile) |

## Backlog (not ticketed; becomes a bundle only when Mahesh agrees)
- From the Technical PRD §11 roadmap: OTLP span export (P1); Prometheus metrics + OPS-6 dashboard (P2); auth + rate limiting on the query API, needed before any shared deployment (P2); streaming answers QA-9 (P2); saved questions (rest of UI-5).
- Deferred in the reset (2026-11-28): OPS-H6g lock-strength pins; ING-6d compose `crawler` profile; ING-6e late-announcement lookback; OPS-H22 prefetch classification pins; the small test/style follow-ups listed on the old board.
- Ideas that need an ADR first: a migration version ledger (`schema_migrations`); the query service reporting its runtime `--model`; an upper bound on `max_citations`; deduping v1/v2 near-duplicate chunks in search (product rule).
