# Securing a Home Network

The realistic threat model for a household is not a targeted attacker. It is automated scanning, a default password nobody changed, a router whose firmware stopped being updated years ago, and a cheap IoT device that phones home to a vendor that no longer exists. Fix those and the household is in better shape than most.

Work through this as a checklist with the user, marking each item 🟢/🟡/🔴 in the it-core report format.

## The baseline, in priority order

**1. Change the router's admin password.** Not the Wi-Fi password — these are different things and users routinely conflate them, which is worth one sentence of explanation. The admin password protects the router's settings page; many are still `admin`/`admin` or printed on a sticker. This is the single highest-value item on the list.

**2. Update the firmware, and check whether updates still exist.** Enable automatic updates if offered. **If the manufacturer no longer publishes firmware for the model, that is the strongest possible reason to replace it** — an unpatched router is the one device where a compromise affects everything else in the house. Age matters more here than performance.

**3. Use WPA3, or WPA2 with AES.** Never WEP, never TKIP, never an open network. If devices are too old to join WPA3, use WPA2/WPA3 mixed mode rather than dropping everything to WPA2 — and note which device forced the compromise, because it is probably also the least maintained thing on the network.

**4. Turn off WPS.** The PIN mechanism is brute-forceable by design and the convenience it buys is one-time. Off, permanently.

**5. Turn off remote administration.** Router management reachable from the internet is a standing invitation and almost no household needs it. Related: turn off any "cloud management" the user does not actively use.

**6. Use a strong Wi-Fi passphrase.** Length beats complexity — three or four unrelated words are stronger and far more usable than `P@ssw0rd!`. This is the credential guests will be given, so make it typeable.

**7. Put IoT devices on the guest network.** Smart plugs, bulbs, cameras, TVs, and anything else with an app go on the guest network, which by default cannot reach the main one. This is real segmentation and costs nothing. It also has a side benefit worth mentioning: guest networks usually block client-to-client traffic, so if a printer or speaker stops working, this is the first thing to check.

**8. Understand UPnP before switching it off.** It lets devices open ports automatically — convenient for game consoles and peer-to-peer calling apps, and a way for a compromised device to expose itself without anyone approving it. If nothing breaks with it off, leave it off. If a games console misbehaves, that is the trade, and the user should make it knowingly.

**9. Audit what is exposed.** Check the router's port-forwarding table and remove entries nobody can explain. Old forwards for a long-gone NAS or camera are common and are exactly what automated scanning finds.

**10. Review DNS.** If the router's DNS points somewhere the user did not choose, that is worth investigating — it is a classic symptom of a compromised router. Setting a mainstream resolver deliberately is fine; finding an unfamiliar one that nobody configured is not.

## Signs a router is actually compromised

Take these seriously rather than tuning around them: DNS servers the user did not set, admin password no longer working, port forwards nobody created, unexplained firmware version changes, or the router's settings reverting. **The response is to reset the router to factory defaults, update its firmware, and reconfigure from scratch with new passwords** — not to hunt for the intruder. And if the firmware is no longer supported, replace the device instead.

## "Someone is using my Wi-Fi"

Nearly always the answer is mundane — a forgotten device, a neighbour who was given the password years ago, or randomized MAC addresses making familiar devices look like strangers (see `diagnostics.md`).

The complete correct response: **change the Wi-Fi passphrase, confirm WPA3 or WPA2-AES, then re-check the device list.** Everything else is theatre. Do not set up MAC filtering (trivially bypassed, breaks guests, false confidence), and do not attempt to identify, locate, track, or interfere with the other party — that crosses out of IT work, and the boundaries in `SKILL.md` are firm about it.

## What this checklist deliberately does not do

- **No penetration testing of the user's own devices.** Verifying settings is the job; probing for exploitable weaknesses is not, and a false sense of "tested" is worse than an honest checklist.
- **No security through obscurity.** Hiding the SSID and changing the default subnet are folklore; they cost usability and buy nothing against anything automated.
- **No blanket "install a security appliance."** For a household, the checklist above outperforms a box that adds cost, complexity, and another unpatched device.

## Report and record

Give the user the findings table, then exactly one recommended next action — the highest-severity red item. Fixing everything at once on a household network guarantees that when something breaks, nobody knows which change did it.

In `~/ITGuy/machine.md` record the fixes applied and the router make, model, and firmware status. Never the passphrases, never the device inventory, never the addressing scheme. Put any 🔴 item the user declined onto the Watch List so the next checkup raises it again rather than silently forgetting it.
