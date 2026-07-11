if i cahnge configs how 

# 01 - Network and Remote Access Guide

This document aggregates all guides related to local networking, file sharing, and remote access.

---

## 1. High-Speed KSMBD File Sharing

> [!NOTE]
> **Automated Setup Completed:** If you ran `02-app-config.sh`, the system has already installed `ksmbd-tools` and `cifs-utils`, and created the necessary `/etc/ksmbd`, `/etc/samba`, and `/mnt/Remote_Folder` directories. You only need to follow these manual configuration steps to bring the network online!

This guide is structured into two main phases: configuring the machine sharing the files (Server), and configuring the machine accessing the files (Client). Because you enabled Bidirectional File Sharing, you will perform **both** phases on **each** machine.

### Phase 1: Configuring the SERVER (To Share Files)

Follow these steps on the machine that owns the physical files you want to share.

#### 1. Set the Network Password

Create the password that the other machine will use to connect.

```bash
sudo ksmbd.adduser -a void
```

#### 2. Configure the Shared Folders

Open the server configuration file:

```bash
sudo nano /etc/ksmbd/ksmbd.conf
```

Paste the following structure (you can add as many `[ShareName]` blocks as you want):

```ini
[global]
    netbios name = HostnameHere
    workgroup = WORKGROUP
    server string = KSMBD Server

[ShareName]
    path = /path/to/your/folder
    read only = no
    guest ok = no
    valid users = @void
    force user = void
    force group = void
```

#### 3. Open the Firewall

Allow the SMB protocol through UFW so the other machine can connect:

```bash
sudo ufw allow 445/tcp
```

#### 4. Start the Server

Apply the configuration and start the background service:

```bash
sudo modprobe ksmbd
sudo systemctl enable --now ksmbd.service
sudo systemctl restart ksmbd.service
```

### Phase 2: Configuring the CLIENT (To Access Files)

Follow these steps on the machine that wants to read the files over the network.

#### 1. Create the Secure Credentials File

This hides your password from plain text.

```bash
sudo nano /etc/samba/credentials
```

Add the login info (using the password you created in Phase 1):

```text
username=void
password=YOUR_KSMBD_PASSWORD
```

#### 2. Lock Down the Credentials

Secure the file so others can't read it, but ensure your user account has permission to read it when you click the drive in Dolphin:

```bash
sudo chmod 600 /etc/samba/credentials
sudo chown $USER:$USER /etc/samba/credentials
```

#### 3. Edit the File Systems Table (fstab)

Open your fstab file:

```bash
sudo nano /etc/fstab
```

Add the manual mount line at the bottom. Replace `IP_ADDRESS` and `ShareName`.

> [!IMPORTANT]
> We use `users,noauto,nofail,_netdev` to ensure the drive only connects when you click it in Dolphin, preventing boot hangs when the server is offline!

```text
//IP_ADDRESS/ShareName  /mnt/Remote_Folder  cifs  credentials=/etc/samba/credentials,uid=1000,gid=1000,vers=3.1.1,users,noauto,nofail,_netdev  0  0
```

#### 4. Activate the Mount

Reload system daemons to recognize the new fstab entry:

```bash
sudo systemctl daemon-reload
sudo systemctl restart local-fs.target
```

*The folder will now instantly connect to the server only when you actively double-click the drive in Dolphin!*

### Phase 3: Advanced KSMBD Operations & Troubleshooting

#### Option A: Using Hostnames Instead of IPs (For Laptops)

If your laptop constantly changes IPs on Wi-Fi, you can use its `.local` hostname instead.

1. Ensure both machines have unique names (`sudo hostnamectl set-hostname new-name`).
2. Check the server's name using `hostname`.
3. In the client's `/etc/fstab`, replace the IP address with the hostname like this: `//TargetHostname.local/ShareName`.
4. Run `sudo systemctl daemon-reload` and `sudo systemctl restart local-fs.target`.

#### Option B: Accessing Files While Using Cloudflare WARP

WARP intercepts local network traffic, breaking your KSMBD connection. Create a split tunnel:

1. Find your local subnet (e.g., `192.168.1.0/24` or `172.21.0.0/22`) using `ip a`.
2. Add the bypass route: `warp-cli tunnel ip add-range 192.168.1.0/24`
3. Restart WARP: `warp-cli disconnect` then `warp-cli connect`.

#### Option C: Sharing a NEW Folder

1. **Server:** Add a new `[NewDrive]` block to `/etc/ksmbd/ksmbd.conf` and run `sudo systemctl restart ksmbd.service`.
2. **Client:** Run `sudo mkdir -p /mnt/NewDrive_Remote`, add a new line to `/etc/fstab`, and run `sudo systemctl daemon-reload`.

#### Option D: Removing Duplicate Drives in Dolphin

If you see two identical network drives in Dolphin:

* **The Easy UI Way:** Right-click the duplicate in Dolphin's sidebar and select **"Hide"**.
* **The Fstab Way:** Add `x-gvfs-hide` to your `/etc/fstab` mount options, then run `sudo systemctl daemon-reload`.

---

## 2. Remote Internet Access & Cloudflare Tunnels

This covers everything from a totally blank slate to a fully automated, firewall-bypassing remote desktop setup across all your devices.

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

---

## 3. Multiplayer Game Hosting Guide (Node.js)

### Method 1: The Local "LAN Party" Server

**Best for:** When everyone is in the same room connected to the exact same Wi-Fi router.

**Step 1: Open the Firewall**

```bash
sudo ufw allow 3000/tcp
sudo ufw allow 10000/tcp
sudo ufw reload
```

**Step 2: Start Your Game**

```bash
node server.js
```

**Step 3: Find Your Local IP Address**
Run `ip -br a` and grab the IP next to your active connection (e.g. `192.168.1.50`).
Give players the link: `http://YOUR_IP:YOUR_PORT`

### Method 2: The Cloudflare Global Tunnel

**Best for:** When players are on different Wi-Fi networks or mobile data.

**Step 1: Start Your Game**

```bash
node server.js
```

**Step 2: Launch the Encrypted Tunnel**

```bash
cloudflared tunnel --protocol http2 --url http://localhost:3000
```

**Step 3: Grab the Golden Link**
Copy the generated `https://random-words-here.trycloudflare.com` URL and give it to your players.

---

## 4. How to Set a Static IP in Linux (Wi-Fi & Ethernet)

### Phase 1: Gather Your Network Information

1. Run `ip a` to find your IP and Subnet Mask (e.g. `inet 172.21.1.129/22`).
2. Run `ip route | grep default` to find your Default Gateway.

### Phase 2: Configure via `nmtui`

1. Open `nmtui`.
2. Select **Edit a connection**.
3. Select your active network interface.
4. Change **IPv4 CONFIGURATION** from `<Automatic>` to **`<Manual>`**.
5. Arrow over to **`<Show>`** and expand the settings.
6. Enter your IP+subnet in **Addresses**, your **Gateway**, and **DNS servers** (`1.1.1.1` and `8.8.8.8`).
7. Save by selecting `<OK>`.

### Phase 3: Apply and Verify

1. Back on the main `nmtui` menu, select **Activate a connection**.
2. Deactivate and reactivate your connection.
3. Run `ping -c 4 google.com` to verify internet access.
