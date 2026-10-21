---
name: resume
description: Restore project context from .context/ and recent git activity as a short briefing. Use at the start of a session, after switching workstations, or when asked "where were we" or "what's the status".
argument-hint: "[optional question about the project's history]"
---

Delegate to the `ctx:loader` agent (Haiku) and pass along any question in $ARGUMENTS. Show its briefing as-is. Don't read the .context files yourself unless the user asks for detail the briefing lacks.
