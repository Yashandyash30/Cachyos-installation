#!/bin/bash

echo "========================================"
echo " Phase 4: Research Apps & Subsystems"
echo "========================================"
read -p "Proceed with setting up Distrobox, PyRAF, and Conda? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping Phase 4."
    exit 0
fi

REPO_DIR="/home/void/Cachyos-installation"
BACKUP_DIR="$REPO_DIR/conda-backups"

# --- Distrobox Setup ---
echo -e "\n--- Distrobox Astrophysics Environment ---"
# Determine hardware isolation type based on GPU
GPU=$(lspci | grep -i 'vga\|3d\|2d')
if echo "$GPU" | grep -iq 'nvidia'; then
    echo "NVIDIA GPU detected. You may need CDI/Nvidia-SMI support for Distrobox."
    # Standard distrobox create (assumes CDI is configured if Nvidia)
    CREATE_ARGS="--nvidia"
else
    echo "No NVIDIA GPU detected. Using clean CPU-only sandboxed Distrobox."
    CREATE_ARGS=""
fi

# Setup "Sandboxed Home" method
mkdir -p ~/.local/share/astro-container-home
if ! distrobox list | grep -q 'astrobox'; then
    echo "Creating 'astrobox' Ubuntu 22.04 container..."
    distrobox create $CREATE_ARGS --name astrobox --image ubuntu:22.04 --home ~/.local/share/astro-container-home
else
    echo "'astrobox' already exists."
fi

# Install legacy NOAO stack inside Distrobox silently
echo "Installing PyRAF & IRAF inside astrobox..."
distrobox enter astrobox -- bash -c "sudo apt update && sudo apt install -y iraf iraf-dev xgterm python3-pyraf saods9 wget curl bzip2 git build-essential"

# --- Conda Setup on Host ---
echo -e "\n--- Conda / Miniforge Setup ---"
if ! command -v mamba &> /dev/null; then
    echo "Miniforge not found. Installing..."
    wget -qO /tmp/Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
    bash /tmp/Miniforge3.sh -b -p "$HOME/miniforge3"
    "$HOME/miniforge3/bin/conda" init bash
    "$HOME/miniforge3/bin/conda" init fish
    # Export path so script can use it immediately
    export PATH="$HOME/miniforge3/bin:$PATH"
fi

# --- Conda Environment Recovery ---
echo -e "\n--- Restoring Conda Environments ---"
# We read the _portable.yml files from your repo
if [ -d "$BACKUP_DIR" ]; then
    for portable_yml in "$BACKUP_DIR"/*_portable.yml; do
        if [ -f "$portable_yml" ]; then
            env_name=$(basename "$portable_yml" _portable.yml)
            echo "Restoring environment: $env_name"
            mamba env create -f "$portable_yml" --yes
            
            # ----------------------------------------------------
            # 🛠️ MANUAL BUG FIXES (Applied Automatically)
            # Add any manual pip installs or sed hacks here for specific environments.
            # This ensures your .yml backups remain clean while bugs are fixed.
            # ----------------------------------------------------
            if [[ "$env_name" == "astro_photometry" ]]; then
                echo "Applying manual bugfixes for $env_name..."
                # Example: mamba run -n $env_name pip install --upgrade dynesty
            fi
        fi
    done
else
    echo "Conda backup directory not found!"
fi

echo -e "\nPhase 4 Complete! Research subsystem is ready."
