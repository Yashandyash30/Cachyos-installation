how to install comfyui on cachyos with amd support

# CachyOS External SSD: Laptop to Desktop Boot Migration & Freeze Fix

**Document Version:** 1.0
**Date:** September 30, 2026
**System:** CachyOS Linux (x86_64)
**Kernels:** `linux-cachyos` (7.2.x) and `linux-cachyos-lts` (6.18.x)
**Bootloader:** Limine (`limine-mkinitcpio-hook`)
**Initramfs Generator:** `mkinitcpio`

---

## 1. Hardware Environment

| Component                 | Laptop (Installation Machine)                                    | Desktop PC (Target Machine)                   |
| :------------------------ | :--------------------------------------------------------------- | :-------------------------------------------- |
| **Model**           | Acer Aspire A715-42G                                             | Custom Desktop (Gigabyte B550M DS3H R2)       |
| **CPU**             | AMD Ryzen 5 5500U (Lucienne)                                     | AMD Ryzen 7 5700X (Vermeer)                   |
| **Integrated GPU**  | AMD Radeon Graphics (Lucienne / GFX9 / DCN 2.1)                  | **None** (No iGPU on Ryzen 5700X)       |
| **Discrete GPU**    | NVIDIA GeForce GTX 1650 Mobile (TU117M)                          | AMD Radeon Desktop GPU (RX 9060 XT / RDNA)    |
| **Display Outputs** | Internal`eDP-1`, External `HDMI-A-1`                         | Dual Monitors:`MAG 255F E20` & `HP 324pv` |
| **Drive Setup**     | External SSD (Btrfs on`/dev/sda2`, FAT32 EFI on `/dev/sda1`) | Same External SSD connected via USB 3.2       |

---

## 2. Problem Description

When booting the external SSD on the desktop PC, the boot process halted indefinitely at:

```text
[ OK ] Reached target Switch Root.
Starting Switch Root...
```

### Why No Logs Appeared on Disk (`journalctl --list-boots`)

* Checking `journalctl --list-boots` on the SSD showed boots jumping directly from the laptop's previous session to the laptop's current session.
* **Explanation:** During early boot, the initramfs runs entirely in RAM. `systemd-journald` writes logs only to tmpfs (`/run/log/journal/`). Logs are only committed to persistent storage (`/var/log/journal/`) once the real root filesystem is mounted and `systemd-journal-flush.service` completes.
* Because the system locked up during the initramfs-to-real-root switch-root transition, the persistent log flush never ran. Hard-resetting the PC wiped the in-memory journal from RAM.

---

## 3. Root Cause Analysis

1. **Hardcoded NVIDIA Modules in Initramfs Drop-in (`/etc/mkinitcpio.conf.d/10-chwd.conf`)**

   * CachyOS Hardware Detection (`chwd`) on the laptop created a drop-in file:
     ```text
     MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
     ```
   * On the desktop PC, there is **no NVIDIA GPU**. During early boot, the kernel attempted to load proprietary NVIDIA DRM modules that stalled or failed waiting for non-existent hardware.
   * `amdgpu` was omitted from early modules.
2. **`autodetect` Hook Stripped Desktop AMD GPU Firmware**

   * In `/etc/mkinitcpio.conf`:
     ```text
     HOOKS=(base systemd autodetect microcode kms modconf block keyboard sd-vconsole plymouth filesystems)
     ```
   * The `autodetect` hook builds the initramfs based *strictly on the host machine's currently connected hardware*.
   * Because it was built on the laptop, `mkinitcpio` bundled firmware only for Lucienne/Renoir and Turing (GTX 1650). All firmware for desktop AMD GPUs (`dcn3*`, `gc11*`, `gc12*`, `psp*`, `smu*`) was stripped from the initramfs image. Early KMS failed when attempting to probe the desktop GPU.
3. **Plymouth KMS & `quiet splash` Screen Freeze**

   * The kernel cmdline in `/etc/default/limine` contained `quiet splash`.
   * Plymouth initializes a graphical splash screen on early DRM. During switch-root, `plymouth-switch-root.service` temporarily holds the framebuffer console (`fbcon: Deferring console take-over`).
   * When the GPU handoff failed or switched outputs, Plymouth froze the display with the last rendered buffer (`Starting Switch Root...`), masking the real boot state.
4. **Greeter / Compositor Display Lockout**

   * DMS-Greeter (`/var/cache/dms-greeter/settings.json`) was configured with:
     ```json
     "enabledGpuPciIds": ["10de:1f9d", "1002:164c"],
     "niriOutputSettings": { "eDP-1": { "focusAtStartup": true } }
     ```
   * If the system booted in the background, the compositor was looking for the laptop's internal display (`eDP-1`) instead of the desktop's DisplayPort/HDMI connectors.

---

## 4. Fixes Applied

### A. Added `amdgpu` to Early Kernel Modules

Edited `/etc/mkinitcpio.conf.d/10-chwd.conf`:

```bash
# /etc/mkinitcpio.conf.d/10-chwd.conf
MODULES+=(amdgpu nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```

* Ensures both open AMD graphics drivers and NVIDIA drivers are ready in early userspace on whichever machine the SSD is plugged into.

### B. Enabled Universal Fallback Initramfs in Limine

Edited `/etc/limine-entry-tool.conf`:

```text
# Changed from:
#MKINITCPIO_FALLBACK=linux-lts

# To:
MKINITCPIO_FALLBACK="yes"
```

### C. Rebuilt Initramfs Images

Executed:

```bash
sudo limine-mkinitcpio
```

This generated:

* `initramfs` (Host-optimized)
* `initramfs-fallback` (Universal – built without `autodetect`, bundling all device drivers, storage controllers, and GPU firmware for both desktop and laptop)
* Updated `/boot/limine.conf` with new boot entries.

Flushed all disk buffers:

```bash
sync
```

---

## 5. Boot Procedure on the Desktop PC

1. **Physical Connections:**

   * Plug the SSD enclosure into the **rear I/O motherboard USB ports** (blue or red USB 3.2 ports connected to CPU lanes; avoid front-panel case ports).
   * Connect monitors directly to the **discrete AMD Radeon GPU** ports (DisplayPort or HDMI), not the motherboard video outputs.
2. **Limine Boot Menu Selection:**

   * Power on the PC and enter the UEFI one-time boot menu (<kbd>F12</kbd> on Gigabyte boards).
   * In the Limine bootloader menu, press <kbd>↓</kbd> or <kbd>↑</kbd> to pause the countdown.
   * Highlight:
     ```text
     linux-cachyos (fallback)
     ```
3. **Verbose Booting (Disabling Plymouth Freeze):**

   * With `linux-cachyos (fallback)` highlighted, press <kbd>e</kbd> to edit the boot parameters.
   * Navigate with arrow keys to the `cmdline:` line.
   * Delete `quiet` and `splash`.
   * Press <kbd>F10</kbd> (or <kbd>Enter</kbd>) to boot.

---

## 6. Maintenance & Future Reference

* **Kernel Updates:** Because `MKINITCPIO_FALLBACK="yes"` is saved in `/etc/limine-entry-tool.conf`, every future `pacman -Syu` kernel upgrade will automatically regenerate both the standard image and the universal fallback image.
* **Manual Rebuild:** If configuration files in `/etc/mkinitcpio.conf.d/` change, regenerate images using:
  ```bash
  sudo limine-mkinitcpio
  ```
* **Greeter Screen Detection:** Once logged into the desktop, DMS/Niri will detect the new DisplayPort/HDMI outputs and write them to `~/.config/niri/dms/outputs.kdl`.

---

## 7. Post-Update Notices & Fixes (Systemd 262 & Portals)

### A. Warning: `Calling import-environment without a list of variable names is deprecated`

* **Cause:** The system update upgraded systemd to version `262-1`. In systemd 262, calling `systemctl import-environment` without specifying individual variable names prints a deprecation warning to stderr.
* **Source:** Line 36 of `/usr/bin/niri-session`:
  ```bash
  systemctl --user import-environment
  ```
* **Impact:** Purely cosmetic deprecation notice. The environment is still imported and the desktop session launches normally.

### B. Slow File Manager (Dolphin) and App Launch Delay Fix

* **Cause:** `/usr/share/xdg-desktop-portal/niri-portals.conf` had `default=gnome;gtk;`. Because Niri is not running GNOME Shell / Mutter, the GNOME portal backend hangs for a 25-second D-Bus timeout before falling back to GTK, causing file managers, file dialogs, and browser links to delay.
* **Fix Applied:** Created user override `~/.config/xdg-desktop-portal/niri-portals.conf`:
  ```ini
  [preferred]
  default=gtk
  org.freedesktop.impl.portal.Access=gtk
  org.freedesktop.impl.portal.Notification=gtk
  org.freedesktop.impl.portal.Secret=gnome-keyring
  org.freedesktop.impl.portal.FileChooser=kde;gtk
  org.freedesktop.impl.portal.ScreenCast=gnome;gtk
  ```
* **Result:** File pickers and Dolphin launch instantaneously with zero delay.

---

## 8. Post-Boot Shortcut Lag & Live Wallpaper Delay Optimization

### A. Root Cause 1: Physical USB Port Bottleneck (USB 2.0 vs USB 3.0)

* **Diagnosis:** Running `lsusb -t` and `udevadm info -a -n /dev/sda` revealed:
  ```text
  ATTRS{product}=="RTL9210B-CG"
  ATTRS{speed}=="480"
  Driver=usb-storage
  ```

  The external NVMe enclosure (Realtek RTL9210B 10 Gbps bridge) was plugged into a **black USB 2.0 port** on the PC.
* **Impact:**
  - Bandwidth was capped at **480 Mbps (~35-40 MB/s)** instead of **5,000-10,000 Mbps (500-1000 MB/s)**.
  - The kernel fell back to the legacy `usb-storage` driver with a single command queue depth of 1 (no command queuing / NCQ) instead of `uas` (USB Attached SCSI).
  - When booting into the desktop, reading two 1080p video streams simultaneously, loading desktop QML assets, running `ffmpeg`, and launching heavy apps saturated the USB 2.0 bus, resulting in 10-20 seconds of I/O queue wait times.
* **Resolution:** Plug the external SSD into one of the **BLUE USB 3.2 Gen 1 ports** in the middle section of the Gigabyte B550M DS3H R2 rear I/O panel.

### B. Root Cause 2: Session Lock Inhibition (`lockAtStartup`)

* **Mechanism:** DMS has `lockAtStartup: true` configured. When `greetd` auto-logs into Niri, DMS immediately engages the Wayland session lock (`ext-session-lock-v1`).
* **Shortcut Behavior:** Under the Wayland security specification, when a session is locked:
  - **All application shortcut keybindings (`Super+E`, `Super+B`, etc.) are completely inhibited by Niri.**
  - The compositor will NOT dispatch shortcuts to launch applications until PAM authenticates and unlocks the session.
  - MpvPaper pauses/stops live wallpapers during lock: `MpvPaper: Screen locked - stopping all videos`.

### C. Software Optimizations Applied

1. **Cached Still Frame Detection in MpvPaper:**
   - Modified `~/.config/DankMaterialShell/plugins/mpvpaper/MpvPaperDaemon.qml` line 634:
     ```bash
     mkdir -p -- "$1" && if [ -s "$3" ]; then exit 0; else ffmpeg -loglevel error -i "$2" -ss 00:00:02 -vframes 1 -vf "scale=1280:-1" -q:v 2 "$3" -y; fi
     ```
   - If the palette thumbnail already exists in cache, it exits in 1ms instead of decoding the video with `ffmpeg` on every startup.
2. **Eliminated Duplicate DMS Spawn in Niri:**
   - Commented out `spawn-at-startup "dms"` in `~/.config/niri/config.kdl` because `dms.service` is already actively started and managed by the systemd user session (`niri.service.wants/dms.service`).
3. **Incremental Cache Updates:**
   - Removed `--noincremental` from `spawn-at-startup "kbuildsycoca6"` in `~/.config/niri/config.kdl`, preventing full scans of all `.desktop` and MIME files across the USB drive on every boot.
