#!/usr/bin/env python3
"""ctx autosave helper.
  autosave.py digest <transcript> <cutoff_epoch>        -> condensed transcript on stdout, exit 3 if trivial
      (CTX_LEAN=1: any session without edits counts as trivial)
  autosave.py apply <root> <logfile> <date> <host>      <- `claude -p --output-format json` on stdin;
      writes the log, STATE.md, IDEAS.md, DECISIONS.md and roadmap ticks, and prints a usage line."""
import json, os, re, sys
from datetime import datetime

SKIP_TOOLS = {"Read", "Grep", "Glob", "ToolSearch", "TodoWrite"}  # lookups: noise for a session log
EDIT_TOOLS = {"Edit", "Write", "NotebookEdit"}
# Shell commands that change files, so lean mode doesn't mistake a Bash-edited session for a read-only one
SHELL_EDIT = re.compile(r"sed -i|(?<![0-9&>])>>?\s*(?!&|/dev/null)[^\s]|\btee\b|\b(mv|cp|rm|mkdir|touch|patch)\s|git (commit|apply|checkout|restore|mv|rm)\b")


def digest(path, cutoff):
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
        role = e["type"].upper()
        c = (e.get("message") or {}).get("content")
        blocks = [{"type": "text", "text": c}] if isinstance(c, str) else (c or [])
        for b in blocks:
            t = b.get("type")
            text = (b.get("text") or "").strip()
            if t == "text" and text:
                if text.startswith("<"):  # command wrappers, reminders: keep a hint only
                    out.append(f"{role}: {text[:200]}")
                    continue
                if role == "USER":
                    prompts += 1
                out.append(f"{role}: {text[:1500 if role == 'USER' else 600]}")
            elif t == "tool_use":
                name = b.get("name", "?")
                if name in EDIT_TOOLS or (name == "Bash" and SHELL_EDIT.search((b.get("input") or {}).get("command", ""))):
                    edits += 1
                if name in SKIP_TOOLS:
                    continue
                i = b.get("input") or {}
                arg = i.get("file_path") or i.get("description") or i.get("command") or i.get("prompt") or ""
                out.append(f"  [{name}: {str(arg)[:150]}]")
    if edits == 0 and (prompts < 3 or os.environ.get("CTX_LEAN") == "1"):
        sys.exit(3)  # trivial or (lean=1) read-only session, nothing worth logging
    print("\n".join(out)[-20000:])  # the tail is what matters for "where we left off"


def sections(text):
    """Split the model's reply on '=== NAME' marker lines."""
    found, cur = {}, None
    for line in text.splitlines():
        m = re.match(r"^=== ?([A-Z]+)\s*$", line.strip())
        if m:
            cur = m.group(1)
            found[cur] = []
        elif cur and not line.strip().startswith("```"):
            found[cur].append(line.rstrip())
    return {k: "\n".join(v).strip() for k, v in found.items()}


def items(block):
    return [l[2:].strip() for l in block.splitlines()
            if l.startswith("- ") and l[2:].strip().lower() not in ("", "none", "(none)")]


def write(path, text):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text.rstrip("\n") + "\n")
    os.replace(tmp, path)


def append(path, text):
    old = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
    write(path, old.rstrip("\n") + "\n" + text)


def apply(root, logfile, date, host):
    raw = sys.stdin.read()
    try:
        j = json.loads(raw)
    except ValueError:
        sys.exit(f"apply: not JSON: {raw[:300]}")
    u = j.get("usage") or {}
    print(f"usage: in={u.get('input_tokens')} cache_read={u.get('cache_read_input_tokens')} "
          f"cache_write={u.get('cache_creation_input_tokens')} out={u.get('output_tokens')} "
          f"turns={j.get('num_turns')} cost=${j.get('total_cost_usd', 0):.4f}")
    if j.get("is_error"):
        sys.exit(f"apply: run failed: {str(j.get('result'))[:300]}")
    s = sections(j.get("result") or "")
    log = s.get("LOG", "")
    if not log:
        sys.exit("apply: no LOG section; nothing written")
    ctx = os.path.join(root, ".context")
    title, _, body = log.partition("\n")
    title = re.sub(r"^#+\s*", "", title).strip()
    write(os.path.join(root, logfile), f"# {date} {host} — {title} (auto)\n\n{body.strip()}")
    touched = [logfile]

    state = s.get("STATE", "")
    if state:
        lines = [l for l in state.splitlines() if not re.match(r"^\W*Updated\W", l)]
        write(os.path.join(ctx, "STATE.md"), "\n".join(lines).rstrip() + f"\n\n**Updated**: {date} on {host}")
        touched.append("STATE.md")

    ideas = items(s.get("IDEAS", ""))
    if ideas:
        append(os.path.join(ctx, "IDEAS.md"), "\n".join(f"- {date}: {i}" for i in ideas))
        touched.append(f"IDEAS.md (+{len(ideas)})")

    dec = s.get("DECISIONS", "")
    if dec and dec.lower() not in ("none", "(none)", "- none"):
        dec = re.sub(r"^#+\s*", f"## {date}: ", dec, flags=re.M)
        append(os.path.join(ctx, "DECISIONS.md"), "\n" + dec)
        touched.append("DECISIONS.md")

    done = [d.casefold() for d in items(s.get("DONE", ""))]
    rm = os.path.join(ctx, "ROADMAP.md")
    if done and os.path.exists(rm):
        lines, n = open(rm, encoding="utf-8").read().splitlines(), 0
        for k, l in enumerate(lines):
            m = re.match(r"^(\s*)- \[ \] (.+)$", l)
            if m and any(m.group(2).strip().casefold().startswith(d) for d in done):
                lines[k] = f"{m.group(1)}- [x] {m.group(2).strip()} ({date[:10]})"
                n += 1
        if n:
            write(rm, "\n".join(lines))
            touched.append(f"ROADMAP.md ({n} ticked)")
    print("wrote: " + ", ".join(touched))


if __name__ == "__main__":
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == "digest":
        digest(args[0], float(args[1]))
    elif cmd == "apply":
        apply(*args)
    else:
        sys.exit(f"unknown command {cmd}")
