# Building the Server

Written July 2026 for Xray-core on Debian 12 / Ubuntu 24.04. **Verify the install command and current release against `github.com/XTLS/Xray-install` before running it** — never reproduce an install URL from memory into a root shell.

## Rules that override convenience

1. **The it-guy-pro guard protects the user's Mac, not this server.** Nothing blocks a destructive command on the far end. Read every remote command before running it, and never run a destructive one against a server that currently works.
2. **Show, then run.** One plain sentence per command before it executes. The user is watching their money get spent; let them see what it buys.
3. **Never paste an unread script into a root shell.** Fetch it, show where it came from, then run the file you fetched. The guard will force a confirmation on `curl | bash` and `bash <(curl …)` — that prompt is correct; do not work around it.
4. **No panels.** 3x-ui and similar web panels are popular and wrong for a single user: they add an internet-facing admin surface with its own vulnerability history, and an exposed panel port is itself a signal. One config file is less to defend.
5. **Nothing secret goes in `~/ITGuy/machine.md`** — no password, no private key, no UUID, no share link.

## Step 1 — First contact and hardening

```bash
ssh root@SERVER_IP                      # provider gives root; this is normal for a fresh VPS
apt-get update && apt-get -y upgrade
apt-get -y install curl ca-certificates
timedatectl set-timezone UTC            # REALITY tolerates clock drift; VMess breaks outside ±90s
```

Set up key-based login and turn off password authentication — a fresh VPS with a password on port 22 is found by scanners within minutes:

```bash
# On the Mac (only if the user has no key yet):
ssh-keygen -t ed25519 -C "itguy-vps"
ssh-copy-id root@SERVER_IP
# Then on the server, after confirming key login works in a SECOND terminal:
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh
```

Verify key login in a separate session **before** closing the working one. Locking yourself out of a fresh box is recoverable through the provider console, but it frightens a non-technical user badly.

Enable BBR congestion control — a genuine throughput win on a lossy long-haul path, and one line:

```bash
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p && sysctl net.ipv4.tcp_congestion_control   # expect: bbr
```

## Step 2 — Install Xray

Fetch the official installer, show its source, then run it:

```bash
curl -fsSL https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh -o /tmp/xray-install.sh
head -40 /tmp/xray-install.sh          # show the user what it is
bash /tmp/xray-install.sh
xray version
```

## Step 3 — Generate the credentials

```bash
xray uuid                               # client id
xray x25519                             # prints PrivateKey (server) and Password/PublicKey (client)
openssl rand -hex 8                     # shortId
```

Keep the private key on the server only. The client needs the **public** key, the UUID, and the shortId.

## Step 4 — Choose the borrowed site (the one judgement call)

REALITY impersonates a real site's TLS handshake. The `dest` must:

- support **TLS 1.3, HTTP/2, and X25519** (verify, don't assume);
- **not be blocked in China** — if the borrowed site is blocked, so is the connection;
- **not be Chinese-hosted**, and not be your own domain;
- be plausibly reachable from your server's location — a Tokyo box borrowing a Japanese or global CDN-backed site looks natural;
- **not be the most over-used default.** Everyone borrowing the same handful of hostnames is itself a weak signal.

Reasonable choices for a Japan-hosted box: `www.apple.com`, `swdist.apple.com`, `dl.google.com`, `addons.mozilla.org`, `www.lovelive-anime.jp`. Verify the chosen one before committing:

```bash
curl -sI --tlsv1.3 --http2 https://www.apple.com | head -3
```

## Step 5 — Write the config

`/usr/local/etc/xray/config.json` — substitute the four generated values and the chosen `dest`:

```json
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{ "id": "YOUR_UUID", "flow": "xtls-rprx-vision" }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": false,
        "dest": "www.apple.com:443",
        "xver": 0,
        "serverNames": ["www.apple.com"],
        "privateKey": "YOUR_PRIVATE_KEY",
        "shortIds": ["YOUR_SHORT_ID"]
      }
    },
    "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic"] }
  }],
  "outbounds": [{ "protocol": "freedom", "tag": "direct" }]
}
```

```bash
xray -test -config /usr/local/etc/xray/config.json     # must pass before restarting
systemctl restart xray && systemctl enable xray
systemctl status xray --no-pager
ss -tlnp | grep 443
```

## Step 6 — Firewall

Keep it minimal: SSH and 443 only. If the provider offers a cloud firewall (Vultr does), prefer it — a locked-out user can fix a cloud firewall from the web console, but not a broken `ufw`.

```bash
ufw allow 22/tcp && ufw allow 443/tcp && ufw --force enable
```

## Step 7 — The share link

```
vless://UUID@SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.apple.com&fp=chrome&pbk=PUBLIC_KEY&sid=SHORT_ID&type=tcp#MyServer
```

`fp=chrome` sets the client's uTLS fingerprint to match a real Chrome — not cosmetic, it is part of what makes the handshake unremarkable. Hand this to the user through a channel they control, explain that it *is* the credential, and record it nowhere in `~/ITGuy/`.

## Step 8 — Verify from the server side

```bash
journalctl -u xray -n 30 --no-pager      # no repeated errors
curl -sI https://www.apple.com | head -1  # server has working egress
```

Real verification happens from the client (see `client-setup.md`): a blocked site loads, the visible IP is the server's, and the speed is measured rather than assumed.

## The CDN-fronted alternative

Use when the decision rule in `SKILL.md` points there — an already-characterized IP, an existing Cloudflare deployment, or a user who values never-fully-blocked over fast.

Shape: **VLESS + httpupgrade (or WebSocket) + TLS**, origin behind Cloudflare, with a domain pointed at the server and proxying enabled. `httpupgrade` is lighter than WebSocket and CDN-compatible. This path additionally needs a domain, DNS records, a certificate on the origin, and a path secret — four more things to renew or break. Do not present it as equivalent work.

Three cautions. Cloudflare's free-tier terms restrict proxying non-web traffic, so a personal tunnel is a grey area rather than a blessed use. The failure mode is **hostname blocking**, so tell the user in advance that the fix is a new subdomain — cheap and fast. And do not oversell the inspection resistance: nested-TLS-handshake detection is measured at roughly 0.70 true-positive rate against this exact shape (shadowsocks over WebSocket over TLS, Xue et al., USENIX Security 2024) at a 0.05% false-positive rate. There is no evidence the GFW runs it, and the CDN's IP is still not blockable — but "inside TLS" is not the same as "invisible," and Vision on the direct path exists specifically to close that gap.

If both stacks run, give each a distinct name in the client and let health checks choose. Never point both at the same IP — the whole reason for the second path is that the first one's address may be gone.

## Ongoing

- `apt-get update && apt-get -y upgrade` monthly; Xray updates by re-running the installer.
- Watch the renewal date. A lapsed VPS is a lost IP and a rebuild from scratch.
- No swap file needed at 1 GB for a single user, but adding 512 MB costs nothing and prevents OOM during upgrades.
