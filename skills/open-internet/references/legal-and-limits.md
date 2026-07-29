# Legal Reality and Hard Boundaries

Research current as of July 2026. Present the substance of this file to the user **before** they spend money, not after. A non-technical user cannot assess this risk on their own, and discovering it later feels like a betrayal.

## What the law actually says (mainland China)

| Fact | Detail |
|------|--------|
| Baseline rule | International connections must go through state-licensed gateways (1997 network regulations; reaffirmed by the 2017 MIIT notice). Unauthorized circumvention is an administrative violation. |
| Amended Cybersecurity Law | Took effect **1 January 2026** — the first major overhaul since 2017. |
| Official signaling | The Ministry of State Security issued a public warning in **November 2025** stating explicitly that using circumvention tools is illegal. |
| Documented individual penalties | Real cases: 500 CNY (Ankang, Shaanxi), 1,000 CNY (Guangdong, Lantern Pro), warnings without fine (Sichuan). 2026 reports describe home visits and fines in the 200–500 CNY range; one penalty document is dated 2 April 2026. The statutory ceiling commonly cited for individuals is 5,000 CNY. |
| Enforcement base rate | Higher than the anecdote count suggests. A Chinese law student's survey found roughly **60 comparable cases in Zhejiang province alone in 2020**, plus about 50 across other provinces in 2019–2020. This is a routine administrative penalty, not a freak event — but also not a dragnet. |
| The underlying rule | MIIT notice Xinguanhan [2017] No. 32 (January 2017): without MIIT approval, no entity may build or lease cross-border lines or VPNs; licensed carriers leasing international dedicated lines must keep centralized user files, and those lines are for the lessee's own internal use only. |
| Draft Cybercrime Law | Would fine 1–10× income earned from the conduct, up to 200,000 CNY, plus up to 15 days detention where circumstances are serious. Draft, not yet enacted as of July 2026 — say so; do not present it as current law. |
| Operating or selling access | A different category entirely: criminal liability. A Shanghai court handed a suspended prison sentence to a circumvention-software developer. 2026 documents show pressure aimed specifically at commercial resale operators (known locally as "airports") and their upstream providers. |

**The load-bearing distinction: personal use is an administrative risk measured in hundreds of yuan; selling or sharing access to others is a criminal risk measured in years.** These are not points on one scale — they are different legal categories.

Direction of travel in 2026 is tightening, not loosening. Do not tell a user this is "not really enforced."

## Hard boundaries — what this skill will not do

1. **No resale, no sharing beyond the household.** Build for one person or one family, on their own server. If a user asks to sell access, run a commercial resale service (an "airport"), resell bandwidth, or onboard paying subscribers — decline and explain that this is the line where liability turns criminal. This is a refusal, not a negotiation.
2. **No scale.** No multi-user provisioning systems, no subscription/billing panels, no reseller node management (XrayR-style multi-node backends), no user-account management for third parties.
3. **No advice on evading investigation.** Setting up a private encrypted tunnel is the task; coaching someone on what to tell police, how to hide evidence, or how to defeat a forensic device search is not.
4. **Nothing illegal through the tunnel.** A tunnel is a network path. Fraud, harassment, piracy, and intrusion are exactly as illegal over it as without it.
5. **Where the user is matters.** These rules are about mainland China. If the user is somewhere with different law (or an employer/school network with its own policy), say what actually applies rather than reciting China rules.

## Other honest caveats to state up front

- **Anthropic does not serve mainland China, Hong Kong, or Macau.** They are absent from the Supported Regions list for both Claude.ai and the API. A tunnel makes Claude Code *reachable*, but it does not make the account *permitted* — account termination is a real, user-borne risk. Say this plainly to anyone whose stated goal is "use Claude Code from China." The same pattern applies to any service that geo-restricts by its own policy rather than by censorship — OpenAI, most streaming catalogues, and many banking and brokerage platforms. Censorship and terms-of-service restriction are different problems, and a tunnel only solves the first.
- **The VPS provider's terms.** Nearly all mainstream providers tolerate a personal proxy — Akamai/Linode's policy does not mention VPNs or proxies at all, and Vultr markets self-operated VPNs — while banning *open* proxies and Tor exit nodes, which a single-user authenticated setup is not. What actually gets accounts closed is signup fraud screening and missed abuse-report deadlines, not proxy use; those two get routinely misreported as "banned for VPN." Alibaba Cloud is the one provider with proxy-targeted enforcement reports.
- **Payment leaves a record.** VPS and domain purchases are tied to a card and an email. This is not an anonymity system, and should never be described as one.
- **Nothing here is a guarantee.** Servers get blocked; blocking intensifies during politically sensitive periods (Party plenums, June anniversaries, major congresses). Set the expectation of occasional maintenance before setup, not during an outage.
- **This is not legal advice.** State the facts and their sources; do not predict what will happen to a specific person. If a user raises the argument that the 1997 Implementing Measures define a "channel" as a *physical* channel and therefore arguably do not reach software tunnels — that argument does exist and appears never to have been litigated. Note it as an untested reading, never as a defence anyone should rely on.
- **One myth to correct rather than repeat:** vendor material claiming that regulation "permits MPLS/SD-WAN but specifically prohibits IPsec" cites no regulation. The rules restrict *unapproved cross-border channels* generally; IPsec is simply the most common do-it-yourself instance.
- **Legitimate channels exist, per organisation.** A registered foreign-trade company with complete credentials can apply through a carrier for an approved cross-border line. It is granted to the *organisation*, never to a protocol, and it costs enterprise money (roughly CNY 80–300 per Mbps per month depending on line type). If the user is actually a business, this is the lawful path and worth naming instead of pretending it doesn't exist. Conversely, using an ordinary enterprise broadband line as a shared circumvention egress is reported to draw police attention.

## How to present this to the user

One short section, plain language, before any money is spent. Do not moralize, do not lecture, and do not bury it in a wall of text. Something close to:

> Before we start, three things you should know. First, in mainland China this is against the rules for individuals — documented fines run a few hundred to a few thousand yuan, and enforcement has picked up in 2026. Setting one up for yourself is a fine-level matter; selling access to other people is a criminal-level matter, and I won't help with that. Second, services that restrict by their own policy rather than by censorship — Claude among them — don't officially serve mainland China at all, so an account can be closed even when the connection works. Third, this needs occasional upkeep: servers do get blocked, and you'll need to move to a new address when that happens. Still want to go ahead?

Then accept their answer and move on. Asked and answered once, not repeated at every step.
