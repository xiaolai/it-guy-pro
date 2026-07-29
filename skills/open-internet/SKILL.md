---
name: open-internet
description: Decision logic for building a personal unrestricted-internet connection from a censored network — which architecture to use (CDN-fronted vs direct), which protocols work and which are detectable, and the boundaries of what to help with. Load before any /it-guy-pro:open-internet work.
---

# Open Internet — what to build and why

Facts verified July 2026. **Every price, protocol status, and provider claim in this skill and its references carries a date. Anything older than three months must be re-verified before you act on it** — this field moves, and stale advice here costs the user real money.

Read `references/legal-and-limits.md` before anything else. Its boundaries are binding: personal and household use only, no resale, no "airport" operation. That is not a style preference — it is the line where the user's legal exposure changes category.

The rest of the detail lives in four more references, each loaded at the step that needs it: `vps-buying.md` (what to buy, what it costs, how to get a new IP), `server-setup.md` (build the server, both architectures), `client-setup.md` (connect the Mac and verify), and `troubleshooting.md` (diagnose in cheapest-first order). This file holds only the decisions that determine which of those you follow.

## The one thing to get right: this is an architecture choice, not a protocol choice

Beginners (and most tutorials) argue about protocols. The decision that actually determines how a setup fails is whether the client connects to a **CDN** or **directly to your server**. The two resist different attacks, and no protocol changes that.

| | **CDN-fronted** (VLESS/VMess + WS or httpupgrade + TLS behind Cloudflare) | **Direct** (VLESS + XTLS-Vision + REALITY on 443) |
|---|---|---|
| What the censor sees | Ordinary HTTPS to a Cloudflare anycast IP | A genuine-looking TLS handshake to a borrowed hostname |
| Deep inspection | **Measurably weaker than it looks.** Xue et al. (USENIX Security 2024) detect the *nested* TLS handshake protocol-agnostically from burst sizes and round trips — 0.697 true-positive rate against shadowsocks-over-WebSocket-over-TLS at 0.05% false-positive rate. No evidence the GFW deploys this, but it is measured, not theoretical | Best available: **Vision exists precisely to defeat that signature** by splicing inner TLS records, uTLS matches a real browser, and active probes reach the genuine borrowed site |
| Origin IP exposure | **Never exposed.** China clients only ever touch Cloudflare | **Fully exposed.** Your server IP is the endpoint |
| IP blocking | Not applicable — blocking Cloudflare's pool is not politically cheap | **No defence whatsoever.** REALITY resists *inspection*, not a decision to null-route your address |
| Name/SNI blocking | **This is its failure mode** — your hostname can be blocked while Cloudflare stays up. Fix: new hostname | Not applicable — no hostname of yours is on the wire |
| Speed into China | Mediocre. No usable mainland Cloudflare presence on free plans; traffic hairpins to an overseas PoP and congests 20:00–23:00 | Determined by the server's route. A CN2 GIA box is dramatically better at peak |
| Moving parts | VPS + domain + CDN account + DNS + certificate + path config | VPS only. No domain, no certificate, no third-party account |

**REALITY and XTLS-Vision cannot traverse a CDN, by design.** REALITY needs the client's ClientHello to reach the REALITY server itself, because the server reads an embedded secret to decide whether to serve the borrowed certificate or transparently proxy to the genuine site; a CDN terminates TLS at its edge, so there is nothing left to intercept. Vision splices inner TLS records on a raw stream, which WebSocket framing breaks. This will not change with a version bump — do not go looking for a config that combines them.

## Choosing — ask these in order

1. **Does the user already run a CDN-fronted setup that works?** Then leave it. Migrating VMess→VLESS behind the same CDN buys almost nothing in detection resistance: the inner protocol was never on the wire. (It does buy slightly lower overhead — VLESS drops an encryption layer that is redundant inside TLS — and removes VMess's ±90s clock-sync requirement, a real failure mode when NTP drifts. Worth doing opportunistically, not worth a migration project.)
2. **Is the server's IP already characterized** — an old address, a burned hosting range, port-specific blocking already observed, or a host that cannot cheaply issue a new IP? Then **do not put a direct listener on it.** Direct architecture is a bet on the IP, and that bet is already lost. Choose CDN-fronted, or buy a fresh box.
3. **Clean slate, and speed matters?** **Direct (VLESS + Vision + REALITY)** on a well-routed IP from a provider with cheap IP replacement. Fewest moving parts, nothing to renew, best inspection resistance, and the failure mode — a blocked IP — has a five-minute remedy the user can perform.
4. **Can the user run two?** Then run both, and stop treating it as a fork. Direct as the fast path, CDN-fronted as the always-works baseline, with client-side health checks failing over automatically (Clash and sing-box both do this natively). This is what experienced users actually run, and it is the honest recommendation whenever the budget allows.

For a non-technical user starting from nothing, the default is **(3)**, then add **(4)** once they have lived with it. The complexity delta in (1)/(2) — domain, DNS, certificate, CDN account — is where beginners abandon the project.

## Protocols: what to use, what to refuse, and the mechanism

| Protocol | Status, July 2026 | Mechanism |
|---|---|---|
| **VLESS + XTLS-Vision + REALITY** | **Recommended for direct.** No peer-reviewed work demonstrates GFW detection | Borrows a real site's certificate; Vision removes the TLS-in-TLS signature; survives active probing because probes reach the genuine borrowed site |
| **VLESS/VMess + WS or httpupgrade + TLS + CDN** | **Recommended for CDN-fronted.** Sound in practice | Inner protocol never appears on the censor-visible path; the censor sees HTTPS to a CDN |
| **Trojan** | Works, superseded | Needs a real domain and certificate; REALITY achieves more with fewer parts |
| **Shadowsocks-2022** | Works; simple and fast | Fine as a fallback, weaker against active probing than REALITY |
| **Hysteria2 / TUIC** | **Sources genuinely conflict — say so.** Widely used and reported working; also measured as fingerprintable | Wang et al., FOCI 2025: Hysteria's **Brutal congestion control** flagged all 1,257 test flows with 16 false positives. The catch is that Brutal is the *reason* to choose Hysteria2 — disable it and the speed advantage goes with it. Acceptable only as the *second* of two paths, where losing it costs availability rather than access; never as a user's only route |
| **WireGuard** | Unreliable cross-border on IPv4; **IPv6 notably less affected**; fine domestically | A handshake init literally begins `01 00 00 00`; fixed 148/92/64-byte handshakes; mac2 of 16 zero bytes; keepalive every ~2 minutes forever; transport lengths always a multiple of 16. Blocking is unidirectional (UDP dropped *from* server:port toward China) and lands on IP:port for days. Cloudflare moved WARP to MASQUE reportedly because WireGuard has "insufficient obscurity" |
| **OpenVPN** | Fingerprinted, with the strongest measurement of any protocol here | Xue et al., USENIX Security 2022 (Best Paper): **85.9% recall on vanilla flows at a 0.0039% false-positive rate, median 7.9 seconds to flag**, on a real 20 Gbps ISP deployment. The XOR patch is structurally worthless — its byte-reversal excludes the first byte, which is where the opcode lives |
| **L2TP/IPsec, IKEv2** | **Do not build this — but the honest failure mode is not "blocked."** It connects and works, then the server IP dies, typically over weeks to months | The handshake is cleartext ISAKMP on **UDP 500**, then UDP 4500 after NAT traversal: fixed-format header, all-zero responder SPI in the first packet, fixed version byte and exchange type — a stateless single-packet byte-offset match at a well-known port. **Cheaper to detect than OpenVPN, far cheaper than WireGuard.** The leaked Geedge ruleset names `isakmp` as a first-class protocol beside `wireguard` and `openvpn` under a "Regulatory Risk" category, and a June 2026 Chinese campus-monitoring product sheet lists `ipsec` among protocols it identifies. DMIT's acceptable-use policy bans China-bound L2TP, IPsec, OpenVPN, PPTP and AnyConnect tunnels by name while explicitly permitting encrypted private proxies — so on that host the legacy protocol is a terms violation and REALITY is not |
| **PPTP** | Dead | Cleartext magic cookie `0x1A2B3C4D` on TCP/1723 plus GRE; also cryptographically broken independent of censorship |
| **Raw VMess over TCP** | Obsolete | The handshake is on the wire and historically probe-able. Note this critique applies **only** to the unwrapped form — it says nothing about VMess inside TLS behind a CDN |

If a user asks for L2TP by name, do not simply build it, and do not claim it "doesn't work" either — that is easy to disprove and costs you their trust. It connects fine. Say the true thing: the handshake announces itself in cleartext on a known port in its very first packet, so the address gets marked and eventually blocked, usually after weeks or months of working — long enough for them to depend on it.

**Expect the objection "but my company's L2TP works fine."** It probably does, for reasons that do not transfer to a personal setup: the company is on a licensed cross-border circuit that never traverses the firewall, it has a public-security filing that effectively allowlists its egress, or its volume is a few megabytes of mail sync a day. Domestic L2TP/IPsec is not restricted at all — **the border is the discriminator, not the protocol.**

One myth to *not* repeat: the claim that Chinese regulation "permits MPLS/SD-WAN but specifically prohibits IPsec" cites no actual regulation. The rules restrict unapproved cross-border channels; IPsec is merely the most common do-it-yourself instance.

## Reliability doctrine

- **Blocks are usually temporary and often not about you.** Reported experience runs from "three servers blocked in two days, all unblocked within about a day" to "the same box ran untouched for over a year." Blocks frequently hit neighbouring addresses in the same range and cluster around politically sensitive dates. **No credible published measurement of fresh-IP survival time exists** — treat any specific number ("IPs last 7 days", "80% survive a month") as invented, including in guides that sound authoritative.
- **Therefore: cheap IP replacement beats a marginally better route.** This is the single most useful selection criterion, and it is the one no beginner thinks about. See `references/vps-buying.md`.
- **But "just get a new IP" is not an unlimited resource.** Documented censorship-system design includes **subscriber-level tagging**: once a subscriber is marked as a known circumvention user, their subsequent unknown high-bandwidth flows are treated as suspicious — which follows the *person*, not the address, and burns each new server they move to. Treat repeated re-rolling as a signal to change something structural (provider, region, architecture, traffic volume), not as a routine that scales.
- **Neighbours burn you.** In the USENIX Security 2022 OpenVPN study, 35 of 41 obfuscated deployments had a vanilla OpenVPN server inside the same /29. Address reputation is a property of the block, not just your host — one more reason heavily-recycled budget ranges cost more than they save.
- **Blocks track the political calendar, precisely.** One documented case: a server blocked exactly for the Two Sessions window, 4 March 2026 through 12 March 2026 at 15:00, then restored. If an outage begins on the eve of a major political event, waiting is often the correct action and rebuilding is wasted effort.
- **There is no evidence of ASN-wide blocking of the major hosts** (Vultr, Linode, DigitalOcean, Oracle, Hetzner) by China. That behaviour is documented for Iran, not here. Claims that "all of provider X is blocked" are unsupported.
- **Two paths beat one good path.** Whatever the architecture, a user with a second way in never has an emergency.

## Sources are polluted — verify before quoting

This topic has an unusually high density of AI-generated affiliate content that fabricates precise-sounding numbers. Concretely: `greatfirewallguide.com` claims Vultr has "zero IP block history" and is "never blocked by GFW" — both false — and cites protocol success rates to the decimal with no methodology, alongside affiliate links. SEO-titled GitHub repos and Google Sites pages with names like "BandwagonHost Review 2026" are fake. **`gfw.report` has published nothing since September 2025**, so anything citing a 2026 GFW Report finding is fabricated.

Prefer: provider API and cart pages for prices, peer-reviewed measurement work for protocol claims, LowEndTalk and V2EX for operational experience. Cite dates. When you cannot verify, say so rather than filling the gap.

**Two anchors for judging staleness.** The most recent rigorous academic measurement of any of these VPN protocols remains **Xue et al., USENIX Security 2024** — the FOCI/PETS 2026 workshop, held 20 July 2026, contained no VPN-protocol-fingerprinting paper at all, so nothing newer exists to cite. And note the asymmetry in the evidence base: **no academic measurement paper has ever studied IPsec/IKE blocking in China**, because the circumvention community abandoned it long before researchers got interested. Claims about L2TP in China rest on leaked vendor rulesets and user reports, not measurement — hold them at medium confidence and say so.

Where evidence is simply absent, refuse to fill it. There is no credible China-specific measurement of AmneziaWG, and no published figure for fresh-IP survival time. Any percentage you encounter for either is fabricated.
