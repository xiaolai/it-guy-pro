# When It Stops Working

Written July 2026. Diagnose in this order — cheapest test first, and confirm each step before acting on the next. The most common cause has the cheapest fix, and rebuilding a server that was never broken is the classic wasted afternoon.

## Step 1 — Is the server alive at all?

```bash
ssh root@SERVER_IP 'systemctl is-active xray; uptime'
```

- **SSH works, Xray inactive** → service or config problem. `journalctl -u xray -n 50 --no-pager`, then `xray -test -config /usr/local/etc/xray/config.json`. Most often this follows a package upgrade or a hand-edited config.
- **SSH times out but the provider console shows it running** → go to Step 2.
- **Provider console shows it stopped** → billing lapse or a provider action. Check the account before touching anything technical. This is more common than people expect and looks exactly like a block.

## Step 2 — Is the IP blocked, or is the server down?

The distinction: a blocked IP is **unreachable from China but healthy from everywhere else.**

- Check from outside China: `ping.pe/SERVER_IP` or `check-host.net` — these test from many locations at once.
- Reachable globally but not from the user's network → **the IP is blocked.** Go to Step 4.
- Unreachable everywhere → the server is genuinely down. Reboot from the provider console; if it stays down, open a provider ticket.

A useful intermediate signal: try SSH on port 22 while 443 fails. **Port-specific blocking is real** — an address can have one port blocked while the rest of the box answers normally. That still counts as blocked for planning purposes: the address is characterized.

## Step 3 — Is it the client, not the server?

Before touching the server at all:

- Is the app actually running and switched on? (Ask without irony. It is frequently this.)
- Did the profile expire or get replaced by a stale import?
- Does the exit IP check return the server's address or the user's own?
- Does the connection work from a phone on cellular data? If yes, the problem is the Mac or the local network, not the server.
- Did the Mac update recently? macOS updates can reset network extension permissions, which silently breaks TUN mode.

## Step 4 — The IP is blocked. Get a new one.

**First, check the calendar, then wait if you can.** Blocks are frequently temporary — hours to about a week is the commonly reported range — and they often hit neighbouring addresses rather than targeting your configuration. They also track political events with real precision: one documented case had a server blocked exactly for the Two Sessions window, 4 March 2026 to 12 March 2026 at 15:00, and restored afterwards. **If an outage starts on the eve of a major political meeting or a sensitive anniversary, waiting is usually correct and rebuilding is wasted money.** Tell the user that honestly instead of selling them a new server. There is **no credible published measurement** of how long blocks last; anyone quoting a precise survival figure is inventing it, however authoritative the page looks.

If waiting is not acceptable, replace the IP by provider:

| Provider | Procedure |
|---|---|
| **Vultr** | Snapshot the instance → destroy → deploy from snapshot. Free, keeps the whole config, new IP from the regional pool. Confirm the snapshot exists **before** destroying anything |
| **RackNerd** | Self-service IP change button in the client portal. Free within 72 h of order, then $3 |
| **BandwagonHost** | Prefer **free datacenter migration** in KiwiVM — it re-rolls the IP and can improve the route at the same time. The paid IP change (~$8.79, unofficial figure) is the fallback |
| **Oracle** | Detach and reassign the public IP in the console. Free and unlimited, about a minute |
| **DMIT** | Ticket. Free every 15 days if ICMP and all TCP ports are dead nationwide; otherwise $5 |
| **CloudCone** | $2 ticket, once per 3 days — and refused if the IP still answers from anywhere else |
| **Linode** | No self-service path. Rebuild: snapshot or re-run the setup on a new instance, then delete the old one. This is the known weakness of Linode for this use case |

After any IP change: update the share link on every device (only the IP changes; UUID, keys, and shortId stay valid), and re-run the four client verification tests.

**If the replacement IP is blocked within days, stop re-rolling.** That pattern means the range is being watched, not that you were unlucky. Change provider or region — and if the user is on a second address from the same host, do not buy a third.

Two reasons this matters more than it appears. Address reputation is a property of the **block, not the host** — in the USENIX Security 2022 OpenVPN study, 35 of 41 obfuscated deployments had a vanilla OpenVPN server in the same /29, so recycled budget ranges carry their neighbours' history. And documented censorship-system design includes **subscriber-level tagging**: once a subscriber is marked as a known circumvention user, later unknown high-bandwidth flows from that subscriber are treated as suspicious. That marking follows the *person*, so it burns each new server they move to. When re-rolling stops working, the thing to change is structural — provider, region, architecture, or traffic volume — not the number in the config.

## Step 5 — Working but slow

Establish whether it is the route, the time, or the link:

- **Slow only 20:00–23:00 Beijing time** → peak congestion on the return path. This is the expected behaviour of a standard-route box and it is not a fault. The fix is a better route (CN2 GIA), not a rebuild. Say so plainly rather than fiddling.
- **Slow always, and it used to be fast** → check whether the monthly transfer allowance is exhausted. Vultr and Linode bill overage per GB, but budget hosts more often throttle to a crawl instead — check the provider's bandwidth meter before diagnosing anything else.
- **Slow on Wi-Fi, fine on cellular** → local network, not the server.
- **Confirm BBR is on:** `sysctl net.ipv4.tcp_congestion_control` should print `bbr`.
- **CDN-fronted setup that is slow** → expected. Free-plan Cloudflare has no usable mainland presence, so traffic hairpins overseas. If speed matters, that architecture is the wrong one; see the decision table in `SKILL.md`.

## Step 6 — Everything foreign fails, including a plain browser, but the tunnel is up

Check the borrowed site: if the REALITY `dest` has itself become blocked or has changed its TLS configuration, the handshake fails. Re-verify it:

```bash
curl -sI --tlsv1.3 --http2 https://YOUR_DEST | head -3
```

If it no longer answers with TLS 1.3 and HTTP/2, pick a different `dest`, update `serverNames` to match, restart Xray, and reissue the share link with the new `sni=`.

## What not to do

- **Do not rebuild a working server** to fix a client problem. Confirm the layer before acting.
- **Do not empty-handedly re-roll IPs** more than twice in a row — see Step 4.
- **Do not add a second protocol** hoping one gets through. Two well-chosen paths on **different addresses** help; two protocols on one blocked IP do nothing.
- **Do not switch to Hysteria2 for speed.** Its congestion-control signature is documented as near-perfectly identifiable (Wang et al., FOCI 2025, flagged all 1,257 test flows). Speed is worthless if the flow is identified.
- **Do not follow "restart everything" advice** from search results. This topic's search results are dominated by AI-generated affiliate content with fabricated specifics.

## Record it

Append what happened to the visit log, and if a cause recurs — a particular provider's IP blocked twice, or reliable evening congestion — write it into the profile's Known Quirks. The second occurrence should be diagnosed from memory in one minute, not rediscovered from scratch.
