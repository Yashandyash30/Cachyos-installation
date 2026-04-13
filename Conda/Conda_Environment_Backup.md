# Conda Environment Backup & Restore Guide
### CachyOS · Miniforge3 · Mamba

> Snapper protects your system. It does not protect your Conda environments. These live in `~/miniforge3/envs/` inside your home directory — outside Btrfs snapshot scope. This guide ensures every environment can be fully restored if something breaks, and cleanly recreated on a new system.

---

## Part 1 — Pre-Flight Checks

Before exporting anything, confirm your Conda installation is clean and unambiguous. Duplicate or split installations cause silent export failures that are hard to diagnose.

### Step 1.1 — Check where mamba and conda point

Run both of these:

```bash
which mamba
which conda
```

Then check what's actually in your PATH:

```bash
echo $PATH | tr ':' '\n' | grep -i conda
```

### Step 1.2 — Interpret the results

**Case A — Both point to miniforge3 (ideal)**

```
/home/void/miniforge3/condabin/mamba
/home/void/miniforge3/condabin/conda
```

You're clean. Skip to Part 2.

---

**Case B — Both point to miniforge3 but different subfolders**

```
/home/void/miniforge3/bin/mamba       ← bin
/home/void/miniforge3/condabin/conda  ← condabin
```

This is normal and not a problem. `condabin` is a thin wrapper added to your PATH at login so conda/mamba work in any shell. `bin` is where the actual executables live. They're the same installation — use either path for exports.

To confirm they resolve to the same install:

```bash
mamba info | grep "base environment"
conda info | grep "base environment"
```

Both should show the same path, e.g. `/home/void/miniforge3`.

---

**Case C — mamba and conda point to different installations**

```
/home/void/miniforge3/condabin/mamba   ← miniforge3
/home/void/miniconda3/condabin/conda   ← miniconda3 (problem)
```

This will cause conflicts. Remove the redundant one. Since you're on CachyOS with miniforge3, remove miniconda3:

```bash
# 1. Remove the directory
rm -rf ~/miniconda3

# 2. Remove miniconda3 lines from your shell configs
nano ~/.bashrc
# Delete any block that looks like:
# >>> conda initialize >>>
# ... lines referencing miniconda3 ...
# <<< conda initialize <<<

nano ~/.config/fish/config.fish
# Delete any similar block referencing miniconda3

# 3. Reload your shell
source ~/.bashrc
# or restart your terminal
```

Verify the fix:

```bash
which mamba
which conda
```

Both should now point to miniforge3 only.

---

**Case D — conda found but mamba not found**

```bash
which mamba
# mamba not found
```

Mamba isn't installed in your base environment. Install it:

```bash
conda install -c conda-forge mamba
```

Then verify:

```bash
which mamba
```

---

**Case E — neither found**

Conda/Mamba aren't initialized for your current shell. Run:

```bash
~/miniforge3/bin/conda init bash
~/miniforge3/bin/conda init fish
```

Then restart your terminal and re-run the `which` checks.

---

## Part 2 — Understand the Two Export Methods

Every environment should be exported twice — once for local recovery, once for portability.

### Method 1 — Exact Export (Rollback / Same Machine)

Records every package at its exact version with platform-specific build strings. Guarantees a byte-for-byte identical environment on the same OS and architecture.

```bash
mamba env export -n ENV_NAME > ENV_NAME.yml
```

**Use for:** local backups, rolling back after a bad update, rebuilding on the same machine.

**Do not use for:** migrating to a new machine — build strings are architecture-specific and will fail on a different system.

---

### Method 2 — Portable Export (New System / Migration)

Strips platform-specific build strings. Mamba resolves the nearest compatible versions cleanly on the target system.

```bash
mamba env export -n ENV_NAME --no-builds > ENV_NAME_portable.yml
```

**Use for:** fresh CachyOS installs, migrating to a new machine, sharing with a colleague.

**Expected behaviour:** Mamba may warn that some exact builds aren't available — it will automatically fall back to the nearest compatible version. This is normal.

---

## Part 3 — Back Up All Environments

### Step 3.1 — Create the backup folder

```bash
mkdir -p ~/conda-backups
cd ~/conda-backups
```

### Step 3.2 — Export all environments

Run this in Bash (not Fish — brace expansion works differently in Fish):

```bash
bash
```

Then export each environment:

```bash
# Exact exports — for local rollback
mamba env export -n henv               > ~/conda-backups/henv.yml
mamba env export -n fermi              > ~/conda-backups/fermi.yml
mamba env export -n threeML            > ~/conda-backups/threeML.yml
mamba env export -n pyraf              > ~/conda-backups/pyraf.yml
mamba env export -n astro_photometry   > ~/conda-backups/astro_photometry.yml

# Portable exports — for new system installation
mamba env export -n henv             --no-builds > ~/conda-backups/henv_portable.yml
mamba env export -n fermi            --no-builds > ~/conda-backups/fermi_portable.yml
mamba env export -n threeML          --no-builds > ~/conda-backups/threeML_portable.yml
mamba env export -n pyraf            --no-builds > ~/conda-backups/pyraf_portable.yml
mamba env export -n astro_photometry --no-builds > ~/conda-backups/astro_photometry_portable.yml
```

### Step 3.3 — Verify all files were created with content

```bash
ls -lh ~/conda-backups/
```

Every file should show a non-zero size. A 0-byte file means the export silently failed — re-run that specific export command and check for errors.

Expected output:

```
astro_photometry.yml
astro_photometry_portable.yml
fermi.yml
fermi_portable.yml
henv.yml
henv_portable.yml
pyraf.yml
pyraf_portable.yml
threeML.yml
threeML_portable.yml
```

---

## Part 4 — Store Backups Somewhere Safe

A backup that only exists on your local machine is not a backup. Copy the files to at least one of:

```bash
# Option A — push to a private git repo
cd ~/conda-backups
git init
git add *.yml
git commit -m "conda env backups"
git remote add origin https://github.com/YOU/conda-backups.git
git push -u origin main

# Option B — copy to a USB drive
cp ~/conda-backups/*.yml /run/media/void/YOUR_USB/

# Option C — sync to Nextcloud or any cloud folder
cp ~/conda-backups/*.yml ~/Nextcloud/backups/conda/
```

These files are only a few KB each but save hours of debugging.

---

## Part 5 — Restoring Environments

### Rollback on the same machine

Use the exact `.yml` file. Remove the broken environment first, then recreate it:

```bash
mamba env remove -n henv
mamba env create -f ~/conda-backups/henv.yml
```

### Fresh install on a new CachyOS system

After installing Miniforge3 on the new machine, use the portable files:

```bash
mamba env create -f ~/conda-backups/henv_portable.yml
mamba env create -f ~/conda-backups/fermi_portable.yml
mamba env create -f ~/conda-backups/threeML_portable.yml
mamba env create -f ~/conda-backups/pyraf_portable.yml
mamba env create -f ~/conda-backups/astro_photometry_portable.yml
```

### Re-register Jupyter kernels after restore

Restoring the environment doesn't restore the Jupyter kernel registration. Re-register each one:

```bash
conda activate astro_photometry
python -m ipykernel install --user --name=astro_photometry --display-name="Python (Astro Photometry)"

conda activate henv
python -m ipykernel install --user --name=henv --display-name="Python (henv)"

# repeat for each environment that uses Jupyter
```

---

## Part 6 — Automated Backup Script

Instead of running the export commands manually each time, use this script. It auto-detects where mamba is installed so it won't break if you ever move your home directory or switch distributions.

### Step 6.1 — Create the script

```bash
nano ~/conda-backups/backup_conda.sh
```

Paste the following:

```bash
#!/bin/bash

# ── Locate mamba ──────────────────────────────────────────────────────────────
MAMBA_CMD=$(which mamba 2>/dev/null)

if [ -z "$MAMBA_CMD" ]; then
    # Fallback: try the miniforge3 bin directory directly
    MAMBA_CMD="$HOME/miniforge3/bin/mamba"
fi

if [ ! -x "$MAMBA_CMD" ]; then
    echo "❌ Error: mamba not found. Is miniforge3 installed and initialized?"
    exit 1
fi

echo "✅ Using mamba at: $MAMBA_CMD"
echo ""

# ── Setup ─────────────────────────────────────────────────────────────────────
BACKUP_DIR="$HOME/conda-backups"
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

# Add your environments here
ENVS=("henv" "fermi" "threeML" "pyraf" "astro_photometry")

# ── Export ────────────────────────────────────────────────────────────────────
for env in "${ENVS[@]}"; do
    # Check the environment actually exists before trying to export
    if ! $MAMBA_CMD env list | grep -q "^$env "; then
        echo "⚠️  Skipping '$env' — environment not found"
        continue
    fi

    echo "📦 Backing up: $env"

    $MAMBA_CMD env export -n "$env" > "${env}.yml"
    $MAMBA_CMD env export -n "$env" --no-builds > "${env}_portable.yml"

    echo "   ✅ Done"
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Backup complete. Files saved to $BACKUP_DIR:"
ls -lh "$BACKUP_DIR"/*.yml
```

Save and exit (**Ctrl+O → Enter**, then **Ctrl+X**).

### Step 6.2 — Make it executable (one time only)

```bash
chmod +x ~/conda-backups/backup_conda.sh
```

### Step 6.3 — Run it

From anywhere in your terminal:

```bash
~/conda-backups/backup_conda.sh
```

> Run this script whenever you install or update packages in any environment — especially after HEASoft, Fermitools, or ThreeML updates.

---

## Quick Reference

### Which file to use

| Situation | File to use |
|---|---|
| Same machine — rollback after bad update | `ENV_NAME.yml` (exact) |
| Same machine — environment corrupted | `ENV_NAME.yml` (exact) |
| New CachyOS install / new machine | `ENV_NAME_portable.yml` (portable) |
| Sharing environment with a colleague | `ENV_NAME_portable.yml` (portable) |

### Key paths

```
Miniforge3 base         ~/miniforge3/
Environments            ~/miniforge3/envs/
Conda wrapper           ~/miniforge3/condabin/conda
Mamba executable        ~/miniforge3/bin/mamba  (or condabin/mamba)
Backup folder           ~/conda-backups/
Backup script           ~/conda-backups/backup_conda.sh
```

### Essential commands

```bash
mamba env list                          # list all environments
mamba env export -n NAME > NAME.yml     # exact export
mamba env export -n NAME --no-builds \
    > NAME_portable.yml                 # portable export
mamba env create -f NAME.yml            # restore from file
mamba env remove -n NAME               # delete an environment
```
