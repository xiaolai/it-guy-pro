---
name: macos-recipes
description: Exact macOS commands for IT diagnostics and safe actions — disk, memory, startup items, updates, Time Machine, battery, SMART, duplicate detection, Trash-based deletion, HEIC conversion, photo dates, launchd scheduling. Load before running any diagnostic or maintenance command on a Mac.
---

# macOS Recipes

Exact commands, expected output shape, and gotchas. Use these verbatim rather than improvising — the gotchas are the value.

## Diagnostics (read-only)

### Disk
- Free space: `df -h /` — use the `Avail` and `Capacity` columns of the `/System/Volumes/Data` or `/` line.
- What's big (one level): `du -x -h -d 1 ~ 2>/dev/null | sort -rh | head -15`
- Top 10 largest files: `find ~ -xdev -type f -size +500M -not -path "*/Library/*" 2>/dev/null -exec du -h {} + | sort -rh | head -10`
- Gotcha: `du` over the whole home folder takes 1–4 minutes on a full disk. Say so before running; use a 300000 ms timeout.
- Gotcha: macOS "purgeable" space makes Finder and `df` disagree. If they differ, trust `df` and explain the difference in one sentence.

### Memory & CPU
- Memory pressure: `memory_pressure | tail -1` — reports "System-wide memory free percentage".
- Top consumers: `ps -Ao pid,pcpu,pmem,comm -r | head -8`
- Load: `uptime`

### Hardware identity (for the profile)
- Model & RAM: `system_profiler SPHardwareDataType | grep -E "Model Name|Model Identifier|Memory|Chip"` — do NOT record the serial number line.
- macOS version: `sw_vers`
- Battery: `system_profiler SPPowerDataType | grep -E "Cycle Count|Condition|Maximum Capacity"`
- SMART status: `diskutil info disk0 | grep SMART` — anything other than "Verified" is a 🔴 finding.

### Startup items
- Login items: `osascript -e 'tell application "System Events" to get the name of every login item'`
  - Gotcha: first run triggers an Automation permission prompt — tell the user to click Allow, and why.
- User launch agents: `ls -1 ~/Library/LaunchAgents 2>/dev/null`
- All-users launch agents: `ls -1 /Library/LaunchAgents /Library/LaunchDaemons 2>/dev/null`
- Interpreting plist names: reverse-DNS names their vendor (`com.google.keystone…` = Google updater). Explain each in plain language; never call something safe to remove unless you can name what it belongs to.

### Updates
- Pending: `softwareupdate -l` — Gotcha: takes 30–90 s and needs network; run with a 120000 ms timeout and report 🟡 "couldn't check" on timeout rather than failing the checkup.

### Time Machine
- Configured? `tmutil destinationinfo` — "No destinations configured" = 🔴 no backup.
- Last backup: `tmutil latestbackup` — Gotcha: errors when the backup disk is disconnected; that means "backup disk not connected", not "no backups exist". Distinguish the two in the report.

### Trash size
- `du -sh ~/.Trash 2>/dev/null` — report it; only the user empties it.

## Safe actions

### Delete = move to Trash (the only allowed deletion)
```bash
osascript -e 'on run argv' -e 'set p to POSIX file (item 1 of argv)' \
  -e 'tell application "Finder" to delete p' -e 'end run' "/full/absolute/path"
```
- The path is passed as an argument, never interpolated into the AppleScript source — filenames containing quotes or apostrophes cannot break out of the script.
- One file/folder per call; for batches, loop and count.
- Preserves "Put Back" in Finder — this is why rm is banned.
- Gotcha: needs Automation permission for Finder on first use (prompt appears once).

### Duplicate files (two-pass, bounded)
1. Candidates by size: `find <dir> -xdev -type f -size +1M -exec stat -f "%z %N" {} + | sort -n` — only same-size files can be duplicates.
2. Confirm by checksum, same-size groups only: `md5 -q <file>`.
- Never auto-delete duplicates. Present groups (keep newest-path suggestion pre-marked) and let the user choose.

### HEIC → JPG
```bash
sips -s format jpeg "photo.heic" --out "photo.jpg"
```
Original is kept; converted copy goes next to it or to a folder the user picked.

### Photo date taken (for date-based renaming)
- `mdls -name kMDItemContentCreationDate -raw "photo.jpg"` — Spotlight metadata, works for most photos.
- Fallback when Spotlight has nothing: `stat -f "%SB" -t "%Y-%m-%d" "photo.jpg"` (file creation date — say it's a fallback, since it's the copy date, not the shoot date).

### Compress images in place-adjacent
```bash
sips -Z 2048 --setProperty formatOptions 70 "big.jpg" --out "big-web.jpg"
```
(2048 px longest side, 70% quality; never overwrite the original.)

### Schedule a tool (launchd, user-level)
Write `~/Library/LaunchAgents/com.itguy.<tool-name>.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.itguy.<tool-name></string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string>
    <string>/Users/NAME/ITGuy/toolbox/<tool-name>/run.sh</string>
    <string>--go</string>
  </array>
  <key>StartCalendarInterval</key><dict>
    <key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer>
  </dict>
  <key>StandardOutPath</key><string>/Users/NAME/ITGuy/toolbox/<tool-name>/runs.log</string>
  <key>StandardErrorPath</key><string>/Users/NAME/ITGuy/toolbox/<tool-name>/runs.log</string>
</dict></plist>
```
Load with `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.itguy.<tool-name>.plist`. Only schedule tools that already pass their dry-run; tell the user how to stop it (`launchctl bootout gui/$(id -u)/com.itguy.<tool-name>`).

## Permission gotchas (read before diagnosing "weird" failures)

| Symptom | Cause | Fix to walk the user through |
|---------|-------|------------------------------|
| "Operation not permitted" reading Desktop/Documents/Downloads/~/Library | Terminal lacks Full Disk Access | System Settings → Privacy & Security → Full Disk Access → enable the terminal app → restart it |
| osascript errors -1743 / "not authorized" | Automation permission not granted | System Settings → Privacy & Security → Automation → allow terminal to control Finder/System Events |
| `tmutil latestbackup` errors | Backup disk not connected | Ask the user to plug in the backup disk — not the same as having no backups |
