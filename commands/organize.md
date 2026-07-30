---
name: organize
description: "Organize files — Downloads triage, Desktop, date-sorted photos, content-classified PDFs. Every run is undoable."
argument-hint: "[downloads|desktop|photos|pdfs|undo]"
allowed-tools: Read, Write, Edit, Bash, Glob, Task, AskUserQuestion
---

# Organize — order without loss

Read `${CLAUDE_PLUGIN_ROOT}/skills/it-core/SKILL.md` first — the safety contract is binding, especially: dry-run first, undo manifest before batch moves, never overwrite. Read `~/ITGuy/machine.md` if it exists — its Conventions section overrides default destinations. If `uname` is not `Darwin`, say this version supports Mac only and stop.

## Step 0: Resolve the mode

- `$ARGUMENTS` names a mode (`downloads`, `desktop`, `photos`, `pdfs`, `undo`) → use it.
- Empty → use AskUserQuestion to pick one, describing each in plain language.
- `photos`/`pdfs` → also ask which folder to organize; verify it exists before proceeding.

## Mode: undo

1. List manifests in `~/ITGuy/undo/` newest first, with date, mode, and file count; let the user pick one (default: newest).
2. Reverse it per the procedure in `${CLAUDE_PLUGIN_ROOT}/skills/machine-profile/SKILL.md`: rows in reverse order, move each `moved_to` back to `moved_from`, skip rows whose destination no longer exists and report every skip.
3. Move the used manifest to the Trash; log the visit. Do not dispatch agents for undo — do it directly.

## Modes: downloads / desktop / photos / pdfs

1. **Plan**: dispatch the `mac-it-guy-pro:librarian` agent (via Task) in plan mode for the chosen scope. Its destination schemes are defined in the agent; profile Conventions override them.
2. **Show the plan**: file-by-file table (first 20 + exact total), plus what will be skipped and why. State clearly: nothing has moved yet.
3. **Approve**: AskUserQuestion — proceed as planned, adjust (take their changes, re-render the plan once), or cancel.
4. **Execute**: dispatch the librarian in execute mode with the approved plan. It writes the undo manifest before the first move.
5. **Report**: destinations table, count moved, the undo manifest path, and the one-line undo instruction (`/mac-it-guy-pro:organize undo`).

## Step: memory

Append the visit line to `~/ITGuy/visits.log`. If the user adjusted destinations in step 3, record the preference in the profile's Conventions section — that is how the IT guy learns their filing habits.

## Errors

- Target folder empty → say so and stop; log the visit as a no-op.
- Files locked/in use → skipped with plain-language cause, listed in the report.
- Full Disk Access missing → walk through the grant (steps in it-core), then resume.
