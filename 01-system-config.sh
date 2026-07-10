#!/bin/bash

echo "========================================"
echo " Phase 1: System Configs & Dotfiles"
echo "========================================"
read -p "Proceed with applying system configurations? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping Phase 1."
    exit 0
fi

REPO_DIR="/home/void/Cachyos-installation"
DOTFILES_DIR="$REPO_DIR/Dotfiles"

# Hardware Detection
echo -e "\n--- Hardware Detection ---"
CHASSIS=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo "Unknown")
if [[ "$CHASSIS" == "9" || "$CHASSIS" == "10" ]]; then
    echo "Device Type: Laptop detected."
    # Apply laptop-specific settings (e.g. lid switch optimizations)
    sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=suspend/' /etc/systemd/logind.conf 2>/dev/null
else
    echo "Device Type: Desktop PC detected."
    sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/systemd/logind.conf 2>/dev/null
fi

GPU=$(lspci | grep -i 'vga\|3d\|2d')
if echo "$GPU" | grep -iq 'nvidia'; then
    echo "GPU: NVIDIA detected."
    export GPU_VENDOR="nvidia"
elif echo "$GPU" | grep -iq 'amd'; then
    echo "GPU: AMD detected."
    export GPU_VENDOR="amd"
else
    echo "GPU: Integrated/Intel only detected."
    export GPU_VENDOR="intel"
fi

# Restore Dotfiles
echo -e "\n--- Restoring Dotfiles ---"
if [ -f "$DOTFILES_DIR/.bashrc" ]; then
    echo "Restoring .bashrc..."
    cp "$DOTFILES_DIR/.bashrc" ~/.bashrc
fi

if [ -d "$DOTFILES_DIR/fish" ]; then
    echo "Restoring Fish config..."
    mkdir -p ~/.config/fish
    cp -r "$DOTFILES_DIR/fish/"* ~/.config/fish/
fi

if [ -d "$DOTFILES_DIR/niri" ]; then
    echo "Restoring Niri config..."
    mkdir -p ~/.config/niri
    cp -r "$DOTFILES_DIR/niri/"* ~/.config/niri/
fi

if [ -f "$DOTFILES_DIR/keyboard/00-keyboard.conf" ]; then
    echo "Restoring system keyboard config..."
    sudo mkdir -p /etc/X11/xorg.conf.d/
    sudo cp "$DOTFILES_DIR/keyboard/00-keyboard.conf" /etc/X11/xorg.conf.d/
fi

echo -e "\nPhase 1 Complete! System configs applied."
