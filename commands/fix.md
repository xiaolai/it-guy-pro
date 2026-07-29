---
name: fix
description: "Describe a computer problem in your own words — get a diagnosis first, then choose from clearly-explained fix options"
argument-hint: "\"<the problem, in your own words>\""
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion
---

# Fix — diagnose before treat

Read `${CLAUDE_PLUGIN_ROOT}/skills/it-core/SKILL.md` first — the safety contract is binding, especially: diagnose before treat, admin work handed to the user, verify after fix. Read `~/ITGuy/machine.md` if it exists — Known Quirks may already explain the symptom. If `uname` is not `Darwin`, say this version supports Mac only and stop.

## Step 1: Restate the symptom

`$ARGUMENTS` is the user's description ("it's slow", "the fan is loud", "I can't find my files"). Restate it in one sentence and confirm anything ambiguous with AskUserQuestion — when did it start, is it constant or occasional, one app or everything. One round of questions at most.

## Step 2: Gather evidence

Dispatch the `it-guy-pro:diagnostician` agent (via Task) scoped to the areas the symptom implicates (slowness → memory, CPU, disk, startup; noise/heat → CPU, battery; space → disk). Cross-check its findings against the profile's Known Quirks.

## Step 3: Present the diagnosis

- **What's going on**: one plain-language paragraph tying evidence to symptom.
- **Confidence**: state it as high / moderate / low, and what would confirm it if not high.
- **Options table**:

| Option | What it does | Risk | Undoable? |
|--------|--------------|------|-----------|

Always include "do nothing for now" as a row. If the honest answer is hardware or an Apple-side problem, say so and describe what to tell the repair shop — a good IT guy knows when it's not a software fix.

## Step 4: Fix only what the user picks

Use AskUserQuestion for the choice, then apply exactly that option. Anything requiring admin rights is handed to the user: the exact command, the `! ` prefix instruction, and one sentence on what it does (safety contract rule 6). Anything requiring a restart: tell them why and let them do it when ready — never restart the machine yourself.

## Step 5: Verify and remember

- Re-run the exact diagnostic from Step 2 that showed the problem; show before/after values. If unchanged, say the fix didn't take and return to Step 3 with the remaining options — never claim success without evidence.
- Append the visit line to `~/ITGuy/visits.log`. If the symptom is likely to recur (or this is its second appearance), add a dated Known Quirks entry to the profile.

## Errors

- Evidence contradicts the user's theory → say so plainly and show the numbers; diagnosing honestly beats agreeing.
- Nothing abnormal found → say that too, list what was ruled out, and put the symptom on the profile's Watch List for the next checkup.
