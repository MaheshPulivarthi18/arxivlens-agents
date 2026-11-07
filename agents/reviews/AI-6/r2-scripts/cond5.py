import json, re, subprocess
pr = json.loads(subprocess.run(["gh", "api", "repos/MaheshPulivarthi18/ArxivLens/pulls/28"], capture_output=True, text=True, check=True).stdout)
body = pr["body"].replace("\r\n", "\n")
sec = body.split("### Mutation check (design condition 5)", 1)
print("section '### Mutation check (design condition 5)' present:", len(sec) == 2)
sec = sec[1].split("\n### ", 1)[0]
print("mentions scratch module:", "scratch module" in sec)
rows = [r for r in sec.splitlines() if r.startswith("| ") and not r.startswith("| Mutation") and not r.startswith("|---")]
pr_rows = {}
for r in rows:
    c = [x.strip() for x in r.strip("|").split("|")]
    pr_rows[c[0]] = sorted(re.findall(r"`(Test\w+)`", c[1]))
# QA round-1 independent run (evidence/08-mutations.txt at b6c9dfb)
qa = open("/home/claude/arxivlens-agents/agents/reviews/AI-6/evidence/08-mutations.txt").read()
qa_rows = {}
for l in qa.splitlines():
    m = re.match(r"KILLED\s+(.*?)\s{2,}-> (.*)", l)
    if m: qa_rows[m.group(1)] = sorted(x.strip() for x in m.group(2).split(","))
pairs = {
 "Skip an oversize passage instead of stopping": "skip-not-stop (2nd break -> continue)",
 "No sanitizing of `<passage>`/`<question>` delimiters": "no sanitizing",
 "No grouping by paper": "no grouping",
 "`ChunkID == 0` used as a dedup key": "ChunkID 0 used as dedup key",
 "No per-paper cap": "no per-paper cap",
 "Metadata not collapsed to one line": "metadata not collapsed to one line",
}
ok = True
print(f"PR mutation rows: {len(pr_rows)} | QA round-1 killed rows: {len(qa_rows)}")
for p, q in pairs.items():
    a, b = pr_rows.get(p), qa_rows.get(q)
    same = a == b
    ok &= same and a is not None
    print(f"[{'SAME' if same else 'DIFF'}] PR: {p}\n        PR tests: {a}\n        QA tests: {b}")
print("third design mutation (out-of-range marker) noted as moved to AI-6b:", "out-of-range" in sec and "AI-6b" in sec)
print("RESULT:", "PASS" if ok and "AI-6b" in sec else "FAIL")
