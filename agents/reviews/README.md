# QA evidence packs

One folder per task, written by `qa-reviewer` and committed to this repo's `main` (never to the ArxivLens PR):

```
agents/reviews/<TASK-ID>/
  report.md            QA report (rounds appended) + PM verdict
  evidence/
    00-ci-checks.png   CI check runs for the reviewed commit (+ .txt)
    01-<ac>.png        rendered from real command output by agents/tools/render_evidence.py (+ .txt full output)
    ...
```

The Jira ticket links to these files; pm-lead embeds the images (commit-pinned URLs into this private repo) in the
ArxivLens PR description when raising the PR, so the reviewer sees the evidence inside the PR.
