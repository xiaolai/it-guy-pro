# Buying Hardware — and When Not To

Written July 2026. Standards and price tiers age; **verify current models and prices before quoting them**, and prefer describing the category over naming a specific product that may be discontinued.

## First, the honest question

Before recommending anything, answer this out loud: **which rung of the ladder failed?** If placement, band, channel, router settings/SQM, **and wired backhaul** have not each been tried or ruled out, the answer is "buy nothing yet" and you should say it. Rung 5 matters most here, because this file's own top recommendation *is* a wired access point — reaching for a router while an Ethernet run is still untried gets the answer backwards. A large share of home network spending fixes nothing, and the user remembers who advised it.

Buying is the right answer when one of these is true:

| Situation | What to buy |
|---|---|
| Coverage gap that placement cannot solve (walls, floors, long house) | **A second access point with a wired connection** — the highest-value purchase in home networking |
| Router is more than about six years old, or is 802.11n / Wi-Fi 4 | A current Wi-Fi 6 router |
| Bufferbloat and the router has no SQM setting | A router with SQM/cake support |
| Many simultaneous devices in a dense building | Wi-Fi 6 for OFDMA, which handles crowds better than raw speed does |
| ISP box is genuinely the weak link | Own router, ISP box in bridge mode — with the caveat below |

## Standards, without the marketing

**Wi-Fi 6 (802.11ax) is the sensible floor in 2026.** Its real advantage over Wi-Fi 5 is not headline speed but *crowd handling* — OFDMA and MU-MIMO let one radio serve many devices efficiently, which is what a modern home actually stresses.

**Wi-Fi 7 (802.11be) is rarely the reason a home network improves.** It matters only when all three of these hold: an internet connection faster than 1 Gbps, client devices that are themselves Wi-Fi 7, and same-room distances — because 6 GHz, the band where its gains live, is stopped by ordinary walls. A household with a 300 Mbps line and a five-year-old laptop gains nothing. Say so; the price difference is better spent on the Ethernet run.

The number in a router's name (AX5400, BE19000) is a sum of theoretical rates across all bands that no single device will ever see. It is a marketing figure, not a specification. Ignore it, and tell the user why so they can ignore it on their own next time.

## Mesh, access points, and extenders — the distinction that matters

| Kind | How the second unit reaches the router | Real-world result |
|---|---|---|
| **Wired access point** | Ethernet | **Best.** Full speed at both ends, no compromise. Cheapest per unit |
| **Mesh with wired backhaul** | Ethernet | Equal to the above, plus easier setup and roaming |
| **Mesh with dedicated radio** | A third radio reserved for backhaul | Good. The main reason to pay for tri-band |
| **Mesh sharing one radio** | Same radio as clients | Halves throughput |
| **Extender / repeater** | Same radio as clients | Halves throughput, usually a separate network name, no roaming. **Avoid** |

**The recommendation that saves the most money and disappoints marketing the most: run one Ethernet cable.** A €40 access point on a cable outperforms a €300 wireless mesh, every time. Where a cable cannot be run, **MoCA** (over existing TV coax) or a modern **powerline** adapter often works and both beat a wireless repeater — powerline being sensitive to which circuits the sockets are on, so buy it somewhere that accepts returns.

If it must be wireless mesh, buy **tri-band** so backhaul gets its own radio, and place units at the *edge of good coverage*, not in the dead zone — a mesh node with a weak link to the router just re-broadcasts a weak signal.

## The ISP router question

An ISP-supplied router counts as adequate when a wired test at it meets the plan's rated speed with RPM above 400 — measure that before blaming it, because blaming it is a reflex. When one genuinely fails that test, the options are:

- **Own router in front, ISP box in bridge mode** — cleanest, but bridge mode can disable the provider's TV or phone service, and providers vary in whether they document it, permit it, or support the line afterwards. Check what the household actually uses, and check the provider's own stance, before advising it.
- **Own router behind it, ISP Wi-Fi off** — keeps provider services working and is slightly less clean. It avoids double NAT only if the ISP box is set to pass a single address through (bridge or DMZ to the new router); leaving both boxes routing is precisely what creates the double-NAT problem below.
- **Keep it and add a wired access point** — often the best answer for a coverage complaint, and it changes nothing the provider supports.

Warn about **double NAT** (two routers both doing NAT): browsing works fine, but it breaks anything that needs an inbound connection — port forwarding, peer-to-peer and host-your-own-match multiplayer, and inbound VPN into the home. It is also genuinely confusing to debug months later, so it is worth naming at install time rather than discovering by symptom.

## Budget guidance

Frame spending against the problem, not the catalogue:

- **Under €50** — a wired access point, a long Ethernet cable, or a MoCA pair. This tier fixes more real complaints than any other.
- **€80–150** — a competent Wi-Fi 6 router with SQM support. Sufficient for most homes.
- **€200–400** — a tri-band mesh set, justified only by a genuinely large or awkward building.
- **Above that** — needs a specific reason the user can state. If they cannot state it, it is not the right purchase.

## What to tell them before they buy

1. **What problem this purchase solves**, in one sentence, and what it will *not* solve.
2. **The measurement it should improve**, so success is checkable rather than a matter of impression.
3. **The return policy** — especially for powerline adapters and mesh in thick-walled buildings, where the outcome is genuinely unpredictable until tested in that specific home.

Then re-measure after installation and show them the before-and-after. A purchase that did not move the numbers should go back, and a user who learns that their IT guy will say so is a user who trusts the next recommendation.
