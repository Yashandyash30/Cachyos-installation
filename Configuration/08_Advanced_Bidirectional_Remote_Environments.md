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
