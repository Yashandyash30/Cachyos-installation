# Complete Astrophotometry Pipeline Setup Guide
### CachyOS · Conda · Astrometry.net · Jupyter

---

## Part 1 — Create the Conda Environment

Install all core libraries in one command using `conda-forge`, which has the most up-to-date and properly compiled binaries for Linux astrophysics packages.

```bash
conda create -n astro_photometry -c conda-forge \
    python=3.11 \
    astropy \
    photutils \
    ccdproc \
    scipy \
    matplotlib \
    astroscrappy \
    jupyter \
    ipykernel
```

> **Why conda-forge?** Packages like `astroscrappy` contain compiled C-extensions and OpenMP code. Conda handles those non-Python dependencies (C compilers, system libraries) far better than pip, especially on Arch-based systems.

---

## Part 2 — Install the Astrometry.net Engine

The plate-solving engine must be installed *inside* your environment to keep it isolated from your system packages.

### 2a. Activate the environment

```bash
conda activate astro_photometry
```

### 2b. Install the engine

```bash
conda install -c conda-forge astrometry
```

### 2c. Verify the install path

```bash
which solve-field
```

Expected output should be inside your environment, something like:

```
/home/void/miniforge3/envs/astro_photometry/bin/solve-field
```

If it points there, you're good. If it points to `/usr/bin/`, the system package took priority — reinstall with the conda-forge flag.

---

## Part 3 — Download the Star Catalog Index Files

Astrometry.net needs pre-compiled star catalog index files to match against your images. For GRB afterglows and deep stacks, the **4200 series** (based on the 2MASS catalog) is standard.

You need scales **4203–4207**, which cover fields of view between roughly **2.8 and 16 arcminutes**.

### 3a. Create the data directory

```bash
mkdir -p ~/astrometry_data
cd ~/astrometry_data
```

### 3b. Download all index files

```bash
wget -r -l1 --no-parent -nd -A "index-4203-*.fits" http://data.astrometry.net/4200/
wget -r -l1 --no-parent -nd -A "index-4204-*.fits" http://data.astrometry.net/4200/
wget -r -l1 --no-parent -nd -A "index-4205-*.fits" http://data.astrometry.net/4200/
wget -r -l1 --no-parent -nd -A "index-4206-*.fits" http://data.astrometry.net/4200/
wget -r -l1 --no-parent -nd -A "index-4207-*.fits" http://data.astrometry.net/4200/
```

Each series has 12 sub-files (00–11). When complete you should have 60 `.fits` files total.

### Index scale reference

| Series | Field of View Coverage | Best for |
|---|---|---|
| 4203 | ~2.8 – 4 arcmin | Narrow-field, long focal length |
| 4204 | ~4 – 5.6 arcmin | Standard deep-sky imaging |
| 4205 | ~5.6 – 8 arcmin | Standard deep-sky imaging |
| 4206 | ~8 – 11 arcmin | Wider field setups |
| 4207 | ~11 – 16 arcmin | Wide-field setups |

> If you ever change your telescope or sensor to one with a significantly different field of view, download the corresponding additional series from `http://data.astrometry.net/4200/`.

---

## Part 4 — Create the Local Config File

This config file forces `solve-field` to use only your local downloaded files, disabling any internet lookups or system-wide directory searches.

```bash
nano ~/astrometry_data/local.cfg
```

Paste in the following:

```text
# Point the engine to your local index files
add_path /home/void/astrometry_data

# Enable multi-threading for faster solves
inparallel

# Stop searching if it takes longer than 5 minutes (prevents hanging on bad frames)
cpulimit 300
```

Save and exit (**Ctrl+O → Enter**, then **Ctrl+X**).

> **Important:** Replace `/home/void/` with your actual home directory path if different. You can confirm it by running `echo $HOME` in your terminal.

---

## Part 5 — Register the Jupyter Kernel

This makes your `astro_photometry` environment appear as a selectable kernel inside Jupyter Notebook and JupyterLab.

Make sure the environment is active, then run:

```bash
conda activate astro_photometry

python -m ipykernel install --user \
    --name=astro_photometry \
    --display-name="Python (Astro Photometry)"
```

### Using the kernel in Jupyter

1. Launch Jupyter from your terminal:
   ```bash
   jupyter notebook
   # or
   jupyter lab
   ```
2. Open your `.ipynb` file
3. Click the kernel name in the top-right corner (or go to **Kernel → Change Kernel**)
4. Select **Python (Astro Photometry)** from the list

---

## Part 6 — Python Integration (Plate Solving in a Pipeline)

Use `subprocess` to call `solve-field` from within your notebook or script, pointing it explicitly to your `local.cfg`.

```python
import subprocess
import os
from astropy.io import fits
from astropy.wcs import WCS

image_file = "your_raw_frame.fits"
config_path = "/home/void/astrometry_data/local.cfg"

# Run the local plate solver
result = subprocess.run([
    "solve-field", image_file,
    "--config", config_path,
    "--no-plots",   # skip visual overlays, speeds up processing
    "--overwrite"   # overwrite existing .new files if re-running
], capture_output=True, text=True)

solved_file = image_file.replace(".fits", ".new")

if os.path.exists(solved_file):
    print(f"✅ Successfully solved: {image_file}")

    # .new file contains the WCS solution embedded in the header
    data, header = fits.getdata(solved_file, header=True)
    wcs = WCS(header)

    # Rename to keep your workspace tidy
    os.rename(solved_file, "wcs_" + image_file)
else:
    print(f"❌ Plate solving failed for: {image_file}")
    print(result.stderr)  # print solver output to help diagnose failures
```

---

## Part 7 — Installing Additional Packages Later

### Rule of thumb

Always try `conda-forge` first. Only fall back to `pip` if the package isn't available there.

```bash
# Always activate first
conda activate astro_photometry

# Install via conda-forge (preferred)
conda install -c conda-forge astroquery

# Install via pip only if not on conda-forge
pip install some_package
```

Pip installs while your environment is active will be scoped to that environment only — they won't touch your system Python.

### Useful packages to add later

| Package | Purpose | Install |
|---|---|---|
| `astroquery` | Fetch FITS files from online archives (ESO, MAST, Simbad) | `conda-forge` |
| `specutils` | Spectral analysis and reduction | `conda-forge` |
| `reproject` | Reproject images to a common WCS | `conda-forge` |
| `sep` | Source extraction (faster alternative to SExtractor) | `conda-forge` |
| `astroalign` | Align images without WCS | `conda-forge` |
| `lacosmic` | Alternative cosmic ray rejection | `pip` |

---

## Quick Reference

```
Environment name       astro_photometry
Index files            ~/astrometry_data/index-42{03..07}-*.fits  (60 files)
Astrometry config      ~/astrometry_data/local.cfg
Jupyter kernel name    Python (Astro Photometry)
Activate environment   conda activate astro_photometry
Deactivate             conda deactivate
List environments      conda env list
```

### Rebuild from scratch (fresh CachyOS install)

```bash
# 1. Re-create the environment
conda create -n astro_photometry -c conda-forge python=3.11 astropy photutils ccdproc scipy matplotlib astroscrappy jupyter ipykernel

# 2. Activate and install the solver engine
conda activate astro_photometry
conda install -c conda-forge astrometry

# 3. Re-download index files (if not backed up)
mkdir -p ~/astrometry_data && cd ~/astrometry_data
for series in 4203 4204 4205 4206 4207; do
    wget -r -l1 --no-parent -nd -A "index-${series}-*.fits" http://data.astrometry.net/4200/
done

# 4. Re-create local.cfg (see Part 4)

# 5. Re-register the Jupyter kernel
python -m ipykernel install --user --name=astro_photometry --display-name="Python (Astro Photometry)"
```
