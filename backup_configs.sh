#!/bin/bash

# Define paths
REPO_DIR="/home/void/Cachyos-installation"
DOTFILES_DIR="$REPO_DIR/Dotfiles"

echo "Creating Dotfiles backup directory at $DOTFILES_DIR..."
mkdir -p "$DOTFILES_DIR/fish"
mkdir -p "$DOTFILES_DIR/niri"
mkdir -p "$DOTFILES_DIR/keyboard"

echo "Backing up ~/.bashrc..."
cp ~/.bashrc "$DOTFILES_DIR/"

echo "Backing up Fish configurations..."
cp -r ~/.config/fish/* "$DOTFILES_DIR/fish/" 2>/dev/null || echo "Fish config not found."

echo "Backing up Niri configurations..."
cp -r ~/.config/niri/* "$DOTFILES_DIR/niri/" 2>/dev/null || echo "Niri config not found."

echo "Backing up system keyboard configurations (if they exist)..."
if [ -f /etc/X11/xorg.conf.d/00-keyboard.conf ]; then
    cp /etc/X11/xorg.conf.d/00-keyboard.conf "$DOTFILES_DIR/keyboard/"
else
    echo "No X11 keyboard config found (likely handled by Niri)."
fi

echo "Backup complete! Your dotfiles are now safely stored in $DOTFILES_DIR."
tree "$DOTFILES_DIR"
