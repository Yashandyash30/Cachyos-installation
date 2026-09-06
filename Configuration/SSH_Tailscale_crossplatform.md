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

4. **Send keys to voidphone (Run on BOTH PC and Laptop):**

This ensures your `sshphone` alias works instantly without a password prompt.

```bash
ssh-copy-id -p 8022 u0_a183@100.103.187.97
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

## Phase 5: Windows Laptop Setup

This section covers setting up SSH and PowerShell aliases on a **Windows laptop** so it participates in the same Tailscale mesh as your Linux machines.

> **Prerequisite:** Install and sign into [Tailscale for Windows](https://tailscale.com/download/windows) first. Your PC's Tailscale IP (`100.117.73.75`) will work identically from Windows.

### 5.1 Enable OpenSSH Client

OpenSSH is built into Windows 10 (1809+) and Windows 11. Verify it by opening PowerShell and running:

```powershell
ssh -V
```

If this returns a version, skip ahead. If not, enable it via **one** of these methods:

**Method A (GUI):**

1. Open **Settings → Apps → Optional Features → Add a feature**.
2. Search for **OpenSSH Client** and install it.

**Method B (Terminal — faster):**
Open PowerShell **as Administrator** and run:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

It will show a loading bar and print `Online : True` when finished.

After either method, **close the PowerShell window and open a new one** so the environment refreshes.

### 5.2 Passwordless Login (SSH Keys)

```powershell
# Generate a key pair (if you don't already have one)
ssh-keygen -t ed25519
```

*(Press Enter for all prompts to accept defaults and skip the passphrase).*

Copy your public key to the PC:

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh void@100.117.73.75 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

Copy your key to voidphone (for `phonebattery` and other phone aliases):

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh -p 8022 u0_a183@100.103.187.97 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 5.3 PowerShell Aliases

Add these functions to your PowerShell profile so they are available in every terminal session.

Open your profile for editing:

```powershell
notepad $PROFILE
```

> If the file doesn't exist, PowerShell will prompt you to create it. Say **Yes**.

Paste the following entire block and save:

```powershell
# ─── Wake-on-LAN ───────────────────────────────────────────────
function wakepc {
    # Replace XX:XX:XX:XX:XX:XX with your PC's actual MAC address
    $mac = "XX:XX:XX:XX:XX:XX"
    $macBytes = $mac -split '[:-]' | ForEach-Object { [byte]('0x' + $_) }
    $magicPacket = [byte[]](,0xFF * 6) + ($macBytes * 16)
    $udpClient = New-Object System.Net.Sockets.UdpClient
    $udpClient.Connect(([System.Net.IPAddress]::Broadcast), 9)
    $udpClient.Send($magicPacket, $magicPacket.Length) | Out-Null
    $udpClient.Close()
    Write-Host "Wake-on-LAN packet sent!" -ForegroundColor Green
}

# ─── SSH to PC (with auto-wake) ────────────────────────────────
function sshpc {
    $ping = Test-Connection -ComputerName 100.117.73.75 -Count 1 -Quiet
    if (-not $ping) {
        Write-Host "PC is offline. Sending Wake-on-LAN..." -ForegroundColor Yellow
        wakepc
        Write-Host "Waiting 30 seconds for PC to boot and connect to Tailscale..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    }
    Write-Host "Connecting to PC..." -ForegroundColor Cyan
    ssh void@100.117.73.75
}

# ─── Phone Battery Check ───────────────────────────────────────
function phonebattery {
    Write-Host "Querying voidphone..." -ForegroundColor Cyan
    $json = ssh -p 8022 u0_a183@100.103.187.97 "termux-battery-status"
    $bat = $json | ConvertFrom-Json
    Write-Host "Battery Level: $($bat.percentage)%"
    Write-Host "Status: $($bat.status)"
}

# ─── Stream Recovery ───────────────────────────────────────────
function fixstream {
    Write-Host "Waking monitors..." -ForegroundColor Cyan
    ssh void@100.117.73.75 "ddcutil -d 1 setvcp 0xd6 0x01 || true; ddcutil -d 2 setvcp 0xd6 0x01 || true"
    Write-Host "Restarting Sunshine..." -ForegroundColor Cyan
    ssh void@100.117.73.75 "systemctl --user restart sunshine"
    Write-Host "Recovery complete." -ForegroundColor Green
}

function checkmonitors {
    Write-Host "Querying physical monitor power states..." -ForegroundColor Cyan
    ssh void@100.117.73.75 "ddcutil -d 1 getvcp d6 || true; ddcutil -d 2 getvcp d6 || true"
}
```

> [!TIP]
> **Do not reload with `. $PROFILE`** if you have Oh My Posh installed — it will throw harmless but confusing red errors about duplicate key bindings. Instead, simply **close the PowerShell window and open a new one** to load the profile cleanly.

> [!IMPORTANT]
> Replace `XX:XX:XX:XX:XX:XX` in the `wakepc` function with your PC's actual MAC address. Find it by running `ip link` on your CachyOS PC.

> **Note:** For the full set of advanced functions (smart path translation, Zellij sessions, Xpra GUI forwarding, and network drive mapping), see the [Advanced Bidirectional Remote Environments](file:///home/void/Cachyos-installation/Configuration/08_Advanced_Bidirectional_Remote_Environments.md) guide (Part 4).

---

## Your New Daily Workflow

### From a Linux Laptop (Fish)

* Type `sshpc` — auto-wakes the PC if needed, then connects.
* Type `sshsurya` — connects directly to Surya HPC (`192.168.4.1`).
* Type `ssharies` — connects directly to ARIES server (`172.18.1.5`).
* Type `fixstream` — recovers crashed Moonlight streams.
* Type `phonebattery` — checks voidphone battery level.
* Type `transfer pc <file>` — sends files to your PC over Tailscale with live progress.
* Type `transfer surya <file>` — sends scientific datasets/archives to Surya HPC.
* Type `transfer aries <file>` — sends files to ARIES server.

### From a Windows Laptop (PowerShell)

* Type `sshpc` — identical behavior: auto-wakes, waits, and connects.
* Type `sshsurya` — connects to Surya HPC cluster.
* Type `ssharies` — connects to ARIES CentOS server.
* Type `fixstream` — same stream recovery over Tailscale.
* Type `phonebattery` — same phone battery check via Termux API.
* Type `wakepc` — sends a standalone Wake-on-LAN packet.
* Type `checkmonitors` — queries physical monitor power states.

### From your PC (Fish)

* Type `sshlaptop` — instantly drops into your laptop's terminal.
* Type `sshsurya` — connects directly to Surya HPC (`192.168.4.1`).
* Type `ssharies` — connects directly to ARIES server (`172.18.1.5`).
* Type `transfer laptop <file>` — sends files to your Laptop over Tailscale.
* Type `transfer surya <file>` — sends files directly to Surya HPC.
* Type `transfer aries <file>` — sends files to the ARIES server.

### X11 Forwarding (Optional)

If you ever need to launch a graphical application from one Linux machine and display it on the other within your Niri/DMS environment, add `-Y` to your ssh commands (e.g., `ssh -Y void@100.117.73.75`). For Windows GUI forwarding, see the Xpra setup in the [Advanced Remote Environments guide](file:///home/void/Cachyos-installation/Configuration/08_Advanced_Bidirectional_Remote_Environments.md).

---

## Phase 5: Surya HPC (ARIES) Cluster Configuration

Surya is the high-performance computing cluster at ARIES (Aryabhatta Research Institute of Observational Sciences). It runs CentOS Linux 7 on dual Intel Xeon Gold 6226R processors (32 physical cores, 188 GB ECC RAM) with XFCE desktop and X2Go support.

### Cluster Details

| Setting                         | Value                                         |
| :------------------------------ | :-------------------------------------------- |
| **Internal IP**           | `192.168.4.1`                               |
| **Hostname**              | `surya` / `surya.aries.res.in`            |
| **Default User**          | `yashsharma`                                |
| **Default Shell**         | `bash`                                      |
| **Desktop Environment**   | `XFCE` (`/usr/bin/xfce4-session`)         |
| **Remote Desktop Server** | `X2Go Server` (`/usr/bin/x2gostartagent`) |

> [!NOTE]
> Public DNS (such as Google `8.8.8.8` or Cloudflare WARP `1.1.1.1`) cannot resolve internal institute hostnames like `surya`. Direct IP (`192.168.4.1`) or local SSH/hosts mappings must be used.

---

### 1. Passwordless SSH Setup

Install your existing local ED25519 public key onto Surya so you never have to type your password:

```bash
ssh-copy-id yashsharma@192.168.4.1
```

*(Enter your cluster password one last time).*

---

### 2. OpenSSH Client Host Configuration (`~/.ssh/config`)

Add Surya to your `~/.ssh/config` file. This enables `ssh surya`, `scp file surya:~`, and system-wide tooling integration:

```ssh
Host surya
    HostName 192.168.4.1
    User yashsharma
    IdentityFile ~/.ssh/id_ed25519
    ForwardX11 yes
```

---

### 3. Fish Shell Function (`sshsurya`)

Run the following in your local Fish shell to create a persistent shortcut that supports passing arguments (e.g. `sshsurya -X` or `sshsurya "free -h"`):

```fish
function sshsurya --description 'SSH into Surya HPC cluster'
    ssh yashsharma@192.168.4.1 $argv
end
funcsave sshsurya
```

---

### 4. Windows PowerShell Function (`sshsurya`)

Add this function to `$PROFILE` on your Windows laptop:

```powershell
function sshsurya {
    ssh yashsharma@192.168.4.1 $args
}
```

---

### 5. Remote GUI Access via X2Go

To run an interactive desktop session (XFCE) over the network:

1. **Launch X2Go Client on Wayland/Niri:**
   ```bash
   QT_QPA_PLATFORM=xcb x2goclient
   ```
2. **Session Configuration:**
   * **Host:** `192.168.4.1`
   * **Login:** `yashsharma`
   * **SSH Port:** `22`
   * **Session Type:** `XFCE`
3. Click the session card to connect.

*(For fast single-app GUI forwarding without launching the full desktop, simply use `sshsurya -Y <app_name>`).*

---

## Phase 6: ARIES Server (`172.18.1.5`) Configuration

ARIES is the scientific analysis server (CentOS 7, 40 threads, 256 GB RAM) hosting Fermitools, 3ML, XSPEC, and VegasAfterglow pipelines.

### 1. Passwordless SSH Setup

Copy your local SSH public key to ARIES:

```bash
ssh-copy-id shashi@172.18.1.5
```

*(Enter `Aries#123$` one last time).*

### 2. OpenSSH Client Host Configuration (`~/.ssh/config`)

Configured in `~/.ssh/config`:

```ssh
Host aries
    HostName 172.18.1.5
    User shashi
    IdentityFile ~/.ssh/id_ed25519
    ForwardX11 yes
```

### 3. Fish Shell Function (`ssharies`)

Installed at `~/.config/fish/functions/ssharies.fish` on both PC and Laptop:

```fish
function ssharies --description 'SSH into ARIES server'
    ssh shashi@172.18.1.5 $argv
end
```

### 4. Windows PowerShell Function (`ssharies`)

Add this function to `$PROFILE` on your Windows laptop:

```powershell
function ssharies {
    ssh shashi@172.18.1.5 $args
}
```

---

## Phase 7: Universal Cross-Machine File Transfer Function (`transfer`)

The `transfer` function provides a unified command across all your machines (PC, Laptop, Surya HPC, and ARIES) using `rsync` over SSH. It displays a real-time progress bar, transfer rate, supports resuming interrupted downloads, and handles single or multiple files in batches.

### 1. Fish Shell Function (`~/.config/fish/functions/transfer.fish`)

This function is installed on both your **PC** and **Laptop**, and backed up in [Dotfiles/fish/functions/transfer.fish](file:///home/void/Cachyos-installation/Dotfiles/fish/functions/transfer.fish):

```fish
function transfer --description "Transfer files/directories to pc, laptop, or surya via rsync"
    if test (count $argv) -lt 2
        echo "Usage: transfer <pc|laptop|surya|aries> <file1> [file2...] [destination_folder/]"
        echo ""
        echo "Examples:"
        echo "  transfer surya mesasdk-x86_64-linux-23.7.3.tar.gz"
        echo "  transfer surya mesasdk-x86_64-linux-23.7.3.tar.gz mesa-r23.05.1.zip"
        echo "  transfer laptop document.pdf"
        echo "  transfer pc report.tar.gz Desktop/"
        return 1
    end

    set -l target (string lower $argv[1])
    set -l remote_user_host ""
    set -l cur_host (hostname)

    switch $target
        case pc
            if test "$cur_host" = "void-pc"
                echo "Error: You are already on PC ($cur_host)."
                return 1
            end
            set remote_user_host "void@100.117.73.75"

        case laptop
            if test "$cur_host" = "void"
                echo "Error: You are already on Laptop ($cur_host)."
                return 1
            end
            set remote_user_host "void@100.70.236.70"

        case surya
            set remote_user_host "yashsharma@192.168.4.1"

        case aries
            set remote_user_host "shashi@172.18.1.5"

        case '*'
            echo "Error: Unknown target '$target'. Supported: pc, laptop, surya, aries"
            return 1
    end

    # Determine files vs optional destination directory
    set -l files
    set -l dest_path "~/"

    # If the last argument does not exist locally and there are > 2 args, treat as remote destination path
    if test (count $argv) -gt 2 -a ! -e "$argv[-1]"
        set dest_path "$argv[-1]"
        set files $argv[2..-2]
    else
        set files $argv[2..-1]
    end

    # Validate source files exist
    for f in $files
        if not test -e "$f"
            echo "Error: Cannot find local file or directory '$f'"
            return 1
        end
    end

    echo "Transferring to $target ($remote_user_host:$dest_path)..."
    rsync -ahP $files "$remote_user_host:$dest_path"
end
```

### 2. Fish Autocompletion (`~/.config/fish/completions/transfer.fish`)

Enables tab autocompletion for target hostnames (`pc`, `laptop`, `surya`, `aries`) and local files:

```fish
complete -c transfer -n "__fish_is_first_arg" -a "pc laptop surya aries" -d "Target host"
complete -c transfer -n "not __fish_is_first_arg" -F
```

### 3. Usage Reference Table

| Command Example                 | Source      | Target Host                   | Default Destination | Key Use Case                                                      |
| :------------------------------ | :---------- | :---------------------------- | :------------------ | :---------------------------------------------------------------- |
| `transfer surya <file>`       | PC / Laptop | Surya HPC (`192.168.4.1`)   | `~/`              | Transfer MESA archives, simulation datasets, or scripts to Surya  |
| `transfer surya <f1> <f2>`    | PC / Laptop | Surya HPC (`192.168.4.1`)   | `~/`              | Batch transfer multiple files in a single operation               |
| `transfer surya <file> MESA/` | PC / Laptop | Surya HPC (`192.168.4.1`)   | `~/MESA/`         | Transfer directly into a specific folder on Surya                 |
| `transfer laptop <file>`      | PC          | Laptop (`100.70.236.70`)    | `~/`              | Transfer documents or code to Laptop over Tailscale               |
| `transfer pc <file>`          | Laptop      | PC (`100.117.73.75`)        | `~/`              | Transfer files to PC over Tailscale (LAN speed when on same WiFi) |
| `transfer aries <file>`       | PC / Laptop | ARIES Server (`172.18.1.5`) | `~/`              | Transfer Fermi / 3ML fits files to ARIES CentOS server            |

> [!TIP]
> `transfer` automatically runs with `rsync -ahP`. If a transfer is ever interrupted (e.g. WiFi drops or terminal closes), simply re-run the exact same command to resume from where it stopped without restarting from 0%.
