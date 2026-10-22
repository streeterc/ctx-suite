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
- `/ctx:save`: checkpoint the session. `/ctx:resume`: briefing of where things stand.
- `/ctx:idea`, `/ctx:decision`, `/ctx:roadmap`: quick records. `/ctx:curate`: weekly tidy.
- `/ctx:handoff`: hand-off note (goal, done, left, key files, open questions) before starting fresh.
  Goes through `/ctx:save` in `.context/` projects; elsewhere it writes `HANDOFF.md`.

## Hooks
- **SessionStart canary** (every project): tells Claude to start every reply with `[<hostname>]`. If the tag stops
  appearing, the start of the session has been lost: run `/ctx:handoff`, then `/clear`. Claude is also told to say so
  when the session gets very long. It's planted again after compaction, and a fresh `HANDOFF.md` is injected on startup/clear.
  Opt out with `CTX_CANARY=0` in the environment or `canary=0` in `.context/config`.
- **SessionStart** injects STATE.md, the last session log, and uncommitted changes (projects with `.context/` only).
- **SessionEnd / PreCompact** autosave: a detached Haiku run writes a log covering work since this host's last log,
  then commits `.context/` (per `.context/config`: `autocommit`, `autopush`, `autofetch`). Output: `~/.cache/ctx-autosave.log`.

Log files are named `YYYY-MM-DD-HHMM-<host>.md`, so two machines never edit the same file.
