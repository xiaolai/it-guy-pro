# it-guy-pro

**Your personal IT guy — he remembers your computer and leaves his tools behind.**

A Claude Code plugin for people who are *not* programmers. It turns Claude into a professional, careful IT person who checks your computer's health, cleans up safely, organizes your files, fixes problems (diagnosis first, always), sets up real backups — and every time it solves a repeated chore, it builds you a small tool you keep forever.

macOS-first (v0.1 supports Mac only).

## Install

```bash
claude plugin install it-guy-pro@xiaolai
```

Then start with:

```
/it-guy-pro:onboard
```

The IT guy introduces himself, learns what you use your computer for, and writes down what he learned in a file you can read: `~/ITGuy/machine.md`.

## Commands

| Command | What it does |
|---------|--------------|
| `/it-guy-pro:onboard` | First visit — interview, machine profile, and a tailored 3-step plan |
| `/it-guy-pro:checkup` | Full health report: disk, memory, startup items, updates, backups, battery. Read-only. Add `--html` for a keepable report |
| `/it-guy-pro:cleanup` | Reclaim disk space — scan first, you approve categories, everything goes to the Trash (never deleted outright) |
| `/it-guy-pro:organize` | Sort Downloads, Desktop, photos (by date), or PDFs (by content). Every run writes an undo manifest — `organize undo` reverses it |
| `/it-guy-pro:fix "it's slow"` | Describe any problem in your own words — evidence-based diagnosis first, then clearly-explained options |
| `/it-guy-pro:automate "the chore"` | Describe a repetitive chore — get a reusable tool in your toolbox, with a double-clickable preview |
| `/it-guy-pro:toolbox` | List, run, evolve, or remove the tools built for you |
| `/it-guy-pro:backup` | "If this Mac died tonight, what would you lose?" — audit, setup, and a real restore drill |
| `/it-guy-pro:profile` | Show or edit everything the IT guy remembers about this machine |

## The three things that make it trustworthy

**1. Memory you can read.** Everything the IT guy knows lives in one visible folder, `~/ITGuy/` — the machine profile, the visit log, the undo manifests, your toolbox. Plain text. Edit any of it; whatever it says is what he believes. No hidden state, ever.

**2. Rails, not promises.** A hook inspects every shell command before it runs and blocks the catastrophic ones outright — `rm` on your Documents or Photos, `sudo`, disk erasing, deleting backups, emptying your Trash — regardless of session permission settings. Deletions only ever go to the Trash (you can always undo), batch moves write an undo manifest first, admin commands are handed to *you* to run, and nothing gets fixed before you've seen the diagnosis.

**3. Tools you keep.** When a chore repeats, the IT guy doesn't just do it — he builds it into a small named tool under `~/ITGuy/toolbox/`, with a plain-language README and a double-clickable preview. Six months in, you own a personal collection of automations, whether or not you ever learn to program.

## What's in the box

```
it-guy-pro/
├── commands/            9 slash commands (above)
├── agents/              diagnostician (read-only), janitor, librarian, toolsmith
├── skills/
│   ├── it-core/         the 10-rule safety contract, report formats, state layout
│   ├── machine-profile/ profile schema, visit log, undo manifests
│   ├── toolbox-contract/ the micro-product contract and evolution ladder
│   └── macos-recipes/   exact diagnostic/action commands with their gotchas
├── hooks/hooks.json     PreToolUse guard + SessionStart profile digest
└── scripts/             guard.sh, profile-digest.sh
```

## Uninstall / data removal

`claude plugin uninstall it-guy-pro@xiaolai` removes the plugin. Your data — profile, logs, and toolbox in `~/ITGuy/` — is yours and stays put; drag it to the Trash if you want it gone. The tools in `~/ITGuy/toolbox/` keep working without the plugin: they're ordinary scripts.

## Notes for technical users

- The guard hook applies to every Bash call in sessions where the plugin is enabled. If you're a developer, `rm -rf` of build artifacts will trigger a confirm prompt (recursive deletes outside user-content folders are "ask", not "deny") — install at project scope if that bothers you.
- The hook parses the tool payload with JXA (`osascript -l JavaScript`), which ships on every Mac — no jq/python dependency. On parse failure it falls back to matching the raw payload, which over-blocks rather than under-blocks.
- Threat model: the guard is text matching, not shell simulation. It reliably stops *accidental* destruction and coarse injection outcomes (plus "ask" tiers for indirection: `..` paths, command substitution, pipe-to-shell, eval, interpreters shelling out). A deliberately obfuscated command can evade it — the layered defenses there are the untrusted-data rules in the it-core skill and Claude Code's own permission system.

## License

MIT
