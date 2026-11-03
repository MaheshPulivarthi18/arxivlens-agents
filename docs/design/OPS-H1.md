# Tech design — OPS-H1: Run processor + embedder workers in docker-compose; one-command full test

**Author:** backend-engineer · **Ticket:** `agents/tasks/OPS-H1.md` · **PRD:** Technical PRD §11 "Containerize processor + embedder in compose" (P0); Technical PRD §9 "External politeness"; app README Known limitations · **Status:** Draft

Studied at ArxivLens `origin/main` 9c1229a. Code paths are relative to the app repo.

## Problem
To run `make test-full` today, someone has to start the processor worker, the embedder worker and the embedder API by hand
on the host. That's why no agent can verify pipeline or query changes end to end. This task adds the three Python
processes to `docker-compose.yml` behind a `workers` profile, so plain `docker compose up -d` still starts infra only
(AC1), and adds `make stack-up`, which starts the whole stack with one command and waits until it is healthy (AC2). A new
`.github/workflows/stack.yml` brings the stack up on a GitHub runner, crawls 2 papers to `embedded` (AC3) and runs
`make test-full` (AC4). Agent sandboxes have no Docker daemon, so this workflow is the only way to prove AC1–AC4. Docs
change as described in AC5. The workflow runs on its own PR, and the diff stays under 400 lines (AC6).

## Approach

### Files
| File | Change | ~lines |
|---|---|---|
| `docker-compose.yml` | Three services under `profiles: [workers]`, one named volume `hf_cache`, an `x-worker` YAML anchor for the shared env. Infra services stay byte-for-byte the same. | +75 |
| `services/processor/Dockerfile`, `services/embedder/Dockerfile` | `ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu` + `--extra-index-url ${TORCH_INDEX_URL}` on the pip line (CPU torch, same as `ci.yml`). Nothing else changes, CMD included. | +4 |
| `Makefile` | `stack-up`, `stack-down`, `STACK_TIMEOUT ?= 900`; `setup-py` also installs `opentelemetry-sdk` (see Data needs, D4); `test-full` help text. | +20 |
| `.github/workflows/stack.yml` (new) | Full-stack job (below). | +150 |
| `README.md` | Quick start `:84-143`, Testing `:196-218`, Known limitations `:227-230`. **`:39` untouched (OPS-H6).** | +30 / −10 |
| `CONTRIBUTING.md` | Commands table `:27` (`make test-full` row), new `make stack-up` / `make stack-down` rows, a `stack.yml` row, and the Python services line `:31`. **`:50-60` untouched (OPS-H6).** | +6 / −2 |

Estimated total is about 300 changed lines. No change to `internal/`, `cmd/`, `services/**/*.py`, `tests/`, `ci.yml` or any shared
contract. I checked `services/common/config.py`: it reads `DATABASE_URL`, `KAFKA_BROKERS`, `MINIO_ENDPOINT` (plus key, secret,
bucket and `EMBEDDING_MODEL`, all with defaults), so containers only need env vars and no Python change.

### 1. Compose services (design item 1)

```yaml
x-worker: &worker
  profiles: [workers]
  restart: unless-stopped
  environment:
    DATABASE_URL: postgresql://postgres:postgres@postgres:5432/arxivlens
    KAFKA_BROKERS: kafka:9092            # INTERNAL listener, advertised as kafka:9092
    MINIO_ENDPOINT: minio:9000
    HF_HOME: /root/.cache/huggingface
  volumes:
    - ${ARXIVLENS_HF_CACHE:-hf_cache}:/root/.cache/huggingface

services:
  # postgres, kafka, kafka-init, minio, minio-init: unchanged (no profile → always started)

  embedder-api:
    <<: *worker
    build: { context: ., dockerfile: services/embedder/Dockerfile, args: { TORCH_INDEX_URL: "${TORCH_INDEX_URL:-https://download.pytorch.org/whl/cpu}" } }
    container_name: arxivlens-embedder-api
    command: ["python", "services/embedder/api.py"]
    ports: ["8081:8081"]
    depends_on:
      postgres:   { condition: service_healthy }
      kafka-init: { condition: service_completed_successfully }
      minio-init: { condition: service_completed_successfully }
    healthcheck:   # 200 only after the startup hook loaded BGE; also require the cross-encoder (M3 + EVAL-3 need it)
      test: ["CMD-SHELL", "curl -fsS http://localhost:8081/healthz | grep -q '\"reranker\":true'"]
      interval: 10s
      timeout: 5s
      retries: 6
      start_period: 600s   # cold local start downloads ~1.5 GB of models

  processor:
    <<: *worker
    build: { context: ., dockerfile: services/processor/Dockerfile, args: { TORCH_INDEX_URL: ... } }
    container_name: arxivlens-processor
    depends_on:
      embedder-api: { condition: service_healthy }   # models are in hf_cache before the workers load them
    healthcheck: { test: [CMD, python, -c, "<group check, processor-v1>"], interval: 10s, timeout: 15s, retries: 6, start_period: 300s }

  embedder-worker:
    <<: *worker
    build: { context: ., dockerfile: services/embedder/Dockerfile, args: { TORCH_INDEX_URL: ... } }   # identical build → BuildKit cache hit
    container_name: arxivlens-embedder-worker
    depends_on:
      embedder-api: { condition: service_healthy }
    healthcheck: { test: [CMD, python, -c, "<group check, embedder-v1>"], ... }

volumes:
  postgres_data:
  kafka_data:
  minio_data:
  hf_cache:
```

- **Worker healthcheck.** The workers have no HTTP port, and the Python code must not change, so the check asks
  Kafka whether the worker's consumer group is up. It's an inline `confluent_kafka.admin.AdminClient(...).describe_consumer_groups([g])`
  that exits 0 when the state is `STABLE` and the group has at least one member. Both workers load their model **before**
  they subscribe (`ProcessorWorker()` / `EmbedderWorker()` are built before `ServiceKafkaConsumer`), so a member in the group
  means the model is loaded and the worker is consuming. Limitation, documented in a compose comment: the check is per group,
  not per container, so a host-run worker in the same group would also make it pass. Fallback if the AdminClient API
  differs in the installed `confluent-kafka` (I'll verify on the first CI run): `kill -0 1`, which only checks the process is alive. If I switch to it, I'll record that here.
- **Startup order.** `postgres` and the two init jobs come first, then `embedder-api` (it downloads both models into `hf_cache`
  exactly once), then the two workers. They load from the cache, so concurrent first downloads can't race. The schema is
  **not** a startup dependency: the workers only touch tables when a message arrives, and `make migrate` runs from the host after `stack-up`.
- **HF cache.** By default this is a named volume `hf_cache`, so models download once per machine. Set `ARXIVLENS_HF_CACHE`
  to an absolute host path and it becomes a bind mount instead. CI uses that to share the host's `~/.cache/huggingface`
  (restored by `actions/cache`) with the containers.
- **Ports.** Only `embedder-api` publishes a port (8081), so the host-run Go query service keeps using its default
  `--embedder-url http://localhost:8081`. The workers publish none.
- **CPU torch.** The Dockerfiles get the CPU wheel index by default. Without it, pip pulls CUDA torch plus the nvidia-* wheels
  (about 4 GB more per image), which would be slow and tight on a runner's disk. GPU passthrough is out of scope: README gets a note that
  `TORCH_INDEX_URL=https://download.pytorch.org/whl/cu121 make stack-up` plus a `deploy.resources.reservations.devices`
  override is the untested path, and that Apple-silicon MPS needs the host-run workers, because Docker on macOS has no MPS.

### 2. Makefile

```make
STACK_TIMEOUT ?= 900   # seconds
STACK_WORKERS := arxivlens-embedder-api arxivlens-processor arxivlens-embedder-worker

stack-up: ## Infra + processor, embedder worker, embedder API (:8081); blocks until healthy (STACK_TIMEOUT s)
	docker compose --profile workers up -d --build
	@end=$$(( $$(date +%s) + $(STACK_TIMEOUT) )); for c in $(STACK_WORKERS); do \
	  until [ "$$(docker inspect -f '{{.State.Health.Status}}' $$c 2>/dev/null)" = healthy ]; do \
	    if [ $$(date +%s) -ge $$end ]; then echo "stack-up: $$c not healthy after $(STACK_TIMEOUT)s"; \
	      docker compose --profile workers ps -a; docker compose --profile workers logs --tail 50 $$c; exit 1; fi; sleep 5; \
	  done; echo "stack-up: $$c healthy"; done
	docker compose --profile workers ps

stack-down: ## Stop infra + workers (keeps volumes)
	docker compose --profile workers down
```

- The target is non-interactive and exits non-zero on timeout, so EVAL-3 can call it (PM note).
- I use an explicit wait loop instead of `up --wait`, because `--wait` reports the one-shot `kafka-init` / `minio-init`
  containers (exit 0) as failures on some Compose v2 versions. The loop behaves the same on every version.
- `infra-up` / `infra-down` don't change, and `make migrate` stays the way to apply the schema. Using it instead of a hard-coded
  `./bin/arxivlens migrate` means OPS-H5's "apply every migration" fix applies here with no edit.

### 3. `.github/workflows/stack.yml` (design item 2)

```yaml
name: Full stack
on:
  workflow_dispatch:
  pull_request:
    paths: [docker-compose.yml, "services/*/Dockerfile", "requirements*.txt", Makefile, .github/workflows/stack.yml]
permissions: { contents: read }
concurrency: { group: stack-${{ github.ref }}, cancel-in-progress: true }   # never two runs crawling arXiv for one ref
jobs:
  stack:
    runs-on: ubuntu-latest          # 4 vCPU, 16 GB, CPU only
    timeout-minutes: 45
    env:
      ARXIVLENS_HF_CACHE: /home/runner/.cache/huggingface
      PIP_EXTRA_INDEX_URL: https://download.pytorch.org/whl/cpu
```

| # | Step | Detail | Step timeout |
|---|---|---|---|
| 1 | checkout, `setup-go` (`go-version-file: go.mod`, built-in module/build cache), `setup-python` 3.11 (`cache: pip`, `cache-dependency-path: requirements*.txt`) | | — |
| 2 | Lint the harness | `docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.7`; `docker compose config --quiet`; `docker compose config --profiles` must print `workers` | 3 min |
| 3 | Cache HF models | `actions/cache@v4`, path `~/.cache/huggingface`, key `hf-${{ runner.os }}-bge-base-en-v1.5-bge-reranker-base`. Not the same key as `ci.yml`'s, because that cache has only bge-base. | — |
| 4 | Host Python deps | `make setup-py` (CPU torch through `PIP_EXTRA_INDEX_URL`) | 10 min |
| 5 | Pre-fetch models on the host | Python one-liner: `AutoTokenizer`/`AutoModel.from_pretrained("BAAI/bge-base-en-v1.5")` and `AutoTokenizer`/`AutoModelForSequenceClassification.from_pretrained("BAAI/bge-reranker-base")`. That's exactly the files the code loads, not a full `snapshot_download`. A warm cache makes this a no-op. The cache dir ends up owned by `runner`, so the host-run tests can write to it. | 10 min |
| 6 | `make build-go` | | 5 min |
| 7 | **AC1**: infra only | `docker compose up -d`, then `docker compose ps -a --services \| sort`, which must equal exactly `kafka kafka-init minio minio-init postgres`. Also `docker compose config --services` (5) vs `--profile workers config --services` (8). Output goes to the log and `$GITHUB_STEP_SUMMARY`. | 5 min |
| 8 | **AC2**: `make stack-up` | Then `docker compose --profile workers ps` shows `(healthy)` for postgres, kafka, minio, embedder-api, processor and embedder-worker. | 25 min (image build ≈ 5–8 min cold) |
| 9 | `make migrate` | | 2 min |
| 10 | **AC3**: crawl | `./bin/arxivlens crawl --query "cat:cs.LG" --limit 2`. **The downloader isn't running yet**, so the crawl's API request, plus its 3 s sleep, finishes before any PDF request (politeness, item 3). | 2 min |
| 11 | Start the Go host services | `nohup ./bin/arxivlens download > downloader.log 2>&1 &` (franz-go defaults to resetting at the start, so it picks up the 2 queued events) and `nohup ./bin/arxivlens query --port 8080 > query.log 2>&1 &`. Then poll `curl -fsS localhost:8080/healthz` every 2 s for up to 60 s. | 2 min |
| 12 | **AC3**: wait for `embedded` | Read the IDs with `docker compose exec -T postgres psql -U postgres -d arxivlens -tAc "select arxiv_id from papers"` (only the 2 crawled papers exist at this point). Every 10 s, print the statuses until both are `embedded`, for at most 15 min. Then run `./bin/arxivlens status --arxiv-id <id>` for each ID (that's the AC3 evidence) and `./bin/arxivlens dlq list` for the 3 DLQ topics, which must be empty. On timeout, print the DLQ lists and fail. | 16 min |
| 13 | Seed the M3/M4 fixture | `sleep 3`, then `curl -fsS -m 300 -X POST localhost:8080/v1/papers/ingest -H 'Content-Type: application/json' -d '{"arxiv_id":"2608.20331"}'`, then `./bin/arxivlens status --arxiv-id 2608.20331`. This is the documented seeding path (`evals/README.md`). | 6 min |
| 14 | **AC4**: `make test-full` | `sudo chown -R runner ~/.cache/huggingface` first (containers write to it as root). Runs pytest on the host against the published ports. The summary line goes to `$GITHUB_STEP_SUMMARY`. | 20 min |
| 15 | Diagnostics, `if: failure()` | `docker compose --profile workers ps -a`, `docker compose --profile workers logs --no-color --timestamps`, `downloader.log`, `query.log`, and `arxivlens dlq list` per DLQ topic, printed to the log **and** uploaded as artifact `stack-logs` (`retention-days: 7`). | 5 min |
| 16 | Teardown, `if: always()` | Kill the background PIDs, `docker compose --profile workers down -v`, `sudo chown -R runner ~/.cache/huggingface` (so the `actions/cache` post-step can save it). | 5 min |

**Secrets:** none. **Triggers:** `pull_request` (not `_target`) with the paths filter, plus `workflow_dispatch` (usable once the file is on
`main`). `ci.yml` doesn't change. EVAL-3 can copy steps 1–11 into `eval.yml`, or pull them into a composite action then; I'm not doing it
now, to keep this diff small.

**Expected runtime** (ubuntu-latest, 4 vCPU):

| Phase | Cold | Warm (pip + HF cache hit) |
|---|---|---|
| Setup, actionlint, pip, model pre-fetch, Go build | 5 min | 2.5 min |
| Two image builds (in parallel; embedder-worker reuses embedder-api's layers) | 6 min | 6 min (no Docker layer cache in v1) |
| Stack healthy | 1.5 min | 1.5 min |
| Crawl 2 → `embedded` (CPU embedding, ~50–150 chunks) + fixture ingest | 4 min | 4 min |
| `make test-full` (M0 loads BGE, M4 reprocesses the fixture 10×) | 4 min | 4 min |
| **Total** | **≈ 21 min** | **≈ 18 min** |

I set `timeout-minutes: 45`, about 2× the cold estimate. The run is rare: only PRs that touch the harness, plus manual runs.

### 4. arXiv politeness in CI (design item 3)
The suites themselves make **no** arXiv requests. I grepped `tests/`; the only URLs in `test_evals_data.py` are mocked. Per run:

| # | Request | Host | Sent by | User-Agent |
|---|---|---|---|---|
| 1 | Atom API `search_query=cat:cs.LG&max_results=2` | export.arxiv.org | crawler (step 10) | `ArxivLens/1.0 (Research Pipeline; mailto:…)` ✔ |
| 2–3 | 2 × PDF | arxiv.org | Go downloader (step 11) | `ArxivLens/1.0 (Downloader Pipeline; mailto:…)` ✔ |
| 4 | Atom API `id_list=2608.20331` | export.arxiv.org | query-service ingester (step 13) | **none** (pre-existing gap) |
| 5 | PDF 2608.20331 | arxiv.org | ingester | `ArxivLens-Bot/1.0`, no contact (pre-existing gap) |

**Total: 5 requests per run** (2 API, 3 PDF). The two API requests are minutes apart. The workflow orders its steps so that requests 1 and 2
are ≥ 3 s apart (the downloader starts only after `crawl` has slept its 3 s), and 3 and 4 are minutes apart (step 12 runs between them plus an
explicit `sleep 3`). Two gaps are in product code that is out of scope here (`internal/`), so I'll report them rather than work around them:
- the Go downloader has no rate limiter, so PDFs 2 and 3 can be < 3 s apart;
- the ingester sends no User-Agent on the metadata call and no contact on the PDF call, and it doesn't wait between its two requests (different hosts).

I'll ask for a follow-up in the task Notes ("downloader + ingester politeness: shared 3 s limiter and the crawler's identifying UA"). `concurrency`
keeps one run per ref, and the paths filter keeps runs rare. Nothing in the workflow sets `--rate-limit`, so the crawler's 3 s default holds.

### 5. Data the suites need (design item 4)

| Suite | Needs | Provided by |
|---|---|---|
| M0, `test_evals_data` | BGE model on the host; no infra | step 5 (HF cache) |
| M1 | pgvector, 5 tables, 6 topics × 12 partitions, bucket, **≥ 2 papers with `raw/…pdf` + sha256** | compose init jobs, `make migrate`, crawl (2) + fixture (1) |
| M2 | **≥ 2 `embedded` papers, ≥ 20 sections, ≥ 10 chunks with ≤ 512 tokens, ≥ 100 embeddings** for the current model | crawl + fixture. Three real papers give far more than 100 chunks in practice, but two very short crawled papers plus a failed fixture could fall below that (see risks) |
| M3 | query service on :8080 + embedder API with cross-encoder; **paper `2608.20331` `embedded`** with content matching "G-CARL … medical report … checklist" (`test_m3_query.py:16,36,70`) | steps 11 + 13; `/healthz` gate requires `"reranker":true` |
| M4 | `2608.20331` v1 with key **`raw/2608.20331_v1.pdf`** (`test_m4_chaos.py:47`); Kafka, MinIO, DB from the host; **DLQ topic empty before the test** (it reads the first DLQ record from `earliest`) | step 13: the ingester always writes `version=1` and `raw/<id>_v1.pdf`, which the crawler path wouldn't guarantee. Step 12 checks the DLQ is empty. |
| M5/M6 | `opentelemetry` importable; **`chunk_embeddings_hnsw_idx` exists** | D4 / D5 below |

Things that can fail for reasons outside this task. If any of them happens, the build stops and reports it (log excerpt + follow-up request in Notes); it never edits or skips a test:
- **D1, fixture unverified.** EVAL-1 QA nit 8 says nobody has checked that `2608.20331` exists on arXiv or matches the G-CARL wording. I couldn't check it either,
  because the sandbox has no route to arXiv. If ingest returns "paper not found", or M3's `rerank_score > 0.50` / `supported` asserts fail, the hard-coded fixture
  is the cause → follow-up for the owner of `tests/` (and EVAL-1's corpus).
- **D2, M3 latency.** `test_m3_query.py` uses a 10 s client timeout. On a CPU runner, `/v1/ask` (20-candidate rerank since RET-1, plus citation validation) might take
  longer. That would be a finding (EVAL-3 measures p95), not something to fix here by raising the timeout.
- **D3, ingest timeout.** The ingester's HTTP client times out after 45 s on `/internal/ingest`, and that endpoint builds a new `ProcessorWorker`
  and `EmbedderWorker` (each loads models) per call. On CPU this may not finish in time → report against the < 60 s on-demand target (Product PRD §8).
- **D4, `make test-full` can't collect M5.** `tests/test_m5_m6_telemetry_eval.py` imports `opentelemetry`, which isn't in `requirements-m0.txt` or
  `make setup-py`. A collection error interrupts the **whole** pytest run, so M0–M4 wouldn't run either. Fix proposed in this task: add `opentelemetry-sdk`
  to `make setup-py` (harness, my area, one word). OPS-H2 folds it into the unified `requirements.txt`. The images don't need it, because no worker imports `services/common/telemetry.py`. *(Open question 2.)*
- **D5, HNSW index (known, OPS-H5).** `test_pgvector_hnsw_index_presence_and_querying` fails on a fresh database until OPS-H5's migration merges.
  It is **not** in AC4's M1–M4 scope, but `make test-full` runs every suite, so the job will be red because of this one test. *(Open question 1.)*

## Alternatives considered
1. **Workers without a profile (always on).** That breaks AC1. People who only want infra, or who run workers on the host for MPS, would get duplicate
   consumers in the same groups.
2. **Go downloader and query service in compose too.** Explicitly out of scope. The workflow runs them on the host, which is also how the README documents
   them today.
3. **`docker compose up --wait`** instead of the wait loop. Rejected because of the one-shot init containers, see §2.
4. **Getting the fixture through the crawler** (`--query "id:2608.20331"`). arXiv discourages `id:` searches, and the crawler records the *latest*
   version, so the key would be `raw/2608.20331_vN.pdf`, but M4 hard-codes `_v1`. The on-demand ingest path always writes v1 and is the documented seeding path.
5. **One shared image for all three services.** That would need the same pip line in both Dockerfiles, which is OPS-H2's job (unifying deps). Two `build:`
   entries with the same Dockerfile get the same result through the BuildKit cache.
6. **Docker layer caching in CI** (`buildx` + `type=gha`). It would save about 4 min, but it adds a bake/buildx path that's different from what developers run
   locally. Left out of v1 for determinism; EVAL-3 (nightly) can add it.
7. **Gating only M1–M4 in CI (`pytest tests/test_m1… test_m4…`) or `continue-on-error` on M5.** Rejected: that's a weakened gate (AGENTS.md §3). The
   workflow runs `make test-full` unchanged.

## Contracts and invariants
- Shared contracts touched: **none**. No event, HTTP API, schema or embedding-model change. `version: '3.8'` and the infra service blocks stay as they are.
- Reliability invariants are unaffected. The containers run the same `worker.py` code with the same consumer groups (`processor-v1`, `embedder-v1`),
  so commit-after-process, the 3× retry, DLQ routing and `traceparent` behave exactly as on the host. M4 runs against the live workers. Its corrupt-PDF event is
  also consumed by the live processor, which DLQs it with `attempts=3` and the same `traceparent` header, so whichever DLQ record M4 reads first still matches.
  That holds only if the DLQ was empty before the test, which step 12 asserts.
- arXiv politeness: §4 above. No limit is lowered, and the identifying UA is kept where it exists today.
- Harness: no secrets, `permissions: contents: read`, and the run is deterministic except for *which* 2 cs.LG papers are newest (inherent to AC3).

## Test plan
| Acceptance criterion | Test (name / type) | Runs in CI? |
|---|---|---|
| AC1 infra-only default | `stack.yml` step 7: `ps -a --services` equals exactly the 5 infra services; `config --services` 5 vs 8 with the profile | yes, `stack.yml` |
| AC2 `make stack-up` healthy, API healthcheck | step 8: `make stack-up` exits 0 (its loop requires `healthy` for the 3 new containers); `docker compose --profile workers ps` output pasted; `docker compose config` shows the `embedder-api` healthcheck | yes |
| AC3 crawl 2 → `embedded` | steps 10–12: `arxivlens status --arxiv-id` for both IDs shows `Status: embedded`; DLQs empty | yes |
| AC4 `make test-full` M1–M4 | step 14: pytest summary in the step summary. M5 HNSW is a known red until OPS-H5 (Open question 1). Host startup of the Go services is documented in README/CONTRIBUTING | yes |
| AC5 docs | Diff review: README Quick start "one command" path, host-run path kept as "Apple-silicon MPS acceleration", Known-limitations bullet, CONTRIBUTING rows (`stack-up`, `stack-down`, `stack.yml`). `README.md:39` and `CONTRIBUTING.md:50-60` unchanged (`git diff -U0` line ranges in evidence) | review |
| AC6 workflow runs on its PR, green; lint/unit green; < 400 lines | `stack.yml` run on the PR (paths include the workflow file); `ci.yml` green; ownership-check prints the line count; step 2 actionlint + `compose config` | yes |

Failure paths covered: stack not healthy in `STACK_TIMEOUT` (the loop prints `ps -a` + tail logs, exits 1); papers not `embedded` in 15 min (DLQ lists
printed, fails); fixture ingest non-200 (`curl -f` fails the step, response body shown); any failure → step 15 dumps all compose logs plus
the downloader/query logs and uploads them. Locally, without a daemon: `docker compose config --quiet`, `docker compose config --profiles`, actionlint, `make -n stack-up`.

## Risks and rollout
- **Newest cs.LG papers are arbitrary.** A PDF that fails to parse sends that paper to the DLQ, and AC3 fails in step 12 with the DLQ printed. That's a
  real pipeline finding; rerun once to tell it apart from flakiness, and report it if it repeats.
- **Runner resources.** Kafka (1 GB heap), Postgres (512 MB shared buffers), 3 model-loading containers and the host pytest add up to about 8–9 GB of the 16 GB.
  Image disk use is about 3 GB each with CPU torch. If the runner runs out, it shows up as OOM-killed containers in the step 15 dump.
- **Healthcheck API drift** (`describe_consumer_groups` in the installed `confluent-kafka`). It would show up on the first CI run, and the fallback is documented in §1.
- **HF cache ownership.** Root-owned files from the containers on a bind mount. Handled with `chown` before host tests and before the cache save.
- **Local context size.** There's no `.dockerignore`, so a local `.venv/` or `frontend/node_modules/` at the repo root gets sent as build context (GBs) on
  every `make stack-up`. CI isn't affected (clean checkout). See Open question 3.
- **Rollback:** the change is purely additive. Reverting the PR restores today's behaviour. Plain `docker compose up -d` never changes, by AC1.

## Open questions (for pm-lead)
1. **M5 HNSW vs. "green" (AC4/AC6).** `make test-full` is red on a fresh DB until OPS-H5 merges. My proposal: build OPS-H1 now. The PR's `stack.yml`
   run shows M0–M4 green and the single known M5 failure. Then mark OPS-H1 `Blocked (needs OPS-H5 merged)`, and once OPS-H5 lands, rebase and rerun for a fully
   green run. That run also gives OPS-H5 its AC5 evidence. The alternative is to sequence OPS-H5 first. I won't deselect the test or set `continue-on-error`.
2. **D4: add `opentelemetry-sdk` to `make setup-py` in this task?** Without it, `make test-full` can't even collect. It's a one-word harness fix inside
   my paths, but it's next to OPS-H2's scope (unify deps). If you'd rather keep it out, the alternative is installing it only in `stack.yml`; either way OPS-H2 should own it afterwards.
3. **`.dockerignore`.** It would make local `make stack-up` fast (excluding `.venv/`, `node_modules/`, `bin/`, `.cache/`, `evals/results/`), but
   `ownership-check.sh` doesn't list `.dockerignore` for backend. Adding it means a one-line allow-list change in `.github/scripts/` (backend-owned) plus about 8 lines.
   Include it in OPS-H1, or make it a follow-up?
4. **Follow-ups to open (not built here):** (a) downloader + ingester arXiv politeness (rate limiter, identifying UA on every request), backend;
   (b) verify or replace the hard-coded `2608.20331` fixture in M3/M4, which depends on the first stack run; (c) AGENTS.md §6 still says workers aren't in compose
   (pm-lead owns it). I'll also put (c) in the task Notes, per the ticket.

## PM decision
**APPROVED with binding conditions** (pm-lead, 2026-11-03, reviewed at design commit 8a9e9a9 against `agents/tasks/OPS-H1.md`,
Technical PRD §11 P0 row "Containerize processor + embedder in compose" and §9 "External politeness"; app `origin/main` 9c1229a).

Why: every ticket design item (1–5) is answered, and every AC maps to a named `stack.yml` step. No shared contract changes.
The infra service blocks and `ci.yml` stay unchanged. The design refuses to deselect, skip or `continue-on-error` any test.
I spot-checked these claims against the code: `test_m5_m6_telemetry_eval.py:4` imports `opentelemetry`, which `make setup-py`
doesn't install; both Dockerfiles already install `curl`, so the `/healthz` check works; the compose `INTERNAL://kafka:9092`
listener exists; `ownership-check.sh` allows `docker-compose.yml`, `Makefile`, `.github/`, both Dockerfiles, `README.md` and
`CONTRIBUTING.md` for backend, but not `.dockerignore`.

### Decisions on the open questions
1. **M5 HNSW: build OPS-H1 now (option A). Do not sequence OPS-H5 first.** The first `stack.yml` run is the team's first-ever full-stack
   run. It proves AC1–AC3 and M0–M4, and it surfaces D1–D3 early. That's worth more than waiting.
   - The first run must show the full, unfiltered `make test-full` summary. **The only allowed failure is
     `test_pgvector_hnsw_index_presence_and_querying`, failing on the missing `chunk_embeddings_hnsw_idx` assertion.** Any other
     failure is a finding: handle it per design item 4 (log excerpt plus a follow-up in Notes).
   - After that run, the task goes to `Blocked (needs OPS-H5 merged)`. The PR stays **draft** and does not go to QA. AC4 covers M1–M4,
     but AC6 still requires a **green** `stack.yml` run, and it is not weakened. Once OPS-H5 merges, rebase, rerun, then QA.
   - OPS-H5 is now on OPS-H1's critical path. **The next free backend slot goes to OPS-H5**, ahead of OPS-H7, OPS-H2, OPS-H8
     and ING-6. Its files (`migrations/`, `internal/db/`, `cmd/arxivlens/`) don't overlap OPS-H1's. OPS-H5's AC5 may say "not run:
     infra unavailable" if OPS-H1 isn't merged, as its spec already allows. OPS-H1's green rerun after OPS-H5 merges is then filed as
     OPS-H5's post-merge AC5 evidence in `agents/reviews/OPS-H5/`. If that rerun fails M1 or M5/M6 because of the migration, it is an
     OPS-H5 bug and gets a new task, not a change to OPS-H1.
2. **D4: add `opentelemetry-sdk` to `make setup-py` in this task.** It's harness and inside backend's paths, and without it `make test-full`
   can't even collect, for every developer, not just CI. `stack.yml` must install it through `make setup-py` and not with a separate
   pip line, so CI and local setup can't drift. Leave it out of the images. OPS-H2 absorbs it into the unified `requirements.txt`
   (note added to OPS-H2).
3. **`.dockerignore`: follow-up, not in this PR.** The ownership allow-list in `ownership-check.sh` is the CI enforcement of the
   AGENTS.md §2 table. Widening it is a rule change, so it goes through a pm-lead rules PR first and then the backend change. Until then,
   the README Quick start must have a one-line note: "run `make stack-up` from a clean checkout or move `.venv/` and `node_modules/` out
   of the repo root, because there is no `.dockerignore` yet."
4. **Follow-ups**: (a) and (b) added to the `agents/board.md` Backlog. (c), the AGENTS.md §6 gotcha, is a pm-lead rules PR after
   OPS-H1 merges, also in the Backlog. Also logged: `.dockerignore`.

### Binding conditions (QA checks each)
1. **Scope as designed.** No edit to `internal/`, `cmd/`, `services/**/*.py`, `tests/`, `ci.yml`, `README.md:39` or `CONTRIBUTING.md:50-60`.
   The infra service blocks in `docker-compose.yml` stay byte-identical (`git diff` evidence). If OPS-H6 shifts those README/CONTRIBUTING
   lines before you rebase, protect the *text*, not the line numbers.
2. **AC2 evidence covers every service.** The `docker compose --profile workers ps -a` output shows `(healthy)` for postgres, kafka,
   minio, embedder-api, processor and embedder-worker, and `Exited (0)` for kafka-init and minio-init.
3. **Worker healthcheck.** Use the consumer-group check. If you fall back to `kill -0 1`, record it in this design (a dated line under §1)
   and in the PR. That fallback is acceptable only because AC3 then proves the workers really consume.
4. **Politeness.** Keep the step order from §4: the downloader starts only after `crawl` returns, and there's an explicit `sleep 3` before
   the fixture ingest. Nothing may pass `--rate-limit` below the default. The PR description lists the two pre-existing product gaps
   (downloader has no limiter; the ingester has no or a non-identifying UA) with the Backlog follow-up. The run is bounded to 5 arXiv requests.
5. **D1–D3 handling.** If the `2608.20331` fixture is missing or mismatched, `/v1/ask` exceeds M3's 10 s client timeout, or the 45 s
   ingest timeout trips: don't raise a timeout, don't swap the fixture and don't edit a test. Stop, paste the log excerpt in Notes, mark
   `Blocked (needs <follow-up>)` and tell pm-lead. Rerunning once to rule out flakiness is fine. Say that you reran.
6. **Diagnostics never leak secrets.** No secrets are used. The `stack-logs` artifact (7 days) holds compose and host logs only.
7. **Diff < 400 changed lines** (the ownership-check line count is the evidence). If it goes over, split the docs into a follow-up PR
   instead of trimming the workflow.
8. **AC5 docs** also include the `.dockerignore` note (decision 3) and the GPU/MPS note (§1 "CPU torch").

### Ticket updates made with this decision
`agents/tasks/OPS-H1.md`: status set to Ready (design approved), AC4 and AC6 now state the M5 rule above (this tightens them, it doesn't
weaken them), a new AC7 covers `opentelemetry-sdk` in `make setup-py`, and Notes record the follow-ups. `agents/tasks/OPS-H5.md` and
`agents/tasks/OPS-H2.md` Notes are updated.
