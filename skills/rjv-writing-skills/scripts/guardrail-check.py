#!/usr/bin/env python3
"""guardrail-check.py <base-ref> <path>...

List guardrail sentences present at <base-ref> that are missing, word for
word, from the working tree. A guardrail sentence holds a ban word
(never, do not, don't, must not, only when the user) and a risky action
(merge, push, deploy, delete, publish, spend, send, permission, secret,
production, commit, credential, cookie, token, start Codex...).
Whitespace and line wraps are ignored. Exit 1 when any is missing.
"""
import re, subprocess, sys, pathlib

BAN = re.compile(r"\b(never|do not|don['’]t|must not|only when the user)\b", re.I)
RISK = re.compile(r"\b(merg\w*|push\w*|deploy\w*|delet\w*|publish\w*|spend\w*|send\w*|"
                  r"permission\w*|secret\w*|production|prod|commit\w*|credential\w*|cookie\w*|"
                  r"token\w*|password\w*|force|drop\w*|migrat\w*|money|payment\w*|"
                  r"start (codex|opencode|a reviewer)|edit, rename|unattended|approv\w*)\b", re.I)

def sentences(text):
    text = re.sub(r"[`*_>|]", "", text)
    text = re.sub(r"\s+", " ", text)
    return [s.strip() for s in re.split(r"(?<=[.!?])\s+|\s-\s|\s\d+\.\s", text) if s.strip()]

def guardrails(text):
    return {s for s in sentences(text) if BAN.search(s) and RISK.search(s)}

def norm(s):
    s = re.sub(r"[`*_>|]", "", s.lower())
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9\s]", "", s)).strip()

base, paths = sys.argv[1], sys.argv[2:]
files = subprocess.run(["git", "ls-tree", "-r", "--name-only", base, "--", *paths],
                       capture_output=True, text=True, check=True).stdout.split()
missing = 0
for f in files:
    if not f.endswith(".md"):
        continue
    old = subprocess.run(["git", "show", f"{base}:{f}"], capture_output=True, text=True).stdout
    p = pathlib.Path(f)
    new = p.read_text() if p.exists() else ""
    # a sentence moved to a sibling file still counts
    sib = " ".join(q.read_text() for q in p.parent.glob("*.md")) if p.parent.exists() else new
    have = norm(sib)
    for g in sorted(guardrails(old)):
        if norm(g) not in have:
            missing += 1
            print(f"{f}: {g}")
print(f"{missing} guardrail sentence(s) missing", file=sys.stderr)
sys.exit(1 if missing else 0)
