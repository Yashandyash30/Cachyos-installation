# Persistent Remote Environments (Advanced Path-Translating Setup)

This guide provides the complete, advanced configuration for bidirectional persistent remote sessions between your Laptop and PC.

It includes **Smart Path Translation**, meaning if you are browsing your PC's network drive (`/mnt/PC_Home/Downloads`) on your laptop, firing the jump command will automatically translate that path into `/home/void/Downloads` and SSH directly into that exact folder on the PC.

---

## Phase 1: The Smart Fish Functions (Laptop)

These functions belong on your **Laptop**. They handle waking the PC if it is offline, translating KSMBD network paths (`/mnt/PC_Home` and `/mnt/PC_Storage`) into their true absolute paths on the PC, and jumping into Zellij.

Open your terminal on your laptop, paste this entire block, and press Enter:

```fish
function _get_pc_target_dir
    # Helper function to dynamically translate local mount paths to PC absolute paths
    set target_dir $PWD

    if string match -q "/mnt/PC_Home*" $PWD
        set target_dir (string replace "/mnt/PC_Home" "/home/void" $PWD)
    else if string match -q "/mnt/PC_Storage*" $PWD
        set target_dir (string replace "/mnt/PC_Storage" "/mnt/Storage" $PWD)
    end

    echo $target_dir
end

function jump_pc
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

function jump_pcz
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

funcsave _get_pc_target_dir jump_pc jump_pcz
```

---

## Phase 2: The Smart Fish Functions (PC)

These functions belong on your **Host PC**. They perform the exact reverse path translation (translating `/mnt/Laptop_Home` to `/home/void`) when jumping into your laptop.

Open your terminal on your PC, paste this block, and replace `<LAPTOP_TAILSCALE_IP>` with your laptop's actual Tailscale IP:

```fish
function _get_laptop_target_dir
    set target_dir $PWD

    if string match -q "/mnt/Laptop_Home*" $PWD
        set target_dir (string replace "/mnt/Laptop_Home" "/home/void" $PWD)
    end

    echo $target_dir
end

function jump_laptop
    set target_dir (_get_laptop_target_dir)

    echo "Jumping to Laptop at $target_dir..."
    ssh -t void@<LAPTOP_TAILSCALE_IP> "cd '$target_dir' && exec fish"
end

function jump_laptopz
    set target_dir (_get_laptop_target_dir)

    echo "Jumping to Zellij session on Laptop at $target_dir..."
    ssh -t void@<LAPTOP_TAILSCALE_IP> "cd '$target_dir' && exec zellij attach -c astro_laptop"
end

funcsave _get_laptop_target_dir jump_laptop jump_laptopz
```

---

## Phase 3: Dolphin Context Menu Integration (Terminal & IDE)

We will now add a powerful right-click context menu in Dolphin.
For terminal sessions (`jump_pc` and `jump_pcz`), Dolphin simply tells the terminal to launch and let Fish handle the heavy lifting.
For the Antigravity IDE, we must use raw bash string replacement within the `.desktop` file to feed the correct absolute remote path directly into the IDE's URI string.

### 1. On your Laptop (To jump to the PC)

Create the directory and the file:

```bash
mkdir -p ~/.local/share/kio/servicemenus/
nano ~/.local/share/kio/servicemenus/antiremote.desktop
```

Paste this configuration (Replace `kitty` with your preferred terminal, like `alacritty` or `konsole`, if needed):

```ini
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=OpenRemote;
X-KDE-Priority=TopLevel

[Desktop Action OpenIDE]
Name=Open PC (Antigravity IDE) Here
Icon=vscode
Exec=bash -c 'target="%f"; if [[ "$target" == /mnt/PC_Home* ]]; then target="${target/\/mnt\/PC_Home/\/home\/void}"; elif [[ "$target" == /mnt/PC_Storage* ]]; then target="${target/\/mnt\/PC_Storage/\/mnt\/Storage}"; fi; antigravity-ide --folder-uri "vscode-remote://ssh-remote+void@100.117.73.75$target"'
```

Make it executable:

```bash
chmod +x ~/.local/share/kio/servicemenus/antiremote.desktop
```

### 2. On your PC (To jump to the Laptop)

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
Exec=bash -c 'target="%f"; if [[ "$target" == /mnt/Laptop_Home* ]]; then target="${target/\/mnt\/Laptop_Home/\/home\/void}"; fi; antigravity-ide --folder-uri "vscode-remote://ssh-remote+void@<LAPTOP_TAILSCALE_IP>$target"'
```

Make it executable:

```bash
chmod +x ~/.local/share/kio/servicemenus/antiremote_laptop.desktop
```

---

## Phase 4: Session Management & Auto-Resume

### 1. How to Resume (The Automatic Way)

The `-c` flag in `zellij attach -c` tells Zellij to "create this session if it doesn't exist, but **attach to it if it is already running.**"

If you are running a MESA simulation on your PC and you accidentally close your laptop lid or click the "X" on the window:

1. The SSH connection drops.
2. Zellij notices the drop and instantly moves your active session into the background. Your simulation keeps running.
3. **To resume:** Open Dolphin, right-click the folder, and select **"Open PC (Persistent Zellij) Here"** (or type `jump_pcz` in a terminal). You will instantly pop back into the active session exactly where you left off.

### 2. How to Detach Gracefully (The Manual Way)

If you want to leave the simulation running and close the terminal *cleanly* without abruptly killing the SSH connection:

1. Press **`Ctrl + o`** (This opens the orange Zellij command ring).
2. Press **`d`** (for **d**etach).

You will be cleanly disconnected, and your local terminal will return to your prompt.
