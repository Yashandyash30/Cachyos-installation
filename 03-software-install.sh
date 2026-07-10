#!/bin/bash

echo "========================================"
echo " Phase 3: Software Installation"
echo "========================================"
read -p "Proceed with installing software via pacman and paru? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping Phase 3."
    exit 0
fi

# Essential System Packages
echo "Installing essential system packages from standard repos..."
sudo pacman -S --needed btop distrobox podman xorg-xhost wget curl git base-devel --noconfirm

# Verify Paru (AUR Helper)
if ! command -v paru &> /dev/null; then
    echo "paru not found! Installing paru..."
    sudo pacman -S --needed rustup --noconfirm
    rustup default stable
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru || exit
    makepkg -si --noconfirm
    cd - || exit
fi

echo "Installing AUR packages..."
paru -S --needed fastfetch xwaylandvideobridge --noconfirm

echo -e "\nPhase 3 Complete! Software installed."
