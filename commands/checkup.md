---
name: checkup
description: "Full health report — disk, memory, startup items, updates, backups, battery — in plain language"
argument-hint: "[--html]"
allowed-tools: Read, Write, Edit, Bash, Glob, Task, AskUserQuestion
---

# Checkup — the regular health visit

Read `${CLAUDE_PLUGIN_ROOT}/skills/it-core/SKILL.md` first — the safety contract and report format are binding. Read `~/ITGuy/machine.md` if it exists (compare today's findings against its Watch List). If `uname` is not `Darwin`, say this version supports Mac only and stop.

**This command changes nothing about the user's system** — it diagnoses and recommends only. It does write its own bookkeeping: the visit log, the machine profile, and a declined pattern id if an automation offer is turned down. Those writes are required, not exceptions to skip.

## Step 1: Gather evidence

Dispatch the `mac-it-guy-pro:diagnostician` agent (via Task) for all six areas: disk, memory & CPU, startup, updates, backups, hardware.

## Step 2: Render the report

Use the it-core report format exactly: plain-language top line with the overall verdict, findings table (Area | Status | What I found | What I suggest, with 🟢🟡🔴), then exactly one recommended next step phrased as an offer — the highest-impact 🔴 item, or the top 🟡 if nothing is red.

Rules:

- Every startup item is named in plain language ("Google's software updater"), never just its plist filename.
- Backup findings distinguish "no backup configured" (🔴) from "backup disk not connected today" (🟡).
- A diagnostic that could not run appears as 🟡 "couldn't check" with the one-sentence reason — never silently dropped.

## Step 2b: One automation offer — only when the machine has earned it

Read `${CLAUDE_PLUGIN_ROOT}/skills/toolbox-contract/SKILL.md` and then its `references/pattern-catalogue.md` — the catalogue's rules refer to the `declined` array, the `pattern` field, and the registry schema, all of which are *defined* in the parent skill, so loading the reference alone leaves those terms undefined. Run its signals. Its rules are binding, and three of them decide whether you say anything at all:

- **Skip this step entirely if any 🔴 finding is open.** A full disk or a missing backup outranks any convenience, and raising both at once buries the one that matters.
- **Skip any pattern already in `declined` or already built** in `~/ITGuy/toolbox.json`.
- **At most one offer**, the highest count among those that fired, appended as a single line below the recommended next step — never a list, never a second section.

Phrase it with their own number: "Separately — I noticed 213 screenshots piled up on your Desktop. Want me to build you something that files those automatically?"

If they decline, append the **pattern id** (the backticked code, not the recipe name) to `declined` in `~/ITGuy/toolbox.json`, **creating the file as `{"tools": [], "declined": []}` if it does not exist** — on a machine where `/mac-it-guy-pro:automate` has never run there is no registry yet, and a decline that lands nowhere comes back next checkup. If they accept, hand off to the `automate` workflow using the catalogue's recipe, and set the new tool's `pattern` field so the offer never repeats.

If no pattern fires, or a 🔴 is open, say nothing here. Silence is the correct output most of the time.

## Step 3: If `--html` was passed (or the user asks for a keepable copy)

Save a self-contained HTML version to `~/ITGuy/reports/YYYY-MM-DD-checkup.html`: inline CSS only, no external requests, readable on a phone, same content as the chat report. Then `open` it and tell the user where it lives.

## Step 3b: The memory pass — retire what is no longer true

Every checkup maintains the memory as well as the machine. Start with the linter, which is fast and deterministic:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/lint-profile.sh"
```

Any `CRITICAL` finding means a secret is stored in the profile — remove it from `machine.md` and `history.md` immediately, log a `redacted` event, and tell the user. Do not defer that to a later `review`.

Then read the provenance and expiry rules in `${CLAUDE_PLUGIN_ROOT}/skills/machine-profile/SKILL.md` and do four things, cheaply:

1. **Re-date measurements.** Disk, memory, macOS version, battery are re-read by this checkup anyway — write the new values with today's date. A stored measurement is a baseline for comparison, never a fact to trust.
2. **Retest due conclusions.** For each Live Conclusion whose `retest by` date has passed, run its recorded retest. Reproduced → re-date and push the retest date out. Not reproduced → demote to `history.md` as "no longer observed" **and tell the user in one line**: "That fan noise you had in July — I couldn't reproduce it today, so I've stopped assuming it." Unverifiable twice → demote.
3. **Close resolved Watch List items.** Anything this checkup shows is fixed moves to `history.md` with what closed it.
4. **Surface contradictions.** If a finding conflicts with a stored belief, raise it as a question rather than overwriting — never resolve against a told-class fact on your own authority.

Append one `ledger.jsonl` event per change (`retested`, `demoted`, `changed`, `confirmed`). If nothing was due and nothing changed, write nothing and say nothing — a quiet memory pass is the normal case.

Keep this to a few lines of output at most. The health report is the deliverable; memory maintenance is housekeeping the user should see evidence of, not a second report.

## Step 4: Update memory

- `~/ITGuy/machine.md` exists → refresh Hardware/System facts in place (new `Updated:` date), resolve or extend Watch List entries this checkup confirms or clears.
- No profile → append a line to the report: running `/mac-it-guy-pro:onboard` lets the IT guy remember this machine between visits.
- Append the visit line to `~/ITGuy/visits.log` (create `~/ITGuy/` if missing).

## Errors

- Full Disk Access missing → the report still renders with the areas that worked; the permission gap becomes its own 🟡 row with the grant walkthrough from it-core.
- Diagnostician returns nothing usable → say the checkup failed and show the raw error; never invent findings.
