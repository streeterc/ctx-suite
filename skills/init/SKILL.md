---
name: init
description: Set up the .context/ project-memory system (STATE, ROADMAP, IDEAS, DECISIONS, session logs) in the current project so context persists across sessions and workstations.
disable-model-invocation: true
---

Create this layout at the git root (or cwd if there's no repo). Never overwrite an existing `.context/` file.
```
.context/
  STATE.md        # ≤40 lines. Snapshot: Focus / In progress / Next steps / Blockers / Updated
  ROADMAP.md      # ## Now / ## Next / ## Later / ## Done, with - [ ] checkboxes
  IDEAS.md        # - YYYY-MM-DD: idea  (newest at the bottom)
  DECISIONS.md    # ## YYYY-MM-DD: Title / **Context:** / **Decision:** / **Consequences:**
  log/            # one file per session: YYYY-MM-DD-HHMM-<host>.md (keeps merges between workstations conflict-free)
  log/archive/    # monthly rollups written by /ctx:curate
  config
```
1. Seed STATE.md and ROADMAP.md from the README, package manifests, a TODO/FIXME grep and `git log --oneline -20`. Label anything inferred `(inferred)`.
2. Write `config` with `autocommit=1`, `autopush=0`, `autofetch=1`, `lean=0`, one per line, each preceded by its own `# comment` line (never a comment on the value line). `lean=1` (opt-in for now) means the start hook injects only a one-line pointer, and autosave skips sessions without edits.
3. If CLAUDE.md exists and doesn't mention .context, append:
   `## Project context\nLiving context lives in .context/ (read STATE.md when a task continues earlier work). Autosave logs each session on exit.`
4. Append `.context/.autosave.lock` to the repo's `.gitignore` if it isn't there.

Report the files in one or two lines, then suggest `git add .context && git commit -m "Add .context project memory"` so other workstations get it.
