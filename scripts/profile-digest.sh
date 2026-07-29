#!/bin/bash
# it-guy-pro profile digest — SessionStart hook.
#
# If this machine has an IT Guy profile, print a compact pointer (~60
# tokens) so every session starts knowing the machine. Prints nothing when
# no profile exists — a user who never ran /it-guy-pro:onboard gets zero
# noise and zero token cost.

ROOT="$HOME/ITGuy"
[ -f "$ROOT/machine.md" ] || exit 0

last="none recorded"
if [ -f "$ROOT/visits.log" ]; then
  line="$(tail -1 "$ROOT/visits.log" 2>/dev/null)"
  [ -n "$line" ] && last="$line"
fi

tools=0
if [ -f "$ROOT/toolbox.json" ]; then
  # Occurrence count, not line count — the registry may be minified JSON.
  tools="$(grep -o '"name"' "$ROOT/toolbox.json" 2>/dev/null | wc -l | tr -d ' ')"
fi

cat <<EOF
it-guy-pro: this machine has an IT Guy profile.
- Profile: ~/ITGuy/machine.md — read it before doing any IT task (checkup, cleanup, organize, fix, automate, backup).
- Last visit: $last
- Toolbox: $tools tool(s) registered in ~/ITGuy/toolbox.json — check it before building anything new.
EOF
exit 0
