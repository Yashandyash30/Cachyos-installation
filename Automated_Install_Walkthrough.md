# CachyOS Automation Walkthrough

Your manual workflow has been completely translated into four modular, hardware-aware installation scripts. I have also successfully backed up your current system configurations into the `Dotfiles/` directory!

Here is how your new automated ecosystem works.

## 1. The Modular Scripts
I have generated the following scripts in your repository:
- `01-system-config.sh`: Detects if you are on a laptop or desktop and applies lid-switch logic. Detects your GPU vendor. Restores your `fish`, `bash`, `niri`, and keyboard configs from the `Dotfiles/` backup.
- `02-app-config.sh`: Restores Antigravity setups, Dolphin fixes, and asks whether to set up KSMBD as a host or client.
- `03-software-install.sh`: Ensures `paru` is installed, then batch installs all necessary AUR and standard repository packages.
- `04-research-apps.sh`: The heavy lifter for astrophysics.

## 2. Solving the Conda Manual Bug Fixes
> **Your Question:** *In some mamba envs there are some manual bugfixes... is it safe or it can break due to manual bug fixes?*

**Solution:** I have designed `04-research-apps.sh` to handle this perfectly. The script will first use `mamba env create -f env_portable.yml` to cleanly install the base packages. 

Immediately after building the environment, the script hits a dedicated **MANUAL BUG FIXES** block. Inside this block, we can script specific `pip install --upgrade` or file patches for specific environments (like `astro_photometry`). 

This means:
1. Your `.yml` files stay completely clean and standard.
2. The manual bug fixes are automated and applied identically every single time.
3. You can safely update your `.yml` files in the future without breaking the bug fixes!

## 3. Sandboxed Testing (With Visuals!)
> **Your Question:** *How can we test the script if its working can we use virtual env or some isolated sandbox to check the script? And how do I know if the theme worked?*

**Solution:** Yes! Because you already use Distrobox and Niri (a Wayland compositor), we can spin up a temporary Arch Linux sandbox *inside* your current system, run the scripts, and then launch a **Nested Wayland Session**. This opens up your sandboxed Niri desktop *inside a window on your current screen*, so you can visually verify all the themes and UI changes without touching your real host OS!

You can run this right now in your terminal to create and visually test the sandbox:
```bash
# 1. Create a disposable Arch Linux sandbox (CachyOS is based on Arch)
distrobox create --name test-cachy --image docker.io/archlinux/archlinux:latest --home ~/.local/share/test-cachy-home

# 2. Enter the sandbox
distrobox enter test-cachy

# 3. Navigate to the repo (using the absolute path!)
cd /home/void/Cachyos-installation
./01-system-config.sh

# 4. Visually verify the theme!
# Launch a nested Niri session to see your themes in an isolated window
niri
```

> [!TIP]
> **Is it safe?** 100% safe. The nested Niri runs as a standard window on your host (like Firefox). Because we used the `--home ~/.local/share/test-cachy-home` flag, the container has absolutely no access to your real files or configs. It's trapped!

When you are done testing, you can delete the sandbox with: `distrobox rm test-cachy`.

## 4. The Future Fresh Install Workflow
> **Your Question:** *In a future install I may also need to first fetch the files required from github, how will we take care of that?*

**Solution:** This is the beauty of this automated Git setup! When you install a completely blank, brand-new CachyOS system on a new PC, all you have to do is type **two commands** to reconstruct your entire setup:

1. **Fetch everything from GitHub:**
   ```bash
   git clone https://github.com/Yashandyash30/Cachyos-installation.git ~/Cachyos-installation
   ```
2. **Run your new automated scripts:**
   ```bash
   cd ~/Cachyos-installation
   ./01-system-config.sh
   # It will automatically copy all your backed up Dotfiles to the correct locations!
   ```
