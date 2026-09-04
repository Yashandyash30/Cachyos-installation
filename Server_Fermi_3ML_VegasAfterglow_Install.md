# Fermitools, 3ML & VegasAfterglow — ARIES Server Installation Guide

Comprehensive guide to install **Fermitools (+ GTBurst)**, **3ML (+ XSPEC)**, and **VegasAfterglow** on the ARIES CentOS 7 server (`172.18.1.5`) — entirely in user space, no root access required.

> **Server Quick Reference**
> | Detail | Value |
> |---|---|
> | Hostname | `ARIES` / `172.18.1.5` |
> | OS | CentOS Linux 7 (Core) x86_64 |
> | Kernel | `3.10.0-1160.119.1.el7.x86_64` |
> | Default Shell | `/bin/csh` (C Shell) |
> | CPU | 2× Intel Xeon Silver 4210 (40 threads) |
> | RAM | ~256 GB ECC DDR4 |
> | Home Storage | 36 TiB RAID (`/home`) |

---

## Table of Contents

1. [Prerequisites — Conda is Already Installed](#1-prerequisites--conda-is-already-installed)
2. [Part A — Fermitools & GTBurst](#2-part-a--fermitools--gtburst)
3. [Part B — 3ML + XSPEC (Standalone Environment)](#3-part-b--3ml--xspec-standalone-environment)
4. [Part C — VegasAfterglow](#4-part-c--vegasafterglow)
5. [Jupyter Kernel Registration (All Environments)](#5-jupyter-kernel-registration-all-environments)
6. [Daily Usage Cheat Sheet](#6-daily-usage-cheat-sheet)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Prerequisites — Conda is Already Installed

The server already has **Anaconda 2021** installed at `~/anaconda3`. You do **not** need to install Miniforge or any other distribution.

```
# Confirmed conda environments on the server:
base                  *  /home/shashi/anaconda3
fermi                    /home/shashi/anaconda3/envs/fermi
threeML                  /home/shashi/anaconda3/envs/threeML
mosfit_env               /home/shashi/anaconda3/envs/mosfit_env
```

> [!CAUTION]
> **NEVER run `conda install` or `mamba install` into the `base` environment.** The Anaconda 2021 base is a monolithic install with hundreds of packages (bokeh, spyder, anaconda-navigator, etc.). Trying to modify it triggers an extremely slow solver that can hang for hours or fail with inconsistency errors.
> All work must be done in **isolated named environments** created with `conda create`.

> [!IMPORTANT]
> **`mamba` is not installed on this server.** Use `conda` for all commands. The server uses standard Anaconda — `mamba` is not available unless explicitly installed (which we avoid to protect `base`).

### 1.1 Always Switch to Bash First

The default shell is `/bin/csh`. Conda does **not** work in csh — `#` comments cause `command not found` errors, `()` cause `Badly placed ()'s`, and inline variables like `VAR=value command` don't work.

```bash
bash
```

Your prompt will change from `[shashi@ARIES ~]$` with csh quirks to a clean bash prompt.
**Every single conda command in this guide must be run inside bash.**

### 1.2 Verify Conda is Working

```bash
conda env list
conda --version
```

Expected: you should see `base`, `fermi`, `threeML`, `mosfit_env` listed, and a conda version number.

### 1.3 Ensure ~/.local/bin is in PATH (for user-installed tools)

Add to `~/.bashrc` so tools like `btop` work without full paths:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

And add to `~/.cshrc` for csh sessions:

```csh
echo 'setenv PATH "$HOME/.local/bin:$PATH"' >> ~/.cshrc
```

---

## 2. Part A — Fermitools & GTBurst

> GTBurst is bundled inside the Fermitools package — no separate installation needed.

### 2.1 Create the Fermi Environment

We lock Python to 3.9 and pin older `numpy`/`astropy` versions to prevent the modern Python ecosystem from breaking GTBurst's older scripts.

> [!NOTE]
> Use `conda create` directly — **not** `mamba create`. `mamba` is not available on this server. `conda create` is fast for new environments because it doesn't need to solve the bloated `base` environment.
> **Note on version:** Do **not** pin `fermitools=2.2.0` as build `2.2.0` is no longer available on the `fermi` channel. Leaving `fermitools` unpinned installs the latest release (2.5+). To inspect available builds, run `conda search -c fermi fermitools`.

```bash
conda create -n fermi \
  -c conda-forge \
  -c fermi \
  fermitools python=3.9 "numpy<1.24" "astropy<6.0" aplpy -y
```

### 2.2 Install 3ML & Fermipy into the Fermi Environment

To perform advanced likelihood fitting (Bayesian blocks for prompt/extended GRB phases), install 3ML and Fermipy into the **same** environment:

```bash
conda install -n fermi \
  -c conda-forge \
  -c threeml \
  threeml fermipy jupyter ipykernel -y
```

### 2.3 Activate the Environment

```bash
conda activate fermi
```

### 2.4 Apply the Patch Script (Critical)

Even with pinned packages, there are hardcoded bugs in the Fermitools install. With `fermi` activated, paste this entire block:

```bash
# 1. Fix permissions for multiprocessing scripts
chmod +x $CONDA_PREFIX/lib/python3.9/site-packages/fermitools/GtBurst/gtapps_mp/*.py

# 2. Fix Numpy float deprecation in Likelihood analysis
sed -i 's/num.float/float/g' $CONDA_PREFIX/lib/python3.9/site-packages/fermitools/UnbinnedAnalysis.py

# 3. Fix Aplpy plotting deprecations in the interactive display
sed -i 's/set_tick_labels_font/tick_labels.set_font/g' $CONDA_PREFIX/lib/python3.9/site-packages/fermitools/GtBurst/commands/gtdolike.py
sed -i 's/set_axis_labels_font/axis_labels.set_font/g' $CONDA_PREFIX/lib/python3.9/site-packages/fermitools/GtBurst/commands/gtdolike.py
sed -i 's/show_grid/add_grid/g' $CONDA_PREFIX/lib/python3.9/site-packages/fermitools/GtBurst/commands/gtdolike.py
```

### 2.5 Install Fermi GBM Data Tools (Optional)

```bash
conda install pip -y
pip install astro-gdt astro-gdt-fermi
```

### 2.6 Set Up Logging Aliases

Add timestamped logging to your bashrc so you never lose GTBurst terminal output:

```bash
cat >> ~/.bashrc << 'EOF'

# Fermi gtburst logging aliases
alias gtburst-log='gtburst 2>&1 | tee "gtburst_$(date +%Y%m%d_%H%M%S).log"'
alias gtburst-quiet='gtburst > "gtburst_$(date +%Y%m%d_%H%M%S).log" 2>&1'
EOF

source ~/.bashrc
```

### 2.7 Register the Jupyter Kernel

```bash
python -m ipykernel install --user --name fermi --display-name "Python (fermi)"
```

### 2.8 Verify the Installation

```bash
python -c "from fermitools import gtburst; print('GTBurst OK')"
python -c "import threeML; print('3ML version:', threeML.__version__)"
python -c "import fermipy; print('Fermipy OK')"
```

> [!TIP]
> WARNING messages about `naima`, `GSL`, `ebltable`, etc. are **normal** — they're optional plugins, not errors.

---

## 3. Part B — 3ML + XSPEC (Standalone Environment)

> Use this if you want a **separate** 3ML environment with full XSPEC support, independent of the Fermi environment above.

### 3.1 Create the Environment with XSPEC

```bash
conda create -n threeML \
  -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ \
  -c conda-forge xspec -y
```

> HEASoft + XSPEC install inside the environment at `~/anaconda3/envs/threeML/heasoft/`. No separate HEASoft compilation needed.

### 3.2 Fix the Broken `heainit.sh` ⚠️ CRITICAL

The XSPEC conda package has a known bug where `heainit.sh` points to a non-existent `BUILD_DIR` path. **This fix must be reapplied every time XSPEC is updated or reinstalled.**

Replace `shashi` with your actual username (run `whoami` if unsure):

```bash
sed -i \
  's|export HEADAS=$CONDA_PREFIX/heasoft|export HEADAS=/home/shashi/anaconda3/envs/threeML/heasoft|' \
  ~/anaconda3/envs/threeML/etc/conda/activate.d/heainit.sh

sed -i \
  's|$HEADAS/BUILD_DIR/headas-init.sh|$HEADAS/headas-init.sh|' \
  ~/anaconda3/envs/threeML/etc/conda/activate.d/heainit.sh
```

Verify the fix:

```bash
cat ~/anaconda3/envs/threeML/etc/conda/activate.d/heainit.sh
```

Expected output:

```
#!/bin/bash
export HEADAS=/home/shashi/anaconda3/envs/threeML/heasoft
echo "activating heasoft in $HEADAS"
source $HEADAS/headas-init.sh
```

### 3.3 Fix conda-meta (If Needed)

Only if conda doesn't recognize the environment (`DirectoryNotACondaEnvironmentError`):

```bash
mkdir -p ~/anaconda3/envs/threeML/conda-meta
echo "# Created by manual fix" > ~/anaconda3/envs/threeML/conda-meta/history
```

### 3.4 Activate & Verify XSPEC

```bash
conda activate threeML
echo $HEADAS
xspec --version
```

Expected: `$HEADAS` prints the correct path, XSPEC launches (v12.15.1+).

### 3.5 Install Python 3.11 + ThreeML

```bash
conda install -c conda-forge python=3.11
conda install -c threeml -c conda-forge astromodels threeml
```

> If a `ucx` error fires, reapply the Step 3.2 fix and retry.

### 3.6 Verify ThreeML

```bash
python -c "import threeML; print(threeML.__version__)"
python -c "import astromodels; print('astromodels ok')"
```

### 3.7 Set Performance Variables

The server has 40 threads shared across ~31 researchers. Setting these to `1` prevents BLAS/MKL from spawning too many threads during MCMC fitting and competing with other users' jobs:

```bash
conda env config vars set OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1
conda deactivate && conda activate threeML
```

### 3.8 Install pynchrotron (Optional — For Synchrotron Modeling)

```bash
conda install pip -y
python -m pip install git+https://github.com/grburgess/pynchrotron.git
```

### 3.9 Register the Jupyter Kernel

```bash
conda install -c conda-forge ipykernel
python -m ipykernel install --user --name threeML --display-name "Python (threeML)"
```

---

## 4. Part C — VegasAfterglow

VegasAfterglow is a GRB afterglow modeling engine with MCMC support. On the server, we install only the **Python library** (no web tool needed — the web UI is designed for local workstations).

### 4.1 Create the VegasAfterglow Environment

```bash
conda create -n vegas_env python=3.11 -y
conda activate vegas_env
```

### 4.2 Install the Physics Engine with MCMC Tools

```bash
conda install pip -y
python -m pip install VegasAfterglow[mcmc]
```

> [!NOTE]
> We install `pip` explicitly inside the Conda environment to avoid conflicts and ensure packages go into the isolated environment, not the system Python.

### 4.3 Register the Jupyter Kernel

```bash
conda install conda-forge::ipykernel -y
python -m ipykernel install --user --name=vegas_env --display-name="Python (VegasAfterglow)"
```

### 4.4 Verify the Installation

```bash
python -c "import VegasAfterglow; print('VegasAfterglow OK')"
```

---

## 5. Jupyter Kernel Registration (All Environments)

After completing the installations above, you should have three Jupyter kernels available:

| Kernel Display Name | Conda Environment | What It Contains |
|---|---|---|
| Python (fermi) | `fermi` | Fermitools (Latest 2.5+), GTBurst, 3ML, Fermipy |
| Python (threeML) | `threeML` | XSPEC, HEASoft, 3ML, astromodels |
| Python (VegasAfterglow) | `vegas_env` | VegasAfterglow + MCMC tools |

### Launching Jupyter on the Server

> [!IMPORTANT]
> You **must** launch Jupyter from inside the activated environment. Fermitools and XSPEC rely on environment variables (`$FERMI_DIR`, `$CALDB`, `$HEADAS`) that are only set upon activation.

```bash
bash                          # if you're in csh
conda activate fermi          # or threeML, or vegas_env
jupyter lab --no-browser --port=8888 --ip=0.0.0.0
```

### Accessing Jupyter from Your Local Machine

On your local PC, create an SSH tunnel:

```bash
ssh -N -L 8888:localhost:8888 shashi@172.18.1.5
```

Then open `http://localhost:8888` in your browser and select the appropriate kernel.

---

## 6. Daily Usage Cheat Sheet

```bash
# 1. SSH into the server
ssh shashi@172.18.1.5

# 2. Switch to bash (mandatory — conda doesn't work in csh)
bash

# 3. Activate the environment you need
conda activate fermi          # For Fermitools / GTBurst / Fermipy
conda activate threeML        # For XSPEC / 3ML spectral fitting
conda activate vegas_env      # For VegasAfterglow afterglow modeling

# 4. Run your analysis
python your_script.py
# or
jupyter lab --no-browser --port=8888

# 5. Launch GTBurst GUI (X2Go session required for display)
gtburst-log

# 6. When done, deactivate
conda deactivate
```

> [!TIP]
> For GTBurst's GUI, you need an X11 display. Connect via **X2Go** (using XFCE session) first, then activate and run GTBurst from within that graphical session.

---

## 7. Troubleshooting

### General Issues

| Error | Fix |
|---|---|
| `conda: command not found` | Run `bash` first, then `source ~/.bashrc` |
| `#: Command not found` or `Badly placed ()'s` | You're in **csh** — run `bash` first, then retry |
| `mamba: command not found` | **Expected** — mamba is not installed. Use `conda` for all commands |
| `(base)` not showing | Close terminal, reopen, type `bash` |
| `terminals database is inaccessible` | Run `echo 'export TERM=xterm-256color' >> ~/.bashrc && source ~/.bashrc` |

### Critical: Never Modify Base

| Symptom | Cause | Fix |
|---|---|---|
| `conda install -n base` hangs for hours | Anaconda 2021 base has 60+ pinned packages — solver can't resolve | `Ctrl+C` immediately, **never install into base** |
| `The environment is inconsistent` warning | Old Anaconda base with mixed channel packages | Ignore, never try to fix base — use isolated envs only |
| Solver very slow even for new envs | Channel priority not set | Run `conda config --set channel_priority strict` |

### Fermitools Issues

| Error | Fix |
|---|---|
| `File __temp_ft1.fits does not exist!` | Don't use GTBurst's built-in downloader — use `threeML` or download manually from [Fermi FSSC](https://fermi.gsfc.nasa.gov/cgi-bin/ssc/LAT/LATDataQuery.cgi), then use "Load User Data" in GTBurst |
| `FITSFixedWarning: 'datfix' made the change…` | **Not an error** — Astropy auto-fixes Fermi metadata date fields |
| `CALDB/Alias Missing Error` | You forgot to activate: run `conda activate fermi` before launching Python |
| Permission denied on `gtapps_mp` scripts | Re-run the patch from Step 2.4 |

### 3ML / XSPEC Issues

| Error | Fix |
|---|---|
| `BUILD_DIR/headas-init.sh: No such file` | Reapply the `heainit.sh` fix from Step 3.2 |
| `DirectoryNotACondaEnvironmentError` | Apply the conda-meta fix from Step 3.3 |
| `ucx post-link script failed` | Reapply Step 3.2 fix, then retry the install |
| `$HEADAS` is empty | Reapply Step 3.2, then `conda deactivate && conda activate threeML` |

### Maintenance

| Task | Command |
|---|---|
| Update Fermitools | `conda update fermitools -c conda-forge -c fermi -y` (re-patch Step 2.4 after) |
| Update 3ML | `conda update -c threeml -c conda-forge threeml astromodels -y` |
| Update VegasAfterglow | `conda activate vegas_env && pip install --upgrade VegasAfterglow[mcmc]` |
| Delete broken environment | `conda env remove -n <env_name>` and redo from scratch |
| List all environments | `conda env list` |
| Clean package cache (save disk) | `conda clean --all -y` |

---

> **References:**
> - [Miniforge.md](file:///home/void/Cachyos-installation/Conda/Miniforge.md) — Miniforge installation & shell setup
> - [Fermitools and gtburst.md](file:///home/void/Cachyos-installation/Conda/Fermitools%20and%20gtburst.md) — Fermitools environment & patches
> - [ThreeML + XSPEC Installation Guide.md](file:///home/void/Cachyos-installation/Conda/ThreeML%20+%20XSPEC%20Installation%20Guide.md) — 3ML/XSPEC with `heainit.sh` fix
> - [vegasafterglow.md](file:///home/void/Cachyos-installation/vegasafterglow.md) — VegasAfterglow Python & web tool setup
> - [server_specs_and_x2go_guide.md](file:///home/void/Cachyos-installation/server_specs_and_x2go_guide.md) — Server specs & X2Go configuration
