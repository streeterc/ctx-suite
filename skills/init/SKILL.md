---
name: init
description: Set up the .context/ project-memory system (STATE, ROADMAP, IDEAS, DECISIONS, session logs) in the current project so context persists across sessions and workstations.
disable-model-invocation: true
---

Delegate to the `ctx:scribe` agent with the task **init** for the current project. When it returns, check that `.gitignore` contains `.context/.autosave.lock` and append it if not (the agent sometimes skips this). Relay its file list in one or two lines. Then suggest: `git add .context && git commit -m "Add .context project memory"` so other workstations get it.
