This is the definitive, battle-tested master runbook for installing Prospector from scratch. It bypasses all the classic astrophysics software traps—Fortran compiler errors, ghost environment variables, and Jupyter naming confusion—in one clean sweep.

Bookmark this page or save it as a text file. Whenever you need to set this up on a new machine, just run down this list.

### Phase 1: The Clean Slate

Always start by ensuring no old environments or ghost configurations are lingering to ruin your path variables.

```bash
# Deactivate any active environments
mamba deactivate

# (Optional) Remove old/broken environments if you are starting over
mamba env remove -n prospector

```

### Phase 2: The Data Foundation

`python-fsps` requires the actual Fortran source code and data tables to exist locally on your machine before it can compile.

```bash
# Create a dedicated project directory
mkdir -p ~/Prospectus
cd ~/Prospectus

# Clone the heavy Fortran/Data repository
git clone https://github.com/cconroy20/fsps.git

# Clone the bleeding-edge Prospector repository
git clone https://github.com/bd-j/prospector.git

```

### Phase 3: The Mamba Build & The Compiler Quirk

We use Mamba to build the foundation (NumPy, SciPy, H5Py), and we immediately install the Fortran compiler. If you skip the compiler, `pip` will fail to build the C/Fortran bridges for FSPS later.

```bash
# Navigate into the Prospector folder
cd ~/Prospectus/prospector

# Create the environment from their official manifest
mamba env create -f environment.yml -n prospector

# Activate it
mamba activate prospector

# INSTALL THE COMPILER (The ultimate quirk fix)
mamba install -c conda-forge fortran-compiler

```

### Phase 4: The `SPS_HOME` Anchor

The Python wrapper needs to know where the Fortran data lives. Instead of relying on fragile shell scripts (`.bashrc` or `.config/fish`), we permanently burn the path into the Conda environment itself.

```bash
# Set the variable permanently for this specific environment
conda env config vars set SPS_HOME="$HOME/Prospectus/fsps"

# Cycle the environment to lock the variable into place
mamba deactivate
mamba activate prospector

```

### Phase 5: The Final Compilations

Now that the compilers are installed and the `SPS_HOME` beacon is lit, we use `pip` to actually build the customized astronomy packages.

```bash
# Compile and install the python-fsps wrapper
python -m pip install fsps

# Install Prospector itself from the local folder
python -m pip install .

```

### Phase 6: The Custom Jupyter Kernel

We install the Jupyter tools, register the kernel, and force a custom, unmissable display name so it never gets lost in a sea of generic "Python 3" labels.

```bash
# Install the kernel package
mamba install ipykernel

# Register it with your exact desired name
python -m ipykernel install --user --name=prospector --display-name="PROSPECTOR"

```

*Note: If you ever want to clean up old, broken Jupyter kernels showing up in VS Code, use `jupyter kernelspec list` to find them, and `jupyter kernelspec uninstall <name>` to delete them.*

### Phase 7: The Verification Test

Completely close and reopen Visual Studio Code to flush its cache. Open your `.ipynb` notebook, select the clearly labeled **PROSPECTOR** kernel from the top-right menu, and run this cell:

```python
import os
import numpy as np
import scipy
import h5py
import dynesty
import sedpy
import fsps
import prospect

print("--- SYSTEM CHECK ---")
print(f"Prospector version:  {prospect.__version__}")
print(f"SPS_HOME path:       {os.environ.get('SPS_HOME')}")

print("\nFiring up the Fortran engines...")
try:
sp = fsps.StellarPopulation(zcontinuous=1)
print("SUCCESS: Ready to model some galaxies!")
except Exception as e:
print(f"ERROR: {e}")

# Just for fun
import antigravity

```
