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

Ran command: `conda run -n fermi gtselect`
Ran command: `conda run -n fermi python -c "from GtBurst.dataHandling import download_LAT_data; download_LAT_data(277.480, 61.790, 12.0, 608375325.707, 608375325.707+100, time_type='MET', data_type='Extended', destination_directory='.')"`
Ran command: `cat << 'EOF' > test_download.py
from threeML.utils.data_download.Fermi_LAT.download_LAT_data import LAT_dataset
from GtBurst.TriggerSelector import TriggerSelector

def find_met(grb_name):
    a = TriggerSelector()
    a.downloadList()
    for x in a.data:
        if x[0] == f"bn{grb_name}" or x[0] == grb_name or grb_name in x[0]:
            return float(x[1])
    return None

met = find_met("200412381")
print(f"MET: {met}")

lat_data = LAT_dataset()
try:
    lat_data.make_LAT_dataset(
        ra=277.480,
        dec=61.790,
        radius=12.0,
        trigger_time=met,
        tstart=-1000,
        tstop=1000,
        data_type="Extended",
        destination_directory=".",
        Emin=100.0,
        Emax=300000.0
    )
except Exception as e:
    import traceback
    traceback.print_exc()
EOF
conda run -n fermi python test_download.py`
Ran command: `cat /home/void/.gemini/antigravity-ide/brain/d90bf6e0-747f-4751-9fb3-dda492b90015/.system_generated/tasks/task-207.log`
Used tool: manage_task
Ran command: `ls -l *.fit *.rsp`
Ran command: `find . -name "*.fit"`

That is a brilliant observation, and it reveals a really fascinating overlap. You actually hit **two completely different bugs** that produce the exact same error (`OSError: File __temp_ft1.fits does not exist!`), which is why it was so confusing. 

Here is exactly what was happening:

1. **In Jupyter Notebook (The Environment Bug)**: `threeML` successfully downloaded the data, but when it handed the files to `gtselect` to extract the events, `gtselect` crashed because Jupyter didn't load your `FERMI_DIR` or `CALDB` environment variables. No `__temp_ft1.fits` was produced. (My previous kernel fix resolved this).
2. **In the GTBurst GUI (The Downloader Bug)**: The terminal environment was perfect. However, `GTBurst` is an older piece of software. The NASA Fermi FSSC server recently changed its HTTPS redirects and query structures. When you click "Download data" in the GTBurst GUI, its outdated built-in downloader silently fails and downloads a corrupted/HTML error file instead of the actual data. When `gtselect` tries to read this bad file, it crashes, and again, no `__temp_ft1.fits` is produced!

Because `threeML` has a modernized, robust data downloader built-in, using the Python notebook actually bypasses the GUI's broken downloader!

***

## Known Issue: "File __temp_ft1.fits does not exist!" in GTBurst GUI

If you attempt to use the built-in LAT data downloader in the GTBurst GUI, it may fail silently and throw an `OSError: File __temp_ft1.fits does not exist!` during the extraction phase.

**Why this happens:**
The NASA Fermi FSSC data servers have updated their HTTPS security and URL structures. The older downloader built into the GTBurst GUI cannot follow these redirects properly, resulting in it downloading an empty or corrupted file. When `gtselect` attempts to process this empty file, it crashes and fails to generate the required temporary files.

**How to fix it:**
Do not use the GTBurst GUI's "Download Data" button. Instead, either:
1. **Use `threeML` in Python to download the data** (its downloader is modernized and works perfectly).
2. **Download manually** via the [Fermi FSSC Data Server](https://fermi.gsfc.nasa.gov/cgi-bin/ssc/LAT/LATDataQuery.cgi). 
Once you have the `FT1` and `FT2` files on your disk, open the GTBurst GUI and select **"Load User Data"** instead of trying to download it through the interface.
