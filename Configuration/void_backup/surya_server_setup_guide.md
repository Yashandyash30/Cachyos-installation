# Surya HPC Server Specifications & Shell Setup Guide

Comprehensive setup and troubleshooting guide for user environments on the **Surya** HPC cluster running CentOS 7. Covers hardware/OS specifications, resolving common terminal editor errors, installing modern tools (Fastfetch and Fish) without root access, configuring an interactive shell safely on an institutional cluster, and customizing the environment.

---

## 1. Surya Server System Specifications

| Component | Specification |
| :--- | :--- |
| **Hostname / IP** | `surya` / `192.168.4.1` |
| **Operating System** | CentOS Linux 7 (Core) x86_64 (Kernel `3.10.0`) |
| **C Library (GLIBC)** | GLIBC 2.17 |
| **Processors** | 2× Intel(R) Xeon(R) Gold 6226R @ 2.90 GHz (32 Physical Cores / 64 Threads) |
| **Memory (RAM)** | 188 GB DDR4 ECC (~176 GB free) |
| **Storage (`/home`)** | 42 TB RAID array (94% utilized — ~2.7 TB remaining institute-wide) |
| **Desktop Environments** | XFCE 4 (Recommended for remote sessions) and GNOME Classic |
| **Remote GUI Server** | X2Go Server (`/usr/bin/x2gostartagent`) |
| **Default Shell** | Bash (`/bin/bash`) |

---

## 2. Troubleshooting Nano: `[ Error writing ~/.bashrc: No such file or directory ]`

### Root Cause
When editing a file in GNU `nano 2.3.1` (the default version on CentOS 7) and pressing `Ctrl+O` or `Ctrl+X` to save, `nano` displays:
```text
File Name to Write: 
```
If you manually type `~/.bashrc`:
* **The tilde (`~`) is expanded by the shell (Bash), not by text editors.**
* Older versions of `nano` do not perform tilde expansion. `nano` attempts to write literally to `./~/.bashrc` (a subdirectory named `~` in the current working directory). Because that folder does not exist, `nano` outputs:
  ```text
  [ Error writing ~/.bashrc: No such file or directory ]
  ```

### How to Resolve It
1. **Inside `nano`:** Press `Ctrl+C` to cancel the save prompt. If you are already in your home directory, simply type `.bashrc` (or the absolute path `/home/<username>/.bashrc`) and press **Enter**.
2. **From the Bash terminal:** Open `nano` targeting the file directly:
   ```bash
   cd ~
   nano .bashrc
   ```
   When saving with `Ctrl+O`, `nano` will automatically prefill `.bashrc`. **Do not type anything; simply press Enter.**
3. **If `.bashrc` is missing entirely:**
   ```bash
   cp /etc/skel/.bashrc ~/
   ```

---

## 3. Installing Fastfetch on CentOS 7 (GLIBC 2.17 Compatibility)

Standard Fastfetch releases from GitHub are compiled against modern GLIBC versions (GLIBC 2.28+) and will fail on CentOS 7 with missing symbol errors:
```text
/lib64/libc.so.6: version 'GLIBC_2.28' not found
```

To run Fastfetch without root access on CentOS 7, you must use the official **polyfilled** build.

### Installation Steps

Execute the following commands in your terminal on `surya`:

```bash
# 1. Create a local user bin directory and a temporary download folder
mkdir -p ~/.local/bin /tmp/ff_install
cd /tmp/ff_install

# 2. Download the official polyfilled release (compatible with GLIBC 2.17)
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

### Adding `~/.local/bin` to PATH

Ensure your `~/.bashrc` includes `~/.local/bin`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Verify Fastfetch:
```bash
fastfetch
```

---

## 4. Installing Fish Shell in User Space

Because CentOS 7 system repositories do not include modern Fish Shell (and institutional HPC users do not have root access), install the official standalone static binary for x86_64 Linux:

```bash
# 1. Create temporary directory
mkdir -p ~/.local/bin /tmp/fish_install
cd /tmp/fish_install

# 2. Download the standalone static binary (no GLIBC/dependency restrictions)
curl -sLO https://github.com/fish-shell/fish-shell/releases/download/4.0.0/fish-4.0.0-linux-x86_64.tar.xz

# 3. Extract and install
tar -xJf fish-4.0.0-linux-x86_64.tar.xz
cp fish ~/.local/bin/
chmod +x ~/.local/bin/fish

# 4. Clean up
cd ~
rm -rf /tmp/fish_install
```

---

## 5. Making Fish the Default Interactive Shell Safely on HPC

### Critical Warning for HPC Clusters
**Do not use `chsh` to change your system login shell to Fish on an HPC cluster.**

Changing your account's login shell breaks non-POSIX workflows, including:
* Non-interactive SSH commands (`ssh surya "command"`)
* `scp`, `sftp`, and `rsync` automated file transfers
* Batch scheduler job scripts (SLURM / PBS / Torque)
* Environment Modules (`module load <software>`), which require Bash/POSIX syntax
* X2Go remote session initialization (`/usr/bin/x2gostartagent`)

### Recommended Solution: Interactive-Only `exec` in `~/.bashrc`

Keep **Bash** as your default system shell, but automatically launch **Fish** whenever you open an interactive terminal.

Open `~/.bashrc`:
```bash
cd ~
nano .bashrc
```

Add the following block at the very bottom:

```bash
# Safely start Fish shell for interactive terminal sessions only
if [[ $- == *i* ]] && [[ -z "$FISH_VERSION" ]] && command -v fish >/dev/null 2>&1; then
    exec fish
fi
```

#### Why this is safe:
1. `[[ $- == *i* ]]` ensures the block executes **only** for interactive human sessions. Automated file transfers (`scp`/`rsync`) and cluster batch jobs continue using Bash.
2. `[[ -z "$FISH_VERSION" ]]` prevents infinite shell recursion loops.
3. `exec fish` replaces the Bash process in-place:
   * Zero extra memory footprint.
   * Typing `exit` directly closes the terminal window or disconnects the SSH session cleanly.

### Alternative: Configure Graphical Terminal (X2Go / XFCE)
If you connect via X2Go and prefer not to modify `.bashrc`:
1. Open **XFCE Terminal**.
2. Go to **Edit** → **Preferences** → **General**.
3. Enable **"Run a custom command instead of my shell"**.
4. Set Command to: `/home/<username>/.local/bin/fish`.

---

## 6. Removing or Customizing the Fish Welcome Greeting

By default, Fish prints:
```text
Welcome to fish, the friendly interactive shell
Type help for instructions on how to use fish
```

### Option A: Silence the Greeting Completely (One-Line Command)
Inside your Fish shell, run:
```fish
set -U fish_greeting
```
* **Note:** The `-U` flag defines a **universal variable**. Fish persists this setting across all future sessions automatically without modifying configuration files.

### Option B: Replace Greeting with Fastfetch
If you want Fastfetch to greet you every time you open a terminal in Fish:

```fish
function fish_greeting
    fastfetch
end
funcsave fish_greeting
```
* `funcsave fish_greeting` writes the customized greeting function directly to `~/.config/fish/functions/fish_greeting.fish`.

---

## 7. Installing & Running Btop (System Resource Monitor)

CentOS 7 repositories lack `btop`, and standard dynamic binaries require newer GLIBC versions. However, the official `btop` project distributes a fully **statically linked musl binary** that runs without any GLIBC or root dependencies.

### Installation Steps (User Space)

Run the following commands in your terminal on `surya`:

```bash
# 1. Create a temporary download directory
mkdir -p ~/.local/bin /tmp/btop_install
cd /tmp/btop_install

# 2. Download the official static musl archive
curl -sLO https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-unknown-linux-musl.tar.gz

# 3. Extract the archive
tar -xzf btop-x86_64-unknown-linux-musl.tar.gz
cd btop

# 4. Install into ~/.local (copies binary, themes, icons, and desktop launcher)
make install PREFIX=$HOME/.local

# 5. Clean up temporary files
cd ~
rm -rf /tmp/btop_install
```

> **Note:** If `make` is not available on your user environment, you can install it manually with:
> ```bash
> cp bin/btop ~/.local/bin/
> chmod +x ~/.local/bin/btop
> mkdir -p ~/.local/share/btop/themes
> cp -r themes/* ~/.local/share/btop/themes/
> ```

### Running Btop

Launch `btop` from any terminal:
```bash
btop
```

* **Features on Surya:**
  * Monitors all **32 physical cores / 64 threads** across both Intel Xeon Gold 6226R CPUs.
  * Real-time monitoring of the **188 GB RAM** and the **42 TB RAID** array.
  * In X2Go (XFCE Desktop), `btop` will also appear in the application launcher menu under *System*.
  * Keyboard shortcuts: Press `m` to toggle memory view, `p` to toggle process view, `d` to toggle disks, and `q` or `Esc` to quit.

