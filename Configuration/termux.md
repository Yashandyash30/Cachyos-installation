Here is your complete, fully integrated master guide. It incorporates the custom Termux display name (`voidphone`), automatic background startup steps, and the dynamic USB/Wi-Fi Fish switching functions for both your CachyOS PC and laptop.

---

# Complete Remote Management & Wake-on-LAN Master Guide

This guide configures your Android phone (**`voidphone`**) as an always-on bridge. It allows you to access it locally via USB (ADB) or remotely from anywhere via Tailscale, and uses it to wake your CachyOS PC over LAN from a remote laptop.

---

## Phase 1: The Android Phone (`voidphone`) Setup

1. **Install Termux and Core Tools:**
2. Download and install **Termux** (from F-Droid).
3. Open Termux and run the update and package installation commands:

```bash
pkg update && pkg upgrade -y
pkg install openssh wol -y
```

3. Set a password for your SSH access:

```bash
passwd
```

2. **Configure Termux Display Name and Auto-Start SSH:**
3. Set your terminal prompt so it reads **`voidphone`**:

```bash
echo "PS1='\033[1;32mvoidphone\033[0m:\033[1;34m\w\033[0m$ '" >> ~/.bashrc
```

2. Make `sshd` launch automatically every time you open Termux:

```bash
echo "sshd" >> ~/.bashrc
```

3. Apply the changes:

```bash
source ~/.bashrc
```

3. **Automate Boot Persistence (Termux:Boot):**
4. Install **Termux:Boot** (from F-Droid) and open it once from your app drawer so Android registers it.
5. Run this inside Termux to create the background boot script (which also acquires a CPU wakelock to prevent Android from killing your server):

```bash
mkdir -p ~/.termux/boot/
cat << 'EOF' > ~/.termux/boot/start-sshd.sh
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
EOF
chmod +x ~/.termux/boot/start-sshd.sh
```

4. Click on **wakelock** on expanding the termux from notification bar.
5. Install and Configure Tailscale:
6. Install **Tailscale** from the Play Store or F-Droid and log in.
7. Go to the [Tailscale Admin Console](https://login.tailscale.com/admin/machines) in a browser, find your phone, click the three dots, select **Edit machine name**, and name it **`voidphone`**. *(Its permanent Tailscale IP is `100.103.187.97`).*
8. In your phone's Android **Settings** > **Network & Internet** > **VPN**, tap the gear icon next to Tailscale and enable **Always-on VPN**.
9. **Enable USB Debugging:**
   In Android **Developer Options**, turn on **USB Debugging** so your computers can interface with it over a physical cable.

---

## Phase 2: The CachyOS PC (Target Machine) Setup

1. **Enable Wake-on-LAN (BIOS & OS):**
2. **BIOS:** Reboot into your motherboard BIOS during startup, locate Power Management, and enable **Wake on LAN** (or PCI-E Wake).
3. **OS (ethtool):** Enable WoL on your wired interface (`enp2s0`):

```bash
sudo pacman -S ethtool
sudo ethtool -s enp2s0 wol g
```

3. **OS (NetworkManager):** Make it persistent across reboots:

```bash
nmcli connection modify "Wired connection 1" 802-3-ethernet.wake-on-lan magic
```

2. **Install Tailscale:**

```bash
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up

```

3. **Create the Dynamic Fish Alias:**
   Open your Fish terminal on the PC and paste this script to automatically toggle between the USB cable tunnel and wireless Tailscale access:

```fish
function phone
    if test "$argv[1]" = "wifi"
        # Connect wirelessly via Tailscale Static IP
        ssh u0_a183@100.103.187.97 -p 8022
    else
        # Connect via USB / ADB bridge
        adb forward tcp:8022 tcp:8022 2>/dev/null
        ssh u0_a183@127.0.0.1 -p 8022
    end
end
funcsave phone

```

---

## Phase 3: The CachyOS Laptop (Remote Commander) Setup

1. **Install Tailscale:**

```bash
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up

```

2. **Create the Dynamic Phone Alias:**
   Paste the exact same `phone` function into your laptop's Fish terminal:

```fish
function phone
    if test "$argv[1]" = "wifi"
        ssh u0_a183@100.103.187.97 -p 8022
    else
        adb forward tcp:8022 tcp:8022 2>/dev/null
        ssh u0_a183@127.0.0.1 -p 8022
    end
end
funcsave phone

```

3. **Create the Remote Wake-on-LAN Alias (wakepc):**
   This command securely logs into `voidphone` via Tailscale from your laptop and fires the magic WoL packet to your PC's MAC address (`f0:4e:a4:37:91:66`):

```fish
function wakepc
    ssh u0_a183@100.103.187.97 -p 8022 "wol f0:4e:a4:37:91:66"
end
funcsave wakepc

```

---

## Daily Workflow Summary

* **Managing `voidphone` via USB (PC or Laptop):** Plug in the phone via cable and type `phone`.
* **Managing `voidphone` Wirelessly (Anywhere via Tailscale):** Type `phone wifi`.
* **Waking up your PC from the Laptop (Outside the local network):** Open your laptop terminal and type `wakepc`. Wait roughly 15–30 seconds for the PC to boot and start Tailscale, then SSH directly into it using its Tailscale IP (`100.117.73.75`).
