Here is the master reference guide for your complete workstation architecture. This documents exactly how to rebuild your bidirectional kernel-level network share and your isolated astrophysics data reduction pipeline on CachyOS, without the troubleshooting steps.

You can save this for whenever you need to reinstall your system, add a new drive, or replicate this setup on future institutional hardware.

---

### Part 1: High-Speed Bidirectional Network Sharing (`ksmbd`)

This connects your PC (`172.21.1.250`) and your Laptop (`172.21.1.129`) for maximum-speed file transfers over the campus network, bypassing Cloudflare WARP restrictions and UFW firewalls.

**1. Set up the Server (The machine holding the files)**

1. Install the tools: `paru -S ksmbd-tools`
2. Create the network password: `sudo ksmbd.adduser -a void`
3. Edit the configuration file: `sudo nano /etc/ksmbd/ksmbd.conf`
```ini
[global]
    netbios name = HostnameHere
    workgroup = WORKGROUP
    server string = KSMBD Server

[ShareName]
    path = /path/to/your/shared/folder
    read only = no
    guest ok = no
    valid users = @void
    force user = void
    force group = void

```


4. Open the UFW firewall: `sudo ufw allow 445/tcp`
5. Enable and start the server:
```bash
sudo modprobe ksmbd
sudo systemctl enable --now ksmbd.service

```



**2. Set up the Client (The machine accessing the files)**

1. Install the tools: `sudo pacman -S cifs-utils`
2. Create the hidden credentials file: `sudo nano /etc/samba/credentials`
```text
username=void
password=YOUR_NETWORK_PASSWORD

```


3. Lock the file: `sudo chmod 600 /etc/samba/credentials`
4. Create the mount point: `sudo mkdir -p /mnt/Remote_Folder`
5. Add the automount trigger to `/etc/fstab`:
```text
//TARGET_IP/ShareName  /mnt/Remote_Folder  cifs  credentials=/etc/samba/credentials,uid=1000,gid=1000,vers=3.1.1,x-systemd.automount,noauto,x-systemd.idle-timeout=600,_netdev  0  0

```


6. Activate it:
```bash
sudo systemctl daemon-reload
sudo systemctl restart remote-fs.target
sudo systemctl restart local-fs.target

```



**3. Android / Tablet Access**
Connect your Galaxy Tab S9 to the same Wi-Fi.

* **For file management:** Use an app like Material Files, add an SMB connection pointing to your PC/Laptop IP, and log in with your `void` credentials.
* **For streaming:** Open VLC for Android, go to the Local Network tab, select your PC, and stream `.mkv` files directly from your shared drives.

---

### Part 2: Network Speed Benchmarking

To verify your network is operating at its maximum capacity.

* **Test Raw Network Capacity (`iperf3`):** * Server machine: `sudo ufw allow 5201/tcp` then `iperf3 -s`
* Client machine: `iperf3 -c TARGET_IP`


* **Test Real-World Read/Write Speed (`rsync`):**
* Push a large file: `rsync --progress /path/to/local/file.mkv /mnt/Remote_Folder/`
* *Note: Expect ~30-50MB/s on solid campus Wi-Fi, and ~115MB/s on a hardwired gigabit connection.*



---

### Part 3: The Isolated Astrophysics Subsystem (Distrobox)

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

---

### Part 4: Daily Workflow & Graphics Testing

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
