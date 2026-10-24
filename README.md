# ctx: cross-session project memory for Claude Code

Keeps a `.context/` directory in each project (STATE, ROADMAP, IDEAS, DECISIONS, per-session logs),
committed to git so context follows the project between sessions and machines.

## Install (any machine)
```
/plugin marketplace add <path-or-git-url-of-this-repo>
/plugin install ctx@ctx-suite
```
Requires `jq`, `flock`, `setsid`, `python3`, and `claude` on the PATH that hooks see (autosave runs `claude -p`).

## Use
- `/ctx:init`: set up `.context/` in a project (once), then commit it.
- `/ctx:note idea|decision|roadmap …`: quick records, or show the roadmap. `/ctx:curate`: weekly tidy.
- `/ctx:save`: checkpoint mid-session (autosave covers exit and compaction). `/ctx:resume`: briefing after a `git pull`.
  These two, `/ctx:init` and `/ctx:curate` are typed by you only, so their descriptions don't cost tokens every session.
- `/ctx:handoff`: hand-off note (goal, done, left, key files, open questions) before starting fresh.
  Writes a session log in `.context/` projects; elsewhere it writes `~/.cache/ctx/handoffs/<project path>.md`,
  outside the repo.

## Hooks
- **SessionStart** (every project): after a compaction, a one-line nudge to hand off; on startup/clear, a pending
  hand-off note. In projects with `.context/` it injects STATE.md, the last session's title and open threads, and
  uncommitted changes. With `lean=1` in `.context/config` it injects only a one-line pointer instead, and Claude reads
  STATE.md itself when the task continues earlier work.
- **SessionEnd / PreCompact** autosave: a detached, tool-less, single-turn Haiku call summarises the work since this
  host's last log; With `lean=1`, sessions without file edits are skipped.
  `hooks/autosave.py` writes the log, STATE.md, ideas, decisions and roadmap ticks, then the hook commits
  `.context/` (per `.context/config`: `autocommit`, `autopush`, `autofetch`). This is the only place
  commits happen; `/ctx:save` and `/ctx:handoff` leave them to it unless you ask. Output, with token usage and cost per run:
  `~/.cache/ctx-autosave.log`.

Log files are named `YYYY-MM-DD-HHMM-<host>.md`, so two machines never edit the same file.
