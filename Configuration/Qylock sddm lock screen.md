# Qylock SDDM Theme — Setup & Management Guide
### CachyOS · Wayland · Qt6

---

## Part 1 — Install Dependencies

### Step 1.1 — Core packages

Qylock uses Qt6 and GStreamer to render its animations and video backgrounds. Missing any of these will cause an instant crash to a black screen on boot.

```bash
sudo pacman -S \
    sddm \
    qt6-declarative qt6-5compat qt6-svg \
    qt6-multimedia qt6-multimedia-ffmpeg \
    gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    fzf
```

### Step 1.2. — AMD or Intel hardware video decoding drivers

`libva-mesa-driver` and `mesa-vdpau` (AMD) and `intel-media-driver`(Intel) are usually pre-installed on CachyOS. Check first:

```bash
#AMD
pacman -Q libva-mesa-driver mesa-vdpau
```
```bash
#Intel
pacman -Q intel-media-driver
```
**If both lines print a version number** (e.g. `intel-media-driver` or `libva-mesa-driver 24.x.x`) — already installed, skip this step.

**If either line shows `error: package 'X' was not found`** — install the missing one(s):

```bash
#AMD
sudo pacman -S libva-mesa-driver mesa-vdpau
```

```bash
#Intel
sudo pacman -S intel-media-driver
```
> These drivers let your AMD Ryzen ot Intel chip decode the theme's background video using the GPU rather than the CPU.

---

## Part 2 — Clone the Repository

```bash
cd ~/Downloads
git clone https://github.com/Darkkal44/qylock.git
cd qylock
```
to clone in Home Folder

```bash
cd ~
git clone https://github.com/Darkkal44/qylock.git
cd qylock
```
---

## Part 3 — Fonts (Optional)

Qylock does not include themed fonts (like the Minecraft or Genshin Impact fonts) due to copyright restrictions.

**If you don't care:** skip this step — the theme falls back to your system font automatically.

**If you want the exact font:** download the `.ttf` or `.otf` file, then install it so SDDM can see it before login:

```bash
sudo cp /path/to/your/font.ttf /usr/share/fonts/
sudo fc-cache -fv
```

---

## Part 4 — Install the Theme

The repo includes an install script that copies the theme files and updates your SDDM config automatically. Don't copy files manually.

### First-time install

```bash
chmod +x sddm.sh && ./sddm.sh
```

Follow the interactive prompt to select your theme (e.g. `forest`, `nier`, `last-of-us`).

**What these two commands mean:**

`chmod +x sddm.sh` — When you clone a repo from GitHub, Linux locks script files by default so they can't execute. This unlocks it and marks it as a runnable program. **You only need to do this once.** The permission is stored permanently on the file.

`&&` — Means "wait for the first command to succeed, then run the next one."

`./sddm.sh` — Actually runs the script.

### Changing themes in the future

Because the file is already marked executable, you only need:

```bash
cd ~/Downloads/qylock
./sddm.sh
```

> **Exception:** If you ever delete the `qylock` folder and re-clone it from GitHub, you'll need to run `chmod +x sddm.sh` again — the fresh clone starts locked.

---

## Part 5 — Always Test Before Rebooting

**Never reboot without testing the theme first.** A broken theme produces a black screen at boot, which requires TTY recovery to fix (see Part 7).

Run the Qt6 test command, replacing `forest` with your chosen theme name:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/forest
```

### What to look for

| Result | Meaning |
|---|---|
| A window appears, video plays, password box is clickable | ✅ Safe to reboot |
| Black window or instant crash | ❌ Do not reboot — see Part 6 |

> **Ignore** terminal warnings about "Socket errors" or "CUDA" — test mode intentionally blocks password verification, and Qt6 often complains about NVIDIA libraries before falling back to your AMD GPU harmlessly.

---

## Part 6 - Add the Fish Abbreviations

Append your custom shortcuts to your Fish configuration file so they load automatically.

    Open your config file:
    Bash

    nano ~/.config/fish/config.fish

    Paste your abbreviations at the bottom of the file:
    Code snippet

    # Qylock SDDM Theme Management
    abbr -a theme "cd ~/Downloads/qylock && ./sddm.sh"
    abbr -a theme-test "sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/"

    Save and exit, then reload your Fish shell to apply the changes:
    Bash

    source ~/.config/fish/config.fish

4. Install and Test Themes

Now you can use your newly created abbreviations to manage your cozy login screens natively in your terminal.

    To install or configure a theme:
    Type theme in your terminal. This will automatically navigate to the Qylock folder and execute the installation script.

    To test a theme without logging out:
    Type theme-test [ThemeName] (e.g., theme-test qylock-cozy). The --test-mode flag will open a window on your current desktop displaying exactly what the SDDM login screen will look like, saving you from having to reboot repeatedly while customizing.

## Part 7 — Troubleshooting

### The script didn't update the SDDM config

If the install script runs but the theme doesn't appear after reboot, set it manually:

```bash
sudo nano /etc/sddm.conf.d/theme.conf
```

Make sure the file contains exactly this (replace `forest` with your theme):

```ini
[Theme]
Current=forest
```

Save and exit (**Ctrl+O → Enter**, then **Ctrl+X**), then test with the command from Part 5 before rebooting.

---

## Part 8 — Emergency Recovery (Black Screen at Boot)

If you reboot and get a frozen black screen, your machine is not broken — the theme failed to render. Do the following:

**Step 1 — Drop to a TTY**

Press **Ctrl + Alt + F3** to open a pure text terminal.

**Step 2 — Log in**

Enter your username (`void`) and password.

**Step 3 — Disable the broken theme**

```bash
sudo nano /etc/sddm.conf.d/theme.conf
```

Change the `Current=` line to a safe fallback:

```ini
[Theme]
Current=breeze
```

Or leave it completely blank to use the SDDM default. Save and exit.

**Step 4 — Reboot**

```bash
sudo reboot
```

You'll land at the standard SDDM login screen. From there you can diagnose what went wrong before trying again.

---

## Quick Reference

```
Install deps         sudo pacman -S sddm qt6-declarative qt6-5compat ...
Clone repo           git clone https://github.com/Darkkal44/qylock.git
First install        chmod +x sddm.sh && ./sddm.sh
Change theme         ./sddm.sh  (from inside ~/Downloads/qylock)
Test theme           sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/THEME_NAME
SDDM config file     /etc/sddm.conf.d/theme.conf
Font directory       /usr/share/fonts/
Emergency TTY        Ctrl + Alt + F3
```
