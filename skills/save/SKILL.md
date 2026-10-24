---
name: save
argument-hint: "[optional note or focus]"
disable-model-invocation: true
description: Checkpoint the session into .context/ now (log, STATE.md, roadmap, ideas, decisions). Autosave already does this on exit and /compact; use this only to save mid-session.
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
3. Report back in one line. Don't commit: autosave commits `.context/` when the session ends (per `autocommit` in `.context/config`). Commit now only if the user asks.
