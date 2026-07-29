---
name: checkup
description: "Full health report — disk, memory, startup items, updates, backups, battery — in plain language"
argument-hint: "[--html]"
allowed-tools: Read, Write, Bash, Glob, Task, AskUserQuestion
---

# Checkup — the regular health visit

Read `${CLAUDE_PLUGIN_ROOT}/skills/it-core/SKILL.md` first — the safety contract and report format are binding. Read `~/ITGuy/machine.md` if it exists (compare today's findings against its Watch List). If `uname` is not `Darwin`, say this version supports Mac only and stop.

This command is read-only: it diagnoses and recommends, it changes nothing.

## Step 1: Gather evidence

Dispatch the `it-guy-pro:diagnostician` agent (via Task) for all six areas: disk, memory & CPU, startup, updates, backups, hardware.

## Step 2: Render the report

Use the it-core report format exactly: plain-language top line with the overall verdict, findings table (Area | Status | What I found | What I suggest, with 🟢🟡🔴), then exactly one recommended next step phrased as an offer — the highest-impact 🔴 item, or the top 🟡 if nothing is red.

Rules:

- Every startup item is named in plain language ("Google's software updater"), never just its plist filename.
- Backup findings distinguish "no backup configured" (🔴) from "backup disk not connected today" (🟡).
- A diagnostic that could not run appears as 🟡 "couldn't check" with the one-sentence reason — never silently dropped.

## Step 3: If `--html` was passed (or the user asks for a keepable copy)

Save a self-contained HTML version to `~/ITGuy/reports/YYYY-MM-DD-checkup.html`: inline CSS only, no external requests, readable on a phone, same content as the chat report. Then `open` it and tell the user where it lives.

## Step 4: Update memory

- `~/ITGuy/machine.md` exists → refresh Hardware/System facts in place (new `Updated:` date), resolve or extend Watch List entries this checkup confirms or clears.
- No profile → append a line to the report: running `/it-guy-pro:onboard` lets the IT guy remember this machine between visits.
- Append the visit line to `~/ITGuy/visits.log` (create `~/ITGuy/` if missing).

## Errors

- Full Disk Access missing → the report still renders with the areas that worked; the permission gap becomes its own 🟡 row with the grant walkthrough from it-core.
- Diagnostician returns nothing usable → say the checkup failed and show the raw error; never invent findings.
