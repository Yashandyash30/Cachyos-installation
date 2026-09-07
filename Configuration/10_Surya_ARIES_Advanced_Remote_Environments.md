# Advanced Remote Environments: Surya HPC & ARIES
*(Generalized Jump Functions, Live GUI Forwarding & Persistent Zellij with GUI)*

This guide provides the complete bidirectional configuration for **Surya HPC** (`192.168.4.1`) and **ARIES** (`172.18.1.5`), modeled directly on [08_Advanced_Bidirectional_Remote_Environments.md](file:///home/void/Cachyos-installation/Configuration/08_Advanced_Bidirectional_Remote_Environments.md).

It works for **any** terminal command or GUI tool (e.g., `pyraf`, `ds9`, `gtburst`, `rmfit`, `mesa`, `python`, `top`) from your **Laptop** or **PC**.

---

## 1. Capabilities Overview

1. **Smart Path Translation**: If browsing remote network shares or mounts in Dolphin, jump commands translate local paths to the server's absolute paths.
2. **Instant Clean Login**: Bypasses slow server `/etc/profile` scripts (`--noprofile`), connecting in **~1.2 seconds** flat.
3. **Live GUI Windows (`guisurya` / `guiaries`)**: Uses Trusted X11 Forwarding (`ssh -Y`) so remote GUI apps project directly onto your local CachyOS Niri desktop.
4. **Persistent Sessions (`jumpsuryaz` / `jumpariesz`)**: Detachable Zellij sessions that keep your jobs running safely even if your Wi-Fi drops or your laptop lid is closed.
5. **Persistent Zellij WITH GUI (`guisuryaz` / `guiariesz`)**: Allows you to connect to a persistent Zellij session with live GUI display sync.

---

## 2. Persistent Zellij with GUI: How It Works

### The Core Problem with SSH X11 + Multiplexers
When you connect with standard `ssh -Y server`, SSH sets `DISPLAY=localhost:10.0`. When your laptop disconnects or you close your lid:
1. The SSH connection closes, and `localhost:10.0` is destroyed.
2. If an active GUI application attempts to refresh or draw against dead `:10.0`, it crashes.
3. When you re-connect later with `ssh -Y server`, your new SSH session is assigned a *new* display (e.g., `localhost:11.0`), but any existing shells inside Zellij still point to the dead `:10.0`.

### The Solution: Dynamic Display Sync Hook
To enable persistent Zellij with live GUI:

1. **When connecting with `guisuryaz` or `guiariesz`:**
   Your local function forwards your active display and writes it to a state file on the server:
   ```bash
   echo $DISPLAY > ~/.current_display
   ```
2. **Inside any Zellij pane:**
   Whenever you reconnect from your laptop or PC, simply run:
   ```bash
   sync_gui
   ```
   *(This executes `export DISPLAY=$(cat ~/.current_display)`, immediately updating that pane to point to your laptop's new screen).*
3. **Alternative for 100% Disconnect-Proof Windows (X2Go):**
   If you have a GUI window (like an active DS9 image or MESA PGSTAR plot) that must **never close even while you are disconnected**, run it inside an **X2Go Desktop Session** (`server_specs_and_x2go_guide.md`). In X2Go, the X11 server runs on the server itself, keeping windows rendered in memory indefinitely.

---

## 3. Command Reference

All functions are installed and available immediately on both your **Laptop** and **PC**:

| Command | Server | GUI Support | Persistence | Description |
| :--- | :--- | :---: | :---: | :--- |
| `jumpsurya [dir]` | Surya HPC | No | No | Instant clean interactive shell |
| `jumpsuryaz [session] [dir]` | Surya HPC | No | **Yes (Zellij)** | Detachable background session |
| `guisurya <cmd> [dir]` | Surya HPC | **Yes (Live X11)** | No | Run GUI tools (`ds9`, `pyraf`, `mesa26`) |
| `guisuryaz [session] [dir]` | Surya HPC | **Yes (Live X11)** | **Yes (Zellij)** | Persistent Zellij with GUI support |
| `jumparies [dir]` | ARIES | No | No | Instant clean interactive shell |
| `jumpariesz [session] [dir]` | ARIES | No | **Yes (Zellij)** | Detachable background session |
| `guiaries <cmd> [dir]` | ARIES | **Yes (Live X11)** | No | Run GUI tools (`gtburst`, `rmfit`, `mesa23`) |
| `guiariesz [session] [dir]` | ARIES | **Yes (Live X11)** | **Yes (Zellij)** | Persistent Zellij with GUI support |

---

## 4. Usage Examples

### Example 1: Run Live Astronomy GUI Tools
```fish
# Open DS9 on Surya HPC
guisurya ds9

# Run PyRAF on Surya HPC in a specific project folder
guisurya pyraf /home/yashsharma/photometry

# Open Fermi gtburst GUI on ARIES
guiaries gtburst

# Run rmfit spectral fitting on ARIES
guiaries rmfit
```

### Example 2: Start a Long Job in Persistent Zellij with GUI
```fish
# 1. Jump into a persistent GUI-enabled Zellij session on ARIES
guiariesz astro_run

# 2. Inside Zellij, start your simulation or Python script:
python long_analysis.py &

# 3. Open a live plot
ds9 &

# 4. Detach cleanly:
# Press Ctrl + o, then press d.
# (Your SSH session closes, but python and your session stay running on ARIES!)

# 5. Reconnect later from Laptop or PC:
guiariesz astro_run

# 6. If you want to open a new plot window from an existing pane:
sync_gui
ds9 &
```

---

## 5. Dolphin Context Menu Integration (Terminal & Antigravity IDE)

Modeled directly on [08_Advanced_Bidirectional_Remote_Environments.md](file:///home/void/Cachyos-installation/Configuration/08_Advanced_Bidirectional_Remote_Environments.md), you can right-click any directory in Dolphin (whether browsing local paths, mounts like `/mnt/Surya` / `/mnt/ARIES`, or KIO `sftp://` URLs) to instantly open an interactive terminal or the Antigravity IDE directly connected over SSH.

### 5.1 Service Menu File (`remote_servers.desktop`)

Saved at `~/.local/share/kio/servicemenus/remote_servers.desktop` on both **PC** and **Laptop**:

```ini
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=OpenSuryaTerminal;OpenSuryaIDE;OpenARIESterminal;OpenARIESide;
X-KDE-Priority=TopLevel

[Desktop Action OpenSuryaTerminal]
Name=Open Surya HPC Terminal Here
Icon=utilities-terminal
Exec=bash -c 'target="%u"; [ -z "$target" ] && target="%f"; target="${target#file://}"; if [[ "$target" =~ ^sftp://[^/]+(/.*)$ ]]; then target="${BASH_REMATCH[1]}"; elif [[ "$target" == /mnt/Surya* ]]; then target="${target/\/mnt\/Surya/\/home\/yashsharma}"; elif [[ "$target" == /home/yashsharma* ]]; then target="$target"; elif [[ "$target" == /home/void* ]]; then target="${target/\/home\/void/\/home\/yashsharma}"; else target="/home/yashsharma"; fi; ghostty -e fish -c "jumpsurya \"$target\"; exec fish"'

[Desktop Action OpenSuryaIDE]
Name=Open Surya HPC (Antigravity IDE) Here
Icon=vscode
Exec=bash -c 'target="%u"; [ -z "$target" ] && target="%f"; target="${target#file://}"; if [[ "$target" =~ ^sftp://[^/]+(/.*)$ ]]; then target="${BASH_REMATCH[1]}"; elif [[ "$target" == /mnt/Surya* ]]; then target="${target/\/mnt\/Surya/\/home\/yashsharma}"; elif [[ "$target" == /home/yashsharma* ]]; then target="$target"; elif [[ "$target" == /home/void* ]]; then target="${target/\/home\/void/\/home\/yashsharma}"; else target="/home/yashsharma"; fi; antigravity-ide --folder-uri "vscode-remote://ssh-remote+surya$target"'

[Desktop Action OpenARIESterminal]
Name=Open ARIES Terminal Here
Icon=utilities-terminal
Exec=bash -c 'target="%u"; [ -z "$target" ] && target="%f"; target="${target#file://}"; if [[ "$target" =~ ^sftp://[^/]+(/.*)$ ]]; then target="${BASH_REMATCH[1]}"; elif [[ "$target" == /mnt/ARIES* ]]; then target="${target/\/mnt\/ARIES/\/home\/shashi}"; elif [[ "$target" == /home/shashi* ]]; then target="$target"; elif [[ "$target" == /home/void* ]]; then target="${target/\/home\/void/\/home\/shashi}"; else target="/home/shashi"; fi; ghostty -e fish -c "jumparies \"$target\"; exec fish"'

[Desktop Action OpenARIESide]
Name=Open ARIES (Antigravity IDE) Here
Icon=vscode
Exec=bash -c 'target="%u"; [ -z "$target" ] && target="%f"; target="${target#file://}"; if [[ "$target" =~ ^sftp://[^/]+(/.*)$ ]]; then target="${BASH_REMATCH[1]}"; elif [[ "$target" == /mnt/ARIES* ]]; then target="${target/\/mnt\/ARIES/\/home\/shashi}"; elif [[ "$target" == /home/shashi* ]]; then target="$target"; elif [[ "$target" == /home/void* ]]; then target="${target/\/home\/void/\/home\/shashi}"; else target="/home/shashi"; fi; antigravity-ide --folder-uri "vscode-remote://ssh-remote+aries$target"'
```

### 5.2 Smart Path Translation Logic

- **SFTP URL (`sftp://...`)**: When browsing remote servers via Dolphin's KIO worker, extracts the true absolute server path.
- **Mounts (`/mnt/Surya*` / `/mnt/ARIES*`)**: Dynamically translates local mount paths into `/home/yashsharma` or `/home/shashi`.
- **Local Paths**: If right-clicking a local folder or outside mounts, smoothly defaults to the user's remote home directory.

### 5.3 Apply & Refresh

To register changes with KDE sycoca:
```bash
kbuildsycoca6
```

### 5.4 CentOS 7 GLIBC 2.28 Compatibility Layer & Auto-Patch Hook

Modern Antigravity IDE / VS Code Remote-SSH requires `glibc >= 2.28`. Because CentOS 7 natively provides `glibc 2.17`, both **ARIES** and **Surya HPC** have been configured with a user-space AlmaLinux 8 `glibc 2.28` and `patchelf` inside `~/local/glibc/`. 

#### 1. Self-Healing Hook (Automated on Updates)
To ensure future Antigravity IDE updates never break the connection, a self-healing check is installed at the top of `~/.bashrc` on both **ARIES** and **Surya HPC**:

```bash
# === Antigravity IDE Auto-Patch Hook (CentOS 7 GLIBC 2.28 Compatibility) ===
if [ -d "$HOME/.antigravity-ide-server/bin" ] && [ -x "$HOME/bin/patchelf" ]; then
    for node_bin in "$HOME"/.antigravity-ide-server/bin/*/node; do
        if [ -f "$node_bin" ] && [ ! -f "$node_bin.patched" ]; then
            "$HOME/bin/patchelf" \
                --set-interpreter "$HOME/local/glibc/usr/lib64/ld-linux-x86-64.so.2" \
                --set-rpath "$HOME/local/glibc/usr/lib64" \
                "$node_bin" 2>/dev/null && touch "$node_bin.patched"
        fi
    done
fi
# ===========================================================================
```
Whenever Antigravity IDE connects via SSH, this hook executes in ~5ms. If a newly downloaded server runtime from an update is detected, it automatically patches `node` on the fly before launching.

#### 2. Manual Pre-Sync Command (`patch_remote_ide`)
Available on both your **PC** and **Laptop**:
```fish
patch_remote_ide
```
This single command detects your newest local Antigravity IDE server version and syncs/patches it immediately to both ARIES and Surya HPC in seconds.
