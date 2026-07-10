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
# Pointing this directly to your Git repository so backups are tracked instantly!
BACKUP_DIR="/home/void/Cachyos-installation/conda-backups"
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR" || exit

# ── Dynamic Environment Detection ─────────────────────────────────────────────
echo "🔍 Detecting existing environments..."

# This fetches the output of mamba env list, strips out the paths, 
# and filters out comments, empty lines, 'base', and mamba's table borders/headers.
mapfile -t ENVS < <($MAMBA_CMD env list | awk '{print $1}' | grep -Ev "^#|^base$|^$|^Name$|^─")

if [ ${#ENVS[@]} -eq 0 ]; then
    echo "⚠️ No custom Conda environments found to backup."
    exit 0
fi

echo "Found ${#ENVS[@]} environments to backup: ${ENVS[*]}"
echo ""

# ── Export ────────────────────────────────────────────────────────────────────
for env in "${ENVS[@]}"; do
    echo "📦 Backing up: $env"

    # Suppress output to keep the terminal clean, only show errors if they happen
    $MAMBA_CMD env export -n "$env" > "${env}.yml" 2>/dev/null
    $MAMBA_CMD env export -n "$env" --no-builds > "${env}_portable.yml" 2>/dev/null

    echo "   ✅ Done"
done
echo ""
echo "Backup complete. Files saved to $BACKUP_DIR:"
ls -lh "$BACKUP_DIR"/*.yml
