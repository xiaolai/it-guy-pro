# Connecting Machines to Each Other

Verified against macOS on 29 July 2026. Everything here is between machines the user owns or administers, on their own network — the boundaries in `SKILL.md` apply.

## Ask what they actually want first

Users describe the mechanism and mean the goal. Route by goal, because the right answer is often not the one they asked for:

| They say | They usually mean | Right answer |
|---|---|---|
| "Connect my two computers" | Move files from the old one to the new one, once | **Migration Assistant** or AirDrop — not file sharing |
| "Share a folder" | Ongoing access to the same files from both | File Sharing, or a NAS |
| "See my other computer's screen" | Help someone, or use a headless machine | Screen Sharing |
| "Get to my files when away" | Remote access | Usually iCloud/Dropbox, not a port forward — see the caution below |
| "Everyone can print" | Printer shared | Almost always already works via Bonjour |

**One-off transfers should never become permanent shares.** A share configured for a single migration is still open years later, and nobody remembers it exists.

## Names beat addresses

Every Mac answers on `«computer-name».local` via Bonjour, so no fixed addresses and no router configuration are needed on a home LAN.

```bash
scutil --get LocalHostName        # this Mac's .local name
ping -c 2 othermac.local          # check the other machine answers
```

Teach the `.local` name, not the IP address. Home addresses come from DHCP and change; the name does not, and it survives a router replacement. If a device genuinely needs a stable address — a NAS or a printer that predates Bonjour — set a **DHCP reservation on the router** rather than a static address on the device, so the router keeps track and nothing collides. Note the modern gotcha: reservations key on MAC address, and private/randomized Wi-Fi addresses will break them (see `diagnostics.md`).

## File sharing

Turn on: **System Settings → General → Sharing → File Sharing**, then use the ⓘ button to choose which folders and who may reach them.

Connect from the other Mac: **Finder → Go → Connect to Server** (⌘K), then `smb://othermac.local`. It appears in the Finder sidebar under Network afterwards.

Three things to get right:

- **Share a specific folder, never the whole home directory.** The default invites accidents and exposes far more than intended.
- **Use a real account with a password**; do not enable guest access on a network with IoT devices or visitors.
- **SMB is the correct protocol** for Mac-to-Mac and Mac-to-Windows alike. AFP is deprecated and should not be used for new setups.

## Screen sharing

**System Settings → General → Sharing → Screen Sharing**, restricted to specific users rather than all users. Connect via Finder ⌘K with `vnc://othermac.local`, or just click the machine in the Finder sidebar and choose Share Screen.

For a household member's machine, agree on consent explicitly: screen sharing that someone does not know is running is surveillance, whoever owns the hardware. Say this out loud when setting it up on a family device.

## Remote login (SSH)

**System Settings → General → Sharing → Remote Login**, limited to specific users. Prefer key-based login over passwords:

```bash
ssh-keygen -t ed25519            # on the client, if no key exists
ssh-copy-id user@othermac.local
```

Only worth enabling if the user actually needs a command line on that machine. An unused service is attack surface with no benefit.

## Printers

Modern printers advertise themselves; **System Settings → Printers & Scanners → Add** usually finds them with no configuration. If it does not:

```bash
dns-sd -B _ipp._tcp local.       # is the printer advertising at all?
```

- Advertising but not connecting → the Mac and printer are probably on **different bands or a guest network that blocks client-to-client traffic.** This is the most common cause and it looks like a driver problem.
- Not advertising → the printer is offline, on a different network, or old enough to need its address entered manually.
- **Prefer AirPrint over manufacturer drivers.** Vendor printer software is a common source of background processes and login items — the same ones the startup audit in `/it-guy-pro:checkup` will flag later.

## Wake-on-LAN

**System Settings → Energy Saver (or Battery → Options) → Wake for network access.** Reliable over Ethernet, unreliable over Wi-Fi and unavailable when a laptop's lid is shut on battery. Set expectations accordingly rather than debugging it for an hour.

## Moving to a new Mac

**Migration Assistant** (in Applications → Utilities), over Ethernet if possible — Thunderbolt or Ethernet is dramatically faster and more reliable than Wi-Fi for tens of gigabytes. Run it during setup of the new Mac for the cleanest result. This is the correct answer to "how do I connect my old laptop," and it is almost never file sharing.

## Reaching home from outside — the caution

When a user asks to reach their files from elsewhere, the reflex answer — forwarding a port to a Mac or NAS — exposes that machine to the entire internet, permanently, and is a frequent route to a compromised household device.

In order of preference: a cloud folder (iCloud Drive, Dropbox) for files; the NAS vendor's own relay service if there is a NAS; a VPN *into* the home network if the router offers a built-in server (WireGuard or IPsec, configured with keys rather than a shared password); and only then, with a clear explanation of the risk, a forwarded port. **Never forward SMB (445), RDP (3389), or a NAS admin interface.** If the user's goal is simply "my files everywhere," the cloud folder is the right answer and the port forward is not.

## Record it

In `~/ITGuy/machine.md`, note only what helps next visit: which machines share what, and which services are enabled on this Mac. No addresses, no MAC addresses, no share credentials — per the privacy rule in `SKILL.md`. Enabled sharing services belong on the profile's Watch List, because they should be reviewed and switched off when the reason for them ends.
