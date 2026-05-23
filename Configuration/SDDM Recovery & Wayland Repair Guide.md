Here is your complete master guide for escaping a broken SDDM boot loop and permanently fixing the underlying Wayland issues. You can save this for future reference whenever an update or custom script knocks out your login manager on a CachyOS/BTRFS system.

---

# SDDM Recovery & Wayland Repair Guide

### (For Infinite Loading Screens, Black Screens, or Display Crashes)

## Phase 1: Emergency Hardware Reset & Snapshot Entry

When your system attempts to boot but gets stuck on an infinite loading loop or a black screen, the graphical interface has completely failed to initialize.

1. **Force Power Off:** Press and hold your physical computer power button for about 5–10 seconds until the machine completely shuts down.
2. **Power On:** Press the power button to turn it back on.
3. **Access GRUB Snapshots:** When the black GRUB bootloader menu appears, use your arrow keys to scroll down to the **CachyOS Snapshots** (or BTRFS Snapshots) submenu and press `Enter`.
4. **Boot the Past:** Select a snapshot dated from *before* the system broke (e.g., right before your last system update) and press `Enter`.

The system will now boot into a temporary, "read-only" state. Your files and desktop will look exactly as they did at that specific time.

## Phase 2: Restoring the Main System

Because the snapshot you are currently in is read-only, any changes you make will be erased when you reboot. You must permanently apply this working state over your broken root filesystem.

1. Open your terminal.
2. Launch your snapshot restoration utility from the command line.
3. When prompted with the restore options (e.g., `[r] restore | [l] list | [c] cancel`), type **`r`** and press `Enter`.
4. If asked to name a backup of the current broken state (e.g., `Description for backup subvolume`), you can type a brief name like `broken-sddm-update` or just press `Enter` to accept the default.
5. Wait for the restoration success message.

## Phase 3: The Proper Reboot (Escaping the Trap)

This is the most common pitfall. If you reboot and select the snapshot menu again, you will be stuck in a loop.

1. Restart your PC:
```bash
sudo reboot

```


2. When the GRUB menu appears, **DO NOT** go into the Snapshots submenu.
3. Select the very first option at the top of the list (usually **CachyOS Linux**).
4. Press `Enter`.

You will now boot normally into your permanently restored, read-write system.

## Phase 4: The Permanent SDDM Fix

You are back in, but the system is still vulnerable. If a custom script (like a tiling manager installer) accidentally stripped out Wayland UI dependencies, the next time you run `sudo pacman -Syu`, SDDM will crash all over again. We need to bulletproof the login screen.

Open your terminal and run these three steps:

**1. Reinstall the Missing Qt Wayland Plugins**
This ensures SDDM has the core graphical libraries it needs to draw the UI without instantly aborting to a black screen:

```bash
sudo pacman -S --needed qt5-wayland qt6-wayland qt5-quickcontrols2 qt6-declarative

```

**2. Erase the Ghost Display Settings (The Flicker Fix)**
If you are running mixed refresh rates or dual monitors, SDDM's hidden system account often tries to apply legacy or conflicting display settings, causing severe screen flickering at the login prompt. Wipe its memory to force a clean hardware read:

```bash
sudo rm -rf /var/lib/sddm/.local/share/kscreen/

```

*(Note: If this returns "No such file or directory", it just means the cache is already empty).*

**3. Final Reboot**
Restart your machine to apply the fresh display cache and load the newly injected Qt packages:

```bash
sudo reboot

```
