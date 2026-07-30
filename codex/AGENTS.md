# mac-it-guy-pro (Codex and other AGENTS.md agents)

A personal, professional IT guy for a Mac, for someone who is **not** a programmer.

Entry point: **`$mac-it-guy`**. It loads the binding safety contract, then routes to the workflow that fits — checkup, cleanup, organise, fix, backup, network, automate, toolbox, learn, profile, onboard.

## Read this before touching anything

`skills/it-core/SKILL.md` holds the ten-rule safety contract. It is binding, not advisory. The four rules that most often get skipped:

1. **Diagnose before treating.** Present findings and get a choice before any change.
2. **Trash, never delete.** Every removal goes through the Finder Trash so the user can undo it.
3. **Dry-run first.** Batch operations show the full plan before executing, and write an undo manifest before the first move.
4. **Admin work is handed to the user.** Never run `sudo`; give them the command and one sentence explaining it.

## macOS only

Every workflow stops if `uname` is not `Darwin`. This is not a portability gap to work around — the recipes depend on Spotlight metadata, Time Machine, `sips`, `mdls`, `launchctl` and `system_profiler`, and several safety promises are stated in terms of the Finder Trash and Full Disk Access. Do not improvise substitutes.

## Skills

| Skill | Purpose |
|---|---|
| `$mac-it-guy` | Entry point. Routes to the right workflow and states what differs from the Claude Code build. |
| `$it-core` | The safety contract, report format, state layout, and the summon rule. Load first, always. |
| `$machine-profile` | How memory is written, dated, retested and retired. Provenance classes, the belief ledger, demotion to history. |
| `$macos-recipes` | Exact commands with their gotchas — the gotchas are the value. Mechanism only, no policy. |
| `$toolbox-contract` | Building tools the user keeps, plus the pattern catalogue that offers automations they did not know to ask for. |
| `$home-network` | Isolating whether a problem is the device, Wi-Fi, the router or the ISP — before anyone spends money. |
| `$tutoring` | How to explain rather than just fix, grounded in the user's own measurements. |
| `$open-internet` | Building a personal unrestricted connection. Personal and household use only. |

The skills are symlinks to the Claude Code tree, so both builds read exactly the same files and cannot drift apart.

## No sub-agents here — supply the discipline yourself

Claude Code dispatches four agents with restricted tool sets. The read-only `diagnostician` structurally cannot modify anything; that is a property of the harness, not a promise in prose.

Without that isolation you must hold the line yourself: gather evidence without fixing anything in the same pass, act only on approved categories, write the undo manifest before the first move, and never run a freshly built tool for real. `agents/*.md` describes each role fully — read the matching one first.

## State

`~/ITGuy/` is a small database with cross-file integrity and two append-only logs, and several sessions may run at once. **`scripts/state.sh` is the only sanctioned writer** — it locks, writes atomically, treats demotion as a three-file transaction, and refuses to commit a profile the linter rejects. Reading directly is fine; writing directly races and skips validation.

## Hooks

`codex/hooks.json` registers two hooks on the events Codex shares with Claude Code:

- **`PreToolUse`** → `scripts/guard.sh` inspects every shell command and blocks the catastrophic ones regardless of permission mode. 62 test assertions cover it.
- **`SessionStart`** → `scripts/profile-digest.sh` injects a short pointer so the session starts knowing the machine, and stays silent when no profile exists.

**If your runtime does not run these hooks, the plugin is materially less safe.** Say so to the user before doing destructive work rather than proceeding quietly.

## Other AGENTS.md agents

Grok Build, opencode and Kimi CLI read this file and the shared skills tree natively, so no separate configuration is needed. What they do *not* necessarily provide is the `PreToolUse` guard — see above. Antigravity (`agy`) reads the workspace skills tree; use `cc-suite:bridge-skills` to link it.
