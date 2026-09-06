# Surya HPC (ARIES) Cluster Setup & User Guide

Comprehensive guide covering system specifications, resolving the `bash` ➔ `fish` startup loop, configuring Fish shell on demand, Fastfetch installation, X2Go remote desktop access, Dolphin remote network folder browsing, and scientific software setup on the ARIES Surya HPC cluster.

---

## 1. System Hardware & Cluster Specifications

| Parameter | Specification |
| :--- | :--- |
| **Hostname** | `surya` / `surya.aries.res.in` |
| **Internal IP** | `192.168.4.1` (Interface `eno7`) |
| **Location** | ARIES Datacenter, Haldwani / Nainital |
| **Operating System** | CentOS Linux 7 (Core) x86_64 |
| **Kernel** | `Linux 3.10.0-1160.31.1.el7.x86_64` |
| **C Standard Library** | `GLIBC 2.17` |
| **Processors (Main Node)** | 2× Intel(R) Xeon(R) Gold 6226R @ 2.90 GHz (3.90 GHz Max Turbo) |
| **Total Cores / Threads** | **32 Physical Cores** (16 cores/socket, 2 sockets) |
| **System Memory (RAM)** | **188.41 GiB DDR4 Registered ECC** (~176 GiB available) |
| **Swap Space** | **64.00 GiB** |
| **Root Partition (`/`)** | **816 GiB** ext4 (17% used, ~680 GiB free) |
| **Applications (`/apps`)**| **1.82 TiB** xfs (Cluster shared software modules) |
| **Home Storage (`/home`)**| **41.84 TiB** xfs shared RAID (**94% full** — ~2.7 TiB remaining) |
| **Desktop Environment** | **XFCE 4.12** (`/usr/bin/xfce4-session`) & GNOME Classic |
| **Remote Display Server** | **X2Go Server** (`/usr/bin/x2gostartagent`) |

---

## 2. Why Typing `bash` Immediately Re-enters `fish` (And How to Fix It)

### Root Cause
When you ran `bash`, you noticed **Fastfetch** ran immediately and the prompt returned to `yashsharma@surya ~>` (Fish prompt).

This happens because `~/.bashrc` (or `~/.bash_profile`) contains lines like:
```bash
fastfetch
exec fish   # or simply 'fish'
```

Because `~/.bashrc` runs **every single time** a new Bash subshell starts, Bash reads the file, executes `fastfetch`, and then immediately replaces itself with `fish` via `exec fish`.

### How to Check It
On Surya, run:
```bash
grep -n -E "fish|fastfetch" ~/.bashrc ~/.bash_profile ~/.profile
```

### The Fix

You have two clean options depending on your preference:

#### Option A: Run Fish on Demand (Recommended on HPC Clusters)
Keep your base interactive shell as **Bash** (essential for running Conda, cluster submission scripts, and build environments), and only start Fish when you want it interactively:

1. Open `~/.bashrc`:
   ```bash
   nano ~/.bashrc
   ```
2. Remove or comment out the `exec fish` (or `fish`) line. Leave `fastfetch` if you like seeing system stats on login.
3. Save with `Ctrl+O`, `Enter`, and exit with `Ctrl+X`.
4. Now, typing `bash` stays in Bash. Whenever you want Fish, simply run:
   ```bash
   fish
   ```
   And return to Bash anytime with:
   ```bash
   exit
   ```

#### Option B: Auto-launch Fish on Login WITHOUT Looping Subshells
If you want Fish to open automatically when you first log in via SSH, but **NOT** when you explicitly type `bash` or run bash scripts:

Replace the raw `exec fish` in `~/.bashrc` with this guard condition:
```bash
# Only launch fish in interactive login sessions, never in nested bash subshells or non-interactive scripts
if [[ $- == *i* && -z "$IN_NESTED_BASH" && -x "$(which fish 2>/dev/null)" ]]; then
    exec fish
fi
```
Then, whenever you need a pure Bash shell from Fish, you can run:
```fish
env IN_NESTED_BASH=1 bash
```
This tells Bash to bypass the auto-Fish trigger!

---

## 3. Remote Desktop Access (GUI via X2Go)

Surya has **X2Go Server** installed with the lightweight **XFCE 4.12** desktop environment.

### Connection Parameters
* **Host:** `192.168.4.1`
* **Login:** `yashsharma`
* **SSH Port:** `22`
* **Session Type:** **XFCE**

### Wayland Client Crash Workaround (Local PC)
If your local Linux workstation runs Wayland (e.g. Niri, Sway, GNOME Wayland), X2Go Client will crash with a segmentation fault under native Wayland. Always launch it using the X11/Xwayland platform plugin:

```bash
QT_QPA_PLATFORM=xcb x2goclient
```

### Quick Single-App X11 Forwarding
To launch a single GUI application (e.g. `ds9`, `topcat`, `xclock`) without a full desktop session, connect using the trusted X11 flag:
```bash
ssh -Y yashsharma@192.168.4.1
```

---

## 4. Remote File Browsing via Dolphin (KDE Network / Remote Location)

Rather than mounting Surya as a local folder in your home directory (which clutters `~/` and causes hangs if the network drops), you can add Surya directly into KDE Dolphin's native **"Remote"** network view using SFTP. This leaves **zero local footprint** in `~/` and connects on-demand.

### 4.1 Setup on Local Machines (PC & Laptop)

KDE stores network locations in `~/.local/share/remoteview/`. Create the desktop link entry:

```bash
mkdir -p ~/.local/share/remoteview
cat << 'EOF' > ~/.local/share/remoteview/Surya_HPC.desktop
[Desktop Entry]
Icon=folder-remote
Name=Surya HPC
Type=Link
URL=sftp://yashsharma@192.168.4.1/home/yashsharma
EOF
```

To sync this from your PC to your Laptop over Tailscale:
```bash
scp ~/.local/share/remoteview/Surya_HPC.desktop void@100.70.236.70:~/.local/share/remoteview/
```

### 4.2 How to Access in Dolphin

1. Open **Dolphin**.
2. Look at the left sidebar under the **"Remote"** category and click **"Network"** (or press `Ctrl + L` and type `remote:/`).
3. **Surya HPC** appears listed there with a remote server folder icon.
4. Double-click it to browse `/home/yashsharma` directly over SFTP.

### 4.3 Pin Directly to Dolphin Sidebar ("Remote" Group)

To make Surya accessible in the sidebar with a single click:

1. Inside Dolphin's **Network** view, right-click on the **"Surya HPC"** icon.
2. Select **"Add to Places"**.
3. In Dolphin's left sidebar, drag the new **Surya HPC** entry directly under the **"Remote"** section header.

*(Now clicking "Surya HPC" in your sidebar loads your remote cluster files instantly without mounting anything to your local disk).*

---

## 5. Software Environment & Module Management

Surya uses the **Environment Modules** system for cluster-wide scientific packages and compilers.

### Useful Module Commands
```bash
# List all pre-installed software modules
module avail

# Load a specific software stack (e.g. GCC 11 or Intel oneAPI)
module load compilers/gcc/11.2.0

# Check currently loaded modules
module list

# Unload / reset loaded modules
module purge
```

### Modern Python via Miniforge3 (Recommended)
Because CentOS 7 uses `GLIBC 2.17`, standard modern system packages cannot be installed via `yum`. Miniforge3 provides modern Python (3.10 / 3.11 / 3.12) with compatibility for CentOS 7:

```bash
# 1. Download and install Miniforge
curl -sLO https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p $HOME/miniforge3
rm -f Miniforge3-Linux-x86_64.sh

# 2. Initialize for bash
$HOME/miniforge3/bin/conda init bash
source ~/.bashrc

# 3. Critical: Prevent timeout on ARIES firewall
conda config --set repodata_use_shards false
```

---

## 6. Storage Quota & Housekeeping

* **Current Status:** `/home` is at **94% capacity** cluster-wide (~2.7 TB available).
* **Check Your Personal Usage:**
  ```bash
  du -sh $HOME
  ```
* **Find Heavy Directories:**
  ```bash
  du -h --max-depth=1 $HOME | sort -hr
  ```
* **Clean Package Caches Periodically:**
  ```bash
  conda clean -a -y
  ```
