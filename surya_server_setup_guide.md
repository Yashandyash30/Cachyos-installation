# Surya HPC (ARIES) Cluster Setup & User Guide

Comprehensive guide covering system specifications, resolving the `bash` ➔ `fish` startup loop, configuring Fish shell on demand, Fastfetch installation, X2Go remote desktop access, Dolphin remote network folder browsing, and scientific software setup on the ARIES Surya HPC cluster.

---

## 1. System Hardware & Cluster Specifications

| Parameter                          | Specification                                                                  |
| :--------------------------------- | :----------------------------------------------------------------------------- |
| **Hostname**                 | `surya` / `surya.aries.res.in`                                             |
| **Internal IP**              | `192.168.4.1` (Interface `eno7`)                                           |
| **Location**                 | ARIES Datacenter, Haldwani / Nainital                                          |
| **Operating System**         | CentOS Linux 7 (Core) x86_64                                                   |
| **Kernel**                   | `Linux 3.10.0-1160.31.1.el7.x86_64`                                          |
| **C Standard Library**       | `GLIBC 2.17`                                                                 |
| **Processors (Main Node)**   | 2× Intel(R) Xeon(R) Gold 6226R @ 2.90 GHz (3.90 GHz Max Turbo)                |
| **Total Cores / Threads**    | **32 Physical Cores** (16 cores/socket, 2 sockets)                       |
| **System Memory (RAM)**      | **188.41 GiB DDR4 Registered ECC** (~176 GiB available)                  |
| **Swap Space**               | **64.00 GiB**                                                            |
| **Root Partition (`/`)**   | **816 GiB** ext4 (17% used, ~680 GiB free)                               |
| **Applications (`/apps`)** | **1.82 TiB** xfs (Cluster shared software modules)                       |
| **Home Storage (`/home`)** | **41.84 TiB** xfs shared RAID (**94% full** — ~2.7 TiB remaining) |
| **Desktop Environment**      | **XFCE 4.12** (`/usr/bin/xfce4-session`) & GNOME Classic               |
| **Remote Display Server**    | **X2Go Server** (`/usr/bin/x2gostartagent`)                            |

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
   ie to remove fastfetch welcome screen everytime remove this block from `~/.bashrc`

```Shell
# Welcome banner for interactive logins
if [[ $- == *i* ]]; then
    fastfetch
fi
```

1. Save with `Ctrl+O`, `Enter`, and exit with `Ctrl+X`.
5. Now, typing `bash` stays in Bash. Whenever you want Fish, simply run:

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

### Fixing Legacy Terminal Compatibility (CentOS 7 XFCE & Fish)

If you see strange escape codes like `[>4;1m` or overlapping/squished text when opening a terminal in X2Go:

#### 1. Fixing the `[>4;1m` Artifact in Fish

* **Why it happens:** Fish 3.6+ / 4.x queries the terminal for extended keyboard protocols (`modifyOtherKeys` via `\e[>4;1m`). CentOS 7's legacy terminal library doesn't understand this escape sequence and prints it out as literal text before your prompt (`[>4;1myashsharma@surya ~>`).
* **How to fix it (Run these commands on Surya):**
  Fish skips this check if the `MC_SID` variable is set. Export it in your shell configurations:
  ```bash
  # 1. Add to Bash startup (~/.bashrc):
  echo 'export MC_SID=1' >> ~/.bashrc

  # 2. Add to Fish startup (~/.config/fish/config.fish):
  mkdir -p ~/.config/fish
  echo 'set -gx MC_SID 1' >> ~/.config/fish/config.fish
  ```

#### 2. Fixing Font Alignment & Overlapping / Squished Text

* **Why it happens:** The default terminal font in CentOS 7 XFCE is set to proportional `Sans 10` instead of a monospace font, causing letters to overlap.
* **How to fix it (Run this command on Surya):**
  ```bash
  mkdir -p ~/.config/xfce4/terminal
  cat << 'EOF' > ~/.config/xfce4/terminal/terminalrc
  [Configuration]
  FontName=DejaVu Sans Mono 11
  FontUseSystem=FALSE
  EOF
  ```

  *(Restart the terminal inside X2Go; your prompt will be clean and all characters will align properly).*

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

## 6. VegasAfterglow & Interactive Web Tool Setup (100% Error-Free)

This section provides the complete, pre-patched procedure to install **VegasAfterglow** and its **interactive Web Tool dashboard** on Surya HPC (`192.168.4.1`) without encountering C++ compilation errors, indentation bugs, or network connection errors.

### 6.1 Create the Environment & Install the Physics Engine

Because CentOS 7 has an ancient system compiler (GCC 4.8.5), never compile packages from source. We pre-install dependencies via Conda and install VegasAfterglow using pre-compiled wheels:

```bash
# 1. Ensure you are in bash
bash

# 2. Create the Python 3.11 environment
mamba create -n vegas_env --override-channels -c conda-forge python=3.11 -y
conda activate vegas_env

# 3. Pre-install heavy numerical and MCMC libraries
mamba install -n vegas_env --override-channels -c conda-forge \
  pip scipy numpy bilby emcee dynesty corner matplotlib ipykernel -y

# 4. Install VegasAfterglow via pre-compiled binary wheel (do NOT use -e from git)
python -m pip install VegasAfterglow[mcmc]

# 5. Register Jupyter kernel
python -m ipykernel install --user --name=vegas_env --display-name="Python (VegasAfterglow)"

# 6. Verify core library works
python -c "import VegasAfterglow; print('VegasAfterglow OK')"
```

---

### 6.2 Install Node.js & Setup the Web Tool

```bash
# 1. Install Node.js v20 LTS into the conda environment (No root required)
mamba install -n vegas_env -c conda-forge nodejs -y
node -v && npm -v

# 2. Clone the VegasAfterglow repository to ~/VegasAfterglow
cd ~
git clone https://github.com/YihanWangAstro/VegasAfterglow.git
```

---

### 6.3 Configure & Patch the Backend (Crucial Fixes)

Install web server dependencies and apply the 2 critical patches that prevent `ModuleNotFoundError: VegasAfterglowC` and `IndentationError`:

```bash
cd ~/VegasAfterglow/webtool/backend

# 1. Install backend dependencies from pre-compiled wheels (FastAPI, Uvicorn, Plotly)
python -m pip install fastapi "uvicorn[standard]" pydantic plotly kaleido python-dotenv orjson

# 2. Patch app/main.py (Disable local sys.path injection to prevent ModuleNotFoundError)
# Comments out all 3 lines cleanly so no IndentationError is created:
sed -i '/if _repo_root and (_repo_root/,+2s/^/# /' app/main.py

# 3. Patch CORS in app/main.py (Allow connections from laptop & external IPs)
sed -i 's/allow_origins=allowed_origins/allow_origins=["*"]/' app/main.py

# 4. Copy the compiled C++ engine (.so) from site-packages into the local repo as a fail-safe
cp -v ~/miniforge3/envs/vegas_env/lib/python3.11/site-packages/VegasAfterglow/VegasAfterglowC* ~/VegasAfterglow/VegasAfterglow/ 2>/dev/null || true

# 5. Verify backend starts with zero errors
python -c "from app.main import app; print('Backend Verified: ' + app.title)"
```
*(Expected output: `Backend Verified: webtool-api`)*

---

### 6.4 Configure the Frontend & Security Overrides

```bash
cd ~/VegasAfterglow/webtool/frontend

# 1. Create environment file pointing to Surya's IP
echo "NEXT_PUBLIC_API_URL=http://192.168.4.1:8000" > .env.local

# 2. Install frontend dependencies
npm install

# 3. Patch Content-Security-Policy (CSP) in next.config.mjs to whitelist backend port 8000
sed -i "s|connect-src 'self'|connect-src 'self' http://*:8000|g" next.config.mjs

# 4. Purge any stale build cache
rm -rf .next
```

---

### 6.5 Install the `vegasweb` All-in-One Launcher

Create a single-command launcher that starts both servers, outputs connection URLs, and handles `Ctrl+C` clean shutdown:

```bash
mkdir -p ~/.local/bin
cat << 'EOF' > ~/.local/bin/vegasweb
#!/bin/bash
# VegasAfterglow Surya HPC Launcher

VEGAS_DIR="$HOME/VegasAfterglow"
UVICORN="$HOME/miniforge3/envs/vegas_env/bin/uvicorn"
NPM="$HOME/miniforge3/envs/vegas_env/bin/npm"
SERVER_IP="192.168.4.1"

echo "================================================="
echo "   VegasAfterglow Surya HPC Launcher             "
echo "================================================="
echo "Server IP: $SERVER_IP"

# 1. Update frontend config
echo "NEXT_PUBLIC_API_URL=http://$SERVER_IP:8000" > "$VEGAS_DIR/webtool/frontend/.env.local"

# 2. Clean up stale ports
fuser -k 8000/tcp 2>/dev/null || true
fuser -k 3000/tcp 2>/dev/null || true

# 3. Start Backend
echo "Starting Backend on 0.0.0.0:8000..."
cd "$VEGAS_DIR/webtool/backend"
"$UVICORN" app.main:app --host 0.0.0.0 --port 8000 > /tmp/vegas_backend.log 2>&1 &
BACKEND_PID=$!

# 4. Start Frontend
echo "Starting Frontend on 0.0.0.0:3000..."
cd "$VEGAS_DIR/webtool/frontend"
export PATH="$HOME/miniforge3/envs/vegas_env/bin:$PATH"
"$NPM" run dev -- -H 0.0.0.0 -p 3000 > /tmp/vegas_frontend.log 2>&1 &
FRONTEND_PID=$!

echo ""
echo "================================================="
echo " VegasAfterglow is LIVE!"
echo " -> Direct LAN Access:      http://$SERVER_IP:3000"
echo " -> SSH Port Forward URL:   http://localhost:3000"
echo " -> Backend API Docs:       http://$SERVER_IP:8000/docs"
echo "================================================="
echo " Logs:"
echo "   Backend:  tail -f /tmp/vegas_backend.log"
echo "   Frontend: tail -f /tmp/vegas_frontend.log"
echo " Press [Ctrl+C] to stop both servers."
echo "================================================="

cleanup() {
    echo -e "\nStopping VegasAfterglow servers..."
    kill "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null
    wait "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null
    echo "Both servers stopped cleanly."
    exit 0
}

trap cleanup INT TERM EXIT
wait
EOF
chmod +x ~/.local/bin/vegasweb
```

---

### 6.6 How to Run and Access

1. **On Surya Server:**
   ```bash
   vegasweb
   ```

2. **On Your Laptop Browser:**
   * **Option A (Direct LAN):** Open `http://192.168.4.1:3000` in your browser.
   * **Option B (SSH Tunnel):** Run on your laptop terminal:
     ```bash
     ssh -N -L 3000:localhost:3000 -L 8000:localhost:8000 yashsharma@192.168.4.1
     ```
     Then open `http://localhost:3000` in your browser.

---

## 7. Storage Quota & Housekeeping

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
