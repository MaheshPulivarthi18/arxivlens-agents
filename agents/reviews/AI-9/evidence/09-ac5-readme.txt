$ bash -c echo '# files changed origin/main...3e6420e:'; git diff --stat origin/main...HEAD; echo; echo '# EMBEDDER_TORCH_THREADS mentions at 3e6420e:'; git grep -n EMBEDDER_TORCH_THREADS HEAD -- . | cut -c1-200; echo; echo '# README Environment table rows mentioning EMBEDDER_:'; git grep -n 'EMBEDDER_' HEAD -- README.md || echo '  (none)'
# files changed origin/main...3e6420e:
 services/embedder/api.py | 100 ++++++++++++++++++++++++++++---
 tests/test_m0.py         | 150 +++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 241 insertions(+), 9 deletions(-)

# EMBEDDER_TORCH_THREADS mentions at 3e6420e:
HEAD:services/embedder/api.py:41:    """CPU threads for torch: EMBEDDER_TORCH_THREADS if set to a positive int, else the cores this process may use."""
HEAD:services/embedder/api.py:42:    raw = os.getenv("EMBEDDER_TORCH_THREADS", "").strip()
HEAD:services/embedder/api.py:50:        logger.warning(f"Ignoring invalid EMBEDDER_TORCH_THREADS={raw!r}")
HEAD:tests/test_m0.py:169:    monkeypatch.setenv("EMBEDDER_TORCH_THREADS", "3")
HEAD:tests/test_m0.py:172:        monkeypatch.setenv("EMBEDDER_TORCH_THREADS", bad)
HEAD:tests/test_m0.py:174:    monkeypatch.delenv("EMBEDDER_TORCH_THREADS")

# README Environment table rows mentioning EMBEDDER_:
  (none)

[exit code 0]
