---
name: network
description: "Fix slow Wi-Fi, connect your machines to each other, see what's on your network, and secure it — measured, not guessed"
argument-hint: "[check|wifi|devices|connect|secure|router]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion, WebSearch, WebFetch
---

# Network — measure first, spend last

Read `${CLAUDE_PLUGIN_ROOT}/skills/home-network/SKILL.md` first — the layer model, the fix ladder, and the boundaries are binding. Read `${CLAUDE_PLUGIN_ROOT}/skills/it-core/SKILL.md` for the safety contract and `${CLAUDE_PLUGIN_ROOT}/skills/machine-profile/SKILL.md` before writing anything to the profile. Read `~/ITGuy/machine.md` if it exists. If `uname` is not `Darwin`, say this version supports Mac only and stop.

**Confirm this is the user's own network before scanning anything — ask explicitly with AskUserQuestion, do not infer it from context.** The question is whether this is their home network or one they administer. If it is a coffee shop, an office, a campus, or shared accommodation they do not control, do the parts that only inspect this Mac and decline the rest — see the boundaries in the skill. Ask once per run, before the first discovery command, and never in place of it.

**Network data is sensitive.** Device names, addresses, MAC addresses, and the SSID together describe a household. Follow the privacy rule in the skill: keep them out of `~/ITGuy/machine.md`, redact them from anything saved or shared, and warn the user before they paste a network report into a support chat or a forum.

Resolve the subcommand from `$ARGUMENTS`; empty means `check`. If `$ARGUMENTS` is non-empty but matches none of the six, treat it as a problem description — name the six subcommands, say which one you think fits, and confirm before running it.

## check — the health report

1. Run the measurements in `${CLAUDE_PLUGIN_ROOT}/skills/home-network/references/diagnostics.md`: Wi-Fi signal and SNR here, `networkQuality` idle, ping to the router and beyond, DNS in use, device count.
2. Report in the it-core report format, **one row per area** (Wi-Fi signal · Speed · Responsiveness · Router link · Internet link · Devices), each with its own 🟢/🟡/🔴 so a single bad area is visible rather than averaged away.
3. Lead the top line with the layer, not the number: "Your Wi-Fi is the bottleneck, not your internet plan" is the sentence the user needs.
4. End with exactly one recommended next step: **read the profile's network notes and Watch List first to see which rungs have already been applied**, then recommend the lowest rung of the fix ladder not yet tried. Without that check, a second visit repeats the advice of the first.

## wifi — diagnose and tune

1. **Isolate the layer first.** Take measurements next to the router and at the problem location, and get a wired comparison if an Ethernet adapter is available. Do not proceed to tuning until you can say which layer is at fault — if it is the ISP or the router hardware, tuning is wasted effort and you should say so.
2. Work `${CLAUDE_PLUGIN_ROOT}/skills/home-network/references/wifi-tuning.md` in ladder order: placement, band, channel, router settings. Router settings live in a web interface, so give the user a numbered click-path and let them make the change — this is their equipment, and the safety contract hands admin work to them.
3. **Re-measure after each change and show before-and-after numbers.** Revert anything that did not move them, and say that you are reverting it.
4. Only if rungs 1–4 are exhausted, continue to `router`.

## devices — what is on the network

1. Discover with the ARP and Bonjour recipes in the diagnostics reference — **local subnet only, and no port scanning of what you find.** Knowing a device exists is inventory; probing it is not.
2. Present devices by role and name ("printer", "someone's iPhone", "unrecognized"), and explain **MAC randomization** before the user panics at unfamiliar entries — modern Apple devices present a different address per network by default.
3. If the user believes someone is using their Wi-Fi: the answer is to rotate the passphrase and confirm WPA3/WPA2-AES, then re-check the list. Do not identify, track, or interfere with anyone, and do not offer MAC filtering as security.

## connect — link machines, printers, shares

1. Ask what the user actually wants to accomplish, then route by goal using the table in `${CLAUDE_PLUGIN_ROOT}/skills/home-network/references/connecting-machines.md`. A one-off file move is Migration Assistant or AirDrop, not a permanent share.
2. Set up the minimum that achieves the goal: a specific folder rather than the home directory, named accounts rather than guest access, `.local` names rather than addresses.
3. If the goal is reaching files from outside the home, follow that reference's order of preference and do **not** forward a port to a Mac or NAS as a first resort. Never forward SMB, RDP, or a NAS admin interface.
4. Note any sharing service switched on in the profile's Watch List, so a future checkup asks whether it is still needed.

## secure — the hardening checklist

Work `${CLAUDE_PLUGIN_ROOT}/skills/home-network/references/network-security.md` in its priority order, reporting each item 🟢/🟡/🔴. Router changes are click-paths for the user, not commands you run. Fix one thing at a time on a household network so a breakage is attributable. Put anything the user declines on the Watch List rather than dropping it.

If findings suggest an actually compromised router — DNS nobody set, unexplained port forwards, admin password no longer working — stop the checklist and follow that reference's response: factory reset, firmware update, reconfigure with new passwords, or replace the device if firmware support has ended.

## router — buying advice

1. **First establish which rung failed — all five, not four.** If placement, band, channel, router settings/SQM, **and wired backhaul** have not each been considered and measured, the recommendation is "buy nothing yet," and you should say so plainly even though the user asked what to buy. Rung 5 is the one most often skipped and most often correct: for a coverage complaint, a cheap access point on an Ethernet run beats any router purchase, so it must be ruled out *before* a router is recommended, not after.
2. Use `${CLAUDE_PLUGIN_ROOT}/skills/home-network/references/router-buying.md`. Recommend one option plus one cheaper alternative, each with the problem it solves, the measurement it should improve, and what it will not fix.
3. Verify any specific model or price before quoting it — that reference carries a date stamp, and hardware recommendations go stale faster than anything else in this plugin.
4. After installation, re-measure and show before-and-after. If the numbers did not move, tell the user it should go back.

## All subcommands

Append the visit line to `~/ITGuy/visits.log` in the format defined under "Visit log line format" in `${CLAUDE_PLUGIN_ROOT}/skills/it-core/SKILL.md`. Record in the profile only what helps next visit — router make and model, band layout, fixes applied, and measured baselines — and never addresses, MAC addresses, device inventories, the SSID, or passphrases.

## Errors

- **A VPN or proxy tunnel is active** (including one built by `/it-guy-pro:open-internet`) → it holds the default route, so speed and latency measurements describe the tunnel, not the home network. Detect it first per the diagnostics reference, ask the user to switch it off for the diagnosis, and if they cannot, say plainly which numbers are untrustworthy.
- Wi-Fi is off or the Mac is on Ethernet only → say so and offer the wired-relevant checks rather than failing.
- A diagnostic needs admin rights (`wdutil info` requires sudo) → prefer the no-privilege recipe (`system_profiler SPAirPortDataType`); if admin is genuinely required, hand the user the exact command per safety contract rule 6.
- The user asks for something in the boundaries list — cracking, deauthentication, scanning a network they do not control, accessing another person's device → decline that specific thing in one sentence, without lecturing, and continue with the rest.
