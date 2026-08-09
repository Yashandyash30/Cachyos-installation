# Voidphone Master Guide: Remote Management & Containerized Command Center

This comprehensive guide merges your remote management tools, Wake-on-LAN (WoL) capabilities, and an always-on containerized Uptime Kuma dashboard into a single, cohesive workflow for your Android phone (**`voidphone`**), CachyOS PC, and CachyOS Laptop.

---

## Phase 1: Android Phone (`voidphone`) Foundation

### 1. Install Termux & Core Tools
Download and install **Termux** (from F-Droid). Open Termux and install the essential packages, including `proot-distro` for your isolated Linux environment:

```bash
pkg update && pkg upgrade -y
pkg install openssh wol fish sudo arp-scan proot-distro -y
```

Set a password for your SSH access:

```bash
passwd
```

### 2. Set Fish as Your Default Shell
Tell Termux to always open in Fish instead of Bash:

```bash
chsh -s fish
```
Now, type `fish` and press Enter to switch to it for the next steps.

### 3. Configure Prompt & Network Scanner
Run these commands inside your new Fish shell to set up your custom prompt and background services.

**Set the custom `voidphone` prompt:**
```fish
function fish_prompt
    set_color green; echo -n "voidphone"
    set_color normal; echo -n ":"
    set_color blue; echo -n (prompt_pwd)
    set_color normal; echo -n '$ '
end
funcsave fish_prompt
```

**Add your `scanlan` alias for network discovery:**
```fish
function scanlan
    sudo arp-scan -I wlan0 --localnet
end
funcsave scanlan
```

**Auto-start SSH on manual Termux launch:**
```fish
mkdir -p ~/.config/fish
echo 'if not pgrep -x sshd > /dev/null; sshd; end' >> ~/.config/fish/config.fish
source ~/.config/fish/config.fish
```

---

## Phase 2: Create the Containerized Dashboard

We will use `proot-distro` to create an isolated, standard Ubuntu server environment to run Node.js without Termux compiler limits.

### 1. Install the Ubuntu Container
In your Termux Fish shell:
```fish
proot-distro install ubuntu
proot-distro login ubuntu
```
*(Your prompt will change—you are now operating inside the Ubuntu environment).*

### 2. Install Uptime Kuma
Run these commands while logged into the Ubuntu container to install Node.js 20 and setup the dashboard:

```bash
apt update && apt install curl git ca-certificates -y
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install nodejs -y

git clone https://github.com/louislam/uptime-kuma.git
cd uptime-kuma
npm run setup
```

Once finished, exit the container to return to Termux:
```bash
exit
```

---

## Phase 3: The Unified Auto-Boot Script

We need to tell the **Termux:Boot** app to automatically wake up the CPU, start your SSH server, and launch the Ubuntu container silently in the background whenever the phone restarts.

### 1. Create the Script
Install **Termux:Boot** (from F-Droid) and open it once from your app drawer so Android registers it. Run this inside Termux:

```fish
mkdir -p ~/.termux/boot/
cat << 'EOF' > ~/.termux/boot/start-services.sh
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
nohup proot-distro login ubuntu -- bash -c "cd ~/uptime-kuma && node server/server.js --port=3001" > ~/uptime-kuma-server.log 2>&1 &
EOF
```

### 2. Make it Executable & Start
```fish
chmod +x ~/.termux/boot/start-services.sh
~/.termux/boot/start-services.sh
```
*(Click on **wakelock** when expanding the Termux notification from the Android status bar).*

---

## Phase 4: Network & Android Configuration

### 1. Install and Configure Tailscale
* Install **Tailscale** from the Play Store or F-Droid and log in.
* Go to the [Tailscale Admin Console](https://login.tailscale.com/admin/machines) in a browser, rename your phone to **`voidphone`**. *(Note its Tailscale IP, e.g., `100.103.187.97`).*
* In Android **Settings** > **Network & Internet** > **VPN**, tap the gear icon next to Tailscale and enable **Always-on VPN**.

### 2. Enable USB Debugging
In Android **Developer Options**, turn on **USB Debugging** so your computers can interface with it over a physical USB cable.

---

## Phase 5: Uptime Kuma First-Time Setup

Grab your laptop or PC, ensure Tailscale is connected, and open your web browser to **`http://100.103.187.97:3001`** *(replace with your phone's Tailscale IP if different)*.

**1. Initial Configuration:**
* **Database:** Select **SQLite** (Ultra-lightweight and perfect for mobile containers).
* Create your admin username and password.

**2. Add Your Core Network Monitors (Ping):**
Click **+ Add New Monitor** and change the **Monitor Type** to **Ping**:
* **Target 1:** CachyOS PC (Hostname: `100.117.73.75`, Heartbeat: 60)
* **Target 2:** CachyOS Laptop (Hostname: *Your laptop's Tailscale IP*, Heartbeat: 60)
* **Target 3:** Institute Wi-Fi Gateway (Hostname: `172.21.3.254`, Heartbeat: 60)

**3. Add Your SSH Service Monitors (TCP Port):**
To ensure your SSH services are actively listening and haven't crashed, monitor their specific TCP ports.
Click **+ Add New Monitor** and change the **Monitor Type** to **TCP Port**:
* **Target 1: CachyOS PC SSH**
  * Friendly Name: CachyOS PC - SSH
  * Hostname: `100.117.73.75`
  * Port: `22`
  * Heartbeat Interval: 60
* **Target 2: voidphone SSH**
  * Friendly Name: voidphone - SSH
  * Hostname: `100.103.187.97`
  * Port: `8022`
  * Heartbeat Interval: 60

Just hit **Save** once you enter those, and your dashboard will immediately start monitoring your actual remote access connections!

---

## Phase 6: Target Devices Setup (PC & Laptop)

### 1. CachyOS PC Setup (The Target)
**Enable Wake-on-LAN (BIOS & OS):**
* Enable **Wake on LAN** (or PCI-E Wake) in your motherboard BIOS.
* Enable WoL in the OS:
```bash
sudo pacman -S ethtool tailscale
sudo ethtool -s enp2s0 wol g
nmcli connection modify "Wired connection 1" 802-3-ethernet.wake-on-lan magic
```

**Tailscale & Dynamic Phone Alias:**
```bash
sudo systemctl enable --now tailscaled
sudo tailscale up
```
Open your Fish terminal and create the `phone` alias:
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

### 2. CachyOS Laptop Setup (The Commander)
Install Tailscale:
```bash
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```

**Dynamic Phone & Remote Wake Aliases:**
Paste these into your laptop's Fish terminal:
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

function wakepc
    ssh u0_a183@100.103.187.97 -p 8022 "wol f0:4e:a4:37:91:66"
end
funcsave wakepc
```

---

## Daily Maintenance & Workflow

* **Network Scanning:** Type `scanlan` on the phone to map connected devices.
* **Phone Management (USB):** Plug phone into PC/Laptop and type `phone`.
* **Phone Management (Wireless):** From anywhere via Tailscale, type `phone wifi`.
* **Remote PC Wakeup:** From the laptop, type `wakepc`. Wait 15–30s for the PC to boot and connect to Tailscale, then SSH into it via `100.117.73.75`.
* **Dashboard Logs:** To view live Uptime Kuma logs, run `cat ~/uptime-kuma-server.log` on the phone.
* **Verify Container:** Run `pgrep -a proot` on the phone to ensure the container is active.
