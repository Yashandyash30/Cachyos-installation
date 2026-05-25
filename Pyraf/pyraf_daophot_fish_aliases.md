Here is the master reference guide for setting up your CachyOS host aliases. You can save this in your documentation so you have the exact syntax ready if you ever need to rebuild your Fish shell or migrate this setup to another machine.

### The Distrobox / Fish Shell Integration Guide

This configuration allows you to run containerized, legacy astrophysics software directly from your native CachyOS terminal as if they were natively installed, while dynamically bypassing a known 32-bit execution limitation in container engines.

#### Step 1: Open the Configuration File

Open your host system's Fish shell configuration file using your preferred text editor:

```bash
nano ~/.config/fish/config.fish

```

#### Step 2: Add the Integration Block

Scroll to the very bottom of the file and paste this entire block.

* **The `xhost` line** ensures the container is allowed to draw legacy graphical windows (like DS9 or PyRAF plots) directly onto your Wayland desktop.
* **The `bash -c` wrapper** around the DAOPHOT tools tricks the host's container engine into loading a 64-bit interpreter first, which then seamlessly executes the 32-bit Fortran binaries inside the container.

```fish
# -----------------------------------------------------
# Wayland Display Bridge for Legacy X11/Distrobox
# -----------------------------------------------------
# Suppress output so it doesn't spam the terminal on startup
xhost +si:localuser:void > /dev/null 2>&1

# -----------------------------------------------------
# Astrophysics Pipeline (astrobox container)
# -----------------------------------------------------
# PyRAF & Image Viewer (Native 64-bit inside container)
alias pyraf="distrobox enter astrobox -- pyraf"
alias ds9="distrobox enter astrobox -- ds9"

# DAOPHOT II Suite (Wrapped in bash to bypass 32-bit crun limitation)
alias daophot="distrobox enter astrobox -- bash -c '~/dao2/daophot'"
alias allstar="distrobox enter astrobox -- bash -c '~/dao2/allstar'"
alias daomatch="distrobox enter astrobox -- bash -c '~/dao2/ndaomatch'"
alias daomaster="distrobox enter astrobox -- bash -c '~/dao2/ndaomaster'"

```

Save the file and exit.

#### Step 3: Reload the Shell

To activate the new aliases immediately without closing your terminal, run:

```bash
source ~/.config/fish/config.fish

```

---

### How to use your new workflow

Because Distrobox preserves your host's working directory, you do not need to navigate file systems *inside* the container anymore.

When you sit down to reduce your GRB or Supernova data, simply use your native CachyOS terminal to navigate to your high-speed network share:

```bash
cd /mnt/Storage/GRB_DATA

```

Then, just type the command you need:

```bash
daophot

```

Distrobox will automatically spin up in the background, map itself to that exact network folder, execute the bash wrapper, load the 32-bit libraries, and drop you straight into the software's prompt, ready to process your files!
