# Fixing Wi-Fi Without Buying Anything

Work the ladder in `SKILL.md` in order. This file is rungs 1–4. Measure before and after each change with the recipes in `diagnostics.md` — an unmeasured "improvement" is a guess, and users remember guesses that failed.

## Rung 1 — Placement

Radio waves are absorbed by water and reflected by metal, which is why the worst router locations are so consistent: inside a media cabinet, on the floor, behind a television, in a corner of the building, next to a mirror, a microwave, a fridge, or a fish tank.

Better: central to the area used, high up (on a shelf rather than under one), out in the open, with at least a hand's width of clear space around it. If antennas are external, standing them at different angles helps, because a client's antenna orientation varies and matching polarisation matters more than aiming.

Concrete, brick, foil-backed insulation, and underfloor heating are effectively walls to Wi-Fi even when they look thin. A single such barrier between router and desk explains most "it's slow in the back bedroom" complaints, and no router upgrade fixes it — **moving the router two metres routinely beats replacing it.**

If the router must live where the cable enters the house, that is the real constraint, and the answer is rung 5 (a wired access point), not a bigger router.

## Rung 2 — Bands

| Band | Range | Speed | Use it for |
|---|---|---|---|
| **2.4 GHz** | Best | Slowest, most congested | IoT devices, far rooms, anything that only needs to work |
| **5 GHz** | Moderate | Fast, much cleaner | Laptops, phones, TVs — anything that matters |
| **6 GHz** (Wi-Fi 6E/7) | Shortest, poor through walls | Fastest, nearly empty | Same room as the router, high-bandwidth work |

Two failure modes worth knowing. A device that has parked itself on 2.4 GHz within sight of the router will feel broken while the hardware is fine — that is a **sticky client**, and the fix is to forget the network on that device and rejoin, or briefly disable 2.4 GHz while it reconnects.

Whether to give both bands **the same name** is a genuine trade-off, not a best practice. One name is simpler and lets devices roam; separate names (`Home` and `Home-5G`) give the user manual control and make sticky clients diagnosable. For a household with modern devices, default to one name; when someone has a stubborn device or an old smart plug that refuses to join a mixed network, split them and say why.

## Rung 3 — Channels

**On 2.4 GHz, only channels 1, 6 and 11 do not overlap.** Any other setting interferes with two neighbours instead of sharing cleanly with one. Auto-select frequently lands somewhere useless; check it and set it manually to whichever of 1, 6 or 11 the scan shows least occupied.

On 5 GHz there are many non-overlapping channels, so the goal is simply to avoid the neighbours the scan shows. Two things to weigh:

- **DFS channels** (roughly 52–144) are usually far emptier because many consumer devices avoid them. The catch is real: the router must vacate a DFS channel within seconds if it detects radar, which near an airport, port, or weather station shows up as **occasional total dropouts of a minute or more**. If a household reports mysterious, short, everything-at-once outages, check whether they are on DFS before anything else — and if they live near any of those, take DFS off the table.
- **Channel width.** 80 MHz is fast but occupies more spectrum and is more vulnerable to interference; 40 MHz is often steadier in a dense apartment block. If speed tests are high but the connection feels unreliable in a crowded building, narrowing the channel width is a real fix that almost no one tries.

## Rung 4 — Router settings that matter

- **Firmware update.** Do this first; it is the only rung-4 item that is also a security fix. Turn on automatic updates if offered.
- **SQM / Smart Queue / QoS.** If `networkQuality` showed RPM under 400, this is the fix. Look for "SQM", "fq_codel", "cake", "Bufferbloat", or "Adaptive QoS". Set it to slightly *below* the measured line rate — roughly 90–95% — because the mechanism works by keeping the queue on the router rather than in the ISP's equipment. Re-measure loaded RPM afterwards; success is loaded RPM back above 400, ideally close to the idle figure.
- **Turn off what is unused.** WPS off always (see `network-security.md`). Remote administration off unless the user knows they need it. Guest network on if there are IoT devices or visitors.
- **Band steering / 802.11k/v/r** — leave on by default; turn off only when diagnosing a sticky client.
- **Transmit power.** Counter-intuitively, *lowering* it can help in a dense flat by encouraging devices to roam to a nearer access point instead of clinging to a distant one. Only relevant once there is more than one access point.

## What not to do

- **Do not use MAC filtering as security.** MAC addresses are trivially spoofed, modern devices randomize them anyway, and it creates support problems every time a guest visits. It provides confidence, not protection.
- **Do not hide the SSID.** It does not conceal the network from anyone capable of looking, it breaks device roaming, and it makes ordinary setup harder.
- **Do not add a repeater to fix coverage** without measuring throughput through it first. See the halving problem in `SKILL.md`.
- **Do not raise the internet plan to fix Wi-Fi.** If the wired test at the router already meets the plan's speed, more bandwidth changes nothing about the room that has no signal — and the user will be paying for it monthly, forever.

## After each change

Re-measure SNR at the problem location and RPM idle and loaded, and show the user the before-and-after numbers. If a change did not move the numbers, say so plainly and revert it. Accumulating settings that "might help" is how a network becomes unmaintainable, and the next person to debug it — often you, in six months — inherits the mess.
