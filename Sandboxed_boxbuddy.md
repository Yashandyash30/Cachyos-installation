This is the classic Distrobox double-edged sword. The shared home directory is amazing for sharing files, but it is an absolute nightmare when installing developer tools like Conda or Mamba that forcefully inject paths into your `~/.bashrc` or `~/.config/fish`.

If you aren't careful, the container's Python environment will bleed into CachyOS, causing both to collapse.

To keep your host environment pristine while setting up a heavy-duty Python pipeline for your GRB and Supernova analysis, you need to build a container with a **sandboxed home directory**.

Since we already know your setup relies heavily on your GTX 1650 for hardware acceleration, I have integrated our previous Podman CDI bypass trick directly into this workflow. Save this as your master guide for building isolated Python/Conda containers.

---

# Isolated Distrobox Guide: The "Sandboxed Home" Method

## Overview

By default, Distrobox shares your CachyOS host's `/home` directory. This guide creates a completely isolated Ubuntu container with its own private home folder. This prevents Python environments (like Miniforge/Mamba) installed inside the container from overwriting your host's configuration files, while still retaining full Nvidia GPU passthrough.

---

## Phase 1: Prepare the Host Directory

Before creating the container, we need to create a physical folder on your CachyOS host that will act as the "fake" home directory for the container.

Run this in your main CachyOS terminal:

```bash
# Create a hidden folder to house the container's private files
mkdir -p ~/.local/share/astro-container-home

```

---

## Phase 2: Create the Sandboxed Container
Generate the CDI (Container Device Interface) map:
This tells Podman exactly how to route your Nvidia GPU into containers.

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
```
The "Foolproof" Container Creation

Warning: Do not use the Boxbuddy GUI to create your Nvidia containers. The GUI’s "Nvidia Integration" toggle triggers Distrobox's native --nvidia bash script, which we discovered will permanently freeze on Arch's multilib packages.

Instead, we use Podman's CDI directly in the terminal to silently bypass the bug.

Wake up the GPU (The Hybrid Graphics Trick):
Because your GTX 1650 goes into a deep sleep to save battery, keep it awake during the initial build so Podman can see it. Open a separate terminal and leave this running:

```bash
watch -n 1 nvidia-smi
```
We will use the `--home` flag to point the container to the new directory, and the `--additional-flags` argument to ensure your Nvidia GPU is seamlessly passed through without triggering the Arch multilib bug.

*Note: If your GPU is asleep, remember to run watch -n 1 nvidia-smi in a second terminal before running this command.*

```bash
# Create the isolated Ubuntu container with GPU access
distrobox create \
  --name astro-box \
  --image ubuntu:22.04 \
  --home ~/.local/share/astro-container-home \
  --additional-flags "--device=nvidia.com/gpu=all"

```

---

## Phase 3: Enter and Prep the Environment

Enter your newly isolated container:

```bash
distrobox enter astro-box

```

Because you are using a custom home directory, Distrobox will not copy over your CachyOS aliases or your Fish shell configs. You will be dropped into a completely clean, vanilla Ubuntu bash prompt.

Install the foundational build tools required by Conda/Mamba and Python packages:

```bash
sudo apt update
sudo apt install -y wget curl bzip2 git build-essential

```

---

## Phase 4: Safe Miniforge/Mamba Installation

You are now completely safe to run standard installation scripts. Because of the `--home` flag, the installer will target `~/.local/share/astro-container-home/miniforge3` instead of your real CachyOS home folder.

```bash
# Download the Miniforge installer
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"

# Run the installer
bash Miniforge3-Linux-x86_64.sh

```

**During the installation prompt:**

- Press `Enter` to review the license.
- Type `yes` to accept.
- Press `Enter` to confirm the default installation location.
- Type `yes` when it asks to initialize Miniforge3 (This edits the container's isolated `.bashrc`, keeping your host completely safe).

---

## Phase 5: Activate and Use

Once the installation finishes, reload the container's bash configuration to activate Mamba:

```bash
source ~/.bashrc

```

You should now see `(base)` next to your prompt! You have successfully built a totally isolated, GPU-accelerated environment. You can install your astrophysics libraries, compile your scripts, and run your data analysis without any fear of breaking CachyOS.
---

## The Permanent Fix (The Fish Shell Shortcut)

Since you are using `fish` on your CachyOS host, you shouldn't have to open two terminal windows every time you want to work on your thesis. We can create a quick function that automatically pings the GPU to wake it up a split-second before entering the container.

Run this in your main CachyOS terminal (outside the container):
```bash
function astro
    # Ping the GPU to wake it up silently
    nvidia-smi > /dev/null 2>&1
    # Enter the container
    distrobox enter astro-box
end

# Save the function permanently
funcsave astro
```
---

If your native VS Code window opens and shows your container's current directory, the bridge is successfully established! You can now edit your GRB analysis scripts with full GUI support while keeping the math isolated in your Ubuntu bubble.
