#!/usr/bin/env python3
"""Condense a Claude Code transcript (JSONL) into a compact digest for ctx autosave.
Usage: extract.py <transcript> <cutoff_epoch>   -> digest on stdout, exit 3 if trivial."""
import json, sys
from datetime import datetime

path, cutoff = sys.argv[1], float(sys.argv[2])
out, prompts, edits = [], 0, 0
for line in open(path, encoding="utf-8", errors="replace"):
    try:
        e = json.loads(line)
    except ValueError:
        continue
    if e.get("type") not in ("user", "assistant") or e.get("isSidechain"):
        continue
    ts = e.get("timestamp")
    if ts and datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp() <= cutoff:
        continue
    c = (e.get("message") or {}).get("content")
    if isinstance(c, str):
        if e["type"] == "user" and not c.startswith("<"):
            prompts += 1
        out.append(f"{e['type'].upper()}: {c[:2000]}")
        continue
    for b in c or []:
        t = b.get("type")
        if t == "text" and b.get("text", "").strip():
            out.append(f"{e['type'].upper()}: {b['text'][:2000]}")
        elif t == "tool_use":
            i = b.get("input") or {}
            name = b.get("name", "?")
            if name in ("Edit", "Write", "NotebookEdit"):
                edits += 1
            arg = i.get("file_path") or i.get("description") or i.get("command") or i.get("prompt") or ""
            out.append(f"  [{name}: {str(arg)[:150]}]")

if prompts < 2 and edits == 0:
    sys.exit(3)  # trivial session, nothing worth logging
print("\n".join(out)[-40000:])  # the tail is what matters for "where we left off"
