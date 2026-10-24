---
name: note
description: Record an idea, a decision, or a roadmap change in .context/, or show the roadmap. Use on "idea:", "park this", "decided", "let's go with", "record that", or when asked what's planned or to add/tick a roadmap item.
argument-hint: "idea <text> | decision <text> | roadmap [show | add <item> [now|next|later] | done <item> | move <item> <section>]"
---

Work inline (no subagent). If `.context/` is missing at the git root, say "No .context/ here; run /ctx:init first" and stop. If $ARGUMENTS gives no kind, pick it from the discussion. Confirm in one line, then go back to the task you were on.

**idea**: append one line with a single Bash command. The quoted heredoc keeps `$`, backticks and quotes literal:
```
f="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.context/IDEAS.md"
{ printf -- '- %s: ' "$(date +%F)"; cat <<'IDEA'; } >> "$f"
<idea, tightened to one line>
IDEA
```

**decision**: write it yourself, since you hold the reasoning. Stay under 8 lines:
```
f="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.context/DECISIONS.md"
{ printf '\n## %s: ' "$(date +%F)"; cat <<'DECISION'; } >> "$f"
<short title>
**Context:** <why a choice was needed, 1–2 lines>
**Decision:** <what was chosen; rejected alternatives in brief>
**Consequences:** <trade-offs and what this rules out>
DECISION
```

**roadmap** (`.context/ROADMAP.md`, sections Now / Next / Later / Done):
- **show** or no args: print the Now and Next sections (Later only if asked). If asked what to work on next, recommend one item from Now, using STATE.md.
- **add / done / move**: edit directly with Edit. Add under the section given (default: Next). For `done`, tick it in place and append ` (<date +%F>)`.
- A bigger reorganisation: suggest /ctx:curate.
