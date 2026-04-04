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

## Step 2: Activate the Environment

```bash
mamba activate fermi
```

---

## Step 3: Launch GTBurst

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
| **Broken environment** | Run `mamba env remove -n fermi` and repeat Steps 1–2 |
| **GTBurst GUI issues** | Always try `QT_QPA_PLATFORM=xcb gtburst` first before debugging further |

---

## Why This Setup Is Safe on a Rolling Release

Fermitools is installed via conda-forge and the official Fermi channel. Like HEASoft, the environment bundles its own runtime libraries — `pacman -Syu` updating system GLIBC does not affect this environment.
