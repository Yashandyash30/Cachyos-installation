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

Here are the additions you can copy and paste directly into your "Ultimate CachyOS + Niri Sunshine Guide".

This covers everything we just went through, including the specific Wayland/Niri quirks.

---

## Phase 7: Installing & Pairing Moonlight (The Client)

*(Note: The host software that sends the stream is **Sunshine**. The client software that receives the stream is **Moonlight**!)*

To allow your machines to stream to each other, you need Moonlight installed on any device that will act as a client.

**1. Install Moonlight**
Run this on your CachyOS machines:

```bash
sudo pacman -Syu moonlight-qt

```

**2. Pair the Devices**
Because your local firewall (`ufw`) is already configured, auto-discovery will work instantly on your local network.

1. Open **Moonlight** on the client machine.
2. Click the icon for your host PC/Laptop. Moonlight will display a 4-digit PIN.
3. Open the Sunshine Web UI on the host machine (`https://localhost:47990` or via its local IP).
4. Click the **PIN** tab at the top and enter the 4-digit PIN to authorize the connection.

---

## Phase 8: Crucial Wayland & Niri Quirks

Wayland’s strict security model introduces a few hurdles when streaming. Keep these in mind for a smooth experience:

### 1. The "First Launch" Screen Share Prompt

The very first time you launch a Desktop session from Moonlight, the stream will appear to hang. Look at the physical screen of your **host** machine. Wayland uses `xdg-desktop-portal` for security, meaning a prompt will pop up asking for permission to "Share this screen." You must physically click **Allow** on the host before the video feed will push through.

### 2. The "Greedy" Super Key (Keyboard Capturing)

If you press global Niri shortcuts (like `Super + Enter`) while streaming, they will trigger on your *local* machine instead of the remote host because Niri intercepts them first.

**To fix this:**

* **Method 1:** In Moonlight, click the Settings (Gear icon) -> Input Settings -> **Capture system keyboard shortcuts** and set it to **Always** (or ensure you are playing in true Fullscreen mode, as Wayland often denies keyboard inhibiting to windowed apps).
* **Method 2:** While actively streaming, press `Ctrl + Alt + Shift + Z` to instantly toggle keyboard capture on or off.

### 3. Wayland Shell Crashes (`wlr-screencopy`)

When Moonlight connects, Sunshine uses the `wlr-screencopy` protocol to aggressively hook into your Wayland compositor. If you are using bleeding-edge `-git` packages for your panels or shells (like `quickshell-git`), they may panic and crash when this hook occurs.

* **Fix:** Always use the stable release of your Wayland shell to ensure compatibility with screen capturing.

### 4. Eradicating Legacy X11 Commands (The `xrandr` Ghost)

If your stream instantly crashes or fails to connect, check your Sunshine logs (`~/.config/sunshine/sunshine.log`) for `xrandr` errors. Old X11 display commands will fatally clash with a pure Wayland environment like Niri.

If the Sunshine Web UI does not show any commands in the **Global Prep Commands** or Application settings, the ghost command is likely stuck in the raw config files.

**To kill it:**

1. Open your apps configuration:
```bash
nano ~/.config/sunshine/apps.json

```


2. Find the "do" and "undo" lines containing `xrandr` commands.
3. Delete the text *inside* the quotes, leaving them empty:
```json
"do": "",
"undo": ""

```


4. Save the file and restart the host service:
```bash
systemctl --user restart app-dev.lizardbyte.app.Sunshine

```
