# Dotfiles Management Guide

This directory contains the system configuration files (dotfiles) for this OS installation. We manage these dotfiles by using **Symbolic Links (Symlinks)**.

## How it works

Instead of copying files back and forth between `~/.config/` and this repository, we keep the actual configuration files right here in this GitHub repository (`/home/void/Cachyos-installation/Dotfiles`).

We then create "shortcuts" (symlinks) in the system's configuration folder (`~/.config/`) that point directly to the files in this repository. 

Whenever you make a change to a config file (like your `fish` or `niri` settings) on your system, you are **directly editing the file inside this repository**. 

---

## How to sync changes to GitHub

Because the files are physically stored in this repository, any changes you make will automatically show up when you check `git status`. 

To save and upload your changes, just run these commands from the `/home/void/Cachyos-installation/` directory:

```bash
git add Dotfiles/
git commit -m "Update dotfiles"
git push
```

---

## How to restore configs (Fresh Install)

If you ever reinstall your OS or move to a new system, you can easily link all these configs back to your system by running the following commands.

> [!WARNING]
> Before running these commands, ensure you back up or remove the default system configs, otherwise the symlink creation will fail.

### 1. Back up existing system configs
```bash
mv ~/.bashrc ~/.bashrc.bak 2>/dev/null
mv ~/.config/fish ~/.config/fish.bak 2>/dev/null
mv ~/.config/keyboard ~/.config/keyboard.bak 2>/dev/null
mv ~/.config/niri ~/.config/niri.bak 2>/dev/null
```

### 2. Create the Symlinks
```bash
ln -s /home/void/Cachyos-installation/Dotfiles/.bashrc ~/.bashrc
ln -s /home/void/Cachyos-installation/Dotfiles/fish ~/.config/fish
ln -s /home/void/Cachyos-installation/Dotfiles/keyboard ~/.config/keyboard
ln -s /home/void/Cachyos-installation/Dotfiles/niri ~/.config/niri
```

Once you run these commands, your system will instantly be configured exactly how you left it!
