# Linux Wake & Lid Fix Guide
> CachyOS + Niri | Acer Aspire | UGREEN KVM Setup

---

## Phase 1 — Laptop Lid Issue

Stop the lid-close event from suspending or crashing the system in clamshell mode.

### Step 1 — Override lid events in logind

Tell systemd to completely ignore the physical lid switch.

```bash
sudo nano /etc/systemd/logind.conf
```

Find these lines, remove the leading `#`, and set them to `ignore`:

```ini
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

Apply the change (this briefly ends your session — save work first):

```bash
sudo systemctl restart systemd-logind
```

---

### Step 2 — Replace power-profiles-daemon with TLP

The default daemon aggressively powers off the Wi-Fi card on lid close.
Mask it and replace it with TLP, which handles power without dropping the network.

```bash
sudo systemctl stop power-profiles-daemon
sudo systemctl mask power-profiles-daemon
sudo pacman -S tlp tlp-rdw
sudo systemctl enable --now tlp
```

Verify TLP is active:

```bash
tlp-stat -s
# Look for: State: enabled
```

> **Note:** After masking the daemon, the DMS shell Power Saver / Performance buttons
> will show an error. Use TLP directly instead (see Step 4).

---

### Step 3 — Disable the internal screen in Niri

In your `~/.config/niri/config.kdl`, tell Niri to ignore the closed laptop screen:

```kdl
output "eDP-1" {
    off
}
```

This prevents the compositor from trying to render to the closed display and saves GPU overhead for your external monitor.

---

### Step 4 — Switch power profiles without the DMS widget

```bash
sudo tlp bat    # Power-saver mode (on battery)
sudo tlp ac     # Performance mode (plugged in)
```

For a full GUI dashboard, install `tlpui`:

```bash
paru -S tlpui
```

---

## Phase 2 — Wake by USB

Wake the suspended laptop with a keyboard tap through the KVM switch.

> **Critical:** Wake on USB only works from **Suspend**, not a full shutdown.
> Always use `systemctl suspend` — never power off when you want USB wake to work.

---

### BIOS Setup (Phase 2A)

1. Reboot and press **F2** to enter BIOS.
2. On the **Main** tab, press **Ctrl + S** to reveal hidden Acer options.
3. Enable **"USB Wake Support"** or **"Power-off USB charge"**.
4. Disable **Fast Boot** — it cuts USB power during sleep.
5. Save with **F10** and reboot.

> If no USB Wake option appears even after Ctrl + S, don't worry.
> On Ryzen 5500U, the OS handles ACPI wake triggers directly.

---

### OS Configuration (Phase 2B)

**1. Check which USB controllers exist and their wake status:**

```bash
cat /proc/acpi/wakeup
```

Look for `XHC0`, `XHC1`, `USB0`, or `PTXH`. If any show `*disabled`, enable them:

```bash
sudo sh -c 'echo XHC0 > /proc/acpi/wakeup'
# Verify:
cat /proc/acpi/wakeup
```

**2. Make it permanent with a systemd service:**

```bash
sudo nano /etc/systemd/system/usb-wake.service
```

Paste the following (replace `XHC0` with your actual controller name if different):

```ini
[Unit]
Description=Enable USB Wakeup
DefaultDependencies=no
After=basic.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'if grep -q "XHC0.*disabled" /proc/acpi/wakeup; then echo XHC0 > /proc/acpi/wakeup; fi'

[Install]
WantedBy=multi-user.target
```

Enable the service:

```bash
sudo systemctl enable --now usb-wake.service
```

---

### KVM Wake Workflow

The KVM physically disconnects the USB bus when toggled to the PC.
The laptop cannot hear keyboard input unless it is the selected input.

```
1. Toggle KVM → to laptop input
2. Tap Spacebar on EvoFox keyboard
3. Niri session appears on MSI monitor
```

---

### Sleep Mode: s2idle vs deep

`s2idle` (Modern Standby) is more reliable for USB wake because hardware never fully shuts down.

Check current mode:

```bash
tlp-stat -s
# Look for: Suspend mode = s2idle [deep]  (bracketed = active)
```

Switch to `s2idle` temporarily:

```bash
echo s2idle | sudo tee /sys/power/mem_sleep
```

Make it permanent via GRUB:

```bash
sudo nano /etc/default/grub
# Add mem_sleep_default=s2idle inside GRUB_CMDLINE_LINUX_DEFAULT quotes
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## Phase 3 — Wake on LAN (Wired Ethernet)

Send a magic packet over ethernet to remotely wake the laptop from your PC.

---

### BIOS Prerequisites

- Enable **Wake on LAN** or **Wake on PCIe** in BIOS.
- Disable **Fast Boot**.

---

### Step 1 — Find your connection name and device

```bash
nmcli connection show
# Note both the NAME (e.g. "Wired connection 1") and DEVICE (e.g. enp3s0)
```

---

### Step 2 — Confirm hardware support

```bash
sudo pacman -S ethtool
sudo ethtool <DEVICE_NAME> | grep Wake-on
```

Look for `Supports Wake-on: pumbg` — the `g` means magic packet is supported.
If `Wake-on` shows `d` (disabled), the next step will fix it.

---

### Step 3 — Bind magic packet to the connection profile

```bash
sudo nmcli connection modify "Wired connection 1" 802-3-ethernet.wake-on-lan magic
```

Replace `"Wired connection 1"` with the exact NAME from Step 1.
This persists across reboots via NetworkManager.

---

### Step 4 — Get the laptop's MAC address

```bash
ip link show eth0
# Look for: link/ether aa:bb:cc:dd:ee:ff
```

Save this MAC address — you need it to send the wake packet.

---

### Step 5 — Send the magic packet from your PC

Install the tool on your PC:

```bash
sudo pacman -S wol
```

Wake the laptop:

```bash
wol 74:4c:a1:7f:41:09
```

**Fish shell alias (permanent):**

```fish
alias wake-laptop="wol 74:4c:a1:7f:41:09"
funcsave wake-laptop
```

Or add to `~/.config/fish/config.fish`:

```fish
abbr -a wl "wol 74:4c:a1:7f:41:09"
```

Run `source ~/.config/fish/config.fish` or open a new terminal. Now just type `wl` to wake the laptop.

---

## Phase 4 — Wake on WLAN (Wi-Fi)

Wake the laptop wirelessly using a magic packet over Wi-Fi.

> **Note:** WoWLAN depends entirely on the Wi-Fi chip. Intel cards usually support it.
> Realtek and MediaTek chips often do not. Check hardware support first.

---

### Step 1 — Check if your Wi-Fi chip supports WoWLAN

```bash
iw phy0 wowlan show
```

| Output | Meaning |
|--------|---------|
| Lists `magic-packet` | Supported — proceed |
| Says `WoWLAN is disabled` | Supported but off — continue to Step 2 |
| Says `unsupported` | Your chip cannot do WoWLAN — use wired LAN instead |

---

### Step 2 — Enable WoWLAN on the Wi-Fi radio

```bash
sudo iw phy0 wowlan enable magic-packet
```

Verify it is now active:

```bash
iw phy0 wowlan show
# Should list: magic-packet
```

---

### Step 3 — Bind magic packet to the Wi-Fi connection profile

```bash
sudo nmcli connection modify "ARIES-WIFI" 802-11-wireless.wake-on-wlan magic
```

Replace `"ARIES-WIFI"` with your actual Wi-Fi SSID / connection name from:

```bash
nmcli connection show
```

NetworkManager will automatically re-apply the `iw` setting every time you connect to this network.

---

### Step 4 — Get the WLAN MAC address

```bash
ip link show wlan0
# Look for: link/ether aa:bb:cc:dd:ee:ff
```

---

### Step 5 — End-to-end test

```bash
# 1. Suspend the laptop
systemctl suspend

# 2. From your PC, send the magic packet
wol <WLAN_MAC_ADDRESS>

# 3. Laptop should wake and reconnect to Wi-Fi
```

If it wakes successfully, the full setup is complete.

---

## Quick Reference

| Goal | Command |
|------|---------|
| Apply lid fix | `sudo systemctl restart systemd-logind` |
| Check TLP status | `tlp-stat -s` |
| Switch to performance | `sudo tlp ac` |
| Switch to power-saver | `sudo tlp bat` |
| Check USB wake status | `cat /proc/acpi/wakeup` |
| Check WoWLAN status | `iw phy0 wowlan show` |
| Enable WoWLAN | `sudo iw phy0 wowlan enable magic-packet` |
| Suspend laptop | `systemctl suspend` |
| Wake over network | `wol <MAC_ADDRESS>` |
| Check sleep mode | `cat /sys/power/mem_sleep` |

---

## Conda Conflict Note

If you run Conda and system tools like `powerprofilesctl` or `tlp` error out, it's because
Conda hijacks the `python` command. Deactivate before running system tools:

```bash
conda deactivate
```

Or call the system Python explicitly:

```bash
/usr/bin/python /usr/bin/powerprofilesctl get
```
