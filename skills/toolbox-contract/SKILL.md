---
name: toolbox-contract
description: The micro-product contract for the IT Guy toolbox — acceptance criteria, directory layout, README template, registry schema, dry-run requirement, double-clickable wrappers, the evolution ladder, and the pattern catalogue used to offer a user automations they did not know to ask for. Load when building, listing, running, evolving, or removing tools in ~/ITGuy/toolbox/, or when deciding whether to suggest one.
---

# Toolbox Contract

Every automation the IT guy builds is left behind as a named tool the user owns. Over months the user accumulates a portfolio of personal micro-products without ever "learning programming".

## Two ways a tool gets built

**The user asks** (`/it-guy-pro:automate`) — they describe a chore and it becomes a tool.

**The IT guy notices** — a measurable pattern on their machine matches a proven recipe, and he offers it with their own number in the sentence. This is the path that matters for non-technical users, because **nobody asks for an automation they don't know exists.** The signals, thresholds, offers, recipes, and the anti-nagging rules that keep it from becoming a pitch list all live in `references/pattern-catalogue.md`. Read that file before making any unsolicited suggestion, and obey its rules: one offer per run, health findings outrank convenience, quote the observed number, and a decline is permanent.

Both paths produce the same thing, and both must pass the test below.

## Acceptance test — all three, or don't build it

1. **Real problem**: it removes a chore the user actually described, even if only theirs.
2. **Repeat use**: the chore recurs. A one-off task is just done directly, not turned into a tool.
3. **Evolvable**: today a script, later a CLI with options, later scheduled — without rewriting from scratch.

If a request fails the test, do the task directly and say why no tool was built.

## Directory layout

```
~/ITGuy/toolbox/<tool-name>/
├── run.sh              # or run.py — the tool itself
├── README.md           # plain language, template below
└── <Tool Name>.command # double-clickable Finder wrapper
```

- `<tool-name>` is kebab-case, verb-first: `rename-photos-by-date`, `file-desktop-screenshots`.
- `run.sh` starts with `#!/bin/bash` and `set -euo pipefail`; `run.py` uses only the Python standard library. No dependencies without naming the dependency to the user and getting a yes.

## Non-negotiable tool behaviors

1. **Dry-run is the default.** Running the tool with no arguments prints what it *would* do and changes nothing. The real run requires `--go`.
2. **Trash, never rm** — same rule as the safety contract. Tools delete via Finder Trash (recipe in `macos-recipes`).
3. **Never overwrite** — collisions get ` (2)` suffixes.
4. **Print a summary line** at the end: how many files touched, how much space affected, where.
5. **Exit non-zero on any error**, with a message a non-technical user understands.

## `README.md` template (plain language)

```markdown
# <Tool Name>

**What it does:** <one sentence a non-technical reader understands>
**Built:** YYYY-MM-DD, because: <the chore, in the user's own words>

## How to run it
1. Double-click `<Tool Name>.command` — it shows a preview and changes nothing.
2. Happy with the preview? Run it for real: <exact command with --go>.

## Example
<one real before → after example from the test run>

## History
- YYYY-MM-DD: built (v1)
```

## `.command` wrapper

macOS runs `.command` files in Terminal on double-click. Wrapper content:

```bash
#!/bin/bash
cd "$(dirname "$0")"
bash run.sh
echo ""
read -p "Preview done — press Return to close (run with --go to apply)."
```

Mark it executable (`chmod +x`). The wrapper always runs the preview, never `--go` — real runs stay deliberate.

## Registry — `~/ITGuy/toolbox.json`

```json
{
  "tools": [
    {
      "name": "rename-photos-by-date",
      "pattern": "camera-named-photos",
      "purpose": "Renames photos to YYYY-MM-DD-<original>.jpg using the date each photo was taken",
      "built": "2026-07-29",
      "last_used": "2026-07-29",
      "runs": 1,
      "stage": "script"
    }
  ],
  "declined": ["desktop-screenshots"]
}
```

`stage` is one of `script` | `cli` | `scheduled`. Update `last_used` and `runs` on every run.

`pattern` is the catalogue id this tool was built from, or absent for a tool the user requested directly. **It is what marks a pattern as handled** — the tool's own `name` cannot serve that purpose, because `/automate` lets users name tools whatever they like, so a user who calls it `tidy-my-desktop-shots` would otherwise be offered `desktop-screenshots` forever. Always set it when building from a catalogue recipe.

`declined` holds catalogue **ids** the user has turned down — the backticked code such as `desktop-screenshots`, never the recipe name such as `file-desktop-screenshots`; the two differ by a word and a decline recorded under the wrong one is a decline no reader will ever match. **A decline is permanent** — never raise that pattern again. Remove the entry only if the user later asks for that tool themselves. If `toolbox.json` is absent, create it as `{"tools": [], "declined": []}`; an absent `declined` key means nothing has been declined yet.

## Evolution ladder

| Stage | Trigger to advance | What changes |
|-------|--------------------|--------------|
| script | used 5+ times, or user asks for options | add flags (`--folder`, `--since`), input validation, `--help` in plain language |
| cli | user says "do this every day/week" | add a launchd LaunchAgent (recipe in `macos-recipes`), log to `~/ITGuy/toolbox/<name>/runs.log` |
| scheduled | — | terminal stage in v0.1 |

When a run of `/it-guy-pro:toolbox` notices a trigger condition, offer the upgrade — never apply it unasked.
