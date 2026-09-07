# MESA Dual-Version (23 & 26) Server Installation Guide

*(Surya HPC & ARIES CentOS 7 Servers)*

This guide provides a comprehensive, production-grade procedure to install both **MESA r23.05.1** and **MESA 26.04.1** side-by-side on CentOS 7 servers (**Surya HPC** `192.168.4.1` and **ARIES** `172.18.1.5`).

Both versions run in 100% isolated user-space environments without clashing with each other or with Miniforge/Conda.

---

## 1. Architecture: How Dual-Version Coexistence Works

MESA versions cannot share a single SDK or global environment because their Fortran/C compilers and internal library ABIs differ:

* **MESA 23 (r23.05.1)** requires **SDK 23.7.3** (GCC 13.1.0).
* **MESA 26 (26.04.1)** requires **SDK 26.3.2** (GCC 15.2.0).

To prevent conflicts:

1. Each SDK is extracted to its own versioned folder (`~/mesasdk-23.7.3` and `~/mesasdk-26.3.2`).
2. Each MESA source is extracted to its own folder (`~/mesa-r23.05.1` and `~/mesa-26.04.1`).
3. **No MESA environment variables are set in global `~/.bashrc`**.
4. Separate subshell scripts (`~/.bashrc_mesa_23` and `~/.bashrc_mesa_26`) manage environment variables, threads, and prompts.
5. You switch environments on demand using `mesa23` or `mesa26`.

| Version           | Source Folder       | SDK Folder           | GCC Version | Launch Command | Prompt Tag    |
| :---------------- | :------------------ | :------------------- | :---------- | :------------- | :------------ |
| **MESA 23** | `~/mesa-r23.05.1` | `~/mesasdk-23.7.3` | GCC 13.1.0  | `mesa23`     | `[MESA 23]` |
| **MESA 26** | `~/mesa-26.04.1`  | `~/mesasdk-26.3.2` | GCC 15.2.0  | `mesa26`     | `[MESA 26]` |

---

## 2. Step 0: Clean Up Existing MESA (Run on ARIES Server)

On **ARIES (`172.18.1.5`)**, remove old MESA builds, legacy SDKs, and global bashrc exports.

> [!NOTE]
> MESA does not use or require a Conda environment. Your scientific Conda environments (`fermi`, `threeML`, `vegas_env`) are untouched.

Run these cleanup commands on ARIES:

```bash
# 1. Enter home directory
cd ~

# 2. Remove old MESA folders and legacy SDK
rm -rf ~/mesa-26.04.1 ~/mesasdk ~/Downloads/MESA 2>/dev/null || true

# 3. Clean out hardcoded MESA variables from ~/.bashrc
sed -i '/MESASDK_ROOT/d' ~/.bashrc
sed -i '/mesasdk_init.sh/d' ~/.bashrc
sed -i '/MESA_DIR/d' ~/.bashrc
sed -i '/scripts\/shmesa/d' ~/.bashrc

# 4. Reload bashrc
source ~/.bashrc
```

*(On **Surya HPC**, this step is not needed as it is already clean).*

---

## 3. Step 1: Download the Software Packages

You need four archive files on each server:

| Package           | Filename                               | Download URL                                                                                          | Size    |
| :---------------- | :------------------------------------- | :---------------------------------------------------------------------------------------------------- | :------ |
| **SDK 23**  | `mesasdk-x86_64-linux-23.7.3.tar.gz` | `http://user.astro.wisc.edu/~townsend/resource/download/mesasdk/mesasdk-x86_64-linux-23.7.3.tar.gz` | ~191 MB |
| **MESA 23** | `mesa-r23.05.1.zip`                  | `https://zenodo.org/records/7983526/files/mesa-r23.05.1.zip`                                        | ~2.1 GB |
| **SDK 26**  | `mesasdk-x86_64-linux-26.3.2.tar.gz` | `http://user.astro.wisc.edu/~townsend/resource/download/mesasdk/mesasdk-x86_64-linux-26.3.2.tar.gz` | ~200 MB |
| **MESA 26** | `mesa-26.04.1.zip`                   | `https://zenodo.org/records/19722306/files/mesa-26.04.1.zip?download=1`                             | ~2.3 GB |

### Option A: Download Directly on the Server

Log into the server (`sshsurya` or `ssharies`), switch to `bash`, and run:

```bash
cd ~

# --- MESA 23 Packages ---
curl -C - -L -O "http://user.astro.wisc.edu/~townsend/resource/download/mesasdk/mesasdk-x86_64-linux-23.7.3.tar.gz"
curl -C - -L -o mesa-r23.05.1.zip "https://zenodo.org/records/7983526/files/mesa-r23.05.1.zip"

# --- MESA 26 Packages ---
curl -C - -L -O "http://user.astro.wisc.edu/~townsend/resource/download/mesasdk/mesasdk-x86_64-linux-26.3.2.tar.gz"
curl -C - -L -o mesa-26.04.1.zip "https://zenodo.org/records/19722306/files/mesa-26.04.1.zip?download=1"
```

### Option B: Download Locally & Transfer via `transfer`

If downloading on your local PC/Laptop, send them to the server using the `transfer` command:

```fish
transfer surya mesasdk-x86_64-linux-23.7.3.tar.gz mesa-r23.05.1.zip mesasdk-x86_64-linux-26.3.2.tar.gz mesa-26.04.1.zip
# or to ARIES:
transfer aries mesasdk-x86_64-linux-23.7.3.tar.gz mesa-r23.05.1.zip mesasdk-x86_64-linux-26.3.2.tar.gz mesa-26.04.1.zip
```

---

## 4. Step 2: Extract & Configure the MESA SDKs

Extract each SDK into its dedicated version folder:

```bash
cd ~

# 1. Extract SDK 23 and rename folder
tar xvfz mesasdk-x86_64-linux-23.7.3.tar.gz -C ~/
mv ~/mesasdk ~/mesasdk-23.7.3

# 2. Extract SDK 26 and rename folder
tar xvfz mesasdk-x86_64-linux-26.3.2.tar.gz -C ~/
mv ~/mesasdk ~/mesasdk-26.3.2
```

---

## 5. Step 3: Extract MESA Source Code

Unzip both source code trees into your home directory:

```bash
cd ~

# 1. Extract MESA 23
unzip mesa-r23.05.1.zip
# Creates ~/mesa-r23.05.1

# 2. Extract MESA 26
unzip mesa-26.04.1.zip
# Creates ~/mesa-26.04.1
```

*(You can delete the `.zip` and `.tar.gz` archives afterward to save disk space if quota is tight: `rm -f ~/mesa*.zip ~/mesasdk*.tar.gz`).*

---

## 6. Step 4: Create Environment Config Files

Create two separate, isolated environment files in your home directory so MESA never clashes with Conda or system Python.

### 6.1 Create `~/.bashrc_mesa_23`

```bash
cat << 'EOF' > ~/.bashrc_mesa_23
# Interactive check
[[ $- != *i* ]] && return

# Prevent Conda from activating and overriding compilers
export CONDA_AUTO_ACTIVATE_BASE=false

# Source base environment
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Set thread count (shared cluster recommendation: 8-16 threads)
export OMP_NUM_THREADS=16

# Initialize MESA SDK 23
export MESASDK_ROOT=$HOME/mesasdk-23.7.3
source $MESASDK_ROOT/bin/mesasdk_init.sh

# Initialize MESA 23
export MESA_DIR=$HOME/mesa-r23.05.1
export PATH=$PATH:$MESA_DIR/scripts/shmesa

# Custom prompt
export PS1="\[\e[1;33m\][MESA 23]\[\e[0m\] [\u@\h \W]\$ "
EOF
```

### 6.2 Create `~/.bashrc_mesa_26`

```bash
cat << 'EOF' > ~/.bashrc_mesa_26
# Interactive check
[[ $- != *i* ]] && return

# Prevent Conda from activating and overriding compilers
export CONDA_AUTO_ACTIVATE_BASE=false

# Source base environment
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Set thread count (shared cluster recommendation: 8-16 threads)
export OMP_NUM_THREADS=16

# Initialize MESA SDK 26
export MESASDK_ROOT=$HOME/mesasdk-26.3.2
source $MESASDK_ROOT/bin/mesasdk_init.sh

# Initialize MESA 26
export MESA_DIR=$HOME/mesa-26.04.1
export PATH=$PATH:$MESA_DIR/scripts/shmesa

# Custom prompt
export PS1="\[\e[1;36m\][MESA 26]\[\e[0m\] [\u@\h \W]\$ "
EOF
```

---

## 7. Step 5: Add Aliases to Shell Profiles

Add activation aliases to your shell configuration so typing `mesa23` or `mesa26` instantly launches the respective isolated environment.

### 7.1 If using Bash (`~/.bashrc`):

```bash
cat << 'EOF' >> ~/.bashrc

# MESA Version Switcher Aliases
alias mesa23="bash --rcfile ~/.bashrc_mesa_23"
alias mesa26="bash --rcfile ~/.bashrc_mesa_26"
EOF
source ~/.bashrc
```

### 7.2 If using Fish on the server (`~/.config/fish/config.fish`):

#### Method A: Step-by-Step with Nano

**Add the MESA 23 Alias to Fish:**
Open your Fish configuration file:

```fish
nano ~/.config/fish/config.fish
```

Add this line at the bottom:

```fish
alias mesa23="bash --rcfile ~/.bashrc_mesa_23"
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`). Then reload your configuration:

```fish
source ~/.config/fish/config.fish
```

**Add the MESA 26 Alias to Fish:**
Open your Fish configuration file:

```fish
nano ~/.config/fish/config.fish
```

Add this alias to the bottom of the file:

```fish
alias mesa26="bash --rcfile ~/.bashrc_mesa_26"
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`). Then reload your configuration:

```fish
source ~/.config/fish/config.fish
```

#### Method B: Quick One-Liner (Append Both & Reload)

```fish
mkdir -p ~/.config/fish
cat << 'EOF' >> ~/.config/fish/config.fish

# MESA Version Switcher Aliases
alias mesa23="bash --rcfile ~/.bashrc_mesa_23"
alias mesa26="bash --rcfile ~/.bashrc_mesa_26"
EOF
source ~/.config/fish/config.fish
```

---

## 8. Step 6: Verify Compilers Before Building

Always verify that the isolated subshells point to the correct SDK compilers before starting compilation.

### Test MESA 23 SDK:

```bash
mesa23
gfortran --version   # Must output: GNU Fortran (GCC) 13.1.0
which gfortran       # Must output: /home/<user>/mesasdk-23.7.3/bin/gfortran
exit
```

### Test MESA 26 SDK:

```bash
mesa26
gfortran --version   # Must output: GNU Fortran (GCC) 15.2.0
which gfortran       # Must output: /home/<user>/mesasdk-26.3.2/bin/gfortran
exit
```

---

## 9. Step 7: Compile MESA 23 and MESA 26

### 9.1 Compile MESA 23

```bash
# 1. Launch MESA 23 environment
mesa23

# 2. Navigate to source
cd $MESA_DIR

# 3. Clean and build
./clean
./install

# 4. Exit environment when finished
exit
```

*(Compilation takes approximately 20–45 minutes. Watch for the banner `MESA installation was successful`).*

### 9.2 Compile MESA 26

```bash
# 1. Launch MESA 26 environment
mesa26

# 2. Navigate to source
cd $MESA_DIR

# 3. Clean and build
./clean
./install

# 4. Exit environment when finished
exit
```

---

## 10. Daily Workflow & Project Usage

Whenever you want to run or test a star model:

### For a MESA 23 Project:

```bash
mesa23
cd ~/my_mesa23_work/
# Run standard workdir commands (e.g. ./mk, ./rn)
exit
```

### For a MESA 26 Project:

```bash
mesa26
cd ~/my_mesa26_work/
# Run standard workdir commands (e.g. ./mk, ./rn)
exit
```

### Running the Verification Tests:

#### Test A: Standard Headless CLI Test

Verify core stellar evolution algorithms without graphics:

```bash
cd $MESA_DIR/star/test
./mk
./rn
```

If the model evolves and terminates with `TERMINATION: reached maximum model number`, core MESA computation is 100% verified.

---

#### Test B: Live Interactive PGPLOT / PGSTAR Windows Test

Verify that live X11/PGPLOT graphical plotting windows pop up properly onto your local Laptop or PC desktop:

1. **Connect from your local Laptop or PC terminal with GUI forwarding:**

   ```fish
   # For MESA 23 on ARIES:
   mesagui aries 23

   # Or for MESA 26 on Surya HPC:
   mesagui surya 26
   ```
2. **Confirm X11 Forwarding is active:**

   ```bash
   echo $DISPLAY
   # Output should show localhost:10.0 or similar (NOT empty)
   ```
3. **Create a clean work directory for the PGPLOT test:**

   ```bash
   cp -r $MESA_DIR/star/work ~/mesa_pgplot_test
   cd ~/mesa_pgplot_test
   ```
4. **Enable PGSTAR live graphic windows in `inlist_pgstar`:**
   Ensure the following flags are active inside `inlist_pgstar`:

   ```fortran
   &pgstar

      pgstar_flag = .true.

      ! 1. Open live HR Diagram window
      HR_win_flag = .true.
      HR_win_width = 7
      HR_win_aspect_ratio = 0.75

      ! 2. Open live Multi-panel Grid (TRho, Abundances, Kippenhahn)
      Grid1_win_flag = .true.
      Grid1_win_width = 11
      Grid1_win_aspect_ratio = 0.65

      ! Refresh plot every 2 timesteps
      Grid1_win_interval = 2

   / ! end of pgstar namelist
   ```
5. **Build and run the simulation:**

   ```bash
   ./mk
   ./rn
   ```
6. **Verification Outcome:**

   * Terminal output begins evolving the stellar model.
   * Two PGPLOT graphical windows (**HR Diagram** and **Grid1 Summary**) immediately pop up on your desktop!
   * The plots will update dynamically in real time at every timestep interval as the star evolves.

---

#### Test C: Simple Verification Inside X2Go Client (100% Persistent GUI)

If you prefer a persistent remote desktop where PGSTAR windows stay alive on the server even when your laptop disconnects:

1. **Open X2Go Client** on your Laptop or PC.
2. **Connect to your server session** (Surya HPC or ARIES) configured with MATE / XFCE desktop.
3. **Open a terminal inside the remote X2Go desktop** and activate your desired MESA version:
   ```bash
   # For MESA 23:
   mesa23

   # Or for MESA 26:
   mesa26
   ```
4. **Enter your work directory and run:**
   ```bash
   cd ~/mesa_pgplot_test
   ./rn
   ```
5. **Result & Persistence:**
   * The PGSTAR windows (HR diagram, Grid) appear directly inside your X2Go desktop.
   * You can close or disconnect X2Go at any time. Because `x2goagent` stays running on the server, your simulation and PGSTAR windows will keep running uninterrupted. When you reconnect X2Go later, your windows will be waiting right where you left them!

---

## 9. Running MESA with Full GUI (PGSTAR) from your Laptop / PC

For complete details on Niri floating window rules, overnight persistent runs with Zellij, and Dolphin remote monitoring, see:

* **[09_MESA_Remote_GUI_Environments.md](file:///home/void/Cachyos-installation/Configuration/09_MESA_Remote_GUI_Environments.md)**

Quick jump commands available on your Laptop & PC:

* **Live GUI:** `mesagui aries 23` or `mesagui surya 26`
* **Persistent Runs:** `mesaz aries` or `mesaz surya`
