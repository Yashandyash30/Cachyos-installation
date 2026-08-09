# Headless Game Streaming with Virtual Displays (Niri & Sunshine)

Here is the complete, start-to-finish guide for your dynamic, hardware-accelerated headless streaming setup on CachyOS. This updated version correctly isolates your standard Niri session from your experimental streaming session.

---

## Phase 1: Build the Experimental Niri Compositor

To utilize virtual outputs, you need the specific Niri build that includes the unmerged virtual display pull request (PR #3800).

**1. Install the Rust toolchain and dependencies (if needed):**
```bash
sudo pacman -S rustup
rustup default stable
```

**2. Clone the Niri repository and check out the pull request:**
```bash
git clone https://github.com/YaLTeR/niri.git
cd niri
git fetch origin pull/3800/head:virtual-outputs
git checkout virtual-outputs
```

**3. Build the binary in release mode:**
```bash
cargo build --release
```

**4. Move the compiled binary to your local binaries folder:**
This ensures it doesn't overwrite your stable CachyOS Niri installation.
```bash
sudo cp target/release/niri /usr/local/bin/niri-virtual
```

---

## Phase 2: Create the Dynamic Systemd Wrapper

This script handles the heavy lifting. When launched, it temporarily hijacks systemd to boot your custom binary, hands control to the CachyOS session manager, and then cleans up after itself when you log out so your standard Niri session remains untouched.

**1. Open a new wrapper script file:**
```bash
sudo nano /usr/local/bin/niri-virtual-session
```

**2. Paste this exact configuration:**
```bash
#!/bin/bash

# 1. Create a temporary systemd override
mkdir -p "$HOME/.config/systemd/user/niri.service.d"

cat << 'EOF' > "$HOME/.config/systemd/user/niri.service.d/virtual-override.conf"
[Service]
ExecStart=
ExecStartPre=/usr/bin/sleep 1
ExecStart=/usr/local/bin/niri-virtual --session
EOF

systemctl --user daemon-reload

# 2. Hand control back to the standard CachyOS session manager
/usr/bin/niri-session

# 3. Clean up the override upon logout/shutdown
rm -f "$HOME/.config/systemd/user/niri.service.d/virtual-override.conf"
systemctl --user daemon-reload
```

**3. Make the script executable:**
```bash
sudo chmod +x /usr/local/bin/niri-virtual-session
```

---

## Phase 3: Register the Custom Desktop Session

SDDM needs to know this script exists so you can log into it.

**1. Create a new Wayland session file:**
```bash
sudo nano /usr/share/wayland-sessions/niri-virtual.desktop
```

**2. Paste this configuration inside:**
```ini
[Desktop Entry]
Name=Niri Virtual
Comment=Niri Wayland compositor with experimental virtual outputs
Exec=/usr/local/bin/niri-virtual-session
Type=Application
```

---

## Phase 4: Configure SDDM Autologin

Set SDDM to automatically boot into your new, isolated streaming environment on startup.

**1. Open your SDDM autologin configuration:**
```bash
sudo nano /etc/sddm.conf.d/autologin.conf
```

**2. Update the file to target the new session:**
```ini
[Autologin]
User=void
Session=niri-virtual
```

---

## Phase 5: Hardware Monitor Control (DDC/CI)

To prevent Wayland pipeline crashes, we bypass OS-level sleep and command the monitors to enter electrical standby via their HDMI/DisplayPort cables.

**1. Ensure `ddcutil` is installed and your user is in the `i2c` group:**
```bash
sudo pacman -S ddcutil
sudo usermod -aG i2c $USER
```
*(A reboot is required if you just added yourself to the group).*

**2. Verify your monitor IDs (typically `1` and `2` for a dual-monitor setup):**
```bash
ddcutil detect
```

---

## Phase 6: The "Panic Button" Safeguard

If a Moonlight stream crashes, the exit script won't run, leaving your physical monitors in hardware sleep. You need a dedicated Niri keybind to wake them up.

**1. Open your Niri configuration:**
```bash
nano ~/.config/niri/config.kdl
```

**2. Add this command to your binds section:**
```kdl
    // Emergency Monitor Wake-Up (Panic Button via DDC/CI Hardware Standby)
    Mod+Shift+Backspace { spawn "bash" "-c" "ddcutil -d 1 setvcp 0xd6 0x01 || true; ddcutil -d 2 setvcp 0xd6 0x01 || true"; }
```
*(Note: If you are entirely locked out of the PC, you can trigger these same commands remotely via SSH from your laptop—see the SSH/Tailscale guide for those commands).*

---

## Phase 7: Automate Sunshine

Configure Sunshine to handle the virtual display creation and hardware monitor sleeping seamlessly.

**1. Navigate to the Configuration Screen:**
Open the Sunshine Web UI (`https://localhost:47990`) and navigate to **Application -> edit (for first Desktop)**.

**2. Rename the Default Desktop:**
Change the name from **Desktop** to **Desktop-Privacy**.

**3. Configure the Pre/Post Commands:**
Below the command preparation section, set the **Do Command** to spin up the virtual screen and put the physical monitors to sleep:
```bash
sh -c "/usr/local/bin/niri-virtual msg create-virtual-output --name sunshine --width ${SUNSHINE_CLIENT_WIDTH} --height ${SUNSHINE_CLIENT_HEIGHT} --refresh-rate ${SUNSHINE_CLIENT_FPS} || true; sleep 2; ddcutil -d 1 setvcp 0xd6 0x04 || true; ddcutil -d 2 setvcp 0xd6 0x04 || true"
```

Set the **Undo Command** to wake your physical monitors and destroy the virtual output upon disconnect:
```bash
sh -c "ddcutil -d 1 setvcp 0xd6 0x01 || true; ddcutil -d 2 setvcp 0xd6 0x01 || true; /usr/local/bin/niri-virtual msg remove-virtual-output sunshine || true"
```
Click **Save** at the bottom to apply changes.

**4. Add a Standard Desktop Entry (Optional):**
To add another normal Desktop entry without privacy safeguards:
* Click on **Add New**.
* Enter **Desktop** in the **Application Name** box.
* Click on **Find Cover** in the Image Section to choose an appropriate icon.
* Click **Save** at the bottom to apply changes.

---

## Phase 8: Fix Moonlight Cursor Boundaries (Input Mapping)

When you disconnect a physical monitor, Niri dynamically recalculates your desktop width, which can cause the absolute mouse in Moonlight (used by phones and tablets) to hit an invisible wall because it thinks the desktop is wider than your stream. 

To fix this without turning off your monitors (which causes pipeline crashes), you must tell Niri to permanently map Sunshine's virtual mouse to the virtual output.

**1. Open your Niri config file:**
```bash
nano ~/.config/niri/config.kdl
```

**2. Add this specific output configuration to the bottom of the file:**
*(Add this anywhere at the root level, outside of any other blocks like input or layout)*

```kdl
    // Force the virtual output to spawn exactly at the origin (0,0).
    // This perfectly overlaps it with the physical monitor space, completely
    // eliminating the invisible absolute mouse boundary without needing to turn monitors off!
    output "sunshine" {
        position x=0 y=0
    }
```

Save and exit. When you start your next stream, your cursor will perfectly map to the exact edges of your screen, no matter how many physical monitors are currently plugged in!
