# ThreeML + XSPEC Installation Guide (Arch/CachyOS)

> This guide installs XSPEC via the HEASARC conda channel and ThreeML via the official threeML channel, fully isolated from system updates.

---

## Prerequisites

- miniforge3 or miniconda3 installed
- Using **bash** (not fish) for all conda commands
- Internet access

---

## Step 1: Start a Bash Session

```bash
bash
```

> All following commands must be run in bash, not fish.

---

## Step 2: Clean Up Any Previous Failed Attempts

```bash
conda deactivate
rm -rf ~/miniforge3/envs/threeML   # adjust path if using miniconda3
```

---

## Step 3: Create the Environment with XSPEC

```bash
conda create -n threeML \
  -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ \
  -c conda-forge xspec
```

> HEASoft + XSPEC install inside the env at `~/miniforge3/envs/threeML/heasoft/`. No separate HEASoft install is needed.

---

## Step 4: Fix the Broken heainit.sh ⚠️ CRITICAL

The XSPEC conda package has a known bug where `heainit.sh` points to a non-existent `BUILD_DIR` path and uses `$CONDA_PREFIX` which resolves incorrectly during post-link scripts. **This fix must be reapplied every time XSPEC is updated or reinstalled.**

**For local install** — replace `YOUR_USERNAME` with your actual username (run `whoami` if unsure):

```bash
sed -i \
  's|export HEADAS=$CONDA_PREFIX/heasoft|export HEADAS=/home/YOUR_USERNAME/miniforge3/envs/threeML/heasoft|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh

sed -i \
  's|$HEADAS/BUILD_DIR/headas-init.sh|$HEADAS/headas-init.sh|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh
```

**For Distrobox:**

```bash
sed -i \
  's|export HEADAS=$CONDA_PREFIX/heasoft|export HEADAS=/home/void/miniforge3/envs/threeML/heasoft|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh

sed -i \
  's|$HEADAS/BUILD_DIR/headas-init.sh|$HEADAS/headas-init.sh|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh
```

Verify the fix looks correct:

```bash
cat ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh
```

Expected output:

```bash
#!/bin/bash
export HEADAS=/home/YOUR_USERNAME/miniforge3/envs/threeML/heasoft
echo "activating heasoft in $HEADAS"
source $HEADAS/headas-init.sh
```

---

## Step 5: Fix the conda-meta History File

Only needed if conda doesn't recognize the env (`DirectoryNotACondaEnvironmentError`):

```bash
mkdir -p ~/miniforge3/envs/threeML/conda-meta
echo "# Created by manual fix" > ~/miniforge3/envs/threeML/conda-meta/history
```

---

## Step 6: Activate and Verify XSPEC

```bash
conda activate threeML
echo $HEADAS
xspec --version
```

Expected output:
- `$HEADAS` prints `/home/YOUR_USERNAME/miniforge3/envs/threeML/heasoft`
- XSPEC launches and prints version (12.15.1 or newer)

---

## Step 7: Install Python 3.11 + ThreeML

```bash
conda install -c conda-forge python=3.11
conda install -c threeml -c conda-forge astromodels threeml
```

> If the `ucx` error fires during either install, reapply the Step 4 fix and retry.

---

## Step 8: Verify ThreeML Works

```bash
python -c "import threeML; print(threeML.__version__)"
python -c "import astromodels; print('astromodels ok')"
```

Expected output: version number (e.g. `2.5.0`) and `astromodels ok`.

> WARNING messages about naima, GSL, ebltable etc. are normal — they are optional packages, not errors.

---

## Step 9: Set Performance Environment Variables

```bash
conda env config vars set OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1
conda deactivate && conda activate threeML
```

---

## Step 10: Set Up Jupyter Kernel for VS Code

```bash
conda install -c conda-forge ipykernel
python -m ipykernel install --user --name threeML --display-name "Python (threeML)"
```

> In VS Code: open any `.ipynb` → kernel picker (top right) → **Python (threeML)**.

---

## Daily Usage

```bash
bash                        # if using fish shell
conda activate threeML
python your_script.py       # or open VS Code and select the kernel
```

---

## Troubleshooting

| Error | Fix |
|---|---|
| `BUILD_DIR/headas-init.sh: No such file or directory` | Reapply Step 4 fix |
| `DirectoryNotACondaEnvironmentError` | Apply Step 5 fix |
| `ucx post-link script failed` | Reapply Step 4 fix, then retry the install |
| `xspec: command not found` in fish | Run `bash` first, then `conda activate threeML` |
| `$HEADAS` is empty | Reapply Step 4, then `conda deactivate && conda activate threeML` |

---

If you ever need to install `pynchrotron` in a new Conda environment in the future, you can follow these simple steps.

Since `pynchrotron` is not available on standard package managers like PyPI or Conda-forge, you have to install it directly from the author's GitHub repository.

### Step-by-Step Guide:

**1. Activate your target environment**
First, open your terminal and activate the Conda environment where you want to install it (for example, `threeML`):
```bash
conda activate threeML
```

**2. Ensure `pip` is installed inside the environment**
Sometimes Conda environments don't have `pip` installed by default. To make sure you don't accidentally install it into your global system, install `pip` directly into the active environment:
```bash
conda install pip -y
```

**3. Install `pynchrotron` directly from GitHub**
Now, use your environment's `pip` to download and install the package from its source code repository:
```bash
python -m pip install git+https://github.com/grburgess/pynchrotron.git
```

*(Note: We use `python -m pip` instead of just `pip` as a best practice to guarantee that the installation goes exactly into the python version of your currently activated environment.)*

That's it! After running those commands, you can open Jupyter and `import pynchrotron` just like normal.

## Appendix: Distrobox Bridge Kernel for VS Code

> Only needed if you want to run ThreeML inside a Distrobox container while using VS Code on the host. Not required for terminal-based analysis.

### Overview

When using an isolated Distrobox container, standard kernel installation commands fail to communicate with host applications. This bridge installs the kernel engine inside the container but places the connection map on the host.

### Phase 1: Inside the Container

```bash
# 1. Enter the container
distrobox enter astro-box

# 2. Activate the environment
conda activate threeML
# If conda activate doesn't work, run 'bash' first and retry

# 3. Install the kernel engine
mamba install -c conda-forge ipykernel

# 4. Exit the container
exit
```

### Phase 2: On the Host System

```bash
# 1. Create the kernel directory
mkdir -p ~/.local/share/jupyter/kernels/threeml-distrobox

# 2. Create the configuration file
nano ~/.local/share/jupyter/kernels/threeml-distrobox/kernel.json
```

Paste the following — the path must be the container-side path, not the host path:

```json
{
  "argv": [
    "distrobox",
    "enter",
    "astro-box",
    "--",
    "/home/void/miniforge3/envs/threeML/bin/python",
    "-m",
    "ipykernel_launcher",
    "-f",
    "{connection_file}"
  ],
  "display_name": "3ML (Distrobox GPU)",
  "language": "python"
}
```

Save and exit: `Ctrl+O` → `Enter` → `Ctrl+X`.

### Phase 3: Connect in VS Code

1. Open VS Code on the host
2. Open any `.ipynb` notebook
3. Click the **Kernel Picker** (top right)
4. Select **Jupyter Kernel** (not "Python Environments")
5. Choose **3ML (Distrobox GPU)**

> If the kernel does not appear, press `Ctrl+Shift+P` → `Developer: Reload Window` and check again.
