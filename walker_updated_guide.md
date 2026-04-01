# 🚀 The Ultimate Guide to Installing Walker on Niri (Arch Linux)

Walker is a blazing fast application launcher for Wayland. It consists of two parts:
1. **Walker**: The visual frontend (UI).
2. **Elephant**: The background data engine that handles searching files, finding apps, and doing calculations.

## 1. Installation

First, install Walker and the Elephant backend using your AUR helper (`paru` or `yay`). We will also install some thumbnail generation packages to make sure file previews look great.

```bash
# Install Walker UI
paru -S walker

# Install Elephant Backend (using the -bin version to avoid compiling Go code)
paru -S elephant-all-bin

# Install optional thumbnail generators for images & PDFs 
sudo pacman -S tumbler poppler-glib ffmpegthumbnailer
```

## 2. Setting Up Niri Autostart

Walker needs to run as a background service so that it pops up instantly when you press your hotkey. 

> [!NOTE] 
> Because of a known issue with virtual machines (like VMware) not supporting Vulkan properly, we are adding the `GSK_RENDERER=gl` flag to force Walker to use standard OpenGL instead of crashing.

Open your Niri autostart configuration file:
```bash
nano ~/.config/niri/cfg/autostart.kdl
```

Add these lines to start both the engine and the UI when you log in. **Note: Elephant must always start before Walker**:
```kdl
spawn-at-startup "elephant"
spawn-at-startup "sh" "-c" "GSK_RENDERER=gl walker --gapplication-service" 
```

## 3. Creating a Niri Keybind

To actually open Walker on your screen, you need to assign it a shortcut (e.g., `Alt + Space`).

Open your Niri keybinds config:
```bash
nano ~/.config/niri/cfg/keybinds.kdl
```

Add this line inside your binds block:
```kdl
// Walker App Launcher
Alt+Space hotkey-overlay-title="Open Walker Launcher" { spawn "walker"; }
```

You can now restart Niri or manually start the background services for this session to test it:
```bash
elephant &
GSK_RENDERER=gl walker --gapplication-service &
```

---

## 4. (Optional but Recommended) Setup Elephant as a Systemd Service

While relying on Niri's autostart works, setting Elephant up as a system service is much more robust because it will automatically restart if the background engine crashes.

**1. Create the systemd directory and service file:**
```bash
mkdir -p ~/.config/systemd/user/
nano ~/.config/systemd/user/elephant.service
```

**2. Paste in the following configuration:**
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

**3. Enable and start the service:**
```bash
systemctl --user daemon-reload
systemctl --user enable --now elephant.service
```
*(If you do this, you can safely remove the `spawn-at-startup "elephant"` line from your Niri autostart file).*

---

## 5. Customizing Elephant Search Paths

By default, Elephant scans your entire home directory. You can drastically speed up your search times by ignoring heavy hidden folders (like `.cache`) and only targeting your active workflow locations.

Create and open the configuration file:
```bash
mkdir -p ~/.config/elephant
nano ~/.config/elephant/files.toml
```

Paste your preferences:
```toml
[files]
# Directories you actively want Walker to search
paths = [
    "~/Documents",
    "~/Downloads",
    "~/Pictures",
    "~/Projects"
]

# Directories you want it to completely ignore (speeds up search!)
ignored_paths = [
    "~/.cache",
    "~/.local",
    "~/.cargo",
    "~/Games"
]

# Disable hidden files to make file searches lightning fast
show_hidden = false
```

Restart your service so it reads the new configuration:
```bash
systemctl --user restart elephant.service
```

---

## 🛠️ Common Troubleshooting

### Error: `Failed to detect any valid GPUs` or `VK_ERROR_INITIALIZATION_FAILED`
This means your graphics environment doesn't support the Vulkan renderer. Kill the background app and start it forcing OpenGL:
```bash
pkill -f walker
GSK_RENDERER=gl walker --gapplication-service &
```

### Error: `Unable to acquire bus name 'dev.benz.walker'`
This means you tried to start Walker, but another invisible instance is already running in the background and holding onto the system bus. Force quit the stuck process and start it again:
```bash
pkill -f walker
GSK_RENDERER=gl walker --gapplication-service &
```

### UI says "waiting for elephant"
Walker cannot find its backend engine. Kill any existing tasks and always **start Elephant first, then Walker**.
```bash
pkill -f walker
pkill -f elephant

elephant &
GSK_RENDERER=gl walker --gapplication-service &
```

### Files & Folders are Opening in the Web Browser (MIME Hijacking)
If you search for a folder and it opens in Firefox/Brave instead of your file manager, use the `xdg-mime` command to force the system to route those files to your actual apps. Examples below:

```bash
# Force folders to open in Nautilus (GNOME Files)
xdg-mime default org.gnome.Nautilus.desktop inode/directory
xdg-mime default org.gnome.Nautilus.desktop application/x-directory

# Force images to open in Loupe (Image Viewer)
xdg-mime default org.gnome.Loupe.desktop image/png
xdg-mime default org.gnome.Loupe.desktop image/jpeg
```
