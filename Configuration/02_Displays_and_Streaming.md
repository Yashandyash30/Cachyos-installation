# 02 - Displays and Streaming Guide

This document aggregates all guides related to external monitors, software KVMs, hardware brightness controls, and Sunshine game streaming.

---

## 1. The Wayland Monitor Switch-Software KVM Guide (Niri Edition)

This guide completely bypasses hardware KVM video bottlenecks, preserving 200Hz refresh rates and Adaptive Sync on the MSI MAG monitor while enabling instant input switching via `ddcutil`.

### Phase 1: Physical Wiring Architecture
The foundation of this setup relies on splitting the video and USB signals. The standalone KVM is relegated strictly to USB duty.
1. **Video Connections (Direct):**
   * **Main PC:** Connect directly to the MSI monitor (e.g., via DisplayPort or HDMI).
   * **Laptop:** Connect directly to the MSI monitor (e.g., via HDMI-1 or HDMI-2).
2. **USB Connections (Routed):**
   * Plug the mechanical keyboard and mouse into the physical KVM switch inputs.
   * Run the KVM's USB outputs to the PC and the laptop.

### Phase 2: OS Dependencies & Permissions
*Perform this phase on BOTH the CachyOS PC and the Laptop.*

**1. Install Required Packages**
```bash
sudo pacman -S ddcutil i2c-tools
```

**2. Enable the I2C Kernel Module**
```bash
sudo modprobe i2c-dev
echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf
```

**3. Grant User Permissions**
To execute display commands via keyboard shortcuts without triggering a `sudo` password prompt every time, add your user to the `i2c` group.
```bash
sudo gpasswd -a $USER i2c
newgrp i2c
```
*(Note: A full system reboot is highly recommended after this step).*

### Phase 3: Hardware Discovery
You need to map your physical hardware to exact hexadecimal addresses.

**1. Identify the Display Number (Crucial for Multi-Monitor)**
Run this on the machine with multiple screens:
```bash
ddcutil detect
```
*Look for the block containing "MSI MAG 255F" and note the Display number (e.g., `Display 2`). You will need the `-d 2` flag for this machine.*

**2. Identify the Input Hex Codes**
To find out exactly what input a machine is currently using, run:
```bash
ddcutil getvcp 60
```
* `0x0f` = DisplayPort
* `0x11` = HDMI-1
* `0x12` = HDMI-2

Write down the code for the **PC** and the code for the **Laptop**.

### Phase 4: Niri Configuration (`config.kdl`)
Map the `ddcutil` commands to a unified toggle key (`Super+Shift+D`). The trick here is that each machine must fire a command telling the monitor to look at the *other* machine's hex code.

**1. The Main PC Configuration**
Assuming the PC is targeting a laptop on **HDMI-2 (`0x12`)**, and the MSI is **Display 2**:
```kdl
    // Switch MSI monitor to Laptop (HDMI-2)
    Super+Shift+D { spawn "ddcutil" "-d" "2" "setvcp" "60" "0x12"; }
```

**2. The Laptop Configuration**
Assuming the laptop is targeting a PC on **HDMI-1 (`0x11`)**, and the MSI is the only external screen:
```kdl
    // Switch MSI monitor back to Main PC (HDMI-1)
    Super+Shift+D { spawn "ddcutil" "setvcp" "60" "0x11"; }
```

### Phase 5: Reload and Execute
1. On both machines, reload the Niri configuration: `niri msg action quit`
2. **The Final Execution Loop:**
   * Hit `Super+Shift+D` (The screen jumps to the other machine).
   * Tap the physical KVM switch button (The USB peripherals jump to the other machine).

---

## 2. External Monitor Brightness Controls

Here is the streamlined, terminal-only guide to setting up and controlling your monitor brightness from the command line using `ddcutil`.

### 1. Prerequisites
You must have `ddcutil` installed and the `i2c-dev` kernel module loaded (which was done in the KVM guide above). 
Verify the connection by running `ddcutil detect`.

### 2. Set Up Terminal Shortcuts
Using abbreviations is the fastest way to control the monitor straight from the prompt.
Open `~/.config/fish/config.fish` and paste these lines at the bottom:
```fish
# External Monitor Brightness Controls
abbr -a bset 'ddcutil setvcp 10'
abbr -a bget 'ddcutil getvcp 10'
abbr -a bup 'ddcutil setvcp 10 + 10'
abbr -a bdown 'ddcutil setvcp 10 - 10'
```
Reload your shell environment: `source ~/.config/fish/config.fish`

### Using Your Shortcuts
* **Set an exact level:** Type `bset 70` to set the brightness to 70%.
* **Adjust relative levels:** Type `bup` to bump it up by 10%, or `bdown` to lower it by 10%.
* **Check the level:** Type `bget` to see what the monitor is currently set to.

---

## 3. The Ultimate CachyOS + Niri Sunshine Guide

This covers everything from the initial install to pinpointing your specific GPU nodes and configuring Sunshine based on your use case.

### Phase 1: Native Installation & Firewall Configuration
Install the required packages and encode libraries:
```bash
sudo pacman -Syu sunshine cuda libva-mesa-driver libva-utils ufw
```
Punch the exact holes needed in UFW:
```bash
sudo ufw enable
sudo ufw allow 47984,47989,47990,48010/tcp
sudo ufw allow 47998:48010/udp
sudo ufw reload
```

### Phase 2: Systemd Initialization
Because you are running a Wayland compositor (Niri), Sunshine must be run as a **user service**, not a system-wide service.
```bash
systemctl --user daemon-reload
systemctl --user enable --now sunshine
```
*(If it fails, use `pacman -Ql sunshine | grep \.service` to find the exact service name, e.g., `app-dev.lizardbyte.app.Sunshine`).*

### Phase 3: Identify Your GPU Rendering Nodes
Because you have a hybrid setup (Ryzen APU + NVIDIA GTX 1650), you need to identify which node is which. Run the `vainfo` command for both `/dev/dri/renderD128` and `129`:
```bash
vainfo --display drm --device /dev/dri/renderD128 | grep -E "((VAProfileH264High|VAProfileHEVCMain|VAProfileHEVCMain10).*VAEntrypointEncSlice)|Driver version"
```
* **NVIDIA:** Shows a vendor ID of `10de` and fails the VA-API test (NVIDIA natively uses NVENC).
* **AMD:** Shows `Mesa Gallium driver... for AMD Radeon Graphics` and passes the VA-API test.

### Phase 4: Choose Your Encoder Setup
Open the Sunshine Web UI (**https://localhost:47990**) -> **Configuration -> Audio/Video**.

**Setup A: AMD APU (Best for Wayland Desktop Stability)**
Prevents EGL memory-sharing crashes between the AMD and NVIDIA chips since Niri renders the desktop on the APU.
1. **Adapter Name:** AMD node (e.g., `/dev/dri/renderD129`).
2. **Video Encoder:** `vaapi`.

**Setup B: NVIDIA GPU (Best for Heavy Gaming)**
If you are streaming demanding games running on the GTX 1650.
1. **Adapter Name:** NVIDIA node (e.g., `/dev/dri/renderD128`).
2. **Video Encoder:** `nvenc`.

Apply and restart:
```bash
systemctl --user restart sunshine
```

### Phase 5: Crucial Wayland & Niri Quirks

1. **The "First Launch" Screen Share Prompt:** The first time you connect from Moonlight, Wayland's `xdg-desktop-portal` will display a prompt on the host physical screen asking for permission to "Share this screen." You must physically click **Allow** before the video feed pushes through.
2. **The "Greedy" Super Key:** If you press global Niri shortcuts (like `Super + Enter`) while streaming, they trigger on your *local* machine. In Moonlight, go to Settings -> Input Settings -> **Capture system keyboard shortcuts** and set it to **Always** (or press `Ctrl + Alt + Shift + Z` while streaming).
3. **Eradicating Legacy X11 Commands:** If your stream instantly crashes, check your apps configuration (`~/.config/sunshine/apps.json`). Delete any `xrandr` commands from the `"do"` and `"undo"` fields, as X11 commands will fatally clash with a pure Wayland environment like Niri.
