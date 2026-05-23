# Future-Proof Guide: Installing IRAF & PyRAF on Arch/CachyOS

> This workflow ensures that your core astronomy tools remain completely isolated from Arch/CachyOS system updates.

---

## Step 1: Install Core System Binaries (AUR)

IRAF is a massive legacy C/Fortran project, so it must be installed globally at the system level. The Arch User Repository packages the pre-compiled binaries along with the essential NOAO packages (necessary for standard optical data reduction).

```bash
paru -S iraf-bin iraf-noao-bin
```

> **Verification:** Run `irafcl` in the terminal to ensure the base system works, then type `logout`.

---

## Step 2: Create an Isolated Mamba Environment

Create a dedicated environment with your required Python version and the standard astronomy stack from conda-forge. Keeping this isolated prevents global package breakage during rolling-release updates.

```bash
mamba create -n pyraf -c conda-forge python=3.11 numpy scipy astropy matplotlib
```

---

## Step 3: Install the PyRAF Wrapper

Because PyRAF is now officially maintained on PyPI rather than Conda, you must install it using pip from inside your newly created environment.

```bash
mamba activate pyraf
pip install pyraf
```

---

To install the pre-compiled binary system-wide, run this instead:

```bash
paru -S ds9-bin
```

## Step 4: Initialize Your Working Directory

IRAF requires a configuration file (`login.cl`) in the directory where your data lives. You must do this once for every new project folder.

```bash
# Navigate to your data folder
cd /path/to/your/project

# Generate the configuration file
mkiraf
```

> **When prompted for terminal type, input `xgterm` or `xterm`.**

---

## Step 5: Launch

Make sure your Mamba environment is active, then launch the wrapper. It will automatically detect the `iraf-bin` installation from Step 1.

```bash
pyraf
```
---

## Fixing `mamba activate pyraf` in `Fish` shell:
### Option 1: The One-Second Fix (Use Conda)

Since Mamba is just a fast downloader and Conda is already awake and managing your environments, you can simply swap the word `mamba` for `conda` to activate it instantly:

```bash
conda activate pyraf

```

*(Remember, activating an environment with Conda takes the exact same amount of time as Mamba. You only really need Mamba when installing new packages!)*

### Option 2: Fix Mamba Permanently

If you want to train your muscle memory to just use `mamba` for everything, you need to initialize Mamba for this specific Fish shell.

To initialize Mamba here, run this:

```bash
# Initialize Mamba for Fish
mamba shell init --shell fish

# Reload your shell to apply it
source ~/.config/fish/config.fish

```
After doing that, `mamba activate pyraf` will work perfectly on your host system from now on.

---

## AUR Package Health Check

Run this once a year to confirm `iraf-bin` is still actively maintained.

```bash
paru -Si iraf-bin
```

Look for the following fields in the output:

| Field | Healthy Sign |
|---|---|
| **Maintainer** | Any named user (not `orphan`) |
| **Last Modified** | Within the last ~12 months |
| **Out Of Date** | `No` |

> **If the package shows as orphaned or out-of-date**, switch to the Distrobox setup in the Appendix below.

---

## Maintenance Tips

| Scenario | Action |
|---|---|
| **Update PyRAF** | Since PyRAF is installed via pip, update it from within the active environment: `pip install --upgrade pyraf` |
| **Update system IRAF** | CachyOS will naturally update the `iraf-bin` packages when you run a standard system update: `paru -Syu` |
| **Broken environment** | Do not attempt to rename or fix it. Run `mamba env remove -n pyraf` and repeat Steps 2 and 3 |

---

## Appendix: Distrobox Setup (Ubuntu 22.04)

> Use this only if you prefer a fully containerized setup.

```bash
# 1. Create the container
distrobox create --name iraf-box --image ubuntu:22.04
distrobox enter iraf-box

# 2. Install IRAF from Ubuntu repos (inside the container)
sudo apt update
sudo apt install iraf

# 3. Install mamba
curl -L https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -o miniforge.sh
bash miniforge.sh -b -p $HOME/miniforge3
source $HOME/miniforge3/etc/profile.d/conda.sh

# 4. Create env and install PyRAF
mamba create -n pyraf -c conda-forge python=3.11 numpy scipy astropy matplotlib ds9
mamba activate pyraf
pip install pyraf

# 5. Export DS9 so it's launchable from the host
distrobox-export --app ds9
```

Here is a drop-in replacement section you can copy and paste directly into your existing guide. This will completely replace your original **Step 2** and **Step 3**, and properly bridge the gap to your Jupyter setup.

---

## Step 2: Automated Environment Setup (YAML)

Instead of manually installing packages one by one, we use a pre-configured YAML file. This guarantees that all required dependencies—including the core astronomy stack, PyRAF, and the Jupyter kernel connector (`ipykernel`)—are resolved and installed flawlessly.

Create a file named `pyraf.yml` in your current directory and paste your configuration into it. Once saved, run the following command to build the entire environment at once:

```bash
mamba env create -f ~/conda-backups/pyraf_portable.yml

```

> **Note:** Mamba will read the file, download the standard astronomy stack via Conda, and automatically run the `pip install pyraf` step at the very end.

---

## Step 3: Activate and Register the Jupyter Kernel

Now that the environment is built, activate it.

```bash
mamba activate pyraf

```

To ensure Jupyter Notebook recognizes this specific PyRAF installation, you must explicitly register the kernel. Run this command while the environment is active:

```bash
python -m ipykernel install --user --name pyraf --display-name "Python (PyRAF)"

```

> **Verification:** The next time you launch a Jupyter Notebook, "Python (PyRAF)" will appear in your kernel dropdown menu and will be perfectly linked to your host system's IRAF binaries.

---

*(Proceed directly to Step 4: Initialize Your Working Directory)*
