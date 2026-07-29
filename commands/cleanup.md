---
name: cleanup
description: "Guided disk space reclaim — scan, show findings with sizes, move only approved items to Trash"
allowed-tools: Read, Bash, Glob, Task, AskUserQuestion
---

# Cleanup — reclaim space without breaking anything

Read `${CLAUDE_PLUGIN_ROOT}/skills/it-core/SKILL.md` first — the safety contract is binding, especially: Trash never rm, only the user empties the Trash, dry-run first. Read `~/ITGuy/machine.md` if it exists. If `uname` is not `Darwin`, say this version supports Mac only and stop.

## Step 1: Scan (changes nothing)

Record free space now (`df -h /`). Dispatch the `it-guy-pro:janitor` agent (via Task) in **scan mode** across all its categories: app caches, old downloads, large stale files, duplicates, developer leftovers, Trash size.

## Step 2: Present findings and let the user choose

Show the janitor's candidate table (Category | Items | Size | Risk) in plain language. Then use AskUserQuestion (multiSelect) to pick categories to clean. Rules:

- Large stale files and duplicates are **never** offered as a bulk category — if selected, walk through them item by item (or group by group) with an explicit keep/Trash choice per item.
- If total reclaimable space is under 1 GB, say cleanup isn't worth it right now and show what's actually using the disk instead (top `du` folders).

## Step 3: Execute the approved list only

Dispatch the janitor in **execute mode** with the exact approved categories/paths. Nothing outside the approved list moves — no matter how obviously junk it looks.

## Step 4: Report and log

- Before/after free space from `df -h /`, and the total now sitting in the Trash.
- Close with: emptying the Trash in Finder is what makes the space real, and that step is the user's.
- Append the visit line to `~/ITGuy/visits.log`. If disk pressure was on the profile's Watch List, update it with today's numbers.

## Errors

- Locked or permission-blocked files → report each with a plain-language cause; never force.
- The guard hook blocks an rm → that is the contract working; the janitor must use the Trash recipe. If it happens, note it and continue via Trash.
- User approves nothing → fine; report the scan findings as a reference and log the visit as scan-only.
