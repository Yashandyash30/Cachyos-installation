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

```

Click the folder in Dolphin to reconnect with your new password!
