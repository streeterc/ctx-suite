#!/usr/bin/env bash
# SessionStart hook: inject "where we left off" (no model call). Runs on startup/resume/clear/compact.
# Every project: hand-off pickup and a post-compact nudge. Projects with .context/: STATE and open threads,
# or with lean=1 in .context/config only a one-line pointer that Claude follows when the task needs it.
[ -n "$CTX_AUTOSAVE" ] && exit 0
input="$(cat)"
source="$(jq -r '.source // "startup"' <<<"$input" 2>/dev/null)"
root="$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" rev-parse --show-toplevel 2>/dev/null || echo "${CLAUDE_PROJECT_DIR:-$PWD}")"
ctx="$root/.context"
fresh() { [ "$source" = startup ] || [ "$source" = clear ]; }

if [ "$source" = compact ]; then
  echo "This session was just compacted, so earlier detail now exists only as a summary. In your next reply, mention this once and, if substantial work remains, suggest /ctx:handoff then /clear."
fi

# Pick up a hand-off left by the previous session. Kept outside the repo so it can't be committed by accident;
# projects with .context/ hand off through a session log instead.
h="$HOME/.cache/ctx/handoffs/$(tr / _ <<<"$root").md"
if [ -f "$h" ] && fresh; then
  age=$(( ($(date +%s) - $(stat -c %Y "$h")) / 3600 ))
  echo "## Hand-off note (written ${age}h ago by a previous session; read it before anything else)"
  head -n 60 "$h"
  echo
  echo "Resume from this note. Once the user confirms the work is picked up, offer to delete $h so it isn't replayed."
fi

[ -d "$ctx" ] || exit 0
conf() { grep -E "^$1=" "$ctx/config" 2>/dev/null | tail -1 | cut -d= -f2 | sed 's/[[:space:]#].*//'; }

# Freshen remote info so we can warn about context saved on another workstation
if [ "$source" = startup ] && [ "$(conf autofetch)" != 0 ] && git -C "$root" rev-parse @{u} >/dev/null 2>&1; then
  GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes" timeout 4 git -C "$root" fetch -q 2>/dev/null
fi
behind() { git -C "$root" status -sb 2>/dev/null | head -1 | grep -q behind; }
# Dated logs only: a stray monthly archive (log/2026-10.md) sorts after them
last="$(ls -1 "$ctx/log"/*.md 2>/dev/null | grep -E '/[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}-[^/]*\.md$' | sort | tail -1)"
threads() { awk '/^(##|\*\*) *Open threads/{f=1; next} f && /^## /{exit} f' "$last" | head -n 20; }

if [ "$(conf lean)" = 1 ]; then
  # Mid-session the conversation already holds this; only fresh sessions get the pointer
  fresh || exit 0
  n=0; [ -n "$last" ] && n="$(threads | grep -cE '^\s*[-*0-9]')"
  printf 'ctx: project memory in .context/'
  [ -n "$last" ] && printf ' (last session: %s; %s open threads)' "$(head -n 1 "$last" | sed 's/^# *//')" "$n"
  echo ". Read .context/STATE.md${last:+ and the Open threads in ${last#"$root"/}} first only if the user's message continues earlier work, asks where things stand, or is a greeting or \"continue\" (then open with a ≤3-line recap and the next step). Otherwise ignore .context/ unless the task needs project history."
  behind && echo "WARNING: branch is behind its remote; another workstation may have newer context. Tell the user to \`git pull\` before continuing."
  exit 0
fi

echo "# Session continuity: where we left off"
if [ -f "$ctx/.autosave.lock" ] && ! flock -n "$ctx/.autosave.lock" true 2>/dev/null; then
  echo "NOTE: previous session's autosave is still running; details below may be one session stale."
fi
behind && echo "WARNING: branch is behind its remote; another workstation may have newer context. Tell the user to \`git pull\` before continuing."
[ -f "$ctx/STATE.md" ] && { echo; echo "## STATE.md"; head -n 40 "$ctx/STATE.md"; }
if [ -n "$last" ]; then
  # Title and open threads only: Done and Notes are history, and STATE.md already carries the summary
  echo; echo "## Last session (${last#"$root"/})"; head -n 1 "$last"
  threads
fi
dirty="$(git -C "$root" status --porcelain 2>/dev/null | grep -v ' .context/' | head -15)"
[ -n "$dirty" ] && { echo; echo "## Uncommitted changes in working tree"; echo "$dirty"; }
echo
echo "Project memory lives in .context/ (committed; autosave logs each session on exit). Record non-obvious choices with /ctx:note decision and park tangents with /ctx:note idea. Don't re-litigate DECISIONS.md without new information."
if fresh; then
  echo "On the user's first message: if it's a greeting, \"continue\", or vague, open with a ≤3-line recap of where we left off and propose the next step from Open threads. Otherwise use this context silently."
fi
