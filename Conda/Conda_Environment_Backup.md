# Conda Environment Backup & Restore Guide

> Snapper protects your system. It does not protect your conda environments. These live in `~/miniforge3/envs/` inside your home directory — outside Btrfs snapshot scope. This guide ensures every environment can be fully restored if something breaks, and cleanly recreated on a new system.
>
>

---

## Important: Before You Start

Make sure only one conda installation exists on your system. Having two (e.g. both `miniconda3` and `miniforge3`) causes silent export failures.

```bash
which mamba
which conda

```

Both should point to `/home/YOUR_USERNAME/miniforge3/condabin/`. If either points to `miniconda3`, remove it:

```bash
rm -rf ~/miniconda3

```

---

## Two Export Methods

### Method 1: Exact Export (Best for Backup / Rollback)

Saves every package at the exact version with platform-specific build strings. Guarantees a byte-for-byte identical environment on the same OS.

```bash
/home/void/miniforge3/condabin/mamba env export -n henv > henv.yml

```

Use this for: **local backups, rollback after a bad update, same-machine recovery.**

---

### Method 2: Portable Export (Best for New System Install)

Drops platform-specific build strings. More flexible — mamba resolves the nearest compatible versions on the new system cleanly.

```bash
/home/void/miniforge3/condabin/mamba env export -n henv --no-builds > henv_portable.yml

```

Use this for: **migrating to a new machine, fresh CachyOS install.**

---

## Step 1: Create the Backup Folder

```bash
mkdir -p ~/conda-backups
cd ~/conda-backups

```

---

## Step 2: Export All Environments

Run in bash (not fish):

```bash
bash

# Exact exports — for local backup and rollback
/home/void/miniforge3/condabin/mamba env export -n henv > henv.yml
/home/void/miniforge3/condabin/mamba env export -n fermi > fermi.yml
/home/void/miniforge3/condabin/mamba env export -n threeML > threeML.yml
/home/void/miniforge3/condabin/mamba env export -n pyraf > pyraf.yml
/home/void/miniforge3/condabin/mamba env export -n astro_photometry > astro_photometry.yml

# Portable exports — for new system installation
/home/void/miniforge3/condabin/mamba env export -n henv --no-builds > henv_portable.yml
/home/void/miniforge3/condabin/mamba env export -n fermi --no-builds > fermi_portable.yml
/home/void/miniforge3/condabin/mamba env export -n threeML --no-builds > threeML_portable.yml
/home/void/miniforge3/condabin/mamba env export -n pyraf --no-builds > pyraf_portable.yml
/home/void/miniforge3/condabin/mamba env export -n astro_photometry --no-builds > astro_photometry_portable.yml

```

Verify all files were created:

```bash
ls -lh ~/conda-backups/

```

Expected output — all files should have a non-zero size:

```
henv.yml
henv_portable.yml
fermi.yml
fermi_portable.yml
threeML.yml
threeML_portable.yml
pyraf.yml
pyraf_portable.yml
astro_photometry.yml
astro_photometry_portable.yml

```

---

## Step 3: Store the Files Somewhere Safe

Do not keep these only on your local machine. Back them up to at least one of:

- A git repository
- Nextcloud / any cloud storage
- A USB drive

These files are a few KB each but save hours of debugging.

---

## Restoring on the Same Machine (Rollback)

Use the exact `.yml` files:

```bash
mamba env remove -n henv
mamba env create -f ~/conda-backups/henv.yml

```

---

## Installing on a New CachyOS System

After installing miniforge3 on the new machine, use the portable `_portable.yml` files:

```bash
mamba env create -f ~/conda-backups/henv_portable.yml
mamba env create -f ~/conda-backups/fermi_portable.yml
mamba env create -f ~/conda-backups/threeML_portable.yml
mamba env create -f ~/conda-backups/pyraf_portable.yml
mamba env create -f ~/conda-backups/astro_photometry_portable.yml

```

> If mamba warns that an exact package build isn't available, it will automatically fall back to the nearest compatible version — this is expected and fine.
>
>

---

## Which File to Use — Quick Reference

SituationFile to UseSame machine rollback after bad update`henv.yml` (exact)Environment corrupted, rebuild in place`henv.yml` (exact)Migrating to new CachyOS install`henv_portable.yml` (portable)Sharing environment with a colleague`henv_portable.yml` (portable)Export to Sheets---

## Maintenance

Re-export after any significant update so backups stay current:

```bash
bash
cd ~/conda-backups

/home/void/miniforge3/condabin/mamba env export -n henv > henv.yml
/home/void/miniforge3/condabin/mamba env export -n henv --no-builds > henv_portable.yml

```

Do this especially after updating HEASoft, Fermitools, or ThreeML as those are the most likely to receive channel updates.

---

## Future-Proofing: Automatic Path Detection

If you ever reinstall conda, move your home directory, or change to a different distribution, hardcoding `/home/void/miniforge3/condabin/` might break your scripts.

Instead of typing out the absolute path every time, you can instruct bash to automatically detect where `mamba` is installed using the `which` command, and store that path as a variable (`$MAMBA_CMD`).

Here is how you can write a fully automated, future-proof backup script:

```bash
#!/bin/bash

# 1. Automatically find the mamba executable path
MAMBA_CMD=$(which mamba)

# Check if mamba was found
if [ -z "$MAMBA_CMD" ]; then
    echo "Error: mamba not found in PATH."
    exit 1
fi

echo "Using mamba at: $MAMBA_CMD"

# 2. Go to backup directory
mkdir -p ~/conda-backups
cd ~/conda-backups

# 3. Define the list of your environments
ENVS=("henv" "fermi" "threeML" "pyraf" "astro_photometry")

# 4. Loop through the list and backup each one automatically
for env in "${ENVS[@]}"; do
    echo "Backing up $env..."
    
    # Exact export
    $MAMBA_CMD env export -n $env > ${env}.yml
    
    # Portable export
    $MAMBA_CMD env export -n $env --no-builds > ${env}_portable.yml
done

echo "Backup complete!"
ls -lh ~/conda-backups/

```

You can save this block of code as `backup_conda.sh`, run `chmod +x backup_conda.sh` to make it executable, and then run `./backup_conda.sh` anytime you want to update all your backups instantly, regardless of where mamba is currently installed on your system.
