#!/usr/bin/env bash
# SessionStart hook: reply-prefix canary, for every project (not only ones with .context/).
# The tag checks that session-start instructions are still being followed; it is re-planted after /compact,
# and compaction itself is the signal that a hand-off and a fresh session may be due.
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
If the conversation has become very long, say so at the start of your reply and suggest a hand-off: /ctx:handoff (current goal, what's done, what's left, key files, open questions), then /clear.
EOF
if [ "$source" = compact ]; then
  echo "This session was just compacted, so earlier detail now exists only as a summary. In your next reply, mention this once and, if substantial work remains, suggest /ctx:handoff then /clear."
fi

# Pick up a hand-off left by the previous session. Kept outside the repo so it can't be committed by accident;
# projects with .context/ hand off through a session log instead.
h="$HOME/.cache/ctx/handoffs/$(tr / _ <<<"$root").md"
if [ -f "$h" ] && { [ "$source" = startup ] || [ "$source" = clear ]; }; then
  age=$(( ($(date +%s) - $(stat -c %Y "$h")) / 3600 ))
  echo
  echo "## Hand-off note (written ${age}h ago by a previous session; read it before anything else)"
  head -n 60 "$h"
  echo
  echo "Resume from this note. Once the user confirms the work is picked up, offer to delete $h so it isn't replayed."
fi
