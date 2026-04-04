# ThreeML + XSPEC Installation Guide (CachyOS / Arch / miniforge3)

## Prerequisites

- miniforge3 or miniconda3 installed
- Using **bash** (not fish) for all conda commands
- Internet access

---

## Step 1 — Start a bash session

```bash
bash
```

All following commands must be run in bash, not fish.

---

## Step 2 — Clean up any previous failed attempts

```bash
conda deactivate
rm -rf ~/miniforge3/envs/threeML   # adjust path if using miniconda3
```

---

## Step 3 — Create the environment with XSPEC only

```bash
conda create -n threeML \
  -c https://heasarc.gsfc.nasa.gov/FTP/software/conda/ \
  -c conda-forge xspec
```

> Note: HEASoft + XSPEC install inside the env at `~/miniforge3/envs/threeML/heasoft/`.
> No separate HEASoft install is needed.

---

## Step 4 — Fix the broken heainit.sh (CRITICAL — do this before anything else)

The XSPEC conda package has a bug where `heainit.sh` points to a non-existent
`BUILD_DIR` path and uses `$CONDA_PREFIX` which resolves incorrectly during
post-link scripts. Fix both issues by hardcoding the correct path:
For Local:
```bash
sed -i \
  's|export HEADAS=$CONDA_PREFIX/heasoft|export HEADAS=/home/YOUR_USERNAME/miniforge3/envs/threeML/heasoft|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh

sed -i \
  's|$HEADAS/BUILD_DIR/headas-init.sh|$HEADAS/headas-init.sh|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh
```
For Distrobox:
```bash
sed -i \
  's|export HEADAS=$CONDA_PREFIX/heasoft|export HEADAS=/home/void/miniforge3/envs/threeML/heasoft|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh

sed -i \
  's|$HEADAS/BUILD_DIR/headas-init.sh|$HEADAS/headas-init.sh|' \
  ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh
```

Replace `YOUR_USERNAME` with your actual username (run `whoami` if unsure).

Verify the fix looks correct:
```bash
cat ~/miniforge3/envs/threeML/etc/conda/activate.d/heainit.sh
```

Expected output:
```bash
#!/bin/bash
export HEADAS=/home/YOUR_USERNAME/miniforge3/envs/threeML/heasoft
echo "activating heasoft in $HEADAS"
source $HEADAS/headas-init.sh
```

---

## Step 5 — Fix the conda-meta history file

If conda doesn't recognize the env (DirectoryNotACondaEnvironmentError):

```bash
mkdir -p ~/miniforge3/envs/threeML/conda-meta
echo "# Created by manual fix" > ~/miniforge3/envs/threeML/conda-meta/history
```

---

## Step 6 — Activate and verify XSPEC works

```bash
conda activate threeML
echo $HEADAS
xspec --version
```

Expected:
- `$HEADAS` prints `/home/YOUR_USERNAME/miniforge3/envs/threeML/heasoft`
- XSPEC launches and prints version (12.15.1 or newer)

---

## Step 7 — Install Python 3.11 + threeML

```bash
conda install -c conda-forge python=3.11
conda install -c threeml -c conda-forge astromodels threeml
```

> If the ucx error fires again during either install, immediately reapply the
> heainit.sh fix from Step 4 and retry.

---

## Step 8 — Verify threeML works

```bash
python -c "import threeML; print(threeML.__version__)"
python -c "import astromodels; print('astromodels ok')"
```

Expected output: version number (e.g. `2.5.0`) and `astromodels ok`.
The WARNING messages about naima, GSL, ebltable etc. are normal — they are
optional packages, not errors.

---

## Step 9 — Set performance env vars

```bash
conda env config vars set OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1
conda deactivate && conda activate threeML
```

---

## Step 10 — Set up Jupyter kernel for VS Code

```bash
conda install -c conda-forge ipykernel
python -m ipykernel install --user --name threeML --display-name "Python (threeML)"
```

In VS Code: open any `.ipynb` → kernel picker (top right) → **Python (threeML)**.

---

## Daily usage

```bash
bash                        # if using fish shell
conda activate threeML
python your_script.py       # or open VS Code and select the kernel
```

---

## Troubleshooting

| Error | Fix |
|---|---|
| `BUILD_DIR/headas-init.sh: No such file or directory` | Reapply Step 4 fix |
| `DirectoryNotACondaEnvironmentError` | Apply Step 5 fix |
| `ucx post-link script failed` | Reapply Step 4 fix, then retry the install |
| `xspec: command not found` in fish | Run `bash` first, then `conda activate threeML` |
| `$HEADAS` is empty | Reapply Step 4, then `conda deactivate && conda activate threeML` |
