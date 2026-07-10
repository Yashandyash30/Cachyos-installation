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
paru -S --needed fastfetch xwaylandvideobridge walker elephant-all-bin tumbler poppler-glib ffmpegthumbnailer cloudflare-warp-bin --noconfirm

# Hardware Media Drivers for SDDM/Qylock
echo -e "\n--- Checking GPU for Media Drivers ---"
GPU=$(lspci | grep -i 'vga\|3d\|2d')
if echo "$GPU" | grep -iq 'nvidia'; then
    echo "GPU: NVIDIA detected. No extra media drivers needed."
elif echo "$GPU" | grep -iq 'amd'; then
    echo "GPU: AMD detected."
    if ! pacman -Q libva-mesa-driver mesa-vdpau &>/dev/null; then
        sudo pacman -S --needed libva-mesa-driver mesa-vdpau --noconfirm
    fi
else
    echo "GPU: Integrated/Intel only detected."
    if ! pacman -Q intel-media-driver &>/dev/null; then
        sudo pacman -S --needed intel-media-driver --noconfirm
    fi
fi

# Additional System Packages
echo "Installing additional system packages (Dolphin, Qt, SDDM, Git)..."
sudo pacman -S --needed qt5ct kvantum breeze adw-gtk-theme xdg-desktop-portal-gtk qt6ct-kde sddm qt6-declarative qt6-5compat qt6-svg qt6-multimedia qt6-multimedia-ffmpeg gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly fzf github-cli --noconfirm

# Walker fix
echo "Applying Walker/Elephant dnf bug fix..."
sudo rm -f /usr/lib/elephant/dnfpackages.so

# WARP Background Service
echo "Enabling Cloudflare WARP background service..."
sudo systemctl enable --now warp-svc.service

# LaTeX
echo ""
read -p "Do you want to download and install LaTeX (texlive-meta) [Size: ~3GB]? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing LaTeX..."
    sudo pacman -S --needed texlive-meta biber --noconfirm
fi

echo -e "\nPhase 3 Complete! Software installed."
