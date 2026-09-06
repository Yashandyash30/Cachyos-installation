# Complete Guide: Migrating from KSMBD to Standard Samba (SMBD)

This guide provides the exact step-by-step instructions to migrate bidirectional file sharing from kernel-space `ksmbd` to userspace standard Samba (`smbd`) on both your **Host PC** and **Laptop**.

---

## Why Migrate from KSMBD to SMBD?

* **The Problem with KSMBD (Kernel Space / Ring 0):** `ksmbd` contains an upstream kernel race condition in `ksmbd_smb_check_shared_mode()` during concurrent file operations. When triggered, it causes `list_add corruption`, sends kernel worker threads into infinite spinlocks (`R` state) or uninterruptible sleep (`D` state), spikes system load, and deadlocks file managers like Dolphin. Because it runs in the kernel, it cannot be killed and hangs system reboots.
* **The Advantage of Standard Samba (User Space / Ring 3):** Standard Samba (`smbd`) runs as a normal userspace daemon. It has been battle-tested for decades. Even under heavy concurrency conflicts, it cannot corrupt kernel memory, cannot hang kernel worker threads, and cannot freeze the operating system or shutdown routines.
* **Compatibility:** Both speak the exact same SMB protocol (SMB 3.1.1) on port `445/tcp`. **All client mount points, credentials files, and Dolphin bookmarks remain completely identical.**

---

## Overview: What Changes vs. What Stays the Same

| Component | Status | Notes |
| :--- | :--- | :--- |
| `/etc/samba/credentials` | **Unchanged** | Same username and password on both machines |
| Mount Points (`/mnt/*`) | **Unchanged** | `/mnt/PC_Home`, `/mnt/PC_Storage`, `/mnt/Laptop_Home` |
| Dolphin Bookmarks & Places | **Unchanged** | Works identically |
| Network & Tailscale IPs | **Unchanged** | `100.117.73.75` (PC) & `100.70.236.70` (Laptop) |
| Server Daemon | **Changed** | Replace `ksmbd.service` with `smb.service` |
| Server Config File | **Changed** | Move settings from `/etc/ksmbd/ksmbd.conf` to `/etc/samba/smb.conf` |
| Client `/etc/fstab` | **Optimized** | Add `soft,echo_interval=30` to prevent future hangs |

---

## Part 1: Host PC Configuration (`void-pc` — IP: `100.117.73.75`)

Follow these steps on the **Host PC** (either locally or via `ssh void@100.117.73.75`).

### 1. Clear Stuck Kernel Threads (Reboot)
If `ksmbd` previously crashed on the PC, reboot it to clear any deadlocked kernel threads:
```bash
sudo systemctl reboot -f
```
*(Once booted back up, reconnect via SSH or terminal).*

### 2. Stop and Disable KSMBD
```bash
sudo systemctl stop ksmbd.service
sudo systemctl disable ksmbd.service
```

### 3. Install Standard Samba
```bash
sudo pacman -S samba
```

### 4. Create `/etc/samba/smb.conf`
Open or create the configuration file:
```bash
sudo nano /etc/samba/smb.conf
```
Paste the following configuration:

```ini
[global]
    workgroup = WORKGROUP
    server string = Samba Server
    server role = standalone server
    security = user
    map to guest = bad user
    dns proxy = no

    # SMB Protocol specifications
    server min protocol = SMB3_00
    server max protocol = SMB3_11

[Storage]
    path = /mnt/Storage
    read only = no
    browseable = yes
    valid users = void
    force user = void
    force group = void
    create mask = 0664
    directory mask = 0775

[Home]
    path = /home/void
    read only = no
    browseable = yes
    valid users = void
    force user = void
    force group = void
    create mask = 0664
    directory mask = 0775
```

### 5. Set the Samba User Password
Add your user `void` to Samba's password database:
```bash
sudo smbpasswd -a void
```
> [!TIP]
> Enter the **exact same password** that you already have stored in the Laptop's `/etc/samba/credentials` file.

### 6. Enable and Start Samba Service
```bash
sudo systemctl enable --now smb.service
```
Verify that the service is running:
```bash
systemctl status smb.service
```

### 7. (Optional) Optimize PC Client Mount for Laptop
To ensure the PC never freezes if the Laptop disconnects unexpectedly, open `/etc/fstab` on the PC:
```bash
sudo nano /etc/fstab
```
Update the `Laptop_Home` entry with `soft,echo_interval=30`:
```text
//100.70.236.70/Home  /mnt/Laptop_Home  cifs  credentials=/etc/samba/credentials,uid=1000,gid=1000,users,vers=3.1.1,soft,echo_interval=30,noauto,nofail,_netdev  0  0
```
Apply changes:
```bash
sudo systemctl daemon-reload
```

---

## Part 2: Laptop Configuration (`void` — IP: `100.70.236.70`)

Follow these steps directly on the **Laptop**.

### 1. Stop and Disable KSMBD
```bash
sudo systemctl stop ksmbd.service
sudo systemctl disable ksmbd.service
```

### 2. Install Standard Samba
```bash
sudo pacman -S samba
```

### 3. Create `/etc/samba/smb.conf`
Open or create the configuration file:
```bash
sudo nano /etc/samba/smb.conf
```
Paste the following configuration:

```ini
[global]
    workgroup = WORKGROUP
    server string = Samba Laptop
    server role = standalone server
    security = user
    map to guest = bad user
    dns proxy = no

    # SMB Protocol specifications
    server min protocol = SMB3_00
    server max protocol = SMB3_11

[Home]
    path = /home/void
    read only = no
    browseable = yes
    valid users = void
    force user = void
    force group = void
    create mask = 0664
    directory mask = 0775
```

### 4. Set the Samba User Password
Add your user `void` to Samba's password database:
```bash
sudo smbpasswd -a void
```
> [!TIP]
> Enter the **exact same password** that is stored in the Host PC's `/etc/samba/credentials` file.

### 5. Enable and Start Samba Service
```bash
sudo systemctl enable --now smb.service
```
Verify that the service is running:
```bash
systemctl status smb.service
```

### 6. Optimize Laptop Client Mounts for PC
To prevent Dolphin from ever freezing on the Laptop if network routes drop or the PC goes to sleep, update `/etc/fstab`:
```bash
sudo nano /etc/fstab
```
Update the PC shares to include `soft,echo_interval=30`:
```text
//100.117.73.75/Storage  /mnt/PC_Storage  cifs  credentials=/etc/samba/credentials,uid=1000,gid=1000,users,vers=3.1.1,soft,echo_interval=30,noauto,nofail,_netdev  0  0
//100.117.73.75/Home     /mnt/PC_Home     cifs  credentials=/etc/samba/credentials,uid=1000,gid=1000,users,vers=3.1.1,soft,echo_interval=30,noauto,nofail,_netdev  0  0
```
Apply the changes:
```bash
sudo systemctl daemon-reload
```

---

## Part 3: Verification & Testing

### Testing from the Laptop
1. Open **Dolphin**.
2. Click **`PC_Home`** or **`PC_Storage`** in the sidebar.
3. The folders should open instantly.
4. Try copying or modifying files. Dolphin will stay responsive even during heavy operations.

### Testing from the Host PC
1. Open **Dolphin** on `void-pc`.
2. Click **`Laptop_Home`** in the sidebar.
3. Verify that the Laptop's home directory is browsable and writable.

### Testing via Terminal (Optional)
Check active SMB sessions on either machine:
```bash
sudo smbstatus
```
List remote shares using credentials:
```bash
smbclient -A /etc/samba/credentials -L //100.117.73.75
smbclient -A /etc/samba/credentials -L //100.70.236.70
```

---

## Troubleshooting Cheatsheet

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| `NT_STATUS_LOGON_FAILURE` | Samba password doesn't match credentials file | Run `sudo smbpasswd -a void` on the server and enter the password saved in `/etc/samba/credentials`. |
| `Permission denied` when writing files | Local Linux permissions or wrong ownership | Check ownership: `chown -R void:void /home/void`. In `smb.conf`, ensure `force user = void` and `force group = void` are present. |
| `Host is down` or `Connection refused` | Service stopped or port blocked | Verify `systemctl status smb.service` on server and ensure UFW allows 445: `sudo ufw allow 445/tcp`. |
| Target is busy when unmounting | Active file handles or Dolphin open | Run `sudo umount -l /mnt/PC_Home` (lazy unmount) to detach cleanly. |
