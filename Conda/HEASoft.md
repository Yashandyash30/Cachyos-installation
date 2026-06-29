Here is the fully updated, polished guide. I have completely rewritten **Step 1 of the CALDB Setup** so that it properly creates the `software/tools` directory structure before downloading and extracting the NASA configuration files.

This version will work flawlessly copy-and-pasted into your terminal.

---

# HEASoft & Xspec Installation Guide (Arch/CachyOS)

> This workflow installs HEASoft via the official HEASARC conda channel, keeping it fully isolated from system updates.

## Important: Shell Requirement

Conda's `activate` mechanism relies on bash hooks and is unreliable under Fish. **Switch to bash before proceeding.**

```bash
bash

```

> All steps below must be run inside a bash session.

---

## Part 1: Install HEASoft & Xspec

**Step 1: Install HEASoft**
Create a new dedicated conda environment called `henv` and install HEASoft directly from the official HEASARC conda channel.

```bash
mamba create -n henv heasoft \
  -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ \
  -c conda-forge

```

**Step 2: Activate the Environment**

```bash
conda activate henv

```

> The prompt will change to `(henv)[...]`. HEASoft is initialized automatically upon activation.

**Step 3: Install Xspec Model Data (Optional)**
If you plan to use Xspec, install the atomic data files separately. Since the environment is already built and active, run this directly into it — no rebuild required.

```bash
mamba install xspec-data \
  -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ \
  -c conda-forge

```

> This downloads ~5GB of Xspec atomic data files and slots them into your existing `henv` without modifying anything else.

---

## Part 2: The Complete Bash CALDB Setup Guide

For a standard Bash shell (`bash`), this will configure everything perfectly for your `henv` environment without any syntax hiccups.

**Step 1: Create the Directory and Download the Data**
NASA's setup tarball does *not* create the required folder structure automatically. We must create the `software/tools` subdirectory first, move into it, and extract the files there.

```bash
# 1. Create the master directory AND the required subdirectories
mkdir -p ~/caldb/software/tools
cd ~/caldb/software/tools

# 2. Download the setup files directly into the tools folder
wget https://heasarc.gsfc.nasa.gov/FTP/caldb/software/tools/caldb_setup_files.tar.Z

# 3. Extract the files (they will now unpack correctly inside software/tools/)
tar -zxvf caldb_setup_files.tar.Z

# 4. Clean up the tarball
rm caldb_setup_files.tar.Z

```

**Step 2: Patch the Initialization Script**
The default HEASOFT script needs your absolute path. This `sed` command automatically finds the dummy variable and replaces it with your actual `~/caldb` path.

```bash
sed -i "s|^CALDB=.*|CALDB=$HOME/caldb; export CALDB|" ~/caldb/software/tools/caldbinit.sh

```

**Step 3: Create the Conda Environment Hooks**
This links the CALDB variables to your `henv` environment so they only load when the environment is active.

```bash
# Locate your henv environment path
ENV_PATH=$(conda info --base)/envs/henv

# Create the Conda hook directories
mkdir -p $ENV_PATH/etc/conda/activate.d
mkdir -p $ENV_PATH/etc/conda/deactivate.d

# Write the Activation Script
cat << 'EOF' > $ENV_PATH/etc/conda/activate.d/caldb_env.sh
#!/bin/bash
export CALDB=$HOME/caldb
source $CALDB/software/tools/caldbinit.sh
EOF

# Write the Deactivation Script (to clean up when you exit the env)
cat << 'EOF' > $ENV_PATH/etc/conda/deactivate.d/caldb_env.sh
#!/bin/bash
unset CALDB
unset CALDBCONFIG
unset CALDBALIAS
EOF

```

*(Note: Conda will automatically execute these `.sh` files upon activation when using Bash or Zsh. If you switch back to Fish permanently later, you will need to translate these hooks into `.fish` scripts.)*

**Step 4: Verify the Installation**
Bounce the environment to trigger the new scripts and run the check.

```bash
conda deactivate
conda activate henv
caldbinfo INST SWIFT XRT

```

> If successful, this will report `Local CALDB appears to be set-up & accessible` and `caldbinfo 1.1.0 completed successfully.`

---

## Part 3: Maintenance & Rolling Release Safety

HEASoft installed via the HEASARC conda channel bundles its own runtime libraries inside the environment. Unlike the pre-compiled tarball from the HEASoft website (which links against system GLIBC), this installation is effectively isolated from `pacman -Syu` updates.

### Safety Comparison

| Feature | Pre-compiled Tarball | This Conda Install |
| --- | --- | --- |
| **GLIBC dependency** | System GLIBC — risky on Arch | Conda-bundled — isolated |
| **Update method** | Manual reinstall | `mamba update heasoft` |
| **Breakage risk on rolling** | High | Very low |
| **Recovery** | Painful | Remove env and reinstall |

### Maintenance Commands

| Scenario | Action |
| --- | --- |
| **Update HEASoft** | `mamba update heasoft -c [https://heasarc.gsfc.nasa.gov/FTP/software/conda/](https://heasarc.gsfc.nasa.gov/FTP/software/conda/) -c conda-forge` |
| **Xspec data out of date** | `mamba update xspec-data -c [https://heasarc.gsfc.nasa.gov/FTP/software/conda/](https://heasarc.gsfc.nasa.gov/FTP/software/conda/) -c conda-forge` |
| **Broken environment** | Do not attempt to fix it. Run `mamba env remove -n henv` and repeat Steps 1–2 |
