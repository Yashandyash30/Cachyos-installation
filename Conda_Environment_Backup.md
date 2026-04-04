# Conda Environment Backup Guide

> Snapper protects your system. It does not protect your conda environments. These live in `~/miniforge3/envs/` inside your home directory — outside Btrfs snapshot scope. This guide ensures every environment can be fully restored if something breaks.

---

## What the Export Does

`mamba env export` saves a complete snapshot of everything inside a conda environment — every package, every version, every dependency — into a `.yml` file.

Example output for `henv.yml`:

```yaml
name: henv
channels:
  - https://heasarc.gsfc.nasa.gov/FTP/software/conda/
  - conda-forge
dependencies:
  - heasoft=6.33
  - python=3.11
  - numpy=1.26.4
  - cfitsio=4.3.0
  # ... and so on
```

---

## Step 1: Export All Environments

Run these from your host terminal in bash:

```bash
bash   # if using fish shell

mamba env export -n henv     > henv.yml
mamba env export -n fermi    > fermi.yml
mamba env export -n threeML  > threeML.yml
mamba env export -n pyraf    > pyraf.yml
```

---

## Step 2: Store the Files Somewhere Safe

Do not keep these only in your home directory. Back them up to at least one of:

- A git repository
- Nextcloud / any cloud storage
- A USB drive

These files are a few KB each but save hours of debugging if an environment breaks.

---

## Step 3: Restore a Broken Environment

If an environment ever breaks beyond repair, do not attempt to fix it. Remove it and rebuild from the backup:

```bash
mamba env remove -n henv
mamba env create -f henv.yml
```

Repeat with the relevant `.yml` for whichever environment broke.

---

## When Conda Environments Can Break

| Cause | Effect |
|---|---|
| Bad `mamba update` pulling incompatible dependency | Broken imports or runtime crashes |
| Python version bump breaking compiled extensions | Tool-specific failures |
| heainit.sh overwritten after XSPEC update | XSPEC/ThreeML activation failure |
| Accidental `pip install` conflicting with conda | Subtle dependency conflicts |

---

## Maintenance Tip

Re-export your environments after any significant update so the backup stays current:

```bash
mamba env export -n henv > henv.yml
```

Do this especially after updating HEASoft, Fermitools, or ThreeML, as those are the most likely to receive channel updates.
