# ARIES Server Specifications & X2Go / Fastfetch Guide

Comprehensive guide containing the server hardware and OS specifications, diagnosis and resolution of the X2Go connection failure under Wayland, and how to install and run Fastfetch on CentOS 7 without root access.

---

## 1. Server System Specifications (`ARIES` / `172.18.1.5`)

### General & Operating System
* **Host Model:** HPE ProLiant DL380 Gen10
* **Hostname:** `ARIES`
* **Operating System:** CentOS Linux 7 (Core) x86_64
* **Kernel:** `Linux 3.10.0-1160.119.1.el7.x86_64`
* **Default Shell:** `/bin/csh` (C Shell)
* **Desktop Environments Available:** 
  * **XFCE 4.12** (via `xfce4-session` — optimal for remote desktop / X2Go)
  * **GNOME 3 / GNOME Classic**
* **System Uptime:** 172+ consecutive days
* **Active User Sessions:** ~31 researcher sessions

### CPU & Architecture
* **Processor Model:** Dual-Socket Intel(R) Xeon(R) Silver 4210 CPU @ 2.20GHz (Max Boost 3.20 GHz)
* **Topology:** 2 Sockets × 10 Cores = **20 Physical Cores**
* **Logical Threads:** **40 Threads** (Hyper-Threading enabled)
* **NUMA Nodes:** 2 Nodes (`Node 0: CPUs 0-9, 20-29` | `Node 1: CPUs 10-19, 30-39`)

### Memory (RAM) & Swap
* **Physical RAM:** **251.43 GiB** (~256 GB ECC DDR4)
  * Used: ~48 GiB
  * Available / Cache: ~203 GiB
* **Swap Space:** **128.00 GiB** (~102 GiB free)

### Storage & Filesystems
* **Root Partition (`/`):** **314 GB** SSD (`/dev/sda1`, ext4) — 185 GB used, 113 GB free (59% used)
* **Home Directory (`/home`):** **36.24 TiB** RAID Array (`/dev/sdb`, ext4 with user/group quotas) — ~28.17 TiB used, 6.3 TiB free (78% used)
* **Observation Data (`/1.3m_Data`):** **2.00 TiB** dedicated storage partition (`/dev/sdh1`)
* **Network Archive (`/observation_Data`):** NFS mount from `10.10.10.26:/Data_Archive_Aries`
* **GPU / Video Controller:** Matrox Electronics Systems Ltd. MGA G200eH3 (integrated server management/VGA controller)

---

## 2. Troubleshooting & Fixing the X2Go Client Error

### The Issue
When connecting to `shashi@172.18.1.5` with X2Go Client, an error dialog popped up:
> *"The remote proxy closed the connection while negotiating the session. This may be due to the wrong authentication credentials passed to the server."*

Standard SSH terminal connections worked completely fine with the password (`Aries#123$`).

### Root Cause Analysis
1. **Misleading Error Text:**  
   The message mentioning *"wrong authentication credentials"* is a generic fallback popup in X2Go Client whenever the internal `nxproxy` process terminates unexpectedly during session negotiation. SSH authentication actually succeeded.
2. **Wayland Compatibility Crash on Local PC (Primary Cause):**  
   The local machine runs a modern Wayland compositor (**niri**). By default, Qt5 applications run via `libQt5WaylandClient`. X2Go Client contains legacy X11 calls (`XDefaultRootWindow(QX11Info::display())`). Under native Wayland, `QX11Info::display()` returns `NULL`, causing `x2goclient` to crash with a **Segmentation Fault (SIGSEGV)** right as it attempts to initialize the session:
   ```
   Process 7506 (x2goclient) dumped core.
   #0  0x00007ffa54c92ed6 XDefaultRootWindow (libX11.so.6)
   #7  0x00007ffa4db15a0e (libQt5WaylandClient.so.5)
   ```
   This client crash instantly severed the SSH port-forwarding proxy tunnel, resulting in the error dialog.
3. **Stale Server-Side Session (Secondary Cause):**  
   An earlier session (`shashi-52-1787652321_stDXFCE_dp24`) on the server had encountered a network disconnect / display failure and was stuck in a hung "Suspended" state on display `:52`.

### The Solution

#### A. Client-Side Fix (Force Xwayland / X11 Backend)
X2Go Client must be instructed to run using Qt's `xcb` (X11 / Xwayland) platform plugin instead of native Wayland.

* **To run from Terminal:**
  ```bash
  QT_QPA_PLATFORM=xcb x2goclient
  ```

* **Permanent Fix for Desktop Launchers:**  
  Create or edit `~/.local/share/applications/x2goclient.desktop`:
  ```desktop
  [Desktop Entry]
  Version=1.0
  Type=Application
  Name=X2Go Client
  Exec=env QT_QPA_PLATFORM=xcb x2goclient
  Icon=x2goclient
  StartupWMClass=x2goclient
  X-Window-Icon=x2goclient
  X-Osso-Type=application/x-executable
  Terminal=false
  Categories=Qt;KDE;Network;
  Keywords=Terminal,Client,Remote,Desktop,Published,Applications,Session,Profile;
  MimeType=application/x-x2go;
  ```
  Update the desktop database:
  ```bash
  update-desktop-database ~/.local/share/applications
  ```

#### B. Server-Side Cleanup (No Root Required)
If an old session gets hung after a network drop or unexpected disconnection:
1. Log in via SSH:
   ```bash
   ssh shashi@172.18.1.5
   ```
2. Terminate any hung user sessions and clean temporary files:
   ```bash
   killall -u shashi x2goagent 2>/dev/null || true
   rm -rf /tmp/.x2go-shashi/*
   rm -rf ~/.x2go/C-*
   ```
3. When reconnecting in X2Go Client, if an old session appears in the list, click **Terminate** (Stop/Trash icon) or **New** instead of resuming a broken session.

---

## 3. How to Install & Run Fastfetch (Without Root Access)

CentOS 7 uses an older C standard library (**GLIBC 2.17**). Standard precompiled binaries from GitHub releases will fail with GLIBC version mismatch errors or missing musl dynamic linkers. 

The Fastfetch project provides an official **polyfilled** build compiled specifically for legacy Linux distributions with older GLIBC versions.

### Installation Steps (Executed in User Space)

Run the following commands in your terminal on the server:

```bash
# 1. Create a local bin directory if it doesn't already exist
mkdir -p ~/.local/bin /tmp/ff_install
cd /tmp/ff_install

# 2. Download the latest polyfilled release of Fastfetch
curl -sLO https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64-polyfilled.tar.gz

# 3. Extract the archive
tar -xzf fastfetch-linux-amd64-polyfilled.tar.gz

# 4. Copy the binary into ~/.local/bin
cp fastfetch-linux-amd64-polyfilled/usr/bin/fastfetch ~/.local/bin/
chmod +x ~/.local/bin/fastfetch

# 5. Clean up temporary files
cd ~
rm -rf /tmp/ff_install
```

### Making Sure `~/.local/bin` is in Your PATH

Because the default shell on the server is `/bin/csh`, ensure your `~/.cshrc` contains:
```csh
setenv PATH "$HOME/.local/bin:$PATH"
```

If using `bash`, ensure `~/.bashrc` contains:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Running Fastfetch

Simply run:
```bash
fastfetch
```

*(Fastfetch 2.68.1 has already been downloaded, verified, and installed into `/home/shashi/.local/bin/fastfetch` on the server).*

---

## 4. Using Fish Shell on Demand (Without Changing Default Shell)

You can use **Fish Shell** without making it your permanent default login shell. Keeping your default login shell as `/bin/csh` is actually recommended on this server to prevent breaking SSH batch jobs, X2Go session scripts, and MESA SDK initialization.

### How It Was Installed
The official Fish Shell project provides a standalone, statically linked binary for x86_64 Linux (no dependencies or glibc restrictions). It was installed directly into your user path:

```bash
mkdir -p ~/.local/bin /tmp/fish_install
cd /tmp/fish_install
curl -sLO https://github.com/fish-shell/fish-shell/releases/download/4.9.0/fish-4.9.0-linux-x86_64.tar.xz
tar -xJf fish-4.9.0-linux-x86_64.tar.xz
cp fish ~/.local/bin/
chmod +x ~/.local/bin/fish
rm -rf /tmp/fish_install
```

### How to Use It
Whenever you want to use Fish in an SSH or X2Go terminal:

1. **Enter Fish:**
   ```bash
   fish
   ```
2. **Use Fish normally:**  
   You will have all Fish features (auto-suggestions, syntax highlighting, completions, etc.).
3. **Exit back to your regular shell:**
   ```bash
   exit
   ```
   You will instantly return to your standard shell (`csh` or `bash`).

### Fixing Legacy Terminal Compatibility (CentOS 7 XFCE)
If you see strange escape codes like `[>4;1m` or overlapping/squished text:

1. **The `[>4;1m` Escape Artifact:**  
   Fish 4.x tries to enable XTerm's `modifyOtherKeys` mode (`\e[>4;1m`). Older VTE terminal libraries (like on CentOS 7) do not recognize this escape code and print it as raw text.  
   *Fix:* A wrapper script was placed at `~/.local/bin/fish` setting `export MC_SID=1`, which instructs Fish to skip unsupported keyboard protocol sequences for legacy terminals.

2. **Font Alignment / Overlapping Text:**  
   The default terminal in XFCE was using a proportional font (`Sans 10`) instead of a fixed-width monospace font, causing character overlapping and cursor misalignment.  
   *Fix:* Configured `~/.config/xfce4/terminal/terminalrc` with:
   ```ini
   [Configuration]
   FontName=DejaVu Sans Mono 11
   FontUseSystem=FALSE
   ```
   Opening a new terminal window will now display a clean, properly spaced monospace font.
