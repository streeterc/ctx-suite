#!/usr/bin/env bash
# SessionEnd / PreCompact hook: checkpoint the session into .context/ automatically.
# Spawns a detached headless Haiku run so it never blocks exit. Skips trivial sessions and
# only covers activity since the last log written on this host (so a manual /ctx:save isn't duplicated).
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
conf() { grep -E "^$1=" .context/config 2>/dev/null | tail -1 | cut -d= -f2 | sed 's/[[:space:]#].*//'; }
# Wait for an autosave that is still running (e.g. PreCompact's) rather than dropping this one
exec 9>"$root/.context/.autosave.lock"; flock -w 900 9 || exit 0
host="$(hostname -s)"
# Cutoff = the start time in the newest log name from this host, not its mtime: a log is written minutes
# after its run starts, and work done in between would otherwise never be logged
last="$(ls -1 .context/log/*-"$host".md 2>/dev/null | sort | tail -1)"
stamp="$(basename "${last:-none}" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}')"
cutoff="$( [ -n "$stamp" ] && date -d "${stamp:0:10} ${stamp:11:2}:${stamp:13:2}" +%s || echo 0 )"
logfile=".context/log/$(date +%Y-%m-%d-%H%M)-$host.md"   # named before reading the transcript, see cutoff
digest="$(CTX_LEAN="$(conf lean)" python3 "$here/autosave.py" digest "$transcript" "$cutoff")" || exit 0
out="$HOME/.cache/ctx-autosave.log"
echo "=== $(date '+%F %T') $event $root" >>"$out"
# One-shot run: no tools, so Haiku answers in a single turn and autosave.py writes the files. An agent loop
# re-sent the digest and every file it had read on each of ~8 turns.
CTX_AUTOSAVE=1 claude -p --model haiku --no-session-persistence --tools "" \
  --strict-mcp-config --disable-slash-commands --output-format json \
  --system-prompt "$(cat "$here/autosave-prompt.md")" 2>>"$out" <<PROMPT |
Automatic ${event} checkpoint. Date: $(date '+%F %H:%M'). Host: $host.

Current STATE.md:
$(cat .context/STATE.md 2>/dev/null || echo "(none yet)")

Decisions already recorded (never repeat or reword these):
$(grep -E '^## ' .context/DECISIONS.md 2>/dev/null | sed 's/^## [0-9-]*:* *//' || true)

Open roadmap items:
$(grep -E '^\s*- \[ \]' .context/ROADMAP.md 2>/dev/null | sed 's/^\s*- \[ \] /- /' || true)

Condensed transcript of the work since the last checkpoint (tool calls in [brackets]):

$digest
PROMPT
  python3 "$here/autosave.py" apply "$root" "$logfile" "$(date +%F)" "$host" >>"$out" 2>&1 || exit 0
# Git sync of .context/ only, per .context/config (autocommit=1 default, autopush=0 default)
if git rev-parse --git-dir >/dev/null 2>&1 && [ "$(conf autocommit)" != 0 ]; then
  git add -- .context ':!.context/.autosave.lock' && git commit -q -m "ctx: autosave ($host)" -- .context ':!.context/.autosave.lock'
  [ "$(conf autopush)" = 1 ] && GIT_TERMINAL_PROMPT=0 timeout 20 git push -q
fi
exit 0
