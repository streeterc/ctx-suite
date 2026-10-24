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
- **SessionStart canary** (every project): tells Claude to start every reply with `[<hostname>]`. If the tag stops
  appearing, Claude has stopped following its session-start instructions; that's a cue to run `/ctx:handoff`, then
  `/clear`. Claude is also told to flag very long sessions, and after a compaction to suggest a hand-off once. The tag is
  planted again after compaction, and a pending hand-off note is injected on startup/clear.
  Opt out with `CTX_CANARY=0` in the environment or `canary=0` in `.context/config`.
- **SessionStart** injects STATE.md, the last session's title and open threads, and uncommitted changes (projects with
  `.context/` only).
- **SessionEnd / PreCompact** autosave: a detached, tool-less, single-turn Haiku call summarises the work since this
  host's last log; `hooks/autosave.py` writes the log, STATE.md, ideas, decisions and roadmap ticks, then the hook commits
  `.context/` (per `.context/config`: `autocommit`, `autopush`, `autofetch`). This is the only place
  commits happen; `/ctx:save` and the agents leave them to it unless you ask. Output, with token usage and cost per run:
  `~/.cache/ctx-autosave.log`.

Log files are named `YYYY-MM-DD-HHMM-<host>.md`, so two machines never edit the same file.
