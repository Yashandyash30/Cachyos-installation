Here is the finalized, updated master guide. It includes the security ownership fix and the exact `fstab` flags needed for seamless, error-free mounting in Dolphin.

---

### The Master Guide: High-Speed KSMBD File Sharing on CachyOS

This is the complete reference for setting up bidirectional file sharing using `ksmbd` and UFW. Save this for whenever you need to rebuild your system, add a new drive, or troubleshoot a connection.

---

### Prerequisites (On Both Machines)

Before a machine can share or access files, it needs the required packages.

1. **For the Server (Sharing files):**
```bash
paru -S ksmbd-tools
sudo mkdir -p /etc/ksmbd

```


2. **For the Client (Accessing files):**
```bash
sudo pacman -S cifs-utils
sudo mkdir -p /etc/samba

```



---

### Part 1: How to Set Up the Server (To Share Files)

Follow these steps on the machine that owns the physical files.

**1. Create the Password**
Set the network password that the other machine will use to connect.

```bash
sudo ksmbd.adduser -a void

```

**2. Configure the Shared Folders**
Open the server configuration file:

```bash
sudo nano /etc/ksmbd/ksmbd.conf

```

Structure it like this (you can add as many folder blocks as you want under the `[global]` block):

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

**3. Open the Firewall**
Allow the SMB protocol through UFW so the other machine can connect:

```bash
sudo ufw allow 445/tcp

```

**4. Start/Restart the Server**
Apply the configuration and enable the service:

```bash
sudo modprobe ksmbd
sudo systemctl enable --now ksmbd.service
sudo systemctl restart ksmbd.service

```

---

### Part 2: How to Set Up the Client (To Access Files)

Follow these steps on the machine that wants to read the files over the network.

**1. Create the Secure Credentials File**
This hides your password from plain text.

```bash
sudo nano /etc/samba/credentials

```

Add the login info:

```text
username=void
password=YOUR_KSMBD_PASSWORD

```

**2. Lock Down & Assign Ownership**
Secure the file so others can't read it, but ensure *your* user account has permission to read it when you click the drive in Dolphin:

```bash
sudo chmod 600 /etc/samba/credentials
sudo chown $USER:$USER /etc/samba/credentials

```

**3. Create the Mount Point**
Create an empty folder where the remote files will appear:

```bash
sudo mkdir -p /mnt/Remote_Folder

```

**4. Edit the fstab**
Open the file systems table:

```bash
sudo nano /etc/fstab

```

Add the manual mount line (replace `IP_ADDRESS` and `ShareName`).

> **Important Note on Mount Options:** We use `users,noauto,nofail,_netdev` to ensure the drive only connects when you click it. The `users` flag allows your standard user account to mount it without needing `sudo`, and `noauto` prevents systemd from trying to connect in the background (which causes boot hangs when the server is offline).

```text
//IP_ADDRESS/ShareName  /mnt/Remote_Folder  cifs  credentials=/etc/samba/credentials,uid=1000,gid=1000,vers=3.1.1,users,noauto,nofail,_netdev  0  0

```

**5. Activate the Mount**
Reload system daemons to recognize the new fstab entry:

```bash
sudo systemctl daemon-reload
sudo systemctl restart local-fs.target

```

*The folder will now remain completely dormant during boot. It will instantly connect to the server only when you actively double-click the drive in Dolphin.*

---

### Part 3: How to Share a NEW Folder or Drive

Whenever you want to add a completely new folder to your network, it is a simple two-step process.

**Step 1: On the Server (The machine with the files)**

1. Open `/etc/ksmbd/ksmbd.conf`.
2. Add a new block at the bottom:
```ini
[NewDrive]
    path = /mnt/NewDrive
    read only = no
    guest ok = no
    valid users = @void
    force user = void
    force group = void

```


3. Restart the service: `sudo systemctl restart ksmbd.service`

**Step 2: On the Client (The machine accessing the files)**

1. Create a new mount point: `sudo mkdir -p /mnt/NewDrive_Remote`
2. Open `/etc/fstab` and add a new line pointing to `//IP_ADDRESS/NewDrive` (remember to use the exact same `users,noauto,nofail,_netdev` flags).
3. Reload systemd: `sudo systemctl daemon-reload` and restart `local-fs.target`.

---

### Part 4: How to Change the Network Password

If you ever need to change the password used for file sharing, you must update it on **both** machines.

**Step 1: Update the Server**
Run the add user command again. It will automatically overwrite the old password with the new one you type in:

```bash
sudo ksmbd.adduser -a void

```

Restart the service to apply it:

```bash
sudo systemctl restart ksmbd.service

```

**Step 2: Update the Client**
Open the hidden credentials file:

```bash
nano /etc/samba/credentials

```

*(Note: Since you took ownership of this file, you no longer need `sudo` to edit it).*

Delete the old password, type the new one, and save the file.

To ensure the client stops using the old cached password, unmount any active network drives and reload the daemon:

```bash
sudo umount -a -t cifs
sudo systemctl daemon-reload

Here is the new section. You can copy and paste this directly to the bottom of your master guide!

---

### Part 5: How to Access Files While Using Cloudflare WARP

If you are using Cloudflare WARP (or similar VPNs), it will aggressively intercept your local network traffic and try to route it through its own servers. This instantly breaks your connection to your KSMBD shared drives.

You must configure a "Split Tunnel" to tell WARP to ignore your local home network.

**1. Find Your Local Subnet**
First, determine the IP range of your local network. You can find this by running `ip a` and looking at your active Wi-Fi or Ethernet connection (look for a line like `inet 172.21.1.129/22` or `192.168.1.X/24`). The subnet is the base IP with the slash (e.g., `172.21.0.0/22`).

**2. Add the Bypass Route**
Run the following command to add your local network to WARP's exclusion list. *(Replace the IP range with your specific subnet if it is different).*

```bash
warp-cli tunnel ip add-range 172.21.0.0/22

```

**3. Restart the Connection**
The new routing rules will not take effect until the tunnel is rebooted. Run these commands to bounce the connection:

```bash
warp-cli disconnect
warp-cli connect

```

You can now keep Cloudflare WARP running 24/7 for privacy, and still click-to-mount your network drives in Dolphin without any interference!


Click the folder in Dolphin to reconnect with your new password!

---

### Part 6: How to Use Hostnames Instead of IP Addresses (For Laptops & Wi-Fi)

If you are sharing files with a machine that frequently switches between Wi-Fi and Ethernet (like a laptop), its IP address will constantly change, breaking your `/etc/fstab` mount. You can fix this by telling the network to look for the machine's name (`.local`) instead of its IP.

**Important Prerequisite: Unique Hostnames**
For this to work, every machine on your network **must** have a unique name. If both your PC and laptop share the exact same hostname (e.g., both are named `void`), the network will collide and fail to connect.

To give a machine a unique name, run this command (replace `new-name` with something like `void-pc` or `void-laptop`), and then reboot the system:

```bash
sudo hostnamectl set-hostname new-name

```

**Step 1: Find the Target Machine's Name**
On the machine that *owns* the files (the Server), open a terminal and check its current name:

```bash
hostname

```

*(Take note of this exact output).*

**Step 2: Update the fstab File**
On the machine trying to *access* the files (the Client), open your file systems table:

```bash
sudo nano /etc/fstab

```

Find your manual mount line. Replace the IP address with the Server's hostname, and attach `.local` directly to the end of it. Keep the rest of your flags exactly the same.

It should look like this (replace `TargetHostname` and `ShareName`):

```text
//TargetHostname.local/ShareName  /mnt/Remote_Folder  cifs  credentials=/etc/samba/credentials,uid=1000,gid=1000,vers=3.1.1,users,noauto,nofail,_netdev  0  0

```

**Step 3: Reload System Daemons**
Flush the old IP configuration and apply the new hostname tracking:

```bash
sudo systemctl daemon-reload
sudo systemctl restart local-fs.target

```

*Your mount point will now dynamically track the target machine across your local network, connecting instantly whether it is plugged into a router or running on Wi-Fi!*



### Part 7: Troubleshooting - How to Remove Duplicate Network Drives in Dolphin

Sometimes you might open Dolphin and see two identical network drives for the exact same folder. This happens for two completely different reasons: either a "ghost" of an old connection is stuck in the system, or Dolphin is double-reporting the drive.

Here is how to fix both.

**Scenario A: "Ghost" Duplicates (After changing an IP or Hostname)**
When you change the address in `/etc/fstab`, Linux's background service (`systemd`) generates a new mount profile, but the system often holds onto the old connection simultaneously.

To flush out the ghost entries and cleanly reset the connection:

1. Unmount all active and ghost network drives:

```bash
sudo umount -a -t cifs


```

*(Note: Ensure you do not have Dolphin open to a network folder when you run this, or it will say "target is busy").*

2. Reload systemd so it forgets the old configuration:

```bash
sudo systemctl daemon-reload


```

3. Restart the local filesystem target:

```bash
sudo systemctl restart local-fs.target


```

Close and reopen Dolphin. The ghost entry should be gone.

**Scenario B: "Discovery" Duplicates (Fstab + Network Scan)**
If you still see two folders, it is because Dolphin is showing your manual `/etc/fstab` mount **AND** automatically discovering your `ksmbd` server over the local network via standard scanning protocols (like mDNS).

You have two options to clean this up visually:

* **The Easy UI Way:** Simply right-click the duplicate you do not want to use in Dolphin's sidebar and select **"Hide"**.
* **The Fstab Way:** You can tell your file manager to ignore the `fstab` entry by adding `x-gvfs-hide` to your mount options. Your fstab line would look like this:

```text
//TargetHostname.local/ShareName  /mnt/Remote_Folder  cifs  credentials=/etc/samba/credentials,uid=1000,gid=1000,vers=3.1.1,users,noauto,nofail,_netdev,x-gvfs-hide  0  0


```

*(Remember to run `sudo systemctl daemon-reload` and restart `local-fs.target` if you edit the fstab file).*
