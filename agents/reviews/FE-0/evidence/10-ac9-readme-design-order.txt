$ bash -c git diff origin/main...HEAD -- README.md; git -C /root/mem/qa-69 log --format='%h %cI %s' -- docs/design/FE-0.md; git log --format='%h %cI %s' origin/main..HEAD
diff --git a/README.md b/README.md
index dbe21ea..e355d1e 100644
--- a/README.md
+++ b/README.md
@@ -135,6 +135,9 @@ Check one paper:
 cd frontend && npm install && npm run dev     # UI on http://localhost:5173 (proxies /v1 → :8080)
 ```
 
+The theme button in the navbar switches between Light, Dark and System (follows your OS); the choice is stored in your
+browser (`localStorage`), and the first visit starts in Dark.
+
 ### Option: Python workers on the host (Apple-silicon MPS acceleration)
 
 Docker on macOS has no MPS, so for GPU-speed embedding on a Mac start infra only and run the three Python processes
abfa173 2026-11-19T21:17:04+00:00 pm(FE-0): design approved with conditions; split FE-0b; FE-3/FE-4 deps + FE-3 AC8
bcc377b 2026-11-19T21:08:11+00:00 FE-0: design
ca76bea 2026-11-19T21:38:39+00:00 FE-0: ThemeToggle without setState in an effect (clear oxlint warning)
dcf93c5 2026-11-19T21:34:06+00:00 FE-0: classic research theme (tokens, self-hosted fonts, dark mode, theme toggle)

[exit code 0]
