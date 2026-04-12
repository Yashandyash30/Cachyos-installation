# HEASoft & Xspec Installation Guide (Arch/CachyOS)

> This workflow installs HEASoft via the official HEASARC conda channel, keeping it fully isolated from system updates.

---

## Important: Shell Requirement

Conda's `activate` mechanism relies on bash hooks and is unreliable under Fish. **Switch to bash before proceeding.**

```bash
fish
bash
```

> All steps below must be run inside a bash session.

---

## Step 1: Install HEASoft

Create a new dedicated conda environment called `henv` and install HEASoft directly from the official HEASARC conda channel.

```bash
mamba create -n henv heasoft \
  -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ \
  -c conda-forge
```

---

## Step 2: Activate the Environment

```bash
conda activate henv
```

> The prompt will change to `(henv)[...]`. HEASoft is initialized automatically upon activation.

---

## Step 3: Install Xspec Model Data (Optional)

If you plan to use Xspec, install the atomic data files separately. Since the environment is already built and active, run this directly into it — no rebuild required.

```bash
mamba install xspec-data \
  -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ \
  -c conda-forge
```

> This downloads ~5GB of Xspec atomic data files and slots them into your existing `henv` without modifying anything else.

---

## Maintenance Tips

| Scenario | Action |
|---|---|
| **Update HEASoft** | `mamba update heasoft -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ -c conda-forge` |
| **Broken environment** | Do not attempt to fix it. Run `mamba env remove -n henv` and repeat Steps 1–2 |
| **Xspec data out of date** | `mamba update xspec-data -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ -c conda-forge` |

---

## Why This Setup Is Safe on a Rolling Release

HEASoft installed via the HEASARC conda channel bundles its own runtime libraries inside the environment. Unlike the pre-compiled tarball from the HEASoft website (which links against system GLIBC), this installation is effectively isolated from `pacman -Syu` updates.

| | Pre-compiled Tarball | This Conda Install |
|---|---|---|
| GLIBC dependency | System GLIBC — risky on Arch | Conda-bundled — isolated |
| Update method | Manual reinstall | `mamba update heasoft` |




For a standard Bash shell (`bash`) it will configure everything perfectly for your `henv` environment without any syntax hiccups.

### The Complete Bash CALDB Setup Guide

**1. Create the Directory and Download the Data**
This ensures the files land exactly in `software/tools` as HEASOFT expects.

```bash
# Move to home and create the master directory
mkdir -p ~/caldb
cd ~/caldb

# Download the setup files
wget https://heasarc.gsfc.nasa.gov/FTP/caldb/software/tools/caldb_setup_files.tar.Z

# Extract the files (this creates the software/tools/ structure automatically)
tar -zxvf caldb_setup_files.tar.Z

# Clean up the tarball
rm caldb_setup_files.tar.Z

```

**2. Patch the Initialization Script**
The default HEASOFT script needs your absolute path. This `sed` command automatically finds the dummy variable and replaces it with your actual `~/caldb` path.

```bash
sed -i "s|^CALDB=.*|CALDB=$HOME/caldb; export CALDB|" ~/caldb/software/tools/caldbinit.sh

```

**3. Create the Conda Environment Hooks**
This links the CALDB variables to your `henv` environment so they only load when XSPEC is active.

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

**4. Verify the Installation**
Bounce the environment to trigger the new scripts and run the check.

```bash
conda deactivate
conda activate henv
caldbinfo INST SWIFT XRT

```

### A Quick Note on Shell Compatibility

Because Conda is smart about extensions, the `caldb_env.sh` scripts created in step 3 will automatically execute whenever you activate `henv` **while using Bash or Zsh**.

If you ever decide to stick with Fish as your daily driver on a future install, Conda will ignore those `.sh` files. You would just need to swap Step 3 with the `.fish` echo blocks we used earlier to ensure Conda passes the variables to your Fish session.
| Breakage risk on rolling | High | Very low |
| Recovery | Painful | Remove env and reinstall |
