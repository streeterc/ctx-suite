---
name: handoff
description: Write a hand-off note (goal, done, left, key files, open questions) so a fresh session can pick up mid-task. Use before /clear or starting a new session, when the conversation has grown very long, when early context can no longer be recalled clearly, or when the user says "hand off" or "start fresh".
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
- **If `.context/` exists at the git root:** run the `/ctx:save` flow with this note as the summary (Goal → Title and Notes, Left → Open threads, Open questions → Open threads). The next session's start hook loads STATE.md and this log, so no HANDOFF.md is needed.
- **Otherwise:** write it to `HANDOFF.md` at the git root (or cwd), headed `# Hand-off: <date> <host>` (`date '+%F %H:%M'`, `hostname -s`). Overwrite any old one. The next session's start hook injects it.

Reply in two lines: where the note went, and "Run /clear (or open a new session) to continue fresh."
