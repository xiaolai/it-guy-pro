---
name: automate
description: "Describe a repetitive chore — the IT guy builds it into a reusable tool in your toolbox"
argument-hint: "\"<the chore, in your own words>\""
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion
---

# Automate — turn a chore into a tool you keep

Read `${CLAUDE_PLUGIN_ROOT}/skills/it-core/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/skills/toolbox-contract/SKILL.md` first — the safety contract and the toolbox contract are binding. Read `~/ITGuy/machine.md` if it exists. If `uname` is not `Darwin`, say this version supports Mac only and stop. If `~/ITGuy/` does not exist, create it (with `toolbox/`, `undo/`, `reports/`) — automate may be a user's first command.

## Step 1: Clarify the chore into a spec

`$ARGUMENTS` is the chore in the user's words ("every week I rename my scans", "I always convert HEIC photos before emailing them"). If `$ARGUMENTS` is empty, ask first: "What's the chore? Describe it the way you'd describe it to a friend." — then continue. Turn the description into a spec — at most one AskUserQuestion round for whatever is genuinely ambiguous:

- **Input**: which folder/files, identified how
- **Action**: what happens to them, including the exact naming/format rule
- **Frequency**: how often the chore recurs
- **Success criteria**: one testable sentence — "afterwards, every scan in X is named YYYY-MM-DD-<original>"

## Step 2: Apply the acceptance test

The toolbox contract's three criteria: real problem, repeat use, evolvable. A one-off task fails the test — do it directly instead (with the same safety rules), tell the user why no tool was built, log the visit, done.

## Step 3: Check the toolbox

Read `~/ITGuy/toolbox.json`. An existing tool covers the chore → show its README and how to run it, bump nothing, done. A near-miss exists → offer evolving it instead of duplicating.

## Step 4: Build

Dispatch the `it-guy-pro:toolsmith` agent (via Task) with the spec. It builds under `~/ITGuy/toolbox/<name>/` per the contract (dry-run default, Trash-only, README, `.command` wrapper), tests the dry-run against the real target, and registers the tool.

## Step 5: Hand over the keys

Show the user, in this order:

1. What the tool does — one sentence.
2. The dry-run preview from the toolsmith's test, so they see it working on their real files.
3. How to run it themselves: double-click `<Tool Name>.command` in `~/ITGuy/toolbox/<name>/` for a preview; the `--go` command applies it.
4. Offer the first real run now (run it with `--go` only after an explicit yes).
5. If the spec's frequency was daily/weekly, offer scheduling it (launchd recipe in `macos-recipes`) — offer, never apply unasked.

Append the visit line to `~/ITGuy/visits.log` and record the chore in the profile's Conventions if it reveals a filing/naming habit.

## Errors

- Toolsmith's dry-run test fails its success criteria → do not hand over a broken tool; report what failed and either fix the spec with the user or stop.
- Chore needs an app the machine doesn't have → name the dependency, how to get it, and stop short of installing without a yes.
