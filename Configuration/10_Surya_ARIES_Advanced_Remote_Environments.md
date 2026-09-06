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

## 5. Dolphin Context Menu Integration

To right-click any remote folder in Dolphin and open an instant terminal or Antigravity IDE on Surya or ARIES:

Create `~/.local/share/kio/servicemenus/remote_servers.desktop` on your Laptop and PC:

```ini
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=OpenSuryaTerminal;OpenARIESterminal;
X-KDE-Priority=TopLevel

[Desktop Action OpenSuryaTerminal]
Name=Open Surya HPC Terminal Here
Icon=utilities-terminal
Exec=fish -c 'jumpsurya "%f"'

[Desktop Action OpenARIESterminal]
Name=Open ARIES Terminal Here
Icon=utilities-terminal
Exec=fish -c 'jumparies "%f"'
```

Refresh Dolphin service menus:
```bash
kbuildsycoca6
```
