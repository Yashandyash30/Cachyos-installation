# ThreeML + XSPEC Installation Guide (CachyOS / Arch / miniforge3)

## Prerequisites

- miniforge3 or miniconda3 installed
- Using **bash** (not fish) for all conda commands
- Internet access

---

## Step 1 — Start a bash session

```bash
bash
```

All following commands must be run in bash, not fish.

---

## Step 2 — Clean up any previous failed attempts

```bash
conda deactivate
rm -rf ~/miniforge3/envs/threeML   # adjust path if using miniconda3
```

---

## Step 3 — Create the environment with XSPEC only

```bash
conda create -n threeML \
  -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ \
  -c conda-forge xspec
```

> Note: HEASoft + XSPEC install inside the env at `~/miniforge3/envs/threeML/heasoft/`.
> No separate HEASoft install is needed.

---

## Step 4 — Fix the broken heainit.sh (CRITICAL — do this before anything else)

The XSPEC conda package has a bug where `heainit.sh` points to a non-existent
`BUILD_DIR` path and uses `$CONDA_PREFIX` which resolves incorrectly during
post-link scripts. Fix both issues by hardcoding the correct path:
For Local:
```bash
sed -i \
  's|export HEADAS=$CONDA_PREFIX/heasoft|export HEADAS=/home/YOUR_USERNAME/miniforge3/envs/threeML/heasoft|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh

sed -i \
  's|$HEADAS/BUILD_DIR/headas-init.sh|$HEADAS/headas-init.sh|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh
```
For Distrobox:
```bash
sed -i \
  's|export HEADAS=$CONDA_PREFIX/heasoft|export HEADAS=/home/void/miniforge3/envs/threeML/heasoft|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh

sed -i \
  's|$HEADAS/BUILD_DIR/headas-init.sh|$HEADAS/headas-init.sh|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh
```

Replace `YOUR_USERNAME` with your actual username (run `whoami` if unsure).

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

## Step 5 — Fix the conda-meta history file

If conda doesn't recognize the env (DirectoryNotACondaEnvironmentError):

```bash
mkdir -p ~/miniforge3/envs/threeML/conda-meta
echo "# Created by manual fix" > ~/miniforge3/envs/threeML/conda-meta/history
```

---

## Step 6 — Activate and verify XSPEC works

```bash
conda activate threeML
echo $HEADAS
xspec --version
```

Expected:
- `$HEADAS` prints `/home/YOUR_USERNAME/miniforge3/envs/threeML/heasoft`
- XSPEC launches and prints version (12.15.1 or newer)

---

## Step 7 — Install Python 3.11 + threeML

```bash
conda install -c conda-forge python=3.11
conda install -c threeml -c conda-forge astromodels threeml
```

> If the ucx error fires again during either install, immediately reapply the
> heainit.sh fix from Step 4 and retry.

---

## Step 8 — Verify threeML works

```bash
python -c "import threeML; print(threeML.__version__)"
python -c "import astromodels; print('astromodels ok')"
```

Expected output: version number (e.g. `2.5.0`) and `astromodels ok`.
The WARNING messages about naima, GSL, ebltable etc. are normal — they are
optional packages, not errors.

---

## Step 9 — Set performance env vars

```bash
conda env config vars set OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1
conda deactivate && conda activate threeML
```

---

## Step 10 — Set up Jupyter kernel for VS Code

```bash
conda install -c conda-forge ipykernel
python -m ipykernel install --user --name threeML --display-name "Python (threeML)"
```

In VS Code: open any `.ipynb` → kernel picker (top right) → **Python (threeML)**.

---
I am thrilled that the window reload did the trick! Sometimes VS Code just needs a quick tap on the shoulder to notice new files on the hard drive.

Since this specific "Bridge Kernel" method is the absolute best way to use native CachyOS editors with a secure, GPU-accelerated astrophysics container, having it documented is a great idea.

Here is the complete, start-to-finish markdown guide for setting up the Distrobox Bridge Kernel. You can save this as `distrobox-jupyter-kernel-guide.md`.

---


# Distrobox Bridge Kernel Guide for Jupyter / VS Code

## Overview
When using an isolated Distrobox container (sandboxed home directory), standard kernel installation commands (`python -m ipykernel install`) fail to communicate with host applications. 

To use a native host editor (like VS Code on CachyOS) while executing code inside the container, we must manually build a "Bridge Kernel." This setup installs the mathematical engine inside the container, but places the connection map on the host.

---

## Phase 1: Fuel the Engine (Inside the Container)
The container environment must have `ipykernel` installed so it knows how to receive code from the host editor.

**1. Enter your isolated container:**
```bash
distrobox enter astro-box

```

**2. Activate your target environment:**

```bash
conda activate threeML

```
If conda activate doesnt work run 'bash' and then retry

**3. Install the Jupyter kernel engine:**

```bash
mamba install -c conda-forge ipykernel

```

**4. Exit the container:**

```bash
exit

```

---

## Phase 2: Build the Bridge (On the Host System)

You must tell your native Jupyter/VS Code exactly how to route the code through the container wall. Do this strictly on your host machine.

**1. Create the custom kernel directory on your host:**

```bash
mkdir -p ~/.local/share/jupyter/kernels/threeml-distrobox

```

**2. Create the configuration file:**

```bash
nano ~/.local/share/jupyter/kernels/threeml-distrobox/kernel.json

```

**3. Paste the routing configuration:**
*Note: The path in this JSON must be the "illusion" path (how the container sees its own hard drive), NOT the path on your host.*

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

*Save and exit Nano (Ctrl+O, Enter, Ctrl+X).*

---

## Phase 3: Connect and Execute

1. Open VS Code or your local JupyterLab on the host system.
2. Open any `.ipynb` notebook.
3. Click the **Kernel Picker** in the top right.
4. Select **Jupyter Kernel** (do *not* select "Python Environments").
5. Choose **3ML (Distrobox GPU)**.

*(Troubleshooting: If the kernel does not appear in VS Code, press Ctrl + Shift + P, type Developer: Reload Window, and check the menu again).*
---

## Daily usage

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
