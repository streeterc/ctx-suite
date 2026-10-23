#!/usr/bin/env bash
# SessionEnd / PreCompact hook: checkpoint the session into .context/ automatically.
# Spawns a detached headless Haiku run so it never blocks exit. Skips trivial sessions and
# only covers activity since the last log written on this host (so manual /ctx:save isn't duplicated).
[ -n "$CTX_AUTOSAVE" ] && exit 0                     # don't recurse from the child run
here="$(cd "$(dirname "$0")" && pwd)"
input="$(cat)"
if [ -z "$CTX_DETACHED" ]; then
  # Re-run in a new session so closing the terminal (SIGHUP) can't kill the slow Haiku run
  CTX_DETACHED=1 setsid -f "$here/autosave.sh" <<<"$input" >/dev/null 2>&1
  exit 0
fi
transcript="$(jq -r '.transcript_path // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
event="$(jq -r '.hook_event_name // "SessionEnd"' <<<"$input")"
root="$(git -C "${cwd:-$PWD}" rev-parse --show-toplevel 2>/dev/null || echo "${cwd:-$PWD}")"
[ -d "$root/.context" ] && [ -f "$transcript" ] || exit 0

cd "$root" || exit 0
# Wait for an autosave that is still running (e.g. PreCompact's) rather than dropping this one
exec 9>"$root/.context/.autosave.lock"; flock -w 900 9 || exit 0
host="$(hostname -s)"
# Cutoff = the start time in the newest log name from this host, not its mtime: a log is written minutes
# after its run starts, and work done in between would otherwise never be logged
last="$(ls -1 .context/log/*-"$host".md 2>/dev/null | sort | tail -1)"
stamp="$(basename "${last:-none}" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}')"
cutoff="$( [ -n "$stamp" ] && date -d "${stamp:0:10} ${stamp:11:2}:${stamp:13:2}" +%s || echo 0 )"
logfile=".context/log/$(date +%Y-%m-%d-%H%M)-$host.md"   # named before reading the transcript, see cutoff
digest="$(python3 "$here/extract.py" "$transcript" "$cutoff")" || exit 0
scribe="$(awk 'f>=2; /^---$/{f++}' "$here/../agents/scribe.md")"   # agent body without frontmatter
echo "=== $(date '+%F %T') $event $root" >>"$HOME/.cache/ctx-autosave.log"
# Lean run: only the file tools, no MCP servers or skill listing, and the scribe prompt in place of
# Claude Code's default system prompt (cuts the fixed load per turn from ~23k tokens to ~4k)
tools="Read,Write,Edit,Glob,Grep"
CTX_AUTOSAVE=1 claude -p --model haiku --no-session-persistence \
  --permission-mode acceptEdits --tools "$tools" --allowedTools "$tools" \
  --strict-mcp-config --disable-slash-commands \
  --system-prompt "$scribe" >>"$HOME/.cache/ctx-autosave.log" 2>&1 <<PROMPT
Task: save (automatic ${event} checkpoint). Date: $(date '+%F %H:%M'). Host: $host. Project root: $root
You have no Bash in this run: use the date and host given here instead of running date/hostname.
File tools need absolute paths: every .context path below is relative to the project root.
Write the session log to exactly: $root/$logfile  (title line should end with "(auto)").
Then update .context/STATE.md, ROADMAP.md, IDEAS.md, DECISIONS.md as your instructions say.
Most important: an accurate "Open threads / next steps" section capturing exactly what was in progress
at the END of the transcript, so the next session can resume mid-task.
Below is a condensed transcript of the work since the last checkpoint (tool calls in [brackets]):

$digest
PROMPT
# Git sync of .context/ only, per .context/config (autocommit=1 default, autopush=0 default)
conf() { grep -E "^$1=" .context/config 2>/dev/null | tail -1 | cut -d= -f2 | sed 's/[[:space:]#].*//'; }
if git rev-parse --git-dir >/dev/null 2>&1 && [ "$(conf autocommit)" != 0 ]; then
  git add -- .context ':!.context/.autosave.lock' && git commit -q -m "ctx: autosave ($host)" -- .context ':!.context/.autosave.lock'
  [ "$(conf autopush)" = 1 ] && GIT_TERMINAL_PROMPT=0 timeout 20 git push -q
fi
exit 0
