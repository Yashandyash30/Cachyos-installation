# Fermitools, 3ML & VegasAfterglow — ARIES Server Installation Guide

Comprehensive guide to install **Fermitools (+ GTBurst)**, **3ML (+ XSPEC)**, and **VegasAfterglow** on the ARIES CentOS 7 server (`172.18.1.5`) — entirely in user space, no root access required.

> **Server Quick Reference**
>
> | Detail        | Value                                   |
> | ------------- | --------------------------------------- |
> | Hostname      | `ARIES` / `172.18.1.5`              |
> | OS            | CentOS Linux 7 (Core) x86_64            |
> | Kernel        | `3.10.0-1160.119.1.el7.x86_64`        |
> | Default Shell | `/bin/csh` (C Shell)                  |
> | CPU           | 2× Intel Xeon Silver 4210 (40 threads) |
> | RAM           | ~256 GB ECC DDR4                        |
> | Home Storage  | 36 TiB RAID (`/home`)                 |

---

## Table of Contents

1. [Prerequisites — Miniforge3 is Installed](#1-prerequisites--miniforge3-is-installed)
2. [Part A — Fermitools &amp; GTBurst](#2-part-a--fermitools--gtburst)
3. [Part B — 3ML + XSPEC (Standalone Environment)](#3-part-b--3ml--xspec-standalone-environment)
4. [Part C — VegasAfterglow](#4-part-c--vegasafterglow)
5. [Jupyter Kernel Registration (All Environments)](#5-jupyter-kernel-registration-all-environments)
6. [Daily Usage Cheat Sheet](#6-daily-usage-cheat-sheet)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Prerequisites — Miniforge3 is Installed

This guide assumes you have completely removed standard Anaconda and installed **Miniforge3** to `~/miniforge3`. Miniforge provides the lightning-fast `mamba` solver and uses the community `conda-forge` channel by default.

> [!CAUTION]
> **NEVER run `mamba install` or `conda install` into the `base` environment.** All work must be done in **isolated named environments** created with `mamba create`.

### 1.1 Always Switch to Bash First

The default shell is `/bin/csh`. Conda does **not** work in csh — `#` comments cause `command not found` errors, `()` cause `Badly placed ()'s`, and inline variables like `VAR=value command` don't work.

```bash
bash
```

Your prompt will change from `[shashi@ARIES ~]$` to a clean bash prompt.
**Every single mamba/conda command in this guide must be run inside bash.**

### 1.2 Verify Conda & Mamba are Working

```bash
conda --version
mamba --version
```

### 1.3 Configure Conda for the Institute Network (Critical)

The ARIES institute firewall throttles parallel shard downloads, causing `Download error (28) Timeout was reached` errors. Disable sharded repodata to use a stable single stream instead:

```bash
conda config --set repodata_use_shards false
```

### 1.4 Ensure Conda & Mamba are Synchronized (Critical)

To prevent `mamba` and `conda` from creating environments in different paths (`~/.local/share/mamba` vs `~/miniforge3`), ensure `~/.bashrc` points `MAMBA_ROOT_PREFIX` to `~/miniforge3`:

```bash
sed -i "s|export MAMBA_ROOT_PREFIX=.*|export MAMBA_ROOT_PREFIX='/home/shashi/miniforge3';|" ~/.bashrc
source ~/.bashrc
```

Verify both point to `/home/shashi/miniforge3`:

```bash
conda env list
mamba env list
```

---

## 2. Part A — Fermitools & GTBurst

> GTBurst is bundled inside the Fermitools package — no separate installation needed.

### 2.1 Create the Fermi Environment

> [!NOTE]
> Modern Fermitools (2.4.0+) installs with modern Python (3.11/3.12). Because older builds (like 2.2.0) were purged from the Conda channel, we install modern Fermitools alongside `patchelf`, and then apply a user-space patch in Step 2.4 to resolve CentOS 7's `GLIBC_2.27` requirement on `libLikelihood.so`.

```bash
mamba create -n fermi \
  --override-channels \
  -c conda-forge \
  -c fermi \
  fermitools aplpy patchelf -y
```

**If the command gets interrupted (Ctrl+C) and leaves a corrupted cache:**

```bash
mamba clean --all -y
# Then re-run the create command above
```

### 2.2 Install 3ML & Fermipy into the Fermi Environment

To perform advanced likelihood fitting (Bayesian blocks for prompt/extended GRB phases), install 3ML and Fermipy into the **same** environment:

```bash
mamba install -n fermi \
  --override-channels \
  -c conda-forge \
  -c threeml \
  threeml fermipy jupyter ipykernel -y
```

### 2.3 Activate the Environment

```bash
conda activate fermi
```

### 2.4 Apply the Patch Script (Critical)

Even with modern packages, there are hardcoded bugs in Fermitools and a GLIBC mismatch on CentOS 7 (`GLIBC 2.17` vs `GLIBC_2.27` for `expf`/`logf`). With `fermi` activated, paste this entire block:

```bash
# 1. Fix permissions for multiprocessing scripts
chmod +x $CONDA_PREFIX/lib/python3.*/site-packages/fermitools/GtBurst/gtapps_mp/*.py

# 2. Fix Numpy float deprecation in Likelihood analysis
sed -i 's/num.float/float/g' $CONDA_PREFIX/lib/python3.*/site-packages/fermitools/UnbinnedAnalysis.py

# 3. Fix Aplpy plotting deprecations in the interactive display
sed -i 's/set_tick_labels_font/tick_labels.set_font/g' $CONDA_PREFIX/lib/python3.*/site-packages/fermitools/GtBurst/commands/gtdolike.py
sed -i 's/set_axis_labels_font/axis_labels.set_font/g' $CONDA_PREFIX/lib/python3.*/site-packages/fermitools/GtBurst/commands/gtdolike.py
sed -i 's/show_grid/add_grid/g' $CONDA_PREFIX/lib/python3.*/site-packages/fermitools/GtBurst/commands/gtdolike.py

# 4. Clear symbol version constraints on libLikelihood.so
patchelf --clear-symbol-version expf $CONDA_PREFIX/lib/libLikelihood.so 2>/dev/null || true
patchelf --clear-symbol-version logf $CONDA_PREFIX/lib/libLikelihood.so 2>/dev/null || true

# 5. Patch .gnu.version_r table in libLikelihood.so for CentOS 7 GLIBC 2.17 compatibility
python3 << 'EOF'
import os, struct

def patch_elf_verneed(filepath):
    try:
        with open(filepath, "r+b") as f:
            data = bytearray(f.read())
            if data[:4] != b"\x7fELF" or data[4] != 2:
                return False
          
            e_shoff = struct.unpack("<Q", data[40:48])[0]
            e_shentsize = struct.unpack("<H", data[58:60])[0]
            e_shnum = struct.unpack("<H", data[60:62])[0]
            e_shstrndx = struct.unpack("<H", data[62:64])[0]
      
            if e_shstrndx >= e_shnum or e_shoff == 0:
                return False
          
            shstr_hdr = e_shoff + e_shstrndx * e_shentsize
            shstr_offset = struct.unpack("<Q", data[shstr_hdr+24:shstr_hdr+32])[0]
      
            sections = {}
            for i in range(e_shnum):
                hdr = e_shoff + i * e_shentsize
                sh_name_idx = struct.unpack("<I", data[hdr:hdr+4])[0]
                sh_offset = struct.unpack("<Q", data[hdr+24:hdr+32])[0]
                sh_size = struct.unpack("<Q", data[hdr+32:hdr+40])[0]
                name = data[shstr_offset + sh_name_idx:].split(b"\x00")[0].decode("latin1", errors="ignore")
                sections[name] = (sh_offset, sh_size)
          
            if ".gnu.version_r" not in sections or ".dynstr" not in sections:
                return False
          
            dynstr_off, dynstr_size = sections[".dynstr"]
            verneed_off, verneed_size = sections[".gnu.version_r"]
      
            dynstr = data[dynstr_off : dynstr_off + dynstr_size]
            idx_227 = dynstr.find(b"GLIBC_2.27\x00")
            idx_225 = dynstr.find(b"GLIBC_2.2.5\x00")
      
            if idx_227 == -1 or idx_225 == -1:
                return False
          
            hash_225 = 0x09691a75
            curr_vn = verneed_off
            modified = False
            while curr_vn and (curr_vn < verneed_off + verneed_size):
                vn_cnt = struct.unpack("<H", data[curr_vn+2:curr_vn+4])[0]
                vn_aux = struct.unpack("<I", data[curr_vn+8:curr_vn+12])[0]
                vn_next = struct.unpack("<I", data[curr_vn+12:curr_vn+16])[0]
          
                curr_vna = curr_vn + vn_aux
                for _ in range(vn_cnt):
                    vna_name = struct.unpack("<I", data[curr_vna+8:curr_vna+12])[0]
                    vna_next = struct.unpack("<I", data[curr_vna+12:curr_vna+16])[0]
              
                    if vna_name == idx_227:
                        data[curr_vna : curr_vna+4] = struct.pack("<I", hash_225)
                        data[curr_vna+8 : curr_vna+12] = struct.pack("<I", idx_225)
                        modified = True
                  
                    if vna_next == 0:
                        break
                    curr_vna += vna_next
              
                if vn_next == 0:
                    break
                curr_vn += vn_next
          
            if modified:
                f.seek(0)
                f.write(data)
                print(f"[PATCHED] {filepath}")
                return True
    except Exception as e:
        pass
    return False

env_prefix = os.environ.get("CONDA_PREFIX", "")
if env_prefix:
    for root, dirs, files in os.walk(env_prefix):
        for f in files:
            if f.endswith(".so") or ".so." in f:
                patch_elf_verneed(os.path.join(root, f))
EOF
```

### 2.5 Install Fermi GBM Data Tools (Optional)

```bash
mamba install -n fermi --override-channels -c conda-forge pip -y
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

### 3.1 Create the Environment with XSPEC, ThreeML & Astromodels

> [!IMPORTANT]
> The latest NASA build (`xspec 13.x`) is compiled against Python 3.14, which breaks `threeML` and `astromodels` (which only support up to Python 3.12). We explicitly pin **`xspec=12.15.1`** and **`python=3.12`** so the entire scientific stack installs with 100% compatibility in one go.

> [!WARNING]
> The HEASARC server is notoriously slow and frequently times out on this institute's firewall. If the `mamba create` command below fails with a "Timeout was reached (28)" error, you MUST download the package on your local laptop and SCP it to the server (see workaround below).

**Standard Installation:**

```bash
mamba create -n threeML \
  --override-channels \
  -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ \
  -c threeml \
  -c conda-forge \
  xspec=12.15.1 python=3.12 threeml astromodels ipykernel pip -y
```

**Timeout Workaround (If the above fails):**

1. On your **local laptop** (not the server), download and transfer the file:
   ```bash
   curl -L -o ~/xspec-12.15.1-hb0f4dca_1.conda "https://heasarc.gsfc.nasa.gov/FTP/software/conda/linux-64/xspec-12.15.1-hb0f4dca_1.conda"
   scp ~/xspec-12.15.1-hb0f4dca_1.conda shashi@172.18.1.5:~/
   ```
2. On the **server**, place it in the cache so mamba skips the download:
   ```bash
   CACHE_DIR=$(conda info | grep "package cache" | head -1 | awk '{print $NF}')
   mkdir -p "$CACHE_DIR"
   cp ~/xspec-12.15.1-hb0f4dca_1.conda "$CACHE_DIR/"

   mamba create -n threeML \
     --override-channels \
     -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ \
     -c threeml \
     -c conda-forge \
     xspec=12.15.1 python=3.12 threeml astromodels ipykernel pip -y
   ```

> HEASoft + XSPEC install inside the environment at `~/miniforge3/envs/threeML/heasoft/`. No separate HEASoft compilation needed.

### 3.2 Fix the Broken `heainit.sh` ⚠️ CRITICAL

The XSPEC conda package has a known bug where `heainit.sh` points to a non-existent `BUILD_DIR` path. **This fix must be reapplied every time XSPEC is updated or reinstalled.**

Replace `shashi` with your actual username (run `whoami` if unsure):

```bash
sed -i \
  's|export HEADAS=$CONDA_PREFIX/heasoft|export HEADAS=/home/shashi/miniforge3/envs/threeML/heasoft|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh

sed -i \
  's|$HEADAS/BUILD_DIR/headas-init.sh|$HEADAS/headas-init.sh|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh
```

Verify the fix:

```bash
cat ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh
```

Expected output:

```
#!/bin/bash
export HEADAS=/home/shashi/miniforge3/envs/threeML/heasoft
echo "activating heasoft in $HEADAS"
source $HEADAS/headas-init.sh
```

### 3.3 Fix conda-meta (If Needed)

Only if conda doesn't recognize the environment (`DirectoryNotACondaEnvironmentError`):

```bash
mkdir -p ~/miniforge3/envs/threeML/conda-meta
echo "# Created by manual fix" > ~/miniforge3/envs/threeML/conda-meta/history
```

### 3.4 Activate & Verify XSPEC

```bash
conda activate threeML
echo $HEADAS
xspec --version
```

Expected: `$HEADAS` prints the correct path, XSPEC launches (v12.15.1).

### 3.5 Update / Reinstall ThreeML & Astromodels (If Needed)

Because ThreeML and Astromodels were already installed in Step 3.1, this step is only needed if you ever want to update them:

```bash
mamba install -n threeML \
  --override-channels \
  -c conda-forge \
  -c threeml \
  threeml astromodels -y
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

> [!NOTE]
> `pynchrotron` bundles an older `versioneer.py` using `configparser.SafeConfigParser` and `readfp`, which were removed in Python 3.12. We patch both functions before running `pip install`:

```bash
# 1. Clone to temporary directory
cd /tmp
rm -rf /tmp/pynchrotron
git clone --depth 1 https://github.com/grburgess/pynchrotron.git
cd pynchrotron

# 2. Patch the two removed functions for Python 3.12
sed -i 's/SafeConfigParser/ConfigParser/g' versioneer.py
sed -i 's/readfp/read_file/g' versioneer.py

# 3. Install cleanly using the existing conda dependencies
python -m pip install --no-build-isolation .

# 4. Clean up temporary directory
cd ~
rm -rf /tmp/pynchrotron

# 5. Verify import
python -c "import pynchrotron; print('pynchrotron OK')"
```

### 3.9 Register the Jupyter Kernel

```bash
mamba install -n threeML --override-channels -c conda-forge ipykernel -y
python -m ipykernel install --user --name threeML --display-name "Python (threeML)"
```

---

## 4. Part C — VegasAfterglow

VegasAfterglow is a GRB afterglow modeling engine with MCMC support. On the server, we install only the **Python library** (no web tool needed — the web UI is designed for local workstations).

### 4.1 Create the VegasAfterglow Environment

```bash
mamba create -n vegas_env \
  --override-channels \
  -c conda-forge \
  python=3.11 -y
conda activate vegas_env
```

### 4.2 Install Dependencies and the Physics Engine

> [!IMPORTANT]
> Because CentOS 7 has ancient compilers, installing `scipy` via `pip` will fail to compile. We must pre-install the heavy math and MCMC dependencies using `mamba` first.

```bash
# 1. Pre-install pip and heavy dependencies via conda-forge
mamba install -n vegas_env \
  --override-channels \
  -c conda-forge \
  pip scipy numpy bilby emcee dynesty corner matplotlib -y

# 2. Install VegasAfterglow (pip will skip compiling the dependencies above)
python -m pip install VegasAfterglow[mcmc]
```

> [!NOTE]
> We install `pip` explicitly inside the Conda environment to avoid conflicts and ensure packages go into the isolated environment, not the system Python.

### 4.3 Register the Jupyter Kernel

```bash
mamba install -n vegas_env --override-channels -c conda-forge ipykernel -y
python -m ipykernel install --user --name=vegas_env --display-name="Python (VegasAfterglow)"
```

### 4.4 Verify the Installation

```bash
python -c "import VegasAfterglow; print('VegasAfterglow OK')"
```

---

## 5. Jupyter Kernel Registration (All Environments)

After completing the installations above, you should have three Jupyter kernels available:

| Kernel Display Name     | Conda Environment | What It Contains                                  |
| ----------------------- | ----------------- | ------------------------------------------------- |
| Python (fermi)          | `fermi`         | Fermitools (CentOS-compat), GTBurst, 3ML, Fermipy |
| Python (threeML)        | `threeML`       | XSPEC, HEASoft, 3ML, astromodels                  |
| Python (VegasAfterglow) | `vegas_env`     | VegasAfterglow + MCMC tools                       |

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

| Error                                             | Fix                                                                                                                       |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `conda: command not found`                      | Run`bash` first, then `source ~/.bashrc`                                                                              |
| `#: Command not found` or `Badly placed ()'s` | You're in**csh** — run `bash` first, then retry                                                                  |
| `(base)` not showing                            | Close terminal, reopen, type`bash`                                                                                      |
| `terminals database is inaccessible`            | Run`echo 'export TERM=xterm-256color' >> ~/.bashrc && source ~/.bashrc`                                                 |
| `conda` and `mamba` activate different envs   | Run`sed -i "s\|export MAMBA_ROOT_PREFIX=.*\|export MAMBA_ROOT_PREFIX='/home/shashi/miniforge3';\|" ~/.bashrc && exec bash` |

### Mamba / Network Issues

| Error                                                                | Cause                                                                              | Fix                                                                  |
| -------------------------------------------------------------------- | ---------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `Download error (28) Timeout was reached`                          | Institute firewall throttles parallel shard downloads                              | Run`conda config --set repodata_use_shards false` once, then retry |
| `Failed to download shard … Stopped by user request` after Ctrl+C | Ctrl+C interrupted shard downloads mid-flight, corrupting cache                    | Run`mamba clean --all -y` then retry the create command            |
| `warning: 'repo.anaconda.com', a commercial channel … is used`    | Default channels from`~/.condarc` are being queried (slow, Anaconda TOS warning) | Add`--override-channels` flag to your mamba command                |

### Fermitools Issues

| Error                                                                       | Fix                                                                                                                                                                                                 |
| --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GLIBC_2.27 not found` (`libLikelihood.so`)                             | Modern Fermitools (2.4.0+) requires`expf`/`logf` from GLIBC 2.27. Re-run Step 2.4 to apply the `.gnu.version_r` ELF patch to retarget them to `GLIBC_2.2.5` on CentOS 7.                    |
| `_tkinter.TclError: no display name and no $DISPLAY environment variable` | GTBurst is a GUI application. Launch it from an**X2Go** session (XFCE) or connect with trusted X11 forwarding: `ssh -Y shashi@172.18.1.5`.                                                  |
| `File __temp_ft1.fits does not exist!`                                    | Don't use GTBurst's built-in downloader — use`threeML` or download manually from [Fermi FSSC](https://fermi.gsfc.nasa.gov/cgi-bin/ssc/LAT/LATDataQuery.cgi), then use "Load User Data" in GTBurst |
| `FITSFixedWarning: 'datfix' made the change…`                            | **Not an error** — Astropy auto-fixes Fermi metadata date fields                                                                                                                             |
| `CALDB/Alias Missing Error`                                               | You forgot to activate: run`conda activate fermi` before launching Python                                                                                                                         |
| Permission denied on`gtapps_mp` scripts                                   | Re-run the patch from Step 2.4                                                                                                                                                                      |

### 3ML / XSPEC Issues

| Error                                      | Fix                                                                  |
| ------------------------------------------ | -------------------------------------------------------------------- |
| `BUILD_DIR/headas-init.sh: No such file` | Reapply the`heainit.sh` fix from Step 3.2                          |
| `DirectoryNotACondaEnvironmentError`     | Apply the conda-meta fix from Step 3.3                               |
| `ucx post-link script failed`            | Reapply Step 3.2 fix, then retry the install                         |
| `$HEADAS` is empty                       | Reapply Step 3.2, then`conda deactivate && conda activate threeML` |

### Maintenance

| Task                      | Command                                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------------------------------- |
| Update Fermitools         | `mamba update -n fermi --override-channels -c conda-forge -c fermi fermitools -y` (re-patch Step 2.4 after) |
| Update 3ML                | `mamba update -n threeML --override-channels -c threeml -c conda-forge threeml astromodels -y`              |
| Update VegasAfterglow     | `conda activate vegas_env && pip install --upgrade VegasAfterglow[mcmc]`                                    |
| Delete broken environment | `mamba env remove -n <env_name>` and redo from scratch                                                      |
| List all environments     | `conda env list`                                                                                            |
| Clean mamba cache         | `mamba clean --all -y`                                                                                      |

---

> **References:**
>
> - [Miniforge.md](file:///home/void/Cachyos-installation/Conda/Miniforge.md) — Miniforge installation & shell setup
> - [Fermitools and gtburst.md](<file:///home/void/Cachyos-installation/Conda/Fermitools%20and%20gtburst.md>) — Fermitools environment & patches
> - [ThreeML + XSPEC Installation Guide.md](<file:///home/void/Cachyos-installation/Conda/ThreeML%20+%20XSPEC%20Installation%20Guide.md>) — 3ML/XSPEC with `heainit.sh` fix
> - [vegasafterglow.md](file:///home/void/Cachyos-installation/vegasafterglow.md) — VegasAfterglow Python & web tool setup
> - [server_specs_and_x2go_guide.md](file:///home/void/Cachyos-installation/server_specs_and_x2go_guide.md) — Server specs & X2Go configuration
