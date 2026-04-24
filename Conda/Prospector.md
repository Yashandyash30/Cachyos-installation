# Prospector Installation Guide
### CachyOS · Fish Shell · Niri · Conda

This guide bypasses every known trap when installing Prospector on CachyOS: PyPI naming collisions, system compiler mismatches, Niri/Wayland display issues, and library version mismatches.

---

## Part 1 — Clean Slate

Remove any previous broken attempts entirely before starting. Leftover environments and stale kernels cause silent failures that are hard to trace.

```fish
# Deactivate any running environment
conda deactivate

# Remove the old environment
mamba env remove -n prospector -y

# Remove the old experimental repo if it exists
rm -rf ~/Prospectus/prospector

# Remove the stale Jupyter kernel so VS Code doesn't load the wrong one
jupyter kernelspec uninstall prospector -y

```

> If conda isn't responding in Fish, re-initialize it:
>
> ```code snippet
> ~/miniforge3/condabin/conda init fish
> ```
> Then restart your terminal and try again.
>

---

## Part 2 — Download the FSPS Data

Prospector requires the raw Fortran stellar population data tables to be present locally on your machine before any Python code can run.

```code snippet
mkdir -p ~/Prospectus
cd ~/Prospectus

git clone [https://github.com/cconroy20/fsps.git](https://github.com/cconroy20/fsps.git)
```

---

## Part 3 — Build the Conda Environment

Lock the environment to Python 3.11 and install the Fortran compilers **inside Conda**, not from the system. This isolates the build from CachyOS's rapidly updating system compilers, which frequently cause linker errors on Arch-based systems.

> **The Dynesty Version Mismatch:** This is a classic library version mismatch. Prospector 1.4.1 has a `try/except` block specifically looking for older Dynesty formats. The Dynesty developers recently updated their sampler to return a new number of values in that tuple (16 values). Prospector 1.4.1 doesn't know how to unpack the new Dynesty format, so it crashes. To correct for this, we must downgrade dynesty to the "Goldilocks" version that Prospector 1.4.1 was specifically built to handle: **version 2.0.3**.
>
>

```code snippet
mamba create -n prospector \
python=3.11 \
dynesty=2.0.3 \
astroquery \
h5py \
matplotlib \
astropy \
threadpoolctl \
ipykernel \
fortran-compiler \
compilers \
-y
```

Then activate it:

```code snippet
conda activate prospector
```

---

## Part 4 — Set Environment Variables

Two issues specific to Fish + Niri need to be fixed here:

- Fish doesn't read `~/.bashrc`, so `SPS_HOME` must be set permanently using `set -Ux`
- Niri has no default browser set, which causes Jupyter to crash when it tries to open a tab

### Step 4.1 — Set SPS_HOME

Set it in Fish permanently and also bake it into the Conda environment as a failsafe:

```code snippet
# Permanent Fish variable (survives reboots and new terminals)
set -Ux SPS_HOME $HOME/Prospectus/fsps

# Also set it inside the Conda environment directly
conda env config vars set SPS_HOME="$HOME/Prospectus/fsps"
```

### Step 4.2 — Set a default browser for Jupyter under Niri

```code snippet
set -Ux BROWSER /usr/bin/zen-browser
```

### Step 4.3 — Cycle the environment to lock in the variables

```code snippet
conda deactivate
conda activate prospector
```

---

## Part 5 — Compile and Install Packages

### Why not just `pip install sedpy`?

There is a PyPI naming collision — the plain `sedpy` package on PyPI is a different, unrelated project. You must install `astro-sedpy` instead. Similarly, use `astro-prospector` rather than `prospector` (which installs a Python code linter, not the galaxy SED fitter).

### Step 5.1 — Point the compiler flags to Conda's internal libraries

This prevents CachyOS's system linker from interfering during the Fortran `fsps` build:

```code snippet
set -gx LDFLAGS "-L$CONDA_PREFIX/lib"
set -gx CPPFLAGS "-I$CONDA_PREFIX/include"
```

### Step 5.2 — Install the packages in order

```code snippet
# 1. Fortran FSPS wrapper
python -m pip install fsps

# 2. Correct sedpy (NOT plain "sedpy")
python -m pip install astro-sedpy

# 3. Correct Prospector (NOT plain "prospector")
python -m pip install astro-prospector
```
---

## Part 6 — Register the Jupyter Kernel

Register the environment with a clear, unmistakable label so you always know which kernel VS Code is using:

```code snippet
python -m ipykernel install --user \
--name=prospector \
--display-name="PROSPECTOR (Stable Release)"
```
---

## Part 7 — The Final Verification

Open VS Code/Jupyter, select your brand new PROSPECTOR (Stable Release) kernel, and run this to confirm you are on the safe version:

```python
import prospect
import fsps
import dynesty

print("--- STABLE SYSTEM CHECK ---")
print(f"Prospector version: {prospect.__version__}")
print(f"FSPS version:       {fsps.__version__}")
print(f"Dynesty version:    {dynesty.__version__}")
```
---

## Quick Reference

```
Environment name      prospector
Python version        3.11
Dynesty version       2.0.3
FSPS data path        ~/Prospectus/fsps
SPS_HOME (Fish)       set -Ux SPS_HOME $HOME/Prospectus/fsps
Activate env          conda activate prospector
Rebuild from scratch  start from Part 1

Correct pip packages:
fsps                python -m pip install fsps
sedpy               python -m pip install astro-sedpy      ← NOT "sedpy"
prospector          python -m pip install astro-prospector ← NOT "prospector"
```

### Common mistakes that break the install

| Mistake | Result | Fix |
| --- | --- | --- |
| `pip install sedpy` | Installs wrong package (code linter) | Use `astro-sedpy` |
| `pip install prospector` | Installs wrong package (code linter) | Use `astro-prospector` |
| Installing latest Dynesty | `ValueError: too many values to unpack` | Pin `dynesty=2.0.3` via conda/mamba |
| Elephant/Conda not init'd in Fish | `conda: command not found` | Run `~/miniforge3/condabin/conda init fish` |
| Using system Fortran compiler | Linker errors during `fsps` build | Install `fortran-compiler compilers` via mamba |

Export to Sheets
