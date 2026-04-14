# Walker App Launcher — Setup Guide
### Niri · CachyOS · Wayland

Walker is a fast application launcher for Wayland. It has two parts that must both be running for it to work:

- **Elephant** — the background data engine that indexes files, apps, and calculations
- **Walker** — the visual frontend (UI) that appears when you press your hotkey

Elephant must always start **before** Walker.

---

## Part 1 — Install

### Step 1.1 — Walker and Elephant

```bash
# Walker UI
paru -S walker

# Elephant backend (-bin avoids compiling Go from source)
paru -S elephant-all-bin
```

### Step 1.2 — Thumbnail generators (optional)

Enables image, PDF, and video previews in file search results:

```bash
sudo pacman -S tumbler poppler-glib ffmpegthumbnailer
```

---

## Part 2 — Choose a Launch Method

There are two ways to start Elephant at login. **Use only one** — running both simultaneously causes two separate Elephant instances to compete for the same system bus, wastes RAM, and triggers the resource drain described in Part 6.

| | Systemd Service | Niri Autostart |
|---|---|---|
| Auto-restarts if it crashes | ✅ Yes | ❌ No |
| Starts before Niri is fully ready | ✅ Yes | ❌ No — races with session startup |
| Resource usage | Lower (managed process) | Higher (risks double-launch) |
| Easy to check status/logs | ✅ `systemctl --user status elephant` | ❌ No visibility |
| **Recommended** | ✅ **Yes** | Only if you don't use systemd |

**The systemd service is the better choice.** It uses less resources, is more stable, and gives you proper crash recovery. The steps below follow that method.

---

## Part 3 — Set Up Elephant as a Systemd Service

### Step 3.1 — Create the service file

```bash
mkdir -p ~/.config/systemd/user/
nano ~/.config/systemd/user/elephant.service
```

Paste the following:

```ini
[Unit]
Description=Elephant Data Engine for Walker
After=graphical-session.target

[Service]
ExecStart=/usr/bin/elephant
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
```

Save and exit (**Ctrl+O → Enter**, then **Ctrl+X**).

### Step 3.2 — Enable and start the service

```bash
systemctl --user daemon-reload
systemctl --user enable --now elephant.service
```

### Step 3.3 — Verify it's running

```bash
systemctl --user status elephant.service
```

You should see `Active: active (running)`. If it shows failed, check Part 7 for troubleshooting.

---

## Part 4 — Configure Niri

### Step 4.1 — Autostart Walker only (not Elephant)

Since Elephant is now managed by systemd, only Walker needs to be in your Niri autostart. Open your autostart config:

```bash
nano ~/.config/niri/config.kdl
```

Add this line:

```code snippet
spawn-at-startup "walker" "--gapplication-service"
#Optional
exec-once = kbuildsycoca6 --noincremental
```

> `kbuildsycoca6" "--noincremental` This runs kbuildsycoca6, a KDE Plasma 6 utility that rebuilds your system's desktop application cache. Running this at startup is a genuinely great idea because it ensures Walker (via the Elephant backend) can immediately see and launch all of your installed apps.

> Also, do not add `spawn-at-startup "elephant"` here. Elephant is already handled by systemd, and adding it to Niri will cause a double-launch that drains system resources.

>```kdl
>spawn-at-startup "sh" "-c" "GSK_RENDERER=gl walker --gapplication-service"
>```

> **Note:** `GSK_RENDERER=gl` line is a specific fallback designed for Virtual Machines (which usually lack proper 3D/Vulkan hardware acceleration) or systems with broken graphics drivers. It forces the app to use older OpenGL rendering instead of modern Vulkan. This prevents crashes on systems where Vulkan isn't fully supported and has no performance downside on AMD.


### Step 4.2 — Add a keybind

Open your keybinds config:

```bash
nano ~/.config/niri/cfg/keybinds.kdl
```

Add this inside your binds block:

```kdl
// Walker App Launcher
Alt+Space hotkey-overlay-title="Open Walker Launcher" { spawn "walker"; }
```

---

## Part 5 — Fix the dnf Resource Drain

By default, Elephant tries to scan for installed apps using package managers from multiple Linux distributions — including `dnf` (Fedora's package manager). Since you're on CachyOS, `dnf` doesn't exist here, so Elephant gets stuck trying to run it, times out, and retries in a loop. This silently eats CPU in the background.

Find and open the Elephant package provider config:

```bash
# Check which location exists on your install
ls ~/.config/elephant/
ls ~/.config/walker/
```

Open the relevant config file (likely `packages.toml` or `providers.toml`) and ensure only Arch-based package managers are listed. Remove or comment out any references to `dnf`, `apt`, `rpm`, or `zypper`.

It should only contain entries for `pacman` (and optionally `paru`/`yay`).

After editing, restart Elephant:

```bash
systemctl --user restart elephant.service
```

---

## Part 6 — Customise Elephant Search Paths

By default Elephant scans your entire home directory, which is slow. Restrict it to only the folders you actually use:

```bash
mkdir -p ~/.config/elephant
nano ~/.config/elephant/files.toml
```

Paste and adjust to your workflow:

```toml
[files]
# Folders to search
paths = [
    "~/Documents",
    "~/Downloads",
    "~/Pictures",
    "~/Projects"
]

# Folders to skip entirely (big speed improvement)
ignored_paths = [
    "~/.cache",
    "~/.local",
    "~/.cargo",
    "~/Games"
]

# Hide dotfiles from results
show_hidden = false
```

Restart to apply:

```bash
systemctl --user restart elephant.service
```

---

## Part 7 — Troubleshooting

### Check for duplicate Elephant instances

If Walker feels sluggish or you suspect something is wrong, check how many Elephant processes are running:

```bash
pgrep -a elephant
```

More than one line means you have a double-launch. Fix it:

```bash
# Kill all instances
killall elephant

# Make sure Niri autostart doesn't also spawn elephant
nano ~/.config/niri/cfg/autostart.kdl
# Remove any line containing "elephant"

# Start a single clean instance via systemd
systemctl --user start elephant.service
```

---

### `Failed to detect any valid GPUs` or `VK_ERROR_INITIALIZATION_FAILED`

Vulkan isn't available or working. The `GSK_RENDERER=gl` flag in your autostart (Part 4) already handles this. If you see it anyway:

```bash
pkill -f walker
GSK_RENDERER=gl walker --gapplication-service &
```

---

### `Unable to acquire bus name 'dev.benz.walker'`

A stale Walker instance is holding the session bus. Kill it and restart:

```bash
pkill -f walker
GSK_RENDERER=gl walker --gapplication-service &
```

---

### UI shows "waiting for elephant"

Elephant isn't running. Check its status and start it:

```bash
systemctl --user status elephant.service
systemctl --user start elephant.service
```

If it refuses to start, check the logs:

```bash
journalctl --user -u elephant.service -n 50
```

---

### Files open in the browser instead of the correct app (MIME hijacking)

Fix by explicitly assigning the correct app to each file type:

```bash
# Folders → Dolphin (or replace with your file manager's .desktop name)
xdg-mime default org.kde.dolphin.desktop inode/directory
xdg-mime default org.kde.dolphin.desktop application/x-directory

# Images → your image viewer
xdg-mime default org.gnome.Loupe.desktop image/png
xdg-mime default org.gnome.Loupe.desktop image/jpeg
```

Verify a change took effect:

```bash
xdg-mime query default inode/directory
```
---

### Switch Autostart from Systemd to Niri (Fix Double-Launch)

If you previously set up Elephant to run as a background service using `systemd`, but now want Niri to handle the autostart, you must disable the systemd entry. Leaving both active will cause a double-launch, where two instances of Elephant run simultaneously and drain system resources.

**1. Disable the systemd service**
First, tell systemd to stop managing Elephant and disable it from launching on boot:

```bash
systemctl --user disable --now elephant

```

**2. Kill any duplicate processes**
Clear out any currently running instances of Elephant so you can start fresh:

```bash
killall elephant

```
## Quick Reference

```
Start Elephant (systemd)    systemctl --user start elephant.service
Stop Elephant               systemctl --user stop elephant.service
Restart Elephant            systemctl --user restart elephant.service
Check Elephant status       systemctl --user status elephant.service
systemd disable Elephant    systemctl --user disable --now elephant
View Elephant logs          journalctl --user -u elephant.service -n 50
Check for duplicates        pgrep -a elephant
Kill all Walker instances    pkill -f walker
Elephant search config      ~/.config/elephant/files.toml
Elephant service file        ~/.config/systemd/user/elephant.service
Niri autostart               ~/.config/niri/config.kdl
Niri keybinds                ~/.config/niri/cfg/keybinds.kdl
```
