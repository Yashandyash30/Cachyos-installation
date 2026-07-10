Here is your complete, updated master guide for setting up the Qylock SDDM Theme, custom-tailored for your Intel UHD 770 graphics and dual-monitor setup on CachyOS.

This integrates the Intel hardware decoding step and the X11 failsafe directly into the workflow so you can copy and paste your way to a flawless login screen.

---

# Qylock SDDM Theme — Intel & Dual-Monitor Setup Guide

### CachyOS · X11 Failsafe · Qt6

## Part 1 — Install Dependencies

### Step 1.1 — Core Packages

Qylock uses Qt6 and GStreamer to render its animations and video backgrounds.

```bash
sudo pacman -S \
    sddm \
    qt6-declarative qt6-5compat qt6-svg \
    qt6-multimedia qt6-multimedia-ffmpeg \
    gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    fzf

```

### Step 1.2 — Intel Hardware Video Decoding (Updated)

Since you are running an Intel i7-14700, you need the Intel media driver to allow your UHD 770 graphics to decode the theme's background video smoothly without stressing the CPU.

```bash
sudo pacman -S intel-media-driver

```

---

## Part 2 — The Dual-Monitor X11 Bypass (New)

Because you are running dual monitors (100Hz and 120Hz), SDDM natively running on Wayland will cause severe flickering. We need to force SDDM to use X11 just to draw this theme flawlessly, while still allowing Niri to run natively on Wayland once you log in.

Run these two commands to create the bypass:

```bash
sudo mkdir -p /etc/sddm.conf.d
echo -e "[General]\nDisplayServer=x11" | sudo tee /etc/sddm.conf.d/10-x11.conf

```

---

## Part 3 — Clone the Repository

Download the theme files directly from GitHub.

```bash
cd ~/Downloads
git clone https://github.com/Darkkal44/qylock.git
cd qylock

```

---

## Part 4 — Fonts (Optional)

Qylock does not include themed fonts (like the Minecraft or Genshin Impact fonts) due to copyright restrictions.

* **If you don't care:** Skip this step — the theme falls back to your system font automatically (likely your JetBrainsMono Nerd Font).
* **If you want the exact font:** Download the `.ttf` or `.otf` file, then install it so SDDM can see it before login:
```bash
sudo cp /path/to/your/font.ttf /usr/share/fonts/
sudo fc-cache -fv

```



---

## Part 5 — Install the Theme

The repository includes an interactive installation script.

### First-time install

Make the script executable and run it:

```bash
chmod +x sddm.sh && ./sddm.sh

```

Follow the interactive prompt to select your theme (e.g. `forest`, `nier`, `last-of-us`).

### Changing themes in the future

```bash
cd ~/Downloads/qylock
./sddm.sh

```

---

## Part 6 — Always Test Before Rebooting

**Never reboot without testing the theme first.** A broken theme produces a black screen at boot.

Run the Qt6 test command, replacing `forest` with the exact name of the theme you chose in Step 5:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/forest

```

### What to look for

* ✅ **A window appears, video plays, password box is clickable:** Safe to reboot!
* ❌ **Black window or instant crash:** Do not reboot. See Part 7.

> *Note: Ignore terminal warnings about "Socket errors" or "CUDA" during the test — test mode intentionally blocks actual password verification.*

---

## Part 7 — Emergency Recovery (Just in Case)

If you ever reboot and get a frozen black screen, the theme failed to render. Your machine is fine; it just needs a fallback.

1. **Drop to a TTY:** Press **`Ctrl` + `Alt` + `F3**`.
2. **Log in:** Enter your username and password.
3. **Disable the broken theme:**
```bash
sudo nano /etc/sddm.conf.d/theme.conf

```


Change the `Current=` line to the default fallback:
```ini
[Theme]
Current=breeze

```


*(Save and exit using `Ctrl+O`, `Enter`, `Ctrl+X`)*
4. **Reboot:**
```bash
sudo reboot

```
