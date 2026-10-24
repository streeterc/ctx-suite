---
name: handoff
description: Write a hand-off note (goal, done, left, key files, open questions) so a fresh session can pick up mid-task. Use before /clear or starting a new session, when the conversation has grown very long or has been compacted, or when the user says "hand off" or "start fresh".
argument-hint: "[optional note]"
---

You hold the session knowledge. Work from what you already know; don't re-read files to do this.

Draft the note (≤30 lines, facts only, include anything from $ARGUMENTS):
- **Goal**: what we're ultimately trying to achieve
- **Done**: what changed and why
- **Left**: remaining steps, in order. Be precise about what was mid-flight (file, function, step)
- **Key files**: paths, with one line each on their role
- **Open questions**: anything undecided or waiting on the user

Then:
- **If `.context/` exists at the git root:** write it as a session log `.context/log/<date +%Y-%m-%d-%H%M>-<hostname -s>.md`: `# <date> <host> — <title from Goal>`, then **Done**, **Open threads / next steps** (Left, then Open questions), **Notes** (Goal and Key files). Update STATE.md's In progress and Next steps to match. The next session's start hook points at this log, so no HANDOFF.md is needed.
- **Otherwise:** write it outside the repo, so it can't be committed by accident, to the path printed by
  `echo "$HOME/.cache/ctx/handoffs/$( (git rev-parse --show-toplevel 2>/dev/null || pwd) | tr / _).md"`
  (create the directory if needed), headed `# Hand-off: <date> <host>` (`date '+%F %H:%M'`, `hostname -s`). Overwrite any old one. The next session's start hook injects it.

Reply in two lines: where the note went, and "Run /clear (or open a new session) to continue fresh."
