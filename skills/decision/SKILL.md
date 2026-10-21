---
name: decision
description: Record an architectural or product decision (with context, choice, and consequences) in .context/DECISIONS.md so future sessions don't re-litigate it. Use when a non-obvious choice is made, or when the user says "decided", "let's go with", or "record that".
argument-hint: "<decision>"
---

Append to `.context/DECISIONS.md` (at the git root) with one Bash heredoc. Write it yourself, since you hold the reasoning:
```
## YYYY-MM-DD: <short title>
**Context:** <why a choice was needed, 1–2 lines>
**Decision:** <what was chosen; rejected alternatives in brief>
**Consequences:** <trade-offs and what this rules out>
```
Use `date +%F`. Stay under 8 lines. Confirm in one line.
