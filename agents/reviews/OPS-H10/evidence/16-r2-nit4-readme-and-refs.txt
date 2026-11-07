$ bash -c git diff 9ebb49e 532440e; echo '--- ls-remote:'; git ls-remote origin 'refs/heads/agent/backend/OPS-H10*'
diff --git a/README.md b/README.md
index f319c84..4e63b0c 100644
--- a/README.md
+++ b/README.md
@@ -232,7 +232,7 @@ The `Full stack` workflow (`.github/workflows/stack.yml`) does all of this on a
 ingests the `2608.20331` fixture and runs `make test-full`. Known failure F1: the two M3 `/v1/ask` tests exceed their 10 s
 timeout on CPU runners, so they are deselected there and run in a separate, non-blocking step. It runs on PRs that touch compose, Dockerfiles,
 `requirements*.txt`, the Makefile, the workflow, Go code (`cmd/`, `internal/`, `go.mod`, `go.sum`) or `tests/`, and on demand (`workflow_dispatch`).
-Every run, green or red, uploads a `stack-logs` artifact with `compose.log`, `query.log`, `downloader.log` and `embedder-timing.log`.
+Every run, green or red, uploads a `stack-logs` artifact with `compose.log` and `embedder-timing.log`, plus `query.log` and `downloader.log` once the host services have started.
 
 ---
 
--- ls-remote:
532440e04dad297fc08ed31fbaca4945e5fed73d	refs/heads/agent/backend/OPS-H10
0558a34523bb6397867fefc9c767f4efdee7bbf8	refs/heads/agent/backend/OPS-H10-ac3

[exit code 0]
