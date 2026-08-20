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

If this returns a version, you're good. If not, enable it via **one** of these methods:

**Method A (GUI):**
1. Open **Settings → Apps → Optional Features → Add a feature**.
2. Search for **OpenSSH Client** and install it.

**Method B (Terminal — faster):**
Open PowerShell **as Administrator** (right-click → "Run as administrator") and run:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

It will show a small loading bar at the top of the terminal. Once it finishes, it will print out `Online : True` and `RestartNeeded : False`.

After either method, **close that PowerShell window entirely and open a new one** so the environment variables refresh. You should now be able to run `ssh -V` successfully.

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

> [!WARNING]
> **Do NOT run `net use` in an Administrator PowerShell window.** Windows UAC (User Account Control) Token Splitting causes drives mapped in an elevated context to be invisible in File Explorer, which runs as a standard user.

Open a **normal (non-Admin)** PowerShell window and map the PC's SMB shares to drive letters. These will persist across reboots:

```powershell
# Map PC Home directory to Z:
net use Z: \\100.117.73.75\Home /persistent:yes /user:void

# Map PC Storage to Y:
net use Y: \\100.117.73.75\Storage /persistent:yes /user:void
```

Check **File Explorer → This PC** to verify the drives appear.

> **Tip:** If the PC is behind a firewall, ensure SMB (port 445) is allowed over Tailscale, or use `sshfs-win` as an alternative to native SMB shares (see Troubleshooting section 4.5).

**If drives were previously mapped from an Admin window**, clear the broken mappings first:

```powershell
net use * /delete /y
```

Then re-run the mapping commands above in a normal (non-Admin) shell.

#### Verify SMB Connectivity

If mapping returns errors like `The network path was not found` or `System error 53 / 67`, test whether the PC is actually reachable on port 445:

```powershell
Test-NetConnection -ComputerName 100.117.73.75 -Port 445
```

* **If `TcpTestSucceeded : False`:** Port 445 is blocked by a firewall, or Samba (`smbd`) is not running on your CachyOS PC.
* **If `TcpTestSucceeded : True`:** The port is open, but the share names `[Home]` / `[Storage]` might not be defined in your PC's `/etc/samba/smb.conf`.

#### Ensure Samba Is Active on CachyOS (If Not Already Configured)

On your **CachyOS PC terminal**, ensure Samba is installed and your user is added:

```fish
# 1. Install Samba
sudo pacman -S samba

# 2. Add your user to the Samba database and set a password
sudo smbpasswd -a void

# 3. Enable and start the Samba daemon
sudo systemctl enable --now smbd
```

#### Renaming Mapped Drives

By default, Windows File Explorer names mapped drives as **`ShareName (\\IP_Address) (DriveLetter:)`**. To rename them:

1. Right-click the drive in **This PC** (e.g., the **Storage** drive).
2. Click **Rename** (or press **F2**).
3. Type your preferred name (e.g., "PC Storage" or "Home") and press Enter.

Windows will remember your custom name while still pointing to the Tailscale IP in the background.

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

    # Strip the base path and convert the folder name into a safe Zellij session name
    $sessionName = ($target -replace '^/home/void/|^/mnt/Storage/', '') -replace '[^a-zA-Z0-9]', '_'
    if ([string]::IsNullOrWhiteSpace($sessionName)) { $sessionName = 'root_workspace' }

    Write-Host "Jumping to Zellij session [$sessionName] on PC at $target..." -ForegroundColor Cyan
    ssh -t void@100.117.73.75 "cd '$target' && exec zellij attach -c '$sessionName'"
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

    # 2. Attach using native Windows SSH (bypasses Xpra's MSYS2 SSH)
    Start-Process -NoNewWindow -FilePath "C:\Program Files\Xpra\Xpra.exe" -ArgumentList "attach", "ssh://void@100.117.73.75/100", "--ssh=`"C:\Windows\System32\OpenSSH\ssh.exe -o StrictHostKeyChecking=no`""

    Write-Host "Launching $AppCmd on Host PC at $target..." -ForegroundColor Cyan

    # 3. SSH in, point graphics to :100, and launch the app
    ssh -t void@100.117.73.75 "cd '$target' && export DISPLAY=:100 && exec fish -i -C '$AppCmd'"

    # 4. Clean up Xpra when done
    Get-Process -Name "Xpra" -ErrorAction SilentlyContinue | Stop-Process
}

function guipcz {
    $target = Get-PCTargetDir

    # Strip the base path and convert the folder name into a safe Zellij session name
    $sessionName = ($target -replace '^/home/void/|^/mnt/Storage/', '') -replace '[^a-zA-Z0-9]', '_'
    if ([string]::IsNullOrWhiteSpace($sessionName)) { $sessionName = 'root_workspace' }
    $sessionName = $sessionName + "_gui"

    Write-Host "Starting Xpra Graphics Tunnel..." -ForegroundColor Cyan

    ssh void@100.117.73.75 "xpra start :100 2>/dev/null"

    # Attach using native Windows SSH (bypasses Xpra's MSYS2 SSH)
    Start-Process -NoNewWindow -FilePath "C:\Program Files\Xpra\Xpra.exe" -ArgumentList "attach", "ssh://void@100.117.73.75/100", "--ssh=`"C:\Windows\System32\OpenSSH\ssh.exe -o StrictHostKeyChecking=no`""

    Write-Host "Jumping to Zellij GUI session [$sessionName] on PC at $target..." -ForegroundColor Cyan
    ssh -t void@100.117.73.75 "cd '$target' && export DISPLAY=:100 && exec zellij attach -c '$sessionName'"

    Get-Process -Name "Xpra" -ErrorAction SilentlyContinue | Stop-Process
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

> [!TIP]
> **Do not reload with `. $PROFILE`** if you have Oh My Posh installed — it will throw harmless but confusing red errors about duplicate key bindings. Instead, simply **close the PowerShell window and open a new one** to load the profile cleanly from scratch.

### 4.4 Usage (Identical Workflow)

The commands work exactly like their Linux counterparts. Open PowerShell, navigate into a mapped network drive, and run:

| Command | What it does |
|---|---|
| `jumppc` | SSH into the PC, landing in the translated folder |
| `jumppcz` | Attach to a **folder-specific** persistent Zellij session on the PC |
| `guipc pyraf` | Launch a specific GUI app on the PC with Xpra forwarding |
| `guipcz` | Folder-specific persistent Zellij session with GUI forwarding enabled |
| `wakepc` | Send a Wake-on-LAN magic packet to boot the PC |

> [!NOTE]
> **Dynamic session names:** `jumppcz` and `guipcz` automatically name each Zellij session after the folder you launch from. Opening Zellij in `Z:\Research\MESA_models` creates a session called `Research_MESA_models`, while `Z:\Downloads` creates `Downloads`. Each project gets its own independent, persistent workspace.

**Example — Resume a MESA simulation with plots:**

```powershell
# Navigate to the PC's project folder via the mapped drive
cd Z:\Research\MESA_models\my_star

# Attach to the GUI-enabled persistent session (auto-named "Research_MESA_models_my_star_gui")
guipcz
```

You'll land right back in your running Zellij session with MESA still going, and any `pgstar` plot windows will reappear on your Windows desktop via Xpra.

### 4.5 Managing Zellij Sessions

Because the functions use `zellij attach -c`, simply closing the PowerShell window or pressing `Ctrl+C` will only **detach** you from the session — it keeps running in the background on your CachyOS PC. This is intentional: your work is never lost if you close your laptop lid or lose connectivity.

To actually kill a session and free up memory, use one of these methods:

#### Method 1: Quick Kill (Inside the Session)

Press **`Ctrl + q`** while inside the Zellij session. This is Zellij's hard-quit command — it immediately terminates the workspace and all its panes.

#### Method 2: Traditional Exit (Inside the Session)

Type **`exit`** (or press **`Ctrl + d`**) in each terminal pane. Once the final pane closes, the session destroys itself.

#### Method 3: Remote Management (Outside the Session)

If you detached from a session and want to clean it up without re-entering it, manage sessions via SSH:

```powershell
# List all running Zellij sessions on the PC
ssh void@100.117.73.75 "zellij list-sessions"

# Kill a specific session by name
ssh void@100.117.73.75 "zellij kill-session Research_MESA_models_my_star"

# Nuclear option: kill ALL Zellij sessions on the PC
ssh void@100.117.73.75 "zellij kill-all-sessions"
```

> **Tip:** You can also run these `zellij kill` commands from inside a regular `jumppc` shell on the PC.

### 4.6 File Explorer Context Menu (Antigravity IDE)

On Linux, we added a Dolphin right-click menu entry in Part 2. On Windows, we achieve the same thing using Windows Registry entries and a small PowerShell "middleman" script that translates mapped drive paths into SSH remote URIs.

#### Step 1: Find Your Antigravity IDE Path

Locate the exact path to the Antigravity IDE executable:

1. Find the shortcut you use to launch it (Desktop or Start Menu).
2. Right-click it and select **Properties**.
3. Copy the path from the **Target** box.

> The default path is typically: `C:\Users\Yash\AppData\Local\Programs\Antigravity IDE\Antigravity IDE.exe`

#### Step 2: Create the Middleman Script

When you right-click a folder on a mapped network drive (like `Z:\Coursework`), Windows sends the literal drive letter path to the IDE. The IDE has no idea it should connect via SSH. This script intercepts the path, translates `Z:\` → `/home/void/` and `Y:\` → `/mnt/Storage/`, and launches the IDE in **Remote SSH mode**.

1. Open PowerShell and run:

```powershell
notepad C:\Users\Yash\Documents\Launch-Antigravity.ps1
```

2. Paste this code into Notepad:

```powershell
param([string]$path)

$exePath = "C:\Users\Yash\AppData\Local\Programs\Antigravity IDE\Antigravity IDE.exe"

# If the path is on the Z: or Y: drives, translate to the remote Linux path
if ($path -match "^Z:") {
    $linuxPath = $path -replace '^Z:', '/home/void' -replace '\\', '/'
    $remoteUri = "vscode-remote://ssh-remote+void@100.117.73.75$linuxPath"
    Start-Process -FilePath $exePath -ArgumentList "--folder-uri", "`"$remoteUri`""
}
elseif ($path -match "^Y:") {
    $linuxPath = $path -replace '^Y:', '/mnt/Storage' -replace '\\', '/'
    $remoteUri = "vscode-remote://ssh-remote+void@100.117.73.75$linuxPath"
    Start-Process -FilePath $exePath -ArgumentList "--folder-uri", "`"$remoteUri`""
}
else {
    # If it is a local C: drive folder, just open it normally
    Start-Process -FilePath $exePath -ArgumentList "`"$path`""
}
```

3. **Save** and close Notepad.

#### Step 3: Add the Registry Entries

Create a `.reg` file that adds "Open in Antigravity IDE" to the right-click menu for folders, folder backgrounds, and individual files.

1. Open Notepad and paste this code:

```registry
Windows Registry Editor Version 5.00

; 1. Right-click a folder
[HKEY_CLASSES_ROOT\Directory\shell\AntigravityIDE]
@="Open in Antigravity IDE"
"Icon"="\"C:\\Users\\Yash\\AppData\\Local\\Programs\\Antigravity IDE\\Antigravity IDE.exe\""

[HKEY_CLASSES_ROOT\Directory\shell\AntigravityIDE\command]
@="powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"C:\\Users\\Yash\\Documents\\Launch-Antigravity.ps1\" \"%1\""

; 2. Right-click the empty background inside a folder
[HKEY_CLASSES_ROOT\Directory\Background\shell\AntigravityIDE]
@="Open in Antigravity IDE"
"Icon"="\"C:\\Users\\Yash\\AppData\\Local\\Programs\\Antigravity IDE\\Antigravity IDE.exe\""

[HKEY_CLASSES_ROOT\Directory\Background\shell\AntigravityIDE\command]
@="powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"C:\\Users\\Yash\\Documents\\Launch-Antigravity.ps1\" \"%V\""

; 3. Right-click a specific file
[HKEY_CLASSES_ROOT\*\shell\AntigravityIDE]
@="Open in Antigravity IDE"
"Icon"="\"C:\\Users\\Yash\\AppData\\Local\\Programs\\Antigravity IDE\\Antigravity IDE.exe\""

[HKEY_CLASSES_ROOT\*\shell\AntigravityIDE\command]
@="powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"C:\\Users\\Yash\\Documents\\Launch-Antigravity.ps1\" \"%1\""
```

2. Save as `Antigravity_Context_Menu.reg` on your Desktop (set "Save as type" to **All Files**).
3. Double-click the `.reg` file and click **Yes** to apply.

#### Windows 11 Note

Windows 11 hides custom context menu entries behind the compact menu by default. To access the full menu:

* Right-click any file or folder → click **Show more options** at the bottom.
* Or hold **Shift** while right-clicking to skip directly to the full menu.

Your **Open in Antigravity IDE** entry will appear with its icon in the expanded menu.

> [!TIP]
> If you change your Antigravity IDE install path in the future, you only need to update the `$exePath` variable in `Launch-Antigravity.ps1` — the registry entries always point to the script, not the IDE directly.

---

### 4.7 Troubleshooting

#### Xpra: "Command Not Found" or "Not Recognized"

This error happens because Windows does not know where the `xpra` executable is located (it wasn't automatically added to your system's PATH during installation).

The corrected `guipc` and `guipcz` functions above already use the full explicit path (`C:\Program Files\Xpra\Xpra.exe`). If you still see this error, verify your Xpra install location:

```powershell
Get-ChildItem "C:\Program Files\Xpra\Xpra.exe"
```

If it's installed elsewhere, update the `-FilePath` parameter in both functions accordingly.

---

#### Xpra: "Permission Denied" or "Could not create directory /home/User/.ssh"

Xpra for Windows is compiled using **MSYS2**, a Linux-compatibility layer. When Xpra internally calls `ssh` to tunnel to the remote display, it triggers its own bundled Linux-style SSH — which looks for your keys in a non-existent `/home/YourUser/.ssh/` directory instead of your actual `C:\Users\YourUser\.ssh\` folder. Because it can't find your `id_ed25519` key, it throws "Permission denied".

The `guipc` and `guipcz` functions above already include the fix: the `--ssh` flag forces Xpra to use Microsoft's native OpenSSH client (`C:\Windows\System32\OpenSSH\ssh.exe`) instead of its bundled MSYS2 SSH. This ensures it reads your real Windows SSH keys.

To verify the fix manually, run this one-liner:

```powershell
& "C:\Program Files\Xpra\Xpra_cmd.exe" attach ssh://void@100.117.73.75/100 --ssh="C:\Windows\System32\OpenSSH\ssh.exe -o StrictHostKeyChecking=no"
```

If it connects without red errors, the fix is working. Leave it running, open a new PowerShell tab, and test with:

```powershell
ssh void@100.117.73.75 "export DISPLAY=:100 && alacritty"
```

---

#### Oh My Posh Errors When Reloading Profile

If you run `. $PROFILE` and see red errors about `Spacebar`, `Enter`, or `Ctrl+C` key bindings already being bound, this is a known bug with **Oh My Posh**. When you reload the profile, Oh My Posh tries to initialize itself a second time in the same session, and the duplicate bindings cause errors.

**The errors are harmless** — your functions still loaded correctly.

**How to avoid this:** Whenever you edit your `$PROFILE` and have Oh My Posh installed, simply **close the PowerShell window and open a new one**. A fresh window loads the profile cleanly without triggering the duplicate binding errors.

---

#### `jumppc` or `wakepc` Not Recognized After Restart

This usually happens because Windows has **two separate versions of PowerShell** with independent `$PROFILE` files:

| Version | Typical Profile Path |
|---|---|
| Windows PowerShell 5 | `~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` |
| PowerShell 7 | `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |

If the functions worked once (via `. $PROFILE`) but disappeared after restarting, you likely saved them into the wrong version's profile.

**Fix:**

1. Verify what your current PowerShell 7 profile contains:

```powershell
Get-Content $PROFILE
```

If it does not print your `jumppc` and `wakepc` functions, the code is missing from this profile.

2. Edit the correct profile directly from your current terminal:

```powershell
notepad $PROFILE
```

3. Scroll to the very bottom, paste the entire block of functions (from `Get-PCTargetDir` all the way through `wakepc`), save (Ctrl+S), and close Notepad.
4. Close the terminal and open a fresh one. `jumppc` should now be permanently recognized.

---

#### Mapped Drives Not Visible in File Explorer

See the UAC warning in section 4.2 above. The most common cause is mapping drives from an Administrator PowerShell window. Always use a **normal (non-Admin)** shell for `net use` commands.

---

#### Alternative to SMB: Mount via SSH (SSHFS-Win)

If you don't want to configure and maintain Samba on your CachyOS PC, you can mount folders directly over your existing SSH connection:

1. Install **WinFsp** and **SSHFS-Win** via winget in PowerShell:

```powershell
winget install BillZiss-Gh.WinFsp
winget install evil-shred.SSHFS-Win
```

2. In File Explorer, right-click **This PC → Map network drive**.
3. Choose drive letter `Z:` and enter this path (using your SSH key or password):

```text
\\sshfs.r\void@100.117.73.75\home\void
```

This maps your PC's home directory over the encrypted Tailscale SSH tunnel — no Samba configuration required.
