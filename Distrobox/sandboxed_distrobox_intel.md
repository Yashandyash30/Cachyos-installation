Since this machine relies entirely on the i7-14700's CPU power without a dedicated GPU, we can strip out all the messy Podman CDI and Nvidia-SMI workarounds from the previous guide. The core isolation concept remains exactly the same, but the setup is now much cleaner and faster.

Here is the updated, streamlined guide for your current specs.

---

# Isolated Distrobox Guide: The "Sandboxed Home" Method

This guide creates a completely isolated Ubuntu container with its own private home folder. This prevents Python environments (like Miniforge/Mamba) installed inside the container from forcefully injecting paths into your host's `~/.config/fish`, keeping your CachyOS environment pristine.

1. **Prepare the Host Directory:**
Before creating the container, we need to create a physical folder on your CachyOS host that will act as the "fake" home directory for the container. Run this in your main CachyOS terminal:

```bash
# Create a hidden folder to house the container's private files
mkdir -p ~/.local/share/astro-container-home

```


2. **Create the Sandboxed Container:** Simplified for i7-14700.
We will use the `--home` flag to point the container to the new directory. Without the Nvidia GPU to worry about, the command is clean and simple:

```bash
# Create the isolated Ubuntu container
distrobox create \
  --name astro-box \
  --image ubuntu:22.04 \
  --home ~/.local/share/astro-container-home

```


3. **Enter and Prep the Environment:**
Enter your newly isolated container:

```bash
distrobox enter astro-box

```

Because you are using a custom home directory, Distrobox will not copy over your CachyOS aliases or your Fish shell configs. You will be dropped into a completely clean, vanilla Ubuntu bash prompt. Install the foundational build tools required by Conda/Mamba:

```bash
sudo apt update
sudo apt install -y wget curl bzip2 git build-essential

```


4. **Install Miniforge/Mamba:**
You are now completely safe to run standard installation scripts. Because of the `--home` flag, the installer will target `~/.local/share/astro-container-home/miniforge3` instead of your real CachyOS home folder.

```bash
# Download the Miniforge installer
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"

# Run the installer
bash Miniforge3-Linux-x86_64.sh

```

**During the installation prompt:**

* Press `Enter` to review the license.
* Type `yes` to accept.
* Press `Enter` to confirm the default installation location.
* Type `yes` when it asks to initialize Miniforge3 (This edits the container's isolated `.bashrc`, keeping your host completely safe).


5. **Activate and Build the Analysis Environment:**
Once the installation finishes, reload the container's bash configuration to activate Mamba:

```bash
source ~/.bashrc

```

You should now see `(base)` next to your prompt! You can safely create your astrophysics environment. Here is a command to quickly build a stable environment that avoids the known `ValueError` caused by newer Dynesty versions:

```bash
# Create an environment locking the Goldilocks versions
mamba create -n astro python=3.10 prospector=1.4.1 dynesty=2.0.3
mamba activate astro

```


6. **Set Up the Fish Shortcut:** Run on host system.
Since you are using `fish` on your CachyOS host, we can create a quick function to enter your container instantly.

Open a **new CachyOS terminal tab** (outside the container) and run:

```bash
function astro
  distrobox enter astro-box
end

# Save the function permanently
funcsave astro

```


---

If your native VS Code window opens and shows your container's current directory, the bridge is successfully established! You can now edit your GRB analysis scripts with full GUI support on Niri while keeping the math isolated in your Ubuntu bubble.
