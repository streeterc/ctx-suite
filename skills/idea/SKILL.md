---
name: idea
description: Capture an idea in .context/IDEAS.md without derailing the current task. Use when the user says "idea:", "note for later", "we should eventually", or "park this".
argument-hint: "<idea text>"
---

Append one line with a single Bash command (no subagent; this is cheaper inline):
`printf -- '- %s: %s\n' "$(date +%F)" "<idea, tightened to one line>" >> "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.context/IDEAS.md"`
If $ARGUMENTS is empty, take the idea from the most recent discussion. Confirm in ≤1 line, then go back to the task you were on.
