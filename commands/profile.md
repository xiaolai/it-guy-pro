---
name: profile
description: "Show or update what the IT guy remembers about this machine — the memory is yours to read and edit"
argument-hint: "[show|review|update|forget|history]"
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# Profile — auditable memory

Read `${CLAUDE_PLUGIN_ROOT}/skills/machine-profile/SKILL.md` first — schema and update rules are binding. If `uname` is not `Darwin`, say this version supports Mac only and stop. If `~/ITGuy/machine.md` does not exist, say there is no profile yet and point to `/mac-it-guy-pro:onboard` — then stop.

Resolve the subcommand from `$ARGUMENTS`; empty means `show`.

## show

Print `~/ITGuy/machine.md` verbatim, then a three-line footer:

- How to reach him: list both triggers — the `Summon:` value and, when an `IT guy:` name is set, the derived `_<name>` — noting that capitalisation is irrelevant to either.
- Visits on record: count of lines in `~/ITGuy/visits.log`, with the date of the first and the latest.
- **Memory health**: run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/lint-profile.sh"` and summarise it in one line — counts by severity, nothing more. If it reports any `CRITICAL`, say so first and offer `review` immediately; a stored secret is not a footnote.
- "This file is the IT guy's entire memory of this machine. Edit it or delete any line — whatever it says is what I'll believe next visit. What I've stopped believing is in `history.md`."

## review — the deep memory audit

**Run the linter first — it does the mechanical half deterministically:**

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/lint-profile.sh"
```

It emits `SEVERITY|rule|location|message` per finding (exit 0 clean, 1 findings, 2 no profile) and checks what prose cannot enforce: stored secrets, untagged facts, conclusions with no retest date or method, overdue retests, told-facts over a year old, stale measurements, an unverified or 60-day-old connection status, a summon word missing its underscore, the 120-line cap, malformed ledger lines, and demoted beliefs missing from `history.md`.

**Act on `CRITICAL` findings before anything else and before showing the profile.** A stored private IP, MAC address, UUID, share link, or password is a privacy failure, not a tidiness issue: remove it from `machine.md` *and* `history.md`, write a `redacted` ledger event that records the removal without repeating the value, and tell the user plainly what was stored and that it is gone.

Then work through the remaining findings and the facts the linter cannot judge:

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

1. Use AskUserQuestion to find out what changed (options: my work/goals changed, change the language you answer me in, change my name or the summon word, remove something that's wrong). A language change edits the Owner `- Language:` line and takes effect next session; say so, and note that files and tool names stay English by design. A name change edits the Owner `- Call me:` line; a summon change edits the `Summon:` line — the new word must keep the leading underscore (that's the collision guard) — and confirms the convention in one sentence ("from now on it's `_mac`; takes effect next session").
2. Apply the edit to the right section, respecting the schema's rules: 120-line cap, newest-first quirks, replace-in-place for facts, and never store passwords, serial numbers, IPs, or account emails — if the user offers one, decline it and say why in one sentence.
3. Show a before/after diff of the changed lines.
4. Append the visit line to `~/ITGuy/visits.log`.

## forget

Confirm with AskUserQuestion, listing exactly what will be forgotten: the profile, the visit history, the belief history (`history.md` and `ledger.jsonl`), or everything in `~/ITGuy` except the toolbox (tools are the user's property and are only removed via `/mac-it-guy-pro:toolbox remove`). On yes: move the chosen files to the Trash (never rm — recoverable until the user empties it). Say what was forgotten and that the Trash holds the copies.

`forget` is the **only** path that destroys memory. Everything else demotes to `history.md`, because deleting a belief destroys the ability to explain a past decision. The single exception is data that should never have been stored — a password, an address, a serial number — which is removed from the profile *and* from history, with a `redacted` ledger event that records that it happened without repeating the value.

## Errors

- Profile exists but is malformed (missing sections) → show it anyway, note which sections the schema expects, and offer to restructure it without losing any of the user's own lines.
