---
name: decision
description: Record an architectural or product decision (with context, choice, and consequences) in .context/DECISIONS.md so future sessions don't re-litigate it. Use when a non-obvious choice is made, or when the user says "decided", "let's go with", or "record that".
argument-hint: "<decision>"
---

Append to `.context/DECISIONS.md` with one Bash command. Write it yourself, since you hold the reasoning; the quoted heredoc keeps `$` and backticks in the text literal:
```
f="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.context/DECISIONS.md"
if [ -d "${f%/*}" ]; then { printf '\n## %s: ' "$(date +%F)"; cat <<'DECISION'; } >> "$f"
<short title>
**Context:** <why a choice was needed, 1–2 lines>
**Decision:** <what was chosen; rejected alternatives in brief>
**Consequences:** <trade-offs and what this rules out>
DECISION
else echo "No .context/ here; run /ctx:init first"; fi
```
Stay under 8 lines. Confirm in one line.
