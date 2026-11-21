# EVAL-8 evidence: local real-LLM baseline

**Source:** Mahesh's own `make eval` run on 2026-11-21 21:27Z, pasted into orchestrator session `session_01ATEBeRawKzi1RDhbRiuzYB`. Results file `evals/results/20261121T212749Z.json` (git-ignored in the app repo) is committed here as [`baseline-local-20261121T212749Z.json`](baseline-local-20261121T212749Z.json). The values are as pasted; the orchestrator only reformatted the whitespace.

**Setup (reported by Mahesh, not recorded in the JSON):** Apple MacBook Air M4 (embedder `device=mps`), Ollama `0.40.16`, model `qwen2.5:3b-instruct` ID `357c53fb659c`, `LLM_BASE_URL=http://localhost:11434/v1`. The JSON does not record which LLM ran. The full-answer latencies (6–19 s per answered case) show that real synthesis ran. EVAL-8a should add the model name and digest to the results JSON.

**Gate: PASS.**

| Metric | Value | Gate |
|---|---|---|
| recall@5 (Hybrid RRF + Rerank) | 0.9850 | ≥ 0.8 |
| supported_citation_rate | 1.0000 (44 citations) | ≥ 0.9 |
| correct_refusal_rate | 1.0000 (22) | ≥ 0.95 |
| ask_p95_ms (quick stage) | 2423 | < 3000 |
| ask_errors | 0 | == 0 |
| expected_paper_hit_rate | 1.0000 (22) | info |
| ask_full_p95_ms | 16786 | report-only |
| citation_coverage | 1.0000 | report-only |
| near_miss_correct_refusal_rate | 0.9333 (15; `n003` answered) | report-only |

**Observations for pm-lead / ai-engineer (not yet triaged):**

1. **`n003` near-miss was answered.** One of its three citations is unsupported (chunk 239, score 0.055), but the answer still shipped. Under ADR-0003, check whether that unsupported claim reached the user.
2. **Duplicate citations.** `a001` cites chunk 98 / marker 2 three times, and `a020` cites chunk 1680 / marker 1 twice. Check whether claims or citations need de-duplication.
3. **Full-answer latency.** p95 is 16.8 s on the M4, against the 3 s budget in ADR-0001. That metric is report-only today, but it is the real user wait for a full answer.

**Direction (Mahesh, 2026-11-21):** run this same model in CI on Modal (Ollama `0.40.16`, `qwen2.5:3b-instruct` @ `357c53fb659c`), behind a bearer-token proxy. The Modal numbers will be compared with this file. The ADR and the EVAL-8a/8b specs are still to be drafted.
