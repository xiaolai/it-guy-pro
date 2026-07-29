---
name: machine-profile
description: Schema and update rules for the machine profile (~/ITGuy/machine.md), the visit log (~/ITGuy/visits.log), and undo manifests (~/ITGuy/undo/). Load when creating, reading, or updating what the IT guy remembers about this machine.
---

# Machine Profile

The profile is the IT guy's memory. It is a plain Markdown file the user can open and read — never a hidden database. Everything in it must be something the user could verify themselves.

## `~/ITGuy/machine.md` template

```markdown
# This Machine

Updated: YYYY-MM-DD by /it-guy-pro:<command>
IT guy: <name>

## Hardware
- Model: <e.g. MacBook Air M2, 2022>
- Memory: <e.g. 16 GB>
- Disk: <e.g. 500 GB, 41 GB free as of YYYY-MM-DD>
- Battery: <cycle count + condition, or "desktop — no battery">

## System
- macOS: <version name + number>
- Backups: <e.g. "Time Machine to 'Backup2TB', last ran YYYY-MM-DD" or "NONE — flagged">

## Owner
- Work: <profession / what they use the computer for, in their own words>
- Comfort level: <beginner | comfortable | technical>
- Goals: <what "production tool" means to them, 1–3 bullets>

## Conventions
- <folder habits, e.g. "Screenshots pile up on Desktop; wants them auto-filed">
- <naming habits, e.g. "Prefers YYYY-MM-DD prefixes on documents">

## Known Quirks
- YYYY-MM-DD: <recurring issue or hardware oddity, newest first>

## Watch List
- <things to re-check on next visit, e.g. "disk was 92% full on 2026-07-29">
```

## Field sources

Fill hardware/system fields from real commands (exact recipes in the `macos-recipes` skill), never from guesses. Fill Owner and Conventions only from what the user actually said.

## The `IT guy:` line

- Set once at onboarding from the user's answer; omit the line entirely if they chose no name.
- The exact format `IT guy: <name>` on its own line matters — the SessionStart digest greps for this prefix to inject the calling convention (`<name>_`, name + underscore) into every session.
- Renamed only via `/it-guy-pro:profile update`, never spontaneously.
- The name changes voice, nothing else — see the persona rule in the `it-core` skill.

## Update rules

1. **Cap: 120 lines.** When over, delete the oldest Known Quirks entries first, then compress Conventions.
2. **Newest first** in Known Quirks and Watch List.
3. **Update, don't append**: hardware/system facts are replaced in place with a fresh `Updated:` date.
4. **Never store**: passwords, serial numbers, IP addresses, Wi-Fi names, account emails. If the user volunteers one, leave it out and say why.
5. Every command that learns something durable (a quirk, a convention, a fixed problem) writes it here in the same run — memory that only lives in the conversation is lost.

## `~/ITGuy/visits.log`

Append-only, one line per command run, format defined in the `it-core` skill. Never edit or delete existing lines.

## Undo manifests — `~/ITGuy/undo/`

Before any batch move/rename, write `<YYYY-MM-DD-HHMM>-<command>-<mode>.csv`:

```csv
moved_from,moved_to
/Users/name/Downloads/report.pdf,/Users/name/Documents/Invoices/2026/report.pdf
```

- One row per file, full absolute paths, written **before** the first move executes.
- To undo: process rows in reverse order, move `moved_to` back to `moved_from`, skipping rows where the destination no longer exists (report skipped rows to the user).
- Keep the 20 most recent manifests; move older ones to the Trash during cleanup runs.
