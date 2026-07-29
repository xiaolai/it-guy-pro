# Buying the Server

**Prices verified 29 July 2026** against provider APIs and cart pages unless marked otherwise. Re-verify anything you are about to quote if today is more than three months later. Do not quote a price from memory.

## What you are actually buying

A proxy is a latency-and-loss workload, not a compute workload. A 1 vCPU / 512 MB box saturates a gigabit link running VLESS-REALITY; **CPU is never the constraint.** What the user feels is packet loss on the **return path into China** between roughly 20:00 and 23:00 Beijing time. TCP reads loss as congestion and collapses its window, so 6% loss does not cost 6% of throughput — it costs most of it. That is why a CN2 GIA box holding ~120–140 ms with minimal peak degradation can feel dramatically faster in the evening than a standard-route Tokyo box that is *faster* off-peak (40–60 ms from Shanghai) but bleeds 10–20% loss at peak.

Routing is asymmetric: the path out and the path back are chosen independently, and the return path is the one that matters.

Explain this to the user in one sentence — "we're paying for the quality of the road, not the size of the engine" — because otherwise every price comparison they do themselves will be wrong.

## Routes, briefly

| Route | Tier | Peak behaviour |
|---|---|---|
| **CN2 GIA** (AS4809, `59.43.*` end to end) | Top consumer-buyable tier | Near-flat; bypasses the congested backbone |
| **CMIN2** / **CUII 9929** | Premium, comparable | Stable, but tiny bandwidth allocations |
| **CN2 GT** | Mid — **dead as a purchasing category in 2026** | Its domestic leg is the bottleneck; >8% loss at peak |
| **AS4837 (Unicom)**, standard BGP | Consumer | Fine off-peak, degrades in the evening |
| **163 / ChinaNet**, **CMI** | Bottom | Deliberate QoS drops; heavy evening congestion |

**Stale-advice trap:** guides still recommend BandwagonHost's $49.99 plan "for the CN2 GT route." That plan is standard-route only now — DC8 was renamed DC8 ZNET and lost its CN2 GT feed, and DC3 CN2 was withdrawn from the cheap plan. If a user arrives quoting this, correct it.

## Providers

| Provider | Entry price (Asia) | Route | IP replacement | Verdict |
|---|---|---|---|---|
| **Vultr** | **$5.00/mo** `vc2-1c-1gb`, Tokyo/Osaka/Seoul/Singapore. Overage $0.01/GB | Standard (NTT in Tokyo). 40–60 ms off-peak, 10–20% loss at Telecom peak. **Avoid Singapore for China** (200 ms+) | **Free** — snapshot, destroy, redeploy. Documented first-class workflow | **Default recommendation.** The $2.50/$3.50 plans are US-only — do not quote them for Asia |
| **BandwagonHost CN2 GIA-E 20G** | **$169.99/yr** (or $49.99/quarter) | **CN2 GIA** — the real thing | $8.79 per change ⚠️ unofficial figure. **But free datacenter migration** between ~12 DCs, which also re-rolls the IP | **The speed upgrade.** Right answer when evening performance actually matters |
| **BandwagonHost 20G KVM** | $49.99/yr | **Standard only — no CN2** | as above | Fine cheap box; do not sell it as CN2 |
| **Linode / Akamai** | **$5.00/mo** Nanode, Tokyo 2, Tokyo 3, **Osaka**, no regional premium. Overage **$0.005/GB — cheapest of the majors** | Standard, no CN2 | **Worst in class.** Cannot change an instance's primary IPv4; extra IPs need a justified ticket; support has historically rejected "blocked in China" requests. Only remedy is destroy and rebuild | Good boring host, **dominated here.** See below |
| **RackNerd** | **~$11/yr** 1 GB (LowEndBox, Jan 2026); price locked at renewal | Asia-optimised blends, not CN2 | **Free within 72 h, then $3**, self-service button | Best cost-per-year. Caveat below on burned ranges — it is the real cost of the price |
| **DMIT** | ~$36.90/yr LAX.Pro.WEE ⚠️ secondary sources only | Real CN2 GIA, LA/San Jose/HK/Tokyo | Free every 15 days if fully dead nationwide, else $5 | Good, but **premium stock persistently sold out through May 2026** |
| **DigitalOcean** | $4–6/mo | **Singapore is the only Asia-Pacific region** — poor route to China | Destroy and recreate | Largely disqualified on geography |
| **Oracle Always Free** | $0 | Unmeasured from China | **Free and unlimited** — best mechanism anywhere | **Do not recommend.** See below |
| **Hetzner** | €5.49+ and €0.50/mo per IPv4; prices rose +30–50% (1 Apr 2026) then +113–175% on some lines (15 Jun 2026) | Frankfurt→Shanghai ~250 ms. Singapore exists but is their priciest region | Free swap in console | Wrong hemisphere |
| **CloudCone** | ~$15/yr | LA | $2, conditional | **Avoid in 2026** — see below |
| **Alibaba Cloud HK** | ~¥25/mo cheap plan | Cheap plan rides the *wrong* line; the China-optimised line is **232 CNY per Mbps/month** | — | **Actively warn against.** Account ties to real-name ID under PRC jurisdiction; the only provider with proxy-targeted enforcement reports |

### Three providers that need explaining, not just listing

**Linode — the honest answer when a user asks for it by name.** It is a genuinely good host: verified $5 Nanode in Tokyo 2, Tokyo 3, and Osaka with no regional premium, the cheapest overage of the majors at $0.005/GB, ~99.98% uptime, and — notably — Akamai's acceptable-use policy contains **no clause about VPN, proxy, anonymisation, or tunnelling at all**, the most permissive text of any provider examined. It is not a mistake; it is *dominated*. The one operation this use case needs most is issuing a new IP, and Linode is the worst provider in this comparison at exactly that: you cannot change an instance's primary IPv4, additional addresses require a justified support ticket reviewed against ARIN guidelines, and the IP-swap feature only moves addresses between two of your own instances in the same datacenter. Historically, support has rejected "my IP is blocked in China" tickets outright. Vultr costs the same $5 in the same cities and makes IP replacement a documented one-click path. Recommend Vultr; say plainly that Linode is fine hardware with the wrong operational model for this job.

**Oracle Always Free — better on paper than in life.** On **15 June 2026 Oracle silently halved the ARM allowance** from 4 OCPU / 24 GB to 2 OCPU / 12 GB (guides still quoting 4/24 are stale). Worse for this use case: Oracle reclaims Always Free compute when 7-day 95th-percentile CPU, network, **and** memory are all under 20% — a single-user proxy is close to a worst case for that test. Add chronic "out of host capacity" in exactly the useful regions (Tokyo, Osaka, Singapore each have a single availability domain, so Oracle's official "try another AD" workaround does not exist), plus a documented record of accounts deleted without recourse. Its free unlimited IP changes are the best mechanism in this table and still do not redeem it. The Chinese technical community does not treat it as a contender.

**CloudCone — avoid, for operator reasons rather than price.** On 30 January 2026 an attack on their Los Angeles budget line caused **permanent, unrecoverable data loss** and about a week of downtime by their own admission; a July 2026 datacenter migration then ran 12+ hours over with problems persisting for weeks, backups still non-functional, and refunds refused.

## The decisive criterion beginners miss: how you get a new IP

Blocks happen, are frequently temporary, and often hit neighbouring addresses rather than targeting your configuration. Assume the user will need a new IP at least once during the first year. **A free, self-service, five-minute IP replacement is worth more than a marginally better route** — and it is the difference between a problem the user can fix alone and a support ticket they cannot write.

Ranked by how well a non-technical person can actually perform it: **Oracle** (free, unlimited, 60 seconds) > **Vultr** (free, snapshot-destroy-redeploy) ≈ **RackNerd** (a button; free for 72 h then $3) > **DMIT** (free every 15 days, conditional) > **BandwagonHost** ($8.79, but free datacenter migration achieves the same thing and improves the route) > **CloudCone** ($2, refused if the IP is reachable from anywhere else) > **Linode** (rebuild from scratch).

**Buy the neighbourhood, not just the address.** Reputation attaches to the surrounding block: in the USENIX Security 2022 OpenVPN study, 35 of 41 obfuscated deployments had a vanilla OpenVPN server inside the same /29. That is the hidden cost of the cheapest tier — a $11/yr box on a heavily recycled range inherits every previous tenant's history, and no amount of protocol choice fixes an address that was suspect before you rented it. It is also why re-rolling within the same provider eventually stops helping.

Also worth knowing: AWS Lightsail attaches and re-attaches static IPs free while the instance runs, from $5/mo. If IP churn is the dominant concern, it belongs on the shortlist.

## Recommendation to give

| Situation | Buy | Yearly |
|---|---|---|
| **Default for a non-technical user** | Vultr `vc2-1c-1gb`, **Tokyo or Osaka** (Seoul for northern China) | **$60** |
| **Evening speed genuinely matters** (video, large downloads, heavy dev work) | BandwagonHost **CN2 GIA-E 20G** | **$169.99** |
| **Absolute minimum budget** | RackNerd 1 GB | **~$11** |
| **Never** | Alibaba Cloud (identity exposure), CloudCone (operator reliability), Oracle (reclamation + capacity), anything sold as "CN2 GT" | — |

Present one recommendation plus the cheaper option, not the whole table. The table is for your reasoning, not for a beginner's screen.

## Paying for it from China

Payment is a real bootstrap obstacle and it has a boring answer: **BandwagonHost accepts Alipay, WeChat Pay, PayPal and cards; Vultr accepts Alipay and PayPal.** An international credit card is not required for either. Purchases are tied to a card and an email — say this plainly, because a user who believes they are buying anonymity has misunderstood what they are buying.

Chinese-language guides consistently advise registering a Vultr account **from a normal mainland connection without a proxy**, because Vultr's fraud screening flags proxied signups. Vultr's KYC suspensions are its main real-world risk — accounts frozen for identity verification with infrastructure access cut immediately. Warn the user before they put a year of prepayment into it.

## The cost conversation, honestly

Self-hosting is **not** the cheap option, and telling a user otherwise sets them up to feel cheated. In the June 2026 Stanford / GFW Report / CU Boulder survey ([arXiv:2606.18427](https://arxiv.org/abs/2606.18427)), commercial-service users paid a median of **$2.80/month** while self-hosters paid a median of **$4.60/month**. Self-hosting buys **control, privacy, and not being someone else's product** — not savings.

What the commercial alternative actually costs the user, from the same study: of 35 services subscribed to in spring 2025, **only 15 were still operating five months later.** Of 368 censored domains tested through 15 services, **198 were blocked by at least one of them, and only 2 of 15 blocked nothing** — twelve blocked Falun Gong sites, nine blocked RFA/VOA/NYT, and five blocked `110.qq.com` and `12321.cn`, the official channels for reporting illegal content. Some of those same services publish audit logs showing timestamp, node, and matched rule — meaning they log and rule-match their users' requests by design, and say so openly. Payment is real-name via Alipay or WeChat. **A user escaping censorship into a service that censors them, logs them, and knows their legal identity has not solved their problem.** That is the argument for self-hosting, and it is stronger than any price argument.

Consumer VPN apps are the weakest option: Psiphon, Orbot, NordVPN, ProtonVPN, and ExpressVPN all measured blocked from Beijing in August 2025; LetsVPN (LetsVPN), the most popular consumer VPN in China, announced termination of mainland operations on 28 April 2026. Roughly one in five of the top 100 free VPNs on the US App Store were found to be covertly Chinese-owned.

**Do not push the user to a single path.** In the same survey, 55% used a commercial service and 55% self-hosted — heavily overlapping. A cheap monthly subscription as an always-works fallback alongside a self-hosted box is what the community converged on, and it is the honest recommendation. If they buy a commercial service, tell them to **pay monthly, never annually** — the attrition data is why.

## Strategic context worth one sentence to the user

On 1 April 2026 a cross-border leased-line rectification campaign began; MIIT convened the three carriers that week, notices explicitly banned "VPN, proxy and related businesses," and enforcement was immediate disconnection. Relay-based commercial services collapsed because their **domestic ingress nodes** were cut, and replacement circuits were being found and cut within days. The campaign hit the infrastructure category that premium commercial services depend on — while ordinary overseas VPS boxes were untouched. Advice from 2024–2025 to "just buy an IPLC airport" is materially weaker now, and a plain self-hosted box has become comparatively *more* robust than it was.

## Uncertainty to carry forward, not paper over

- BandwagonHost's $8.79 IP-change fee and the frequency limit on free datacenter migration are unconfirmed officially (their pages require login). Check KiwiVM before relying on migration as a free IP swap.
- DMIT pricing is from secondary sources; their site blocks automated fetches.
- Hetzner prices moved twice in three months — verify before quoting.
- Oracle's 2/12 reduction was still inconsistently enforced as of July 2026.
- No credible measurement of fresh-IP survival time exists in any source. Do not invent one, and flag guides that do.
