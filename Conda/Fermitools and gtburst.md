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

## Step 1: The "Bulletproof" Environment Creation

Create a new dedicated conda environment called `fermi`. By locking Python to 3.9 and pinning older versions of `numpy` and `astropy`, we prevent the modern Python ecosystem from breaking the older GTBurst scripts.

```bash
mamba create -n fermi \
  -c conda-forge \
  -c fermi \
  fermitools=2.2.0 python=3.9 "numpy<1.24" "astropy<6.0" aplpy

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

## Step 4: The Master Pre-Flight Patch Script

Even with pinned packages, there are a few hardcoded bugs in the Fermitools installation (like missing executable permissions and outdated `aplpy` plotting syntax) that must be fixed.

With your `fermi` environment activated, copy and paste this entire block into your terminal to automatically patch the software:

```bash
# 1. Fix the permissions bug for all multiprocessing scripts
chmod +x $CONDA_PREFIX/lib/python3.9/site-packages/fermitools/GtBurst/gtapps_mp/*.py

# 2. Fix the Numpy float deprecation in Likelihood analysis
sed -i 's/num.float/float/g' $CONDA_PREFIX/lib/python3.9/site-packages/fermitools/UnbinnedAnalysis.py

# 3. Fix the Aplpy plotting deprecations in the interactive display
sed -i 's/set_tick_labels_font/tick_labels.set_font/g' $CONDA_PREFIX/lib/python3.9/site-packages/fermitools/GtBurst/commands/gtdolike.py
sed -i 's/set_axis_labels_font/axis_labels.set_font/g' $CONDA_PREFIX/lib/python3.9/site-packages/fermitools/GtBurst/commands/gtdolike.py
sed -i 's/show_grid/add_grid/g' $CONDA_PREFIX/lib/python3.9/site-packages/fermitools/GtBurst/commands/gtdolike.py

```

---

## Step 5: Set Up Persistent Logging Aliases

GTBurst outputs critical Likelihood fitting data directly into the terminal. To ensure you never lose this data, add timestamped logging aliases to your system.

1. Open your bash configuration file:
```bash
nano ~/.bashrc

```


2. Paste these at the bottom of the file:
```bash
# Fermi gtburst logging aliases
alias gtburst-log='gtburst 2>&1 | tee "gtburst_$(date +%Y%m%d_%H%M%S).log"'
alias gtburst-quiet='gtburst > "gtburst_$(date +%Y%m%d_%H%M%S).log" 2>&1'

```


3. Save, exit, and apply:
```bash
source ~/.bashrc

```



---

## Step 6: Using Jupyter Notebooks (For ThreeML/Fermipy)

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

## Step 7: Launch GTBurst

To use the interactive GUI, use your new logging alias instead of the standard command:

```bash
gtburst-log

```

> GTBurst will load as **pyBurstAnalysisGUI v. 03-00-00p5**, ready for LAT/GBM data download, unbinned likelihood analyses, and `.pha` file generation for ThreeML.

---

## Wayland Compatibility

On CachyOS with KDE Plasma, if the GTBurst window looks glitchy or refuses to open, force it through XWayland:

```bash
QT_QPA_PLATFORM=xcb gtburst-log

```

> If GTBurst opens smoothly on first launch, this step is not needed.

---

## Known Issues & Operational Best Practices

### 1. "File __temp_ft1.fits does not exist!" in GTBurst GUI

If you attempt to use the built-in LAT data downloader in the GTBurst GUI, it may fail silently and throw an `OSError` during the extraction phase.

**Why this happens:** The NASA Fermi FSSC data servers have updated their HTTPS security and URL structures. The older downloader built into the GTBurst GUI cannot follow these redirects properly, resulting in it downloading an empty or corrupted file.

**How to fix it:** Do not use the GTBurst GUI's "Download Data" button. Instead, either:

* **Use `threeML` in Python to download the data** (its downloader is modernized and works perfectly).
* **Download manually** via the [Fermi FSSC Data Server](https://fermi.gsfc.nasa.gov/cgi-bin/ssc/LAT/LATDataQuery.cgi).

Once you have the `FT1` and `FT2` files on your disk, open the GTBurst GUI and select **"Load User Data"** instead of trying to download it through the interface.

### 2. Ignoring "FITSFixedWarning"

During likelihood analysis or plotting, you may see a wall of text in the terminal warning that `'datfix' made the change 'Invalid DATE-OBS format'`. **This is not an error.** The standard Fermi data pipeline leaves these date fields blank in favor of MJD format; Astropy is simply fixing the metadata formatting for you in the background.

---

## Maintenance Tips

| Scenario | Action |
| --- | --- |
| **Update Fermitools** | `mamba update fermitools -c conda-forge -c fermi` |
| **Broken environment** | Run `mamba env remove -n fermi` and repeat the installation steps |
| **GTBurst GUI issues** | Always try `QT_QPA_PLATFORM=xcb gtburst` first before debugging further |
| **CALDB/Alias Missing Error** | This means your `FERMI_DIR` variables aren't set. Ensure you ran `mamba activate fermi` before launching Python/Jupyter. |

---

## Why This Setup Is Safe on a Rolling Release

Fermitools is installed via conda-forge and the official Fermi channel. Like HEASoft, the environment bundles its own runtime libraries — `pacman -Syu` updating system GLIBC does not affect this environment.

Viewed plot_panels.py:111-138
Ran command: `conda run -n fermi python -c "
import gdt.missions.fermi.gbm.tte as tte
from gdt.core.binning.unbinned import bin_by_time
from gdt.core.background.fitter import BackgroundFitter
from gdt.core.background.binned import Polynomial

n6 = tte.GbmTte.open('glg_tte_n6_bn200412381_v00.fit.gz')
phaii = n6.to_phaii(bin_by_time, 1.0)
bkgd = BackgroundFitter.from_phaii(phaii, Polynomial, time_ranges=[(-10.0, -2.0), (20.0, 30.0)])
bkgd.fit(order=1)
bkg_phaii = bkgd.interpolate_bins(phaii.data.tstart, phaii.data.tstop)

lc_data = phaii.to_lightcurve(energy_range=(8.0, 50.0))
lc_bkg = bkg_phaii.integrate_energy(8.0, 50.0)
print('Data counts shape:', lc_data.counts.shape)
print('Bkg counts shape:', lc_bkg.counts.shape)
print('Bkg object type:', type(lc_bkg))
print('Data time centroids:', lc_data.centroids[:3])
"`
Ran command: `echo 'Waiting for task-246'`
Edited plot_panels.py
Ran command: `conda run -n fermi python plot_panels.py`
Ran command: `echo 'Waiting for task-256'`
Ran command: `conda run -n fermi python -c "
import gdt.missions.fermi.gbm.tte as tte
from gdt.core.binning.unbinned import bin_by_time

n6 = tte.GbmTte.open('glg_tte_n6_bn200412381_v00.fit.gz')
phaii = n6.to_phaii(bin_by_time, 1.0)
lc = phaii.to_lightcurve(energy_range=(8.0, 50.0))
print(dir(lc))
"`
Ran command: `echo 'Waiting for task-263'`
Edited plot_panels.py
Ran command: `conda run -n fermi python plot_panels.py`
Ran command: `echo 'Waiting for task-273'`



```bash
pip install astro-gdt astro-gdt-fermi
```
*(These are the modern, official Fermi GBM Data Tools supported by the GBM team).*

