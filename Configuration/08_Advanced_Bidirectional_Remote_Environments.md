# Advanced Bidirectional Remote Environments

This guide provides the complete configuration for persistent remote sessions, smart path translation, IDE integration, and GUI application forwarding between your Laptop and PC.

## Overview of Capabilities

1. **Smart Path Translation**: If you browse a network share (e.g., `/mnt/PC_Home/Downloads`) on your laptop, the jump commands automatically translate that into the true absolute path (`/home/void/Downloads`) before SSHing into the remote machine.
2. **Persistent Sessions (Zellij)**: Never lose a running task if your connection drops or you close your laptop lid.
3. **IDE & Dolphin Integration**: Right-click any network folder to instantly open it in a remote terminal session or the Antigravity IDE.
4. **GUI Forwarding (Xpra)**: A hybrid solution to run legacy X11 GUI apps remotely onto a strict pure-Wayland desktop where standard SSH X11 forwarding fails.

---

## Part 1: Smart Fish Functions & Tunneling

These Fish functions are the engine of this setup. They handle wake-on-LAN, path translation, session attachment, and the invisible Xpra graphics tunnels.

### 1.1 Laptop Configuration (Targeting the PC)

Open your terminal on your **Laptop**, paste this entire block, and press Enter to save these functions:

```fish
function _get_pc_target_dir
    # Helper function to dynamically translate local mount paths to PC absolute paths
    if string match -q "/mnt/PC_Home*" $PWD
        set target_dir (string replace "/mnt/PC_Home" "/home/void" $PWD)
    else if string match -q "/mnt/PC_Storage*" $PWD
        set target_dir (string replace "/mnt/PC_Storage" "/mnt/Storage" $PWD)
    else if string match -q "/home/void*" $PWD
        set target_dir (string replace "/home/void" "/mnt/Laptop_Home" $PWD)
    else
        set target_dir "/home/void"
    end

    echo $target_dir
end

function jumppc
    set target_dir (_get_pc_target_dir)

    ping -c 1 -W 1 100.117.73.75 > /dev/null
    if test $status -ne 0
        echo "PC is offline. Sending Wake-on-LAN via voidphone..."
        wakepc
        echo "Waiting 30 seconds for PC to boot..."
        sleep 30
    end

    echo "Jumping to PC at $target_dir..."
    ssh -t void@100.117.73.75 "cd '$target_dir' && exec fish"
end

function jumppcz
    set target_dir (_get_pc_target_dir)

    ping -c 1 -W 1 100.117.73.75 > /dev/null
    if test $status -ne 0
        echo "PC is offline. Sending Wake-on-LAN..."
        wakepc
        sleep 30
    end

    echo "Jumping to Zellij session on PC at $target_dir..."
    ssh -t void@100.117.73.75 "cd '$target_dir' && exec zellij attach -c astro"
end

function guipc
    set app_cmd $argv[1]
    if test -z "$app_cmd"
        echo "Please specify a tool (e.g., guipc pyraf)"
        return 1
    end

    set target_dir (_get_pc_target_dir)

    ping -c 1 -W 1 100.117.73.75 > /dev/null
    if test $status -ne 0
        echo "PC is offline. Sending Wake-on-LAN..."
        wakepc; sleep 30
    end
  
    echo "Starting Xpra Graphics Tunnel..."
    # 1. Start a persistent invisible X11 display (:100) on the Host PC
    ssh void@100.117.73.75 "xpra start :100 2>/dev/null"
  
    # 2. Attach the laptop to that display in the background
    # We use GDK_BACKEND=x11 to prevent Niri scaling bugs
    env GDK_BACKEND=x11 xpra attach ssh://void@100.117.73.75/100 >/dev/null 2>&1 &
    set xpra_pid $last_pid
  
    echo "Launching $app_cmd on Host PC at $target_dir..."
    # 3. SSH in interactively, point the graphics to :100, and launch the CLI tool
    ssh -t void@100.117.73.75 "cd '$target_dir' && set -x DISPLAY :100 && exec fish -i -C '$app_cmd'"
  
    # 4. Clean up the background Xpra window grabber when you close the app
    kill $xpra_pid
end

function guipcz
    set target_dir (_get_pc_target_dir)

    ping -c 1 -W 1 100.117.73.75 > /dev/null
    if test $status -ne 0
        echo "PC is offline. Sending Wake-on-LAN..."
        wakepc; sleep 30
    end
  
    echo "Starting Xpra Graphics Tunnel..."
    ssh void@100.117.73.75 "xpra start :100 2>/dev/null"
  
    env GDK_BACKEND=x11 xpra attach ssh://void@100.117.73.75/100 >/dev/null 2>&1 &
    set xpra_pid $last_pid
  
    echo "Jumping to Zellij (GUI-enabled) session on PC at $target_dir..."
    ssh -t void@100.117.73.75 "cd '$target_dir' && set -x DISPLAY :100 && exec zellij attach -c astro_gui"
  
    kill $xpra_pid
end

funcsave _get_pc_target_dir jumppc jumppcz guipc guipcz
```

*(Note: Ensure you have `xpra` installed on both the laptop and the Host PC).*

### 1.2 PC Configuration (Targeting the Laptop)

These perform the exact reverse operations when jumping from your Host PC into your laptop.

Open your terminal on your **Host PC**, paste this block, and replace `<LAPTOP_TAILSCALE_IP>` with your laptop's actual Tailscale IP:

```fish
function _get_laptop_target_dir
    if string match -q "/mnt/Laptop_Home*" $PWD
        set target_dir (string replace "/mnt/Laptop_Home" "/home/void" $PWD)
    else if string match -q "/mnt/Storage*" $PWD
        set target_dir (string replace "/mnt/Storage" "/mnt/PC_Storage" $PWD)
    else if string match -q "/home/void*" $PWD
        set target_dir (string replace "/home/void" "/mnt/PC_Home" $PWD)
    else
        set target_dir "/home/void"
    end

    echo $target_dir
end

function jumplaptop
    set target_dir (_get_laptop_target_dir)

    echo "Jumping to Laptop at $target_dir..."
    ssh -t void@<LAPTOP_TAILSCALE_IP> "cd '$target_dir' && exec fish"
end

function jumplaptopz
    set target_dir (_get_laptop_target_dir)

    echo "Jumping to Zellij session on Laptop at $target_dir..."
    ssh -t void@<LAPTOP_TAILSCALE_IP> "cd '$target_dir' && exec zellij attach -c astro_laptop"
end

function guilaptop
    set app_cmd $argv[1]
    if test -z "$app_cmd"
        echo "Please specify a tool (e.g., guilaptop pyraf)"
        return 1
    end

    set target_dir (_get_laptop_target_dir)
  
    echo "Starting Xpra Graphics Tunnel to Laptop..."
    ssh void@<LAPTOP_TAILSCALE_IP> "xpra start :100 2>/dev/null"
  
    env GDK_BACKEND=x11 xpra attach ssh://void@<LAPTOP_TAILSCALE_IP>/100 >/dev/null 2>&1 &
    set xpra_pid $last_pid
  
    echo "Launching $app_cmd on Laptop at $target_dir..."
    ssh -t void@<LAPTOP_TAILSCALE_IP> "cd '$target_dir' && set -x DISPLAY :100 && exec fish -i -C '$app_cmd'"
  
    kill $xpra_pid
end

function guilaptopz
    set target_dir (_get_laptop_target_dir)
  
    echo "Starting Xpra Graphics Tunnel to Laptop..."
    ssh void@<LAPTOP_TAILSCALE_IP> "xpra start :100 2>/dev/null"
  
    env GDK_BACKEND=x11 xpra attach ssh://void@<LAPTOP_TAILSCALE_IP>/100 >/dev/null 2>&1 &
    set xpra_pid $last_pid
  
    echo "Jumping to Zellij (GUI-enabled) session on Laptop at $target_dir..."
    ssh -t void@<LAPTOP_TAILSCALE_IP> "cd '$target_dir' && set -x DISPLAY :100 && exec zellij attach -c astro_laptop_gui"
  
    kill $xpra_pid
end

funcsave _get_laptop_target_dir jumplaptop jumplaptopz guilaptop guilaptopz
```

---

## Part 2: Dolphin Context Menu Integration (Terminal & IDE)

We will now add a powerful right-click context menu in Dolphin. For terminal sessions, Dolphin simply launches the terminal and lets Fish handle the heavy lifting. For the IDE, we use string replacement in the `.desktop` file to feed the correct absolute remote path directly into the IDE's URI string.

### 2.1 On your Laptop (To open the PC)

Create the directory and the file:

```bash
mkdir -p ~/.local/share/kio/servicemenus/
nano ~/.local/share/kio/servicemenus/antiremote.desktop
```

Paste this configuration:

```ini
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=OpenRemote;
X-KDE-Priority=TopLevel

[Desktop Action OpenIDE]
Name=Open PC (Antigravity IDE) Here
Icon=vscode
Exec=bash -c 'target="%f"; if [[ "$target" == /mnt/PC_Home* ]]; then target="${target/\/mnt\/PC_Home/\/home\/void}"; elif [[ "$target" == /mnt/PC_Storage* ]]; then target="${target/\/mnt\/PC_Storage/\/mnt\/Storage}"; elif [[ "$target" == /home/void* ]]; then target="${target/\/home\/void/\/mnt\/Laptop_Home}"; else target="/home/void"; fi; antigravity-ide --folder-uri "vscode-remote://ssh-remote+void@100.117.73.75$target"'
```

Make it executable and register it with the system so it populates instantly:

```bash
chmod +x ~/.local/share/kio/servicemenus/antiremote.desktop
kbuildsycoca6
```

### 2.2 On your PC (To open the Laptop)

Create the directory and the file:

```bash
mkdir -p ~/.local/share/kio/servicemenus/
nano ~/.local/share/kio/servicemenus/antiremote_laptop.desktop
```

Paste this configuration (Replace `<LAPTOP_TAILSCALE_IP>` with your laptop's actual IP):

```ini
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=OpenRemote;
X-KDE-Priority=TopLevel

[Desktop Action OpenIDE]
Name=Open Laptop (Antigravity IDE) Here
Icon=vscode
Exec=bash -c 'target="%f"; if [[ "$target" == /mnt/Laptop_Home* ]]; then target="${target/\/mnt\/Laptop_Home/\/home\/void}"; elif [[ "$target" == /mnt/Storage* ]]; then target="${target/\/mnt\/Storage/\/mnt\/PC_Storage}"; elif [[ "$target" == /home/void* ]]; then target="${target/\/home\/void/\/mnt\/PC_Home}"; else target="/home/void"; fi; antigravity-ide --folder-uri "vscode-remote://ssh-remote+void@<LAPTOP_TAILSCALE_IP>$target"'
```

Make it executable and register it with the system so it populates instantly:

```bash
chmod +x ~/.local/share/kio/servicemenus/antiremote_laptop.desktop
kbuildsycoca6
```

---

## Part 3: Workflows & Usage Guide

### 3.1 Persistent Sessions & Auto-Resume (Zellij)

The `-c` flag in our smart functions (`zellij attach -c`) tells Zellij to "create this session if it doesn't exist, but **attach to it if it is already running.**"

If you are running a long process (like a MESA simulation) and you accidentally close your laptop lid or close the window:

1. The SSH connection drops.
2. Zellij notices the drop and instantly moves your active session into the background. Your simulation keeps running safely on the host machine.
3. **To resume:** Open a terminal and run `jump_pcz` (or `jump_laptopz`). You will instantly pop back into the active session exactly where you left off.

**How to Detach Gracefully (The Manual Way):**
If you want to leave the simulation running and close the terminal *cleanly* without abruptly killing the SSH connection:

1. Press **`Ctrl + o`** (This opens the orange Zellij command ring).
2. Press **`d`** (for **d**etach).
   You will be cleanly disconnected, and your local terminal will return to your prompt.

### 3.2 Running Remote GUI Apps in Wayland (Xpra)

Niri's strict pure-Wayland environment completely blocks standard SSH X11 forwarding because Wayland doesn't generate legacy `.Xauthority` cookies.

Our "Hybrid Xpra" functions (`guipc` and `guilaptop`) bypass this elegantly:

1. Your local machine tells the remote machine to silently create an invisible monitor (Display `:100`) using Xpra.
2. Your local machine attaches to that invisible monitor in the background.
3. Your local machine SSHs into the remote machine, links your terminal to Display `:100`, and runs your app (e.g., PyRAF).
4. The CLI text stays beautifully inside your local terminal (like Ghostty), but whenever the app tries to draw a plot or open a GUI window, Xpra intercepts the window and beams it directly to your Niri desktop.

**The Ultimate Test:**
Close your terminal and open a fresh one in a mounted network folder on your laptop. Run:

```bash
guipc pyraf
```

Once the `pyraf>` prompt appears in your terminal, type:

```iraf
!ds9 &
```

Because of this hybrid setup, PyRAF will think it's running natively on a local X11 machine, and Xpra will flawlessly beam the DS9 GUI window out to your Wayland desktop!

---

## Part 4: Windows Laptop Configuration (Targeting the PC)

This section covers replicating the full remote environment workflow from a **Windows laptop** that only has **Tailscale** configured. We will set up SSH, network shares, and PowerShell functions equivalent to every Fish function in Part 1.

> **Note:** Zellij does not need to be installed on Windows. It runs on the remote Linux PC — your Windows laptop only needs to SSH in and attach to the session.

### 4.1 Prerequisites

#### Enable OpenSSH Client

OpenSSH is built into Windows 10 (1809+) and Windows 11. Verify it's available by opening PowerShell and running:

```powershell
ssh -V
```

If this returns a version, you're good. If not, enable it:

1. Open **Settings → Apps → Optional Features → Add a feature**.
2. Search for **OpenSSH Client** and install it.

#### Set Up SSH Key Authentication

To avoid typing your password every time:

```powershell
# Generate a key pair (if you don't already have one)
ssh-keygen -t ed25519

# Copy your public key to the PC
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh void@100.117.73.75 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

#### Install Xpra (For GUI Forwarding)

Download and install the Xpra Windows client from [xpra.org](https://xpra.org/). After installation, ensure `xpra` is in your system PATH, or note the install path (typically `C:\Program Files\Xpra\`).

### 4.2 Map Network Shares as Drive Letters

Open PowerShell **as Administrator** and map the PC's SMB shares to drive letters. These will persist across reboots:

```powershell
# Map PC Home directory to Z:
net use Z: \\100.117.73.75\Home /persistent:yes /user:void

# Map PC Storage to Y:
net use Y: \\100.117.73.75\Storage /persistent:yes /user:void
```

> **Tip:** If the PC is behind a firewall, ensure SMB (port 445) is allowed over Tailscale, or use `sshfs-win` as an alternative to native SMB shares.

### 4.3 PowerShell Functions

Add these functions to your PowerShell profile so they are available in every terminal session.

Open your profile for editing:

```powershell
notepad $PROFILE
```

> If the file doesn't exist, PowerShell will prompt you to create it. Say **Yes**.

Paste the following entire block and save:

```powershell
function Get-PCTargetDir {
    $cwd = (Get-Location).Path

    if ($cwd -match '^Z:\\') {
        # Z: is mapped to PC's /home/void
        $target = $cwd -replace '^Z:\\', '/home/void/'
        $target = $target -replace '\\', '/'
    }
    elseif ($cwd -match '^Y:\\') {
        # Y: is mapped to PC's /mnt/Storage
        $target = $cwd -replace '^Y:\\', '/mnt/Storage/'
        $target = $target -replace '\\', '/'
    }
    else {
        $target = "/home/void"
    }

    # Clean up any trailing or double slashes
    $target = $target -replace '/$', ''
    $target = $target -replace '//', '/'
    return $target
}

function jumppc {
    $target = Get-PCTargetDir

    Write-Host "Jumping to PC at $target..." -ForegroundColor Cyan
    ssh -t void@100.117.73.75 "cd '$target' && exec fish"
}

function jumppcz {
    $target = Get-PCTargetDir

    Write-Host "Jumping to Zellij session on PC at $target..." -ForegroundColor Cyan
    ssh -t void@100.117.73.75 "cd '$target' && exec zellij attach -c astro"
}

function guipc {
    param([string]$AppCmd)

    if (-not $AppCmd) {
        Write-Host "Please specify a tool (e.g., guipc pyraf)" -ForegroundColor Red
        return
    }

    $target = Get-PCTargetDir

    Write-Host "Starting Xpra Graphics Tunnel..." -ForegroundColor Cyan

    # 1. Start the invisible X11 display on the PC
    ssh void@100.117.73.75 "xpra start :100 2>/dev/null"

    # 2. Attach the Windows laptop to that display in the background
    Start-Process -NoNewWindow -FilePath "xpra" -ArgumentList "attach", "ssh://void@100.117.73.75/100"

    Write-Host "Launching $AppCmd on Host PC at $target..." -ForegroundColor Cyan

    # 3. SSH in, point graphics to :100, and launch the app
    ssh -t void@100.117.73.75 "cd '$target' && export DISPLAY=:100 && exec fish -i -C '$AppCmd'"

    # 4. Clean up Xpra when done
    Get-Process -Name "xpra" -ErrorAction SilentlyContinue | Stop-Process
}

function guipcz {
    $target = Get-PCTargetDir

    Write-Host "Starting Xpra Graphics Tunnel..." -ForegroundColor Cyan

    ssh void@100.117.73.75 "xpra start :100 2>/dev/null"

    Start-Process -NoNewWindow -FilePath "xpra" -ArgumentList "attach", "ssh://void@100.117.73.75/100"

    Write-Host "Jumping to Zellij (GUI-enabled) session on PC at $target..." -ForegroundColor Cyan
    ssh -t void@100.117.73.75 "cd '$target' && export DISPLAY=:100 && exec zellij attach -c astro_gui"

    Get-Process -Name "xpra" -ErrorAction SilentlyContinue | Stop-Process
}

function wakepc {
    # Wake-on-LAN: Replace MAC_ADDRESS with your PC's actual MAC address
    $mac = "XX:XX:XX:XX:XX:XX"
    $macBytes = $mac -split '[:-]' | ForEach-Object { [byte]('0x' + $_) }
    $magicPacket = [byte[]](,0xFF * 6) + ($macBytes * 16)
    $udpClient = New-Object System.Net.Sockets.UdpClient
    $udpClient.Connect(([System.Net.IPAddress]::Broadcast), 9)
    $udpClient.Send($magicPacket, $magicPacket.Length) | Out-Null
    $udpClient.Close()
    Write-Host "Wake-on-LAN packet sent!" -ForegroundColor Green
}
```

After saving, reload your profile:

```powershell
. $PROFILE
```

### 4.4 Usage (Identical Workflow)

The commands work exactly like their Linux counterparts. Open PowerShell, navigate into a mapped network drive, and run:

| Command | What it does |
|---|---|
| `jumppc` | SSH into the PC, landing in the translated folder |
| `jumppcz` | Attach to a persistent Zellij session on the PC |
| `guipc pyraf` | Launch a specific GUI app on the PC with Xpra forwarding |
| `guipcz` | Persistent Zellij session with GUI forwarding enabled |
| `wakepc` | Send a Wake-on-LAN magic packet to boot the PC |

**Example — Resume a MESA simulation with plots:**

```powershell
# Navigate to the PC's project folder via the mapped drive
cd Z:\Research\MESA_models\my_star

# Attach to the GUI-enabled persistent session
guipcz
```

You'll land right back in your running Zellij session with MESA still going, and any `pgstar` plot windows will reappear on your Windows desktop via Xpra.

> **Important:** Replace `XX:XX:XX:XX:XX:XX` in the `wakepc` function with your PC's actual MAC address. You can find it by running `ip link` on your PC.
