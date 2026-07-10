This covers everything from a totally blank slate to a fully automated, firewall-bypassing remote desktop setup across all your devices.

---

### Phase 1: Global Installation

Before automating anything, we need to ensure the correct tools are installed safely on all three devices. We will use `go install` for Chisel everywhere to completely bypass any AUR supply-chain risks.

**1. On the Institute PC (Host)**
Open your terminal and install the streaming host, the tunnel daemon, and the Go compiler:

```bash
sudo pacman -Syu
sudo pacman -S sunshine cloudflared go

```

Now, compile Chisel locally and link it to your system binaries:

```bash
go install github.com/jpillora/chisel@latest
sudo ln -s ~/go/bin/chisel /usr/local/bin/chisel

```

**2. On the Laptop (Client)**
Install the Moonlight client and the Go compiler:

```bash
sudo pacman -Syu
sudo pacman -S moonlight-qt go

```

Compile and link Chisel:

```bash
go install github.com/jpillora/chisel@latest
sudo ln -s ~/go/bin/chisel /usr/local/bin/chisel

```

**3. On the Android Tablet (Client)**

1. Install **Moonlight Game Streaming** from the Google Play Store.
2. Install **Termux** from F-Droid or GitHub (do not use the Play Store version).
3. Open Termux and run these commands to install your environment and Chisel:

```bash
pkg update && pkg upgrade -y
pkg install golang -y
go install github.com/jpillora/chisel@latest

```

---

### Phase 2: Automating the Institute PC (The Server)

We will configure your PC to launch the Chisel server and the Cloudflare tunnel in the background every time it boots, automatically piping the randomized URL into your Syncthing directory.

**Step 1: Create the Systemd Directory**

```bash
mkdir -p ~/.config/systemd/user/

```

**Step 2: Create the Chisel Service**

```bash
nano ~/.config/systemd/user/chisel-server.service

```

Paste this configuration, save, and exit:

```ini
[Unit]
Description=Chisel Server for Moonlight
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/chisel server --port 8080 --auth "yash:MySecurePassword123"
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target

```

**Step 3: Create the Cloudflare Tunnel Service**
This strictly forces standard HTTPS (`http2`) to slip past the campus DPI firewall.

```bash
nano ~/.config/systemd/user/cloudflared-tunnel.service

```

Paste this configuration, save, and exit:

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

**Step 4: Enable and Start**

```bash
systemctl --user daemon-reload
systemctl --user enable --now chisel-server.service
systemctl --user enable --now cloudflared-tunnel.service

```

---

### Phase 3: Automating the Laptop (The Fish Client)

Your laptop receives `tunnel_url.txt` silently in the background via Syncthing. This `fish` function will read that file, extract the active URL, and instantly establish the connection.

**Step 1: Write the Function**
Run this block in your laptop's terminal:

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

**Step 2: Save it Permanently**

```fish
funcsave stream_pc

```

---

### Phase 4: Automating the Android Tablet (The Termux Client)

**Step 1: Create the Executable Script**
Open Termux and run this block to generate your connection script:

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

### Phase 5: Your Daily Workflow

The installation and configuration are entirely finished. Here is how you will connect moving forward:

**From the Laptop:**

1. Open your terminal.
2. Type `stream_pc` and press Enter.
3. Launch Moonlight (`QT_QPA_PLATFORM=wayland moonlight`) and connect to **`127.0.0.1`**.

**From the Tablet:**

1. Open your Syncthing app (or file browser), open `tunnel_url.txt`, and copy the Cloudflare link.
2. Open Termux and type: `./stream_pc [paste-link-here]`
3. Leave Termux running, open the Moonlight app, and connect to **`127.0.0.1`**.
