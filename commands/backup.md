---
name: backup
description: "Backup audit and setup — find out what would survive if this computer died tonight, then close the gaps"
allowed-tools: Read, Write, Edit, Bash, Glob, Task, AskUserQuestion
---

# Backup — the most important visit

Read `${CLAUDE_PLUGIN_ROOT}/skills/it-core/SKILL.md` first — the safety contract is binding, especially: admin work handed to the user, never touch existing backups (the guard hook also enforces `tmutil delete/disable` as out of bounds). Read `~/ITGuy/machine.md` if it exists. If `uname` is not `Darwin`, say this version supports Mac only and stop.

## Step 1: Audit what exists

Dispatch the `it-guy-pro:diagnostician` agent (via Task) for the backup area, plus these direct read-only checks:

- Time Machine: destination configured? latest backup date? (distinguish "no backup" from "backup disk not connected" — recipes in `macos-recipes`)
- iCloud Drive: `ls ~/Library/Mobile\ Documents/com~apple~CloudDocs 2>/dev/null` — present and syncing Desktop/Documents, or not
- External disks currently mounted: `ls /Volumes`

## Step 2: Map coverage against what matters

Build the coverage table from the user's actual key folders (profile Owner/Conventions first; otherwise Desktop, Documents, Pictures, plus anything they name):

| What | Where it lives | Covered by | Verdict |
|------|----------------|------------|---------|
| Photos | ~/Pictures | nothing | 🔴 would be lost |

Top line of the report answers the only question that matters, in one sentence: **"If this Mac died tonight, you would lose: …"**

## Step 3: Propose a strategy

Explain 3-2-1 in one plain sentence (three copies, two kinds of storage, one away from home) — then propose the smallest setup that closes the 🔴 rows, as an options table (Option | Cost | Effort | What it protects). Recommend exactly one. Do not recommend buying anything without naming a cheaper alternative in the same table.

## Step 4: Set it up — user does the clicking

Time Machine setup, disk formatting choices, and iCloud toggles live in System Settings and are the user's hands, not yours: give a numbered click-path for each step, wait for their "done", then **verify from the terminal** (e.g. `tmutil destinationinfo` now shows the disk; first backup running). Never format a disk yourself — if the chosen disk needs erasing, that is a Disk Utility walkthrough with an explicit "this erases everything currently on that disk" warning.

## Step 5: The restore drill (a backup that's never been restored from is a hope, not a backup)

Once at least one backup completed: pick one recent file with the user, restore a **copy** of it (never overwrite the live original), and verify with a checksum comparison (`md5 -q`) or a visual open. Report the drill's result in the audit.

## Step 6: Remember

Update the profile's System → Backups line and clear/add Watch List entries. Append the visit line to `~/ITGuy/visits.log`. Offer a calendar habit: re-run this audit quarterly.

## Errors

- No external disk and no budget for one → iCloud-only coverage of Desktop+Documents is honestly labeled as better-than-nothing, and the gap (Photos, large files) stays 🔴 on record.
- First backup will take hours → say so up front; the visit ends with the backup running, and verification of completion moves to the next checkup's Watch List.
