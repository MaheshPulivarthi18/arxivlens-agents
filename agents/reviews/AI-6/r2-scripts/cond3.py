import re, subprocess, os
R = "/home/claude/arxivlens-agents"
rd = lambda p: open(os.path.join(R, p)).read()
ok = True
def chk(name, cond):
    global ok; ok &= bool(cond); print(f"[{'OK' if cond else 'NO'}] {name}")
chk("agents/tasks/AI-6b.md exists", os.path.exists(f"{R}/agents/tasks/AI-6b.md"))
ai6, ai6b, des, qa8 = rd("agents/tasks/AI-6.md"), rd("agents/tasks/AI-6b.md"), rd("docs/design/QA-8.md"), rd("agents/tasks/QA-8.md")
ac3 = re.search(r"- \[ \] AC3 — (`parseSynthesis`:.*?error\.)\n", ai6, re.S).group(1)
norm = lambda s: " ".join(s.split())
print("AI-6 AC3 text:", norm(ac3))
chk("AI-6 AC3 text appears verbatim (whitespace-normalised) in AI-6b.md", norm(ac3) in norm(ai6b))
chk("AI-6 AC3 annotated 'Moved to AI-6b'", "Moved to AI-6b (design condition 1 seam c)" in ai6)
# AC3 text in AI-6.md unchanged since the build commit a598ad5 (only lines added)
d = subprocess.run(["git","-C",R,"diff","a598ad5","HEAD","--","agents/tasks/AI-6.md"],capture_output=True,text=True).stdout
removed = [l for l in d.splitlines() if l.startswith("-") and not l.startswith("---")]
removed_ac = [l for l in removed if re.match(r"-(- \[.\] AC|\s{6}\S)", l)]  # AC checklist lines + their continuations
print("lines removed from AI-6.md since a598ad5 (all):", [l[:60] + "..." for l in removed])
chk("no acceptance-criterion line removed/edited in AI-6.md since a598ad5 (removed AC lines: %d)" % len(removed_ac), not removed_ac)
for t in ["TestParseSynthesis` (table)", "TestParseSynthesisErrorHasNoCompletionText"]:
    row = [l for l in des.splitlines() if l.startswith("| AC3 |") and t in l]
    body = norm(row[0].split("|")[3]) if row else ""
    chk(f"design test-plan row {t.strip('`')} found", row)
    chk(f"  ...its expectation text appears verbatim in AI-6b.md", body and body in norm(ai6b))
dd = subprocess.run(["git","-C",R,"log","--format=%h","-L230,231:docs/design/QA-8.md","--no-patch"],capture_output=True,text=True).stdout.split()
chk("design AC3 test-plan rows (lines 230-231) only ever touched by design commit effaf87: %s" % dd, dd == ["effaf87"])
chk("design §5 referenced by AI-6b", "§5" in ai6b and "parseSynthesis" in ai6b)
chk("out-of-range-marker mutation carried to AI-6b (AC8)", "out-of-range marker kept" in ai6b)
dep = [l for l in qa8.splitlines() if l.startswith("| **Depends on**")][0]
chk("QA-8 'Depends on' includes AI-6b", "AI-6b" in dep)
print("--- design nits (r1 findings 4, 6)")
chk("nit 4: metaField refinement recorded in design", "passageTokens` counts `metaField` output" in des)
chk("nit 4: imports as built (sort) recorded", "AI-6 adds `sort`" in des)
chk("nit 6: branch name corrected to agent/ai/AI-6", "Next: ai-engineer builds AI-6 on `agent/ai/AI-6`" in des and "agent/ai-engineer/AI-6" not in des)
print("RESULT:", "PASS" if ok else "FAIL")
