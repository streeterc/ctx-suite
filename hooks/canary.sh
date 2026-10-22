#!/usr/bin/env bash
# SessionStart hook: context-health canary, for every project (not only ones with .context/).
# The reply prefix is planted at the very start of context; if replies stop carrying it, the early
# instructions have been lost and it's time for a hand-off and a fresh session. Re-planted after /compact.
# Opt out: CTX_CANARY=0 in the environment, or canary=0 in .context/config.
[ -n "$CTX_AUTOSAVE" ] && exit 0
[ "${CTX_CANARY:-1}" = 0 ] && exit 0
input="$(cat)"
source="$(jq -r '.source // "startup"' <<<"$input" 2>/dev/null)"
root="$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" rev-parse --show-toplevel 2>/dev/null || echo "${CLAUDE_PROJECT_DIR:-$PWD}")"
[ "$(grep -E '^canary=' "$root/.context/config" 2>/dev/null | tail -1 | cut -d= -f2 | sed 's/[[:space:]#].*//')" = 0 ] && exit 0
tag="[$(hostname -s)]"

cat <<EOF
# Canary check
Start every reply with "$tag"; no exceptions, including short replies and tool summaries.
If you notice you can no longer recall the earliest parts of this session clearly, or the conversation has become very long, say so at the start of your reply and suggest the user start a fresh session.
Before starting fresh, write a hand-off note with /ctx:handoff (current goal, what's done, what's left, key files, open questions), then suggest /clear.
EOF

# Pick up a hand-off left by the previous session (projects without .context/; those resume from STATE.md and the log)
h="$root/HANDOFF.md"
if [ -f "$h" ] && { [ "$source" = startup ] || [ "$source" = clear ]; }; then
  age=$(( ($(date +%s) - $(stat -c %Y "$h")) / 3600 ))
  echo
  echo "## HANDOFF.md (written ${age}h ago by a previous session; read it before anything else)"
  head -n 60 "$h"
  echo
  echo "Resume from this note. Once the user confirms the work is picked up, offer to delete HANDOFF.md so it isn't replayed."
fi
