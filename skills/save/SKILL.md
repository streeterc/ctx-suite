---
name: save
description: Checkpoint the current session into .context/ by writing a session log, refreshing STATE.md, ticking roadmap items, and capturing ideas and decisions. Use at the end of meaningful work, before switching machines, before /compact, or when the user says "save context", "log this", or "checkpoint".
argument-hint: "[optional note or focus]"
---

You hold the session knowledge; `ctx:scribe` (Haiku) does the file work. Keep your own output small.

1. Draft a terse summary of this session (≤25 bullets total, facts only) under these headings:
   - **Title** (one line)
   - **Done** (what changed and why)
   - **Changed files** (paths)
   - **Open threads / next steps**
   - **Decisions** (with the reason for each)
   - **Ideas** raised but not acted on
   - **Roadmap items completed**
   Include anything from $ARGUMENTS. Leave out empty headings. Don't re-read files to do this; work from what you already know.
2. Call the `ctx:scribe` agent with task **save** and the summary.
3. Report back in one line. Commit `.context/` only if the user asks, or if they have asked for that before in this project.
