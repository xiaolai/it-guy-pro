---
name: toolbox
description: "Your personal tool collection — list, run, evolve, or remove the tools the IT guy has built for you"
argument-hint: "[list|run <name>|evolve <name>|remove <name>]"
allowed-tools: Read, Write, Edit, Bash, Glob, Task, AskUserQuestion
---

# Toolbox — the tools you own

Read `${CLAUDE_PLUGIN_ROOT}/skills/it-core/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/skills/toolbox-contract/SKILL.md` first. If `uname` is not `Darwin`, say this version supports Mac only and stop.

If `~/ITGuy/toolbox.json` does not exist or holds no tools, **do not simply send the user away to `/it-guy-pro:automate`** — a user with an empty toolbox usually has no idea what is automatable, so telling them to go describe a chore is the dead end this catalogue exists to fix. Instead run the suggestion pass below and let them choose from something concrete.

Resolve the subcommand from `$ARGUMENTS`; empty means `list`.

## list

Read `~/ITGuy/toolbox.json` and render:

| Tool | What it does | Built | Last used | Runs | Stage |
|------|--------------|-------|-----------|------|-------|

Then check the evolution ladder's triggers: any tool with 5+ runs still at `script` stage gets one line offering the upgrade. If the registry references a folder that no longer exists, flag it as broken and offer `remove`.

**Staleness check** — a toolbox rots as quietly as a profile does:

- **Unused for 180+ days** → offer removal once. If declined, do not raise it again for another 180 days.
- **Broken by a system update** → run each tool's dry-run and report any that now error. A tool the user believes works but doesn't is worse than no tool: offer repair via `evolve`, and mark it in the registry so it is not silently recommended meanwhile.
- **A tool whose pattern no longer fires** (its chore stopped happening) is *not* stale — it is probably working. Say so rather than offering removal.

**Suggestion pass.** Read `${CLAUDE_PLUGIN_ROOT}/skills/toolbox-contract/references/pattern-catalogue.md` and run its signals, including the 30-day recency companions. Skip any pattern whose id appears in `declined`, and any whose id already appears as a `pattern` field on a built tool. Per the catalogue's per-command table this context allows **up to three** offers — the user came here to look at tools — highest count first, each a one-line offer containing the observed number, chosen via AskUserQuestion with a "none of these" option.

Recording declines follows catalogue rule 4: **"none of these" declines all three; picking one records nothing about the other two**, which stay eligible next time. Say nothing about a pattern below its threshold or with a zero 30-day count. If nothing fires, say the machine looks tidy and that `/it-guy-pro:automate` is there whenever a chore starts to annoy them — an honest empty result, not a failure.

## run <name>

1. Resolve the tool (fuzzy-match the name; if ambiguous, ask). Show its README's "What it does" line.
2. Run the dry-run (`bash run.sh` in the tool folder) and show the preview.
3. AskUserQuestion: apply for real? Yes → run with `--go`, show the summary line. No → stop, preview was free.
4. Update `last_used` and `runs` in the registry; append the visit line to `~/ITGuy/visits.log`.

## evolve <name>

1. Confirm the target stage with the user per the contract ladder (script → cli → scheduled), including what changes in plain language. Scheduling includes when it runs and how to stop it.
2. Dispatch the `it-guy-pro:toolsmith` agent (via Task) with the upgrade spec.
3. Show the toolsmith's report; append the visit line.

## remove <name>

1. Show the tool's README summary and its registry stats, and confirm with AskUserQuestion.
2. If the tool is `scheduled`, first unload its LaunchAgent (`launchctl bootout gui/$(id -u)/com.itguy.<name>`) and move the plist to the Trash.
3. Move `~/ITGuy/toolbox/<name>/` to the Trash (never rm — safety contract rule 2), remove its registry entry, append the visit line.

## Errors

- Named tool not in the registry → list what is, suggest the closest name.
- A tool's real run exits non-zero → show its error message verbatim, do not retry with `--go`, and offer `/it-guy-pro:fix` framing: diagnose why before running again.
