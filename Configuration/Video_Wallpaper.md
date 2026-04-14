Here is your definitive, step-by-step master guide for setting up hardware-accelerated video wallpapers on your Wayland setup. Save this for whenever you need to rebuild your environment from scratch!

## The Wayland Video Wallpaper Master Guide

### Phase 1: Core Installation

First, install the base rendering engine and the standalone GUI manager. `mpvpaper` handles the video drawing, and `waypaper` gives you a graphical interface to manage it.

Run this in your terminal:

```bash
paru -S mpvpaper waypaper

```

### Phase 2: Verifying Hardware Acceleration (VAAPI)

Before plugging anything into a GUI, you must ensure your GPU can decode the video natively. If you skip this, `mpvpaper` will fallback to software decoding and consume massive amounts of CPU.

1. Open your terminal.
2. Run a test command against a standard `.mp4` file (do **not** use `.webp` or `.gif`):

```bash
mpvpaper -o "--hwdec=vaapi" '*' /path/to/your/video.mp4

```
3. Look at the terminal output. If you see `VO: [libmpv] ... vaapi[nv12]` and your CPU usage stays low, your hardware acceleration is working perfectly. Press `Ctrl+C` to close it.

---

### Phase 3: Configuring Standalone Waypaper

If you are using the standard Waypaper application to manage your backgrounds, you need to tell it to inject your hardware decoding flags.

1. Open the Waypaper configuration file:

```bash
nano ~/.config/waypaper/config.ini

```
2. Locate the `[Settings]` block.
3. Add or modify the `mpvpaper_options` line to include your exact `mpv` flags:

```ini, toml
mpvpaper_options = -o "hwdec=vaapi loop-file=inf no-audio"

```
4. Save and restart Waypaper.

---

### Phase 4: Configuring the Dank Material Shell Plugin

If you are using the Dank Shell Wayland environment, it has its own built-in GUI wrapper for `mpvpaper`.

1. Open the Dank Shell settings and navigate to the **Video Wallpaper Plugin** section.
2. Scroll down to the **Advanced** section.
3. Locate the text box labeled **Custom mpv Options**.
4. Type your hardware decoding flag exactly like this:

```plaintext
--hwdec=vaapi

```

*(Note: You do not need to type the -o wrapper here; the Dank Shell plugin automatically formats it for you in the background).*
5. Click **Apply**.

---

### Phase 5: Crucial Rules & Troubleshooting

To keep your system stable and avoid the Out Of Memory (OOM) crashes we encountered previously, follow these golden rules:

- **Strictly Use .mp4 Files:** Video engines like `mpvpaper` are built for standard video codecs (H.264/H.265). Trying to force animated images like `.webp` or `.gif` will either crash the engine or bypass hardware acceleration entirely.
- **Respect the Resolution:** If you have a 1080p monitor, use a 1080p video. Using a 4K 60FPS video on a lower-resolution screen forces the GPU to downscale it in real-time, wasting resources.
- **The "Ghost" Fix:** If wallpapers ever stop loading or you get an "Already running" error, it means an old instance crashed but didn't close. Kill it with:

```bash
killall -9 mpvpaper

```

---

Now that your visual environment is fully dialed in, do you want to back up these specific configuration lines into your `my-dotfiles` GitHub repository so you can auto-deploy them in the future?
