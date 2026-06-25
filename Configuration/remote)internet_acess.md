Here is the complete, fully automated guide. This leverages your existing Syncthing setup to bridge the gap until you get a permanent domain.

We will configure the institute PC to automatically start the tunnel on boot and write the randomized Cloudflare URL directly into your sync folder. Your client devices will then use that URL to connect with a single command.

---

### Phase 1: Automating the Institute PC (Host)

We will use **user-level systemd services**. This ensures the tunnels start automatically when you log in, run in the background, and have the correct permissions to write to your `~/Sync` folder.

**Step 1: Create the Systemd Directories**
Open a terminal on your institute PC and create the necessary folder:

```bash
mkdir -p ~/.config/systemd/user/

```

**Step 2: Create the Chisel Background Service**
Create the service file:

```bash
nano ~/.config/systemd/user/chisel-server.service

```

Paste this configuration, then save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`):

```ini
[Unit]
Description=Chisel Server for Moonlight
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/env chisel server --port 8080 --auth "yash:MySecurePassword123"
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target

```

**Step 3: Create the Cloudflare URL Sync Service**
Create the second service file:

```bash
nano ~/.config/systemd/user/cloudflared-tunnel.service

```

Paste this configuration. *(This specifically forces HTTP2 to bypass the firewall and pipes the generated URL directly into your Syncthing folder).*

```ini
[Unit]
Description=Cloudflare Tunnel to Sync Folder
After=chisel-server.service

[Service]
Type=simple
ExecStart=/bin/bash -c "cloudflared tunnel --protocol http2 --url http://localhost:8080 2> %h/Sync/tunnel_url.txt"
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target

```

**Step 4: Enable and Start the Automation**
Run these commands to activate both services permanently:

```bash
systemctl --user daemon-reload
systemctl --user enable --now chisel-server.service
systemctl --user enable --now cloudflared-tunnel.service

```

Your institute PC is now fully autonomous. Every time it turns on, it will secure the ports and silently drop the current streaming URL into `~/Sync/tunnel_url.txt`.

---

### Phase 2: The One-Click Laptop Client (CachyOS / Niri)

Since your laptop receives that `tunnel_url.txt` file via Syncthing, we can write a native `fish` function that automatically reads the file, extracts the URL, and launches the connection. You won't even have to copy and paste.

**Step 1: Create the Fish Function**
Open a terminal on your laptop and run this block:

```fish
function stream_pc
    echo "Scanning Sync folder for latest tunnel URL..."
    set TUNNEL_URL (grep -o 'https://[a-zA-Z0-9.-]*\.trycloudflare\.com' ~/Sync/tunnel_url.txt | tail -n 1)
    
    if test -z "$TUNNEL_URL"
        echo "Error: No Cloudflare URL found in ~/Sync/tunnel_url.txt"
        return 1
    end
    
    echo "Connecting to: $TUNNEL_URL"
    chisel client --auth "yash:MySecurePassword123" $TUNNEL_URL \
        47984:127.0.0.1:47984 47989:127.0.0.1:47989 48010:127.0.0.1:48010 \
        47998:127.0.0.1:47998/udp 47999:127.0.0.1:47999/udp \
        48000:127.0.0.1:48000/udp 48002:127.0.0.1:48002/udp
end

```

**Step 2: Save the Function Permanently**

```fish
funcsave stream_pc

```

---

### Phase 3: The Android Tablet Client (Termux)

On your tablet, you will likely just open your Android Syncthing app (or whatever text editor you use) to glance at the `tunnel_url.txt` file, copy the link, and pass it to a simple script.

**Step 1: Create the Executable Script**
Open Termux on your tablet and paste this to generate the script:

```bash
cat << 'EOF' > ~/stream_pc
#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: ./stream_pc https://your-url.trycloudflare.com"
  exit 1
fi
~/go/bin/chisel client --auth "yash:MySecurePassword123" $1 \
  47984:127.0.0.1:47984 47989:127.0.0.1:47989 48010:127.0.0.1:48010 \
  47998:127.0.0.1:47998/udp 47999:127.0.0.1:47999/udp \
  48000:127.0.0.1:48000/udp 48002:127.0.0.1:48002/udp
EOF

```

**Step 2: Make it Executable**

```bash
chmod +x ~/stream_pc

```

---

### Your New Daily Workflow

**From the Laptop:**

1. Open a terminal.
2. Type `stream_pc` and hit Enter.
3. Open Moonlight (`QT_QPA_PLATFORM=wayland moonlight`) and connect to `127.0.0.1`.

**From the Tablet:**

1. Check your synced `tunnel_url.txt` file and copy the link.
2. Open Termux and type `./stream_pc [paste-the-link-here]`.
3. Open the Moonlight app and connect to `127.0.0.1`.
