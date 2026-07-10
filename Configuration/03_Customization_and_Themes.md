# 03 - Customization and Themes Guide

This document aggregates all guides related to visual customization, including hardware-accelerated video wallpapers, Dolphin file manager theming, and the Qylock SDDM login screen.

---

## 1. The Wayland Video Wallpaper Master Guide

### Phase 1: Core Installation
Install the base rendering engine (`mpvpaper`) and the standalone GUI manager (`waypaper`):
```bash
paru -S mpvpaper waypaper
```

### Phase 2: Verifying Hardware Acceleration (VAAPI)
Before plugging anything into a GUI, ensure your GPU can decode the video natively to save CPU usage. Run a test command against a standard `.mp4` file:
```bash
mpvpaper -o "--hwdec=vaapi" '*' /path/to/your/video.mp4
```
Look at the terminal output. If you see `VO: [libmpv] ... vaapi[nv12]` and your CPU usage stays low, hardware acceleration is working. Press `Ctrl+C` to close it.

### Phase 3: Configuring Standalone Waypaper
Tell Waypaper to inject your hardware decoding flags:
1. Open the config: `nano ~/.config/waypaper/config.ini`
2. Add or modify the `mpvpaper_options` line:
```ini
mpvpaper_options = -o "hwdec=vaapi loop-file=inf no-audio"
```

### Phase 4: Configuring the Dank Material Shell Plugin
If you are using the Dank Shell Wayland environment:
1. Open **Dank Shell Settings** -> **Video Wallpaper Plugin** -> **Advanced**.
2. In the **Custom mpv Options** box, type exactly: `--hwdec=vaapi`
3. Click **Apply**.

### Phase 5: Crucial Rules
- **Strictly Use .mp4 Files:** Do not use `.webp` or `.gif` files; they crash the engine or bypass hardware acceleration.
- **The "Ghost" Fix:** If wallpapers stop loading or you get an "Already running" error, kill it with: `killall -9 mpvpaper`

---

## 2. Qylock SDDM Theme (Intel & Dual-Monitor)

### Phase 1: Dependencies (Automated)
> [!NOTE]
> `03-software-install.sh` automatically installs the required SDDM, Qt6, GStreamer, and `intel-media-driver` (or AMD equivalent) packages based on your hardware. It also automatically swaps `plasmalogin.service` to classic `sddm.service`!

### Phase 2: The Dual-Monitor X11 Bypass
Because you are running dual monitors with mismatched refresh rates (100Hz and 120Hz), SDDM natively running on Wayland causes severe flickering. We force SDDM to use X11 just to draw this theme safely.
```bash
sudo mkdir -p /etc/sddm.conf.d
echo -e "[General]\nDisplayServer=x11" | sudo tee /etc/sddm.conf.d/10-x11.conf
```

### Phase 3: Install the Theme
Clone the repo and run the interactive script to select a theme (e.g. `forest`, `nier`):
```bash
cd ~/Downloads
git clone https://github.com/Darkkal44/qylock.git
cd qylock
chmod +x sddm.sh && ./sddm.sh
```

### Phase 4: Test Before Rebooting
**Never reboot without testing the theme first.** A broken theme produces a black screen at boot. Replace `forest` with your chosen theme:
```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/forest
```
* ✅ **A window appears, video plays:** Safe to reboot!
* ❌ **Black window or instant crash:** Do not reboot. Drop to TTY (`Ctrl+Alt+F3`) and change `/etc/sddm.conf.d/theme.conf` back to `Current=breeze`.

### Phase 5: Fish Shortcuts
Add these to `~/.config/fish/config.fish` to easily manage themes:
```fish
# Qylock SDDM Theme Management
abbr -a theme "cd ~/Downloads/qylock && ./sddm.sh"
abbr -a theme-test "sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/"
```

---

## 3. Fixing Dolphin & File Dialogs on Niri

> [!NOTE]
> `02-app-config.sh` automatically installs all Qt/GTK theming dependencies (`qt5ct`, `kvantum`, `qt6ct-kde`, `xdg-desktop-portal-gtk`), forces GTK apps to dark mode, sets Dolphin as the default file manager, and generates the `qt.conf` environment file.

### Step 1: Niri config (`~/.config/niri/config.kdl`)
Ensure your Niri config has this `environment` block to route styling and file managers correctly:
```kdl
environment {
  XDG_CURRENT_DESKTOP "niri"
  XDG_MENU_PREFIX "plasma-"
  QT_QPA_PLATFORMTHEME "qt6ct"
  FILEMANAGER "dolphin"
}
```

### Step 2: Apply Themes via Dank Material Shell
Generate the actual color schemes from within DMS:
1. Open **Dank Shell Settings**
2. Go to **Theme & Colors** -> **System App Theming**
3. Click **Apply GTK Colors** (fixes browser dialogs)
4. Click **Apply Qt Colors** (fixes Dolphin)

### Step 3: Fix the "Open With" Menu
Dolphin relies on a background cache. Add this to the startup section of your `~/.config/niri/config.kdl`:
```kdl
spawn-at-startup "kded6"
```
*(This watches for new apps in real time so the "Open With" menu updates instantly after installing an app).*
