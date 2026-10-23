---
name: init
description: Set up the .context/ project-memory system (STATE, ROADMAP, IDEAS, DECISIONS, session logs) in the current project so context persists across sessions and workstations.
disable-model-invocation: true
---

Delegate to the `ctx:scribe` agent with the task **init** for the current project, overriding its model to `sonnet`: seeding STATE.md and ROADMAP.md is inference-heavy and runs once per project, so it's worth more than Haiku. When it returns, append `.context/.autosave.lock` to the repo's `.gitignore` if it isn't there. Relay its file list in one or two lines. Then suggest: `git add .context && git commit -m "Add .context project memory"` so other workstations get it.
