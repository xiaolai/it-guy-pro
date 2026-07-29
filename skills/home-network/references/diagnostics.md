# Measuring the Network

Verified against macOS on 29 July 2026. All commands here are read-only and need no admin rights unless flagged.

**Two tool notes that most guides get wrong.** The old `airport -I` utility was removed in macOS 14.4 and no longer exists — do not use it or suggest it. And `wdutil info` requires sudo outright (without it, it just prints usage), which the safety contract hands to the user rather than running. **`system_profiler SPAirPortDataType` returns signal, noise, channel, PHY mode, and transmit rate with no admin rights at all** — make it the primary recipe and only escalate to `wdutil` when something is genuinely missing.

## Wi-Fi signal quality

```bash
system_profiler SPAirPortDataType 2>/dev/null | sed -n '/Current Network/,/^ *$/p'
```

Read four fields, and interpret them against these thresholds rather than "bars":

| Field | Meaning | Good | Marginal | Bad |
|---|---|---|---|---|
| **Signal** (RSSI, dBm) | How loud the router is here. Closer to zero is better | −30 to −60 | −61 to −70 | below −70 |
| **Noise** (dBm) | The interference floor | below −90 | −85 to −90 | above −85 |
| **SNR** (signal minus noise) | **The number that actually predicts performance** | above 25 dB | 15–25 dB | below 15 dB |
| **PHY Mode / Transmit Rate** | The standard and negotiated speed in use | 802.11ax/be | 802.11ac | 802.11n or older |

**SNR is the field to lead with.** A −65 dBm signal with a −95 dBm noise floor (SNR 30) works well; the same −65 dBm in a noisy flat with a −80 dBm floor (SNR 15) will stutter. Reporting only signal strength is why "full bars but it doesn't work" feels mysterious to users. **−67 dBm is the practical threshold for reliable video calls**; below that, expect trouble regardless of the plan's speed.

Measure at three places minimum: next to the router, where the user actually works, and the worst room they complain about. One reading tells you nothing about coverage.

## Speed *and* responsiveness

```bash
networkQuality -v
```

Built into macOS since Monterey (2021) at `/usr/bin/networkQuality`, and better than any web speed test, because it reports **responsiveness in RPM (round-trips per minute)** alongside throughput.

| RPM | Verdict |
|---|---|
| above 800 | Excellent — video calls and gaming will feel crisp |
| 400–800 | Acceptable |
| below 400 | **Bufferbloat.** Calls stutter and pages hang *while something else is downloading*, even though the speed number looks fine |

**Bufferbloat is the most common invisible cause of "the internet feels slow."** The user's speed test reads 500 Mbps and everything still lags during a backup or a game update, because oversized buffers queue packets instead of dropping them. It is not fixed by a faster plan or a faster router — it is fixed by enabling **SQM / Smart Queue Management / fq_codel / cake** on the router if it offers it (many do under "QoS" or "Bufferbloat"), or by replacing a router that does not. Diagnosing this correctly is the highest-value thing in this file, because the intuitive fix — pay for more bandwidth — makes no difference at all.

Run it twice: once idle, once while a large download runs. The gap between the two RPM figures *is* the bufferbloat.

## Isolating the layer

**Check for an active tunnel before anything else.** If a VPN or proxy tunnel holds the default route, every measurement below describes the tunnel rather than the home network — the "router" ping lands on a tunnel endpoint and the speed test measures a server in another country. This plugin ships `/it-guy-pro:open-internet`, which creates exactly such a tunnel, so the case is common rather than exotic:

```bash
route -n get default 2>/dev/null | awk '/interface/{print $2}'   # utun*/ppp*/ipsec* means a tunnel
```

If a tunnel is active, ask the user to switch it off for the duration of the diagnosis, and say why in one sentence. If they cannot, target the Wi-Fi interface explicitly as below and tell them the internet-side numbers are not trustworthy this run.

**Find the router robustly.** Do not use `route -n get default | awk '/gateway/{print $2}'` on its own: on a point-to-point or tunnelled default route there is no `gateway:` field at all, so it silently yields an empty string and the next command pings nothing. Ask the Wi-Fi interface for its DHCP router instead, which is both more reliable and semantically what "the router" means here:

```bash
WIFI=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}')
ROUTER=$(ipconfig getoption "$WIFI" router)
echo "$WIFI -> $ROUTER"

ping -c 20 "$ROUTER"                                     # local link quality
ping -c 20 1.1.1.1                                       # beyond the router
scutil --dns | awk '/nameserver/{print $3}' | sort -u     # DNS in use
```

If `$ROUTER` comes back empty, the Mac is not on Wi-Fi (check Ethernet with the same `ipconfig getoption` against that interface) or has no DHCP lease — which is itself the finding.

Interpretation:

- **Loss or high variance pinging the router** → the problem is between the Mac and the router: Wi-Fi, not the ISP. Do not call the provider.
- **Router clean, `1.1.1.1` lossy** → upstream. That is an ISP conversation, and the ping output is the evidence to bring.
- **Both clean but browsing is slow** → suspect DNS. Compare against a known resolver before blaming anything else.
- **Wired is clean and Wi-Fi is not** → the entire fix is free; go to `wifi-tuning.md`.

For the wired comparison, connect by Ethernet (an adapter is fine) and re-run `networkQuality`. This single comparison decides whether the user should spend money at all.

## What is on the network

Populate the ARP cache with a broadcast ping, then read it — no extra software, no port scanning:

```bash
ping -c 3 224.0.0.1 >/dev/null 2>&1
arp -a
```

Discover services the friendly way, which names printers, speakers and NAS boxes without probing them:

```bash
dns-sd -B _services._dns-sd._udp local.      # what service types exist (Ctrl-C to stop)
dns-sd -B _ipp._tcp local.                   # printers
dns-sd -B _smb._tcp local.                   # file shares
```

**This list is a floor, not a census.** The multicast-ping trick only populates ARP for devices that answer right now, so sleeping phones, powered-down machines, and anything on a guest network with client isolation enabled will be missing. Say "at least these" rather than "these are all your devices" — a user who concludes a device is gone because it is absent from this list has been misled.

**Three cautions.** Keep discovery inside the user's own subnet — `arp -a` and Bonjour do this naturally, which is exactly why they are preferred here over a scanner. Do not port-scan discovered devices; knowing a device exists is inventory, probing it is not. And expect **MAC randomization**: iPhones, iPads and Macs present a different "private Wi-Fi address" per network by default, so MAC addresses no longer reliably identify a device across networks, and DHCP reservations keyed to a MAC will break when a user toggles that setting. Identify by hostname and service type instead, and tell the user why the router's device list looks like strangers.

## Channel congestion

The GUI path is the right one for a pedestrian and it is free: hold **Option** and click the Wi-Fi menu, choose **Open Wireless Diagnostics**, then in the menu bar pick **Window → Scan**. It lists every nearby network with its channel, band, and signal, and recommends a best channel.

Read it for two things: how many neighbours share the user's 2.4 GHz channel, and whether the router sits on a non-overlapping one (1, 6, 11). On 5 GHz, note whether the chosen channel is a DFS channel — see `wifi-tuning.md` for why that matters.

## Recording results

Write down the numbers, not impressions: SNR at each location, RPM idle and loaded, ping loss to the router and beyond. A future "it got slow again" is answerable in one minute against a baseline and unanswerable without one. Store the summary — not the device inventory, MAC addresses, or SSID — per the privacy rule in `SKILL.md`.
