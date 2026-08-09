# SSH & Tailscale Cross-Platform Setup Guide

Tailscale completely handles the routing for you. You do not need separate local and remote setups.

Tailscale uses a peer-to-peer mesh architecture. When your laptop and PC are on the same local network, Tailscale detects this and routes the SSH traffic directly over your LAN for maximum speed and zero latency. When you are away from home, it automatically creates a secure tunnel over the internet using NAT traversal. You just use the same Tailscale IP everywhere.

Here is the complete guide to setting up SSH on your CachyOS + Niri + DMS machines, complete with smart Fish functions that integrate your existing `voidphone` Wake-on-LAN setup.

---

## Phase 1: Enable SSH on Both PC and Laptop

By default, CachyOS might not have the SSH daemon running. You need to enable it on both machines.

1. **Install and start OpenSSH (Run on BOTH PC and Laptop):**

```bash
sudo pacman -S openssh jq
sudo systemctl enable --now sshd
```

2. **Find your Laptop's Tailscale IP:**
   Since you already know your PC's IP (`100.117.73.75`), run this on your laptop to get its specific IP:

```bash
tailscale ip -4
```

*(Note this IP down for the PC's configuration step).*

---

## Phase 2: Passwordless Login (SSH Keys)

To make your Fish aliases completely seamless, set up SSH keys so you don't have to type your password every time you connect.

1. **Generate keys (Run on BOTH PC and Laptop):**

```bash
ssh-keygen -t ed25519
```

*(Press Enter for all prompts to accept the defaults and skip the passphrase).*

2. **Send Laptop's key to the PC (Run on Laptop):**

```bash
ssh-copy-id void@100.117.73.75
```

*(It will ask for your PC's user password once).*

3. **Send PC's key to the Laptop (Run on PC):**

```bash
ssh-copy-id void@<LAPTOP_TAILSCALE_IP>
```

---

## Phase 3: Smart Fish Shell Functions

These functions will allow you to quickly jump between machines. Because you already have `wakepc` configured via `voidphone`, we can make the laptop's connection command "smart"—it will check if the PC is awake, and if not, it will automatically wake it up before connecting.

### On your Laptop (The Remote Commander)

Open your Fish terminal and paste this code. Replace `<your_username>` with your actual CachyOS username.

```fish
function sshpc
    # Ping the PC's Tailscale IP once to see if it is online
    ping -c 1 -W 1 100.117.73.75 > /dev/null
  
    if test $status -ne 0
        echo "PC is offline. Sending Wake-on-LAN via voidphone..."
        wakepc
        echo "Waiting 30 seconds for PC to boot and connect to Tailscale..."
        sleep 30
    end
  
    echo "Connecting to PC..."
    ssh void@100.117.73.75
end
funcsave sshpc
```

### On your PC (The Target Machine)

Open your Fish terminal and paste this code. Replace `<your_username>` and `<LAPTOP_TAILSCALE_IP>`.

```fish
function sshlaptop
    echo "Connecting to Laptop..."
    ssh void@<LAPTOP_TAILSCALE_IP>
end
funcsave sshlaptop
```

### Universal Utilities (For Both PC and Laptop)

Check your phone's current battery level and charging status directly from your computer's terminal using the official Termux API:

*(Note: This requires you to have installed `pkg install termux-api` in Termux and the **Termux:API** app from F-Droid).*

```fish
function phonebattery
    echo "Querying voidphone..."
    ssh -p 8022 u0_a183@100.103.187.97 "termux-battery-status" | jq -r '"Battery Level: \(.percentage)%\nStatus: \(.status)"'
end
funcsave phonebattery
```

---

## Phase 4: Emergency Streaming Recovery (Over SSH)

If your Moonlight stream crashes on your laptop, the automated "Undo Command" in Sunshine won't trigger. This leaves your physical monitors turned off (in hardware sleep mode) and Sunshine potentially in a bad state.

You can instantly recover your PC remotely by sending these commands from your laptop's terminal:

**1. Wake Up Both Physical Monitors:**

```bash
ssh void@100.117.73.75 "ddcutil -d 1 setvcp 0xd6 0x01 || true; ddcutil -d 2 setvcp 0xd6 0x01 || true"
```

**2. Restart the Sunshine Service:**

```bash
ssh void@100.117.73.75 "systemctl --user restart sunshine"
```

**(Highly Recommended) Create `fixstream` and `checkmonitors` Aliases:**
Bundle these commands into Fish aliases on your laptop for instant one-click access.

```fish
function fixstream
    echo "Waking monitors..."
    ssh void@100.117.73.75 "ddcutil -d 1 setvcp 0xd6 0x01 || true; ddcutil -d 2 setvcp 0xd6 0x01 || true"
    echo "Restarting Sunshine..."
    ssh void@100.117.73.75 "systemctl --user restart sunshine"
    echo "Recovery complete."
end
funcsave fixstream

function checkmonitors
    echo "Querying physical monitor power states..."
    ssh void@100.117.73.75 "ddcutil -d 1 getvcp d6 || true; ddcutil -d 2 getvcp d6 || true"
end
funcsave checkmonitors
```

---

## Your New Daily Workflow

* **From your Laptop (Anywhere):** Type `sshpc`.
  * If the PC is already on (locally or at home), you will instantly log in.
  * If the PC is off, Fish will automatically trigger `voidphone` to wake it up, wait for CachyOS and Tailscale to launch, and then log you in.
* **Stream Recovery:** Type `fixstream` from your laptop if Moonlight ever crashes and leaves your PC monitors turned off.
* **From your PC:** Type `sshlaptop` to instantly drop into your laptop's terminal.
* **X11 Forwarding (Optional):** If you ever need to launch a graphical application from one machine and display it on the other within your Niri/DMS environment, simply add `-Y` to your ssh commands (e.g., `ssh -Y <your_username>@100.117.73.75`).
