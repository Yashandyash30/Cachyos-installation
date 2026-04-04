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
| Breakage risk on rolling | High | Very low |
| Recovery | Painful | Remove env and reinstall |
