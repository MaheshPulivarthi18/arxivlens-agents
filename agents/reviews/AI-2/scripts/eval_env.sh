#!/usr/bin/env bash
# AC4: can `make eval` run here? Shows the eval entry point, its live dependency on /v1/ask, and the sandbox infra state.
echo "== Makefile eval target =="; grep -n -A2 '^eval:' Makefile
echo "== eval_gate / evaluate_answers: what supported_citation_rate counts =="
grep -nE 'supported_citation_rate|c.get\("supported"\)|QUERY_URL|8080|/v1/ask' scripts/eval_gate.py scripts/evaluate_answers.py | head -12
echo "== infra in this sandbox =="
echo "docker daemon: $(docker info 2>&1 | grep -m1 -iE 'failed to connect|cannot connect|Server Version' || echo 'docker CLI missing')"
curl -sS -m 3 http://localhost:8080/health >/dev/null 2>&1; echo "curl http://localhost:8080/health exit $? (7 = connection refused)"
echo "== actual attempt: timeout 90 make eval =="
timeout 90 make eval 2>&1 | tail -5; echo "make eval exit ${PIPESTATUS[0]}"
echo "== PR #11 body, AC4 line =="
gh api repos/MaheshPulivarthi18/ArxivLens/pulls/11 --jq .body | grep -n 'AC4\|make eval'
