# it-guy-pro

**Your personal IT guy — he remembers your computer and leaves his tools behind.**

A Claude Code plugin for people who are *not* programmers. It turns Claude into a professional, careful IT person who checks your computer's health, cleans up safely, organizes your files, fixes problems (diagnosis first, always), sets up real backups — and every time it solves a repeated chore, it builds you a small tool you keep forever.

macOS only.

## Install

```bash
claude plugin install it-guy-pro@xiaolai
```

### Where to start it from

**Open Terminal and type `claude` — that lands you in your home folder, which is exactly right.** Everything the IT guy looks at lives there: your Desktop, Downloads, Documents and Pictures.

Nothing breaks if you start somewhere else. His memory lives at a fixed location (`~/ITGuy/`) that he can reach from anywhere, and `_it` works in any session on any topic. But a session started deep inside a project folder has to reach outside that folder for every scan and every note he writes, which can mean extra permission prompts for no benefit. If you are already working in a project and want him, summon him with `_it` and carry on — only start a *fresh* session in your home folder when the visit itself is the point.

Then start with:

```
/it-guy-pro:onboard
```

The IT guy looks over your machine — he doesn't quiz you, since the Desktop and Downloads folder tell him more than a questionnaire would. He asks one short round of questions (what to call him, what to call you, which language to answer in), then writes down what he observed in a file you can read: `~/ITGuy/machine.md`.

## Name him, and summon him with `_it`

At setup he asks what you'd like to call him. Name him Alan and you get **two triggers, either of which reaches him from any conversation on any topic**:

```
_it  my mac feels slow
_alan  my mac feels slow
```

**Capitalisation never matters** — `_alan`, `_Alan` and `_ALAN` are one trigger, as are `_it` and `_IT`.

The leading underscore is what makes both reliable. It keeps the trigger mechanical, so there is nothing to interpret: `_alan` cannot appear by accident, which means "Alan Turing" or "I asked Alan yesterday" summons nothing at all. That is exactly why naming him after a real person is safe.

`_it` always works too, whatever you named him — so the convention is one sentence to teach, and the same for everybody. Prefer him nameless? Say so; only `_it` applies and he works identically.

From any Claude session — any project, any topic — typing `_it` as a standalone word summons the IT guy:

```
_it my mac feels slow
```

The leading underscore is the trigger; the everyday word "it" never summons him, and neither does `_it` buried inside code like `_item`. Prefer a different word? Edit the `Summon:` line in `~/ITGuy/machine.md` (keep the underscore) or ask via `/it-guy-pro:profile update`. The slash commands always work regardless.

## Commands

| Command | What it does |
|---------|--------------|
| `/it-guy-pro:onboard` | First visit — observes the machine, asks one short round of questions, proposes 3 next steps from evidence |
| `/it-guy-pro:checkup` | Full health report: disk, memory, startup items, updates, backups, battery. Changes nothing on your Mac; it does update its own notes. Add `--html` for a keepable report |
| `/it-guy-pro:cleanup` | Reclaim disk space — scan first, you approve categories, everything goes to the Trash (never deleted outright) |
| `/it-guy-pro:organize` | Sort Downloads, Desktop, photos (by date), or PDFs (by content). Every run writes an undo manifest — `organize undo` reverses it |
| `/it-guy-pro:fix "it's slow"` | Describe any problem in your own words — evidence-based diagnosis first, then clearly-explained options |
| `/it-guy-pro:automate "the chore"` | Describe a repetitive chore — get a reusable tool in your toolbox, with a double-clickable preview |
| `/it-guy-pro:toolbox` | List, run, evolve, or remove the tools built for you |
| `/it-guy-pro:backup` | "If this Mac died tonight, what would you lose?" — audit, setup, and a real restore drill |
| `/it-guy-pro:network` | Fix slow Wi-Fi, connect your machines to each other, see what's on your network, secure it, and get honest advice on whether a new router would help at all |
| `/it-guy-pro:open-internet` | Build and maintain your own private server for unrestricted access — buy it, configure it, connect, and fix it when it's blocked |
| `/it-guy-pro:learn` | Understand what just happened, or study a whole topic — built from your machine's real numbers, not a generic tutorial |
| `/it-guy-pro:profile` | Show or edit everything the IT guy remembers about this machine |

## He explains, not just fixes

Ask `/it-guy-pro:learn why` after anything and get the reasoning in a paragraph, grounded in the numbers actually measured on your Mac — not a generic article. Ask for a topic (`/it-guy-pro:learn wifi`) and get a full learning map saved to `~/ITGuy/learn/`: what it is, why it exists, when to think of it, the decisions it drives, and what you don't yet know to ask.

The maps date the half that expires. Prices, standards and app recommendations carry a review-by date; principles like *find the failing layer before spending money* don't — because knowing which of your beliefs have expiry dates is most of what expertise is.

## Answer me in my language

At setup the IT guy asks which language to answer you in, and everything you read follows it — reports, explanations, learning maps. Everything written to disk stays English by design: file names, tool names, code, and the profile's field labels, so nothing breaks and your tools stay portable. Technical terms keep their English name alongside a short gloss in your language, so you can still search for them later.

Change it anytime with `/it-guy-pro:profile update`.

## The three things that make it trustworthy

**1. Memory you can read — that retires itself.** Everything the IT guy knows lives in one visible folder, `~/ITGuy/` — the machine profile, the visit log, the undo manifests, your toolbox. Plain text. Edit any of it; whatever it says is what he believes.

More importantly, **it forgets on purpose.** Every remembered fact is tagged with how it was learned — measured, observed, you told me, or concluded — and every conclusion carries a date by which it must be retested. When a checkup comes around, overdue conclusions get re-tested against the machine: reproduce and they stay, fail to reproduce and they're retired with a note. Stale beliefs are worse than none, because a diagnosis from a year ago quietly biases every diagnosis after it. Nothing is deleted, though — retired beliefs move to `history.md`, and `ledger.jsonl` records every change, so "why do you think that?" and "did you ever fix that?" both have real answers.

**2. Rails, not promises.** A hook inspects every shell command before it runs and blocks the catastrophic ones outright — `rm` on your Documents or Photos, `sudo`, disk erasing, deleting backups, emptying your Trash — regardless of session permission settings. Deletions only ever go to the Trash (you can always undo), batch moves write an undo manifest first, admin commands are handed to *you* to run, and nothing gets fixed before you've seen the diagnosis.

**3. Tools you keep.** When a chore repeats, the IT guy doesn't just do it — he builds it into a small named tool under `~/ITGuy/toolbox/`, with a plain-language README and a double-clickable preview. Six months in, you own a personal collection of automations, whether or not you ever learn to program.

And he offers them before you know to ask. Nobody requests an automation they don't know exists, so a checkup measures your machine and, when something has clearly become a chore, makes exactly one offer using your own number: *"I noticed 213 screenshots piled up on your Desktop — want me to file those automatically from now on?"* One offer at a time, never while something more important is broken, and a "no" is remembered permanently.

## What's in the box

```
it-guy-pro/
├── commands/            12 slash commands (above)
├── agents/              diagnostician (read-only), janitor, librarian, toolsmith
├── skills/
│   ├── it-core/         the 10-rule safety contract, report formats, state layout
│   ├── machine-profile/ profile schema, visit log, undo manifests
│   ├── toolbox-contract/ the micro-product contract, evolution ladder, and the
│   │                     pattern catalogue that offers tools you didn't ask for
│   ├── tutoring/        teaching modes, the learning-map structure, and the
│   │                     rule that lessons are offered rather than inserted
│   ├── macos-recipes/   exact diagnostic/action commands with their gotchas
│   ├── home-network/    layer isolation, Wi-Fi tuning ladder, router buying,
│                        connecting machines, security baseline
│   └── open-internet/   architecture decision, protocol evidence, VPS buying,
│                        server/client setup, troubleshooting, legal boundaries
├── hooks/hooks.json     PreToolUse guard + SessionStart profile digest
├── scripts/             guard.sh, profile-digest.sh, lint-profile.sh, state.sh
└── tests/               guard (60), memory (45), state (12), recipes (8)
```

## Checks that actually run

Four things in here are enforced by code rather than good intentions, because prose rules drift and nobody notices. **125 assertions, run on every push:**

- **`scripts/guard.sh`** inspects every shell command before it runs — 60 test cases covering what it must block, what it must merely ask about, and what it must leave alone.
- **`scripts/lint-profile.sh`** audits the IT guy's own memory, with the session digest, across 45 test cases. It catches stored secrets (private IPs, MAC addresses, connection UUIDs, share links, passwords) in both the live profile and its history, facts with no provenance, conclusions that can never expire because they carry no retest, overdue retests, and demoted beliefs missing from the history trail. `/it-guy-pro:profile review` runs it, and a stored secret is treated as a privacy failure to fix immediately, not a tidiness note.

- **`scripts/state.sh`** is the only thing allowed to modify `~/ITGuy/` — 12 test cases. Several Claude sessions can run at once, so it serialises writers with a lock, writes atomically so a crash can never leave a half-written profile, retires a belief from all three files or none of them, and refuses to save a profile the linter would flag. Tested by racing six writers at the registry and asserting nothing is lost.
- **`tests/recipes_test.py`** binds the prose to the code — 8 test cases. It asserts every documented shell recipe parses, that the guard never blocks a command the plugin tells itself to run, that the published profile schema passes the linter shipped beside it, and that the fields the schema publishes are the fields the session hook actually reads. It also re-checks documented gotchas against the live system, which is how the "Time Machine reports failure by exit code" error was found — it does not; it exits 0 and an agent trusting `$?` would have told you a missing backup was fine.

Run them yourself: `python3 tests/guard_test.py && python3 tests/memory_test.py && python3 tests/state_test.py && python3 tests/recipes_test.py`.

## Uninstall / data removal

`claude plugin uninstall it-guy-pro@xiaolai` removes the plugin. Your data — profile, logs, and toolbox in `~/ITGuy/` — is yours and stays put; drag it to the Trash if you want it gone. The tools in `~/ITGuy/toolbox/` keep working without the plugin: they're ordinary scripts.

## Notes for technical users

- The plugin installs at **user scope**, so the guard applies in every directory, including your own repositories — not just when you are doing IT work. That is deliberate (a destructive command is destructive wherever you type it), but it is why `rm -rf node_modules` asks for confirmation while you are coding. Install at project scope instead if you want it confined.
- The guard hook applies to every Bash call in sessions where the plugin is enabled. If you're a developer, `rm -rf` of build artifacts will trigger a confirm prompt (recursive deletes outside user-content folders are "ask", not "deny") — install at project scope if that bothers you.
- The hook parses the tool payload with JXA (`osascript -l JavaScript`), which ships on every Mac — no jq/python dependency. On parse failure it falls back to matching the raw payload, which over-blocks rather than under-blocks.
- Threat model: the guard is text matching, not shell simulation. It reliably stops *accidental* destruction and coarse injection outcomes (plus "ask" tiers for indirection: `..` paths, command substitution, pipe-to-shell, eval, interpreters shelling out). A deliberately obfuscated command can evade it — the layered defenses there are the untrusted-data rules in the it-core skill and Claude Code's own permission system.

## License

MIT
