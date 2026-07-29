---
name: profile
description: "Show or update what the IT guy remembers about this machine — the memory is yours to read and edit"
argument-hint: "[show|review|update|forget|history]"
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# Profile — auditable memory

Read `${CLAUDE_PLUGIN_ROOT}/skills/machine-profile/SKILL.md` first — schema and update rules are binding. If `uname` is not `Darwin`, say this version supports Mac only and stop. If `~/ITGuy/machine.md` does not exist, say there is no profile yet and point to `/it-guy-pro:onboard` — then stop.

Resolve the subcommand from `$ARGUMENTS`; empty means `show`.

## show

Print `~/ITGuy/machine.md` verbatim, then a three-line footer:

- Visits on record: count of lines in `~/ITGuy/visits.log`, with the date of the first and the latest.
- **Memory health**: how many facts are untagged, how many conclusions are past their retest date, and the profile's line count against the 120 cap. If anything is overdue, offer `review` in the same sentence.
- "This file is the IT guy's entire memory of this machine. Edit it or delete any line — whatever it says is what I'll believe next visit. What I've stopped believing is in `history.md`."

## review — the deep memory audit

The full version of the checkup's automatic pass, for when the profile has drifted or the user asks what is still true. Work through `machine.md` fact by fact, using the provenance tags:

1. **Untagged facts** — anything without a provenance tag predates this discipline. Establish what you can (re-measure, re-observe, or ask) and tag it, or demote it. State how many you found; a large number is itself the finding.
2. **Measurements** — re-read every one and write today's values. Report anything that moved materially.
3. **Observations** — re-observe. A convention that no longer holds ("screenshots pile up on the Desktop" when the Desktop is now clean) is demoted, and worth one sentence to the user, because it usually means a tool is working.
4. **Conclusions** — retest every one, not just the overdue ones. This is the point of a deep review.
5. **Told facts** — never auto-expire. If one is older than a year, ask once whether it still holds: "A year ago you told me this Mac is mainly for teaching — still right?"
6. **Toolbox** — flag tools unused for 180+ days and offer removal, and run each tool's dry-run to catch any broken by a macOS update. A tool that errors is worse than no tool, because the user believes it is working.
7. **Size** — if `machine.md` exceeds 120 lines, demote in the documented order and never demote told-class facts to make room.

Report as a table (Fact | Provenance | Verdict: kept / re-dated / demoted / needs you), then the counts. Write one ledger event per change, and show the user the diff before saving.

## history

Print `~/ITGuy/history.md` newest-first — what the IT guy used to believe and why it stopped believing it. Answers "did you ever fix that thing last spring?" If a `subject` is given in `$ARGUMENTS`, filter both `history.md` and `ledger.jsonl` to that subject and show its full timeline, which is the honest answer to "why do you think that?"

## update

1. Use AskUserQuestion to find out what changed (options: my work/goals changed, my folder habits changed, change my name or the summon word, remove something that's wrong). A name change edits the Owner `- Call me:` line; a summon change edits the `Summon:` line — the new word must keep the leading underscore (that's the collision guard) — and confirms the convention in one sentence ("from now on it's `_mac`; takes effect next session").
2. Apply the edit to the right section, respecting the schema's rules: 120-line cap, newest-first quirks, replace-in-place for facts, and never store passwords, serial numbers, IPs, or account emails — if the user offers one, decline it and say why in one sentence.
3. Show a before/after diff of the changed lines.
4. Append the visit line to `~/ITGuy/visits.log`.

## forget

Confirm with AskUserQuestion, listing exactly what will be forgotten: the profile, the visit history, the belief history (`history.md` and `ledger.jsonl`), or everything in `~/ITGuy` except the toolbox (tools are the user's property and are only removed via `/it-guy-pro:toolbox remove`). On yes: move the chosen files to the Trash (never rm — recoverable until the user empties it). Say what was forgotten and that the Trash holds the copies.

`forget` is the **only** path that destroys memory. Everything else demotes to `history.md`, because deleting a belief destroys the ability to explain a past decision. The single exception is data that should never have been stored — a password, an address, a serial number — which is removed from the profile *and* from history, with a `redacted` ledger event that records that it happened without repeating the value.

## Errors

- Profile exists but is malformed (missing sections) → show it anyway, note which sections the schema expects, and offer to restructure it without losing any of the user's own lines.
