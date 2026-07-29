---
name: open-internet
description: "Set up your own private server for unrestricted internet access — buy it, configure it, connect to it, and keep it working"
argument-hint: "[setup|check|fix|client]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion, WebSearch, WebFetch
---

# Open Internet — your own private connection

Read `${CLAUDE_PLUGIN_ROOT}/skills/open-internet/SKILL.md` first — it holds the current protocol recommendation, the decision logic, and the boundaries. Read `${CLAUDE_PLUGIN_ROOT}/skills/it-core/SKILL.md` for the safety contract and `${CLAUDE_PLUGIN_ROOT}/skills/machine-profile/SKILL.md` for the `Private Connection` schema you will write. Read `~/ITGuy/machine.md` if it exists.

This is the one it-guy-pro workflow that touches a machine other than the user's own. Two rules follow from that:

- **The guard hook protects this Mac, not the server.** Nothing stops a destructive command on the far end. Treat every remote command as unguarded: read it before running it, and never run a destructive one on a server that already works.
- **Server access is root over ssh.** That is normal for a fresh VPS and is not the same as running sudo on the user's Mac.

Resolve the subcommand from `$ARGUMENTS` against the profile's `Private Connection` → `Status` field:

| `$ARGUMENTS` | Route to |
|---|---|
| `setup`, `check`, `fix`, `client` | that subcommand |
| empty, and no `Private Connection` section | `setup` |
| empty, and `Status: working` | `check` |
| empty, and `Status: blocked` | `fix` |
| empty, and `Status: needs setup` | `setup`, resuming from what already exists |
| anything else non-empty | treat as a problem description: say which four subcommands exist, name the one you think they mean, and confirm before running it |

If `setup` is requested when a `Private Connection` already exists, do not silently rebuild. Offer three choices: check the existing one, replace it, or **add a second path alongside it** (the two-architecture setup in the skill's decision rule — direct for speed, CDN-fronted for resilience, with client-side failover). Adding a second path re-runs Steps 3–7 for the new server only and sets `Architecture: both`.

## setup

### Step 1: The honest briefing — before any money is spent

Read `${CLAUDE_PLUGIN_ROOT}/skills/open-internet/references/legal-and-limits.md` and present its substance in the short plain-language form shown there: the legal reality where the user is, the personal-use versus selling-access distinction, the services that do not officially serve their region, and the upkeep expectation. Ask once whether they want to proceed. If they decline, stop cleanly and log the visit.

If the user's goal is to resell or share access beyond their household, decline that part per the skill's boundaries and offer the personal-use setup instead.

### Step 2: Understand the situation

Ask only what changes the recommendation, as **one AskUserQuestion call carrying all four questions** — not four sequential calls:

- Where they are (mainland China has a different answer than a corporate or campus filter elsewhere).
- What they need it for — general browsing, developer tooling, video, or all three. Video and developer downloads change the bandwidth calculus.
- Their budget, in the currency they think in.
- Whether they have an international payment method, and which (this decides the provider shortlist — see the buying reference).

### Step 3: Recommend one plan

Read `${CLAUDE_PLUGIN_ROOT}/skills/open-internet/references/vps-buying.md`. Present exactly one recommended provider and plan with its yearly cost, plus one cheaper alternative and one no-server alternative (a commercial subscription), in a short table with the trade-off named. Recommend, do not survey.

Before quoting prices as current, verify them: prices and stock change, and this reference has a date stamp. If it is more than three months old, check the provider's page with WebFetch and use what you find.

### Step 4: Walk them through buying it

Numbered click-path from the buying reference. The user does the buying — never ask for their card details, account password, or payment credentials, and never offer to buy on their behalf. Stop at the point where they have: the server's IP address, the root password or SSH key, and the provider's control-panel login working.

### Step 5: Build the server

Read `${CLAUDE_PLUGIN_ROOT}/skills/open-internet/references/server-setup.md` and follow it exactly. Rules that override any convenience:

- Show the user what each command does in one plain sentence before running it.
- Never paste a remote install script into a shell unread. Fetch it, show its origin, then run it.
- Record nothing secret in `~/ITGuy/machine.md` — no server password, no private key, no connection UUID.

### Step 6: Connect the Mac

Read `${CLAUDE_PLUGIN_ROOT}/skills/open-internet/references/client-setup.md`. Install and configure the recommended client app, import the connection, and turn it on.

### Step 7: Verify honestly

Test and show real results: a blocked site loads, the visible IP address is the server's, a speed measurement, and — if the user named a specific service — that service actually working. If something fails, say so and go to `fix`; never declare success on an untested assumption.

### Step 8: Record and hand over

- Write the `Private Connection` section of `~/ITGuy/machine.md` exactly per the schema in the machine-profile skill — `Status: working`, provider/region, architecture, client app, renewal date, and today as `Last verified`. **Never** credentials, keys, UUIDs, or the share link.
- Tell them the three things they will eventually need: how to turn it on and off, what a blocked server feels like and that `/it-guy-pro:open-internet fix` handles it, and when the bill renews.
- Append the visit line to `~/ITGuy/visits.log`.

## check

Run the four verification tests from the "Verify" section of `${CLAUDE_PLUGIN_ROOT}/skills/open-internet/references/client-setup.md` — they specify the exact commands, the client's mixed-port caveat, and the discipline of testing the service the user actually named.

Report in the it-core report format with **one row per test** (Client & connection · Exit IP · Blocked site · Speed), each with its own 🟢/🟡/🔴, so a partial failure is visible rather than averaged away. Compare the speed number against the one recorded at setup. Flag a renewal date within 30 days, and update `Last verified` and `Status` in the profile to match what you actually found.

## fix

Diagnose a connection that stopped working, in this order — cheapest test first, and confirm each before acting on the next:

1. Is the server alive at all (does the provider panel show it running, does it respond to ssh)?
2. Is the server's IP blocked from China specifically (reachable from elsewhere but not from the user's network)?
3. Is the client misconfigured, expired, or simply switched off?
4. Is this a local network problem rather than a blocked server?

Then apply the matching remedy from `${CLAUDE_PLUGIN_ROOT}/skills/open-internet/references/troubleshooting.md`. A blocked IP is the common case and the remedy is a new IP address, not a rebuilt server — follow the IP-change procedure for the user's provider.

## client

Add another device (a second Mac, a phone, a family member's laptop in the same household) to the existing server, or switch client apps. Household devices only — see the skill's boundaries.

## Errors

- No working setup recorded but the user asks for `check`/`fix` → say so and offer `setup`.
- Provider or protocol details in the references look stale (older than three months) → verify with WebSearch/WebFetch before acting, and update the reference file's date stamp with what you confirm.
- The user asks for something in the boundaries list → decline that specific thing, in one sentence, without lecturing, and continue with the rest.
