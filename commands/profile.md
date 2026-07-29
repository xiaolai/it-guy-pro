---
name: profile
description: "Show or update what the IT guy remembers about this machine — the memory is yours to read and edit"
argument-hint: "[show|update|forget]"
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# Profile — auditable memory

Read `${CLAUDE_PLUGIN_ROOT}/skills/machine-profile/SKILL.md` first — schema and update rules are binding. If `uname` is not `Darwin`, say this version supports Mac only and stop. If `~/ITGuy/machine.md` does not exist, say there is no profile yet and point to `/it-guy-pro:onboard` — then stop.

Resolve the subcommand from `$ARGUMENTS`; empty means `show`.

## show

Print `~/ITGuy/machine.md` verbatim, then a two-line footer:

- Visits on record: count of lines in `~/ITGuy/visits.log`, with the date of the first and the latest.
- "This file is the IT guy's entire memory of this machine. Edit it or delete any line — whatever it says is what I'll believe next visit."

## update

1. Use AskUserQuestion to find out what changed (options: my work/goals changed, my folder habits changed, remove something that's wrong, something else).
2. Apply the edit to the right section, respecting the schema's rules: 120-line cap, newest-first quirks, replace-in-place for facts, and never store passwords, serial numbers, IPs, or account emails — if the user offers one, decline it and say why in one sentence.
3. Show a before/after diff of the changed lines.
4. Append the visit line to `~/ITGuy/visits.log`.

## forget

Confirm with AskUserQuestion, listing exactly what will be forgotten: the profile, the visit history, or everything in `~/ITGuy` except the toolbox (tools are the user's property and are only removed via `/it-guy-pro:toolbox remove`). On yes: move the chosen files to the Trash (never rm — they can still be recovered until the user empties the Trash). Say what was forgotten and that the Trash holds the copies.

## Errors

- Profile exists but is malformed (missing sections) → show it anyway, note which sections the schema expects, and offer to restructure it without losing any of the user's own lines.
