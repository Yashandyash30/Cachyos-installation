# The Isolated Astrophysics Subsystem (Distrobox)

This creates a sandboxed Ubuntu 22.04 LTS environment that runs legacy NOAO software natively, bridges X11 graphics directly to your Niri Wayland compositor, and keeps your CachyOS host entirely clean.

**1. Prepare the CachyOS Host**

1. Install the container tools and display bridge: `sudo pacman -S podman distrobox xorg-xhost`
2. Create the isolated home directory for the container: `mkdir -p ~/astrobox_home`
3. Grant local display permission (add this to your host `~/.bashrc` or `~/.zshrc`): `xhost +si:localuser:void`

**2. Build the Ubuntu 22.04 Container**

1. Create the sandbox:
```bash
distrobox create --name astrobox --image ubuntu:22.04 --home ~/astrobox_home

```


2. Enter the container: `distrobox enter astrobox`
3. *Crucial:* If your terminal loads into `fish` and throws an error, type `bash` to switch to a standard shell before installing software.

**3. Install the Legacy Data Reduction Stack**
Because the `iraf-community` Conda channel was deprecated, install the official packages directly from Ubuntu's repositories inside the container:

```bash
sudo apt update
sudo apt install iraf iraf-dev xgterm python3-pyraf saods9 -y

```


**Daily Workflow & Graphics Testing**

Whenever you need to reduce GRB or Supernova data, this is your workflow:

1. Open your CachyOS terminal and enter the subsystem: `distrobox enter astrobox`
2. Navigate to your automatically mounted network share: `cd /mnt/Storage/GRB_DATA`
3. Launch the environment: `pyraf`

**The Benchmark Graphics Test**
Run these commands inside PyRAF to verify the XWayland integration is flawlessly displaying interactive windows on your desktop:

1. `!ds9 &` *(Opens the SAOImage DS9 viewer).*
2. `display dev$pix 1` *(Pushes the standard M51 test image to DS9).*
3. `implot dev$pix` *(Opens the interactive X11 plot. Hover your mouse over the graph and press **`c`** to test keyboard interrupts, then **`q`** to quit).*
4. `surface dev$pix` *(Renders a 3D wireframe plot).*
