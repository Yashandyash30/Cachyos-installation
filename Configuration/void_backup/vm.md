h the s

is error whenever i try to connect to my server computer using x2go client with
IP:

# Windows VM with GPU Passthrough on CachyOS

> A complete guide to running Windows in a VM with your **NVIDIA GTX 1650** passed through for near-native GPU performance, while keeping your **AMD iGPU** running your CachyOS desktop.

---

## Your Hardware

| Component            | Details                                                                             |
| -------------------- | ----------------------------------------------------------------------------------- |
| **CPU**        | AMD Ryzen 5 5500U (6C/12T)                                                          |
| **iGPU**       | AMD Radeon (Lucienne) — runs your Linux desktop                                    |
| **dGPU**       | NVIDIA GTX 1650 Mobile (`01:00.0`, ID: `10de:1f9d`) — will be passed to the VM |
| **RAM**        | 15 GB                                                                               |
| **OS**         | CachyOS (Arch-based), Limine bootloader, Niri (Wayland), Fish shell                 |
| **Filesystem** | Btrfs with zstd compression                                                         |

---

## How This Works

```
┌─────────────────────────────────────┐
│         Your Physical PC            │
│                                     │
│  ┌───────────┐    ┌──────────────┐  │
│  │  CachyOS  │    │  Windows VM  │  │
│  │  (Host)   │    │  (Guest)     │  │
│  │           │    │              │  │
│  │ AMD iGPU  │    │ NVIDIA 1650  │  │
│  │ (display) │    │ (passthrough)│  │
│  └───────────┘    └──────────────┘  │
│        │                  │         │
│        ▼                  ▼         │
│   Your Monitor     Looking Glass    │
│   (native)      (Wayland window)    │
└─────────────────────────────────────┘
```

1. thYour CachyOS desktop runs on the **AMD iGPU** (as it already does).
2. When you start the VM, the **NVIDIA GTX 1650** is handed over to Windows.
3. **Looking Glass** captures the Windows display and shows it as a low-latency window inside Niri.
4. When you shut down the VM, the NVIDIA GPU returns to Linux.

---

## Phase 1 — Install the Virtualization Stack

### 1.1 Install packages

```bash
sudo pacman -S qemu-desktop libvirt virt-manager virt-viewer dnsmasq edk2-ovmf virtiofsd
paru -S looking-glass
```

### 1.2 Enable libvirt and add your user to the required groups

```bash
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm $USER
```

> **⚠️ You must log out and back in** for the group changes to take effect.

---

## Phase 2 — Prepare Storage

### 2.1 Create a compressed VM disk directory

Since you are on Btrfs, we can use transparent compression so the VM disk takes up minimal space:

```bash
mkdir -p ~/.local/share/libvirt/images
chattr +c ~/.local/share/libvirt/images
```

### 2.2 Create a sparse VM disk

This creates a 64 GB disk that starts at 0 bytes and only grows as Windows writes data:

```bash
qemu-img create -f qcow2 -o compression_type=zstd ~/.local/share/libvirt/images/win-lean.qcow2 64G
```

### 2.3 Download the required ISOs

Place these in `~/.local/share/libvirt/images/`:

1. **[Tiny11 ISO](https://archive.org/download/tiny11_25H2/tiny11_25H2_Nov25.iso)** — lightweight Windows 11 (5.3 GB)
2. **[VirtIO Drivers ISO](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)** — required for Windows to see the virtual disk and network

---

## Phase 3 — Set Up Looking Glass Shared Memory

Looking Glass needs a shared memory block to copy frames from the VM to your Linux desktop.

### 3.1 Create the shared memory rule

> **Note:** Since you use Fish shell, the `<<EOF` syntax won't work. Use this instead:

```bash
echo "f /dev/shm/looking-glass 0660 $USER kvm -" | sudo tee /etc/tmpfiles.d/10-looking-glass.conf
```

### 3.2 Apply the rule immediately

```bash
sudo systemd-tmpfiles --create /etc/tmpfiles.d/10-looking-glass.conf
```

This will also auto-apply on every reboot.

---

## Phase 4 — GPU Passthrough (Dynamic Method)

> **Why dynamic?** With dynamic passthrough, the NVIDIA GPU is only grabbed when the VM starts and released when it stops. You can still use the NVIDIA GPU for Linux tasks (CUDA, rendering, gaming via PRIME) when the VM is off.

### 4.1 Verify your GPU

```bash
lspci -nn | grep -i nvidia
```

You should see:

```
01:00.0 3D controller [0302]: NVIDIA Corporation TU117M [GeForce GTX 1650 Mobile / Max-Q] [10de:1f9d] (rev a1)
```

### 4.2 Enable IOMMU (required)

Even with dynamic passthrough, IOMMU must be enabled in your kernel. Edit your Limine config:

```bash
sudo nano /boot/limine.conf
```

Find the `cmdline:` line under `//linux-cachyos` (your main kernel entry):

```
cmdline: quiet nowatchdog splash rw rootflags=subvol=/@ root=UUID=... usbcore.autosuspend=-1
```

Add **only** `amd_iommu=on` at the end (do NOT add `vfio-pci.ids=...`):

```
cmdline: quiet nowatchdog splash rw rootflags=subvol=/@ root=UUID=... usbcore.autosuspend=-1 amd_iommu=on
```

> **💡 Why no `vfio-pci.ids`?** Adding `vfio-pci.ids=10de:1f9d` would permanently lock the GPU away from Linux at boot. We skip this so the GPU stays available for Linux use. Virt-Manager will dynamically grab it only when you start the VM.

Save (`Ctrl+O`, `Enter`) and exit (`Ctrl+X`), then reboot:

```bash
sudo reboot
```

### 4.3 Verify IOMMU is active after reboot

```bash
dmesg | grep -i iommu
```

You should see lines like `AMD-Vi: IOMMU performance counters supported` or similar.

---

## Phase 5 — Create the VM in Virt-Manager

Open **Virtual Machine Manager** (`virt-manager`) and create a new VM.

### 5.1 Initial setup

1. Choose **Local install media (ISO)** → select your Tiny11 ISO.
2. Set RAM to **8192 MB** (8 GB) — leaves ~7 GB for CachyOS.
3. Set CPUs to **6** (half your threads).
4. Select your existing disk: `win-lean.qcow2`.
5. ✅ **Check "Customize configuration before install"** before clicking Finish.

### 5.2 Hardware configuration

In the customization screen, change/add these settings:

| Setting                        | Value                                                             |
| ------------------------------ | ----------------------------------------------------------------- |
| **Overview → Firmware** | `UEFI (OVMF_CODE.secboot.fd)`                                   |
| **Overview → Chipset**  | `Q35`                                                           |
| **CPUs → Model**        | `host-passthrough`                                              |
| **CPUs → Topology**     | Check "Manually set CPU topology" → 1 socket, 3 cores, 2 threads |
| **Disk → Bus**          | Change from IDE/SATA to**VirtIO**                           |

### 5.3 Add extra hardware

Click **"Add Hardware"** for each of these:

1. **CDROM** → Attach `virtio-win.iso` (so Windows can find drivers during install)
2. **PCI Host Device** → Select `01:00.0 NVIDIA Corporation TU117M [GeForce GTX 1650]`
3. **Shared Memory (IVSHMEM)**:
   - Name/Path: `/dev/shm/looking-glass`
   - Size: `64` MiB
4. **Filesystem (Virtio-FS)** *(optional, for sharing files between Linux and Windows)*:
   - Driver: `virtiofs`
   - Source path: `/home/void/Documents`
   - Target path: `cachyos_share`

### 5.4 Remove unnecessary hardware

Since you are passing a real GPU, **remove** these default virtual devices (right-click → Remove):

- ❌ **Video QXL** (or Video Virtio)
- ❌ **Display Spice**

> **⚠️ Without Spice/QXL, you won't see the Windows installer on your screen initially!**
> You have two options:
>
> - **Option A:** Keep Spice/QXL during install, complete setup, then remove them and add the GPU later.
> - **Option B:** Plug a monitor into your laptop's HDMI port (connected to the NVIDIA GPU) to see the installer directly.
>
> **Option A is recommended** for simplicity.

### 5.5 Click "Begin Installation"

---

## Phase 6 — Install Windows

### 6.1 Load the storage driver

Windows won't see your VirtIO disk during setup. When asked "Where do you want to install Windows?":

1. Click **"Load Driver"**
2. Browse to the VirtIO CD → `viostor\w11\amd64`
3. Select the driver and click Next
4. Your disk will now appear — proceed with installation

### 6.2 Install VirtIO guest tools (after Windows boots)

Open the VirtIO CD inside Windows and run:

```
virtio-win-guest-tools.exe
```

This installs network, memory balloon, and IVSHMEM drivers.

### 6.3 Set up file sharing with Virtio-FS *(optional)*

If you added the Filesystem device earlier:

1. Download and install **[WinFsp](https://winfsp.dev/)** inside Windows.
2. Open an **Admin PowerShell** and run:

```powershell
sc.exe create VirtioFsSvc binpath="C:\Program Files\VirtIO-Win\virtiofs.exe" start=auto
sc.exe start VirtioFsSvc
```

Your CachyOS `Documents` folder will appear as the `Z:` drive in Windows.

### 6.4 Install Looking Glass Host

1. Download the **Windows Host** application from [looking-glass.io](https://looking-glass.io/downloads).
2. Install it — it creates a background service that captures frames from the NVIDIA GPU.

### 6.5 Shrink Windows *(optional but recommended)*

Open an Admin PowerShell inside Windows:

```powershell
# Disable hibernation (saves 4-8 GB)
powercfg -h off

# Run disk cleanup
cleanmgr
```

---

## Phase 7 — Use Looking Glass on Niri

Once the VM is running with the Looking Glass host service active, open a terminal on CachyOS:

```bash
looking-glass-client -m KEY_SCROLLLOCK
```

The Windows VM appears as a **native Wayland window** inside Niri. It will tile like any other window.

### Controls

| Action                          | Key                     |
| ------------------------------- | ----------------------- |
| **Release mouse** from VM | `Scroll Lock`         |
| **Capture mouse** into VM | Click inside the window |

### Pro tip: Create a quick launcher

Add this to your Niri config or as a shell alias:

```bash
alias winvm="virsh start win-lean 2>/dev/null; looking-glass-client -m KEY_SCROLLLOCK"
```

---

## Phase 8 — Maintenance

### Reclaim disk space

After uninstalling apps inside Windows:

1. Run `fstrim -a` inside Windows (Admin PowerShell: `Optimize-Volume -DriveLetter C -ReTrim`)
2. On CachyOS, compact the image:

```bash
qemu-img convert -O qcow2 -c ~/.local/share/libvirt/images/win-lean.qcow2 ~/.local/share/libvirt/images/win-lean-shrunk.qcow2
mv ~/.local/share/libvirt/images/win-lean-shrunk.qcow2 ~/.local/share/libvirt/images/win-lean.qcow2
```

---

## Troubleshooting

### VM fails to start / GPU passthrough error

If dynamic passthrough fails because the NVIDIA driver won't release the GPU, you can fall back to **static passthrough** (locks the GPU to VFIO at boot):

```bash
sudo nano /boot/limine.conf
```

Change the `cmdline:` line to include `vfio-pci.ids`:

```
cmdline: ... amd_iommu=on vfio-pci.ids=10de:1f9d
```

Reboot. The NVIDIA GPU will no longer be usable by Linux, but the VM will always be able to grab it.

### IOMMU group issues

Check your IOMMU groups:

```bash
for d in /sys/kernel/iommu_groups/*/devices/*; do
  n=$(basename $(dirname $(dirname "$d")))
  echo "IOMMU Group $n: $(lspci -nns ${d##*/})"
done
```

If your GPU shares an IOMMU group with other devices, you may need the `acs_override` kernel patch (available in CachyOS kernels).

### Looking Glass shows black screen

Make sure the Looking Glass **Host** application is running inside Windows (check the system tray). Restart the service if needed:

```powershell
net stop looking-glass-host
net start looking-glass-host
```
