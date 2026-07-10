# 04 - System and Hardware Configuration Guide

This document aggregates guides related to system tuning, hardware quirks, and application setups like Walker, Fastfetch, btop, and LaTeX.

---

## 1. Linux Wake & Lid Fix Guide

> [!NOTE]
> **Automated Setup Completed:** `01-system-config.sh` handles installing `tlp`, ignoring the physical lid switch via `logind.conf`, and configuring the USB wake service.

### Phase 1: Laptop Lid Issue (Clamshell Mode)
1. **Systemd:** We tell systemd to ignore the physical lid switch by editing `/etc/systemd/logind.conf` and setting `HandleLidSwitch=ignore`.
2. **TLP:** We replaced `power-profiles-daemon` with `tlp` to prevent the Wi-Fi card from powering off on lid close. Switch profiles manually: `sudo tlp bat` (power-saver) and `sudo tlp ac` (performance).
3. **Niri:** We tell Niri to ignore the closed screen by adding `output "eDP-1" { off }` in `~/.config/niri/config.kdl`.

### Phase 2: Wake by USB (KVM Setup)
* **BIOS:** Ensure **"USB Wake Support"** is enabled and **Fast Boot** is disabled.
* **Service:** A systemd service ensures `XHC0` is written to `/proc/acpi/wakeup` on boot.
* **Usage:** Always use `systemctl suspend`. Toggle the KVM to the laptop, tap the keyboard, and Niri will wake up.

### Phase 3: Wake on LAN/WLAN (Magic Packet)
* **Wired:** Install `ethtool`, bind magic packets using `sudo nmcli connection modify "Wired connection 1" 802-3-ethernet.wake-on-lan magic`.
* **Wireless:** Ensure WoWLAN is supported (`iw phy0 wowlan show`). Enable it via `sudo iw phy0 wowlan enable magic-packet` and bind it in NetworkManager.
* **Wake Command:** From another machine, run `wol <MAC_ADDRESS>`.

---

## 2. Walker App Launcher — Setup Guide (Niri Edition)

> [!NOTE]
> **Automated Setup Completed:** `03-software-install.sh` automatically installs `walker`, `elephant-all-bin`, and thumbnail generators, and deletes the faulty `dnfpackages.so` plugin.

Walker is a fast application launcher for Wayland. It consists of the **Elephant** backend (data indexing) and the **Walker** frontend (UI).

### Niri Autostart vs Systemd
Systemd struggles to inherit Wayland display variables (`WAYLAND_DISPLAY`), causing a race condition where launched apps crash invisibly. Using Niri's autostart natively passes all required display keys automatically, ensuring 100% stability.

Add these to your `~/.config/niri/config.kdl` instead of running systemd services:
```kdl
// 1. Rebuild the app cache (KDE utility)
spawn-at-startup "kbuildsycoca6" "--noincremental"
// 2. Start the search engine
spawn-at-startup "elephant"
// 3. Start the UI listener natively on Vulkan
spawn-at-startup "walker" "--gapplication-service"
```
Keybind: `Alt+Space hotkey-overlay-title="Open Walker Launcher" { spawn "walker"; }`

### Customise Elephant Search Paths
Restrict it to folders you actually use for speed (`~/.config/elephant/files.toml`):
```toml
[files]
paths = ["~/Documents", "~/Downloads", "~/Pictures", "~/Projects"]
ignored_paths = ["~/.cache", "~/.local", "~/.cargo", "~/Games"]
show_hidden = false
```
Restart Elephant: `killall elephant`

---

## 3. Fastfetch Configuration (Dual Layout)

> [!NOTE]
> **Automated Setup Completed:** Your dotfiles repo handles syncing the `.jsonc` configurations, and your fish config handles the alias.

* **Minimal Config (`config.jsonc`):** Runs automatically on shell open. Displays standard OS details.
* **Full Config (`full.jsonc`):** Triggered manually. Displays detailed package breakdowns (Explicit, AUR, Flatpak) and custom color blocks.
* **Fish Alias:** `alias fetchfull="fastfetch -c full"`

---

## 4. Fixing btop on CachyOS (Missing UTF-8 Locale)

`btop` refuses to run if `.UTF-8` is missing from locale variables.
To fix permanently:
1. Uncomment `en_IN.UTF-8 UTF-8` in `/etc/locale.gen`.
2. Compile it: `sudo locale-gen`.
3. Set all variables in `/etc/locale.conf` to `en_IN.UTF-8` (e.g., `LANG=en_IN.UTF-8`).
4. If on KDE Plasma, mirror this in `~/.config/plasma-localerc`.
5. Apply instantly: `export LANG=en_IN.UTF-8` then run `btop`. Otherwise, log out and back in.

---

## 5. Complete LaTeX Setup Guide (Antigravity IDE)

> [!NOTE]
> **Automated Setup Completed:** `03-software-install.sh` automatically prompts you to install `texlive-meta` and `biber`.

### IDE Configuration
1. **Extensions:** Install **LaTeX Workshop** (building and SyncTeX) and **LTeX+** (grammar/spell checker).
2. **Settings (`settings.json`):** Set auto-build on save (`"latex-workshop.latex.autoBuild.run": "onSave"`), enable word wrap, and configure `ltex.dictionary` for custom astrophysics jargon.
3. **Keybindings (`keybindings.json`):** Bind Forward SyncTeX (Code -> PDF) to `Ctrl + J`.

### Workflow
* **Build:** `Ctrl + S`.
* **Code to PDF:** Press `Ctrl + J`.
* **PDF to Code:** Double-click anywhere in the PDF preview.

---

## 6. Cloudflare WARP Client Setup

> [!NOTE]
> **Automated Setup Completed:** `03-software-install.sh` handles the installation of `cloudflare-warp-bin` from the AUR and enables `warp-svc.service`.

1. **Register Device:** `warp-cli registration new` (Accept ToS).
2. **Connect:** `warp-cli connect`.
3. **Verify:** `curl https://www.cloudflare.com/cdn-cgi/trace/` and look for `warp=on`.

---

## 7. GitHub CLI Authentication

If you are pushing dotfiles, GitHub CLI generates a one-time code and handles the OAuth browser login automatically:
```bash
sudo pacman -S github-cli
gh auth login
```
Choose "GitHub.com" -> "HTTPS" -> "Login with a web browser". Git will automatically use this authentication for `git push`.
