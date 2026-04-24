# Prospector Installation Guide
### CachyOS · Fish Shell · Niri · Conda

This guide bypasses every known trap when installing Prospector on CachyOS: PyPI naming collisions, system compiler mismatches, Niri/Wayland display issues, and Fortran CPU deadlocks.

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
> ```fish
> ~/miniforge3/condabin/conda init fish
> ```
> Then restart your terminal and try again.

---

## Part 2 — Download the FSPS Data

Prospector requires the raw Fortran stellar population data tables to be present locally on your machine before any Python code can run.

```fish
mkdir -p ~/Prospectus
cd ~/Prospectus

git clone https://github.com/cconroy20/fsps.git
```

---

## Part 3 — Build the Conda Environment

Lock the environment to Python 3.11 and install the Fortran compilers **inside Conda**, not from the system. This isolates the build from CachyOS's rapidly updating system compilers, which frequently cause linker errors on Arch-based systems.

```fish
mamba create -n prospector \
    python=3.11 \
    dynesty \
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

```fish
conda activate prospector
```

---

## Part 4 — Set Environment Variables

Two issues specific to Fish + Niri need to be fixed here:

- Fish doesn't read `~/.bashrc`, so `SPS_HOME` must be set permanently using `set -Ux`
- Niri has no default browser set, which causes Jupyter to crash when it tries to open a tab

### Step 4.1 — Set SPS_HOME

Set it in Fish permanently and also bake it into the Conda environment as a failsafe:

```fish
# Permanent Fish variable (survives reboots and new terminals)
set -Ux SPS_HOME $HOME/Prospectus/fsps

# Also set it inside the Conda environment directly
conda env config vars set SPS_HOME="$HOME/Prospectus/fsps"
```

### Step 4.2 — Set a default browser for Jupyter under Niri

```fish
set -Ux BROWSER /usr/bin/zen-browser
```

### Step 4.3 — Cycle the environment to lock in the variables

```fish
conda deactivate
conda activate prospector
```

---

## Part 5 — Compile and Install Packages

### Why not just `pip install sedpy`?

There is a PyPI naming collision — the plain `sedpy` package on PyPI is a different, unrelated project. You must install `astro-sedpy` instead. Similarly, use `astro-prospector` rather than `prospector` (which installs a Python code linter, not the galaxy SED fitter).

### Step 5.1 — Point the compiler flags to Conda's internal libraries

This prevents CachyOS's system linker from interfering during the Fortran `fsps` build:

```fish
set -gx LDFLAGS "-L$CONDA_PREFIX/lib"
set -gx CPPFLAGS "-I$CONDA_PREFIX/include"
```

### Step 5.2 — Install the packages in order

```fish
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

```fish
python -m ipykernel install --user \
    --name=prospector \
    --display-name="PROSPECTOR (Stable 3.11)"
```

---

### Part 7 : The Final Verification
Open VS Code/Jupyter, select your brand new PROSPECTOR (Stable Release) kernel, and run this to confirm you are on the safe version:

```fish
import prospect
import fsps
import dynesty

print("--- STABLE SYSTEM CHECK ---")
print(f"Prospector version: {prospect.__version__}")
print(f"FSPS version:       {fsps.__version__}")
print(f"Dynesty version:    {dynesty.__version__}")
```


## Part 8 — Anti-Deadlock Notebook Setup

**This is mandatory.** Prospector's Fortran `compute_zdep` function will silently deadlock your CPU if it's allowed to spawn multiple threads. The fix must be applied before any other import in your notebook.

Make this **Cell 1** of every Prospector notebook:

```python
import os

# Kill all Fortran/C multithreading before any imports
# These must be set before numpy, fsps, or prospect are imported
os.environ["OMP_NUM_THREADS"]          = "1"
os.environ["MKL_NUM_THREADS"]          = "1"
os.environ["NUMEXPR_NUM_THREADS"]      = "1"
os.environ["OPENBLAS_NUM_THREADS"]     = "1"
os.environ["VECLIB_MAXIMUM_THREADS"]   = "1"

# Verify the full pipeline loaded correctly
import prospect
import fsps
import dynesty
import sedpy

print("--- SYSTEM CHECK ---")
print(f"Prospector : {prospect.__version__}")
print(f"FSPS       : {fsps.__version__}")
print(f"Dynesty    : {dynesty.__version__}")
print(f"Sedpy      : {sedpy.__version__}")
print(f"SPS_HOME   : {os.environ.get('SPS_HOME')}")

print("\nInitialising Fortran engines...")
try:
    sp = fsps.StellarPopulation(zcontinuous=1)
    print("✅ Pipeline is operational.")
except Exception as e:
    print(f"❌ Error: {e}")
```

> Select the **PROSPECTOR (Stable 3.11)** kernel in VS Code before running this cell (bottom-right corner of the notebook interface).

---

## Quick Reference

```
Environment name      prospector
Python version        3.11
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
|---|---|---|
| `pip install sedpy` | Installs wrong package (code linter) | Use `astro-sedpy` |
| `pip install prospector` | Installs wrong package (code linter) | Use `astro-prospector` |
| Missing thread limiters in Cell 1 | CPU deadlock on `compute_zdep` | Add all 5 `os.environ` lines before any imports |
| Elephant/Conda not init'd in Fish | `conda: command not found` | Run `~/miniforge3/condabin/conda init fish` |
| Using system Fortran compiler | Linker errors during `fsps` build | Install `fortran-compiler compilers` via mamba |
