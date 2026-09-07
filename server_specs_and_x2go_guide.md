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

#### C. Fixing Frozen & Uncloseable "Ghost Windows" in Niri (`xwayland-satellite`)

##### The Symptom
The X2Go remote desktop window suddenly freezes into a static picture. When you try to close it:
* Keyboard shortcuts (`Mod+Q` / `close-window`) are completely ignored.
* Running `killall -9 x2goclient nxproxy` in a terminal outputs `no process found`, but the frozen window frame remains stuck on your desktop.

##### Root Cause Analysis
1. **Buffer Desync during Tiling / Fullscreen:**  
   Niri is a scrolling/tiling Wayland compositor. X2Go's client window encapsulates a full nested X11 root display (`nxproxy`). Whenever Niri rearranges columns, resizes tiles, or shifts focus, it floods `xwayland-satellite` with `ConfigureNotify` events. `nxproxy` attempts to renegotiate display geometry across the network to ARIES. If this roundtrip lags or if the window is placed in Fullscreen mode, `xwayland-satellite` loses frame synchronization with Xwayland's surface, freezing the display buffer.
2. **Orphaned Wayland Surface ("Ghost Window"):**  
   If `x2goclient` dies ungracefully or terminates while the socket is blocked, `xwayland-satellite` continues holding the dead X11 surface attached to Niri. When Niri sends `close-window`, it asks `xwayland-satellite` to emit an X11 `WM_DELETE_WINDOW` signal. Because the underlying client process is already dead, no one receives the signal, and `xwayland-satellite` never unmaps the surface—leaving a permanent visual "ghost" on screen.

##### Emergency Fix (Instantly Clear the Stuck Window)
Run this single command in your local terminal on your laptop/PC:

```bash
pkill -9 -f xwayland-satellite
```

> [!IMPORTANT]
> **Why `-f` is required:** Under Linux, process names stored in `/proc/$PID/comm` are limited to **15 characters**. The name `xwayland-satellite` is 18 characters long. Running plain `pkill xwayland-satellite` will fail to match and do nothing. The `-f` flag tells `pkill` to match against the full command-line string.
>
> Killing `xwayland-satellite` instantly destroys all orphaned X11 surfaces without harming Niri or your native Wayland applications (Ghostty, Zen, Dolphin, IDE). Niri will automatically respawn a clean `xwayland-satellite` instance when the next X11 application launches.

##### Preventing Freezes in Niri
If you need to use X2Go on Niri, apply these two safeguards:

1. **Add a Floating Window Rule in Niri:**  
   Prevent Niri from dynamically resizing and applying blur/shaders to X2Go:
   In `~/.config/niri/config.kdl`:
   ```kdl
   window-rule {
       match app-id=r"^x2go"
       match app-id=r"^X2GO"
       open-floating true
       opacity 1.0
   }
   ```
2. **Lock X2Go to Fixed Resolution (Never use Fullscreen):**  
   In X2Go Client ➔ Session Preferences ➔ **Input/Output**:
   * Set display to a fixed custom resolution (e.g. `1920x1080` or `1600x900`).
   * **Uncheck** *"Resize remote screen to local window"*.
   * Avoid triggering Fullscreen mode.

##### Best Practice: Avoid Remote Desktop for Jupyter & Terminal Work
For developing, coding, or data science on ARIES, remote desktop sessions are unnecessary and prone to network latency. Use native Wayland tooling instead:
* **Jupyter Notebooks:** Run headless on ARIES and forward via SSH tunnel to your local Zen browser (`tunnelaries`). Runs at 240Hz with 0 latency (see [Section 7](#7-installing--running-jupyter-notebook--jupyterlab-on-aries)).
* **Terminals & Scripts:** Use native terminal (`ghostty`) via `ssh aries` or persistent Zellij (`jumpariesz`).
* **Astronomical GUI Apps (DS9, MESA, RMFIT):** Forward only the application window using `guiaries <command>`.

#### D. Fixing "Connection failed. CondaError: Run 'conda init' before 'conda deactivate'"

##### The Symptom
When attempting to connect to ARIES with X2Go Client, an error dialog immediately aborts the connection:
> *"Connection failed. CondaError: Run 'conda init' before 'conda deactivate' CondaError: Run 'conda init' before 'conda deactivate'"*

##### Root Cause Analysis
1. **SSHD Execution of Remote Commands:**  
   When X2Go negotiates a session, it executes non-interactive SSH commands on ARIES (e.g. `x2golistsessions`, `x2gostartagent`).
2. **Missing Non-Interactive Guard in `~/.bashrc`:**  
   When bash is invoked by an incoming SSH connection, it reads `~/.bashrc`. Because `~/.bashrc` lacked an interactive guard (`[[ $- != *i* ]] && return`), it automatically executed `conda initialize`, activating the `(base)` environment and setting `CONDA_PROMPT_MODIFIER="(base) "`.
3. **Intel oneAPI Environment Conflict (`setvars.sh`):**  
   The server's system-wide `/etc/profile.d/soft.sh` automatically calls Intel oneAPI's `. /opt/intel/oneapi/setvars.sh`. Intel's internal script (`vars.sh`) checks if a Conda environment is active (`CONDA_PROMPT_MODIFIER`). If active, it attempts to run `conda deactivate` in a loop so IntelPython does not conflict with Conda.
4. **Shell Function Missing in Subshells:**  
   In a non-interactive SSH subshell, `conda` is not defined as a shell function—it is invoked directly as the standalone binary `/home/shashi/miniforge3/bin/conda`. When the raw binary is invoked with `deactivate`, it throws:
   ```text
   CondaError: Run 'conda init' before 'conda deactivate'
   ```
5. **X2Go Protocol Desynchronization:**  
   X2Go monitors the SSH stream expecting strict internal protocol strings (e.g. `X2GODATABEGIN:`). Because `CondaError` was written to stderr/stdout before X2Go's protocol output, X2Go treated the entire handshake as a failure and showed the popup.

##### The Permanent Solution (Applied to ARIES)
Prepend an interactive check at the **very first line** of `/home/shashi/.bashrc` on ARIES:

```bash
# Non-interactive guard (Prevents X2Go, SFTP, and SSH protocol pollution)
[[ $- != *i* ]] && return
```

* **For non-interactive SSH / X2Go commands:** `~/.bashrc` immediately returns without running Conda initialization, keeping the SSH data stream completely silent and error-free.
* **For interactive shells (terminal logins):** The check passes normally, and all Conda environments, aliases, and paths initialize as usual.

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

If you see strange escape codes like `[>4;1m` or overlapping/squished text when running Fish or opening the XFCE terminal:

#### 1. The `[>4;1m` Escape Code Artifact
* **Why it happens:** Fish 3.6+ / 4.x queries the terminal for extended keyboard protocols (`modifyOtherKeys` via `\e[>4;1m`). Older VTE terminal libraries (like on CentOS 7) do not recognize this escape sequence and echo it as raw text directly before your prompt (`[>4;1muser@host ~>`).
* **How to fix it (Run these commands on the server):**

  Fish checks the `MC_SID` environment variable (used by Midnight Commander subshells). When `MC_SID` is set, Fish skips sending the `modifyOtherKeys` sequence completely:

  ```bash
  # 1. Export in your Bash startup:
  echo 'export MC_SID=1' >> ~/.bashrc

  # 2. Export in your Csh startup (default shell on ARIES):
  echo 'setenv MC_SID 1' >> ~/.cshrc

  # 3. Export in Fish config to catch all interactive Fish sessions:
  mkdir -p ~/.config/fish
  echo 'set -gx MC_SID 1' >> ~/.config/fish/config.fish
  ```

  *(If you use a wrapper script at `~/.local/bin/fish`, ensure it includes `export MC_SID=1` before executing the actual fish binary).*

#### 2. Font Alignment & Overlapping / Squished Text
* **Why it happens:** CentOS 7's XFCE terminal defaults to a proportional variable-width font (`Sans 10`) instead of a fixed-width monospace font. This causes character overlapping, cursor misalignment, and ragged text in Fish and text editors.
* **How to fix it (Run this command on the server):**

  Configure `xfce4-terminal` to use a proper monospace font (`DejaVu Sans Mono 11`):
  ```bash
  mkdir -p ~/.config/xfce4/terminal
  cat << 'EOF' > ~/.config/xfce4/terminal/terminalrc
  [Configuration]
  FontName=DejaVu Sans Mono 11
  FontUseSystem=FALSE
  EOF
  ```
  *(Close and reopen your terminal in X2Go; it will immediately render with crisp, properly aligned monospace typography).*

---

## 5. Remote File Browsing via Dolphin (KDE Network / Remote Location)

To access files on the ARIES CentOS server without mounting it to your local disk or cluttering `~/`, you can register it as an on-demand **Remote** network location in KDE Dolphin.

### 5.1 Local Configuration (PC & Laptop)

KDE stores remote network entries in `~/.local/share/remoteview/`. Create `~/.local/share/remoteview/ARIES.desktop`:

```ini
[Desktop Entry]
Icon=folder-remote
Name=ARIES Server
Type=Link
URL=sftp://shashi@172.18.1.5/home/shashi
```

Setup command:
```bash
mkdir -p ~/.local/share/remoteview
cat << 'EOF' > ~/.local/share/remoteview/ARIES.desktop
[Desktop Entry]
Icon=folder-remote
Name=ARIES Server
Type=Link
URL=sftp://shashi@172.18.1.5/home/shashi
EOF
```

To sync to your Laptop over Tailscale:
```bash
scp ~/.local/share/remoteview/ARIES.desktop void@100.70.236.70:~/.local/share/remoteview/
```

### 5.2 How to Access & Pin in Dolphin

1. **View in Network:** Open Dolphin ➔ Under the **Remote** section in the left sidebar, click **Network** (`remote:/`). **ARIES Server** will appear with a network folder icon.
2. **One-Click Sidebar Access:** Right-click **"ARIES Server"** ➔ Click **"Add to Places"** ➔ Drag the bookmark directly under the **"Remote"** header in Dolphin's sidebar.

---

## 6. Passwordless SSH & Connection Shortcut (`ssharies`)

To connect to ARIES without typing your password each time:

### 6.1 Install SSH Public Key to ARIES (One-Time Setup)

Run from your local PC or Laptop terminal:
```bash
ssh-copy-id shashi@172.18.1.5
```
*(Enter your ARIES account password `Aries#123$` one last time).*

### 6.2 Fish Shell Function (`ssharies`)

This function is installed on both your **PC** and **Laptop** (`~/.config/fish/functions/ssharies.fish`):

```fish
function ssharies --description 'SSH into ARIES server'
    ssh shashi@172.18.1.5 $argv
end
```

### 6.3 OpenSSH Client Config (`~/.ssh/config`)

Your `~/.ssh/config` has also been configured with:
```ssh
Host aries
    HostName 172.18.1.5
    User shashi
    IdentityFile ~/.ssh/id_ed25519
    ForwardX11 yes
```

Now you can connect directly with:
```bash
ssharies
# or
ssh aries
```
*(Any arguments passed, such as `ssharies -Y` or `ssharies "free -h"`, are automatically forwarded).*

---

## 7. Installing & Running Jupyter Notebook / JupyterLab on ARIES

The ARIES server environment runs user-space **Miniforge** located at `/home/shashi/miniforge3` with both `conda` and `mamba` available. You can host Jupyter Notebook or JupyterLab directly from ARIES and access it securely from your local PC or laptop via SSH port forwarding.

### 7.1 Installation (via Mamba)

Log in to ARIES and install `jupyterlab` and `notebook` into your base Miniforge environment:

```bash
# 1. SSH into ARIES
ssh aries

# 2. Install JupyterLab and classic Notebook
mamba install -y -c conda-forge jupyterlab notebook
```
*(Alternatively, you can install via pip: `pip install --user jupyterlab notebook`)*

### 7.2 Register Existing Conda Environments as Kernels

To allow Jupyter to execute code within your existing research environments (`fermi`, `threeML`, `vegas_env`), install `ipykernel` in each environment and register them with Jupyter:

```bash
# 1. Ensure ipykernel is installed in your target environments
mamba install -y -n fermi ipykernel
mamba install -y -n threeML ipykernel
mamba install -y -n vegas_env ipykernel

# 2. Register each environment as a user-level kernel spec
python -m ipykernel install --user --name fermi --display-name "Python (fermi)"
python -m ipykernel install --user --name threeML --display-name "Python (threeML)"
python -m ipykernel install --user --name vegas_env --display-name "Python (vegas_env)"
```

To view and verify all registered kernels at any time:
```bash
jupyter kernelspec list
```

### 7.3 Launching Jupyter in Headless Mode (via Zellij)

Because ARIES is a remote server, launch Jupyter with `--no-browser`. It is strongly recommended to run it inside a persistent **Zellij** session so the server keeps running even if you close your terminal or disconnect your network:

```bash
# 1. Start or attach to a persistent Zellij session named 'jupyter'
zellij attach -c jupyter

# 2. Launch the Jupyter Notebook server (or use 'jupyter lab')
jupyter notebook --no-browser --port=8888
```

* **Detach without stopping Jupyter:** Press `Ctrl + o`, then hit `d`. The notebook server will remain running in the background.
* **Re-attach later:** Run `zellij attach jupyter` anytime to check logs or copy token URLs.

When Jupyter launches, it will print connection URLs containing an access token:
```text
http://localhost:8888/tree?token=abcdef1234567890...
```

### 7.4 Connecting from Local Machine (PC / Laptop)

Open a terminal on your local machine and establish an SSH port-forwarding tunnel:

```bash
ssh -N -L 8888:localhost:8888 aries
```

Now, open your web browser locally and navigate to:
```text
http://localhost:8888
```
Paste the authentication token generated in step 7.3 when prompted.

#### Local Fish Shell Shortcut (`tunnelaries`)
To avoid remembering the port-forwarding flags, you can add this function to `~/.config/fish/functions/tunnelaries.fish` on your local system:

```fish
function tunnelaries --description 'Open SSH tunnel for Jupyter on ARIES'
    set port 8888
    if test -n "$argv[1]"
        set port $argv[1]
    end
    echo "Forwarding localhost:$port to ARIES:$port... (Press Ctrl+C to disconnect)"
    ssh -N -L $port:localhost:$port aries
end
```
With this function saved, simply run `tunnelaries` from your local terminal whenever you want to open the web connection.

