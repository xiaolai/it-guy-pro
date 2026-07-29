---
name: home-network
description: Decision logic for home network work — isolating whether a problem is the device, the Wi-Fi, the router, or the ISP before spending money; the fix ladder from free to hardware; router and mesh buying judgement; and the boundaries of whose network may be touched. Load before any /it-guy-pro:network work.
---

# Home Network — find the layer before spending money

The defining mistake in home networking is buying hardware to fix a problem that was never in the hardware. A new router does nothing for a congested channel, a badly placed access point, a saturated uplink, or an ISP fault — and the user has spent real money and still has the problem. **Your job is to locate the layer first.** Everything else in this skill follows from that.

Detail lives in five references, each loaded at the step that needs it: `diagnostics.md` (the measurements and what the numbers mean), `wifi-tuning.md` (the free fixes, in order), `router-buying.md` (what to buy, and when not to), `connecting-machines.md` (sharing files, screens, printers between machines), and `network-security.md` (the hardening baseline).

## The four layers, and how to tell them apart

| Layer | Symptom pattern | The isolating test |
|---|---|---|
| **Device** | One machine is slow; everything else on the same Wi-Fi is fine | Test a second device in the same spot. If it's fine, stop looking at the network |
| **Wi-Fi** | Slow or dropping the further you get from the router, fine beside it; worse in the evening | Compare a wired test to a Wi-Fi test at the router, then Wi-Fi at the problem spot |
| **Router / LAN** | All devices affected, everywhere, including wired; internal transfers slow too | Wired test at the router is also bad |
| **ISP / uplink** | All devices affected, wired included; the router's own status page shows the fault; often time-of-day | Wired speed test at the router is bad *and* the router reports a healthy LAN |

**The single most useful measurement is a wired test at the router.** If wired is fine and Wi-Fi is bad, the ISP is innocent and the fix is free. If wired is bad too, no amount of Wi-Fi tuning will help and no new router will either. Do this before any other diagnosis; it eliminates half the possibilities in ninety seconds.

## The fix ladder — never skip a rung

Work strictly in order. Each rung is cheaper than the one after it, and roughly half of real complaints are solved by the first three.

1. **Placement.** Central, high, out in the open. Not in a cabinet, not on the floor, not behind a TV, not next to a microwave, a mirror, a fish tank, or a metal shelf. Moving a router two metres routinely beats replacing it.
2. **Band.** Put anything that matters on 5 GHz; leave 2.4 GHz for range and IoT devices. A device stuck on 2.4 GHz next to a modern router is a configuration problem, not a hardware limit.
3. **Channel.** On 2.4 GHz only **1, 6, or 11** are non-overlapping — any other choice interferes with neighbours *and* yourself. On 5 GHz, pick a channel your neighbours are not on.
4. **Router settings.** Firmware update, QoS/SQM if the router supports it (see the bufferbloat note in `diagnostics.md`), and turn off anything the user does not use.
5. **Wired backhaul.** One Ethernet run to a second access point beats any wireless mesh. This is the highest-value hardware money in home networking and the least marketed.
6. **New hardware.** Only here. See `router-buying.md`.

**Extenders and repeaters are rung 6 done badly.** A repeater that talks to the router and the client on the same radio halves throughput, and chaining two halves it again. If a user already owns one and it "works," check the actual speed through it before endorsing it.

## Buying judgement in one paragraph

Most homes in 2026 do not need Wi-Fi 7. Wi-Fi 6 is the sensible floor, and the honest question is not "which standard" but "how many walls." Coverage problems are solved by *more radios in better places*, not by a faster radio in the same bad place — so a modest router plus a wired second access point beats a flagship router alone, almost always, for less money. Reach for `router-buying.md` only after rungs 1–5 have actually been tried, and say plainly when the answer is "buy nothing."

## Boundaries — whose network

1. **The user's own network only.** Home, or a network they administer. Confirm this before scanning anything. A café, an office, a campus, or a neighbour's network is out of scope even if it is technically reachable.
2. **Discovery, not intrusion.** Listing devices on one's own LAN is ordinary IT work. Probing them for weaknesses, accessing another household member's machine without their knowledge, or reading traffic that is not the user's own is not — decline it.
3. **No Wi-Fi attacks, ever.** No password cracking or recovery from captured handshakes, no deauthentication, no evil-twin or rogue AP setups, no captive-portal bypass. These are not grey areas, and no "but it's my own building" framing makes them acceptable — decline them outright.
4. **"Someone is stealing my Wi-Fi" has one answer: rotate the password and move to WPA3.** Change the password, check the device list afterwards, done. Do not help identify, track, retaliate against, or block-by-MAC as a security measure (MAC filtering is trivially defeated and gives false confidence).
5. **Scanning is bounded to the local subnet.** No scanning beyond the user's own /24, no port sweeps of the internet, no scanning the ISP's infrastructure.

## Network data is sensitive — treat it that way

A network survey produces internal addresses, device names, MAC addresses, the SSID, and a picture of what hardware the household owns. That is a floor plan of someone's digital life.

- **Never write network topology into `~/ITGuy/machine.md`** beyond what is useful next visit: router make and model, band layout, and the fixes applied. No MAC addresses, no device inventory, no SSID, no internal addressing scheme.
- **Redact before anything leaves the machine.** If a saved HTML report or a message to the user's ISP includes the survey, replace MAC addresses and device names with roles ("laptop", "printer"). Warn the user before they paste a network report into a support chat or a forum — this is the single most common way households leak their own topology.
- **Never commit any of it** to a repository, and never include it in a bug report or a public paste.
