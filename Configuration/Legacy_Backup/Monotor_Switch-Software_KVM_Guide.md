# The Wayland Monotor Switch-Software KVM Guide (Niri Edition)

This guide completely bypasses hardware KVM video bottlenecks, preserving 200Hz refresh rates and Adaptive Sync on the MSI MAG monitor while enabling instant input switching via `ddcutil`.

## Phase 1: Physical Wiring Architecture

The foundation of this setup relies on splitting the video and USB signals. The standalone KVM is relegated strictly to USB duty.

1. **Video Connections (Direct):**
* **Main PC:** Connect directly to the MSI monitor (e.g., via DisplayPort or HDMI).
* **Laptop:** Connect directly to the MSI monitor (e.g., via HDMI-1 or HDMI-2).


2. **USB Connections (Routed):**
* Plug the mechanical keyboard and mouse into the physical KVM switch inputs.
* Run the KVM's USB outputs to the PC and the laptop.



---

## Phase 2: OS Dependencies & Permissions

*Perform this phase on BOTH the CachyOS PC and the Laptop.*

### 1. Install Required Packages

Wayland compositors cannot inherently control monitor hardware, so you need the DDC/CI utility.

```bash
sudo pacman -S ddcutil i2c-tools

```

### 2. Enable the I2C Kernel Module

Load the module that allows communication over the display cables, and set it to load automatically on every boot.

```bash
sudo modprobe i2c-dev
echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf

```

### 3. Grant User Permissions

To execute display commands via keyboard shortcuts without triggering a `sudo` password prompt every time, add your user to the `i2c` group.

```bash
sudo gpasswd -a $USER i2c
newgrp i2c

```

*(Note: A full system reboot is highly recommended after this step to ensure group permissions apply to the Wayland session).*

---

## Phase 3: Hardware Discovery

You need to map your physical hardware to exact hexadecimal addresses.

### 1. Identify the Display Number (Crucial for Multi-Monitor)

If a machine has more than one monitor (like a secondary HP screen), you must isolate the MSI monitor's ID. Run this on the machine with multiple screens:

```bash
ddcutil detect

```

*Look for the block containing "MSI MAG 255F" and note the Display number (e.g., `Display 2`). You will need the `-d 2` flag for this machine.*

### 2. Identify the Input Hex Codes

To find out exactly what input a machine is currently using, run:

```bash
ddcutil getvcp 60

```

* `0x0f` = DisplayPort
* `0x11` = HDMI-1
* `0x12` = HDMI-2

Write down the code for the **PC** and the code for the **Laptop**.

---

## Phase 4: Niri Configuration (`config.kdl`)

Map the `ddcutil` commands to a unified toggle key (`Super+D`). The trick here is that each machine must fire a command telling the monitor to look at the *other* machine's hex code.

### 1. The Main PC Configuration

Open `~/.config/niri/config.kdl`. Assuming the PC is targeting a laptop on **HDMI-2 (`0x12`)**, and the MSI is **Display 2**:

```kdl
    // =========================================
    // Switch MSI monitor to Laptop (HDMI-2)
    // =========================================
    Super+Shift+D { spawn "ddcutil" "-d" "2" "setvcp" "60" "0x12"; }

```

### 2. The Laptop Configuration

Open `~/.config/niri/config.kdl`. Assuming the laptop is targeting a PC on **HDMI-1 (`0x11`)**, and the MSI is the only external screen (`-d` flag not needed):

```kdl
    // =========================================
    // Switch MSI monitor back to Main PC (HDMI-1)
    // =========================================
    Super+Shift+D { spawn "ddcutil" "setvcp" "60" "0x11"; }

```

---

## Phase 5: Reload and Execute

On both machines, reload the Niri configuration:

```bash
niri msg action quit

```

**The Final Execution Loop:**

1. Hit `Super+D` (The screen jumps to the other machine).
2. Tap the physical KVM switch button (The USB peripherals jump to the other machine).
