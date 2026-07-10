#!/bin/bash

echo "========================================"
echo " Phase 2: Application Configs"
echo "========================================"
read -p "Proceed with applying application configurations? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping Phase 2."
    exit 0
fi

# Antigravity Config
echo -e "\n--- Configuring Antigravity ---"
# Assuming Antigravity configs exist in Configuration/Antigravity
if [ -d "/home/void/Cachyos-installation/Configuration/Antigravity" ]; then
    echo "Found Antigravity configurations. Applying..."
    mkdir -p ~/.config/antigravity
    cp -r /home/void/Cachyos-installation/Configuration/Antigravity/* ~/.config/antigravity/ 2>/dev/null
fi

# KDE/Dolphin Config
echo -e "\n--- Configuring KDE / Dolphin ---"
echo "Applying Dolphin open-with fixes..."
# This applies the Dolphin fix script if it exists
if [ -f "/home/void/Cachyos-installation/Dolphin_openwith_fix" ]; then
    bash /home/void/Cachyos-installation/Dolphin_openwith_fix
fi

# Network Sharing Setup
echo -e "\n--- Configuring Network Sharing (KSMBD) ---"
read -p "Do you want to enable Bidirectional Network Sharing (Both Host and Client)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Server & Client tools..."
    sudo pacman -S --needed ksmbd-tools cifs-utils --noconfirm
    
    # Server Setup
    sudo mkdir -p /etc/ksmbd
    
    # Client Setup
    sudo mkdir -p /mnt/Remote_Folder
    sudo mkdir -p /etc/samba
    
    echo "✅ Tools installed! Manual setup required:"
    echo "  - SERVER: Run 'sudo ksmbd.adduser -a void' and configure /etc/ksmbd/ksmbd.conf"
    echo "  - CLIENT: Create /etc/samba/credentials and add your fstab entry."
else
    echo "Skipping network share setup."
fi

# Dolphin & GTK Portals
echo -e "\n--- Configuring Dolphin & GTK Portals ---"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
xdg-mime default org.kde.dolphin.desktop inode/directory
xdg-mime default org.kde.dolphin.desktop application/x-directory
mkdir -p ~/.config/environment.d
echo 'QT_QPA_PLATFORMTHEME=qt6ct' > ~/.config/environment.d/qt.conf

# SDDM Configuration
echo -e "\n--- Configuring SDDM ---"
if systemctl status display-manager | grep -iq plasmalogin; then
    echo "Swapping plasmalogin to classic SDDM..."
    sudo systemctl disable plasmalogin.service
    sudo systemctl enable sddm.service
else
    echo "Classic SDDM is already the default display manager."
fi

echo -e "\nPhase 2 Complete! Application configs applied."
