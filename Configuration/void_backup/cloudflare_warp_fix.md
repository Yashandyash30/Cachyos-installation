# Cloudflare WARP (`warp-cli`) Disconnection & DNS Troubleshooting Guide

## Overview

On the laptop (`void`), attempting to connect Cloudflare WARP (`warp-cli connect`) caused complete loss of internet connectivity, whereas WARP connected without any issues on the desktop PC (`void-pc`).

This document details the comparative diagnostic process between `void` and `void-pc`, the root causes identified, and the exact steps to resolve the issue.

---

## Root Cause Analysis

By comparing system network configurations and WARP settings across both machines, two main discrepancies were found on the laptop (`void`):

### 1. DNS Management Conflict (`NetworkManager` vs `systemd-resolved`)
* **Working Setup (`void-pc`):**
  * `/etc/resolv.conf` was a symlink pointing to `/run/systemd/resolve/stub-resolv.conf`.
  * NetworkManager was configured with `dns=systemd-resolved` (`/etc/NetworkManager/conf.d/dns.conf`).
  * `resolvectl status` was in `stub` mode.
  * When `warp-svc` launched, it dynamically registered DNS proxies (`127.0.2.2` / `127.0.2.3`) with `systemd-resolved` over D-Bus without breaking glibc name resolution.
* **Failing Setup (`void`):**
  * `/etc/resolv.conf` was a regular static file generated directly by NetworkManager.
  * NetworkManager lacked the `dns=systemd-resolved` directive.
  * `resolvectl status` showed `resolv.conf mode: foreign`. `tailscale status` reported: `systemd-resolved and NetworkManager are wired together incorrectly`.
  * When WARP turned on, `warp-svc` updated `systemd-resolved`, but standard applications reading `/etc/resolv.conf` bypassed or conflicted with `systemd-resolved`, causing immediate failure for all DNS queries (e.g. `google.com`).

### 2. Missing Local Subnet Exclusion (`172.21.0.0/22`)
* **Working Setup (`void-pc`):**
  * `172.21.0.0/22 (CLI exclude)` was present under `warp-cli settings`.
* **Failing Setup (`void`):**
  * The local network subnet `172.21.0.0/22` (laptop IP: `172.21.0.115`, gateway: `172.21.0.1`) was **not** in WARP's split-tunnel exclude list.
  * When WARP activated, it captured traffic meant for the local router gateway (`172.21.0.1`), dropping all local gateway packets and severing network access.

---

## Technical Comparison Matrix

| Configuration Property | Laptop (`void`) - Initial State | PC (`void-pc`) - Working State | Status |
| :--- | :--- | :--- | :--- |
| **`/etc/resolv.conf`** | Regular File (`-rw-r--r--`) | Symlink to `/run/systemd/resolve/stub-resolv.conf` | ❌ Broken on Laptop |
| **NetworkManager Config** | Missing `dns=systemd-resolved` | Has `/etc/NetworkManager/conf.d/dns.conf` | ❌ Broken on Laptop |
| **`resolvectl` Mode** | `foreign` | `stub` | ❌ Broken on Laptop |
| **Local Subnet Route Exclusion** | None | `172.21.0.0/22 (CLI exclude)` | ❌ Missing on Laptop |

---

## Resolution Steps

### Step 1: Add Local Subnet to WARP Split-Tunnel Exclude List

*(Already applied on laptop)*

In newer `warp-cli` releases (v2024+), the syntax to exclude IP ranges is `warp-cli tunnel ip add-range`:

```bash
warp-cli tunnel ip add-range 172.21.0.0/22
```

*Verification:* Check `warp-cli settings` output to confirm `172.21.0.0/22 (CLI exclude)` is listed under *Exclude mode*.

### Step 2: Configure NetworkManager to Use `systemd-resolved`

Create `/etc/NetworkManager/conf.d/dns.conf`:

```bash
sudo mkdir -p /etc/NetworkManager/conf.d/
echo -e "[main]\ndns=systemd-resolved" | sudo tee /etc/NetworkManager/conf.d/dns.conf
```

### Step 3: Symlink `/etc/resolv.conf` to `systemd-resolved` Stub Resolver

```bash
sudo systemctl enable --now systemd-resolved
sudo rm -f /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

### Step 4: Restart Network Services

```bash
sudo systemctl restart NetworkManager systemd-resolved
```

---

## Post-Fix Verification

Run the following commands to confirm configuration matches the working environment:

1. **Verify DNS Symlink & Mode:**
   ```bash
   ls -l /etc/resolv.conf
   # Expected output: /etc/resolv.conf -> /run/systemd/resolve/stub-resolv.conf

   resolvectl status
   # Expected output: resolv.conf mode: stub
   ```

2. **Verify Tailscale Health Check:**
   ```bash
   tailscale status
   # Health check warning regarding NetworkManager/resolved should be cleared.
   ```

3. **Connect WARP:**
   ```bash
   warp-cli connect
   warp-cli status
   # Connected and healthy.
   ```
