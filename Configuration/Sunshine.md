Here is the fully updated, comprehensive guide. It covers everything from the initial install to pinpointing your specific GPU nodes and configuring Sunshine based on your use case.

Save this for your next fresh install.

---

# The Ultimate CachyOS + Niri Sunshine Guide

## Phase 1: Native Installation

CachyOS maintains an optimized version of Sunshine in its official repositories. You also need the proper encoding libraries for both your Ryzen APU and GTX 1650, the firewall tool, and the VA-API testing utility.

Run this in your terminal:

```bash
sudo pacman -Syu sunshine cuda libva-mesa-driver libva-utils ufw
# Optional
sudo pacman -Syu cuda libva-mesa-driver libva-utils ufw
```
>  **Note** chech the prompt on terminal for  cuda libva-mesa-driver libva-utils ufw if they alreday exists dont install them.
>dont press y on promp to reinstall
## Phase 2: Firewall Configuration

Sunshine requires specific TCP and UDP ports to handle the web UI, pairing, gamepad inputs, and the low-latency video/audio streams. Without these, the stream will either fail to connect or drop immediately.

Enable UFW and punch the exact holes needed:

```bash
sudo ufw enable
sudo ufw allow 47984,47989,47990,48010/tcp
sudo ufw allow 47998:48010/udp
sudo ufw reload

```
If you are using **firewalld**, run these:

```bash
sudo firewall-cmd --permanent --add-port=47984-48010/tcp
sudo firewall-cmd --permanent --add-port=47998-48010/udp
sudo firewall-cmd --reload

```

## Phase 3: Systemd Initialization

Because you are running a pure Wayland compositor (Niri), Sunshine must be run as a **user service**, not a system-wide service. Never launch it directly from the terminal, as it will hold the port hostage and prevent the background service from starting.

Enable and start the service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now sunshine

```

*(To check if it is running smoothly in the background, use: systemctl --user status sunshine)*

> **Troubleshooting: "Unit sunshine.service does not exist"**
> 
> Depending on how the CachyOS package was built, the systemd service might not be named simply `sunshine`. It often uses the full application domain name instead.
> 
> If `systemctl` fails to find the service, locate the exact file name by running:
> ```bash
> pacman -Ql sunshine | grep \.service
> ```
> 
> If the output shows `/usr/lib/systemd/user/app-dev.lizardbyte.app.Sunshine.service`, you must use that exact name to enable and start it:
> 
> ```bash
> systemctl --user daemon-reload
> systemctl --user enable --now app-dev.lizardbyte.app.Sunshine
> systemctl --user status app-dev.lizardbyte.app.Sunshine
> ```
> *(Note: Any future commands to restart or stop the service must also use this full name).*

## Phase 4: Identify Your GPU Rendering Nodes

Because you have a hybrid setup (Ryzen APU + NVIDIA GTX 1650), your system has two rendering devices, typically `/dev/dri/renderD128` and `/dev/dri/renderD129`. You need to identify which is which before configuring Sunshine.

Run the `vainfo` command for **both** nodes to see their capabilities:

**Test Node 128:**

```bash
vainfo --display drm --device /dev/dri/renderD128 | grep -E "((VAProfileH264High|VAProfileHEVCMain|VAProfileHEVCMain10).*VAEntrypointEncSlice)|Driver version"

```

**Test Node 129:**

```bash
vainfo --display drm --device /dev/dri/renderD129 | grep -E "((VAProfileH264High|VAProfileHEVCMain|VAProfileHEVCMain10).*VAEntrypointEncSlice)|Driver version"

```

**How to read the output:**

- If the output shows a vendor ID of `10de`, that is your **NVIDIA GPU**. It will fail the VA-API test because NVIDIA natively uses NVENC, not VA-API.
- If the output shows `Mesa Gallium driver... for AMD Radeon Graphics` and lists `VAProfileH264High : VAEntrypointEncSlice`, that is your **AMD APU**.

## Phase 5: Choose Your Encoder Setup

Now that you know your nodes, open the Sunshine Web UI (**https://localhost:47990**) and navigate to the **Configuration -> Audio/Video** tab.

Choose the setup that best fits what you are streaming:

### Setup A: Use the AMD APU (Best for Wayland Desktop Stability)

Since Niri renders your Wayland desktop using your AMD integrated graphics to save battery, capturing and encoding on that same chip is the most stable route. It prevents EGL memory-sharing crashes between the AMD and NVIDIA chips.

1. **Adapter Name:** Enter your AMD node (e.g., `/dev/dri/renderD129`).
2. **Video Encoder:** Select **vaapi**.
3. Click **Save**.

### Setup B: Use the NVIDIA GPU (Best for Heavy Gaming)

If you are streaming demanding games that are running on the GTX 1650, you want NVIDIA to handle the encoding so you don't lose performance copying frames back to the AMD chip.

1. **Adapter Name:** Enter your NVIDIA node (e.g., `/dev/dri/renderD128`).
2. **Video Encoder:** Select **nvenc**.
3. Click **Save**.

## Phase 6: Apply & Connect

Whichever method you choose, you must restart the background service for the hardware encoder changes to take effect:

```bash
systemctl --user restart sunshine

```

**The Wayland Quirk:**
The very first time you connect from your client device (like Moonlight on a tablet or phone), look at your laptop screen. Wayland uses `xdg-desktop-portal` for security, meaning a Niri/GNOME prompt will pop up asking for permission to "Share this screen."

You must click **Allow** before the video feed will push through to your client.
