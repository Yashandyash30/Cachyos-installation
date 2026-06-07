Viewed LAT_Analysis_GRB250919A.py:1-45

Here is the updated guide. I have added **Step 2: Install ThreeML, Fermipy, and Jupyter Support** to pull in the tools required for likelihood analysis and notebook integration, and **Step 4: Using Jupyter Notebooks** to ensure the environment variables load correctly.

***

# Fermitools & GTBurst Installation Guide (Arch/CachyOS)

> GTBurst is bundled directly inside the Fermitools package. Installing Fermitools gives you GTBurst automatically — no separate repository needed.

---

## Important: Shell Requirement

Conda's `activate` mechanism relies on bash hooks and is unreliable under Fish. **Switch to bash before proceeding.**

```bash
bash
```

> All steps below must be run inside a bash session.

---

## Step 1: Install Fermitools

Create a new dedicated conda environment called `fermi`. Locking to Python 3.9 ensures the correct older GUI dependencies are pulled in automatically.

```bash
mamba create -n fermi \
  -c conda-forge \
  -c fermi \
  fermitools=2.2.0 python=3.9
```

---

## Step 2: Install ThreeML, Fermipy, and Jupyter Support

To perform advanced likelihood fitting (like Bayesian blocks for prompt/extended GRB phases), you need to install 3ML and Fermipy into this same environment so they can utilize the `fermitools` underlying structure. We also install `jupyter` and `ipykernel`.

```bash
mamba install -n fermi \
  -c conda-forge \
  -c threeml \
  threeml fermipy jupyter ipykernel
```

---

## Step 3: Activate the Environment

```bash
mamba activate fermi
```

---

## Step 4: Using Jupyter Notebooks (For ThreeML/Fermipy)

When using Jupyter Notebooks to run `ThreeML` or `TransientLATDataBuilder`, **you must launch Jupyter from inside the activated `fermi` environment.** Fermitools relies on environment variables (like `$FERMI_DIR` and `$CALDB`) that are only set when the conda environment is explicitly activated in your terminal.

1. First, register the kernel so Jupyter recognizes it:
   ```bash
   python -m ipykernel install --user --name fermi --display-name "Python (fermi)"
   ```
2. Launch Jupyter Lab or Notebook directly from the activated bash session:
   ```bash
   jupyter lab
   ```
3. Inside Jupyter, ensure your notebook's kernel is set to **`Python (fermi)`**.

---

## Step 5: Launch GTBurst

To use the interactive GUI:

```bash
gtburst
```

> GTBurst will load as **pyBurstAnalysisGUI v. 03-00-00p5**, ready for LAT/GBM data download, unbinned likelihood analyses, and `.pha` file generation for ThreeML.

---

## Wayland Compatibility

On CachyOS with KDE Plasma, if the GTBurst window looks glitchy or refuses to open, force it through XWayland:

```bash
QT_QPA_PLATFORM=xcb gtburst
```

> If GTBurst opens smoothly on first launch, this step is not needed.

---

## Maintenance Tips

| Scenario | Action |
|---|---|
| **Update Fermitools** | `mamba update fermitools -c conda-forge -c fermi` |
| **Broken environment** | Run `mamba env remove -n fermi` and repeat the installation steps |
| **GTBurst GUI issues** | Always try `QT_QPA_PLATFORM=xcb gtburst` first before debugging further |
| **CALDB/Alias Missing Error** | This means your `FERMI_DIR` variables aren't set. Ensure you ran `mamba activate fermi` before launching Python/Jupyter. |

---

## Why This Setup Is Safe on a Rolling Release

Fermitools is installed via conda-forge and the official Fermi channel. Like HEASoft, the environment bundles its own runtime libraries — `pacman -Syu` updating system GLIBC does not affect this environment.
