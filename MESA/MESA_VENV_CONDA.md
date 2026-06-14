To set up a `mamba` environment for MESA (Modules for Experiments in Stellar Astrophysics) data analysis, you will want to pull the core scientific stack and `ipykernel` from the `conda-forge` channel.

There is one important caveat: while `conda-forge` has an agent-based modeling package called `mesa`, the astrophysics package you need (`mesa_reader`) is only hosted on PyPI. Therefore, the standard workflow is to build the environment with `mamba` and then install the reader via `pip`.

Here are the exact steps to get everything running seamlessly:

### 1. Create the Environment

Run this command to create a new environment (named `mesa_env`) and install Python, `ipykernel`, and the standard data analysis stack from `conda-forge`:

```bash
mamba create -n mesa_env -c conda-forge python=3.11 ipykernel numpy matplotlib pandas scipy pillow

```

### 2. Activate the Environment

Once mamba finishes resolving and downloading the packages, activate the environment:

```bash
mamba activate mesa_env

```

### 3. Install `mesa_reader` via pip

With your environment active, use `pip` to pull the MESA reader package:

```bash
python -m pip install mesa-reader

```

### 4. Register the Kernel for Jupyter

To ensure this environment shows up as a selectable kernel in your Jupyter Notebooks, JupyterLab, or VS Code, register it with `ipykernel`:

```bash
python -m ipykernel install --user --name mesa_env --display-name "Python (MESA)"

```

### 5. Verify the Setup

The next time you open a Jupyter Notebook, select the **"Python (MESA)"** kernel from your dropdown menu. You can verify the installation by running:

```python
import mesa_reader as mr
import matplotlib.pyplot as plt
import pandas as pd

print("MESA environment is ready!")

```
