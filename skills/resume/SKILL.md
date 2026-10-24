---
name: resume
argument-hint: "[optional question about the project's history]"
disable-model-invocation: true
description: Briefing of where the project stands, from .context/ and git. The start hook already loads STATE.md and the last session's open threads; use this after a git pull or for more history.
---

Delegate to the `ctx:loader` agent (Haiku) and pass along any question in $ARGUMENTS. Show its briefing as-is. Don't read the .context files yourself unless the user asks for detail the briefing lacks.
