#!/usr/bin/env bash
# SessionStart hook: inject "where we left off" (no model call). Runs on startup/resume/clear/compact.
[ -n "$CTX_AUTOSAVE" ] && exit 0
input="$(cat)"
source="$(jq -r '.source // "startup"' <<<"$input" 2>/dev/null)"
root="$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" rev-parse --show-toplevel 2>/dev/null || echo "${CLAUDE_PROJECT_DIR:-$PWD}")"
ctx="$root/.context"
[ -d "$ctx" ] || exit 0
conf() { grep -E "^$1=" "$ctx/config" 2>/dev/null | tail -1 | cut -d= -f2 | sed 's/[[:space:]#].*//'; }

# Freshen remote info so we can warn about context saved on another workstation
if [ "$source" = startup ] && [ "$(conf autofetch)" != 0 ] && git -C "$root" rev-parse @{u} >/dev/null 2>&1; then
  GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes" timeout 4 git -C "$root" fetch -q 2>/dev/null
fi

echo "# Session continuity: where we left off"
if [ -f "$ctx/.autosave.lock" ] && ! flock -n "$ctx/.autosave.lock" true 2>/dev/null; then
  echo "NOTE: previous session's autosave is still running; details below may be one session stale."
fi
if git -C "$root" status -sb 2>/dev/null | head -1 | grep -q behind; then
  echo "WARNING: branch is behind its remote; another workstation may have newer context. Tell the user to \`git pull\` before continuing."
fi
[ -f "$ctx/STATE.md" ] && { echo; echo "## STATE.md"; head -n 40 "$ctx/STATE.md"; }
# Dated logs only: a stray monthly archive (log/2026-10.md) sorts after them
last="$(ls -1 "$ctx/log"/*.md 2>/dev/null | grep -E '/[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}-[^/]*\.md$' | sort | tail -1)"
if [ -n "$last" ]; then
  # Title and open threads only: Done and Notes are history, and STATE.md already carries the summary
  echo; echo "## Last session (${last#"$root"/})"; head -n 1 "$last"
  awk '/^(##|\*\*) *Open threads/{f=1; next} f && /^## /{exit} f' "$last" | head -n 20
fi
dirty="$(git -C "$root" status --porcelain 2>/dev/null | grep -v ' .context/' | head -15)"
[ -n "$dirty" ] && { echo; echo "## Uncommitted changes in working tree"; echo "$dirty"; }
echo
echo "Project memory lives in .context/ (committed; autosave logs each session on exit). Record non-obvious choices with /ctx:note decision and park tangents with /ctx:note idea. Don't re-litigate DECISIONS.md without new information."
if [ "$source" = startup ] || [ "$source" = clear ]; then
  echo "On the user's first message: if it's a greeting, \"continue\", or vague, open with a ≤3-line recap of where we left off and propose the next step from Open threads. Otherwise use this context silently."
fi
