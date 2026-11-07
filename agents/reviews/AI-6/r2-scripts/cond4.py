import json, re, subprocess, sys
head = "c45757622c2476f37128eaa4c8c0da527cb5e210"
src = subprocess.run(["git", "show", f"{head}:internal/query/rag.go"], capture_output=True, text=True, check=True).stdout
m = re.search(r"const synthesisSystemPrompt = `(.*?)`", src, re.S)
const = m.group(1)
ver = re.search(r'synthesisPromptVersion\s*=\s*"([^"]+)"', src).group(1)
pr = json.loads(subprocess.run(["gh", "api", "repos/MaheshPulivarthi18/ArxivLens/pulls/28"], capture_output=True, text=True, check=True).stdout)
body = pr["body"].replace("\r\n", "\n")
print("PR head sha:", pr["head"]["sha"], "| match reviewed head:", pr["head"]["sha"] == head)
print("const lines:", len(const.splitlines()), "| const sha-prefix source: git show", head[:7] + ":internal/query/rag.go")
blocks = re.findall(r"^(`{3,})text\n(.*?)\n\1$", body, re.S | re.M)
print("fenced text blocks in PR body:", len(blocks))
exact = any(b[1] == const for b in blocks)
print("a fenced block equals synthesisSystemPrompt byte-for-byte:", exact)
missing = [l for l in const.splitlines() if l not in body.splitlines()]
print("const lines missing as whole lines from PR body:", len(missing))
for l in missing: print("  MISSING:", l)
print(f"version const in rag.go: {ver!r} | appears in PR body as synthesisPromptVersion = \"{ver}\":", f'synthesisPromptVersion = "{ver}"' in body)
print("RESULT:", "PASS" if exact and not missing else "FAIL")
