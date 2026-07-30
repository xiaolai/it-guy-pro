# Connecting the Mac

Written July 2026. Client apps in this space change fast and are abandoned quietly rather than announced — **check the project's releases page and install nothing whose newest release is more than six months old.**

## Choosing the app

The user is non-technical. The right app is the one whose main window has an on/off switch, not the one with the best feature matrix.

| App | Use it when | Notes |
|---|---|---|
| **Clash Verge Rev** | **Default for macOS.** Actively maintained, mihomo core, real GUI, system-proxy toggle, health checks and automatic failover between multiple servers | The failover capability is why it is the default — it is what makes a two-path setup work without the user understanding it |
| **sing-box (SFM)** | The user wants an App Store install and minimal surface | Official, sparse UI; config-file oriented, less forgiving for a beginner |
| **Hiddify** | Cross-platform household — same app on Mac, Windows, Android | Easy share-link import |
| **Karing** | Alternative to Hiddify with the same profile | — |
| **V2rayU** | **Do not install.** Long unmaintained | Still the top search result in Chinese guides; say so, because the user will find it |

On iPhone: Shadowrocket (paid, requires a non-China Apple ID) or Karing. The Apple ID requirement is a real obstacle — check whether the user has one before promising a phone setup.

## Install and import

```bash
brew install --cask clash-verge-rev     # verify the cask name is current before running
```

If Homebrew is not installed, do **not** install it just for this — download the `.dmg` from the project's GitHub releases page instead. Adding a package manager to a non-technical user's Mac is a bigger commitment than the task warrants, and it becomes something else to maintain.

Import the connection: **Profiles → New → paste the `vless://` share link → Save.** Then set the mode:

- **Rule mode** — the correct default. Chinese sites go direct, foreign sites go through the server. Faster, cheaper on bandwidth, and it keeps domestic banking and payment apps working, which matters more to a normal user than it sounds.
- **Global mode** — everything through the server. Use only when diagnosing.
- **Direct mode** — off.

Turn on **System Proxy** so ordinary apps use it without configuration. Note the gap plainly: system proxy covers browsers and any app that uses the system's networking. It does not cover tools that read the `HTTP_PROXY` and `HTTPS_PROXY` environment variables instead — `npm`, `pip`, and Docker among them — nor apps that ship their own network stack. The test is simple: if System Proxy is on and one specific app still cannot reach anything, that app is in this category. TUN mode captures them and is the fix; it needs an admin approval prompt on first use.

## Verify — actually test, never assume

Run all four with the user watching, and report real numbers:

1. **Exit IP is the server's:** `curl -s --proxy http://127.0.0.1:7897 https://api.ipify.org` (confirm Clash Verge's actual mixed-port in Settings; 7897 is the common default).
2. **A blocked site loads** — open one in the browser, not just curl.
3. **Speed is measured**, not guessed. Run a real speed test and record the number so a future slowdown has a baseline to compare against.
4. **The service the user actually named works.** If they said "I need Claude Code," open Claude Code. A generic green checkmark is not verification.

If the user's goal involves a service that geo-restricts by policy rather than censorship — Claude among them, since Anthropic does not serve mainland China, Hong Kong, or Macau — restate that caveat here, once, at the moment it becomes concrete.

## Handing over

Show the user three things and confirm they can do the first two themselves:

1. **On and off** — where the switch is, and that turning it off is safe and occasionally necessary: domestic banking apps, Alipay and WeChat Pay, and real-name verification flows can refuse to run when the traffic appears to come from abroad.
2. **What a blocked server feels like** — everything foreign stops, everything domestic still works. That specific pattern means the server IP, not their Wi-Fi. The fix is `/mac-it-guy-pro:open-internet fix`.
3. **The renewal date**, and that a lapsed VPS means losing the IP and rebuilding.

Record in `~/ITGuy/machine.md`: that a private connection exists, the provider, the region, the renewal date, and the client app. **Never** the share link, UUID, keys, or passwords.

## Adding household devices

Same share link, same server, one profile per device. Household only — the boundary in `legal-and-limits.md` is not a formality: sharing beyond the household is where the legal exposure changes category.

For a second Mac, repeat this file. For phones, Karing or Hiddify on both platforms keeps one set of instructions for the whole family, which is worth more than any per-app advantage.
